extends SceneTree

## Compare tuner rig vs in-game player mannequin at 1:1 world scale.

const PLAYER_SCENE := "res://scenes/Player.tscn"
const TUNER_SCENE := "res://scenes/tools/LimbTuner.tscn"


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	await process_frame
	var svc = root.get_node_or_null("/root/PlaceholderCardService")
	if svc == null:
		push_error("compare_mannequin_parity: PlaceholderCardService missing")
		quit(1)
		return

	var tuner_app: Node = (load(TUNER_SCENE) as PackedScene).instantiate()
	root.add_child(tuner_app)
	for _i in range(8):
		await process_frame

	var rig: Node = tuner_app.get_node_or_null("World/Stage/TunerRig")
	var player: Node = (load(PLAYER_SCENE) as PackedScene).instantiate()
	root.add_child(player)
	await process_frame
	svc.apply_to_player(player)
	await process_frame

	var tuner_sprite: Sprite2D = rig.get_node("Sprite") as Sprite2D
	var game_sprite: Sprite2D = player.get_node("Sprite") as Sprite2D
	var stage: Node2D = tuner_app.get_node("World/Stage") as Node2D

	print("=== MANNEQUIN PARITY ===")
	print("tuner stage.scale: ", stage.scale if stage else Vector2.ONE)
	print("tuner sprite.scale: ", tuner_sprite.scale)
	print("game  sprite.scale: ", game_sprite.scale)
	print("tuner sprite.position: ", tuner_sprite.position)
	print("game  sprite.position: ", game_sprite.position)

	var tuner_body_h := _body_display_height(tuner_sprite)
	var game_body_h := _body_display_height(game_sprite)
	var tuner_head_h := _head_display_height(tuner_sprite)
	var game_head_h := _head_display_height(game_sprite)

	print("tuner body display height (px): ", tuner_body_h)
	print("game  body display height (px): ", game_body_h)
	print("tuner head display height (px): ", tuner_head_h)
	print("game  head display height (px): ", game_head_h)
	print("tuner head global_scale.y: ", _head_global_scale(tuner_sprite))
	print("game  head global_scale.y: ", _head_global_scale(game_sprite))
	print("tuner body global_scale.y: ", _body_global_scale(tuner_sprite))
	print("game  body global_scale.y: ", _body_global_scale(game_sprite))

	var fail := false
	if absf(stage.scale.x - 1.0) > 0.01 or absf(stage.scale.y - 1.0) > 0.01:
		push_error("tuner stage must be 1:1 with game, got %s" % str(stage.scale))
		fail = true
	if absf(tuner_sprite.scale.x - game_sprite.scale.x) > 0.001:
		push_error("sprite.scale mismatch tuner=%s game=%s" % [tuner_sprite.scale, game_sprite.scale])
		fail = true
	if absf(tuner_body_h - game_body_h) > 2.0:
		push_error("body height mismatch tuner=%.1f game=%.1f" % [tuner_body_h, game_body_h])
		fail = true
	if absf(tuner_head_h - game_head_h) > 2.0:
		push_error("head height mismatch tuner=%.1f game=%.1f" % [tuner_head_h, game_head_h])
		fail = true

	var expected_scale: float = 128.0 / 470.0
	if absf(game_sprite.scale.x - expected_scale) > 0.01:
		push_error("game scale %.4f expected body1 scale %.4f" % [game_sprite.scale.x, expected_scale])
		fail = true

	if fail:
		quit(1)
	else:
		print("compare_mannequin_parity: PASS (tuner rig matches in-game player at 1:1 scale)")
		quit(0)


func _body_display_height(sprite: Sprite2D) -> float:
	var body_visual: Node = sprite.get_node_or_null("BodyVisual")
	if body_visual == null or not body_visual.has_method("get_body_sprite"):
		return -1.0
	var body: Sprite2D = body_visual.call("get_body_sprite") as Sprite2D
	if body == null or body.texture == null:
		return -1.0
	return float(body.texture.get_height()) * absf(body.global_scale.y)


func _head_display_height(sprite: Sprite2D) -> float:
	var head_pivot: Node2D = sprite.get_node_or_null("HeadPivot") as Node2D
	if head_pivot == null:
		return -1.0
	var head: Sprite2D = head_pivot.get_node_or_null("HeadSprite") as Sprite2D
	if head == null or head.texture == null:
		return -1.0
	return float(head.texture.get_height()) * absf(head.global_scale.y)


func _head_global_scale(sprite: Sprite2D) -> float:
	var head_pivot: Node2D = sprite.get_node_or_null("HeadPivot") as Node2D
	if head_pivot == null:
		return -1.0
	var head: Sprite2D = head_pivot.get_node_or_null("HeadSprite") as Sprite2D
	if head == null:
		return -1.0
	return absf(head.global_scale.y)


func _body_global_scale(sprite: Sprite2D) -> float:
	var body_visual: Node = sprite.get_node_or_null("BodyVisual")
	if body_visual == null or not body_visual.has_method("get_body_sprite"):
		return -1.0
	var body: Sprite2D = body_visual.call("get_body_sprite") as Sprite2D
	if body == null:
		return -1.0
	return absf(body.global_scale.y)
