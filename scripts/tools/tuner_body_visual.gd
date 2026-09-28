extends Node2D
class_name TunerBodyVisual

## Layered blank body + head sprites in card texture space (feet at card bottom).

const CardVisualController = preload("res://scripts/systems/card_visual_controller.gd")

const PartsRegistry = preload("res://scripts/config/character_card_parts_registry.gd")
const BODY_DRAW_Z_INDEX := 1
const HEAD_DRAW_Z_INDEX := 2
const WEAPON_DRAW_Z_INDEX := 3
## Hair front on HeadPivot — above HeadSprite (0), below future hat layer.
const HAIR_FRONT_Z_INDEX := 1
const HAT_DRAW_Z_INDEX := 2

@export var body_texture_path: String = PartsRegistry.BLANK_BODY_PATH
@export var head_texture_path: String = PartsRegistry.BLANK_HEAD_PATH

var _layout
var _layer_layout: CharacterCardLayerLayout
var _body_sprite: Sprite2D
var _head_pivot: Node2D
var _head_sprite: Sprite2D
var _hair_sprite: Sprite2D
var _head_rest_y := 0.0
var _head_bob_y := 0.0
var _look_right := true
var _body_tex: Texture2D
var _death_active := false
var _body_build_scale := Vector2.ONE
var _head_build_scale := Vector2.ONE


func _ready() -> void:
	z_index = 0


func get_layer_layout() -> CharacterCardLayerLayout:
	return _layer_layout


func apply_layout(layout, layer_layout: CharacterCardLayerLayout = null) -> void:
	_layout = layout
	_layer_layout = layer_layout if layer_layout != null else PartsRegistry.get_layout()
	_build_layers()


func apply_layer_layout(layer_layout: CharacterCardLayerLayout) -> void:
	if layer_layout == null:
		return
	var paths_changed := (
		_layer_layout == null
		or layer_layout.body_texture_path != body_texture_path
		or layer_layout.head_texture_path != head_texture_path
		or layer_layout.hair_texture_path != (
			_layer_layout.hair_texture_path if _layer_layout else ""
		)
	)
	_layer_layout = layer_layout
	if paths_changed or _body_sprite == null or _head_sprite == null:
		_build_layers()
	else:
		_build_hair_layer()
		_apply_head_attachment()


func neck_socket_global() -> Vector2:
	if _head_pivot:
		return _head_pivot.global_position
	return global_position


func get_body_sprite() -> Sprite2D:
	return _body_sprite


func get_body_sprite_offset() -> Vector2:
	return _body_sprite.position if _body_sprite else Vector2.ZERO


func apply_tuner_draw_layers() -> void:
	if _body_sprite:
		_body_sprite.z_as_relative = false
		_body_sprite.z_index = BODY_DRAW_Z_INDEX
	if _head_pivot:
		_head_pivot.z_as_relative = false
		_head_pivot.z_index = HEAD_DRAW_Z_INDEX
	if _head_sprite:
		_head_sprite.z_as_relative = true
		_head_sprite.z_index = 0
	if _hair_sprite:
		_hair_sprite.z_as_relative = true
		_hair_sprite.z_index = HAIR_FRONT_Z_INDEX


## In-game mannequin: stack body/head/weapon relative to card Sprite Y-sort z_index.
func apply_runtime_draw_layers() -> void:
	z_as_relative = true
	z_index = 0
	if _body_sprite:
		_body_sprite.z_as_relative = true
		_body_sprite.z_index = BODY_DRAW_Z_INDEX
	if _head_pivot:
		_head_pivot.z_as_relative = true
		_head_pivot.z_index = HEAD_DRAW_Z_INDEX
	if _head_sprite:
		_head_sprite.z_as_relative = true
		_head_sprite.z_index = 0
	if _hair_sprite:
		_hair_sprite.z_as_relative = true
		_hair_sprite.z_index = HAIR_FRONT_Z_INDEX
	var sprite_root := get_parent() as Node2D
	if sprite_root:
		var weapon := sprite_root.get_node_or_null("WeaponOverlay") as Sprite2D
		if weapon:
			weapon.z_as_relative = true
			weapon.z_index = WEAPON_DRAW_Z_INDEX
			sprite_root.move_child(weapon, -1)


