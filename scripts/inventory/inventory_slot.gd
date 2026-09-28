extends Panel
class_name InventorySlot

## Boxed inventory cell. Hotbar = square; bag = list row (icon + name + desc + count).

signal slot_clicked(slot: InventorySlot)
signal slot_drag_ended(slot: InventorySlot)

const ICON_SIZE := 32
const HOTBAR_CELL := 40
const LIST_ROW_H := 56
const COUNT_COL := Vector2(72, 22)
const DRAG_THRESHOLD_PX := 6.0

var slot_index: int = -1
var item_data: Dictionary = {}
var is_hotbar: bool = false
var can_stack: bool = false
var short_class_desc: bool = false

var icon_texture: TextureRect = null
var name_label: Label = null
var desc_label: Label = null
var quality_border: Control = null
var count_label: Label = null
var slot_number_label: Label = null
var hotbar_number_label: Label = null

var drag_manager: DragManager = null
var is_drag_source: bool = false
var is_hovered_during_drag: bool = false
var highlight_overlay: ColorRect = null
var base_modulate: Color = Color.WHITE

var _pressing: bool = false
var _drag_armed: bool = false
var _press_global: Vector2 = Vector2.ZERO


func _ready() -> void:
	# List rows must not clip the count column on the right.
	clip_contents = is_hotbar
	mouse_filter = MOUSE_FILTER_STOP
	if is_hotbar:
		custom_minimum_size = Vector2(HOTBAR_CELL, HOTBAR_CELL)
		size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		size_flags_vertical = Control.SIZE_SHRINK_CENTER
	else:
		custom_minimum_size = Vector2(ICON_SIZE + 16 + COUNT_COL.x, LIST_ROW_H)
		size_flags_horizontal = Control.SIZE_EXPAND_FILL
	UITheme.apply_slot_style(self, is_hotbar)
	_setup_children()
	if not gui_input.is_connected(_on_gui_input):
		gui_input.connect(_on_gui_input)
	if not mouse_entered.is_connected(_on_mouse_entered):
		mouse_entered.connect(_on_mouse_entered)
	if not mouse_exited.is_connected(_on_mouse_exited):
		mouse_exited.connect(_on_mouse_exited)
	_setup_drag_manager()
	base_modulate = modulate
	_create_highlight_overlay()
	set_process_input(true)


func _input(event: InputEvent) -> void:
	if not _pressing:
		return
	if event is InputEventMouseMotion:
		if not _drag_armed and not item_data.is_empty():
			if get_global_mouse_position().distance_to(_press_global) >= DRAG_THRESHOLD_PX:
				_drag_armed = true
				slot_clicked.emit(self)
	elif event is InputEventMouseButton:
		var mb := event as InputEventMouseButton
		if mb.button_index == MOUSE_BUTTON_LEFT and not mb.pressed:
			if _pressing and not _drag_armed:
				slot_drag_ended.emit(self)
			_pressing = false
			_drag_armed = false


func _setup_children() -> void:
	if has_node("SlotInner") or has_node("SlotInnerPad"):
		_bind_existing()
		_pin_list_count_label()
		return
	if is_hotbar:
		_setup_hotbar_children()
	else:
		_setup_list_children()


func _bind_existing() -> void:
	icon_texture = get_node_or_null("SlotInner/IconCell/Icon") as TextureRect
	if icon_texture == null:
		icon_texture = get_node_or_null("SlotInnerPad/SlotInner/IconCell/Icon") as TextureRect
	if icon_texture == null:
		icon_texture = get_node_or_null("SlotInner/Icon") as TextureRect
	name_label = get_node_or_null("SlotInner/TextCol/NameLabel") as Label
	if name_label == null:
		name_label = get_node_or_null("SlotInnerPad/SlotInner/TextCol/NameLabel") as Label
	desc_label = get_node_or_null("SlotInner/TextCol/DescLabel") as Label
	if desc_label == null:
		desc_label = get_node_or_null("SlotInnerPad/SlotInner/TextCol/DescLabel") as Label
	count_label = get_node_or_null("CountLabel") as Label
	if count_label == null:
		count_label = get_node_or_null("SlotInnerPad/SlotInner/CountLabel") as Label
	hotbar_number_label = get_node_or_null("HotbarNumberLabel") as Label
	slot_number_label = get_node_or_null("SlotNumberLabel") as Label
	quality_border = get_node_or_null("SlotInner/IconCell/QualityBorder") as Control
	if quality_border == null:
		quality_border = get_node_or_null("SlotInnerPad/SlotInner/IconCell/QualityBorder") as Control


