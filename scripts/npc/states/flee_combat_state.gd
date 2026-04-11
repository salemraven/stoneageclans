extends "res://scripts/npc/states/base_state.gd"

# Run away from combat — not toward land claim (steering flees from threat position).
# Entered from combat_state when _should_flee(); does not win FSM priority sweep (can_enter false).

const PerceptionArea = preload("res://scripts/npc/components/perception_area.gd")
const CombatAllyCheck = preload("res://scripts/systems/combat_ally_check.gd")

var _flee_from_position: Vector2 = Vector2.ZERO
var _flee_until_sec: float = 0.0
var _scatter_radians: float = 0.0

func enter() -> void:
	_cancel_tasks_if_active()
	if not npc:
		return
	var ct: Node2D = null
	if npc.has_method("resolve_combat_target"):
		ct = npc.resolve_combat_target() as Node2D
	if ct == null or not is_instance_valid(ct):
		ct = npc.get("combat_target") as Node2D
	if ct and is_instance_valid(ct):
		_flee_from_position = ct.global_position
	else:
		_flee_from_position = npc.global_position + Vector2(1, 0)
	var sc_deg: float = 30.0
	var dur: float = 5.0
	var spd: float = 1.4
	if NPCConfig:
		sc_deg = NPCConfig.flee_scatter_angle_deg
		dur = NPCConfig.flee_duration_seconds
		spd = NPCConfig.flee_speed_multiplier
	_scatter_radians = deg_to_rad(randf_range(-sc_deg, sc_deg))
	_flee_until_sec = Time.get_ticks_msec() / 1000.0 + dur
	# Drop combat and agro so we do not snap back immediately
	npc.set("combat_target_id", -1)
	npc.set("combat_target", null)
	if "combat_target_id" in npc:
		npc.combat_target_id = -1
	if "combat_target" in npc:
		npc.combat_target = null
	var ccmp: Node = npc.get_node_or_null("CombatComponent")
	if ccmp and ccmp.has_method("clear_target"):
		ccmp.clear_target()
	npc.set("agro_meter", 0.0)
	if "agro_meter" in npc:
		npc.agro_meter = 0.0
	if npc.steering_agent and npc.steering_agent.has_method("set_speed_multiplier"):
		npc.steering_agent.set_speed_multiplier(spd)
	if npc.steering_agent and npc.steering_agent.has_method("set_flee_target"):
		npc.steering_agent.set_flee_target(_flee_from_position)
	npc.set_meta("last_flee_combat_time", Time.get_ticks_msec() / 1000.0)

func exit() -> void:
	_cancel_tasks_if_active()
	if npc and npc.steering_agent and npc.steering_agent.has_method("restore_original_speed"):
		npc.steering_agent.restore_original_speed()

func update(delta: float) -> void:
	if not npc:
		return
	if npc.has_method("is_dead") and npc.is_dead():
		return
	var now: float = Time.get_ticks_msec() / 1000.0
	var away: Vector2 = (npc.global_position - _flee_from_position).normalized()
	if away.length_squared() < 0.01:
		away = Vector2.RIGHT.rotated(randf() * TAU)
	away = away.rotated(_scatter_radians)
	var bias: Vector2 = _bias_if_heading_into_enemy_claim(npc.global_position, away)
	away = (away + bias * 0.35).normalized()
	var run_to: Vector2 = npc.global_position + away * 420.0
	if npc.steering_agent:
		if npc.steering_agent.has_method("set_target_position"):
			npc.steering_agent.set_target_position(run_to)
		if npc.steering_agent.has_method("set_flee_target"):
			npc.steering_agent.set_flee_target(_flee_from_position)
	if now >= _flee_until_sec and fsm:
		fsm.change_state("wander")

func _bias_if_heading_into_enemy_claim(from: Vector2, flee_dir: Vector2) -> Vector2:
	var out: Vector2 = Vector2.ZERO
	if not npc:
		return out
	var my_clan: String = npc.get_clan_name() if npc.has_method("get_clan_name") else ""
	for claim in npc.get_tree().get_nodes_in_group("land_claims"):
		if not is_instance_valid(claim):
			continue
		var cc: String = str(claim.get("clan_name")) if claim.get("clan_name") != null else ""
		if cc == "" or cc == my_clan:
			continue
		var cp: Vector2 = claim.global_position
		var rad: float = float(claim.get("radius")) if claim.get("radius") != null else 400.0
		var next_pos: Vector2 = from + flee_dir * 80.0
		if next_pos.distance_to(cp) < rad:
			out += (next_pos - cp).normalized()
	return out

func can_enter() -> bool:
	return false

func get_priority() -> float:
	return 13.0

func get_data() -> Dictionary:
	return {"flee_until": _flee_until_sec}
