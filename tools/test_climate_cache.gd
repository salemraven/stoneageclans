extends SceneTree
## Gate G: cache invalidation.

var _failed := 0


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	print("=== CLIMATE_CACHE_TEST start ===")
	await process_frame
	var tq: Node = root.get_node_or_null("/root/TerrainQuery")
	var cs: Node = root.get_node_or_null("/root/ClimateState")
	cs.enable_for_tests()
	var p := Vector2(30000, 31000)
	var gen0: int = cs.cache_generation()
	var a: int = tq.get_effective_biome(p)
	var gen1: int = cs.cache_generation()
	var b: int = tq.get_effective_biome(p)
	if a != b:
		_fail("cached answers differ")
	if gen1 != gen0:
		_fail("generation bumped on read")
	cs.set_region_knobs("W", -0.9, 0.0)
	var gen2: int = cs.cache_generation()
	if gen2 <= gen1:
		_fail("knob change must bump cache gen")
	else:
		print("PASS cache gen %d -> %d" % [gen1, gen2])
	var sim: Node = root.get_node_or_null("/root/ClimateSimulator")
	cs.active_event = "ice_age"
	var gen3: int = cs.cache_generation()
	sim.skip_days(10)
	var gen4: int = cs.cache_generation()
	if gen4 <= gen3:
		_fail("skip 10 must bump generation")
	var c1: int = tq.get_effective_biome(p)
	var c2: int = tq.get_effective_biome(p)
	if c1 != c2:
		_fail("second query after skip mismatch")
	else:
		print("PASS skip10 gen %d -> %d id=%d" % [gen3, gen4, c1])
	print("=== CLIMATE_CACHE_TEST done failed=%d ===" % _failed)
	quit(0 if _failed == 0 else 1)


func _fail(msg: String) -> void:
	_failed += 1
	print("FAIL %s" % msg)
