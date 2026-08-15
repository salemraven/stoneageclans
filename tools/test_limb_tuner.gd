extends SceneTree

## Headless: limb preset registry + LimbTuner scene wiring.

const WeaponLimbPresetScript = preload("res://scripts/config/weapon_limb_preset.gd")
const LimbPresetRegistryScript = preload("res://scripts/systems/limb_preset_registry.gd")
const WeaponOverlayCombat = preload("res://scripts/systems/weapon_overlay_combat.gd")
const CombatComponent = preload("res://scripts/npc/components/combat_component.gd")

var _failures: Array[String] = []
var _registry: Node


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	await process_frame
	_registry = LimbPresetRegistryScript.new()
	_test_preset_defaults()
	_test_none_preset_path()
	_test_walk_fields_roundtrip()
	_test_save_roundtrip()
	_test_save_all_staged_holdables()
	_test_arm_thickness_preset()
	_test_walk_arm_swing()
	_test_walk_body_snapshot_alternates()
	_test_walk_keyframe_syncs_with_bounce()
	_test_limb_tuner_scene()
	_test_clip_browser()
	_test_pose_row_isolation()
	_test_commit_row_hand_isolation()
	_test_walk1_pose_b_support_elbow_paused()
	_test_idle_club_drag_handles()
	_test_club_windup_drag_handles()
	_test_club_windup_idle_loop()
	_test_elbow_bend_sign_flips_with_facing()
	_test_body_head_flip_with_travel_facing()
	_test_gather_motion_smooth()
	_test_gather_preset_lockin()
	_test_club_swing_facing_from_aim()
	_test_idle_club_combat_ready()
	_test_walk_preview_body_bounce()
	_test_none_walk_arm_swing_in_tuner()
	_test_walk_elbows_no_flip_in_tuner()
	_test_mannequin_walk_uses_walk_rest()
	_test_idle_travel_walk_on_ad()
	_test_weapon_rotation_attack_spin()
	_test_club_combat_ready_arm_pins()
	_test_club_shift_windup_loop_plays()
	_test_spear_yellow_pinned_to_hand()
	_test_spear_walk_grip_pinned_to_shaft()
	_test_spear_windup_pins_stacked()
	_test_spear_windup_drag_handles()
	_test_club_overlay_grip_fallback()
	_test_club_walk_carry_pose()
	_test_pose_snapshot_isolation()
	_test_idle_club1_minimal_scenario()
	_test_idle_arm2_raise_preview()
	_test_none_idle_sun_shield_keeps_walk_lock()
	_test_walk1_locked_poses()
	_test_walk1_pendulum_smooth()
	_test_ik_utils_elbow_pole()
	_test_golden_motion_files()
	_test_spear_idle_raise_no_flip()
	_test_gather_pick_cycle()
	_test_procedural_arms_still_pass()
	_report()
	quit()


func _test_preset_defaults() -> void:
	var preset: WeaponLimbPreset = _registry.get_preset(ResourceData.ResourceType.SPEAR, "clansmen_1", 1)
	if preset == null:
		_fail("preset null")
		return
	if preset.overlay_offset_idle_px == Vector2.ZERO:
		_fail("expected non-zero default overlay offset")


func _test_none_preset_path() -> void:
	var path: String = _registry.preset_path(ResourceData.ResourceType.NONE, "clansmen_1")
	if not path.ends_with("none_clansmen_1.tres"):
		_fail("none preset path wrong: %s" % path)
	var none_preset: WeaponLimbPreset = _registry.get_preset(ResourceData.ResourceType.NONE, "clansmen_1", 1)
	if none_preset.weapon_type != ResourceData.ResourceType.NONE:
		_fail("none preset weapon_type wrong")


func _test_walk_fields_roundtrip() -> void:
	var preset: WeaponLimbPreset = WeaponLimbPresetScript.defaults_for(ResourceData.ResourceType.WOOD, 1)
	preset.body_card_id = "test_walk"
	preset.walk_hand_grip_offset_px = Vector2(10.0, 20.0)
	preset.walk_overlay_offset_px = Vector2(30.0, -5.0)
	var err: Error = _registry.save_preset(preset)
	if err != OK:
		_fail("walk save failed %s" % str(err))
		return
	var reloaded: WeaponLimbPreset = _registry.reload_preset(ResourceData.ResourceType.WOOD, "test_walk")
	if reloaded.walk_hand_grip_offset_px != Vector2(10.0, 20.0):
		_fail("walk hand round-trip failed got %s" % str(reloaded.walk_hand_grip_offset_px))


func _test_save_roundtrip() -> void:
	var preset: WeaponLimbPreset = WeaponLimbPresetScript.defaults_for(ResourceData.ResourceType.SPEAR, 1)
	preset.body_card_id = "test_roundtrip"
	preset.shoulder_offset_px = Vector2(5.0, -12.0)
	preset.hand_grip_offset_px = Vector2(2.0, 80.0)
	preset.weapon_elbow_pole_idle_px = Vector2(3.0, -5.0)
	var err: Error = _registry.save_preset(preset)
	if err != OK:
		_fail("save_preset failed %s" % str(err))
		return
	var reloaded: WeaponLimbPreset = _registry.reload_preset(ResourceData.ResourceType.SPEAR, "test_roundtrip")
	if reloaded.shoulder_offset_px != Vector2(5.0, -12.0):
		_fail("shoulder round-trip failed got %s" % str(reloaded.shoulder_offset_px))
	if reloaded.hand_grip_offset_px != Vector2(2.0, 80.0):
		_fail("hand grip round-trip failed got %s" % str(reloaded.hand_grip_offset_px))
	if reloaded.weapon_elbow_pole_idle_px != Vector2(3.0, -5.0):
		_fail("elbow pole round-trip failed got %s" % str(reloaded.weapon_elbow_pole_idle_px))


func _test_save_all_staged_holdables() -> void:
	var none: WeaponLimbPreset = _registry.get_preset(ResourceData.ResourceType.NONE, "clansmen_1", 1)
	var spear: WeaponLimbPreset = _registry.get_preset(ResourceData.ResourceType.SPEAR, "clansmen_1", 1)
	var none_marker := none.walk_hand_grip_offset_px
	var spear_marker := spear.overlay_offset_idle_px
	none.walk_hand_grip_offset_px = none_marker + Vector2(3.0, 4.0)
	spear.overlay_offset_idle_px = spear_marker + Vector2(5.0, -2.0)
	_registry.stage_preset(none)
	_registry.stage_preset(spear)
	var result: Dictionary = _registry.save_all_staged()
	if int(result.get("count", 0)) < 2:
		_fail("save_all_staged should write multiple holdables, got %s" % str(result))
	if result.get("err", ERR_CANT_CREATE) != OK:
		_fail("save_all_staged failed err=%s keys=%s" % [str(result.get("err")), str(result.get("failed_keys"))])
	_registry.reload_all_presets("clansmen_1")
	var none_disk: WeaponLimbPreset = _registry.get_preset(ResourceData.ResourceType.NONE, "clansmen_1", 1)
	var spear_disk: WeaponLimbPreset = _registry.get_preset(ResourceData.ResourceType.SPEAR, "clansmen_1", 1)
	if none_disk.walk_hand_grip_offset_px != none_marker + Vector2(3.0, 4.0):
		_fail("save_all_staged did not persist none walk hand")
	if spear_disk.overlay_offset_idle_px != spear_marker + Vector2(5.0, -2.0):
		_fail("save_all_staged did not persist spear idle overlay")
	none.walk_hand_grip_offset_px = none_marker
	spear.overlay_offset_idle_px = spear_marker
	_registry.save_preset(none)
	_registry.save_preset(spear)
	_registry.reload_all_presets("clansmen_1")


func _test_arm_thickness_preset() -> void:
	const ProceduralArmConfigScript = preload("res://scripts/systems/procedural_arm_config.gd")
	var preset: WeaponLimbPreset = WeaponLimbPresetScript.defaults_for(ResourceData.ResourceType.NONE, 1)
	preset.apply_tuner_arm_thickness(22.0)
	if not is_equal_approx(preset.arm_width, 22.0):
		_fail("arm_width should be 22, got %s" % str(preset.arm_width))
	if not is_equal_approx(preset.hand_width, 22.0 * (10.0 / 14.0)):
		_fail("hand_width should taper with thickness, got %s" % str(preset.hand_width))
	var cfg: ProceduralArmConfig = ProceduralArmConfigScript.new()
	_registry.apply_to_arm_config(cfg, preset)
	if not is_equal_approx(cfg.arm_width, 22.0):
		_fail("arm config arm_width not synced from preset")
	preset.body_card_id = "test_thickness"
	var err: Error = _registry.save_preset(preset)
	if err != OK:
		_fail("thickness save failed %s" % str(err))
		return
	var reloaded: WeaponLimbPreset = _registry.reload_preset(ResourceData.ResourceType.NONE, "test_thickness")
	if not is_equal_approx(reloaded.arm_width, 22.0):
		_fail("arm_width round-trip failed got %s" % str(reloaded.arm_width))


func _test_walk_arm_swing() -> void:
	const WalkArmSwingScript = preload("res://scripts/systems/walk_arm_swing.gd")
	var rest_dom := Vector2(80.0, 60.0)
	var rest_sup := Vector2(-70.0, 55.0)
	var phase := PI * 0.5
	var swung_phase := WalkArmSwingScript.swing_phase_from_bounce(phase)
	var weapon := WalkArmSwingScript.swing_hand_local_offset(rest_dom, swung_phase, true, 1.0)
	var support := WalkArmSwingScript.swing_hand_local_offset(rest_sup, swung_phase, false, 1.0)
	if weapon.distance_squared_to(rest_dom) < 16.0:
		_fail("walk swing should move dominant hand away from rest at peak phase")
	if support.distance_squared_to(rest_sup) < 16.0:
		_fail("walk swing should move support hand away from rest at peak phase")
	var dom_travel := WalkArmSwingScript.travel_axis_offset(rest_dom, swung_phase, true, 1.0)
	var sup_travel := WalkArmSwingScript.travel_axis_offset(rest_sup, swung_phase, false, 1.0)
	if dom_travel * sup_travel > 0.0 and absf(dom_travel) > 0.01:
		_fail("walk swing should push arms in opposite travel directions at peak phase")
	if absf(sup_travel) <= absf(dom_travel):
		_fail("support arm should swing farther along travel than dominant")
	var left_dom := WalkArmSwingScript.travel_axis_offset(rest_dom, swung_phase, true, -1.0)
	if is_equal_approx(left_dom, dom_travel):
		_fail("walk swing should mirror when travel sign flips")
	if WalkArmSwingScript.reach_slack_ratio(false) <= WalkArmSwingScript.reach_slack_ratio(true):
		_fail("support arm should get more walk reach slack than dominant")
	var spear_dom_travel := absf(
		WalkArmSwingScript.travel_axis_offset(
			rest_dom, swung_phase, true, 1.0, ResourceData.ResourceType.SPEAR
		)
	)
	var none_dom_travel := absf(
		WalkArmSwingScript.travel_axis_offset(
			rest_dom, swung_phase, true, 1.0, ResourceData.ResourceType.NONE
		)
	)
	if spear_dom_travel >= none_dom_travel * 0.5:
		_fail("spear dominant walk should travel less forward/back than empty hands")
	var spear_dom := WalkArmSwingScript.swing_hand_local_offset(
		rest_dom, swung_phase, true, 1.0, ResourceData.ResourceType.SPEAR
	)
	var none_dom := WalkArmSwingScript.swing_hand_local_offset(
		rest_dom, swung_phase, true, 1.0, ResourceData.ResourceType.NONE
	)
	if absf(spear_dom.y - rest_dom.y) >= absf(none_dom.y - rest_dom.y):
		_fail("spear dominant walk should stay subtler vertically than empty-hands swing")
	var phase_b := swung_phase + PI
	var spear_a := WalkArmSwingScript.swing_hand_local_offset(
		rest_dom, swung_phase, true, 1.0, ResourceData.ResourceType.SPEAR
	)
	var spear_b := WalkArmSwingScript.swing_hand_local_offset(
		rest_dom, phase_b, true, 1.0, ResourceData.ResourceType.SPEAR
	)
	if absf(spear_a.y - spear_b.y) < 4.0:
		_fail("spear dominant walk should oscillate smoothly across half a cycle")


func _test_walk_body_snapshot_alternates() -> void:
	const WalkArmMotionScript = preload("res://scripts/systems/walk_arm_motion.gd")
	# Locked none_clansmen_1 walk poses — Pose 1 vs Pose 2 are opposite full-body frames.
	var pose1_dom := Vector2(228.2682, 78.41058)
	var pose2_dom := Vector2(76.93042, 97.59346)
	var pose1_sup := Vector2(-170.7422, 83.3064)
	var pose2_sup := Vector2(5.507812, 71.06683)
	var dom_start := WalkArmMotionScript.body_snapshot_between_keyframes(pose1_dom, pose2_dom, 0.0)
	var sup_start := WalkArmMotionScript.body_snapshot_between_keyframes(pose1_sup, pose2_sup, 0.0)
	var dom_mid := WalkArmMotionScript.body_snapshot_between_keyframes(pose1_dom, pose2_dom, 0.5)
	var sup_mid := WalkArmMotionScript.body_snapshot_between_keyframes(pose1_sup, pose2_sup, 0.5)
	if dom_start.x <= sup_start.x:
		_fail("walk snapshot t=0: dominant should be forward of support on X")
	var dom_delta_x := dom_mid.x - dom_start.x
	var sup_delta_x := sup_mid.x - sup_start.x
	if dom_delta_x * sup_delta_x > 0.0 and absf(dom_delta_x) > 1.0:
		_fail("walk snapshot: arms should move in opposite X directions over half cycle")