func _setup_hotbar_children() -> void:
	var inner := MarginContainer.new()
	inner.name = "SlotInner"
	inner.mouse_filter = Control.MOUSE_FILTER_IGNORE
	inner.add_theme_constant_override("margin_left", 4)
	inner.add_theme_constant_override("margin_top", 4)
	inner.add_theme_constant_override("margin_right", 4)
	inner.add_theme_constant_override("margin_bottom", 4)
	inner.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(inner)

	icon_texture = TextureRect.new()
	icon_texture.name = "Icon"
	icon_texture.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon_texture.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon_texture.texture_filter = TEXTURE_FILTER_NEAREST
	icon_texture.mouse_filter = Control.MOUSE_FILTER_IGNORE
	icon_texture.set_anchors_preset(Control.PRESET_FULL_RECT)
	inner.add_child(icon_texture)

	quality_border = _make_quality_border()
	inner.add_child(quality_border)

	hotbar_number_label = Label.new()
	hotbar_number_label.name = "HotbarNumberLabel"
	hotbar_number_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hotbar_number_label.add_theme_font_size_override("font_size", 10)
	hotbar_number_label.add_theme_color_override("font_color", Color(1, 1, 1, 0.45))
	hotbar_number_label.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.7))
	hotbar_number_label.add_theme_constant_override("outline_size", 2)
	hotbar_number_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	hotbar_number_label.vertical_alignment = VERTICAL_ALIGNMENT_TOP
	hotbar_number_label.set_anchors_preset(Control.PRESET_FULL_RECT)
	hotbar_number_label.offset_left = 3
	hotbar_number_label.offset_top = 1
	var slot_num: String
	if has_meta("slot_number"):
		slot_num = str(get_meta("slot_number"))
	else:
		slot_num = str((slot_index + 1) % 10)
	hotbar_number_label.text = slot_num
	add_child(hotbar_number_label)

	count_label = _make_count_label()
	count_label.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
	count_label.offset_left = -22
	count_label.offset_top = -16
	count_label.offset_right = -2
	count_label.offset_bottom = -1
	add_child(count_label)


