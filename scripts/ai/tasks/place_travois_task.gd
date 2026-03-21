extends Task
class_name PlaceTravoisTask

const MoveToTaskScript = preload("res://scripts/ai/tasks/move_to_task.gd")

# NPC places carried travois at target position - spawns TravoisGround, transfers inventory, clears carried state
# Assumes NPC has carried_travois_inventory (use PickUpTravoisTask before this)

var target_position: Vector2
var place_range: float = 50.0
var _move_task: Task = null
var _place_timer: float = 0.0
const PLACE_DURATION: float = 0.5

const TRAVOIS_GROUND_SCENE = preload("res://scenes/TravoisGround.tscn")

func _init(pos: Vector2, range_dist: float = 50.0) -> void:
	target_position = pos
	place_range = range_dist

func _start_impl(actor: Node) -> void:
	if not actor is NPCBase:
		status = TaskStatus.FAILED
		return
	var npc: NPCBase = actor as NPCBase
	if not npc.has_travois():
		status = TaskStatus.FAILED
		return
	status = TaskStatus.RUNNING

func _tick_impl(actor: Node, delta: float) -> TaskStatus:
	if not actor is NPCBase:
		return TaskStatus.FAILED
	var npc: NPCBase = actor as NPCBase
	if npc.should_abort_work():
		return TaskStatus.FAILED
	if not npc.has_travois():
		return TaskStatus.FAILED
	# Move to range if needed
	var dist: float = npc.global_position.distance_to(target_position)
	if dist > place_range:
		if not _move_task:
			_move_task = MoveToTaskScript.new(target_position, place_range) as Task
			if _move_task:
				_move_task.start(actor)
		if _move_task:
			var move_status = _move_task.tick(actor, delta)
			if move_status == TaskStatus.RUNNING:
				return TaskStatus.RUNNING
			if move_status == TaskStatus.FAILED:
				return TaskStatus.FAILED
	# In range - wait then place
	_place_timer += delta
	if _place_timer < PLACE_DURATION:
		return TaskStatus.RUNNING
	# Spawn TravoisGround, transfer inventory
	var tg = TRAVOIS_GROUND_SCENE.instantiate()
	if not tg:
		return TaskStatus.FAILED
	var tg_node := tg as TravoisGround
	tg_node.global_position = target_position
	tg_node.inventory = npc.carried_travois_inventory
	npc.carried_travois_inventory = null
	# Clear hotbar slots 0+1
	if npc.hotbar:
		npc.hotbar.set_slot(0, {})
		npc.hotbar.set_slot(1, {})
	# Add to world
	var parent = npc.get_parent()
	if parent:
		parent.add_child(tg_node)
	else:
		return TaskStatus.FAILED
	return TaskStatus.SUCCESS

func _cancel_impl(_actor: Node) -> void:
	pass
