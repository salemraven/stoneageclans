extends Node2D
class_name ProceduralArmController

const ProceduralArmConfigScript = preload("res://scripts/systems/procedural_arm_config.gd")
const ProceduralArmScript = preload("res://scripts/systems/procedural_arm.gd")
const WeaponOverlayCombat = preload("res://scripts/systems/weapon_overlay_combat.gd")
const LimbPresetCoords = preload("res://scripts/systems/limb_preset_coords.gd")

const THRUST_SUPPORT_SHOULDER_FOLLOW := 0.1

@export var config: ProceduralArmConfigScript
@export var enabled: bool = true
@export var debug_draw: bool = false
@export var body_card_id: String = "clansmen_1"

var _player: CharacterBody2D
var _arm_left: ProceduralArm
var _arm_right: ProceduralArm
var _weapon_endpoints_override: bool = false
var _weapon_shoulder_override := Vector2.ZERO
var _weapon_hand_override := Vector2.ZERO
var _support_endpoints_override: bool = false
var _support_shoulder_override := Vector2.ZERO
var _support_hand_override := Vector2.ZERO
var _overlay_rest_local := Vector2.ZERO
var _overlay_motion_active: bool = false


func _ready() -> void:
	_player = get_parent() as CharacterBody2D
	if config == null:
		config = ProceduralArmConfigScript.new()
	_apply_draw_layer()
	_arm_left = ProceduralArmScript.new()
	_arm_right = ProceduralArmScript.new()
	_arm_left.setup(self, "L", config)
	_arm_right.setup(self, "R", config)
	_apply_debug_state()


func _apply_draw_layer() -> void:
	z_as_relative = false
	if YSortUtils:
		z_index = YSortUtils.Z_ABOVE_WORLD
	elif config:
		z_index = config.arm_z_index


func _process(_delta: float) -> void:
	if not enabled or _player == null or config == null:
		_set_arms_visible(false)
		return
	var sprite: Sprite2D = _player.get_node_or_null("Sprite") as Sprite2D
	if sprite == null or not sprite.visible:
		_set_arms_visible(false)
		return

	# Stay in player-local space so IK points (sprite.position + offsets) line up with the card.
	if get_parent() == _player:
		position = Vector2.ZERO
		rotation = 0.0
		scale = Vector2.ONE
	else:
		global_position = _player.global_position
		global_rotation = 0.0
		scale = Vector2.ONE

	var weapon_type := _get_weapon_type()
	_apply_limb_preset(weapon_type)

	var overlay: Sprite2D = sprite.get_node_or_null("WeaponOverlay") as Sprite2D
	if not _should_show_weapon_arms(overlay, weapon_type):
		_set_arms_visible(false)
		return

	var sprite_scale := sprite.scale
	var thrust_active := is_thrust_active()
	_update_overlay_rest(overlay, thrust_active)
	var thrust_motion := _overlay_motion_delta_rig(sprite, overlay, sprite_scale)

	var shoulder_weapon := _weapon_shoulder_local(sprite, sprite_scale)
	var hand_grip := _hand_grip_local(sprite, overlay, sprite_scale)
	if _weapon_endpoints_override:
		shoulder_weapon = _weapon_shoulder_override
		hand_grip = _weapon_hand_override

	var aiming_left := _is_aiming_left()
	var support_shoulder := _support_shoulder_local(sprite, config.shoulder_offset_left, sprite_scale)
	var support_hand := _support_hand_target_local(sprite, overlay, sprite_scale)
	if _support_endpoints_override:
		support_shoulder = _support_shoulder_override
		support_hand = _support_hand_override
	if thrust_active:
		var counter_motion := _thrust_counter_motion(sprite, thrust_motion)
		support_shoulder += counter_motion * THRUST_SUPPORT_SHOULDER_FOLLOW

	var ready_poles := is_overlay_hand_tracking_active() or thrust_active
	var weapon_pole := _resolve_elbow_pole_local(sprite, config.weapon_elbow_pole_ready_px if ready_poles else config.weapon_elbow_pole_idle_px, sprite_scale)
	var support_pole := _resolve_elbow_pole_local(sprite, config.support_elbow_pole_ready_px if ready_poles else config.support_elbow_pole_idle_px, sprite_scale)
	var use_weapon_pole := weapon_pole.length_squared() > 0.0001
	var use_support_pole := support_pole.length_squared() > 0.0001

	if aiming_left:
		_arm_left.update_arm(shoulder_weapon, hand_grip, config, -1.0, sprite_scale, weapon_pole, use_weapon_pole)
		_arm_right.update_arm(support_shoulder, support_hand, config, 1.0, sprite_scale, support_pole, use_support_pole)
	else:
		_arm_right.update_arm(shoulder_weapon, hand_grip, config, 1.0, sprite_scale, weapon_pole, use_weapon_pole)
		_arm_left.update_arm(support_shoulder, support_hand, config, -1.0, sprite_scale, support_pole, use_support_pole)

	_set_arms_visible(true)
	_apply_debug_state()


