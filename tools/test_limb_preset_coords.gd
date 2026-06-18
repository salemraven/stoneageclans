extends SceneTree

## Headless: tuner vs player use the same body/overlay coordinate math.

const LimbPresetCoords = preload("res://scripts/systems/limb_preset_coords.gd")


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	await process_frame
	var failures: Array[String] = []

	var tuner_scene := load("res://scenes/tools/LimbTuner.tscn") as PackedScene
	var app: Node = tuner_scene.instantiate()
	root.add_child(app)
	for _i in range(8):
		await process_frame

	var tuner_rig: LimbTunerRig = app.get_node("World/Stage/TunerRig") as LimbTunerRig
	var player_scene := load("res://scenes/Player.tscn") as PackedScene
	var player: Node = player_scene.instantiate()
	root.add_child(player)
	await process_frame

	var preset := WeaponLimbPreset.new()
	preset.shoulder_offset_px = Vector2(8.0, -14.0)
	preset.support_shoulder_offset_px = Vector2(-16.0, -18.0)
	preset.support_hand_idle_offset_px = Vector2(-10.0, 28.0)
	preset.hand_grip_offset_px = Vector2(0.0, 82.0)
	preset.support_hand_offset_px = Vector2(-3.0, 310.0)
	preset.overlay_offset_idle_px = Vector2(22.0, -34.0)
	preset.ready_offset_px = Vector2(37.0, 5.0)

	tuner_rig.apply_preset_overlay_idle(preset)
	var tuner_sprite: Sprite2D = tuner_rig.sprite
	var player_sprite: Sprite2D = player.get_node("Sprite") as Sprite2D

	var tuner_shoulder := LimbPresetCoords.body_display_to_rig_local(tuner_sprite, preset.shoulder_offset_px)
	var player_shoulder := player_sprite.position + Vector2(
		preset.shoulder_offset_px.x * player_sprite.scale.x,
		preset.shoulder_offset_px.y * player_sprite.scale.y
	)
	if tuner_shoulder.distance_to(player_shoulder) > 2.0:
		failures.append("shoulder rig-local mismatch tuner=%s player=%s" % [tuner_shoulder, player_shoulder])

	var roundtrip := LimbPresetCoords.body_display_from_global(
		tuner_sprite,
		LimbPresetCoords.body_global_from_display(tuner_sprite, preset.shoulder_offset_px)
	)
	if roundtrip.distance_to(preset.shoulder_offset_px) > 0.05:
		failures.append("shoulder roundtrip failed %s -> %s" % [preset.shoulder_offset_px, roundtrip])

	app.queue_free()
	player.queue_free()

	if failures.is_empty():
		print("test_limb_preset_coords: PASS")
	else:
		for f in failures:
			print("test_limb_preset_coords: FAIL — ", f)
		quit(1)
		return
	quit(0)
