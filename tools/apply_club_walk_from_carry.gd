extends SceneTree
## Sync club Walk 1 from saved idle carry (hand_grip_offset_px) + none off-arm swing; save preset.
## Run: godot --headless -s res://tools/apply_club_walk_from_carry.gd

const LimbPresetRegistryScript = preload("res://scripts/systems/limb_preset_registry.gd")


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	await process_frame
	var registry := LimbPresetRegistryScript.new()
	var club: WeaponLimbPreset = registry.reload_preset(ResourceData.ResourceType.WOOD, "clansmen_1")
	var none: WeaponLimbPreset = registry.get_preset(ResourceData.ResourceType.NONE, "clansmen_1", 1)
	if club == null:
		push_error("apply_club_walk_from_carry: club preset missing")
		quit(1)
		return
	if none == null:
		push_error("apply_club_walk_from_carry: none preset missing")
		quit(1)
		return
	if not club.club_carry_body_hand_is_plausible():
		push_error(
			"apply_club_walk_from_carry: save idle carry first (hand_grip_offset_px invalid)"
		)
		quit(1)
		return
	club.mark_walk1_pose_a_saved()
	club.mark_walk1_pose_b_saved()
	club.sync_club_walk_dominant_from_saved_carry_if_needed()
	club.sync_club_walk_off_arm_keyframe_from_none(none)
	club.seed_club_walk_off_arm_from_none(none)
	club.seed_walk1_pull_from_pose_a_if_unset()
	var err := registry.save_preset(club)
	if err != OK:
		push_error("apply_club_walk_from_carry: save failed %s" % error_string(err))
		quit(1)
		return
	print("apply_club_walk_from_carry: OK")
	print("  body carry: ", club.resolve_club_carry_body_hand_px())
	print("  walk1 dominant: ", club.resolve_club_walk1_dominant_hand_export(false))
	print("  walk1 off-arm A: ", club.walk1_support_hand_offset_px)
	print("  walk1 off-arm B: ", club.walk1_pull_support_hand_offset_px)
	quit(0)
