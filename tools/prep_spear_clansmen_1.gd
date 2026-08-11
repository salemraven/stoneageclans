extends SceneTree

## Headless: validate + persist spear_clansmen_1 for tuner sessions (idle, walk, windup, thrust).

const WeaponLimbPresetScript = preload("res://scripts/config/weapon_limb_preset.gd")
const LimbPresetRegistryScript = preload("res://scripts/systems/limb_preset_registry.gd")

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

	print("=== Spear clansmen_1 tuning prep ===")
	_finalize_preset(preset)
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


func _finalize_preset(preset: WeaponLimbPreset) -> void:
	preset.ensure_spear_grip_defaults()
	preset.seed_walk_from_idle_if_unset()
	preset.seed_walk1_from_walk_if_unset()
	preset.seed_spear_attack_windup_if_unset()
	if preset.hand_grip_ready_offset_px.length_squared() < 0.0001:
		preset.hand_grip_ready_offset_px = preset.hand_grip_offset_px
	if preset.strike_offset_px.length_squared() < 0.0001:
		preset.strike_offset_px = preset.ready_offset_px + Vector2(50.0, -2.0)


func _validate(preset: WeaponLimbPreset) -> void:
	if not preset.uses_saved_spear_grip_on_art():
		_fail("shaft grip not saved on art")
	if preset.ready_offset_px.length_squared() < 0.0001:
		_fail("attack ready_offset unset")
	if preset.strike_offset_px.length_squared() < 0.0001:
		_fail("strike_offset unset")


func _fail(msg: String) -> void:
	_failures.append(msg)
	print("FAIL: ", msg)


func _report() -> void:
	print("\n=== Prep summary ===")
	if _failures.is_empty():
		print("prep_spear_clansmen_1: PASS — saved assets/limb_presets/spear_clansmen_1.tres")
	else:
		print("prep_spear_clansmen_1: FAIL")
		for f in _failures:
			print("  - ", f)
