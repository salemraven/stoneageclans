extends SceneTree
## Animation prep gate: elbows, ping-pong, pose rows, hand drag stability.
## Run: godot --headless -s res://tools/test_tuner_elbow_pose_prep.gd

const WeaponLimbPresetScript = preload("res://scripts/config/weapon_limb_preset.gd")
const LimbTunerClipBridgeScript = preload("res://scripts/tools/limb_tuner_clip_bridge.gd")
const CharacterAnimationSamplerScript = preload("res://scripts/config/character_animation_sampler.gd")
const CharacterAnimationPresetStoreScript = preload(
	"res://scripts/config/character_animation_preset_store.gd"
)
const AnimCatalogScript = preload("res://scripts/config/character_animation_catalog.gd")
const TunerElbowInstrumentationScript = preload(
	"res://scripts/tools/tuner_elbow_instrumentation.gd"
)
const LimbPresetCoords = preload("res://scripts/systems/limb_preset_coords.gd")
const CharacterCardPartsRegistry = preload("res://scripts/config/character_card_parts_registry.gd")

const HANDLE_SYNC_LIMIT_PX := 2.0
const ON_ARM_LIMIT_PX := 4.0
const PING_PONG_EPS := 0.02


func _init() -> void:
	call_deferred("_run_all")


func _run_all() -> void:
	var failures: Array[String] = []
	failures.append_array(_test_ping_pong_phase())
	failures.append_array(_test_ping_pong_sample_endpoints())
	failures.append_array(await _test_walk_shoulders_use_morph_anchors())
	failures.append_array(await _test_walk_elbow_flip_both_arms())
	failures.append_array(await _test_elbow_stays_on_arm_after_hand_drag())
	failures.append_array(await _test_elbow_bend_preserved_on_hand_drag())
	failures.append_array(await _test_pose1_pose2_separate_elbows())
	failures.append_array(await _test_sync_frames_no_elbow_drift())
	failures.append_array(await _test_head_pin_on_neck_socket())
	if failures.is_empty():
		print("test_tuner_elbow_pose_prep: PASS")
		quit(0)
	else:
		for f in failures:
			push_error("test_tuner_elbow_pose_prep: FAIL — %s" % f)
		print("test_tuner_elbow_pose_prep: FAIL (%d)" % failures.size())
		quit(1)


func _test_ping_pong_phase() -> Array[String]:
	var out: Array[String] = []
	if absf(CharacterAnimationSamplerScript.ping_pong_phase(0.0, 1.0)) > PING_PONG_EPS:
		out.append("ping_pong: t=0 should be phase 0")
	if absf(CharacterAnimationSamplerScript.ping_pong_phase(1.0, 1.0) - 1.0) > PING_PONG_EPS:
		out.append("ping_pong: t=duration should be phase 1 (Pose 2)")
	if absf(CharacterAnimationSamplerScript.ping_pong_phase(2.0, 1.0)) > PING_PONG_EPS:
		out.append("ping_pong: t=2*duration should return to phase 0 (Pose 1)")
	var mid_back := CharacterAnimationSamplerScript.ping_pong_phase(1.5, 1.0)
	if absf(mid_back - 0.5) > PING_PONG_EPS:
		out.append("ping_pong: return leg should ease Pose 2→1 (got %.3f at 1.5s)" % mid_back)
	return out


func _test_ping_pong_sample_endpoints() -> Array[String]:
	var out: Array[String] = []
	var preset: WeaponLimbPreset = WeaponLimbPresetScript.defaults_for(ResourceData.ResourceType.NONE, 1)
	preset.ensure_unified_clips(null)
	var clip = preset.get_unified_clip(CharacterAnimationPresetStoreScript.CLIP_WALK)
	if clip == null:
		out.append("ping_pong_sample: walk clip missing")
		return out
	clip.pose_a.hand_weapon_px = Vector2(10, 40)
	clip.pose_b.hand_weapon_px = Vector2(10, 90)
	clip.duration_sec = 1.0
	var at_start = CharacterAnimationSamplerScript.sample_clip(clip, 0.0)
	var at_end = CharacterAnimationSamplerScript.sample_clip(clip, 1.0)
	var at_return = CharacterAnimationSamplerScript.sample_clip(clip, 2.0)
	if at_start.hand_weapon_px.distance_to(clip.pose_a.hand_weapon_px) > 0.5:
		out.append("ping_pong_sample: t=0 should match Pose 1 hand")
	if at_end.hand_weapon_px.distance_to(clip.pose_b.hand_weapon_px) > 0.5:
		out.append("ping_pong_sample: t=duration should match Pose 2 hand")
	if at_return.hand_weapon_px.distance_to(clip.pose_a.hand_weapon_px) > 0.5:
		out.append("ping_pong_sample: t=2*duration should match Pose 1 hand again")
	return out


