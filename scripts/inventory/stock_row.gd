extends PanelContainer
class_name StockRow

## One row in the scrollable building inventory: icon + name + qty. Click = take 1 (quick tap); hold + move = drag.

signal row_clicked(row: StockRow)
signal row_drag_started(row: StockRow)

const ICON_SZ := 28
const HOLD_SEC := 0.15
const DRAG_PX := 5.0

var slot_index: int = -1
var drag_proxy_slot: InventorySlot = null

var _row: HBoxContainer
var _icon: TextureRect
var _name_label: Label
var _qty_label: Label
var _hold_elapsed: bool = false
var _drag_begun: bool = false
var _press_global: Vector2 = Vector2.ZERO
var _base_bg: Color = Color(0x3c / 255.0, 0x27 / 255.0, 0x23 / 255.0, 0.95)
var _base_modulate: Color = Color.WHITE
var _highlight_overlay: ColorRect = null

func _ready() -> void:
	custom_minimum_size = Vector2(0, 34)
	mouse_filter = Control.MOUSE_FILTER_STOP
	_base_modulate = modulate
	_apply_style(false)
	_build_children()
	_ensure_highlight_overlay()
	if not gui_input.is_connected(_on_gui_input):
		gui_input.connect(_on_gui_input)
	if not mouse_entered.is_connected(_on_mouse_entered):
		mouse_entered.connect(_on_mouse_entered)
	if not mouse_exited.is_connected(_on_mouse_exited):
		mouse_exited.connect(_on_mouse_exited)


func setup_row(idx: int, proxy: InventorySlot, item: Dictionary) -> void:
	slot_index = idx
	drag_proxy_slot = proxy
	_refresh_from_item(item)


func _build_children() -> void:
	if _row:
		return
	add_theme_constant_override("margin_left", 4)
	add_theme_constant_override("margin_top", 2)
	add_theme_constant_override("margin_right", 4)
	add_theme_constant_override("margin_bottom", 2)

	_row = HBoxContainer.new()
	_row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_row.add_theme_constant_override("separation", 8)
	add_child(_row)

	_icon = TextureRect.new()
	_icon.custom_minimum_size = Vector2(ICON_SZ, ICON_SZ)
	_icon.texture_filter = TextureRect.TEXTURE_FILTER_NEAREST
	_icon.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
	_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_row.add_child(_icon)

	_name_label = Label.new()
	_name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_name_label.add_theme_font_size_override("font_size", 14)
	_name_label.add_theme_color_override("font_color", UITheme.COLOR_TEXT_PRIMARY)
	_name_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_row.add_child(_name_label)

	_qty_label = Label.new()
	_qty_label.custom_minimum_size = Vector2(50, 0)
	_qty_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_qty_label.add_theme_font_size_override("font_size", 14)
	_qty_label.add_theme_color_override("font_color", UITheme.COLOR_TEXT_PRIMARY)
	_qty_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_row.add_child(_qty_label)


func _refresh_from_item(item: Dictionary) -> void:
	if not _row:
		_build_children()
	if item.is_empty():
		_icon.texture = null
		_name_label.text = ""
		_qty_label.text = ""
		return
	var t: ResourceData.ResourceType = item.get("type", ResourceData.ResourceType.NONE) as ResourceData.ResourceType
	var c: int = int(item.get("count", 1))
	var path: String = ResourceData.get_resource_icon_path(t)
	if path != "":
		var tex: Texture2D = load(path) as Texture2D
		_icon.texture = tex
	else:
		_icon.texture = null
	_name_label.text = ResourceData.get_resource_name(t)
	_qty_label.text = "x%d" % c


func _apply_style(hover: bool) -> void:
	var style := StyleBoxFlat.new()
	var col := _base_bg
	if hover:
		col = Color(
			minf(col.r * 1.15, 1.0),
			minf(col.g * 1.15, 1.0),
			minf(col.b * 1.15, 1.0),
			col.a
		)
	style.bg_color = col
	style.border_color = Color(0x8b / 255.0, 0x45 / 255.0, 0x13 / 255.0, 0.4)
	style.set_border_width_all(1)
	style.set_corner_radius_all(4)
	add_theme_stylebox_override("panel", style)


func _on_mouse_entered() -> void:
	_apply_style(true)


func _on_mouse_exited() -> void:
	_apply_style(false)


func _on_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		var mb := event as InputEventMouseButton
		if mb.button_index != MOUSE_BUTTON_LEFT:
			return
		if mb.pressed:
			_hold_elapsed = false
			_drag_begun = false
			_press_global = get_global_mouse_position()
			var tr := get_tree().create_timer(HOLD_SEC)
			tr.timeout.connect(_on_hold_timeout, CONNECT_ONE_SHOT)
		else:
			if not _drag_begun and not _hold_elapsed:
				row_clicked.emit(self)
			_hold_elapsed = false
			_drag_begun = false
	elif event is InputEventMouseMotion:
		var mot := event as InputEventMouseMotion
		if (mot.button_mask & MOUSE_BUTTON_MASK_LEFT) == 0:
			return
		if _hold_elapsed and not _drag_begun:
			if get_global_mouse_position().distance_to(_press_global) >= DRAG_PX:
				_drag_begun = true
				row_drag_started.emit(self)
				get_viewport().set_input_as_handled()


func _on_hold_timeout() -> void:
	_hold_elapsed = true


func _ensure_highlight_overlay() -> void:
	if _highlight_overlay:
		return
	_highlight_overlay = ColorRect.new()
	_highlight_overlay.name = "HighlightOverlay"
	_highlight_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_highlight_overlay.visible = false
	_highlight_overlay.color = Color.TRANSPARENT
	_highlight_overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(_highlight_overlay)


func show_drop_highlight(is_valid: bool) -> void:
	_ensure_highlight_overlay()
	_highlight_overlay.color = (
		UITheme.get_drag_drop_highlight_valid()
		if is_valid
		else UITheme.get_drag_drop_highlight_invalid()
	)
	_highlight_overlay.visible = true


func clear_drop_highlight() -> void:
	if _highlight_overlay:
		_highlight_overlay.visible = false
		_highlight_overlay.color = Color.TRANSPARENT


func set_drag_source_dimmed(dim: bool) -> void:
	modulate = Color(1, 1, 1, 0.5) if dim else _base_modulate


func reset_drag_visuals() -> void:
	clear_drop_highlight()
	set_drag_source_dimmed(false)
