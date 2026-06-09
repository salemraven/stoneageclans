extends Task
class_name ButcherCorpseTask

## Butcher slices until inventory threshold, bag full, or corpse empty — one trip to the corpse job site.

const MoveToTaskScript := preload("res://scripts/ai/tasks/move_to_task.gd")

var corpse: Node = null
var butcher_distance: float = 52.0
var butcher_duration: float = 1.0
var deposit_at_pct: float = 0.4

var _slice_timer: float = 0.0
var _has_started_slice: bool = false
var _slice_start_position: Vector2 = Vector2.ZERO
var _move_cancel_threshold: float = 28.0
var _move_task: Task = null


func _init(corpse_node: Node, duration: float = 1.0, dist: float = 52.0, dep_pct: float = 0.4) -> void:
	corpse = corpse_node
	butcher_duration = duration
	butcher_distance = dist
	deposit_at_pct = dep_pct


func _deposit_threshold(npc: NPCBase) -> int:
	var max_slots: int = npc.inventory.slot_count if npc.inventory else 5
	return maxi(2, int(ceil(float(max_slots) * deposit_at_pct)))


func _used_slots(npc: NPCBase) -> int:
	if not npc.inventory:
		return 0
	if npc.inventory.has_method("get_used_slots"):
		return int(npc.inventory.get_used_slots())
	return 0


func _corpse_yield_total() -> int:
	if not corpse or not is_instance_valid(corpse):
		return 0
	return int(corpse.get_meta("meat_remaining", 0)) + int(corpse.get_meta("hide_remaining", 0)) + int(corpse.get_meta("bone_remaining", 0))


func _corpse_empty() -> bool:
	return _corpse_yield_total() <= 0


func _start_impl(actor: Node) -> void:
	if not actor is NPCBase:
		status = TaskStatus.FAILED
		return
	var npc: NPCBase = actor as NPCBase
	if not corpse or not is_instance_valid(corpse) or _corpse_empty():
		status = TaskStatus.SUCCESS
		return
	if not npc.inventory or not npc.inventory.has_space():
		status = TaskStatus.SUCCESS
		return
	npc.set_meta("hunt_butchering", true)
	_slice_timer = 0.0
	_has_started_slice = false
	_move_task = null
	status = TaskStatus.RUNNING


