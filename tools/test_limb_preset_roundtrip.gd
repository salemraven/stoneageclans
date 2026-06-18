extends SceneTree

## Headless: shoulder/overlay preset round-trip through LimbTunerRig.

func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	await process_frame
	var packed := load("res://scenes/tools/LimbTuner.tscn") as PackedScene
	var app: Node = packed.instantiate()
	root.add_child(app)
	for _i in range(6):
		await process_frame
	var rig: LimbTunerRig = app.get_node("World/Stage/TunerRig") as LimbTunerRig
	var preset := WeaponLimbPreset.defaults_for(ResourceData.ResourceType.SPEAR, 1)
	preset.shoulder_offset_px = Vector2(528.3281, -447.0468)
	preset.support_shoulder_offset_px = Vector2(-690.8906, -487.6875)
	preset.support_hand_idle_offset_px = Vector2(-731.5312, 975.3749)
	preset.hand_grip_offset_px = Vector2(6.375, 95.625)
	preset.overlay_offset_idle_px = Vector2(22.0, -34.0)
	preset.ready_offset_px = Vector2(36.0, 3.0)
	preset.support_hand_offset_px = Vector2(12.75, 325.125)

	rig.apply_preset_overlay_idle(preset)
	var g_sh := rig.shoulder_global_from_preset(preset)
	var g_sup := rig.support_shoulder_global_from_preset(preset)
	var g_idle := rig.support_hand_idle_global_from_preset(preset)
	var g_hand := rig.hand_grip_global_from_preset(preset)
	print("user_json shoulder global: ", g_sh, " rig_global: ", rig.global_position)
	print("user_json support_shoulder global: ", g_sup)
	print("user_json support_idle global: ", g_idle)
	print("user_json hand_grip global: ", g_hand)

	var p2 := WeaponLimbPreset.new()
	rig.set_shoulder_from_global(p2, g_sh)
	rig.set_support_shoulder_from_global(p2, g_sup)
	rig.set_support_hand_idle_from_global(p2, g_idle)
	rig.set_hand_grip_from_global(p2, g_hand)

	print("roundtrip shoulder: ", preset.shoulder_offset_px, " -> ", p2.shoulder_offset_px)
	print("roundtrip support_shoulder: ", preset.support_shoulder_offset_px, " -> ", p2.support_shoulder_offset_px)
	print("roundtrip support_idle_hand: ", preset.support_hand_idle_offset_px, " -> ", p2.support_hand_idle_offset_px)
	print("roundtrip hand_grip: ", preset.hand_grip_offset_px, " -> ", p2.hand_grip_offset_px)
	print("sprite.scale: ", rig.sprite.scale)
	app.queue_free()
	quit(0)
