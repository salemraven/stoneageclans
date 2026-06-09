extends Control
class_name PlayerMovementDebugOverlay

## Live player movement diagnostics — toggle with F8 (wired in main.gd).
## Shows input vs velocity vs position delta to catch stuck keys or ghost drift.

const LOG_INTERVAL_SEC := 2.0
const ANOMALY_LOG_COOLDOWN_SEC := 0.35
const DRIFT_VEL_THRESHOLD := 8.0
const DRIFT_POS_THRESHOLD_PX := 1.5

var _player: CharacterBody2D = null
var _label: RichTextLabel = null
var _panel: Panel = null
var _debug_visible: bool = false
var _prev_pos: Vector2 = Vector2.ZERO
var _prev_input: Vector2 = Vector2.ZERO
var _log_timer: float = 0.0
var _anomaly_cooldown: float = 0.0
var _anomaly_count: int = 0


func setup(player: CharacterBody2D) -> void:
	_player = player
	_build_ui()
	visible = false
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func _build_ui() -> void:
	set_anchors_preset(Control.PRESET_BOTTOM_LEFT)
	offset_left = 8.0
	offset_bottom = -8.0
	offset_right = 420.0
	offset_top = -248.0

	_panel = Panel.new()
	_panel.set_anchors_preset(Control.PRESET_FULL_RECT)
	_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_panel)

	_label = RichTextLabel.new()
	_label.set_anchors_preset(Control.PRESET_FULL_RECT)
	_label.offset_left = 8.0
	_label.offset_top = 6.0
	_label.offset_right = -8.0
	_label.offset_bottom = -6.0
	_label.bbcode_enabled = true
	_label.scroll_active = false
	_label.fit_content = true
	_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_panel.add_child(_label)


func toggle() -> void:
	_debug_visible = not _debug_visible
	visible = _debug_visible
	_log_timer = 0.0
	_anomaly_cooldown = 0.0
	if _player and is_instance_valid(_player):
		_prev_pos = _player.global_position
	_prev_input = _read_input_vector()
	if _debug_visible:
		print("PLAYER_MOVE_DEBUG: overlay ON (F8 to hide)")
		_log_snapshot("toggle_on")
	else:
		print("PLAYER_MOVE_DEBUG: overlay OFF — anomalies this session: %d" % _anomaly_count)


func is_debug_visible() -> bool:
	return _debug_visible


func _process(delta: float) -> void:
	if not _debug_visible or _player == null or not is_instance_valid(_player):
		return

	var input_vec := _read_input_vector()
	if _prev_input.length_squared() > 0.01 and input_vec.length_squared() < 0.0001:
		_log_snapshot("input_dropped_to_zero")

	_prev_input = input_vec
	_update_label(delta, input_vec)

	_log_timer += delta
	if _log_timer >= LOG_INTERVAL_SEC:
		_log_timer = 0.0
		_log_snapshot("periodic")

	_anomaly_cooldown = maxf(0.0, _anomaly_cooldown - delta)


func _read_input_vector() -> Vector2:
	var v := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	if v.length_squared() > 1.0:
		v = v.normalized()
	return v


func _action_strengths() -> Dictionary:
	return {
		"L": Input.get_action_strength("move_left"),
		"R": Input.get_action_strength("move_right"),
		"U": Input.get_action_strength("move_up"),
		"D": Input.get_action_strength("move_down"),
	}


func _pressed_labels() -> String:
	var parts: PackedStringArray = []
	if Input.is_action_pressed("move_left"):
		parts.append("L")
	if Input.is_action_pressed("move_right"):
		parts.append("R")
	if Input.is_action_pressed("move_up"):
		parts.append("U")
	if Input.is_action_pressed("move_down"):
		parts.append("D")
	if parts.is_empty():
		return "(none)"
	return ", ".join(parts)


