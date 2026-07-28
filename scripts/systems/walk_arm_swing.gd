extends RefCounted
class_name WalkArmSwing

## Humanoid walk arm swing — travel-aligned push + shoulder arc (rig-local px).
## Keeps natural arm length while letting hands move forward/back along travel (+X when moving right).

const DOM_TRAVEL_FORWARD_PX := 32.0
const DOM_TRAVEL_BACK_PX := 26.0
const SUPPORT_TRAVEL_FORWARD_PX := 24.0
const SUPPORT_TRAVEL_BACK_PX := 48.0
const DOM_ARC_FORWARD_DEG := 18.0
const DOM_ARC_BACK_DEG := 14.0
const SUPPORT_ARC_FORWARD_DEG := 32.0
const SUPPORT_ARC_BACK_DEG := 14.0
const DOM_REACH_SLACK_RATIO := 0.18
const SUPPORT_REACH_SLACK_RATIO := 0.30
## Arm 2: pendulum-first — one smooth beat per step, not 2× vertical bob.
const SUPPORT_VERT_SWAY_PX := 2.5
## Spear carry: subtle vertical bob on the main walk beat — minimal forward/back (unlike club swing).
const SPEAR_DOM_TRAVEL_SCALE := 0.08
const SPEAR_DOM_ARC_SCALE := 0.12
const SPEAR_DOM_VERT_SWAY_PX := 11.0
const SPEAR_DOM_LENGTH_BREATHE_SCALE := 0.2
## Small phase lag so arms trail the torso on the same walk beat (see PlaceholderCardRegistry.WALK_RHYTHM_SPEED_SCALE).
const SWING_PHASE_LAG_RAD := 0.22
const HARMONIC_MIX := 0.02
const LENGTH_BREATHE := 0.08
const VERT_SWAY_PX := 5.0


static func swing_phase_from_bounce(bounce_time: float) -> float:
	return bounce_time - SWING_PHASE_LAG_RAD


static func reach_slack_ratio(dominant: bool) -> float:
	return DOM_REACH_SLACK_RATIO if dominant else SUPPORT_REACH_SLACK_RATIO


## Swing target in rig-local display px relative to the shoulder.
static func swing_hand_local_offset(
	rest_offset: Vector2,
	cycle_phase: float,
	dominant: bool,
	travel_sign: float = 1.0,
	weapon_type: ResourceData.ResourceType = ResourceData.ResourceType.NONE
) -> Vector2:
	if rest_offset.length_squared() < 1.0:
		return rest_offset
	var arm_phase := cycle_phase + (0.0 if dominant else PI)
	var spear_carry := _is_spear_dominant_carry(weapon_type, dominant)
	var wave := _shaped_wave(arm_phase) if dominant else _support_swing_wave(arm_phase)
	var travel := Vector2(travel_sign, 0.0)
	var travel_fwd := DOM_TRAVEL_FORWARD_PX if dominant else SUPPORT_TRAVEL_FORWARD_PX
	var travel_back := DOM_TRAVEL_BACK_PX if dominant else SUPPORT_TRAVEL_BACK_PX
	var arc_fwd := DOM_ARC_FORWARD_DEG if dominant else SUPPORT_ARC_FORWARD_DEG
	var arc_back := DOM_ARC_BACK_DEG if dominant else SUPPORT_ARC_BACK_DEG
	if spear_carry:
		travel_fwd *= SPEAR_DOM_TRAVEL_SCALE
		travel_back *= SPEAR_DOM_TRAVEL_SCALE
		arc_fwd *= SPEAR_DOM_ARC_SCALE
		arc_back *= SPEAR_DOM_ARC_SCALE
	var travel_push := (travel_fwd if wave >= 0.0 else -travel_back) * absf(wave)
	var arc_deg := (arc_fwd if wave >= 0.0 else arc_back) * wave
	var rest_len := rest_offset.length()
	var base_angle := rest_offset.angle()
	var breathe := LENGTH_BREATHE * (SPEAR_DOM_LENGTH_BREATHE_SCALE if spear_carry else 1.0)
	# Arm 2: constant reach during swing — length breathe jerks the elbow through IK.
	var len_scale := 1.0
	if dominant and not spear_carry:
		len_scale = 1.0 + breathe * (1.0 - absf(wave))
	var rotated := Vector2.from_angle(base_angle + deg_to_rad(arc_deg)) * rest_len * len_scale
	var vert := 0.0
	if spear_carry:
		# Same _shaped_wave beat as support travel — one smooth cycle per step, not 2× vertical frequency.
		vert = wave * SPEAR_DOM_VERT_SWAY_PX
	elif dominant:
		var vert_raw := sin(arm_phase * 2.0)
		vert = signf(vert_raw) * pow(absf(vert_raw), 0.75) * VERT_SWAY_PX
	else:
		# Arm 2 pendulum: forward/back + shoulder arc; minimal vertical (no 2× bob).
		vert = wave * SUPPORT_VERT_SWAY_PX
	return rotated + travel * travel_push + Vector2(0.0, vert)


static func _is_spear_dominant_carry(
	weapon_type: ResourceData.ResourceType,
	dominant: bool
) -> bool:
	return dominant and weapon_type == ResourceData.ResourceType.SPEAR


static func travel_axis_offset(
	rest_offset: Vector2,
	cycle_phase: float,
	dominant: bool,
	travel_sign: float = 1.0,
	weapon_type: ResourceData.ResourceType = ResourceData.ResourceType.NONE
) -> float:
	var arm_phase := cycle_phase + (0.0 if dominant else PI)
	var wave := _shaped_wave(arm_phase)
	var travel_fwd := DOM_TRAVEL_FORWARD_PX if dominant else SUPPORT_TRAVEL_FORWARD_PX
	var travel_back := DOM_TRAVEL_BACK_PX if dominant else SUPPORT_TRAVEL_BACK_PX
	if _is_spear_dominant_carry(weapon_type, dominant):
		travel_fwd *= SPEAR_DOM_TRAVEL_SCALE
		travel_back *= SPEAR_DOM_TRAVEL_SCALE
	var travel_push := (travel_fwd if wave >= 0.0 else -travel_back) * absf(wave)
	return travel_push * travel_sign


static func _shaped_wave(phase: float) -> float:
	var base := sin(phase)
	# Softer peaks/troughs — less snappy reversal at forward/back extremes.
	var softened := signf(base) * pow(absf(base), 0.72)
	var harmonic := sin(phase * 2.0 + 0.35) * HARMONIC_MIX
	return clampf(softened + harmonic, -1.0, 1.0)


static func _support_swing_wave(phase: float) -> float:
	## Arm 2 pendulum — softer reversal, no harmonic (smoother elbow IK).
	var base := sin(phase)
	return signf(base) * pow(absf(base), 0.88)
