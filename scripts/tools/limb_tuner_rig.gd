extends CharacterBody2D
class_name LimbTunerRig

## Minimal player-like rig for LimbTuner — same node layout as Player for shared combat/arm code.

const CardVisualController = preload("res://scripts/systems/card_visual_controller.gd")
const WeaponOverlayCombat = preload("res://scripts/systems/weapon_overlay_combat.gd")
const LimbPresetCoords = preload("res://scripts/systems/limb_preset_coords.gd")
const TunerWalkPreview = preload("res://scripts/tools/tuner_walk_preview.gd")
const TunerMannequinLayoutScript = preload("res://scripts/tools/tuner_mannequin_layout.gd")
const CharacterCardPartsRegistry = preload("res://scripts/config/character_card_parts_registry.gd")

## Tuner handle 3 — center of bottom quarter of overlay texture (normalized Y from top).
const WEAPON_HANDLE_Y_FRAC := 0.875

var aim_dir: Vector2 = Vector2(1.0, 0.0)
var body_card_index: int = 1
var weapon_type: ResourceData.ResourceType = ResourceData.ResourceType.SPEAR

@onready var sprite: Sprite2D = $Sprite
@onready var body_visual: Node2D = $Sprite/BodyVisual
@onready var weapon_overlay: Sprite2D = $Sprite/WeaponOverlay
@onready var combat_component: CombatComponent = $CombatComponent
@onready var arm_controller: ProceduralArmController = $ProceduralArmController

var _anchor_foot_y: float = -64.0
var _mannequin_layout
var _walk := TunerWalkPreview.new()
var _registry = PlaceholderCardRegistry.new()
var _last_overlay_base := Vector2.ZERO


func _ready() -> void:
	add_to_group("player")
	if combat_component:
		combat_component.initialize(self)
		combat_component.windup_time = 0.1
		combat_component.recovery_time = 0.22
	if arm_controller:
		arm_controller.body_card_id = "clansmen_1"
	_setup_mannequin_anchor()
	_show_weapon_overlay()


func _process(delta: float) -> void:
	_update_walk_preview(delta)


func set_walk_direction(dir: int) -> void:
	_walk.set_direction(dir)


func is_walking() -> bool:
	return _walk.is_moving()


func get_walk_direction() -> int:
	return _walk.direction


func get_walk_phase() -> float:
	return _walk.walk_phase


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


func _setup_mannequin_anchor() -> void:
	if sprite == null:
		return
	_mannequin_layout = TunerMannequinLayoutScript.from_registry(_registry, body_card_index)
	sprite.texture = null
	sprite.region_enabled = false
	sprite.hframes = 1
	sprite.vframes = 1
	sprite.frame = 0
	sprite.scale = Vector2.ONE * _mannequin_layout.sprite_scale
	_anchor_foot_y = _mannequin_layout.foot_y
	sprite.position = Vector2(0.0, _anchor_foot_y)
	set_meta("card_index", body_card_index)
	if body_visual and body_visual.has_method("apply_layout"):
		body_visual.call("apply_layout", _mannequin_layout)


func get_layer_layout() -> CharacterCardLayerLayout:
	if body_visual and body_visual.has_method("get_layer_layout"):
		return body_visual.call("get_layer_layout") as CharacterCardLayerLayout
	return CharacterCardPartsRegistry.get_layout()


func neck_socket_global() -> Vector2:
	if body_visual and body_visual.has_method("neck_socket_global"):
		return body_visual.call("neck_socket_global")
	return global_position


func set_neck_socket_from_global(global_pos: Vector2) -> void:
	if body_visual and body_visual.has_method("set_neck_socket_from_global"):
		body_visual.call("set_neck_socket_from_global", global_pos)


func _update_walk_preview(delta: float) -> void:
	if sprite == null:
		return
	_walk.tick(delta)
	var moving := _walk.is_moving()
	if moving:
		sprite.flip_h = _walk.direction < 0
	_walk.bounce_time = CardVisualController.tick_walk_bounce(
		sprite, _anchor_foot_y, _walk.bounce_time, moving, delta
	)
	if body_visual and body_visual.has_method("set_walk_state"):
		body_visual.call("set_walk_state", moving, _walk.bounce_time, _walk.direction)
	_sync_overlay_walk_bounce(moving)


