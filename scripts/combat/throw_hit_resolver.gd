extends RefCounted
class_name ThrowHitResolver

## Single source of truth for thrown-stone landing, snap, victim pick, and hit chance.
## Combat, projectile, AI, and tests must all call these helpers — no duplicate math.

const CombatAllyCheck = preload("res://scripts/systems/combat_ally_check.gd")
const CardRegistry = preload("res://scripts/config/placeholder_card_registry.gd")
const SimRngScript = preload("res://scripts/network/sim_rng.gd")

const FALLBACK_RANGE_PX := 420.0
const FALLBACK_HIT_RADIUS_PX := 48.0
const FALLBACK_SNAP_RADIUS_PX := 32.0
const FALLBACK_TORSO_FRAC := 0.35
const FALLBACK_DAMAGE := 6
const FALLBACK_FLIGHT_SEC := 0.55
const FALLBACK_ARC_HEIGHT_PX := 78.0


static func _balance() -> Node:
	var loop := Engine.get_main_loop()
	if loop is SceneTree:
		return (loop as SceneTree).root.get_node_or_null("/root/BalanceConfig")
	return null


const SPEAR_RANGE_PX := 640.0
const SPEAR_DAMAGE := 12


static func throw_range_px_for(item_type: ResourceData.ResourceType) -> float:
	if item_type == ResourceData.ResourceType.SPEAR:
		return SPEAR_RANGE_PX
	return throw_range_px()


static func throw_damage_for(item_type: ResourceData.ResourceType) -> int:
	if item_type == ResourceData.ResourceType.SPEAR:
		return SPEAR_DAMAGE
	return throw_damage()


static func leaves_ground_pickup(item_type: ResourceData.ResourceType) -> bool:
	return item_type != ResourceData.ResourceType.SPEAR


static func throw_range_px() -> float:
	var bc := _balance()
	if bc and bc.get("throw_range_px") != null:
		return maxf(1.0, float(bc.get("throw_range_px")))
	return FALLBACK_RANGE_PX


static func land_hit_radius_px() -> float:
	var bc := _balance()
	if bc and bc.get("throw_land_hit_radius_px") != null:
		return maxf(1.0, float(bc.get("throw_land_hit_radius_px")))
	return FALLBACK_HIT_RADIUS_PX


static func snap_radius_px() -> float:
	var bc := _balance()
	if bc and bc.get("throw_snap_radius_px") != null:
		return maxf(0.0, float(bc.get("throw_snap_radius_px")))
	return FALLBACK_SNAP_RADIUS_PX


static func torso_height_frac() -> float:
	var bc := _balance()
	if bc and bc.get("throw_torso_height_frac") != null:
		return clampf(float(bc.get("throw_torso_height_frac")), 0.0, 1.0)
	return FALLBACK_TORSO_FRAC


static func throw_damage() -> int:
	var bc := _balance()
	if bc and bc.get("throw_damage") != null:
		return maxi(1, int(bc.get("throw_damage")))
	return FALLBACK_DAMAGE


static func flight_sec() -> float:
	var bc := _balance()
	if bc and bc.get("throw_flight_sec") != null:
		return maxf(0.05, float(bc.get("throw_flight_sec")))
	return FALLBACK_FLIGHT_SEC


static func arc_height_px() -> float:
	var bc := _balance()
	if bc and bc.get("throw_arc_height_px") != null:
		return maxf(0.0, float(bc.get("throw_arc_height_px")))
	return FALLBACK_ARC_HEIGHT_PX


static func use_skill_hit_chance() -> bool:
	var bc := _balance()
	return bc != null and bool(bc.get("throw_use_skill_hit_chance"))


static func get_display_height(target: Node2D) -> float:
	if target == null:
		return CardRegistry.RUNTIME_MANNEQUIN_DISPLAY_HEIGHT
	var foot_y: Variant = target.get("_card_foot_y")
	if foot_y != null:
		return maxf(1.0, absf(float(foot_y)) * 2.0)
	return CardRegistry.RUNTIME_MANNEQUIN_DISPLAY_HEIGHT


static func get_hit_point(target: Node2D) -> Vector2:
	if target == null or not is_instance_valid(target):
		return Vector2.ZERO
	var height: float = get_display_height(target)
	return target.global_position + Vector2(0.0, -height * torso_height_frac())


static func clamp_land_to_range(origin: Vector2, desired: Vector2, range_px: float = -1.0) -> Vector2:
	var cap: float = throw_range_px() if range_px < 0.0 else range_px
	var delta: Vector2 = desired - origin
	var dist: float = delta.length()
	if dist <= cap or dist < 0.001:
		return desired
	return origin + delta * (cap / dist)


