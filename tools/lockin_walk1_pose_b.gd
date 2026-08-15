extends SceneTree

## Lock-in: Walk 1 Pose B (none / clansmen_1) — left forward, right back

const LimbPresetRegistryScript = preload("res://scripts/systems/limb_preset_registry.gd")

const TOLERANCE_PX := 0.05

const WALK1_B_HAND_1 := Vector2(76.93, 97.59)
const WALK1_B_HAND_2 := Vector2(5.51, 71.07)
const WALK1_B_ELBOW_1_POLE := Vector2(88.0, -41.98)
const WALK1_B_ELBOW_2_POLE := Vector2(-81.92, -38.28)
const WALK1_B_ELBOW_1_BEND := 1.0
const WALK1_B_ELBOW_2_BEND := 1.0

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

	print("=== Walk 1 Pose B lock-in (none / clansmen_1) ===")
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
	preset.walk1_pull_hand_grip_offset_px = WALK1_B_HAND_1
	preset.walk1_pull_support_hand_offset_px = WALK1_B_HAND_2
	preset.walk1_pull_weapon_elbow_pole_px = WALK1_B_ELBOW_1_POLE
	preset.walk1_pull_support_elbow_pole_px = WALK1_B_ELBOW_2_POLE
	preset.walk1_pull_weapon_elbow_bend_sign_override = WALK1_B_ELBOW_1_BEND
	preset.walk1_pull_support_elbow_bend_sign_override = WALK1_B_ELBOW_2_BEND
	preset.walk1_pose_b_saved = true


func _validate(preset: WeaponLimbPreset) -> void:
	print("\n-- Walk 1 Pose B --")
	_expect_vec("walk1_pull_hand_1", preset.walk1_pull_hand_grip_offset_px, WALK1_B_HAND_1)
	_expect_vec("walk1_pull_hand_2", preset.walk1_pull_support_hand_offset_px, WALK1_B_HAND_2)
	_expect_vec("walk1_pull_elbow_1_pole", preset.walk1_pull_weapon_elbow_pole_px, WALK1_B_ELBOW_1_POLE)
	_expect_vec("walk1_pull_elbow_2_pole", preset.walk1_pull_support_elbow_pole_px, WALK1_B_ELBOW_2_POLE)
	_expect_float("walk1_pull_elbow_1_bend", preset.walk1_pull_weapon_elbow_bend_sign_override, WALK1_B_ELBOW_1_BEND)
	_expect_float("walk1_pull_elbow_2_bend", preset.walk1_pull_support_elbow_bend_sign_override, WALK1_B_ELBOW_2_BEND)
	if not preset.walk1_pose_b_saved:
		_fail("walk1_pose_b_saved must be true")


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
		print("lockin_walk1_pose_b: PASS — saved assets/limb_presets/none_clansmen_1.tres")
	else:
		print("lockin_walk1_pose_b: FAIL (%d)" % _failures.size())
		for f in _failures:
			print("  - ", f)
