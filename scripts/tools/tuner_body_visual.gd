extends Node2D
class_name TunerBodyVisual

## Layered blank body + head sprites in card texture space (feet at card bottom).

const PartsRegistry = preload("res://scripts/config/character_card_parts_registry.gd")

@export var body_texture_path: String = PartsRegistry.BLANK_BODY_PATH
@export var head_texture_path: String = PartsRegistry.BLANK_HEAD_PATH

var _layout
var _layer_layout: CharacterCardLayerLayout
var _body_sprite: Sprite2D
var _head_pivot: Node2D
var _head_sprite: Sprite2D
var _head_rest_y := 0.0
var _body_tex: Texture2D


func _ready() -> void:
	z_index = -2


func get_layer_layout() -> CharacterCardLayerLayout:
	return _layer_layout


func apply_layout(layout) -> void:
	_layout = layout
	_layer_layout = PartsRegistry.get_layout()
	_build_layers()


func apply_layer_layout(layer_layout: CharacterCardLayerLayout) -> void:
	if layer_layout == null:
		return
	_layer_layout = layer_layout
	if _body_tex != null:
		_apply_head_attachment()


func neck_socket_global() -> Vector2:
	if _head_pivot:
		return _head_pivot.global_position
	return global_position


func set_neck_socket_from_global(global_pos: Vector2) -> void:
	if _layer_layout == null or _body_tex == null:
		return
	var local_pos := to_local(global_pos)
	var center := Vector2(_body_tex.get_width(), _body_tex.get_height()) * 0.5
	_layer_layout.body_neck_socket_px = local_pos + center
	_apply_head_attachment()


func set_walk_state(moving: bool, bounce_time: float, direction: int) -> void:
	var tilt_sign := -1.0 if direction < 0 else 1.0
	var bob: float = _layout.head_bob_local() if _layout else 2.5
	if moving:
		rotation = sin(bounce_time) * 0.06 * tilt_sign
		if _head_pivot:
			_head_pivot.position.y = _head_rest_y + sin(bounce_time - 0.45) * bob
	else:
		rotation = 0.0
		if _head_pivot:
			_head_pivot.position.y = _head_rest_y


func _build_layers() -> void:
	for child in get_children():
		child.queue_free()

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
	_body_sprite.position = Vector2.ZERO
	add_child(_body_sprite)

	if head_tex == null:
		push_warning("TunerBodyVisual: missing head texture at %s" % head_texture_path)
		return

	_head_pivot = Node2D.new()
	_head_pivot.name = "HeadPivot"
	add_child(_head_pivot)

	_head_sprite = Sprite2D.new()
	_head_sprite.name = "HeadSprite"
	_head_sprite.texture = head_tex
	_head_sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_head_sprite.centered = true
	_head_pivot.add_child(_head_sprite)
	_apply_head_attachment()


func _apply_head_attachment() -> void:
	if _head_pivot == null or _head_sprite == null or _layer_layout == null or _body_tex == null:
		return
	var head_tex := _head_sprite.texture
	_head_rest_y = PartsRegistry.head_pivot_on_body_local(_body_tex, _layer_layout).y
	_head_pivot.position = PartsRegistry.head_pivot_on_body_local(_body_tex, _layer_layout)
	_head_sprite.position = PartsRegistry.head_sprite_offset_local(head_tex, _layer_layout)


func _load_texture(path: String) -> Texture2D:
	if path.is_empty() or not ResourceLoader.exists(path):
		return null
	return load(path) as Texture2D
