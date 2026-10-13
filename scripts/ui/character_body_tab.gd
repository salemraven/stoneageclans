extends Control
class_name CharacterBodyTab

const BodyTabData = preload("res://scripts/ui/character_body_tab_data.gd")
const ThemeScript = preload("res://scripts/ui/ui_theme.gd")

const COLOR_WOUND_BG := Color(0.35, 0.14, 0.12, 0.35)
const COLOR_WOUND_BORDER := Color(0.85, 0.22, 0.18, 0.95)
const COLOR_HEAL_TRACK := Color(0.12, 0.1, 0.09, 0.9)
const COLOR_HEAL_FILL := Color(0.75, 0.18, 0.14, 0.95)
const COLOR_SCAR_BG := Color(0.22, 0.2, 0.18, 0.5)
const COLOR_SCAR_BORDER := Color(0.55, 0.52, 0.48, 0.85)

var wounds_list: VBoxContainer = null
var scars_list: VBoxContainer = null
var _empty_wounds_label: Label = null


func _ready() -> void:
	size_flags_horizontal = Control.SIZE_EXPAND_FILL
	size_flags_vertical = Control.SIZE_EXPAND_FILL
	var root := VBoxContainer.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.add_theme_constant_override("separation", 8)
	add_child(root)
	
	_add_header(root, "Wounds now")
	wounds_list = VBoxContainer.new()
	wounds_list.add_theme_constant_override("separation", 6)
	root.add_child(wounds_list)
	_empty_wounds_label = Label.new()
	_empty_wounds_label.text = "No open wounds"
	_empty_wounds_label.add_theme_font_size_override("font_size", 12)
	_empty_wounds_label.add_theme_color_override("font_color", ThemeScript.COLOR_TEXT_SECONDARY)
	wounds_list.add_child(_empty_wounds_label)
	
	_add_header(root, "Scars")
	scars_list = VBoxContainer.new()
	scars_list.add_theme_constant_override("separation", 4)
	root.add_child(scars_list)


func _add_header(parent: Control, text: String) -> void:
	var h := Label.new()
	h.text = text
	h.add_theme_font_size_override("font_size", 12)
	h.add_theme_color_override("font_color", ThemeScript.COLOR_TEXT_SELECTED)
	parent.add_child(h)


func refresh(npc: Node) -> void:
	var state: Dictionary = BodyTabData.get_display_state(npc)
	var active: Array = state.get("active", [])
	var scars: Array = state.get("scars", [])
	_rebuild_wounds(active)
	_rebuild_scars(scars)


func _rebuild_wounds(active: Array) -> void:
	for c in wounds_list.get_children():
		if c != _empty_wounds_label:
			c.queue_free()
	_empty_wounds_label.visible = active.is_empty()
	for row in active:
		if not row is Dictionary:
			continue
		wounds_list.add_child(_make_wound_row(row))


func _make_wound_row(data: Dictionary) -> Control:
	var wrap := Panel.new()
	wrap.custom_minimum_size = Vector2(0, 56)
	var style := StyleBoxFlat.new()
	style.bg_color = COLOR_WOUND_BG
	style.border_width_left = 4
	style.border_color = COLOR_WOUND_BORDER
	style.corner_radius_top_left = 6
	style.corner_radius_top_right = 6
	style.corner_radius_bottom_left = 6
	style.corner_radius_bottom_right = 6
	wrap.add_theme_stylebox_override("panel", style)
	
	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 10)
	margin.add_theme_constant_override("margin_top", 6)
	margin.add_theme_constant_override("margin_right", 10)
	margin.add_theme_constant_override("margin_bottom", 8)
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	wrap.add_child(margin)
	
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 4)
	margin.add_child(v)
	
	var title := Label.new()
	title.text = str(data.get("display_title", _fallback_title(data)))
	title.add_theme_font_size_override("font_size", 14)
	title.add_theme_color_override("font_color", ThemeScript.COLOR_TEXT_PRIMARY)
	v.add_child(title)
	
	var progress: float = float(data.get("heal_progress", 0.0))
	var track := Panel.new()
	track.custom_minimum_size = Vector2(0, 8)
	track.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	track.set_meta("heal_progress", progress)
	var track_style := StyleBoxFlat.new()
	track_style.bg_color = COLOR_HEAL_TRACK
	track_style.corner_radius_top_left = 3
	track_style.corner_radius_top_right = 3
	track_style.corner_radius_bottom_left = 3
	track_style.corner_radius_bottom_right = 3
	track.add_theme_stylebox_override("panel", track_style)
	v.add_child(track)
	
	var fill := Panel.new()
	fill.name = "HealFill"
	fill.mouse_filter = Control.MOUSE_FILTER_IGNORE
	track.add_child(fill)
	_apply_heal_fill(track, fill, progress)
	
	return wrap


func _apply_heal_fill(track: Panel, fill: Panel, progress: float) -> void:
	# progress 0 = fresh wound (bar full); 1 = healed (bar empty, retreats left).
	var w: float = maxf(track.size.x, track.custom_minimum_size.x)
	if w < 4.0:
		w = 280.0
	var remaining: float = 1.0 - clampf(progress, 0.0, 1.0)
	var fill_w: float = w * remaining
	var h: float = 8.0
	var fill_style := StyleBoxFlat.new()
	fill_style.bg_color = COLOR_HEAL_FILL
	fill_style.corner_radius_top_left = 3
	fill_style.corner_radius_top_right = 3
	fill_style.corner_radius_bottom_left = 3
	fill_style.corner_radius_bottom_right = 3
	fill.add_theme_stylebox_override("panel", fill_style)
	fill.custom_minimum_size = Vector2(fill_w, h)
	fill.set_anchors_and_offsets_preset(Control.PRESET_TOP_LEFT)
	fill.offset_right = fill_w
	fill.offset_bottom = h


func _rebuild_scars(scars: Array) -> void:
	for c in scars_list.get_children():
		c.queue_free()
	if scars.is_empty():
		var empty := Label.new()
		empty.text = "None yet"
		empty.add_theme_font_size_override("font_size", 12)
		empty.add_theme_color_override("font_color", ThemeScript.COLOR_TEXT_SECONDARY)
		scars_list.add_child(empty)
		return
	for row in scars:
		if not row is Dictionary:
			continue
		scars_list.add_child(_make_scar_row(row))


func _make_scar_row(data: Dictionary) -> Control:
	var wrap := Panel.new()
	wrap.custom_minimum_size = Vector2(0, 32)
	var style := StyleBoxFlat.new()
	style.bg_color = COLOR_SCAR_BG
	style.border_width_left = 3
	style.border_color = COLOR_SCAR_BORDER
	style.corner_radius_top_left = 6
	style.corner_radius_top_right = 6
	style.corner_radius_bottom_left = 6
	style.corner_radius_bottom_right = 6
	wrap.add_theme_stylebox_override("panel", style)
	
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 8)
	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 10)
	margin.add_theme_constant_override("margin_right", 10)
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	wrap.add_child(margin)
	margin.add_child(h)
	
	var label := Label.new()
	label.text = str(data.get("display_title", _fallback_title(data)))
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	label.add_theme_font_size_override("font_size", 13)
	label.add_theme_color_override("font_color", ThemeScript.COLOR_TEXT_SECONDARY)
	h.add_child(label)
	return wrap


func _fallback_title(data: Dictionary) -> String:
	return BodyTabData.format_injury_title(
		str(data.get("part_label", "wound")),
		str(data.get("weapon", ""))
	)
