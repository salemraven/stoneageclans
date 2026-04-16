extends Node
class_name TaskRunner

# Task System - Step 13
# NPC component that holds current_job and current_task, runs tick loop,
# advances job on SUCCESS, clears on FAILED or cancel.

# Reference to the NPC this TaskRunner belongs to
var npc: Node2D = null

# Current job (Step 14: now using Job class)
var current_job: Job = null

# Current task being executed
var current_task: Task = null

# Whether the TaskRunner is active (running tasks)
var is_active: bool = false

func _ready() -> void:
	# Get NPC reference (parent should be the NPC)
	npc = get_parent() as Node2D
	if not npc:
		push_error("TaskRunner: Parent is not a Node2D (NPC)")
		set_physics_process(false)
		return
	
	set_physics_process(true)

func _physics_process(delta: float) -> void:
	if not is_active:
		return
	
	if not npc or not is_instance_valid(npc):
		# NPC is invalid, cancel everything
		cancel_current_job()
		return
	
	# Cancel tasks if NPC should abort work (defending, combat, or ordered follow)
	if npc is NPCBase and (npc as NPCBase).should_abort_work():
		cancel_current_job()
		return
	
	# If no current task, try to get next task from job
	if not current_task:
		_advance_to_next_task()
	
	# If still no task, job is complete or empty
	if not current_task:
		_clear_job()
		return
	
	# Lease expiry: cancel gather jobs that have exceeded their lease time
	if current_job and "expire_time" in current_job:
		var now: float = Time.get_ticks_msec() / 1000.0
		if now > current_job.expire_time:
			UnifiedLogger.log_npc("TaskRunner: Gather job lease expired - cancelling", {"npc": (npc as NPCBase).npc_name if npc is NPCBase else "unknown"}, UnifiedLogger.Level.DEBUG)
			cancel_current_job()
			return
	
	# Pre-validate job targets - fail early if building or land_claim became invalid
	if current_job and current_job.building and not is_instance_valid(current_job.building):
		if DebugConfig and DebugConfig.enable_debug_mode:
			UnifiedLogger.log_npc("TaskRunner: Job building invalid - cancelling", {"npc": (npc as NPCBase).npc_name if npc is NPCBase else "unknown"}, UnifiedLogger.Level.DEBUG)
		cancel_current_job()
		return
	var task_claim = current_task.get("land_claim")
	if task_claim != null and not is_instance_valid(task_claim):
		if DebugConfig and DebugConfig.enable_debug_mode:
			UnifiedLogger.log_npc("TaskRunner: Task land_claim invalid - cancelling", {"npc": (npc as NPCBase).npc_name if npc is NPCBase else "unknown"}, UnifiedLogger.Level.DEBUG)
		cancel_current_job()
		return
	
	# Run current task
	var status = current_task.tick(npc, delta)
	
	# DEBUG: Log task status
	var task_type = "unknown"
	if current_task.get_script():
		task_type = current_task.get_script().get_path().get_file()
	
	match status:
		Task.TaskStatus.RUNNING:
			# Task still running, continue next frame
			pass
		
		Task.TaskStatus.SUCCESS:
			# Task completed successfully, advance job to next task
			if DebugConfig and DebugConfig.enable_debug_mode:
				UnifiedLogger.log_npc("TaskRunner: Task %s (%s) completed SUCCESS" % [current_job.get_progress_string(), task_type], {"npc": (npc as NPCBase).npc_name if npc is NPCBase else "unknown"}, UnifiedLogger.Level.DEBUG)
			current_task = null
			if current_job:
				current_job.advance()
			# Will get next task on next frame
		
		Task.TaskStatus.FAILED:
			# Task failed, cancel job
			var npc_name: String = (npc as NPCBase).npc_name if npc is NPCBase else "unknown"
			UnifiedLogger.log_npc("TaskRunner: Task %s (%s) FAILED - cancelling job" % [current_job.get_progress_string(), task_type], {
				"npc": npc_name,
				"job_progress": current_job.get_progress_string(),
				"task_type": task_type
			}, UnifiedLogger.Level.WARNING)
			if current_task:
				current_task.cancel(npc)
			cancel_current_job()

