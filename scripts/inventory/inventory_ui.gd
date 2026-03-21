extends Control
class_name InventoryUI

# Base class for all inventory UIs (Player, Building, Cart)
# Handles slot creation, drag-and-drop, and visual updates

signal inventory_closed()
signal item_dropped(item_data: Dictionary, from_slot: InventorySlot, to_slot: InventorySlot)

var inventory_data: InventoryData = null
var slots: Array[InventorySlot] = []
var slot_container: Container = null
var drag_manager: Node = null

func _ready() -> void:
	# Get drag manager from autoload or create
	drag_manager = get_node_or_null("/root/DragManager")
	if not drag_manager:
		# Try to get from main scene
		var main: Node = get_tree().get_first_node_in_group("main")
		if main and main.has_method("get") and main.get("drag_manager"):
			drag_manager = main.drag_manager
	
	# Connect drag manager signals
	if drag_manager:
		if not drag_manager.drag_ended.is_connected(_on_drag_ended):
			drag_manager.drag_ended.connect(_on_drag_ended)
	
	# Enable input processing to catch mouse button release globally
	# This ensures we catch mouse release even when not over a slot
	set_process_input(true)

func setup(inventory: InventoryData) -> void:
	print("🔍 INVENTORY_UI: setup() called")
	print("   - inventory: %s (valid: %s)" % [inventory, inventory != null])
	
	if not inventory:
		print("❌ INVENTORY UI ERROR: setup() called with NULL inventory!")
		return
	
	var old_inventory = inventory_data
	inventory_data = inventory
	
	print("🔍 INVENTORY UI SETUP: Setting inventory_data from %s to %s (slot_count=%d)" % [old_inventory, inventory_data, inventory_data.slot_count if inventory_data else 0])
	print("   - Calling _build_slots() deferred...")
	call_deferred("_build_slots")
	print("   - Calling _update_all_slots() deferred...")
	call_deferred("_update_all_slots")
	print("✅ INVENTORY_UI: setup() completed")

func _build_slots() -> void:
	# Override in subclasses
	pass

func _update_all_slots() -> void:
	if not inventory_data:
		return
	
	# Safety check: ensure slots array matches inventory size
	if slots.size() != inventory_data.slot_count:
		return  # Slots not initialized yet
	
	for i in slots.size():
		if i >= slots.size() or i >= inventory_data.slot_count:
			break  # Safety check to prevent index out of bounds
		var slot_data: Dictionary = inventory_data.get_slot(i)
		if i < slots.size() and slots[i] and is_instance_valid(slots[i]):
			slots[i].set_item(slot_data)

func _on_slot_clicked(slot: InventorySlot) -> void:
	if not drag_manager:
		return
	
	# Only start drag if not already dragging
	if not drag_manager.is_dragging:
		if not slot.is_empty():
			# Start drag - item will follow mouse
			drag_manager.start_drag(slot)
			get_viewport().set_input_as_handled()

func _on_slot_drag_ended(_slot: InventorySlot) -> void:
	# Handle drop when mouse is released
	if not drag_manager or not drag_manager.is_dragging:
		return
	
	# Check if mouse is over this slot or any other slot
	var mouse_pos: Vector2 = get_viewport().get_mouse_position()
	
	# Check all slots to find which one the mouse is over
	for check_slot in slots:
		var slot_rect: Rect2 = Rect2(check_slot.get_global_rect())
		if slot_rect.has_point(mouse_pos):
			# Mouse is over this slot - drop here
			_handle_drop(check_slot)
			return
	
	# Mouse not over any slot - end drag (world drop handled in main.gd via drag_ended signal)
	drag_manager.end_drag()

func _input(event: InputEvent) -> void:
	# Global mouse button release handler for drag-and-drop
	if event is InputEventMouseButton:
		var mouse_event := event as InputEventMouseButton
		if mouse_event.button_index == MOUSE_BUTTON_LEFT and not mouse_event.pressed:
			# Mouse button released - check if we're dragging
			if drag_manager and drag_manager.is_dragging:
				# Check all slots to see if mouse is over any of them
				var mouse_pos: Vector2 = get_viewport().get_mouse_position()
				
				for check_slot in slots:
					var slot_rect: Rect2 = Rect2(check_slot.get_global_rect())
					if slot_rect.has_point(mouse_pos):
						# Mouse is over this slot - handle drop
						_handle_drop(check_slot)
						get_viewport().set_input_as_handled()
						return
				
				# Not over any slot in this inventory - let other inventories check
				# Don't end drag here, let the specific inventory UI handle it

func _on_drag_ended() -> void:
	# Check if drop was successful
	pass

