extends Task
class_name HutCarryTask
## Walk one stack for a specialty hut. Does not craft. Combat destroy is a meta flag set before cancel.

const MoveToScript = preload("res://scripts/ai/tasks/move_to_task.gd")
const HutCarryScript = preload("res://scripts/buildings/hut_carry.gd")
const HutSpecialtyScript = preload("res://scripts/buildings/hut_specialty.gd")

var building: Node = null
var claim: Node = null
var _phase: String = "start"
var _mover: Task = null
var _origin: Node = null
var _reserved_type: int = -1
var _reserved_qty: int = 0
var _stuck_since: float = -1.0
const STUCK_DROP_SEC := 2.0


func _init(hut: Node, land_claim: Node) -> void:
	building = hut
	claim = land_claim


func _start_impl(actor: Node) -> void:
	if not _alive(building) or not _alive(claim) or not (actor is NPCBase):
		status = TaskStatus.SUCCESS
		return
	var kind := str(building.get("hut_specialty"))
	var action := HutCarryScript.next_action(_inv(building), _inv(claim), kind, _other_reserved())
	if str(action["kind"]) == "none":
		status = TaskStatus.SUCCESS
		return
	if str(action["kind"]) == "input":
		_reserve(actor, action["type"], int(action["qty"]))
	_phase = "to_source"
	status = TaskStatus.RUNNING


func _tick_impl(actor: Node, delta: float) -> TaskStatus:
	if not HutSpecialtyScript.sim_authority_ok():
		if actor is NPCBase:
			_release(actor)
		return TaskStatus.SUCCESS
	if not (actor is NPCBase):
		return TaskStatus.FAILED
	var npc := actor as NPCBase
	_show_woman(npc)
	if not _alive(building):
		_release(npc)
		if _stack_count(npc) > 0:
			HutCarryScript.destroy_hands(npc)
		return TaskStatus.SUCCESS
	if str(building.get("hut_specialty")) == "":
		_release(npc)
		_put_back(npc)
		return TaskStatus.SUCCESS
	match _phase:
		"to_source":
			return _walk(npc, delta, _source_pos(), "pick")
		"pick":
			_hold(npc)
			return _pick(npc)
		"to_dest":
			return _walk(npc, delta, _dest_pos(), "drop")
		"drop":
			_hold(npc)
			return _drop(npc)
		"wait":
			_hold(npc)
			return _wait()
		"take":
			_hold(npc)
			return _take_product(npc)
		"to_claim":
			return _walk(npc, delta, _pos(claim), "drop_claim")
		"drop_claim":
			_hold(npc)
			return _drop_at(npc, claim, building)
		_:
			_release(npc)
			return TaskStatus.SUCCESS


func _cancel_impl(actor: Node) -> void:
	var npc: Node = actor
	_release(npc)
	if npc != null and npc.has_meta("hut_carry_destroy"):
		HutCarryScript.destroy_hands(npc)
		return
	_put_back(npc)


func _show_woman(npc: Node) -> void:
	if npc == null:
		return
	var shown := npc.get_node_or_null("Sprite")
	if shown:
		shown.visible = true


func controls_movement() -> bool:
	return _phase in ["to_source", "to_dest", "to_claim"]


func _hold(npc: NPCBase) -> void:
	npc.velocity = Vector2.ZERO
	npc.move_and_slide()


func _walk(npc: NPCBase, delta: float, pos: Vector2, next_phase: String) -> TaskStatus:
	if _mover == null:
		_mover = MoveToScript.new(pos, 28.0)
		_mover.start(npc)
	if _mover.tick(npc, delta) == TaskStatus.SUCCESS:
		_mover = null
		_phase = next_phase
	return TaskStatus.RUNNING


func _pick(npc: NPCBase) -> TaskStatus:
	var src := _source()
	var dest := _dest()
	if not _alive(src) or _inv(src) == null or npc.inventory == null:
		_release(npc)
		return TaskStatus.SUCCESS
	var kind := str(building.get("hut_specialty"))
	var action := HutCarryScript.next_action(_inv(building), _inv(claim), kind, _other_reserved())
	if str(action["kind"]) == "wait":
		_phase = "wait"
		return TaskStatus.RUNNING
	if str(action["kind"]) == "none":
		_release(npc)
		return TaskStatus.SUCCESS
	var item_type: ResourceData.ResourceType = action["type"]
	var have := _inv(src).get_count(item_type)
	if src == claim:
		var others := int(_other_reserved().get(int(item_type), 0))
		have = HutCarryScript.free_count(_inv(src), others, item_type)
	var qty := HutCarryScript.carry_qty(have, HutCarryScript.room_for(_inv(dest), item_type))
	qty = mini(qty, HutCarryScript.room_for(npc.inventory, item_type))
	if qty <= 0:
		_release(npc)
		return TaskStatus.SUCCESS
	if not _inv(src).remove_item(item_type, qty):
		_release(npc)
		return TaskStatus.SUCCESS
	if not npc.inventory.add_item(item_type, qty):
		_inv(src).add_item(item_type, qty)
		_release(npc)
		return TaskStatus.SUCCESS
	print("%s carrying %d %s for %s hut" % [npc.npc_name, qty, ResourceData.get_resource_name(item_type), kind])
	HutCarryScript._log_transfer("live", kind, int(item_type), qty, "pick")
	HutSpecialtyScript.publish_stock(building)
	_origin = src
	_release(npc)
	_mover = null
	_phase = "to_dest"
	return TaskStatus.RUNNING


