extends SceneTree

## Debug: see if game overlay positioning matches preset.

const CardVisualController = preload("res://scripts/systems/card_visual_controller.gd")
const LimbPresetRegistryScript = preload("res://scripts/systems/limb_preset_registry.gd")


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	await process_frame

	# Load preset directly
	var preset_path := "res://assets/limb_presets/spear_clansmen_1.tres"
	var preset: WeaponLimbPreset = load(preset_path) as WeaponLimbPreset

	print("=== PRESET VALUES ===")
	print("overlay_offset_idle_px: ", preset.overlay_offset_idle_px)
	print("shoulder_offset_px: ", preset.shoulder_offset_px)
	print("support_hand_idle_offset_px: ", preset.support_hand_idle_offset_px)
	print("hand_grip_offset_px: ", preset.hand_grip_offset_px)

	# Load player scene
	var player_scene := load("res://scenes/Player.tscn") as PackedScene
	var player: CharacterBody2D = player_scene.instantiate() as CharacterBody2D
	root.add_child(player)
	player.global_position = Vector2(500, 500)
	await process_frame

	var sprite: Sprite2D = player.get_node("Sprite") as Sprite2D
	var overlay: Sprite2D = sprite.get_node("WeaponOverlay") as Sprite2D
	var card_registry := PlaceholderCardRegistry.new()

	print("\n=== SPRITE SETUP ===")
	CardVisualController.apply_card_layout(sprite, card_registry.get_clansmen_card(1), card_registry)
	await process_frame
	print("sprite.scale: ", sprite.scale)

	# Manually set up overlay like game does
	var tex: Texture2D = card_registry.get_tool_overlay(ResourceData.ResourceType.SPEAR)
	overlay.texture = tex
	var overlay_scale: float = card_registry.get_tool_overlay_scale(ResourceData.ResourceType.SPEAR)
	overlay.scale = Vector2(overlay_scale, overlay_scale)
	overlay.visible = true

	print("\n=== OVERLAY BEFORE POSITIONING ===")
	print("overlay.position: ", overlay.position)
	print("overlay.scale: ", overlay.scale)

	# Get overlay offset from preset (like _effective_overlay_offset_px does)
	var limb_registry := LimbPresetRegistryScript.new()
	var offset_px := limb_registry.get_overlay_offset_idle_px(ResourceData.ResourceType.SPEAR)
	print("\nLimbPresetRegistry.get_overlay_offset_idle_px: ", offset_px)

	# Convert to local offset (like _overlay_local_offset does)
	var sx: float = absf(sprite.scale.x)
	var base_offset := Vector2(offset_px.x / sx, offset_px.y / sx)
	print("base_offset (offset_px / sprite.scale): ", base_offset)

	# Apply via sync_weapon_overlay_flip
	CardVisualController.sync_weapon_overlay_flip(sprite, overlay, base_offset, true)
	await process_frame

	print("\n=== OVERLAY AFTER POSITIONING ===")
	print("overlay.position: ", overlay.position)
	print("overlay.global_position: ", overlay.global_position)

	# Now compare: what does the arm controller expect?
	print("\n=== EXPECTED ARM POSITIONS ===")
	# Shoulder = sprite.position + shoulder_offset_px * sprite.scale
	var shoulder_local := sprite.position + Vector2(preset.shoulder_offset_px.x * sx, preset.shoulder_offset_px.y * sx)
	var shoulder_global := player.to_global(shoulder_local)
	print("Weapon shoulder (player-local): ", shoulder_local)
	print("Weapon shoulder (global): ", shoulder_global)

	# Support hand idle = sprite.position + support_hand_idle_offset_px * sprite.scale
	var idle_hand_local := sprite.position + Vector2(preset.support_hand_idle_offset_px.x * sx, preset.support_hand_idle_offset_px.y * sx)
	var idle_hand_global := player.to_global(idle_hand_local)
	print("Support hand idle (player-local): ", idle_hand_local)
	print("Support hand idle (global): ", idle_hand_global)

	# Hand grip = overlay.to_global(grip_px * overlay.scale) converted to sprite local
	var grip_overlay_local := Vector2(preset.hand_grip_offset_px.x * overlay.scale.x, preset.hand_grip_offset_px.y * overlay.scale.y)
	var grip_global := overlay.to_global(grip_overlay_local)
	var grip_sprite_local := sprite.to_local(grip_global)
	print("Hand grip (global): ", grip_global)
	print("Hand grip (sprite-local): ", grip_sprite_local)

	# Compare: shoulder vs sprite center
	print("\n=== RELATIVE CHECKS ===")
	print("Shoulder offset from sprite: ", shoulder_local - sprite.position)
	print("Idle hand offset from sprite: ", idle_hand_local - sprite.position)
	print("Overlay position: ", overlay.position)

	player.queue_free()
	print("\n=== DONE ===")
	quit(0)
