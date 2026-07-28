extends Node2D
class_name TunerBodyVisual

## Layered blank body + head sprites in card texture space (feet at card bottom).

const PartsRegistry = preload("res://scripts/config/character_card_parts_registry.gd")
const BODY_DRAW_Z_INDEX := 1
const HEAD_DRAW_Z_INDEX := 2

@export var body_texture_path: String = PartsRegistry.BLANK_BODY_PATH
@export var head_texture_path: String = PartsRegistry.BLANK_HEAD_PATH

var _layout
var _layer_layout: CharacterCardLayerLayout
var _body_sprite: Sprite2D
var _head_pivot: Node2D
var _head_sprite: Sprite2D
var _head_rest_y := 0.0
var _head_bob_y := 0.0
var _look_right := true
var _body_tex: Texture2D


func _ready() -> void:
	z_index = 0


func get_layer_layout() -> CharacterCardLayerLayout:
	return _layer_layout


func apply_layout(layout) -> void:
	_layout = layout
	_layer_layout = PartsRegistry.get_layout()
	_build_layers()


func apply_layer_layout(layer_layout: CharacterCardLayerLayout) -> void:
	if layer_layout == null:
		return
	var paths_changed := (
		_layer_layout == null
		or layer_layout.body_texture_path != body_texture_path
		or layer_layout.head_texture_path != head_texture_path
	)
	_layer_layout = layer_layout
	if paths_changed or _body_sprite == null or _head_sprite == null:
		_build_layers()
	else:
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


## In-game mannequin uses the same body/head z stack as the limb tuner.
func apply_runtime_draw_layers() -> void:
	apply_tuner_draw_layers()


func sync_head_draw_transform() -> void:
	if _head_pivot == null or _layer_layout == null or _body_tex == null:
		return
	var neck_local := PartsRegistry.head_pivot_on_body_local(_body_tex, _layer_layout)
	neck_local.y += _head_bob_y
	_head_pivot.global_position = to_global(neck_local)
	_head_pivot.global_rotation = global_rotation
	var look_sign := 1.0 if _look_right else -1.0
	# HeadPivot is parented under the card Sprite; scale comes from that parent once.
	_head_pivot.scale = Vector2(look_sign, 1.0)


func _apply_facing(look_right: bool) -> void:
	_look_right = look_right
	if _body_sprite:
		_body_sprite.flip_h = not look_right


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


func set_walk_state(moving: bool, bounce_time: float, direction: int) -> void:
	_apply_facing(direction > 0)
	var tilt_sign := -1.0 if direction < 0 else 1.0
	var bob: float = _layout.head_bob_local() if _layout else 2.5
	if moving:
		_apply_torso_sway(sin(bounce_time) * 0.06 * tilt_sign)
		_head_bob_y = sin(bounce_time - 0.45) * bob
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
	rotation = 0.0
	position = Vector2.ZERO
	_head_bob_y = 0.0
	_look_right = true
	sync_head_draw_transform()


func _build_layers() -> void:
	var sprite_root := get_parent() as Node2D
	_clear_sprite_head_pivots(sprite_root)

	for child in get_children():
		child.queue_free()
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
		apply_tuner_draw_layers()
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
	_apply_head_attachment()
	apply_tuner_draw_layers()


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


func _load_texture(path: String) -> Texture2D:
	if path.is_empty() or not ResourceLoader.exists(path):
		return null
	return ResourceLoader.load(path, "Texture2D", ResourceLoader.CACHE_MODE_IGNORE_DEEP) as Texture2D
