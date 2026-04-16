extends "res://scripts/npc/states/base_state.gd"

# Hunt State — AI clan hunting party (Area of Hunt → chase wild mammoth/sheep/goat)
# Pull-based: ClanBrain sets hunt intent; mirrors raid_state flow (assemble → move → engage → return).

enum HuntPhase { FORMING, CHASING, KILLING, LOOTING, RETURNING }

var hunt_phase: HuntPhase = HuntPhase.FORMING
var land_claim: Node = null
var clan_brain: RefCounted = null
var assembly_timeout: float = 30.0
var assembly_timer: float = 0.0
var _loot_timer: float = 0.0
## Brief claim/brain misses should not drop hunt (one-frame get_my_land_claim() gaps).
var _hunt_abort_grace_timer: float = 0.0
const HUNT_ABORT_GRACE_SEC: float = 0.4

func enter() -> void:
	if not npc:
		return
	# Defensive: ordered followers should be party, not hunt (race if FSM beat _form_hunt_party).
	var nt0: String = str(npc.get("npc_type")) if npc.get("npc_type") != null else ""
	if npc.get("follow_is_ordered") and (nt0 == "caveman" or nt0 == "clansman") and fsm:
		fsm.change_state("party")
		return
	_cancel_tasks_if_active()
	_find_clan_brain()
	if not clan_brain:
		if fsm:
			fsm.change_state("wander")
		return
	if clan_brain.has_method("npc_join_hunt"):
		clan_brain.npc_join_hunt(npc)
	npc.set("is_hostile", true)
	hunt_phase = HuntPhase.FORMING
	assembly_timer = 0.0
	_loot_timer = 0.0
	var nn: String = str(npc.get("npc_name")) if npc.get("npc_name") != null else str(npc.name)
	print("🎯 HUNT_STATE: %s joined hunt (FORMING)" % nn)
	var tree = npc.get_tree() if npc else null
	if tree:
		var pi = tree.root.get_node_or_null("PlaytestInstrumentor")
		if pi and pi.is_enabled() and pi.has_method("hunt_joined"):
			pi.hunt_joined(nn, HuntPhase.keys()[hunt_phase])
	_hunt_abort_grace_timer = 0.0

func exit() -> void:
	_cancel_tasks_if_active()
	if npc:
		npc.remove_meta("hunt_after_combat")
	if clan_brain and clan_brain.has_method("npc_leave_hunt"):
		clan_brain.npc_leave_hunt(npc)
	if npc:
		npc.set("is_hostile", false)
	print("🎯 HUNT_STATE: %s left hunt" % (npc.get("npc_name") if npc else "NPC"))

func update(delta: float) -> void:
	if not npc:
		return
	if _is_following():
		if fsm:
			var nt_rf: String = str(npc.get("npc_type")) if npc.get("npc_type") != null else ""
			if nt_rf == "caveman" or nt_rf == "clansman":
				fsm.change_state("party")
			else:
				fsm.change_state("herd")
		return
	_find_clan_brain()
	var brain_ok: bool = clan_brain != null and clan_brain.has_method("is_hunting") and clan_brain.is_hunting()
	if not brain_ok:
		_hunt_abort_grace_timer += delta
		if _hunt_abort_grace_timer < HUNT_ABORT_GRACE_SEC:
			return
		if fsm:
			fsm.change_state("wander")
		return
	_hunt_abort_grace_timer = 0.0
	var hint: Dictionary = clan_brain.get_hunt_intent() if clan_brain.has_method("get_hunt_intent") else {}
	var hs: int = int(hint.get("state", 0))
	# ClanBrain.HuntIntentState: 0 NONE — sync retreat
	if hs == 3:  # RETREATING
		hunt_phase = HuntPhase.RETURNING
	match hunt_phase:
		HuntPhase.FORMING:
			_update_forming(delta)
		HuntPhase.CHASING:
			_update_chasing(delta)
		HuntPhase.KILLING:
			_update_killing()
		HuntPhase.LOOTING:
			_update_looting(delta)
		HuntPhase.RETURNING:
			_update_returning(delta)

