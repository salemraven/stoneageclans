extends RefCounted
class_name WalkArmMotion

## Walk 1 animation motion interpreter — pendulum swing between Pose A and B.
## This file owns ALL walk motion logic. Changing this cannot affect idle, gather, etc.
## Clock syncs with body bounce. One full Pose 1↔Pose 2↔Pose 1 takes two body bobs.

const WalkArmSwingScript = preload("res://scripts/systems/walk_arm_swing.gd")
const IKUtils = preload("res://scripts/systems/ik_utils.gd")

## Body sin() period is TAU rad. Arms use this many body periods per full swing.
const BOUNCE_CYCLES_PER_ARM_CYCLE := 2.0
## Legacy standalone clock (tests only) — live preview + in-game use cycle_phase_from_bounce().
const CYCLE_SPEED := 0.34
const ARM_PHASE_OFFSET := 0.5
const DOM_REACH_SLACK_RATIO := 0.28
const SUPPORT_REACH_SLACK_RATIO := 0.32


static func cycle_phase_from_bounce(bounce_time: float) -> float:
	var lagged := bounce_time - WalkArmSwingScript.SWING_PHASE_LAG_RAD
	return fposmod(lagged / (TAU * BOUNCE_CYCLES_PER_ARM_CYCLE), 1.0)


static func cycle_phase_from_time(cycle_time: float) -> float:
	return fmod(cycle_time * CYCLE_SPEED, 1.0)


static func reach_slack_ratio(dominant: bool) -> float:
	return DOM_REACH_SLACK_RATIO if dominant else SUPPORT_REACH_SLACK_RATIO


static func hand_offset_between_keyframes(
	pose_a_offset: Vector2,
	pose_b_offset: Vector2,
	cycle_phase: float,
	_dominant: bool = true
) -> Vector2:
	## Pose 1 / Pose 2 are full-body snapshots (R fwd + L back vs swapped). Same phase for both arms.
	return body_snapshot_between_keyframes(pose_a_offset, pose_b_offset, cycle_phase)


## Pendulum blend — same harmonic as body sin(), no smootherstep (that rushed the mid-swing).
static func body_snapshot_blend(cycle_phase: float) -> float:
	return (1.0 - cos(cycle_phase * TAU)) * 0.5


static func body_snapshot_between_keyframes(
	pose_a: Vector2,
	pose_b: Vector2,
	cycle_phase: float
) -> Vector2:
	if pose_a.length_squared() < 1.0:
		return pose_a
	if pose_b.length_squared() < 1.0:
		return pose_a
	return pose_a.lerp(pose_b, body_snapshot_blend(cycle_phase))


static func keyframe_blend(cycle_phase: float, dominant: bool) -> float:
	var phase_rad := cycle_phase * TAU
	if not dominant:
		phase_rad += ARM_PHASE_OFFSET * TAU
	return (1.0 - cos(phase_rad)) * 0.5


static func vector_between_keyframes(
	pose_a: Vector2,
	pose_b: Vector2,
	cycle_phase: float,
	dominant: bool
) -> Vector2:
	if pose_a.length_squared() < 1.0:
		return pose_a
	if pose_b.length_squared() < 1.0:
		return pose_a
	return pose_a.lerp(pose_b, keyframe_blend(cycle_phase, dominant))


## Calculate dominant arm elbow for walk cycle.
## Interpolates between Pose A and Pose B elbow poles based on cycle phase.
static func calculate_dominant_elbow(
	preset: WeaponLimbPreset,
	shoulder_global: Vector2,
	hand_global: Vector2,
	cycle_phase: float,
	flip_h: bool
) -> Vector2:
	var pole_a := preset.walk1_weapon_elbow_pole_px
	var pole_b := preset.walk1_pull_weapon_elbow_pole_px if preset.walk1_pose_b_saved else pole_a
	
	# Interpolate pole position based on cycle phase
	var blend := body_snapshot_blend(cycle_phase)
	var pole_display := pole_a.lerp(pole_b, blend)
	
	if pole_display.length_squared() < 0.01:
		# No pole saved, use bend sign fallback
		var bend_a := preset.walk1_weapon_elbow_bend_sign_override
		var bend_b := preset.walk1_pull_weapon_elbow_bend_sign_override if preset.walk1_pose_b_saved else bend_a
		var bend := lerpf(bend_a, bend_b, blend)
		if flip_h:
			bend = -bend
		return IKUtils.calculate_elbow_from_bend_sign(
			shoulder_global,
			hand_global,
			bend,
			preset.upper_arm_length,
			preset.lower_arm_length
		)
	
	# Convert pole from display px to global
	var pole_global := _display_px_to_global(pole_display, shoulder_global, flip_h)
	return IKUtils.calculate_elbow_from_pole(
		shoulder_global,
		hand_global,
		pole_global,
		preset.upper_arm_length,
		preset.lower_arm_length
	)


## Calculate support arm elbow for walk cycle.
## Interpolates between Pose A and Pose B elbow poles based on cycle phase.
static func calculate_support_elbow(
	preset: WeaponLimbPreset,
	shoulder_global: Vector2,
	hand_global: Vector2,
	cycle_phase: float,
	flip_h: bool
) -> Vector2:
	var pole_a := preset.walk1_support_elbow_pole_px
	var pole_b := preset.walk1_pull_support_elbow_pole_px if preset.walk1_pose_b_saved else pole_a
	
	# Interpolate pole position based on cycle phase
	var blend := body_snapshot_blend(cycle_phase)
	var pole_display := pole_a.lerp(pole_b, blend)
	
	if pole_display.length_squared() < 0.01:
		# No pole saved, use bend sign fallback
		var bend_a := preset.walk1_support_elbow_bend_sign_override
		var bend_b := preset.walk1_pull_support_elbow_bend_sign_override if preset.walk1_pose_b_saved else bend_a
		var bend := lerpf(bend_a, bend_b, blend)
		if flip_h:
			bend = -bend
		return IKUtils.calculate_elbow_from_bend_sign(
			shoulder_global,
			hand_global,
			bend,
			preset.upper_arm_length,
			preset.lower_arm_length
		)
	
	# Convert pole from display px to global
	var pole_global := _display_px_to_global(pole_display, shoulder_global, flip_h)
	return IKUtils.calculate_elbow_from_pole(
		shoulder_global,
		hand_global,
		pole_global,
		preset.upper_arm_length,
		preset.lower_arm_length
	)


## Helper: convert display px to global coordinates for IK calculation.
## NOTE: This is a stub — proper implementation needs body transform context.
static func _display_px_to_global(display_px: Vector2, reference_global: Vector2, _flip_h: bool) -> Vector2:
	# Simplified conversion — real implementation needs body sprite scale/position
	return reference_global + display_px
