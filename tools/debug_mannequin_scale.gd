extends SceneTree

## Headless: verify mannequin + limb anchor sizes match card scale.

func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	await process_frame
	var packed := load("res://scenes/tools/LimbTuner.tscn") as PackedScene
	var app: Node = packed.instantiate()
	root.add_child(app)
	for _i in range(6):
		await process_frame
	var rig: Node = app.get_node("World/Stage/TunerRig")
	var sprite: Sprite2D = rig.get_node("Sprite") as Sprite2D
	var layout = rig.get("_mannequin_layout")
	var scale: float = sprite.scale.x
	var expected_scale: float = 128.0 / 470.0
	if absf(scale - expected_scale) > 0.02:
		push_error("scale got %.4f expected ~%.4f (body1.png card scale)" % [scale, expected_scale])
		quit(1)
		return
	if absf(sprite.position.y - (-64.0)) > 1.0:
		push_error("foot_y got %s expected ~-64" % str(sprite.position.y))
		quit(1)
		return
	var body: Node2D = sprite.get_node("BodyVisual") as Node2D
	if body.get_child_count() < 1:
		push_error("BodyVisual has no shapes")
		quit(1)
		return
	print("debug_mannequin_scale: PASS scale=%.4f foot_y=%.1f ref_h=%s" % [
		scale, sprite.position.y, str(layout.ref_texture_height if layout else "?")
	])
	quit(0)
