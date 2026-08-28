extends RefCounted
class_name TunerElbowInstrumentation

## Elbow flip, on-arm alignment, and ping-pong prep checks for Pose Tuner.
## CLI: --tuner-elbow-instrument  →  Tests/logs/tuner_elbow_instrument.jsonl

const LOG_REL_PATH := "Tests/logs/tuner_elbow_instrument.jsonl"
const ON_ARM_MAX_PX := 3.5
const ARM_LINE_MAX_PX := 4.0

var enabled: bool = false
var log_to_file: bool = true
var event_index: int = 0
var violations: Array[String] = []


static func wants_cli_instrument() -> bool:
	if "--tuner-elbow-instrument" in OS.get_cmdline_user_args():
		return true
	return "--tuner-elbow-instrument" in OS.get_cmdline_args()


func reset_session() -> void:
	event_index = 0
	violations.clear()


static func measure_elbow_on_arm_rig_px(
	rig: LimbTunerRig,
	shoulder_g: Vector2,
	elbow_g: Vector2,
	hand_g: Vector2,
	upper_len: float,
	lower_len: float
) -> float:
	var shoulder_v: Vector2 = shoulder_g
	var elbow_v: Vector2 = elbow_g
	var hand_v: Vector2 = hand_g
	if rig != null:
		shoulder_v = rig.to_local(shoulder_g)
		elbow_v = rig.to_local(elbow_g)
		hand_v = rig.to_local(hand_g)
	var upper_err := absf(shoulder_v.distance_to(elbow_v) - upper_len)
	var lower_err := absf(elbow_v.distance_to(hand_v) - lower_len)
	return upper_err + lower_err


static func measure_elbow_on_arm_px(
	shoulder_g: Vector2,
	elbow_g: Vector2,
	hand_g: Vector2,
	upper_len: float,
	lower_len: float
) -> float:
	return measure_elbow_on_arm_rig_px(null, shoulder_g, elbow_g, hand_g, upper_len, lower_len)


static func measure_arm_line_elbow_delta_px(rig: LimbTunerRig, elbow_g: Vector2, dominant: bool) -> float:
	if rig == null:
		return 0.0
	var arm_elbow := rig.elbow_joint_global_from_arms(dominant)
	return elbow_g.distance_to(arm_elbow)


func record_flip(
	app: Node,
	dominant: bool,
	bend_before: float,
	bend_after: float,
	reason: String = "right_click"
) -> void:
	if not enabled:
		return
	var err_px := _measure_side(app, dominant)
	var payload := {
		"idx": event_index,
		"type": "elbow_flip",
		"dominant": dominant,
		"label": "1e" if dominant else "2e",
		"bend_before": snappedf(bend_before, 0.001),
		"bend_after": snappedf(bend_after, 0.001),
		"on_arm_err_px": snappedf(err_px, 0.01),
		"reason": reason,
	}
	_check_on_arm(payload, dominant, err_px)
	if log_to_file:
		_append_log(payload)
	event_index += 1


func record_pose_check(app: Node, phase: String, extra: Dictionary = {}) -> void:
	if not enabled:
		return
	var payload := {
		"idx": event_index,
		"type": "pose_check",
		"phase": phase,
		"weapon_on_arm_px": snappedf(_measure_side(app, true), 0.01),
		"support_on_arm_px": snappedf(_measure_side(app, false), 0.01),
		"weapon_arm_line_px": snappedf(_measure_arm_line(app, true), 0.01),
		"support_arm_line_px": snappedf(_measure_arm_line(app, false), 0.01),
	}
	for key in extra.keys():
		payload[key] = extra[key]
	for side in [true, false]:
		var on_arm: float = payload["weapon_on_arm_px"] if side else payload["support_on_arm_px"]
		var arm_line: float = payload["weapon_arm_line_px"] if side else payload["support_arm_line_px"]
		_check_on_arm(payload, side, on_arm)
		if arm_line > ARM_LINE_MAX_PX:
			_add_violation(
				"arm_line %s Δ=%.1fpx phase=%s"
				% ["1e" if side else "2e", arm_line, phase]
			)
	if log_to_file:
		_append_log(payload)
	event_index += 1


func hud_line() -> String:
	if violations.is_empty():
		return "ELBOW-INSTR ok (events=%d)" % event_index
	return "ELBOW-INSTR ⚠ %d · %s" % [violations.size(), violations[-1]]


func _measure_side(app: Node, dominant: bool) -> float:
	var rig: LimbTunerRig = app.get("_rig")
	var preset: WeaponLimbPreset = app.get("_preset")
	if rig == null or preset == null:
		return 0.0
	var shoulder: Node2D = app.get("_shoulder_handle") if dominant else app.get("_support_shoulder_handle")
	var hand: Node2D = app.get("_hand_handle") if dominant else app.get("_support_hand_handle")
	var elbow: Node2D = app.get("_weapon_elbow_handle") if dominant else app.get("_support_elbow_handle")
	if shoulder == null or hand == null or elbow == null:
		return 0.0
	var sx := absf(rig.sprite.scale.x) if rig.sprite else 1.0
	var upper := preset.resolve_upper_arm_length(dominant) * sx
	var lower := preset.resolve_lower_arm_length(dominant) * sx
	return measure_elbow_on_arm_rig_px(
		rig,
		shoulder.global_position,
		elbow.global_position,
		hand.global_position,
		upper,
		lower
	)


func _measure_arm_line(app: Node, dominant: bool) -> float:
	var rig: LimbTunerRig = app.get("_rig")
	var elbow: Node2D = app.get("_weapon_elbow_handle") if dominant else app.get("_support_elbow_handle")
	if rig == null or elbow == null:
		return 0.0
	return measure_arm_line_elbow_delta_px(rig, elbow.global_position, dominant)


func _check_on_arm(payload: Dictionary, dominant: bool, err_px: float) -> void:
	if err_px > ON_ARM_MAX_PX:
		_add_violation(
			"on_arm %s err=%.1fpx type=%s phase=%s"
			% [
				"1e" if dominant else "2e",
				err_px,
				str(payload.get("type", "")),
				str(payload.get("phase", "")),
			]
		)


func _add_violation(msg: String) -> void:
	if msg not in violations:
		violations.append(msg)


func _append_log(payload: Dictionary) -> void:
	var dir_path := ProjectSettings.globalize_path("res://Tests/logs/")
	DirAccess.make_dir_recursive_absolute(dir_path)
	var path := dir_path.path_join("tuner_elbow_instrument.jsonl")
	var f := FileAccess.open(path, FileAccess.READ_WRITE)
	if f == null:
		f = FileAccess.open(path, FileAccess.WRITE)
	if f == null:
		return
	f.seek_end()
	f.store_line(JSON.stringify(payload))
	f.close()
