extends SceneTree

var _failed := 0


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	print("=== ECO_ICE_RINGS start ===")
	await process_frame
	var cs: Node = root.get_node_or_null("/root/ClimateState")
	var sim: Node = root.get_node_or_null("/root/ClimateSimulator")
	var tq: Node = root.get_node_or_null("/root/TerrainQuery")
	cs.enable_for_tests()
	cs.reset_knobs()
	cs.active_event = "ice_age"
	for _i in 28:
		sim.advance_day()
	var snap: Dictionary = tq.eco_hud_snapshot(48)
	var gc := float(snap.get("glacier_center", 0.0))
	var gm := float(snap.get("glacier_mid", 0.0))
	var gco := float(snap.get("glacier_coast", 0.0))
	print("rings center=%s mid=%s coast=%s radius=%s" % [gc, gm, gco, cs.ice_radius])
	if not (gc > gm and gm >= gco - 0.002):
		_fail("center > mid > coast %s %s %s" % [gc, gm, gco])
	if gco > 0.08 and float(cs.ice_radius) < 0.42:
		_fail("coast glacier too early %s r=%s" % [gco, cs.ice_radius])
	var r_a := float(cs.ice_radius)
	var cell_a: int = tq.get_effective_biome(Vector2(32768, 32768))
	cs.reset_knobs()
	cs.enable_for_tests()
	cs.active_event = "ice_age"
	sim.skip_days(28)
	if absf(float(cs.ice_radius) - r_a) > 0.0001:
		_fail("catch-up radius %s vs %s" % [cs.ice_radius, r_a])
	if tq.get_effective_biome(Vector2(32768, 32768)) != cell_a:
		_fail("catch-up golden cell")
	else:
		print("PASS catch-up radius=%s cell=%d" % [cs.ice_radius, cell_a])
	print("=== ECO_ICE_RINGS done failed=%d ===" % _failed)
	quit(0 if _failed == 0 else 1)


func _fail(msg: String) -> void:
	_failed += 1
	print("FAIL %s" % msg)
