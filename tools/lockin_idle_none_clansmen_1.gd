extends SceneTree

## Lock-in: Idle rest pose (none / clansmen_1)

const LimbPresetRegistryScript = preload("res://scripts/systems/limb_preset_registry.gd")

const TOLERANCE_PX := 0.05

const SHOULDER_1 := Vector2(118.0, -179.0)
const SHOULDER_2 := Vector2(-95.0, -178.0)
const IDLE_HAND_1 := Vector2(127.90, 51.48)
const IDLE_HAND_2 := Vector2(17.75, 24.56)
const IDLE_ELBOW_1_POLE := Vector2(89.89, -62.34)
const IDLE_ELBOW_2_POLE := Vector2(-65.77, -61.62)
const IDLE_ELBOW_1_BEND := 1.0
const IDLE_ELBOW_2_BEND := 1.0
const IDLE_OVERLAY := Vector2(22.0, -34.0)

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

	print("=== Idle rest lock-in (none / clansmen_1) ===")
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
	preset.shoulder_offset_px = SHOULDER_1
	preset.support_shoulder_offset_px = SHOULDER_2
	preset.hand_grip_offset_px = IDLE_HAND_1
	preset.support_hand_idle_offset_px = IDLE_HAND_2
	preset.weapon_elbow_pole_idle_px = IDLE_ELBOW_1_POLE
	preset.support_elbow_pole_idle_px = IDLE_ELBOW_2_POLE
	preset.weapon_elbow_bend_sign_override = IDLE_ELBOW_1_BEND
	preset.support_elbow_bend_sign_override = IDLE_ELBOW_2_BEND
	preset.overlay_offset_idle_px = IDLE_OVERLAY


func _validate(preset: WeaponLimbPreset) -> void:
	print("\n-- Idle rest --")
	_expect_vec("hand_1", preset.hand_grip_offset_px, IDLE_HAND_1)
	_expect_vec("hand_2", preset.support_hand_idle_offset_px, IDLE_HAND_2)
	_expect_vec("elbow_1_pole", preset.weapon_elbow_pole_idle_px, IDLE_ELBOW_1_POLE)
	_expect_vec("elbow_2_pole", preset.support_elbow_pole_idle_px, IDLE_ELBOW_2_POLE)
	_expect_vec("overlay", preset.overlay_offset_idle_px, IDLE_OVERLAY)


func _expect_vec(label: String, got: Vector2, want: Vector2) -> void:
	_print_vec("  %s" % label, got)
	if got.distance_to(want) > TOLERANCE_PX:
		_fail("%s expected (%.2f, %.2f) got (%.2f, %.2f)" % [label, want.x, want.y, got.x, got.y])


func _print_vec(label: String, v: Vector2) -> void:
	print("%s = (%.2f, %.2f)" % [label, v.x, v.y])


func _fail(msg: String) -> void:
	_failures.append(msg)
	print("FAIL: ", msg)


func _report() -> void:
	print("\n=== Lock-in summary ===")
	if _failures.is_empty():
		print("lockin_idle_none_clansmen_1: PASS")
	else:
		print("lockin_idle_none_clansmen_1: FAIL (%d)" % _failures.size())
		for f in _failures:
			print("  - ", f)
