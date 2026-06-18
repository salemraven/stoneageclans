extends Node2D
class_name LimbTunerHandle

## Draggable circle handle for the limb tuner (shoulder / hand / spear anchor).

signal drag_started
signal drag_moved(global_pos: Vector2)
signal drag_ended

@export var handle_color: Color = Color(0.9, 0.2, 0.2, 1.0)
@export var handle_radius: float = 8.0

var draggable: bool = true

var _dragging: bool = false
var _poly: Polygon2D
var _side_label: Label


func _ready() -> void:
	z_as_relative = false
	z_index = 4094
	_poly = Polygon2D.new()
	_poly.antialiased = false
	add_child(_poly)
	_side_label = Label.new()
	_side_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_side_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_side_label.add_theme_font_size_override("font_size", 9)
	_side_label.add_theme_color_override("font_color", Color(1.0, 1.0, 1.0, 1.0))
	_side_label.add_theme_color_override("font_outline_color", Color(0.0, 0.0, 0.0, 1.0))
	_side_label.add_theme_constant_override("outline_size", 2)
	add_child(_side_label)
	_refresh_circle()
	_refresh_side_label_layout()


func set_side_label(text: String) -> void:
	if _side_label:
		_side_label.text = text
		_side_label.visible = text.length() > 0
		_refresh_side_label_layout()


func set_handle_color(color: Color) -> void:
	handle_color = color
	if _poly:
		_poly.color = color
	_refresh_circle()


func set_handle_radius(radius: float) -> void:
	handle_radius = radius
	_refresh_circle()
	_refresh_side_label_layout()


func set_draggable(on: bool) -> void:
	draggable = on
	if not on:
		_dragging = false


func _refresh_circle() -> void:
	if _poly == null:
		return
	_poly.color = handle_color
	var pts := PackedVector2Array()
	var segments := 14
	for i in range(segments):
		var angle := TAU * float(i) / float(segments)
		pts.append(Vector2(cos(angle), sin(angle)) * handle_radius)
	_poly.polygon = pts
	_refresh_side_label_layout()


func _refresh_side_label_layout() -> void:
	if _side_label == null:
		return
	var box: float = handle_radius * 1.6
	_side_label.position = Vector2(-box * 0.5, -box * 0.5)
	_side_label.size = Vector2(box, box)


func is_dragging() -> bool:
	return _dragging


func _unhandled_input(_event: InputEvent) -> void:
	# Input is handled centrally by LimbTunerApp._input — handles are visual only.
	pass