func set_show_elbow_joints(on: bool) -> void:
	if config:
		config.show_elbow_joints = on
	if _arm_left:
		_arm_left.set_show_elbow_joints(on)
	if _arm_right:
		_arm_right.set_show_elbow_joints(on)
	_apply_debug_state()


func set_debug_draw(on: bool) -> void:
	debug_draw = on
	_apply_debug_state()


func toggle_debug_draw() -> bool:
	debug_draw = not debug_draw
	_apply_debug_state()
	return debug_draw


## Limb tuner: lock shoulder anchors; hands always grip the spear overlay.
func set_weapon_shoulder_from_global(shoulder_global: Vector2) -> void:
	_weapon_endpoints_override = true
	_weapon_shoulder_override = to_local(shoulder_global)


func set_weapon_endpoints_from_global(shoulder_global: Vector2, hand_global: Vector2) -> void:
	set_weapon_shoulder_from_global(shoulder_global)
	_weapon_hand_override = to_local(hand_global)


func clear_weapon_endpoint_override() -> void:
	_weapon_endpoints_override = false


func set_support_shoulder_from_global(shoulder_global: Vector2) -> void:
	_support_endpoints_override = true
	_support_shoulder_override = to_local(shoulder_global)


func set_support_endpoints_from_global(shoulder_global: Vector2, hand_global: Vector2) -> void:
	set_support_shoulder_from_global(shoulder_global)
	_support_hand_override = to_local(hand_global)


func clear_support_endpoint_override() -> void:
	_support_endpoints_override = false


func clear_all_endpoint_overrides() -> void:
	clear_weapon_endpoint_override()
	clear_support_endpoint_override()


func get_weapon_arm_global_endpoints() -> Dictionary:
	var active_arm: ProceduralArm = _arm_right if not _is_aiming_left() else _arm_left
	if active_arm == null:
		return {"shoulder": global_position, "hand": global_position}
	var joints: Dictionary = active_arm.get_last_joint_positions()
	return {
		"shoulder": to_global(joints.get("shoulder", Vector2.ZERO)),
		"hand": to_global(joints.get("hand", Vector2.ZERO)),
	}


func get_support_arm_global_endpoints() -> Dictionary:
	var active_arm: ProceduralArm = _arm_left if not _is_aiming_left() else _arm_right
	if active_arm == null:
		return {"shoulder": global_position, "hand": global_position}
	var joints: Dictionary = active_arm.get_last_joint_positions()
	return {
		"shoulder": to_global(joints.get("shoulder", Vector2.ZERO)),
		"hand": to_global(joints.get("hand", Vector2.ZERO)),
	}


func is_combat_pose_active() -> bool:
	return is_overlay_hand_tracking_active() or is_thrust_active()


