extends SceneTree

## Nearby player scans are 10 Hz helpers, not per-frame group walks.

func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	await process_frame
	var src := FileAccess.get_file_as_string("res://scripts/main.gd")
	if not src.contains("PLAYER_NEARBY_CHECK_SEC"):
		push_error("TEST_PLAYER_PROXIMITY: missing PLAYER_NEARBY_CHECK_SEC")
		quit(1)
		return
	if not src.contains("0.1"):
		push_error("TEST_PLAYER_PROXIMITY: expected 0.1s interval")
		quit(1)
		return
	if not src.contains("func _check_nearby_corpses"):
		push_error("TEST_PLAYER_PROXIMITY: missing _check_nearby_corpses")
		quit(1)
		return
	if not src.contains("func _check_nearby_buildings"):
		push_error("TEST_PLAYER_PROXIMITY: missing _check_nearby_buildings")
		quit(1)
		return
	if not src.contains("func _check_nearby_travois_ground"):
		push_error("TEST_PLAYER_PROXIMITY: missing _check_nearby_travois_ground")
		quit(1)
		return
	if src.contains("CORPSE DETECTED"):
		push_error("TEST_PLAYER_PROXIMITY: per-frame corpse print still present")
		quit(1)
		return
	if not src.contains("get_cached_land_claims()"):
		push_error("TEST_PLAYER_PROXIMITY: buildings check should use claim cache")
		quit(1)
		return
	if not src.contains("const PLAYER_NEARBY_CHECK_SEC: float = 0.1"):
		push_error("TEST_PLAYER_PROXIMITY: PLAYER_NEARBY_CHECK_SEC must be 0.1")
		quit(1)
		return
	print("TEST_PLAYER_PROXIMITY: ok interval=0.1")
	quit(0)
