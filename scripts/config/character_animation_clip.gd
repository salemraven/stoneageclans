extends Resource
class_name CharacterAnimationClip

## Two-pose animation unit — Pose 1 and Pose 2 with shared timing.

const CharacterAnimationPoseScript = preload("res://scripts/config/character_animation_pose.gd")
const SelfScript = preload("res://scripts/config/character_animation_clip.gd")

@export var clip_id: StringName = &"idle"
@export var pose_a: Resource
@export var pose_b: Resource
@export var duration_sec: float = 1.0
@export var saved: bool = false
@export var pose_b_saved: bool = false


func _init() -> void:
	if pose_a == null:
		pose_a = CharacterAnimationPoseScript.new()
	if pose_b == null:
		pose_b = CharacterAnimationPoseScript.new()


func duplicate_clip():
	var copy = SelfScript.new()
	copy.clip_id = clip_id
	copy.pose_a = _pose_a().duplicate_pose()
	copy.pose_b = _pose_b().duplicate_pose()
	copy.duration_sec = duration_sec
	copy.saved = saved
	copy.pose_b_saved = pose_b_saved
	return copy


func pose_at_index(pose_index: int):
	if pose_index == 1:
		return _pose_b()
	return _pose_a()


func set_pose_at_index(pose_index: int, pose) -> void:
	if pose_index == 1:
		pose_b = pose
	else:
		pose_a = pose


func both_poses_saved() -> bool:
	return saved and pose_b_saved


func _pose_a():
	if pose_a == null:
		pose_a = CharacterAnimationPoseScript.new()
	return pose_a


func _pose_b():
	if pose_b == null:
		pose_b = CharacterAnimationPoseScript.new()
	return pose_b
