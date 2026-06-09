extends "res://scripts/npc/states/base_state.gd"

const CorpseJobs = preload("res://scripts/systems/corpse_job_service.gd")

# Hunt State — AI clan hunting party (Area of Hunt → chase wild prey: deer, mammoth). Sheep/goat are herd-only.
# Pull-based: ClanBrain sets hunt intent; mirrors raid_state flow (assemble → move → engage → return).
# LOOTING is owned by ClanBrain + CorpseJobs; hunters exit to gather and pull butcher jobs.

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
const HUNT_ENCIRCLE_LEADER_DIST: float = 160.0
const HUNT_ENCIRCLE_FORCE_ATTACK_SEC: float = 3.0
const HUNT_CLOSE_TIMER_DECAY_MULT: float = 0.35
const HUNT_SKIP_RALLY_DIST: float = 450.0

var _hunt_abort_logged: bool = false
var _hunt_prey_killed_logged: bool = false
var _hunt_arc_mode_set: bool = false
var _hunt_close_timer: float = 0.0
var _hunt_attack_triggered: bool = false

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
	if npc.has_method("equip_work_weapon_spear"):
		npc.equip_work_weapon_spear()
	npc.set("is_hostile", true)
	var hint_resume: Dictionary = clan_brain.get_hunt_intent() if clan_brain.has_method("get_hunt_intent") else {}
	var prey_resume: Node = _resolve_prey_from_hint(hint_resume)
	if prey_resume:
		var prey_dead_resume: bool = false
		if prey_resume.has_method("is_dead"):
			prey_dead_resume = bool(prey_resume.is_dead())
		else:
			prey_dead_resume = not is_attack_target_alive(prey_resume)
		if prey_dead_resume:
			hunt_phase = HuntPhase.LOOTING
			_prepare_looting_entry()
		elif int(hint_resume.get("state", 0)) == 3:
			hunt_phase = HuntPhase.LOOTING
			_prepare_looting_entry()
		elif int(hint_resume.get("state", 0)) == 4:
			hunt_phase = HuntPhase.RETURNING
		elif npc.global_position.distance_to(prey_resume.global_position) < HUNT_SKIP_RALLY_DIST:
			hunt_phase = HuntPhase.CHASING
		elif npc.global_position.distance_to(prey_resume.global_position) < HUNT_ENCIRCLE_LEADER_DIST:
			hunt_phase = HuntPhase.CHASING
		else:
			hunt_phase = HuntPhase.FORMING
	else:
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
	_hunt_abort_logged = false
	_hunt_prey_killed_logged = false
	_hunt_arc_mode_set = false
	_hunt_close_timer = 0.0
	_hunt_attack_triggered = false
	if npc:
		npc.set_meta("chunk_sticky", true)

func exit() -> void:
	_cancel_tasks_if_active()
	if npc:
		if npc.has_meta("chunk_sticky"):
			npc.remove_meta("chunk_sticky")
	if npc:
		if npc.has_meta("is_stalking"):
			npc.remove_meta("is_stalking")
		if npc.has_meta("hunt_butchering"):
			npc.remove_meta("hunt_butchering")
	if clan_brain and clan_brain.has_method("npc_leave_hunt"):
		var resume_after_combat: bool = npc.get_meta("hunt_after_combat", false) if npc else false
		if not resume_after_combat:
			clan_brain.npc_leave_hunt(npc)
	if npc:
		if not npc.get_meta("hunt_after_combat", false):
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
		_emit_hunt_abort_if_needed("brain_lost")
		if fsm:
			fsm.change_state("wander")
		return
	_hunt_abort_grace_timer = 0.0
	var hint: Dictionary = clan_brain.get_hunt_intent() if clan_brain.has_method("get_hunt_intent") else {}
	var hs: int = int(hint.get("state", 0))
	# ClanBrain.HuntIntentState: LOOTING=3, RETREATING=4
	if hs == 3:
		if hunt_phase != HuntPhase.LOOTING:
			hunt_phase = HuntPhase.LOOTING
			_prepare_looting_entry()
	elif hs == 4:
		if hunt_phase == HuntPhase.LOOTING:
			_finish_looting("brain_retreat")
		elif hunt_phase != HuntPhase.RETURNING:
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
		_emit_hunt_abort_if_needed("assembly_timeout")
		if fsm:
			fsm.change_state("wander")
		return
	var hint_form: Dictionary = clan_brain.get_hunt_intent() if clan_brain.has_method("get_hunt_intent") else {}
	var prey_form: Node = _resolve_prey_from_hint(hint_form)
	if prey_form and npc.global_position.distance_to(prey_form.global_position) < HUNT_SKIP_RALLY_DIST:
		hunt_phase = HuntPhase.CHASING
		return
	var rally: Vector2 = clan_brain.get_hunt_rally_point() if clan_brain.has_method("get_hunt_rally_point") else Vector2.ZERO
	if rally != Vector2.ZERO and npc.steering_agent:
		npc.steering_agent.set_target_position(rally)
	if rally != Vector2.ZERO and npc.global_position.distance_to(rally) < 55.0:
		hunt_phase = HuntPhase.CHASING

