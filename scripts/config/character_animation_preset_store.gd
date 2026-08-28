extends RefCounted
class_name CharacterAnimationPresetStore

## Unified animation clip storage and default seeding on WeaponLimbPreset.
## Uses duck-typed preset refs to avoid circular script loads with weapon_limb_preset.gd.

const CharacterAnimationClipScript = preload("res://scripts/config/character_animation_clip.gd")
const CharacterAnimationPoseScript = preload("res://scripts/config/character_animation_pose.gd")

const CLIP_IDLE := &"idle"
const CLIP_WALK := &"walk"
const CLIP_GATHER := &"gather"
const CLIP_WINDUP := &"windup"
const CLIP_STRIKE := &"strike"


static func ensure_all_clips(preset, registry: Node = null) -> void:
	if preset == null:
		return
	for clip_id in clips_for_holdable(preset.weapon_type):
		ensure_clip(preset, clip_id, registry)


static func clips_for_holdable(weapon_type: ResourceData.ResourceType) -> Array[StringName]:
	match weapon_type:
		ResourceData.ResourceType.WOOD, ResourceData.ResourceType.SPEAR:
			return [CLIP_IDLE, CLIP_WALK, CLIP_WINDUP, CLIP_STRIKE]
		ResourceData.ResourceType.AXE, ResourceData.ResourceType.PICK, ResourceData.ResourceType.OLDOWAN:
			return [CLIP_IDLE, CLIP_WALK, CLIP_GATHER]
		_:
			return [CLIP_IDLE, CLIP_WALK, CLIP_GATHER]


static func ensure_clip(preset, clip_id: StringName, registry: Node = null):
	var clip = get_clip(preset, clip_id)
	if clip != null:
		return clip
	clip = _create_default_clip(preset, clip_id, registry)
	set_clip(preset, clip)
	return clip


static func get_clip(preset, clip_id: StringName):
	if preset == null:
		return null
	for c in preset.animation_clips:
		if c != null and c.clip_id == clip_id:
			return c
	return null


static func set_clip(preset, clip) -> void:
	if preset == null or clip == null:
		return
	for i in preset.animation_clips.size():
		var existing = preset.animation_clips[i]
		if existing != null and existing.clip_id == clip.clip_id:
			preset.animation_clips[i] = clip
			return
	preset.animation_clips.append(clip)


static func reset_pose_to_default(
	preset,
	clip_id: StringName,
	pose_index: int,
	registry: Node = null
) -> void:
	var clip = ensure_clip(preset, clip_id, registry)
	var pose = _default_pose_for_clip(preset, clip_id, pose_index, registry)
	clip.set_pose_at_index(pose_index, pose)
	clip.saved = false
	if pose_index == 1:
		clip.pose_b_saved = false


static func mark_clip_saved(preset, clip_id: StringName, pose_b_saved: bool) -> void:
	var clip = get_clip(preset, clip_id)
	if clip == null:
		return
	clip.saved = true
	clip.pose_b_saved = pose_b_saved


static func _create_default_clip(preset, clip_id: StringName, registry: Node = null):
	var clip := CharacterAnimationClipScript.new()
	clip.clip_id = clip_id
	clip.duration_sec = _default_duration(clip_id)
	clip.pose_a = _default_pose_for_clip(preset, clip_id, 0, registry)
	clip.pose_b = _default_pose_for_clip(preset, clip_id, 1, registry)
	clip.saved = false
	clip.pose_b_saved = false
	if clip_id == CLIP_WALK and preset.weapon_type == ResourceData.ResourceType.WOOD:
		_apply_club_walk_mixed_defaults(preset, clip, registry)
	return clip


static func _default_duration(clip_id: StringName) -> float:
	match clip_id:
		CLIP_WALK:
			return 0.8
		CLIP_GATHER:
			return 1.0
		CLIP_WINDUP, CLIP_STRIKE:
			return 0.6
		_:
			return 2.0