func _test_walk_shoulders_use_morph_anchors() -> Array[String]:
	var out: Array[String] = []
	var ctx := await _boot_walk_tuner()
	if not ctx.ok:
		return ctx.failures
	var app: Node = ctx.app
	var preset: WeaponLimbPreset = ctx.preset
	var walk = preset.get_unified_clip(AnimCatalogScript.CLIP_WALK)
	if walk == null:
		out.append("shoulders: walk clip missing")
		app.queue_free()
		return out
	# Simulate partial pose row (hands only — shoulders unset in clip data).
	walk.pose_at_index(0).shoulder_weapon_px = Vector2.ZERO
	walk.pose_at_index(0).shoulder_support_px = Vector2(-18.0, -20.0)
	LimbTunerClipBridgeScript.load_active_pose(app)
	await process_frame
	var shoulder: Node2D = app.get("_shoulder_handle")
	var support_shoulder: Node2D = app.get("_support_shoulder_handle")
	if shoulder == null or support_shoulder == null:
		out.append("shoulders: handles missing")
		app.queue_free()
		return out
	var expected_weapon := LimbPresetCoords.body_global_from_display(
		ctx.rig.sprite, preset.shoulder_offset_px
	)
	var expected_support := LimbPresetCoords.body_global_from_display(
		ctx.rig.sprite, preset.support_shoulder_offset_px
	)
	if shoulder.global_position.distance_to(expected_weapon) > 2.0:
		out.append(
			"shoulders: weapon shoulder off morph anchor by %.1fpx"
			% shoulder.global_position.distance_to(expected_weapon)
		)
	if support_shoulder.global_position.distance_to(expected_support) > 2.0:
		out.append(
			"shoulders: support shoulder off morph anchor by %.1fpx"
			% support_shoulder.global_position.distance_to(expected_support)
		)
	app.queue_free()
	return out


func _test_walk_elbow_flip_both_arms() -> Array[String]:
	var out: Array[String] = []
	var ctx := await _boot_walk_tuner()
	if not ctx.ok:
		return ctx.failures
	var app: Node = ctx.app
	var preset: WeaponLimbPreset = ctx.preset
	var walk = preset.get_unified_clip(AnimCatalogScript.CLIP_WALK)
	for dominant in [true, false]:
		var label := "1e" if dominant else "2e"
		var before: float = (
			walk.pose_at_index(0).elbow_weapon_bend_sign
			if dominant
			else walk.pose_at_index(0).elbow_support_bend_sign
		)
		app.call("_flip_elbow_bend", dominant)
		await process_frame
		var after: float = (
			walk.pose_at_index(0).elbow_weapon_bend_sign
			if dominant
			else walk.pose_at_index(0).elbow_support_bend_sign
		)
		if absf(after) < 0.001:
			out.append("elbow_flip_%s: bend sign zero after flip" % label)
		if signf(before) == signf(after) and absf(before) > 0.001:
			out.append("elbow_flip_%s: bend sign did not change" % label)
		var sync_delta := LimbTunerClipBridgeScript.elbow_handle_delta_px(app, dominant)
		if sync_delta > HANDLE_SYNC_LIMIT_PX:
			out.append("elbow_flip_%s: handle off IK target by %.1fpx" % [label, sync_delta])
		var rig: LimbTunerRig = app.get("_rig")
		var arm_elbow := rig.elbow_joint_global_from_arms(dominant)
		var handle: Node2D = app.get("_weapon_elbow_handle") if dominant else app.get("_support_elbow_handle")
		var arm_delta := arm_elbow.distance_to(handle.global_position)
		if arm_delta > HANDLE_SYNC_LIMIT_PX:
			out.append("elbow_flip_%s: arm line off handle by %.1fpx" % [label, arm_delta])
	app.queue_free()
	return out


