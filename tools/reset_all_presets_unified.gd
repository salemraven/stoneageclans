extends SceneTree

## Reset every limb preset to fresh unified animation clips (no legacy pose migration).

const LimbPresetRegistryScript = preload("res://scripts/systems/limb_preset_registry.gd")

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
	var registry := LimbPresetRegistryScript.new()
	print("=== reset_all_presets_unified ===")
	for path in PRESET_FILES:
		var preset: WeaponLimbPreset = load(path)
		if preset == null:
			_fail("missing preset: %s" % path)
			continue
		preset.reset_unified_animation_data(registry)
		var err := ResourceSaver.save(preset, path)
		if err != OK:
			_fail("save failed %s: %s" % [path, error_string(err)])
			continue
		var disk: WeaponLimbPreset = load(path)
		if disk == null:
			_fail("reload failed: %s" % path)
			continue
		if not disk.unified_clips_initialized:
			_fail("%s unified_clips_initialized false after reset" % path)
		if disk.animation_clips.is_empty():
			_fail("%s animation_clips empty after reset" % path)
		for clip in disk.animation_clips:
			if clip == null:
				continue
			if clip.saved or clip.pose_b_saved:
				_fail("%s clip %s should be unsaved after reset" % [path, str(clip.clip_id)])
		print("  OK %s (%d clips)" % [path.get_file(), disk.animation_clips.size()])
	_report()
	quit(0 if _failures.is_empty() else 1)


func _fail(msg: String) -> void:
	push_error(msg)
	_failures.append(msg)


func _report() -> void:
	if _failures.is_empty():
		print("reset_all_presets_unified: PASS")
	else:
		print("reset_all_presets_unified: FAIL (%d)" % _failures.size())
		for f in _failures:
			print("  - %s" % f)
