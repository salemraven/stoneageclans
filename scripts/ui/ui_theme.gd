extends Node

const _DesignTokensParser = preload("res://scripts/ui/ui_design_tokens_parser.gd")

# UITheme - Centralized UI styling for Stone Age Clans
# Values default below; optional JSON at res://ui/design_tokens/design_tokens.json
# overrides them (Figma Variables → export → same keys; see ui/figma/README.md).
# Use: UITheme.get_panel_style() or UITheme.COLOR_TEXT_PRIMARY

static var _tokens_applied: bool = false

## Color tokens (mutable — design_tokens.json may override)
static var COLOR_BG_DARK_BROWN: Color = Color(0x1a / 255.0, 0x15 / 255.0, 0x12 / 255.0, 0.85)
static var COLOR_BORDER_SADDLE_BROWN: Color = Color(0x8b / 255.0, 0x45 / 255.0, 0x13 / 255.0, 0.9)
static var COLOR_SHADOW_BLACK: Color = Color(0, 0, 0, 0.25)
static var COLOR_TEXT_PRIMARY: Color = Color(0xe8 / 255.0, 0xe8 / 255.0, 0xe8 / 255.0, 1.0)
static var COLOR_TEXT_SECONDARY: Color = Color(0xb0 / 255.0, 0xb0 / 255.0, 0xb0 / 255.0, 1.0)
static var COLOR_TEXT_ERROR: Color = Color(0xd3 / 255.0, 0x2f / 255.0, 0x2f / 255.0, 1.0)
static var COLOR_TEXT_SUCCESS: Color = Color(0x66 / 255.0, 0xbb / 255.0, 0x6a / 255.0, 1.0)
static var COLOR_TEXT_SELECTED: Color = Color(0xff / 255.0, 0xa7 / 255.0, 0x26 / 255.0, 1.0)

## Layout / size tokens
static var BORDER_WIDTH: int = 2
static var CORNER_RADIUS: int = 12
static var SHADOW_SIZE: int = 4
static var SHADOW_OFFSET: Vector2 = Vector2(0, 5)

static var PANEL_WIDTH_STANDARD: int = 320
static var PANEL_HEIGHT_STANDARD: int = 400
static var PANEL_PADDING_STANDARD: int = 8
static var PANEL_PADDING_LARGE: int = 16

static var SLOT_SIZE: int = 32
static var SLOT_SPACING_VERTICAL: int = 0
static var SLOT_SPACING_HORIZONTAL: int = 6

static var HOTBAR_HEIGHT: int = 64

static var FONT_SIZE_TITLE: int = 18
static var FONT_SIZE_BODY: int = 12
static var FONT_SIZE_SECONDARY: int = 10


static func _ensure_tokens_loaded() -> void:
	if _tokens_applied:
		return
	_tokens_applied = true
	var root: Dictionary = _DesignTokensParser.load_file()
	if root.is_empty():
		return
	_apply_design_tokens(root)