func _drop(npc: NPCBase) -> TaskStatus:
	return _drop_at(npc, _dest(), _source())


func _drop_at(npc: NPCBase, dest: Node, back: Node) -> TaskStatus:
	if _stack_count(npc) <= 0:
		_after_drop(npc)
		return TaskStatus.RUNNING
	if not _alive(dest) or _inv(dest) == null:
		if _alive(back) and HutCarryScript.return_stack(npc.inventory, _inv(back)):
			_after_drop(npc)
			return TaskStatus.RUNNING
		HutCarryScript.destroy_hands(npc)
		return TaskStatus.SUCCESS
	var slot: Dictionary = npc.inventory.get_slot(0)
	var item_type: ResourceData.ResourceType = slot.get("type", ResourceData.ResourceType.NONE)
	var count: int = int(slot.get("count", 0))
	var fit := mini(count, HutCarryScript.room_for(_inv(dest), item_type))
	if fit <= 0:
		if _alive(back) and HutCarryScript.return_stack(npc.inventory, _inv(back)):
			_stuck_since = -1.0
			_after_drop(npc)
			return TaskStatus.RUNNING
		var now: float = Time.get_ticks_msec() / 1000.0
		if _stuck_since < 0.0:
			_stuck_since = now
			return TaskStatus.RUNNING
		if now - _stuck_since < STUCK_DROP_SEC:
			return TaskStatus.RUNNING
		_relieve_stuck(npc)
		return TaskStatus.SUCCESS
	if not npc.inventory.remove_item(item_type, fit):
		return TaskStatus.RUNNING
	if not _inv(dest).add_item(item_type, fit):
		npc.inventory.add_item(item_type, fit)
		return TaskStatus.RUNNING
	if _stack_count(npc) > 0:
		return TaskStatus.RUNNING
	HutCarryScript._log_transfer("live", str(building.get("hut_specialty")), int(item_type), fit, "drop")
	HutSpecialtyScript.publish_stock(building)
	_stuck_since = -1.0
	_after_drop(npc)
	return TaskStatus.RUNNING


func _after_drop(_npc: NPCBase) -> void:
	# Only the input she just put in the hut can start a wait. A product drop ends the walk.
	if _origin != claim:
		_phase = "done"
		return
	var kind := str(building.get("hut_specialty"))
	if HutSpecialtyScript.craft_can_commit(_inv(building), kind):
		_phase = "wait"
		return
	_phase = "done"


func _wait() -> TaskStatus:
	var kind := str(building.get("hut_specialty"))
	if kind == "":
		_phase = "done"
		return TaskStatus.RUNNING
	if kind == "crop":
		if _inv(building).get_count(ResourceData.ResourceType.GRAIN) > 0:
			_phase = "take"
		return TaskStatus.RUNNING
	if HutCarryScript._blocking_output(_inv(building), kind) != ResourceData.ResourceType.NONE or not HutSpecialtyScript.craft_can_commit(_inv(building), kind):
		_phase = "take"
		return TaskStatus.RUNNING
	return TaskStatus.RUNNING


func _take_product(npc: NPCBase) -> TaskStatus:
	var kind := str(building.get("hut_specialty"))
	var action := HutCarryScript.next_action(_inv(building), _inv(claim), kind, {})
	if str(action["kind"]) != "output":
		_phase = "done"
		return TaskStatus.RUNNING
	var item_type: ResourceData.ResourceType = action["type"]
	var qty := HutCarryScript.carry_qty(_inv(building).get_count(item_type), HutCarryScript.room_for(npc.inventory, item_type))
	qty = mini(qty, HutCarryScript.room_for(_inv(claim), item_type))
	if qty <= 0:
		_phase = "done"
		return TaskStatus.RUNNING
	if _inv(building).remove_item(item_type, qty) and npc.inventory.add_item(item_type, qty):
		print("%s carrying %d %s home from %s hut" % [npc.npc_name, qty, ResourceData.get_resource_name(item_type), kind])
		_origin = building
		_phase = "to_claim"
		return TaskStatus.RUNNING
	_phase = "done"
	return TaskStatus.RUNNING


