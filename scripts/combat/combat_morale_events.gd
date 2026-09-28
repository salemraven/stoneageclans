extends RefCounted
class_name CombatMoraleEvents

## Kill and death bumps on the fight/flight score (not the future 0–100 bar).

const CombatAllyCheck = preload("res://scripts/systems/combat_ally_check.gd")

const KILL_BOOST_SELF := 0.35
const KILL_BOOST_NEARBY := 0.15
const DEATH_PENALTY_NEARBY := -0.28
const SPREAD_RADIUS := 560.0
const BIAS_CAP := 2.5


static func apply_person_kill(killer: Node, _victim: Node) -> void:
	if killer == null or not is_instance_valid(killer):
		return
	_add_bias(killer, KILL_BOOST_SELF)
	_spread_to_clan(killer, KILL_BOOST_NEARBY, killer)


static func apply_clan_man_death(dead: Node) -> void:
	if dead == null or not is_instance_valid(dead):
		return
	var clan: String = str(dead.get("clan_name")) if dead.get("clan_name") != null else ""
	if clan == "":
		return
	var tree: SceneTree = dead.get_tree()
	if tree == null:
		return
	var origin: Vector2 = (dead as Node2D).global_position if dead is Node2D else Vector2.ZERO
	var r2: float = SPREAD_RADIUS * SPREAD_RADIUS
	for n in tree.get_nodes_in_group("npcs"):
		if n == null or not is_instance_valid(n) or n == dead:
			continue
		if str(n.get("npc_type")) not in ["caveman", "clansman"]:
			continue
		if str(n.get("clan_name")) != clan:
			continue
		if n.has_method("is_dead") and n.is_dead():
			continue
		if n is Node2D and origin.distance_squared_to((n as Node2D).global_position) > r2:
			continue
		_add_bias(n, DEATH_PENALTY_NEARBY)


static func _spread_to_clan(source: Node, amount: float, skip: Node) -> void:
	var clan: String = ""
	if source.has_method("get_clan_name"):
		clan = str(source.get_clan_name())
	elif source.get("clan_name") != null:
		clan = str(source.get("clan_name"))
	if clan == "" or not source.is_inside_tree():
		return
	var tree: SceneTree = source.get_tree()
	var origin: Vector2 = (source as Node2D).global_position if source is Node2D else Vector2.ZERO
	var r2: float = SPREAD_RADIUS * SPREAD_RADIUS
	for n in tree.get_nodes_in_group("npcs"):
		if n == null or not is_instance_valid(n) or n == skip:
			continue
		if str(n.get("npc_type")) not in ["caveman", "clansman"]:
			continue
		if str(n.get("clan_name")) != clan:
			continue
		if n.has_method("is_dead") and n.is_dead():
			continue
		if n is Node2D and origin.distance_squared_to((n as Node2D).global_position) > r2:
			continue
		_add_bias(n, amount)


static func _add_bias(n: Node, delta: float) -> void:
	if n == null:
		return
	var cur: float = float(n.get_meta("combat_morale_bias", 0.0))
	cur = clampf(cur + delta, -BIAS_CAP, BIAS_CAP)
	n.set_meta("combat_morale_bias", cur)


static func bias_of(npc: Node) -> float:
	if npc == null or not npc.has_meta("combat_morale_bias"):
		return 0.0
	return float(npc.get_meta("combat_morale_bias", 0.0))


static func tick_decay(npc: Node, delta: float) -> void:
	if npc == null or not npc.has_meta("combat_morale_bias"):
		return
	var cur: float = float(npc.get_meta("combat_morale_bias", 0.0))
	if absf(cur) < 0.02:
		npc.remove_meta("combat_morale_bias")
		return
	var step: float = 0.45 * delta
	if cur > 0.0:
		cur = maxf(0.0, cur - step)
	else:
		cur = minf(0.0, cur + step)
	if absf(cur) < 0.02:
		npc.remove_meta("combat_morale_bias")
	else:
		npc.set_meta("combat_morale_bias", cur)
