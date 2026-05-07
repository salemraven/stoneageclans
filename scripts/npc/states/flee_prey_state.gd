extends "res://scripts/npc/states/base_state.gd"

const SoundDetection = preload("res://scripts/systems/sound_detection.gd")

## Deer / prey flee — run from human centroid + loud sounds; short winded phase; optional cower when boxed in.

enum RunPhase { BURST, WINDED }


var _phase: RunPhase = RunPhase.BURST
var _phase_timer: float = 0.0
var _safe_timer: float = 0.0
var _panic_emitted: bool = false
var _stuck_timer: float = 0.0


func enter() -> void:
	_cancel_tasks_if_active()
	_phase = RunPhase.BURST
	_phase_timer = 0.0
	_safe_timer = 0.0
	_panic_emitted = false
	_stuck_timer = 0.0
	if npc:
		npc.remove_meta("deer_cower")
	if npc and npc.steering_agent and npc.steering_agent.has_method("restore_original_speed"):
		npc.steering_agent.restore_original_speed()
	if npc:
		npc.deer_fright_meter = 0.0
	if not _panic_emitted and npc:
		_panic_emitted = true
		SoundDetection.register_sound(npc.global_position, 95.0, &"deer_panic")


func exit() -> void:
	_cancel_tasks_if_active()
	if npc and npc.steering_agent and npc.steering_agent.has_method("restore_original_speed"):
		npc.steering_agent.restore_original_speed()


func _heard_spook() -> bool:
	if npc == null:
		return false
	var thr: float = NPCConfig.deer_sound_threshold if NPCConfig else 0.5
	return SoundDetection.heard_intensity_at(npc.global_position) > thr


func _threat_centroid() -> Vector2:
	var pa: PerceptionArea = npc.get_node_or_null("DetectionArea") as PerceptionArea if npc else null
	if pa == null:
		return Vector2.ZERO
	return pa.get_deer_threat_centroid(npc.global_position, pa.detection_range, npc)


func _apply_run_steering(away_from: Vector2) -> void:
	if npc == null or npc.steering_agent == null:
		return
	var dir: Vector2 = npc.global_position - away_from
	if dir.length_squared() < 2.0:
		dir = Vector2(1, 0).rotated(randf() * TAU)
	else:
		dir = dir.normalized()
	var goal: Vector2 = npc.global_position + dir * 480.0
	if npc.steering_agent.has_method("set_target_position_immediate"):
		npc.steering_agent.set_target_position_immediate(goal)


func update(delta: float) -> void:
	if npc == null or npc.is_dead():
		return
	var centroid: Vector2 = _threat_centroid()
	var spooked_sound: bool = _heard_spook()
	var threatened: bool = (centroid != Vector2.ZERO) or spooked_sound

	if not threatened:
		_safe_timer += delta
		if _safe_timer >= 3.0:
			if fsm:
				fsm.change_state("wander")
			return
	else:
		_safe_timer = 0.0

	match _phase:
		RunPhase.BURST:
			_phase_timer += delta
			var flee_cap: float = NPCConfig.deer_flee_duration_sec if NPCConfig else 10.0
			if centroid != Vector2.ZERO:
				_apply_run_steering(centroid)
			else:
				_apply_run_steering(npc.global_position + npc.velocity.normalized() * -1.0 if npc.velocity.length_squared() > 4.0 else Vector2(1, 0))

			if npc.velocity.length_squared() < 64.0:
				_stuck_timer += delta
			else:
				_stuck_timer = 0.0
			if _stuck_timer > 1.8:
				npc.set_meta("deer_cower", true)
				if npc.steering_agent:
					npc.steering_agent.set_wander(npc.global_position, 12.0)

			if _phase_timer >= flee_cap:
				_phase = RunPhase.WINDED
				_phase_timer = 0.0
				var wm: float = NPCConfig.deer_winded_speed_mult if NPCConfig else 0.6
				if npc.steering_agent and npc.steering_agent.has_method("set_speed_multiplier"):
					npc.steering_agent.set_speed_multiplier(wm)
		RunPhase.WINDED:
			_phase_timer += delta
			var wd: float = NPCConfig.deer_winded_duration_sec if NPCConfig else 3.0
			if centroid != Vector2.ZERO:
				_apply_run_steering(centroid)
			if _phase_timer >= wd:
				if npc.steering_agent and npc.steering_agent.has_method("restore_original_speed"):
					npc.steering_agent.restore_original_speed()
				_phase = RunPhase.BURST
				_phase_timer = 0.0


func can_enter() -> bool:
	if npc == null or npc.is_dead():
		return false
	if str(npc.get("npc_type")) != "deer":
		return false
	var centroid: Vector2 = _threat_centroid()
	var thr: float = NPCConfig.deer_sound_threshold if NPCConfig else 0.5
	var heard: bool = SoundDetection.heard_intensity_at(npc.global_position) > thr
	return centroid != Vector2.ZERO or heard


func get_priority() -> float:
	return 9.5


func get_data() -> Dictionary:
	return {"state": "flee_prey", "phase": _phase}