func _test_elbow_stays_on_arm_after_hand_drag() -> Array[String]:
	var out: Array[String] = []
	var ctx := await _boot_walk_tuner()
	if not ctx.ok:
		return ctx.failures
	var app: Node = ctx.app
	app.call("_flip_elbow_bend", true)
	app.call("_flip_elbow_bend", false)
	var hand: Node2D = app.get("_hand_handle")
	var support_hand: Node2D = app.get("_support_hand_handle")
	var offsets := [Vector2(24, -12), Vector2(-18, 20), Vector2(30, 8)]
	for offset in offsets:
		app.set("_active_drag_handle", hand)
		app.call("_on_hand_dragged", hand.global_position + offset)
		app.call("_lock_arm_lines_to_handles")
		await process_frame
		for dominant in [true, false]:
			var sync_delta := LimbTunerClipBridgeScript.elbow_handle_delta_px(app, dominant)
			if sync_delta > HANDLE_SYNC_LIMIT_PX:
				out.append(
					"hand_drag: %s handle Δ=%.1fpx after offset %s"
					% ["1e" if dominant else "2e", sync_delta, str(offset)]
				)
		app.set("_active_drag_handle", support_hand)
		app.call("_on_support_hand_dragged", support_hand.global_position + offset)
		app.call("_lock_arm_lines_to_handles")
		await process_frame
		for dominant in [true, false]:
			var sync_delta := LimbTunerClipBridgeScript.elbow_handle_delta_px(app, dominant)
			if sync_delta > HANDLE_SYNC_LIMIT_PX:
				out.append(
					"support_drag: %s handle Δ=%.1fpx after offset %s"
					% ["1e" if dominant else "2e", sync_delta, str(offset)]
				)
	app.queue_free()
	return out


func _test_elbow_bend_preserved_on_hand_drag() -> Array[String]:
	var out: Array[String] = []
	var ctx := await _boot_walk_tuner()
	if not ctx.ok:
		return ctx.failures
	var app: Node = ctx.app
	var preset: WeaponLimbPreset = ctx.preset
	var walk = preset.get_unified_clip(AnimCatalogScript.CLIP_WALK)
	app.call("_flip_elbow_bend", false)
	var bend_before: float = walk.pose_at_index(0).elbow_support_bend_sign
	var hand: Node2D = app.get("_hand_handle")
	app.set("_active_drag_handle", hand)
	app.call("_on_hand_dragged", hand.global_position + Vector2(20, -10))
	await process_frame
	var bend_after: float = walk.pose_at_index(0).elbow_support_bend_sign
	if signf(bend_before) != signf(bend_after):
		out.append(
			"bend_preserve: support bend flipped during weapon-hand drag (%s→%s)"
			% [str(bend_before), str(bend_after)]
		)
	app.queue_free()
	return out


func _test_pose1_pose2_separate_elbows() -> Array[String]:
	var out: Array[String] = []
	var ctx := await _boot_walk_tuner()
	if not ctx.ok:
		return ctx.failures
	var app: Node = ctx.app
	var preset: WeaponLimbPreset = ctx.preset
	var walk = preset.get_unified_clip(AnimCatalogScript.CLIP_WALK)
	app.call("_flip_elbow_bend", false)
	var pose1_bend: float = walk.pose_at_index(0).elbow_support_bend_sign
	app.call("_snap_pose_edit", true)
	await process_frame
	walk.pose_at_index(1).elbow_support_bend_sign = -pose1_bend
	LimbTunerClipBridgeScript.apply_pose_to_handles(app, walk.pose_at_index(1))
	var pose2_bend: float = walk.pose_at_index(1).elbow_support_bend_sign
	app.call("_snap_pose_edit", false)
	await process_frame
	var pose1_reload: float = walk.pose_at_index(0).elbow_support_bend_sign
	if signf(pose1_bend) != signf(pose1_reload):
		out.append(
			"pose_rows: Pose 1 support bend changed when editing Pose 2 (%s→%s)"
			% [str(pose1_bend), str(pose1_reload)]
		)
	if absf(pose1_bend - pose2_bend) < 0.001:
		out.append("pose_rows: Pose 2 support bend never diverged from Pose 1")
	app.queue_free()
	return out


