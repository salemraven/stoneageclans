extends InventoryUI
class_name PlayerInventoryUI

const CraftRegistryScript = preload("res://scripts/config/craft_registry.gd")
const ProgressPieOverlay = preload("res://scripts/ui/progress_pie_overlay.gd")

# Player inventory: 10 vertical slots + 4-slot hotbar at bottom
# No stacking, centered panel 320x480

const SLOT_COUNT := 5  # Main inventory slots (reduced from 10 per UI.md spec)
const HOTBAR_COUNT := 10  # Equipment hotbar: 1=right hand, 2=left hand, 3=head, 4=body, 5=legs, 6=feet, 7=neck, 8=backpack, 9=consumable, 0=consumable
const RIGHT_HAND_SLOT_INDEX := 0   # Slot 1 (right hand) = index 0 — primary weapon (axe/pick)
const LEFT_HAND_SLOT_INDEX := 1    # Slot 2 (left hand) = index 1
const SLOT_SIZE := 32
const PANEL_WIDTH := 320
const PANEL_HEIGHT := 444  # Inventory slots + craft icons (32 + 8 separation) below
const HOTBAR_HEIGHT := 64  # Just enough for 32x32 slots with padding (no labels below)
const HUNGER_BAR_HEIGHT := 12  # 8px bar + 4px separation (above hotbar)
const HEALTH_BAR_UPDATE_INTERVAL: int = 5  # Throttle hunger bar updates (match building_base)
const CRAFT_ICON_SIZE := 32
const CRAFT_ICON_SPACING := 4

var inventory_panel: Panel = null
var hotbar_panel: Panel = null  # Always visible, separate from inventory
var inventory_container: VBoxContainer = null
var hotbar_container: HBoxContainer = null

var hotbar_slots: Array[InventorySlot] = []
var hunger_bar: Control = null
var _hunger_bar_update_frame: int = 0
var craft_icons_container: HBoxContainer = null
var craft_icons: Array[Control] = []
var is_open: bool = false
var _active_craft_overlay: ProgressPieOverlay = null
var _active_craft_data: CraftRegistryScript.CraftData = null

func _ready() -> void:
	super._ready()
	
	# Create inventory data (5 slots, no stacking) - reduced from 10 per UI.md spec
	inventory_data = InventoryData.new(SLOT_COUNT, false, 1)
	
	# Setup panels
	_setup_panels()
	
	# Build slots (use call_deferred to ensure nodes are ready)
	call_deferred("_build_slots")
	
	# Hotbar is always visible, inventory starts hidden
	inventory_panel.visible = false
	hotbar_panel.visible = true
	
	# Enable input processing for global mouse release detection
	set_process_input(true)

