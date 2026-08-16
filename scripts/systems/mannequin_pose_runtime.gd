extends RefCounted
class_name MannequinPoseRuntime

## Runtime mannequin pose — same overlay + arm endpoint math as LimbTuner.

const LimbPresetCoordsScript = preload("res://scripts/systems/limb_preset_coords.gd")
const MannequinAnchorResolverScript = preload("res://scripts/systems/mannequin_anchor_resolver.gd")
const WeaponOverlayCombatScript = preload("res://scripts/systems/weapon_overlay_combat.gd")
const CardVisualControllerScript = preload("res://scripts/systems/card_visual_controller.gd")
const WalkArmSwingScript = preload("res://scripts/systems/walk_arm_swing.gd")
const WalkArmMotionScript = preload("res://scripts/systems/walk_arm_motion.gd")


static func get_body_visual(sprite: Sprite2D) -> Node:
	if sprite == null:
		return null
	return sprite.get_node_or_null("BodyVisual")


static func uses_mannequin(sprite: Sprite2D) -> bool:
	var body_visual := get_body_visual(sprite)
	if body_visual == null:
		return false
	if body_visual.has_method("get_body_sprite"):
		return body_visual.call("get_body_sprite") != null
	return false


static func rig_local(rig: Node2D, global_pos: Vector2) -> Vector2:
	return MannequinAnchorResolverScript.rig_local_from_global(rig, global_pos)


static func apply_idle_overlay(
	sprite: Sprite2D,
	overlay: Sprite2D,
	registry,
	preset: WeaponLimbPreset,
	weapon_type: ResourceData.ResourceType,
	entity: Node = null
) -> void:
	if sprite == null or overlay == null or preset == null or registry == null:
		return
	var profile: Dictionary = registry.get_weapon_combat_profile(weapon_type)
	if LimbPresetRegistry:
		profile = LimbPresetRegistry.apply_combat_profile_overrides(profile, weapon_type)
	WeaponOverlayCombatScript._ensure_weapon_pivot(overlay, profile)
	var idle_deg: float = preset.idle_rotation_deg
	if absf(idle_deg) < 0.001:
		idle_deg = float(profile.get("idle_rotation_deg", 0.0))
	_apply_overlay_pose(
		sprite,
		overlay,
		registry,
		weapon_type,
		preset.resolve_overlay_for_mode(WeaponLimbPreset.TunerAnimMode.IDLE),
		deg_to_rad(idle_deg),
		WeaponOverlayCombatScript.OverlayState.IDLE,
		entity
	)


static func apply_ready_overlay(
	sprite: Sprite2D,
	overlay: Sprite2D,
	registry,
	preset: WeaponLimbPreset,
	weapon_type: ResourceData.ResourceType,
	aim_dir: Vector2,
	entity: Node = null
) -> void:
	if sprite == null or overlay == null or preset == null or registry == null:
		return
	var profile: Dictionary = registry.get_weapon_combat_profile(weapon_type)
	if LimbPresetRegistry:
		profile = LimbPresetRegistry.apply_combat_profile_overrides(profile, weapon_type)
	var kind: int = int(profile.get("attack_kind", WeaponOverlayCombatScript.AttackKind.SWING_DOWN))
	var rot: float
	var aim := aim_dir.normalized() if aim_dir.length_squared() > 0.0001 else Vector2(1.0, 0.0)
	if kind == WeaponOverlayCombatScript.AttackKind.THRUST:
		sprite.flip_h = aim.x < 0.0
		var tip_deg: float = float(profile.get("texture_tip_deg", -90.0))
		rot = WeaponOverlayCombatScript.compute_aim_rotation(sprite, aim, tip_deg, 0.0)
	else:
		if entity:
			WeaponOverlayCombatScript.sync_swing_body_facing(entity, sprite)
		rot = deg_to_rad(WeaponOverlayCombatScript._swing_ready_degrees(sprite, profile))
	WeaponOverlayCombatScript._ensure_weapon_pivot(overlay, profile)
	var offset_px: Vector2 = preset.ready_offset_px if preset.ready_offset_px.length_squared() > 0.0001 else preset.overlay_offset_idle_px
	_apply_overlay_pose(sprite, overlay, registry, weapon_type, offset_px, rot, WeaponOverlayCombatScript.OverlayState.READY, entity)


