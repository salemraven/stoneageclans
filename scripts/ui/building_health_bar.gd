extends RefCounted
class_name BuildingHealthBar

## World-space health bar for buildings and land claims.
## Hidden at 100% health; green → yellow → red as health drops.

const BAR_WIDTH := 80.0
const BAR_HEIGHT := 8.0
const BAR_TOP_Y := -60.0
const BAR_BOTTOM_Y := -52.0
const FULL_HEALTH_EPSILON := 0.001
const Z_ABOVE_WORLD := 4095

const COLOR_BG := Color(0.15, 0.05, 0.05, 0.85)
const COLOR_GREEN := Color(0.15, 0.85, 0.2, 0.95)
const COLOR_YELLOW := Color(0.95, 0.85, 0.1, 0.95)
const COLOR_RED := Color(0.9, 0.15, 0.1, 0.95)


static func create(parent: Node2D, top_y: float = BAR_TOP_Y, bottom_y: float = BAR_BOTTOM_Y) -> Control:
	var health_bar := Control.new()
	health_bar.name = "HealthBar"
	health_bar.anchor_left = 0.5
	health_bar.anchor_right = 0.5
	health_bar.anchor_top = 0.0
	health_bar.anchor_bottom = 0.0
	health_bar.offset_left = -BAR_WIDTH * 0.5
	health_bar.offset_right = BAR_WIDTH * 0.5
	health_bar.offset_top = top_y
	health_bar.offset_bottom = bottom_y
	health_bar.visible = false
	health_bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	health_bar.z_as_relative = false
	health_bar.z_index = Z_ABOVE_WORLD
	parent.add_child(health_bar)

	var bg_bar := ColorRect.new()
	bg_bar.name = "Background"
	bg_bar.color = COLOR_BG
	bg_bar.anchor_left = 0.0
	bg_bar.anchor_top = 0.0
	bg_bar.anchor_right = 1.0
	bg_bar.anchor_bottom = 1.0
	bg_bar.offset_left = 0.0
	bg_bar.offset_top = 0.0
	bg_bar.offset_right = 0.0
	bg_bar.offset_bottom = 0.0
	bg_bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	health_bar.add_child(bg_bar)

	var health_fill := ColorRect.new()
	health_fill.name = "HealthFill"
	health_fill.color = COLOR_GREEN
	health_fill.anchor_left = 0.0
	health_fill.anchor_top = 0.0
	health_fill.anchor_right = 0.0
	health_fill.anchor_bottom = 0.0
	health_fill.offset_left = 0.0
	health_fill.offset_top = 0.0
	health_fill.offset_right = BAR_WIDTH
	health_fill.offset_bottom = BAR_HEIGHT
	health_fill.mouse_filter = Control.MOUSE_FILTER_IGNORE
	health_bar.add_child(health_fill)

	return health_bar


static func update_bar(health_bar: Control, current_health: float, max_health: float) -> void:
	if health_bar == null or not is_instance_valid(health_bar):
		return
	var health_fill: ColorRect = health_bar.get_node_or_null("HealthFill") as ColorRect
	if health_fill == null:
		return

	var safe_max: float = max(max_health, 0.0001)
	var health_percent: float = clampf(current_health / safe_max, 0.0, 1.0)
	health_bar.visible = health_percent < 1.0 - FULL_HEALTH_EPSILON
	health_fill.offset_right = BAR_WIDTH * health_percent
	health_fill.color = color_for_percent(health_percent)


static func color_for_percent(health_percent: float) -> Color:
	var p: float = clampf(health_percent, 0.0, 1.0)
	if p > 0.6:
		return COLOR_GREEN
	if p > 0.3:
		return COLOR_YELLOW
	return COLOR_RED