func _uses_runtime_draw_layers() -> bool:
	var sprite_root := get_parent() as Node2D
	if sprite_root == null:
		return false
	var entity := sprite_root.get_parent()
	if entity == null or not PlaceholderCardService:
		return false
	return PlaceholderCardService.uses_layered_body_mannequin(entity)


func _apply_draw_layers() -> void:
	if _uses_runtime_draw_layers():
		apply_runtime_draw_layers()
	else:
		apply_tuner_draw_layers()


func sync_head_draw_transform() -> void:
	if _death_active:
		sync_attached_head_transform()
		return
	if _head_pivot == null or _layer_layout == null or _body_tex == null:
		return
	var neck_local := _neck_local_scaled()
	neck_local.y += _head_bob_y
	_head_pivot.global_position = to_global(neck_local)
	_head_pivot.global_rotation = global_rotation
	if _head_pivot:
		_head_pivot.scale = _head_build_scale
	_apply_layer_facing_flips()
	if _uses_runtime_draw_layers():
		apply_runtime_draw_layers()


## Death fall: keep head on neck without re-sorting draw layers every frame.
func sync_attached_head_transform() -> void:
	if _head_pivot == null or _layer_layout == null or _body_tex == null:
		return
	var neck_local := _neck_local_scaled()
	var neck_global := to_global(neck_local)
	_head_pivot.global_position = neck_global.round()
	_head_pivot.global_rotation = global_rotation
	if _head_pivot:
		_head_pivot.scale = _head_build_scale


func prepare_for_death_fall() -> void:
	_death_active = true
	_head_bob_y = 0.0
	rotation = 0.0
	position = Vector2.ZERO
	sync_attached_head_transform()


func _card_sprite_root() -> Sprite2D:
	return get_parent() as Sprite2D


func _facing_left() -> bool:
	var root := _card_sprite_root()
	return root != null and root.flip_h


func _resolve_head_sprite_flip_h() -> bool:
	## Card Sprite.flip_h is logical facing only — body/head sprites mirror themselves.
	var facing_left := _facing_left()
	## Default travel look (in-game): look_right == (not facing_left) → head mirrors with body.
	if _look_right == (not facing_left):
		return facing_left
	## Idle1 look-around on top of travel facing.
	if not facing_left:
		return not _look_right
	return _look_right


func _apply_layer_facing_flips() -> void:
	var facing_left := _facing_left()
	if _body_sprite:
		_body_sprite.flip_h = facing_left
	if _head_sprite:
		_head_sprite.flip_h = _resolve_head_sprite_flip_h()
	if _hair_sprite:
		_hair_sprite.flip_h = _resolve_head_sprite_flip_h()
	_apply_hair_attachment()


func _resolved_hair_attach_local_px() -> Vector2:
	if _layer_layout == null:
		return Vector2.ZERO
	return PartsRegistry.resolved_hair_attach_local_px(_layer_layout, _facing_left())


func layer_facing_in_sync() -> bool:
	if _body_sprite == null:
		return true
	var head_flip := _resolve_head_sprite_flip_h()
	var hair_ok := _hair_sprite == null or _hair_sprite.flip_h == head_flip
	return _body_sprite.flip_h == _facing_left() and (
		_head_sprite == null or _head_sprite.flip_h == head_flip
	) and hair_ok


func _apply_facing(look_right: bool) -> void:
	_look_right = look_right
	_apply_layer_facing_flips()


func _body_pivot_local() -> Vector2:
	return get_body_sprite_offset()


func _apply_torso_sway(sway_rad: float) -> void:
	var pivot := _body_pivot_local()
	rotation = sway_rad
	position = pivot - pivot.rotated(sway_rad)


## Nearest point on the visible torso silhouette for a shoulder/arm pin stem.
func torso_surface_global_for(world_point: Vector2) -> Vector2:
	if _body_sprite == null or _body_tex == null:
		return world_point
	var center := _body_sprite.global_position
	var half_w := float(_body_tex.get_width()) * 0.5 * absf(_body_sprite.global_scale.x)
	var half_h := float(_body_tex.get_height()) * 0.5 * absf(_body_sprite.global_scale.y)
	if half_w < 1.0 or half_h < 1.0:
		return center
	var local := world_point - center
	var dir := local.normalized()
	if dir.length_squared() < 0.0001:
		dir = Vector2.RIGHT
	var inset := 0.82
	var edge := Vector2(dir.x * half_w * inset, dir.y * half_h * inset)
	if dir.y < -0.15:
		edge.y = minf(edge.y, -half_h * 0.28)
	return center + edge