func is_thrust_active() -> bool:
	if _player == null:
		return false
	if WeaponOverlayCombat.get_overlay_state(_player) == WeaponOverlayCombat.OverlayState.STRIKING:
		return true
	var combat: CombatComponent = _player.get_node_or_null("CombatComponent") as CombatComponent
	return combat != null and combat.state == CombatComponent.CombatState.WINDUP


func is_overlay_hand_tracking_active() -> bool:
	if _player == null:
		return false
	return WeaponOverlayCombat.get_overlay_state(_player) != WeaponOverlayCombat.OverlayState.IDLE


func set_show_endpoint_markers(on: bool) -> void:
	if _arm_left:
		_arm_left.set_endpoint_markers_visible(on)
	if _arm_right:
		_arm_right.set_endpoint_markers_visible(on)


func _apply_limb_preset(weapon_type: ResourceData.ResourceType) -> void:
	if LimbPresetRegistry == null or config == null:
		return
	var preset := LimbPresetRegistry.get_preset(weapon_type, body_card_id)
	LimbPresetRegistry.apply_to_arm_config(config, preset)


func _apply_debug_state() -> void:
	var show_debug := debug_draw or _debug_config_enabled()
	var show_elbows := config != null and config.show_elbow_joints
	if _arm_left:
		_arm_left.set_debug_enabled(show_debug)
		_arm_left.set_show_elbow_joints(show_elbows)
	if _arm_right:
		_arm_right.set_debug_enabled(show_debug)
		_arm_right.set_show_elbow_joints(show_elbows)


func _debug_config_enabled() -> bool:
	var dc := get_node_or_null("/root/DebugConfig")
	return dc != null and bool(dc.get("enable_procedural_arms_debug"))


func _set_arms_visible(visible_arms: bool) -> void:
	if _arm_left:
		_arm_left.set_visible_arm(visible_arms)
	if _arm_right:
		_arm_right.set_visible_arm(visible_arms)


func _should_show_weapon_arms(overlay: Sprite2D, weapon_type: ResourceData.ResourceType) -> bool:
	if overlay == null or not overlay.visible:
		return false
	return weapon_type == ResourceData.ResourceType.SPEAR or weapon_type == ResourceData.ResourceType.WOOD


func _resolve_elbow_pole_local(sprite: Sprite2D, pole_display_px: Vector2, _sprite_scale: Vector2) -> Vector2:
	if pole_display_px.length_squared() < 0.0001:
		return Vector2.ZERO
	return LimbPresetCoords.body_display_to_rig_local(sprite, pole_display_px)


func _get_weapon_type() -> ResourceData.ResourceType:
	if _player.has_method("get_equipped_weapon_type"):
		return _player.get_equipped_weapon_type()
	if _player.get("_equipped_item") != null:
		return _player.get("_equipped_item") as ResourceData.ResourceType
	return ResourceData.ResourceType.NONE


func _is_aiming_left() -> bool:
	if _player.get("aim_dir") != null:
		var aim: Vector2 = _player.get("aim_dir") as Vector2
		if aim.length_squared() > 0.0001:
			return aim.x < 0.0
	var sprite: Sprite2D = _player.get_node_or_null("Sprite") as Sprite2D
	return sprite != null and sprite.flip_h


func _weapon_shoulder_offset_px() -> Vector2:
	if config.weapon_shoulder_offset_px.length_squared() > 0.0001:
		return config.weapon_shoulder_offset_px
	return config.card_center_offset


func _weapon_shoulder_local(sprite: Sprite2D, sprite_scale: Vector2) -> Vector2:
	var offset := _flip_offset_x(_weapon_shoulder_offset_px(), sprite.flip_h)
	return sprite.position + Vector2(offset.x * sprite_scale.x, offset.y * sprite_scale.y)


