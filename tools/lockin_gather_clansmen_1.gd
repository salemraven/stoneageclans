extends SceneTree

## Lock-in: gather1 on none / clansmen_1 — skipped until visually authored (golden locked=false).

const MotionGolden = preload("res://scripts/systems/motion_golden.gd")

var _failures: Array[String] = []


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	await process_frame
	var data := MotionGolden.load_json("res://Tests/golden/gather1_motion.json")
	if data.is_empty():
		_fail("gather1_motion.json missing")
	elif data.get("locked", false) == false:
		print("lockin_gather_clansmen_1: SKIP (not visually locked yet)")
	else:
		print("lockin_gather_clansmen_1: TODO implement when gather is authored")
	_report()
	quit(0 if _failures.is_empty() else 1)


func _fail(msg: String) -> void:
	_failures.append(msg)
	print("FAIL: ", msg)


func _report() -> void:
	if not _failures.is_empty():
		print("lockin_gather_clansmen_1: FAIL")
