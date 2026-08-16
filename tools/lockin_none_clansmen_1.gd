extends SceneTree

## Lock-in: none / clansmen_1 — idle rest + Walk 1 Pose A + Pose B (clean architecture baseline)

const LimbPresetRegistryScript = preload("res://scripts/systems/limb_preset_registry.gd")
const WalkArmMotion = preload("res://scripts/systems/walk_arm_motion.gd")
const MotionGolden = preload("res://scripts/systems/motion_golden.gd")

const TOLERANCE_PX := 0.05

const SHOULDER_1 := Vector2(118.0, -179.0)
const SHOULDER_2 := Vector2(-95.0, -178.0)

const IDLE_HAND_1 := Vector2(127.90, 51.48)
const IDLE_HAND_2 := Vector2(17.75, 24.56)
const IDLE_ELBOW_1_POLE := Vector2(89.89, -62.34)
const IDLE_ELBOW_2_POLE := Vector2(-65.77, -61.62)
const IDLE_OVERLAY := Vector2(22.0, -34.0)

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

	print("=== none_clansmen_1 full lock-in (idle + walk1) ===")
	_apply_all(preset)
	_validate_static(preset)
	_validate_motion(preset)

	var err := registry.save_preset(preset)
	if err != OK:
		_fail("ResourceSaver.save failed: %s" % error_string(err))
		_report()
		quit(1)
		return

	registry.reload_all_presets("clansmen_1")
	var disk: WeaponLimbPreset = registry.reload_preset(ResourceData.ResourceType.NONE, "clansmen_1")
	if disk == null:
		_fail("reload after save failed")
	else:
		_validate_static(disk)
		_validate_motion(disk)

	_report()
	quit(0 if _failures.is_empty() else 1)


func _apply_all(preset: WeaponLimbPreset) -> void:
	preset.weapon_type = ResourceData.ResourceType.NONE
	preset.body_card_id = "clansmen_1"
	preset.shoulder_offset_px = SHOULDER_1
	preset.support_shoulder_offset_px = SHOULDER_2
	preset.upper_arm_length = 120.0
	preset.lower_arm_length = 120.0
	preset.arm_width = 14.0
	preset.hand_width = 10.0

	preset.hand_grip_offset_px = IDLE_HAND_1
	preset.support_hand_idle_offset_px = IDLE_HAND_2
	preset.weapon_elbow_pole_idle_px = IDLE_ELBOW_1_POLE
	preset.support_elbow_pole_idle_px = IDLE_ELBOW_2_POLE
	preset.weapon_elbow_bend_sign_override = 1.0
	preset.support_elbow_bend_sign_override = 1.0
	preset.overlay_offset_idle_px = IDLE_OVERLAY

	preset.walk1_hand_grip_offset_px = WALK1_A_HAND_1
	preset.walk1_support_hand_offset_px = WALK1_A_HAND_2
	preset.walk1_weapon_elbow_pole_px = WALK1_A_ELBOW_1_POLE
	preset.walk1_support_elbow_pole_px = WALK1_A_ELBOW_2_POLE
	preset.walk1_weapon_elbow_bend_sign_override = WALK1_ELBOW_BEND
	preset.walk1_support_elbow_bend_sign_override = WALK1_ELBOW_BEND
	preset.walk1_overlay_offset_px = IDLE_OVERLAY
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
	_expect_vec("idle_hand_1", preset.hand_grip_offset_px, IDLE_HAND_1)
	_expect_vec("walk1_a_hand_1", preset.walk1_hand_grip_offset_px, WALK1_A_HAND_1)
	_expect_vec("walk1_b_hand_1", preset.walk1_pull_hand_grip_offset_px, WALK1_B_HAND_1)
	if not preset.walk1_pose_a_saved or not preset.walk1_pose_b_saved:
		_fail("walk1 pose saved flags must be true")


func _validate_motion(preset: WeaponLimbPreset) -> void:
	print("\n-- Walk pendulum motion --")
	var prev_dom := WALK1_A_HAND_1
	for i in range(9):
		var phase := float(i) / 8.0
		var dom := WalkArmMotion.body_snapshot_between_keyframes(
			WALK1_A_HAND_1, WALK1_B_HAND_1, phase
		)
		var step := dom.distance_to(prev_dom)
		if phase > 0.0 and step > 180.0:
			_fail("walk1 hand teleport at phase %.2f step %.1f" % [phase, step])
		prev_dom = dom
	var mid := WalkArmMotion.body_snapshot_between_keyframes(WALK1_A_HAND_1, WALK1_B_HAND_1, 0.5)
	if mid.distance_to(WALK1_B_HAND_1) > TOLERANCE_PX + 1.0:
		_fail("walk1 mid phase should match pose B")
	print("  walk1 pendulum: OK (9 samples, no teleport)")

	print("\n-- Golden motion trajectories --")
	for err_msg in MotionGolden.validate_idle_rest(
		"res://Tests/golden/idle_motion.json", preset
	):
		_fail(err_msg)
	for err_msg in MotionGolden.validate_walk1_pendulum(
		"res://Tests/golden/walk1_motion.json",
		WALK1_A_HAND_1,
		WALK1_B_HAND_1,
		WALK1_A_HAND_2,
		WALK1_B_HAND_2
	):
		_fail(err_msg)
	if _failures.is_empty():
		print("  golden idle + walk1: OK")


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
		print("lockin_none_clansmen_1: PASS")
	else:
		print("lockin_none_clansmen_1: FAIL (%d)" % _failures.size())
		for f in _failures:
			print("  - ", f)
