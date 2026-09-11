extends SceneTree
## Regression: Save / commit must not write Walk clip Pose A from animation playback frames.
## Run: godot --headless -s res://tools/test_tuner_save_playback_guard.gd

const LimbPresetRegistryScript = preload("res://scripts/systems/limb_preset_registry.gd")
const CharacterAnimationPresetStoreScript = preload(
	"res://scripts/config/character_animation_preset_store.gd"
)
const CharacterAnimationPoseScript = preload("res://scripts/config/character_animation_pose.gd")

const POSE_A_HAND_1 := Vector2(115.7, 60.39)
const POSE_A_HAND_2 := Vector2(20.18, 31.88)
const POSE_B_HAND_1 := Vector2(233.16, 29.45)


func _init() -> void:
	call_deferred("_run_all")


func _run_all() -> void:
	var failures: Array[String] = []
	failures.append_array(await _test_walk_preview_commit_keeps_pose_a())
	failures.append_array(_test_save_all_skips_unedited_cached_presets())
	failures.append_array(await _test_walk_save_does_not_store_head_offset())
	if failures.is_empty():
		print("test_tuner_save_playback_guard: PASS")
		quit(0)
	else:
		for f in failures:
			push_error("test_tuner_save_playback_guard: FAIL — %s" % f)
		print("test_tuner_save_playback_guard: FAIL (%d)" % failures.size())
		quit(1)


func _seed_walk_clip(preset: WeaponLimbPreset) -> void:
	preset.ensure_unified_clips(null)
	var walk = CharacterAnimationPresetStoreScript.ensure_clip(
		preset, CharacterAnimationPresetStoreScript.CLIP_WALK, null
	)
	var pose_a = CharacterAnimationPoseScript.new()
	pose_a.hand_weapon_px = POSE_A_HAND_1
	pose_a.hand_support_px = POSE_A_HAND_2
	var pose_b = CharacterAnimationPoseScript.new()
	pose_b.hand_weapon_px = POSE_B_HAND_1
	pose_b.hand_support_px = Vector2(-163.4, 44.14)
	walk.set_pose_at_index(0, pose_a)
	walk.set_pose_at_index(1, pose_b)
	walk.saved = true
	walk.pose_b_saved = true


func _test_walk_preview_commit_keeps_pose_a() -> Array[String]:
	var out: Array[String] = []
	var registry := LimbPresetRegistryScript.new()
	var before: WeaponLimbPreset = registry.reload_preset(ResourceData.ResourceType.NONE, "clansmen_1")
	if before == null:
		out.append("none preset missing")
		return out
	_seed_walk_clip(before)
	registry.save_preset(before)
	before = registry.reload_preset(ResourceData.ResourceType.NONE, "clansmen_1")
	var walk_before = before.get_unified_clip(CharacterAnimationPresetStoreScript.CLIP_WALK)
	if walk_before == null:
		out.append("walk clip missing")
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
		out.append("walk preview preset missing")
		app.queue_free()
		return out
	app.call("_commit_all_poses_to_preset", false)
	var walk = preset.get_unified_clip(CharacterAnimationPresetStoreScript.CLIP_WALK)
	if walk == null:
		out.append("walk clip missing after preview")
		app.queue_free()
		return out
	if walk.pose_at_index(0).hand_weapon_px.distance_to(POSE_A_HAND_1) > 0.05:
		out.append(
			"commit while playing changed walk pose_a hand_weapon: %s"
			% str(walk.pose_at_index(0).hand_weapon_px)
		)
	if walk.pose_at_index(0).hand_support_px.distance_to(POSE_A_HAND_2) > 0.05:
		out.append(
			"commit while playing changed walk pose_a hand_support: %s"
			% str(walk.pose_at_index(0).hand_support_px)
		)
	if walk.pose_at_index(1).hand_weapon_px.distance_to(POSE_B_HAND_1) > 0.05:
		out.append("commit while playing changed walk pose_b hand_weapon")
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
	var spear_overlay := spear.overlay_offset_idle_px
	_seed_walk_clip(none)
	none.ensure_unified_clips(null)
	var walk = none.get_unified_clip(CharacterAnimationPresetStoreScript.CLIP_WALK)
	var restore_hand: Vector2 = walk.pose_at_index(0).hand_weapon_px
	walk.pose_at_index(0).hand_weapon_px = Vector2(777.0, 888.0)
	registry.mark_staged_dirty(none)
	var result: Dictionary = registry.save_all_staged()
	if int(result.get("count", 0)) != 1:
		out.append("save_all_staged should write only dirty preset, got %s" % str(result))
	var disk_spear: WeaponLimbPreset = registry.reload_preset(ResourceData.ResourceType.SPEAR, "clansmen_1")
	if disk_spear.overlay_offset_idle_px != spear_overlay:
		out.append("unchanged cached spear must not be written on save")
	walk.pose_at_index(0).hand_weapon_px = restore_hand
	registry.mark_staged_dirty(none)
	registry.save_all_staged()
	return out


func _test_walk_save_does_not_store_head_offset() -> Array[String]:
	var out: Array[String] = []
	var packed := load("res://scenes/tools/LimbTuner.tscn") as PackedScene
	if packed == null:
		out.append("LimbTuner.tscn missing")
		return out
	var app: Node = packed.instantiate()
	root.add_child(app)
	for _i in range(8):
		await process_frame
	if not app.has_method("_begin_walk1_edit_session"):
		out.append("LimbTuner missing _begin_walk1_edit_session")
		app.queue_free()
		return out
	app.call("_begin_walk1_edit_session")
	for _i in range(4):
		await process_frame
	var preset: WeaponLimbPreset = app.get("_preset")
	if preset == null:
		out.append("walk edit preset missing")
		app.queue_free()
		return out
	app.call("_finish_save_animation")
	await process_frame
	var walk = preset.get_unified_clip(CharacterAnimationPresetStoreScript.CLIP_WALK)
	if walk == null:
		out.append("walk clip missing after save")
		app.queue_free()
		return out
	var pose_a = walk.pose_at_index(0)
	if pose_a.head_offset_px.length_squared() > 0.0001:
		out.append(
			"walk save stored head_offset on pose_a: %s" % str(pose_a.head_offset_px)
		)
	if pose_a.grip_on_art_px.length_squared() > 0.0001:
		out.append(
			"walk save stored grip_on_art on pose_a: %s" % str(pose_a.grip_on_art_px)
		)
	app.queue_free()
	return out