func _setup_panels() -> void:
	# Main inventory panel (centered, semi-transparent)
	if not has_node("InventoryPanel"):
		inventory_panel = Panel.new()
		inventory_panel.name = "InventoryPanel"
		add_child(inventory_panel)
	
	inventory_panel.custom_minimum_size = Vector2(PANEL_WIDTH, PANEL_HEIGHT)
	
	# Style inventory panel using UITheme
	UITheme.apply_panel_style(inventory_panel)
	
	# Inventory panel positioning is handled in _ready() after root control setup
	# (Positioned in center, offset up to avoid hotbar - see _ready() function)
	
	# Slot container with padding; craft icons directly below inventory
	if not inventory_panel.has_node("MarginContainer"):
		var margin: MarginContainer = MarginContainer.new()
		margin.name = "MarginContainer"
		margin.add_theme_constant_override("margin_left", 8)
		margin.add_theme_constant_override("margin_top", 8)
		margin.add_theme_constant_override("margin_right", 8)
		margin.add_theme_constant_override("margin_bottom", 8)
		inventory_panel.add_child(margin)
		
		var inventory_vbox: VBoxContainer = VBoxContainer.new()
		inventory_vbox.name = "InventoryVBox"
		inventory_vbox.add_theme_constant_override("separation", 8)
		margin.add_child(inventory_vbox)
		
		inventory_container = VBoxContainer.new()
		inventory_container.name = "SlotContainer"
		inventory_container.add_theme_constant_override("separation", 0)  # No spacing between slots
		inventory_vbox.add_child(inventory_container)
		
		craft_icons_container = HBoxContainer.new()
		craft_icons_container.name = "CraftIconsContainer"
		craft_icons_container.add_theme_constant_override("separation", CRAFT_ICON_SPACING)
		inventory_vbox.add_child(craft_icons_container)
	
	# Hotbar panel (always visible at bottom)
	if not has_node("HotbarPanel"):
		hotbar_panel = Panel.new()
		hotbar_panel.name = "HotbarPanel"
		add_child(hotbar_panel)
	
	# Calculate hotbar width: 10 slots * 32px + spacing + padding (accounting for labels)
	var hotbar_width: float = (HOTBAR_COUNT * 32) + ((HOTBAR_COUNT - 1) * 6) + 24  # 6px spacing, 12px padding each side
	hotbar_panel.custom_minimum_size = Vector2(hotbar_width, HOTBAR_HEIGHT + HUNGER_BAR_HEIGHT)
	
	# Style hotbar using UITheme
	UITheme.apply_panel_style(hotbar_panel)
	
	# Position hotbar at very bottom of screen, almost touching bottom edge
	hotbar_panel.anchors_preset = Control.PRESET_BOTTOM_WIDE
	hotbar_panel.anchor_left = 0.5
	hotbar_panel.anchor_top = 1.0
	hotbar_panel.anchor_right = 0.5
	hotbar_panel.anchor_bottom = 1.0
	hotbar_panel.offset_left = -hotbar_width / 2.0  # Center horizontally
	hotbar_panel.offset_top = -HOTBAR_HEIGHT - HUNGER_BAR_HEIGHT - 8  # 8px from bottom edge
	hotbar_panel.offset_right = hotbar_width / 2.0
	hotbar_panel.offset_bottom = -8
	
	# Hotbar container with padding; hunger bar above slots
	if not hotbar_panel.has_node("MarginContainer"):
		var hotbar_margin: MarginContainer = MarginContainer.new()
		hotbar_margin.name = "MarginContainer"
		hotbar_margin.add_theme_constant_override("margin_left", 12)
		hotbar_margin.add_theme_constant_override("margin_top", 12)
		hotbar_margin.add_theme_constant_override("margin_right", 12)
		hotbar_margin.add_theme_constant_override("margin_bottom", 12)
		hotbar_panel.add_child(hotbar_margin)
		
		var hotbar_vbox: VBoxContainer = VBoxContainer.new()
		hotbar_vbox.name = "HotbarVBox"
		hotbar_vbox.add_theme_constant_override("separation", 4)
		
		# Hunger bar (above hotbar slots, same pattern as building health bar)
		hunger_bar = Control.new()
		hunger_bar.name = "HungerBar"
		hunger_bar.custom_minimum_size = Vector2(80, 8)
		hunger_bar.size = Vector2(80, 8)
		var hunger_bg: ColorRect = ColorRect.new()
		hunger_bg.name = "Background"
		hunger_bg.color = Color(0.3, 0.0, 0.0, 0.8)
		hunger_bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		hunger_bar.add_child(hunger_bg)
		var hunger_fill: ColorRect = ColorRect.new()
		hunger_fill.name = "HungerFill"
		hunger_fill.color = Color(0.0, 1.0, 0.0, 0.8)
		hunger_fill.set_anchors_preset(Control.PRESET_TOP_LEFT)
		hunger_fill.position = Vector2(0, 0)
		hunger_fill.size = Vector2(80, 8)
		hunger_bar.add_child(hunger_fill)
		hotbar_vbox.add_child(hunger_bar)
		
		hotbar_container = HBoxContainer.new()
		hotbar_container.name = "SlotContainer"
		hotbar_container.add_theme_constant_override("separation", 6)
		hotbar_vbox.add_child(hotbar_container)
		hotbar_margin.add_child(hotbar_vbox)
	
	# Root control setup - center inventory panel, hotbar is positioned independently
	# Make root control fill screen but don't interfere with hotbar positioning
	custom_minimum_size = Vector2(PANEL_WIDTH, PANEL_HEIGHT)
	anchors_preset = Control.PRESET_FULL_RECT
	anchor_left = 0.0
	anchor_top = 0.0
	anchor_right = 1.0
	anchor_bottom = 1.0
	offset_left = 0.0
	offset_top = 0.0
	offset_right = 0.0
	offset_bottom = 0.0
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	
	# Position inventory panel in center of screen (above hotbar area)
	inventory_panel.anchors_preset = Control.PRESET_CENTER
	inventory_panel.anchor_left = 0.5
	inventory_panel.anchor_top = 0.5
	inventory_panel.anchor_right = 0.5
	inventory_panel.anchor_bottom = 0.5
	inventory_panel.offset_left = -PANEL_WIDTH / 2.0
	inventory_panel.offset_top = -PANEL_HEIGHT / 2.0 - 120  # Offset up to leave room for hotbar
	inventory_panel.offset_right = PANEL_WIDTH / 2.0
	inventory_panel.offset_bottom = PANEL_HEIGHT / 2.0 - 120