func _test_walk_keyframe_syncs_with_bounce() -> void:
	const WalkArmMotionScript = preload("res://scripts/systems/walk_arm_motion.gd")
	var period := TAU * WalkArmMotionScript.BOUNCE_CYCLES_PER_ARM_CYCLE
	var phase_start := WalkArmMotionScript.cycle_phase_from_bounce(0.0)
	var phase_mid_body := WalkArmMotionScript.cycle_phase_from_bounce(PI)
	var phase_one_bounce := WalkArmMotionScript.cycle_phase_from_bounce(TAU)
	var phase_full := WalkArmMotionScript.cycle_phase_from_bounce(period)
	if not is_equal_approx(phase_start, phase_full):
		_fail("walk keyframe phase should wrap after %s body bounce cycles" % WalkArmMotionScript.BOUNCE_CYCLES_PER_ARM_CYCLE)
	if is_equal_approx(phase_start, phase_mid_body):
		_fail("walk keyframe phase should advance during a body bounce")
	if is_equal_approx(phase_start, phase_one_bounce):
		_fail("walk arm cycle should be slower than one body bounce")
	var mid_blend := WalkArmMotionScript.body_snapshot_blend(0.25)
	if absf(mid_blend - 0.5) > 0.02:
		_fail("walk blend at quarter cycle should be cosine 0.5 (got %.3f) — no mid-swing rush" % mid_blend)


func _test_limb_tuner_scene() -> void:
	var packed := load("res://scenes/tools/LimbTuner.tscn") as PackedScene
	if packed == null:
		_fail("LimbTuner.tscn missing")
		return
	var app: Node = packed.instantiate()
	root.add_child(app)
	for _i in range(8):
		await process_frame
	var rig: LimbTunerRig = app.get_node_or_null("World/Stage/TunerRig") as LimbTunerRig
	if rig == null:
		_fail("TunerRig missing")
	elif rig.get_node_or_null("Sprite/BodyVisual") == null:
		_fail("BodyVisual mannequin missing")
	elif (rig.get_node("Sprite") as Sprite2D).texture != null:
		_fail("expected no card texture on tuner mannequin sprite")
	var holdable_grid: GridContainer = app.get_node_or_null(
		"UI/Panel/Margin/Scroll/VBox/TunerSection/SelectSection/HoldableRow/HoldableGrid"
	) as GridContainer
	if holdable_grid == null:
		_fail("holdable grid missing")
	elif holdable_grid.get_child_count() < 6:
		_fail("holdable grid too small: %d buttons" % holdable_grid.get_child_count())
	var category_row: HBoxContainer = app.get_node_or_null(
		"UI/Panel/Margin/Scroll/VBox/TunerSection/SelectSection/CategoryRow/CategoryButtons"
	) as HBoxContainer
	if category_row == null or category_row.get_child_count() < 4:
		_fail("category picker missing or incomplete")
	var thickness_spin: SpinBox = app.get_node_or_null(
		"UI/Panel/Margin/Scroll/VBox/TunerSection/ArmsSection/ArmThicknessRow/ArmThicknessSpin"
	) as SpinBox
	if thickness_spin == null:
		_fail("ArmThicknessSpin missing")
	elif thickness_spin.min_value > 2.0 or thickness_spin.max_value < 48.0:
		_fail("ArmThicknessSpin range unexpected")
	if rig.weapon_overlay != null and rig.weapon_overlay.visible:
		_fail("default weapon None should hide overlay")
	var handle_stage: Node2D = app.get_node_or_null("World/HandleLayer/HandleStage") as Node2D
	var stage: Node2D = app.get_node("World/Stage") as Node2D
	if handle_stage == null:
		_fail("HandleStage missing on HandleLayer")
	elif handle_stage.global_transform.origin.distance_to(stage.global_transform.origin) > 2.0:
		_fail(
			"HandleStage should track Stage world transform (dist=%.2f)"
			% handle_stage.global_transform.origin.distance_to(stage.global_transform.origin)
		)
	var shoulder: Node2D = handle_stage.get_node_or_null("ShoulderHandle") as Node2D
	if shoulder == null:
		_fail("ShoulderHandle missing on HandleStage overlay")
	elif shoulder.get_parent() != handle_stage:
		_fail("shoulder handle should stay on HandleStage overlay, got %s" % shoulder.get_parent().name)
	_test_tuner_draw_layers(rig)
	_test_tuner_arm_lines_draw(rig)
	var scale_before := stage.scale.x
	app.call(
		"_apply_pose_catalog_entry",
		ResourceData.ResourceType.WOOD,
		WeaponLimbPresetScript.TunerAnimMode.IDLE
	)
	for _i in range(6):
		await process_frame
	if rig.weapon_overlay == null or not rig.weapon_overlay.visible:
		_fail("club WeaponOverlay should be visible after selecting Club · Idle")
	elif rig.weapon_overlay.texture == null:
		_fail("club WeaponOverlay texture missing after selecting Club · Idle")
	if absf(stage.scale.x - scale_before) > 0.01:
		_fail("stage scale changed when switching pose catalog entry")
	if absf(app.stage_scale - 1.0) > 0.01:
		_fail("stage_scale export must stay 1.0 (1:1 with game), got %s" % str(app.stage_scale))
	if app.view_zoom < 1.0:
		_fail("view_zoom should be >= 1 for preview zoom")
	var club_preset: WeaponLimbPreset = _registry.reload_preset(ResourceData.ResourceType.WOOD, "clansmen_1")
	if club_preset != null:
		var overlay_px := club_preset.overlay_offset_idle_px
		var rig_overlay := rig.display_px_from_overlay_position()
		if rig_overlay.distance_to(overlay_px) > 3.0:
			_fail(
				"club idle standing overlay mismatch: saved=%s live=%s"
				% [str(overlay_px), str(rig_overlay)]
			)
		if absf(rad_to_deg(rig.weapon_overlay.rotation)) > 2.0:
			_fail(
				"club idle carry rotation should be ~0° got %.1f°"
				% rad_to_deg(rig.weapon_overlay.rotation)
			)
	var none_preset: WeaponLimbPreset = _registry.reload_preset(ResourceData.ResourceType.NONE, "clansmen_1")
	if none_preset == null:
		_fail("none_clansmen_1 preset missing")
	elif not none_preset.has_idle_arm2_raise_pose():
		_fail("none preset should define support_hand_idle_raise_offset_px")
	elif none_preset.support_hand_idle_offset_px.distance_to(Vector2(-86.28906, 52.03825)) > 2.0:
		_fail("none preset rest hand drifted from saved idle pose")
	app.queue_free()


func _test_clip_browser() -> void:
	var Catalog := load("res://scripts/config/character_animation_catalog.gd")
	var clips: Array = Catalog.all_clips()
	if clips.size() < 20:
		_fail("all_clips too small: %d" % clips.size())
		return
	var saw_none_walk1 := false
	var walk1_idx := -1
	for i in clips.size():
		var clip: Dictionary = clips[i]
		if clip.get("label") == "None · Walk 1":
			saw_none_walk1 = true
			walk1_idx = i
		if not Catalog.clip_can_loop(clip.get("weapon"), clip.get("mode")):
			if WeaponLimbPresetScript.is_idle_mode(clip.get("mode")):
				_fail("idle clip should loop: %s" % clip.get("label"))
	if not saw_none_walk1:
		_fail("all_clips missing None · Walk 1")
		return
	var packed := load("res://scenes/tools/LimbTuner.tscn") as PackedScene
	if packed == null:
		_fail("LimbTuner.tscn missing for clip browser test")
		return
	var app: Node = packed.instantiate()
	root.add_child(app)
	for _i in range(8):
		await process_frame
	var clip_list: ItemList = app.get_node_or_null(
		"UI/Panel/Margin/Scroll/VBox/ReviewerSection/ClipBrowserRow/ClipList"
	) as ItemList
	if clip_list == null:
		_fail("ClipList missing")
		app.queue_free()
		return
	if clip_list.item_count != clips.size():
		_fail("ClipList count %d != catalog %d" % [clip_list.item_count, clips.size()])
	app.call("_set_workspace_mode", app.WorkspaceMode.REVIEWER)
	for _i in range(4):
		await process_frame
	app.call("_select_clip_index", walk1_idx, true)
	if app.get("_anim_mode") != WeaponLimbPresetScript.TunerAnimMode.WALK1:
		_fail("clip browser did not select Walk 1")
	if app.get("_selected_weapon") != ResourceData.ResourceType.NONE:
		_fail("clip browser Walk 1 should use empty hands")
	if not app.get("_anim_playing"):
		_fail("clip browser should auto-play loopable Walk 1 in reviewer mode")
	app.call("_set_workspace_mode", app.WorkspaceMode.TUNER)
	for _i in range(4):
		await process_frame
	if app.get("_anim_playing"):
		_fail("tuner tab should pause playback by default")
	app.queue_free()


func _test_pose_row_isolation() -> void:
	var none: WeaponLimbPreset = _registry.reload_preset(ResourceData.ResourceType.NONE, "clansmen_1")
	var spear: WeaponLimbPreset = _registry.reload_preset(ResourceData.ResourceType.SPEAR, "clansmen_1")
	if none == null or spear == null:
		_fail("pose isolation presets missing")
		return
	var idle_elbow_before := none.weapon_elbow_pole_idle_px
	var spear_idle_before := spear.weapon_elbow_pole_idle_px
	none.set_elbow_pole_for_mode(true, WeaponLimbPresetScript.TunerAnimMode.WALK1, Vector2(111.0, -22.0))
	if none.weapon_elbow_pole_idle_px.distance_to(idle_elbow_before) > 0.01:
		_fail("walk1 elbow edit changed idle elbow on same holdable")
	if spear.weapon_elbow_pole_idle_px.distance_to(spear_idle_before) > 0.01:
		_fail("walk1 elbow edit on none must not change spear preset")
	none.set_walk1_elbow_pole(true, true, Vector2(55.0, -33.0))
	if none.walk1_weapon_elbow_pole_px.distance_to(Vector2(111.0, -22.0)) > 0.01:
		_fail("walk1 pose B elbow should not overwrite pose A elbow")
	# Seed gather row locally — gather not locked yet on disk; test only row isolation.
	if none.gather1_weapon_elbow_pole_px.length_squared() < 0.0001:
		none.gather1_weapon_elbow_pole_px = Vector2(12.0, -34.0)
		none.gather1_pull_weapon_elbow_pole_px = Vector2(20.0, -40.0)
	var gather_before := none.gather1_weapon_elbow_pole_px
	none.set_gather1_elbow_pole(true, true, Vector2(77.0, -88.0))
	if none.gather1_weapon_elbow_pole_px.distance_to(gather_before) > 0.01:
		_fail("gather pull elbow edit changed reach elbow row")
	if none.gather1_pull_weapon_elbow_pole_px.distance_to(Vector2(77.0, -88.0)) > 0.01:
		_fail("gather pull elbow should save to gather1_pull_weapon_elbow_pole_px")


func _test_commit_row_hand_isolation() -> void:
	var preset := WeaponLimbPresetScript.new()
	preset.walk1_hand_grip_offset_px = Vector2(10.0, 20.0)
	preset.walk1_support_hand_offset_px = Vector2(30.0, 40.0)
	preset.walk1_pull_hand_grip_offset_px = Vector2(50.0, 60.0)
	preset.walk1_pull_support_hand_offset_px = Vector2(70.0, 80.0)
	preset.gather1_hand_grip_offset_px = Vector2(11.0, 21.0)
	preset.gather1_support_hand_offset_px = Vector2(31.0, 41.0)
	preset.gather1_pull_hand_grip_offset_px = Vector2(51.0, 61.0)
	preset.gather1_pull_support_hand_offset_px = Vector2(71.0, 81.0)
	preset.commit_row_hand_display_px(
		WeaponLimbPresetScript.TunerAnimMode.WALK1,
		true,
		false,
		Vector2(111.0, 222.0),
		Vector2(333.0, 444.0)
	)
	if preset.walk1_hand_grip_offset_px.distance_to(Vector2(10.0, 20.0)) > 0.01:
		_fail("commit_row hands: walk1 pose B must not overwrite pose A dominant hand")
	if preset.walk1_support_hand_offset_px.distance_to(Vector2(30.0, 40.0)) > 0.01:
		_fail("commit_row hands: walk1 pose B must not overwrite pose A support hand")
	if preset.walk1_pull_hand_grip_offset_px.distance_to(Vector2(111.0, 222.0)) > 0.01:
		_fail("commit_row hands: walk1 pose B dominant should land in walk1_pull_hand_grip_offset_px")
	if preset.walk1_pull_support_hand_offset_px.distance_to(Vector2(333.0, 444.0)) > 0.01:
		_fail("commit_row hands: walk1 pose B support should land in walk1_pull_support_hand_offset_px")
	preset.commit_row_hand_display_px(
		WeaponLimbPresetScript.TunerAnimMode.GATHER1,
		false,
		true,
		Vector2(55.0, 66.0),
		Vector2(77.0, 88.0)
	)
	if preset.gather1_hand_grip_offset_px.distance_to(Vector2(11.0, 21.0)) > 0.01:
		_fail("commit_row hands: gather pull must not overwrite reach dominant hand")
	if preset.gather1_pull_support_hand_offset_px.distance_to(Vector2(77.0, 88.0)) > 0.01:
		_fail("commit_row hands: gather pull support should land in gather1_pull_support_hand_offset_px")
	if WeaponLimbPresetScript.resolve_pose_row_id(
		WeaponLimbPresetScript.TunerAnimMode.WALK1, true, false
	) != &"walk1_b":
		_fail("resolve_pose_row_id walk1 pose B")


