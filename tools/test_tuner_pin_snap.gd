extends SceneTree
## Headless repro: drag dominant hand → commit → sync; fail if handle snaps back.
## Run: godot --headless -s res://tools/test_tuner_pin_snap.gd

const WeaponLimbPresetScript = preload("res://scripts/config/weapon_limb_preset.gd")
const LimbTunerClipBridgeScript = preload("res://scripts/tools/limb_tuner_clip_bridge.gd")
const AnimCatalogScript = preload("res://scripts/config/character_animation_catalog.gd")
const TunerPinSyncInstrumentationScript = preload(
	"res://scripts/tools/tuner_pin_sync_instrumentation.gd"
)
const SNAP_LIMIT_PX := 2.0


func _init() -> void:
	call_deferred("_run_all")


func _run_all() -> void:
	var failures: Array[String] = []
	failures.append_array(await _test_club_walk1_hand_drag_release())
	failures.append_array(await _test_club_idle_standing_hand_drag_release())
	failures.append_array(await _test_none_walk1_hand_drag_release())
	failures.append_array(await _test_club_walk_yellow_locked_on_art())
	if failures.is_empty():
		print("test_tuner_pin_snap: PASS")
		quit(0)
	else:
		for f in failures:
			push_error("test_tuner_pin_snap: FAIL — %s" % f)
		print("test_tuner_pin_snap: FAIL (%d)" % failures.size())
		quit(1)


func _test_club_walk1_hand_drag_release() -> Array[String]:
	return await _run_drag_release_case(
		"club_walk1",
		ResourceData.ResourceType.WOOD,
		WeaponLimbPresetScript.TunerAnimMode.WALK1,
		Vector2(40.0, -22.0)
	)


func _test_club_idle_standing_hand_drag_release() -> Array[String]:
	return await _run_drag_release_case(
		"club_idle",
		ResourceData.ResourceType.WOOD,
		WeaponLimbPresetScript.TunerAnimMode.IDLE,
		Vector2(28.0, -16.0)
	)


func _test_none_walk1_hand_drag_release() -> Array[String]:
	return await _run_drag_release_case(
		"none_walk1",
		ResourceData.ResourceType.NONE,
		WeaponLimbPresetScript.TunerAnimMode.WALK1,
		Vector2(35.0, -18.0)
	)


func _test_club_walk_yellow_locked_on_art() -> Array[String]:
	var out: Array[String] = []
	var packed := load("res://scenes/tools/LimbTuner.tscn") as PackedScene
	if packed == null:
		out.append("club_walk_yellow: LimbTuner.tscn missing")
		return out
	var app: Node = packed.instantiate()
	root.add_child(app)
	for _i in range(8):
		await process_frame
	app.call("_apply_pose_catalog_entry", ResourceData.ResourceType.WOOD, WeaponLimbPresetScript.TunerAnimMode.WALK1)
	app.call("_set_anim_mode", WeaponLimbPresetScript.TunerAnimMode.WALK1)
	for _i in range(6):
		await process_frame
	var rig: LimbTunerRig = app.get_node_or_null("World/Stage/TunerRig") as LimbTunerRig
	var yellow: Node2D = app.get_node_or_null("World/HandleLayer/HandleStage/SpearHandle") as Node2D
	var preset: WeaponLimbPreset = app.get("_preset")
	if rig == null or yellow == null or preset == null or rig.weapon_overlay == null:
		out.append("club_walk_yellow: rig, yellow, preset, or overlay missing")
		app.queue_free()
		return out
	if not preset.uses_saved_club_grip_on_art():
		out.append("club_walk_yellow: preset has no saved club grip on art")
		app.queue_free()
		return out
	var max_local_drift := 0.0
	app.set("_walk_ad_preview_active", true)
	app.set("_walk_ad_preview_elapsed", 0.0)
	for phase in [0.0, 0.25, 0.5, 0.75, 1.0]:
		app.set("_walk_ad_preview_elapsed", phase)
		LimbTunerClipBridgeScript.sample_walk_preview(app, phase, false)
		await process_frame
		var overlay := rig.weapon_overlay
		var sx: float = overlay.scale.x
		var sy: float = overlay.scale.y
		var clip = preset.get_unified_clip(AnimCatalogScript.CLIP_WALK)
		var grip_px = clip.pose_at_index(0).grip_on_art_px if clip != null else Vector2.ZERO
		if grip_px.length_squared() < 0.0001:
			grip_px = preset.resolve_club_overlay_grip_px(WeaponLimbPresetScript.TunerAnimMode.IDLE)
		var expected_local := Vector2(grip_px.x * sx, grip_px.y * sy)
		var actual_local := overlay.to_local(yellow.global_position)
		max_local_drift = maxf(max_local_drift, expected_local.distance_to(actual_local))
	app.set("_walk_ad_preview_active", false)
	if max_local_drift > 0.75:
		out.append(
			"club_walk_yellow: yellow drifted on club art during A/D walk (max local Δ=%.2fpx)"
			% max_local_drift
		)
	app.queue_free()
	return out

func _run_drag_release_case(
	case_id: String,
	weapon_type: ResourceData.ResourceType,
	anim_mode: WeaponLimbPreset.TunerAnimMode,
	drag_offset: Vector2
) -> Array[String]:
	var out: Array[String] = []
	var packed := load("res://scenes/tools/LimbTuner.tscn") as PackedScene
	if packed == null:
		out.append("%s: LimbTuner.tscn missing" % case_id)
		return out
	var app: Node = packed.instantiate()
	root.add_child(app)
	for _i in range(8):
		await process_frame
	if not app.has_method("_apply_pose_catalog_entry"):
		out.append("%s: LimbTuner script failed to load" % case_id)
		app.queue_free()
		return out
	app.call("_apply_pose_catalog_entry", weapon_type, anim_mode)
	if app.has_method("_set_anim_mode"):
		app.call("_set_anim_mode", anim_mode)
	for _i in range(6):
		await process_frame
	var rig: LimbTunerRig = app.get_node_or_null("World/Stage/TunerRig") as LimbTunerRig
	var hand: Node2D = app.get_node_or_null("World/HandleLayer/HandleStage/HandHandle") as Node2D
	if rig == null or hand == null:
		out.append("%s: rig or hand missing" % case_id)
		app.queue_free()
		return out
	var pin_instr: RefCounted = TunerPinSyncInstrumentationScript.new()
	pin_instr.enabled = true
	pin_instr.reset_session()
	app.set("_pin_sync_instrumentation", pin_instr)
	var before := hand.global_position
	var target := before + drag_offset
	app.set("_active_drag_handle", app.get("_hand_handle"))
	app.call("_on_hand_dragged", target)
	var after_drag := hand.global_position
	app.call("_commit_all_poses_to_preset", true)
	app.set("_active_drag_handle", null)
	app.call("_sync_assemble_preview")
	var after_sync := hand.global_position
	var drag_delta := before.distance_to(after_drag)
	var snap_delta := after_drag.distance_to(after_sync)
	if drag_delta < 4.0:
		out.append("%s: drag did not move hand (%.1fpx)" % [case_id, drag_delta])
	if snap_delta > SNAP_LIMIT_PX:
		out.append(
			"%s: hand snapped back after release Δ=%.1fpx (drag=%s sync=%s)"
			% [case_id, snap_delta, str(after_drag), str(after_sync)]
		)
	for v in pin_instr.violations:
		if v.begins_with("sync_overwrite 1h") or v.begins_with("drag_end_snap 1h"):
			out.append("%s: pin instrument: %s" % [case_id, v])
			break
	app.queue_free()
	return out
