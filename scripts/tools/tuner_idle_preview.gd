extends RefCounted
class_name TunerIdlePreview

## Idle variants: **idle** = breathe/sway only; **idle1** = look-around + arm-2 sun-shield raise.
const VARIANT_BASE := "idle"
const VARIANT_ID := "idle1"
const BREATH_SPEED := 2.35
const SWAY_SPEED := 1.25
## Tuner idle preview amplitudes (display px) — subtle but visibly alive; club follows body + slight lag.
const BODY_BOUNCE_DISPLAY_PX := 0.48
const HEAD_BOB_DISPLAY_PX := 0.52
const WEAPON_EXTRA_BOUNCE_DISPLAY_PX := 0.14
const BODY_SWAY_RAD := 0.0035
const LOOK_HOLD_SEC := 5.0
const ARM2_RAISE_HOLD_SEC := 1.8
const ARM2_RAISE_TRANSITION_SEC := 0.9
const ARM2_RAISE_EVERY_LOOKS_MIN := 3
const ARM2_RAISE_EVERY_LOOKS_MAX := 5

enum _Arm2RaisePhase { REST, RAISING, HOLD, LOWERING }

var playing := false
var breath_time := 0.0
var _look_right := true
var _look_timer := 0.0
var _arm2_phase: _Arm2RaisePhase = _Arm2RaisePhase.REST
var _arm2_phase_time := 0.0
var _arm2_raise_blend := 0.0
var _looks_until_arm_raise := 3
var _variant_id := VARIANT_BASE
var _lookaround_enabled := false


func get_variant_id() -> String:
	return _variant_id


func set_variant(variant_id: String) -> void:
	_variant_id = variant_id
	_lookaround_enabled = variant_id == VARIANT_ID
	reset()


func reset() -> void:
	breath_time = 0.0
	_look_right = true
	_look_timer = 0.0
	_reset_arm2_raise()


func _reset_arm2_raise() -> void:
	_arm2_phase = _Arm2RaisePhase.REST
	_arm2_phase_time = 0.0
	_arm2_raise_blend = 0.0
	_looks_until_arm_raise = randi_range(ARM2_RAISE_EVERY_LOOKS_MIN, ARM2_RAISE_EVERY_LOOKS_MAX)


func set_playing(on: bool) -> void:
	playing = on
	if not playing:
		reset()


func tick(delta: float) -> void:
	if not playing:
		return
	breath_time += delta
	if not _lookaround_enabled:
		_look_right = true
		_arm2_raise_blend = 0.0
		return
	_look_timer += delta
	if _look_timer >= LOOK_HOLD_SEC:
		_look_timer = 0.0
		_look_right = not _look_right
		_on_head_look_flip()
	_tick_arm2_raise(delta)


func _on_head_look_flip() -> void:
	if _should_raise_arm_for_look():
		_arm2_phase = _Arm2RaisePhase.RAISING
		_arm2_phase_time = 0.0
	elif _arm2_phase == _Arm2RaisePhase.HOLD or _arm2_phase == _Arm2RaisePhase.RAISING:
		_arm2_phase = _Arm2RaisePhase.LOWERING
		_arm2_phase_time = 0.0


func _should_raise_arm_for_look() -> bool:
	_looks_until_arm_raise -= 1
	if _looks_until_arm_raise > 0:
		return false
	_looks_until_arm_raise = randi_range(ARM2_RAISE_EVERY_LOOKS_MIN, ARM2_RAISE_EVERY_LOOKS_MAX)
	return true


func _tick_arm2_raise(delta: float) -> void:
	match _arm2_phase:
		_Arm2RaisePhase.REST:
			_arm2_raise_blend = 0.0
		_Arm2RaisePhase.RAISING:
			_arm2_phase_time += delta
			var t := clampf(_arm2_phase_time / ARM2_RAISE_TRANSITION_SEC, 0.0, 1.0)
			_arm2_raise_blend = _smoothstep(t)
			if t >= 1.0:
				_arm2_phase = _Arm2RaisePhase.HOLD
				_arm2_phase_time = 0.0
		_Arm2RaisePhase.HOLD:
			_arm2_phase_time += delta
			_arm2_raise_blend = 1.0
			if _arm2_phase_time >= ARM2_RAISE_HOLD_SEC:
				_arm2_phase = _Arm2RaisePhase.LOWERING
				_arm2_phase_time = 0.0
		_Arm2RaisePhase.LOWERING:
			_arm2_phase_time += delta
			var t := clampf(_arm2_phase_time / ARM2_RAISE_TRANSITION_SEC, 0.0, 1.0)
			_arm2_raise_blend = 1.0 - _smoothstep(t)
			if t >= 1.0:
				_arm2_phase = _Arm2RaisePhase.REST
				_arm2_phase_time = 0.0


func arm2_raise_blend() -> float:
	return _arm2_raise_blend if playing else 0.0


func _smoothstep(t: float) -> float:
	return t * t * (3.0 - 2.0 * t)


func body_bounce_offset(amplitude_local: float) -> float:
	if not playing:
		return 0.0
	return sin(breath_time * BREATH_SPEED) * amplitude_local


func head_bob_offset(amplitude_local: float) -> float:
	if not playing:
		return 0.0
	return sin(breath_time * BREATH_SPEED * 1.15 - 0.4) * amplitude_local


func body_sway_rad() -> float:
	if not playing:
		return 0.0
	return sin(breath_time * SWAY_SPEED) * BODY_SWAY_RAD


func head_look_right() -> bool:
	return _look_right if playing else true


func weapon_bounce_offset(amplitude_local: float) -> float:
	if not playing:
		return 0.0
	return sin(breath_time * BREATH_SPEED - 0.55) * amplitude_local * 0.65
