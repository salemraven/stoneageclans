extends RefCounted
class_name Job

# Task System - Step 14
# Job = ordered list of tasks. Data only; no logic.
# Jobs are created by buildings via generate_job(worker) and consumed by NPCs via TaskRunner.

# Ordered array of Task objects
var tasks: Array[Task] = []

# Current task index (which task we're on)
var current_index: int = 0

# Optional metadata (e.g. building, is_claimed)
var building: Node = null  # Building that generated this job
var is_claimed: bool = false  # Whether this job is claimed by a worker
var worker_id: int = 0  # worker.get_instance_id() - for releasing reservations when npc is invalid/dead

# Create a new job with a list of tasks
func _init(task_list: Array = []) -> void:
	tasks = []
	for task in task_list:
		if task is Task:
			tasks.append(task)
		else:
			push_error("Job: Non-Task object in task list: %s" % task)

# Add a task to the end of the job
func add_task(task: Task) -> void:
	if not task is Task:
		push_error("Job: Cannot add non-Task object")
		return
	tasks.append(task)

# Get the current task (the one that should be executed next)
func get_current_task() -> Task:
	if is_complete():
		return null
	if current_index >= tasks.size():
		return null
	return tasks[current_index]

# Advance to the next task
func advance() -> void:
	if not is_complete():
		current_index += 1

# Check if the job is complete (all tasks done)
func is_complete() -> bool:
	return current_index >= tasks.size()

# Reset the job to the beginning (for reuse or retry)
func reset() -> void:
	current_index = 0

# Get the number of tasks in this job
func get_task_count() -> int:
	return tasks.size()

# Get the number of remaining tasks
func get_remaining_task_count() -> int:
	return max(0, tasks.size() - current_index)

# Get progress as a string (for debugging)
func get_progress_string() -> String:
	if tasks.is_empty():
		return "0/0"
	return "%d/%d" % [current_index, tasks.size()]
