extends Node2D
class_name ProceduralArmController

const ProceduralArmConfigScript = preload("res://scripts/systems/procedural_arm_config.gd")
const ProceduralArmScript = preload("res://scripts/systems/procedural_arm.gd")
const WeaponOverlayCombat = preload("res://scripts/systems/weapon_overlay_combat.gd")
const LimbPresetCoords = preload("res://scripts/systems/limb_preset_coords.gd")
const WalkArmSwing = preload("res://scripts/systems/walk_arm_swing.gd")
const PlaceholderCardRegistry = preload("res://scripts/config/placeholder_card_registry.gd")
const MannequinAnchorResolver = preload("res://scripts/systems/mannequin_anchor_resolver.gd")
const MannequinPoseRuntime = preload("res://scripts/systems/mannequin_pose_runtime.gd")

const THRUST_SUPPORT_SHOULDER_FOLLOW := 0.1
const THRUST_WEAPON_SHOULDER_FOLLOW := 0.16
## Godot 4.5 clamps canvas z_index to 0..4095 — stay inside that range.
const YSortUtilsScript = preload("res://scripts/systems/y_sort_utils.gd")
## Tuner draw stack (back → front): arm1=0, body=1, head=2, arm2=3
const TUNER_Z_ARM1 := 0
const TUNER_Z_ARM2 := 3

@export var config: ProceduralArmConfigScript
@export var enabled: bool = true
@export var debug_draw: bool = false
@export var force_show_arms: bool = false
@export var use_tuner_arm_layers: bool = false
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
var _weapon_elbow_override: bool = false
var _weapon_elbow_override_local := Vector2.ZERO
var _support_elbow_override: bool = false
var _support_elbow_override_local := Vector2.ZERO
var _overlay_rest_local := Vector2.ZERO
var _overlay_motion_active: bool = false
var _arm1_draw: Node2D
var _arm2_draw: Node2D
var _walk_cycle_phase := 0.0
var _cached_limb_preset: WeaponLimbPreset
var _cached_limb_preset_weapon: ResourceData.ResourceType = ResourceData.ResourceType.NONE as ResourceData.ResourceType
var _tuner_arm_layers_ready: bool = false


func _ready() -> void:
	_player = get_parent() as CharacterBody2D
	if config == null:
		config = ProceduralArmConfigScript.new()
	_apply_draw_layer()
	_arm_left = ProceduralArmScript.new()
	_arm_right = ProceduralArmScript.new()
	if use_tuner_arm_layers:
		initialize_tuner_arm_layers()
	else:
		_arm_left.setup(self, "L", config)
		_arm_right.setup(self, "R", config)
	set_process(false)
	_apply_debug_state()


## LimbTuner: back arm → body → head → front arm. Safe to call again after rig rebuild.
func initialize_tuner_arm_layers() -> void:
	if is_tuner_arm_layers_ready():
		return
	use_tuner_arm_layers = true
	_apply_draw_layer()
	_ensure_tuner_draw_containers()
	if _arm_left == null:
		_arm_left = ProceduralArmScript.new()
	if _arm_right == null:
		_arm_right = ProceduralArmScript.new()
	if _arm1_draw == null or _arm2_draw == null:
		return
	if _arm_right.get_draw_root() != null:
		_arm_right.reparent_draw_to(_arm1_draw)
	else:
		_arm_right.setup(_arm1_draw, "R", config)
	if _arm_left.get_draw_root() != null:
		_arm_left.reparent_draw_to(_arm2_draw)
	else:
		_arm_left.setup(_arm2_draw, "L", config)
	_apply_tuner_rig_child_order()
	_apply_tuner_arm_layers(_is_aiming_left())
	_tuner_arm_layers_ready = true


func is_tuner_arm_layers_ready() -> bool:
	return (
		_tuner_arm_layers_ready
		and _arm1_draw != null
		and _arm2_draw != null
		and _arm_left != null
		and _arm_right != null
		and _arm_left.get_draw_root() != null
		and _arm_right.get_draw_root() != null
	)


func _ensure_tuner_draw_containers() -> void:
	if _player == null:
		return
	_arm1_draw = _player.get_node_or_null("Arm1Draw") as Node2D
	if _arm1_draw == null:
		_arm1_draw = Node2D.new()
		_arm1_draw.name = "Arm1Draw"
		_player.add_child(_arm1_draw)
	_arm1_draw.z_as_relative = false
	_arm1_draw.z_index = TUNER_Z_ARM1
	_arm2_draw = _player.get_node_or_null("Arm2Draw") as Node2D
	if _arm2_draw == null:
		_arm2_draw = Node2D.new()
		_arm2_draw.name = "Arm2Draw"
		_player.add_child(_arm2_draw)
	_arm2_draw.z_as_relative = false
	_arm2_draw.z_index = TUNER_Z_ARM2
	_apply_tuner_rig_child_order()


