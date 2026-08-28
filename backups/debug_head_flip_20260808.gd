extends SceneTree

func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	await process_frame
	var packed := load("res://scenes/tools/LimbTuner.tscn") as PackedScene
	var app: Node = packed.instantiate()
	root.add_child(app)
	for _i in range(8):
		await process_frame
	var rig: LimbTunerRig = app.get_node("World/Stage/TunerRig") as LimbTunerRig
	var body_visual: Node = rig.get_node("Sprite/BodyVisual")
	var sprite: Sprite2D = rig.get_node("Sprite") as Sprite2D
	var head_sprite: Sprite2D = sprite.get_node("HeadPivot/HeadSprite") as Sprite2D
	var body_sprite: Sprite2D = body_visual.call("get_body_sprite") as Sprite2D
	rig.apply_travel_facing_direction(-1)
	print(
		"west: sprite.flip_h=%s body.flip_h=%s head.flip_h=%s look_right=%s"
		% [sprite.flip_h, body_sprite.flip_h, head_sprite.flip_h, body_visual.call("is_facing_right")]
	)
	quit()
