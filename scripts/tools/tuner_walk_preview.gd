extends RefCounted
class_name TunerWalkPreview

## Arrow-key walk preview for the animation tuner (body bounce + facing, no card spritesheet).

const CardVisualController = preload("res://scripts/systems/card_visual_controller.gd")
const PlaceholderCardRegistry = preload("res://scripts/config/placeholder_card_registry.gd")
const WalkArmSwing = preload("res://scripts/systems/walk_arm_swing.gd")

const DISPLAY_HEIGHT := 128.0

var direction := 0
var bounce_time := 0.0
var walk_phase := 0.0


func reset() -> void:
	direction = 0
	bounce_time = 0.0
	walk_phase = 0.0


func is_moving() -> bool:
	return direction != 0


func set_direction(dir: int) -> void:
	direction = clampi(dir, -1, 1)


func tick(delta: float) -> void:
	if not is_moving():
		walk_phase = 0.0
		return
	walk_phase += delta * PlaceholderCardRegistry.effective_walk_bounce_speed()
	if walk_phase > TAU:
		walk_phase = fmod(walk_phase, TAU)


func swing_phase() -> float:
	return WalkArmSwing.swing_phase_from_bounce(bounce_time) if is_moving() else 0.0


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
