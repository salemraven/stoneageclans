extends SceneTree

var _failed := 0


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	print("=== ECO_OVERLAP start ===")
	await process_frame
	var cs: Node = root.get_node_or_null("/root/ClimateState")
	var sim: Node = root.get_node_or_null("/root/ClimateSimulator")
	var tq: Node = root.get_node_or_null("/root/TerrainQuery")
	cs.enable_for_tests()
	cs.reset_knobs()
	cs.set_event_flag("ice_age", true)
	cs.set_event_flag("drought", true)
	for _i in 30:
		sim.advance_day()
	var snap: Dictionary = tq.eco_hud_snapshot(48)
	var gc := float(snap.get("glacier_center", 0.0))
	var dc := float(snap.get("hist_center", {}).get("2", 0.0))
	print("overlap g_center=%s desert_center=%s" % [gc, dc])
	if dc > gc and gc < 0.02:
		_fail("center became desert under ice+drought")
	if tq.get_effective_biome(Vector2(80, 80)) != 0:
		print("note corner=%d" % tq.get_effective_biome(Vector2(80, 80)))
	if tq.get_base_biome(Vector2(80, 80)) == 0 and tq.get_effective_biome(Vector2(80, 80)) != 0:
		_fail("ocean corner left ocean")
	var mouths: Array[Vector2] = [Vector2(20000, 32768), Vector2(45000, 20000), Vector2(32768, 18000)]
	for p in mouths:
		if tq.is_base_water(p) and tq.get_effective_biome(p) == 0:
			_fail("river mouth became ocean %s" % p)
	cs.set_event_flag("", false)
	cs.active_event = ""
	var g_paint0 := float(tq.sample_climate_histogram(64).get("5", 0.0))
	for _j in 40:
		sim.advance_day()
	var g_back := float(tq.sample_climate_histogram(64).get("5", 0.0))
	print("recover glacier %s -> %s" % [g_paint0, g_back])
	var d_sav := float(tq.eco_hud_snapshot(64).get("desert_far", 0.0))
	if d_sav > 0.12:
		print("note leftover far desert %s" % d_sav)
	print("=== ECO_OVERLAP done failed=%d ===" % _failed)
	quit(0 if _failed == 0 else 1)


func _fail(msg: String) -> void:
	_failed += 1
	print("FAIL %s" % msg)