func _setup_list_children() -> void:
	var pad := MarginContainer.new()
	pad.name = "SlotInnerPad"
	pad.mouse_filter = Control.MOUSE_FILTER_IGNORE
	pad.add_theme_constant_override("margin_left", 6)
	pad.add_theme_constant_override("margin_top", 4)
	pad.add_theme_constant_override("margin_right", 8 + int(COUNT_COL.x))
	pad.add_theme_constant_override("margin_bottom", 4)
	pad.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(pad)

	var inner := HBoxContainer.new()
	inner.name = "SlotInner"
	inner.mouse_filter = Control.MOUSE_FILTER_IGNORE
	inner.add_theme_constant_override("separation", 8)
	inner.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	pad.add_child(inner)

	var icon_cell := Panel.new()
	icon_cell.name = "IconCell"
	icon_cell.mouse_filter = Control.MOUSE_FILTER_IGNORE
	icon_cell.custom_minimum_size = Vector2(ICON_SIZE, ICON_SIZE)
	icon_cell.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	icon_cell.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	icon_cell.add_theme_stylebox_override("panel", UITheme.get_slot_icon_cell_style())
	inner.add_child(icon_cell)

	icon_texture = TextureRect.new()
	icon_texture.name = "Icon"
	icon_texture.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon_texture.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon_texture.texture_filter = TEXTURE_FILTER_NEAREST
	icon_texture.mouse_filter = Control.MOUSE_FILTER_IGNORE
	icon_texture.set_anchors_preset(Control.PRESET_FULL_RECT)
	icon_texture.offset_left = 2
	icon_texture.offset_top = 2
	icon_texture.offset_right = -2
	icon_texture.offset_bottom = -2
	icon_cell.add_child(icon_texture)

	quality_border = _make_quality_border()
	icon_cell.add_child(quality_border)

	var text_col := VBoxContainer.new()
	text_col.name = "TextCol"
	text_col.mouse_filter = Control.MOUSE_FILTER_IGNORE
	text_col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	text_col.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	text_col.add_theme_constant_override("separation", 0)
	inner.add_child(text_col)

	name_label = Label.new()
	name_label.name = "NameLabel"
	name_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	name_label.add_theme_font_size_override("font_size", UITheme.FONT_SIZE_BODY)
	name_label.add_theme_color_override("font_color", UITheme.COLOR_TEXT_PRIMARY)
	name_label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	name_label.clip_text = true
	name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	text_col.add_child(name_label)

	desc_label = Label.new()
	desc_label.name = "DescLabel"
	desc_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	desc_label.add_theme_font_size_override("font_size", UITheme.FONT_SIZE_SECONDARY)
	desc_label.add_theme_color_override("font_color", UITheme.COLOR_TEXT_SECONDARY)
	desc_label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	desc_label.clip_text = true
	desc_label.max_lines_visible = 1
	desc_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	text_col.add_child(desc_label)

	count_label = _make_count_label()
	_pin_list_count_label()
	add_child(count_label)

	slot_number_label = Label.new()
	slot_number_label.name = "SlotNumberLabel"
	slot_number_label.visible = false
	slot_number_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(slot_number_label)


func _make_count_label() -> Label:
	var lab := Label.new()
	lab.name = "CountLabel"
	lab.mouse_filter = Control.MOUSE_FILTER_IGNORE
	lab.add_theme_font_size_override("font_size", 18)
	lab.add_theme_color_override("font_color", Color.WHITE)
	lab.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.9))
	lab.add_theme_constant_override("outline_size", 4)
	lab.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	lab.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	lab.visible = false
	return lab


func _pin_list_count_label() -> void:
	if count_label == null or is_hotbar:
		return
	if count_label.get_parent() and count_label.get_parent() != self:
		count_label.get_parent().remove_child(count_label)
		add_child(count_label)
	count_label.custom_minimum_size = COUNT_COL
	count_label.clip_text = false
	count_label.mouse_filter = MOUSE_FILTER_IGNORE
	count_label.set_anchors_preset(Control.PRESET_CENTER_RIGHT)
	count_label.anchor_left = 1.0
	count_label.anchor_right = 1.0
	count_label.anchor_top = 0.5
	count_label.anchor_bottom = 0.5
	count_label.offset_left = -10.0 - COUNT_COL.x
	count_label.offset_right = -10.0
	count_label.offset_top = -COUNT_COL.y * 0.5
	count_label.offset_bottom = COUNT_COL.y * 0.5
	count_label.z_index = 2


func _make_quality_border() -> Panel:
	var border := Panel.new()
	border.name = "QualityBorder"
	border.mouse_filter = Control.MOUSE_FILTER_IGNORE
	border.visible = false
	border.set_anchors_preset(Control.PRESET_FULL_RECT)
	return border


func set_item(data: Dictionary) -> void:
	item_data = data.duplicate() if data.size() > 0 else {}
	_update_display()


func get_item() -> Dictionary:
	return item_data.duplicate()


func is_empty() -> bool:
	return item_data.is_empty()


func _display_item() -> Dictionary:
	if is_drag_source and drag_manager and drag_manager.is_dragging and not drag_manager.dragged_item.is_empty():
		return drag_manager.dragged_item
	return item_data


