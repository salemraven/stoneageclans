extends SceneTree

## Debug: compare grip positions between tuner-like and game-like setups.

const LimbPresetCoords = preload("res://scripts/systems/limb_preset_coords.gd")
const CardVisualController = preload("res://scripts/systems/card_visual_controller.gd")
const LimbPresetRegistryScript = preload("res://scripts/systems/limb_preset_registry.gd")


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	await process_frame

	var preset_path := "res://assets/limb_presets/spear_clansmen_1.tres"
	var preset: WeaponLimbPreset = load(preset_path) as WeaponLimbPreset
	var registry := PlaceholderCardRegistry.new()

	print("=== PRESET GRIP VALUES ===")
	print("hand_grip_offset_px: ", preset.hand_grip_offset_px)
	print("support_hand_offset_px: ", preset.support_hand_offset_px)
	print("support_hand_idle_offset_px: ", preset.support_hand_idle_offset_px)

	# --- TUNER-LIKE SETUP (with 4x stage scale) ---
	print("\n=== TUNER ENVIRONMENT (4x stage scale) ===")

	var tuner_root := Node2D.new()
	root.add_child(tuner_root)
	tuner_root.scale = Vector2(4.0, 4.0)  # Simulates Stage.scale
	tuner_root.position = Vector2(960, 540)  # Stage center

	var tuner_rig := Node2D.new()
	tuner_root.add_child(tuner_rig)

	var tuner_sprite := Sprite2D.new()
	tuner_sprite.texture = registry.get_clansmen_card(1)
	tuner_sprite.scale = Vector2(0.156863, 0.156863)
	tuner_sprite.position = Vector2(0, -64)
	tuner_rig.add_child(tuner_sprite)

	var tuner_overlay := Sprite2D.new()
	tuner_overlay.texture = registry.get_tool_overlay(ResourceData.ResourceType.SPEAR)
	tuner_overlay.scale = Vector2(1.0, 1.0)
	tuner_sprite.add_child(tuner_overlay)
	# Position overlay using idle offset
	var idle_local := Vector2(preset.overlay_offset_idle_px.x / tuner_sprite.scale.x, preset.overlay_offset_idle_px.y / tuner_sprite.scale.y)
	tuner_overlay.position = idle_local
	await process_frame

	print("tuner_sprite.global_position: ", tuner_sprite.global_position)
	print("tuner_overlay.position (local): ", tuner_overlay.position)
	print("tuner_overlay.global_position: ", tuner_overlay.global_position)
	print("tuner_overlay.global_transform.get_scale(): ", tuner_overlay.global_transform.get_scale())

	# Compute grip global position from preset using LimbPresetCoords
	var tuner_grip_global := LimbPresetCoords.overlay_grip_global(tuner_overlay, preset.hand_grip_offset_px)
	print("LimbPresetCoords.overlay_grip_global(hand_grip): ", tuner_grip_global)

	var tuner_support_grip_global := LimbPresetCoords.overlay_grip_global(tuner_overlay, preset.support_hand_offset_px)
	print("LimbPresetCoords.overlay_grip_global(support_hand): ", tuner_support_grip_global)

	# Verify roundtrip: global -> grip_px -> global
	var roundtrip_grip_px := LimbPresetCoords.overlay_grip_px_from_global(tuner_overlay, tuner_grip_global)
	print("Roundtrip hand_grip_offset_px: ", roundtrip_grip_px, " (original: ", preset.hand_grip_offset_px, ")")

	# --- GAME-LIKE SETUP (no stage scale) ---
	print("\n=== GAME ENVIRONMENT (no stage scale) ===")

	var game_player := Node2D.new()
	root.add_child(game_player)
	game_player.position = Vector2(500, 500)

	var game_sprite := Sprite2D.new()
	game_sprite.texture = registry.get_clansmen_card(1)
	game_sprite.scale = Vector2(0.156863, 0.156863)
	game_sprite.position = Vector2(0, -64)
	game_player.add_child(game_sprite)

	var game_overlay := Sprite2D.new()
	game_overlay.texture = registry.get_tool_overlay(ResourceData.ResourceType.SPEAR)
	game_overlay.scale = Vector2(1.0, 1.0)
	game_sprite.add_child(game_overlay)
	# Position overlay using idle offset (same as tuner)
	var game_idle_local := Vector2(preset.overlay_offset_idle_px.x / game_sprite.scale.x, preset.overlay_offset_idle_px.y / game_sprite.scale.y)
	game_overlay.position = game_idle_local
	await process_frame

	print("game_sprite.global_position: ", game_sprite.global_position)
	print("game_overlay.position (local): ", game_overlay.position)
	print("game_overlay.global_position: ", game_overlay.global_position)
	print("game_overlay.global_transform.get_scale(): ", game_overlay.global_transform.get_scale())

	# Compute grip using game's arm controller style
	var grip_px := preset.hand_grip_offset_px
	var grip_overlay_local := Vector2(grip_px.x * game_overlay.scale.x, grip_px.y * game_overlay.scale.y)
	var grip_global := game_overlay.to_global(grip_overlay_local)
	var grip_sprite_local := game_sprite.to_local(grip_global)
	print("Game arm controller style:")
	print("  grip_overlay_local: ", grip_overlay_local)
	print("  grip_global: ", grip_global)
	print("  grip_sprite_local: ", grip_sprite_local)

	# Same for support hand
	var support_grip_px := preset.support_hand_offset_px
	var support_grip_overlay_local := Vector2(support_grip_px.x * game_overlay.scale.x, support_grip_px.y * game_overlay.scale.y)
	var support_grip_global := game_overlay.to_global(support_grip_overlay_local)
	var support_grip_sprite_local := game_sprite.to_local(support_grip_global)
	print("Support hand grip:")
	print("  support_grip_overlay_local: ", support_grip_overlay_local)
	print("  support_grip_global: ", support_grip_global)
	print("  support_grip_sprite_local: ", support_grip_sprite_local)

	# --- KEY COMPARISON ---
	print("\n=== KEY COMPARISON ===")
	print("Overlay LOCAL positions match: ", tuner_overlay.position.distance_to(game_overlay.position) < 0.01)

	# The grip positions RELATIVE TO THE SPRITE should match
	var tuner_grip_sprite_local := tuner_sprite.to_local(tuner_grip_global)
	print("Tuner grip (sprite-local): ", tuner_grip_sprite_local)
	print("Game grip (sprite-local): ", grip_sprite_local)
	print("Grip positions (sprite-local) match: ", tuner_grip_sprite_local.distance_to(grip_sprite_local) < 1.0)

	tuner_root.queue_free()
	game_player.queue_free()
	print("\n=== DONE ===")
	quit(0)