func _update_label(delta: float, input_vec: Vector2) -> void:
	var pos: Vector2 = _player.global_position
	var pos_delta: float = pos.distance_to(_prev_pos)
	_prev_pos = pos

	var vel: Vector2 = _player.velocity
	var can_move: bool = bool(_player.get("_can_move")) if "_can_move" in _player else true
	var gathering: bool = _player.get("is_gathering") == true
	var form_vel: Vector2 = _player.get_meta("formation_velocity", Vector2.ZERO) as Vector2
	var form_mult: float = float(_player.get_meta("formation_speed_mult", 1.0))
	var strengths: Dictionary = _action_strengths()

	var zero_input := input_vec.length_squared() < 0.0001
	var drift_vel := zero_input and vel.length() > DRIFT_VEL_THRESHOLD
	var drift_pos := zero_input and can_move and pos_delta > DRIFT_POS_THRESHOLD_PX
	var mismatch := input_vec.length_squared() > 0.01 and vel.length() > 1.0
	if mismatch:
		var dot: float = input_vec.normalized().dot(vel.normalized()) if vel.length_squared() > 0.01 else 1.0
		mismatch = dot < 0.3 and vel.length() > DRIFT_VEL_THRESHOLD

	var anomaly := drift_vel or drift_pos or mismatch
	if anomaly and _anomaly_cooldown <= 0.0:
		_anomaly_count += 1
		_anomaly_cooldown = ANOMALY_LOG_COOLDOWN_SEC
		var reason := "drift_vel" if drift_vel else ("drift_pos" if drift_pos else "input_vel_mismatch")
		_log_snapshot("ANOMALY_%s" % reason)

	var warn_line := ""
	if anomaly:
		warn_line = "[color=yellow]⚠ "
		if drift_vel:
			warn_line += "Zero input but velocity=%.0f px/s. " % vel.length()
		if drift_pos:
			warn_line += "Zero input but moved %.1f px this frame. " % pos_delta
		if mismatch:
			warn_line += "Input dir ≠ velocity dir. "
		warn_line += "[/color]"

	var lines: PackedStringArray = [
		"[b]Player movement (F8)[/b]",
		"input: (%.2f, %.2f)" % [input_vec.x, input_vec.y],
		"strength L:%.2f R:%.2f U:%.2f D:%.2f" % [strengths["L"], strengths["R"], strengths["U"], strengths["D"]],
		"pressed: %s" % _pressed_labels(),
		"velocity: (%.0f, %.0f) spd=%.0f" % [vel.x, vel.y, vel.length()],
		"pos: (%.0f, %.0f)  Δ=%.1f px/frame (%.0f fps est)" % [pos.x, pos.y, pos_delta, 1.0 / maxf(delta, 0.0001)],
		"can_move=%s  gathering=%s  form_mult=%.2f" % [str(can_move), str(gathering), form_mult],
		"formation_vel: (%.0f, %.0f)" % [form_vel.x, form_vel.y],
		"anomalies logged: %d" % _anomaly_count,
	]
	if warn_line != "":
		lines.append(warn_line)

	_label.text = "\n".join(lines)


func _log_snapshot(reason: String) -> void:
	if _player == null or not is_instance_valid(_player):
		return
	var input_vec := _read_input_vector()
	var strengths: Dictionary = _action_strengths()
	var vel: Vector2 = _player.velocity
	var pos: Vector2 = _player.global_position
	var can_move: bool = bool(_player.get("_can_move")) if "_can_move" in _player else true
	var gathering: bool = _player.get("is_gathering") == true
	var form_vel: Vector2 = _player.get_meta("formation_velocity", Vector2.ZERO) as Vector2
	var form_mult: float = float(_player.get_meta("formation_speed_mult", 1.0))
	var msg := (
		"PLAYER_MOVE_DEBUG [%s] input=(%.2f,%.2f) str(L=%.2f R=%.2f U=%.2f D=%.2f) pressed=%s "
		+ "vel=(%.0f,%.0f) spd=%.0f pos=(%.0f,%.0f) can_move=%s gathering=%s form_vel=(%.0f,%.0f) form_mult=%.2f"
	) % [
		reason,
		input_vec.x, input_vec.y,
		strengths["L"], strengths["R"], strengths["U"], strengths["D"],
		_pressed_labels(),
		vel.x, vel.y, vel.length(),
		pos.x, pos.y,
		str(can_move), str(gathering),
		form_vel.x, form_vel.y, form_mult,
	]
	print(msg)
	if UnifiedLogger:
		UnifiedLogger.log_movement("PLAYER_MOVE", {
			"reason": reason,
			"input_x": snappedf(input_vec.x, 0.01),
			"input_y": snappedf(input_vec.y, 0.01),
			"vel_x": snappedf(vel.x, 1.0),
			"vel_y": snappedf(vel.y, 1.0),
			"pos_x": snappedf(pos.x, 1.0),
			"pos_y": snappedf(pos.y, 1.0),
			"can_move": can_move,
			"gathering": gathering,
			"pressed": _pressed_labels(),
		})
