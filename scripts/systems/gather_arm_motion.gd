extends RefCounted
class_name GatherArmMotion

## Full gather sequence: idle stand → bend over → arm picks → stand idle (loop).
## Rig-local display px. Hands stay on arm reach during picks.

const BODY_BEND_PEAK_RAD := 0.14
const HEAD_FORWARD_PEAK_PX := 7.0
## Slower cycle — less rushed than 0.34 (tuner + gameplay share this module).
const CYCLE_SPEED := 0.26
const ARM_PHASE_OFFSET := 0.5
const DOM_REACH_SLACK_RATIO := 0.10
const SUPPORT_REACH_SLACK_RATIO := 0.14
## Normalized cycle timeline (sum ≤ 1.0).
const SEQ_BEND_IN_END := 0.20
const SEQ_ARM_END := 0.80
const SEQ_BEND_OUT_END := 0.98
## Reach↔pull oscillations while bent (continuous sine — no fmod keyframe snaps).
const ARM_PICK_CYCLES := 1.35
## Edit hold: full bend at start of arm-work window.
const EDIT_HOLD_PHASE := 0.24


static func cycle_phase_from_time(cycle_time: float) -> float:
	return fmod(cycle_time * CYCLE_SPEED, 1.0)


static func reach_slack_ratio(dominant: bool) -> float:
	return DOM_REACH_SLACK_RATIO if dominant else SUPPORT_REACH_SLACK_RATIO


static func body_bend_amount(cycle_phase: float) -> float:
	return _bend_envelope(cycle_phase)


static func body_bend_rad(cycle_phase: float) -> float:
	return BODY_BEND_PEAK_RAD * body_bend_amount(cycle_phase)


static func head_forward_display_px(cycle_phase: float) -> float:
	return HEAD_FORWARD_PEAK_PX * body_bend_amount(cycle_phase)


## 0–1 while bent and picking; -1 during idle stand or bend transitions.
static func arm_work_phase(cycle_phase: float) -> float:
	if cycle_phase < SEQ_BEND_IN_END or cycle_phase >= SEQ_ARM_END:
		return -1.0
	var raw := (cycle_phase - SEQ_BEND_IN_END) / (SEQ_ARM_END - SEQ_BEND_IN_END)
	return _smootherstep(clampf(raw, 0.0, 1.0))


static func is_arm_picking(cycle_phase: float) -> bool:
	return arm_work_phase(cycle_phase) >= 0.0


static func hand_offset_between_keyframes(
	reach_offset: Vector2,
	pull_offset: Vector2,
	arm_work: float,
	dominant: bool
) -> Vector2:
	if reach_offset.length_squared() < 1.0 or pull_offset.length_squared() < 1.0:
		return reach_offset
	if arm_work < 0.0:
		return reach_offset
	var phase_rad := arm_work * ARM_PICK_CYCLES * TAU
	if not dominant:
		phase_rad += ARM_PHASE_OFFSET * TAU
	## 0 at reach, 1 at pull, continuous — no hard keyframe plateaus.
	var blend := (1.0 - cos(phase_rad)) * 0.5
	return reach_offset.lerp(pull_offset, _smootherstep(blend))


static func blend_idle_to_reach_offset(
	idle_offset: Vector2,
	reach_offset: Vector2,
	cycle_phase: float
) -> Vector2:
	var bend := body_bend_amount(cycle_phase)
	return idle_offset.lerp(reach_offset, _smootherstep(bend))


## C2 smoothstep — softer than quadratic smoothstep (less snap at keyframes).
static func _smootherstep(t: float) -> float:
	t = clampf(t, 0.0, 1.0)
	return t * t * t * (t * (t * 6.0 - 15.0) + 10.0)


static func _smooth(t: float) -> float:
	return _smootherstep(t)


## Single smooth bend bump (0 → 1 → 0) — avoids plateau kinks from piecewise hold.
static func _bend_envelope(phase: float) -> float:
	if phase >= SEQ_BEND_OUT_END:
		return 0.0
	var t := clampf(phase / SEQ_BEND_OUT_END, 0.0, 1.0)
	return sin(t * PI)
