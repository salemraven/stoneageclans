extends SceneTree

## Headless: saved preset loads into player arm config with expected body + grip values.

const LimbPresetRegistryScript = preload("res://scripts/systems/limb_preset_registry.gd")
const LimbPresetCoords = preload("res://scripts/systems/limb_preset_coords.gd")
const CardVisualController = preload("res://scripts/systems/card_visual_controller.gd")

const EXPECTED_SHOULDER := Vector2(102.0, -70.125)
const EXPECTED_IDLE_HAND := Vector2(-140.25, 172.125)
const EXPECTED_HAND_GRIP := Vector2(-12.75, 95.62498)
const EXPECTED_READY := Vector2(37.5, 5.0)


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	await process_frame
	var failures: Array[String] = []
	var registry := LimbPresetRegistryScript.new()
	var preset: WeaponLimbPreset = registry.reload_preset(ResourceData.ResourceType.SPEAR, "clansmen_1")

	if preset.shoulder_offset_px != EXPECTED_SHOULDER:
		failures.append("shoulder got %s" % str(preset.shoulder_offset_px))
	if preset.support_hand_idle_offset_px != EXPECTED_IDLE_HAND:
		failures.append("idle hand got %s" % str(preset.support_hand_idle_offset_px))
	if preset.hand_grip_offset_px != EXPECTED_HAND_GRIP:
		failures.append("hand grip got %s" % str(preset.hand_grip_offset_px))
	if preset.ready_offset_px != EXPECTED_READY:
		failures.append("ready offset got %s" % str(preset.ready_offset_px))
	if preset.tuner_stage_scale != 1.0:
		failures.append("tuner_stage_scale got %s" % str(preset.tuner_stage_scale))

	var player_scene := load("res://scenes/Player.tscn") as PackedScene
	var player: Node = player_scene.instantiate()
	root.add_child(player)
	await process_frame

	var cfg := ProceduralArmConfig.new()
	registry.apply_to_arm_config(cfg, preset)
	if cfg.weapon_shoulder_offset_px != EXPECTED_SHOULDER:
		failures.append("arm config shoulder got %s" % str(cfg.weapon_shoulder_offset_px))
	if cfg.support_hand_idle_offset_px != EXPECTED_IDLE_HAND:
		failures.append("arm config idle hand got %s" % str(cfg.support_hand_idle_offset_px))
	if cfg.hand_grip_offset_px != EXPECTED_HAND_GRIP:
		failures.append("arm config hand grip got %s" % str(cfg.hand_grip_offset_px))

	var sprite: Sprite2D = player.get_node("Sprite") as Sprite2D
	var overlay: Sprite2D = sprite.get_node("WeaponOverlay") as Sprite2D
	overlay.visible = true
	overlay.texture = PlaceholderCardRegistry.new().get_tool_overlay(ResourceData.ResourceType.SPEAR)
	overlay.scale = Vector2(1.0, 1.0)
	CardVisualController.apply_card_layout(sprite, PlaceholderCardRegistry.new().get_clansmen_card(1), PlaceholderCardRegistry.new())
	var base := Vector2(preset.overlay_offset_idle_px.x / sprite.scale.x, preset.overlay_offset_idle_px.y / sprite.scale.y)
	CardVisualController.sync_weapon_overlay_flip(sprite, overlay, base, true)

	var shoulder_local := sprite.position + Vector2(
		EXPECTED_SHOULDER.x * sprite.scale.x,
		EXPECTED_SHOULDER.y * sprite.scale.y
	)
	var tuner_style := LimbPresetCoords.body_display_to_rig_local(sprite, EXPECTED_SHOULDER)
	if shoulder_local.distance_to(tuner_style) > 1.0:
		failures.append("shoulder local mismatch player=%s coords=%s" % [shoulder_local, tuner_style])

	player.queue_free()

	if failures.is_empty():
		print("test_spear_preset_load: PASS")
		quit(0)
	else:
		for f in failures:
			print("test_spear_preset_load: FAIL — ", f)
		quit(1)
