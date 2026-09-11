extends SceneTree

var _failed := 0


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	print("=== ECO_DROUGHT_LADDER start ===")
	await process_frame
	var cs: Node = root.get_node_or_null("/root/ClimateState")
	var sim: Node = root.get_node_or_null("/root/ClimateSimulator")
	var tq: Node = root.get_node_or_null("/root/TerrainQuery")
	cs.enable_for_tests()
	cs.reset_knobs()
	var h0: Dictionary = tq.sample_climate_histogram(48)
	var w0 := float(tq.sample_authored_river_keep(24))
	var d0 := float(h0.get("2", 0.0))
	var f0 := float(h0.get("6", 0.0))
	var s0 := float(h0.get("4", 0.0))
	cs.active_event = "drought"
	var saw_water_drop := false
	var desert_up := false
	for i in 40:
		sim.advance_day()
		var h: Dictionary = tq.sample_climate_histogram(48)
		var w := float(tq.sample_authored_river_keep(24))
		var d := float(h.get("2", 0.0))
		var f := float(h.get("6", 0.0))
		if w < w0 - 0.01:
			saw_water_drop = true
		if d > d0 + 0.004:
			desert_up = true
			if not saw_water_drop:
				_fail("desert rose before water dropped day %d keep=%s->%s" % [i, w0, w])
				break
		if desert_up and f > f0 + 0.01:
			_fail("forest rose while deserting")
		if i == 12 and d > d0 + 0.02 and (f0 - f) < 0.0 and (s0 - float(h.get("4", 0.0))) < 0.0:
			_fail("trees did not fall toward savanna before desert")
	var snap: Dictionary = tq.eco_hud_snapshot(48)
	var dn := float(snap.get("desert_near", 0.0))
	var df := float(snap.get("desert_far", 0.0))
	print("drought desert near=%s far=%s" % [dn, df])
	if dn > df + 0.01:
		_fail("near_river desert should be < far")
	cs.reset_knobs()
	cs.enable_for_tests()
	cs.set_region_knobs("NE", 0.2, -1.0)
	cs.set_region_knobs("SW", 0.0, 0.0)
	var ne: Dictionary = tq.sample_histogram_uv(Vector2(0.66, 0.0), Vector2(1.0, 0.34), 32)
	var sw: Dictionary = tq.sample_histogram_uv(Vector2(0.0, 0.66), Vector2(0.34, 1.0), 32)
	var dne := float(ne.get("2", 0.0))
	var dsw := float(sw.get("2", 0.0))
	print("NE desert=%s SW desert=%s" % [dne, dsw])
	if dne + 0.0005 < dsw:
		_fail("NE desert should be >= SW when only NE is dry")
	else:
		print("PASS NE>=SW drought")
	print("=== ECO_DROUGHT_LADDER done failed=%d ===" % _failed)
	quit(0 if _failed == 0 else 1)


func _fail(msg: String) -> void:
	_failed += 1
	print("FAIL %s" % msg)