func _test_walk1_pose_b_support_elbow_paused() -> void:
	const ProceduralArmScript = preload("res://scripts/systems/procedural_arm.gd")
	var none: WeaponLimbPreset = _registry.reload_preset(ResourceData.ResourceType.NONE, "clansmen_1")
	if none == null:
		_fail("none preset missing for walk1 pose B elbow test")
		return
	if none.walk1_pull_support_elbow_pole_px.length_squared() < 0.0001:
		_fail("walk1 pull support elbow pole missing on locked none preset")
	var packed := load("res://scenes/tools/LimbTuner.tscn") as PackedScene
	if packed == null:
		_fail("LimbTuner.tscn missing for walk1 pose B elbow test")
		return
	var app: Node = packed.instantiate()
	root.add_child(app)
	for _i in range(8):
		await process_frame
	app.call(
		"_apply_pose_catalog_entry",
		ResourceData.ResourceType.NONE,
		WeaponLimbPresetScript.TunerAnimMode.WALK1
	)
	for _i in range(4):
		await process_frame
	var rig: LimbTunerRig = app.get_node("World/Stage/TunerRig") as LimbTunerRig
	var support_elbow: Node2D = app.get_node_or_null(
		"World/HandleLayer/HandleStage/SupportElbowHandle"
	) as Node2D
	var support_hand: Node2D = app.get_node_or_null(
		"World/HandleLayer/HandleStage/SupportHandHandle"
	) as Node2D
	var support_shoulder: Node2D = app.get_node_or_null(
		"World/HandleLayer/HandleStage/SupportShoulderHandle"
	) as Node2D
	if rig == null or support_elbow == null or support_hand == null or support_shoulder == null:
		_fail("walk1 pose B elbow: rig or support handles missing")
		app.queue_free()
		return
	rig.call("set_preview_playing", false)
	rig.snap_walk_pose_edit(true)
	for _i in range(2):
		app.call("_sync_assemble_preview")
		await process_frame
	var sx: float = absf(rig.sprite.scale.x)
	var upper := none.resolve_upper_arm_length(false) * sx
	var lower := none.resolve_lower_arm_length(false) * sx
	var hand_g := rig.walk_support_hand_global_for_pose_edit(none, true)
	var shoulder_g := support_shoulder.global_position
	var expected := rig.elbow_joint_global_from_handles(
		none, false, WeaponLimbPresetScript.TunerAnimMode.WALK1, shoulder_g, hand_g
	)
	if support_elbow.global_position.distance_to(expected) > 2.0:
		_fail(
			"walk1 pose B support elbow drifted on first sync (got=%s expected=%s)"
			% [str(support_elbow.global_position), str(expected)]
		)
	var candidates: Array = ProceduralArmScript.ik_elbow_candidates(
		rig.to_local(shoulder_g),
		rig.to_local(hand_g),
		upper,
		lower,
		false
	)
	var elbow_local := rig.to_local(support_elbow.global_position)
	var last_prefers_a := elbow_local.distance_squared_to(candidates[0]) <= elbow_local.distance_squared_to(candidates[1])
	for _i in range(24):
		app.call("_sync_assemble_preview")
		await process_frame
		hand_g = rig.walk_support_hand_global_for_pose_edit(none, true)
		expected = rig.elbow_joint_global_from_handles(
			none, false, WeaponLimbPresetScript.TunerAnimMode.WALK1, shoulder_g, hand_g
		)
		if support_elbow.global_position.distance_to(expected) > 2.0:
			_fail("walk1 pose B support elbow drifted while paused (frame=%d)" % _i)
		candidates = ProceduralArmScript.ik_elbow_candidates(
			rig.to_local(shoulder_g),
			rig.to_local(hand_g),
			upper,
			lower,
			false
		)
		elbow_local = rig.to_local(support_elbow.global_position)
		var prefers_a := elbow_local.distance_squared_to(candidates[0]) <= elbow_local.distance_squared_to(candidates[1])
		if prefers_a != last_prefers_a:
			_fail("walk1 pose B support elbow IK branch flipped while paused")
		last_prefers_a = prefers_a
	app.queue_free()


func _test_idle_club_drag_handles() -> void:
	var packed := load("res://scenes/tools/LimbTuner.tscn") as PackedScene
	if packed == null:
		_fail("LimbTuner.tscn missing for idle club drag test")
		return
	var app: Node = packed.instantiate()
	root.add_child(app)
	for _i in range(6):
		await process_frame
	app.call(
		"_apply_pose_catalog_entry",
		ResourceData.ResourceType.WOOD,
		WeaponLimbPresetScript.TunerAnimMode.IDLE
	)
	for _i in range(8):
		await process_frame
	var rig: LimbTunerRig = app.get_node_or_null("World/Stage/TunerRig") as LimbTunerRig
	var hand: Node2D = app.get_node_or_null("World/HandleLayer/HandleStage/HandHandle") as Node2D
	var spear: Node2D = app.get_node_or_null("World/HandleLayer/HandleStage/SpearHandle") as Node2D
	if rig == null or hand == null or spear == null:
		_fail("idle club drag: rig or handles missing")
		app.queue_free()
		return
	var preset: WeaponLimbPreset = app.get("_preset")
	if preset == null:
		_fail("idle club drag: preset missing")
		app.queue_free()
		return
	var grip_on_art := LimbPresetCoords.overlay_grip_global(
		rig.weapon_overlay,
		preset.idle_club1_hand_grip_offset_px
	)
	if spear.global_position.distance_to(grip_on_art) > 1.5:
		_fail(
			"idle club: yellow pin off club grip by %.2f px (pin=%s art=%s)"
			% [spear.global_position.distance_to(grip_on_art), str(spear.global_position), str(grip_on_art)]
		)
	if hand.global_position.distance_to(spear.global_position) > 1.5:
		_fail("idle club: green 1h not stacked on yellow 3")
	for _i in range(6):
		app.call("_sync_assemble_preview")
	if spear.global_position.distance_to(grip_on_art) > 1.5:
		_fail("idle club: preview sync broke yellow↔club grip lock")
	app.set("_active_drag_handle", hand)
	var drag_target := grip_on_art + Vector2(30.0, -18.0)
	app.call("_on_hand_dragged", drag_target)
	for _i in range(3):
		app.call("_sync_assemble_preview")
	var grip_after := LimbPresetCoords.overlay_grip_global(
		rig.weapon_overlay,
		preset.idle_club1_hand_grip_offset_px
	)
	if spear.global_position.distance_to(grip_after) > 1.5:
		_fail("idle club: yellow pin drifted from club grip during hand drag")
	if hand.global_position.distance_to(spear.global_position) > 1.5:
		_fail("idle club: hand/spear not stacked during drag")
	var overlay_after_drag := rig.weapon_overlay.global_position
	for _i in range(8):
		rig.call("_update_motion_preview", 0.016)
	if rig.weapon_overlay.global_position.distance_to(overlay_after_drag) > 1.5:
		_fail(
			"idle club: motion preview reset club after drag (was %s now %s)"
			% [str(overlay_after_drag), str(rig.weapon_overlay.global_position)]
		)
	app.queue_free()


func _test_club_windup_drag_handles() -> void:
	var packed := load("res://scenes/tools/LimbTuner.tscn") as PackedScene
	if packed == null:
		_fail("LimbTuner.tscn missing for club windup drag test")
		return
	var app: Node = packed.instantiate()
	root.add_child(app)
	for _i in range(6):
		await process_frame
	if not app.has_method("_begin_club_windup_edit_session"):
		_fail("LimbTuner missing _begin_club_windup_edit_session")
		app.queue_free()
		return
	app.call("_begin_club_windup_edit_session")
	for _i in range(8):
		await process_frame
	var rig: LimbTunerRig = app.get_node_or_null("World/Stage/TunerRig") as LimbTunerRig
	var hand: Node2D = app.get_node_or_null("World/HandleLayer/HandleStage/HandHandle") as Node2D
	var spear: Node2D = app.get_node_or_null("World/HandleLayer/HandleStage/SpearHandle") as Node2D
	if rig == null or hand == null or spear == null:
		_fail("club windup drag: rig or handles missing")
		app.queue_free()
		return
	var preset: WeaponLimbPreset = app.get("_preset")
	if preset == null:
		_fail("club windup drag: preset missing")
		app.queue_free()
		return
	var attack_mode := WeaponLimbPresetScript.TunerAnimMode.ATTACK
	var grip_on_art := rig.hand_grip_global_from_preset(preset, attack_mode)
	if spear.global_position.distance_to(grip_on_art) > 1.5:
		_fail(
			"club windup: yellow pin off club grip by %.2f px"
			% spear.global_position.distance_to(grip_on_art)
		)
	if hand.global_position.distance_to(spear.global_position) > 1.5:
		_fail("club windup: green 1h not stacked on yellow 3")
	app.set("_active_drag_handle", spear)
	var overlay_before_club_drag := rig.weapon_overlay.global_position
	var club_drag_target := grip_on_art + Vector2(36.0, -22.0)
	app.call("_on_spear_dragged", club_drag_target)
	for _i in range(3):
		app.call("_sync_assemble_preview")
	var grip_after_club_drag := rig.hand_grip_global_from_preset(preset, attack_mode)
	if rig.weapon_overlay.global_position.distance_to(overlay_before_club_drag) < 1.5:
		_fail("club windup: club art should move when dragging yellow 3")
	if spear.global_position.distance_to(grip_after_club_drag) > 1.5:
		_fail("club windup: yellow pin did not follow club after weapon drag")
	if hand.global_position.distance_to(spear.global_position) > 1.5:
		_fail("club windup: hand/spear not stacked after weapon drag")
	app.set("_active_drag_handle", hand)
	var overlay_before_hand_drag := rig.weapon_overlay.global_position
	var hand_drag_target := grip_after_club_drag + Vector2(18.0, -12.0)
	app.call("_on_hand_dragged", hand_drag_target)
	for _i in range(3):
		app.call("_sync_assemble_preview")
	if rig.weapon_overlay.global_position.distance_to(overlay_before_hand_drag) < 1.5:
		_fail("club windup: club art should move when dragging green 1h")
	var grip_after_hand_drag := rig.hand_grip_global_from_preset(preset, attack_mode)
	if spear.global_position.distance_to(grip_after_hand_drag) > 1.5:
		_fail("club windup: yellow pin drifted from club grip during hand drag")
	if hand.global_position.distance_to(spear.global_position) > 1.5:
		_fail("club windup: hand/spear not stacked during hand drag")
	var shoulder := app.get_node_or_null("World/HandleLayer/HandleStage/ShoulderHandle") as Node2D
	if shoulder != null:
		var far_target := shoulder.global_position + Vector2(400.0, -50.0)
		app.call("_on_club_windup_grip_dragged", far_target)
		var max_reach := preset.tuner_ik_max_reach_px(true)
		if hand.global_position.distance_to(shoulder.global_position) <= max_reach + 2.0:
			_fail("club windup: grip drag should not clamp to arm reach (max=%.1f got %.1f)" % [
				max_reach,
				shoulder.global_position.distance_to(hand.global_position),
			])
	app.queue_free()


func _test_club_windup_idle_loop() -> void:
	var preset: WeaponLimbPreset = _registry.reload_preset(ResourceData.ResourceType.WOOD, "clansmen_1")
	if preset == null:
		_fail("club_clansmen_1 preset missing for windup idle loop test")
		return
	if not preset.has_club_windup_idle_loop():
		_fail("club_clansmen_1 must have windup idle keyframes on disk")
	var at_rest := preset.sample_club_windup_idle_loop(0.0)
	if at_rest.get("ready_offset_px", Vector2.ZERO).distance_to(preset.ready_offset_px) > 0.5:
		_fail("windup loop phase 0 must match rest ready_offset_px")
	if at_rest.get("support_hand_idle_offset_px", Vector2.ZERO).distance_to(
		preset.support_hand_idle_offset_px
	) > 0.5:
		_fail("windup loop phase 0 must match rest support_hand_idle_offset_px")
	var at_a := preset.sample_club_windup_idle_loop(1.0 / 3.0)
	if at_a.get("ready_offset_px", Vector2.ZERO).distance_to(
		preset.club_windup_idle_key_a_ready_offset_px
	) > 0.5:
		_fail("windup loop phase 1/3 must match key A ready_offset_px")
	var at_b := preset.sample_club_windup_idle_loop(2.0 / 3.0)
	if at_b.get("ready_offset_px", Vector2.ZERO).distance_to(
		preset.club_windup_idle_key_b_ready_offset_px
	) > 0.5:
		_fail("windup loop phase 2/3 must match key B ready_offset_px")
	var mid := preset.sample_club_windup_idle_loop(5.0 / 6.0)
	var rest_ready := preset.ready_offset_px
	var key_b_ready := preset.club_windup_idle_key_b_ready_offset_px
	var expected_mid := key_b_ready.lerp(rest_ready, 0.5)
	if mid.get("ready_offset_px", Vector2.ZERO).distance_to(expected_mid) > 2.0:
		_fail("windup loop late cycle should smoothstep between key B and rest")


func _test_elbow_bend_sign_flips_with_facing() -> void:
	var preset: WeaponLimbPreset = WeaponLimbPresetScript.defaults_for(ResourceData.ResourceType.WOOD, 1)
	preset.weapon_elbow_bend_sign_override = 1.0
	var east_auto := -WeaponLimbPresetScript.DOMINANT_ELBOW_BEND_SIGN
	var west_auto := WeaponLimbPresetScript.DOMINANT_ELBOW_BEND_SIGN
	var east_resolved := preset.resolve_elbow_bend_sign(
		true, WeaponLimbPresetScript.TunerAnimMode.IDLE, east_auto
	)
	var west_resolved := preset.resolve_elbow_bend_sign(
		true, WeaponLimbPresetScript.TunerAnimMode.IDLE, west_auto
	)
	if east_resolved != 1.0:
		_fail("east-facing elbow override + should resolve to +1, got %s" % str(east_resolved))
	if west_resolved != -1.0:
		_fail("west-facing elbow override + should resolve to -1, got %s" % str(west_resolved))


