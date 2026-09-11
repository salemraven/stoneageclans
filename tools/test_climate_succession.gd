extends SceneTree
## Grow/recede property tests.

var _failed := 0


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	print("=== CLIMATE_SUCCESSION_TEST start ===")
	await process_frame
	var tq: Node = root.get_node_or_null("/root/TerrainQuery")
	var cs: Node = root.get_node_or_null("/root/ClimateState")
	cs.enable_for_tests()
	var h0: Dictionary = tq.sample_climate_histogram(48)
	cs.set_region_knobs("CENTER", -0.3, 0.0)
	var h1: Dictionary = tq.sample_climate_histogram(48)
	cs.set_region_knobs("CENTER", -0.7, 0.0)
	var h2: Dictionary = tq.sample_climate_histogram(48)
	var g0 := float(h0.get("5", 0.0))
	var g1 := float(h1.get("5", 0.0))
	var g2 := float(h2.get("5", 0.0))
	if g1 < g0 - 0.0001 or g2 < g1 - 0.0001:
		_fail("colder never decreases glacier %s %s %s" % [g0, g1, g2])
	else:
		print("PASS glacier monotonic %s %s %s" % [g0, g1, g2])
	cs.set_region_knobs("CENTER", 0.0, 0.0)
	var p := Vector2(20000, 20000)
	var a: int = int(tq.get_effective_biome(p))
	var b: int = int(tq.get_effective_biome(p))
	if a != b:
		_fail("repeat query")
	else:
		print("PASS deterministic query")
	print("=== CLIMATE_SUCCESSION_TEST done failed=%d ===" % _failed)
	quit(0 if _failed == 0 else 1)


func _fail(msg: String) -> void:
	_failed += 1
	print("FAIL %s" % msg)
