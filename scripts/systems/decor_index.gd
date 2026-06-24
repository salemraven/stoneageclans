extends Node
## Spatial index for interactable decor (grass bug patches, future hidden loot).
## Mirrors ResourceIndex grid — O(cells) queries, not O(all decor).

const CELL_SIZE: float = 200.0
const KIND_GRASS_BUG := &"grass_bug"

var _entries: Array[Node2D] = []
var _grid: Dictionary = {}  # cell_key -> Array[Node2D]


func _cell_key(pos: Vector2) -> String:
	return "%d,%d" % [int(pos.x / CELL_SIZE), int(pos.y / CELL_SIZE)]


func register(node: Node2D) -> void:
	if node == null or node in _entries:
		return
	_entries.append(node)
	var key: String = _cell_key(node.global_position)
	if not _grid.has(key):
		_grid[key] = []
	(_grid[key] as Array).append(node)


func unregister(node: Node2D) -> void:
	if node == null:
		return
	_entries.erase(node)
	var key: String = _cell_key(node.global_position)
	if _grid.has(key):
		(_grid[key] as Array).erase(node)
		if (_grid[key] as Array).is_empty():
			_grid.erase(key)


func query_near(position: Vector2, radius: float, filters: Dictionary = {}) -> Array:
	var result: Array = []
	var min_cx: int = int((position.x - radius) / CELL_SIZE)
	var max_cx: int = int((position.x + radius) / CELL_SIZE)
	var min_cy: int = int((position.y - radius) / CELL_SIZE)
	var max_cy: int = int((position.y + radius) / CELL_SIZE)
	var want_kind: StringName = filters.get("kind", &"") as StringName
	var require_forageable: bool = bool(filters.get("forageable_only", false))
	for cx in range(min_cx, max_cx + 1):
		for cy in range(min_cy, max_cy + 1):
			var key: String = "%d,%d" % [cx, cy]
			if not _grid.has(key):
				continue
			for node in _grid[key] as Array:
				if not is_instance_valid(node):
					continue
				if want_kind != &"" and node.get("decor_kind") != want_kind:
					continue
				var dist: float = position.distance_to(node.global_position)
				if dist > radius:
					continue
				if require_forageable and node.has_method("is_forageable") and not node.is_forageable():
					continue
				result.append({"node": node, "distance": dist})
	result.sort_custom(func(a, b): return (a.distance as float) < (b.distance as float))
	return result


func query_nearest_node(position: Vector2, radius: float, filters: Dictionary = {}) -> Node2D:
	var pairs: Array = query_near(position, radius, filters)
	if pairs.is_empty():
		return null
	return pairs[0].node as Node2D


func deplete_bug_patches_in_radius(center: Vector2, radius: float) -> void:
	var pairs: Array = query_near(center, radius, {"kind": KIND_GRASS_BUG})
	for p in pairs:
		var node: Node2D = p.node as Node2D
		if not is_instance_valid(node):
			continue
		if node.has_method("force_deplete"):
			node.call("force_deplete")
