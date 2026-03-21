extends Node

# UITheme - Centralized UI styling for Stone Age Clans
# Provides consistent colors, styles, and sizing across all UI elements
# Use as autoload singleton: UITheme.get_panel_style()

## Color Constants

# Background colors
const COLOR_BG_DARK_BROWN: Color = Color(0x1a / 255.0, 0x15 / 255.0, 0x12 / 255.0, 0.85)  # Dark brown, 85% opacity
const COLOR_BG_OPACITY: float = 0.85

# Border colors
const COLOR_BORDER_SADDLE_BROWN: Color = Color(0x8b / 255.0, 0x45 / 255.0, 0x13 / 255.0, 0.9)  # Saddle brown, 90% opacity
const COLOR_BORDER_OPACITY: float = 0.9

# Shadow colors
const COLOR_SHADOW_BLACK: Color = Color(0, 0, 0, 0.25)  # Black, 25% opacity

# Text colors
const COLOR_TEXT_PRIMARY: Color = Color(0xe8 / 255.0, 0xe8 / 255.0, 0xe8 / 255.0, 1.0)  # Off-white #e8e8e8
const COLOR_TEXT_SECONDARY: Color = Color(0xb0 / 255.0, 0xb0 / 255.0, 0xb0 / 255.0, 1.0)  # Light gray #b0b0b0
const COLOR_TEXT_ERROR: Color = Color(0xd3 / 255.0, 0x2f / 255.0, 0x2f / 255.0, 1.0)  # Red #d32f2f
const COLOR_TEXT_SUCCESS: Color = Color(0x66 / 255.0, 0xbb / 255.0, 0x6a / 255.0, 1.0)  # Green #66bb6a
const COLOR_TEXT_SELECTED: Color = Color(0xff / 255.0, 0xa7 / 255.0, 0x26 / 255.0, 1.0)  # Gold #ffa726

## Style Constants

const BORDER_WIDTH: int = 2
const CORNER_RADIUS: int = 12
const SHADOW_SIZE: int = 4
const SHADOW_OFFSET: Vector2 = Vector2(0, 5)

## Size Constants

const PANEL_WIDTH_STANDARD: int = 320
const PANEL_HEIGHT_STANDARD: int = 400
const PANEL_PADDING_STANDARD: int = 8
const PANEL_PADDING_LARGE: int = 16

const SLOT_SIZE: int = 32
const SLOT_SPACING_VERTICAL: int = 0
const SLOT_SPACING_HORIZONTAL: int = 6

const HOTBAR_HEIGHT: int = 64

## Font Size Constants

const FONT_SIZE_TITLE: int = 18  # 18-20px for titles/headers
const FONT_SIZE_BODY: int = 12   # 12-14px for body text
const FONT_SIZE_SECONDARY: int = 10  # 10-12px for secondary text

## Style Functions

# Returns the standard panel style used across all UI elements
# This is the default brown, semi-transparent panel style
static func get_panel_style() -> StyleBoxFlat:
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

# Returns a custom panel style with modified opacity
# opacity: 0.0 - 1.0 (default 0.85)
static func get_panel_style_with_opacity(opacity: float = 0.85) -> StyleBoxFlat:
	var style := get_panel_style()
	style.bg_color.a = opacity
	return style

# Returns a panel style with custom border color
# border_color: Color to use for border (defaults to saddle brown)
static func get_panel_style_with_border(border_color: Color = COLOR_BORDER_SADDLE_BROWN) -> StyleBoxFlat:
	var style := get_panel_style()
	style.border_color = border_color
	return style

# Returns a highlighted panel style (e.g., for selected items)
# Uses gold border color for selection
static func get_panel_style_highlighted() -> StyleBoxFlat:
	return get_panel_style_with_border(COLOR_TEXT_SELECTED)

## Utility Functions

# Applies standard panel style to a Panel node
# panel: Panel node to style
static func apply_panel_style(panel: Panel) -> void:
	if not panel:
		return
	panel.add_theme_stylebox_override("panel", get_panel_style())

# Creates a standard panel with style already applied
# size: Vector2 size for panel (default 320x400)
static func create_styled_panel(size: Vector2 = Vector2(PANEL_WIDTH_STANDARD, PANEL_HEIGHT_STANDARD)) -> Panel:
	var panel := Panel.new()
	panel.custom_minimum_size = size
	apply_panel_style(panel)
	return panel

# Returns text color based on state
# state: "primary", "secondary", "error", "success", "selected"
static func get_text_color(state: String = "primary") -> Color:
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

## Debug/Development

func _ready() -> void:
	# UITheme singleton loaded
	pass