static func _default_pose_for_clip(preset, clip_id: StringName, pose_index: int, registry: Node = null):
	var pose = _builtin_safe_pose(preset)
	if clip_id == CLIP_IDLE:
		return pose
	var same_idle = _copy_pose_from_clip(preset, CLIP_IDLE, pose_index, registry)
	if same_idle != null:
		return same_idle
	var none = _none_preset(registry)
	if none != null and none != preset:
		var none_clip = get_clip(none, clip_id)
		if none_clip != null:
			return none_clip.pose_at_index(pose_index).duplicate_pose()
	return pose


static func _copy_pose_from_clip(preset, clip_id: StringName, pose_index: int, registry: Node = null):
	var clip = get_clip(preset, clip_id)
	if clip == null and registry != null:
		var temp = preset.duplicate(true)
		ensure_clip(temp, clip_id, registry)
		clip = get_clip(temp, clip_id)
	if clip == null:
		return null
	return clip.pose_at_index(pose_index).duplicate_pose()


static func _apply_club_walk_mixed_defaults(preset, clip, registry: Node = null) -> void:
	var none = _none_preset(registry)
	if none == null:
		return
	var none_walk = get_clip(none, CLIP_WALK)
	if none_walk == null:
		ensure_clip(none, CLIP_WALK, registry)
		none_walk = get_clip(none, CLIP_WALK)
	var club_idle = get_clip(preset, CLIP_IDLE)
	if club_idle == null:
		ensure_clip(preset, CLIP_IDLE, registry)
		club_idle = get_clip(preset, CLIP_IDLE)
	if none_walk == null or club_idle == null:
		return
	for pose_index in [0, 1]:
		var pose = none_walk.pose_at_index(pose_index).duplicate_pose()
		var idle_pose = club_idle.pose_at_index(pose_index)
		pose.hand_weapon_px = idle_pose.hand_weapon_px
		pose.grip_on_art_px = idle_pose.grip_on_art_px
		pose.overlay_offset_px = idle_pose.overlay_offset_px
		pose.elbow_weapon_bend_sign = idle_pose.elbow_weapon_bend_sign
		clip.set_pose_at_index(pose_index, pose)


static func _builtin_safe_pose(preset):
	var pose = CharacterAnimationPoseScript.new()
	if preset == null:
		return pose
	pose.shoulder_weapon_px = preset.shoulder_offset_px
	pose.shoulder_support_px = preset.support_shoulder_offset_px
	pose.hand_weapon_px = preset.hand_grip_offset_px
	pose.hand_support_px = preset.support_hand_idle_offset_px
	pose.overlay_offset_px = preset.overlay_offset_idle_px
	pose.elbow_weapon_bend_sign = preset.weapon_elbow_bend_sign_override
	pose.elbow_support_bend_sign = preset.support_elbow_bend_sign_override
	pose.weapon_rotation_deg = preset.idle_rotation_deg
	return pose


static func _none_preset(registry: Node):
	if registry != null and registry.has_method("get_preset"):
		return registry.get_preset(ResourceData.ResourceType.NONE, "clansmen_1", 1)
	var wlp_script: GDScript = load("res://scripts/config/weapon_limb_preset.gd") as GDScript
	if wlp_script == null:
		return null
	return wlp_script.call("load_none_body_preset", 1)


static func apply_pose_to_arm_config(config, pose, preset) -> void:
	if config == null or pose == null or preset == null:
		return
	config.weapon_shoulder_offset_px = pose.resolved_shoulder_weapon_px(preset)
	config.shoulder_offset_left = pose.resolved_shoulder_support_px(preset)
	config.shoulder_offset_right = Vector2(-pose.resolved_shoulder_support_px(preset).x, pose.resolved_shoulder_support_px(preset).y)
	if (
		preset.weapon_type == ResourceData.ResourceType.WOOD
		and pose.grip_on_art_px.length_squared() > 0.0001
	):
		config.hand_grip_offset_px = pose.grip_on_art_px
	else:
		config.hand_grip_offset_px = pose.hand_weapon_px
	config.support_hand_idle_offset_px = pose.hand_support_px
	config.weapon_elbow_bend_sign_active = pose.elbow_weapon_bend_sign
	config.support_elbow_bend_sign_active = pose.elbow_support_bend_sign