static func resolve_arm_endpoints(
	rig: Node2D,
	sprite: Sprite2D,
	overlay: Sprite2D,
	preset: WeaponLimbPreset,
	weapon_type: ResourceData.ResourceType,
	overlay_state: int,
	aim_dir: Vector2,
	moving: bool,
	bounce_time: float,
	idle_raise_blend: float = 0.0,
	idle_scan_blend: float = 0.0,
	idle_lowering: bool = false
) -> Dictionary:
	var body_visual := get_body_visual(sprite)
	var weapon_shoulder_g := MannequinAnchorResolverScript.shoulder_global_from_display(
		sprite, body_visual, preset.shoulder_offset_px
	)
	var support_shoulder_g := MannequinAnchorResolverScript.shoulder_global_from_display(
		sprite, body_visual, preset.support_shoulder_offset_px
	)
	if (
		idle_raise_blend > 0.0001
		and preset.has_idle_support_shoulder_raise()
		and overlay_state == WeaponOverlayCombatScript.OverlayState.IDLE
		and not moving
	):
		support_shoulder_g = MannequinAnchorResolverScript.shoulder_global_from_display(
			sprite,
			body_visual,
			preset.resolve_support_shoulder_for_idle_raise(idle_raise_blend, idle_lowering)
		)
	var weapon_hand_g := _weapon_hand_global(sprite, overlay, preset, weapon_type, overlay_state, moving)
	var support_hand_g := _support_hand_global(sprite, overlay, preset, weapon_type, overlay_state, moving)
	if (
		idle_raise_blend > 0.0001
		and preset.has_idle_arm2_raise_pose()
		and overlay_state == WeaponOverlayCombatScript.OverlayState.IDLE
		and not moving
	):
		support_hand_g = LimbPresetCoordsScript.body_global_from_display(
			sprite,
			preset.resolve_support_hand_idle_for_idle_scan(
				idle_raise_blend, idle_scan_blend, idle_lowering
			)
		)
	if moving and overlay_state == WeaponOverlayCombatScript.OverlayState.IDLE:
		if uses_walk1_keyframe_walk(preset):
			if preset.uses_club_walk_off_arm_travel_swing():
				weapon_hand_g = LimbPresetCoordsScript.body_global_from_display(
					sprite, preset.resolve_club_carry_body_hand_px()
				)
				var off_arm_preset := _club_walk_off_arm_keyframe_preset(preset)
				support_hand_g = walk1_keyframe_hand_global(
					rig, sprite, off_arm_preset, support_shoulder_g, false, bounce_time
				)
			else:
				weapon_hand_g = walk1_keyframe_hand_global(
					rig, sprite, preset, weapon_shoulder_g, true, bounce_time
				)
				support_hand_g = walk1_keyframe_hand_global(
					rig, sprite, preset, support_shoulder_g, false, bounce_time
				)
		else:
			var travel_sign := _travel_sign(rig, sprite, aim_dir)
			var weapon_overlay_carries := (
				overlay != null
				and overlay.visible
				and (
					weapon_type == ResourceData.ResourceType.WOOD
					or weapon_type == ResourceData.ResourceType.SPEAR
				)
			)
			if not weapon_overlay_carries:
				weapon_hand_g = _apply_walk_swing_global(
					rig, weapon_shoulder_g, weapon_hand_g, bounce_time, true, travel_sign, weapon_type
				)
			support_hand_g = _apply_walk_swing_global(
				rig, support_shoulder_g, support_hand_g, bounce_time, false, travel_sign, weapon_type
			)
	return {
		"weapon_shoulder": rig_local(rig, weapon_shoulder_g),
		"weapon_hand": rig_local(rig, weapon_hand_g),
		"support_shoulder": rig_local(rig, support_shoulder_g),
		"support_hand": rig_local(rig, support_hand_g),
	}


