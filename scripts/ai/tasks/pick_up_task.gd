extends Task
class_name PickUpTask

# Task System - Step 15
# Transfers an item from a source inventory to the NPC's inventory

# Source inventory (can be InventoryData or a Node with inventory property)
var source: Variant

# Resource type to pick up
var resource_type: ResourceData.ResourceType

# Amount to pick up
var amount: int = 1

# Internal state
var _picked_up: bool = false
var _pickup_timer: float = 0.0
const PICKUP_DURATION: float = 0.5  # Time to pick up item (makes it feel more deliberate)

func _init(src: Variant, res_type: ResourceData.ResourceType, amt: int = 1) -> void:
	source = src
	resource_type = res_type
	amount = amt

func _start_impl(actor: Node) -> void:
	if not actor is NPCBase:
		UnifiedLogger.log_npc("PickUpTask FAILED: actor not NPCBase", {"actor_type": actor.get_class() if actor else "null"}, UnifiedLogger.Level.DEBUG)
		status = TaskStatus.FAILED
		return
	
	var npc: NPCBase = actor as NPCBase
	if not npc.inventory:
		UnifiedLogger.log_npc("PickUpTask FAILED: %s has no inventory" % npc.npc_name, {"npc": npc.npc_name}, UnifiedLogger.Level.DEBUG)
		status = TaskStatus.FAILED
		return
	
	# Get source inventory
	var source_inventory: InventoryData = _get_source_inventory()
	if not source_inventory:
		UnifiedLogger.log_npc("PickUpTask FAILED: %s source inventory null (res_type=%d)" % [npc.npc_name, int(resource_type)], {"npc": npc.npc_name, "res_type": int(resource_type)}, UnifiedLogger.Level.DEBUG)
		status = TaskStatus.FAILED
		return
	
	# Check if source has the item
	if not source_inventory.has_item(resource_type, amount):
		var cnt := source_inventory.get_count(resource_type) if source_inventory.has_method("get_count") else -1
		UnifiedLogger.log_npc("PickUpTask FAILED: %s source lacks %s x%d (has: %d)" % [npc.npc_name, ResourceData.get_resource_name(resource_type), amount, cnt], {"npc": npc.npc_name, "needed": amount, "has": cnt}, UnifiedLogger.Level.DEBUG)
		status = TaskStatus.FAILED
		return
	
	# Check if NPC has space
	if not npc.inventory.has_space():
		UnifiedLogger.log_npc("PickUpTask FAILED: %s inventory full" % npc.npc_name, {"npc": npc.npc_name}, UnifiedLogger.Level.DEBUG)
		status = TaskStatus.FAILED
		return
	
	status = TaskStatus.RUNNING

func _tick_impl(actor: Node, delta: float) -> TaskStatus:
	if _picked_up:
		return TaskStatus.SUCCESS
	
	if not actor is NPCBase:
		return TaskStatus.FAILED
	
	var npc: NPCBase = actor as NPCBase
	
	if npc.should_abort_work():
		return TaskStatus.FAILED
	if source is Node and not is_instance_valid(source):
		return TaskStatus.FAILED
	if not npc.inventory:
		return TaskStatus.FAILED
	
	# Get source inventory
	var source_inventory: InventoryData = _get_source_inventory()
	if not source_inventory:
		return TaskStatus.FAILED
	
	# Wait for pickup duration before actually transferring
	_pickup_timer += delta
	if _pickup_timer < PICKUP_DURATION:
		return TaskStatus.RUNNING
	
	# Try to remove from source and add to NPC
	if source_inventory.remove_item(resource_type, amount):
		if npc.inventory.add_item(resource_type, amount):
			_picked_up = true
			
			# EDGE CASE FIX: If picking up from a building (transport job), clear transport reservation
			# This prevents duplicate transport jobs for the same bread
			if source is Node and "transport_reserved_by" in source:
				var building = source as Node
				if building.transport_reserved_by == npc:
					building.transport_reserved_by = null
					print("🔵 Transport reservation cleared (bread picked up)")
			
			# Partial release: when picking up from land claim, release consumed amount from reservation
			if source is Node and source.has_method("release_items_partial"):
				source.release_items_partial(npc, {int(resource_type): amount})
			
			return TaskStatus.SUCCESS
		else:
			# Failed to add to NPC - put it back in source
			source_inventory.add_item(resource_type, amount)
			return TaskStatus.FAILED
	else:
		return TaskStatus.FAILED

func _get_source_inventory() -> InventoryData:
	if source is InventoryData:
		return source as InventoryData
	elif source is Node:
		var node: Node = source as Node
		if "inventory" in node:
			return node.inventory as InventoryData
		elif node.has_method("get_inventory"):
			return node.get_inventory() as InventoryData
	return null

func _cancel_impl(_actor: Node) -> void:
	# If we picked up but task was cancelled, we could return the item
	# For now, just mark as cancelled
	pass
