extends RefCounted
class_name TunerGatherPreview

const GatherArmMotion = preload("res://scripts/systems/gather_arm_motion.gd")

var playing := false
var cycle_time := 0.0
var _pose_edit_active := false
var _pose_edit_pull := false


func reset() -> void:
	cycle_time = 0.0
	_pose_edit_active = false
	_pose_edit_pull = false


func set_playing(on: bool) -> void:
	playing = on
	if not playing:
		return
	_pose_edit_active = false
	_pose_edit_pull = false


func is_pose_edit_active() -> bool:
	return _pose_edit_active


func is_pose_edit_pull() -> bool:
	return _pose_edit_active and _pose_edit_pull


func set_pose_edit(active: bool, pull: bool = false) -> void:
	_pose_edit_active = active
	_pose_edit_pull = pull
	playing = false
	if active:
		cycle_time = GatherArmMotion.EDIT_HOLD_PHASE / GatherArmMotion.CYCLE_SPEED


func tick(delta: float) -> void:
	if not playing:
		return
	cycle_time += delta


func cycle_phase() -> float:
	return GatherArmMotion.cycle_phase_from_time(cycle_time) if playing else GatherArmMotion.EDIT_HOLD_PHASE