func _handle_drop(target_slot: InventorySlot) -> void:
	if not drag_manager or not drag_manager.is_dragging:
		return
	
	# NPC inventory is read-only - prevent drops into it
	if self is NPCInventoryUI:
		# This is an NPC inventory - cancel the drop
		drag_manager.end_drag()
		return
	
	var dragged_item: Dictionary = drag_manager.dragged_item
	var from_slot: InventorySlot = drag_manager.from_slot
	
	if not from_slot:
		UnifiedLogger.log_drag_drop("Drop failed: no_from_slot", {}, UnifiedLogger.Level.DEBUG)
		return
	
	# Check if same slot
	if target_slot == from_slot:
		UnifiedLogger.log_drag_drop("Drop failed: same_slot", {}, UnifiedLogger.Level.DEBUG)
		return
	
	# Get target slot data
	var target_item: Dictionary = target_slot.get_item()
	
	# Handle stacking logic
	if not target_item.is_empty():
		# Target has item - check if can stack
		var target_type: ResourceData.ResourceType = target_item.get("type", -1) as ResourceData.ResourceType
		var dragged_type: ResourceData.ResourceType = dragged_item.get("type", -1) as ResourceData.ResourceType
		
		if target_type == dragged_type and inventory_data.can_stack:
			# Same type, try to stack
			var target_count: int = target_item.get("count", 1) as int
			var dragged_count: int = dragged_item.get("count", 1) as int
			var total: int = target_count + dragged_count
			
			if total <= inventory_data.max_stack:
				# Full stack
				target_item["count"] = total
				target_slot.set_item(target_item)
				inventory_data.set_slot(target_slot.slot_index, target_item)
				
				# Clear from slot
				from_slot.set_item({})
				# Update from inventory if it's different
				var from_inventory = _get_inventory_for_slot(from_slot)
				if from_inventory:
					from_inventory.set_slot(from_slot.slot_index, {})
				
				var item_type = dragged_item.get("type", -1)
				var item_name: String = ResourceData.get_resource_name(item_type) if item_type != -1 else "unknown"
				UnifiedLogger.log_drag_drop("Drop success: stacked_full - %s" % item_name, {
					"from_slot": from_slot.slot_index if from_slot else -1,
					"to_slot": target_slot.slot_index
				}, UnifiedLogger.Level.DEBUG)
				
				drag_manager.complete_drop(target_slot)
				item_dropped.emit(dragged_item, from_slot, target_slot)
				return
			else:
				# Partial stack
				var stack_amount: int = inventory_data.max_stack - target_count
				target_item["count"] = inventory_data.max_stack
				target_slot.set_item(target_item)
				inventory_data.set_slot(target_slot.slot_index, target_item)
				
				# Update dragged item
				dragged_item["count"] = dragged_count - stack_amount
				from_slot.set_item(dragged_item)
				# Update from inventory if it's different
				var from_inventory = _get_inventory_for_slot(from_slot)
				if from_inventory:
					from_inventory.set_slot(from_slot.slot_index, dragged_item)
				
				var item_type = dragged_item.get("type", -1)
				var item_name: String = ResourceData.get_resource_name(item_type) if item_type != -1 else "unknown"
				UnifiedLogger.log_drag_drop("Drop success: stacked_partial - %s" % item_name, {
					"from_slot": from_slot.slot_index if from_slot else -1,
					"to_slot": target_slot.slot_index
				}, UnifiedLogger.Level.DEBUG)
				
				drag_manager.complete_drop(target_slot)
				item_dropped.emit(dragged_item, from_slot, target_slot)
				return
	
	# Swap items
	var temp: Dictionary = target_item.duplicate()
	target_slot.set_item(dragged_item)
	inventory_data.set_slot(target_slot.slot_index, dragged_item)
	
	from_slot.set_item(temp)
	# Update from inventory if it's different
	var from_inventory = _get_inventory_for_slot(from_slot)
	if from_inventory:
		from_inventory.set_slot(from_slot.slot_index, temp)
	
	var item_type = dragged_item.get("type", -1)
	var item_name: String = ResourceData.get_resource_name(item_type) if item_type != -1 else "unknown"
	UnifiedLogger.log_drag_drop("Drop success: swapped - %s" % item_name, {
		"from_slot": from_slot.slot_index if from_slot else -1,
		"to_slot": target_slot.slot_index
	}, UnifiedLogger.Level.DEBUG)
	
	drag_manager.complete_drop(target_slot)
	item_dropped.emit(dragged_item, from_slot, target_slot)

func _get_inventory_for_slot(slot: InventorySlot) -> InventoryData:
	# Helper to find which inventory data a slot belongs to
	# This is needed for cross-inventory drops
	var parent = slot.get_parent()
	while parent:
		if parent.has_method("get") and parent.get("inventory_data"):
			return parent.get("inventory_data") as InventoryData
		parent = parent.get_parent()
	return null
