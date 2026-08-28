extends RefCounted
class_name CharacterCardPartsRegistry

## Layered character-card parts (blank body + head) for the animation tuner and future card pipeline.

const LayerLayoutScript = preload("res://scripts/config/character_card_layer_layout.gd")

const PARTS_DIR := "res://assets/character_cards/"
const BLANK_BODY_PATH := PARTS_DIR + "body1.png"
const BLANK_HEAD_PATH := PARTS_DIR + "head1.png"
const HAIR1_PATH := PARTS_DIR + "hair1.png"
const HAIR2_PATH := PARTS_DIR + "hair2.png"
const HAIR_SHEET_SIZE := Vector2(500.0, 700.0)
const HEAD1_SHEET_SIZE := Vector2(307.0, 350.0)
## head1.png top-left on the locked HEAD GUIDE layer in 500×700 hair sheets.
const HEAD_GUIDE_TOP_LEFT_IN_HAIR_PX := Vector2(96.5, 310.0)
const DEFAULT_LAYOUT_PATH := PARTS_DIR + "layered_blank_1.tres"

static var _layout: CharacterCardLayerLayout
static var _runtime_hair_texture_path: String = ""


static func set_runtime_hair_texture_path(path: String) -> void:
	_runtime_hair_texture_path = path.strip_edges()
	if _layout != null and not _runtime_hair_texture_path.is_empty():
		_layout.hair_texture_path = _runtime_hair_texture_path


static func get_layout() -> CharacterCardLayerLayout:
	if _layout == null:
		if ResourceLoader.exists(DEFAULT_LAYOUT_PATH):
			_layout = load(DEFAULT_LAYOUT_PATH) as CharacterCardLayerLayout
		if _layout == null:
			_layout = LayerLayoutScript.new()
	if _layout != null and not _runtime_hair_texture_path.is_empty():
		_layout.hair_texture_path = _runtime_hair_texture_path
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
	return active.body_neck_socket_px - center + active.body_offset_px


static func head_sprite_offset_local(head_tex: Texture2D, layout: CharacterCardLayerLayout = null) -> Vector2:
	if head_tex == null:
		return Vector2.ZERO
	var active := layout if layout else get_layout()
	var size := Vector2(head_tex.get_width(), head_tex.get_height())
	var center := size * 0.5
	return center - active.head_pivot_px


static func default_hair_pivot_px(layout: CharacterCardLayerLayout = null) -> Vector2:
	var active := layout if layout else get_layout()
	if active == null:
		return HEAD_GUIDE_TOP_LEFT_IN_HAIR_PX + Vector2(153.0, 345.0)
	return HEAD_GUIDE_TOP_LEFT_IN_HAIR_PX + active.head_pivot_px


static func resolved_hair_pivot_px(layout: CharacterCardLayerLayout = null) -> Vector2:
	var active := layout if layout else get_layout()
	if active == null:
		return default_hair_pivot_px()
	if active.hair_pivot_px.x < 0.0 or active.hair_pivot_px.y < 0.0:
		return default_hair_pivot_px(active)
	return active.hair_pivot_px


static func resolved_hair_attach_local_px(
	layout: CharacterCardLayerLayout = null,
	facing_left: bool = false
) -> Vector2:
	var active := layout if layout else get_layout()
	if active == null:
		return Vector2.ZERO
	var attach := active.hair_attach_local_px
	if facing_left:
		attach.x = -attach.x
	return attach


static func hair_sprite_offset_local(
	hair_tex: Texture2D,
	layout: CharacterCardLayerLayout = null,
	facing_left: bool = false
) -> Vector2:
	if hair_tex == null:
		return Vector2.ZERO
	var active := layout if layout else get_layout()
	var center := Vector2(hair_tex.get_width(), hair_tex.get_height()) * 0.5
	var pivot := resolved_hair_pivot_px(active)
	var attach := resolved_hair_attach_local_px(active, facing_left)
	return attach + pivot - center


static func load_hair_texture(layout: CharacterCardLayerLayout = null) -> Texture2D:
	var active := layout if layout else get_layout()
	var path := active.hair_texture_path if active else HAIR1_PATH
	if path.is_empty() or not ResourceLoader.exists(path):
		return null
	return load(path) as Texture2D
