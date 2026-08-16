extends SceneTree

## Lock-in: Walk 1 on none / clansmen_1 — Pose A + B + golden motion (receipt 2026-08-15).

const LimbPresetRegistryScript = preload("res://scripts/systems/limb_preset_registry.gd")
const WalkArmMotion = preload("res://scripts/systems/walk_arm_motion.gd")
const MotionGolden = preload("res://scripts/systems/motion_golden.gd")

const TOLERANCE_PX := 0.05

const WALK1_A_HAND_1 := Vector2(115.7, 60.39)
const WALK1_A_HAND_2 := Vector2(20.18, 31.88)
const WALK1_A_ELBOW_1_POLE := Vector2(108.22, -59.39)
const WALK1_A_ELBOW_2_POLE := Vector2(-44.97, -68.91)

const WALK1_B_HAND_1 := Vector2(233.16, 29.45)
const WALK1_B_HAND_2 := Vector2(-163.4, 44.14)
const WALK1_B_ELBOW_1_POLE := Vector2(162.56, -67.58)
const WALK1_B_ELBOW_2_POLE := Vector2(-157.77, -75.73)

const WALK1_ELBOW_BEND := -1.0

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
	_apply_handoff(preset)
	_validate_static(preset)
	_validate_motion(preset)

	var err := registry.save_preset(preset)
	if err != OK:
		_fail("ResourceSaver.save failed: %s" % error_string(err))
		_report()
		quit(1)
		return

	var disk: WeaponLimbPreset = registry.reload_preset(ResourceData.ResourceType.NONE, "clansmen_1")
	if disk != null:
		_validate_static(disk)
		_validate_motion(disk)

	_report()
	quit(0 if _failures.is_empty() else 1)


func _apply_handoff(preset: WeaponLimbPreset) -> void:
	preset.walk1_hand_grip_offset_px = WALK1_A_HAND_1
	preset.walk1_support_hand_offset_px = WALK1_A_HAND_2
	preset.walk1_weapon_elbow_pole_px = WALK1_A_ELBOW_1_POLE
	preset.walk1_support_elbow_pole_px = WALK1_A_ELBOW_2_POLE
	preset.walk1_weapon_elbow_bend_sign_override = WALK1_ELBOW_BEND
	preset.walk1_support_elbow_bend_sign_override = WALK1_ELBOW_BEND
	preset.walk1_overlay_offset_px = Vector2(22.0, -34.0)
	preset.walk1_pose_a_saved = true

	preset.walk1_pull_hand_grip_offset_px = WALK1_B_HAND_1
	preset.walk1_pull_support_hand_offset_px = WALK1_B_HAND_2
	preset.walk1_pull_weapon_elbow_pole_px = WALK1_B_ELBOW_1_POLE
	preset.walk1_pull_support_elbow_pole_px = WALK1_B_ELBOW_2_POLE
	preset.walk1_pull_weapon_elbow_bend_sign_override = WALK1_ELBOW_BEND
	preset.walk1_pull_support_elbow_bend_sign_override = WALK1_ELBOW_BEND
	preset.walk1_pose_b_saved = true


func _validate_static(preset: WeaponLimbPreset) -> void:
	print("\n-- Static pins --")
	_expect_vec("walk1_a_hand_1", preset.walk1_hand_grip_offset_px, WALK1_A_HAND_1)
	_expect_vec("walk1_a_hand_2", preset.walk1_support_hand_offset_px, WALK1_A_HAND_2)
	_expect_vec("walk1_b_hand_1", preset.walk1_pull_hand_grip_offset_px, WALK1_B_HAND_1)
	_expect_vec("walk1_b_hand_2", preset.walk1_pull_support_hand_offset_px, WALK1_B_HAND_2)
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
