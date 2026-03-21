extends Node2D
class_name CollectionProgress

@export var collection_time: float = 1.0
@export var radius: float = 18.0

var _progress: float = 0.0
var _is_collecting: bool = false
var _collection_tween: Tween
var _item_icon: Texture2D = null  # Icon to show in center of progress circle

func _ready() -> void:
	# Make sure we can draw
	pass

func start_collection(icon: Texture2D = null) -> void:
	if _is_collecting:
		return
	
	_is_collecting = true
	_progress = 0.0
	_item_icon = icon
	visible = true
	
	if _collection_tween:
		_collection_tween.kill()
	
	_collection_tween = create_tween()
	_collection_tween.tween_method(_update_progress, 0.0, 1.0, collection_time)
	_collection_tween.tween_callback(_on_collection_complete)

func stop_collection() -> void:
	_is_collecting = false
	_progress = 0.0
	_item_icon = null
	visible = false
	
	if _collection_tween:
		_collection_tween.kill()
		_collection_tween = null
	
	queue_redraw()

func _update_progress(value: float) -> void:
	_progress = value
	queue_redraw()

func _on_collection_complete() -> void:
	_is_collecting = false
	_progress = 1.0
	queue_redraw()

func is_collecting() -> bool:
	return _is_collecting

func get_progress() -> float:
	return _progress

func set_progress(value: float) -> void:
	_progress = clamp(value, 0.0, 1.0)
	queue_redraw()

func _draw() -> void:
	if _progress <= 0.0:
		return
	
	# Draw pie chart progress (smaller circle)
	var center := Vector2.ZERO
	var start_angle := -TAU / 4.0  # Start at top (-90 degrees)
	
	if _progress >= 1.0:
		# Full circle when complete (green)
		draw_circle(center, radius, Color(0.0, 1.0, 0.0, 0.6))
		draw_arc(center, radius, 0.0, TAU, 64, Color(0.0, 1.0, 0.0, 0.9), 2.0, false)
	else:
		# Draw pie slice
		var end_angle: float = start_angle + (TAU * _progress)
		var point_count: int = max(8, int(_progress * 32))  # More points for smoother arc
		
		# Create points for the pie slice
		var points := PackedVector2Array()
		points.append(center)  # Center point
		
		# Add points along the arc
		for i in point_count + 1:
			var angle: float = lerp(start_angle, end_angle, float(i) / float(point_count))
			var point: Vector2 = center + Vector2(cos(angle), sin(angle)) * radius
			points.append(point)
		
		# Draw filled pie slice
		draw_colored_polygon(points, Color(1.0, 1.0, 1.0, 0.7))
		
		# Draw outline
		draw_arc(center, radius, start_angle, end_angle, point_count, Color(1.0, 1.0, 1.0, 0.9), 2.0, false)
		
		# Draw lines from center to arc ends
		draw_line(center, center + Vector2(cos(start_angle), sin(start_angle)) * radius, Color(1.0, 1.0, 1.0, 0.9), 2.0)
		draw_line(center, center + Vector2(cos(end_angle), sin(end_angle)) * radius, Color(1.0, 1.0, 1.0, 0.9), 2.0)
	
	# Draw outer circle outline
	draw_arc(center, radius, 0.0, TAU, 64, Color(1.0, 1.0, 1.0, 0.7), 2.0, false)
	
	# Draw item icon in center if available (larger icon)
	if _item_icon:
		# Icon is larger than circle, so it's clearly visible
		var icon_size: float = radius * 1.6
		var icon_rect := Rect2(center - Vector2(icon_size / 2.0, icon_size / 2.0), Vector2(icon_size, icon_size))
		draw_texture_rect(_item_icon, icon_rect, false)