func _apply_tuner_rig_child_order() -> void:
	if _player == null or _arm1_draw == null or _arm2_draw == null:
		return
	var sprite: Node = _player.get_node_or_null("Sprite")
	_player.move_child(_arm1_draw, 0)
	if sprite:
		_player.move_child(_arm2_draw, sprite.get_index() + 1)
	else:
		_player.move_child(_arm2_draw, _player.get_child_count() - 1)


func _apply_draw_layer() -> void:
	z_as_relative = false
	if use_tuner_arm_layers:
		z_index = 0
	else:
		z_index = YSortUtilsScript.Z_ABOVE_WORLD


func _process(_delta: float) -> void:
	if LagProfiler and LagProfiler.is_enabled():
		LagProfiler.record_arm_process()
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
	var overlay: Sprite2D = sprite.get_node_or_null("WeaponOverlay") as Sprite2D
	if (
		not _should_show_weapon_arms(overlay, weapon_type)
		and not force_show_arms
		and not _weapon_endpoints_override
		and not _support_endpoints_override
	):
		_set_arms_visible(false)
		return

	_apply_limb_preset(weapon_type)
	_tick_walk_cycle(_delta, sprite)

	var sprite_scale := sprite.scale
	var thrust_active := is_thrust_active()
	_update_overlay_rest(overlay, thrust_active)
	var thrust_motion := _overlay_motion_delta_rig(sprite, overlay, sprite_scale)

	var overlay_combat := is_overlay_hand_tracking_active() or thrust_active
	var use_mannequin_endpoints := MannequinPoseRuntime.uses_mannequin(sprite) and _cached_limb_preset != null

	var shoulder_weapon: Vector2
	var hand_grip: Vector2
	var support_shoulder: Vector2
	var support_hand: Vector2
	if use_mannequin_endpoints:
		var endpoints: Dictionary = MannequinPoseRuntime.resolve_arm_endpoints(
			_player,
			sprite,
			overlay,
			_cached_limb_preset,
			weapon_type,
			WeaponOverlayCombat.get_overlay_state(_player),
			_get_aim_dir(sprite),
			_is_walking_for_swing(sprite),
			_get_walk_bounce_time()
		)
		shoulder_weapon = endpoints.get("weapon_shoulder", Vector2.ZERO)
		hand_grip = endpoints.get("weapon_hand", Vector2.ZERO)
		support_shoulder = endpoints.get("support_shoulder", Vector2.ZERO)
		support_hand = endpoints.get("support_hand", Vector2.ZERO)
	else:
		shoulder_weapon = _weapon_shoulder_local(sprite, sprite_scale)
		hand_grip = _hand_grip_local(sprite, overlay, sprite_scale)
		support_shoulder = _support_shoulder_local(sprite, config.shoulder_offset_left, sprite_scale)
		support_hand = _support_hand_target_local(sprite, overlay, sprite_scale)
	if not _weapon_hand_uses_overlay_walk_carry() and not overlay_combat:
		hand_grip = _apply_walk_swing_rig_local(sprite, shoulder_weapon, hand_grip, true, weapon_type)
	if not overlay_combat:
		support_hand = _apply_walk_swing_rig_local(sprite, support_shoulder, support_hand, false, weapon_type)
	if _weapon_endpoints_override:
		shoulder_weapon = _weapon_shoulder_override
		hand_grip = _weapon_hand_override

	var aiming_left := _is_aiming_left()
	if _support_endpoints_override:
		support_shoulder = _support_shoulder_override
		support_hand = _support_hand_override
	if thrust_active:
		var counter_motion := _thrust_counter_motion(sprite, thrust_motion)
		shoulder_weapon += thrust_motion * THRUST_WEAPON_SHOULDER_FOLLOW
		support_shoulder += counter_motion * THRUST_SUPPORT_SHOULDER_FOLLOW

	var ready_poles := overlay_combat
	var weapon_pole := _resolve_elbow_pole_local(sprite, config.weapon_elbow_pole_ready_px if ready_poles else config.weapon_elbow_pole_idle_px, sprite_scale)
	var support_pole := _resolve_elbow_pole_local(sprite, config.support_elbow_pole_ready_px if ready_poles else config.support_elbow_pole_idle_px, sprite_scale)
	var use_weapon_pole := weapon_pole.length_squared() > 0.0001
	var use_support_pole := support_pole.length_squared() > 0.0001
	var weapon_bend := _resolve_weapon_bend_sign()
	var support_bend := _resolve_support_bend_sign()
	var use_walk_elbow_limits := _is_walking_for_swing(sprite) or _is_gather_preview_for_ik()
	var relax_reach := use_walk_elbow_limits or thrust_active

	if aiming_left:
		_arm_left.update_arm(
			shoulder_weapon, hand_grip, config, weapon_bend, sprite_scale,
			weapon_pole, use_weapon_pole,
			config.resolve_weapon_upper_arm_length(), config.resolve_weapon_lower_arm_length(),
			_weapon_elbow_override_local, _weapon_elbow_override,
			relax_reach, use_walk_elbow_limits
		)
		_arm_right.update_arm(
			support_shoulder, support_hand, config, support_bend, sprite_scale,
			support_pole, use_support_pole,
			config.resolve_support_upper_arm_length(), config.resolve_support_lower_arm_length(),
			_support_elbow_override_local, _support_elbow_override,
			relax_reach, use_walk_elbow_limits
		)
	else:
		_arm_right.update_arm(
			shoulder_weapon, hand_grip, config, weapon_bend, sprite_scale,
			weapon_pole, use_weapon_pole,
			config.resolve_weapon_upper_arm_length(), config.resolve_weapon_lower_arm_length(),
			_weapon_elbow_override_local, _weapon_elbow_override,
			relax_reach, use_walk_elbow_limits
		)
		_arm_left.update_arm(
			support_shoulder, support_hand, config, support_bend, sprite_scale,
			support_pole, use_support_pole,
			config.resolve_support_upper_arm_length(), config.resolve_support_lower_arm_length(),
			_support_elbow_override_local, _support_elbow_override,
			relax_reach, use_walk_elbow_limits
		)

	_apply_tuner_arm_layers(aiming_left)
	_set_arms_visible(true)
	_apply_debug_state()


