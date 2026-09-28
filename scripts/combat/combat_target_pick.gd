extends RefCounted
class_name CombatTargetPick

## Pick the best enemy to fight: closest first, spread off targets allies already pile on.

const CombatAllyCheck = preload("res://scripts/systems/combat_ally_check.gd")

const SATURATION_RADIUS := 420.0
const ALLY_FOCUS_PENALTY_PX := 90.0


static func count_allies_focusing_on(asker: Node, foe: Node) -> int:
	if asker == null or foe == null or not is_instance_valid(asker) or not is_instance_valid(foe):
		return 0
	if not asker.is_inside_tree():
		return 0
	var tree := asker.get_tree()
	if tree == null:
		return 0
	var foe_id: int = foe.get_instance_id()
	var self_body := asker as Node2D
	if self_body == null:
		return 0
	var r2: float = SATURATION_RADIUS * SATURATION_RADIUS
	var n: int = 0
	for other in tree.get_nodes_in_group("npcs"):
		if other == asker or other == null or not is_instance_valid(other):
			continue
		if not CombatAllyCheck.is_ally(asker, other):
			continue
		var ob := other as Node2D
		if ob == null:
			continue
		if self_body.global_position.distance_squared_to(ob.global_position) > r2:
			continue
		var raw: Variant = other.get("combat_target")
		if raw == null or not is_instance_valid(raw):
			continue
		if (raw as Node).get_instance_id() == foe_id:
			n += 1
	var ply: Node = tree.get_first_node_in_group("player")
	if ply != null and is_instance_valid(ply) and CombatAllyCheck.is_ally(asker, ply):
		var pb := ply as Node2D
		if pb and self_body.global_position.distance_squared_to(pb.global_position) <= r2:
			var pr: Variant = ply.get("combat_target")
			if pr != null and is_instance_valid(pr) and (pr as Node).get_instance_id() == foe_id:
				n += 1
	return n


static func _score_enemy(origin: Vector2, asker: Node, enemy: Node) -> float:
	var dist: float = origin.distance_to((enemy as Node2D).global_position)
	var focus: int = count_allies_focusing_on(asker, enemy)
	return dist + float(focus) * ALLY_FOCUS_PENALTY_PX


static func pick_best_enemy(origin: Vector2, asker: Node, candidates: Array) -> Node:
	var best: Node = null
	var best_score: float = INF
	for enemy in candidates:
		if enemy == null or not is_instance_valid(enemy):
			continue
		if asker and CombatAllyCheck.is_ally(asker, enemy):
			continue
		var sc: float = _score_enemy(origin, asker, enemy)
		if sc < best_score:
			best_score = sc
			best = enemy
	return best


static func pick_from_perception(pa: PerceptionArea, origin: Vector2, npc: NPCBase) -> Node:
	if pa == null:
		return null
	var candidates: Array = pa.get_enemies_in_range(origin, pa.detection_range, npc)
	return pick_best_enemy(origin, npc, candidates)
