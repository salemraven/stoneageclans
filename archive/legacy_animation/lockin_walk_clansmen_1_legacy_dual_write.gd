extends SceneTree

## Lock-in: Empty hands walk on clansmen_1 — unified walk clip Pose 1 + Pose 2 + sampler motion.

const LimbPresetRegistryScript = preload("res://scripts/systems/limb_preset_registry.gd")
const CharacterAnimationPresetStoreScript = preload(
	"res://scripts/config/character_animation_preset_store.gd"
)
const CharacterAnimationPoseScript = preload("res://scripts/config/character_animation_pose.gd")
const CharacterAnimationSamplerScript = preload(
	"res://scripts/config/character_animation_sampler.gd"
)
const MotionGolden = preload("res://scripts/systems/motion_golden.gd")

const TOLERANCE_PX := 0.05

const WALK1_A_HAND_1 := Vector2(115.7, 60.39)
const WALK1_A_HAND_2 := Vector2(20.18, 31.88)
const WALK1_B_HAND_1 := Vector2(233.16, 29.45)
const WALK1_B_HAND_2 := Vector2(-163.4, 44.14)
const WALK1_ELBOW_BEND := -1.0
const WALK_DURATION_SEC := 0.8

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

	print("=== walk_clansmen_1 lock-in (unified walk clip) ===")
	_apply_handoff(preset, registry)
	_validate_static(preset)
	_validate_motion(preset)

	var err := registry.save_preset(preset)
	if err != OK:
		_fail("ResourceSaver.save failed: %s" % error_string(err))
		_report()
		quit(1)
		return

	var disk: WeaponLimbPreset = registry.reload_preset(ResourceData.ResourceType.NONE, "clansmen_1")
	if disk != null:
		_validate_static(disk)
		_validate_motion(disk)

	_report()
	quit(0 if _failures.is_empty() else 1)


func _apply_handoff(preset: WeaponLimbPreset, registry) -> void:
	# Legacy row kept in sync for tools still reading walk1_* during cutover.
	preset.walk1_hand_grip_offset_px = WALK1_A_HAND_1
	preset.walk1_support_hand_offset_px = WALK1_A_HAND_2
	preset.walk1_weapon_elbow_bend_sign_override = WALK1_ELBOW_BEND
	preset.walk1_support_elbow_bend_sign_override = WALK1_ELBOW_BEND
	preset.walk1_overlay_offset_px = Vector2(22.0, -34.0)
	preset.walk1_pose_a_saved = true
	preset.walk1_pull_hand_grip_offset_px = WALK1_B_HAND_1
	preset.walk1_pull_support_hand_offset_px = WALK1_B_HAND_2
	preset.walk1_pull_weapon_elbow_bend_sign_override = WALK1_ELBOW_BEND
	preset.walk1_pull_support_elbow_bend_sign_override = WALK1_ELBOW_BEND
	preset.walk1_pose_b_saved = true

	preset.ensure_unified_clips(registry)
	var walk = CharacterAnimationPresetStoreScript.ensure_clip(
		preset, CharacterAnimationPresetStoreScript.CLIP_WALK, registry
	)
	walk.pose_a = _walk_pose(preset, WALK1_A_HAND_1, WALK1_A_HAND_2)
	walk.pose_b = _walk_pose(preset, WALK1_B_HAND_1, WALK1_B_HAND_2)
	walk.duration_sec = WALK_DURATION_SEC
	walk.saved = true
	walk.pose_b_saved = true
	preset.unified_clips_initialized = true


func _walk_pose(preset: WeaponLimbPreset, hand_weapon: Vector2, hand_support: Vector2) -> Resource:
	var pose = CharacterAnimationPoseScript.new()
	pose.shoulder_weapon_px = preset.shoulder_offset_px
	pose.shoulder_support_px = preset.support_shoulder_offset_px
	pose.hand_weapon_px = hand_weapon
	pose.hand_support_px = hand_support
	pose.elbow_weapon_bend_sign = WALK1_ELBOW_BEND
	pose.elbow_support_bend_sign = WALK1_ELBOW_BEND
	pose.overlay_offset_px = Vector2(22.0, -34.0)
	pose.weapon_rotation_deg = preset.idle_rotation_deg
	return pose


func _walk_clip(preset: WeaponLimbPreset):
	return preset.get_unified_clip(CharacterAnimationPresetStoreScript.CLIP_WALK)


func _validate_static(preset: WeaponLimbPreset) -> void:
	print("\n-- Static pins (unified walk clip) --")
	var walk = _walk_clip(preset)
	if walk == null:
		_fail("unified walk clip missing")
		return
	_expect_vec("walk_pose_a_hand_weapon", walk.pose_a.hand_weapon_px, WALK1_A_HAND_1)
	_expect_vec("walk_pose_a_hand_support", walk.pose_a.hand_support_px, WALK1_A_HAND_2)
	_expect_vec("walk_pose_b_hand_weapon", walk.pose_b.hand_weapon_px, WALK1_B_HAND_1)
	_expect_vec("walk_pose_b_hand_support", walk.pose_b.hand_support_px, WALK1_B_HAND_2)
	if not walk.saved or not walk.pose_b_saved:
		_fail("walk clip saved flags must be true")
	if absf(walk.duration_sec - WALK_DURATION_SEC) > 0.001:
		_fail("walk duration expected %.2f got %.2f" % [WALK_DURATION_SEC, walk.duration_sec])


func _validate_motion(preset: WeaponLimbPreset) -> void:
	print("\n-- Walk sampler motion --")
	var walk = _walk_clip(preset)
	if walk == null:
		return
	var prev := WALK1_A_HAND_1
	for i in range(9):
		var elapsed := (float(i) / 8.0) * WALK_DURATION_SEC * 2.0
		var sampled = CharacterAnimationSamplerScript.sample_clip(walk, elapsed)
		var dom = sampled.hand_weapon_px
		if i > 0 and dom.distance_to(prev) > 180.0:
			_fail("walk hand teleport at phase %.2f" % (float(i) / 8.0))
		prev = dom
	for err_msg in MotionGolden.validate_walk1_pendulum(
		"res://Tests/golden/walk1_motion.json",
		WALK1_A_HAND_1,
		WALK1_B_HAND_1,
		WALK1_A_HAND_2,
		WALK1_B_HAND_2
	):
		_fail(err_msg)
	if _failures.is_empty():
		print("  walk sampler + golden: OK")


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
		print("lockin_walk_clansmen_1: PASS")
	else:
		print("lockin_walk_clansmen_1: FAIL (%d)" % _failures.size())
		for f in _failures:
			print("  - ", f)
