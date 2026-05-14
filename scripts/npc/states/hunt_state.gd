extends "res://scripts/npc/states/base_state.gd"

const _ButcherTaskScript := preload("res://scripts/ai/tasks/butcher_task.gd")
const _JobScript := preload("res://scripts/ai/jobs/job.gd")

# Hunt State — AI clan hunting party (Area of Hunt → chase wild prey: deer, mammoth). Sheep/goat are herd-only.
# Pull-based: ClanBrain sets hunt intent; mirrors raid_state flow (assemble → move → engage → return).

enum HuntPhase { FORMING, CHASING, KILLING, LOOTING, RETURNING }

var hunt_phase: HuntPhase = HuntPhase.FORMING
var land_claim: Node = null
var clan_brain: RefCounted = null
var assembly_timeout: float = 30.0
var assembly_timer: float = 0.0
var _loot_timer: float = 0.0
var _loot_butcher_started_logged: bool = false
## Brief claim/brain misses should not drop hunt (one-frame get_my_land_claim() gaps).
var _hunt_abort_grace_timer: float = 0.0
const HUNT_ABORT_GRACE_SEC: float = 0.4
const LOOT_PHASE_TIMEOUT_SEC: float = 15.0

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
	_loot_butcher_started_logged = false
	var nn: String = str(npc.get("npc_name")) if npc.get("npc_name") != null else str(npc.name)
	print("🎯 HUNT_STATE: %s joined hunt (FORMING)" % nn)
	var pi = npc.get_node_or_null("/root/PlaytestInstrumentor")
	if pi and pi.is_enabled() and pi.has_method("hunt_joined"):
		pi.hunt_joined(nn, HuntPhase.keys()[hunt_phase])
	_hunt_abort_grace_timer = 0.0

func exit() -> void:
	_cancel_tasks_if_active()
	if npc:
		npc.remove_meta("hunt_after_combat")
		if npc.has_meta("is_stalking"):
			npc.remove_meta("is_stalking")
		if npc.has_meta("hunt_butchering"):
			npc.remove_meta("hunt_butchering")
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
	# ClanBrain.HuntIntentState: RETREATING — abort loot cleanup then sync phase
	if hs == 3:
		if hunt_phase == HuntPhase.LOOTING:
			_finish_looting("brain_retreat")
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
		_prepare_looting_entry()
		return
	var prey_pos: Vector2 = prey.global_position
	var dist: float = npc.global_position.distance_to(prey_pos)
	var stalk := bool(hint0.get("use_stalk_approach", false))
	if stalk and dist > 200.0:
		npc.set_meta("is_stalking", true)
	else:
		if npc.has_meta("is_stalking"):
			npc.remove_meta("is_stalking")
	if npc.steering_agent:
		npc.steering_agent.set_target_position(prey_pos)
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
		_prepare_looting_entry()
		return
	npc.set("combat_target", prey)
	npc.set("agro_meter", 100.0)
	if npc:
		npc.set_meta("hunt_after_combat", true)
	# Combat (priority 12) takes over next FSM tick

func _update_looting(delta: float) -> void:
	_loot_timer += delta
	if _loot_timer > LOOT_PHASE_TIMEOUT_SEC:
		_finish_looting("timeout")
		return
	var corpse: Node = _loot_corpse()
	if not corpse or not is_instance_valid(corpse):
		_finish_looting("corpse_invalid")
		return
	if _corpse_yield_total(corpse) <= 0:
		_finish_looting("corpse_empty")
		return
	if npc.inventory and not npc.inventory.has_space():
		_finish_looting("inventory_full")
		return
	if not _loot_butcher_started_logged:
		_emit_hunt_butcher_started_evt(corpse)
		_loot_butcher_started_logged = true
	if not npc.task_runner:
		return
	if npc.task_runner.has_job():
		return
	var job := _JobScript.new()
	job.add_task(_ButcherTaskScript.new(corpse))
	npc.task_runner.assign_job(job)
	npc.set_meta("hunt_butchering", true)

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

