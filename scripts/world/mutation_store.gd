extends Node
## Authoritative world deltas per chunk (depletions, clan deaths, grass clear zones) for streaming + MP/save.

const META_STABLE_ID := &"stable_id"
const META_CHUNK_COORDS := &"chunk_coords"


func chunk_key(c: Vector2i) -> String:
	return "%d,%d" % [c.x, c.y]


func get_chunk_record(chunk: Vector2i) -> Dictionary:
	var k := chunk_key(chunk)
	if not _chunks.has(k):
		_chunks[k] = _default_record()
	return _chunks[k]


func _default_record() -> Dictionary:
	return {"clan_deaths": 0, "depleted": [], "grass_clear_zones": []}


var _chunks: Dictionary = {}


func chunk_from_stable_id(stable_id: String) -> Vector2i:
	var parts: PackedStringArray = stable_id.split("_")
	if parts.size() < 2:
		return Vector2i.ZERO
	return Vector2i(int(parts[0]), int(parts[1]))


func is_depleted(stable_id: String) -> bool:
	if stable_id.is_empty():
		return false
	var chunk := chunk_from_stable_id(stable_id)
	var rec: Dictionary = get_chunk_record(chunk)
	var depleted: Array = rec.get("depleted", []) as Array
	return stable_id in depleted


func deplete_stable_id(stable_id: String) -> void:
	if stable_id.is_empty() or is_depleted(stable_id):
		return
	var chunk := chunk_from_stable_id(stable_id)
	var rec: Dictionary = get_chunk_record(chunk)
	var depleted: Array = rec.get("depleted", []) as Array
	if stable_id in depleted:
		return
	depleted.append(stable_id)
	rec["depleted"] = depleted
	_chunks[chunk_key(chunk)] = rec


func deplete_node_if_stable(node: Node) -> void:
	if node == null:
		return
	if not node.has_meta(META_STABLE_ID):
		return
	deplete_stable_id(str(node.get_meta(META_STABLE_ID)))


func add_grass_clear_zone(world_center: Vector2, radius: float) -> void:
	if radius <= 0.0:
		return
	var chunk := ChunkUtils.get_chunk_coords(world_center) if ChunkUtils else Vector2i.ZERO
	var rec: Dictionary = get_chunk_record(chunk)
	var zones: Array = rec.get("grass_clear_zones", []) as Array
	zones.append({"x": world_center.x, "y": world_center.y, "r": radius})
	rec["grass_clear_zones"] = zones
	_chunks[chunk_key(chunk)] = rec
	# Large radii can affect neighbor chunks — mirror zone on overlapping chunks.
	if ChunkUtils:
		var r_chunks: int = int(ceil(radius / ChunkUtils.CHUNK_SIZE)) + 1
		for dx in range(-r_chunks, r_chunks + 1):
			for dy in range(-r_chunks, r_chunks + 1):
				var c := chunk + Vector2i(dx, dy)
				if c == chunk:
					continue
				var center := Vector2(float(c.x), float(c.y)) * ChunkUtils.CHUNK_SIZE + Vector2(ChunkUtils.CHUNK_SIZE * 0.5, ChunkUtils.CHUNK_SIZE * 0.5)
				if center.distance_to(world_center) > radius + ChunkUtils.CHUNK_SIZE * 0.75:
					continue
				var rec2: Dictionary = get_chunk_record(c)
				var z2: Array = rec2.get("grass_clear_zones", []) as Array
				var entry := {"x": world_center.x, "y": world_center.y, "r": radius}
				if not _zone_list_has(z2, entry):
					z2.append(entry)
					rec2["grass_clear_zones"] = z2
					_chunks[chunk_key(c)] = rec2


func _zone_list_has(zones: Array, entry: Dictionary) -> bool:
	for z in zones:
		if typeof(z) != TYPE_DICTIONARY:
			continue
		if absf(float(z.get("x", 0)) - float(entry.get("x", 0))) < 0.5 \
				and absf(float(z.get("y", 0)) - float(entry.get("y", 0))) < 0.5 \
				and absf(float(z.get("r", 0)) - float(entry.get("r", 0))) < 0.5:
			return true
	return false


func is_position_grass_cleared(world_pos: Vector2) -> bool:
	var chunk := ChunkUtils.get_chunk_coords(world_pos) if ChunkUtils else Vector2i.ZERO
	var rec: Dictionary = get_chunk_record(chunk)
	for z in rec.get("grass_clear_zones", []) as Array:
		if typeof(z) != TYPE_DICTIONARY:
			continue
		var c := Vector2(float(z.get("x", 0)), float(z.get("y", 0)))
		if world_pos.distance_to(c) <= float(z.get("r", 0)):
			return true
	return false


func deplete_in_radius(world_center: Vector2, radius: float) -> void:
	add_grass_clear_zone(world_center, radius)
	var decor: Node = get_node_or_null("/root/DecorIndex")
	if decor and decor.has_method("deplete_bug_patches_in_radius"):
		decor.call("deplete_bug_patches_in_radius", world_center, radius)


func get_clan_deaths_in_chunk(chunk: Vector2i) -> int:
	return int(get_chunk_record(chunk).get("clan_deaths", 0))


func record_clan_death(chunk: Vector2i) -> void:
	var rec := get_chunk_record(chunk)
	rec["clan_deaths"] = int(rec.get("clan_deaths", 0)) + 1
	_chunks[chunk_key(chunk)] = rec


func record_clan_death_at_world_pos(world_pos: Vector2) -> void:
	if ChunkUtils == null:
		return
	record_clan_death(ChunkUtils.get_chunk_coords(world_pos))


func reset_chunk(chunk: Vector2i) -> void:
	_chunks.erase(chunk_key(chunk))


func to_dict() -> Dictionary:
	return _chunks.duplicate(true)


func load_from_dict(data: Dictionary) -> void:
	_chunks = data.duplicate(true)