func _test_sync_frames_no_elbow_drift() -> Array[String]:
	var out: Array[String] = []
	var ctx := await _boot_walk_tuner()
	if not ctx.ok:
		return ctx.failures
	var app: Node = ctx.app
	var rig: LimbTunerRig = ctx.rig
	app.call("_flip_elbow_bend", true)
	var elbow: Node2D = app.get("_weapon_elbow_handle")
	var baseline := elbow.global_position
	for _i in range(12):
		app.call("_sync_assemble_preview")
		await process_frame
	var drift := baseline.distance_to(elbow.global_position)
	if drift > 2.0:
		out.append("elbow_drift: 1e moved %.1fpx over 12 sync frames while static" % drift)
	var sync_delta := LimbTunerClipBridgeScript.elbow_handle_delta_px(app, true)
	if sync_delta > HANDLE_SYNC_LIMIT_PX:
		out.append("elbow_drift: 1e handle off IK by %.1fpx after sync frames" % sync_delta)
	app.queue_free()
	return out


func _test_head_pin_on_neck_socket() -> Array[String]:
	var out: Array[String] = []
	var ctx := await _boot_walk_tuner()
	if not ctx.ok:
		return ctx.failures
	var app: Node = ctx.app
	var rig: LimbTunerRig = ctx.rig
	var head: Node2D = app.get("_head_handle")
	if head == null:
		out.append("head_pin: HeadNeckHandle missing")
		app.queue_free()
		return out
	var neck := rig.neck_socket_global()
	var delta := head.global_position.distance_to(neck)
	if delta > HANDLE_SYNC_LIMIT_PX:
		out.append("head_pin: H handle %.1fpx from neck socket" % delta)
	var layout = CharacterCardPartsRegistry.get_layout()
	if layout.body_neck_socket_px.y < 0.0 or layout.body_neck_socket_px.y > 470.0:
		out.append(
			"head_pin: body_neck_socket_px.y out of body texture range: %s"
			% str(layout.body_neck_socket_px)
		)
	app.queue_free()
	return out


func _boot_walk_tuner() -> Dictionary:
	var failures: Array[String] = []
	var packed := load("res://scenes/tools/LimbTuner.tscn") as PackedScene
	if packed == null:
		return {"ok": false, "failures": ["boot: LimbTuner.tscn missing"]}
	var app: Node = packed.instantiate()
	root.add_child(app)
	for _i in range(8):
		await process_frame
	if not app.has_method("_begin_walk1_edit_session"):
		failures.append("boot: _begin_walk1_edit_session missing")
		app.queue_free()
		return {"ok": false, "failures": failures}
	app.call("_begin_walk1_edit_session")
	for _i in range(6):
		await process_frame
	var rig: LimbTunerRig = app.get("_rig")
	var preset: WeaponLimbPreset = app.get("_preset")
	if rig == null or preset == null:
		failures.append("boot: rig or preset missing")
		app.queue_free()
		return {"ok": false, "failures": failures}
	if not app.call("_uses_unified_tuner_pose"):
		failures.append("boot: expected unified static pose tuner mode")
	LimbTunerClipBridgeScript.load_active_pose(app)
	app.call("_lock_arm_lines_to_handles")
	return {"ok": failures.is_empty(), "app": app, "rig": rig, "preset": preset, "failures": failures}


func _measure_on_arm(app: Node, rig: LimbTunerRig, dominant: bool) -> float:
	return TunerElbowInstrumentationScript.measure_elbow_on_arm_rig_px(
		rig,
		_ctx_shoulder(app, dominant).global_position,
		_ctx_elbow(app, dominant).global_position,
		_ctx_hand(app, dominant).global_position,
		_ctx_upper(app, dominant),
		_ctx_lower(app, dominant)
	)


func _ctx_shoulder(app: Node, dominant: bool) -> Node2D:
	return app.get("_shoulder_handle") if dominant else app.get("_support_shoulder_handle")


func _ctx_hand(app: Node, dominant: bool) -> Node2D:
	return app.get("_hand_handle") if dominant else app.get("_support_hand_handle")


func _ctx_elbow(app: Node, dominant: bool) -> Node2D:
	return app.get("_weapon_elbow_handle") if dominant else app.get("_support_elbow_handle")


func _ctx_upper(app: Node, dominant: bool) -> float:
	var rig: LimbTunerRig = app.get("_rig")
	var preset: WeaponLimbPreset = app.get("_preset")
	var sx := absf(rig.sprite.scale.x) if rig and rig.sprite else 1.0
	return preset.resolve_upper_arm_length(dominant) * sx


func _ctx_lower(app: Node, dominant: bool) -> float:
	var rig: LimbTunerRig = app.get("_rig")
	var preset: WeaponLimbPreset = app.get("_preset")
	var sx := absf(rig.sprite.scale.x) if rig and rig.sprite else 1.0
	return preset.resolve_lower_arm_length(dominant) * sx