func _update_display() -> void:
	var shown: Dictionary = _display_item()
	if shown.is_empty():
		if icon_texture:
			icon_texture.texture = null
			icon_texture.visible = false
		if name_label:
			name_label.text = ""
		if desc_label:
			desc_label.text = ""
		if quality_border:
			quality_border.visible = false
		if count_label:
			count_label.visible = false
		if hotbar_number_label:
			hotbar_number_label.visible = true
		return

	if icon_texture:
		icon_texture.visible = true
	var item_type: ResourceData.ResourceType = shown.get("type", ResourceData.ResourceType.NONE) as ResourceData.ResourceType
	var count: int = shown.get("count", 1) as int
	var quality: int = shown.get("quality", 0) as int
	if icon_texture:
		var icon_path: String = ResourceData.get_resource_icon_path(item_type)
		var loaded: Texture2D = load(icon_path) as Texture2D if icon_path != "" else null
		icon_texture.texture = loaded if loaded else _create_fallback_icon(item_type)
	if not is_hotbar:
		if name_label:
			name_label.text = ResourceData.get_resource_name(item_type)
			name_label.visible = true
		if desc_label:
			desc_label.text = ResourceData.get_item_class(item_type) if short_class_desc else ResourceData.get_resource_description(item_type)
			desc_label.visible = true
	_update_quality_border(quality)
	if count_label:
		if can_stack and count >= 1:
			count_label.text = str(count)
			count_label.visible = true
		elif count > 1:
			count_label.text = str(count)
			count_label.visible = true
		else:
			count_label.visible = false


func _create_fallback_icon(item_type: ResourceData.ResourceType) -> Texture2D:
	var image := Image.create(ICON_SIZE, ICON_SIZE, false, Image.FORMAT_RGBA8)
	image.fill(ResourceData.get_resource_color(item_type))
	return ImageTexture.create_from_image(image)


func _update_quality_border(quality: int) -> void:
	if quality_border == null:
		return
	var border_colors := [
		Color(0.5, 0.5, 0.5),
		Color(1.0, 1.0, 1.0),
		Color(0.2, 0.4, 1.0),
		Color(0.4, 0.6, 1.0),
		Color(0.7, 0.5, 1.0),
		Color(0.8, 0.2, 1.0),
	]
	if quality < 0 or quality >= border_colors.size():
		quality_border.visible = false
		return
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0, 0, 0, 0)
	style.border_color = border_colors[quality]
	style.set_border_width_all(2)
	style.set_corner_radius_all(3)
	quality_border.add_theme_stylebox_override("panel", style)
	quality_border.visible = true


func _on_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		var mouse_event := event as InputEventMouseButton
		if mouse_event.button_index != MOUSE_BUTTON_LEFT:
			return
		if mouse_event.pressed:
			_pressing = true
			_drag_armed = false
			_press_global = get_global_mouse_position()
			get_viewport().set_input_as_handled()
		else:
			if _pressing and not _drag_armed:
				slot_drag_ended.emit(self)
			_pressing = false
			_drag_armed = false
			get_viewport().set_input_as_handled()
	elif event is InputEventMouseMotion:
		if _pressing and not _drag_armed and not item_data.is_empty():
			if get_global_mouse_position().distance_to(_press_global) >= DRAG_THRESHOLD_PX:
				_drag_armed = true
				slot_clicked.emit(self)
		if drag_manager and drag_manager.is_dragging:
			_update_drop_target_highlight()


func _setup_drag_manager() -> void:
	var main: Node = get_tree().get_first_node_in_group("main")
	if main and main.get("drag_manager"):
		drag_manager = main.get("drag_manager") as DragManager
		if drag_manager:
			if not drag_manager.drag_started.is_connected(_on_drag_started):
				drag_manager.drag_started.connect(_on_drag_started)
			if not drag_manager.drag_ended.is_connected(_on_drag_ended):
				drag_manager.drag_ended.connect(_on_drag_ended)


func _create_highlight_overlay() -> void:
	if highlight_overlay:
		return
	highlight_overlay = ColorRect.new()
	highlight_overlay.name = "HighlightOverlay"
	highlight_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	highlight_overlay.visible = false
	highlight_overlay.color = Color.TRANSPARENT
	highlight_overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(highlight_overlay)