# Assign a job to this TaskRunner
# @param job: Job object (Step 14: now using Job class)
func assign_job(job: Job) -> void:
	if not job:
		print("TaskRunner: Cannot assign null job")
		return
	
	if job.is_complete() or job.get_task_count() == 0:
		print("TaskRunner: Cannot assign empty or complete job")
		return
	
	# Cancel any existing job
	if is_active:
		cancel_current_job()
	
	current_job = job
	current_job.reset()  # Reset job to beginning
	current_job.worker_id = npc.get_instance_id() if npc else 0  # For release when npc invalid/dead
	current_task = null
	is_active = true
	
	# DEBUG: Log job structure
	var task_types = []
	for task in current_job.tasks:
		if task.get_script():
			task_types.append(task.get_script().get_path().get_file())
		else:
			task_types.append("no_script")
	
	if DebugConfig and DebugConfig.enable_debug_mode:
		UnifiedLogger.log_npc("TaskRunner: Assigned job with %d tasks: %s" % [current_job.get_task_count(), str(task_types)], {"npc": (npc as NPCBase).npc_name if npc is NPCBase else "unknown"}, UnifiedLogger.Level.DEBUG)

# Cancel the current job and all tasks
func cancel_current_job() -> void:
	if current_task:
		current_task.cancel(npc)
		current_task = null
	
	# RULE 2: Release resource slot when job is cancelled
	if current_job and "resource_node" in current_job:
		var resource = current_job.resource_node
		if resource and is_instance_valid(resource) and resource.has_method("release"):
			resource.release(npc)
	
	# Clear job reservations on building if job had a building reference
	if current_job and current_job.building and is_instance_valid(current_job.building):
		var building = current_job.building
		# Clear production job reservation
		if "job_reserved_by" in building:
			building.job_reserved_by = null
		# Clear transport job reservation
		if "transport_reserved_by" in building:
			building.transport_reserved_by = null
		# Release land claim item reservations (PickUpTask race prevention)
		if "land_claim" in building and building.land_claim and is_instance_valid(building.land_claim):
			if building.land_claim.has_method("release_items"):
				if npc and is_instance_valid(npc):
					building.land_claim.release_items(npc)
				elif current_job and current_job.worker_id != 0 and building.land_claim.has_method("release_items_by_id"):
					building.land_claim.release_items_by_id(current_job.worker_id)
	
	current_job = null
	is_active = false
	
	if DebugConfig and DebugConfig.enable_debug_mode:
		UnifiedLogger.log_npc("TaskRunner: Job cancelled", {"npc": (npc as NPCBase).npc_name if npc is NPCBase else "unknown"}, UnifiedLogger.Level.DEBUG)

# Clear the job (job completed successfully)
func _clear_job() -> void:
	# RULE 2: Release resource slot when job completes
	if current_job and "resource_node" in current_job:
		var resource = current_job.resource_node
		if resource and is_instance_valid(resource) and resource.has_method("release"):
			resource.release(npc)
	
	# Clear job reservations on building if job had a building reference
	if current_job and current_job.building and is_instance_valid(current_job.building):
		var building = current_job.building
		# Clear production job reservation
		if "job_reserved_by" in building:
			building.job_reserved_by = null
		# Clear transport job reservation
		if "transport_reserved_by" in building:
			building.transport_reserved_by = null
		# Release land claim item reservations (PickUpTask race prevention)
		if "land_claim" in building and building.land_claim and is_instance_valid(building.land_claim):
			if building.land_claim.has_method("release_items"):
				if npc and is_instance_valid(npc):
					building.land_claim.release_items(npc)
				elif current_job and current_job.worker_id != 0 and building.land_claim.has_method("release_items_by_id"):
					building.land_claim.release_items_by_id(current_job.worker_id)
	
	current_job = null
	current_task = null
	is_active = false
	
	if DebugConfig and DebugConfig.enable_debug_mode:
		UnifiedLogger.log_npc("TaskRunner: Job completed and cleared", {"npc": (npc as NPCBase).npc_name if npc is NPCBase else "unknown"}, UnifiedLogger.Level.DEBUG)

