extends Node
# ResourceIndex - Centralized resource lookup for gather system
# Phase 4: Spatial grid for O(cells) queries instead of O(all resources)
# Replaces get_nodes_in_group("resources") for performance and multiplayer readiness

var _resources: Array[Node2D] = []  # Keep for unregister lookup
var _grid: Dictionary = {}  # cell_key -> Array[Node2D]
const CELL_SIZE: float = 200.0


func _cell_key(pos: Vector2) -> String:
	return "%d,%d" % [int(pos.x / CELL_SIZE), int(pos.y / CELL_SIZE)]


# Static helper: is position inside an enemy land claim (for given clan)?
# Pass pre-fetched land_claims (e.g. main.get_cached_land_claims()) to avoid group query.
static func is_position_in_enemy_claim(land_claims: Array, position: Vector2, my_clan: String) -> bool:
	if my_clan == "":
		return false
	for claim in land_claims:
		if not is_instance_valid(claim):
			continue
		var claim_clan: String = claim.get("clan_name") as String if claim.get("clan_name") != null else ""
		if claim_clan == "" or claim_clan == my_clan:
			continue
		var claim_pos: Vector2 = claim.global_position
		var claim_radius: float = claim.get("radius") as float if claim.get("radius") != null else 400.0
		if position.distance_to(claim_pos) <= claim_radius:
			return true
	return false


func register(resource: Node2D) -> void:
	if not resource or resource in _resources:
		return
	_resources.append(resource)
	var key: String = _cell_key(resource.global_position)
	if not _grid.has(key):
		_grid[key] = []
	_grid[key].append(resource)


func unregister(resource: Node2D) -> void:
	if not resource:
		return
	_resources.erase(resource)
	var key: String = _cell_key(resource.global_position)
	if _grid.has(key):
		_grid[key].erase(resource)
		if _grid[key].is_empty():
			_grid.erase(key)


# filters: exclude_enemy_claim (bool), clan_name (String for territory check), exclude_cooldown (bool), exclude_no_capacity (bool), resource_type (optional int)
# exclude_position_enemy_claim: pass a callable(position)->bool or null; if set, used for territory
func query_near(position: Vector2, radius: float, filters: Dictionary = {}) -> Array:
	var result: Array = []
	var min_cx: int = int((position.x - radius) / CELL_SIZE)
	var max_cx: int = int((position.x + radius) / CELL_SIZE)
	var min_cy: int = int((position.y - radius) / CELL_SIZE)
	var max_cy: int = int((position.y + radius) / CELL_SIZE)
	for cx in range(min_cx, max_cx + 1):
		for cy in range(min_cy, max_cy + 1):
			var key: String = "%d,%d" % [cx, cy]
			if not _grid.has(key):
				continue
			for res in _grid[key]:
				if not is_instance_valid(res):
					continue
				var dist: float = position.distance_to(res.global_position)
				if dist > radius:
					continue
				if filters.get("exclude_cooldown", true) and res.has_method("is_in_cooldown_state") and res.is_in_cooldown_state():
					continue
				if filters.get("exclude_no_capacity", true) and res.has_method("has_capacity") and not res.has_capacity():
					continue
				if filters.has("resource_type"):
					var rt = res.get("resource_type")
					if rt == null:
						rt = res.get("item_type")
					if rt != filters.resource_type:
						continue
				var exclude_enemy: Variant = filters.get("exclude_position_enemy_claim", null)
				if exclude_enemy != null and exclude_enemy is Callable:
					if exclude_enemy.call(res.global_position):
						continue
				if filters.get("exclude_empty", true):
					if res.has_method("is_harvestable_ignore_lock") and not res.is_harvestable_ignore_lock():
						continue
					elif res.has_method("is_harvestable") and not res.is_harvestable():
						continue
				result.append({ "node": res, "distance": dist })
	# Sort by distance
	result.sort_custom(func(a, b): return a.distance < b.distance)
	return result


# Convenience: return just the nodes, sorted by distance
func query_near_nodes(position: Vector2, radius: float, filters: Dictionary = {}) -> Array:
	var pairs: Array = query_near(position, radius, filters)
	var nodes: Array = []
	for p in pairs:
		nodes.append(p.node)
	return nodes
