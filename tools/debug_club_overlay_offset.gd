extends SceneTree
## Headless: print club WeaponOverlay local Y from registry offset (layered pawn path).

const PlayerScene := preload("res://scenes/Player.tscn")


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var root_node: Node = root
	var player: Node = PlayerScene.instantiate()
	root_node.add_child(player)
	await process_frame
	if PlaceholderCardService:
		PlaceholderCardService.apply_to_player(player)
	if player.has_method("set_equipment"):
		player.set_equipment(ResourceData.ResourceType.WOOD)
	await process_frame
	if PlaceholderCardService:
		PlaceholderCardService.sync_weapon_overlay(player, ResourceData.ResourceType.WOOD, true)
	await process_frame
	var sprite: Sprite2D = player.get_node_or_null("Sprite") as Sprite2D
	var overlay: Sprite2D = sprite.get_node_or_null("WeaponOverlay") as Sprite2D
	if overlay == null:
		push_error("DEBUG_CLUB: WeaponOverlay missing")
		quit(1)
		return
	var registry_y: float = PlaceholderCardService.registry.get_tool_overlay_offset_px(
		ResourceData.ResourceType.WOOD
	).y
	print(
		"DEBUG_CLUB registry_y=%s overlay.position=%s visible=%s scale=%s offset=%s"
		% [registry_y, overlay.position, overlay.visible, overlay.scale, overlay.offset]
	)
	PlaceholderCardService.sync_weapon_overlay_flip(player)
	print("DEBUG_CLUB after sync_flip overlay.position=%s" % overlay.position)
	WeaponOverlayCombat.apply_idle_pose(
		sprite, overlay, PlaceholderCardService.registry, ResourceData.ResourceType.WOOD
	)
	print("DEBUG_CLUB after apply_idle_pose overlay.position=%s" % overlay.position)
	player.queue_free()
	quit(0)
