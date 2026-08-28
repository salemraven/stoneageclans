extends SceneTree

## Write morph shoulder anchors into every unified clip pose (fixes zero / factory defaults).
## Run: godot --headless -s res://tools/sync_shoulder_anchors.gd

const PRESET_FILES := [
	"res://assets/limb_presets/none_clansmen_1.tres",
	"res://assets/limb_presets/none_test_thickness.tres",
	"res://assets/limb_presets/none_test_unified_rt.tres",
	"res://assets/limb_presets/spear_clansmen_1.tres",
	"res://assets/limb_presets/spear_test_roundtrip.tres",
	"res://assets/limb_presets/club_test_walk.tres",
	"res://assets/limb_presets/club_clansmen_1.tres",
	"res://assets/limb_presets/oldowan_clansmen_1.tres",
	"res://assets/limb_presets/pick_clansmen_1.tres",
	"res://assets/limb_presets/axe_clansmen_1.tres",
]

var _failures: Array[String] = []


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	await process_frame
	print("=== sync_shoulder_anchors ===")
	for path in PRESET_FILES:
		_sync_preset(path)
	_report()
	quit(0 if _failures.is_empty() else 1)


func _sync_preset(path: String) -> void:
	var preset: WeaponLimbPreset = load(path)
	if preset == null:
		_fail("missing preset: %s" % path)
		return
	var weapon_shoulder := preset.shoulder_offset_px
	var support_shoulder := preset.support_shoulder_offset_px
	var pose_count := 0
	for clip in preset.animation_clips:
		if clip == null:
			continue
		for pose_index in [0, 1]:
			var pose = clip.pose_at_index(pose_index)
			if pose == null:
				continue
			pose.shoulder_weapon_px = weapon_shoulder
			pose.shoulder_support_px = support_shoulder
			clip.set_pose_at_index(pose_index, pose)
			pose_count += 1
	var err := ResourceSaver.save(preset, path)
	if err != OK:
		_fail("save failed %s: %s" % [path, error_string(err)])
		return
	print("  OK %s (%d poses, 1=%s 2=%s)" % [
		path.get_file(),
		pose_count,
		str(weapon_shoulder),
		str(support_shoulder),
	])


func _fail(msg: String) -> void:
	push_error(msg)
	_failures.append(msg)


func _report() -> void:
	if _failures.is_empty():
		print("sync_shoulder_anchors: PASS")
	else:
		print("sync_shoulder_anchors: FAIL (%d)" % _failures.size())
