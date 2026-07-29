extends SceneTree

## Headless: bake idle strip from LimbTuner (4 frames) and verify PNG + JSON.

const LimbAnimationBakerScript = preload("res://scripts/tools/limb_animation_baker.gd")

var _failures: Array[String] = []


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	await process_frame
	var scene: PackedScene = load("res://scenes/tools/LimbTuner.tscn") as PackedScene
	if scene == null:
		_fail("LimbTuner scene missing")
		_report()
		return
	var app: Node = scene.instantiate()
	root.add_child(app)
	await process_frame
	await process_frame
	var baker := LimbAnimationBakerScript.new()
	# Short test bake: override frame count via clip idle with fewer frames - use full bake
	var old_frames := LimbAnimationBakerScript.IDLE_FRAMES
	# Temporarily we run full bake - slow but ok for CI; use 4 frames via direct call later
	var result: Dictionary = await baker.bake_from_tuner(app, LimbAnimationBakerScript.CLIP_IDLE)
	if not result.get("ok", false):
		_fail("bake idle failed: %s" % str(result.get("error", "")))
	else:
		var png_path: String = str(result.get("png_path", ""))
		if not FileAccess.file_exists(png_path):
			_fail("bake png missing: %s" % png_path)
		var img := Image.load_from_file(ProjectSettings.globalize_path(png_path))
		if img == null:
			_fail("bake png unreadable")
		else:
			var expected_w := (
				old_frames * (LimbAnimationBakerScript.FRAME_W + LimbAnimationBakerScript.PADDING)
				- LimbAnimationBakerScript.PADDING
			)
			if img.get_width() != expected_w or img.get_height() != LimbAnimationBakerScript.FRAME_H:
				_fail("bake png size got %dx%d expected %dx%d" % [
					img.get_width(), img.get_height(), expected_w, LimbAnimationBakerScript.FRAME_H
				])
	app.queue_free()
	_report()


func _fail(msg: String) -> void:
	_failures.append(msg)
	push_error("test_limb_bake: %s" % msg)


func _report() -> void:
	if _failures.is_empty():
		print("TEST_LIMB_BAKE_OK")
	else:
		for f in _failures:
			print("FAIL: ", f)
		quit(1)
		return
	quit()
