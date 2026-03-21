extends Node
class_name DragManager

# Global singleton for managing drag-and-drop operations
# Tracks the currently dragged item and provides drag preview

signal drag_started(item_data: Dictionary, from_slot: InventorySlot)
signal drag_ended()
signal drop_completed(item_data: Dictionary, to_slot: InventorySlot)

var is_dragging: bool = false
var dragged_item: Dictionary = {}
var from_slot: InventorySlot = null
var drag_preview: Control = null
var invalid_overlay: Control = null  # Red X overlay for invalid placement
var drag_layer: CanvasLayer = null
var main_node: Node2D = null  # Reference to main node for world position checks
var is_over_world: bool = false  # Track if mouse is over world (not UI)
var building_preview_size: Vector2 = Vector2(64, 64)  # Default building size (native)
var is_placement_valid: bool = true  # Track if current placement position is valid

func _ready() -> void:
	# Create drag layer for preview
	drag_layer = CanvasLayer.new()
	drag_layer.name = "DragLayer"
	drag_layer.layer = 100  # Always on top
	get_tree().root.add_child(drag_layer)

func start_drag(slot: InventorySlot) -> void:
	if is_dragging:
		return
	
	var item = slot.get_item()
	if item.is_empty():
		return
	
	# Debug: Check if item type is valid
	var item_type = item.get("type", -1)
	if item_type == -1 or item_type == ResourceData.ResourceType.NONE:
		print("ERROR: Invalid item type in drag: ", item)
		return
	
	# When dragging a stacked item, only drag 1 item (not the whole stack)
	var item_count: int = item.get("count", 1) as int
	var dragged_item_copy: Dictionary = item.duplicate()
	
	if item_count > 1:
		# Only drag 1 item from the stack
		dragged_item_copy["count"] = 1
		
		# Reduce the stack in the source slot by 1
		var remaining_count: int = item_count - 1
		var updated_item: Dictionary = item.duplicate()
		updated_item["count"] = remaining_count
		slot.set_item(updated_item)
		
		# Update the inventory data
		var inventory_data = _get_inventory_data_for_slot(slot)
		if inventory_data:
			inventory_data.set_slot(slot.slot_index, updated_item)
	else:
		# Single item - clear the source slot
		slot.set_item({})
		var inventory_data = _get_inventory_data_for_slot(slot)
		if inventory_data:
			inventory_data.set_slot(slot.slot_index, {})
	
	# Log drag start
	var dragged_item_type = dragged_item_copy.get("type", -1)
	var item_name: String = ResourceData.get_resource_name(dragged_item_type) if dragged_item_type != -1 else "unknown"
	var slot_index: int = slot.slot_index if slot else -1
	UnifiedLogger.log_drag_drop("Drag started: %s (count: %d)" % [item_name, dragged_item_copy.get("count", 1)], {
		"item_type": dragged_item_type,
		"item_name": item_name,
		"count": dragged_item_copy.get("count", 1),
		"slot_index": slot_index
	})
	
	is_dragging = true
	dragged_item = dragged_item_copy
	from_slot = slot
	
	# Create drag preview
	_create_drag_preview(dragged_item)
	
	drag_started.emit(dragged_item, from_slot)

