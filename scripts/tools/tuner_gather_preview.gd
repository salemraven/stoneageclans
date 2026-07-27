extends RefCounted
class_name TunerGatherPreview

const GatherArmMotion = preload("res://scripts/systems/gather_arm_motion.gd")

var playing := false
var cycle_time := 0.0


func reset() -> void:
	cycle_time = 0.0


func set_playing(on: bool) -> void:
	playing = on
	if not playing:
		reset()


func tick(delta: float) -> void:
	if not playing:
		return
	cycle_time += delta


func cycle_phase() -> float:
	return GatherArmMotion.cycle_phase_from_time(cycle_time) if playing else 0.0