func _apply_tuner_arm_layers(aiming_left: bool) -> void:
	if not use_tuner_arm_layers or _arm1_draw == null or _arm2_draw == null:
		return
	if aiming_left:
		_arm_left.reparent_draw_to(_arm1_draw)
		_arm_right.reparent_draw_to(_arm2_draw)
	else:
		_arm_right.reparent_draw_to(_arm1_draw)
		_arm_left.reparent_draw_to(_arm2_draw)


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


func set_weapon_elbow_override_from_global(elbow_global: Vector2) -> void:
	_weapon_elbow_override = true
	_weapon_elbow_override_local = to_local(elbow_global)


func set_support_elbow_override_from_global(elbow_global: Vector2) -> void:
	_support_elbow_override = true
	_support_elbow_override_local = to_local(elbow_global)


func clear_weapon_elbow_override() -> void:
	_weapon_elbow_override = false


func clear_support_elbow_override() -> void:
	_support_elbow_override = false


func clear_all_elbow_overrides() -> void:
	clear_weapon_elbow_override()
	clear_support_elbow_override()


func get_weapon_arm_global_endpoints() -> Dictionary:
	var active_arm: ProceduralArm = _arm_right if not _is_aiming_left() else _arm_left
	if active_arm == null:
		return {"shoulder": global_position, "hand": global_position}
	var joints: Dictionary = active_arm.get_last_joint_positions()
	return {
		"shoulder": to_global(joints.get("shoulder", Vector2.ZERO)),
		"elbow": to_global(joints.get("elbow", Vector2.ZERO)),
		"hand": to_global(joints.get("hand", Vector2.ZERO)),
	}