func end_drag(restore_item: bool = true) -> void:
	if not is_dragging:
		return
	
	# Check if this is a placeable building - if so, don't restore (placement will handle it)
	var item_type: ResourceData.ResourceType = dragged_item.get("type", ResourceData.ResourceType.NONE) as ResourceData.ResourceType
	var is_placeable_building: bool = (
		item_type == ResourceData.ResourceType.LANDCLAIM or
		item_type == ResourceData.ResourceType.LIVING_HUT or
		item_type == ResourceData.ResourceType.SUPPLY_HUT or
		item_type == ResourceData.ResourceType.SHRINE or
		item_type == ResourceData.ResourceType.DAIRY_FARM or
		item_type == ResourceData.ResourceType.FARM or
		item_type == ResourceData.ResourceType.OVEN
	)
	
	# For placeable buildings, skip restoration - let placement logic handle it
	# Only restore if explicitly requested or if not a placeable building
	if restore_item and not is_placeable_building:
		# Restore item to source slot if drag was cancelled (not completed)
		# Only restore if from_slot still exists and is valid
		if from_slot and is_instance_valid(from_slot):
			var inventory_data = _get_inventory_data_for_slot(from_slot)
			if inventory_data:
				# Get current slot data
				var current_slot_data = inventory_data.get_slot(from_slot.slot_index)
				
				# If slot is empty, restore the dragged item
				if current_slot_data.is_empty():
					from_slot.set_item(dragged_item)
					inventory_data.set_slot(from_slot.slot_index, dragged_item)
				else:
					# Slot has something - try to stack if same type
					var current_type = current_slot_data.get("type", -1)
					var dragged_type = dragged_item.get("type", -1)
					if current_type == dragged_type and inventory_data.can_stack:
						# Stack the items
						var current_count = current_slot_data.get("count", 1)
						var dragged_count = dragged_item.get("count", 1)
						var new_count = current_count + dragged_count
						if new_count <= inventory_data.max_stack:
							current_slot_data["count"] = new_count
							from_slot.set_item(current_slot_data)
							inventory_data.set_slot(from_slot.slot_index, current_slot_data)
						else:
							# Can't stack fully - restore to original slot
							from_slot.set_item(dragged_item)
							inventory_data.set_slot(from_slot.slot_index, dragged_item)
					else:
						# Different type or can't stack - restore to original slot (overwrites)
						from_slot.set_item(dragged_item)
						inventory_data.set_slot(from_slot.slot_index, dragged_item)
				
				# Update slot display
				if from_slot.is_hotbar:
					var player_ui = _get_player_inventory_ui()
					if player_ui:
						player_ui._update_hotbar_slots()
				else:
					var inventory_ui = _get_inventory_ui_for_slot(from_slot)
					if inventory_ui:
						inventory_ui._update_all_slots()
	
	if is_placeable_building:
		UnifiedLogger.log_drag_drop("Drag ended: placeable building (placement will handle removal)")
	else:
		UnifiedLogger.log_drag_drop("Drag ended: cancelled")
	
	is_dragging = false
	_remove_drag_preview()
	drag_ended.emit()
	
	# Clear references
	dragged_item = {}
	from_slot = null

func complete_drop(to_slot: InventorySlot) -> void:
	if not is_dragging:
		return
	
	# Log successful drop
	var item_type = dragged_item.get("type", -1)
	var item_name: String = ResourceData.get_resource_name(item_type) if item_type != -1 else "unknown"
	var slot_index: int = to_slot.slot_index if to_slot else -1
	UnifiedLogger.log_drag_drop("Drag ended: dropped - %s (count: %d) to slot %d" % [item_name, dragged_item.get("count", 1), slot_index], {
		"item_type": item_type,
		"item_name": item_name,
		"count": dragged_item.get("count", 1),
		"slot_index": slot_index
	})
	
	drop_completed.emit(dragged_item, to_slot)
	# Don't restore item when drop is completed (successful drop to slot)
	end_drag(false)

func cancel_drag() -> void:
	# For placeable buildings, don't restore - let placement logic handle it
	# For other items, restore to original slot
	var item_type: ResourceData.ResourceType = dragged_item.get("type", ResourceData.ResourceType.NONE) as ResourceData.ResourceType
	var is_placeable_building: bool = (
		item_type == ResourceData.ResourceType.LANDCLAIM or
		item_type == ResourceData.ResourceType.LIVING_HUT or
		item_type == ResourceData.ResourceType.SUPPLY_HUT or
		item_type == ResourceData.ResourceType.SHRINE or
		item_type == ResourceData.ResourceType.DAIRY_FARM or
		item_type == ResourceData.ResourceType.FARM or
		item_type == ResourceData.ResourceType.OVEN
	)
	end_drag(not is_placeable_building)

