extends RefCounted
class_name TunerWindupIdlePreview

## Slow loop through rest → key A → key B → rest for club windup idle preview.

const DEFAULT_CYCLE_SEC := 5.0

var playing := false
var cycle_time := 0.0
var cycle_sec := DEFAULT_CYCLE_SEC


func reset() -> void:
	cycle_time = 0.0


func set_playing(on: bool) -> void:
	playing = on
	if not playing:
		reset()


func set_cycle_sec(sec: float) -> void:
	cycle_sec = maxf(sec, 0.5)


func tick(delta: float) -> void:
	if not playing:
		return
	cycle_time += delta


func cycle_phase() -> float:
	if not playing or cycle_sec <= 0.001:
		return 0.0
	return fposmod(cycle_time, cycle_sec) / cycle_sec