func _build_slots() -> void:
	# Ensure containers exist - create them if needed
	if not inventory_container:
		if inventory_panel:
			var margin = inventory_panel.get_node_or_null("MarginContainer")
			var vbox = margin.get_node_or_null("InventoryVBox") if margin else null
			var parent = vbox if vbox else margin
			if parent and parent.has_node("SlotContainer"):
				inventory_container = parent.get_node("SlotContainer") as VBoxContainer
			elif margin:
				inventory_container = VBoxContainer.new()
				inventory_container.name = "SlotContainer"
				inventory_container.add_theme_constant_override("separation", 0)
				margin.add_child(inventory_container)
	
	if not hotbar_container:
		if hotbar_panel:
			var margin = hotbar_panel.get_node_or_null("MarginContainer")
			if margin and margin.has_node("SlotContainer"):
				hotbar_container = margin.get_node("SlotContainer") as HBoxContainer
			elif margin:
				hotbar_container = HBoxContainer.new()
				hotbar_container.name = "SlotContainer"
				hotbar_container.add_theme_constant_override("separation", 6)
				margin.add_child(hotbar_container)
	
	if not inventory_container or not hotbar_container:
		print("ERROR: Failed to create inventory containers")
		return
	
	# Clear existing
	for slot in slots:
		if is_instance_valid(slot):
			slot.queue_free()
	slots.clear()
	for slot in hotbar_slots:
		if is_instance_valid(slot):
			slot.queue_free()
	hotbar_slots.clear()
	
	# Create inventory slots
	for i in SLOT_COUNT:
		var slot: InventorySlot = InventorySlot.new()
		slot.slot_index = i
		slot.is_hotbar = false
		slot.can_stack = false
		# Make slots expand horizontally to fill available width
		slot.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		if not slot.slot_clicked.is_connected(_on_slot_clicked):
			slot.slot_clicked.connect(_on_slot_clicked)
		if not slot.slot_drag_ended.is_connected(_on_slot_drag_ended):
			slot.slot_drag_ended.connect(_on_slot_drag_ended)
		inventory_container.add_child(slot)
		slots.append(slot)
	
	# Create hotbar slots with large transparent numbers in center
	# Equipment slots: 1=right hand, 2=left hand, 3=head, 4=body, 5=legs, 6=feet, 7=neck, 8=backpack
	# Consumable slots: 9=consumable, 0=consumable (only these two are consumables)
	# Slot numbers: index 0-8 = "1"-"9", index 9 = "0"
	for i in HOTBAR_COUNT:
		# Create slot
		var slot: InventorySlot = InventorySlot.new()
		slot.slot_index = i
		slot.is_hotbar = true
		slot.can_stack = false
		# Set slot number for display: 0-8 show "1"-"9", 9 shows "0"
		var slot_number: String = str((i + 1) % 10)  # 1-9 for indices 0-8, 0 for index 9
		slot.set_meta("slot_number", slot_number)
		if not slot.slot_clicked.is_connected(_on_slot_clicked):
			slot.slot_clicked.connect(_on_slot_clicked)
		if not slot.slot_drag_ended.is_connected(_on_slot_drag_ended):
			slot.slot_drag_ended.connect(_on_slot_drag_ended)
		hotbar_container.add_child(slot)
		hotbar_slots.append(slot)
	
	# Create hotbar data (separate inventory for hotbar)
	if not has_meta("hotbar_data"):
		var hotbar_data: InventoryData = InventoryData.new(HOTBAR_COUNT, false, 1)
		# Store as metadata for now - we'll handle hotbar separately
		set_meta("hotbar_data", hotbar_data)
	
	# Build craft icons (above hotbar)
	_build_craft_icons()
	
	# Update displays
	_update_all_slots()
	_update_hotbar_slots()

func _process(_delta: float) -> void:
	# Throttle hunger bar updates (match building health bar)
	if not hunger_bar:
		return
	_hunger_bar_update_frame += 1
	if _hunger_bar_update_frame >= HEALTH_BAR_UPDATE_INTERVAL:
		_hunger_bar_update_frame = 0
		_update_hunger_bar()

func _update_hunger_bar() -> void:
	if not hunger_bar:
		return
	var fill: ColorRect = hunger_bar.get_node_or_null("HungerFill") as ColorRect
	if not fill:
		return
	var main_node = get_tree().get_first_node_in_group("main")
	if not main_node or not main_node.get("player"):
		return
	var p = main_node.player
	if not p or not p.get("hunger") is float:
		return
	var h: float = p.hunger
	var h_max: float = p.get("hunger_max") if p.get("hunger_max") is float else 100.0
	var percent: float = h / h_max if h_max > 0 else 0.0
	fill.size.x = 80.0 * percent
	if percent > 0.6:
		fill.color = Color(0.0, 1.0, 0.0, 0.8)
	elif percent > 0.3:
		fill.color = Color(1.0, 1.0, 0.0, 0.8)
	else:
		fill.color = Color(1.0, 0.0, 0.0, 0.8)

