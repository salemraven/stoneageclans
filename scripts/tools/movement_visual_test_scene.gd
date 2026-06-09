extends Node2D
## Run `res://scenes/MovementVisualTest.tscn` for a minimal 2D movement test (WASD / arrows).

@export var zoom_level: float = 2.75
@export var zoom_min: float = 0.85
@export var zoom_max: float = 6.0
@export var zoom_step: float = 1.12
## Matches main game: no wood club until wood is in hotbar slot 1. Enable to preview 2D club walk here.
@export var equip_wood_club_for_test: bool = false

@onready var _player: CharacterBody2D = $Player
@onready var _cam: Camera2D = $Camera2D


func _ready() -> void:
	if _cam:
		_cam.make_current()
		_apply_zoom()
	if equip_wood_club_for_test and is_instance_valid(_player) and _player.has_method("set_equipment"):
		_player.call_deferred("set_equipment", ResourceData.ResourceType.WOOD)


func _unhandled_input(event: InputEvent) -> void:
	if _cam == null:
		return
	if event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_WHEEL_UP:
			zoom_level = clampf(zoom_level * zoom_step, zoom_min, zoom_max)
			_apply_zoom()
			get_viewport().set_input_as_handled()
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			zoom_level = clampf(zoom_level / zoom_step, zoom_min, zoom_max)
			_apply_zoom()
			get_viewport().set_input_as_handled()
	elif event is InputEventKey and event.pressed:
		if event.keycode in [KEY_EQUAL, KEY_PLUS]:
			zoom_level = clampf(zoom_level * zoom_step, zoom_min, zoom_max)
			_apply_zoom()
			get_viewport().set_input_as_handled()
		elif event.keycode == KEY_MINUS:
			zoom_level = clampf(zoom_level / zoom_step, zoom_min, zoom_max)
			_apply_zoom()
			get_viewport().set_input_as_handled()


func _apply_zoom() -> void:
	if _cam:
		var z: float = clampf(zoom_level, zoom_min, zoom_max)
		_cam.zoom = Vector2(z, z)


func _physics_process(_delta: float) -> void:
	if _cam and is_instance_valid(_player):
		_cam.global_position = _player.global_position
