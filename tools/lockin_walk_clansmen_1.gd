extends SceneTree

## Lock-in: Walk 1 on none / clansmen_1 — delegates to combined none lock-in walk rows + golden motion.

const LimbPresetRegistryScript = preload("res://scripts/systems/limb_preset_registry.gd")
const WalkArmMotion = preload("res://scripts/systems/walk_arm_motion.gd")
const MotionGolden = preload("res://scripts/systems/motion_golden.gd")

const TOLERANCE_PX := 0.05

const WALK1_A_HAND_1 := Vector2(225.82, 34.35)
const WALK1_A_HAND_2 := Vector2(-173.19, 41.69)
const WALK1_B_HAND_1 := Vector2(76.93, 97.59)
const WALK1_B_HAND_2 := Vector2(5.51, 71.07)

var _failures: Array[String] = []


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	await process_frame
	var registry := LimbPresetRegistryScript.new()
	var preset: WeaponLimbPreset = registry.reload_preset(ResourceData.ResourceType.NONE, "clansmen_1")
	if preset == null:
		_fail("none_clansmen_1.tres missing")
		_report()
		quit(1)
		return

	print("=== walk_clansmen_1 lock-in (Walk 1 Pose A + B) ===")
	_validate_static(preset)
	_validate_motion(preset)
	_report()
	quit(0 if _failures.is_empty() else 1)


func _validate_static(preset: WeaponLimbPreset) -> void:
	print("\n-- Static pins --")
	_expect_vec("walk1_a_hand_1", preset.walk1_hand_grip_offset_px, WALK1_A_HAND_1)
	_expect_vec("walk1_b_hand_1", preset.walk1_pull_hand_grip_offset_px, WALK1_B_HAND_1)
	if not preset.walk1_pose_a_saved or not preset.walk1_pose_b_saved:
		_fail("walk1 pose saved flags must be true")


func _validate_motion(preset: WeaponLimbPreset) -> void:
	print("\n-- Walk pendulum motion --")
	var prev := WALK1_A_HAND_1
	for i in range(9):
		var phase := float(i) / 8.0
		var dom := WalkArmMotion.body_snapshot_between_keyframes(
			WALK1_A_HAND_1, WALK1_B_HAND_1, phase
		)
		if i > 0 and dom.distance_to(prev) > 180.0:
			_fail("walk1 hand teleport at phase %.2f" % phase)
		prev = dom
	for err_msg in MotionGolden.validate_walk1_pendulum(
		"res://Tests/golden/walk1_motion.json",
		WALK1_A_HAND_1,
		WALK1_B_HAND_1,
		WALK1_A_HAND_2,
		WALK1_B_HAND_2
	):
		_fail(err_msg)
	if _failures.is_empty():
		print("  walk1 pendulum + golden: OK")


func _expect_vec(label: String, got: Vector2, want: Vector2) -> void:
	print("  %s = (%.2f, %.2f)" % [label, got.x, got.y])
	if got.distance_to(want) > TOLERANCE_PX:
		_fail("%s expected (%.2f, %.2f) got (%.2f, %.2f)" % [label, want.x, want.y, got.x, got.y])


func _fail(msg: String) -> void:
	_failures.append(msg)
	print("FAIL: ", msg)


func _report() -> void:
	print("\n=== Lock-in summary ===")
	if _failures.is_empty():
		print("lockin_walk_clansmen_1: PASS")
	else:
		print("lockin_walk_clansmen_1: FAIL (%d)" % _failures.size())
		for f in _failures:
			print("  - ", f)
