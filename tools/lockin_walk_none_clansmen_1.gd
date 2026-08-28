extends SceneTree

## Lock-in: Walk animation (none / clansmen_1) — Pose 1 ↔ Pose 2 with pendulum motion.
## Run: godot --headless -s res://tools/lockin_walk_none_clansmen_1.gd

const LimbPresetRegistryScript = preload("res://scripts/systems/limb_preset_registry.gd")
const CharacterAnimationPresetStoreScript = preload(
	"res://scripts/config/character_animation_preset_store.gd"
)
const CharacterAnimationPoseScript = preload("res://scripts/config/character_animation_pose.gd")
const CharacterCardPartsRegistry = preload("res://scripts/config/character_card_parts_registry.gd")
const MotionGolden = preload("res://scripts/systems/motion_golden.gd")
const WalkArmMotion = preload("res://scripts/systems/walk_arm_motion.gd")

const TOLERANCE_PX := 0.05

const SHOULDER_1 := Vector2(118.0, -179.0)
const SHOULDER_2 := Vector2(-95.0, -178.0)
const WALK_A_HAND_1 := Vector2(277.23, -28.68)
const WALK_A_HAND_2 := Vector2(-158.5, 30.07)
const WALK_B_HAND_1 := Vector2(181.76, 37.65)
const WALK_B_HAND_2 := Vector2(42.23, 0.93)
const WALK_ELBOW_1_BEND := 1.0
const WALK_ELBOW_2_BEND := 1.0
const WALK_OVERLAY := Vector2(22.0, -34.0)
const WALK_DURATION := 0.8
const NECK_SOCKET_PX := Vector2(181.2, 77.12)

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

	print("=== Walk animation lock-in (none / clansmen_1) ===")
	_apply_unified_walk(preset)
	_apply_neck_layout()
	_validate_static(preset)
	_validate_motion()

	var err := registry.save_preset(preset)
	if err != OK:
		_fail("ResourceSaver.save failed: %s" % error_string(err))
		_report()
		quit(1)
		return

	var layout_err := CharacterCardPartsRegistry.save_layout(CharacterCardPartsRegistry.get_layout())
	if layout_err != OK:
		_fail("neck layout save failed: %s" % error_string(layout_err))

	var disk: WeaponLimbPreset = registry.reload_preset(ResourceData.ResourceType.NONE, "clansmen_1")
	if disk == null:
		_fail("reload after save failed")
	else:
		_validate_static(disk)
		_validate_motion()

	_report()
	quit(0 if _failures.is_empty() else 1)


func _make_pose(hand_1: Vector2, hand_2: Vector2) -> Resource:
	var pose = CharacterAnimationPoseScript.new()
	pose.shoulder_weapon_px = SHOULDER_1
	pose.shoulder_support_px = SHOULDER_2
	pose.hand_weapon_px = hand_1
	pose.hand_support_px = hand_2
	pose.elbow_weapon_bend_sign = WALK_ELBOW_1_BEND
	pose.elbow_support_bend_sign = WALK_ELBOW_2_BEND
	pose.overlay_offset_px = WALK_OVERLAY
	pose.weapon_rotation_deg = 0.0
	return pose


func _apply_unified_walk(preset: WeaponLimbPreset) -> void:
	preset.ensure_unified_clips(null)
	var clip = CharacterAnimationPresetStoreScript.ensure_clip(
		preset, CharacterAnimationPresetStoreScript.CLIP_WALK, null
	)
	if clip == null:
		_fail("walk unified clip missing")
		return
	clip.set_pose_at_index(0, _make_pose(WALK_A_HAND_1, WALK_A_HAND_2))
	clip.set_pose_at_index(1, _make_pose(WALK_B_HAND_1, WALK_B_HAND_2))
	clip.duration_sec = WALK_DURATION
	clip.saved = true
	clip.pose_b_saved = true
	preset.unified_clips_initialized = true


func _apply_neck_layout() -> void:
	var layout = CharacterCardPartsRegistry.get_layout()
	if layout == null:
		_fail("layer layout missing")
		return
	layout.body_neck_socket_px = NECK_SOCKET_PX


func _validate_static(preset: WeaponLimbPreset) -> void:
	print("\n-- Walk keyframes --")
	var clip = preset.get_unified_clip(CharacterAnimationPresetStoreScript.CLIP_WALK)
	if clip == null:
		_fail("walk clip missing on validate")
		return
	var pose_a = clip.pose_at_index(0)
	var pose_b = clip.pose_at_index(1)
	_expect_vec("clip pose_a hand_1", pose_a.hand_weapon_px, WALK_A_HAND_1)
	_expect_vec("clip pose_a hand_2", pose_a.hand_support_px, WALK_A_HAND_2)
	_expect_vec("clip pose_b hand_1", pose_b.hand_weapon_px, WALK_B_HAND_1)
	_expect_vec("clip pose_b hand_2", pose_b.hand_support_px, WALK_B_HAND_2)
	if not is_equal_approx(clip.duration_sec, WALK_DURATION):
		_fail("walk duration expected %.2f got %.2f" % [WALK_DURATION, clip.duration_sec])
	if not clip.saved or not clip.pose_b_saved:
		_fail("walk saved flags should be true")
	var layout = CharacterCardPartsRegistry.get_layout()
	if layout != null:
		_expect_vec("neck socket", layout.body_neck_socket_px, NECK_SOCKET_PX)


func _validate_motion() -> void:
	print("\n-- Walk pendulum motion --")
	for err_msg in MotionGolden.validate_walk1_pendulum(
		"res://Tests/golden/walk1_motion.json",
		WALK_A_HAND_1,
		WALK_B_HAND_1,
		WALK_A_HAND_2,
		WALK_B_HAND_2
	):
		_fail(err_msg)
	if _failures.is_empty():
		print("  golden walk1 pendulum: OK")


func _expect_vec(label: String, got: Vector2, want: Vector2) -> void:
	print("  %s = (%.2f, %.2f)" % [label, got.x, got.y])
	if got.distance_to(want) > TOLERANCE_PX:
		_fail("%s expected (%.2f, %.2f) got (%.2f, %.2f)" % [label, want.x, want.y, got.x, got.y])


func _fail(msg: String) -> void:
	_failures.append(msg)
	print("FAIL: ", msg)


func _report() -> void:
	print("\n=== Lock-in summary ===")
	if _failures.is_empty():
		print("lockin_walk_none_clansmen_1: PASS")
	else:
		print("lockin_walk_none_clansmen_1: FAIL (%d)" % _failures.size())
		for f in _failures:
			print("  - ", f)
