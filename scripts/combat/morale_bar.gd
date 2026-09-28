extends RefCounted
class_name MoraleBar

## One 0–100 bar. Flight when bar is below the personal flight line (default 50, bravery shifts it).

const FightFlight = preload("res://scripts/combat/fight_flight.gd")
const CombatAllyCheck = preload("res://scripts/systems/combat_ally_check.gd")

const DEFAULT_BAR := 50.0
const DRIFT_TO := 50.0
const DRIFT_SPEED := 4.0
const KILL_SELF := 12.0
const KILL_NEARBY := 5.0
const DEATH_NEARBY := -14.0
const ALLY_FLIGHT_NEARBY := -6.0
const LEADER_DEATH_CLAN := -18.0
const LEADER_SHOCK_SEC := 8.0
const SPREAD_RADIUS := 560.0
const NUDGE_INTERVAL := 1.0
const NUDGE_MAX := 8.0
const RAID_FLIGHT_LINE_OFFSET := -36.0
const META_BAR := "morale_bar_value"
const META_LOG_SIG := "morale_log_sig"


static func is_fighter(npc: Node) -> bool:
	if npc == null:
		return false
	var nt: String = str(npc.get("npc_type")) if npc.get("npc_type") != null else ""
	if nt == "woman":
		return false
	return nt == "caveman" or nt == "clansman" or npc.is_in_group("player")


static func current(npc: Node) -> float:
	if npc == null:
		return DEFAULT_BAR
	if npc.get("morale_bar") != null:
		return clampf(float(npc.get("morale_bar")), 0.0, 100.0)
	if npc.has_meta(META_BAR):
		return clampf(float(npc.get_meta(META_BAR)), 0.0, 100.0)
	return DEFAULT_BAR


static func _set_bar(npc: Node, value: float) -> void:
	var v: float = clampf(value, 0.0, 100.0)
	npc.set_meta(META_BAR, v)
	if "morale_bar" in npc:
		npc.set("morale_bar", v)


static func flight_line(npc: Node) -> float:
	var line: float = DEFAULT_BAR
	var b: float = 0.5
	if NPCConfig and NPCConfig.get("flee_default_bravery") != null:
		b = float(NPCConfig.flee_default_bravery)
	var bvar: Variant = npc.get("bravery") if npc else null
	if bvar != null and float(bvar) >= 0.0:
		b = clampf(float(bvar), 0.0, 1.0)
	line = DEFAULT_BAR - (b - 0.5) * 30.0
	if npc and npc.has_meta("flight_line_offset"):
		line += float(npc.get_meta("flight_line_offset", 0.0))
	return clampf(line, 15.0, 85.0)


static func should_flight(npc: Node, target: Node) -> bool:
	if FightFlight.is_woman(npc):
		return true
	if target == null or not is_instance_valid(target) or FightFlight.is_building(target):
		return false
	if target.has_method("is_dead") and target.is_dead():
		return false
	var foe_hp: Node = target.get_node_or_null("HealthComponent")
	if foe_hp and bool(foe_hp.get("is_dead")):
		return false
	if not is_fighter(npc):
		return false
	return current(npc) < flight_line(npc)


static func _log_swing(npc: Node, why: String) -> void:
	if npc == null:
		return
	var bar: float = current(npc)
	var line: float = flight_line(npc)
	var sig: String = "%s|%.0f|%.0f|%s" % [str(npc.get("npc_name")), bar, line, why]
	if str(npc.get_meta(META_LOG_SIG, "")) == sig:
		return
	npc.set_meta(META_LOG_SIG, sig)
	var name_s: String = str(npc.get("npc_name")) if npc.get("npc_name") != null else "?"
	print("NPC_MORALE name=%s bar=%.0f line=%.0f why=%s" % [name_s, bar, line, why])


static func _apply_delta(npc: Node, delta: float, why: String) -> void:
	if npc == null or not is_instance_valid(npc) or not is_fighter(npc):
		return
	_set_bar(npc, current(npc) + delta)
	_log_swing(npc, why)


static func _is_person(node: Node) -> bool:
	if node == null or not is_instance_valid(node):
		return false
	if node.is_in_group("player"):
		return true
	var nt: String = str(node.get("npc_type")) if node.get("npc_type") != null else ""
	return nt == "caveman" or nt == "clansman"


static func apply_person_kill(killer: Node, victim: Node) -> void:
	if killer == null or not _is_person(victim):
		return
	if not is_fighter(killer):
		return
	_apply_delta(killer, KILL_SELF, "kill")
	_spread_clan(killer, KILL_NEARBY, killer, "kill")


static func apply_clan_man_death(dead: Node, skip_nearby_because_leader: bool) -> void:
	if dead == null or not _is_person(dead) or skip_nearby_because_leader:
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
		if not is_fighter(n):
			continue
		if str(n.get("clan_name")) != clan:
			continue
		if n.has_method("is_dead") and n.is_dead():
			continue
		if n is Node2D and origin.distance_squared_to((n as Node2D).global_position) > r2:
			continue
		_apply_delta(n, DEATH_NEARBY, "death")


