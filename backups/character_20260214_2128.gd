extends CharacterBody2D

@export var move_speed := 200.0

@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var combat_component: CombatComponent = $CombatComponent
@onready var sprite: Sprite2D = $Sprite

var _can_move := true
var player_name := ""
var is_gathering := false

func _ready() -> void:
	add_to_group("player")
	if combat_component:
		combat_component.initialize(self)
		combat_component.windup_time = 0.1
		combat_component.recovery_time = 0.3

func set_can_move(can_move: bool) -> void:
	_can_move = can_move
	if not can_move:
		velocity = Vector2.ZERO

func set_player_name(pname: String) -> void:
	player_name = pname
	set_meta("player_name", pname)

func get_player_name() -> String:
	if player_name != "":
		return player_name
	return get_meta("player_name", "Player")

func set_equipment(_item_type: Variant) -> void:
	pass  # Stub for main.gd compatibility

func _physics_process(_delta: float) -> void:
	if not _can_move:
		velocity = Vector2.ZERO
		move_and_slide()
		return
	if get("is_gathering") == true:
		velocity = Vector2.ZERO
		move_and_slide()
		return
	var input_vector := Vector2(
		Input.get_axis(&"move_left", &"move_right"),
		Input.get_axis(&"move_up", &"move_down")
	)
	if input_vector.length_squared() > 1.0:
		input_vector = input_vector.normalized()

	velocity = input_vector * move_speed
	move_and_slide()

	if sprite:
		YSortUtils.update_draw_order(sprite, self)

	var is_moving := input_vector != Vector2.ZERO
	if is_moving:
		scale.x = -1.0 if velocity.x < 0 else 1.0
		if not animation_player.is_playing():
			animation_player.play(&"walk")
	else:
		if animation_player.is_playing():
			animation_player.seek(0.0)
			animation_player.stop()
