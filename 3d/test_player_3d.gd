extends CharacterBody3D
## Simple WASD movement for Test3D scene (DISABLED - in 3d/ folder)

var speed := 8.0

func _physics_process(_delta: float) -> void:
	var input := Vector3.ZERO
	input.x = Input.get_axis("move_right", "move_left")
	input.z = Input.get_axis("move_down", "move_up")
	input = input.normalized()
	velocity.x = input.x * speed
	velocity.z = input.z * speed
	move_and_slide()
