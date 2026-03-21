extends Task
class_name DropOffTask

const MoveToTaskScript = preload("res://scripts/ai/tasks/move_to_task.gd")

# Task System - Step 15
# Transfers an item from the NPC's inventory to a target inventory
# Also handles moving to the target if needed (within deposit range)

# Target inventory (can be InventoryData or a Node with inventory property)
var target: Variant

# Resource type to drop off
var resource_type: ResourceData.ResourceType

# Amount to drop off
var amount: int = 1

# Deposit range (pixels) - NPC must be within this distance to deposit
var deposit_range: float = 50.0

# Internal state
var _dropped_off: bool = false
var _move_task: Task = null  # MoveToTask instance (using Task base type to avoid compile-time dependency)
var _dropoff_timer: float = 0.0
const DROPOFF_DURATION: float = 0.5  # Time to drop off item (makes it feel more deliberate)

func _init(tgt: Variant, res_type: ResourceData.ResourceType, amt: int = 1, range_dist: float = 50.0) -> void:
	target = tgt
	resource_type = res_type
	amount = amt
	deposit_range = range_dist

func _start_impl(actor: Node) -> void:
	if not actor is NPCBase:
		var reason := "actor not NPCBase (%s)" % (str(actor.get_class()) if actor else "null")
		UnifiedLogger.log_npc("DropOffTask FAILED: %s" % reason, {"task": "drop_off"}, UnifiedLogger.Level.WARNING)
		status = TaskStatus.FAILED
		return
	
	var npc: NPCBase = actor as NPCBase
	if not npc.inventory:
		UnifiedLogger.log_npc("DropOffTask FAILED: %s inventory null" % npc.npc_name, {"npc": npc.npc_name}, UnifiedLogger.Level.WARNING)
		status = TaskStatus.FAILED
		return
	
	# Check if NPC has the item
	if not npc.inventory.has_item(resource_type, amount):
		var cnt := npc.inventory.get_count(resource_type) if npc.inventory.has_method("get_count") else -1
		var res_name := ResourceData.get_resource_name(resource_type) if ResourceData else str(resource_type)
		UnifiedLogger.log_npc("DropOffTask FAILED: %s lacks %d %s (has %d)" % [npc.npc_name, amount, res_name, cnt], {"npc": npc.npc_name, "resource": res_name, "needed": amount, "has": cnt}, UnifiedLogger.Level.WARNING)
		status = TaskStatus.FAILED
		return
	
	# Get target inventory
	var target_inventory: InventoryData = _get_target_inventory()
	if not target_inventory:
		UnifiedLogger.log_npc("DropOffTask FAILED: %s target has no inventory (%s)" % [npc.npc_name, str(target)], {"npc": npc.npc_name, "target": str(target)}, UnifiedLogger.Level.WARNING)
		status = TaskStatus.FAILED
		return
	
	# Check if target has space
	if not target_inventory.has_space():
		var used := target_inventory.get_used_slots() if target_inventory.has_method("get_used_slots") else -1
		UnifiedLogger.log_npc("DropOffTask FAILED: %s target full (%d/%d slots)" % [npc.npc_name, used, target_inventory.slot_count], {"npc": npc.npc_name, "target": str(target)}, UnifiedLogger.Level.WARNING)
		status = TaskStatus.FAILED
		return
	
	status = TaskStatus.RUNNING

func _tick_impl(actor: Node, delta: float) -> TaskStatus:
	if _dropped_off:
		return TaskStatus.SUCCESS
	
	if not actor is NPCBase:
		return TaskStatus.FAILED
	
	var npc: NPCBase = actor as NPCBase
	
	if npc.should_abort_work():
		UnifiedLogger.log_npc("DropOffTask FAILED: %s abort_work" % npc.npc_name, {"npc": npc.npc_name}, UnifiedLogger.Level.DEBUG)
		return TaskStatus.FAILED
	if target is Node and not is_instance_valid(target):
		return TaskStatus.FAILED
	if not npc.inventory:
		UnifiedLogger.log_npc("DropOffTask FAILED: %s inventory null (tick)" % npc.npc_name, {"npc": npc.npc_name}, UnifiedLogger.Level.WARNING)
		return TaskStatus.FAILED
	
	# Get target position (if target is a Node)
	var target_pos: Vector2 = _get_target_position()
	var npc_pos: Vector2 = npc.global_position
	var distance_to_target: float = npc_pos.distance_to(target_pos)
	
	# Check if we need to move closer
	if distance_to_target > deposit_range:
		# Create and run a MoveToTask to get within range
		if not _move_task:
			_move_task = MoveToTaskScript.new(target_pos, deposit_range) as Task
			if _move_task:
				_move_task.start(actor)
			else:
				return TaskStatus.FAILED
		
		var move_status = _move_task.tick(actor, delta)
		if move_status == TaskStatus.RUNNING:
			return TaskStatus.RUNNING
		elif move_status == TaskStatus.FAILED:
			UnifiedLogger.log_npc("DropOffTask FAILED: %s move_to_target failed" % npc.npc_name, {"npc": npc.npc_name, "distance": distance_to_target, "range": deposit_range}, UnifiedLogger.Level.WARNING)
			return TaskStatus.FAILED
		# If SUCCESS, continue to drop off
	
	# We're within range - wait for dropoff duration before actually transferring
	_dropoff_timer += delta
	if _dropoff_timer < DROPOFF_DURATION:
		return TaskStatus.RUNNING
	
	# Perform drop off
	var target_inventory: InventoryData = _get_target_inventory()
	if not target_inventory:
		UnifiedLogger.log_npc("DropOffTask FAILED: %s target_inventory null at transfer" % npc.npc_name, {"npc": npc.npc_name}, UnifiedLogger.Level.WARNING)
		return TaskStatus.FAILED
	
	# Try to remove from NPC and add to target
	var res_name := ResourceData.get_resource_name(resource_type) if ResourceData else str(resource_type)
	if npc.inventory.remove_item(resource_type, amount):
		if target_inventory.add_item(resource_type, amount):
			_dropped_off = true
			return TaskStatus.SUCCESS
		else:
			# Failed to add to target - put it back in NPC
			npc.inventory.add_item(resource_type, amount)
			UnifiedLogger.log_npc("DropOffTask FAILED: %s target add_item failed for %s" % [npc.npc_name, res_name], {"npc": npc.npc_name, "resource": res_name}, UnifiedLogger.Level.WARNING)
			return TaskStatus.FAILED
	else:
		UnifiedLogger.log_npc("DropOffTask FAILED: %s remove_item failed (race?)" % npc.npc_name, {"npc": npc.npc_name, "resource": res_name}, UnifiedLogger.Level.WARNING)
		return TaskStatus.FAILED

func _get_target_inventory() -> InventoryData:
	if target is InventoryData:
		return target as InventoryData
	elif target is Node:
		var node: Node = target as Node
		if "inventory" in node:
			return node.inventory as InventoryData
		elif node.has_method("get_inventory"):
			return node.get_inventory() as InventoryData
	return null

func _get_target_position() -> Vector2:
	if target is Node:
		return (target as Node).global_position
	# If target is InventoryData, we can't get position - use NPC's position as fallback
	return Vector2.ZERO

func _cancel_impl(actor: Node) -> void:
	if _move_task:
		_move_task.cancel(actor)