func _tick_impl(actor: Node, delta: float) -> TaskStatus:
	if not actor is NPCBase:
		return TaskStatus.FAILED
	var npc: NPCBase = actor as NPCBase
	if _corpse_empty() or not corpse or not is_instance_valid(corpse):
		npc.set("is_gathering", false)
		if npc.progress_display:
			npc.progress_display.stop_collection(true)
		return TaskStatus.SUCCESS
	if not npc.inventory or not npc.inventory.has_space():
		return TaskStatus.SUCCESS
	if _used_slots(npc) >= _deposit_threshold(npc):
		return TaskStatus.SUCCESS

	var dist_to: float = npc.global_position.distance_to(corpse.global_position)
	if dist_to > butcher_distance:
		if not _move_task:
			_move_task = MoveToTaskScript.new(corpse.global_position, butcher_distance) as Task
			if _move_task:
				_move_task.start(actor)
			else:
				return TaskStatus.FAILED
		var mv: TaskStatus = _move_task.tick(actor, delta)
		if mv == TaskStatus.RUNNING:
			return TaskStatus.RUNNING
		if mv == TaskStatus.FAILED:
			return TaskStatus.FAILED

	if not _has_started_slice:
		_has_started_slice = true
		_slice_start_position = npc.global_position
		npc.set("is_gathering", true)
		npc.velocity = Vector2.ZERO
		if npc.steering_agent:
			npc.steering_agent.set_target_position(npc.global_position)
		if npc.progress_display:
			var icon_path: String = ResourceData.get_resource_icon_path(ResourceData.ResourceType.MEAT)
			var icon: Texture2D = load(icon_path) as Texture2D if icon_path != "" else null
			npc.progress_display.start_collection(icon, butcher_duration)

	if npc.global_position.distance_to(_slice_start_position) > _move_cancel_threshold:
		npc.set("is_gathering", false)
		if npc.progress_display:
			npc.progress_display.stop_collection(true)
		_has_started_slice = false
		return TaskStatus.RUNNING

	npc.velocity = Vector2.ZERO
	_slice_timer += delta
	if npc.progress_display:
		npc.progress_display.set_progress(_slice_timer / butcher_duration)
	if _slice_timer < butcher_duration:
		return TaskStatus.RUNNING

	npc.set("is_gathering", false)
	if npc.progress_display:
		npc.progress_display.stop_collection(false)
	_has_started_slice = false
	_slice_timer = 0.0
	_move_task = null

	var meat_left: int = int(corpse.get_meta("meat_remaining", 0))
	var hide_left: int = int(corpse.get_meta("hide_remaining", 0))
	var bone_left: int = int(corpse.get_meta("bone_remaining", 0))
	var took: ResourceData.ResourceType = ResourceData.ResourceType.NONE
	if meat_left > 0:
		corpse.set_meta("meat_remaining", meat_left - 1)
		took = ResourceData.ResourceType.MEAT
	elif hide_left > 0:
		corpse.set_meta("hide_remaining", hide_left - 1)
		took = ResourceData.ResourceType.HIDE
	elif bone_left > 0:
		corpse.set_meta("bone_remaining", bone_left - 1)
		took = ResourceData.ResourceType.BONE
	else:
		return TaskStatus.SUCCESS

	corpse.set_meta("last_butcher_time", Time.get_ticks_msec() / 1000.0)
	if not npc.inventory.add_item(took, 1):
		if took == ResourceData.ResourceType.MEAT:
			corpse.set_meta("meat_remaining", meat_left)
		elif took == ResourceData.ResourceType.HIDE:
			corpse.set_meta("hide_remaining", hide_left)
		elif took == ResourceData.ResourceType.BONE:
			corpse.set_meta("bone_remaining", bone_left)
		return TaskStatus.SUCCESS

	var prev_units: int = int(npc.get_meta("hunt_butcher_units", 0))
	npc.set_meta("hunt_butcher_units", prev_units + 1)
	match took:
		ResourceData.ResourceType.MEAT:
			npc.set_meta("hunt_loot_meat", int(npc.get_meta("hunt_loot_meat", 0)) + 1)
		ResourceData.ResourceType.HIDE:
			npc.set_meta("hunt_loot_hide", int(npc.get_meta("hunt_loot_hide", 0)) + 1)
		ResourceData.ResourceType.BONE:
			npc.set_meta("hunt_loot_bone", int(npc.get_meta("hunt_loot_bone", 0)) + 1)

	var pi = npc.get_node_or_null("/root/PlaytestInstrumentor")
	if pi and pi.is_enabled() and pi.has_method("hunt_butcher_extract"):
		var ctype: String = str(corpse.get("npc_type")) if corpse.get("npc_type") != null else "unknown"
		pi.hunt_butcher_extract(npc.npc_name, ctype, ResourceData.get_resource_name(took), int(took), 1)

	if _corpse_empty() and corpse.is_inside_tree():
		corpse.queue_free()

	if _corpse_empty() or not npc.inventory.has_space() or _used_slots(npc) >= _deposit_threshold(npc):
		return TaskStatus.SUCCESS
	return TaskStatus.RUNNING


func _cancel_impl(actor: Node) -> void:
	if actor is NPCBase:
		var npc: NPCBase = actor as NPCBase
		npc.set("is_gathering", false)
		if npc.progress_display:
			npc.progress_display.stop_collection(true)
		if npc.has_meta("hunt_butchering"):
			npc.remove_meta("hunt_butchering")
	if _move_task:
		_move_task.cancel(actor)
	_move_task = null