func _update_chasing(delta: float) -> void:
	var hint0: Dictionary = clan_brain.get_hunt_intent() if clan_brain.has_method("get_hunt_intent") else {}
	var prey: Node = _resolve_prey_from_hint(hint0)
	if not prey:
		_emit_hunt_abort_if_needed("prey_invalid")
		hunt_phase = HuntPhase.RETURNING
		return
	var prey_dead: bool = false
	if prey.has_method("is_dead"):
		prey_dead = bool(prey.is_dead())
	else:
		prey_dead = not is_attack_target_alive(prey)
	if prey_dead:
		_emit_hunt_prey_killed_once(prey)
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
	if dist < HUNT_ENCIRCLE_LEADER_DIST:
		_hunt_close_timer += delta
		_ensure_hunt_arc_stance()
		var encircled: bool = clan_brain.has_method("is_hunt_party_encircled") and clan_brain.is_hunt_party_encircled(prey)
		if encircled or _hunt_close_timer >= HUNT_ENCIRCLE_FORCE_ATTACK_SEC:
			hunt_phase = HuntPhase.KILLING
	else:
		_hunt_close_timer = maxf(0.0, _hunt_close_timer - delta * HUNT_CLOSE_TIMER_DECAY_MULT)

func _update_killing() -> void:
	var hint1: Dictionary = clan_brain.get_hunt_intent() if clan_brain and clan_brain.has_method("get_hunt_intent") else {}
	var prey: Node = _resolve_prey_from_hint(hint1)
	if not prey:
		_emit_hunt_abort_if_needed("prey_invalid_killing")
		hunt_phase = HuntPhase.RETURNING
		return
	var prey_dead: bool = false
	if prey.has_method("is_dead"):
		prey_dead = bool(prey.is_dead())
	else:
		prey_dead = not is_attack_target_alive(prey)
	if prey_dead:
		_emit_hunt_prey_killed_once(prey)
		hunt_phase = HuntPhase.LOOTING
		_prepare_looting_entry()
		return
	if _hunt_attack_triggered:
		return
	_hunt_attack_triggered = true
	if clan_brain and clan_brain.has_method("trigger_hunt_party_attack"):
		clan_brain.trigger_hunt_party_attack(prey)

func _update_looting(_delta: float) -> void:
	# Corpse butchering runs via gather + ButcherCorpseJob; leave hunt FSM once site is open.
	if fsm:
		fsm.evaluation_timer = 0.0
		fsm.change_state("gather", true)

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

func _resolve_prey_from_hint(hint: Dictionary) -> Node:
	var raw_prey = hint.get("target")
	if raw_prey == null or not is_instance_valid(raw_prey):
		return null
	return raw_prey as Node


func _loot_corpse() -> Node:
	var hint_ch: Dictionary = clan_brain.get_hunt_intent() if clan_brain and clan_brain.has_method("get_hunt_intent") else {}
	return _resolve_prey_from_hint(hint_ch)

func _corpse_yield_total(corpse_node: Node) -> int:
	if not corpse_node or not is_instance_valid(corpse_node):
		return 0
	return int(corpse_node.get_meta("meat_remaining", 0)) + int(corpse_node.get_meta("hide_remaining", 0)) + int(corpse_node.get_meta("bone_remaining", 0))

func _corpse_kind(corpse: Node) -> String:
	if not corpse:
		return "unknown"
	return str(corpse.get("npc_type")) if corpse.get("npc_type") != null else "unknown"

func _hunter_clan_name() -> String:
	if npc and npc.has_method("get_clan_name"):
		var cn: Variant = npc.get_clan_name()
		if cn != null:
			return str(cn)
	return ""

func _emit_hunt_abort_if_needed(reason: String) -> void:
	if _hunt_abort_logged or not npc:
		return
	_hunt_abort_logged = true
	_find_clan_brain()
	if clan_brain and clan_brain.has_method("abort_hunt"):
		clan_brain.abort_hunt(reason)
		return
	var cn: String = _hunter_clan_name()
	var pi = npc.get_node_or_null("/root/PlaytestInstrumentor")
	if pi and pi.is_enabled() and pi.has_method("hunt_aborted"):
		pi.hunt_aborted(cn, reason)

func _emit_hunt_prey_killed_once(prey: Node) -> void:
	if _hunt_prey_killed_logged or not npc:
		return
	_hunt_prey_killed_logged = true
	var cn: String = _hunter_clan_name()
	var prey_type: String = _corpse_kind(prey)
	var killer: String = str(npc.npc_name) if npc.get("npc_name") != null else str(npc.name)
	var pi = npc.get_node_or_null("/root/PlaytestInstrumentor")
	if pi and pi.is_enabled() and pi.has_method("hunt_prey_killed"):
		pi.hunt_prey_killed(cn, prey_type, killer)

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
		CorpseJobs.clear_worker_meta(npc)
	hunt_phase = HuntPhase.RETURNING

func _ensure_hunt_arc_stance() -> void:
	if _hunt_arc_mode_set or not clan_brain:
		return
	if not clan_brain.has_method("set_hunt_party_arc_stance"):
		return
	clan_brain.set_hunt_party_arc_stance()
	_hunt_arc_mode_set = true


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
