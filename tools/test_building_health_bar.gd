extends SceneTree

const BuildingHealthBar = preload("res://scripts/ui/building_health_bar.gd")

## Headless: BuildingHealthBar visibility + color tiers.
func _initialize() -> void:
	var host := Node2D.new()
	root.add_child(host)
	var bar: Control = BuildingHealthBar.create(host)

	BuildingHealthBar.update_bar(bar, 100.0, 100.0)
	assert(not bar.visible, "full health hides bar")

	BuildingHealthBar.update_bar(bar, 80.0, 100.0)
	assert(bar.visible, "damaged shows bar")
	var fill: ColorRect = bar.get_node("HealthFill") as ColorRect
	assert(fill.color.is_equal_approx(BuildingHealthBar.COLOR_GREEN), "80% is green")

	BuildingHealthBar.update_bar(bar, 45.0, 100.0)
	assert(fill.color.is_equal_approx(BuildingHealthBar.COLOR_YELLOW), "45% is yellow")

	BuildingHealthBar.update_bar(bar, 10.0, 100.0)
	assert(fill.color.is_equal_approx(BuildingHealthBar.COLOR_RED), "10% is red")
	assert(is_equal_approx(fill.offset_right, 8.0), "width scales with health")

	print("TEST_BUILDING_HEALTH_BAR_OK")
	quit(0)
