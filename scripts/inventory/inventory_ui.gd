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
var _window_dragging: bool = false
var _window_grab: Vector2 = Vector2.ZERO
var _window_panel: Control = null
## Saved screen position after the player drags a title bar. Empty = use default layout.
var window_layout_id: String = ""
const WINDOW_LAYOUT_PATH := "user://ui_window_layout.cfg"
static var _window_layout: Dictionary = {}
static var _window_layout_loaded: bool = false
static var persist_window_layout_to_disk: bool = true

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
	if _window_dragging and _window_panel and is_instance_valid(_window_panel):
		if event is InputEventMouseMotion:
			_window_panel.global_position = get_viewport().get_mouse_position() - _window_grab
			_clamp_panel_on_screen(_window_panel)
			get_viewport().set_input_as_handled()
			return
		if event is InputEventMouseButton:
			var mbw := event as InputEventMouseButton
			if mbw.button_index == MOUSE_BUTTON_LEFT and not mbw.pressed:
				remember_window_position(_window_panel)
				_window_dragging = false
				_window_panel = null
				return
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


func _make_title_bar(text: String) -> PanelContainer:
	var bar := PanelContainer.new()
	bar.name = "TitleBar"
	bar.mouse_filter = Control.MOUSE_FILTER_STOP
	bar.custom_minimum_size = Vector2(0, 28)
	var st := StyleBoxFlat.new()
	st.bg_color = Color(0x24 / 255.0, 0x1b / 255.0, 0x16 / 255.0, 0.95)
	st.border_color = UITheme.COLOR_BORDER_SADDLE_BROWN
	st.border_width_bottom = 1
	st.set_corner_radius_all(0)
	st.content_margin_left = 10
	st.content_margin_right = 10
	st.content_margin_top = 4
	st.content_margin_bottom = 4
	bar.add_theme_stylebox_override("panel", st)
	var lab := Label.new()
	lab.name = "TitleLabel"
	lab.text = text
	lab.mouse_filter = Control.MOUSE_FILTER_IGNORE
	lab.add_theme_font_size_override("font_size", UITheme.FONT_SIZE_TITLE - 2)
	lab.add_theme_color_override("font_color", UITheme.COLOR_TEXT_PRIMARY)
	lab.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	lab.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	bar.add_child(lab)
	return bar


func enable_window_drag(title: Control, panel: Control) -> void:
	if title == null or panel == null:
		return
	title.mouse_filter = Control.MOUSE_FILTER_STOP
	if not title.gui_input.is_connected(_on_window_title_gui_input):
		title.gui_input.connect(_on_window_title_gui_input.bind(panel))


func _ensure_window_layout_loaded() -> void:
	if _window_layout_loaded:
		return
	_window_layout_loaded = true
	var cf := ConfigFile.new()
	if cf.load(WINDOW_LAYOUT_PATH) != OK:
		return
	if not cf.has_section("windows"):
		return
	for key in cf.get_section_keys("windows"):
		var raw: Variant = cf.get_value("windows", key)
		if raw is Vector2:
			_window_layout[String(key)] = raw


func _save_window_layout() -> void:
	var cf := ConfigFile.new()
	for key in _window_layout.keys():
		cf.set_value("windows", String(key), _window_layout[key])
	cf.save(WINDOW_LAYOUT_PATH)


func remember_window_position(panel: Control) -> void:
	if window_layout_id.is_empty() or panel == null or not is_instance_valid(panel):
		return
	_ensure_window_layout_loaded()
	_window_layout[window_layout_id] = panel.global_position
	if persist_window_layout_to_disk:
		_save_window_layout()


func try_restore_window_position(panel: Control) -> bool:
	if window_layout_id.is_empty() or panel == null or not is_instance_valid(panel):
		return false
	_ensure_window_layout_loaded()
	if not _window_layout.has(window_layout_id):
		return false
	_bake_panel_top_left(panel)
	panel.global_position = _window_layout[window_layout_id]
	_clamp_panel_on_screen(panel)
	return true