func _test_body_head_flip_with_travel_facing() -> void:
	var packed := load("res://scenes/tools/LimbTuner.tscn") as PackedScene
	if packed == null:
		_fail("LimbTuner.tscn missing for body/head facing test")
		return
	var app: Node = packed.instantiate()
	root.add_child(app)
	for _i in range(8):
		await process_frame
	var rig: LimbTunerRig = app.get_node_or_null("World/Stage/TunerRig") as LimbTunerRig
	if rig == null:
		_fail("TunerRig missing for body/head facing test")
		app.queue_free()
		return
	var body_visual: Node = rig.get_node_or_null("Sprite/BodyVisual")
	var sprite: Sprite2D = rig.get_node_or_null("Sprite") as Sprite2D
	if body_visual == null or sprite == null:
		_fail("body/head facing test missing BodyVisual or Sprite")
		app.queue_free()
		return
	sprite.flip_h = false
	body_visual.call("clear_motion_state")
	var body_sprite: Sprite2D = body_visual.call("get_body_sprite") as Sprite2D
	var head_sprite: Sprite2D = sprite.get_node_or_null("HeadPivot/HeadSprite") as Sprite2D
	if body_sprite == null or head_sprite == null:
		_fail("body/head facing test missing body or head sprite")
		app.queue_free()
		return
	if body_sprite.flip_h or head_sprite.flip_h:
		_fail("east-facing body/head should not flip_h at rest")
	rig.apply_travel_facing_direction(-1)
	if not sprite.flip_h:
		_fail("apply_travel_facing_direction should set sprite.flip_h for west")
	if not body_sprite.flip_h:
		_fail("west-facing body sprite should flip_h=true")
	if not head_sprite.flip_h:
		_fail("west-facing head sprite should flip_h=true at default look")
	rig.apply_travel_facing_direction(1)
	if sprite.flip_h or body_sprite.flip_h:
		_fail("east-facing body should flip_h=false after turn back")
	if head_sprite.flip_h:
		_fail("east-facing head should flip_h=false at default look")
	app.queue_free()


func _test_gather_motion_smooth() -> void:
	const GatherArmMotionScript = preload("res://scripts/systems/gather_arm_motion.gd")
	const STEPS := 240
	var max_bend_step := 0.0
	var max_pick_step := 0.0
	var prev_bend := GatherArmMotionScript.body_bend_amount(0.0)
	var prev_pick: Vector2 = Vector2.ZERO
	var had_pick := false
	for i in range(1, STEPS + 1):
		var phase := float(i) / float(STEPS)
		var bend := GatherArmMotionScript.body_bend_amount(phase)
		max_bend_step = maxf(max_bend_step, absf(bend - prev_bend))
		prev_bend = bend
		var arm_work := GatherArmMotionScript.arm_work_phase(phase)
		if arm_work >= 0.0:
			var pick := GatherArmMotionScript.hand_offset_between_keyframes(
				Vector2(40.0, 20.0), Vector2(10.0, 50.0), arm_work, true
			)
			if had_pick:
				max_pick_step = maxf(max_pick_step, pick.distance_to(prev_pick))
			prev_pick = pick
			had_pick = true
		else:
			had_pick = false
	# One step across full cycle — tighter than pre-smooth tuning (was ~0.05+ on pick snaps).
	if max_bend_step > 0.035:
		_fail("gather bend envelope step too large (%.4f)" % max_bend_step)
	if max_pick_step > 4.5:
		_fail("gather pick hand step too large (%.2f px)" % max_pick_step)


func _test_gather_preset_lockin() -> void:
	const GatherArmMotionScript = preload("res://scripts/systems/gather_arm_motion.gd")
	var preset := WeaponLimbPreset.new()
	preset.gather1_hand_grip_offset_px = Vector2(219.6391, 66.4864)
	preset.gather1_support_hand_offset_px = Vector2(-95.91631, 59.91696)
	preset.gather1_pull_hand_grip_offset_px = Vector2(123.0078, -52.90563)
	preset.gather1_pull_support_hand_offset_px = Vector2(-11.01562, 33.38344)
	if not preset.has_gather1_pull_pose():
		_fail("gather preset should expose pull pose")
	var reach := preset.gather1_hand_grip_offset_px
	var pull := preset.resolve_gather1_pull_hand(true)
	var mid := GatherArmMotionScript.hand_offset_between_keyframes(
		reach, pull, 0.5, true
	)
	if mid.is_equal_approx(reach) or mid.is_equal_approx(pull):
		_fail("gather pick blend should move hand between reach and pull mid-cycle")
	var copy_target := WeaponLimbPreset.new()
	copy_target.copy_gather1_pose_from(preset)
	if not copy_target.gather1_pull_hand_grip_offset_px.is_equal_approx(pull):
		_fail("copy_gather1_pose_from should copy pull dominant hand")


func _test_club_swing_facing_from_aim() -> void:
	var packed := load("res://scenes/tools/LimbTuner.tscn") as PackedScene
	if packed == null:
		_fail("LimbTuner.tscn missing for club swing facing test")
		return
	var app: Node = packed.instantiate()
	root.add_child(app)
	for _i in range(8):
		await process_frame
	app.call(
		"_apply_pose_catalog_entry",
		ResourceData.ResourceType.WOOD,
		WeaponLimbPresetScript.TunerAnimMode.IDLE
	)
	for _i in range(4):
		await process_frame
	var rig: LimbTunerRig = app.get_node("World/Stage/TunerRig") as LimbTunerRig
	var preset: WeaponLimbPreset = app.get("_preset")
	if rig == null or preset == null:
		_fail("club swing facing test missing rig or preset")
		app.queue_free()
		return
	rig.aim_dir = Vector2(-1.0, -0.2)
	rig.apply_preset_overlay_ready(preset, rig.aim_dir)
	var sprite: Sprite2D = rig.get_node("Sprite") as Sprite2D
	if not sprite.flip_h:
		_fail("club ready overlay should flip_h when aim is left")
	var body_visual: Node = rig.get_node("Sprite/BodyVisual")
	var body_sprite: Sprite2D = body_visual.call("get_body_sprite") as Sprite2D
	if body_sprite == null or not body_sprite.flip_h:
		_fail("club ready should mirror body sprite when aim is left")
	app.queue_free()


func _test_idle_club_combat_ready() -> void:
	var packed := load("res://scenes/tools/LimbTuner.tscn") as PackedScene
	if packed == null:
		_fail("LimbTuner.tscn missing for idle club combat ready test")
		return
	var app: Node = packed.instantiate()
	root.add_child(app)
	for _i in range(8):
		await process_frame
	app.call(
		"_apply_pose_catalog_entry",
		ResourceData.ResourceType.WOOD,
		WeaponLimbPresetScript.TunerAnimMode.IDLE
	)
	for _i in range(4):
		await process_frame
	var rig: LimbTunerRig = app.get_node("World/Stage/TunerRig") as LimbTunerRig
	if rig == null or rig.combat_component == null:
		_fail("idle club combat ready: missing rig or combat component")
		app.queue_free()
		return
	rig.combat_component.enter_ready(Vector2(1.0, 0.0))
	for _i in range(2):
		await process_frame
	if rig.combat_component.state != CombatComponent.CombatState.READY:
		_fail("idle club: enter_ready should set combat READY")
	var ostate: int = WeaponOverlayCombat.get_overlay_state(rig)
	if ostate != WeaponOverlayCombat.OverlayState.READY:
		_fail("idle club: overlay should be READY after enter_ready (got %d)" % ostate)
	rig.set_shift_ready_windup_loop(true)
	for _i in range(2):
		await process_frame
	# Tuner must not leave shift windup loop on during idle strike test — only Attack ▶ Play uses it.
	app.call("_process", 0.016)
	if rig.combat_component.state != CombatComponent.CombatState.READY:
		_fail("idle club: combat READY should survive tuner process tick")
	app.queue_free()


func _test_walk_preview_body_bounce() -> void:
	var packed := load("res://scenes/tools/LimbTuner.tscn") as PackedScene
	if packed == null:
		_fail("LimbTuner.tscn missing for walk bounce test")
		return
	var app: Node = packed.instantiate()
	root.add_child(app)
	for _i in range(8):
		await process_frame
	app.call(
		"_apply_pose_catalog_entry",
		ResourceData.ResourceType.WOOD,
		WeaponLimbPresetScript.TunerAnimMode.WALK
	)
	for _i in range(4):
		await process_frame
	var rig: LimbTunerRig = app.get_node("World/Stage/TunerRig") as LimbTunerRig
	if rig == null:
		_fail("walk bounce test: missing rig")
		app.queue_free()
		return
	rig.set_walk_direction(1)
	var min_y := INF
	var max_y := -INF
	for _i in range(40):
		await process_frame
		var y := rig.sprite.position.y
		min_y = minf(min_y, y)
		max_y = maxf(max_y, y)
	if max_y - min_y < 0.15:
		_fail("walk preview: sprite Y should bounce (range=%.3f)" % (max_y - min_y))
	app.queue_free()


func _test_none_walk_arm_swing_in_tuner() -> void:
	var none: WeaponLimbPreset = _registry.reload_preset(ResourceData.ResourceType.NONE, "clansmen_1")
	if none == null:
		_fail("none preset missing for walk keyframe test")
		return
	none.seed_walk1_from_idle_if_unset()
	none.walk1_pull_hand_grip_offset_px = none.walk1_hand_grip_offset_px + Vector2(48.0, 0.0)
	none.walk1_pull_support_hand_offset_px = none.walk1_support_hand_offset_px + Vector2(-48.0, 0.0)
	var packed := load("res://scenes/tools/LimbTuner.tscn") as PackedScene
	if packed == null:
		_fail("LimbTuner.tscn missing for none walk keyframe test")
		return
	var app: Node = packed.instantiate()
	root.add_child(app)
	for _i in range(8):
		await process_frame
	app.call(
		"_apply_pose_catalog_entry",
		ResourceData.ResourceType.NONE,
		WeaponLimbPresetScript.TunerAnimMode.WALK1
	)
	for _i in range(4):
		await process_frame
	var rig: LimbTunerRig = app.get_node("World/Stage/TunerRig") as LimbTunerRig
	var hand: Node2D = app.get_node_or_null("World/HandleLayer/HandleStage/HandHandle") as Node2D
	var support: Node2D = app.get_node_or_null("World/HandleLayer/HandleStage/SupportHandHandle") as Node2D
	if rig == null or hand == null or support == null:
		_fail("none walk keyframe: rig or handles missing")
		app.queue_free()
		return
	rig.set_preview_walk_mode(true)
	rig.set_walk_direction(1)
	rig.call("set_preview_playing", true)
	for _i in range(4):
		await process_frame
	if not rig.is_walking():
		_fail("none walk keyframe: rig should report walking while preview plays")
		app.queue_free()
		return
	var hand_start := hand.global_position
	var support_start := support.global_position
	var hand_peak := 0.0
	var support_peak := 0.0
	for _i in range(48):
		await process_frame
		hand_peak = maxf(hand_peak, hand.global_position.distance_to(hand_start))
		support_peak = maxf(support_peak, support.global_position.distance_to(support_start))
	if hand_peak < 12.0:
		_fail("none walk keyframe: dominant hand should move (peak=%.2f px)" % hand_peak)
	if support_peak < 12.0:
		_fail("none walk keyframe: support hand should move (peak=%.2f px)" % support_peak)
	app.queue_free()


func _test_walk_elbows_no_flip_in_tuner() -> void:
	const ProceduralArmScript = preload("res://scripts/systems/procedural_arm.gd")
	var none: WeaponLimbPreset = _registry.reload_preset(ResourceData.ResourceType.NONE, "clansmen_1")
	if none == null:
		_fail("none preset missing for walk elbow stability test")
		return
	var packed := load("res://scenes/tools/LimbTuner.tscn") as PackedScene
	if packed == null:
		_fail("LimbTuner.tscn missing for walk elbow stability test")
		return
	var app: Node = packed.instantiate()
	root.add_child(app)
	for _i in range(8):
		await process_frame
	app.call(
		"_apply_pose_catalog_entry",
		ResourceData.ResourceType.NONE,
		WeaponLimbPresetScript.TunerAnimMode.WALK1
	)
	for _i in range(4):
		await process_frame
	var rig: LimbTunerRig = app.get_node("World/Stage/TunerRig") as LimbTunerRig
	var weapon_elbow: Node2D = app.get_node_or_null(
		"World/HandleLayer/HandleStage/WeaponElbowHandle"
	) as Node2D
	var weapon_hand: Node2D = app.get_node_or_null(
		"World/HandleLayer/HandleStage/HandHandle"
	) as Node2D
	var weapon_shoulder: Node2D = app.get_node_or_null(
		"World/HandleLayer/HandleStage/ShoulderHandle"
	) as Node2D
	var support_elbow: Node2D = app.get_node_or_null(
		"World/HandleLayer/HandleStage/SupportElbowHandle"
	) as Node2D
	var support_hand: Node2D = app.get_node_or_null(
		"World/HandleLayer/HandleStage/SupportHandHandle"
	) as Node2D
	var support_shoulder: Node2D = app.get_node_or_null(
		"World/HandleLayer/HandleStage/SupportShoulderHandle"
	) as Node2D
	if (
		rig == null
		or weapon_elbow == null
		or weapon_hand == null
		or weapon_shoulder == null
		or support_elbow == null
		or support_hand == null
		or support_shoulder == null
	):
		_fail("walk elbow stability: rig or handles missing")
		app.queue_free()
		return
	none.seed_walk1_from_idle_if_unset()
	none.walk1_pull_hand_grip_offset_px = none.walk1_hand_grip_offset_px + Vector2(40.0, 0.0)
	none.walk1_pull_support_hand_offset_px = none.walk1_support_hand_offset_px + Vector2(-40.0, 0.0)
	rig.set_preview_walk_mode(true)
	rig.set_walk_direction(1)
	rig.call("set_preview_playing", true)
	for _i in range(4):
		await process_frame
	var sx: float = absf(rig.sprite.scale.x)
	_assert_walk_elbow_stable_over_cycle(
		rig, none, true, weapon_elbow, weapon_shoulder, weapon_hand, sx
	)
	_assert_walk_elbow_stable_over_cycle(
		rig, none, false, support_elbow, support_shoulder, support_hand, sx
	)
	app.queue_free()