func toggle() -> void:
	is_open = not is_open
	
	# Hotbar is always visible, only toggle inventory panel
	if inventory_panel:
		inventory_panel.visible = is_open
	
	if is_open:
		# Allow input when open
		mouse_filter = Control.MOUSE_FILTER_STOP
		if inventory_panel:
			inventory_panel.mouse_filter = Control.MOUSE_FILTER_STOP
		_update_all_slots()
		_update_hotbar_slots()
		UnifiedLogger.log_inventory("PlayerInventoryUI opened")
		print("Player inventory toggled: OPEN")
	else:
		# Cancel any in-progress craft and refund
		_cancel_active_craft()
		# Ignore input when closed
		mouse_filter = Control.MOUSE_FILTER_IGNORE
		if inventory_panel:
			inventory_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
		UnifiedLogger.log_inventory("PlayerInventoryUI closed")
		print("Player inventory toggled: CLOSED")

func _update_all_slots() -> void:
	super._update_all_slots()
	_update_craft_icon_states()

func _update_hotbar_slots() -> void:
	var hotbar_data = get_meta("hotbar_data", null) as InventoryData
	if not hotbar_data:
		return
	
	for i in hotbar_slots.size():
		var slot_data := hotbar_data.get_slot(i)
		hotbar_slots[i].set_item(slot_data)
	
	_update_craft_icon_states()
	
	# Sync player equip from slot 1 / right hand (axe/pick visible, attack valid)
	var main_node = get_tree().get_first_node_in_group("main")
	if main_node and main_node.has_method("_update_equipment"):
		main_node._update_equipment()

func add_item(type: ResourceData.ResourceType, amount: int = 1) -> bool:
	return inventory_data.add_item(type, amount)

func add_item_preferring_food_slots(type: ResourceData.ResourceType, amount: int = 1) -> bool:
	"""Add items preferring consumable hotbar slots (8, 9) first, then inventory, then other hotbar."""
	var hotbar_data = get_meta("hotbar_data", null) as InventoryData
	if not hotbar_data:
		return inventory_data.add_item(type, amount)
	# Preference order: (hotbar,8), (hotbar,9), (inv,0..4), (hotbar,0..7)
	var slot_order: Array[Dictionary] = []
	for idx in [8, 9]:
		slot_order.append({"data": hotbar_data, "idx": idx})
	for idx in range(SLOT_COUNT):
		slot_order.append({"data": inventory_data, "idx": idx})
	for idx in range(8):
		slot_order.append({"data": hotbar_data, "idx": idx})
	for _iter in range(amount):
		var added := false
		for entry in slot_order:
			var slot_data: Dictionary = entry.data.get_slot(entry.idx)
			if slot_data.is_empty():
				entry.data.set_slot(entry.idx, {"type": type, "count": 1})
				added = true
				break
		if not added:
			return false
	_update_all_slots()
	_update_hotbar_slots()
	return true

func get_hotbar_slot(index: int) -> Dictionary:
	if index < 0 or index >= hotbar_slots.size():
		return {}
	var hotbar_data = get_meta("hotbar_data", null) as InventoryData
	if not hotbar_data:
		return {}
	return hotbar_data.get_slot(index)