# Advance to the next task in the job
func _advance_to_next_task() -> void:
	if not current_job:
		return
	
	if current_job.is_complete():
		_clear_job()
		return
	
	# Get current task from job
	var next_task = current_job.get_current_task()
	if not next_task:
		_clear_job()
		return
	
	current_task = next_task
	
	# DEBUG: Log task type
	var task_type = "unknown"
	if current_task.get_script():
		task_type = current_task.get_script().get_path().get_file()
	
	# Pre-validate resource_node for GatherTask: fail job early if resource was freed
	if current_job and "resource_node" in current_job:
		var res = current_job.resource_node
		if not res or not is_instance_valid(res):
			if DebugConfig and DebugConfig.enable_debug_mode:
				UnifiedLogger.log_npc("TaskRunner: Skipping task %s - resource_node invalid (freed)" % task_type, {"npc": (npc as NPCBase).npc_name if npc is NPCBase else "unknown"}, UnifiedLogger.Level.DEBUG)
			cancel_current_job()
			return
	
	# Pre-validate for PickUpTask: NPC must have inventory space (prevents PickUpTask E)
	if task_type == "pick_up_task.gd" and npc and npc.inventory and not npc.inventory.has_space():
		if DebugConfig and DebugConfig.enable_debug_mode:
			UnifiedLogger.log_npc("TaskRunner: Skipping task %s - npc inventory full" % task_type, {"npc": (npc as NPCBase).npc_name if npc is NPCBase else "unknown"}, UnifiedLogger.Level.DEBUG)
		cancel_current_job()
		return
	
	if DebugConfig and DebugConfig.enable_debug_mode:
		UnifiedLogger.log_npc("TaskRunner: Starting task %s (%s)" % [current_job.get_progress_string(), task_type], {"npc": (npc as NPCBase).npc_name if npc is NPCBase else "unknown"}, UnifiedLogger.Level.DEBUG)
	
	# Start the task
	current_task.start(npc)
	
	# DEBUG: Check task status after start
	var task_status_after_start = current_task.status
	if DebugConfig and DebugConfig.enable_debug_mode:
		UnifiedLogger.log_npc("TaskRunner: Task %s status after start(): %s" % [task_type, Task.TaskStatus.keys()[task_status_after_start] if task_status_after_start < Task.TaskStatus.keys().size() else "UNKNOWN"], {"npc": (npc as NPCBase).npc_name if npc is NPCBase else "unknown"}, UnifiedLogger.Level.DEBUG)

# Check if there's an active job
func has_job() -> bool:
	return is_active and current_job != null and not current_job.is_complete()

# True when current task is KnapTask (NPC must stay still while knapping)
func is_current_task_knap() -> bool:
	if not current_task or not current_task.get_script():
		return false
	var path: String = current_task.get_script().get_path()
	return path.ends_with("knap_task.gd")

# True when current task directly controls NPC movement (MoveToTask or DropOffTask moving) - skip steering
func controls_movement() -> bool:
	if not is_active or not current_task or not current_task.get_script():
		return false
	var script_path: String = current_task.get_script().get_path().get_file()
	if script_path == "move_to_task.gd":
		return true
	if script_path == "drop_off_task.gd":
		# DropOffTask creates internal MoveToTask when too far - task controls velocity
		return current_task.get("_move_task") != null
	return false

# Get current task status (for debugging)
func get_status_string() -> String:
	if not is_active:
		return "IDLE"
	if not current_task:
		return "NO_TASK"
	return "RUNNING: %s" % current_task.get_status_string()