func _create_drag_preview(item: Dictionary) -> void:
	_remove_drag_preview()
	
	# Ensure drag_layer exists
	if not drag_layer:
		# Try to get it if _ready() hasn't run yet
		drag_layer = get_node_or_null("DragLayer")
		if not drag_layer:
			# Create it now
			drag_layer = CanvasLayer.new()
			drag_layer.name = "DragLayer"
			drag_layer.layer = 100  # Always on top
			if get_tree() and get_tree().root:
				get_tree().root.add_child.call_deferred(drag_layer)
			else:
				# Can't create, return
				return
	
	# Get main node reference for world position checks
	if not main_node:
		var main_nodes := get_tree().get_nodes_in_group("main")
		if main_nodes.size() > 0:
			main_node = main_nodes[0] as Node2D
	
	var item_type: ResourceData.ResourceType = item.get("type", ResourceData.ResourceType.NONE) as ResourceData.ResourceType
	var is_placeable_building: bool = (
		item_type == ResourceData.ResourceType.LANDCLAIM or
		item_type == ResourceData.ResourceType.LIVING_HUT or
		item_type == ResourceData.ResourceType.SUPPLY_HUT or
		item_type == ResourceData.ResourceType.SHRINE or
		item_type == ResourceData.ResourceType.DAIRY_FARM or
		item_type == ResourceData.ResourceType.FARM or
		item_type == ResourceData.ResourceType.OVEN
	)
	
	# Create preview sprite
	drag_preview = TextureRect.new()
	drag_preview.name = "DragPreview"
	drag_preview.custom_minimum_size = Vector2(32, 32)  # Start with icon size
	drag_preview.texture_filter = TextureRect.TEXTURE_FILTER_NEAREST
	drag_preview.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
	drag_preview.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	drag_preview.mouse_filter = Control.MOUSE_FILTER_IGNORE
	
	# Load texture - use building sprite if placeable, otherwise use icon
	var texture_path: String = ""
	if is_placeable_building:
		# For placeable buildings, load the actual building sprite
		match item_type:
			ResourceData.ResourceType.LANDCLAIM:
				texture_path = "res://assets/sprites/landclaim.png"
				building_preview_size = Vector2(128, 128)  # Land claim is 128px
			ResourceData.ResourceType.LIVING_HUT:
				texture_path = "res://assets/sprites/hut.png"
				building_preview_size = Vector2(64, 64)
			ResourceData.ResourceType.SUPPLY_HUT:
				texture_path = "res://assets/sprites/supply.png"
				building_preview_size = Vector2(64, 64)
			ResourceData.ResourceType.SHRINE:
				texture_path = "res://assets/sprites/shrine.png"
				building_preview_size = Vector2(64, 64)
			ResourceData.ResourceType.DAIRY_FARM:
				texture_path = "res://assets/sprites/dairy.png"
				building_preview_size = Vector2(64, 64)
			ResourceData.ResourceType.FARM:
				texture_path = "res://assets/sprites/farm1.png"
				building_preview_size = Vector2(64, 64)
			ResourceData.ResourceType.OVEN:
				texture_path = "res://assets/sprites/oven.png"
				building_preview_size = Vector2(64, 64)
	else:
		# For regular items, use icon
		texture_path = ResourceData.get_resource_icon_path(item_type)
	
	if texture_path != "":
		var loaded_texture: Texture2D = load(texture_path) as Texture2D
		if loaded_texture:
			drag_preview.texture = loaded_texture
		else:
			drag_preview.texture = _create_fallback_icon(item_type)
	else:
		drag_preview.texture = _create_fallback_icon(item_type)
	
	# Make semi-transparent
	drag_preview.modulate = Color(1, 1, 1, 0.8)
	
	# Create red X overlay for invalid placement (only for placeable buildings)
	if is_placeable_building:
		invalid_overlay = Control.new()
		invalid_overlay.name = "InvalidOverlay"
		invalid_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
		invalid_overlay.visible = false
		invalid_overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
		invalid_overlay.position = Vector2.ZERO
		
		# Create a red X using a Label with large X character
		var x_label := Label.new()
		x_label.name = "XLabel"
		x_label.text = "X"
		x_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		x_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		x_label.add_theme_color_override("font_color", Color.RED)
		x_label.add_theme_color_override("font_outline_color", Color.WHITE)
		x_label.add_theme_constant_override("outline_size", 12)
		x_label.add_theme_font_size_override("font_size", 96)  # Large font size
		
		# Make X label fill the overlay
		x_label.set_anchors_preset(Control.PRESET_FULL_RECT)
		x_label.position = Vector2.ZERO
		
		invalid_overlay.add_child(x_label)
		drag_preview.add_child(invalid_overlay)
	
	# Add child safely
	if drag_layer and is_instance_valid(drag_layer):
		if drag_layer.is_inside_tree():
			drag_layer.add_child(drag_preview)
		else:
			drag_layer.add_child.call_deferred(drag_preview)

func _remove_drag_preview() -> void:
	if drag_preview:
		drag_preview.queue_free()
		drag_preview = null
	invalid_overlay = null

