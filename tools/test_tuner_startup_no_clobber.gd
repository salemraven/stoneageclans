extends SceneTree
## Regression: tuner startup must not clobber saved unified animation clips.
## Run: godot --headless -s res://tools/test_tuner_startup_no_clobber.gd

const LimbPresetRegistryScript = preload("res://scripts/systems/limb_preset_registry.gd")
const CharacterAnimationPresetStoreScript = preload(
	"res://scripts/config/character_animation_preset_store.gd"
)
const CharacterAnimationPoseScript = preload("res://scripts/config/character_animation_pose.gd")
const WeaponLimbPresetScript = preload("res://scripts/config/weapon_limb_preset.gd")


func _init() -> void:
	call_deferred("_run_all")


func _run_all() -> void:
	var failures: Array[String] = []
	failures.append_array(_test_unified_saved_skips_walk_seed())
	failures.append_array(_test_unified_saved_skips_gather_seed())
	failures.append_array(await _test_walk_edit_session_keeps_saved_clip())
	if failures.is_empty():
		print("test_tuner_startup_no_clobber: PASS")
		quit(0)
	else:
		for f in failures:
			push_error("test_tuner_startup_no_clobber: FAIL — %s" % f)
		print("test_tuner_startup_no_clobber: FAIL (%d)" % failures.size())
		quit(1)


func _test_unified_saved_skips_walk_seed() -> Array[String]:
	var out: Array[String] = []
	var none: WeaponLimbPreset = WeaponLimbPresetScript.defaults_for(ResourceData.ResourceType.NONE, 1)
	none.hand_grip_offset_px = Vector2(10.0, 20.0)
	none.ensure_unified_clips(null)
	var walk = CharacterAnimationPresetStoreScript.ensure_clip(
		none, CharacterAnimationPresetStoreScript.CLIP_WALK, null
	)
	var pose = CharacterAnimationPoseScript.new()
	pose.hand_weapon_px = Vector2(99.0, 88.0)
	walk.set_pose_at_index(0, pose)
	walk.saved = true
	none.unified_clips_initialized = true
	none.seed_walk1_from_idle_if_unset()
	var after = walk.pose_at_index(0).hand_weapon_px
	if after.distance_to(Vector2(99.0, 88.0)) > 0.01:
		out.append("seed_walk1 should no-op when unified_clips_initialized")
	return out


func _test_unified_saved_skips_gather_seed() -> Array[String]:
	var out: Array[String] = []
	var none: WeaponLimbPreset = WeaponLimbPresetScript.defaults_for(ResourceData.ResourceType.NONE, 1)
	none.ensure_unified_clips(null)
	var gather = CharacterAnimationPresetStoreScript.ensure_clip(
		none, CharacterAnimationPresetStoreScript.CLIP_GATHER, null
	)
	var pose = CharacterAnimationPoseScript.new()
	pose.hand_weapon_px = Vector2(12.0, 34.0)
	gather.set_pose_at_index(0, pose)
	gather.saved = true
	none.unified_clips_initialized = true
	none.seed_gather1_from_idle_if_unset()
	if gather.pose_at_index(0).hand_weapon_px.distance_to(Vector2(12.0, 34.0)) > 0.01:
		out.append("seed_gather1 should no-op when unified_clips_initialized")
	return out


func _test_walk_edit_session_keeps_saved_clip() -> Array[String]:
	var out: Array[String] = []
	var registry := LimbPresetRegistryScript.new()
	var none: WeaponLimbPreset = registry.reload_preset(ResourceData.ResourceType.NONE, "clansmen_1")
	if none == null:
		out.append("none preset missing")
		return out
	none.ensure_unified_clips(null)
	var walk = CharacterAnimationPresetStoreScript.ensure_clip(
		none, CharacterAnimationPresetStoreScript.CLIP_WALK, null
	)
	var saved_hand := Vector2(55.0, 66.0)
	walk.pose_at_index(0).hand_weapon_px = saved_hand
	walk.saved = true
	registry.save_preset(none)
	var packed := load("res://scenes/tools/LimbTuner.tscn") as PackedScene
	if packed == null:
		out.append("LimbTuner.tscn missing")
		return out
	var app: Node = packed.instantiate()
	root.add_child(app)
	for _i in range(8):
		await process_frame
	app.call("_begin_walk1_edit_session")
	for _i in range(6):
		await process_frame
	var preset: WeaponLimbPreset = app.get("_preset")
	var walk_after = preset.get_unified_clip(CharacterAnimationPresetStoreScript.CLIP_WALK)
	if walk_after == null:
		out.append("walk clip missing after edit session")
	elif walk_after.pose_at_index(0).hand_weapon_px.distance_to(saved_hand) > 0.5:
		out.append(
			"walk edit session clobbered saved pose_a hand: %s"
			% str(walk_after.pose_at_index(0).hand_weapon_px)
		)
	app.queue_free()
	return out
