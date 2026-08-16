extends RefCounted
class_name TunerWalkPreview

## Walk preview for the animation tuner — body bounce, facing, and Pose 1 ↔ Pose 2 keyframes.

const CardVisualController = preload("res://scripts/systems/card_visual_controller.gd")
const PlaceholderCardRegistry = preload("res://scripts/config/placeholder_card_registry.gd")
const WalkArmMotion = preload("res://scripts/systems/walk_arm_motion.gd")

const DISPLAY_HEIGHT := 128.0

var direction := 0
var bounce_time := 0.0
var walk_phase := 0.0
var playing := false
var _pose_edit_active := false
var _pose_edit_b := false


func reset() -> void:
	direction = 0
	bounce_time = 0.0
	walk_phase = 0.0
	playing = false
	_pose_edit_active = false
	_pose_edit_b = false


func is_moving() -> bool:
	return direction != 0 or playing


func is_keyframe_playing() -> bool:
	return playing


func is_pose_edit_active() -> bool:
	return _pose_edit_active


func is_pose_edit_b() -> bool:
	return _pose_edit_active and _pose_edit_b


func set_direction(dir: int) -> void:
	direction = clampi(dir, -1, 1)


func set_playing(on: bool) -> void:
	playing = on
	if playing:
		_pose_edit_active = false
		_pose_edit_b = false
		if direction == 0:
			direction = 1


func set_pose_edit(active: bool, pose_b: bool = false) -> void:
	_pose_edit_active = active
	_pose_edit_b = pose_b
	playing = false
	if active:
		direction = 0


func tick(delta: float) -> void:
	if playing and direction == 0:
		direction = 1
	if direction == 0:
		walk_phase = 0.0
		return
	walk_phase += delta * PlaceholderCardRegistry.effective_walk_bounce_speed()
	if walk_phase > TAU:
		walk_phase = fmod(walk_phase, TAU)


func swing_phase() -> float:
	return cycle_phase()


func cycle_phase() -> float:
	if not is_moving():
		return 0.0
	return WalkArmMotion.cycle_phase_from_bounce(bounce_time)


func arm_swing_offset_rig(_dominant: bool) -> Vector2:
	return Vector2.ZERO


static func mannequin_foot_y(layout = null) -> float:
	if layout:
		return layout.foot_y
	return -DISPLAY_HEIGHT * 0.5


static func mannequin_scale(layout = null) -> float:
	if layout:
		return layout.sprite_scale
	return DISPLAY_HEIGHT / 816.0