static func _weapon_hand_global(
	sprite: Sprite2D,
	overlay: Sprite2D,
	preset: WeaponLimbPreset,
	weapon_type: ResourceData.ResourceType,
	overlay_state: int,
	moving: bool = false
) -> Vector2:
	if overlay == null or not overlay.visible:
		var grip_px := preset.hand_grip_offset_px
		if moving:
			if preset.uses_club_walk_off_arm_travel_swing():
				grip_px = preset.resolve_club_carry_body_hand_px()
			else:
				grip_px = preset.resolve_walk_rest_hand_grip()
		return LimbPresetCoordsScript.body_global_from_display(sprite, grip_px)
	var grip_px := preset.hand_grip_offset_px
	if moving and preset.uses_club_walk_off_arm_travel_swing():
		grip_px = preset.resolve_club_overlay_grip_px(WeaponLimbPreset.TunerAnimMode.IDLE)
	elif overlay_state != WeaponOverlayCombatScript.OverlayState.IDLE:
		if preset.hand_grip_ready_offset_px.length_squared() > 0.0001:
			grip_px = preset.hand_grip_ready_offset_px
		elif WeaponLimbPreset.uses_two_hand_grip(weapon_type):
			grip_px = preset.hand_grip_offset_px
	return LimbPresetCoordsScript.overlay_grip_global(overlay, grip_px)


static func _support_hand_global(
	sprite: Sprite2D,
	overlay: Sprite2D,
	preset: WeaponLimbPreset,
	weapon_type: ResourceData.ResourceType,
	overlay_state: int,
	moving: bool = false
) -> Vector2:
	if (
		overlay_state != WeaponOverlayCombatScript.OverlayState.IDLE
		and WeaponLimbPreset.uses_two_hand_grip(weapon_type)
		and not preset.attack_pose_inherits_idle()
	):
		if overlay:
			return LimbPresetCoordsScript.overlay_grip_global(overlay, preset.support_hand_offset_px)
	var support_px := (
		preset.resolve_walk_rest_support_hand()
		if moving
		else preset.resolve_support_hand_for_mode(WeaponLimbPreset.TunerAnimMode.IDLE)
	)
	return LimbPresetCoordsScript.body_global_from_display(sprite, support_px)


static func _apply_overlay_pose(
	sprite: Sprite2D,
	overlay: Sprite2D,
	registry,
	weapon_type: ResourceData.ResourceType,
	display_px: Vector2,
	rotation_rad: float,
	overlay_state: int,
	entity: Node
) -> void:
	var sx: float = absf(sprite.scale.x)
	if sx < 0.001:
		sx = 1.0
	var base_unflipped := Vector2(display_px.x / sx, display_px.y / sx)
	overlay.rotation = rotation_rad
	overlay.set_meta("card_overlay_offset", base_unflipped)
	var mirror_tex: bool = WeaponOverlayCombatScript._overlay_mirror_texture(registry, weapon_type)
	CardVisualControllerScript.sync_weapon_overlay_flip(sprite, overlay, base_unflipped, mirror_tex, 0.0)
	if entity:
		WeaponOverlayCombatScript.set_overlay_state(entity, overlay_state)


static func _travel_sign(rig: Node2D, sprite: Sprite2D, aim_dir: Vector2) -> float:
	if rig is CharacterBody2D:
		var vel := (rig as CharacterBody2D).velocity
		if absf(vel.x) > 1.0:
			return signf(vel.x)
	if sprite.flip_h:
		return -1.0
	if aim_dir.length_squared() > 0.0001:
		return signf(aim_dir.x) if absf(aim_dir.x) > 0.01 else 1.0
	return 1.0