func _assert_walk_elbow_stable_over_cycle(
	rig: LimbTunerRig,
	preset: WeaponLimbPreset,
	dominant: bool,
	elbow_node: Node2D,
	shoulder_node: Node2D,
	hand_node: Node2D,
	sx: float
) -> void:
	const ProceduralArmScript = preload("res://scripts/systems/procedural_arm.gd")
	var label := "dominant" if dominant else "support"
	var upper := preset.resolve_upper_arm_length(dominant) * sx
	var lower := preset.resolve_lower_arm_length(dominant) * sx
	var prev := elbow_node.global_position
	var max_step := 0.0
	var branch_flips := 0
	var candidates: Array = ProceduralArmScript.ik_elbow_candidates(
		rig.to_local(shoulder_node.global_position),
		rig.to_local(hand_node.global_position),
		upper,
		lower,
		true
	)
	var elbow_local := rig.to_local(prev)
	var last_prefers_a := elbow_local.distance_squared_to(candidates[0]) <= elbow_local.distance_squared_to(candidates[1])
	for _i in range(72):
		await process_frame
		var elbow_g := elbow_node.global_position
		max_step = maxf(max_step, elbow_g.distance_to(prev))
		prev = elbow_g
		candidates = ProceduralArmScript.ik_elbow_candidates(
			rig.to_local(shoulder_node.global_position),
			rig.to_local(hand_node.global_position),
			upper,
			lower,
			true
		)
		elbow_local = rig.to_local(elbow_g)
		var dist_a: float = elbow_local.distance_squared_to(candidates[0])
		var dist_b: float = elbow_local.distance_squared_to(candidates[1])
		var prefers_a := dist_a <= dist_b
		if prefers_a != last_prefers_a:
			branch_flips += 1
			last_prefers_a = prefers_a
	if max_step > 32.0:
		_fail("walk %s elbow jumped %.1f px in one frame (likely IK flip)" % [label, max_step])
	if branch_flips > 0:
		_fail("walk %s elbow switched IK branch %d times — should stay locked" % [label, branch_flips])


func _test_mannequin_walk_uses_walk_rest() -> void:
	const MannequinPoseRuntimeScript = preload("res://scripts/systems/mannequin_pose_runtime.gd")
	var none: WeaponLimbPreset = _registry.reload_preset(ResourceData.ResourceType.NONE, "clansmen_1")
	if none == null:
		_fail("none preset missing for mannequin walk rest test")
		return
	var packed := load("res://scenes/tools/LimbTuner.tscn") as PackedScene
	if packed == null:
		_fail("LimbTuner.tscn missing for mannequin walk rest test")
		return
	var app: Node = packed.instantiate()
	root.add_child(app)
	for _i in range(6):
		await process_frame
	var rig: LimbTunerRig = app.get_node("World/Stage/TunerRig") as LimbTunerRig
	if rig == null or rig.sprite == null:
		_fail("mannequin walk rest: missing rig")
		app.queue_free()
		return
	var endpoints := MannequinPoseRuntimeScript.resolve_arm_endpoints(
		rig,
		rig.sprite,
		null,
		none,
		ResourceData.ResourceType.NONE,
		WeaponOverlayCombat.OverlayState.IDLE,
		Vector2(1.0, 0.0),
		true,
		0.0
	)
	var weapon_rest := LimbPresetCoords.body_global_from_display(
		rig.sprite, none.resolve_walk_rest_hand_grip()
	)
	var support_rest := LimbPresetCoords.body_global_from_display(
		rig.sprite, none.resolve_walk_rest_support_hand()
	)
	var weapon_hand: Vector2 = endpoints.get("weapon_hand", Vector2.ZERO)
	var support_hand: Vector2 = endpoints.get("support_hand", Vector2.ZERO)
	# At bounce phase 0 with lag, swing may be non-zero — compare against idle rest to ensure walk row is used.
	var idle_weapon := LimbPresetCoords.body_global_from_display(
		rig.sprite, none.hand_grip_offset_px
	)
	if weapon_hand.distance_to(idle_weapon) < weapon_hand.distance_to(weapon_rest) * 0.5:
		_fail("mannequin walk should rest on walk1 hand row, not idle hand")
	if support_hand.distance_to(
		LimbPresetCoords.body_global_from_display(rig.sprite, none.support_hand_idle_offset_px)
	) < 4.0 and support_hand.distance_to(support_rest) > 8.0:
		_fail("mannequin walk support should use walk rest row")
	app.queue_free()


func _test_idle_travel_walk_on_ad() -> void:
	var packed := load("res://scenes/tools/LimbTuner.tscn") as PackedScene
	if packed == null:
		_fail("LimbTuner.tscn missing for idle travel walk test")
		return
	var app: Node = packed.instantiate()
	root.add_child(app)
	for _i in range(8):
		await process_frame
	app.call("_begin_club_preview_session")
	for _i in range(4):
		await process_frame
	var rig: LimbTunerRig = app.get_node("World/Stage/TunerRig") as LimbTunerRig
	if rig == null:
		_fail("idle travel walk: missing rig")
		app.queue_free()
		return
	if app.get("_anim_mode") != WeaponLimbPresetScript.TunerAnimMode.IDLE:
		_fail("idle travel walk: expected club idle startup mode")
	rig.set_walk_direction(1)
	var min_y := INF
	var max_y := -INF
	for _i in range(40):
		await process_frame
		var y := rig.sprite.position.y
		min_y = minf(min_y, y)
		max_y = maxf(max_y, y)
	if max_y - min_y < 0.15:
		_fail("idle travel walk: sprite Y should bounce (range=%.3f)" % (max_y - min_y))
	if not rig.is_walking():
		_fail("idle travel walk: rig should report walking when direction set")
	app.queue_free()


func _test_weapon_rotation_attack_spin() -> void:
	var packed := load("res://scenes/tools/LimbTuner.tscn") as PackedScene
	if packed == null:
		_fail("LimbTuner.tscn missing for weapon rotation test")
		return
	var app: Node = packed.instantiate()
	root.add_child(app)
	for _i in range(8):
		await process_frame
	app.call("_apply_pose_catalog_entry", ResourceData.ResourceType.WOOD, WeaponLimbPresetScript.TunerAnimMode.ATTACK)
	for _i in range(6):
		await process_frame
	var rig: LimbTunerRig = app.get_node("World/Stage/TunerRig") as LimbTunerRig
	if rig == null or rig.weapon_overlay == null:
		_fail("weapon rotation test: missing rig overlay")
		app.queue_free()
		return
	var before := rig.weapon_overlay.rotation
	app.call("_on_weapon_rotation_changed", 135.0)
	for _i in range(3):
		await process_frame
	if is_equal_approx(rig.weapon_overlay.rotation, before):
		_fail("weapon rotation spin should change overlay rotation")
	var preset: WeaponLimbPreset = app.get("_preset")
	if preset == null or not is_equal_approx(preset.attack_rotation_deg, 135.0):
		_fail("weapon rotation spin should store attack_rotation_deg=135 got %s" % str(preset.attack_rotation_deg if preset else null))
	app.queue_free()


func _test_club_combat_ready_arm_pins() -> void:
	var club: WeaponLimbPreset = WeaponLimbPresetScript.defaults_for(ResourceData.ResourceType.WOOD, 1)
	club.mark_club_attack_pose_saved()
	club.support_hand_offset_px = Vector2(-70.0, 56.0)
	if club.resolve_support_hand_for_mode(WeaponLimbPresetScript.TunerAnimMode.ATTACK) != Vector2(-70.0, 56.0):
		_fail("club attack support hand should use support_hand_offset_px when saved")
	var packed := load("res://scenes/tools/LimbTuner.tscn") as PackedScene
	if packed == null:
		_fail("LimbTuner.tscn missing for combat arm pin test")
		return
	var app: Node = packed.instantiate()
	root.add_child(app)
	for _i in range(8):
		await process_frame
	app.call(
		"_apply_pose_catalog_entry",
		ResourceData.ResourceType.WOOD,
		WeaponLimbPresetScript.TunerAnimMode.IDLE
	)
	for _i in range(4):
		await process_frame
	var rig: LimbTunerRig = app.get_node("World/Stage/TunerRig") as LimbTunerRig
	var hand: Node2D = app.get_node_or_null("World/HandleLayer/HandleStage/HandHandle") as Node2D
	if rig == null or hand == null or rig.combat_component == null:
		_fail("combat arm pin test: missing rig/hand/combat")
		app.queue_free()
		return
	rig.combat_component.enter_ready(Vector2(1.0, 0.0))
	for _i in range(2):
		await process_frame
	app.call("_apply_club_tuner_windup_ready", Vector2(1.0, 0.0))
	for _i in range(2):
		await process_frame
	var preset: WeaponLimbPreset = app.get("_preset")
	var grip_global := rig.hand_grip_global_from_preset(
		preset, WeaponLimbPresetScript.TunerAnimMode.ATTACK
	)
	if hand.global_position.distance_to(grip_global) > 3.0:
		_fail(
			"combat ready: hand should track overlay grip (drift=%.2f)"
			% hand.global_position.distance_to(grip_global)
		)
	app.queue_free()


func _test_club_shift_windup_loop_plays() -> void:
	var packed := load("res://scenes/tools/LimbTuner.tscn") as PackedScene
	if packed == null:
		_fail("LimbTuner.tscn missing for shift windup loop test")
		return
	var app: Node = packed.instantiate()
	root.add_child(app)
	for _i in range(8):
		await process_frame
	app.call(
		"_apply_pose_catalog_entry",
		ResourceData.ResourceType.WOOD,
		WeaponLimbPresetScript.TunerAnimMode.IDLE
	)
	for _i in range(4):
		await process_frame
	var rig: LimbTunerRig = app.get_node("World/Stage/TunerRig") as LimbTunerRig
	var preset: WeaponLimbPreset = app.get("_preset")
	if rig == null or preset == null or not preset.has_club_windup_idle_loop():
		_fail("shift windup loop test: missing rig or loop keyframes")
		app.queue_free()
		return
	app.call("_apply_club_tuner_windup_ready", Vector2(1.0, 0.0))
	for _i in range(6):
		await process_frame
	if not rig.is_shift_ready_windup_loop():
		_fail("shift windup: loop should be active after apply_club_tuner_windup_ready")
	var y0 := rig.weapon_overlay.position.y if rig.weapon_overlay else 0.0
	for _i in range(30):
		await process_frame
	var y1 := rig.weapon_overlay.position.y if rig.weapon_overlay else 0.0
	if absf(y1 - y0) < 0.05:
		_fail("shift windup loop should animate overlay (y delta=%.3f)" % absf(y1 - y0))
	app.queue_free()


func _test_spear_yellow_pinned_to_hand() -> void:
	var root := get_root()
	var packed := load("res://scenes/tools/LimbTuner.tscn") as PackedScene
	if packed == null:
		_fail("LimbTuner.tscn missing for spear yellow pin test")
		return
	var app: Node = packed.instantiate()
	root.add_child(app)
	for _i in range(6):
		await process_frame
	app.call(
		"_apply_pose_catalog_entry",
		ResourceData.ResourceType.SPEAR,
		WeaponLimbPresetScript.TunerAnimMode.IDLE
	)
	for _i in range(8):
		await process_frame
	var hand: Node2D = app.get_node_or_null("World/HandleLayer/HandleStage/HandHandle") as Node2D
	var spear: Node2D = app.get_node_or_null("World/HandleLayer/HandleStage/SpearHandle") as Node2D
	if hand == null or spear == null:
		_fail("spear yellow pin: handles missing")
		app.queue_free()
		return
	if hand.global_position.distance_to(spear.global_position) > 1.5:
		_fail(
			"spear idle: yellow 3 not stacked on green 1h (dist=%.2f hand=%s spear=%s)"
			% [hand.global_position.distance_to(spear.global_position), str(hand.global_position), str(spear.global_position)]
		)
	var preset: WeaponLimbPreset = app.get("_preset")
	var rig: LimbTunerRig = app.get_node_or_null("World/Stage/TunerRig") as LimbTunerRig
	if preset != null and rig != null and rig.weapon_overlay != null:
		var grip_on_art := LimbPresetCoords.overlay_grip_global(
			rig.weapon_overlay,
			preset.resolve_hand_grip_for_mode(WeaponLimbPresetScript.TunerAnimMode.IDLE)
		)
		if spear.global_position.distance_to(grip_on_art) > 2.0:
			_fail(
				"spear idle: yellow 3 not on spear art grip (dist=%.2f pin=%s art=%s)"
				% [spear.global_position.distance_to(grip_on_art), str(spear.global_position), str(grip_on_art)]
			)
	for _i in range(6):
		app.call("_sync_assemble_preview")
	if hand.global_position.distance_to(spear.global_position) > 1.5:
		_fail("spear idle: preview sync broke yellow↔1h stack")
	app.set("_active_drag_handle", hand)
	app.call("_on_hand_dragged", hand.global_position + Vector2(24.0, -12.0))
	for _i in range(3):
		app.call("_sync_assemble_preview")
	if hand.global_position.distance_to(spear.global_position) > 1.5:
		_fail("spear idle: yellow 3 drifted from 1h during hand drag")
	app.queue_free()


func _test_spear_walk_grip_pinned_to_shaft() -> void:
	var root := get_root()
	var packed := load("res://scenes/tools/LimbTuner.tscn") as PackedScene
	if packed == null:
		_fail("LimbTuner.tscn missing for spear walk grip test")
		return
	var app: Node = packed.instantiate()
	root.add_child(app)
	for _i in range(6):
		await process_frame
	app.call(
		"_apply_pose_catalog_entry",
		ResourceData.ResourceType.SPEAR,
		WeaponLimbPresetScript.TunerAnimMode.WALK
	)
	for _i in range(8):
		await process_frame
	var rig: LimbTunerRig = app.get_node_or_null("World/Stage/TunerRig") as LimbTunerRig
	var hand: Node2D = app.get_node_or_null("World/HandleLayer/HandleStage/HandHandle") as Node2D
	if rig == null or hand == null or rig.weapon_overlay == null:
		_fail("spear walk grip: rig, hand, or overlay missing")
		app.queue_free()
		return
	var preset: WeaponLimbPreset = app.get("_preset")
	if preset == null:
		_fail("spear walk grip: preset missing")
		app.queue_free()
		return
	rig.set_walk_direction(1)
	var max_drift := 0.0
	for _i in range(36):
		await process_frame
		var grip_on_art := LimbPresetCoords.overlay_grip_global(
			rig.weapon_overlay,
			preset.resolve_hand_grip_for_mode(WeaponLimbPresetScript.TunerAnimMode.WALK)
		)
		var drift := hand.global_position.distance_to(grip_on_art)
		max_drift = maxf(max_drift, drift)
		if drift > 2.5:
			_fail(
				"spear walk: hand slid off shaft grip (drift=%.2f hand=%s grip=%s)"
				% [drift, str(hand.global_position), str(grip_on_art)]
			)
			break
	if max_drift > 2.5:
		app.queue_free()
		return
	app.queue_free()


