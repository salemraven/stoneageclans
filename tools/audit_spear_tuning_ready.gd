extends SceneTree

## Headless audit: spear_clansmen_1 preset ready for LimbTuner sessions (idle / walk / windup / thrust).

const WeaponLimbPresetScript = preload("res://scripts/config/weapon_limb_preset.gd")
const LimbPresetRegistryScript = preload("res://scripts/systems/limb_preset_registry.gd")

var _failures: Array[String] = []
var _warnings: Array[String] = []


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	await process_frame
	var registry := LimbPresetRegistryScript.new()
	var preset: WeaponLimbPreset = registry.reload_preset(ResourceData.ResourceType.SPEAR, "clansmen_1")
	if preset == null:
		_fail("spear_clansmen_1.tres missing or failed to load")
		_report()
		quit(1)
		return
	print("=== Spear tuning-ready audit (clansmen_1) ===")
	_audit_idle_standing(preset)
	_audit_walk_rows(preset)
	_audit_attack_windup(preset)
	_audit_thrust_strike(preset)
	_report()
	quit(0 if _failures.is_empty() else 1)


func _audit_idle_standing(preset: WeaponLimbPreset) -> void:
	print("\n-- Idle standing --")
	_print_vec("  overlay", preset.overlay_offset_idle_px)
	_print_vec("  hand_grip (shaft)", preset.hand_grip_offset_px)
	_print_vec("  support_hand idle", preset.support_hand_idle_offset_px)
	if preset.overlay_offset_idle_px.length_squared() < 0.0001:
		_fail("idle standing: overlay unset")
	if preset.spear_hand_grip_needs_reseed():
		_fail("idle standing: hand_grip looks like legacy overlay coords — run prep_spear")
	if not preset.uses_saved_spear_grip_on_art():
		_fail("idle standing: yellow pin needs saved shaft grip on art")


func _audit_walk_rows(preset: WeaponLimbPreset) -> void:
	print("\n-- Walk / Walk 1 --")
	_print_vec("  walk overlay", preset.walk_overlay_offset_px)
	_print_vec("  walk hand_grip", preset.walk_hand_grip_offset_px)
	_print_vec("  walk1 overlay", preset.walk1_overlay_offset_px)
	_print_vec("  walk1 hand_grip", preset.walk1_hand_grip_offset_px)
	if preset.walk_hand_grip_offset_px.length_squared() < 0.0001:
		_warn("walk row unset — will borrow idle until tuned")
	if preset.walk1_hand_grip_offset_px.length_squared() < 0.0001:
		_warn("walk1 row unset — will borrow walk/idle until tuned")


func _audit_attack_windup(preset: WeaponLimbPreset) -> void:
	print("\n-- Attack windup (Shift ready / --spear-windup-edit) --")
	print("  spear_attack_pose_saved: ", preset.spear_attack_pose_saved)
	_print_vec("  ready_offset_px", preset.ready_offset_px)
	_print_vec("  hand_grip_ready", preset.hand_grip_ready_offset_px)
	_print_vec("  support_hand_offset (2h on shaft)", preset.support_hand_offset_px)
	_print_vec("  weapon_elbow_ready", preset.weapon_elbow_pole_ready_px)
	if preset.ready_offset_px.length_squared() < 0.0001:
		_fail("attack windup: ready_offset_px unset")
	if preset.hand_grip_ready_offset_px.length_squared() < 0.0001:
		_fail("attack windup: hand_grip_ready unset")
	if preset.support_hand_offset_px.length_squared() < 0.0001:
		_fail("attack windup: support_hand_offset unset (need Y2 / 2h on shaft)")


func _audit_thrust_strike(preset: WeaponLimbPreset) -> void:
	print("\n-- Thrust strike (Shift+click) --")
	_print_vec("  strike_offset_px", preset.strike_offset_px)
	print("  attack_rotation_deg: ", preset.attack_rotation_deg)
	if not preset.spear_attack_pose_saved:
		_warn("spear_attack_pose_saved is false — Attack row still inherits idle until Save all")
	if preset.strike_offset_px.length_squared() < 0.0001:
		_fail("thrust: strike_offset_px unset")
	elif preset.strike_offset_px.distance_to(preset.ready_offset_px) < 4.0:
		_warn("strike_offset_px very close to ready — thrust may look short until re-tuned")


func _print_vec(label: String, v: Vector2) -> void:
	print("%s = (%.2f, %.2f)" % [label, v.x, v.y])


func _fail(msg: String) -> void:
	_failures.append(msg)
	print("FAIL: ", msg)


func _warn(msg: String) -> void:
	_warnings.append(msg)
	print("WARN: ", msg)


func _report() -> void:
	print("\n=== Summary ===")
	print("Failures: ", _failures.size())
	print("Warnings: ", _warnings.size())
	if _failures.is_empty() and _warnings.is_empty():
		print("spear_tuning_audit: PASS")
	elif _failures.is_empty():
		print("spear_tuning_audit: PASS_WITH_WARNINGS")
	else:
		print("spear_tuning_audit: FAIL")
		for f in _failures:
			print("  - ", f)
