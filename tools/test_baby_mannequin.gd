extends SceneTree
## SKIP_SINGLE_INSTANCE=1 godot --headless --path . --script res://tools/test_baby_mannequin.gd

const NPC_SCENE_PATH := "res://scenes/NPC.tscn"


func _init() -> void:
	call_deferred("_run")


func _fail(msg: String) -> void:
	push_error("TEST_BABY_MANNEQUIN_FAIL: %s" % msg)
	quit(1)


func _run() -> void:
	var svc: Node = Engine.get_main_loop().root.get_node_or_null("PlaceholderCardService")
	if svc == null:
		_fail("PlaceholderCardService missing")
		return
	var npc_scene: PackedScene = load(NPC_SCENE_PATH) as PackedScene
	var baby: Node = npc_scene.instantiate()
	baby.set("npc_type", "baby")
	baby.set("npc_name", "TEST_BABY")
	root.add_child(baby)
	await process_frame
	if not svc.uses_layered_body_mannequin(baby):
		_fail("baby should be layered, not baby.png")
	if svc.uses_legacy_baked_card(baby):
		_fail("baby should not be legacy baked")
	svc.apply_to_npc(baby)
	var sprite: Sprite2D = baby.get_node_or_null("Sprite") as Sprite2D
	if sprite == null or sprite.texture != null:
		_fail("baby sprite should be layered (no card texture)")
	if sprite.get_node_or_null("BodyVisual") == null:
		_fail("baby BodyVisual missing")
	if sprite.get_node_or_null("HeadPivot") == null:
		_fail("baby HeadPivot missing")
	if baby.get_node_or_null("Sprite/HeadPivot/HairFront") != null:
		_fail("baby should have no hair")
	var body_sprite: Sprite2D = sprite.get_node_or_null("BodyVisual/BodySprite") as Sprite2D
	if body_sprite == null or body_sprite.texture == null:
		_fail("baby BodySprite missing")
	else:
		var h: float = float(body_sprite.texture.get_height()) * sprite.scale.y
		if absf(h - 28.0) > 1.5:
			_fail("baby display height should be ~28px, got %.1f" % h)
	print("TEST_BABY_MANNEQUIN_PASS")
	baby.queue_free()
	quit(0)
