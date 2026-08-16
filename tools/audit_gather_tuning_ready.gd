extends SceneTree

## Headless audit: gather1 rows ready on none_clansmen_1 (+ tool holdables share body gather).

const LimbPresetRegistryScript = preload("res://scripts/systems/limb_preset_registry.gd")

var _failures: Array[String] = []
var _warnings: Array[String] = []


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	await process_frame
	var registry := LimbPresetRegistryScript.new()
	var none_preset: WeaponLimbPreset = registry.reload_preset(ResourceData.ResourceType.NONE, "clansmen_1")
	if none_preset == null:
		_fail("none_clansmen_1.tres missing")
		_report()
		quit(1)
		return
	print("=== Gather tuning-ready audit (clansmen_1) ===")
	_audit_gather_row(none_preset, "none")
	for weapon_type in [ResourceData.ResourceType.AXE, ResourceData.ResourceType.PICK, ResourceData.ResourceType.OLDOWAN]:
		var preset: WeaponLimbPreset = registry.reload_preset(weapon_type, "clansmen_1")
		if preset == null:
			_warn("missing preset for weapon %s — gather copy skipped" % str(weapon_type))
			continue
		_audit_gather_row(preset, str(weapon_type))
		if not _gather_rows_match(none_preset, preset):
			_warn("%s gather row differs from none — re-run lockin_gather_clansmen_1.gd" % str(weapon_type))
	_report()
	quit(0 if _failures.is_empty() else 1)


func _audit_gather_row(preset: WeaponLimbPreset, label: String) -> void:
	print("\n-- Gather 1 [%s] --" % label)
	_print_vec("  reach 1h", preset.gather1_hand_grip_offset_px)
	_print_vec("  reach 2h", preset.gather1_support_hand_offset_px)
	_print_vec("  pull 1h", preset.gather1_pull_hand_grip_offset_px)
	_print_vec("  pull 2h", preset.gather1_pull_support_hand_offset_px)
	_print_vec("  support elbow pole", preset.gather1_support_elbow_pole_px)
	if preset.gather1_hand_grip_offset_px.length_squared() < 0.0001:
		_fail("%s: reach dominant hand unset" % label)
	if preset.gather1_support_hand_offset_px.length_squared() < 0.0001:
		_fail("%s: reach support hand unset" % label)
	if not preset.has_gather1_pull_pose():
		_fail("%s: pull pose unset (need both pull hand fields)" % label)


func _gather_rows_match(a: WeaponLimbPreset, b: WeaponLimbPreset) -> bool:
	return (
		a.gather1_hand_grip_offset_px.is_equal_approx(b.gather1_hand_grip_offset_px)
		and a.gather1_support_hand_offset_px.is_equal_approx(b.gather1_support_hand_offset_px)
		and a.gather1_pull_hand_grip_offset_px.is_equal_approx(b.gather1_pull_hand_grip_offset_px)
		and a.gather1_pull_support_hand_offset_px.is_equal_approx(b.gather1_pull_support_hand_offset_px)
	)


func _print_vec(label: String, v: Vector2) -> void:
	print("%s = (%.2f, %.2f)" % [label, v.x, v.y])


func _fail(msg: String) -> void:
	_failures.append(msg)
	print("FAIL: ", msg)


func _warn(msg: String) -> void:
	_warnings.append(msg)
	print("WARN: ", msg)


func _report() -> void:
	print("\n=== Summary ===")
	print("Failures: ", _failures.size())
	print("Warnings: ", _warnings.size())
	if _failures.is_empty() and _warnings.is_empty():
		print("gather_tuning_audit: PASS")
	elif _failures.is_empty():
		print("gather_tuning_audit: PASS_WITH_WARNINGS")
	else:
		print("gather_tuning_audit: FAIL")
