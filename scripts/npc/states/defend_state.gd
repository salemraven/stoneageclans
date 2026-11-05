extends "res://scripts/npc/states/base_state.gd"

# Defend state — NPC holds land claim border, patrols guard band, engages hostiles via intrusion/combat.
# Step 7: Clansmen only (and cavemen). defend_target = land claim.

var guard_angle: float = 0.0  # Angle on claim circle for guard position
var guard_band_factor: float = 1.0  # On the claim circle
## Beats gather (~5.8) and wife search (6). Combat is 12, so a fight still pulls him off the post.
const GUARD_POST_PRIORITY := 11.6
const HOLD_MIN_SEC := 4.5
const HOLD_MAX_SEC := 9.0
const STEP_MIN_RAD := 0.55
const STEP_MAX_RAD := 1.15
const ARRIVE_PX := 28.0
## One shift, then he leaves the spear so he can look for a wife. Someone else fills the post.
const SHIFT_MIN_SEC := 50.0
const SHIFT_MAX_SEC := 80.0
const REST_MIN_SEC := 70.0
const REST_MAX_SEC := 110.0
var _pace: String = "walk"
var _hold_left: float = 0.0
var _walk_refresh: float = 0.0

func enter() -> void:
	if not npc:
		return
	
	# Set defend_target here (not in can_enter) so should_abort_work only triggers after we actually enter
	var dt = npc.get("defend_target")
	if not dt or not is_instance_valid(dt):
		var claim = npc.get_my_land_claim() if npc.has_method("get_my_land_claim") else null
		if claim and is_instance_valid(claim) and claim.has_method("_prune_defenders"):
			claim._prune_defenders()
			if npc in claim.assigned_defenders:
				npc.set("defend_target", claim)
				dt = claim
	if not dt or not is_instance_valid(dt):
		return
	
	# Task System - Step 18: Cancel current job when entering defend
	_cancel_tasks_if_active()
	if npc.task_runner and npc.task_runner.has_method("has_job") and npc.task_runner.has_job():
		UnifiedLogger.log_npc("DEFEND: %s cancelled gather job due to defend assignment" % npc.npc_name, {
			"npc": npc.npc_name,
			"event": "job_cancelled_defend"
		})
	# Spread defenders around the border so they do different positions (avoids clustering)
	var raw_defenders: Array = dt.assigned_defenders if "assigned_defenders" in dt else []
	var valid_defenders: Array = []
	for d in raw_defenders:
		if is_instance_valid(d):
			valid_defenders.append(d)
	var my_index: int = 0
	if valid_defenders.size() > 0:
		for i in range(valid_defenders.size()):
			if valid_defenders[i] == npc:
				my_index = i
				break
		guard_angle = (TAU * my_index) / valid_defenders.size()  # Evenly spaced around circle
	else:
		guard_angle = fmod(float(npc.get_instance_id() % 360) * 0.01745329, TAU)  # Fallback: unique by instance
	_pace = "walk"
	_hold_left = 0.0
	_walk_refresh = 0.0
	_arm_shift()
	if npc.has_method("equip_work_weapon_spear"):
		npc.equip_work_weapon_spear()
	UnifiedLogger.log_npc("Defend enter: %s at claim %s (angle=%.2f)" % [
		npc.npc_name if npc else "?",
		dt.name if dt else "?",
		guard_angle
	], {"npc": npc.npc_name, "state": "defend"}, UnifiedLogger.Level.DEBUG)
	var pi_d: Node = npc.get_node_or_null("/root/PlaytestInstrumentor")
	if pi_d and pi_d.is_enabled():
		var total_def: int = valid_defenders.size()
		pi_d.clansman_defend_entered(npc.npc_name, dt.name if dt else "?", guard_angle, my_index, total_def)

