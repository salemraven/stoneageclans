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
	_test_save_roundtrip()
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
	if app.get_node_or_null("World/Stage") == null:
		_fail("Stage missing")
	var stage: Node2D = app.get_node("World/Stage") as Node2D
	var shoulder: Node2D = stage.get_node_or_null("ShoulderHandle") as Node2D
	if shoulder == null:
		_fail("ShoulderHandle missing")
	else:
		var center := stage.global_position
		if shoulder.global_position.distance_to(center) < 8.0:
			_fail("shoulder handle still at stage center after startup")
	var weapon_elbow: Node2D = stage.get_node_or_null("WeaponElbowHandle") as Node2D
	if weapon_elbow == null:
		_fail("WeaponElbowHandle missing")
	var support_elbow: Node2D = stage.get_node_or_null("SupportElbowHandle") as Node2D
	if support_elbow == null:
		_fail("SupportElbowHandle missing")
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
