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
const ARM2_LOWER_TRANSITION_SEC := 1.05
const SCAN_POSE_A_HOLD_SEC := 1.1
const SCAN_REST_BETWEEN_CYCLES_SEC := 3.5
const SCAN_FLIPS_BEFORE_LOWER := 2
const ARM2_RAISE_EVERY_LOOKS_MIN := 3
const ARM2_RAISE_EVERY_LOOKS_MAX := 5
## Off-hand slides sideways with head look while raised (display px, body space pre-flip).
const HAND_SHADE_SLIDE_DISPLAY_PX := 34.0
const HAND_SHADE_SLIDE_SEC := 0.58

enum _Arm2RaisePhase { REST, RAISING, HOLD, LOWERING }

var playing := false
var breath_time := 0.0
var _look_right := true
var _look_timer := 0.0
var _look_hold_sec := LOOK_HOLD_SEC
var _arm2_phase: _Arm2RaisePhase = _Arm2RaisePhase.REST
var _arm2_phase_time := 0.0
var _arm2_raise_blend := 0.0
var _hand_shade_slide_amount := 0.0
var _looks_until_arm_raise := 3
var _scan_look_count := 0
var _rest_pause_time := 0.0
var _variant_id := VARIANT_BASE
var _lookaround_enabled := false
var _keep_raised_while_scanning := false
var _pose_edit_active := false
var _pose_edit_key := "a"  ## "a" = hand up + head forward; "b" = hand up + head back


func is_pose_edit_active() -> bool:
	return _pose_edit_active


func is_pose_edit_b() -> bool:
	return _pose_edit_active and _pose_edit_key == "b"


func set_pose_edit(active: bool, key: String = "a") -> void:
	_pose_edit_active = active
	_pose_edit_key = "b" if key == "b" else "a"
	if not active:
		return
	_arm2_phase = _Arm2RaisePhase.HOLD
	_arm2_phase_time = 0.0
	_arm2_raise_blend = 1.0
	_look_right = _pose_edit_key == "a"
	_hand_shade_slide_amount = 0.0 if _pose_edit_key == "a" else 1.0
	_look_timer = 0.0


func get_variant_id() -> String:
	return _variant_id


func set_variant(variant_id: String) -> void:
	_variant_id = variant_id
	_lookaround_enabled = variant_id == VARIANT_ID
	reset()


func set_look_hold_sec(sec: float) -> void:
	_look_hold_sec = maxf(sec, 0.75)


func prime_arm_raise_soon() -> void:
	## Legacy: next head flip schedules raise. Prefer begin_sun_shield_raise() for spear idle.
	_looks_until_arm_raise = 1


func set_sun_shield_scan_mode(on: bool) -> void:
	## Arm rises first; head look-around + hand slide while up (spear idle / horizon scan).
	_keep_raised_while_scanning = on


func begin_sun_shield_raise() -> void:
	if not _lookaround_enabled:
		return
	if _arm2_phase == _Arm2RaisePhase.REST:
		_arm2_phase = _Arm2RaisePhase.RAISING
		_arm2_phase_time = 0.0
	_looks_until_arm_raise = randi_range(ARM2_RAISE_EVERY_LOOKS_MIN, ARM2_RAISE_EVERY_LOOKS_MAX)
	_look_timer = 0.0


func begin_sun_shield_raise_if_idle() -> void:
	if _arm2_phase == _Arm2RaisePhase.REST:
		begin_sun_shield_raise()


func reset() -> void:
	if _pose_edit_active:
		return
	breath_time = 0.0
	_look_right = true
	_look_timer = 0.0
	_hand_shade_slide_amount = 0.0
	_reset_arm2_raise()


func _reset_arm2_raise() -> void:
	_arm2_phase = _Arm2RaisePhase.REST
	_arm2_phase_time = 0.0
	_arm2_raise_blend = 0.0
	_hand_shade_slide_amount = 0.0
	_scan_look_count = 0
	_rest_pause_time = 0.0
	_looks_until_arm_raise = randi_range(ARM2_RAISE_EVERY_LOOKS_MIN, ARM2_RAISE_EVERY_LOOKS_MAX)


func set_playing(on: bool) -> void:
	playing = on
	if not playing and not _pose_edit_active:
		reset()


func tick(delta: float) -> void:
	if not playing:
		return
	breath_time += delta
	if not _lookaround_enabled:
		_look_right = true
		_arm2_raise_blend = 0.0
		return
	if _head_look_flips_enabled():
		_look_timer += delta
		if _look_timer >= _look_hold_sec:
			_look_timer = 0.0
			_look_right = not _look_right
			_on_head_look_flip()
	else:
		_look_timer = 0.0
	_tick_arm2_raise(delta)


func _head_look_flips_enabled() -> bool:
	if _arm2_phase == _Arm2RaisePhase.LOWERING or _arm2_phase == _Arm2RaisePhase.RAISING:
		return false
	## Shield eyes before scanning the horizon — no head flip while arm is down.
	if _keep_raised_while_scanning:
		return _arm2_raise_blend >= 0.88
	return true


