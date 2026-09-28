extends SceneTree
## SKIP_SINGLE_INSTANCE=1 godot --headless --path . --script res://tools/measure_throw_stone_pose.gd

const PLAYER_SCENE_PATH := "res://scenes/Player.tscn"
const WeaponOverlayCombat = preload("res://scripts/systems/weapon_overlay_combat.gd")


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var svc: Node = root.get_node_or_null("PlaceholderCardService")
	if svc == null:
		push_error("MEASURE: no PlaceholderCardService")
		quit(1)
		return
	var scene: PackedScene = load(PLAYER_SCENE_PATH) as PackedScene
	var player: Node = scene.instantiate()
	player.add_to_group("player")
	root.add_child(player)
	svc.apply_to_player(player)
	await process_frame
	await process_frame
	var sprite: Sprite2D = player.get_node_or_null("Sprite") as Sprite2D
	var overlay: Sprite2D = sprite.get_node_or_null("WeaponOverlay") as Sprite2D
	var head_pivot: Node2D = sprite.get_node_or_null("HeadPivot") as Node2D
	var head: Sprite2D = sprite.get_node_or_null("HeadPivot/HeadSprite") as Sprite2D
	var hair: Sprite2D = sprite.get_node_or_null("HeadPivot/HairFront") as Sprite2D
	var body_vis: Node = sprite.get_node_or_null("BodyVisual")
	if body_vis and body_vis.has_method("sync_head_draw_transform"):
		body_vis.call("sync_head_draw_transform")
	svc.sync_weapon_overlay(player, ResourceData.ResourceType.STONE, true)
	WeaponOverlayCombat.set_throw_stance(player, false)
	WeaponOverlayCombat.apply_stone_melee_pose(sprite, overlay, 20.0)
	await process_frame
	var world_sz: Vector2 = Vector2.ZERO
	if overlay.texture:
		world_sz = Vector2(overlay.texture.get_width(), overlay.texture.get_height()) * overlay.scale * sprite.scale
	print("MEASURE melee overlay.world_size=", world_sz, " global=", overlay.global_position)
	var body: Sprite2D = sprite.get_node_or_null("BodyVisual/BodySprite") as Sprite2D
	if body:
		print("MEASURE melee minus body=", overlay.global_position - body.global_position)
	WeaponOverlayCombat.set_throw_stance(player, true)
	WeaponOverlayCombat.apply_throw_ready_pose(sprite, overlay, Vector2(1, 0))
	await process_frame
	if overlay.texture:
		world_sz = Vector2(overlay.texture.get_width(), overlay.texture.get_height()) * overlay.scale * sprite.scale
	print("MEASURE throw overlay.world_size=", world_sz, " global=", overlay.global_position)
	if head and head.texture:
		var hr2 := head.get_rect()
		var head_top2 := head.to_global(Vector2(hr2.position.x + hr2.size.x * 0.5, hr2.position.y))
		print("MEASURE throw minus head_top=", overlay.global_position - head_top2)
		print("MEASURE head_w=", float(head.texture.get_width()) * absf(head.global_scale.x))
	player.queue_free()
	quit(0)
