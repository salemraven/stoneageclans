extends "res://scripts/npc/states/base_state.gd"

# Work at Building State - Women working at occupied buildings
# Priority: 7.0 (below occupy 7.5, above gathering 3.0)

var working_building: Node = null
var job_check_timer: float = 0.0
const JOB_CHECK_INTERVAL: float = 2.0  # Check for jobs every 2 seconds

# Throttle "no job" log to avoid spam
var _last_no_job_log_time: float = 0.0
const NO_JOB_LOG_THROTTLE_SEC: float = 5.0

func enter() -> void:
	# Task System - Step 17: Check for jobs when entering this state
	_try_pull_job()

func exit() -> void:
	# Clear occupation when leaving
	if npc and OccupationSystem:
		OccupationSystem.unassign(npc, "state_exit")
	
	# Show woman's sprite again (she's leaving the building)
	if npc:
		var npc_sprite = npc.get_node_or_null("Sprite")
		if npc_sprite:
			npc_sprite.visible = true
	
	# EDGE CASE FIX: Clear job reservations if NPC exits state without completing job
	# This prevents reservation starvation when NPC is interrupted
	if npc and npc.task_runner:
		# If NPC has a job, cancel it (which clears reservations)
		if npc.task_runner.has_method("has_job") and npc.task_runner.has_job():
			npc.task_runner.cancel_current_job()
		else:
			# If no job but might have reserved one, clear reservations manually (belt-and-suspenders)
			var buildings = get_tree().get_nodes_in_group("buildings")
			for building in buildings:
				if not is_instance_valid(building):
					continue
				# Clear production reservation
				if "job_reserved_by" in building and building.job_reserved_by == npc:
					building.job_reserved_by = null
				# Clear transport reservation
				if "transport_reserved_by" in building and building.transport_reserved_by == npc:
					building.transport_reserved_by = null
			# Release land claim item reservations (in case job was cancelled elsewhere before we got here)
			var land_claims = get_tree().get_nodes_in_group("land_claims")
			for claim in land_claims:
				if is_instance_valid(claim) and claim.has_method("release_items") and npc:
					claim.release_items(npc)
	
	working_building = null

func update(delta: float) -> void:
	if not npc:
		return
	
	# Dead NPCs can't work
	if npc.is_dead():
		return
	
	# Sprite visibility: hidden when inside building; visible when outside (including transporting)
	var npc_sprite = npc.get_node_or_null("Sprite")
	if npc_sprite:
		npc_sprite.visible = not _is_occupying_building()
	
	# Task System - Step 17: Check for jobs periodically if no current job
	job_check_timer += delta
	if job_check_timer >= JOB_CHECK_INTERVAL:
		job_check_timer = 0.0
		if not _has_active_job():
			_try_pull_job()
	
	# If we have an active job, TaskRunner handles it - we just need to stay in this state
	if _has_active_job():
		return
	
	# Legacy behavior: If no job system active, use old building occupation logic
	# Check if building is still valid
	if not working_building or not is_instance_valid(working_building):
		# Building destroyed or invalid - exit state
		return
	
	# Check if woman is still at building (within range)
	var distance: float = npc.global_position.distance_to(working_building.global_position)
	var work_range: float = 128.0  # Range to stay at building
	
	if distance > work_range:
		# Too far - move back to building
		if npc.steering_agent:
			npc.steering_agent.set_arrive_target(working_building.global_position)
	else:
		# At building - idle animation (production handled by building's production component)
		if npc.steering_agent:
			npc.steering_agent.set_arrive_target(npc.global_position)  # Stop moving

func can_enter() -> bool:
	if not npc:
		return false
	
	# Only women can work at buildings
	if npc.get("npc_type") != "woman":
		return false
	
	# Must be in clan
	if npc.is_wild():
		return false
	
	# Task System - Step 17: Can enter if there's a job available OR if already occupying a building
	if _has_available_job() or _is_occupying_building():
		return true
	
	return false

func get_priority() -> float:
	# Task System - Step 17: Higher priority if there's an available job OR if actively working
	# If NPC has an active job, prevent interruption by reproduction
	if _has_active_job():
		return 10.0  # Highest priority - don't interrupt active work
	if _has_available_job():
		return 9.0  # Higher than reproduction (8.0) when job is available
	return 7.0  # Below occupy (7.5), above gathering (3.0)

func _find_working_building() -> void:
	if not npc:
		return
	
	var npc_clan: String = npc.get_clan_name() if npc.has_method("get_clan_name") else ""
	if npc_clan == "":
		return
	
	# Find all buildings in the "buildings" group
	var buildings = get_tree().get_nodes_in_group("buildings")
	
	for building in buildings:
		if not is_instance_valid(building):
			continue
		if not "woman_slots" in building:
			continue
		for i in building.woman_slots.size():
			if building.woman_slots[i] == npc and is_instance_valid(building.woman_slots[i]):
				working_building = building
				return

