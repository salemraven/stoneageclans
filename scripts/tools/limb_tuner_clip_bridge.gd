extends RefCounted
class_name LimbTunerClipBridge

## Sync unified animation clips ↔ tuner handles and rig.

const CharacterAnimationSamplerScript = preload(
	"res://scripts/config/character_animation_sampler.gd"
)
const CharacterAnimationPresetStoreScript = preload(
	"res://scripts/config/character_animation_preset_store.gd"
)
const CharacterAnimationPoseScript = preload("res://scripts/config/character_animation_pose.gd")
const AnimCatalogScript = preload("res://scripts/config/character_animation_catalog.gd")
const WeaponLimbPresetScript = preload("res://scripts/config/weapon_limb_preset.gd")
const ProceduralArmScript = preload("res://scripts/systems/procedural_arm.gd")
const LimbPresetCoords = preload("res://scripts/systems/limb_preset_coords.gd")


static func clip_id_for_app(app: Node) -> StringName:
	if app == null:
		return AnimCatalogScript.CLIP_IDLE
	var mode: int = app.get("_anim_mode")
	var weapon: ResourceData.ResourceType = app.get("_selected_weapon")
	return AnimCatalogScript.clip_id_for_mode(mode as WeaponLimbPresetScript.TunerAnimMode, weapon)


static func pose_index_for_app(app: Node) -> int:
	if app == null:
		return 0
	if app.get("_pose_index") != null:
		return int(app.get("_pose_index"))
	if app.has_method("_walk_pose_edit_b") and app.call("_walk_pose_edit_b"):
		return 1
	if app.has_method("_gather_pose_edit_pull") and app.call("_gather_pose_edit_pull"):
		return 1
	return 0


static func apply_pose_to_handles(app: Node, pose) -> void:
	if app == null or pose == null:
		return
	var rig: LimbTunerRig = app.get("_rig")
	var shoulder: Node2D = app.get("_shoulder_handle")
	var support_shoulder: Node2D = app.get("_support_shoulder_handle")
	var hand: Node2D = app.get("_hand_handle")
	var support_hand: Node2D = app.get("_support_hand_handle")
	var head: Node2D = app.get("_head_handle")
	var spear: Node2D = app.get("_spear_handle")
	if shoulder:
		shoulder.global_position = _body_global(rig, pose.shoulder_weapon_px)
	if support_shoulder:
		support_shoulder.global_position = _body_global(rig, pose.shoulder_support_px)
	if hand:
		if (
			rig
			and rig.has_weapon_overlay()
			and pose.grip_on_art_px.length_squared() > 0.0001
		):
			hand.global_position = LimbPresetCoords.overlay_grip_global(
				rig.weapon_overlay, pose.grip_on_art_px
			)
		else:
			hand.global_position = _body_global(rig, pose.hand_weapon_px)
	if support_hand:
		support_hand.global_position = _body_global(rig, pose.hand_support_px)
	if head and rig:
		head.global_position = rig.neck_socket_global() + _body_global(rig, pose.head_offset_px) - rig.global_position
	if spear and rig and rig.has_weapon_overlay() and pose.grip_on_art_px.length_squared() > 0.0001:
		spear.global_position = LimbPresetCoords.overlay_grip_global(
			rig.weapon_overlay, pose.grip_on_art_px
		)
	_sync_elbow_handles_from_pose(app, pose)


static func read_handles_into_pose(app: Node):
	var pose = CharacterAnimationPoseScript.new()
	var rig: LimbTunerRig = app.get("_rig")
	var shoulder: Node2D = app.get("_shoulder_handle")
	var support_shoulder: Node2D = app.get("_support_shoulder_handle")
	var hand: Node2D = app.get("_hand_handle")
	var support_hand: Node2D = app.get("_support_hand_handle")
	var head: Node2D = app.get("_head_handle")
	var spear: Node2D = app.get("_spear_handle")
	if shoulder and rig:
		pose.shoulder_weapon_px = LimbPresetCoords.body_display_from_global(rig.sprite, shoulder.global_position)
	if support_shoulder and rig:
		pose.shoulder_support_px = LimbPresetCoords.body_display_from_global(
			rig.sprite, support_shoulder.global_position
		)
	if spear and rig and rig.weapon_overlay:
		pose.grip_on_art_px = LimbPresetCoords.overlay_grip_px_from_global(
			rig.weapon_overlay, spear.global_position
		)
		if hand:
			pose.hand_weapon_px = LimbPresetCoords.body_display_from_global(
				rig.sprite, spear.global_position
			)
	elif hand and rig:
		pose.hand_weapon_px = LimbPresetCoords.body_display_from_global(rig.sprite, hand.global_position)
	if support_hand and rig:
		pose.hand_support_px = LimbPresetCoords.body_display_from_global(
			rig.sprite, support_hand.global_position
		)
	if head and rig:
		var neck := rig.neck_socket_global()
		pose.head_offset_px = LimbPresetCoords.body_display_from_global(
			rig.sprite, head.global_position
		) - LimbPresetCoords.body_display_from_global(rig.sprite, neck)
	var weapon_elbow: Node2D = app.get("_weapon_elbow_handle")
	var support_elbow: Node2D = app.get("_support_elbow_handle")
	if weapon_elbow:
		pose.elbow_weapon_bend_sign = _read_bend_from_handle(app, true, weapon_elbow.global_position)
	if support_elbow:
		pose.elbow_support_bend_sign = _read_bend_from_handle(app, false, support_elbow.global_position)
	if app.has_method("_read_weapon_rotation_for_pose"):
		pose.weapon_rotation_deg = float(app.call("_read_weapon_rotation_for_pose"))
	return pose