static func _apply_design_tokens(root: Dictionary) -> void:
	var colors: Dictionary = root.get("colors", {}) as Dictionary
	if not colors.is_empty():
		if colors.has("bg_dark_brown"):
			COLOR_BG_DARK_BROWN = _DesignTokensParser.parse_color(colors["bg_dark_brown"])
		if colors.has("border_saddle_brown"):
			COLOR_BORDER_SADDLE_BROWN = _DesignTokensParser.parse_color(colors["border_saddle_brown"])
		if colors.has("shadow_black"):
			COLOR_SHADOW_BLACK = _DesignTokensParser.parse_color(colors["shadow_black"])
		if colors.has("text_primary"):
			COLOR_TEXT_PRIMARY = _DesignTokensParser.parse_color(colors["text_primary"])
		if colors.has("text_secondary"):
			COLOR_TEXT_SECONDARY = _DesignTokensParser.parse_color(colors["text_secondary"])
		if colors.has("text_error"):
			COLOR_TEXT_ERROR = _DesignTokensParser.parse_color(colors["text_error"])
		if colors.has("text_success"):
			COLOR_TEXT_SUCCESS = _DesignTokensParser.parse_color(colors["text_success"])
		if colors.has("text_selected"):
			COLOR_TEXT_SELECTED = _DesignTokensParser.parse_color(colors["text_selected"])

	var layout: Dictionary = root.get("layout", {}) as Dictionary
	if not layout.is_empty():
		if layout.has("border_width"):
			BORDER_WIDTH = int(layout["border_width"])
		if layout.has("corner_radius"):
			CORNER_RADIUS = int(layout["corner_radius"])
		if layout.has("shadow_size"):
			SHADOW_SIZE = int(layout["shadow_size"])
		if layout.has("shadow_offset") and layout["shadow_offset"] is Array:
			var o: Array = layout["shadow_offset"] as Array
			if o.size() >= 2:
				SHADOW_OFFSET = Vector2(float(o[0]), float(o[1]))

	var sizes: Dictionary = root.get("sizes", {}) as Dictionary
	if not sizes.is_empty():
		if sizes.has("panel_width_standard"):
			PANEL_WIDTH_STANDARD = int(sizes["panel_width_standard"])
		if sizes.has("panel_height_standard"):
			PANEL_HEIGHT_STANDARD = int(sizes["panel_height_standard"])
		if sizes.has("panel_padding_standard"):
			PANEL_PADDING_STANDARD = int(sizes["panel_padding_standard"])
		if sizes.has("panel_padding_large"):
			PANEL_PADDING_LARGE = int(sizes["panel_padding_large"])
		if sizes.has("slot_size"):
			SLOT_SIZE = int(sizes["slot_size"])
		if sizes.has("slot_spacing_vertical"):
			SLOT_SPACING_VERTICAL = int(sizes["slot_spacing_vertical"])
		if sizes.has("slot_spacing_horizontal"):
			SLOT_SPACING_HORIZONTAL = int(sizes["slot_spacing_horizontal"])
		if sizes.has("hotbar_height"):
			HOTBAR_HEIGHT = int(sizes["hotbar_height"])

	var typo: Dictionary = root.get("typography", {}) as Dictionary
	if not typo.is_empty():
		if typo.has("font_size_title"):
			FONT_SIZE_TITLE = int(typo["font_size_title"])
		if typo.has("font_size_body"):
			FONT_SIZE_BODY = int(typo["font_size_body"])
		if typo.has("font_size_secondary"):
			FONT_SIZE_SECONDARY = int(typo["font_size_secondary"])


## Reload tokens at runtime (e.g. after editing JSON in dev)
static func reload_design_tokens(path: String = "res://ui/design_tokens/design_tokens.json") -> bool:
	var root: Dictionary = _DesignTokensParser.load_file(path)
	if root.is_empty():
		return false
	_apply_design_tokens(root)
	return true


static func get_panel_style() -> StyleBoxFlat:
	_ensure_tokens_loaded()
	var style := StyleBoxFlat.new()
	style.bg_color = COLOR_BG_DARK_BROWN
	style.border_color = COLOR_BORDER_SADDLE_BROWN
	style.set_border_width_all(BORDER_WIDTH)
	style.corner_radius_top_left = CORNER_RADIUS
	style.corner_radius_top_right = CORNER_RADIUS
	style.corner_radius_bottom_left = CORNER_RADIUS
	style.corner_radius_bottom_right = CORNER_RADIUS
	style.shadow_color = COLOR_SHADOW_BLACK
	style.shadow_size = SHADOW_SIZE
	style.shadow_offset = SHADOW_OFFSET
	return style


static func get_panel_style_with_opacity(opacity: float = 0.85) -> StyleBoxFlat:
	var style := get_panel_style()
	style.bg_color.a = opacity
	return style


static func get_panel_style_with_border(border_color: Color = COLOR_BORDER_SADDLE_BROWN) -> StyleBoxFlat:
	var style := get_panel_style()
	style.border_color = border_color
	return style


static func get_panel_style_highlighted() -> StyleBoxFlat:
	return get_panel_style_with_border(COLOR_TEXT_SELECTED)


static func apply_panel_style(panel: Panel) -> void:
	if not panel:
		return
	_ensure_tokens_loaded()
	panel.add_theme_stylebox_override("panel", get_panel_style())


static func create_styled_panel(size: Vector2 = Vector2(PANEL_WIDTH_STANDARD, PANEL_HEIGHT_STANDARD)) -> Panel:
	_ensure_tokens_loaded()
	var panel := Panel.new()
	panel.custom_minimum_size = size
	apply_panel_style(panel)
	return panel


static func get_text_color(state: String = "primary") -> Color:
	_ensure_tokens_loaded()
	match state:
		"primary":
			return COLOR_TEXT_PRIMARY
		"secondary":
			return COLOR_TEXT_SECONDARY
		"error":
			return COLOR_TEXT_ERROR
		"success":
			return COLOR_TEXT_SUCCESS
		"selected":
			return COLOR_TEXT_SELECTED
		_:
			return COLOR_TEXT_PRIMARY


func _init() -> void:
	_ensure_tokens_loaded()


func _ready() -> void:
	pass