func set_neck_socket_from_global(global_pos: Vector2) -> void:
	if _layer_layout == null or _body_tex == null:
		return
	var local_pos := to_local(global_pos)
	var center := Vector2(_body_tex.get_width(), _body_tex.get_height()) * 0.5
	_layer_layout.body_neck_socket_px = local_pos + center - _layer_layout.body_offset_px
	_apply_head_attachment()


func hair_attach_global() -> Vector2:
	if _head_pivot == null:
		return global_position
	return _head_pivot.to_global(_resolved_hair_attach_local_px())


func set_hair_attach_from_global(global_pos: Vector2) -> void:
	if _head_pivot == null or _layer_layout == null:
		return
	var local_pos := _head_pivot.to_local(global_pos)
	if _facing_left():
		local_pos.x = -local_pos.x
	_layer_layout.hair_attach_local_px = local_pos
	_apply_hair_attachment()


func has_hair_layer() -> bool:
	return _hair_sprite != null and _hair_sprite.texture != null


func get_hair_sprite() -> Sprite2D:
	return _hair_sprite


func is_facing_right() -> bool:
	return not _facing_left()


func set_walk_state(moving: bool, bounce_time: float, direction: int) -> void:
	if _death_active:
		return
	_apply_facing(direction > 0)
	var tilt_sign := -1.0 if direction < 0 else 1.0
	var bob: float = _layout.head_bob_local() if _layout else 2.5
	if moving:
		var hop := CardVisualController.walk_bounce_hop_factor(bounce_time)
		var hop_dir := signf(sin(bounce_time))
		if hop_dir == 0.0:
			hop_dir = tilt_sign
		_apply_torso_sway(hop * hop_dir * 0.11 * tilt_sign)
		_head_bob_y = -CardVisualController.walk_bounce_hop_factor(bounce_time - 0.28) * bob
		sync_head_draw_transform()
	else:
		clear_motion_state()


func set_idle_state(head_offset_y: float, sway_rad: float, look_right: bool = true) -> void:
	_head_bob_y = head_offset_y
	_apply_facing(look_right)
	_apply_torso_sway(sway_rad)
	sync_head_draw_transform()


func set_gather_state(bend_rad: float, head_forward_local: float) -> void:
	_apply_torso_sway(bend_rad)
	_head_bob_y = head_forward_local
	sync_head_draw_transform()


func clear_motion_state() -> void:
	if _death_active:
		return
	rotation = 0.0
	position = Vector2.ZERO
	_head_bob_y = 0.0
	var sprite_root := _card_sprite_root()
	_look_right = not sprite_root.flip_h if sprite_root else true
	sync_head_draw_transform()


func set_death_active(on: bool) -> void:
	_death_active = on


func is_death_active() -> bool:
	return _death_active


## Bottom-center of body art — pivot for tipping over onto the ground.
func apply_body_build_scale(body_scale: Vector2, head_scale: Vector2 = Vector2.ONE) -> void:
	_body_build_scale = body_scale
	_head_build_scale = head_scale
	_apply_body_build_to_sprites()
	if _death_active:
		sync_attached_head_transform()
	else:
		sync_head_draw_transform()


func _apply_body_build_to_sprites() -> void:
	if _body_sprite == null or _layer_layout == null or _body_tex == null:
		return
	var half_h := float(_body_tex.get_height()) * 0.5
	var sy: float = _body_build_scale.y
	_body_sprite.scale = _body_build_scale
	_body_sprite.position = _layer_layout.body_offset_px + Vector2(0.0, -(sy - 1.0) * half_h)
	## Hair / future hats live on HeadPivot — they follow head_scale, not body_scale.
	## Future body clothes should be children of BodySprite so they stretch with the torso.
	if _head_pivot:
		_head_pivot.scale = _head_build_scale
	if _head_sprite:
		_head_sprite.scale = Vector2.ONE


func _neck_local_scaled() -> Vector2:
	var unscaled := PartsRegistry.head_pivot_on_body_local(_body_tex, _layer_layout)
	if _facing_left():
		unscaled.x = -unscaled.x
	if _body_sprite == null or _layer_layout == null:
		return unscaled
	var body_off: Vector2 = _layer_layout.body_offset_px
	return _body_sprite.position + (unscaled - body_off) * _body_sprite.scale