func _clamp_panel_on_screen(panel: Control) -> void:
	if panel == null or not is_instance_valid(panel):
		return
	var vp := get_viewport()
	if vp == null:
		return
	var vr: Rect2 = vp.get_visible_rect()
	var sz: Vector2 = panel.size
	if sz.x < 8.0 or sz.y < 8.0:
		sz = panel.custom_minimum_size
	var p: Vector2 = panel.global_position
	var max_x: float = vr.position.x + maxf(0.0, vr.size.x - sz.x)
	var max_y: float = vr.position.y + maxf(0.0, vr.size.y - sz.y)
	p.x = clampf(p.x, vr.position.x, max_x)
	p.y = clampf(p.y, vr.position.y, max_y)
	panel.global_position = p


func _bake_panel_top_left(panel: Control) -> void:
	var gp: Vector2 = panel.global_position
	panel.set_anchors_preset(Control.PRESET_TOP_LEFT)
	panel.anchor_left = 0.0
	panel.anchor_top = 0.0
	panel.anchor_right = 0.0
	panel.anchor_bottom = 0.0
	panel.global_position = gp


func _on_window_title_gui_input(event: InputEvent, panel: Control) -> void:
	if event is InputEventMouseButton:
		var mb := event as InputEventMouseButton
		if mb.button_index != MOUSE_BUTTON_LEFT:
			return
		if mb.pressed:
			_window_dragging = true
			_window_panel = panel
			_bake_panel_top_left(panel)
			_window_grab = mb.global_position - panel.global_position
			panel.z_index = 30
			get_viewport().set_input_as_handled()
		else:
			remember_window_position(panel)
			_window_dragging = false
			_window_panel = null
	elif event is InputEventMouseMotion and _window_dragging and _window_panel == panel:
		panel.global_position = (event as InputEventMouseMotion).global_position - _window_grab
		_clamp_panel_on_screen(panel)
		get_viewport().set_input_as_handled()

func _on_drag_ended() -> void:
	# Check if drop was successful
	pass


func _get_inventory_bridge() -> Node:
	return get_node_or_null("/root/InventoryActionBridge")


func _propose_move_between_slots(
	from_slot: InventorySlot,
	to_slot: InventorySlot,
	dragged_item: Dictionary,
	target_item: Dictionary,
	to_can_stack: bool,
	to_max_stack: int
) -> bool:
	var bridge: Node = _get_inventory_bridge()
	if bridge == null:
		return false
	var from_ctx: Dictionary = bridge.resolve_slot_context(from_slot)
	var to_ctx: Dictionary = bridge.resolve_slot_context(to_slot)
	var op: Dictionary = bridge.build_move_op(
		str(from_ctx.get("kind", InventoryActionBridge.INV_PLAYER)),
		int(from_ctx.get("entity_id", -1)),
		from_slot.slot_index,
		str(to_ctx.get("kind", InventoryActionBridge.INV_PLAYER)),
		int(to_ctx.get("entity_id", -1)),
		to_slot.slot_index,
		dragged_item,
		target_item,
		to_can_stack,
		to_max_stack
	)
	if op.is_empty():
		return false
	return bridge.propose_inventory_mutate(op)


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
				if not _propose_move_between_slots(
					from_slot, target_slot, dragged_item, target_item,
					inventory_data.can_stack, inventory_data.max_stack
				):
					drag_manager.end_drag(true)
					return
				target_slot.set_item(inventory_data.get_slot(target_slot.slot_index))
				from_slot.set_item(inventory_data.get_slot(from_slot.slot_index))
				
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
				if not _propose_move_between_slots(
					from_slot, target_slot, dragged_item, target_item,
					inventory_data.can_stack, inventory_data.max_stack
				):
					drag_manager.end_drag(true)
					return
				target_slot.set_item(inventory_data.get_slot(target_slot.slot_index))
				from_slot.set_item(inventory_data.get_slot(from_slot.slot_index))
				
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
	if not _propose_move_between_slots(
		from_slot, target_slot, dragged_item, target_item,
		inventory_data.can_stack, inventory_data.max_stack
	):
		drag_manager.end_drag(true)
		return
	target_slot.set_item(inventory_data.get_slot(target_slot.slot_index))
	from_slot.set_item(inventory_data.get_slot(from_slot.slot_index))
	
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
