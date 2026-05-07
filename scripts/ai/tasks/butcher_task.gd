extends Task
class_name ButcherTask

const MoveToTaskScript = preload("res://scripts/ai/tasks/move_to_task.gd")

## One timed slice from a corpse NPC (metadata meat_remaining / hide_remaining / bone_remaining).
## Returns SUCCESS after a single extraction (or corpse already empty → empty pull for another hunter).

var corpse: Node = null

var butcher_distance: float = 52.0
var butcher_duration: float = 1.0

var _slice_timer: float = 0.0
var _has_started_slice: bool = false
var _slice_start_position: Vector2 = Vector2.ZERO
var _move_cancel_threshold: float = 28.0
var _move_task: Task = null

func _init(corpse_node: Node, duration: float = 1.0, dist: float = 52.0) -> void:
	corpse = corpse_node
	butcher_duration = duration
	butcher_distance = dist


static func corpse_yield_total(corpse_node: Node) -> int:
	if not corpse_node or not is_instance_valid(corpse_node):
		return 0
	return int(corpse_node.get_meta("meat_remaining", 0)) + int(corpse_node.get_meta("hide_remaining", 0)) + int(corpse_node.get_meta("bone_remaining", 0))


func _start_impl(actor: Node) -> void:
	if not actor is NPCBase:
		status = TaskStatus.FAILED
		return

	var npc: NPCBase = actor as NPCBase
	if not corpse or not is_instance_valid(corpse):
		UnifiedLogger.log_npc("ButcherTask FAILED: corpse invalid at start", {"npc": npc.npc_name}, UnifiedLogger.Level.DEBUG)
		status = TaskStatus.FAILED
		return
	if corpse_yield_total(corpse) <= 0:
		_emit_empty(npc)
		status = TaskStatus.SUCCESS
		return

	if npc.should_abort_work():
		status = TaskStatus.FAILED
		return
	if not npc.inventory:
		status = TaskStatus.FAILED
		return
	if not npc.inventory.has_space():
		status = TaskStatus.FAILED
		return

	_slice_timer = 0.0
	_has_started_slice = false
	_move_task = null
	status = TaskStatus.RUNNING


