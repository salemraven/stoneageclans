extends Node2D
class_name TunerBodyVisual

## Rounded-square body + circle head in card texture space (feet at card bottom).

@export var body_color := Color(0.55, 0.42, 0.35, 1.0)
@export var head_color := Color(0.72, 0.58, 0.48, 1.0)

var _layout
var _body_poly: Polygon2D
var _head_poly: Polygon2D
var _head_pivot: Node2D
var _feet_local_y := 408.0


func _ready() -> void:
	z_index = -2


func apply_layout(layout) -> void:
	_layout = layout
	_feet_local_y = layout.feet_local_y if layout else 408.0
	_build_shapes()


func set_walk_state(moving: bool, bounce_time: float, direction: int) -> void:
	var tilt_sign := -1.0 if direction < 0 else 1.0
	var bob: float = _layout.head_bob_local() if _layout else 2.5
	if moving:
		rotation = sin(bounce_time) * 0.06 * tilt_sign
		if _head_pivot:
			_head_pivot.position.y = _head_center_y() + sin(bounce_time - 0.45) * bob
	else:
		rotation = 0.0
		if _head_pivot:
			_head_pivot.position.y = _head_center_y()


func _head_center_y() -> float:
	var body_h: float = _layout.body_height_local() if _layout else 72.0
	var gap: float = _layout.head_gap_local() if _layout else 8.0
	var head_r: float = _layout.head_radius_local() if _layout else 20.0
	return _feet_local_y - body_h - gap - head_r


func _build_shapes() -> void:
	for child in get_children():
		child.queue_free()

	var body_w: float = _layout.body_width_local() if _layout else 52.0
	var body_h: float = _layout.body_height_local() if _layout else 72.0
	var corner_r: float = _layout.corner_radius_local() if _layout else 12.0
	var head_r: float = _layout.head_radius_local() if _layout else 20.0
	var feet := Vector2(0.0, _feet_local_y)

	_body_poly = _make_filled_poly(body_color)
	_body_poly.polygon = make_rounded_rect_points(body_w, body_h, corner_r, feet)
	add_child(_body_poly)

	_head_pivot = Node2D.new()
	_head_pivot.name = "HeadPivot"
	_head_pivot.position.y = _head_center_y()
	add_child(_head_pivot)

	_head_poly = _make_filled_poly(head_color)
	_head_poly.polygon = _circle_points(head_r, 18)
	_head_pivot.add_child(_head_poly)


func _make_filled_poly(color: Color) -> Polygon2D:
	var poly := Polygon2D.new()
	poly.color = color
	poly.antialiased = true
	return poly


static func make_rounded_rect_points(width: float, height: float, radius: float, bottom_center: Vector2) -> PackedVector2Array:
	var left := bottom_center.x - width * 0.5
	var right := bottom_center.x + width * 0.5
	var bottom := bottom_center.y
	var top := bottom_center.y - height
	var r := minf(radius, minf(width, height) * 0.5)
	var arc_segments := 7
	var pts := PackedVector2Array()

	pts.append(Vector2(left + r, bottom))
	pts.append(Vector2(right - r, bottom))
	_append_arc(pts, Vector2(right - r, bottom - r), r, 0.0, -PI * 0.5, arc_segments)
	pts.append(Vector2(right, top + r))
	_append_arc(pts, Vector2(right - r, top + r), r, -PI * 0.5, -PI, arc_segments)
	pts.append(Vector2(left + r, top))
	_append_arc(pts, Vector2(left + r, top + r), r, -PI, -PI * 1.5, arc_segments)
	pts.append(Vector2(left, bottom - r))
	_append_arc(pts, Vector2(left + r, bottom - r), r, PI * 0.5, 0.0, arc_segments)
	return pts


static func _append_arc(
	pts: PackedVector2Array,
	center: Vector2,
	radius: float,
	angle_from: float,
	angle_to: float,
	segments: int
) -> void:
	for i in range(1, segments + 1):
		var t := float(i) / float(segments)
		var angle := lerpf(angle_from, angle_to, t)
		pts.append(center + Vector2(cos(angle), sin(angle)) * radius)


static func _circle_points(radius: float, segments: int) -> PackedVector2Array:
	var pts := PackedVector2Array()
	for i in range(segments):
		var angle := TAU * float(i) / float(segments)
		pts.append(Vector2(cos(angle), sin(angle)) * radius)
	return pts
