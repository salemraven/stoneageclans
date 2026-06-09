extends SceneTree

func _initialize() -> void:
	var script: GDScript = load("res://scripts/systems/corpse_job_service.gd") as GDScript
	if script == null:
		push_error("FAILED to load corpse_job_service.gd")
		quit(1)
		return
	print("OK: corpse_job_service.gd loaded")
	quit(0)
