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
var _socket_poly: Polygon2D
var _pin_line: Line2D
var _side_label: Label
var _body_pin_enabled: bool = false
var _pin_anchor_global: Vector2 = Vector2.ZERO


func _ready() -> void:
	z_as_relative = false
	z_index = 64
	_poly = Polygon2D.new()
	_poly.antialiased = false
	add_child(_poly)
	_pin_line = Line2D.new()
	_pin_line.name = "BodyPinLine"
	_pin_line.width = 2.0
	_pin_line.default_color = Color(0.55, 0.12, 0.12, 0.85)
	_pin_line.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_pin_line.joint_mode = Line2D.LINE_JOINT_ROUND
	_pin_line.begin_cap_mode = Line2D.LINE_CAP_ROUND
	_pin_line.end_cap_mode = Line2D.LINE_CAP_ROUND
	_pin_line.visible = false
	_pin_line.z_index = -2
	add_child(_pin_line)
	_socket_poly = Polygon2D.new()
	_socket_poly.name = "BodySocket"
	_socket_poly.antialiased = false
	_socket_poly.visible = false
	_socket_poly.z_index = -1
	add_child(_socket_poly)
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


func set_body_pin_enabled(on: bool) -> void:
	_body_pin_enabled = on
	if not on:
		if _pin_line:
			_pin_line.visible = false
		if _socket_poly:
			_socket_poly.visible = false


func set_pin_anchor_global(global_pos: Vector2) -> void:
	_pin_anchor_global = global_pos
	_refresh_pin_visual()


func _refresh_pin_visual() -> void:
	if not _body_pin_enabled or _pin_line == null or _socket_poly == null:
		return
	if _pin_anchor_global.distance_squared_to(global_position) < 0.25:
		_pin_line.visible = false
		_socket_poly.visible = false
		return
	var anchor_local := to_local(_pin_anchor_global)
	_pin_line.visible = true
	_pin_line.points = PackedVector2Array([anchor_local, Vector2.ZERO])
	_socket_poly.visible = true
	var socket_radius := maxf(handle_radius * 0.42, 2.5)
	var darker := handle_color.darkened(0.35)
	darker.a = 0.95
	_socket_poly.color = darker
	var pts := PackedVector2Array()
	var segments := 10
	for i in range(segments):
		var angle := TAU * float(i) / float(segments)
		pts.append(anchor_local + Vector2(cos(angle), sin(angle)) * socket_radius)
	_socket_poly.polygon = pts
	_pin_line.default_color = Color(darker.r, darker.g, darker.b, 0.75)


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
	_refresh_pin_visual()


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
