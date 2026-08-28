extends SceneTree
## Verify --none-idle-edit loads unified idle Pose 1 (default rest), not sun-shield preview.
## Run: godot --headless -s res://tools/test_tuner_idle_default_load.gd

const LimbPresetCoords = preload("res://scripts/systems/limb_preset_coords.gd")
const CharacterAnimationPresetStoreScript = preload(
	"res://scripts/config/character_animation_preset_store.gd"
)

const EXPECT_HAND_1 := Vector2(186.65, 34.35)
const EXPECT_HAND_2 := Vector2(-136.47, 41.69)
const TOL_PX := 1.0


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var failures: Array[String] = []
	failures.append_array(await _test_idle_edit_loads_default_rest())
	if failures.is_empty():
		print("test_tuner_idle_default_load: PASS")
		quit(0)
	else:
		for f in failures:
			push_error("test_tuner_idle_default_load: FAIL — %s" % f)
		print("test_tuner_idle_default_load: FAIL (%d)" % failures.size())
		quit(1)


func _test_idle_edit_loads_default_rest() -> Array[String]:
	var out: Array[String] = []
	var packed := load("res://scenes/tools/LimbTuner.tscn") as PackedScene
	if packed == null:
		out.append("LimbTuner.tscn missing")
		return out
	var app: Node = packed.instantiate()
	root.add_child(app)
	for _i in range(8):
		await process_frame
	if not app.has_method("_begin_none_idle_session"):
		out.append("_begin_none_idle_session missing")
		app.queue_free()
		return out
	app.call("_begin_none_idle_session")
	for _i in range(6):
		await process_frame
		app.call("_sync_assemble_preview")
		await process_frame
	var rig: LimbTunerRig = app.get("_rig")
	var preset: WeaponLimbPreset = app.get("_preset")
	var hand: Node2D = app.get("_hand_handle")
	var support: Node2D = app.get("_support_hand_handle")
	if rig == null or preset == null or hand == null or support == null:
		out.append("rig/preset/handles missing after boot")
		app.queue_free()
		return out
	var idle_preview = rig.get("_idle")
	if idle_preview != null and idle_preview.is_pose_edit_active():
		out.append("sun-shield pose edit should be off in unified idle edit")
	if rig.get_idle_arm2_raise_blend() > 0.001:
		out.append(
			"off-hand raise blend should be 0 at rest, got %.3f" % rig.get_idle_arm2_raise_blend()
		)
	var clip = preset.get_unified_clip(CharacterAnimationPresetStoreScript.CLIP_IDLE)
	if clip == null:
		out.append("idle unified clip missing")
	else:
		var pose_a = clip.pose_at_index(0)
		if pose_a.hand_weapon_px.distance_to(EXPECT_HAND_1) > TOL_PX:
			out.append("disk pose_a hand_1 mismatch: %s" % str(pose_a.hand_weapon_px))
	var h1 := LimbPresetCoords.body_display_from_global(rig.sprite, hand.global_position)
	var h2 := LimbPresetCoords.body_display_from_global(rig.sprite, support.global_position)
	if h1.distance_to(EXPECT_HAND_1) > TOL_PX:
		out.append("live hand_1 display %s expected %s" % [str(h1), str(EXPECT_HAND_1)])
	if h2.distance_to(EXPECT_HAND_2) > TOL_PX:
		out.append("live hand_2 display %s expected %s" % [str(h2), str(EXPECT_HAND_2)])
	# Old sun-shield reach hands should NOT appear on startup.
	var reach_1 := Vector2(196.45, 29.45)
	if h1.distance_to(reach_1) < 8.0:
		out.append("hand_1 looks like stale sun-shield reach pose, not default rest")
	app.queue_free()
	return out
