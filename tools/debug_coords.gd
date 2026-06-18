extends SceneTree

## Debug: compare tuner vs player coordinate systems.

const LimbPresetCoords = preload("res://scripts/systems/limb_preset_coords.gd")
const CardVisualController = preload("res://scripts/systems/card_visual_controller.gd")


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	await process_frame

	# Load tuner scene
	var tuner_scene := load("res://scenes/tools/LimbTuner.tscn") as PackedScene
	var app: Node = tuner_scene.instantiate()
	root.add_child(app)
	for _i in range(10):
		await process_frame

	var stage: Node2D = app.get_node("World/Stage") as Node2D
	var tuner_rig: LimbTunerRig = app.get_node("World/Stage/TunerRig") as LimbTunerRig
	var tuner_sprite: Sprite2D = tuner_rig.sprite

	print("=== TUNER ENVIRONMENT ===")
	print("stage.scale: ", stage.scale)
	print("stage.global_scale: ", stage.global_transform.get_scale())
	print("tuner_rig.scale: ", tuner_rig.scale)
	print("tuner_rig.global_position: ", tuner_rig.global_position)
	print("tuner_sprite.scale: ", tuner_sprite.scale)
	print("tuner_sprite.position (local): ", tuner_sprite.position)
	print("tuner_sprite.global_position: ", tuner_sprite.global_position)

	# Load player scene
	var player_scene := load("res://scenes/Player.tscn") as PackedScene
	var player: Node = player_scene.instantiate()
	root.add_child(player)
	player.global_position = Vector2(500, 500)
	await process_frame

	var player_sprite: Sprite2D = player.get_node("Sprite") as Sprite2D
	var registry := PlaceholderCardRegistry.new()
	CardVisualController.apply_card_layout(player_sprite, registry.get_clansmen_card(1), registry)
	await process_frame

	print("\n=== PLAYER ENVIRONMENT ===")
	print("player.scale: ", player.scale)
	print("player.global_position: ", player.global_position)
	print("player_sprite.scale: ", player_sprite.scale)
	print("player_sprite.position (local): ", player_sprite.position)
	print("player_sprite.global_position: ", player_sprite.global_position)

	# Test a known offset
	var test_display_px := Vector2(102.0, -70.125)  # shoulder from preset

	print("\n=== COORDINATE CONVERSION TEST ===")
	print("test_display_px: ", test_display_px)

	# Tuner conversion
	var tuner_rig_local := LimbPresetCoords.body_display_to_rig_local(tuner_sprite, test_display_px)
	var tuner_global := LimbPresetCoords.body_global_from_display(tuner_sprite, test_display_px)
	print("\nTuner:")
	print("  body_display_to_rig_local: ", tuner_rig_local)
	print("  body_global_from_display: ", tuner_global)

	# Player/game conversion (what ProceduralArmController does)
	var flip_h := player_sprite.flip_h
	var offset := test_display_px if not flip_h else Vector2(-test_display_px.x, test_display_px.y)
	var player_local := player_sprite.position + Vector2(offset.x * player_sprite.scale.x, offset.y * player_sprite.scale.y)
	print("\nPlayer (game arm controller style):")
	print("  sprite.position + offset*scale: ", player_local)
	print("  as global: ", player.to_global(player_local))

	# Check if tuner roundtrip works
	print("\n=== ROUNDTRIP TEST ===")
	var roundtrip := LimbPresetCoords.body_display_from_global(tuner_sprite, tuner_global)
	print("tuner roundtrip: ", test_display_px, " -> global -> ", roundtrip)
	print("match: ", roundtrip.distance_to(test_display_px) < 1.0)

	# The issue: tuner saves display_px but stage is scaled 4x
	# When you drag handle at global G, to_local(G) gives you rig-local position
	# But that rig-local is relative to a 4x scaled stage
	print("\n=== STAGE SCALE IMPACT ===")
	var test_global := tuner_rig.global_position + Vector2(100, 0)  # 100px right of rig center in world
	var in_rig_local := tuner_rig.to_local(test_global)
	print("test_global (100px right of rig): ", test_global)
	print("rig.to_local(test_global): ", in_rig_local)
	print("Expected if no stage scale: 100")
	print("Actual (with 4x stage): ", in_rig_local.x, " (should be 25 if stage scales affects to_local)")

	app.queue_free()
	player.queue_free()

	print("\n=== DONE ===")
	quit(0)