static func apply_leader_death_clan(clan_name: String, tree: SceneTree, dead_leader_name: String) -> void:
	if clan_name == "" or tree == null:
		return
	for n in tree.get_nodes_in_group("npcs"):
		if n == null or not is_instance_valid(n):
			continue
		if not is_fighter(n):
			continue
		var nc: String = str(n.get("clan_name")) if n.get("clan_name") != null else ""
		if nc != clan_name:
			continue
		if n.has_method("is_dead") and n.is_dead():
			continue
		_apply_delta(n, LEADER_DEATH_CLAN, "leader")
	print("NPC_MORALE_LEADER clan=%s dead=%s drop=%.0f" % [clan_name, dead_leader_name, LEADER_DEATH_CLAN])


static func apply_ally_entered_flight(router: Node) -> void:
	if router == null or not is_instance_valid(router):
		return
	var clan: String = str(router.get("clan_name")) if router.get("clan_name") != null else ""
	if clan == "" or not router.is_inside_tree():
		return
	var tree: SceneTree = router.get_tree()
	var origin: Vector2 = (router as Node2D).global_position if router is Node2D else Vector2.ZERO
	var r2: float = SPREAD_RADIUS * SPREAD_RADIUS
	for n in tree.get_nodes_in_group("npcs"):
		if n == router or n == null or not is_instance_valid(n):
			continue
		if not is_fighter(n):
			continue
		if str(n.get("clan_name")) != clan:
			continue
		if n is Node2D and origin.distance_squared_to((n as Node2D).global_position) > r2:
			continue
		_apply_delta(n, ALLY_FLIGHT_NEARBY, "ally_flight")


static func _spread_clan(source: Node, amount: float, skip: Node, why: String) -> void:
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
		if not is_fighter(n):
			continue
		if str(n.get("clan_name")) != clan:
			continue
		if n is Node2D and origin.distance_squared_to((n as Node2D).global_position) > r2:
			continue
		_apply_delta(n, amount, why)


static func leader_shock_active(npc: Node) -> bool:
	if npc == null or not npc.has_meta("leader_shock_until"):
		return false
	return Time.get_ticks_msec() / 1000.0 <= float(npc.get_meta("leader_shock_until", 0.0))


static func apply_leader_shock_timer(clan_name: String, tree: SceneTree) -> void:
	if clan_name == "" or tree == null:
		return
	var until: float = Time.get_ticks_msec() / 1000.0 + LEADER_SHOCK_SEC
	for n in tree.get_nodes_in_group("npcs"):
		if n == null or not is_instance_valid(n):
			continue
		if not is_fighter(n):
			continue
		if str(n.get("clan_name")) != clan_name:
			continue
		n.set_meta("leader_shock_until", until)


static func tick_drift(npc: Node, delta: float) -> void:
	if npc == null or not is_fighter(npc):
		return
	var fsm: Node = npc.get("fsm") as Node
	if fsm and fsm.has_method("get_current_state_name"):
		var st: String = str(fsm.get_current_state_name())
		if st == "combat" or st == "flee_combat":
			return
	var bar: float = current(npc)
	if absf(bar - DRIFT_TO) < 0.5:
		_set_bar(npc, DRIFT_TO)
		return
	var step: float = DRIFT_SPEED * delta
	if bar > DRIFT_TO:
		_set_bar(npc, maxf(DRIFT_TO, bar - step))
	else:
		_set_bar(npc, minf(DRIFT_TO, bar + step))


static func tick_combat_nudge(npc: Node, target: Node, delta: float) -> void:
	if npc == null or not is_fighter(npc) or target == null or not is_instance_valid(target):
		return
	if not _is_person(target):
		return
	var acc: float = float(npc.get_meta("morale_nudge_acc", 0.0)) + delta
	if acc < NUDGE_INTERVAL:
		npc.set_meta("morale_nudge_acc", acc)
		return
	npc.set_meta("morale_nudge_acc", 0.0)
	var situational: float = FightFlight.score(npc, target)
	var delta_bar: float = clampf(situational * 2.5, -NUDGE_MAX, NUDGE_MAX)
	if absf(delta_bar) < 0.5:
		return
	if delta_bar < 0.0 and bool(npc.get_meta("raid_joined", false)):
		return
	_apply_delta(npc, delta_bar, "nudge")


static func log_flight_start(npc: Node) -> void:
	if npc == null:
		return
	var name_s: String = str(npc.get("npc_name")) if npc.get("npc_name") != null else "?"
	print("NPC_FLIGHT name=%s bar=%.0f line=%.0f" % [name_s, current(npc), flight_line(npc)])
