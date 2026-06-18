extends SceneTree

## Debug: compare arm positions computed in tuner vs player.

const LimbPresetCoords = preload("res://scripts/systems/limb_preset_coords.gd")
const LimbPresetRegistryScript = preload("res://scripts/systems/limb_preset_registry.gd")
const CardVisualController = preload("res://scripts/systems/card_visual_controller.gd")


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	await process_frame

	var registry_inst := LimbPresetRegistryScript.new()
	var preset := registry_inst.reload_preset(ResourceData.ResourceType.SPEAR, "clansmen_1")

	print("=== LOADED PRESET ===")
	print("shoulder_offset_px: ", preset.shoulder_offset_px)
	print("support_shoulder_offset_px: ", preset.support_shoulder_offset_px)
	print("support_hand_idle_offset_px: ", preset.support_hand_idle_offset_px)
	print("hand_grip_offset_px: ", preset.hand_grip_offset_px)
	print("support_hand_offset_px: ", preset.support_hand_offset_px)
	print("overlay_offset_idle_px: ", preset.overlay_offset_idle_px)

	# Load tuner
	var tuner_scene := load("res://scenes/tools/LimbTuner.tscn") as PackedScene
	var app: Node = tuner_scene.instantiate()
	root.add_child(app)
	for _i in range(10):
		await process_frame

	var stage: Node2D = app.get_node("World/Stage") as Node2D
	var tuner_rig: LimbTunerRig = app.get_node("World/Stage/TunerRig") as LimbTunerRig
	var tuner_sprite: Sprite2D = tuner_rig.sprite
	var tuner_overlay: Sprite2D = tuner_rig.weapon_overlay

	# Apply idle pose
	tuner_rig.apply_preset_overlay_idle(preset)
	await process_frame

	print("\n=== TUNER (stage_scale=4) ===")
	print("sprite.scale: ", tuner_sprite.scale)
	print("sprite.position: ", tuner_sprite.position)
	print("overlay.position: ", tuner_overlay.position)
	print("overlay.global_position: ", tuner_overlay.global_position)

	# Where handles would be
	var tuner_shoulder_global := tuner_rig.shoulder_global_from_preset(preset)
	var tuner_support_shoulder_global := tuner_rig.support_shoulder_global_from_preset(preset)
	var tuner_hand_global := tuner_rig.hand_grip_global_from_preset(preset)
	var tuner_idle_hand_global := tuner_rig.support_hand_idle_global_from_preset(preset)

	print("\nHandle positions (global):")
	print("  shoulder: ", tuner_shoulder_global)
	print("  support_shoulder: ", tuner_support_shoulder_global)
	print("  hand_grip: ", tuner_hand_global)
	print("  idle_hand: ", tuner_idle_hand_global)

	# What ProceduralArmController style would compute
	var sprite_scale := tuner_sprite.scale
	var sx := absf(sprite_scale.x)

	var tuner_shoulder_local := tuner_sprite.position + Vector2(preset.shoulder_offset_px.x * sx, preset.shoulder_offset_px.y * sx)
	var tuner_sup_shoulder_local := tuner_sprite.position + Vector2(preset.support_shoulder_offset_px.x * sx, preset.support_shoulder_offset_px.y * sx)
	var tuner_idle_hand_local := tuner_sprite.position + Vector2(preset.support_hand_idle_offset_px.x * sx, preset.support_hand_idle_offset_px.y * sx)

	print("\nArm controller style (rig-local):")
	print("  shoulder: ", tuner_shoulder_local)
	print("  support_shoulder: ", tuner_sup_shoulder_local)
	print("  idle_hand: ", tuner_idle_hand_local)

	# Convert to global for tuner (includes 4x stage scale)
	print("\nArm controller style as global (tuner):")
	print("  shoulder: ", tuner_rig.to_global(tuner_shoulder_local))
	print("  support_shoulder: ", tuner_rig.to_global(tuner_sup_shoulder_local))
	print("  idle_hand: ", tuner_rig.to_global(tuner_idle_hand_local))

	# Load player
	var player_scene := load("res://scenes/Player.tscn") as PackedScene
	var player: CharacterBody2D = player_scene.instantiate() as CharacterBody2D
	root.add_child(player)
	player.global_position = Vector2(500, 500)
	await process_frame

	var player_sprite: Sprite2D = player.get_node("Sprite") as Sprite2D
	var player_overlay: Sprite2D = player_sprite.get_node("WeaponOverlay") as Sprite2D
	var card_registry := PlaceholderCardRegistry.new()
	CardVisualController.apply_card_layout(player_sprite, card_registry.get_clansmen_card(1), card_registry)

	# Set up weapon overlay
	player_overlay.texture = card_registry.get_tool_overlay(ResourceData.ResourceType.SPEAR)
	player_overlay.scale = Vector2(card_registry.get_tool_overlay_scale(ResourceData.ResourceType.SPEAR), card_registry.get_tool_overlay_scale(ResourceData.ResourceType.SPEAR))
	player_overlay.visible = true
	# Apply idle position
	var base_offset := Vector2(preset.overlay_offset_idle_px.x / player_sprite.scale.x, preset.overlay_offset_idle_px.y / player_sprite.scale.y)
	CardVisualController.sync_weapon_overlay_flip(player_sprite, player_overlay, base_offset, true)
	await process_frame

	print("\n=== PLAYER (no stage scale) ===")
	print("sprite.scale: ", player_sprite.scale)
	print("sprite.position: ", player_sprite.position)
	print("overlay.position: ", player_overlay.position)
	print("overlay.global_position: ", player_overlay.global_position)

	# What ProceduralArmController would compute
	var psx := absf(player_sprite.scale.x)
	var player_shoulder_local := player_sprite.position + Vector2(preset.shoulder_offset_px.x * psx, preset.shoulder_offset_px.y * psx)
	var player_sup_shoulder_local := player_sprite.position + Vector2(preset.support_shoulder_offset_px.x * psx, preset.support_shoulder_offset_px.y * psx)
	var player_idle_hand_local := player_sprite.position + Vector2(preset.support_hand_idle_offset_px.x * psx, preset.support_hand_idle_offset_px.y * psx)

	print("\nArm controller style (player-local):")
	print("  shoulder: ", player_shoulder_local)
	print("  support_shoulder: ", player_sup_shoulder_local)
	print("  idle_hand: ", player_idle_hand_local)

	print("\nArm controller style as global (player):")
	print("  shoulder: ", player.to_global(player_shoulder_local))
	print("  support_shoulder: ", player.to_global(player_sup_shoulder_local))
	print("  idle_hand: ", player.to_global(player_idle_hand_local))

	# Key comparison: relative to sprite center
	print("\n=== RELATIVE TO SPRITE (this should match) ===")
	print("Tuner shoulder relative to sprite: ", tuner_shoulder_local - tuner_sprite.position)
	print("Player shoulder relative to sprite: ", player_shoulder_local - player_sprite.position)
	print("Match: ", (tuner_shoulder_local - tuner_sprite.position).distance_to(player_shoulder_local - player_sprite.position) < 1.0)

	app.queue_free()
	player.queue_free()
	quit(0)