func _hand_grip_local(sprite: Sprite2D, overlay: Sprite2D, sprite_scale: Vector2) -> Vector2:
	var grip_px := config.hand_grip_offset_px
	if is_overlay_hand_tracking_active() and config.hand_grip_ready_offset_px.length_squared() > 0.0001:
		grip_px = config.hand_grip_ready_offset_px
	return _grip_on_overlay_local(sprite, overlay, grip_px)


func _support_hand_grip_local(sprite: Sprite2D, overlay: Sprite2D, _sprite_scale: Vector2) -> Vector2:
	return _grip_on_overlay_local(sprite, overlay, config.support_hand_grip_offset_px)


func _support_hand_idle_local(sprite: Sprite2D, sprite_scale: Vector2) -> Vector2:
	var offset := _flip_offset_x(config.support_hand_idle_offset_px, sprite.flip_h)
	return sprite.position + Vector2(offset.x * sprite_scale.x, offset.y * sprite_scale.y)


func _support_hand_target_local(sprite: Sprite2D, overlay: Sprite2D, sprite_scale: Vector2) -> Vector2:
	if _use_two_hand_spear_grip():
		return _support_hand_grip_local(sprite, overlay, sprite_scale)
	return _support_hand_idle_local(sprite, sprite_scale)


func _use_two_hand_spear_grip() -> bool:
	if _get_weapon_type() != ResourceData.ResourceType.SPEAR:
		return false
	return is_overlay_hand_tracking_active() or is_thrust_active()


func _grip_on_overlay_local(sprite: Sprite2D, overlay: Sprite2D, grip_px: Vector2) -> Vector2:
	var overlay_scale := overlay.scale
	var grip_overlay_local := Vector2(grip_px.x * overlay_scale.x, grip_px.y * overlay_scale.y)
	var grip_global := overlay.to_global(grip_overlay_local)
	# Convert to player-local (where arm controller draws), not sprite-local
	var player := sprite.get_parent() as Node2D
	if player:
		return player.to_local(grip_global)
	return sprite.to_local(grip_global)


func _support_shoulder_local(sprite: Sprite2D, offset_px: Vector2, sprite_scale: Vector2) -> Vector2:
	var offset := _flip_offset_x(offset_px, sprite.flip_h)
	return sprite.position + Vector2(offset.x * sprite_scale.x, offset.y * sprite_scale.y)


func _flip_offset_x(offset_px: Vector2, flip_h: bool) -> Vector2:
	if flip_h:
		return Vector2(-offset_px.x, offset_px.y)
	return offset_px


func _update_overlay_rest(overlay: Sprite2D, active: bool) -> void:
	if overlay == null:
		return
	if active:
		if not _overlay_motion_active:
			_overlay_rest_local = overlay.position
			_overlay_motion_active = true
	else:
		_overlay_motion_active = false


func _overlay_motion_delta_rig(sprite: Sprite2D, overlay: Sprite2D, sprite_scale: Vector2) -> Vector2:
	if not _overlay_motion_active or sprite == null or overlay == null:
		return Vector2.ZERO
	var delta_sprite := overlay.position - _overlay_rest_local
	return Vector2(delta_sprite.x * sprite_scale.x, delta_sprite.y * sprite_scale.y)


func _thrust_counter_motion(sprite: Sprite2D, thrust_motion: Vector2) -> Vector2:
	var aim := _get_aim_dir(sprite)
	if aim.length_squared() < 0.0001 or thrust_motion.length_squared() < 0.0001:
		return -thrust_motion
	var forward_amount: float = thrust_motion.dot(aim)
	return -aim * forward_amount


func _get_aim_dir(sprite: Sprite2D) -> Vector2:
	if _player.get("aim_dir") != null:
		var aim: Vector2 = _player.get("aim_dir") as Vector2
		if aim.length_squared() > 0.0001:
			return aim.normalized()
	if sprite != null and sprite.flip_h:
		return Vector2.LEFT
	return Vector2.RIGHT
