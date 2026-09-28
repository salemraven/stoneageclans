extends RefCounted
class_name CharacterCardPartsRegistry

## Layered character-card parts (blank body + head) for the animation tuner and future card pipeline.

const LayerLayoutScript = preload("res://scripts/config/character_card_layer_layout.gd")

const PARTS_DIR := "res://assets/character_cards/"
const BLANK_BODY_PATH := PARTS_DIR + "body1.png"
const BLANK_HEAD_PATH := PARTS_DIR + "head1.png"
const FEMALE_BODY_PATH := PARTS_DIR + "fbody1.png"
const FEMALE_HEAD_PATH := PARTS_DIR + "fhead1.png"
const HAIR_DIR := PARTS_DIR + "hair/"
const HAIR_STYLE_COUNT := 15
const HAIR1_PATH := HAIR_DIR + "01hair.png"
const HAIR2_PATH := HAIR_DIR + "02hair.png"
const HAIR_TONE_IDS: Array[String] = [
	"Black",
	"DarkBrown",
	"Brown",
	"LightBrown",
	"DirtyBlonde",
	"Auburn",
	"Gray",
]
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
	return _load_png(path)


static func load_blank_head() -> Texture2D:
	var path := get_layout().head_texture_path if get_layout() else BLANK_HEAD_PATH
	return _load_png(path)


static func _load_png(path: String) -> Texture2D:
	if path.is_empty():
		return null
	if ResourceLoader.exists(path):
		var tex: Texture2D = load(path) as Texture2D
		if tex:
			return tex
	if FileAccess.file_exists(path):
		var img := Image.new()
		if img.load(path) == OK:
			return ImageTexture.create_from_image(img)
	return null


static func clone_layout(src: CharacterCardLayerLayout) -> CharacterCardLayerLayout:
	var copy := LayerLayoutScript.new()
	if src == null:
		return copy
	copy.layout_id = src.layout_id
	copy.body_texture_path = src.body_texture_path
	copy.head_texture_path = src.head_texture_path
	copy.body_neck_socket_px = src.body_neck_socket_px
	copy.head_pivot_px = src.head_pivot_px
	copy.body_offset_px = src.body_offset_px
	copy.hair_texture_path = src.hair_texture_path
	copy.hair_pivot_px = src.hair_pivot_px
	copy.hair_attach_local_px = src.hair_attach_local_px
	return copy


static func clamp_hair_id(hair_id: int) -> int:
	if hair_id < 1 or hair_id > HAIR_STYLE_COUNT:
		return 1
	return hair_id


static func hair_tone_count() -> int:
	return HAIR_TONE_IDS.size()


static func normalize_hair_tone(tone: String) -> String:
	var key := tone.strip_edges()
	for id in HAIR_TONE_IDS:
		if id == key:
			return id
	return "Brown"


static func hair_tone_at(index: int) -> String:
	var n := hair_tone_count()
	if n < 1:
		return "Brown"
	var i := index % n
	if i < 0:
		i += n
	return HAIR_TONE_IDS[i]


static func hair_tone_to_color(tone: String) -> Color:
	match normalize_hair_tone(tone):
		"Black":
			return Color(0.10, 0.08, 0.07, 1.0)
		"DarkBrown":
			return Color(0.22, 0.14, 0.10, 1.0)
		"LightBrown":
			return Color(0.58, 0.40, 0.24, 1.0)
		"DirtyBlonde":
			return Color(0.82, 0.68, 0.42, 1.0)
		"Auburn":
			return Color(0.55, 0.24, 0.14, 1.0)
		"Gray":
			return Color(0.68, 0.66, 0.64, 1.0)
		_:
			return Color(0.42, 0.28, 0.16, 1.0)


static func _png_available(path: String) -> bool:
	if path.is_empty():
		return false
	return ResourceLoader.exists(path) or FileAccess.file_exists(path)


## `07hair.png` preferred; `07.png` accepted (export typo).
static func hair_texture_path_for_id(hair_id: int) -> String:
	var n := clamp_hair_id(hair_id)
	var pad := "%02d" % n
	var primary := HAIR_DIR + pad + "hair.png"
	if _png_available(primary):
		return primary
	var alt := HAIR_DIR + pad + ".png"
	if _png_available(alt):
		return alt
	return HAIR1_PATH


static func layout_with_hair(hair_id: int, female: bool) -> CharacterCardLayerLayout:
	var layout := get_female_layout() if female else clone_layout(get_layout())
	if not _runtime_hair_texture_path.is_empty():
		layout.hair_texture_path = _runtime_hair_texture_path
	else:
		layout.hair_texture_path = hair_texture_path_for_id(hair_id)
	return layout


## Same neck/pivot/hair numbers as the male layout; only body+head PNGs change.
static func get_female_layout() -> CharacterCardLayerLayout:
	var female := clone_layout(get_layout())
	female.body_texture_path = FEMALE_BODY_PATH
	female.head_texture_path = FEMALE_HEAD_PATH
	return female


static func load_female_body() -> Texture2D:
	return _load_png(get_female_layout().body_texture_path)


static func load_female_head() -> Texture2D:
	return _load_png(get_female_layout().head_texture_path)


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
	return _load_png(path)