func _process(_delta: float) -> void:
	if is_dragging and drag_preview:
		# Follow mouse
		var mouse_pos := get_viewport().get_mouse_position()
		
		# Check if we're dragging a placeable building
		var item_type: ResourceData.ResourceType = dragged_item.get("type", ResourceData.ResourceType.NONE) as ResourceData.ResourceType
		var is_placeable_building: bool = (
		item_type == ResourceData.ResourceType.LANDCLAIM or
		item_type == ResourceData.ResourceType.LIVING_HUT or
		item_type == ResourceData.ResourceType.SUPPLY_HUT or
		item_type == ResourceData.ResourceType.SHRINE or
		item_type == ResourceData.ResourceType.DAIRY_FARM or
		item_type == ResourceData.ResourceType.FARM or
		item_type == ResourceData.ResourceType.OVEN
	)
		
		# Check if mouse is over world (not UI)
		is_over_world = false
		if is_placeable_building and main_node:
			# Check if mouse is over UI using main node's function
			if main_node.has_method("_is_mouse_over_ui"):
				var over_ui: bool = main_node._is_mouse_over_ui(mouse_pos)
				is_over_world = not over_ui
		
		# Validate placement position if over world
		is_placement_valid = true
		if is_placeable_building and is_over_world and main_node:
			if main_node.has_method("_validate_building_placement"):
				var world_pos: Vector2 = main_node._get_world_mouse_position() if main_node.has_method("_get_world_mouse_position") else Vector2.ZERO
				is_placement_valid = main_node._validate_building_placement(world_pos, item_type)
		
		# Update preview size based on whether we're over world
		if is_placeable_building:
			if is_over_world:
				# Over world: show building size
				var target_size: Vector2 = building_preview_size
				if drag_preview.custom_minimum_size != target_size:
					# Animate size change
					var tween := drag_preview.create_tween()
					tween.tween_property(drag_preview, "custom_minimum_size", target_size, 0.2)
					tween.parallel().tween_property(drag_preview, "modulate", Color(1, 1, 1, 0.9), 0.2)
			else:
				# Over UI: show icon size
				var target_size: Vector2 = Vector2(32, 32)
				if drag_preview.custom_minimum_size != target_size:
					var tween := drag_preview.create_tween()
					tween.tween_property(drag_preview, "custom_minimum_size", target_size, 0.2)
					tween.parallel().tween_property(drag_preview, "modulate", Color(1, 1, 1, 0.8), 0.2)
		
		# Show/hide red X overlay based on placement validity
		if invalid_overlay and is_instance_valid(invalid_overlay):
			var should_show_x: bool = is_placeable_building and is_over_world and not is_placement_valid
			invalid_overlay.visible = should_show_x
			# Update overlay size to match preview (always update size, not just when showing)
			if is_placeable_building:
				var overlay_size: Vector2 = drag_preview.custom_minimum_size
				invalid_overlay.custom_minimum_size = overlay_size
				invalid_overlay.size = overlay_size
		
		# Center preview on mouse (account for size)
		var preview_size: Vector2 = drag_preview.custom_minimum_size
		drag_preview.position = mouse_pos - preview_size / 2.0

func _create_fallback_icon(item_type: ResourceData.ResourceType) -> Texture2D:
	var image := Image.create(32, 32, false, Image.FORMAT_RGBA8)
	var color := ResourceData.get_resource_color(item_type)
	image.fill(color)
	var texture := ImageTexture.create_from_image(image)
	return texture

func _get_inventory_data_for_slot(slot: InventorySlot) -> InventoryData:
	# Helper function to get the inventory data for a slot
	var main: Node = get_tree().get_first_node_in_group("main")
	if not main:
		return null
	
	# Check if it's a player inventory slot
	if main.has_method("get") and main.get("player_inventory_ui"):
		var player_ui = main.get("player_inventory_ui")
		if player_ui:
			if slot in player_ui.slots:
				return player_ui.inventory_data
			elif slot in player_ui.hotbar_slots:
				return player_ui.get_meta("hotbar_data", null) as InventoryData
	
	# Check if it's a building inventory slot
	if main.has_method("get") and main.get("building_inventory_ui"):
		var building_ui = main.get("building_inventory_ui")
		if building_ui and slot in building_ui.slots:
			return building_ui.inventory_data
	
	# Check if it's an NPC inventory slot
	if main.has_method("get") and main.get("npc_inventory_ui"):
		var npc_ui = main.get("npc_inventory_ui")
		if npc_ui and slot in npc_ui.slots:
			return npc_ui.inventory_data
	
	return null

func _get_player_inventory_ui() -> PlayerInventoryUI:
	var main: Node = get_tree().get_first_node_in_group("main")
	if not main:
		return null
	if main.has_method("get") and main.get("player_inventory_ui"):
		return main.get("player_inventory_ui") as PlayerInventoryUI
	return null

func _get_inventory_ui_for_slot(slot: InventorySlot) -> InventoryUI:
	var main: Node = get_tree().get_first_node_in_group("main")
	if not main:
		return null
	
	# Check player inventory
	if main.has_method("get") and main.get("player_inventory_ui"):
		var player_ui = main.get("player_inventory_ui") as PlayerInventoryUI
		if player_ui:
			if slot in player_ui.slots or slot in player_ui.hotbar_slots:
				return player_ui
	
	# Check building inventory
	if main.has_method("get") and main.get("building_inventory_ui"):
		var building_ui = main.get("building_inventory_ui") as BuildingInventoryUI
		if building_ui and slot in building_ui.slots:
			return building_ui
	
	# Check NPC inventory
	if main.has_method("get") and main.get("npc_inventory_ui"):
		var npc_ui = main.get("npc_inventory_ui") as NPCInventoryUI
		if npc_ui and slot in npc_ui.slots:
			return npc_ui
	
	return null