func _sync_overlay_walk_bounce(moving: bool) -> void:
	if weapon_overlay == null or sprite == null or not weapon_overlay.visible:
		return
	var base_offset: Vector2 = weapon_overlay.get_meta("card_overlay_offset", _last_overlay_base)
	if base_offset != Vector2.ZERO:
		_last_overlay_base = base_offset
	var bounce_y := 0.0
	if moving:
		bounce_y = CardVisualController.weapon_overlay_walk_bounce_offset_y(_walk.bounce_time, true)
	var mirror_tex: bool = WeaponOverlayCombat._overlay_mirror_texture(_registry, weapon_type)
	CardVisualController.sync_weapon_overlay_flip(sprite, weapon_overlay, base_offset, mirror_tex, bounce_y)


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
	_last_overlay_base = base_unflipped
	var mirror_tex: bool = WeaponOverlayCombat._overlay_mirror_texture(_registry, weapon_type)
	var bounce_y := 0.0
	if _walk.is_moving():
		bounce_y = CardVisualController.weapon_overlay_walk_bounce_offset_y(_walk.bounce_time, true)
	CardVisualController.sync_weapon_overlay_flip(sprite, weapon_overlay, base_unflipped, mirror_tex, bounce_y)
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
	return move_weapon_handle_anchor_global(global_pos)


func _ensure_overlay_pivot() -> void:
	if weapon_overlay == null or sprite == null:
		return
	var profile: Dictionary = _registry.get_weapon_combat_profile(weapon_type)
	if LimbPresetRegistry:
		profile = LimbPresetRegistry.apply_combat_profile_overrides(profile, weapon_type)
	WeaponOverlayCombat._ensure_weapon_pivot(weapon_overlay, profile)


func _texture_frac_to_overlay_local(nx: float, ny: float) -> Vector2:
	if weapon_overlay == null or weapon_overlay.texture == null:
		return Vector2.ZERO
	var tex := weapon_overlay.texture
	var draw_size := Vector2(tex.get_width(), tex.get_height()) * weapon_overlay.scale.abs()
	return Vector2(
		weapon_overlay.offset.x + (nx - 0.5) * draw_size.x,
		weapon_overlay.offset.y + (ny - 0.5) * draw_size.y
	)


func weapon_handle_anchor_local() -> Vector2:
	_ensure_overlay_pivot()
	return _texture_frac_to_overlay_local(0.5, _weapon_handle_y_frac())


func _weapon_handle_y_frac() -> float:
	var profile: Dictionary = _registry.get_weapon_combat_profile(weapon_type)
	if LimbPresetRegistry:
		profile = LimbPresetRegistry.apply_combat_profile_overrides(profile, weapon_type)
	var kind: int = int(profile.get("attack_kind", WeaponOverlayCombat.AttackKind.SWING_DOWN))
	if kind != WeaponOverlayCombat.AttackKind.THRUST:
		return float(profile.get("pivot_y_frac", WEAPON_HANDLE_Y_FRAC))
	return WEAPON_HANDLE_Y_FRAC


func weapon_handle_anchor_global() -> Vector2:
	if weapon_overlay == null:
		return global_position
	return weapon_overlay.to_global(weapon_handle_anchor_local())


func move_weapon_handle_anchor_global(anchor_global: Vector2) -> Vector2:
	if weapon_overlay == null or sprite == null:
		return Vector2.ZERO
	_ensure_overlay_pivot()
	var local := weapon_handle_anchor_local()
	var anchor_offset: Vector2 = weapon_overlay.to_global(local) - weapon_overlay.global_position
	weapon_overlay.global_position = anchor_global - anchor_offset
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


func snap_dominant_hand_grip_to_weapon_anchor(preset: WeaponLimbPreset) -> void:
	if preset == null or weapon_overlay == null:
		return
	var anchor_local := weapon_handle_anchor_local()
	preset.hand_grip_offset_px = LimbPresetCoords.overlay_grip_px_from_global(
		weapon_overlay, weapon_overlay.to_global(anchor_local)
	)


func uses_weapon_grip_anchor_hand() -> bool:
	var profile: Dictionary = _registry.get_weapon_combat_profile(weapon_type)
	if LimbPresetRegistry:
		profile = LimbPresetRegistry.apply_combat_profile_overrides(profile, weapon_type)
	return int(profile.get("attack_kind", WeaponOverlayCombat.AttackKind.SWING_DOWN)) != WeaponOverlayCombat.AttackKind.THRUST


