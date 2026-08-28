extends RefCounted
class_name SpearIdleMotion

## Spear / idle1 sun-shield motion — raise, scan, lower phases.
## Isolated from walk/gather/club. Uses WeaponLimbPreset pose fields + timing only.

const IKUtils = preload("res://scripts/systems/ik_utils.gd")

## Phase timing (seconds) — shared with tuner_idle_preview.gd
const ARM2_RAISE_TRANSITION_SEC := 0.9
const ARM2_LOWER_TRANSITION_SEC := 1.05
const SCAN_POSE_A_HOLD_SEC := 1.1
const SCAN_REST_BETWEEN_CYCLES_SEC := 3.5
const HAND_SHADE_SLIDE_DISPLAY_PX := 34.0
const HAND_SHADE_SLIDE_SEC := 0.58

const RAISE_SAMPLE_BLEND := [
	0.0, 0.25, 0.5, 0.75, 1.0, 0.75, 0.5, 0.25, 0.0
]


static func raise_blend_from_elapsed(elapsed_sec: float, transition_sec: float = ARM2_RAISE_TRANSITION_SEC) -> float:
	if transition_sec <= 0.001:
		return 1.0
	return clampf(elapsed_sec / transition_sec, 0.0, 1.0)


static func smoothstep01(t: float) -> float:
	t = clampf(t, 0.0, 1.0)
	return t * t * (3.0 - 2.0 * t)


## Which side of the shoulder→hand line the elbow sits on (+1 / -1). Zero if degenerate.
static func elbow_side_sign(shoulder: Vector2, hand: Vector2, elbow: Vector2) -> float:
	var line := hand - shoulder
	if line.length_squared() < 0.01:
		return 0.0
	var perp := Vector2(-line.y, line.x).normalized()
	return signf((elbow - shoulder).dot(perp))


## Sample support elbow display px during raise/lower (display space).
static func sample_support_elbow_display(
	preset: WeaponLimbPreset,
	raise_blend: float,
	upper_len_px: float,
	lower_len_px: float,
	lowering: bool = false
) -> Vector2:
	if preset == null:
		return Vector2.ZERO
	if lowering and raise_blend < 0.999:
		return preset.resolve_support_elbow_display_for_idle_lower(
			raise_blend, 0.0, true, upper_len_px, lower_len_px
		)
	return preset.resolve_support_elbow_display_for_idle_raise(
		raise_blend, upper_len_px, lower_len_px
	)


## Assert raise arc is smooth and elbow side never flips. Returns error strings (empty = OK).
static func validate_raise_elbow_arc(
	preset: WeaponLimbPreset,
	upper_len_px: float = 120.0,
	lower_len_px: float = 120.0,
	max_step_px: float = 80.0
) -> Array[String]:
	var errors: Array[String] = []
	if preset == null or not preset.has_idle_arm2_raise_pose():
		return errors
	var rest_shoulder := preset.resolve_support_shoulder_idle_rest_px()
	var rest_hand := preset.resolve_support_hand_idle_rest_px()
	var prev_elbow := Vector2.ZERO
	var prev_side := 0.0
	var prev_blend := -1.0
	var got_sample := false
	for blend in RAISE_SAMPLE_BLEND:
		var lowering: bool = prev_blend >= 0.0 and blend < prev_blend and blend < 0.999
		var elbow := sample_support_elbow_display(
			preset, blend, upper_len_px, lower_len_px, lowering
		)
		if elbow.length_squared() < 0.01:
			prev_blend = blend
			continue
		got_sample = true
		if prev_elbow.length_squared() > 0.01 and elbow.distance_to(prev_elbow) > max_step_px:
			errors.append("spear idle raise teleport at blend %.2f step %.1f px" % [blend, elbow.distance_to(prev_elbow)])
		var shoulder := rest_shoulder.lerp(
			preset.resolve_support_shoulder_idle_raised_px(), blend
		)
		var hand := rest_hand.lerp(
			preset.resolve_support_hand_idle_raised_px(), blend
		)
		var side := elbow_side_sign(shoulder, hand, elbow)
		if side != 0.0:
			if prev_side != 0.0 and side != prev_side:
				errors.append("spear idle raise elbow side flip at blend %.2f" % blend)
			prev_side = side
		prev_elbow = elbow
		prev_blend = blend
	if not got_sample:
		errors.append("spear idle raise produced no elbow samples")
	return errors


static func support_elbow_display_for_raise(
	preset: WeaponLimbPreset,
	raise_blend: float,
	lowering: bool = false
) -> Vector2:
	if preset == null:
		return Vector2.ZERO
	return preset.resolve_support_elbow_display_for_idle_raise(
		raise_blend, preset.upper_arm_length, preset.lower_arm_length
	)


static func support_elbow_display_for_lower(
	preset: WeaponLimbPreset,
	lower_progress: float
) -> Vector2:
	if preset == null:
		return Vector2.ZERO
	return preset.resolve_support_elbow_display_for_idle_lower(
		lower_progress, 0.0, true, preset.upper_arm_length, preset.lower_arm_length
	)


static func support_elbow_display_for_rest(preset: WeaponLimbPreset) -> Vector2:
	if preset == null:
		return Vector2.ZERO
	return preset.resolve_support_elbow_display_for_idle_rest(
		preset.upper_arm_length, preset.lower_arm_length
	)


## Pure IK elbow from pole when preset has saved pole for idle rest.
static func support_elbow_global_from_pole(
	preset: WeaponLimbPreset,
	shoulder_global: Vector2,
	hand_global: Vector2,
	pole_display_px: Vector2,
	body_global_from_display: Callable,
	flip_h: bool
) -> Vector2:
	if preset == null or pole_display_px.length_squared() < 0.01:
		return shoulder_global
	var pole_global: Vector2 = body_global_from_display.call(pole_display_px)
	return IKUtils.calculate_elbow_from_pole(
		shoulder_global,
		hand_global,
		pole_global,
		preset.upper_arm_length,
		preset.lower_arm_length
	)
