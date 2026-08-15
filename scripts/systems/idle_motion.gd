extends RefCounted
class_name IdleMotion

## Idle animation motion interpreter — breathe, sway, optional lookaround.
## This file owns ALL idle motion logic. Changing this cannot affect walk, gather, etc.

const IKUtils = preload("res://scripts/systems/ik_utils.gd")

## Base idle (breathe + sway only)
const BREATH_SPEED := 2.35
const SWAY_SPEED := 1.25
const BODY_BOUNCE_DISPLAY_PX := 0.48
const HEAD_BOB_DISPLAY_PX := 0.52
const WEAPON_EXTRA_BOUNCE_DISPLAY_PX := 0.14
const BODY_SWAY_RAD := 0.0035

## Idle1 variant (lookaround + off-hand raise) — will be added after basic idle works
const LOOK_HOLD_SEC := 5.0
const ARM2_RAISE_HOLD_SEC := 1.8
const ARM2_RAISE_TRANSITION_SEC := 0.9
const ARM2_LOWER_TRANSITION_SEC := 1.05
const SCAN_POSE_A_HOLD_SEC := 1.1
const SCAN_REST_BETWEEN_CYCLES_SEC := 3.5
const SCAN_FLIPS_BEFORE_LOWER := 2
const HAND_SHADE_SLIDE_DISPLAY_PX := 34.0
const HAND_SHADE_SLIDE_SEC := 0.58

var breath_time := 0.0
var variant_id := "idle"  # "idle" = base, "idle1" = lookaround


func reset() -> void:
	breath_time = 0.0


func update(delta: float) -> void:
	breath_time += delta


## Get body bounce offset (vertical display px) for current breath phase.
func get_body_bounce_offset() -> float:
	return sin(breath_time * BREATH_SPEED) * BODY_BOUNCE_DISPLAY_PX


## Get head bob offset (vertical display px) for current breath phase.
func get_head_bob_offset() -> float:
	return sin(breath_time * BREATH_SPEED) * HEAD_BOB_DISPLAY_PX


## Get body sway rotation (radians) for current breath phase.
func get_body_sway_rotation() -> float:
	return sin(breath_time * SWAY_SPEED) * BODY_SWAY_RAD


## Get weapon extra bounce for club/spear carry (follows body with slight lag).
func get_weapon_extra_bounce() -> float:
	return sin(breath_time * BREATH_SPEED - 0.1) * WEAPON_EXTRA_BOUNCE_DISPLAY_PX


## Calculate dominant arm elbow position for idle carry.
## Uses preset rest pose + IK from saved pole.
static func calculate_dominant_elbow(
	preset: WeaponLimbPreset,
	shoulder_global: Vector2,
	hand_global: Vector2,
	flip_h: bool
) -> Vector2:
	var pole_display := preset.weapon_elbow_pole_idle_px
	if pole_display.length_squared() < 0.01:
		# No pole saved, use bend sign fallback
		var bend := preset.weapon_elbow_bend_sign_override
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


## Calculate support arm elbow position for idle carry.
## Uses preset rest pose + IK from saved pole.
static func calculate_support_elbow(
	preset: WeaponLimbPreset,
	shoulder_global: Vector2,
	hand_global: Vector2,
	flip_h: bool
) -> Vector2:
	var pole_display := preset.support_elbow_pole_idle_px
	if pole_display.length_squared() < 0.01:
		# No pole saved, use bend sign fallback
		var bend := preset.support_elbow_bend_sign_override
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
