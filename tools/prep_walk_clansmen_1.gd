extends SceneTree

## Headless: clear walk / walk1 rows on none_clansmen_1 and seed Pose 1 from idle for fresh tuning.

const LimbPresetRegistryScript = preload("res://scripts/systems/limb_preset_registry.gd")

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

	print("=== Prep walk clansmen_1 (clear + seed Pose 1 from idle) ===")
	preset.reset_mode_to_defaults(WeaponLimbPreset.TunerAnimMode.WALK)
	preset.reset_mode_to_defaults(WeaponLimbPreset.TunerAnimMode.WALK1)
	preset.seed_walk1_from_idle_if_unset()

	var err := registry.save_preset(preset)
	if err != OK:
		_fail("save failed: %s" % error_string(err))

	print("  walk1 hand (Pose 1): ", preset.walk1_hand_grip_offset_px)
	print("  walk1 support (Pose 1): ", preset.walk1_support_hand_offset_px)
	print("  walk1 pull hand (Pose 2): ", preset.walk1_pull_hand_grip_offset_px)
	print("  walk1 pull support (Pose 2): ", preset.walk1_pull_support_hand_offset_px)

	_report()
	quit(0 if _failures.is_empty() else 1)


func _fail(msg: String) -> void:
	_failures.append(msg)
	print("FAIL: ", msg)


func _report() -> void:
	if _failures.is_empty():
		print("prep_walk_clansmen_1: PASS — walk rows cleared; Pose 1 seeded from idle")
	else:
		print("prep_walk_clansmen_1: FAIL (%d)" % _failures.size())