func _on_drag_started(_item: Dictionary, from_slot: InventorySlot) -> void:
	is_drag_source = from_slot == self
	if is_drag_source:
		modulate = Color(1, 1, 1, 0.45)
		_update_display()
	else:
		modulate = base_modulate


func _on_drag_ended() -> void:
	is_drag_source = false
	is_hovered_during_drag = false
	modulate = base_modulate
	_clear_highlight()
	_update_display()


func _on_mouse_entered() -> void:
	if drag_manager and drag_manager.is_dragging:
		is_hovered_during_drag = true
		_update_drop_target_highlight()


func _on_mouse_exited() -> void:
	is_hovered_during_drag = false
	_clear_highlight()


func _update_drop_target_highlight() -> void:
	if not drag_manager or not drag_manager.is_dragging or not is_hovered_during_drag or is_drag_source:
		_clear_highlight()
		return
	if _is_valid_drop_target():
		_show_highlight(UITheme.get_drag_drop_highlight_valid())
	else:
		_show_highlight(UITheme.get_drag_drop_highlight_invalid())


func _is_valid_drop_target() -> bool:
	if not drag_manager or not drag_manager.is_dragging:
		return false
	var dragged_item = drag_manager.dragged_item
	if dragged_item.is_empty():
		return false
	var pui: PlayerInventoryUI = drag_manager._get_player_inventory_ui()
	var npc_ui = null
	var building_ui = null
	var main: Node = get_tree().get_first_node_in_group("main") if is_inside_tree() else null
	if main:
		npc_ui = main.get("npc_inventory_ui")
		building_ui = main.get("building_inventory_ui")
	if npc_ui and self in npc_ui.slots:
		return false
	var item_type: ResourceData.ResourceType = dragged_item.get("type", -1) as ResourceData.ResourceType
	if pui and (self in pui.slots or self in pui.hotbar_slots):
		if not pui._player_slot_accepts_item(self, item_type):
			return false
		if is_hotbar:
			var is_placeable_building: bool = (
				item_type == ResourceData.ResourceType.LANDCLAIM or
				item_type == ResourceData.ResourceType.LIVING_HUT or
				item_type == ResourceData.ResourceType.SUPPLY_HUT or
				item_type == ResourceData.ResourceType.SHRINE or
				item_type == ResourceData.ResourceType.DAIRY_FARM or
				item_type == ResourceData.ResourceType.FARM or
				item_type == ResourceData.ResourceType.OVEN
			)
			if is_placeable_building:
				return false
		if item_data.is_empty():
			return true
		if pui.slot_allows_stack_merge(self, item_type):
			var slot_count: int = int(item_data.get("count", 1))
			var dragged_count: int = int(dragged_item.get("count", 1))
			return (slot_count + dragged_count) <= pui.get_slot_stack_limit(self, item_type)
		return false
	var inventory_data = _get_inventory_data_for_slot()
	if not inventory_data:
		return false
	if building_ui and self in building_ui.slots:
		if item_data.is_empty():
			return inventory_data.can_add_item(item_type, int(dragged_item.get("count", 1)))
		var slot_item_type = item_data.get("type", -1)
		if slot_item_type == item_type and inventory_data.can_stack:
			var total: int = int(item_data.get("count", 1)) + int(dragged_item.get("count", 1))
			return total <= inventory_data.max_stack
		return true
	if item_data.is_empty():
		return true
	var slot_item_type = item_data.get("type", -1)
	if slot_item_type == item_type and inventory_data.can_stack:
		var total2: int = int(item_data.get("count", 1)) + int(dragged_item.get("count", 1))
		return total2 <= inventory_data.max_stack
	return inventory_data.can_stack


func _get_inventory_data_for_slot() -> InventoryData:
	if drag_manager:
		return drag_manager._get_inventory_data_for_slot(self)
	return null


func _show_highlight(color: Color) -> void:
	if highlight_overlay:
		highlight_overlay.color = color
		highlight_overlay.visible = true


func _clear_highlight() -> void:
	if highlight_overlay:
		highlight_overlay.visible = false
		highlight_overlay.color = Color.TRANSPARENT
