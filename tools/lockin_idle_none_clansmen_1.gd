extends SceneTree

## Lock-in: Idle animation (none / clansmen_1) — Pose 1 default rest + Pose 2 idle cycle.
## Run: godot --headless -s res://tools/lockin_idle_none_clansmen_1.gd

const LimbPresetRegistryScript = preload("res://scripts/systems/limb_preset_registry.gd")
const CharacterAnimationPresetStoreScript = preload(
	"res://scripts/config/character_animation_preset_store.gd"
)
const CharacterAnimationPoseScript = preload("res://scripts/config/character_animation_pose.gd")
const CharacterCardPartsRegistry = preload("res://scripts/config/character_card_parts_registry.gd")

const TOLERANCE_PX := 0.05

const SHOULDER_1 := Vector2(118.0, -179.0)
const SHOULDER_2 := Vector2(-95.0, -178.0)
const IDLE_A_HAND_1 := Vector2(186.65, 34.35)
const IDLE_A_HAND_2 := Vector2(-136.47, 41.69)
const IDLE_B_HAND_1 := Vector2(174.41, 44.14)
const IDLE_B_HAND_2 := Vector2(-119.34, 46.59)
const IDLE_ELBOW_1_BEND := -1.0
const IDLE_ELBOW_2_BEND := 1.0
const IDLE_OVERLAY := Vector2(22.0, -34.0)
const NECK_SOCKET_PX := Vector2(179.21, 66.09)

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

	print("=== Idle animation lock-in (none / clansmen_1) ===")
	_apply_morphology(preset)
	_apply_unified_idle(preset)
	_reseed_gather_from_idle_default(preset)
	_apply_neck_layout()
	_validate(preset)

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
		_validate(disk)

	_report()
	quit(0 if _failures.is_empty() else 1)


func _make_pose(
	hand_1: Vector2,
	hand_2: Vector2,
	elbow_1: float,
	elbow_2: float
) -> Resource:
	var pose = CharacterAnimationPoseScript.new()
	pose.shoulder_weapon_px = SHOULDER_1
	pose.shoulder_support_px = SHOULDER_2
	pose.hand_weapon_px = hand_1
	pose.hand_support_px = hand_2
	pose.elbow_weapon_bend_sign = elbow_1
	pose.elbow_support_bend_sign = elbow_2
	pose.overlay_offset_px = IDLE_OVERLAY
	pose.weapon_rotation_deg = 0.0
	return pose


func _apply_morphology(preset: WeaponLimbPreset) -> void:
	preset.weapon_type = ResourceData.ResourceType.NONE
	preset.body_card_id = "clansmen_1"
	preset.shoulder_offset_px = SHOULDER_1
	preset.support_shoulder_offset_px = SHOULDER_2
	preset.hand_grip_offset_px = IDLE_A_HAND_1
	preset.support_hand_idle_offset_px = IDLE_A_HAND_2
	preset.weapon_elbow_bend_sign_override = IDLE_ELBOW_1_BEND
	preset.support_elbow_bend_sign_override = IDLE_ELBOW_2_BEND
	preset.overlay_offset_idle_px = IDLE_OVERLAY
	preset.upper_arm_length = 120.0
	preset.lower_arm_length = 120.0
	preset.unified_clips_initialized = true


func _apply_unified_idle(preset: WeaponLimbPreset) -> void:
	preset.ensure_unified_clips(null)
	var clip = CharacterAnimationPresetStoreScript.ensure_clip(
		preset, CharacterAnimationPresetStoreScript.CLIP_IDLE, null
	)
	if clip == null:
		_fail("idle unified clip missing")
		return
	clip.set_pose_at_index(
		0,
		_make_pose(IDLE_A_HAND_1, IDLE_A_HAND_2, IDLE_ELBOW_1_BEND, IDLE_ELBOW_2_BEND)
	)
	clip.set_pose_at_index(
		1,
		_make_pose(IDLE_B_HAND_1, IDLE_B_HAND_2, IDLE_ELBOW_1_BEND, IDLE_ELBOW_2_BEND)
	)
	clip.saved = true
	clip.pose_b_saved = true


