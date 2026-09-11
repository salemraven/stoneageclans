extends SceneTree

var _failed := 0


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	print("=== ECO_HYSTERESIS start ===")
	await process_frame
	var cs: Node = root.get_node_or_null("/root/ClimateState")
	var sim: Node = root.get_node_or_null("/root/ClimateSimulator")
	var tq: Node = root.get_node_or_null("/root/TerrainQuery")
	cs.enable_for_tests()
	cs.reset_knobs()
	if tq.get_base_biome(Vector2(80, 80)) == 0 and tq.get_effective_biome(Vector2(80, 80)) != 0:
		_fail("ocean left ocean at start")
	cs.active_event = "drought"
	for _i in 20:
		sim.advance_day()
	var bf: Node = root.get_node_or_null("/root/BiomeFronts")
	var d_dry := int(bf.get_last_metrics().get("dry4", 0))
	var hist_dry := float(tq.sample_climate_histogram(48).get("2", 0.0))
	cs.active_event = ""
	for _j in 4:
		sim.advance_day()
	var d_early := int(bf.get_last_metrics().get("dry4", 0))
	print("dry4 after 20 dry=%s after 4 recover=%s hist_desert=%s" % [d_dry, d_early, hist_dry])
	if d_dry > 80 and d_early < int(float(d_dry) * 0.2):
		_fail("recover erased drought desert too fast %s -> %s" % [d_dry, d_early])
	if tq.get_base_biome(Vector2(80, 80)) == 0 and tq.get_effective_biome(Vector2(80, 80)) != 0:
		_fail("ocean left ocean after recover")
	for _k in 56:
		sim.advance_day()
	var d_late := int(bf.get_last_metrics().get("dry4", 0))
	print("dry4 late recover=%s" % d_late)
	if d_dry > 80 and d_late > int(float(d_dry) * 0.15):
		_fail("drought off did not bring desert back down %s -> %s" % [d_dry, d_late])
	print("=== ECO_HYSTERESIS done failed=%d ===" % _failed)
	quit(0 if _failed == 0 else 1)


func _fail(msg: String) -> void:
	_failed += 1
	print("FAIL %s" % msg)