func _is_occupying_building() -> bool:
	if not npc:
		return false
	
	var npc_clan: String = npc.get_clan_name() if npc.has_method("get_clan_name") else ""
	if npc_clan == "":
		return false
	
	# Check all woman slots in all buildings (not just primary/slot 0)
	var buildings = get_tree().get_nodes_in_group("buildings")
	for building in buildings:
		if not is_instance_valid(building):
			continue
		if not "woman_slots" in building:
			continue
		for i in building.woman_slots.size():
			if building.woman_slots[i] == npc and is_instance_valid(building.woman_slots[i]):
				return true
	return false

func get_data() -> Dictionary:
	return {
		"state": "work_at_building",
		"building": ResourceData.get_resource_name(working_building.building_type) if working_building and is_instance_valid(working_building) else "none"
	}

# Task System - Step 17: Job-pull logic

# Check if NPC has an active job
func _has_active_job() -> bool:
	if not npc:
		return false
	
	if not npc.task_runner:
		return false
	
	# Check if task_runner has the has_job method (it's a TaskRunner)
	if npc.task_runner.has_method("has_job"):
		return npc.task_runner.has_job()
	
	return false

# Check if there's an available job from any building (cheap check for priority/can_enter)
func _has_available_job() -> bool:
	if not npc:
		return false
	
	var npc_clan: String = npc.get_clan_name() if npc.has_method("get_clan_name") else ""
	if npc_clan == "":
		return false
	
	# Check all buildings for available jobs
	var buildings = get_tree().get_nodes_in_group("buildings")
	for building in buildings:
		if not is_instance_valid(building):
			continue
		
		# Only check buildings in same clan
		if not "clan_name" in building:
			continue
		var building_clan: String = building.clan_name
		if building_clan != npc_clan:
			continue
		
		# Use cheap availability check (not generate_job!)
		if building.has_method("has_available_job"):
			if building.has_available_job(npc):
				return true
	
	return false

# Try to pull a job from buildings and assign to TaskRunner
# This is called ONLY when entering work_at_building state (actual job creation)
func _try_pull_job() -> void:
	if not npc:
		return
	
	if not npc.task_runner:
		return
	
	# If already has a job, don't pull another
	if npc.task_runner.has_method("has_job") and npc.task_runner.has_job():
		return
	
	var npc_clan: String = npc.get_clan_name() if npc.has_method("get_clan_name") else ""
	if npc_clan == "":
		return
	
	# Check all buildings for available jobs
	var buildings = get_tree().get_nodes_in_group("buildings")
	var same_clan_count: int = 0
	var last_null_building: Node = null  # Last building whose generate_job returned null
	for building in buildings:
		if not is_instance_valid(building):
			continue
		if not "clan_name" in building:
			continue
		var building_clan: String = building.clan_name
		if building_clan != npc_clan:
			continue
		same_clan_count += 1
		# NOW use generate_job() - this is the actual job creation
		if building.has_method("generate_job"):
			var job = building.generate_job(npc)
			if job:
				# Pre-check: if first task is PickUpTask and NPC has no space, skip (prevents PickUpTask E)
				var first_task = job.get_current_task() if job.has_method("get_current_task") else null
				if first_task and first_task.get_script():
					var script_path: String = first_task.get_script().get_path().get_file()
					if script_path == "pick_up_task.gd" and npc.inventory and not npc.inventory.has_space():
						last_null_building = building  # Count as null for diagnostics
						continue  # Try next building
				# Found a job! Assign it to TaskRunner
				if npc.task_runner.has_method("assign_job"):
					npc.task_runner.assign_job(job)
					print("Task System: %s pulled job from %s (%d tasks)" % [
						npc.npc_name,
						ResourceData.get_resource_name(building.building_type) if "building_type" in building else "building",
						job.get_task_count() if job.has_method("get_task_count") else 0
					])
				return
			else:
				last_null_building = building
	# Optional debug: when woman-test has women idle, shows why no job was pulled (throttled)
	if same_clan_count > 0:
		var now := Time.get_ticks_msec() / 1000.0
		if now - _last_no_job_log_time >= NO_JOB_LOG_THROTTLE_SEC:
			_last_no_job_log_time = now
			var reason_str := ""
			var reason_raw := ""
			var building_name := "unknown"
			if last_null_building and last_null_building.has_method("get_last_job_failure_reason"):
				reason_raw = last_null_building.get_last_job_failure_reason()
				if reason_raw != "":
					reason_str = " (last reason: %s)" % reason_raw
				if "building_type" in last_null_building and ResourceData:
					building_name = ResourceData.get_resource_name(last_null_building.building_type)
			elif last_null_building == null:
				reason_raw = "no production buildings with generate_job"
				reason_str = " (no production buildings with generate_job)"
			print("Task System: %s found %d same-clan building(s) but no job%s" % [npc.npc_name, same_clan_count, reason_str])
			# Playtest instrumentation
			var pi = npc.get_node_or_null("/root/PlaytestInstrumentor")
			if pi and pi.has_method("is_enabled") and pi.is_enabled() and pi.has_method("task_no_job"):
				pi.task_no_job(npc.npc_name, building_name, reason_raw if reason_raw else "unknown", same_clan_count)
