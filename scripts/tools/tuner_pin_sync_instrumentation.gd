extends RefCounted
class_name TunerPinSyncInstrumentation

## Logs dominant-pin drag / commit / sync overwrites for LimbTuner debugging.
## CLI: --tuner-pin-instrument  →  Tests/logs/tuner_pin_sync_instrument.jsonl

const LimbPresetCoords = preload("res://scripts/systems/limb_preset_coords.gd")

const LOG_REL_PATH := "Tests/logs/tuner_pin_sync_instrument.jsonl"
const SNAP_WARN_PX := 2.0

var enabled: bool = false
var log_to_file: bool = true
var event_index: int = 0
var violations: Array[String] = []
var _last_drag_hand_global: Vector2 = Vector2.ZERO
var _last_drag_preset_body_px: Vector2 = Vector2.ZERO


static func wants_cli_instrument() -> bool:
	if "--tuner-pin-instrument" in OS.get_cmdline_user_args():
		return true
	return "--tuner-pin-instrument" in OS.get_cmdline_args()


func reset_session() -> void:
	event_index = 0
	violations.clear()
	_last_drag_hand_global = Vector2.ZERO
	_last_drag_preset_body_px = Vector2.ZERO


func record(
	event_type: String,
	anim_mode: int,
	weapon_type: int,
	handle_name: String,
	phase: String,
	hand_global: Vector2,
	spear_global: Vector2,
	preset_body_px: Vector2,
	preset_grip_px: Vector2,
	sync_source: String,
	before_global: Vector2,
	after_global: Vector2,
	extra: Dictionary = {}
) -> Dictionary:
	if not enabled:
		return {}
	var delta_px := before_global.distance_to(after_global) if before_global != Vector2.ZERO else 0.0
	var payload := {
		"idx": event_index,
		"type": event_type,
		"phase": phase,
		"anim_mode": anim_mode,
		"weapon_type": weapon_type,
		"handle": handle_name,
		"hand_global": _vec(hand_global),
		"spear_global": _vec(spear_global),
		"preset_body_px": _vec(preset_body_px),
		"preset_grip_px": _vec(preset_grip_px),
		"sync_source": sync_source,
		"before_global": _vec(before_global),
		"after_global": _vec(after_global),
		"delta_px": snappedf(delta_px, 0.01),
	}
	for key in extra.keys():
		payload[key] = extra[key]
	if event_type == "sync_overwrite" and delta_px > SNAP_WARN_PX:
		var msg := (
			"sync_overwrite %s Δ=%.1fpx via %s (mode=%s)"
			% [handle_name, delta_px, sync_source, str(anim_mode)]
		)
		if msg not in violations:
			violations.append(msg)
	if event_type == "drag_end_snap" and delta_px > SNAP_WARN_PX:
		var snap_msg := (
			"drag_end_snap %s Δ=%.1fpx preset_body=%s"
			% [handle_name, delta_px, str(preset_body_px)]
		)
		if snap_msg not in violations:
			violations.append(snap_msg)
	if log_to_file:
		_append_log(payload)
	event_index += 1
	return payload


func record_drag_start(
	anim_mode: int,
	weapon_type: int,
	handle_name: String,
	hand_global: Vector2,
	spear_global: Vector2,
	preset_body_px: Vector2,
	preset_grip_px: Vector2
) -> void:
	_last_drag_hand_global = hand_global
	_last_drag_preset_body_px = preset_body_px
	record(
		"drag_start",
		anim_mode,
		weapon_type,
		handle_name,
		"start",
		hand_global,
		spear_global,
		preset_body_px,
		preset_grip_px,
		"",
		hand_global,
		hand_global
	)


func record_drag_move(
	anim_mode: int,
	weapon_type: int,
	handle_name: String,
	hand_global: Vector2,
	spear_global: Vector2,
	preset_body_px: Vector2,
	preset_grip_px: Vector2
) -> void:
	if event_index > 0 and event_index % 8 != 0:
		return
	_last_drag_hand_global = hand_global
	_last_drag_preset_body_px = preset_body_px
	record(
		"drag_move",
		anim_mode,
		weapon_type,
		handle_name,
		"move",
		hand_global,
		spear_global,
		preset_body_px,
		preset_grip_px,
		"",
		hand_global,
		hand_global
	)


func record_drag_end(
	anim_mode: int,
	weapon_type: int,
	handle_name: String,
	hand_before: Vector2,
	hand_after: Vector2,
	spear_global: Vector2,
	preset_body_px: Vector2,
	preset_grip_px: Vector2
) -> void:
	record(
		"drag_end_snap",
		anim_mode,
		weapon_type,
		handle_name,
		"release",
		hand_after,
		spear_global,
		preset_body_px,
		preset_grip_px,
		"mouse_release",
		hand_before,
		hand_after,
		{
			"drag_target_global": _vec(_last_drag_hand_global),
			"preset_body_at_drag": _vec(_last_drag_preset_body_px),
		}
	)


func record_sync_overwrite(
	anim_mode: int,
	weapon_type: int,
	handle_name: String,
	sync_source: String,
	before_global: Vector2,
	after_global: Vector2,
	hand_global: Vector2,
	spear_global: Vector2,
	preset_body_px: Vector2,
	preset_grip_px: Vector2,
	extra: Dictionary = {}
) -> void:
	if before_global.distance_to(after_global) < 0.05:
		return
	record(
		"sync_overwrite",
		anim_mode,
		weapon_type,
		handle_name,
		"sync",
		hand_global,
		spear_global,
		preset_body_px,
		preset_grip_px,
		sync_source,
		before_global,
		after_global,
		extra
	)


func hud_line() -> String:
	if violations.is_empty():
		return "PIN-INSTR ok (events=%d)" % event_index
	return "PIN-INSTR ⚠ %d issues · last: %s" % [violations.size(), violations[-1]]


func _vec(v: Vector2) -> Array:
	return [snappedf(v.x, 0.01), snappedf(v.y, 0.01)]


func _append_log(payload: Dictionary) -> void:
	var dir_path := ProjectSettings.globalize_path("res://Tests/logs/")
	DirAccess.make_dir_recursive_absolute(dir_path)
	var path := dir_path.path_join("tuner_pin_sync_instrument.jsonl")
	var f := FileAccess.open(path, FileAccess.READ_WRITE)
	if f == null:
		f = FileAccess.open(path, FileAccess.WRITE)
	if f == null:
		return
	f.seek_end()
	f.store_line(JSON.stringify(payload))
	f.close()
