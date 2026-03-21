extends RefCounted
class_name Task

# Task System - Step 12
# Base class for all tasks. Tasks are atomic, reusable actions.
# Tasks are "dumb" - they don't know about modes, issuers, or intent.
# They can take parameters (target, resource, building) but not context.

# Task status enum
enum TaskStatus {
	RUNNING,  # Task is in progress
	SUCCESS,  # Task completed successfully
	FAILED    # Task failed and cannot continue
}

# Current status of this task
var status: TaskStatus = TaskStatus.RUNNING

# Whether the task has been started
var is_started: bool = false

# Whether the task has been cancelled
var is_cancelled: bool = false

# Start the task. Called once when task begins execution.
# @param actor: The NPC (or other entity) performing this task
func start(actor: Node) -> void:
	is_started = true
	is_cancelled = false
	status = TaskStatus.RUNNING
	_start_impl(actor)

# Update the task. Called every frame (or throttled) while task is running.
# @param actor: The NPC performing this task
# @param delta: Time since last frame
# @return: TaskStatus (RUNNING, SUCCESS, or FAILED)
func tick(actor: Node, delta: float) -> TaskStatus:
	if is_cancelled:
		status = TaskStatus.FAILED
		return status
	
	if status != TaskStatus.RUNNING:
		return status
	
	status = _tick_impl(actor, delta)
	return status

# Cancel the task. Called when task is interrupted (mode switch, agro, etc.)
# @param actor: The NPC performing this task
func cancel(actor: Node) -> void:
	if not is_started:
		return
	
	is_cancelled = true
	status = TaskStatus.FAILED
	_cancel_impl(actor)

# Virtual methods - subclasses must implement these

# Implementation of start() - subclasses override this
func _start_impl(actor: Node) -> void:
	# Default: no-op task succeeds immediately
	status = TaskStatus.SUCCESS

# Implementation of tick() - subclasses override this
# @return: TaskStatus (RUNNING, SUCCESS, or FAILED)
func _tick_impl(actor: Node, delta: float) -> TaskStatus:
	# Default: no-op task succeeds immediately
	return TaskStatus.SUCCESS

# Implementation of cancel() - subclasses override this
func _cancel_impl(actor: Node) -> void:
	# Default: no-op
	pass

# Helper to get status as string (for debugging)
func get_status_string() -> String:
	match status:
		TaskStatus.RUNNING:
			return "RUNNING"
		TaskStatus.SUCCESS:
			return "SUCCESS"
		TaskStatus.FAILED:
			return "FAILED"
		_:
			return "UNKNOWN"
