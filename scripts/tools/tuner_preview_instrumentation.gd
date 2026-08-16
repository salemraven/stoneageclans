extends RefCounted
class_name TunerPreviewInstrumentation

## Measurable preview checks for LimbTuner — walk bounce, combat ready, strike overlay vs preset.

const WeaponOverlayCombat = preload("res://scripts/systems/weapon_overlay_combat.gd")
const CombatComponent = preload("res://scripts/npc/components/combat_component.gd")
const LimbPresetCoords = preload("res://scripts/systems/limb_preset_coords.gd")

const LOG_REL_PATH := "Tests/logs/tuner_preview_instrument.jsonl"

var enabled: bool = false
var log_to_file: bool = false
var frame_index: int = 0
var last_snapshot: Dictionary = {}
var violations: Array[String] = []


static func wants_cli_instrument() -> bool:
	if "--tuner-instrument" in OS.get_cmdline_user_args():
		return true
	return "--tuner-instrument" in OS.get_cmdline_args()


func reset_session() -> void:
	frame_index = 0
	last_snapshot = {}
	violations.clear()


func capture(
	anim_mode: int,
	weapon_type: int,
	rig: LimbTunerRig,
	preset: WeaponLimbPreset,
	hand_handle: Node2D,
	support_handle: Node2D
) -> Dictionary:
	var snap := {
		"frame": frame_index,
		"anim_mode": anim_mode,
		"weapon_type": weapon_type,
		"walk_dir": rig.get_walk_direction() if rig else 0,
		"walk_moving": rig.is_walking() if rig else false,
		"walk_phase": rig.get_walk_phase() if rig else 0.0,
		"sprite_y": 0.0,
		"overlay_state": -1,
		"combat_state": -1,
		"overlay_rot_deg": 0.0,
		"overlay_pos": Vector2.ZERO,
		"preset_ready_px": Vector2.ZERO,
		"live_ready_px": Vector2.ZERO,
		"hand_overlay_drift_px": -1.0,
		"support_delta_px": 0.0,
	}
	if rig == null:
		return snap
	if rig.sprite:
		snap["sprite_y"] = rig.sprite.position.y
	if rig.combat_component:
		snap["combat_state"] = rig.combat_component.state
	snap["overlay_state"] = WeaponOverlayCombat.get_overlay_state(rig)
	if rig.weapon_overlay and rig.sprite:
		snap["overlay_rot_deg"] = rad_to_deg(rig.weapon_overlay.rotation)
		snap["overlay_pos"] = rig.weapon_overlay.position
	if preset != null:
		snap["preset_ready_px"] = preset.ready_offset_px
		if rig.weapon_overlay and rig.sprite:
			snap["live_ready_px"] = LimbPresetCoords.overlay_display_from_position(
				rig.sprite, rig.weapon_overlay
			)
	if hand_handle != null and rig.weapon_overlay and preset != null:
		var grip_global := rig.hand_grip_global_from_preset(
			preset, WeaponLimbPreset.TunerAnimMode.ATTACK
		)
		snap["hand_overlay_drift_px"] = hand_handle.global_position.distance_to(grip_global)
	if not last_snapshot.is_empty() and support_handle != null:
		var prev_support: Variant = last_snapshot.get("support_y", support_handle.global_position.y)
		snap["support_delta_px"] = absf(
			support_handle.global_position.y - float(prev_support)
		)
		snap["support_y"] = support_handle.global_position.y
	elif support_handle != null:
		snap["support_y"] = support_handle.global_position.y
	return snap


func evaluate(snap: Dictionary) -> Array[String]:
	var issues: Array[String] = []
	if bool(snap.get("walk_moving", false)):
		if not last_snapshot.is_empty():
			var dy: float = absf(float(snap.get("sprite_y", 0.0)) - float(last_snapshot.get("sprite_y", 0.0)))
			if dy < 0.05 and frame_index > 3:
				issues.append("walk_moving_but_sprite_y_flat")
			var support_delta: float = float(snap.get("support_delta_px", 0.0))
			if support_delta < 0.05 and frame_index > 6:
				issues.append("walk_moving_but_support_arm_flat")
	var combat_state: int = int(snap.get("combat_state", -1))
	if combat_state == CombatComponent.CombatState.READY:
		var drift: float = float(snap.get("hand_overlay_drift_px", -1.0))
		if drift >= 0.0 and drift > 3.0:
			issues.append("combat_ready_hand_off_overlay (%.1f px)" % drift)
		var preset_ready: Vector2 = snap.get("preset_ready_px", Vector2.ZERO)
		var live_ready: Vector2 = snap.get("live_ready_px", Vector2.ZERO)
		if preset_ready.length_squared() > 0.0001 and live_ready.distance_to(preset_ready) > 8.0:
			issues.append(
				"combat_ready_overlay_not_preset (live=%s preset=%s)"
				% [str(live_ready), str(preset_ready)]
			)
	if int(snap.get("overlay_state", -1)) == WeaponOverlayCombat.OverlayState.STRIKING:
		var drift_strike: float = float(snap.get("hand_overlay_drift_px", -1.0))
		if drift_strike >= 0.0 and drift_strike > 4.0:
			issues.append("strike_hand_off_overlay (%.1f px)" % drift_strike)
	return issues


func tick(
	anim_mode: int,
	weapon_type: int,
	rig: LimbTunerRig,
	preset: WeaponLimbPreset,
	hand_handle: Node2D,
	support_handle: Node2D
) -> Dictionary:
	if not enabled:
		return {}
	var snap := capture(anim_mode, weapon_type, rig, preset, hand_handle, support_handle)
	var issues := evaluate(snap)
	for issue in issues:
		if issue not in violations:
			violations.append(issue)
	if log_to_file:
		_append_log(snap, issues)
	last_snapshot = snap
	frame_index += 1
	return snap


func hud_line(snap: Dictionary) -> String:
	if snap.is_empty():
		return ""
	return (
		"INSTR walk=%s dir=%d body_y=%.2f | combat=%d overlay=%d | handΔ=%.1fpx"
		% [
			"on" if snap.get("walk_moving", false) else "off",
			int(snap.get("walk_dir", 0)),
			float(snap.get("sprite_y", 0.0)),
			int(snap.get("combat_state", -1)),
			int(snap.get("overlay_state", -1)),
			float(snap.get("hand_overlay_drift_px", -1.0)),
		]
	)


func _append_log(snap: Dictionary, issues: Array[String]) -> void:
	var dir_path := ProjectSettings.globalize_path("res://Tests/logs/")
	DirAccess.make_dir_recursive_absolute(dir_path)
	var path := dir_path.path_join("tuner_preview_instrument.jsonl")
	var payload := {
		"frame": snap.get("frame", 0),
		"snapshot": snap,
		"issues": issues,
	}
	var f := FileAccess.open(path, FileAccess.READ_WRITE)
	if f == null:
		f = FileAccess.open(path, FileAccess.WRITE)
	if f == null:
		return
	f.seek_end()
	f.store_line(JSON.stringify(payload))
	f.close()
