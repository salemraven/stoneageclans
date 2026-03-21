extends Control
class_name DropdownMenuUI

## Context menu (Mac/Windows style): right-click opens, hover highlights, left-click confirms.
## Step 1 — integration_plan.md

signal option_selected(id: String)

const OPTION_HEIGHT := 32
const MENU_MIN_WIDTH := 160
const MENU_PADDING := 8
const OPTION_SEPARATION := 2

var _overlay: ColorRect = null
var _panel: Panel = null
var _options_container: VBoxContainer = null
var _option_buttons: Array[Button] = []
var _target: Variant = null
var _options: Array[Dictionary] = []
var _is_open: bool = false
var _frozen_npc: Node = null  # NPC we froze while menu is open; unfreeze on hide

func _ready() -> void:
	visible = false
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_preset(Control.PRESET_FULL_RECT)
	custom_minimum_size = Vector2(1280, 720)
	_setup_ui()

func _setup_ui() -> void:
	# Full-screen transparent overlay: click outside → close (behind panel)
	_overlay = ColorRect.new()
	_overlay.name = "Overlay"
	_overlay.color = Color(0, 0, 0, 0)
	_overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	_overlay.gui_input.connect(_on_overlay_gui_input)
	_overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	_overlay.offset_left = 0
	_overlay.offset_top = 0
	_overlay.offset_right = 0
	_overlay.offset_bottom = 0
	add_child(_overlay)

	# Menu panel (on top of overlay)
	_panel = Panel.new()
	_panel.name = "MenuPanel"
	UITheme.apply_panel_style(_panel)
	_panel.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(_panel)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", MENU_PADDING)
	margin.add_theme_constant_override("margin_top", MENU_PADDING)
	margin.add_theme_constant_override("margin_right", MENU_PADDING)
	margin.add_theme_constant_override("margin_bottom", MENU_PADDING)
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_panel.add_child(margin)

	_options_container = VBoxContainer.new()
	_options_container.add_theme_constant_override("separation", OPTION_SEPARATION)
	margin.add_child(_options_container)

func _on_overlay_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed:
		hide_menu()
		get_viewport().set_input_as_handled()

func _process(_delta: float) -> void:
	if not _is_open:
		return
	# Step 4: target invalidated (e.g. NPC died) while menu open → hide
	if _target is Node and not is_instance_valid(_target):
		hide_menu()

func _input(event: InputEvent) -> void:
	if not _is_open:
		return
	if event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE:
		hide_menu()
		get_viewport().set_input_as_handled()

func _update_overlay_size() -> void:
	# Overlay already full rect; ensure root size matches viewport
	var viewport := get_viewport()
	if viewport:
		var vs := viewport.get_visible_rect().size
		custom_minimum_size = vs

func _clear_options() -> void:
	for c in _options_container.get_children():
		c.queue_free()
	_option_buttons.clear()

func _build_options() -> void:
	_clear_options()
	for opt in _options:
		var id_val: String = opt.get("id", "")
		var label_val: String = opt.get("label", "")
		var btn := Button.new()
		btn.text = label_val
		btn.custom_minimum_size = Vector2(MENU_MIN_WIDTH - MENU_PADDING * 2, OPTION_HEIGHT)
		btn.flat = false
		# Use theme for hover-like highlight; Button highlights by default
		btn.pressed.connect(_on_option_pressed.bind(id_val))
		_options_container.add_child(btn)
		_option_buttons.append(btn)

func _on_option_pressed(id: String) -> void:
	option_selected.emit(id)
	hide_menu(id)

func _freeze_npc_movement(npc: Node, freeze: bool) -> void:
	if not npc or not is_instance_valid(npc):
		return
	if not "velocity" in npc:
		return
	if freeze:
		npc.velocity = Vector2.ZERO
		npc.set_meta("inspection_frozen", true)
	else:
		if npc.has_meta("inspection_frozen"):
			npc.remove_meta("inspection_frozen")

func show_at(target: Variant, screen_position: Vector2, options: Array) -> void:
	_target = target
	_options.clear()
	for o in options:
		if o is Dictionary:
			_options.append({ "id": str(o.get("id", "")), "label": str(o.get("label", "")) })
		else:
			continue
	_build_options()
	_update_overlay_size()

	var viewport := get_viewport()
	var viewport_size: Vector2 = viewport.get_visible_rect().size if viewport else Vector2(1280, 720)
	var n := _option_buttons.size()
	var panel_width := float(MENU_MIN_WIDTH)
	var panel_height := MENU_PADDING * 2
	if n > 0:
		panel_height += n * OPTION_HEIGHT + maxi(0, n - 1) * OPTION_SEPARATION
	else:
		panel_height += OPTION_HEIGHT
	_panel.custom_minimum_size = Vector2(panel_width, panel_height)

	# Clamp position so menu stays on screen
	var pos := screen_position
	pos.x = clampf(pos.x, 8, viewport_size.x - panel_width - 8)
	pos.y = clampf(pos.y, 8, viewport_size.y - panel_height - 8)
	_panel.position = pos

	# Freeze NPC while menu is open (same as character menu inspection)
	if target is Node and is_instance_valid(target):
		_freeze_npc_movement(target, true)
		_frozen_npc = target

	_is_open = true
	visible = true
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	_panel.mouse_filter = Control.MOUSE_FILTER_STOP

func hide_menu(option_id: String = "") -> void:
	# Unfreeze NPC first, unless opening character menu (Info) — it will freeze
	if option_id != "info":
		if _frozen_npc and is_instance_valid(_frozen_npc):
			_freeze_npc_movement(_frozen_npc, false)
	_frozen_npc = null

	_is_open = false
	visible = false
	_target = null
	_options.clear()
	_clear_options()
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	if _overlay:
		_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if _panel:
		_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE

func is_menu_open() -> bool:
	return _is_open

func get_target() -> Variant:
	return _target
