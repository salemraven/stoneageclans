extends SceneTree

## Headless: limb preset registry + LimbTuner scene wiring.

const WeaponLimbPresetScript = preload("res://scripts/config/weapon_limb_preset.gd")
const LimbPresetRegistryScript = preload("res://scripts/systems/limb_preset_registry.gd")

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
	_test_arm_thickness_preset()
	_test_walk_arm_swing()
	_test_limb_tuner_scene()
	_test_idle_club_drag_handles()
	_test_club_overlay_grip_fallback()
	_test_club_walk_carry_pose()
	_test_pose_snapshot_isolation()
	_test_idle_club1_minimal_scenario()
	_test_idle_arm2_raise_preview()
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
	var anim_option: OptionButton = app.get_node_or_null(
		"UI/Panel/Margin/VBox/SelectSection/PoseRow/AnimModeOption"
	) as OptionButton
	if anim_option == null:
		_fail("pose dropdown missing")
	elif anim_option.item_count < 20:
		_fail("pose catalog too small: %d items" % anim_option.item_count)
	var thickness_spin: SpinBox = app.get_node_or_null(
		"UI/Panel/Margin/VBox/ArmsSection/ArmThicknessRow/ArmThicknessSpin"
	) as SpinBox
	if thickness_spin == null:
		_fail("ArmThicknessSpin missing")
	elif thickness_spin.min_value > 2.0 or thickness_spin.max_value < 48.0:
		_fail("ArmThicknessSpin range unexpected")
	if rig.weapon_overlay != null and rig.weapon_overlay.visible:
		_fail("default weapon None should hide overlay")
	var handle_stage: Node2D = app.get_node_or_null("World/HandleLayer/HandleStage") as Node2D
	if handle_stage == null:
		_fail("HandleStage missing on HandleLayer")
	var shoulder: Node2D = handle_stage.get_node_or_null("ShoulderHandle") as Node2D
	if shoulder == null:
		_fail("ShoulderHandle missing on HandleStage overlay")
	elif shoulder.get_parent() != handle_stage:
		_fail("shoulder handle should stay on HandleStage overlay, got %s" % shoulder.get_parent().name)
	_test_tuner_draw_layers(rig)
	var stage: Node2D = app.get_node("World/Stage") as Node2D
	var scale_before := stage.scale.x
	for i in anim_option.item_count:
		var label := anim_option.get_item_text(i)
		if label.begins_with("Club · Idle standing"):
			anim_option.select(i)
			anim_option.item_selected.emit(i)
			break
	for _i in range(6):
		await process_frame
	if rig.weapon_overlay == null or not rig.weapon_overlay.visible:
		_fail("club WeaponOverlay should be visible after selecting Club · Idle")
	elif rig.weapon_overlay.texture == null:
		_fail("club WeaponOverlay texture missing after selecting Club · Idle")
	if absf(stage.scale.x - scale_before) > 0.01:
		_fail("stage scale changed when switching pose catalog entry")
	if stage.scale.x < 3.5:
		_fail("expected stage_scale >= 4.0 for tuner zoom, got %s" % str(stage.scale.x))
	var club_preset: WeaponLimbPreset = _registry.reload_preset(ResourceData.ResourceType.WOOD, "clansmen_1")
	if club_preset != null:
		var overlay_px := club_preset.overlay_offset_idle_px
		var rig_overlay := rig.display_px_from_overlay_position()
		if rig_overlay.distance_to(overlay_px) > 3.0:
			_fail(
				"club idle standing overlay mismatch: saved=%s live=%s"
				% [str(overlay_px), str(rig_overlay)]
			)
	var none_preset: WeaponLimbPreset = _registry.reload_preset(ResourceData.ResourceType.NONE, "clansmen_1")
	if none_preset == null:
		_fail("none_clansmen_1 preset missing")
	elif not none_preset.has_idle_arm2_raise_pose():
		_fail("none preset should define support_hand_idle_raise_offset_px")
	elif none_preset.support_hand_idle_offset_px.distance_to(Vector2(-86.28906, 52.03825)) > 2.0:
		_fail("none preset rest hand drifted from saved idle pose")
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
	var weapon_option: OptionButton = app.get_node_or_null(
		"UI/Panel/Margin/VBox/SelectSection/PoseRow/AnimModeOption"
	) as OptionButton
	if weapon_option:
		for i in weapon_option.item_count:
			if weapon_option.get_item_text(i).begins_with("Club ·"):
				weapon_option.select(i)
				weapon_option.item_selected.emit(i)
				break
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
	var pose_option: OptionButton = app.get_node_or_null(
		"UI/Panel/Margin/VBox/SelectSection/PoseRow/AnimModeOption"
	) as OptionButton
	if pose_option == null:
		_fail("club walk carry: pose dropdown missing")
		app.queue_free()
		return
	for i in pose_option.item_count:
		if pose_option.get_item_text(i).begins_with("Club · Idle standing"):
			pose_option.select(i)
			pose_option.item_selected.emit(i)
			break
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
	var pose_option: OptionButton = app.get_node_or_null(
		"UI/Panel/Margin/VBox/SelectSection/PoseRow/AnimModeOption"
	) as OptionButton
	if pose_option == null:
		_fail("snapshot isolation: pose dropdown missing")
		app.queue_free()
		return
	var spear_strike_overlay := spear.strike_offset_px
	var cases: Array[Dictionary] = [
		{"prefix": "Club · Idle standing", "expect": idle_overlay},
		{"prefix": "Club · Attack windup", "expect": idle_overlay},
		{"prefix": "Spear · Idle standing", "expect": spear_idle_overlay},
		{"prefix": "Spear · Attack windup", "expect": spear_strike_overlay},
	]
	for case in cases:
		for i in pose_option.item_count:
			if pose_option.get_item_text(i).begins_with(case["prefix"] as String):
				pose_option.select(i)
				pose_option.item_selected.emit(i)
				break
		for _i in range(8):
			await process_frame
		var rig: LimbTunerRig = app.get_node_or_null("World/Stage/TunerRig") as LimbTunerRig
		if rig == null:
			_fail("snapshot isolation: rig missing for %s" % case["prefix"])
			continue
		var live := rig.display_px_from_overlay_position()
		var expect: Vector2 = case["expect"] as Vector2
		if live.distance_to(expect) > 3.0:
			_fail(
				"snapshot isolation: %s overlay expected %s got %s"
				% [case["prefix"], str(expect), str(live)]
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
	var save_btn: Button = app.get_node_or_null("UI/Panel/Margin/VBox/ActionsSection/ActionGrid/SaveAllBtn") as Button
	if save_btn == null or not save_btn.visible:
		_fail("idle club1: Save all button should stay visible")
	var select_section: Control = app.get_node_or_null("UI/Panel/Margin/VBox/SelectSection") as Control
	if select_section != null and select_section.visible:
		_fail("idle club1: pose/holdable section should be hidden in minimal view")
	app.queue_free()


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
	if preset.resolve_support_elbow_bend_sign_for_idle_raise(0.0, 1.0) != 1.0:
		_fail("support elbow at rest should use idle bend sign")
	if preset.resolve_support_elbow_bend_sign_for_idle_raise(0.25, 1.0) != 1.0:
		_fail("support elbow should keep rest bend before halfway raise")
	if preset.resolve_support_elbow_bend_sign_for_idle_raise(0.75, 1.0) != -1.0:
		_fail("support elbow should flip bend after halfway raise")
	if preset.resolve_support_elbow_bend_sign_for_idle_raise(1.0, 1.0) != -1.0:
		_fail("support elbow at full raise should use raised bend sign")


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