func _on_slot_drag_ended(_slot: InventorySlot) -> void:
	# Handle drop when mouse is released - check both inventory and hotbar slots, and building inventory
	if not drag_manager or not drag_manager.is_dragging:
		return
	
	# Check if mouse is over any slot (inventory or hotbar)
	var mouse_pos: Vector2 = get_viewport().get_mouse_position()
	
	# Check inventory slots
	for check_slot in slots:
		var slot_rect: Rect2 = Rect2(check_slot.get_global_rect())
		if slot_rect.has_point(mouse_pos):
			_handle_drop(check_slot)
			return
	
	# Check hotbar slots
	for check_slot in hotbar_slots:
		var slot_rect: Rect2 = Rect2(check_slot.get_global_rect())
		if slot_rect.has_point(mouse_pos):
			_handle_drop(check_slot)
			return
	
	# Check if mouse is over building inventory slots (for cross-inventory drag)
	var main: Node = get_tree().get_first_node_in_group("main")
	if main and main.has_method("get") and main.get("building_inventory_ui"):
		var building_ui = main.get("building_inventory_ui")
		if building_ui and building_ui.visible:
			# Check building inventory slots
			for check_slot in building_ui.slots:
				var slot_rect: Rect2 = Rect2(check_slot.get_global_rect())
				if slot_rect.has_point(mouse_pos):
					# Dropping from player to building - handled by building inventory
					return
	
	# Mouse not over any slot - check if it's a placeable building
	var dragged_item = drag_manager.dragged_item if drag_manager else {}
	var from_slot = drag_manager.from_slot if drag_manager else null
	if not dragged_item.is_empty() and from_slot:
		var item_type: ResourceData.ResourceType = dragged_item.get("type", -1) as ResourceData.ResourceType
		var is_placeable_building: bool = (
			item_type == ResourceData.ResourceType.LANDCLAIM or
			item_type == ResourceData.ResourceType.CAMPFIRE or
			item_type == ResourceData.ResourceType.TRAVOIS or
			item_type == ResourceData.ResourceType.LIVING_HUT or
			item_type == ResourceData.ResourceType.SUPPLY_HUT or
			item_type == ResourceData.ResourceType.SHRINE or
			item_type == ResourceData.ResourceType.DAIRY_FARM or
			item_type == ResourceData.ResourceType.FARM or
			item_type == ResourceData.ResourceType.OVEN
		)
		if is_placeable_building:
			# Handle placement directly (like land claims)
			# Reuse 'main' variable declared above
			if main:
				var world_pos: Vector2 = main._get_world_mouse_position() if main.has_method("_get_world_mouse_position") else Vector2.ZERO
				if item_type == ResourceData.ResourceType.LANDCLAIM:
					if main.has_method("_place_land_claim"):
						main._place_land_claim(world_pos, from_slot)
				elif item_type == ResourceData.ResourceType.CAMPFIRE:
					if main.has_method("_place_campfire"):
						main._place_campfire(world_pos, from_slot)
				elif item_type == ResourceData.ResourceType.TRAVOIS:
					if main.has_method("_place_travois"):
						main._place_travois(world_pos, from_slot)
				else:
					if main.has_method("_place_building"):
						main._place_building(world_pos, from_slot, item_type)
				# End drag after placement (item removal handled in _place_building)
				drag_manager.end_drag()
				return
	
	# Not a placeable building - end drag normally
	drag_manager.end_drag()

func _input(event: InputEvent) -> void:
	# Global mouse button release handler for drag-and-drop
	if event is InputEventMouseButton:
		var mouse_event := event as InputEventMouseButton
		if mouse_event.button_index == MOUSE_BUTTON_LEFT and not mouse_event.pressed:
			# Mouse button released - check if we're dragging
			if drag_manager and drag_manager.is_dragging:
				var mouse_pos: Vector2 = get_viewport().get_mouse_position()
				
				# Check inventory slots
				for check_slot in slots:
					var slot_rect: Rect2 = Rect2(check_slot.get_global_rect())
					if slot_rect.has_point(mouse_pos):
						_handle_drop(check_slot)
						get_viewport().set_input_as_handled()
						return
				
				# Check hotbar slots
				for check_slot in hotbar_slots:
					var slot_rect: Rect2 = Rect2(check_slot.get_global_rect())
					if slot_rect.has_point(mouse_pos):
						_handle_drop(check_slot)
						get_viewport().set_input_as_handled()
						return
				
				# Check building inventory slots
				var main: Node = get_tree().get_first_node_in_group("main")
				if main and main.has_method("get") and main.get("building_inventory_ui"):
					var building_ui = main.get("building_inventory_ui")
					if building_ui and building_ui.visible:
						for check_slot in building_ui.slots:
							var slot_rect: Rect2 = Rect2(check_slot.get_global_rect())
							if slot_rect.has_point(mouse_pos):
								# Dropping from player to building - let building handle it
								# Building inventory will handle the drop
								get_viewport().set_input_as_handled()
								return
				
				# Not over any slot - end drag. Main._on_drag_ended handles building placement when drag_ended fires.
				if drag_manager:
					drag_manager.end_drag()
					get_viewport().set_input_as_handled()