func _reseed_gather_from_idle_default(preset: WeaponLimbPreset) -> void:
	var gather = CharacterAnimationPresetStoreScript.ensure_clip(
		preset, CharacterAnimationPresetStoreScript.CLIP_GATHER, null
	)
	if gather == null:
		_fail("gather unified clip missing")
		return
	var idle = preset.get_unified_clip(CharacterAnimationPresetStoreScript.CLIP_IDLE)
	if idle == null:
		_fail("idle clip missing for gather reseed")
		return
	var default_pose = idle.pose_at_index(0).duplicate_pose()
	gather.set_pose_at_index(0, default_pose)
	gather.set_pose_at_index(1, default_pose.duplicate_pose())
	gather.saved = false
	gather.pose_b_saved = false


func _apply_neck_layout() -> void:
	var layout = CharacterCardPartsRegistry.get_layout()
	if layout == null:
		_fail("layer layout missing")
		return
	layout.body_neck_socket_px = NECK_SOCKET_PX


func _validate(preset: WeaponLimbPreset) -> void:
	print("\n-- Idle default rest (Pose 1 / morphology) --")
	_expect_vec("morph hand_1", preset.hand_grip_offset_px, IDLE_A_HAND_1)
	_expect_vec("morph hand_2", preset.support_hand_idle_offset_px, IDLE_A_HAND_2)
	if signf(preset.weapon_elbow_bend_sign_override) != signf(IDLE_ELBOW_1_BEND):
		_fail("morph elbow_1 bend sign wrong")
	if signf(preset.support_elbow_bend_sign_override) != signf(IDLE_ELBOW_2_BEND):
		_fail("morph elbow_2 bend sign wrong")

	var clip = preset.get_unified_clip(CharacterAnimationPresetStoreScript.CLIP_IDLE)
	if clip == null:
		_fail("idle clip missing on validate")
		return
	var pose_a = clip.pose_at_index(0)
	var pose_b = clip.pose_at_index(1)
	_expect_vec("clip pose_a hand_1", pose_a.hand_weapon_px, IDLE_A_HAND_1)
	_expect_vec("clip pose_a hand_2", pose_a.hand_support_px, IDLE_A_HAND_2)
	_expect_vec("clip pose_b hand_1", pose_b.hand_weapon_px, IDLE_B_HAND_1)
	_expect_vec("clip pose_b hand_2", pose_b.hand_support_px, IDLE_B_HAND_2)
	if not clip.saved or not clip.pose_b_saved:
		_fail("idle clip saved flags should be true")

	var gather = preset.get_unified_clip(CharacterAnimationPresetStoreScript.CLIP_GATHER)
	if gather != null:
		var g_a = gather.pose_at_index(0)
		_expect_vec("gather pose_a hand_1", g_a.hand_weapon_px, IDLE_A_HAND_1)
		_expect_vec("gather pose_a hand_2", g_a.hand_support_px, IDLE_A_HAND_2)

	var layout = CharacterCardPartsRegistry.get_layout()
	if layout != null:
		_expect_vec("neck socket", layout.body_neck_socket_px, NECK_SOCKET_PX)


func _expect_vec(label: String, got: Vector2, want: Vector2) -> void:
	_print_vec("  %s" % label, got)
	if got.distance_to(want) > TOLERANCE_PX:
		_fail("%s expected (%.2f, %.2f) got (%.2f, %.2f)" % [label, want.x, want.y, got.x, got.y])


func _print_vec(label: String, v: Vector2) -> void:
	print("%s = (%.2f, %.2f)" % [label, v.x, v.y])


func _fail(msg: String) -> void:
	_failures.append(msg)
	print("FAIL: ", msg)


func _report() -> void:
	print("\n=== Lock-in summary ===")
	if _failures.is_empty():
		print("lockin_idle_none_clansmen_1: PASS")
	else:
		print("lockin_idle_none_clansmen_1: FAIL (%d)" % _failures.size())
		for f in _failures:
			print("  - ", f)