static func sync_elbows_live(app: Node) -> void:
	var preset: WeaponLimbPreset = app.get("_preset")
	if preset == null:
		return
	var clip_id := clip_id_for_app(app)
	var pose_index := pose_index_for_app(app)
	var clip = preset.get_unified_clip(clip_id)
	if clip == null:
		return
	var stored = clip.pose_at_index(pose_index)
	var live = read_handles_into_pose(app)
	live.elbow_weapon_bend_sign = stored.elbow_weapon_bend_sign
	live.elbow_support_bend_sign = stored.elbow_support_bend_sign
	_sync_elbow_handles_from_pose(app, live)


static func commit_active_pose(app: Node) -> void:
	var preset: WeaponLimbPreset = app.get("_preset")
	if preset == null:
		return
	var clip_id := clip_id_for_app(app)
	var pose_index := pose_index_for_app(app)
	var clip = CharacterAnimationPresetStoreScript.ensure_clip(preset, clip_id, LimbPresetRegistry)
	if clip == null:
		return
	clip.set_pose_at_index(pose_index, read_handles_into_pose(app))
	if pose_index == 1:
		clip.pose_b_saved = true
	preset.unified_clips_initialized = true


static func load_active_pose(app: Node) -> void:
	var preset: WeaponLimbPreset = app.get("_preset")
	if preset == null:
		return
	var clip_id := clip_id_for_app(app)
	var pose_index := pose_index_for_app(app)
	preset.ensure_unified_clips(LimbPresetRegistry)
	var pose = preset.current_pose(clip_id, pose_index)
	apply_pose_to_handles(app, pose)
	if app.has_method("_apply_weapon_rotation_from_pose"):
		app.call("_apply_weapon_rotation_from_pose", pose.weapon_rotation_deg)


static func flip_elbow(app: Node, dominant: bool) -> void:
	var preset: WeaponLimbPreset = app.get("_preset")
	if preset == null:
		return
	var clip_id := clip_id_for_app(app)
	var pose_index := pose_index_for_app(app)
	var clip = CharacterAnimationPresetStoreScript.ensure_clip(preset, clip_id, LimbPresetRegistry)
	var pose = clip.pose_at_index(pose_index).duplicate_pose()
	if dominant:
		pose.elbow_weapon_bend_sign = -pose.elbow_weapon_bend_sign if absf(pose.elbow_weapon_bend_sign) > 0.001 else WeaponLimbPresetScript.DOMINANT_ELBOW_BEND_SIGN
	else:
		pose.elbow_support_bend_sign = -pose.elbow_support_bend_sign if absf(pose.elbow_support_bend_sign) > 0.001 else WeaponLimbPresetScript.SUPPORT_ELBOW_BEND_SIGN
	clip.set_pose_at_index(pose_index, pose)
	apply_pose_to_handles(app, pose)
	if app.has_method("_mark_pose_dirty"):
		app.call("_mark_pose_dirty")


static func sample_walk_preview(app: Node, elapsed_sec: float, facing_left: bool) -> void:
	var preset: WeaponLimbPreset = app.get("_preset")
	if preset == null:
		return
	preset.ensure_unified_clips(LimbPresetRegistry)
	var clip = preset.get_unified_clip(AnimCatalogScript.CLIP_WALK)
	if clip == null:
		return
	var sampled = CharacterAnimationSamplerScript.sample_clip(clip, elapsed_sec)
	if facing_left:
		sampled = CharacterAnimationSamplerScript.mirror_pose_for_facing(sampled, true)
	apply_pose_to_handles(app, sampled)


