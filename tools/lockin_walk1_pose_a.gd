extends SceneTree

## Lock-in: Walk 1 Pose A (none / clansmen_1) - First clean animation
## Authored: 2026-08-15 from scratch in isolated architecture

const WeaponLimbPresetScript = preload("res://scripts/config/weapon_limb_preset.gd")
const LimbPresetRegistryScript = preload("res://scripts/systems/limb_preset_registry.gd")

const TOLERANCE_PX := 0.05

## Shoulders (reference - rarely change)
const SHOULDER_1 := Vector2(118.0, -179.0)
const SHOULDER_2 := Vector2(-95.0, -178.0)

## Walk 1 Pose A (right forward, left back) - LOCKED
const WALK1_A_HAND_1 := Vector2(115.7, 60.39)
const WALK1_A_HAND_2 := Vector2(20.18, 31.88)
const WALK1_A_ELBOW_1_POLE := Vector2(108.22, -59.39)
const WALK1_A_ELBOW_2_POLE := Vector2(-44.97, -68.91)
const WALK1_A_ELBOW_1_BEND := -1.0
const WALK1_A_ELBOW_2_BEND := -1.0
const WALK1_A_OVERLAY := Vector2(22.0, -34.0)

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

	print("=== Walk 1 Pose A lock-in (none / clansmen_1) ===")
	_apply_handoff(preset)
	_validate(preset)

	var err := registry.save_preset(preset)
	if err != OK:
		_fail("ResourceSaver.save failed: %s" % error_string(err))
		_report()
		quit(1)
		return

	var disk: WeaponLimbPreset = registry.reload_preset(ResourceData.ResourceType.NONE, "clansmen_1")
	if disk == null:
		_fail("reload after save failed")
	else:
		_validate(disk)

	_report()
	quit(0 if _failures.is_empty() else 1)


func _apply_handoff(preset: WeaponLimbPreset) -> void:
	preset.weapon_type = ResourceData.ResourceType.NONE
	preset.body_card_id = "clansmen_1"
	# Shoulders (reference)
	preset.shoulder_offset_px = SHOULDER_1
	preset.support_shoulder_offset_px = SHOULDER_2
	
	# Walk 1 Pose A
	preset.walk1_hand_grip_offset_px = WALK1_A_HAND_1
	preset.walk1_support_hand_offset_px = WALK1_A_HAND_2
	preset.walk1_weapon_elbow_pole_px = WALK1_A_ELBOW_1_POLE
	preset.walk1_support_elbow_pole_px = WALK1_A_ELBOW_2_POLE
	preset.walk1_weapon_elbow_bend_sign_override = WALK1_A_ELBOW_1_BEND
	preset.walk1_support_elbow_bend_sign_override = WALK1_A_ELBOW_2_BEND
	preset.walk1_overlay_offset_px = WALK1_A_OVERLAY
	preset.walk1_pose_a_saved = true
	
	# Arm lengths
	preset.upper_arm_length = 120.0
	preset.lower_arm_length = 120.0
	preset.arm_width = 14.0
	preset.hand_width = 10.0


func _validate(preset: WeaponLimbPreset) -> void:
	print("\n-- Walk 1 Pose A --")
	_expect_vec("walk1_hand_1", preset.walk1_hand_grip_offset_px, WALK1_A_HAND_1)
	_expect_vec("walk1_hand_2", preset.walk1_support_hand_offset_px, WALK1_A_HAND_2)
	_expect_vec("walk1_elbow_1_pole", preset.walk1_weapon_elbow_pole_px, WALK1_A_ELBOW_1_POLE)
	_expect_vec("walk1_elbow_2_pole", preset.walk1_support_elbow_pole_px, WALK1_A_ELBOW_2_POLE)
	_expect_float("walk1_elbow_1_bend", preset.walk1_weapon_elbow_bend_sign_override, WALK1_A_ELBOW_1_BEND)
	_expect_float("walk1_elbow_2_bend", preset.walk1_support_elbow_bend_sign_override, WALK1_A_ELBOW_2_BEND)
	_expect_vec("walk1_overlay", preset.walk1_overlay_offset_px, WALK1_A_OVERLAY)
	
	if not preset.walk1_pose_a_saved:
		_fail("walk1_pose_a_saved must be true")


func _expect_vec(label: String, got: Vector2, want: Vector2) -> void:
	_print_vec("  %s" % label, got)
	if got.distance_to(want) > TOLERANCE_PX:
		_fail("%s expected (%.2f, %.2f) got (%.2f, %.2f)" % [label, want.x, want.y, got.x, got.y])


func _expect_float(label: String, got: float, want: float) -> void:
	print("  %s = %.1f" % [label, got])
	if abs(got - want) > 0.01:
		_fail("%s expected %.1f got %.1f" % [label, want, got])


func _print_vec(label: String, v: Vector2) -> void:
	print("%s = (%.2f, %.2f)" % [label, v.x, v.y])


func _fail(msg: String) -> void:
	_failures.append(msg)
	print("FAIL: ", msg)


func _report() -> void:
	print("\n=== Lock-in summary ===")
	if _failures.is_empty():
		print("lockin_walk1_pose_a: PASS — saved assets/limb_presets/none_clansmen_1.tres")
	else:
		print("lockin_walk1_pose_a: FAIL (%d)" % _failures.size())
		for f in _failures:
			print("  - ", f)
