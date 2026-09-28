extends "res://scripts/npc/states/base_state.gd"

# Run away from combat on the immediate walk. The 200px steering flee is not used here.
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
	var saved_from: Variant = npc.get_meta("flee_from_position", null) if npc.has_meta("flee_from_position") else null
	var nearest_hostile: Vector2 = _nearest_hostile_position()
	if saved_from is Vector2:
		_flee_from_position = saved_from
		npc.remove_meta("flee_from_position")
	elif ct and is_instance_valid(ct):
		_flee_from_position = ct.global_position
	elif nearest_hostile != Vector2.INF:
		_flee_from_position = nearest_hostile
	else:
		_flee_from_position = npc.global_position + Vector2(1, 0)
	var sc_deg: float = 30.0
	var dur: float = 5.0
	var spd: float = 1.4
	if NPCConfig:
		sc_deg = NPCConfig.flee_scatter_angle_deg
		dur = NPCConfig.flee_duration_seconds
		spd = NPCConfig.flee_speed_multiplier
	_scatter_radians = deg_to_rad(_npc_rngf_range(-sc_deg, sc_deg))
	_flee_until_sec = Time.get_ticks_msec() / 1000.0 + dur
	npc.set_meta("flee_until_sec", _flee_until_sec)
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
	if LagProfiler and LagProfiler.is_enabled():
		LagProfiler.record_gameplay("agro_clears")
	if npc.steering_agent and npc.steering_agent.has_method("set_speed_multiplier"):
		npc.steering_agent.set_speed_multiplier(spd)
	npc.set_meta("flee_origin", npc.global_position)
	npc.remove_meta("flee_moved_logged")
	_commit_flee_walk()
	npc.set_meta("last_flee_combat_time", Time.get_ticks_msec() / 1000.0)
	if npc.has_method("show_rout_flash"):
		npc.show_rout_flash()
	const MoraleBarScript = preload("res://scripts/combat/morale_bar.gd")
	if MoraleBarScript.is_fighter(npc):
		MoraleBarScript.log_flight_start(npc)
	var from_dist: float = npc.global_position.distance_to(_flee_from_position)
	print("NPC_FLEE name=%s dist=%.0f" % [str(npc.get("npc_name")), from_dist])

func exit() -> void:
	_cancel_tasks_if_active()
	if npc and npc.has_meta("flee_until_sec"):
		npc.remove_meta("flee_until_sec")
	if npc and npc.has_method("hide_rout_flash"):
		npc.hide_rout_flash()
	if npc and npc.steering_agent and npc.steering_agent.has_method("restore_original_speed"):
		npc.steering_agent.restore_original_speed()

func update(delta: float) -> void:
	if not npc:
		return
	if npc.has_method("is_dead") and npc.is_dead():
		return
	if panic_can_end():
		print("NPC_HOME name=%s" % str(npc.get("npc_name")))
		if fsm:
			fsm.change_state("wander")
		return
	var now: float = Time.get_ticks_msec() / 1000.0
	if now >= _flee_until_sec and fsm:
		fsm.change_state("wander")
		return
	_commit_flee_walk()
	_note_flee_moved()


func _commit_flee_walk() -> void:
	if npc == null or npc.steering_agent == null:
		return
	var dest: Vector2
	if str(npc.get("npc_type")) == "woman":
		var shelter: Vector2 = _woman_shelter_position()
		if shelter == Vector2.INF:
			dest = _run_away_point()
		else:
			dest = shelter
	elif _is_man() and not _last_resort() and _own_claim() != null:
		dest = _own_claim().global_position
	else:
		dest = _run_away_point()
	if npc.steering_agent.has_method("retarget_seek"):
		npc.steering_agent.retarget_seek(dest)
	elif npc.steering_agent.has_method("set_target_position_immediate"):
		npc.steering_agent.set_target_position_immediate(dest)
	elif npc.steering_agent.has_method("set_target_position"):
		npc.steering_agent.set_target_position(dest)


func _nearest_hostile_position() -> Vector2:
	if npc == null or not npc.is_inside_tree():
		return Vector2.INF
	var my_clan: String = npc.get_clan_name() if npc.has_method("get_clan_name") else ""
	var best := Vector2.INF
	var best_d := INF
	var bodies: Array = npc.get_tree().get_nodes_in_group("npcs")
	for body in bodies:
		if body == npc or not is_instance_valid(body) or not (body is Node2D):
			continue
		if body.has_method("is_dead") and body.is_dead():
			continue
		var hp: Node = body.get_node_or_null("HealthComponent")
		if hp and bool(hp.get("is_dead")):
			continue
		var kind: String = str(body.get("npc_type")) if body.get("npc_type") != null else ""
		var person: bool = body.is_in_group("player") or kind == "caveman" or kind == "clansman" or kind == "woman"
		if not person:
			continue
		var their_clan: String = body.get_clan_name() if body.has_method("get_clan_name") else ""
		if my_clan != "" and their_clan == my_clan:
			continue
		var d: float = npc.global_position.distance_squared_to((body as Node2D).global_position)
		if d < best_d:
			best_d = d
			best = (body as Node2D).global_position
	return best


