extends SceneTree

const BenchMath = preload("res://tools/bench_math.gd")

var _failed := 0


func _init() -> void:
	_test_bins()
	_test_compare_regress()
	_test_invalid_zero_fighters()
	if _failed > 0:
		push_error("TEST_BENCH_BINS: %d fail(s)" % _failed)
		quit(1)
		return
	print("TEST_BENCH_BINS: ok")
	quit(0)


func _row(awake: int, usec: float) -> Dictionary:
	return {
		"evt": "interval",
		"npcs_physics_process": awake,
		"npc_usec_per_tick": usec,
		"npc_physics_ticks": 60,
		"npc_physics_usec": int(usec * 60.0),
	}


func _test_bins() -> void:
	var rows: Array = [
		_row(22, 200.0),
		_row(23, 220.0),
		_row(24, 210.0),
		_row(31, 180.0),
	]
	var bins: Dictionary = BenchMath.bin_rows(rows)
	if not bins.has(20) or not bins.has(30):
		_fail("expected bins 20 and 30")
		return
	var m20: float = float((bins[20] as Dictionary)["mean"])
	if absf(m20 - 210.0) > 0.01:
		_fail("bin 20 mean want 210 got %s" % m20)
	if int((bins[20] as Dictionary)["n"]) != 3:
		_fail("bin 20 n want 3")
	if int((bins[30] as Dictionary)["n"]) != 1:
		_fail("bin 30 n want 1")


func _test_compare_regress() -> void:
	var before: Dictionary = {
		20: {"mean": 200.0, "n": 5},
		30: {"mean": 180.0, "n": 5},
	}
	var after_ok: Dictionary = {
		20: {"mean": 205.0, "n": 5},
		30: {"mean": 170.0, "n": 5},
	}
	var ok: Dictionary = BenchMath.compare_bins(before, after_ok)
	if not bool(ok["ok"]):
		_fail("2.5% slower should pass the 5% floor")
	var after_fail: Dictionary = {
		20: {"mean": 212.0, "n": 5},
		30: {"mean": 180.0, "n": 5},
	}
	var bad: Dictionary = BenchMath.compare_bins(before, after_fail)
	if bool(bad["ok"]):
		_fail("6% slower in one bin should fail compare")


func _test_invalid_zero_fighters() -> void:
	var rows: Array = [_row(10, 200.0), _row(12, 190.0)]
	var v: Dictionary = BenchMath.validate_run(rows, 0, 4, 3, 180.0, 45.0)
	if bool(v["ok"]):
		_fail("peak_fighters=0 must be invalid")
	var v2: Dictionary = BenchMath.validate_run(rows, 24, 0, 3, 180.0, 45.0)
	if bool(v2["ok"]):
		_fail("births=0 must be invalid")


func _fail(msg: String) -> void:
	_failed += 1
	push_error("TEST_BENCH_BINS: %s" % msg)