func _handle_drop(target_slot: InventorySlot) -> void:
	# Check if dropping between hotbar and inventory, or from building inventory
	var from_slot: InventorySlot = drag_manager.from_slot if drag_manager else null
	if not from_slot:
		return
	
	# Get appropriate inventory data
	var from_data: InventoryData = null
	var to_data: InventoryData = null
	
	# Check if dragging from building inventory
	var main: Node = get_tree().get_first_node_in_group("main")
	if main and main.has_method("get") and main.get("building_inventory_ui"):
		var building_ui = main.get("building_inventory_ui")
		if building_ui and from_slot in building_ui.slots:
			# Dragging from building inventory
			from_data = building_ui.inventory_data
		elif from_slot.is_hotbar:
			from_data = get_meta("hotbar_data", null) as InventoryData
		else:
			from_data = inventory_data
	else:
		if from_slot.is_hotbar:
			from_data = get_meta("hotbar_data", null) as InventoryData
		else:
			from_data = inventory_data
	
	if target_slot.is_hotbar:
		to_data = get_meta("hotbar_data", null) as InventoryData
	else:
		to_data = inventory_data
	
	if not from_data or not to_data:
		return
	
	var dragged_item: Dictionary = drag_manager.dragged_item if drag_manager else {}
	var target_item: Dictionary = target_slot.get_item()
	var dragged_type: ResourceData.ResourceType = dragged_item.get("type", -1) as ResourceData.ResourceType
	var dragged_count: int = dragged_item.get("count", 1) as int
	
	# Hotbar: reject placeable buildings (must be placed in world, not equipped)
	if target_slot.is_hotbar:
		var is_placeable_building: bool = (
			dragged_type == ResourceData.ResourceType.LANDCLAIM or
			dragged_type == ResourceData.ResourceType.CAMPFIRE or
			dragged_type == ResourceData.ResourceType.LIVING_HUT or
			dragged_type == ResourceData.ResourceType.SUPPLY_HUT or
			dragged_type == ResourceData.ResourceType.SHRINE or
			dragged_type == ResourceData.ResourceType.DAIRY_FARM or
			dragged_type == ResourceData.ResourceType.FARM or
			dragged_type == ResourceData.ResourceType.OVEN
		)
		if is_placeable_building:
			if drag_manager:
				drag_manager.end_drag(true)  # Restore item to source
			return
	
	# Handle the drop
	
	# First, try to stack with target slot if same type
	if not target_item.is_empty():
		var target_type: ResourceData.ResourceType = target_item.get("type", -1) as ResourceData.ResourceType
		if target_type == dragged_type and to_data.can_stack:
			# Same type - try to stack
			var target_count: int = target_item.get("count", 1) as int
			var total: int = target_count + dragged_count
			
			if total <= to_data.max_stack:
				# Full stack - all dragged items fit
				target_item["count"] = total
				target_slot.set_item(target_item)
				to_data.set_slot(target_slot.slot_index, target_item)
				
				# Source slot is already cleared (handled in start_drag)
				# Just update display
				_update_all_slots()
				if target_slot.is_hotbar or from_slot.is_hotbar:
					_update_hotbar_slots()
				if main and main.has_method("get") and main.get("building_inventory_ui"):
					var building_ui = main.get("building_inventory_ui")
					if building_ui and from_slot in building_ui.slots:
						building_ui._update_all_slots()
				
				if drag_manager:
					drag_manager.complete_drop(target_slot)
					item_dropped.emit(dragged_item, from_slot, target_slot)
				return
			else:
				# Partial stack - some items fit
				var stack_amount: int = to_data.max_stack - target_count
				target_item["count"] = to_data.max_stack
				target_slot.set_item(target_item)
				to_data.set_slot(target_slot.slot_index, target_item)
				
				# Put remaining items back in source slot
				var remaining: Dictionary = dragged_item.duplicate()
				remaining["count"] = dragged_count - stack_amount
				from_slot.set_item(remaining)
				from_data.set_slot(from_slot.slot_index, remaining)
				
				_update_all_slots()
				if target_slot.is_hotbar or from_slot.is_hotbar:
					_update_hotbar_slots()
				if main and main.has_method("get") and main.get("building_inventory_ui"):
					var building_ui = main.get("building_inventory_ui")
					if building_ui and from_slot in building_ui.slots:
						building_ui._update_all_slots()
				
				if drag_manager:
					drag_manager.complete_drop(target_slot)
					item_dropped.emit(dragged_item, from_slot, target_slot)
				return
	
	# If target is empty, check if there's already a slot with the same item type that can be stacked
	if target_item.is_empty() and to_data.can_stack:
		for check_slot in (slots if not target_slot.is_hotbar else hotbar_slots):
			if check_slot == target_slot:
				continue
			var check_item: Dictionary = check_slot.get_item()
			if not check_item.is_empty():
				var check_type: ResourceData.ResourceType = check_item.get("type", -1) as ResourceData.ResourceType
				if check_type == dragged_type:
					# Found matching item - try to stack
					var check_count: int = check_item.get("count", 1) as int
					var total: int = check_count + dragged_count
					
					if total <= to_data.max_stack:
						# Full stack - all dragged items fit
						check_item["count"] = total
						check_slot.set_item(check_item)
						to_data.set_slot(check_slot.slot_index, check_item)
						
						# Source slot is already cleared (handled in start_drag)
						# Just update display
						_update_all_slots()
						if target_slot.is_hotbar or from_slot.is_hotbar:
							_update_hotbar_slots()
						if main and main.has_method("get") and main.get("building_inventory_ui"):
							var building_ui = main.get("building_inventory_ui")
							if building_ui and from_slot in building_ui.slots:
								building_ui._update_all_slots()
						
						if drag_manager:
							drag_manager.complete_drop(check_slot)
							item_dropped.emit(dragged_item, from_slot, check_slot)
						return
					else:
						# Partial stack - some items fit
						var stack_amount: int = to_data.max_stack - check_count
						check_item["count"] = to_data.max_stack
						check_slot.set_item(check_item)
						to_data.set_slot(check_slot.slot_index, check_item)
						
						# Put remaining items in target slot
						var remaining: Dictionary = dragged_item.duplicate()
						remaining["count"] = dragged_count - stack_amount
						target_slot.set_item(remaining)
						to_data.set_slot(target_slot.slot_index, remaining)
						
						_update_all_slots()
						if target_slot.is_hotbar or from_slot.is_hotbar:
							_update_hotbar_slots()
						if main and main.has_method("get") and main.get("building_inventory_ui"):
							var building_ui = main.get("building_inventory_ui")
							if building_ui and from_slot in building_ui.slots:
								building_ui._update_all_slots()
						
						if drag_manager:
							drag_manager.complete_drop(target_slot)
							item_dropped.emit(dragged_item, from_slot, target_slot)
						return
	
	# No stacking possible - if target slot is empty, place item there directly
	# Otherwise, find an empty slot instead of swapping
	var empty_slot: InventorySlot = null
	
	# CRITICAL FIX: If target slot is empty, use it directly (don't search for other empty slots)
	if target_item.is_empty():
		empty_slot = target_slot
	else:
		# Target slot has an item - find an empty slot instead of swapping
		var slot_list: Array = slots if not target_slot.is_hotbar else hotbar_slots
		
		# Find first empty slot in the appropriate inventory
		for check_slot in slot_list:
			if check_slot.is_empty() and check_slot != from_slot:
				empty_slot = check_slot
				break
	
	if empty_slot:
		# Found empty slot - place dragged item there
		empty_slot.set_item(dragged_item)
		to_data.set_slot(empty_slot.slot_index, dragged_item)
		
		# Source slot is already cleared by start_drag, but ensure building/corpse inventory display is updated
		# This is especially important for cross-inventory drops (corpse -> player)
		
		# Log successful drop
		var item_type = dragged_item.get("type", -1)
		var item_name: String = ResourceData.get_resource_name(item_type) if item_type != -1 else "unknown"
		UnifiedLogger.log_drag_drop("Drop success: moved_to_empty - %s" % item_name, {
			"from_slot": from_slot.slot_index if from_slot else -1,
			"to_slot": empty_slot.slot_index if empty_slot else -1
		}, UnifiedLogger.Level.DEBUG)
		
		# Update displays - ensure both player and building/corpse inventories are updated
		_update_all_slots()
		if target_slot.is_hotbar or from_slot.is_hotbar or empty_slot.is_hotbar:
			_update_hotbar_slots()
		# Always update building/corpse inventory if dragging from it
		if main and main.has_method("get") and main.get("building_inventory_ui"):
			var building_ui = main.get("building_inventory_ui")
			if building_ui and from_slot in building_ui.slots:
				# Force update to reflect source slot clearing
				building_ui._update_all_slots()
		
		if drag_manager:
			drag_manager.complete_drop(empty_slot)
			item_dropped.emit(dragged_item, from_slot, empty_slot)
	else:
		# No empty slot found - cancel the drop, put item back in source slot
		from_slot.set_item(dragged_item)
		from_data.set_slot(from_slot.slot_index, dragged_item)
		
		# Log drop failure
		UnifiedLogger.log_drag_drop("Drop failed: no_empty_slot", {}, UnifiedLogger.Level.DEBUG)
		
		# Update displays
		_update_all_slots()
		if from_slot.is_hotbar:
			_update_hotbar_slots()
		if main and main.has_method("get") and main.get("building_inventory_ui"):
			var building_ui = main.get("building_inventory_ui")
			if building_ui and from_slot in building_ui.slots:
				building_ui._update_all_slots()
		
		if drag_manager:
			drag_manager.end_drag()


