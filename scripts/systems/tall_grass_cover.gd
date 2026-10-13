extends Node
## Spatial index of tall-grass blade positions (from GrassBatch). Used for crouch-hide cover.

const CELL_SIZE: float = 64.0
const DEFAULT_COVER_RADIUS: float = 34.0

var _grid: Dictionary = {}  # "cx,cy" -> Array[Vector2]
var _chunk_keys: Dictionary = {}  # Vector2i chunk -> Array[String] cell keys touched


func register_chunk_blades(chunk: Vector2i, points: Array) -> void:
	clear_chunk(chunk)
	if points.is_empty():
		return
	var keys: Array[String] = []
	for pt in points:
		if typeof(pt) != TYPE_DICTIONARY:
			continue
		var pos: Vector2 = pt.get("position", Vector2.ZERO) as Vector2
		if MutationStore and MutationStore.is_position_grass_cleared(pos):
			continue
		_add_blade(pos, keys)
	_chunk_keys[chunk] = keys


func clear_chunk(chunk: Vector2i) -> void:
	if not _chunk_keys.has(chunk):
		return
	for key: String in _chunk_keys[chunk] as Array:
		if _grid.has(key):
			_grid.erase(key)
	_chunk_keys.erase(chunk)


func covers_position(world_pos: Vector2, radius: float = DEFAULT_COVER_RADIUS) -> bool:
	if radius <= 0.0:
		radius = DEFAULT_COVER_RADIUS
	var r2: float = radius * radius
	var min_cx: int = int(floor((world_pos.x - radius) / CELL_SIZE))
	var max_cx: int = int(floor((world_pos.x + radius) / CELL_SIZE))
	var min_cy: int = int(floor((world_pos.y - radius) / CELL_SIZE))
	var max_cy: int = int(floor((world_pos.y + radius) / CELL_SIZE))
	for cx in range(min_cx, max_cx + 1):
		for cy in range(min_cy, max_cy + 1):
			var key: String = "%d,%d" % [cx, cy]
			if not _grid.has(key):
				continue
			for blade: Vector2 in _grid[key] as Array:
				if world_pos.distance_squared_to(blade) <= r2:
					return true
	return false


func _add_blade(pos: Vector2, chunk_keys_out: Array[String]) -> void:
	var key: String = _cell_key(pos)
	if not _grid.has(key):
		_grid[key] = [] as Array
	(_grid[key] as Array).append(pos)
	if key not in chunk_keys_out:
		chunk_keys_out.append(key)


func _cell_key(pos: Vector2) -> String:
	return "%d,%d" % [int(floor(pos.x / CELL_SIZE)), int(floor(pos.y / CELL_SIZE))]
