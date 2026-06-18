extends SceneTree

## Headless: print LimbTuner layout + rig state after a few frames.

func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	await process_frame
	var packed := load("res://scenes/tools/LimbTuner.tscn") as PackedScene
	if packed == null:
		push_error("debug_limb_tuner_boot: scene missing")
		quit(1)
		return
	var app: Control = packed.instantiate() as Control
	root.add_child(app)
	for _i in range(4):
		await process_frame
	var stage: Node2D = app.get_node_or_null("World/Stage") as Node2D
	var rig: Node = app.get_node_or_null("World/Stage/TunerRig")
	var sprite: Sprite2D = app.get_node_or_null("World/Stage/TunerRig/Sprite") as Sprite2D
	var overlay: Sprite2D = app.get_node_or_null("World/Stage/TunerRig/Sprite/WeaponOverlay") as Sprite2D
	var bg: ColorRect = app.get_node_or_null("Background") as ColorRect
	var panel: Control = app.get_node_or_null("UI/Panel") as Control
	print("debug_limb_tuner_boot: app_size=%s stage_pos=%s bg_size=%s panel_size=%s" % [
		str(app.size),
		str(stage.position if stage else "?"),
		str(bg.size if bg else "?"),
		str(panel.size if panel else "?"),
	])
	print("debug_limb_tuner_boot: sprite_tex=%s overlay_vis=%s overlay_tex=%s" % [
		"ok" if sprite and sprite.texture else "MISSING",
		str(overlay.visible if overlay else "?"),
		"ok" if overlay and overlay.texture else "MISSING",
	])
	print("debug_limb_tuner_boot: app_script=%s rig_script=%s" % [
		str(app.get_script()),
		str(rig.get_script() if rig else "?"),
	])
	quit(0)
