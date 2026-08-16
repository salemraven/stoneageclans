extends SceneTree
## Regression: tuner startup must not clobber saved pose rows (club walk, walk1, gather1).
## Run: godot --headless -s res://tools/test_tuner_startup_no_clobber.gd

const LimbPresetRegistryScript = preload("res://scripts/systems/limb_preset_registry.gd")
const TunerPoseSeedGuardScript = preload("res://scripts/tools/tuner_pose_seed_guard.gd")
const WeaponLimbPresetScript = preload("res://scripts/config/weapon_limb_preset.gd")


func _init() -> void:
	call_deferred("_run_all")


func _run_all() -> void:
	var failures: Array[String] = []
	failures.append_array(_test_club_preset_seeds_do_not_import_none_carry())
	failures.append_array(_test_club_walk_off_arm_skips_when_tuned())
	failures.append_array(_test_walk1_saved_skips_idle_seed())
	failures.append_array(_test_gather1_saved_skips_reach_seed())
	failures.append_array(await _test_club_walk_preview_session_keeps_disk_carry())
	if failures.is_empty():
		print("test_tuner_startup_no_clobber: PASS")
		quit(0)
	else:
		for f in failures:
			push_error("test_tuner_startup_no_clobber: FAIL — %s" % f)
		print("test_tuner_startup_no_clobber: FAIL (%d)" % failures.size())
		quit(1)


func _test_club_preset_seeds_do_not_import_none_carry() -> Array[String]:
	var out: Array[String] = []
	var registry := LimbPresetRegistryScript.new()
	var club: WeaponLimbPreset = registry.reload_preset(ResourceData.ResourceType.WOOD, "clansmen_1")
	var none: WeaponLimbPreset = registry.get_preset(ResourceData.ResourceType.NONE, "clansmen_1", 1)
	if club == null or none == null:
		out.append("club/none preset missing")
		return out
	var before := TunerPoseSeedGuardScript.fingerprint(club)
	var none_carry := none.hand_grip_offset_px
	club.seed_club_walk1_dominant_from_idle_carry(none_carry)
	club.seed_club_walk_off_arm_from_none(none)
	club.repair_club_carry_body_hand_from_none(none)
	var after := TunerPoseSeedGuardScript.fingerprint(club)
	if after.get("hand_grip_offset_px") != before.get("hand_grip_offset_px"):
		out.append(
			"club hand_grip changed after startup seeds: %s"
			% str(TunerPoseSeedGuardScript.fingerprint_diff(before, after))
		)
	if after.get("walk1_hand_grip_offset_px") != before.get("walk1_hand_grip_offset_px"):
		out.append("club walk1_hand changed after startup seeds (must stay disk carry)")
	return out


func _test_club_walk_off_arm_skips_when_tuned() -> Array[String]:
	var out: Array[String] = []
	var club: WeaponLimbPreset = WeaponLimbPresetScript.defaults_for(ResourceData.ResourceType.WOOD, 1)
	var none: WeaponLimbPreset = WeaponLimbPresetScript.defaults_for(ResourceData.ResourceType.NONE, 1)
	club.mark_walk1_pose_a_saved()
	club.walk1_support_hand_offset_px = Vector2(-88.0, 12.0)
	club.walk1_pull_support_hand_offset_px = Vector2(-150.0, 40.0)
	none.walk1_support_hand_offset_px = Vector2(-1.0, -1.0)
	none.walk1_pull_support_hand_offset_px = Vector2(-2.0, -2.0)
	club.seed_club_walk_off_arm_from_none(none)
	if club.walk1_support_hand_offset_px != Vector2(-88.0, 12.0):
		out.append("seed_club_walk_off_arm overwrote tuned walk1_support_hand")
	if club.walk1_pull_support_hand_offset_px != Vector2(-150.0, 40.0):
		out.append("seed_club_walk_off_arm overwrote tuned walk1_pull_support_hand")
	return out


func _test_walk1_saved_skips_idle_seed() -> Array[String]:
	var out: Array[String] = []
	var none: WeaponLimbPreset = WeaponLimbPresetScript.defaults_for(ResourceData.ResourceType.NONE, 1)
	none.hand_grip_offset_px = Vector2(10.0, 20.0)
	none.walk1_hand_grip_offset_px = Vector2(99.0, 88.0)
	none.mark_walk1_pose_a_saved()
	var before := TunerPoseSeedGuardScript.fingerprint(none)
	none.seed_walk1_from_idle_if_unset()
	var after := TunerPoseSeedGuardScript.fingerprint(none)
	if after.get("walk1_hand_grip_offset_px") != before.get("walk1_hand_grip_offset_px"):
		out.append("seed_walk1_from_idle_if_unset clobbered saved walk1 pose A")
	return out


func _test_gather1_saved_skips_reach_seed() -> Array[String]:
	var out: Array[String] = []
	var none: WeaponLimbPreset = WeaponLimbPresetScript.defaults_for(ResourceData.ResourceType.NONE, 1)
	none.gather1_hand_grip_offset_px = Vector2(12.0, 34.0)
	none.mark_gather1_reach_saved()
	var before := none.gather1_hand_grip_offset_px
	none.seed_gather1_from_idle_if_unset()
	if none.gather1_hand_grip_offset_px != before:
		out.append("seed_gather1_from_idle_if_unset clobbered saved gather reach")
	return out


func _test_club_walk_preview_session_keeps_disk_carry() -> Array[String]:
	var out: Array[String] = []
	var registry := LimbPresetRegistryScript.new()
	var club: WeaponLimbPreset = registry.reload_preset(ResourceData.ResourceType.WOOD, "clansmen_1")
	if club == null:
		out.append("club preset missing for preview session test")
		return out
	var before := TunerPoseSeedGuardScript.fingerprint(club)
	var packed := load("res://scenes/tools/LimbTuner.tscn") as PackedScene
	if packed == null:
		out.append("LimbTuner.tscn missing")
		return out
	var app: Node = packed.instantiate()
	root.add_child(app)
	for _i in range(8):
		await process_frame
	if not app.has_method("_begin_club_walk_preview_session"):
		out.append("LimbTuner missing _begin_club_walk_preview_session")
		app.queue_free()
		return out
	app.call("_begin_club_walk_preview_session")
	for _i in range(6):
		await process_frame
	var preset: WeaponLimbPreset = app.get("_preset")
	if preset == null:
		out.append("preview session preset missing")
		app.queue_free()
		return out
	var after := TunerPoseSeedGuardScript.fingerprint(preset)
	if after.get("hand_grip_offset_px") != before.get("hand_grip_offset_px"):
		out.append(
			"club walk preview changed hand_grip: %s"
			% str(TunerPoseSeedGuardScript.fingerprint_diff(before, after))
		)
	var body := preset.resolve_club_carry_body_hand_px()
	if preset.walk1_hand_grip_offset_px.distance_to(body) > 0.5:
		out.append("club walk preview: walk1_hand must match saved carry body")
	app.queue_free()
	return out
