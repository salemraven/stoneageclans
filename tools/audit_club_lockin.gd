extends SceneTree

## Headless audit: club_clansmen_1 preset + pose row readiness before lock-in.

const WeaponLimbPresetScript = preload("res://scripts/config/weapon_limb_preset.gd")
const LimbPresetRegistryScript = preload("res://scripts/systems/limb_preset_registry.gd")

var _failures: Array[String] = []
var _warnings: Array[String] = []


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	await process_frame
	var registry := LimbPresetRegistryScript.new()
	var preset: WeaponLimbPreset = registry.reload_preset(ResourceData.ResourceType.WOOD, "clansmen_1")
	if preset == null:
		_fail("club_clansmen_1.tres missing or failed to load")
		_report()
		quit()
		return
	print("=== Club lock-in audit (clansmen_1) ===")
	_audit_flags(preset)
	_audit_idle_standing(preset)
	_audit_idle_club1(preset)
	_audit_attack_windup(preset)
	_audit_windup_loop(preset)
	_audit_walk_borrow(preset)
	_audit_strike_path(preset)
	_report()
	quit()


func _audit_flags(preset: WeaponLimbPreset) -> void:
	print("\n-- Flags --")
	print("  club_attack_pose_saved: ", preset.club_attack_pose_saved)
	print("  idle_club1_grip_authoritative: ", preset.idle_club1_grip_authoritative)
	print("  attack_pose_inherits_idle: ", preset.attack_pose_inherits_idle())
	if not preset.club_attack_pose_saved:
		_fail("club_attack_pose_saved is false — attack row not marked saved")
	if not preset.idle_club1_grip_authoritative:
		_warn("idle_club1_grip_authoritative is false — club grip row may drift")


func _audit_idle_standing(preset: WeaponLimbPreset) -> void:
	print("\n-- Idle standing (carry pose) --")
	_print_vec("  hand_grip", preset.hand_grip_offset_px)
	_print_vec("  overlay", preset.overlay_offset_idle_px)
	_print_vec("  support_hand", preset.support_hand_idle_offset_px)
	_print_vec("  weapon_elbow", preset.weapon_elbow_pole_idle_px)
	if preset.hand_grip_offset_px.length_squared() < 0.0001:
		_fail("idle standing: hand_grip unset")
	if preset.overlay_offset_idle_px.length_squared() < 0.0001:
		_fail("idle standing: overlay unset")


func _audit_idle_club1(preset: WeaponLimbPreset) -> void:
	print("\n-- Club grip (idle_club1 row) --")
	_print_vec("  hand_grip", preset.idle_club1_hand_grip_offset_px)
	_print_vec("  overlay", preset.idle_club1_overlay_offset_px)
	_print_vec("  support_hand", preset.idle_club1_support_hand_offset_px)
	if not preset.idle_club1_hand_grip_is_plausible():
		_fail("club grip row: hand grip not plausible")
	if preset.idle_club1_overlay_offset_px.distance_to(preset.overlay_offset_idle_px) < 0.01:
		_warn("club grip overlay matches idle standing — confirm intentional")


func _audit_attack_windup(preset: WeaponLimbPreset) -> void:
	print("\n-- Attack windup (Shift ready / strike start) --")
	_print_vec("  ready_offset_px", preset.ready_offset_px)
	_print_vec("  hand_grip_ready", preset.hand_grip_ready_offset_px)
	_print_vec("  support_hand_offset", preset.support_hand_offset_px)
	_print_vec("  weapon_elbow_ready", preset.weapon_elbow_pole_ready_px)
	_print_vec("  support_elbow_ready", preset.support_elbow_pole_ready_px)
	if preset.ready_offset_px.length_squared() < 0.0001:
		_fail("attack: ready_offset_px unset")
	if preset.hand_grip_ready_offset_px.length_squared() < 0.0001:
		_fail("attack: hand_grip_ready unset")
	if preset.support_hand_offset_px.distance_to(Vector2(6.0, 52.0)) < 0.01:
		_warn(
			"attack support_hand_offset still default (6, 52) — "
			+ "may not match tuned windup loop off-hand"
		)


func _audit_windup_loop(preset: WeaponLimbPreset) -> void:
	print("\n-- Windup idle loop (Attack ▶ Play) --")
	print("  loop_sec: ", preset.club_windup_idle_loop_sec)
	print("  has_loop: ", preset.has_club_windup_idle_loop())
	if not preset.has_club_windup_idle_loop():
		_fail("windup loop keys A/B not saved")
		return
	_print_vec("  key_a ready", preset.club_windup_idle_key_a_ready_offset_px)
	_print_vec("  key_a support", preset.club_windup_idle_key_a_support_hand_offset_px)
	_print_vec("  key_b ready", preset.club_windup_idle_key_b_ready_offset_px)
	_print_vec("  key_b support", preset.club_windup_idle_key_b_support_hand_offset_px)
	var sample_a: Dictionary = preset.sample_club_windup_idle_loop(0.15)
	var sample_mid: Dictionary = preset.sample_club_windup_idle_loop(0.5)
	if sample_a.is_empty() or sample_mid.is_empty():
		_fail("windup loop sample returned empty")
	# Shift-ready uses attack row, not loop sample — flag mismatch.
	var key_a_support: Vector2 = preset.club_windup_idle_key_a_support_hand_offset_px
	if preset.support_hand_offset_px.distance_to(key_a_support) > 12.0:
		_warn(
			"attack support_hand (%.0f, %.0f) differs from loop key A support (%.0f, %.0f) — "
			% [
				preset.support_hand_offset_px.x,
				preset.support_hand_offset_px.y,
				key_a_support.x,
				key_a_support.y,
			]
			+ "Shift ready uses attack row; loop uses key A/B"
		)


func _audit_walk_borrow(preset: WeaponLimbPreset) -> void:
	print("\n-- Walk (not in Club picker — borrows idle if unset) --")
	var walk_saved := preset.walk_hand_grip_offset_px.length_squared() > 0.0001
	print("  walk row saved on disk: ", walk_saved)
	if not walk_saved:
		print("  runtime: weapon arm → idle standing · support → walk or idle seed")
		_warn("walk_* fields are zero on disk — walk uses idle carry until you tune Walk row")


func _audit_strike_path(preset: WeaponLimbPreset) -> void:
	print("\n-- Strike (Shift+click) --")
	_print_vec("  strike_offset_px", preset.strike_offset_px)
	print("  attack_rotation_deg: ", preset.attack_rotation_deg)
	print("  has_club_keyframed_strike: ", preset.has_club_keyframed_strike())
	if not preset.has_club_keyframed_strike():
		_fail("keyframed club strike not ready — save windup loop + attack peak")
		return
	var windup_kf: Dictionary = preset.club_strike_windup_keyframe()
	var peak_kf: Dictionary = preset.club_strike_peak_keyframe()
	_print_vec("  windup_overlay", windup_kf.get("overlay_px", Vector2.ZERO))
	_print_vec("  peak_overlay", peak_kf.get("overlay_px", Vector2.ZERO))
	_print_vec("  windup_hand_grip", windup_kf.get("hand_grip_px", Vector2.ZERO))
	_print_vec("  peak_hand_grip", peak_kf.get("hand_grip_px", Vector2.ZERO))


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
		print("club_lockin_audit: PASS (no blockers — visual sign-off still needed)")
	elif _failures.is_empty():
		print("club_lockin_audit: PASS_WITH_WARNINGS")
	else:
		print("club_lockin_audit: FAIL")
		for f in _failures:
			print("  - ", f)
