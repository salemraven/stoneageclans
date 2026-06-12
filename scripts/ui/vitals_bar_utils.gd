extends RefCounted
class_name VitalsBarUtils

const _UIThemeScript = preload("res://scripts/ui/ui_theme.gd")

## Shared HUD vitals bars: health, calories (food), hydration (water placeholder).
## Green above yellow threshold, yellow above red threshold, red at/below red threshold.

enum BarKind { HEALTH, CALORIES, WATER }

const YELLOW_ABOVE: float = 0.65
const RED_ABOVE: float = 0.25

const COLOR_BG := Color(0.12, 0.12, 0.14, 0.88)
const COLOR_GREEN := Color(0.15, 0.85, 0.2, 0.95)
const COLOR_YELLOW := Color(0.95, 0.85, 0.1, 0.95)
const COLOR_RED := Color(0.9, 0.15, 0.1, 0.95)
const COLOR_CALORIES_FULL := Color(0.92, 0.28, 0.12, 0.95)
const COLOR_WATER_FULL := Color(0.22, 0.58, 0.98, 0.95)


static func color_for_percent(percent: float, kind: BarKind = BarKind.HEALTH) -> Color:
	var p: float = clampf(percent, 0.0, 1.0)
	if p > YELLOW_ABOVE:
		match kind:
			BarKind.CALORIES:
				return COLOR_CALORIES_FULL
			BarKind.WATER:
				return COLOR_WATER_FULL
			_:
				return COLOR_GREEN
	if p > RED_ABOVE:
		return COLOR_YELLOW
	return COLOR_RED


static func create_compact_bar(bar_name: String, width: float, height: float) -> Control:
	var bar := Control.new()
	bar.name = bar_name
	bar.custom_minimum_size = Vector2(width, height)
	bar.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	var bg := ColorRect.new()
	bg.name = "Background"
	bg.color = COLOR_BG
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	bar.add_child(bg)

	var fill := ColorRect.new()
	fill.name = "Fill"
	fill.color = COLOR_GREEN
	fill.set_anchors_preset(Control.PRESET_TOP_LEFT)
	fill.mouse_filter = Control.MOUSE_FILTER_IGNORE
	bar.add_child(fill)
	return bar


static func update_compact_bar(bar: Control, percent: float, kind: BarKind = BarKind.HEALTH) -> void:
	if bar == null or not is_instance_valid(bar):
		return
	var fill: ColorRect = bar.get_node_or_null("Fill") as ColorRect
	if fill == null:
		return
	var p: float = clampf(percent, 0.0, 1.0)
	var bar_w: float = maxf(bar.size.x, bar.custom_minimum_size.x)
	if bar_w <= 1.0:
		bar_w = 80.0
	fill.size = Vector2(bar_w * p, maxf(bar.size.y, bar.custom_minimum_size.y))
	fill.color = color_for_percent(p, kind)


## Hotbar layout: full-width health on top, calorie + water half-width row below.
static func create_hotbar_vitals_block(total_width: float, bar_height: float, row_gap: float, half_gap: float) -> Dictionary:
	var root := VBoxContainer.new()
	root.name = "VitalsBars"
	root.add_theme_constant_override("separation", row_gap)

	var health_bar := create_compact_bar("HealthBar", total_width, bar_height)
	root.add_child(health_bar)

	var half_row := HBoxContainer.new()
	half_row.name = "HalfVitalsRow"
	half_row.add_theme_constant_override("separation", half_gap)
	half_row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var half_w: float = maxf(1.0, (total_width - half_gap) * 0.5)
	var calorie_bar := create_compact_bar("CalorieBar", half_w, bar_height)
	var water_bar := create_compact_bar("WaterBar", half_w, bar_height)
	calorie_bar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	water_bar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	half_row.add_child(calorie_bar)
	half_row.add_child(water_bar)
	root.add_child(half_row)

	return {
		"root": root,
		"health_bar": health_bar,
		"calorie_bar": calorie_bar,
		"water_bar": water_bar,
	}


static func create_labeled_bar(label_text: String, bar_width: float = 200.0, bar_height: float = 16.0) -> Control:
	var container := VBoxContainer.new()
	container.add_theme_constant_override("separation", 4)
	container.custom_minimum_size = Vector2(0, bar_height + 20)

	var label := Label.new()
	label.text = label_text
	label.add_theme_font_size_override("font_size", 14)
	label.add_theme_color_override("font_color", _UIThemeScript.COLOR_TEXT_PRIMARY)
	container.add_child(label)

	var bar_bg := Panel.new()
	bar_bg.custom_minimum_size = Vector2(bar_width, bar_height)
	bar_bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var bg_style := StyleBoxFlat.new()
	bg_style.bg_color = COLOR_BG
	bg_style.corner_radius_top_left = 4
	bg_style.corner_radius_top_right = 4
	bg_style.corner_radius_bottom_left = 4
	bg_style.corner_radius_bottom_right = 4
	bar_bg.add_theme_stylebox_override("panel", bg_style)
	container.add_child(bar_bg)

	var bar_fill := Panel.new()
	bar_fill.name = "BarFill"
	bar_fill.mouse_filter = Control.MOUSE_FILTER_IGNORE
	bar_bg.add_child(bar_fill)
	bar_fill.set_meta("bar_width", bar_width)
	bar_fill.set_meta("bar_height", bar_height)
	return container


static func update_labeled_bar(bar_container: Control, percent: float, kind: BarKind = BarKind.HEALTH) -> void:
	if bar_container == null or not is_instance_valid(bar_container):
		return
	var bar_bg: Panel = bar_container.get_child(1) as Panel if bar_container.get_child_count() > 1 else null
	if bar_bg == null:
		return
	var bar_fill: Panel = bar_bg.get_node_or_null("BarFill") as Panel
	if bar_fill == null:
		return
	var bar_width: float = float(bar_fill.get_meta("bar_width", 200.0))
	var bar_height: float = float(bar_fill.get_meta("bar_height", 16.0))
	var p: float = clampf(percent, 0.0, 1.0)
	var fill_width: float = bar_width * p
	var fill_style := StyleBoxFlat.new()
	fill_style.bg_color = color_for_percent(p, kind)
	fill_style.corner_radius_top_left = 4
	fill_style.corner_radius_top_right = 4
	fill_style.corner_radius_bottom_left = 4
	fill_style.corner_radius_bottom_right = 4
	bar_fill.add_theme_stylebox_override("panel", fill_style)
	bar_fill.custom_minimum_size = Vector2(fill_width, bar_height)
	bar_fill.set_anchors_and_offsets_preset(Control.PRESET_TOP_LEFT)
	bar_fill.offset_left = 0
	bar_fill.offset_top = 0
	bar_fill.offset_right = fill_width
	bar_fill.offset_bottom = bar_height