func elbow_pole_global_from_preset(preset: WeaponLimbPreset, dominant: bool, ready_pose: bool) -> Vector2:
	if preset == null or sprite == null:
		return global_position
	var pole_px := preset.resolve_elbow_pole_px(dominant, ready_pose)
	if pole_px.length_squared() < 0.0001:
		return global_position
	return LimbPresetCoords.body_global_from_display(sprite, pole_px)


func set_elbow_pole_from_global(preset: WeaponLimbPreset, dominant: bool, ready_pose: bool, global_pos: Vector2) -> void:
	if preset == null or sprite == null:
		return
	preset.set_elbow_pole_px(
		dominant,
		ready_pose,
		LimbPresetCoords.body_display_from_global(sprite, global_pos)
	)


func elbow_joint_global_from_arms(dominant: bool) -> Vector2:
	if arm_controller == null:
		return global_position
	var endpoints: Dictionary = (
		arm_controller.get_weapon_arm_global_endpoints()
		if dominant
		else arm_controller.get_support_arm_global_endpoints()
	)
	return endpoints.get("elbow", global_position)


func set_elbow_joint_from_global(
	preset: WeaponLimbPreset,
	dominant: bool,
	ready_pose: bool,
	elbow_global: Vector2,
	shoulder_global: Vector2,
	hand_global: Vector2,
	bend_sign: float
) -> void:
	if preset == null or sprite == null:
		return
	var pole_px := LimbPresetCoords.pole_display_from_elbow_global(
		sprite, shoulder_global, hand_global, elbow_global, preset.elbow_hint_outward, bend_sign
	)
	preset.set_elbow_pole_px(dominant, ready_pose, pole_px)


func seed_elbow_pole_if_unset(
	preset: WeaponLimbPreset,
	dominant: bool,
	ready_pose: bool,
	shoulder_global: Vector2,
	hand_global: Vector2,
	bend_sign: float
) -> void:
	if preset == null or sprite == null:
		return
	if preset.resolve_elbow_pole_px(dominant, ready_pose).length_squared() > 0.0001:
		return
	var auto_px := LimbPresetCoords.auto_elbow_pole_display_from_global(
		sprite, shoulder_global, hand_global, preset.elbow_hint_outward, bend_sign
	)
	preset.set_elbow_pole_px(dominant, ready_pose, auto_px)


func get_visual_bounds_on_stage() -> Rect2:
	var stage := get_parent() as Node2D
	if stage == null:
		return Rect2()
	var rects: Array[Rect2] = []
	_collect_sprite_rects(self, stage, rects)
	if rects.is_empty():
		return Rect2()
	var merged: Rect2 = rects[0]
	for i in range(1, rects.size()):
		merged = merged.merge(rects[i])
	return merged


func get_visual_center_on_stage() -> Vector2:
	var bounds := get_visual_bounds_on_stage()
	if bounds.size.length_squared() < 1.0:
		return Vector2.ZERO
	return bounds.get_center()


func _collect_sprite_rects(node: Node, stage: Node2D, rects: Array[Rect2]) -> void:
	if node is Sprite2D:
		var sprite := node as Sprite2D
		if sprite.visible and sprite.texture != null:
			var rect := _sprite_rect_on_stage(sprite, stage)
			if rect.size.length_squared() > 0.01:
				rects.append(rect)
	for child in node.get_children():
		_collect_sprite_rects(child, stage, rects)


func _sprite_rect_on_stage(sprite: Sprite2D, stage: Node2D) -> Rect2:
	var tex := sprite.texture
	if tex == null:
		return Rect2()
	var draw_size := Vector2(tex.get_width(), tex.get_height()) * sprite.scale.abs()
	var half := draw_size * 0.5 if sprite.centered else Vector2.ZERO
	var corners := [
		Vector2(-half.x, -half.y) + sprite.offset,
		Vector2(half.x, -half.y) + sprite.offset,
		Vector2(half.x, half.y) + sprite.offset,
		Vector2(-half.x, half.y) + sprite.offset,
	]
	var xf := sprite.global_transform
	var rect := Rect2()
	for i in corners.size():
		var stage_pt := stage.to_local(xf * corners[i])
		if i == 0:
			rect = Rect2(stage_pt, Vector2.ZERO)
		else:
			rect = rect.expand(stage_pt)
	return rect


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
