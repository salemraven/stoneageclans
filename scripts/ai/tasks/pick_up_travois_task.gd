extends Task
class_name PickUpTravoisTask

const MoveToTaskScript = preload("res://scripts/ai/tasks/move_to_task.gd")

# NPC picks up a TravoisGround - transfers inventory to carried_travois_inventory, destroys node
# Assumes NPC is within range (use MoveToTask before this in a job)
# Travois can have items - we take the whole inventory

var travois: TravoisGround
var pickup_range: float = 50.0
var _move_task: Task = null
var _pickup_timer: float = 0.0
const PICKUP_DURATION: float = 0.5

func _init(tg: TravoisGround, range_dist: float = 50.0) -> void:
	travois = tg
	pickup_range = range_dist

func _start_impl(actor: Node) -> void:
	if not actor is NPCBase:
		status = TaskStatus.FAILED
		return
	var npc: NPCBase = actor as NPCBase
	if npc.has_travois():
		status = TaskStatus.FAILED  # Already carrying one
		return
	if not npc.hotbar:
		status = TaskStatus.FAILED
		return
	if not travois or not is_instance_valid(travois):
		status = TaskStatus.FAILED
		return
	# Reserve (or check not taken)
	if travois.carried_by != null and travois.carried_by != npc:
		status = TaskStatus.FAILED
		return
	travois.carried_by = npc
	status = TaskStatus.RUNNING

func _tick_impl(actor: Node, delta: float) -> TaskStatus:
	if not actor is NPCBase:
		return TaskStatus.FAILED
	var npc: NPCBase = actor as NPCBase
	if npc.should_abort_work():
		_release_reservation()
		return TaskStatus.FAILED
	if not travois or not is_instance_valid(travois):
		_release_reservation()
		return TaskStatus.FAILED
	# Move to range if needed
	var dist: float = npc.global_position.distance_to(travois.global_position)
	if dist > pickup_range:
		if not _move_task:
			_move_task = MoveToTaskScript.new(travois.global_position, pickup_range) as Task
			if _move_task:
				_move_task.start(actor)
		if _move_task:
			var move_status = _move_task.tick(actor, delta)
			if move_status == TaskStatus.RUNNING:
				return TaskStatus.RUNNING
			if move_status == TaskStatus.FAILED:
				_release_reservation()
				return TaskStatus.FAILED
	# In range - wait then pickup
	_pickup_timer += delta
	if _pickup_timer < PICKUP_DURATION:
		return TaskStatus.RUNNING
	# Transfer inventory to NPC
	npc.carried_travois_inventory = travois.inventory
	travois.inventory = null  # Detach so we don't double-free
	# Set hotbar slots 0+1 to TRAVOIS (2-handed)
	var travois_slot := {"type": ResourceData.ResourceType.TRAVOIS, "count": 1, "quality": 0}
	npc.hotbar.set_slot(0, travois_slot)
	npc.hotbar.set_slot(1, travois_slot)
	travois.carried_by = null
	travois.queue_free()
	return TaskStatus.SUCCESS

func _release_reservation() -> void:
	if travois and is_instance_valid(travois):
		travois.carried_by = null

func _cancel_impl(actor: Node) -> void:
	_release_reservation()