func exit() -> void:
	_cancel_tasks_if_active()
	
	# When transitioning to combat: keep defend_target so combat can enforce pursuit limit
	# Defender stays in pool; they'll return to defend when combat ends or target flees
	var next_state: String = npc.get_meta("fsm_next_state", "") if npc and npc.has_meta("fsm_next_state") else ""
	if next_state == "combat":
		return  # Don't remove from defenders, don't clear defend_target
	
	# Phase 3 Pull-based: Remove self from defender pool when leaving
	if npc:
		var dt = npc.get("defend_target")
		var claim_name_exit: String = dt.name if (dt and is_instance_valid(dt)) else "?"
		if dt and is_instance_valid(dt):
			dt.remove_defender(npc)
		print("🛡️ DEFEND_STATE: %s left defend duty" % (npc.get("npc_name") if "npc_name" in npc else "NPC"))
		var pi_dx: Node = npc.get_node_or_null("/root/PlaytestInstrumentor")
		if pi_dx and pi_dx.is_enabled():
			var next_dx: String = npc.get_meta("fsm_next_state", "") if npc.has_meta("fsm_next_state") else "fsm_eval"
			pi_dx.clansman_defend_exited(npc.get("npc_name") if "npc_name" in npc else "NPC", claim_name_exit, next_dx)
		npc.set_meta("defend_last_exit_time", Time.get_ticks_msec() / 1000.0)
		npc.set("defend_target", null)
	var next_weapon: String = npc.get_meta("fsm_next_state", "") if npc.has_meta("fsm_next_state") else ""
	if next_weapon != "combat" and next_weapon != "party" and next_weapon != "hunt" and next_weapon != "raid":
		if npc.has_method("equip_work_weapon_club"):
			npc.equip_work_weapon_club()

func update(delta: float) -> void:
	if not npc:
		return
	
	if _is_following():
		if fsm:
			var nt_df: String = str(npc.get("npc_type")) if npc.get("npc_type") != null else ""
			if nt_df == "caveman" or nt_df == "clansman":
				fsm.change_state("party")
			else:
				fsm.change_state("herd")
		return
	
	# OPTIMIZATION: Tasks are cancelled on enter() - no need to cancel every frame
	# Removed per-frame _cancel_tasks_if_active() call for performance
	
	var dt = npc.get("defend_target")
	if not dt or not is_instance_valid(dt):
		npc.set("defend_target", null)
		if fsm:
			fsm.change_state("wander")
		return
	
	# Phase 3: Lazy self-eviction - check if we should still be defending
	# This handles quota drops without thrashing (NPCs self-evict, not force-removed)
	if _shift_is_over() and not _camp_needs_every_man(dt):
		_step_off_post()
		if fsm:
			fsm.change_state("wander")
		return
	
	if dt.has_method("should_i_defend") and not dt.should_i_defend(npc):
		print("🛡️ DEFEND_STATE: %s self-evicting (over quota)" % npc.npc_name)
		var pi_ev: Node = npc.get_node_or_null("/root/PlaytestInstrumentor")
		if pi_ev and pi_ev.is_enabled():
			pi_ev.clansman_defend_exited(npc.npc_name, dt.name if is_instance_valid(dt) else "?", "self_evict_over_quota")
		if fsm:
			fsm.change_state("wander")
		return
	
	var claim_pos: Vector2 = dt.global_position
	var radius: float = 400.0
	var rp = dt.get("radius")
	if rp != null:
		radius = rp as float
	
	var dist: float = radius * guard_band_factor
	var guard_pos: Vector2 = claim_pos + Vector2(cos(guard_angle), sin(guard_angle)) * dist
	if _pace == "hold":
		_hold_left -= delta
		if npc.steering_agent:
			npc.steering_agent.hold_still()
		if _hold_left <= 0.0:
			guard_angle = fmod(guard_angle + _step_radians(), TAU)
			_pace = "walk"
			_walk_refresh = 0.0
	if _pace == "walk":
		if npc.global_position.distance_to(guard_pos) <= ARRIVE_PX:
			_pace = "hold"
			_hold_left = _pause_seconds()
			if npc.steering_agent:
				npc.steering_agent.hold_still()
		else:
			_walk_refresh -= delta
			if _walk_refresh <= 0.0 and npc.steering_agent:
				npc.steering_agent.set_target_position_immediate(guard_pos)
				_walk_refresh = 1.5