func _tick_impl(actor: Node, delta: float) -> TaskStatus:
	if not actor is NPCBase:
		return TaskStatus.FAILED
	var npc: NPCBase = actor as NPCBase

	if corpse_yield_total(corpse) <= 0:
		_emit_empty(npc)
		return TaskStatus.SUCCESS

	if not corpse or not is_instance_valid(corpse):
		return TaskStatus.FAILED

	if npc.should_abort_work():
		return TaskStatus.FAILED
	if not npc.inventory:
		return TaskStatus.FAILED
	if not npc.inventory.has_space():
		return TaskStatus.FAILED

	var npc_pos: Vector2 = npc.global_position
	var corpse_pos: Vector2 = corpse.global_position
	var dist_to: float = npc_pos.distance_to(corpse_pos)

	if dist_to > butcher_distance:
		if not _move_task:
			_move_task = MoveToTaskScript.new(corpse_pos, butcher_distance) as Task
			if _move_task:
				_move_task.start(actor)
			else:
				return TaskStatus.FAILED
		var mv: TaskStatus = _move_task.tick(actor, delta)
		if mv == TaskStatus.RUNNING:
			return TaskStatus.RUNNING
		if mv == TaskStatus.FAILED:
			return TaskStatus.FAILED
		if corpse_yield_total(corpse) <= 0:
			_emit_empty(npc)
			return TaskStatus.SUCCESS

	if not _has_started_slice:
		_has_started_slice = true
		_slice_start_position = npc.global_position
		npc.set("is_gathering", true)
		npc.velocity = Vector2.ZERO
		if npc.steering_agent:
			npc.steering_agent.target_position = npc.global_position
			npc.steering_agent.target_node = null
		if npc.progress_display:
			var icon: Texture2D = null
			var icon_path: String = ResourceData.get_resource_icon_path(ResourceData.ResourceType.MEAT)
			if icon_path != "":
				icon = load(icon_path) as Texture2D
			npc.progress_display.start_collection(icon)
			npc.progress_display.collection_time = butcher_duration

	var moved_slice: float = npc.global_position.distance_to(_slice_start_position)
	if moved_slice > _move_cancel_threshold:
		npc.set("is_gathering", false)
		if npc.progress_display:
			npc.progress_display.stop_collection(true)
		return TaskStatus.FAILED

	npc.velocity = Vector2.ZERO
	if npc.steering_agent:
		npc.steering_agent.target_position = npc.global_position
		npc.steering_agent.target_node = null

	_slice_timer += delta
	if npc.progress_display:
		npc.progress_display.set_progress(_slice_timer / butcher_duration)

	if _slice_timer < butcher_duration:
		return TaskStatus.RUNNING

	# Finished one butcher tick — resolve one inventory unit (mirror player order meat → hide → bone)
	npc.set("is_gathering", false)
	if npc.progress_display:
		npc.progress_display.stop_collection(false)

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
		_emit_empty(npc)
		return TaskStatus.SUCCESS

	corpse.set_meta("last_butcher_time", Time.get_ticks_msec() / 1000.0)

	if not npc.inventory.add_item(took, 1):
		# Undo meta if bag full — let another hunter take it or leave on corpse
		if took == ResourceData.ResourceType.MEAT:
			corpse.set_meta("meat_remaining", meat_left)
		elif took == ResourceData.ResourceType.HIDE:
			corpse.set_meta("hide_remaining", hide_left)
		elif took == ResourceData.ResourceType.BONE:
			corpse.set_meta("bone_remaining", bone_left)
		return TaskStatus.SUCCESS  # Inventory full → stop chaining in hunt_state

	var prev_units: int = int(npc.get_meta("hunt_butcher_units", 0))
	npc.set_meta("hunt_butcher_units", prev_units + 1)
	match took:
		ResourceData.ResourceType.MEAT:
			npc.set_meta("hunt_loot_meat", int(npc.get_meta("hunt_loot_meat", 0)) + 1)
		ResourceData.ResourceType.HIDE:
			npc.set_meta("hunt_loot_hide", int(npc.get_meta("hunt_loot_hide", 0)) + 1)
		ResourceData.ResourceType.BONE:
			npc.set_meta("hunt_loot_bone", int(npc.get_meta("hunt_loot_bone", 0)) + 1)

	var tree = npc.get_tree()
	if tree:
		var dc = npc.get_node_or_null("/root/DebugConfig")
		if dc and dc.get("enable_hunt_butcher_debug") == true:
			print("[HUNT_BUTCHER] %s took %s from corpse (remain m=%d h=%d b=%d)" % [
				npc.npc_name,
				ResourceData.get_resource_name(took),
				int(corpse.get_meta("meat_remaining", 0)),
				int(corpse.get_meta("hide_remaining", 0)),
				int(corpse.get_meta("bone_remaining", 0)),
			])
		var pi = npc.get_node_or_null("/root/PlaytestInstrumentor")
		if pi and pi.is_enabled() and pi.has_method("hunt_butcher_extract"):
			var ctype: String = str(corpse.get("npc_type")) if corpse.get("npc_type") != null else "unknown"
			pi.hunt_butcher_extract(npc.npc_name, ctype, ResourceData.get_resource_name(took), int(took), 1)

	var mr: int = int(corpse.get_meta("meat_remaining", 0))
	var hr: int = int(corpse.get_meta("hide_remaining", 0))
	var br: int = int(corpse.get_meta("bone_remaining", 0))
	if mr <= 0 and hr <= 0 and br <= 0 and corpse.is_inside_tree():
		corpse.queue_free()

	return TaskStatus.SUCCESS


func _emit_empty(npc: NPCBase) -> void:
	var pi = npc.get_node_or_null("/root/PlaytestInstrumentor")
	if pi and pi.is_enabled() and pi.has_method("hunt_butcher_empty"):
		pi.hunt_butcher_empty(npc.npc_name)


func _cancel_impl(actor: Node) -> void:
	if actor is NPCBase:
		var npc: NPCBase = actor as NPCBase
		npc.set("is_gathering", false)
		if npc.progress_display:
			npc.progress_display.stop_collection(true)
	if _move_task:
		_move_task.cancel(actor)
	_move_task = null

