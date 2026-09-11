extends SceneTree

var _failed := 0


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	print("=== ECO_FRONT_RING start ===")
	await process_frame
	var cs: Node = root.get_node_or_null("/root/ClimateState")
	var sim: Node = root.get_node_or_null("/root/ClimateSimulator")
	var tq: Node = root.get_node_or_null("/root/TerrainQuery")
	cs.enable_for_tests()
	cs.reset_knobs()
	cs.active_event = "ice_age"
	var prev_c := 0.0
	var mid_gain_after_center := false
	for d in 24:
		sim.advance_day()
		var snap: Dictionary = tq.eco_hud_snapshot(48)
		var gc := float(snap.get("glacier_center", 0.0))
		var gm := float(snap.get("glacier_mid", 0.0))
		var gco := float(snap.get("glacier_coast", 0.0))
		var dg := float(snap.get("hist", {}).get("5", 0.0))
		if d > 0:
			var delta := absf(gc - prev_c)
			if delta > 0.12 and gc > 0.15:
				print("NOTE center jump day %d %s" % [d, delta])
		if gc > 0.35 and gm > 0.02:
			mid_gain_after_center = true
		if not (gc + 0.001 >= gm and gm + 0.002 >= gco):
			if d > 8:
				_fail("center>=mid>=coast day %d %s %s %s" % [d, gc, gm, gco])
		if gco > 0.08 and float(cs.ice_radius) < 0.42:
			_fail("coast too early")
		prev_c = gc
	if not mid_gain_after_center:
		print("NOTE mid stayed empty (ring may still be in center band)")
	cs.reset_knobs()
	cs.enable_for_tests()
	cs.active_event = "ice_age"
	var bf: Node = root.get_node_or_null("/root/BiomeFronts")
	sim.skip_days(24)
	var r2 := float(cs.ice_radius)
	cs.reset_knobs()
	cs.enable_for_tests()
	cs.active_event = "ice_age"
	for _i in 24:
		sim.advance_day()
	if absf(float(cs.ice_radius) - r2) > 0.0001:
		_fail("catch-up radius")
	else:
		print("PASS catch-up r=%s" % cs.ice_radius)
	print("=== ECO_FRONT_RING done failed=%d ===" % _failed)
	quit(0 if _failed == 0 else 1)


func _fail(msg: String) -> void:
	_failed += 1
	print("FAIL %s" % msg)
