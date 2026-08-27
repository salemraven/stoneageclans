extends SceneTree

const SimRngScript = preload("res://scripts/network/sim_rng.gd")
const TEST_SEED := 424242
const DRAW_COUNT := 1000


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	await process_frame
	var sim: Node = root.get_node_or_null("/root/SimRng")
	if sim == null:
		_fail("SimRng autoload missing")
		return
	sim.set_sim_seed(TEST_SEED)
	var expected: Array[float] = []
	var probe := RandomNumberGenerator.new()
	probe.seed = TEST_SEED if TEST_SEED != 0 else 1
	for _i in DRAW_COUNT:
		expected.append(probe.randf())
	sim.set_sim_seed(TEST_SEED)
	for i in DRAW_COUNT:
		var got: float = sim.sim_randf()
		if not is_equal_approx(got, expected[i]):
			_fail("draw %d mismatch: got %s expected %s" % [i, got, expected[i]])
			return
	if sim.get_draw_count() != DRAW_COUNT:
		_fail("draw count %d != %d" % [sim.get_draw_count(), DRAW_COUNT])
		return
	# Scoped RNG stability
	var scoped_a := SimRngScript.make_scoped_rng(TEST_SEED, 777)
	var scoped_b := SimRngScript.make_scoped_rng(TEST_SEED, 777)
	if not is_equal_approx(scoped_a.randf(), scoped_b.randf()):
		_fail("scoped rng not stable")
		return
	print("TEST_SIM_RNG_DETERMINISM: all checks passed")
	quit(0)


func _fail(msg: String) -> void:
	push_error("TEST_SIM_RNG_DETERMINISM_FAIL: %s" % msg)
	print("FAIL: ", msg)
	quit(1)
