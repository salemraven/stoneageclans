extends SceneTree

## Lock-in: spear / clansmen_1 — default shaft grip + idle overlay baseline.

const WeaponLimbPresetScript = preload("res://scripts/config/weapon_limb_preset.gd")
const LimbPresetRegistryScript = preload("res://scripts/systems/limb_preset_registry.gd")
const MotionGolden = preload("res://scripts/systems/motion_golden.gd")

const TOLERANCE_PX := 0.05

var _failures: Array[String] = []


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	await process_frame
	var registry := LimbPresetRegistryScript.new()
	var none: WeaponLimbPreset = registry.reload_preset(ResourceData.ResourceType.NONE, "clansmen_1")
	var preset: WeaponLimbPreset = registry.reload_preset(ResourceData.ResourceType.SPEAR, "clansmen_1")
	if preset == null:
		_fail("spear_clansmen_1.tres missing")
		_report()
		quit(1)
		return

	print("=== spear_clansmen_1 lock-in (default idle baseline) ===")
	if none != null:
		preset.apply_shared_body_from_none(none)
	WeaponLimbPresetScript.apply_default_spear_idle_pose(preset)
	preset.weapon_type = ResourceData.ResourceType.SPEAR
	preset.body_card_id = "clansmen_1"

	_validate_static(preset)
	_validate_golden(preset)

	var err := registry.save_preset(preset)
	if err != OK:
		_fail("save failed: %s" % error_string(err))

	registry.reload_all_presets("clansmen_1")
	var disk: WeaponLimbPreset = registry.reload_preset(ResourceData.ResourceType.SPEAR, "clansmen_1")
	if disk != null:
		_validate_static(disk)

	_report()
	quit(0 if _failures.is_empty() else 1)


func _validate_static(preset: WeaponLimbPreset) -> void:
	print("\n-- Static pins --")
	var want_grip := WeaponLimbPresetScript.default_spear_hand_grip_px()
	var want_overlay := WeaponLimbPresetScript.default_spear_overlay_idle_px()
	_expect_vec("hand_grip", preset.hand_grip_offset_px, want_grip)
	_expect_vec("overlay_idle", preset.overlay_offset_idle_px, want_overlay)
	if preset.spear_hand_grip_needs_reseed():
		_fail("spear grip still looks like legacy coords")


func _validate_golden(preset: WeaponLimbPreset) -> void:
	print("\n-- Golden rest pose --")
	var data := MotionGolden.load_json("res://Tests/golden/spear_idle1_motion.json")
	if data.is_empty():
		_fail("spear_idle1_motion.json missing")
		return
	var tol := float(data.get("tolerance_px", 2.0))
	var rest: Dictionary = data.get("rest", {})
	for key in ["hand_grip", "overlay"]:
		var arr: Array = rest.get(key, [])
		if arr.size() < 2:
			continue
		var want := Vector2(float(arr[0]), float(arr[1]))
		var got := preset.hand_grip_offset_px if key == "hand_grip" else preset.overlay_offset_idle_px
		if got.distance_to(want) > tol:
			_fail("golden %s mismatch got %s want %s" % [key, str(got), str(want)])
	if _failures.is_empty():
		print("  golden spear idle: OK")


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
		print("lockin_spear_clansmen_1: PASS")
	else:
		print("lockin_spear_clansmen_1: FAIL (%d)" % _failures.size())
		for f in _failures:
			print("  - ", f)