func _test_spear_windup_pins_stacked() -> void:
	var root := get_root()
	var packed := load("res://scenes/tools/LimbTuner.tscn") as PackedScene
	if packed == null:
		_fail("LimbTuner.tscn missing for spear windup pin test")
		return
	var app: Node = packed.instantiate()
	root.add_child(app)
	for _i in range(6):
		await process_frame
	app.call("_begin_spear_windup_edit_session")
	for _i in range(10):
		await process_frame
	var hand: Node2D = app.get_node_or_null("World/HandleLayer/HandleStage/HandHandle") as Node2D
	var support: Node2D = app.get_node_or_null("World/HandleLayer/HandleStage/SupportHandHandle") as Node2D
	var y1: Node2D = app.get_node_or_null("World/HandleLayer/HandleStage/SpearHandle") as Node2D
	var y2: Node2D = app.get_node_or_null("World/HandleLayer/HandleStage/SpearGrip2Handle") as Node2D
	var preset: WeaponLimbPreset = app.get("_preset")
	var rig: LimbTunerRig = app.get_node_or_null("World/Stage/TunerRig") as LimbTunerRig
	if hand == null or support == null or y1 == null or y2 == null or preset == null or rig == null:
		_fail("spear windup: handles or preset missing")
		app.queue_free()
		return
	if not y2.visible:
		_fail("spear windup: Y2 handle should be visible in windup edit")
	for _i in range(6):
		app.call("_sync_spear_windup_handles")
	if hand.global_position.distance_to(y1.global_position) > 1.5:
		_fail(
			"spear windup: 1h not stacked on Y1 (dist=%.2f)"
			% hand.global_position.distance_to(y1.global_position)
		)
	if support.global_position.distance_to(y2.global_position) > 1.5:
		_fail(
			"spear windup: 2h not stacked on Y2 (dist=%.2f)"
			% support.global_position.distance_to(y2.global_position)
		)
	var y1_on_art := rig.spear_windup_dominant_grip_global(preset)
	var y2_on_art := rig.spear_windup_support_grip_global(preset)
	if y1.global_position.distance_to(y1_on_art) > 2.0:
		_fail("spear windup: Y1 drifted off dominant shaft grip on art")
	if y2.global_position.distance_to(y2_on_art) > 2.0:
		_fail("spear windup: Y2 drifted off support shaft grip on art")
	app.queue_free()


func _test_spear_windup_drag_handles() -> void:
	var packed := load("res://scenes/tools/LimbTuner.tscn") as PackedScene
	if packed == null:
		_fail("LimbTuner.tscn missing for spear windup drag test")
		return
	var app: Node = packed.instantiate()
	root.add_child(app)
	for _i in range(6):
		await process_frame
	if not app.has_method("_begin_spear_windup_edit_session"):
		_fail("LimbTuner missing _begin_spear_windup_edit_session")
		app.queue_free()
		return
	app.call("_begin_spear_windup_edit_session")
	for _i in range(10):
		await process_frame
	var rig: LimbTunerRig = app.get_node_or_null("World/Stage/TunerRig") as LimbTunerRig
	var hand: Node2D = app.get_node_or_null("World/HandleLayer/HandleStage/HandHandle") as Node2D
	var y1: Node2D = app.get_node_or_null("World/HandleLayer/HandleStage/SpearHandle") as Node2D
	if rig == null or hand == null or y1 == null:
		_fail("spear windup drag: rig or handles missing")
		app.queue_free()
		return
	var preset: WeaponLimbPreset = app.get("_preset")
	if preset == null:
		_fail("spear windup drag: preset missing")
		app.queue_free()
		return
	var y1_on_art := rig.spear_windup_dominant_grip_global(preset)
	if y1.global_position.distance_to(y1_on_art) > 2.0:
		_fail("spear windup drag: Y1 not on shaft grip before drag")
	if hand.global_position.distance_to(y1.global_position) > 1.5:
		_fail("spear windup drag: 1h not stacked on Y1 before drag")
	app.set("_active_drag_handle", y1)
	var overlay_before_y1_drag := rig.weapon_overlay.global_position
	var y1_drag_target := y1_on_art + Vector2(42.0, -18.0)
	app.call("_on_spear_dragged", y1_drag_target)
	for _i in range(3):
		app.call("_sync_assemble_preview")
	var y1_after_y1_drag := rig.spear_windup_dominant_grip_global(preset)
	if rig.weapon_overlay.global_position.distance_to(overlay_before_y1_drag) < 1.5:
		_fail("spear windup: spear art should move when dragging yellow Y1")
	if y1.global_position.distance_to(y1_after_y1_drag) > 1.5:
		_fail("spear windup: yellow Y1 did not follow spear after Y1 drag")
	if hand.global_position.distance_to(y1.global_position) > 1.5:
		_fail("spear windup: green 1h not stacked after Y1 drag")
	app.set("_active_drag_handle", hand)
	var overlay_before_hand_drag := rig.weapon_overlay.global_position
	var hand_drag_target := y1_after_y1_drag + Vector2(24.0, -10.0)
	app.call("_on_hand_dragged", hand_drag_target)
	for _i in range(3):
		app.call("_sync_assemble_preview")
	if rig.weapon_overlay.global_position.distance_to(overlay_before_hand_drag) < 1.5:
		_fail("spear windup: spear art should move when dragging green 1h")
	var y1_after_hand_drag := rig.spear_windup_dominant_grip_global(preset)
	if y1.global_position.distance_to(y1_after_hand_drag) > 1.5:
		_fail("spear windup: yellow Y1 drifted from shaft grip during 1h drag")
	if hand.global_position.distance_to(y1.global_position) > 1.5:
		_fail("spear windup: green 1h not stacked during 1h drag")
	var shoulder := app.get_node_or_null("World/HandleLayer/HandleStage/ShoulderHandle") as Node2D
	if shoulder != null:
		var far_target := shoulder.global_position + Vector2(420.0, -40.0)
		app.call("_on_spear_windup_grip_dragged", far_target)
		var max_reach := preset.tuner_ik_max_reach_px(true)
		if hand.global_position.distance_to(shoulder.global_position) <= max_reach + 2.0:
			_fail(
				"spear windup: grip drag should not clamp to arm reach (max=%.1f got %.1f)"
				% [max_reach, shoulder.global_position.distance_to(hand.global_position)]
			)
	app.queue_free()


func _test_club_overlay_grip_fallback() -> void:
	var club: WeaponLimbPreset = WeaponLimbPresetScript.defaults_for(ResourceData.ResourceType.WOOD, 1)
	club.hand_grip_offset_px = Vector2.ZERO
	club.idle_club1_hand_grip_offset_px = Vector2(0.0, -67.0)
	club.mark_club_grip_on_art_authoritative()
	var idle_grip := club.resolve_club_overlay_grip_px(WeaponLimbPresetScript.TunerAnimMode.IDLE)
	if idle_grip != Vector2(0.0, -67.0):
		_fail("authoritative club grip must be used for idle standing display")
	var rig_script: GDScript = load("res://scripts/tools/limb_tuner_rig.gd") as GDScript
	var rig: Node = rig_script.new()
	root.add_child(rig)
	if rig.has_method("snap_hand_grip_to_weapon_anchor"):
		var before := club.idle_club1_hand_grip_offset_px
		rig.call("snap_hand_grip_to_weapon_anchor", club, false)
		if club.idle_club1_hand_grip_offset_px != before:
			_fail("snap_hand_grip must not overwrite authoritative club grip")
	rig.queue_free()


func _test_club_walk_carry_pose() -> void:
	var club_preset: WeaponLimbPreset = WeaponLimbPresetScript.defaults_for(ResourceData.ResourceType.WOOD, 1)
	club_preset.hand_grip_offset_px = Vector2(0.0, 0.0)
	club_preset.idle_club1_hand_grip_offset_px = Vector2(0.0, -67.0)
	if club_preset.resolve_walk_rest_hand_grip() != Vector2(0.0, 0.0):
		_fail("club walk rest grip must use idle standing row, not idle_club1")
	var packed := load("res://scenes/tools/LimbTuner.tscn") as PackedScene
	if packed == null:
		_fail("LimbTuner.tscn missing for club walk carry test")
		return
	var app: Node = packed.instantiate()
	root.add_child(app)
	for _i in range(6):
		await process_frame
	app.call(
		"_apply_pose_catalog_entry",
		ResourceData.ResourceType.WOOD,
		WeaponLimbPresetScript.TunerAnimMode.IDLE
	)
	if app.has_method("_set_anim_mode"):
		app.call("_set_anim_mode", WeaponLimbPresetScript.TunerAnimMode.WALK)
	for _i in range(6):
		await process_frame
	var rig: LimbTunerRig = app.get_node_or_null("World/Stage/TunerRig") as LimbTunerRig
	var hand: Node2D = app.get_node_or_null("World/HandleLayer/HandleStage/HandHandle") as Node2D
	var support: Node2D = app.get_node_or_null("World/HandleLayer/HandleStage/SupportHandHandle") as Node2D
	if rig == null or hand == null or support == null:
		_fail("club walk carry: rig or handles missing")
		app.queue_free()
		return
	rig.set_walk_direction(1)
	for _i in range(4):
		await process_frame
	var weapon_rest := hand.global_position
	var support_rest := support.global_position
	for _i in range(24):
		await process_frame
	if hand.global_position.distance_squared_to(weapon_rest) > 4.0:
		_fail(
			"club walk: weapon hand should stay in idle carry pose (moved %.2f px)"
			% hand.global_position.distance_to(weapon_rest)
		)
	if support.global_position.distance_squared_to(support_rest) > 16.0:
		_fail("club walk: support hand should still swing while walking")
	app.queue_free()


func _test_pose_snapshot_isolation() -> void:
	const WeaponLimbPresetScript = preload("res://scripts/config/weapon_limb_preset.gd")
	var club: WeaponLimbPreset = _registry.reload_preset(ResourceData.ResourceType.WOOD, "clansmen_1")
	if club == null:
		_fail("club_clansmen_1 preset missing for snapshot isolation test")
		return
	var idle_overlay := club.overlay_offset_idle_px
	var club_attack_overlay := club.resolve_overlay_for_mode(
		WeaponLimbPresetScript.TunerAnimMode.ATTACK
	)
	if not club.club_attack_inherits_idle() and club_attack_overlay.distance_to(idle_overlay) < 8.0:
		_fail("saved club attack overlay must differ from idle standing on disk")
	var club1_overlay := club.idle_club1_overlay_offset_px
	if idle_overlay.distance_to(club1_overlay) < 8.0:
		_fail("test needs distinct idle vs idle_club1 overlays on disk")
	if WeaponLimbPresetScript.tuner_overlay_storage_mode(
		WeaponLimbPresetScript.TunerAnimMode.IDLE, ResourceData.ResourceType.WOOD
	) != WeaponLimbPresetScript.TunerAnimMode.IDLE:
		_fail("idle standing must read idle overlay row")
	if WeaponLimbPresetScript.tuner_overlay_storage_mode(
		WeaponLimbPresetScript.TunerAnimMode.IDLE_CLUB1, ResourceData.ResourceType.WOOD
	) != WeaponLimbPresetScript.TunerAnimMode.IDLE_CLUB1:
		_fail("idle club1 must read idle_club1 overlay row")
	if WeaponLimbPresetScript.tuner_overlay_storage_mode(
		WeaponLimbPresetScript.TunerAnimMode.WALK, ResourceData.ResourceType.WOOD
	) != WeaponLimbPresetScript.TunerAnimMode.IDLE:
		_fail("club walk weapon overlay must borrow idle standing row")
	if WeaponLimbPresetScript.tuner_overlay_storage_mode(
		WeaponLimbPresetScript.TunerAnimMode.WALK, ResourceData.ResourceType.SPEAR
	) != WeaponLimbPresetScript.TunerAnimMode.WALK:
		_fail("spear walk must read walk overlay row")
	if club.club_attack_inherits_idle():
		if club.resolve_overlay_for_mode(WeaponLimbPresetScript.TunerAnimMode.ATTACK) != idle_overlay:
			_fail("unsaved club attack must resolve idle standing overlay")
	var spear: WeaponLimbPreset = _registry.reload_preset(ResourceData.ResourceType.SPEAR, "clansmen_1")
	if spear == null:
		_fail("spear_clansmen_1 preset missing for snapshot isolation test")
		return
	var spear_idle_overlay := spear.overlay_offset_idle_px
	if spear.attack_pose_inherits_idle():
		if spear.resolve_overlay_for_mode(WeaponLimbPresetScript.TunerAnimMode.ATTACK) != spear_idle_overlay:
			_fail("unsaved spear attack must resolve idle standing overlay")
	if spear.spear_hand_grip_needs_reseed():
		_fail("saved spear grip still looks like legacy overlay coords")
	if spear.overlay_offset_idle_px.distance_to(Vector2(63.5, -116.0)) > 1.0:
		_fail("spear idle overlay should match saved idle standing pose")
	var expected_grip := WeaponLimbPresetScript.default_spear_hand_grip_px()
	if spear.hand_grip_offset_px.distance_to(expected_grip) > 1.0:
		_fail("spear idle grip should match saved shaft grip got %s" % str(spear.hand_grip_offset_px))
	if not spear.uses_saved_spear_grip_on_art():
		_fail("spear should use saved grip on art for yellow pin")
	var none: WeaponLimbPreset = _registry.reload_preset(ResourceData.ResourceType.NONE, "clansmen_1")
	if none != null:
		if spear.shoulder_offset_px.distance_to(none.shoulder_offset_px) > 1.0:
			_fail("spear shoulder 1 should match empty-hands default")
		if spear.support_shoulder_offset_px.distance_to(none.support_shoulder_offset_px) > 1.0:
			_fail("spear shoulder 2 should match empty-hands default")
	var packed := load("res://scenes/tools/LimbTuner.tscn") as PackedScene
	if packed == null:
		_fail("LimbTuner.tscn missing for snapshot isolation test")
		return
	var app: Node = packed.instantiate()
	root.add_child(app)
	var spear_strike_overlay := spear.strike_offset_px
	var cases: Array[Dictionary] = [
		{"weapon": ResourceData.ResourceType.WOOD, "mode": WeaponLimbPresetScript.TunerAnimMode.IDLE, "expect": idle_overlay},
		{"weapon": ResourceData.ResourceType.WOOD, "mode": WeaponLimbPresetScript.TunerAnimMode.ATTACK, "expect": club_attack_overlay},
		{"weapon": ResourceData.ResourceType.SPEAR, "mode": WeaponLimbPresetScript.TunerAnimMode.IDLE, "expect": spear_idle_overlay},
		{"weapon": ResourceData.ResourceType.SPEAR, "mode": WeaponLimbPresetScript.TunerAnimMode.ATTACK, "expect": spear_strike_overlay},
	]
	for case in cases:
		app.call("_apply_pose_catalog_entry", case["weapon"], case["mode"])
		for _i in range(8):
			await process_frame
		var rig: LimbTunerRig = app.get_node_or_null("World/Stage/TunerRig") as LimbTunerRig
		if rig == null:
			_fail("snapshot isolation: rig missing for %s" % str(case))
			continue
		var live := rig.display_px_from_overlay_position()
		var expect: Vector2 = case["expect"] as Vector2
		if live.distance_to(expect) > 3.0:
			_fail(
				"snapshot isolation: %s/%s overlay expected %s got %s"
				% [str(case["weapon"]), str(case["mode"]), str(expect), str(live)]
			)
	app.queue_free()


