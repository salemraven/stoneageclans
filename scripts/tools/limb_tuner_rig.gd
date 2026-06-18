extends CharacterBody2D
class_name LimbTunerRig

## Minimal player-like rig for LimbTuner — same node layout as Player for shared combat/arm code.

const CardVisualController = preload("res://scripts/systems/card_visual_controller.gd")
const WeaponOverlayCombat = preload("res://scripts/systems/weapon_overlay_combat.gd")
const LimbPresetCoords = preload("res://scripts/systems/limb_preset_coords.gd")

var aim_dir: Vector2 = Vector2(1.0, 0.0)
var body_card_index: int = 1
var weapon_type: ResourceData.ResourceType = ResourceData.ResourceType.SPEAR

@onready var sprite: Sprite2D = $Sprite
@onready var weapon_overlay: Sprite2D = $Sprite/WeaponOverlay
@onready var combat_component: CombatComponent = $CombatComponent
@onready var arm_controller: ProceduralArmController = $ProceduralArmController

var _card_foot_y: float = -64.0
var _registry = PlaceholderCardRegistry.new()


func _ready() -> void:
	add_to_group("player")
	if combat_component:
		combat_component.initialize(self)
		combat_component.windup_time = 0.1
		combat_component.recovery_time = 0.22
	if arm_controller:
		arm_controller.body_card_id = "clansmen_1"
	_apply_body_card(body_card_index)
	_show_weapon_overlay()


func refresh_weapon_overlay() -> void:
	_show_weapon_overlay()


func get_equipped_weapon_type() -> ResourceData.ResourceType:
	return weapon_type


func _get_cursor_aim_direction() -> Vector2:
	var mp := get_global_mouse_position()
	var delta := mp - global_position
	if delta.length_squared() > 4.0:
		return delta.normalized()
	return aim_dir


func _apply_body_card(card_index: int) -> void:
	body_card_index = card_index
	var texture: Texture2D = _registry.get_clansmen_card(card_index)
	if texture == null or sprite == null:
		return
	_card_foot_y = CardVisualController.apply_card_layout(sprite, texture, _registry)
	set_meta("card_index", card_index)


func _show_weapon_overlay() -> void:
	if weapon_overlay == null or sprite == null:
		return
	var tex: Texture2D = _registry.get_tool_overlay(weapon_type)
	if tex == null:
		return
	weapon_overlay.texture = tex
	var overlay_scale: float = _registry.get_tool_overlay_scale(weapon_type)
	weapon_overlay.scale = Vector2(overlay_scale, overlay_scale)
	weapon_overlay.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	weapon_overlay.visible = true
	WeaponOverlayCombat.set_overlay_state(self, WeaponOverlayCombat.OverlayState.IDLE)


func apply_preset_overlay_idle(preset: WeaponLimbPreset) -> void:
	if preset == null or sprite == null or weapon_overlay == null:
		return
	var profile: Dictionary = _registry.get_weapon_combat_profile(weapon_type)
	if LimbPresetRegistry:
		profile = LimbPresetRegistry.apply_combat_profile_overrides(profile, weapon_type)
	WeaponOverlayCombat._ensure_weapon_pivot(weapon_overlay, profile)
	var idle_deg: float = preset.idle_rotation_deg
	if absf(idle_deg) < 0.001:
		idle_deg = float(profile.get("idle_rotation_deg", 0.0))
	_apply_tuner_overlay_pose(
		preset.overlay_offset_idle_px,
		deg_to_rad(idle_deg),
		WeaponOverlayCombat.OverlayState.IDLE
	)


func apply_preset_overlay_ready(preset: WeaponLimbPreset, aim: Vector2) -> void:
	if preset == null or sprite == null or weapon_overlay == null:
		return
	aim_dir = aim.normalized() if aim.length_squared() > 0.0001 else Vector2(1.0, 0.0)
	var profile: Dictionary = _registry.get_weapon_combat_profile(weapon_type)
	if LimbPresetRegistry:
		profile = LimbPresetRegistry.apply_combat_profile_overrides(profile, weapon_type)
	var kind: int = int(profile.get("attack_kind", WeaponOverlayCombat.AttackKind.SWING_DOWN))
	var rot: float
	if kind == WeaponOverlayCombat.AttackKind.THRUST:
		if sprite:
			sprite.flip_h = aim_dir.x < 0.0
		var tip_deg: float = float(profile.get("texture_tip_deg", -90.0))
		rot = WeaponOverlayCombat.compute_aim_rotation(sprite, aim_dir, tip_deg, 0.0)
	else:
		WeaponOverlayCombat.sync_swing_body_facing(self, sprite)
		rot = deg_to_rad(WeaponOverlayCombat._swing_ready_degrees(sprite, profile))
	WeaponOverlayCombat._ensure_weapon_pivot(weapon_overlay, profile)
	_apply_tuner_overlay_pose(preset.ready_offset_px, rot, WeaponOverlayCombat.OverlayState.READY)