func can_enter() -> bool:
	if not npc:
		return false
	# Agro combat test leaders are driven by main — must not patrol (defend)
	if npc.has_meta("agro_combat_test_leader"):
		return false
	var tp: String = npc.get("npc_type") if npc else ""
	if tp != "caveman" and tp != "clansman":
		return false
	
	# Don't defend while ordered to follow
	if npc.get("follow_is_ordered"):
		return false
	
	# Carrying travois: cannot defend (must drop and equip weapon first)
	if npc.has_method("has_travois") and npc.has_travois():
		return false
	
	if _on_guard_rest():
		return false
	
	# Re-entry cooldown: avoid thrashing defend <-> wander when switching states
	if npc.has_meta("defend_last_exit_time"):
		var last_exit: float = npc.get_meta("defend_last_exit_time", 0.0)
		if Time.get_ticks_msec() / 1000.0 - last_exit < 5.0:
			return false
	
	# Phase 3 Pull-based: Check if already assigned (defend_target set in enter) OR if quota has room
	var dt = npc.get("defend_target")
	if dt and is_instance_valid(dt):
		return true  # Already in defend - re-entry (e.g. from combat)
	
	# Check if clan needs more defenders (pull-based self-assignment)
	var clan_name: String = ""
	if npc.has_method("get_clan_name"):
		clan_name = npc.get_clan_name()
	else:
		clan_name = npc.get("clan_name") if "clan_name" in npc else ""
	
	if clan_name == "":
		return false
	
	var claim = npc.get_my_land_claim() if npc.has_method("get_my_land_claim") else null
	if not claim or not is_instance_valid(claim):
		return false
	
	# Check defender quota
	var quota: int = claim.get_meta("defender_quota", 0)
	if quota <= 0:
		return false
	
	# Check current defender count
	claim._prune_defenders()
	var current_count: int = claim.assigned_defenders.size()
	
	if current_count < quota:
		# There's room - self-assign to pool only (defend_target set in enter() to avoid premature job cancellation)
		claim.add_defender(npc)
		UnifiedLogger.log_npc("Defender self-assigned", {
			"npc": npc.get("npc_name") if "npc_name" in npc else "NPC",
			"current": current_count + 1,
			"quota": quota
		})
		return true
	
	return false

func _pause_seconds() -> float:
	var roll := 0.5
	if npc and npc.has_method("npc_randf"):
		roll = npc.npc_randf()
	return lerpf(HOLD_MIN_SEC, HOLD_MAX_SEC, roll)


func _step_radians() -> float:
	var roll := 0.5
	if npc and npc.has_method("npc_randf"):
		roll = npc.npc_randf()
	return lerpf(STEP_MIN_RAD, STEP_MAX_RAD, roll)


func _arm_shift() -> void:
	if not npc:
		return
	var now := Time.get_ticks_msec() / 1000.0
	var ends := float(npc.get_meta("guard_shift_ends_at", 0.0))
	if ends > now:
		return
	if ends > 0.0:
		return
	npc.set_meta("guard_shift_ends_at", now + lerpf(SHIFT_MIN_SEC, SHIFT_MAX_SEC, _roll()))


func _shift_is_over() -> bool:
	if not npc:
		return false
	return Time.get_ticks_msec() / 1000.0 >= float(npc.get_meta("guard_shift_ends_at", 0.0))


func _on_guard_rest() -> bool:
	if not npc or not npc.has_meta("guard_rest_until"):
		return false
	return Time.get_ticks_msec() / 1000.0 < float(npc.get_meta("guard_rest_until", 0.0))


func _step_off_post() -> void:
	if not npc:
		return
	var now := Time.get_ticks_msec() / 1000.0
	npc.set_meta("guard_rest_until", now + lerpf(REST_MIN_SEC, REST_MAX_SEC, _roll()))
	npc.set_meta("guard_shift_ends_at", 0.0)


func _camp_needs_every_man(claim: Node) -> bool:
	if claim == null or not is_instance_valid(claim):
		return false
	var brain = claim.get("clan_brain")
	if brain == null:
		return false
	if bool(brain.get("player_emergency_defend")):
		return true
	return int(brain.get("alert_level")) >= 3


func _roll() -> float:
	if npc and npc.has_method("npc_randf"):
		return npc.npc_randf()
	return 0.5


func _post_is_open() -> bool:
	if not npc or _on_guard_rest():
		return false
	var dt = npc.get("defend_target")
	if dt and is_instance_valid(dt):
		return true
	var claim = npc.get_my_land_claim() if npc.has_method("get_my_land_claim") else null
	if not claim or not is_instance_valid(claim):
		return false
	if npc in claim.assigned_defenders:
		return true
	var quota: int = int(claim.get_meta("defender_quota", 0))
	if quota <= 0:
		return false
	if claim.has_method("_prune_defenders"):
		claim._prune_defenders()
	return claim.assigned_defenders.size() < quota


func get_priority() -> float:
	if _post_is_open():
		return GUARD_POST_PRIORITY
	var p_default: float = 3.0
	if NPCConfig:
		p_default = NPCConfig.priority_defend_default
	return p_default

func get_data() -> Dictionary:
	var dt = npc.get("defend_target") if npc else null
	return {
		"defend_target": dt.get("name") if dt and is_instance_valid(dt) else "null",
		"guard_angle": guard_angle
	}