func _update_forming(delta: float) -> void:
	assembly_timer += delta
	if assembly_timer > assembly_timeout:
		if fsm:
			fsm.change_state("wander")
		return
	var rally: Vector2 = clan_brain.get_hunt_rally_point() if clan_brain.has_method("get_hunt_rally_point") else Vector2.ZERO
	if rally != Vector2.ZERO and npc.steering_agent:
		npc.steering_agent.set_target_position(rally)
	if rally != Vector2.ZERO and npc.global_position.distance_to(rally) < 55.0:
		hunt_phase = HuntPhase.CHASING

func _update_chasing(_delta: float) -> void:
	var hint0: Dictionary = clan_brain.get_hunt_intent() if clan_brain.has_method("get_hunt_intent") else {}
	var prey: Node = hint0.get("target") as Node
	if not prey or not is_instance_valid(prey):
		hunt_phase = HuntPhase.RETURNING
		return
	if prey.has_method("is_dead") and prey.is_dead():
		hunt_phase = HuntPhase.LOOTING
		_loot_timer = 0.0
		return
	var prey_pos: Vector2 = prey.global_position
	if npc.steering_agent:
		npc.steering_agent.set_target_position(prey_pos)
	var dist: float = npc.global_position.distance_to(prey_pos)
	if dist < 120.0:
		hunt_phase = HuntPhase.KILLING

func _update_killing() -> void:
	var hint1: Dictionary = clan_brain.get_hunt_intent() if clan_brain and clan_brain.has_method("get_hunt_intent") else {}
	var prey: Node = hint1.get("target") as Node
	if not prey or not is_instance_valid(prey):
		hunt_phase = HuntPhase.RETURNING
		return
	if prey.has_method("is_dead") and prey.is_dead():
		hunt_phase = HuntPhase.LOOTING
		_loot_timer = 0.0
		return
	npc.set("combat_target", prey)
	npc.set("agro_meter", 100.0)
	if npc:
		npc.set_meta("hunt_after_combat", true)
	# Combat (priority 12) takes over next FSM tick

func _update_looting(delta: float) -> void:
	_loot_timer += delta
	if _loot_timer > 0.75:
		hunt_phase = HuntPhase.RETURNING

func _update_returning(_delta: float) -> void:
	if not land_claim or not is_instance_valid(land_claim):
		_find_clan_brain()
	if land_claim and is_instance_valid(land_claim):
		var home: Vector2 = land_claim.global_position
		if npc.steering_agent:
			npc.steering_agent.set_target_position(home)
		if npc.global_position.distance_to(home) < land_claim.radius * 1.1:
			if fsm:
				fsm.change_state("wander")
	else:
		if fsm:
			fsm.change_state("wander")

func _find_clan_brain() -> void:
	# Do not clear cache first: get_my_land_claim() can be null for a frame at territory edges.
	var claim = npc.get_my_land_claim() if npc and npc.has_method("get_my_land_claim") else null
	if claim and is_instance_valid(claim):
		land_claim = claim
		if claim.has_method("get_clan_brain"):
			clan_brain = claim.get_clan_brain()
		elif "clan_brain" in claim:
			clan_brain = claim.clan_brain
		return
	if land_claim and is_instance_valid(land_claim):
		if land_claim.has_method("get_clan_brain"):
			clan_brain = land_claim.get_clan_brain()
		elif "clan_brain" in land_claim:
			clan_brain = land_claim.clan_brain
		return
	land_claim = null
	clan_brain = null

func can_enter() -> bool:
	if not npc:
		return false
	var tp: String = str(npc.get("npc_type")) if npc.get("npc_type") != null else ""
	if tp != "caveman" and tp != "clansman":
		return false
	if npc.get("follow_is_ordered"):
		return false
	var defend_target = npc.get("defend_target")
	if defend_target and is_instance_valid(defend_target):
		return false
	_find_clan_brain()
	if not clan_brain or not clan_brain.has_method("is_hunting"):
		return false
	if not clan_brain.is_hunting():
		return false
	if clan_brain.has_method("should_npc_hunt") and not clan_brain.should_npc_hunt(npc):
		return false
	return true

func get_priority() -> float:
	# Between raid (8.5) and combat (12)
	return 9.0

func get_data() -> Dictionary:
	return {
		"hunt_phase": HuntPhase.keys()[hunt_phase],
		"has_clan_brain": clan_brain != null
	}