func _apply_tuner_overlay_pose(display_px: Vector2, rotation_rad: float, overlay_state: int) -> void:
	var sx: float = absf(sprite.scale.x)
	if sx < 0.001:
		sx = 1.0
	var base_unflipped := Vector2(display_px.x / sx, display_px.y / sx)
	weapon_overlay.rotation = rotation_rad
	weapon_overlay.set_meta("card_overlay_offset", base_unflipped)
	var mirror_tex: bool = WeaponOverlayCombat._overlay_mirror_texture(_registry, weapon_type)
	CardVisualController.sync_weapon_overlay_flip(sprite, weapon_overlay, base_unflipped, mirror_tex)
	WeaponOverlayCombat.set_overlay_state(self, overlay_state)


func display_px_from_overlay_position() -> Vector2:
	return LimbPresetCoords.overlay_display_from_position(sprite, weapon_overlay)


func display_px_from_global(global_pos: Vector2) -> Vector2:
	return LimbPresetCoords.body_display_from_global(sprite, global_pos)


func set_overlay_from_display_px(display_px: Vector2) -> void:
	if sprite == null or weapon_overlay == null:
		return
	var sx: float = absf(sprite.scale.x)
	if sx < 0.001:
		sx = 1.0
	var base_unflipped := Vector2(display_px.x / sx, display_px.y / sx)
	weapon_overlay.set_meta("card_overlay_offset", base_unflipped)
	CardVisualController.sync_weapon_overlay_flip(sprite, weapon_overlay, base_unflipped, true)


func move_weapon_overlay_global(global_pos: Vector2) -> Vector2:
	if weapon_overlay == null or sprite == null:
		return Vector2.ZERO
	weapon_overlay.global_position = global_pos
	return display_px_from_overlay_position()


func shoulder_global_from_preset(preset: WeaponLimbPreset) -> Vector2:
	return LimbPresetCoords.body_global_from_display(sprite, preset.shoulder_offset_px)


func set_shoulder_from_global(preset: WeaponLimbPreset, global_pos: Vector2) -> void:
	if preset == null:
		return
	preset.shoulder_offset_px = LimbPresetCoords.body_display_from_global(sprite, global_pos)


func support_shoulder_global_from_preset(preset: WeaponLimbPreset) -> Vector2:
	return LimbPresetCoords.body_global_from_display(sprite, preset.support_shoulder_offset_px)


func set_support_shoulder_from_global(preset: WeaponLimbPreset, global_pos: Vector2) -> void:
	if preset == null:
		return
	preset.support_shoulder_offset_px = LimbPresetCoords.body_display_from_global(sprite, global_pos)


func support_hand_idle_global_from_preset(preset: WeaponLimbPreset) -> Vector2:
	return LimbPresetCoords.body_global_from_display(sprite, preset.support_hand_idle_offset_px)


func set_support_hand_idle_from_global(preset: WeaponLimbPreset, global_pos: Vector2) -> void:
	if preset == null:
		return
	preset.support_hand_idle_offset_px = LimbPresetCoords.body_display_from_global(sprite, global_pos)


func support_hand_global_from_preset(preset: WeaponLimbPreset) -> Vector2:
	return LimbPresetCoords.overlay_grip_global(weapon_overlay, preset.support_hand_offset_px)


func set_support_hand_from_global(preset: WeaponLimbPreset, global_pos: Vector2) -> void:
	if preset == null:
		return
	preset.support_hand_offset_px = LimbPresetCoords.overlay_grip_px_from_global(weapon_overlay, global_pos)


func hand_grip_global_from_preset(preset: WeaponLimbPreset, ready_pose: bool = false) -> Vector2:
	var grip_px := preset.resolve_hand_grip_ready_px() if ready_pose else preset.hand_grip_offset_px
	return LimbPresetCoords.overlay_grip_global(weapon_overlay, grip_px)


func set_hand_grip_from_global(preset: WeaponLimbPreset, global_pos: Vector2, ready_pose: bool = false) -> void:
	if preset == null:
		return
	var grip_px := LimbPresetCoords.overlay_grip_px_from_global(weapon_overlay, global_pos)
	if ready_pose:
		preset.hand_grip_ready_offset_px = grip_px
	else:
		preset.hand_grip_offset_px = grip_px


func sync_combat_overlay(hold_ready: bool) -> void:
	if weapon_overlay == null or not weapon_overlay.visible:
		return
	var ostate: int = WeaponOverlayCombat.get_overlay_state(self)
	if ostate == WeaponOverlayCombat.OverlayState.STRIKING:
		return
	if hold_ready:
		aim_dir = _get_cursor_aim_direction()
		if PlaceholderCardService:
			PlaceholderCardService.update_weapon_overlay_combat(self, weapon_type, aim_dir)
		if combat_component and combat_component.state == CombatComponent.CombatState.READY:
			combat_component.update_ready_aim(aim_dir)
	elif combat_component and combat_component.state == CombatComponent.CombatState.READY:
		combat_component.update_ready_aim(aim_dir)
		if PlaceholderCardService:
			PlaceholderCardService.update_weapon_overlay_combat(self, weapon_type, aim_dir)