func get_total_resource_count(type: ResourceData.ResourceType) -> int:
	var total := 0
	if inventory_data:
		total += inventory_data.get_count(type)
	var hotbar_data = get_meta("hotbar_data", null) as InventoryData
	if hotbar_data:
		total += hotbar_data.get_count(type)
	return total


func _build_craft_icons() -> void:
	if not craft_icons_container:
		var margin = inventory_panel.get_node_or_null("MarginContainer") if inventory_panel else null
		var vbox = margin.get_node_or_null("InventoryVBox") if margin else null
		craft_icons_container = vbox.get_node_or_null("CraftIconsContainer") as HBoxContainer if vbox else null
	if not craft_icons_container:
		return
	
	for icon in craft_icons:
		if is_instance_valid(icon):
			icon.queue_free()
	craft_icons.clear()
	
	var crafts = CraftRegistryScript.get_all_crafts()
	for craft in crafts:
		var icon := _create_craft_icon(craft)
		craft_icons_container.add_child(icon)
		craft_icons.append(icon)
	
	_update_craft_icon_states()


func _create_craft_icon(craft: CraftRegistryScript.CraftData) -> Control:
	var icon_container := Panel.new()
	icon_container.custom_minimum_size = Vector2(CRAFT_ICON_SIZE, CRAFT_ICON_SIZE)
	icon_container.mouse_filter = Control.MOUSE_FILTER_STOP
	
	var style := UITheme.get_panel_style()
	style.bg_color.a = 0.9
	icon_container.add_theme_stylebox_override("panel", style)
	
	var icon_texture := TextureRect.new()
	var texture := load(craft.icon_path) as Texture2D
	if texture:
		icon_texture.texture = texture
	else:
		var placeholder := ColorRect.new()
		placeholder.color = Color(0.5, 0.5, 0.5, 0.5)
		placeholder.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		icon_container.add_child(placeholder)
		icon_container.set_meta("craft_data", craft)
		icon_container.gui_input.connect(_on_craft_icon_clicked.bind(craft, icon_container))
		return icon_container
	
	icon_texture.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
	icon_texture.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon_texture.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	icon_container.add_child(icon_texture)
	
	icon_container.set_meta("craft_data", craft)
	icon_container.gui_input.connect(_on_craft_icon_clicked.bind(craft, icon_container))
	return icon_container


