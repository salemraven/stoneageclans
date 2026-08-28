extends SceneTree

## Headless: seed unified walk Pose 1 from idle default rest for idle→walk tuning.
## Pose 2 gets a stride offset template from Pose 1 (not idle breathe frame).

const LimbPresetRegistryScript = preload("res://scripts/systems/limb_preset_registry.gd")
const CharacterAnimationPresetStoreScript = preload(
	"res://scripts/config/character_animation_preset_store.gd"
)

const STRIDE_HAND_1_OFFSET := Vector2(-40.0, 20.0)
const STRIDE_HAND_2_OFFSET := Vector2(40.0, -10.0)

var _failures: Array[String] = []


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	await process_frame
	var registry := LimbPresetRegistryScript.new()
	var preset: WeaponLimbPreset = registry.reload_preset(ResourceData.ResourceType.NONE, "clansmen_1")
	if preset == null:
		_fail("none_clansmen_1.tres missing")
		_report()
		quit(1)
		return

	print("=== Prep walk clansmen_1 (unified: seed Pose 1 from idle rest) ===")
	preset.ensure_unified_clips(null)
	var idle = preset.get_unified_clip(CharacterAnimationPresetStoreScript.CLIP_IDLE)
	var walk = CharacterAnimationPresetStoreScript.ensure_clip(
		preset, CharacterAnimationPresetStoreScript.CLIP_WALK, null
	)
	if idle == null or walk == null:
		_fail("idle or walk unified clip missing")
		_report()
		quit(1)
		return

	var rest = idle.pose_at_index(0).duplicate_pose()
	walk.set_pose_at_index(0, rest)
	var stride = rest.duplicate_pose()
	stride.hand_weapon_px += STRIDE_HAND_1_OFFSET
	stride.hand_support_px += STRIDE_HAND_2_OFFSET
	walk.set_pose_at_index(1, stride)
	walk.saved = false
	walk.pose_b_saved = false

	var err := registry.save_preset(preset)
	if err != OK:
		_fail("save failed: %s" % error_string(err))

	var pose_a = walk.pose_at_index(0)
	var pose_b = walk.pose_at_index(1)
	print("  walk pose_a hand_1: ", pose_a.hand_weapon_px)
	print("  walk pose_a hand_2: ", pose_a.hand_support_px)
	print("  walk pose_b hand_1: ", pose_b.hand_weapon_px)
	print("  walk pose_b hand_2: ", pose_b.hand_support_px)

	_report()
	quit(0 if _failures.is_empty() else 1)


func _fail(msg: String) -> void:
	_failures.append(msg)
	print("FAIL: ", msg)


func _report() -> void:
	if _failures.is_empty():
		print("prep_walk_clansmen_1: PASS — walk Pose 1 = idle rest; Pose 2 = stride template")
	else:
		print("prep_walk_clansmen_1: FAIL (%d)" % _failures.size())