static func _apply_walk_swing_global(
	rig: Node2D,
	shoulder_global: Vector2,
	hand_global: Vector2,
	bounce_time: float,
	dominant: bool,
	travel_sign: float,
	weapon_type: ResourceData.ResourceType = ResourceData.ResourceType.NONE
) -> Vector2:
	var shoulder_local := rig.to_local(shoulder_global)
	var hand_local := rig.to_local(hand_global)
	var sx: float = 1.0
	if rig.get_node_or_null("Sprite") is Sprite2D:
		sx = absf((rig.get_node("Sprite") as Sprite2D).scale.x)
		if sx < 0.001:
			sx = 1.0
	var rest_offset := (hand_local - shoulder_local) / sx
	var swung_offset := WalkArmSwingScript.swing_hand_local_offset(
		rest_offset,
		WalkArmSwingScript.swing_phase_from_bounce(bounce_time),
		dominant,
		travel_sign,
		weapon_type
	) * sx
	return rig.to_global(shoulder_local + swung_offset)


static func uses_walk1_keyframe_walk(preset: WeaponLimbPreset) -> bool:
	return preset != null and preset.walk1_pose_a_saved


static func _club_walk_off_arm_keyframe_preset(club_preset: WeaponLimbPreset) -> WeaponLimbPreset:
	if club_preset == null or not club_preset.uses_club_walk_off_arm_travel_swing():
		return club_preset
	if LimbPresetRegistry != null:
		var none_preset: WeaponLimbPreset = LimbPresetRegistry.get_preset(
			ResourceData.ResourceType.NONE, "clansmen_1", 1
		)
		if none_preset != null and none_preset.walk1_pose_a_saved:
			return none_preset
	return club_preset


static func walk1_keyframe_hand_global(
	rig: Node2D,
	sprite: Sprite2D,
	preset: WeaponLimbPreset,
	shoulder_global: Vector2,
	dominant: bool,
	bounce_time: float
) -> Vector2:
	if preset == null or sprite == null or rig == null:
		return shoulder_global
	var phase := WalkArmSwingScript.swing_phase_from_bounce(bounce_time)
	var pose_a_px := (
		preset.walk1_hand_grip_offset_px if dominant else preset.walk1_support_hand_offset_px
	)
	if pose_a_px.length_squared() < 0.0001:
		pose_a_px = (
			preset.hand_grip_offset_px if dominant else preset.support_hand_idle_offset_px
		)
	var pose_a_global := LimbPresetCoordsScript.body_global_from_display(sprite, pose_a_px)
	if not preset.has_walk1_pull_pose():
		return pose_a_global
	var sx: float = absf(sprite.scale.x)
	if sx < 0.001:
		sx = 1.0
	var shoulder_local := rig.to_local(shoulder_global)
	var pose_a_local := rig.to_local(pose_a_global)
	var pose_a_offset := (pose_a_local - shoulder_local) / sx
	var pull_px := (
		preset.walk1_pull_hand_grip_offset_px if dominant else preset.walk1_pull_support_hand_offset_px
	)
	var pose_b_global := LimbPresetCoordsScript.body_global_from_display(sprite, pull_px)
	var pose_b_local := rig.to_local(pose_b_global)
	var pose_b_offset := (pose_b_local - shoulder_local) / sx
	var motion_offset := WalkArmMotionScript.hand_offset_between_keyframes(
		pose_a_offset, pose_b_offset, phase, dominant
	) * sx
	return rig.to_global(shoulder_local + motion_offset)


static func align_overlay_grip_to_hand_global(
	sprite: Sprite2D,
	overlay: Sprite2D,
	grip_px: Vector2,
	hand_global: Vector2
) -> void:
	if sprite == null or overlay == null:
		return
	var grip_local := Vector2(grip_px.x * overlay.scale.x, grip_px.y * overlay.scale.y)
	var grip_global := overlay.to_global(grip_local)
	overlay.global_position += hand_global - grip_global
