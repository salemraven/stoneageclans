extends RefCounted
class_name LimbAnimationBaker

## Samples LimbTuner preview motion into horizontal PNG strips + JSON manifests.

const LimbBakeFrameCaptureScript = preload("res://scripts/tools/limb_bake_frame_capture.gd")
const PlaceholderCardRegistryScript = preload("res://scripts/config/placeholder_card_registry.gd")

const BAKED_ROOT := "res://assets/baked/clansmen_1"
const FRAME_W := LimbBakeFrameCaptureScript.FRAME_W
const FRAME_H := LimbBakeFrameCaptureScript.FRAME_H
const PADDING := 2

const CLIP_IDLE := "idle"
const CLIP_IDLE1 := "idle1"
const CLIP_WALK := "walk"
const CLIP_GATHER1 := "gather1"

const IDLE_FPS := 8
const WALK_FPS := 12
const GATHER_FPS := 10
const IDLE_FRAMES := 16
const WALK_FRAMES := 24
const GATHER_FRAMES := 20
const IDLE_CYCLE_SEC := 2.0


static func clip_for_anim_mode(mode: int) -> String:
	match mode:
		WeaponLimbPreset.TunerAnimMode.IDLE:
			return CLIP_IDLE
		WeaponLimbPreset.TunerAnimMode.IDLE1:
			return CLIP_IDLE1
		WeaponLimbPreset.TunerAnimMode.WALK, WeaponLimbPreset.TunerAnimMode.WALK1:
			return CLIP_WALK
		WeaponLimbPreset.TunerAnimMode.GATHER1:
			return CLIP_GATHER1
		_:
			return ""


static func is_bakeable_anim_mode(mode: int) -> bool:
	return not clip_for_anim_mode(mode).is_empty()


static func weapon_slug(weapon_type: ResourceData.ResourceType) -> String:
	match weapon_type:
		ResourceData.ResourceType.NONE:
			return "none"
		ResourceData.ResourceType.WOOD:
			return "club"
		ResourceData.ResourceType.SPEAR:
			return "spear"
		ResourceData.ResourceType.AXE:
			return "axe"
		ResourceData.ResourceType.PICK:
			return "pick"
		ResourceData.ResourceType.OLDOWAN:
			return "oldowan"
		_:
			return "unknown"


static func fps_for_clip(clip: String) -> int:
	match clip:
		CLIP_WALK:
			return WALK_FPS
		CLIP_GATHER1:
			return GATHER_FPS
		_:
			return IDLE_FPS


static func frame_count_for_clip(clip: String) -> int:
	match clip:
		CLIP_WALK:
			return WALK_FRAMES
		CLIP_GATHER1:
			return GATHER_FRAMES
		_:
			return IDLE_FRAMES


static func output_paths(weapon_type: ResourceData.ResourceType, clip: String) -> Dictionary:
	var dir := "%s/%s" % [BAKED_ROOT, weapon_slug(weapon_type)]
	return {
		"dir": dir,
		"png": "%s/%s.png" % [dir, clip],
		"json": "%s/%s.json" % [dir, clip],
	}


func bake_from_tuner(app: Node, clip: String) -> Dictionary:
	return await _bake_from_tuner_async(app, clip)


func _bake_from_tuner_async(app: Node, clip: String) -> Dictionary:
	var result := {
		"ok": false,
		"clip": clip,
		"error": "",
		"png_path": "",
		"json_path": "",
		"manifest": {},
	}
	if app == null or not app.has_method("prepare_bake_sample"):
		result.error = "Tuner app missing prepare_bake_sample."
		return result
	var rig: Node = app.get("_rig")
	var preset = app.get("_preset")
	if rig == null or preset == null:
		result.error = "Tuner rig or preset missing."
		return result
	if clip.is_empty():
		result.error = "No bakeable clip for this pose."
		return result
	var tree := app.get_tree()
	if tree == null or tree.root == null:
		result.error = "Scene tree unavailable."
		return result
	var frame_count := frame_count_for_clip(clip)
	var fps := fps_for_clip(clip)
	var capture := LimbBakeFrameCaptureScript.new()
	var was_handle_visible: bool = _set_handles_visible(app, false)
	var was_arms_visible: bool = _set_arms_visible(app, false)
	var strip_w := frame_count * (FRAME_W + PADDING) - PADDING
	var strip := Image.create(strip_w, FRAME_H, false, Image.FORMAT_RGBA8)
	strip.fill(Color(0, 0, 0, 0))
	for i in frame_count:
		var phase := float(i) / float(frame_count)
		app.prepare_bake_sample(clip, phase)
		await tree.process_frame
		RenderingServer.force_draw(true)
		var frame_img := capture.capture_rig(rig as LimbTunerRig)
		if frame_img.get_width() != FRAME_W or frame_img.get_height() != FRAME_H:
			result.error = "Bake capture returned wrong frame size."
			_restore_visibility(app, was_handle_visible, was_arms_visible)
			return result
		var x := i * (FRAME_W + PADDING)
		strip.blit_rect(frame_img, Rect2i(0, 0, FRAME_W, FRAME_H), Vector2i(x, 0))
	_restore_visibility(app, was_handle_visible, was_arms_visible)
	var paths := output_paths(app.get("_selected_weapon"), clip)
	var abs_dir := ProjectSettings.globalize_path(paths.dir)
	if not DirAccess.dir_exists_absolute(abs_dir):
		DirAccess.make_dir_recursive_absolute(abs_dir)
	var png_err := strip.save_png(paths.png)
	if png_err != OK:
		result.error = "Failed to save PNG (%s)" % str(png_err)
		return result
	var manifest := {
		"clip": clip,
		"weapon": weapon_slug(app.get("_selected_weapon")),
		"body_card_id": "clansmen_1",
		"frame_size": [FRAME_W, FRAME_H],
		"padding": PADDING,
		"columns": frame_count,
		"rows": 1,
		"directions": 1,
		"direction": "E",
		"fps": fps,
		"loop": true,
		"baked_at_utc": Time.get_datetime_string_from_system(true),
	}
	var json_err := _write_json(paths.json, manifest)
	if json_err != OK:
		result.error = "Failed to save JSON (%s)" % str(json_err)
		return result
	result.ok = true
	result.png_path = paths.png
	result.json_path = paths.json
	result.manifest = manifest
	return result


static func _write_json(path: String, data: Dictionary) -> Error:
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		return FileAccess.get_open_error()
	file.store_string(JSON.stringify(data, "\t"))
	file.close()
	return OK


static func _set_handles_visible(app: Node, visible: bool) -> bool:
	var handle_stage: Node = app.get("_handle_stage")
	if handle_stage == null:
		return false
	var was: bool = handle_stage.visible
	handle_stage.visible = visible
	return was


static func _set_arms_visible(app: Node, visible: bool) -> bool:
	var rig: Node = app.get("_rig")
	if rig == null:
		return false
	var ctrl: Node = rig.get_node_or_null("ProceduralArmController")
	if ctrl == null:
		return false
	var was: bool = ctrl.visible
	ctrl.visible = visible
	if visible:
		ctrl.set_process(true)
	return was


static func _restore_visibility(app: Node, handles: bool, arms: bool) -> void:
	_set_handles_visible(app, handles)
	_set_arms_visible(app, arms)
	var rig: Node = app.get("_rig")
	if rig and rig.has_method("_sync_body_visual_head_draw"):
		rig.call("_sync_body_visual_head_draw")