func _relieve_stuck(npc: NPCBase) -> void:
	_release(npc)
	var result: Dictionary = HutCarryScript.unstick_hands(npc.inventory, _inv(building))
	if str(result.get("where", "")) == "ground":
		_drop_stack_on_ground(npc, int(result.get("type", 0)), int(result.get("qty", 0)))
	elif str(result.get("where", "")) == "hut":
		HutSpecialtyScript.publish_stock(building)
	_phase = "done"


func _drop_stack_on_ground(npc: Node2D, item_type: int, count: int) -> void:
	if count <= 0 or npc == null:
		return
	var tree: SceneTree = npc.get_tree()
	if tree == null:
		return
	var main: Node = tree.get_first_node_in_group("main")
	if main == null or not main.has_method("_spawn_ground_item"):
		return
	var pos: Vector2 = npc.global_position
	for _i in count:
		main.call("_spawn_ground_item", item_type as ResourceData.ResourceType, pos)


func _put_back(npc: Node) -> void:
	if npc == null or npc.get("inventory") == null:
		return
	if _alive(_origin) and _inv(_origin) != null:
		if HutCarryScript.return_stack(npc.inventory, _inv(_origin)):
			return
	if _stack_count(npc) > 0 and not _alive(_origin):
		HutCarryScript.destroy_hands(npc)


func _reserve(actor: Node, type: ResourceData.ResourceType, qty: int) -> void:
	if qty <= 0 or claim == null or not claim.has_method("reserve_items"):
		return
	if claim.reserve_items(actor, {int(type): qty}):
		_reserved_type = int(type)
		_reserved_qty = qty


func _release(npc: Node) -> void:
	if claim != null and is_instance_valid(claim) and npc != null and claim.has_method("release_items"):
		claim.release_items(npc)
	_reserved_qty = 0
	_reserved_type = -1


func _other_reserved() -> Dictionary:
	var out: Dictionary = {}
	if claim == null or not is_instance_valid(claim) or not claim.has_method("get_reserved_count"):
		return out
	var types: Array = [
		ResourceData.ResourceType.GRAIN, ResourceData.ResourceType.WOOD, ResourceData.ResourceType.HIDE,
		ResourceData.ResourceType.FIBER, ResourceData.ResourceType.WOOL, ResourceData.ResourceType.BREAD,
		ResourceData.ResourceType.LEATHER_SHEET, ResourceData.ResourceType.CORDAGE,
		ResourceData.ResourceType.FIBER_SHEET, ResourceData.ResourceType.WOOL_SHEET,
	]
	for type in types:
		var held: int = int(claim.get_reserved_count(type))
		if int(type) == _reserved_type:
			held -= _reserved_qty
		if held > 0:
			out[int(type)] = held
	return out


func _source() -> Node:
	var kind := str(building.get("hut_specialty"))
	var action := HutCarryScript.next_action(_inv(building), _inv(claim), kind, _other_reserved())
	if str(action["kind"]) == "output" or str(action["kind"]) == "wait":
		return building
	return claim


func _dest() -> Node:
	if _source() == building:
		return claim
	return building


func _source_pos() -> Vector2:
	var src: Node = _source()
	if src == claim and claim is Node2D and building is Node2D:
		return HutWomanWorkPresence.claim_approach_position(claim as Node2D, (building as Node2D).global_position)
	if src == building and building is Node2D:
		return HutWomanWorkPresence.hut_approach_position(building as Node2D)
	return _pos(src)


func _dest_pos() -> Vector2:
	var dest: Node = _dest()
	if dest == building and building is Node2D:
		return HutWomanWorkPresence.hut_approach_position(building as Node2D)
	if dest == claim and claim is Node2D and building is Node2D:
		return HutWomanWorkPresence.claim_approach_position(claim as Node2D, (building as Node2D).global_position)
	return _pos(dest)


func _pos(node: Node) -> Vector2:
	if node is Node2D:
		return (node as Node2D).global_position
	return Vector2.ZERO


func _inv(node: Node) -> InventoryData:
	if node == null or not is_instance_valid(node):
		return null
	return node.get("inventory") as InventoryData


func _stack_count(npc: Node) -> int:
	if npc == null or npc.get("inventory") == null:
		return 0
	var slot: Dictionary = (npc.get("inventory") as InventoryData).get_slot(0)
	return int(slot.get("count", 0)) if not slot.is_empty() else 0


func _alive(node: Node) -> bool:
	return node != null and is_instance_valid(node)
