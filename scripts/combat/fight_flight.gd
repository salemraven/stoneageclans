extends RefCounted

## Situational fight math for morale nudges only. Flight uses MoraleBar.

const MoraleBar = preload("res://scripts/combat/morale_bar.gd")
const CombatAllyCheck = preload("res://scripts/systems/combat_ally_check.gd")

const W_SELF := 2.0
const W_TARGET := 1.0
const W_MASS := 0.8
const W_COUNT := 0.6
const W_BUFF := 1.0
const COUNT_RADIUS := 380.0
const GUARD_ACQUIRE_RADIUS := 200.0

const SPECIES_MASS := {
	"caveman": 1.0,
	"clansman": 1.0,
	"woman": 1.0,
	"player": 1.0,
	"deer": 0.6,
	"sheep": 0.5,
	"goat": 0.5,
	"mammoth": 4.0,
}


static func ordered_mode(npc: Node) -> String:
	if npc == null or not bool(npc.get("follow_is_ordered")):
		return ""
	var ctx: Dictionary = npc.get("command_context") if npc.get("command_context") != null else {}
	return str(ctx.get("mode", "FOLLOW"))


static func is_woman(npc: Node) -> bool:
	return npc != null and str(npc.get("npc_type")) == "woman"


static func is_building(node: Node) -> bool:
	return node != null and node.is_in_group("buildings")


static func should_break(npc: Node, target: Node) -> bool:
	return MoraleBar.should_flight(npc, target)


static func leader_shock_active(npc: Node) -> bool:
	return MoraleBar.leader_shock_active(npc)


static func score(npc: Node, target: Node) -> float:
	var total := 0.0
	total += ( _hp_ratio(npc) - 1.0 ) * W_SELF
	total += ( 1.0 - _hp_ratio(target) ) * W_TARGET
	var self_mass := mass_of(npc)
	var foe_mass := mass_of(target)
	total += (self_mass - foe_mass) * W_MASS
	var counts := _headcount(npc)
	total += (float(counts.x) - float(counts.y)) * W_COUNT
	total += _combat_buff_push(npc)
	return total


static func mass_of(node: Node) -> float:
	if node == null or not is_instance_valid(node):
		return 1.0
	var kind := "player" if node.is_in_group("player") else str(node.get("npc_type"))
	var base: float = float(SPECIES_MASS.get(kind, 1.0))
	var scale := 1.0
	var profile: Variant = node.get("genetics_profile")
	if profile is Dictionary:
		var raw: Variant = (profile as Dictionary).get("body_scale", null)
		if raw is Vector2:
			var sc: Vector2 = raw
			scale = maxf(0.05, (absf(sc.x) + absf(sc.y)) * 0.5)
	return maxf(0.05, base * scale)


static func _hp_ratio(node: Node) -> float:
	if node == null or not is_instance_valid(node):
		return 1.0
	var hc: Node = node.get_node_or_null("HealthComponent")
	if hc == null:
		return 1.0
	var max_hp := float(hc.get("max_hp")) if hc.get("max_hp") != null else 0.0
	if max_hp <= 0.0:
		return 1.0
	return clampf(float(hc.get("current_hp")) / max_hp, 0.0, 1.0)


static func _headcount(npc: Node) -> Vector2:
	var allies := 0
	var enemies := 0
	if npc == null or not npc.is_inside_tree():
		return Vector2.ZERO
	var tree := npc.get_tree()
	var self_body := npc as Node2D
	if self_body == null:
		return Vector2.ZERO
	var nearby: Array = tree.get_nodes_in_group("npcs")
	nearby.append_array(tree.get_nodes_in_group("player"))
	for other in nearby:
		if other == null or other == npc or not is_instance_valid(other):
			continue
		var body := other as Node2D
		if body == null:
			continue
		if other.has_method("is_dead") and other.is_dead():
			continue
		var hc: Node = other.get_node_or_null("HealthComponent")
		if hc and bool(hc.get("is_dead")):
			continue
		if self_body.global_position.distance_to(body.global_position) > COUNT_RADIUS:
			continue
		if CombatAllyCheck.is_ally(npc, other):
			var fsm = other.get("fsm")
			var state_name := ""
			if fsm and fsm.has_method("get_current_state_name"):
				state_name = str(fsm.get_current_state_name())
			if state_name == "flee_combat":
				continue
			allies += 1
		else:
			enemies += 1
	return Vector2(allies, enemies)


static func _combat_buff_push(npc: Node) -> float:
	if npc == null:
		return 0.0
	var rows: Variant = npc.get("buffs_debuffs")
	if not (rows is Array):
		return 0.0
	var push := 0.0
	for row in rows:
		if not (row is Dictionary):
			continue
		var label := (str((row as Dictionary).get("stat", "")) + " " + str((row as Dictionary).get("name", ""))).to_lower()
		var counts_stat := label.contains("damage") or label.contains("armor") or label.contains("attack_speed") or label.contains("attack speed")
		if not counts_stat:
			continue
		var mult := float((row as Dictionary).get("mult", 1.0))
		push += (mult - 1.0) * W_BUFF
	return push
