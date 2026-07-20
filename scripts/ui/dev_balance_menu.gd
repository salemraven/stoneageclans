extends Control
class_name DevBalanceMenu

## In-game dev panel for ClanBrainTuningConfig. F10 toggles when godmode/debug enabled.

var _panel: Panel
var _scroll: ScrollContainer
var _fields: VBoxContainer
var _visible_flag: bool = false


func _ready() -> void:
	visible = false
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_preset(Control.PRESET_BOTTOM_LEFT)
	offset_left = 12.0
	offset_top = -420.0
	offset_right = 320.0
	offset_bottom = -12.0
	_build_ui()
	var tuning: Node = get_node_or_null("/root/ClanBrainTuningConfig")
	if tuning and tuning.has_signal("tuning_changed"):
		tuning.tuning_changed.connect(_on_tuning_changed)


func _build_ui() -> void:
	_panel = Panel.new()
	_panel.mouse_filter = Control.MOUSE_FILTER_STOP
	UITheme.apply_panel_style(_panel)
	_panel.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(_panel)

	var root := VBoxContainer.new()
	root.add_theme_constant_override("separation", 6)
	_panel.add_child(root)

	var title := Label.new()
	title.text = "ClanBrain tuning (F10)"
	title.add_theme_font_size_override("font_size", 14)
	root.add_child(title)

	var hint := Label.new()
	hint.text = "Live edits → all AI clans. Reset syncs BalanceConfig defaults."
	hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	hint.add_theme_font_size_override("font_size", 10)
	hint.modulate = Color(0.8, 0.85, 0.8)
	root.add_child(hint)

	var btn_row := HBoxContainer.new()
	root.add_child(btn_row)
	var reset_btn := Button.new()
	reset_btn.text = "Reset defaults"
	reset_btn.pressed.connect(_on_reset_pressed)
	btn_row.add_child(reset_btn)

	_scroll = ScrollContainer.new()
	_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_scroll.custom_minimum_size = Vector2(280.0, 320.0)
	_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	root.add_child(_scroll)

	_fields = VBoxContainer.new()
	_fields.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_fields.add_theme_constant_override("separation", 4)
	_scroll.add_child(_fields)

	_populate_fields()


func _populate_fields() -> void:
	for c in _fields.get_children():
		c.queue_free()
	var tuning: Node = get_node_or_null("/root/ClanBrainTuningConfig")
	if not tuning or not tuning.has_method("get_editable_fields"):
		return
	for entry in tuning.get_editable_fields():
		if entry.has("section"):
			var sec := Label.new()
			sec.text = str(entry["section"])
			sec.add_theme_font_size_override("font_size", 12)
			sec.modulate = Color(0.9, 0.95, 1.0)
			_fields.add_child(sec)
			continue
		var prop: StringName = StringName(str(entry.get("prop", "")))
		if prop == &"":
			continue
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 6)
		var lbl := Label.new()
		lbl.text = str(entry.get("label", prop))
		lbl.custom_minimum_size.x = 140.0
		lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		lbl.add_theme_font_size_override("font_size", 11)
		row.add_child(lbl)
		var typ: String = str(entry.get("type", "float"))
		if typ == "bool":
			var cb := CheckBox.new()
			cb.button_pressed = bool(tuning.get(prop))
			cb.toggled.connect(func(on: bool) -> void:
				if tuning.has_method("set_tuned"):
					tuning.set_tuned(prop, on)
				else:
					tuning.set(prop, on)
			)
			row.add_child(cb)
		else:
			var spin := SpinBox.new()
			spin.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			spin.min_value = float(entry.get("min", 0.0))
			spin.max_value = float(entry.get("max", 100.0))
			spin.step = float(entry.get("step", 0.1))
			if typ == "int":
				spin.rounded = true
				spin.value = float(int(tuning.get(prop)))
			else:
				spin.value = float(tuning.get(prop))
			spin.value_changed.connect(func(v: float) -> void:
				var val: Variant = int(v) if typ == "int" else float(v)
				if tuning.has_method("set_tuned"):
					tuning.set_tuned(prop, val)
				else:
					tuning.set(prop, val)
			)
			row.add_child(spin)
		_fields.add_child(row)


func toggle() -> void:
	_visible_flag = not _visible_flag
	visible = _visible_flag
	if _panel:
		_panel.visible = _visible_flag
	if _visible_flag:
		_populate_fields()


func is_menu_visible() -> bool:
	return _visible_flag


func _on_reset_pressed() -> void:
	var tuning: Node = get_node_or_null("/root/ClanBrainTuningConfig")
	if tuning and tuning.has_method("sync_defaults_from_balance_config"):
		tuning.sync_defaults_from_balance_config()
	_populate_fields()


func _on_tuning_changed(_prop: StringName) -> void:
	if _visible_flag:
		_populate_fields()
