extends SceneTree

## Headless: sample club keyframed strike rotation/position timeline (facing right).

const WeaponOverlayCombat = preload("res://scripts/systems/weapon_overlay_combat.gd")
const LimbPresetRegistryScript = preload("res://scripts/systems/limb_preset_registry.gd")
const PlaceholderCardRegistry = preload("res://scripts/config/placeholder_card_registry.gd")


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	await process_frame
	var registry := LimbPresetRegistryScript.new()
	var card_registry := PlaceholderCardRegistry.new()
	var base_profile: Dictionary = card_registry.get_weapon_combat_profile(
		ResourceData.ResourceType.WOOD
	)
	var profile: Dictionary = registry.apply_combat_profile_overrides(
		base_profile, ResourceData.ResourceType.WOOD
	)
	var body := Sprite2D.new()
	body.flip_h = false
	body.scale = Vector2(0.5, 0.5)
	var overlay := Sprite2D.new()
	body.add_child(overlay)
	root.add_child(body)
	await process_frame
	var targets: Dictionary = WeaponOverlayCombat.compute_tuned_swing_strike_targets(body, profile)
	var start_rot: float = targets["ready_rot"]
	var end_rot: float = targets["end_rot"]
	var facing: float = WeaponOverlayCombat._swing_facing_sign(body)
	print("=== Club strike timeline (facing right) ===")
	print(
		"  windup B pos=%s rot=%.1f°"
		% [str(targets["ready_pos"]), rad_to_deg(start_rot)]
	)
	print(
		"  strike peak pos=%s rot=%.1f° (saved overlay %s @ %.1f°)"
		% [
			str(targets["hit_pos"]),
			rad_to_deg(end_rot),
			str(profile.get("club_strike_peak_overlay_px", Vector2.ZERO)),
			float(profile.get("attack_rotation_deg", 0.0)),
		]
	)
	var delta_strike: float = rad_to_deg(
		WeaponOverlayCombat._lerp_swing_rotation_rad(start_rot, end_rot, 1.0, facing, true)
		- start_rot
	)
	print("  strike rotation delta: %.1f° (expect + = clockwise away from body)" % delta_strike)
	for t in [0.0, 0.25, 0.5, 0.75, 1.0]:
		var rot: float = WeaponOverlayCombat._lerp_swing_rotation_rad(
			start_rot, end_rot, t, facing, true
		)
		var pos: Vector2 = targets["ready_pos"].lerp(targets["hit_pos"], t)
		print("  t=%.2f  rot=%.1f°  pos=%s" % [t, rad_to_deg(rot), str(pos)])
	print("club_strike_preview: OK")
	quit()