func _run_away_point() -> Vector2:
	var away: Vector2 = (npc.global_position - _flee_from_position)
	if away.length_squared() < 0.01:
		away = Vector2.RIGHT.rotated(_npc_rngf() * TAU)
	else:
		away = away.normalized()
	away = away.rotated(_scatter_radians)
	var bias: Vector2 = _bias_if_heading_into_enemy_claim(npc.global_position, away)
	away = (away + bias * 0.35).normalized()
	if away.length_squared() < 0.01:
		away = Vector2.RIGHT
	return npc.global_position + away * 420.0


func _note_flee_moved() -> void:
	if npc == null or npc.has_meta("flee_moved_logged"):
		return
	var origin: Variant = npc.get_meta("flee_origin", npc.global_position)
	if not (origin is Vector2):
		return
	var moved: float = npc.global_position.distance_to(origin as Vector2)
	if moved < 80.0:
		return
	npc.set_meta("flee_moved_logged", true)
	print("NPC_FLEE_MOVED name=%s dist=%.0f" % [str(npc.get("npc_name")), moved])

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

func _woman_shelter_position() -> Vector2:
	if not npc or not npc.is_inside_tree():
		return Vector2.INF
	var clan: String = npc.get_clan_name() if npc.has_method("get_clan_name") else ""
	if clan == "":
		return Vector2.INF
	var best := Vector2.INF
	var best_d := INF
	for node in npc.get_tree().get_nodes_in_group("campfires"):
		if not is_instance_valid(node) or not (node is Node2D):
			continue
		if clan != "" and str(node.get("clan_name")) != clan:
			continue
		var d: float = npc.global_position.distance_squared_to((node as Node2D).global_position)
		if d < best_d:
			best_d = d
			best = (node as Node2D).global_position
	for node in npc.get_tree().get_nodes_in_group("buildings"):
		if not is_instance_valid(node) or not (node is Node2D):
			continue
		if clan != "" and str(node.get("clan_name")) != clan:
			continue
		var d2: float = npc.global_position.distance_squared_to((node as Node2D).global_position)
		if d2 < best_d:
			best_d = d2
			best = (node as Node2D).global_position
	return best


func village_holds() -> bool:
	## The claim's one answer. True when this man should turn and fight the intruder.
	var claim: Node2D = _own_claim()
	if claim == null or not claim.has_method("village_target") or npc == null:
		return false
	var intruder: Variant = claim.village_target(npc)
	return intruder != null and is_instance_valid(intruder)


func panic_can_end() -> bool:
	## Reaching home ends the run. A called man turns and fights. Last resort keeps running out.
	if not _inside_own_claim():
		return false
	if village_holds():
		return false
	var claim: Node2D = _own_claim()
	if _last_resort() and claim != null and claim.has_method("has_village_intruder") and bool(claim.has_village_intruder()):
		return false
	return true


func _is_man() -> bool:
	if npc == null:
		return false
	var kind: String = str(npc.get("npc_type")) if npc.get("npc_type") != null else ""
	return kind == "caveman" or kind == "clansman"


func _last_resort() -> bool:
	if npc == null:
		return false
	var hp: Node = npc.get_node_or_null("HealthComponent")
	if hp == null:
		return false
	var max_hp: int = int(hp.get("max_hp"))
	var cur: int = int(hp.get("current_hp"))
	if max_hp <= 0:
		return false
	return cur <= maxi(1, max_hp / 3)


func _own_claim() -> Node2D:
	if npc == null or not npc.has_method("get_my_land_claim"):
		return null
	var claim: Node = npc.get_my_land_claim()
	if claim == null or not is_instance_valid(claim) or not (claim is Node2D):
		return null
	return claim as Node2D


func _inside_own_claim() -> bool:
	var claim: Node2D = _own_claim()
	if claim == null or npc == null:
		return false
	var radius: float = 400.0
	var rp: Variant = claim.get("radius")
	if rp != null:
		radius = float(rp)
	return npc.global_position.distance_to(claim.global_position) < radius


func can_enter() -> bool:
	return false

func get_priority() -> float:
	if NPCConfig:
		return NPCConfig.priority_flee_combat
	return 13.0

func get_data() -> Dictionary:
	return {"flee_until": _flee_until_sec}