func _test_idle_club1_minimal_scenario() -> void:
	var packed := load("res://scenes/tools/LimbTuner.tscn") as PackedScene
	if packed == null:
		_fail("LimbTuner.tscn missing for idle club1 test")
		return
	var app: Node = packed.instantiate()
	root.add_child(app)
	for _i in range(4):
		await process_frame
	if not app.has_method("_begin_idle_club1_edit_session"):
		_fail("LimbTuner missing _begin_idle_club1_edit_session")
		app.queue_free()
		return
	app.call("_begin_idle_club1_edit_session")
	for _i in range(8):
		await process_frame
	var rig: LimbTunerRig = app.get_node_or_null("World/Stage/TunerRig") as LimbTunerRig
	if rig == null:
		_fail("idle club1: TunerRig missing")
		app.queue_free()
		return
	if rig.weapon_type != ResourceData.ResourceType.WOOD:
		_fail("idle club1: expected WOOD holdable, got %s" % str(rig.weapon_type))
	if not rig.has_weapon_overlay():
		_fail("idle club1: club overlay not visible")
	elif rig.weapon_overlay.texture == null:
		_fail("idle club1: club overlay texture missing")
	var spear_handle: Node2D = app.get_node_or_null("World/HandleLayer/HandleStage/SpearHandle") as Node2D
	if spear_handle == null:
		_fail("idle club1: SpearHandle (yellow grip) missing")
	elif not spear_handle.visible:
		_fail("idle club1: yellow grip handle should be visible")
	var handle_stage: Node2D = app.get_node_or_null("World/HandleLayer/HandleStage") as Node2D
	if handle_stage == null:
		_fail("idle club1: HandleStage missing")
	elif spear_handle.get_parent() != handle_stage:
		_fail("idle club1: yellow grip should stay on HandleStage, got %s" % spear_handle.get_parent().name)
	var club_preset: WeaponLimbPreset = _registry.reload_preset(ResourceData.ResourceType.WOOD, "clansmen_1")
	if club_preset != null:
		var grip_px := club_preset.resolve_hand_grip_for_mode(WeaponLimbPresetScript.TunerAnimMode.IDLE_CLUB1)
		var expected_global := LimbPresetCoords.overlay_grip_global(rig.weapon_overlay, grip_px)
		if spear_handle.global_position.distance_to(expected_global) > 3.0:
			_fail(
				"idle club1: yellow grip should sit on club art, dist=%s expected=%s got=%s"
				% [str(spear_handle.global_position.distance_to(expected_global)), str(expected_global), str(spear_handle.global_position)]
			)
	var body_visual: Node = rig.get_node_or_null("Sprite/BodyVisual")
	if body_visual != null and body_visual.visible:
		_fail("idle club1: body should be hidden in minimal view")
	var head_pivot: CanvasItem = rig.get_node_or_null("Sprite/HeadPivot") as CanvasItem
	if head_pivot != null and head_pivot.visible:
		_fail("idle club1: head should be hidden in minimal view")
	for arm_name in ["Arm1Draw", "Arm2Draw"]:
		var arm_draw: CanvasItem = rig.get_node_or_null(arm_name) as CanvasItem
		if arm_draw != null and arm_draw.visible:
			_fail("idle club1: %s should be hidden in minimal view" % arm_name)
	var save_btn: Button = app.get_node_or_null("UI/Panel/Margin/Scroll/VBox/TunerSection/ActionsSection/ActionGrid/SaveBtn") as Button
	if save_btn == null or not save_btn.visible:
		_fail("idle club1: Save all button should stay visible")
	var select_section: Control = app.get_node_or_null("UI/Panel/Margin/Scroll/VBox/TunerSection/SelectSection") as Control
	if select_section != null and select_section.visible:
		_fail("idle club1: pose/holdable section should be hidden in minimal view")
	app.queue_free()


func _test_tuner_arm_lines_draw(rig: LimbTunerRig) -> void:
	if rig == null or rig.arm_controller == null:
		_fail("arm line draw: rig or arm_controller missing")
		return
	if not rig.arm_controller.is_processing():
		_fail("tuner arm_controller must set_process(true) so Line2D IK runs")
	var arm1: Node2D = rig.get_node_or_null("Arm1Draw") as Node2D
	if arm1 == null:
		_fail("Arm1Draw missing for arm line draw test")
		return
	var saw_points := false
	for child in arm1.get_children():
		for sub in child.get_children():
			var line := sub as Line2D
			if line == null:
				continue
			if line.points.size() >= 2 and line.visible:
				saw_points = true
				break
	if not saw_points:
		_fail("tuner arm Line2D should have IK points after startup (got empty lines)")


func _test_tuner_draw_layers(rig: LimbTunerRig) -> void:
	const ARM1_Z := 0
	const BODY_Z := 1
	const HEAD_Z := 2
	const ARM2_Z := 3
	var arm_ctrl: ProceduralArmController = rig.arm_controller
	if arm_ctrl == null:
		_fail("arm_controller missing for layer test")
		return
	if not arm_ctrl.use_tuner_arm_layers:
		_fail("use_tuner_arm_layers should be enabled on tuner arm controller")
		return
	var body_visual: Node = rig.get_node_or_null("Sprite/BodyVisual")
	if body_visual == null or not body_visual.has_method("get_body_sprite"):
		_fail("BodyVisual missing get_body_sprite")
		return
	var body_sprite: Sprite2D = body_visual.call("get_body_sprite") as Sprite2D
	var sprite_root: Node2D = rig.get_node_or_null("Sprite") as Node2D
	var head_sprite: Sprite2D = null
	if sprite_root:
		head_sprite = sprite_root.get_node_or_null("HeadPivot/HeadSprite") as Sprite2D
	if head_sprite == null:
		head_sprite = body_visual.get_node_or_null("HeadPivot/HeadSprite") as Sprite2D
	var head_pivot: Node2D = null
	if sprite_root:
		head_pivot = sprite_root.get_node_or_null("HeadPivot") as Node2D
	var arm_line_r: Line2D = null
	var arm_line_l: Line2D = null
	var arm1_draw: Node2D = rig.get_node_or_null("Arm1Draw") as Node2D
	var arm2_draw: Node2D = rig.get_node_or_null("Arm2Draw") as Node2D
	if arm1_draw:
		arm_line_r = arm1_draw.get_node_or_null("ArmDraw_R/ArmLine_R") as Line2D
	if arm2_draw:
		arm_line_l = arm2_draw.get_node_or_null("ArmDraw_L/ArmLine_L") as Line2D
	if arm_line_r == null:
		arm_line_r = arm_ctrl.get_node_or_null("ArmDraw_R/ArmLine_R") as Line2D
	if arm_line_l == null:
		arm_line_l = arm_ctrl.get_node_or_null("ArmDraw_L/ArmLine_L") as Line2D
	if arm_line_r == null or arm_line_l == null:
		_fail("layer test missing arm line nodes under Arm1Draw/Arm2Draw")
		return
	if body_sprite == null or head_sprite == null:
		_fail("layer test missing body/head sprites")
		return
	if head_pivot == null:
		_fail("HeadPivot should live under Sprite for draw order")
		return
	if arm1_draw == null or arm2_draw == null:
		_fail("Arm1Draw/Arm2Draw layer nodes missing on TunerRig")
		return
	if rig.get_node_or_null("ProceduralArmController/ArmDraw_R") != null:
		_fail("weapon arm should draw under Arm1Draw, not ProceduralArmController")
	if not (arm1_draw.z_index < body_sprite.z_index and body_sprite.z_index < head_pivot.z_index and head_pivot.z_index < arm2_draw.z_index):
		_fail("layer stack should be arm1(%d) < body(%d) < head(%d) < arm2(%d)" % [
			arm1_draw.z_index, body_sprite.z_index, head_pivot.z_index, arm2_draw.z_index
		])