func _on_head_look_flip() -> void:
	if _keep_raised_while_scanning:
		if _arm2_raise_blend >= 0.88:
			_scan_look_count += 1
			## Back at pose A after forward → back → forward — hold briefly, then lower.
			if _scan_look_count >= SCAN_FLIPS_BEFORE_LOWER and _look_right:
				_arm2_phase_time = 0.0
		return
	if _should_raise_arm_for_look():
		_arm2_phase = _Arm2RaisePhase.RAISING
		_arm2_phase_time = 0.0
	elif (
		not _keep_raised_while_scanning
		and (_arm2_phase == _Arm2RaisePhase.HOLD or _arm2_phase == _Arm2RaisePhase.RAISING)
	):
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
			if _keep_raised_while_scanning and playing:
				_rest_pause_time += delta
				if _rest_pause_time >= SCAN_REST_BETWEEN_CYCLES_SEC:
					_rest_pause_time = 0.0
					_scan_look_count = 0
					begin_sun_shield_raise()
		_Arm2RaisePhase.RAISING:
			_arm2_phase_time += delta
			var t := clampf(_arm2_phase_time / ARM2_RAISE_TRANSITION_SEC, 0.0, 1.0)
			_arm2_raise_blend = _smoothstep(t)
			if t >= 1.0:
				_arm2_phase = _Arm2RaisePhase.HOLD
				_arm2_phase_time = 0.0
				_scan_look_count = 0
		_Arm2RaisePhase.HOLD:
			_arm2_phase_time += delta
			_arm2_raise_blend = 1.0
			if _keep_raised_while_scanning:
				if (
					_scan_look_count >= SCAN_FLIPS_BEFORE_LOWER
					and _look_right
					and _hand_shade_slide_amount < 0.08
					and _arm2_phase_time >= SCAN_POSE_A_HOLD_SEC
				):
					_arm2_phase = _Arm2RaisePhase.LOWERING
					_arm2_phase_time = 0.0
			elif _arm2_phase_time >= ARM2_RAISE_HOLD_SEC:
				_arm2_phase = _Arm2RaisePhase.LOWERING
				_arm2_phase_time = 0.0
		_Arm2RaisePhase.LOWERING:
			_look_right = true
			_arm2_phase_time += delta
			var t := clampf(_arm2_phase_time / ARM2_LOWER_TRANSITION_SEC, 0.0, 1.0)
			_arm2_raise_blend = 1.0 - _smoothstep(t)
			if t >= 1.0:
				_arm2_phase = _Arm2RaisePhase.REST
				_arm2_phase_time = 0.0
				_scan_look_count = 0
				_rest_pause_time = 0.0


func arm2_raise_blend() -> float:
	if _pose_edit_active:
		return 1.0
	return _arm2_raise_blend if playing else 0.0


func is_sun_shield_scan_mode() -> bool:
	return _keep_raised_while_scanning and _lookaround_enabled


func is_arm2_lowering() -> bool:
	return _arm2_phase == _Arm2RaisePhase.LOWERING


func hand_shade_slide_amount() -> float:
	return _hand_shade_slide_amount


func scan_blend() -> float:
	return _hand_shade_slide_amount


func tick_hand_shade_slide(delta: float, body_faces_left: bool, head_look_visual_right: bool) -> void:
	if not playing or not _lookaround_enabled:
		_hand_shade_slide_amount = move_toward(_hand_shade_slide_amount, 0.0, delta / HAND_SHADE_SLIDE_SEC)
		return
	if _arm2_phase == _Arm2RaisePhase.LOWERING or _arm2_raise_blend < 0.05:
		_hand_shade_slide_amount = move_toward(_hand_shade_slide_amount, 0.0, delta / HAND_SHADE_SLIDE_SEC)
		return
	var neutral_look_right := not body_faces_left
	var target := 0.0 if head_look_visual_right == neutral_look_right else 1.0
	_hand_shade_slide_amount = move_toward(_hand_shade_slide_amount, target, delta / HAND_SHADE_SLIDE_SEC)


func hand_shade_offset_display_px(body_faces_left: bool, head_look_visual_right: bool) -> Vector2:
	if _hand_shade_slide_amount < 0.001 or _arm2_raise_blend < 0.05:
		return Vector2.ZERO
	var neutral_look_right := not body_faces_left
	if head_look_visual_right == neutral_look_right:
		return Vector2.ZERO
	var sign_x := -1.0 if not head_look_visual_right else 1.0
	if body_faces_left:
		sign_x = -sign_x
	var scale := _hand_shade_slide_amount * _arm2_raise_blend
	return Vector2(sign_x * HAND_SHADE_SLIDE_DISPLAY_PX * scale, 0.0)


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
	if _pose_edit_active:
		return _look_right
	if _arm2_phase == _Arm2RaisePhase.LOWERING:
		return true
	return _look_right if playing else true


func weapon_bounce_offset(amplitude_local: float) -> float:
	if not playing:
		return 0.0
	return sin(breath_time * BREATH_SPEED - 0.55) * amplitude_local * 0.65
