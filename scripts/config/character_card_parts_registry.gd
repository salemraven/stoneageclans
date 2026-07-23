extends RefCounted
class_name CharacterCardPartsRegistry

## Layered character-card parts (blank body + head) for the animation tuner and future card pipeline.

const LayerLayoutScript = preload("res://scripts/config/character_card_layer_layout.gd")

const PARTS_DIR := "res://assets/character_cards/"
const BLANK_BODY_PATH := PARTS_DIR + "body1.png"
const BLANK_HEAD_PATH := PARTS_DIR + "head1.png"
const DEFAULT_LAYOUT_PATH := PARTS_DIR + "layered_blank_1.tres"

static var _layout: CharacterCardLayerLayout


static func get_layout() -> CharacterCardLayerLayout:
	if _layout == null:
		if ResourceLoader.exists(DEFAULT_LAYOUT_PATH):
			_layout = load(DEFAULT_LAYOUT_PATH) as CharacterCardLayerLayout
		if _layout == null:
			_layout = LayerLayoutScript.new()
	return _layout


static func reload_layout() -> CharacterCardLayerLayout:
	_layout = null
	return get_layout()


static func save_layout(layout: CharacterCardLayerLayout) -> Error:
	if layout == null:
		return ERR_INVALID_PARAMETER
	_layout = layout
	return ResourceSaver.save(layout, DEFAULT_LAYOUT_PATH)


static func load_blank_body() -> Texture2D:
	var path := get_layout().body_texture_path if get_layout() else BLANK_BODY_PATH
	if ResourceLoader.exists(path):
		return load(path) as Texture2D
	return null


static func load_blank_head() -> Texture2D:
	var path := get_layout().head_texture_path if get_layout() else BLANK_HEAD_PATH
	if ResourceLoader.exists(path):
		return load(path) as Texture2D
	return null


static func head_pivot_on_body_local(body_tex: Texture2D, layout: CharacterCardLayerLayout = null) -> Vector2:
	if body_tex == null:
		return Vector2.ZERO
	var active := layout if layout else get_layout()
	var size := Vector2(body_tex.get_width(), body_tex.get_height())
	var center := size * 0.5
	return active.body_neck_socket_px - center


static func head_sprite_offset_local(head_tex: Texture2D, layout: CharacterCardLayerLayout = null) -> Vector2:
	if head_tex == null:
		return Vector2.ZERO
	var active := layout if layout else get_layout()
	var size := Vector2(head_tex.get_width(), head_tex.get_height())
	var center := size * 0.5
	return center - active.head_pivot_px