func _test_idle_arm2_raise_preview() -> void:
	const TunerIdlePreviewScript = preload("res://scripts/tools/tuner_idle_preview.gd")
	var idle = TunerIdlePreviewScript.new()
	idle.set_variant(TunerIdlePreviewScript.VARIANT_ID)
	idle.set_playing(true)
	var saw_raise := false
	for _i in range(700):
		idle.tick(0.05)
		if idle.arm2_raise_blend() > 0.05:
			saw_raise = true
			break
	if not saw_raise:
		_fail("idle arm2 raise should trigger on a look-around within ~35s")
	var preset: WeaponLimbPreset = WeaponLimbPresetScript.defaults_for(ResourceData.ResourceType.NONE, 1)
	preset.support_shoulder_offset_px = Vector2(-93.40444, -178.1011)
	preset.support_hand_idle_offset_px = Vector2(-86.28906, 52.03825)
	preset.support_hand_idle_raise_offset_px = Vector2(9.1796875, -375.7352)
	preset.support_elbow_bend_sign_override = 1.0
	preset.support_elbow_bend_sign_raise_override = -1.0
	var raised: Vector2 = preset.resolve_support_hand_idle_raised_px()
	var rest: Vector2 = preset.resolve_support_hand_idle_rest_px()
	if not preset.has_idle_arm2_raise_pose():
		_fail("expected explicit idle arm2 raise pose")
	if raised.distance_squared_to(rest) < 100.0:
		_fail("raised and rest support hand should be far apart")
	var east_auto := -WeaponLimbPresetScript.SUPPORT_ELBOW_BEND_SIGN
	var west_auto := WeaponLimbPresetScript.SUPPORT_ELBOW_BEND_SIGN
	if preset.resolve_support_elbow_bend_sign_for_idle_raise(0.0, east_auto) != 1.0:
		_fail("support elbow at rest should use idle bend sign (east-facing)")
	if preset.resolve_support_elbow_bend_sign_for_idle_raise(0.25, east_auto, false) != 1.0:
		_fail("support elbow should keep rest bend during raise (pole arc drives sweep)")
	if preset.resolve_support_elbow_bend_sign_for_idle_raise(0.0, west_auto) != -1.0:
		_fail("support elbow at rest should mirror when facing west")
	if preset.resolve_support_elbow_bend_sign_for_idle_raise(0.75, east_auto, false) != 1.0:
		_fail("support elbow should not flip mid-raise (pole arc)")
	if preset.resolve_support_elbow_bend_sign_for_idle_raise(0.75, east_auto, true) != 1.0:
		_fail("support elbow should stay rest bend while lowering (pole arc)")
	if preset.resolve_support_elbow_bend_sign_for_idle_raise(1.0, east_auto, false) != 1.0:
		_fail("support elbow should keep rest bend through full raise")
	var pole_preset := WeaponLimbPreset.new()
	pole_preset.support_elbow_pole_idle_px = Vector2(-111.0, -176.0)
	pole_preset.support_elbow_pole_idle_raise_px = Vector2(-187.0, -257.0)
	if pole_preset.resolve_support_elbow_pole_for_idle_raise(0.0).distance_squared_to(Vector2(-111.0, -176.0)) > 1.0:
		_fail("idle elbow pole at rest should use idle pole")
	var mid_pole := pole_preset.resolve_support_elbow_pole_for_idle_raise(0.5)
	if mid_pole.x <= -111.0:
		_fail("mid-raise elbow pole should sweep in front (toward body center)")
	if pole_preset.resolve_support_elbow_pole_for_idle_raise(1.0).distance_squared_to(Vector2(-187.0, -257.0)) > 1.0:
		_fail("idle elbow pole at full raise should use raise pole")
	var raise_arc_preset := WeaponLimbPreset.new()
	raise_arc_preset.support_shoulder_offset_px = Vector2(-94.0, -177.0)
	raise_arc_preset.support_shoulder_idle_raise_offset_px = Vector2(-126.0, -154.0)
	raise_arc_preset.support_hand_idle_offset_px = Vector2(-11.0, 40.0)
	raise_arc_preset.support_hand_idle_raise_offset_px = Vector2(-20.0, -370.0)
	raise_arc_preset.support_elbow_pole_idle_px = Vector2(-111.0, -176.0)
	raise_arc_preset.support_elbow_pole_idle_raise_px = Vector2(-187.0, -257.0)
	var rest_elbow := ProceduralArm.estimate_elbow_position(
		Vector2(-94.0, -177.0), Vector2(-11.0, 40.0), 120.0, 120.0, Vector2(-111.0, -176.0), true
	)
	var raised_elbow := ProceduralArm.estimate_elbow_position(
		Vector2(-126.0, -154.0), Vector2(-20.0, -370.0), 120.0, 120.0, Vector2(-187.0, -257.0), true
	)
	var linear_mid_elbow := rest_elbow.lerp(raised_elbow, 0.5)
	var arc_mid_elbow := raise_arc_preset.resolve_support_elbow_display_for_idle_raise(0.5, 120.0, 120.0)
	if arc_mid_elbow.x <= linear_mid_elbow.x:
		_fail("raise elbow arc should pass in front (toward body center) of a straight rest→raised path")
	var rest_elbow_pose := raise_arc_preset.resolve_support_elbow_display_for_idle_rest(120.0, 120.0)
	var lower_end_elbow := raise_arc_preset.resolve_support_elbow_display_for_idle_lower(
		0.0, 0.0, true, 120.0, 120.0
	)
	if rest_elbow_pose.distance_squared_to(lower_end_elbow) > 4.0:
		_fail("idle rest elbow should match lower endpoint (no post-lower flip)")
	var scan_preset := WeaponLimbPreset.new()
	scan_preset.support_hand_idle_offset_px = Vector2(-11.0, 40.0)
	scan_preset.support_hand_idle_raise_offset_px = Vector2(-20.0, -370.0)
	scan_preset.support_hand_idle_raise_lookback_offset_px = Vector2(-140.0, -365.0)
	var pose_a := scan_preset.resolve_support_hand_idle_for_idle_scan(1.0, 0.0)
	var pose_b := scan_preset.resolve_support_hand_idle_for_idle_scan(1.0, 1.0)
	if pose_a.is_equal_approx(pose_b):
		_fail("scan blend should move hand from pose A to pose B")
	if pose_a.distance_squared_to(Vector2(-20.0, -370.0)) > 1.0:
		_fail("scan blend 0 should match pose A hand")
	if pose_b.distance_squared_to(Vector2(-140.0, -365.0)) > 1.0:
		_fail("scan blend 1 should match pose B hand")
	var shoulder_preset := WeaponLimbPreset.new()
	shoulder_preset.support_shoulder_offset_px = Vector2(-94.0, -177.0)
	shoulder_preset.support_shoulder_idle_raise_offset_px = Vector2(-126.0, -154.0)
	var rest_shoulder := shoulder_preset.resolve_support_shoulder_for_idle_raise(0.0)
	var raised_shoulder := shoulder_preset.resolve_support_shoulder_for_idle_raise(1.0)
	if rest_shoulder.is_equal_approx(raised_shoulder):
		_fail("idle raise should move support shoulder")
	var scan := TunerIdlePreviewScript.new()
	scan.set_variant(TunerIdlePreviewScript.VARIANT_ID)
	scan.set_playing(true)
	scan.set_sun_shield_scan_mode(true)
	if scan._head_look_flips_enabled():
		_fail("head flip should wait until arm is raised in scan mode")
	scan._arm2_raise_blend = 0.9
	if not scan._head_look_flips_enabled():
		_fail("head flip should enable once arm is up")
	scan._arm2_raise_blend = 1.0
	scan._arm2_phase = scan._Arm2RaisePhase.HOLD
	scan._on_head_look_flip()
	if scan._scan_look_count != 1:
		_fail("scan mode should count first head flip")
	scan._on_head_look_flip()
	if scan._scan_look_count != 2:
		_fail("scan mode should count return flip to pose A")
	scan._arm2_phase_time = scan.SCAN_POSE_A_HOLD_SEC + 0.05
	scan._hand_shade_slide_amount = 0.0
	scan._tick_arm2_raise(0.016)
	if scan._arm2_phase != scan._Arm2RaisePhase.LOWERING:
		_fail("scan cycle should lower arm after forward-back-forward looks")
	var lower_preset := WeaponLimbPreset.new()
	lower_preset.support_hand_idle_offset_px = Vector2(-11.0, 40.0)
	lower_preset.support_hand_idle_raise_offset_px = Vector2(-20.0, -370.0)
	lower_preset.support_shoulder_offset_px = Vector2(-94.0, -177.0)
	lower_preset.support_shoulder_idle_raise_offset_px = Vector2(-126.0, -154.0)
	lower_preset.support_elbow_pole_idle_px = Vector2(-111.0, -176.0)
	lower_preset.support_elbow_pole_idle_raise_px = Vector2(-187.0, -257.0)
	var linear_hand := lower_preset.resolve_support_hand_idle_for_idle_scan(0.5, 0.0, false)
	var lag_hand := lower_preset.resolve_support_hand_idle_for_idle_scan(0.5, 0.0, true)
	if lag_hand.y >= linear_hand.y:
		_fail("lowering should lag support hand above linear mid-lower path")
	var linear_shoulder := lower_preset.resolve_support_shoulder_for_idle_raise(0.5, false)
	var lead_shoulder := lower_preset.resolve_support_shoulder_for_idle_raise(0.5, true)
	if lead_shoulder.y >= linear_shoulder.y:
		_fail("lowering should drop support shoulder ahead of linear mid-lower path")
	var elbow_mid := lower_preset.resolve_support_elbow_display_for_idle_lower(
		0.5, 0.0, true, 140.0, 140.0
	)
	if elbow_mid.length_squared() <= 0.0001:
		_fail("lowering should force a support elbow display position")
	var arm := ProceduralArm.new()
	arm.set_pole_pick_lock(true, true)
	var shoulder := Vector2(0.0, 0.0)
	var hand := Vector2(40.0, -200.0)
	var upper := 140.0
	var lower := 140.0
	var pole_near_b := Vector2(120.0, -80.0)
	var unlocked := ProceduralArm.estimate_elbow_position(shoulder, hand, upper, lower, pole_near_b, true)
	var locked_joints: Dictionary = {}
	arm.update_arm(
		shoulder, hand, ProceduralArmConfig.new(), 1.0, Vector2.ONE,
		pole_near_b, true, upper, lower, Vector2.ZERO, false, true, false, 1.0 / 60.0
	)
	locked_joints = arm.get_last_joint_positions()
	if unlocked.distance_squared_to(locked_joints.get("elbow", Vector2.ZERO)) < 1.0:
		_fail("pole pick lock should keep elbow on rest side during idle raise")
	arm.clear_pole_pick_lock()


func _test_none_idle_sun_shield_keeps_walk_lock() -> void:
	var none: WeaponLimbPreset = _registry.reload_preset(ResourceData.ResourceType.NONE, "clansmen_1")
	if none == null:
		_fail("none preset missing")
		return
	if none.hand_grip_offset_px.distance_to(Vector2(127.90, 51.48)) > 0.5:
		_fail("none idle hand must match locked rest pose")
	if none.walk1_hand_grip_offset_px.distance_to(Vector2(225.82, 34.35)) > 0.05:
		_fail("idle work must not change locked Walk 1 Pose A")
	if none.walk1_pull_hand_grip_offset_px.distance_to(Vector2(76.93, 97.59)) > 0.05:
		_fail("idle work must not change locked Walk 1 Pose B")
	if not none.walk1_pose_a_saved or not none.walk1_pose_b_saved:
		_fail("walk1 saved flags must be set")


func _test_walk1_locked_poses() -> void:
	var none: WeaponLimbPreset = _registry.reload_preset(ResourceData.ResourceType.NONE, "clansmen_1")
	if none == null:
		_fail("none preset missing for walk1 lock test")
		return
	if not none.has_walk1_pull_pose():
		_fail("walk1 pose B (pull row) must exist")
	if none.walk1_weapon_elbow_bend_sign_override != -1.0:
		_fail("walk1 pose A elbow 1 bend should be -1")
	if none.walk1_pull_weapon_elbow_bend_sign_override != 1.0:
		_fail("walk1 pose B elbow 1 bend should be 1")


func _test_walk1_pendulum_smooth() -> void:
	const WalkArmMotion = preload("res://scripts/systems/walk_arm_motion.gd")
	var a := Vector2(225.82, 34.35)
	var b := Vector2(76.93, 97.59)
	var prev := a
	for i in range(1, 9):
		var phase := float(i) / 8.0
		var sample := WalkArmMotion.body_snapshot_between_keyframes(a, b, phase)
		if sample.distance_to(prev) > 200.0:
			_fail("walk1 pendulum jump at phase %.2f" % phase)
		prev = sample


func _test_ik_utils_elbow_pole() -> void:
	const IKUtils = preload("res://scripts/systems/ik_utils.gd")
	var shoulder := Vector2(100.0, 0.0)
	var hand := Vector2(200.0, 0.0)
	var pole := Vector2(150.0, 50.0)
	var elbow := IKUtils.calculate_elbow_from_pole(shoulder, hand, pole, 60.0, 60.0)
	if elbow.distance_to(shoulder) < 10.0:
		_fail("IKUtils elbow should not sit on shoulder")
	var sign := IKUtils.derive_bend_sign_from_pole(shoulder, hand, pole)
	if sign != 1.0:
		_fail("IKUtils bend sign from pole above line should be +1")


func _test_golden_motion_files() -> void:
	const MotionGolden = preload("res://scripts/systems/motion_golden.gd")
	var none: WeaponLimbPreset = _registry.reload_preset(ResourceData.ResourceType.NONE, "clansmen_1")
	if none == null:
		_fail("none preset missing for golden motion test")
		return
	for err_msg in MotionGolden.validate_idle_rest("res://Tests/golden/idle_motion.json", none):
		_fail(err_msg)
	for err_msg in MotionGolden.validate_walk1_pendulum(
		"res://Tests/golden/walk1_motion.json",
		Vector2(225.82, 34.35),
		Vector2(76.93, 97.59),
		Vector2(-173.19, 41.69),
		Vector2(5.51, 71.07)
	):
		_fail(err_msg)
	var spear_data := MotionGolden.load_json("res://Tests/golden/spear_idle1_motion.json")
	if spear_data.is_empty():
		_fail("spear_idle1_motion.json missing")


func _test_spear_idle_raise_no_flip() -> void:
	const SpearIdleMotion = preload("res://scripts/systems/spear_idle_motion.gd")
	const WeaponLimbPresetScript = preload("res://scripts/config/weapon_limb_preset.gd")
	var preset := WeaponLimbPresetScript.defaults_for(ResourceData.ResourceType.SPEAR, 1)
	preset.support_hand_idle_raise_offset_px = WeaponLimbPresetScript.default_none_idle_raise_hand_px()
	preset.support_elbow_bend_sign_raise_override = -1.0
	if not preset.has_idle_arm2_raise_pose():
		_fail("spear idle raise test needs arm2 raise pose seeded")
		return
	for err_msg in SpearIdleMotion.validate_raise_elbow_arc(preset):
		_fail(err_msg)


func _test_gather_pick_cycle() -> void:
	const GatherArmMotion = preload("res://scripts/systems/gather_arm_motion.gd")
	var reach := Vector2(219.64, 66.49)
	var pull := Vector2(123.01, -52.91)
	var prev_bend := GatherArmMotion.body_bend_amount(0.0)
	var prev_hand := reach
	var max_bend_step := 0.0
	var max_hand_step := 0.0
	var min_dist_to_pull := INF
	var max_dist_from_reach := 0.0
	var had_pick := false
	const STEPS := 240
	for i in range(1, STEPS + 1):
		var phase := float(i) / float(STEPS)
		var bend := GatherArmMotion.body_bend_amount(phase)
		max_bend_step = maxf(max_bend_step, absf(bend - prev_bend))
		prev_bend = bend
		var arm_work := GatherArmMotion.arm_work_phase(phase)
		if arm_work < 0.0:
			had_pick = false
			continue
		var hand := GatherArmMotion.hand_offset_between_keyframes(reach, pull, arm_work, true)
		if had_pick:
			max_hand_step = maxf(max_hand_step, hand.distance_to(prev_hand))
		prev_hand = hand
		had_pick = true
		min_dist_to_pull = minf(min_dist_to_pull, hand.distance_to(pull))
		max_dist_from_reach = maxf(max_dist_from_reach, hand.distance_to(reach))
	if max_bend_step > 0.035:
		_fail("gather pick cycle bend not smooth (max step %.4f)" % max_bend_step)
	var span := reach.distance_to(pull)
	var hand_step_limit := 4.5 * span / 36.0
	if max_hand_step > hand_step_limit:
		_fail(
			"gather pick cycle hand jump too large (%.2f px, limit %.2f)"
			% [max_hand_step, hand_step_limit]
		)
	if min_dist_to_pull > 30.0:
		_fail("gather pick cycle should approach pull pose during arm work")
	if max_dist_from_reach < 5.0:
		_fail("gather pick cycle should move away from reach pose")


func _test_procedural_arms_still_pass() -> void:
	var packed := load("res://scenes/Player.tscn") as PackedScene
	if packed == null:
		_fail("Player.tscn missing")
		return
	var player: Node = packed.instantiate()
	root.add_child(player)
	if player.get_node_or_null("ProceduralArmController") == null:
		_fail("ProceduralArmController missing on Player")
	player.queue_free()


func _fail(msg: String) -> void:
	push_error(msg)
	_failures.append(msg)


func _report() -> void:
	if _failures.is_empty():
		print("test_limb_tuner: PASS")
	else:
		for f in _failures:
			print("test_limb_tuner: FAIL — ", f)
		quit(1)
