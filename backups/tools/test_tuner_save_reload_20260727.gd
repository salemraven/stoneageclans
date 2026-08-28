extends SceneTree

## Repro: save in LimbTuner then reload — verify disk + UI match.

var _failures: Array[String] = []


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	await process_frame
	var registry: Node = root.get_node_or_null("LimbPresetRegistry")
	if registry == null:
		_fail("LimbPresetRegistry autoload missing")
		_report()
		quit(1)
		return
	_test_registry_reload_cache(registry)
	_test_tuner_spear_save_reload(registry)
	_report()
	quit()


func _test_registry_reload_cache(registry: Node) -> void:
	var path: String = registry.preset_path(ResourceData.ResourceType.SPEAR, "clansmen_1")
	var before: WeaponLimbPreset = registry.get_preset(ResourceData.ResourceType.SPEAR, "clansmen_1", 1)
	var marker := before.overlay_offset_idle_px
	before.overlay_offset_idle_px = marker + Vector2(17.0, -3.0)
	var err: Error = registry.save_preset(before)
	if err != OK:
		_fail("save_preset err=%s" % str(err))
		return
	var reloaded: WeaponLimbPreset = registry.reload_preset(ResourceData.ResourceType.SPEAR, "clansmen_1")
	if reloaded.overlay_offset_idle_px != marker + Vector2(17.0, -3.0):
		_fail(
			"reload after save mismatch got=%s expected=%s"
			% [str(reloaded.overlay_offset_idle_px), str(marker + Vector2(17.0, -3.0))]
		)
	before.overlay_offset_idle_px = marker
	registry.save_preset(before)
	registry.reload_preset(ResourceData.ResourceType.SPEAR, "clansmen_1")
	if not FileAccess.file_exists(path):
		_fail("preset path missing: %s" % path)


func _test_tuner_spear_save_reload(registry: Node) -> void:
	var packed := load("res://scenes/tools/LimbTuner.tscn") as PackedScene
	if packed == null:
		_fail("LimbTuner.tscn missing")
		return
	var app: Node = packed.instantiate()
	root.add_child(app)
	for _i in range(8):
		await process_frame
	var pose_option: OptionButton = app.get_node_or_null(
		"UI/Panel/Margin/VBox/SelectSection/PoseRow/AnimModeOption"
	) as OptionButton
	if pose_option == null:
		_fail("pose dropdown missing")
		app.queue_free()
		return
	for i in pose_option.item_count:
		if pose_option.get_item_text(i).begins_with("Spear · Idle standing"):
			pose_option.select(i)
			pose_option.item_selected.emit(i)
			break
	for _i in range(8):
		await process_frame
	var preset: WeaponLimbPreset = app.get("_preset")
	var rig: LimbTunerRig = app.get_node_or_null("World/Stage/TunerRig") as LimbTunerRig
	if preset == null or rig == null:
		_fail("tuner spear idle: preset or rig missing")
		app.queue_free()
		return
	var saved_overlay := preset.overlay_offset_idle_px
	var live := rig.display_px_from_overlay_position()
	if live.distance_to(saved_overlay) > 4.0:
		_fail(
			"tuner spear idle load mismatch saved=%s live=%s"
			% [str(saved_overlay), str(live)]
		)
	var new_overlay := saved_overlay + Vector2(11.0, -7.0)
	preset.overlay_offset_idle_px = new_overlay
	rig.apply_preset_overlay_for_mode(preset, WeaponLimbPreset.TunerAnimMode.IDLE)
	for _i in range(3):
		await process_frame
	var err: Error = registry.save_preset(preset)
	if err != OK:
		_fail("tuner save_preset err=%s" % str(err))
	app.call("_reload_all_from_disk")
	for _i in range(6):
		await process_frame
	preset = app.get("_preset")
	rig = app.get_node_or_null("World/Stage/TunerRig") as LimbTunerRig
	if preset.overlay_offset_idle_px != new_overlay:
		_fail(
			"after reload preset overlay=%s expected=%s"
			% [str(preset.overlay_offset_idle_px), str(new_overlay)]
		)
	live = rig.display_px_from_overlay_position()
	if live.distance_to(new_overlay) > 4.0:
		_fail(
			"after reload live overlay=%s expected=%s"
			% [str(live), str(new_overlay)]
		)
	preset.overlay_offset_idle_px = saved_overlay
	registry.save_preset(preset)
	app.queue_free()


func _fail(msg: String) -> void:
	push_error(msg)
	_failures.append(msg)


func _report() -> void:
	if _failures.is_empty():
		print("test_tuner_save_reload: PASS")
	else:
		for f in _failures:
			print("test_tuner_save_reload: FAIL — ", f)
		quit(1)
