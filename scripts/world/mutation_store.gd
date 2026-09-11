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
	return {
		"clan_deaths": 0,
		"depleted": [],
		"grass_clear_zones": [],
		"abstract_resources": {},
		"abstract_resource_caps": {},
	}


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


const ChunkGeneratorScript = preload("res://scripts/world/chunk_generator.gd")
var _chunk_gen: RefCounted = null


func _get_chunk_generator() -> RefCounted:
	if _chunk_gen == null:
		_chunk_gen = ChunkGeneratorScript.new()
	return _chunk_gen


func get_abstract_resource_pool(chunk: Vector2i) -> Dictionary:
	var rec: Dictionary = get_chunk_record(chunk)
	var pool = rec.get("abstract_resources", {})
	if pool is Dictionary and not (pool as Dictionary).is_empty():
		return (pool as Dictionary).duplicate()
	return {}


func ensure_abstract_resource_pool(chunk: Vector2i, world_seed: int, cfg: Node) -> Dictionary:
	var rec: Dictionary = get_chunk_record(chunk)
	var existing = rec.get("abstract_resources", {})
	if existing is Dictionary and not (existing as Dictionary).is_empty():
		_ensure_caps_for_chunk(rec, existing as Dictionary)
		_chunks[chunk_key(chunk)] = rec
		return (existing as Dictionary).duplicate()
	var gen := _get_chunk_generator()
	if gen == null or cfg == null:
		return {}
	var pool: Dictionary = gen.call("compute_abstract_resource_pool", world_seed, chunk, cfg) as Dictionary
	rec["abstract_resources"] = pool.duplicate()
	rec["abstract_resource_caps"] = pool.duplicate()
	_chunks[chunk_key(chunk)] = rec
	return pool.duplicate()


func _ensure_caps_for_chunk(rec: Dictionary, pool: Dictionary) -> void:
	var caps = rec.get("abstract_resource_caps", {})
	if not (caps is Dictionary) or (caps as Dictionary).is_empty():
		rec["abstract_resource_caps"] = pool.duplicate()


func regen_abstract_resources(chunk: Vector2i, elapsed_sec: float, cfg: Node) -> Dictionary:
	var events: Dictionary = {"regen": []}
	if cfg == null or elapsed_sec <= 0.0:
		return events
	var regen_table = cfg.get("gather_regen_per_sim_day")
	if not (regen_table is Dictionary):
		return events
	var sim_day_sec: float = maxf(float(cfg.get("abstract_regen_sim_day_sec")), 1.0)
	var fraction: float = elapsed_sec / sim_day_sec
	if fraction <= 0.0:
		return events
	var rec: Dictionary = get_chunk_record(chunk)
	var pool = rec.get("abstract_resources", {})
	if not (pool is Dictionary):
		return events
	var pool_dict: Dictionary = pool as Dictionary
	var caps = rec.get("abstract_resource_caps", {})
	if not (caps is Dictionary) or (caps as Dictionary).is_empty():
		_ensure_caps_for_chunk(rec, pool_dict)
		caps = rec.get("abstract_resource_caps", {})
	var caps_dict: Dictionary = caps as Dictionary if caps is Dictionary else {}
	for key_val in caps_dict.keys():
		var key: String = str(key_val)
		var cap: int = int(caps_dict.get(key, 0))
		if cap <= 0:
			continue
		var rate: float = float((regen_table as Dictionary).get(key, 0.0))
		if rate <= 0.0:
			continue
		var before: int = int(pool_dict.get(key, 0))
		if before >= cap:
			continue
		var add: int = int(floor(rate * fraction))
		if add <= 0:
			continue
		var after: int = mini(cap, before + add)
		if after <= before:
			continue
		pool_dict[key] = after
		events["regen"].append({"resource_key": key, "before": before, "after": after, "cap": cap})
	rec["abstract_resources"] = pool_dict
	_chunks[chunk_key(chunk)] = rec
	return events


func get_abstract_resource_remaining(chunk: Vector2i, resource_key: String) -> int:
	var pool: Dictionary = get_abstract_resource_pool(chunk)
	return int(pool.get(resource_key, 0))


func deplete_abstract_resource(chunk: Vector2i, resource_key: String, amount: int) -> int:
	if amount <= 0:
		return 0
	var rec: Dictionary = get_chunk_record(chunk)
	var pool = rec.get("abstract_resources", {})
	if not (pool is Dictionary):
		return 0
	var pool_dict: Dictionary = pool as Dictionary
	var before: int = int(pool_dict.get(resource_key, 0))
	if before <= 0:
		return 0
	var taken: int = mini(amount, before)
	pool_dict[resource_key] = before - taken
	rec["abstract_resources"] = pool_dict
	_chunks[chunk_key(chunk)] = rec
	return taken
