extends SceneTree
## Regression: Save / commit must not write Walk 1 Pose A from animation playback frames.
## Run: godot --headless -s res://tools/test_tuner_save_playback_guard.gd

const LimbPresetRegistryScript = preload("res://scripts/systems/limb_preset_registry.gd")
const WeaponLimbPresetScript = preload("res://scripts/config/weapon_limb_preset.gd")

const WALK1_A_HAND_1 := Vector2(115.7, 60.39)
const WALK1_A_HAND_2 := Vector2(20.18, 31.88)
const WALK1_B_HAND_1 := Vector2(233.16, 29.45)


func _init() -> void:
	call_deferred("_run_all")


func _run_all() -> void:
	var failures: Array[String] = []
	failures.append_array(await _test_walk1_preview_commit_keeps_pose_a())
	failures.append_array(_test_save_all_skips_unedited_cached_presets())
	if failures.is_empty():
		print("test_tuner_save_playback_guard: PASS")
		quit(0)
	else:
		for f in failures:
			push_error("test_tuner_save_playback_guard: FAIL — %s" % f)
		print("test_tuner_save_playback_guard: FAIL (%d)" % failures.size())
		quit(1)


func _test_walk1_preview_commit_keeps_pose_a() -> Array[String]:
	var out: Array[String] = []
	var registry := LimbPresetRegistryScript.new()
	var before: WeaponLimbPreset = registry.reload_preset(ResourceData.ResourceType.NONE, "clansmen_1")
	if before == null:
		out.append("none preset missing")
		return out
	if before.walk1_hand_grip_offset_px.distance_to(WALK1_A_HAND_1) > 0.05:
		out.append(
			"precondition: run lockin_walk_clansmen_1.gd first (walk1_a=%s)"
			% str(before.walk1_hand_grip_offset_px)
		)
		return out
	var packed := load("res://scenes/tools/LimbTuner.tscn") as PackedScene
	if packed == null:
		out.append("LimbTuner.tscn missing")
		return out
	var app: Node = packed.instantiate()
	root.add_child(app)
	for _i in range(8):
		await process_frame
	if not app.has_method("_begin_walk1_preview_session"):
		out.append("LimbTuner missing _begin_walk1_preview_session")
		app.queue_free()
		return out
	app.call("_begin_walk1_preview_session")
	for _i in range(36):
		await process_frame
	var preset: WeaponLimbPreset = app.get("_preset")
	if preset == null:
		out.append("walk1 preview preset missing")
		app.queue_free()
		return out
	# Simulate Save / mode switch without user edits (pose not dirty).
	app.call("_commit_all_poses_to_preset", false)
	if preset.walk1_hand_grip_offset_px.distance_to(WALK1_A_HAND_1) > 0.05:
		out.append(
			"commit while playing changed walk1_a hand_1: %s"
			% str(preset.walk1_hand_grip_offset_px)
		)
	if preset.walk1_support_hand_offset_px.distance_to(WALK1_A_HAND_2) > 0.05:
		out.append(
			"commit while playing changed walk1_a hand_2: %s"
			% str(preset.walk1_support_hand_offset_px)
		)
	if preset.walk1_pull_hand_grip_offset_px.distance_to(WALK1_B_HAND_1) > 0.05:
		out.append("commit while playing changed walk1_b hand_1")
	app.queue_free()
	return out


func _test_save_all_skips_unedited_cached_presets() -> Array[String]:
	var out: Array[String] = []
	var registry := LimbPresetRegistryScript.new()
	var none: WeaponLimbPreset = registry.reload_preset(ResourceData.ResourceType.NONE, "clansmen_1")
	var spear: WeaponLimbPreset = registry.get_preset(ResourceData.ResourceType.SPEAR, "clansmen_1", 1)
	if none == null or spear == null:
		out.append("none/spear preset missing")
		return out
	# Load spear into cache without marking dirty.
	var _touch := spear.overlay_offset_idle_px
	none.walk1_hand_grip_offset_px = Vector2(777.0, 888.0)
	registry.mark_staged_dirty(none)
	var result: Dictionary = registry.save_all_staged()
	if int(result.get("count", 0)) != 1:
		out.append("save_all_staged should write only dirty preset, got %s" % str(result))
	var disk_spear: WeaponLimbPreset = registry.reload_preset(ResourceData.ResourceType.SPEAR, "clansmen_1")
	if disk_spear.overlay_offset_idle_px != spear.overlay_offset_idle_px:
		out.append("unchanged cached spear must not be written on save")
	# Restore none walk1_a from lock-in values for downstream tests.
	none.walk1_hand_grip_offset_px = WALK1_A_HAND_1
	none.walk1_support_hand_offset_px = WALK1_A_HAND_2
	registry.save_preset(none)
	return out