func get_support_arm_global_endpoints() -> Dictionary:
	var active_arm: ProceduralArm = _arm_left if not _is_aiming_left() else _arm_right
	if active_arm == null:
		return {"shoulder": global_position, "hand": global_position}
	var joints: Dictionary = active_arm.get_last_joint_positions()
	return {
		"shoulder": to_global(joints.get("shoulder", Vector2.ZERO)),
		"elbow": to_global(joints.get("elbow", Vector2.ZERO)),
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


func refresh_line_styles_from_config() -> void:
	if config == null:
		return
	if _arm_left:
		_arm_left.refresh_line_style(config)
	if _arm_right:
		_arm_right.refresh_line_style(config)


func _apply_limb_preset(weapon_type: ResourceData.ResourceType) -> void:
	if LimbPresetRegistry == null or config == null:
		return
	if weapon_type == _cached_limb_preset_weapon and _cached_limb_preset != null:
		return
	var preset := LimbPresetRegistry.get_preset(weapon_type, body_card_id)
	LimbPresetRegistry.apply_to_arm_config(config, preset)
	_cached_limb_preset = preset
	_cached_limb_preset_weapon = weapon_type
	refresh_line_styles_from_config()


func _resolve_walk_rest_hand_grip() -> Vector2:
	var preset := _cached_limb_preset
	if preset == null and LimbPresetRegistry != null:
		preset = LimbPresetRegistry.get_preset(_get_weapon_type(), body_card_id)
	if preset != null:
		return preset.resolve_walk_rest_hand_grip()
	return config.hand_grip_offset_px if config else Vector2.ZERO


func _resolve_walk_rest_support_hand() -> Vector2:
	var preset := _cached_limb_preset
	if preset == null and LimbPresetRegistry != null:
		preset = LimbPresetRegistry.get_preset(_get_weapon_type(), body_card_id)
	if preset != null:
		return preset.resolve_walk_rest_support_hand()
	return config.support_hand_idle_offset_px if config else Vector2.ZERO


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
	if force_show_arms or _weapon_endpoints_override or _support_endpoints_override:
		return true
	if overlay == null or not overlay.visible:
		return false
	return weapon_type == ResourceData.ResourceType.SPEAR or weapon_type == ResourceData.ResourceType.WOOD


func _resolve_weapon_bend_sign() -> float:
	if config and absf(config.weapon_elbow_bend_sign_active) > 0.001:
		return config.weapon_elbow_bend_sign_active
	return _resolve_weapon_bend_sign_auto()


func _resolve_weapon_bend_sign_auto() -> float:
	if _is_aiming_left():
		return WeaponLimbPreset.DOMINANT_ELBOW_BEND_SIGN
	return -WeaponLimbPreset.DOMINANT_ELBOW_BEND_SIGN


func _resolve_support_bend_sign() -> float:
	if config and absf(config.support_elbow_bend_sign_active) > 0.001:
		return config.support_elbow_bend_sign_active
	return _resolve_support_bend_sign_auto()


func _resolve_support_bend_sign_auto() -> float:
	if _is_aiming_left():
		return WeaponLimbPreset.SUPPORT_ELBOW_BEND_SIGN
	return -WeaponLimbPreset.SUPPORT_ELBOW_BEND_SIGN


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
	var offset_px := _weapon_shoulder_offset_px()
	if _uses_mannequin_anchors(sprite):
		var global_pos := MannequinAnchorResolver.shoulder_global_from_display(
			sprite, _get_body_visual(sprite), offset_px
		)
		return MannequinAnchorResolver.rig_local_from_global(_player, global_pos)
	var offset := _flip_offset_x(offset_px, sprite.flip_h)
	return sprite.position + Vector2(offset.x * sprite_scale.x, offset.y * sprite_scale.y)


func _hand_grip_local(sprite: Sprite2D, overlay: Sprite2D, sprite_scale: Vector2) -> Vector2:
	var grip_px := config.hand_grip_offset_px
	if is_overlay_hand_tracking_active() and config.hand_grip_ready_offset_px.length_squared() > 0.0001:
		grip_px = config.hand_grip_ready_offset_px
	elif _is_walking_for_swing(sprite):
		grip_px = _resolve_walk_rest_hand_grip()
	return _grip_on_overlay_local(sprite, overlay, grip_px)


func _support_hand_grip_local(sprite: Sprite2D, overlay: Sprite2D, _sprite_scale: Vector2) -> Vector2:
	return _grip_on_overlay_local(sprite, overlay, config.support_hand_grip_offset_px)


func _support_hand_idle_local(sprite: Sprite2D, sprite_scale: Vector2) -> Vector2:
	var offset := _flip_offset_x(config.support_hand_idle_offset_px, sprite.flip_h)
	return sprite.position + Vector2(offset.x * sprite_scale.x, offset.y * sprite_scale.y)


func _support_hand_target_local(sprite: Sprite2D, overlay: Sprite2D, sprite_scale: Vector2) -> Vector2:
	if _use_two_hand_spear_grip():
		return _support_hand_grip_local(sprite, overlay, sprite_scale)
	if _is_walking_for_swing(sprite):
		var offset := _flip_offset_x(_resolve_walk_rest_support_hand(), sprite.flip_h)
		return sprite.position + Vector2(offset.x * sprite_scale.x, offset.y * sprite_scale.y)
	return _support_hand_idle_local(sprite, sprite_scale)


func _use_two_hand_spear_grip() -> bool:
	if _get_weapon_type() != ResourceData.ResourceType.SPEAR:
		return false
	return is_overlay_hand_tracking_active() or is_thrust_active()


func _weapon_hand_uses_overlay_walk_carry() -> bool:
	## Club + spear: weapon overlay sways during walk; hand stays on saved grip art.
	var wt := _get_weapon_type()
	return wt == ResourceData.ResourceType.WOOD or wt == ResourceData.ResourceType.SPEAR


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
	if _uses_mannequin_anchors(sprite):
		var global_pos := MannequinAnchorResolver.shoulder_global_from_display(
			sprite, _get_body_visual(sprite), offset_px
		)
		return MannequinAnchorResolver.rig_local_from_global(_player, global_pos)
	var offset := _flip_offset_x(offset_px, sprite.flip_h)
	return sprite.position + Vector2(offset.x * sprite_scale.x, offset.y * sprite_scale.y)


func _flip_offset_x(offset_px: Vector2, flip_h: bool) -> Vector2:
	if flip_h:
		return Vector2(-offset_px.x, offset_px.y)
	return offset_px


func _tick_walk_cycle(delta: float, sprite: Sprite2D) -> void:
	if _uses_shared_walk_bounce_time():
		return
	if not _is_walking_for_swing(sprite):
		_walk_cycle_phase = 0.0
		return
	_walk_cycle_phase += delta * PlaceholderCardRegistry.effective_walk_bounce_speed()
	if _walk_cycle_phase > TAU:
		_walk_cycle_phase = fmod(_walk_cycle_phase, TAU)


func _uses_shared_walk_bounce_time() -> bool:
	if _player == null:
		return false
	if _player.get("_card_bounce_time") != null:
		return true
	return _player.has_method("get_walk_bounce_time")


func _get_walk_bounce_time() -> float:
	if _player != null:
		if _player.get("_card_bounce_time") != null:
			return float(_player.get("_card_bounce_time"))
		if _player.has_method("get_walk_bounce_time"):
			return float(_player.call("get_walk_bounce_time"))
	return _walk_cycle_phase


func _is_walking_for_swing(sprite: Sprite2D) -> bool:
	if is_overlay_hand_tracking_active() or is_thrust_active():
		return false
	if _player is CharacterBody2D:
		return (_player as CharacterBody2D).velocity.length_squared() > 16.0
	return false


func _is_gather_preview_for_ik() -> bool:
	if _player == null or not _player.has_method("is_gather_preview_playing"):
		return false
	return _player.is_gather_preview_playing()


func _apply_walk_swing_rig_local(
	sprite: Sprite2D,
	shoulder_local: Vector2,
	hand_local: Vector2,
	dominant: bool,
	weapon_type: ResourceData.ResourceType = ResourceData.ResourceType.NONE
) -> Vector2:
	if sprite == null or not _is_walking_for_swing(sprite):
		return hand_local
	var travel_sign := 1.0
	if _player is CharacterBody2D:
		var vel := (_player as CharacterBody2D).velocity
		if absf(vel.x) > 1.0:
			travel_sign = signf(vel.x)
		elif sprite.flip_h:
			travel_sign = -1.0
	var sx: float = absf(sprite.scale.x)
	if sx < 0.001:
		sx = 1.0
	var rest_offset := (hand_local - shoulder_local) / sx
	var swung_offset := WalkArmSwing.swing_hand_local_offset(
		rest_offset,
		WalkArmSwing.swing_phase_from_bounce(_get_walk_bounce_time()),
		dominant,
		travel_sign,
		_get_weapon_type()
	) * sx
	return shoulder_local + swung_offset


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


func _get_body_visual(sprite: Sprite2D) -> Node:
	if sprite == null:
		return null
	return sprite.get_node_or_null("BodyVisual")


func _uses_mannequin_anchors(sprite: Sprite2D) -> bool:
	var body_visual := _get_body_visual(sprite)
	if body_visual == null:
		return false
	if body_visual.has_method("get_body_sprite"):
		return body_visual.call("get_body_sprite") != null
	return body_visual.get_child_count() > 0