func get_death_fall_pivot_local() -> Vector2:
	if _body_sprite == null or _body_tex == null:
		return Vector2.ZERO
	var half_h := float(_body_tex.get_height()) * 0.5
	return _body_sprite.position + Vector2(0.0, half_h * _body_sprite.scale.y)


func _build_layers() -> void:
	var sprite_root := get_parent() as Node2D
	_clear_sprite_head_pivots(sprite_root)

	while get_child_count() > 0:
		var old: Node = get_child(0)
		remove_child(old)
		old.free()
	_body_sprite = null

	if _layer_layout == null:
		_layer_layout = PartsRegistry.get_layout()

	body_texture_path = _layer_layout.body_texture_path
	head_texture_path = _layer_layout.head_texture_path

	_body_tex = _load_texture(body_texture_path)
	var head_tex := _load_texture(head_texture_path)
	if _body_tex == null:
		push_warning("TunerBodyVisual: missing body texture at %s" % body_texture_path)
		return

	_body_sprite = Sprite2D.new()
	_body_sprite.name = "BodySprite"
	_body_sprite.texture = _body_tex
	_body_sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_body_sprite.centered = true
	_body_sprite.position = _layer_layout.body_offset_px
	add_child(_body_sprite)

	if head_tex == null:
		push_warning("TunerBodyVisual: missing head texture at %s" % head_texture_path)
		_apply_draw_layers()
		return

	_head_pivot = Node2D.new()
	_head_pivot.name = "HeadPivot"
	if sprite_root:
		sprite_root.add_child(_head_pivot)
	else:
		add_child(_head_pivot)

	_head_sprite = Sprite2D.new()
	_head_sprite.name = "HeadSprite"
	_head_sprite.texture = head_tex
	_head_sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_head_sprite.centered = true
	_head_pivot.add_child(_head_sprite)
	_build_hair_layer()
	_apply_body_build_to_sprites()
	_apply_head_attachment()
	_apply_draw_layers()


func _build_hair_layer() -> void:
	if _head_pivot == null or _layer_layout == null:
		return
	if _hair_sprite != null:
		_hair_sprite.queue_free()
		_hair_sprite = null
	var path := _layer_layout.hair_texture_path
	if path.is_empty() or not ResourceLoader.exists(path):
		return
	var hair_tex := _load_texture(path)
	if hair_tex == null:
		return
	_hair_sprite = Sprite2D.new()
	_hair_sprite.name = "HairFront"
	_hair_sprite.texture = hair_tex
	_hair_sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_hair_sprite.centered = true
	_head_pivot.add_child(_hair_sprite)
	_head_pivot.move_child(_hair_sprite, -1)
	_apply_hair_attachment()


func _clear_sprite_head_pivots(sprite_root: Node2D) -> void:
	if sprite_root == null:
		return
	var stale: Array[Node] = []
	for child in sprite_root.get_children():
		if child.name == "HeadPivot":
			stale.append(child)
	for node in stale:
		node.free()
	_head_pivot = null
	_head_sprite = null


func _apply_head_attachment() -> void:
	if _head_pivot == null or _head_sprite == null or _layer_layout == null or _body_tex == null:
		return
	var head_tex := _head_sprite.texture
	_head_rest_y = PartsRegistry.head_pivot_on_body_local(_body_tex, _layer_layout).y
	_head_sprite.position = PartsRegistry.head_sprite_offset_local(head_tex, _layer_layout)
	sync_head_draw_transform()
	_apply_hair_attachment()


func _apply_hair_attachment() -> void:
	if _hair_sprite == null or _layer_layout == null:
		return
	var hair_tex := _hair_sprite.texture
	if hair_tex == null:
		return
	_hair_sprite.position = PartsRegistry.hair_sprite_offset_local(
		hair_tex, _layer_layout, _facing_left()
	)
	if _head_sprite:
		_hair_sprite.flip_h = _head_sprite.flip_h


func _load_texture(path: String) -> Texture2D:
	if path.is_empty():
		return null
	if ResourceLoader.exists(path):
		var loaded: Texture2D = ResourceLoader.load(path, "Texture2D", ResourceLoader.CACHE_MODE_IGNORE_DEEP) as Texture2D
		if loaded:
			return loaded
	if FileAccess.file_exists(path):
		var img := Image.new()
		if img.load(path) == OK:
			return ImageTexture.create_from_image(img)
	return null