func _prepare_looting_entry() -> void:
	_loot_timer = 0.0
	_loot_butcher_started_logged = false
	if not npc:
		return
	if npc.has_method("_invalidate_combat_target"):
		npc.call("_invalidate_combat_target")
	npc.set_meta("hunt_loot_meat", 0)
	npc.set_meta("hunt_loot_hide", 0)
	npc.set_meta("hunt_loot_bone", 0)
	npc.set_meta("hunt_butcher_units", 0)

func _loot_corpse() -> Node:
	var hint_ch: Dictionary = clan_brain.get_hunt_intent() if clan_brain and clan_brain.has_method("get_hunt_intent") else {}
	return hint_ch.get("target") as Node

func _corpse_yield_total(corpse_node: Node) -> int:
	if not corpse_node or not is_instance_valid(corpse_node):
		return 0
	return int(corpse_node.get_meta("meat_remaining", 0)) + int(corpse_node.get_meta("hide_remaining", 0)) + int(corpse_node.get_meta("bone_remaining", 0))

func _corpse_kind(corpse: Node) -> String:
	if not corpse:
		return "unknown"
	return str(corpse.get("npc_type")) if corpse.get("npc_type") != null else "unknown"

func _emit_hunt_butcher_started_evt(corpse: Node) -> void:
	var pi_evt = npc.get_node_or_null("/root/PlaytestInstrumentor")
	if not pi_evt or not pi_evt.is_enabled() or not pi_evt.has_method("hunt_butcher_started"):
		return
	var ctype: String = _corpse_kind(corpse)
	pi_evt.hunt_butcher_started(
		str(npc.npc_name),
		ctype,
		int(corpse.get_meta("meat_remaining", 0)),
		int(corpse.get_meta("hide_remaining", 0)),
		int(corpse.get_meta("bone_remaining", 0))
	)

func _emit_hunt_butcher_complete_evt(reason: String) -> void:
	if not npc:
		return
	var pi_evt = npc.get_node_or_null("/root/PlaytestInstrumentor")
	if not pi_evt or not pi_evt.is_enabled() or not pi_evt.has_method("hunt_butcher_complete"):
		return
	var ctype: String = "unknown"
	var cor: Node = _loot_corpse()
	if cor and is_instance_valid(cor):
		ctype = _corpse_kind(cor)
	elif clan_brain and clan_brain.has_method("get_hunt_intent"):
		var hint_ck: Variant = clan_brain.get_hunt_intent().get("target_type", "unknown")
		ctype = str(hint_ck)
	pi_evt.hunt_butcher_complete(
		str(npc.npc_name),
		ctype,
		int(npc.get_meta("hunt_loot_meat", 0)),
		int(npc.get_meta("hunt_loot_hide", 0)),
		int(npc.get_meta("hunt_loot_bone", 0)),
		reason
	)

func _finish_looting(reason: String) -> void:
	if hunt_phase != HuntPhase.LOOTING:
		return
	if npc:
		if npc.task_runner and npc.task_runner.has_job():
			npc.task_runner.cancel_current_job("hunt_looting_%s" % reason)
		if npc.has_meta("hunt_butchering"):
			npc.remove_meta("hunt_butchering")
	var gained: int = 0
	if npc:
		gained = int(npc.get_meta("hunt_loot_meat", 0)) + int(npc.get_meta("hunt_loot_hide", 0)) + int(npc.get_meta("hunt_loot_bone", 0))
	if _loot_butcher_started_logged or gained > 0:
		_emit_hunt_butcher_complete_evt(reason)
	hunt_phase = HuntPhase.RETURNING

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
	if NPCConfig:
		return NPCConfig.priority_hunt
	return 9.0

func get_data() -> Dictionary:
	return {
		"hunt_phase": HuntPhase.keys()[hunt_phase],
		"has_clan_brain": clan_brain != null
	}
