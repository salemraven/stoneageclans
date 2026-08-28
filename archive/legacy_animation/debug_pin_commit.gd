extends SceneTree

const LimbTunerClipBridgeScript = preload("res://scripts/tools/limb_tuner_clip_bridge.gd")
const AnimCatalogScript = preload("res://scripts/config/character_animation_catalog.gd")
const LimbPresetCoords = preload("res://scripts/systems/limb_preset_coords.gd")
const WeaponLimbPresetScript = preload("res://scripts/config/weapon_limb_preset.gd")

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	await process_frame
	var packed := load("res://scenes/tools/LimbTuner.tscn") as PackedScene
	var app: Node = packed.instantiate()
	root.add_child(app)
	for _i in range(8):
		await process_frame
	app.call("_apply_pose_catalog_entry", ResourceData.ResourceType.NONE, WeaponLimbPresetScript.TunerAnimMode.WALK1)
	for _i in range(6):
		await process_frame
	var rig: LimbTunerRig = app.get("_rig")
	var hand: Node2D = app.get("_hand_handle")
	var preset: WeaponLimbPreset = app.get("_preset")
	var before := hand.global_position
	var target := before + Vector2(35.0, -18.0)
	app.set("_active_drag_handle", app.get("_hand_handle"))
	app.call("_on_hand_dragged", target)
	print("after drag hand: ", hand.global_position)
	print("rig.to_local(hand): ", rig.to_local(hand.global_position))
	print("sprite.position: ", rig.sprite.position)
	var manual_display := LimbPresetCoords.body_display_from_global(rig.sprite, hand.global_position)
	print("body_display_from_global: ", manual_display)
	var roundtrip := LimbPresetCoords.body_global_from_display(rig.sprite, manual_display)
	print("roundtrip global: ", roundtrip)
	var pose = LimbTunerClipBridgeScript.read_handles_into_pose(app)
	print("read pose hand_weapon_px: ", pose.hand_weapon_px)
	print("hand global at read: ", hand.global_position)
	LimbTunerClipBridgeScript.commit_active_pose(app)
	var clip = preset.get_unified_clip(AnimCatalogScript.CLIP_WALK)
	print("clip hand_weapon_px: ", clip.pose_at_index(0).hand_weapon_px)
	var from_clip := LimbPresetCoords.body_global_from_display(rig.sprite, clip.pose_at_index(0).hand_weapon_px)
	print("from_clip global: ", from_clip)
	print("drag delta: ", before.distance_to(hand.global_position))
	print("commit roundtrip delta: ", hand.global_position.distance_to(from_clip))
	app.set("_active_drag_handle", null)
	app.call("_sync_assemble_preview")
	print("after sync hand: ", hand.global_position)
	print("sync delta from drag: ", target.distance_to(hand.global_position))
	app.queue_free()
	quit(0)
