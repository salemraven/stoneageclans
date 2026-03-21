extends "res://scripts/npc/states/base_state.gd"

# Defend state — NPC holds land claim border, patrols guard band, engages hostiles via intrusion/combat.
# Step 7: Clansmen only (and cavemen). defend_target = land claim.

var guard_angle: float = 0.0  # Angle on claim circle for guard position
var guard_band_factor: float = 0.9  # Stay at radius * this (inside border)
var update_interval: float = 0.3
var update_timer: float = 0.0

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
	UnifiedLogger.log_npc("Defend enter: %s at claim %s (angle=%.2f)" % [
		npc.npc_name if npc else "?",
		dt.name if dt else "?",
		guard_angle
	], {"npc": npc.npc_name, "state": "defend"}, UnifiedLogger.Level.DEBUG)

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
		if dt and is_instance_valid(dt):
			dt.remove_defender(npc)
			print("🛡️ DEFEND_STATE: %s left defend duty" % (npc.get("npc_name") if "npc_name" in npc else "NPC"))
		npc.set_meta("defend_last_exit_time", Time.get_ticks_msec() / 1000.0)
		npc.set("defend_target", null)

func update(delta: float) -> void:
	if not npc:
		return
	
	# CRITICAL: Exit immediately if following - following takes priority
	if _is_following():
		if fsm:
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
	if dt.has_method("should_i_defend") and not dt.should_i_defend(npc):
		print("🛡️ DEFEND_STATE: %s self-evicting (over quota)" % npc.npc_name)
		if fsm:
			fsm.change_state("wander")
		return
	
	var claim_pos: Vector2 = dt.global_position
	var radius: float = 400.0
	var rp = dt.get("radius")
	if rp != null:
		radius = rp as float
	
	# Slight patrol: drift angle over time (per-NPC phase so defenders don't sync and cluster)
	var drift_speed: float = 0.08 * (0.7 + 0.6 * fmod(float(npc.get_instance_id() % 17) / 17.0, 1.0))
	update_timer += delta
	if update_timer >= update_interval:
		update_timer = 0.0
		guard_angle += drift_speed
		if guard_angle >= TAU:
			guard_angle -= TAU
	
	var dist: float = radius * guard_band_factor
	var guard_pos: Vector2 = claim_pos + Vector2(cos(guard_angle), sin(guard_angle)) * dist
	
	# CRITICAL: Override any task system movement - defend position takes priority
	if npc.steering_agent:
		npc.steering_agent.set_target_position(guard_pos)

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

func get_priority() -> float:
	# Trait-driven: "protective" or "guardian" = high priority (will fill defender slot when quota allows)
	var is_protective: bool = npc.has_trait("protective") if npc.has_method("has_trait") else false
	if not is_protective and npc.has_method("has_trait"):
		is_protective = npc.has_trait("guardian")
	if is_protective:
		return 11.0  # Above herd_wildnpc; will defend when slot exists
	# Cavemen: low priority so they herd/gather and grow the clan (unless protective)
	var tp: String = npc.get("npc_type") if npc else ""
	if tp == "caveman":
		return 3.0  # Below gather and herd_wildnpc so cavemen go out to gather/herd
	# Clansmen: default high priority; "solitary" = prefer gather/herd, only defend when needed
	if npc.has_trait("solitary") if npc.has_method("has_trait") else false:
		return 8.0  # Below herd_wildnpc (11.5) so they prefer to herd/gather unless defender slot is open and no one else took it
	return 11.0  # Above herd_wildnpc; follow/defend override work-mode via can_enter in gather/herd_wildnpc

func get_data() -> Dictionary:
	var dt = npc.get("defend_target") if npc else null
	return {
		"defend_target": dt.get("name") if dt and is_instance_valid(dt) else "null",
		"guard_angle": guard_angle
	}
