extends SceneTree

## One-shot: seed spear + club presets after clean-slate reset (test-passing baselines).

const WeaponLimbPresetScript = preload("res://scripts/config/weapon_limb_preset.gd")
const LimbPresetRegistryScript = preload("res://scripts/systems/limb_preset_registry.gd")


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	await process_frame
	var registry := LimbPresetRegistryScript.new()
	var none: WeaponLimbPreset = registry.reload_preset(ResourceData.ResourceType.NONE, "clansmen_1")
	if none == null:
		push_error("none_clansmen_1 missing — run lockin_none_clansmen_1 first")
		quit(1)
		return

	var spear := WeaponLimbPresetScript.defaults_for(ResourceData.ResourceType.SPEAR, 1)
	spear.apply_shared_body_from_none(none)
	WeaponLimbPresetScript.apply_default_spear_idle_pose(spear)
	spear.weapon_type = ResourceData.ResourceType.SPEAR
	spear.body_card_id = "clansmen_1"
	var spear_err := registry.save_preset(spear)
	print("spear_clansmen_1 save: ", error_string(spear_err))

	var club := WeaponLimbPresetScript.defaults_for(ResourceData.ResourceType.WOOD, 1)
	club.apply_shared_body_from_none(none)
	club.weapon_type = ResourceData.ResourceType.WOOD
	club.body_card_id = "clansmen_1"
	club.overlay_offset_idle_px = Vector2(22.0, -34.0)
	club.hand_grip_offset_px = Vector2(5.0, 75.0)
	club.support_hand_idle_offset_px = none.support_hand_idle_offset_px
	club.weapon_elbow_pole_idle_px = none.weapon_elbow_pole_idle_px
	club.support_elbow_pole_idle_px = none.support_elbow_pole_idle_px
	club.idle_club1_overlay_offset_px = Vector2(45.0, -55.0)
	club.idle_club1_hand_grip_offset_px = Vector2(5.0, 80.0)
	club.idle_club1_support_hand_offset_px = none.support_hand_idle_offset_px
	club.idle_club1_grip_authoritative = true
	club.ready_offset_px = Vector2(8.0, 6.0)
	club.hand_grip_ready_offset_px = Vector2(12.0, 70.0)
	club.support_hand_offset_px = Vector2(10.0, 40.0)
	club.strike_offset_px = Vector2(12.0, 18.0)
	club.club_attack_pose_saved = true
	club.club_windup_idle_loop_sec = 5.0
	club.club_windup_idle_key_a_ready_offset_px = Vector2(10.0, 0.0)
	club.club_windup_idle_key_a_hand_grip_offset_px = Vector2(12.0, 68.0)
	club.club_windup_idle_key_a_support_hand_offset_px = Vector2(10.0, 40.0)
	club.club_windup_idle_key_b_ready_offset_px = Vector2(18.0, -8.0)
	club.club_windup_idle_key_b_hand_grip_offset_px = Vector2(14.0, 65.0)
	club.club_windup_idle_key_b_support_hand_offset_px = Vector2(15.0, 45.0)
	var club_err := registry.save_preset(club)
	print("club_clansmen_1 save: ", error_string(club_err))

	registry.reload_all_presets("clansmen_1")
	print("seed_baseline_weapon_presets: done")
	quit(0 if spear_err == OK and club_err == OK else 1)
