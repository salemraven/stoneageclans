extends Task
class_name WaitTask

# Task System - Step 15
# Simple delay task - waits for a specified duration

# Duration to wait (seconds)
var duration: float = 1.0

# Internal state
var _elapsed_time: float = 0.0

func _init(wait_time: float) -> void:
	duration = wait_time

func _start_impl(actor: Node) -> void:
	_elapsed_time = 0.0
	status = TaskStatus.RUNNING

func _tick_impl(actor: Node, delta: float) -> TaskStatus:
	_elapsed_time += delta
	
	if _elapsed_time >= duration:
		return TaskStatus.SUCCESS
	
	return TaskStatus.RUNNING

func _cancel_impl(actor: Node) -> void:
	# No cleanup needed for wait task
	pass
