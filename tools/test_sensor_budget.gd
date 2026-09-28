extends SceneTree


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	await process_frame
	var src := FileAccess.get_file_as_string("res://scripts/npc/npc_base.gd")
	if not src.contains("func _apply_sensor_budget"):
		push_error("TEST_SENSOR: missing _apply_sensor_budget")
		quit(1)
		return
	if not src.contains("func _apply_fighter_perception_off"):
		push_error("TEST_SENSOR: missing fighter perception off")
		quit(1)
		return
	var claim := FileAccess.get_file_as_string("res://scripts/land_claim.gd")
	if claim.contains("get_overlapping_bodies"):
		push_error("TEST_SENSOR: land_claim still calls get_overlapping_bodies")
		quit(1)
		return
	if not claim.contains("_refresh_lists_from_grid"):
		push_error("TEST_SENSOR: missing grid claim refresh")
		quit(1)
		return
	print("TEST_SENSOR: ok")
	quit(0)
