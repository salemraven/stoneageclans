extends Node2D
class_name TunerBodyVisual

## Layered blank body + head sprites in card texture space (feet at card bottom).

const PartsRegistry = preload("res://scripts/config/character_card_parts_registry.gd")

@export var body_texture_path: String = PartsRegistry.BLANK_BODY_PATH
@export var head_texture_path: String = PartsRegistry.BLANK_HEAD_PATH

var _layout
var _body_sprite: Sprite2D
var _head_pivot: Node2D
var _head_sprite: Sprite2D
var _head_rest_y := 0.0


func _ready() -> void:
	z_index = -2


func apply_layout(layout) -> void:
	_layout = layout
	_build_layers()


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

	var body_tex := _load_texture(body_texture_path)
	var head_tex := _load_texture(head_texture_path)
	if body_tex == null:
		push_warning("TunerBodyVisual: missing body texture at %s" % body_texture_path)
		return

	_body_sprite = Sprite2D.new()
	_body_sprite.name = "BodySprite"
	_body_sprite.texture = body_tex
	_body_sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_body_sprite.centered = true
	_body_sprite.position = Vector2.ZERO
	add_child(_body_sprite)

	if head_tex == null:
		push_warning("TunerBodyVisual: missing head texture at %s" % head_texture_path)
		return

	_head_pivot = Node2D.new()
	_head_pivot.name = "HeadPivot"
	_head_rest_y = PartsRegistry.head_pivot_on_body_local(body_tex).y
	_head_pivot.position = PartsRegistry.head_pivot_on_body_local(body_tex)
	add_child(_head_pivot)

	_head_sprite = Sprite2D.new()
	_head_sprite.name = "HeadSprite"
	_head_sprite.texture = head_tex
	_head_sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_head_sprite.centered = true
	_head_sprite.position = PartsRegistry.head_sprite_offset_local(head_tex)
	_head_pivot.add_child(_head_sprite)


func _load_texture(path: String) -> Texture2D:
	if path.is_empty() or not ResourceLoader.exists(path):
		return null
	return load(path) as Texture2D
