extends SceneTree

## Headless: limb preset registry + LimbTuner scene wiring.

const WeaponLimbPresetScript = preload("res://scripts/config/weapon_limb_preset.gd")
const LimbPresetRegistryScript = preload("res://scripts/systems/limb_preset_registry.gd")
const CardVisualController = preload("res://scripts/systems/card_visual_controller.gd")

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
	_test_walk_arm_sway()
	_test_save_roundtrip()
	_test_club_preset_sane()
	_test_limb_tuner_scene()
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


func _test_walk_arm_sway() -> void:
	var shoulder := Vector2(0.0, 0.0)
	var hand := Vector2(48.0, 56.0)
	var support_shoulder := Vector2(-24.0, 0.0)
	var support_hand := Vector2(-36.0, 52.0)
	var t := PI * 0.5
	var dom := CardVisualController.swing_hand_delta_display_px(shoulder, hand, t, true, false, true)
	var sup := CardVisualController.swing_hand_delta_display_px(support_shoulder, support_hand, t, true, false, false)
	if dom.length_squared() < 0.01:
		_fail("expected dominant shoulder swing delta at sin peak got %s" % str(dom))
	if sup.length_squared() < 0.01:
		_fail("expected support shoulder swing delta at sin peak got %s" % str(sup))
	if dom.x * sup.x > 0.0:
		_fail("arms should alternate forward/back on X, not clap: dom %s sup %s" % [str(dom), str(sup)])
	var idle := CardVisualController.swing_hand_delta_display_px(shoulder, hand, t, false, false, true)
	if idle != Vector2.ZERO:
		_fail("sway should be zero when not moving got %s" % str(idle))


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


func _test_club_preset_sane() -> void:
	var preset: WeaponLimbPreset = _registry.reload_preset(ResourceData.ResourceType.WOOD, "clansmen_1")
	if preset == null:
		_fail("club preset missing")
		return
	if preset.upper_arm_length > WeaponLimbPreset.TUNER_MAX_UPPER_ARM_PX + 0.01:
		_fail("club upper arm exceeds tuner cap")
	if preset.lower_arm_length > WeaponLimbPreset.TUNER_MAX_LOWER_ARM_PX + 0.01:
		_fail("club lower arm exceeds tuner cap")
	if preset.overlay_offset_idle_px.length_squared() < 1.0:
		_fail("club overlay offset looks unset")


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
		"UI/Panel/VBox/Toolbar/AnimModeOption"
	) as OptionButton
	var weapon_option: OptionButton = app.get_node_or_null(
		"UI/Panel/VBox/Toolbar/WeaponOption"
	) as OptionButton
	if anim_option == null or weapon_option == null:
		_fail("animation/weapon dropdowns missing")
	elif anim_option.item_count < 3 or weapon_option.item_count < 2:
		_fail("dropdowns need idle/walk/attack and none/club items")
	var save_btn: Button = app.get_node_or_null("UI/Panel/VBox/PrimaryButtons/SaveBtn") as Button
	var reach_banner: Label = app.get_node_or_null("UI/Panel/VBox/ReachBanner") as Label
	var values_scroll: ScrollContainer = app.get_node_or_null("UI/Panel/VBox/ValuesScroll") as ScrollContainer
	var legend: Label = app.get_node_or_null("UI/CanvasLegend") as Label
	if save_btn == null:
		_fail("primary SaveBtn missing")
	if reach_banner == null:
		_fail("ReachBanner missing")
	if values_scroll == null:
		_fail("ValuesScroll missing")
	if legend == null:
		_fail("CanvasLegend missing")
	if rig.weapon_overlay == null or not rig.weapon_overlay.visible:
		_fail("club WeaponOverlay should be visible on startup (default weapon)")
	elif rig.weapon_overlay.texture == null:
		_fail("club WeaponOverlay texture missing on startup")
	var handle_stage: Node2D = app.get_node_or_null("World/HandleLayer/HandleStage") as Node2D
	if handle_stage == null:
		_fail("HandleStage missing")
	var shoulder: Node2D = handle_stage.get_node_or_null("ShoulderHandle") as Node2D
	if shoulder == null:
		_fail("ShoulderHandle missing on HandleStage")
	elif shoulder.global_position.distance_to(handle_stage.global_position) < 8.0:
		_fail("shoulder handle still at stage center after startup (expected club preset)")
	if weapon_option and weapon_option.selected != 1:
		_fail("weapon dropdown should default to Club (index 1), got %d" % weapon_option.selected)
	var stage: Node2D = app.get_node("World/Stage") as Node2D
	if stage.scale.x < 3.5:
		_fail("expected stage_scale >= 4.0 for tuner zoom, got %s" % str(stage.scale.x))
	app.queue_free()


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