static func is_valid_throw_victim(thrower: Node, node: Node) -> bool:
	if thrower == null or node == null or not is_instance_valid(thrower) or not is_instance_valid(node):
		return false
	if node == thrower:
		return false
	if CombatAllyCheck.is_ally(thrower, node):
		return false
	if node.is_in_group("buildings"):
		if not node.has_method("take_damage"):
			return false
		if node.get("player_owned") == true and thrower.is_in_group("player"):
			return false
		var building_clan: String = str(node.get("clan_name")) if node.get("clan_name") != null else ""
		var attacker_clan: String = ""
		if thrower.has_method("get_clan_name"):
			attacker_clan = str(thrower.get_clan_name())
		elif thrower.get("clan_name") != null:
			attacker_clan = str(thrower.get("clan_name"))
		if building_clan != "" and attacker_clan != "" and building_clan == attacker_clan:
			return false
		return true
	var hc: Node = node.get_node_or_null("HealthComponent")
	if hc and hc.get("is_dead") == true:
		return false
	return node is Node2D and (node.is_in_group("npcs") or node.is_in_group("player"))


static func _collect_candidates(tree: SceneTree) -> Array:
	var out: Array = []
	if tree == null:
		return out
	out.append_array(tree.get_nodes_in_group("npcs"))
	out.append_array(tree.get_nodes_in_group("player"))
	out.append_array(tree.get_nodes_in_group("buildings"))
	return out


static func find_best_target_at_point(
	point: Vector2,
	radius_px: float,
	thrower: Node,
	tree: SceneTree
) -> Node2D:
	var best: Node2D = null
	var best_d: float = radius_px
	for n in _collect_candidates(tree):
		if not is_valid_throw_victim(thrower, n):
			continue
		if not (n is Node2D):
			continue
		var d: float = point.distance_to(get_hit_point(n as Node2D))
		if d <= best_d:
			best_d = d
			best = n as Node2D
	return best


static func snap_landing_if_target(
	cursor_world: Vector2,
	thrower: Node,
	tree: SceneTree
) -> Vector2:
	var snapped: Node2D = find_best_target_at_point(cursor_world, snap_radius_px(), thrower, tree)
	if snapped:
		return get_hit_point(snapped)
	return cursor_world


static func resolve_player_landing(thrower: Node2D, cursor_world: Vector2, tree: SceneTree, range_px: float = -1.0) -> Vector2:
	var snapped: Vector2 = snap_landing_if_target(cursor_world, thrower, tree)
	return clamp_land_to_range(thrower.global_position, snapped, range_px)


static func resolve_npc_landing(thrower: Node2D, combat_target: Node, aim: Vector2, range_px: float = -1.0) -> Vector2:
	var origin: Vector2 = thrower.global_position
	var cap: float = throw_range_px() if range_px < 0.0 else range_px
	var desired: Vector2
	if combat_target is Node2D and is_instance_valid(combat_target):
		desired = get_hit_point(combat_target as Node2D)
	else:
		var dir: Vector2 = aim if aim.length_squared() > 0.0001 else Vector2.RIGHT
		desired = origin + dir.normalized() * minf(80.0, cap)
	return clamp_land_to_range(origin, desired, cap)


static func compute_hit_chance(_thrower: Node) -> float:
	if not use_skill_hit_chance():
		return 1.0
	var bc := _balance()
	var base: float = 1.0
	if bc and bc.get("throw_base_hit_chance") != null:
		base = float(bc.get("throw_base_hit_chance"))
	return clampf(base, 0.0, 1.0)


static func roll_hit(thrower: Node, land: Vector2) -> bool:
	var chance: float = compute_hit_chance(thrower)
	if chance >= 1.0:
		return true
	if chance <= 0.0:
		return false
	var world_seed: int = 1
	var loop := Engine.get_main_loop()
	if loop is SceneTree:
		var sim: Node = (loop as SceneTree).root.get_node_or_null("/root/SimRng")
		if sim and sim.has_method("get_world_seed"):
			world_seed = int(sim.get_world_seed())
	var salt: int = hash(Vector3i(thrower.get_instance_id() if thrower else 0, int(land.x), int(land.y)))
	var rng := SimRngScript.make_scoped_rng(world_seed, salt)
	return rng.randf() < chance


static func is_online_client() -> bool:
	var loop := Engine.get_main_loop()
	if not (loop is SceneTree):
		return false
	var tree := loop as SceneTree
	var nm: Node = tree.root.get_node_or_null("/root/NetworkManager")
	if nm == null or not nm.has_method("get_network_peer"):
		return false
	if nm.get_network_peer() == null:
		return false
	return not tree.root.get_multiplayer().is_server()
