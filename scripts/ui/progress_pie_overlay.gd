extends Control
class_name ProgressPieOverlay

## Pie-style progress overlay for UI (craft icons, building slots).
## Parent to any Control; draws a pie timer matching CollectionProgress style.

signal progress_completed

var _progress: float = 0.0
var _tween: Tween = null

func start_progress(duration: float) -> void:
	if _tween:
		_tween.kill()
	_progress = 0.0
	visible = true
	_tween = create_tween()
	_tween.tween_method(_update_progress, 0.0, 1.0, duration)
	_tween.tween_callback(_on_complete)

func stop_progress() -> void:
	if _tween:
		_tween.kill()
		_tween = null
	_progress = 0.0
	visible = false
	queue_redraw()

func is_in_progress() -> bool:
	return visible and _tween and _tween.is_valid()

func _update_progress(value: float) -> void:
	_progress = value
	queue_redraw()

func _on_complete() -> void:
	_progress = 1.0
	_tween = null
	queue_redraw()
	progress_completed.emit()

func _draw() -> void:
	if _progress <= 0.0:
		return
	var draw_size: Vector2 = get_size()
	var center: Vector2 = draw_size / 2.0
	var radius: float = minf(draw_size.x, draw_size.y) * 0.45
	var start_angle: float = -TAU / 4.0
	if _progress >= 1.0:
		draw_circle(center, radius, Color(0.0, 1.0, 0.0, 0.6))
		draw_arc(center, radius, 0.0, TAU, 64, Color(0.0, 1.0, 0.0, 0.9), 2.0, false)
	else:
		var end_angle: float = start_angle + (TAU * _progress)
		var point_count: int = maxi(8, int(_progress * 32))
		var points := PackedVector2Array()
		points.append(center)
		for i in point_count + 1:
			var angle: float = lerp(start_angle, end_angle, float(i) / float(point_count))
			points.append(center + Vector2(cos(angle), sin(angle)) * radius)
		draw_colored_polygon(points, Color(1.0, 1.0, 1.0, 0.7))
		draw_arc(center, radius, start_angle, end_angle, point_count, Color(1.0, 1.0, 1.0, 0.9), 2.0, false)
		draw_line(center, center + Vector2(cos(start_angle), sin(start_angle)) * radius, Color(1.0, 1.0, 1.0, 0.9), 2.0)
		draw_line(center, center + Vector2(cos(end_angle), sin(end_angle)) * radius, Color(1.0, 1.0, 1.0, 0.9), 2.0)
	draw_arc(center, radius, 0.0, TAU, 64, Color(1.0, 1.0, 1.0, 0.7), 2.0, false)