func _update_craft_icon_states() -> void:
	var hotbar_data = get_meta("hotbar_data", null) as InventoryData
	for i in craft_icons.size():
		var icon = craft_icons[i] as Control
		if not is_instance_valid(icon):
			continue
		var craft = icon.get_meta("craft_data", null) as CraftRegistryScript.CraftData
		if not craft:
			continue
		var affordable: bool = CraftRegistryScript.can_afford(craft, inventory_data, hotbar_data)
		icon.modulate = Color.WHITE if affordable else Color(0.5, 0.5, 0.5)


func _on_craft_icon_clicked(event: InputEvent, craft: CraftRegistryScript.CraftData, icon: Control) -> void:
	if not (event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT):
		return
	if _active_craft_overlay and _active_craft_overlay.is_in_progress():
		return
	var hotbar_data = get_meta("hotbar_data", null) as InventoryData
	if not CraftRegistryScript.can_afford(craft, inventory_data, hotbar_data):
		return
	if not CraftRegistryScript.consume_materials(craft, inventory_data, hotbar_data):
		return
	var overlay := ProgressPieOverlay.new()
	overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	icon.add_child(overlay)
	_active_craft_overlay = overlay
	_active_craft_data = craft
	overlay.progress_completed.connect(_on_craft_progress_completed.bind(craft))
	overlay.start_progress(craft.duration)

func _on_craft_progress_completed(craft: CraftRegistryScript.CraftData) -> void:
	if _active_craft_overlay:
		_active_craft_overlay.queue_free()
		_active_craft_overlay = null
	_active_craft_data = null
	inventory_data.add_item(craft.output_type, 1)
	_update_all_slots()
	_update_hotbar_slots()
	_update_craft_icon_states()

func _cancel_active_craft() -> void:
	if not _active_craft_overlay or not _active_craft_data:
		return
	if _active_craft_overlay.is_in_progress():
		_active_craft_overlay.stop_progress()
		var hotbar_data = get_meta("hotbar_data", null) as InventoryData
		CraftRegistryScript.refund_materials(_active_craft_data, inventory_data, hotbar_data)
		_update_all_slots()
		_update_hotbar_slots()
	_active_craft_overlay.queue_free()
	_active_craft_overlay = null
	_active_craft_data = null
