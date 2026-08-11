extends SceneTree

## Headless: validate + persist spear_clansmen_1 windup/thrust from tuner handoff.

const WeaponLimbPresetScript = preload("res://scripts/config/weapon_limb_preset.gd")
const LimbPresetRegistryScript = preload("res://scripts/systems/limb_preset_registry.gd")

const TOLERANCE_PX := 0.05

var _failures: Array[String] = []


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	await process_frame
	var registry := LimbPresetRegistryScript.new()
	var preset: WeaponLimbPreset = registry.reload_preset(ResourceData.ResourceType.SPEAR, "clansmen_1")
	if preset == null:
		_fail("spear_clansmen_1.tres missing")
		_report()
		quit(1)
		return

	print("=== Spear clansmen_1 lock-in (windup handoff) ===")
	_apply_handoff(preset)
	_validate(preset)

	var err := registry.save_preset(preset)
	if err != OK:
		_fail("ResourceSaver.save failed: %s" % error_string(err))
		_report()
		quit(1)
		return

	var disk: WeaponLimbPreset = registry.reload_preset(ResourceData.ResourceType.SPEAR, "clansmen_1")
	if disk == null:
		_fail("reload after save failed")
	else:
		_validate(disk)

	_report()
	quit(0 if _failures.is_empty() else 1)


func _apply_handoff(preset: WeaponLimbPreset) -> void:
	preset.shoulder_offset_px = Vector2(118.4381, -178.8513)
	preset.support_shoulder_offset_px = Vector2(-94.52647, -177.509)
	preset.hand_grip_offset_px = Vector2(4.966575, 101.0589)
	preset.overlay_offset_idle_px = Vector2(63.5, -116.0)
	preset.walk_hand_grip_offset_px = Vector2(5.413738, 78.92036)
	preset.walk_overlay_offset_px = Vector2(62.62826, -119.1889)
	preset.walk1_hand_grip_offset_px = Vector2(-31.02883, 57.09174)
	preset.walk1_overlay_offset_px = Vector2(63.5, -116.4406)
	preset.ready_offset_px = Vector2(113.5, -17.0)
	preset.hand_grip_ready_offset_px = Vector2(4.966615, 101.0587)
	preset.support_hand_offset_px = Vector2(7.493873, 205.6479)
	preset.strike_offset_px = Vector2(140.8995, -24.16345)
	preset.attack_rotation_deg = 83.0
	preset.weapon_elbow_pole_ready_px = Vector2(168.886, -69.97058)
	preset.support_elbow_pole_ready_px = Vector2(-61.92468, -62.02262)
	preset.weapon_elbow_bend_sign_ready_override = 1.0
	preset.support_elbow_bend_sign_ready_override = 1.0
	preset.weapon_elbow_bend_sign_override = 1.0
	preset.support_elbow_bend_sign_override = 1.0
	preset.walk_weapon_elbow_bend_sign_override = 1.0
	preset.walk_support_elbow_bend_sign_override = 1.0
	preset.walk1_weapon_elbow_bend_sign_override = 1.0
	preset.walk1_support_elbow_bend_sign_override = 1.0
	preset.upper_arm_length = 120.0
	preset.lower_arm_length = 120.0
	preset.arm_width = 14.0
	preset.hand_width = 10.0
	preset.ready_forward_px = 24.0
	preset.elbow_hint_outward = 18.0
	preset.mark_attack_windup_pose_saved()


func _validate(preset: WeaponLimbPreset) -> void:
	print("\n-- Attack windup --")
	_expect_vec("ready_offset_px", preset.ready_offset_px, Vector2(113.5, -17.0))
	_expect_vec("hand_grip_ready (Y1)", preset.hand_grip_ready_offset_px, Vector2(4.966615, 101.0587))
	_expect_vec("support_hand (Y2)", preset.support_hand_offset_px, Vector2(7.493873, 205.6479))
	_expect_vec("weapon_elbow_ready", preset.weapon_elbow_pole_ready_px, Vector2(168.886, -69.97058))
	_expect_vec("support_elbow_ready", preset.support_elbow_pole_ready_px, Vector2(-61.92468, -62.02262))
	if not preset.spear_attack_pose_saved:
		_fail("spear_attack_pose_saved must be true")

	print("\n-- Thrust strike --")
	_expect_vec("strike_offset_px", preset.strike_offset_px, Vector2(140.8995, -24.16345))
	if absf(preset.attack_rotation_deg - 83.0) > 0.01:
		_fail("attack_rotation_deg expected 83.0 got %.2f" % preset.attack_rotation_deg)
	if preset.strike_offset_px.distance_to(preset.ready_offset_px) < 4.0:
		_fail("strike_offset_px too close to ready — thrust will look short")


func _expect_vec(label: String, got: Vector2, want: Vector2) -> void:
	_print_vec("  %s" % label, got)
	if got.distance_to(want) > TOLERANCE_PX:
		_fail("%s expected (%.4f, %.4f) got (%.4f, %.4f)" % [label, want.x, want.y, got.x, got.y])


func _print_vec(label: String, v: Vector2) -> void:
	print("%s = (%.4f, %.4f)" % [label, v.x, v.y])


func _fail(msg: String) -> void:
	_failures.append(msg)
	print("FAIL: ", msg)


func _report() -> void:
	print("\n=== Lock-in summary ===")
	if _failures.is_empty():
		print("lockin_spear_clansmen_1: PASS — saved assets/limb_presets/spear_clansmen_1.tres")
	else:
		print("lockin_spear_clansmen_1: FAIL (%d)" % _failures.size())
		for f in _failures:
			print("  - ", f)
