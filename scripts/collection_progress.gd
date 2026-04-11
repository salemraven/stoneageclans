extends Node2D
class_name CollectionProgress

@export var collection_time: float = 1.0
@export var radius: float = 18.0

const CANCEL_FLASH_DURATION: float = 1.0
const CANCEL_COLOR_FILL := Color(0.95, 0.15, 0.12, 0.75)
const CANCEL_COLOR_OUTLINE := Color(0.95, 0.2, 0.15, 0.95)
const CANCEL_ICON_TINT := Color(1.0, 0.35, 0.35, 1.0)

var _progress: float = 0.0
var _is_collecting: bool = false
var _collection_tween: Tween
var _item_icon: Texture2D = null  # Icon to show in center of progress circle

var _cancel_flash_active: bool = false
var _cancel_flash_generation: int = 0

func _ready() -> void:
	pass

func _end_cancel_flash_generation(gen: int) -> void:
	if gen != _cancel_flash_generation:
		return
	_cancel_flash_active = false
	_full_reset_hidden()

func _full_reset_hidden() -> void:
	_is_collecting = false
	_progress = 0.0
	_item_icon = null
	_cancel_flash_active = false
	visible = false
	if _collection_tween:
		_collection_tween.kill()
		_collection_tween = null
	queue_redraw()

func start_collection(icon: Texture2D = null) -> void:
	# New action clears any cancel flash or prior tween
	_cancel_flash_generation += 1
	if _cancel_flash_active:
		_cancel_flash_active = false
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

## If cancelled is true, shows frozen progress + icon in red for [CANCEL_FLASH_DURATION], then hides.
func stop_collection(cancelled: bool = false) -> void:
	if _collection_tween:
		_collection_tween.kill()
		_collection_tween = null

	if cancelled and ( _is_collecting or _progress > 0.001 or _cancel_flash_active ):
		_is_collecting = false
		_cancel_flash_active = true
		_cancel_flash_generation += 1
		var gen: int = _cancel_flash_generation
		visible = true
		queue_redraw()
		var t: SceneTreeTimer = get_tree().create_timer(CANCEL_FLASH_DURATION)
		t.timeout.connect(func(): _end_cancel_flash_generation(gen))
		return

	_full_reset_hidden()

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
	if _cancel_flash_active:
		if _progress <= 0.0:
			return
		_draw_progress_fill(_progress, CANCEL_COLOR_FILL, CANCEL_COLOR_OUTLINE)
		if _item_icon:
			var center := Vector2.ZERO
			var icon_size: float = radius * 1.6
			var icon_rect := Rect2(center - Vector2(icon_size / 2.0, icon_size / 2.0), Vector2(icon_size, icon_size))
			draw_texture_rect(_item_icon, icon_rect, false, CANCEL_ICON_TINT)
		draw_arc(Vector2.ZERO, radius, 0.0, TAU, 64, CANCEL_COLOR_OUTLINE, 2.0, false)
		return

	if _progress <= 0.0:
		return

	var fill_col := Color(1.0, 1.0, 1.0, 0.7)
	var outline_col := Color(1.0, 1.0, 1.0, 0.9)
	if _progress >= 1.0:
		draw_circle(Vector2.ZERO, radius, Color(0.0, 1.0, 0.0, 0.6))
		draw_arc(Vector2.ZERO, radius, 0.0, TAU, 64, Color(0.0, 1.0, 0.0, 0.9), 2.0, false)
	else:
		_draw_progress_fill(_progress, fill_col, outline_col)

	draw_arc(Vector2.ZERO, radius, 0.0, TAU, 64, Color(1.0, 1.0, 1.0, 0.7), 2.0, false)

	if _item_icon:
		var center := Vector2.ZERO
		var icon_size: float = radius * 1.6
		var icon_rect := Rect2(center - Vector2(icon_size / 2.0, icon_size / 2.0), Vector2(icon_size, icon_size))
		draw_texture_rect(_item_icon, icon_rect, false)

func _draw_progress_fill(p: float, fill_col: Color, outline_col: Color) -> void:
	var center := Vector2.ZERO
	var start_angle := -TAU / 4.0
	if p >= 1.0:
		draw_circle(center, radius, fill_col)
		draw_arc(center, radius, 0.0, TAU, 64, outline_col, 2.0, false)
		return
	var end_angle: float = start_angle + (TAU * p)
	var point_count: int = max(8, int(p * 32))
	var points := PackedVector2Array()
	points.append(center)
	for i in point_count + 1:
		var angle: float = lerp(start_angle, end_angle, float(i) / float(point_count))
		var point: Vector2 = center + Vector2(cos(angle), sin(angle)) * radius
		points.append(point)
	draw_colored_polygon(points, fill_col)
	draw_arc(center, radius, start_angle, end_angle, point_count, outline_col, 2.0, false)
	draw_line(center, center + Vector2(cos(start_angle), sin(start_angle)) * radius, outline_col, 2.0)
	draw_line(center, center + Vector2(cos(end_angle), sin(end_angle)) * radius, outline_col, 2.0)
