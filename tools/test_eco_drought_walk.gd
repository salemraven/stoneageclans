extends SceneTree

var _failed := 0


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	print("=== ECO_DROUGHT_WALK start ===")
	await process_frame
	var cs: Node = root.get_node_or_null("/root/ClimateState")
	var sim: Node = root.get_node_or_null("/root/ClimateSimulator")
	var tq: Node = root.get_node_or_null("/root/TerrainQuery")
	cs.enable_for_tests()
	cs.reset_knobs()
	var swamp0 := float(tq.sample_climate_histogram(48).get("4", 0.0))
	var w0 := float(tq.sample_climate_histogram(48).get("7", 0.0))
	cs.active_event = "drought"
	var saw_water := false
	var saw_desert := false
	var near_up := false
	var prev_swamp := swamp0
	var near0 := 0.0
	for i in 45:
		sim.advance_day()
		var h: Dictionary = tq.sample_climate_histogram(48)
		var w := float(h.get("7", 0.0))
		var d := float(h.get("2", 0.0))
		var sw := float(h.get("4", 0.0))
		if w < w0 - 0.002:
			saw_water = true
		if sw < prev_swamp - 0.35:
			_fail("swamp pop day %d %s -> %s" % [i, prev_swamp, sw])
		prev_swamp = sw
		var snap: Dictionary = tq.eco_hud_snapshot(48)
		var dn := float(snap.get("desert_near", 0.0))
		var df := float(snap.get("desert_far", 0.0))
		if i == 0:
			near0 = dn
		if dn > near0 + 0.01:
			near_up = true
		if d > 0.02:
			saw_desert = true
			if not saw_water:
				_fail("desert before water day %d" % i)
			if df + 0.002 < dn:
				_fail("far should exceed near desert")
	if not saw_desert:
		_fail("no desert formed")
	if not near_up:
		print("NOTE desert_near did not rise (may need more days)")
	print("=== ECO_DROUGHT_WALK done failed=%d ===" % _failed)
	quit(0 if _failed == 0 else 1)


func _fail(msg: String) -> void:
	_failed += 1
	print("FAIL %s" % msg)