static func sample_reviewer_clip(app: Node, clip_id: StringName, elapsed_sec: float) -> void:
	var preset: WeaponLimbPreset = app.get("_preset")
	if preset == null:
		return
	preset.ensure_unified_clips(LimbPresetRegistry)
	var clip = preset.get_unified_clip(clip_id)
	if clip == null:
		return
	apply_pose_to_handles(app, CharacterAnimationSamplerScript.sample_clip(clip, elapsed_sec))


static func _body_global(rig: LimbTunerRig, display_px: Vector2) -> Vector2:
	if rig == null or rig.sprite == null:
		return display_px
	return LimbPresetCoords.body_global_from_display(rig.sprite, display_px)


static func _sync_elbow_handles_from_pose(app: Node, pose) -> void:
	var rig: LimbTunerRig = app.get("_rig")
	var preset: WeaponLimbPreset = app.get("_preset")
	if rig == null or preset == null or pose == null:
		return
	var weapon_elbow: Node2D = app.get("_weapon_elbow_handle")
	var support_elbow: Node2D = app.get("_support_elbow_handle")
	var shoulder: Node2D = app.get("_shoulder_handle")
	var support_shoulder: Node2D = app.get("_support_shoulder_handle")
	var hand: Node2D = app.get("_hand_handle")
	var support_hand: Node2D = app.get("_support_hand_handle")
	var sx := absf(rig.sprite.scale.x) if rig.sprite else 1.0
	if weapon_elbow and shoulder and hand:
		weapon_elbow.global_position = _elbow_global(
			rig, shoulder.global_position, hand.global_position,
			preset.resolve_upper_arm_length(true) * sx,
			preset.resolve_lower_arm_length(true) * sx,
			pose.elbow_weapon_bend_sign
		)
	if support_elbow and support_shoulder and support_hand:
		support_elbow.global_position = _elbow_global(
			rig, support_shoulder.global_position, support_hand.global_position,
			preset.resolve_upper_arm_length(false) * sx,
			preset.resolve_lower_arm_length(false) * sx,
			pose.elbow_support_bend_sign
		)


static func _elbow_global(
	rig: LimbTunerRig,
	shoulder_g: Vector2,
	hand_g: Vector2,
	upper_len: float,
	lower_len: float,
	bend_sign: float
) -> Vector2:
	var shoulder_local := rig.to_local(shoulder_g)
	var hand_local := rig.to_local(hand_g)
	var candidates: Array = ProceduralArmScript.ik_elbow_candidates(
		shoulder_local, hand_local, upper_len, lower_len, false
	)
	if candidates.size() < 2:
		return shoulder_g
	var pick_a := signf(bend_sign) >= 0.0 if absf(bend_sign) > 0.001 else true
	var elbow_local: Vector2 = candidates[0] if pick_a else candidates[1]
	return rig.to_global(elbow_local)


static func _read_bend_from_handle(app: Node, dominant: bool, elbow_global: Vector2) -> float:
	var preset: WeaponLimbPreset = app.get("_preset")
	var rig: LimbTunerRig = app.get("_rig")
	var shoulder: Node2D = app.get("_shoulder_handle") if dominant else app.get("_support_shoulder_handle")
	var hand: Node2D = app.get("_hand_handle") if dominant else app.get("_support_hand_handle")
	if preset == null or rig == null or shoulder == null or hand == null:
		return WeaponLimbPresetScript.DOMINANT_ELBOW_BEND_SIGN if dominant else WeaponLimbPresetScript.SUPPORT_ELBOW_BEND_SIGN
	var sx := absf(rig.sprite.scale.x) if rig.sprite else 1.0
	var upper := preset.resolve_upper_arm_length(dominant) * sx
	var lower := preset.resolve_lower_arm_length(dominant) * sx
	var shoulder_local := rig.to_local(shoulder.global_position)
	var hand_local := rig.to_local(hand.global_position)
	var elbow_local := rig.to_local(elbow_global)
	var candidates: Array = ProceduralArmScript.ik_elbow_candidates(
		shoulder_local, hand_local, upper, lower, false
	)
	if candidates.size() < 2:
		return WeaponLimbPresetScript.DOMINANT_ELBOW_BEND_SIGN if dominant else WeaponLimbPresetScript.SUPPORT_ELBOW_BEND_SIGN
	var pick_a := elbow_local.distance_squared_to(candidates[0]) <= elbow_local.distance_squared_to(candidates[1])
	var auto = WeaponLimbPresetScript.DOMINANT_ELBOW_BEND_SIGN if dominant else WeaponLimbPresetScript.SUPPORT_ELBOW_BEND_SIGN
	return auto if pick_a else -auto
