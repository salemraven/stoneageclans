extends Node2D
class_name ProceduralArmController

const ProceduralArmConfigScript = preload("res://scripts/systems/procedural_arm_config.gd")
const ProceduralArmScript = preload("res://scripts/systems/procedural_arm.gd")

@export var config: ProceduralArmConfigScript
@export var enabled: bool = true
@export var debug_draw: bool = false

var _player: CharacterBody2D
var _arm_left: ProceduralArm
var _arm_right: ProceduralArm


func _ready() -> void:
	_player = get_parent() as CharacterBody2D
	if config == null:
		config = ProceduralArmConfigScript.new()
	_arm_left = ProceduralArmScript.new()
	_arm_right = ProceduralArmScript.new()
	_arm_left.setup(self, "L", config)
	_arm_right.setup(self, "R", config)
	_apply_debug_state()


func _process(_delta: float) -> void:
	if not enabled or _player == null or config == null:
		_set_arms_visible(false)
		return
	var sprite: Sprite2D = _player.get_node_or_null("Sprite") as Sprite2D
	if sprite == null or not sprite.visible:
		_set_arms_visible(false)
		return

	global_position = _player.global_position
	global_rotation = 0.0
	scale = Vector2.ONE

	var sprite_scale := sprite.scale
	var shoulder_r := _shoulder_local(sprite, config.shoulder_offset_right, sprite_scale)
	var shoulder_l := _shoulder_local(sprite, config.shoulder_offset_left, sprite_scale)

	var overlay: Sprite2D = sprite.get_node_or_null("WeaponOverlay") as Sprite2D
	var weapon_visible := overlay != null and overlay.visible and _player_has_combat_weapon()
	var aiming_left := _is_aiming_left()

	if weapon_visible:
		var grip_local := _weapon_grip_local(sprite, overlay)
		if aiming_left:
			_arm_left.update_arm(shoulder_l, grip_local, config, -1.0, sprite_scale)
			_arm_right.update_arm(shoulder_r, _idle_hand_local(sprite, false, sprite_scale), config, 1.0, sprite_scale)
		else:
			_arm_right.update_arm(shoulder_r, grip_local, config, 1.0, sprite_scale)
			_arm_left.update_arm(shoulder_l, _idle_hand_local(sprite, true, sprite_scale), config, -1.0, sprite_scale)
	else:
		_arm_right.update_arm(shoulder_r, _idle_hand_local(sprite, false, sprite_scale), config, 1.0, sprite_scale)
		_arm_left.update_arm(shoulder_l, _idle_hand_local(sprite, true, sprite_scale), config, -1.0, sprite_scale)

	_set_arms_visible(true)
	_apply_debug_state()


func set_debug_draw(on: bool) -> void:
	debug_draw = on
	_apply_debug_state()


func toggle_debug_draw() -> bool:
	debug_draw = not debug_draw
	_apply_debug_state()
	return debug_draw


func _apply_debug_state() -> void:
	var show_debug := debug_draw or _debug_config_enabled()
	if _arm_left:
		_arm_left.set_debug_enabled(show_debug)
	if _arm_right:
		_arm_right.set_debug_enabled(show_debug)


func _debug_config_enabled() -> bool:
	var dc := get_node_or_null("/root/DebugConfig")
	return dc != null and bool(dc.get("enable_procedural_arms_debug"))


func _set_arms_visible(visible_arms: bool) -> void:
	if _arm_left:
		_arm_left.set_visible_arm(visible_arms)
	if _arm_right:
		_arm_right.set_visible_arm(visible_arms)


func _player_has_combat_weapon() -> bool:
	if _player.has_method("get_equipped_weapon_type"):
		var wt: ResourceData.ResourceType = _player.get_equipped_weapon_type()
		return wt != ResourceData.ResourceType.NONE and wt != ResourceData.ResourceType.TRAVOIS
	if _player.get("_equipped_item") != null:
		var item: ResourceData.ResourceType = _player.get("_equipped_item") as ResourceData.ResourceType
		return ResourceData.is_equipment(item) and item != ResourceData.ResourceType.TRAVOIS
	return false


func _is_aiming_left() -> bool:
	if _player.get("aim_dir") != null:
		var aim: Vector2 = _player.get("aim_dir") as Vector2
		if aim.length_squared() > 0.0001:
			return aim.x < 0.0
	var sprite: Sprite2D = _player.get_node_or_null("Sprite") as Sprite2D
	return sprite != null and sprite.flip_h


func _shoulder_local(sprite: Sprite2D, offset_px: Vector2, sprite_scale: Vector2) -> Vector2:
	var offset := _flip_offset_x(offset_px, sprite.flip_h)
	return sprite.position + Vector2(offset.x * sprite_scale.x, offset.y * sprite_scale.y)


func _idle_hand_local(sprite: Sprite2D, is_left: bool, sprite_scale: Vector2) -> Vector2:
	var offset_px: Vector2 = config.idle_hand_offset_left if is_left else config.idle_hand_offset_right
	var offset := _flip_offset_x(offset_px, sprite.flip_h)
	return sprite.position + Vector2(offset.x * sprite_scale.x, offset.y * sprite_scale.y)


func _weapon_grip_local(sprite: Sprite2D, overlay: Sprite2D) -> Vector2:
	var grip_px: Vector2 = config.grip_offset_from_overlay_px
	var grip_overlay_local := Vector2(grip_px.x * overlay.scale.x, grip_px.y * overlay.scale.y)
	return sprite.to_local(overlay.to_global(grip_overlay_local))


func _flip_offset_x(offset_px: Vector2, flip_h: bool) -> Vector2:
	if flip_h:
		return Vector2(-offset_px.x, offset_px.y)
	return offset_px
