extends SceneTree

var _failed := 0


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	print("=== ECO_NEIGHBORS start ===")
	await process_frame
	var cs: Node = root.get_node_or_null("/root/ClimateState")
	var sim: Node = root.get_node_or_null("/root/ClimateSimulator")
	var tq: Node = root.get_node_or_null("/root/TerrainQuery")
	cs.enable_for_tests()
	cs.reset_knobs()
	var g0 := float(tq.sample_climate_histogram(64).get("5", 0.0))
	cs.active_event = "ice_age"
	sim.skip_days(18)
	var g1 := float(tq.sample_climate_histogram(64).get("5", 0.0))
	print("glacier painted+front %s -> %s" % [g0, g1])
	if g1 < g0:
		_fail("ice should not shrink painted cap")
	# blotch: not a perfect filled disk — mid should be less than center
	var snap: Dictionary = tq.eco_hud_snapshot(48)
	var gc := float(snap.get("glacier_center", 0.0))
	var gm := float(snap.get("glacier_mid", 0.0))
	if gm > gc + 0.05:
		_fail("mid ice ahead of center")
	print("center=%s mid=%s" % [gc, gm])
	print("=== ECO_NEIGHBORS done failed=%d ===" % _failed)
	quit(0 if _failed == 0 else 1)


func _fail(msg: String) -> void:
	_failed += 1
	print("FAIL %s" % msg)
