extends RefCounted
## Same wildlife roll as a loaded chunk, without creating nodes.
## Spawn and the dormant herd both read this list so a spent animal is not born twice.

const SALT := &"wild_migratory_v1"


static func describe(chunk: Vector2i) -> Array:
	var out: Array = []
	var wgc: Node = _autoload("WorldGenConfig")
	if wgc == null or not bool(wgc.get("wild_migratory_chunk_spawns_enabled")):
		return out
	if ChunkUtils == null:
		return out
	var world_seed := int(wgc.world_seed)
	var rng: RandomNumberGenerator = ChunkRng.create(world_seed, chunk.x, chunk.y, SALT)
	if rng.randf() > float(wgc.get("wild_migratory_chunk_pass_chance")):
		return out
	var pmin: int = int(wgc.get("wild_migratory_packs_min"))
	var pmax: int = maxi(pmin, int(wgc.get("wild_migratory_packs_max")))
	var packs: int = rng.randi_range(pmin, pmax)
	var origin: Vector2 = Vector2(float(chunk.x), float(chunk.y)) * ChunkUtils.CHUNK_SIZE
	for pack_i in packs:
		var roll: float = rng.randf()
		var corr: Dictionary = _corridor(origin, rng)
		var probe: Vector2 = origin + Vector2(ChunkUtils.CHUNK_SIZE * 0.5, ChunkUtils.CHUNK_SIZE * 0.5)
		var tq: Node = _autoload("TerrainQuery")
		var eff_b := 1
		var rd := 1.0
		if tq and tq.has_method("get_effective_biome"):
			eff_b = int(tq.get_effective_biome(probe))
			rd = float(tq.river_distance_01(probe))
		var life: Node = _autoload("BiomeLifeCatalog")
		var want_type := "deer" if roll < 0.38 else ("sheep" if roll < 0.72 else "goat")
		if life and life.has_method("can_spawn_fauna"):
			if not bool(life.can_spawn_fauna(want_type, eff_b, rd, rng)):
				continue
		var entry_side: int = int(corr["entry_side"])
		var exit_x: float = float(corr["exit_x"])
		var entry_edge_x: float = float(corr["entry_edge_x"])
		var base_y: float = origin.y + rng.randf_range(140.0, ChunkUtils.CHUNK_SIZE - 140.0)
		if roll < 0.38:
			var deer_cap: int = BalanceConfig.deer_initial if BalanceConfig else 8
			var herd_n := rng.randi_range(2, mini(12, deer_cap + 3))
			for hh in herd_n:
				var sx := entry_edge_x + float(hh) * 30.0 * float(entry_side)
				var sy := base_y + rng.randf_range(-44.0, 44.0)
				out.append(_row(chunk, pack_i, hh, "deer", Vector2(sx, sy), entry_side, exit_x, rng))
		elif roll < 0.72:
			var sheep_cap: int = BalanceConfig.sheep_initial + 5 if BalanceConfig else 15
			var herd_s := rng.randi_range(2, mini(6, sheep_cap))
			for ss in herd_s:
				var spx := entry_edge_x + float(ss) * 22.0 * float(entry_side)
				var spy := base_y + rng.randf_range(-50.0, 50.0)
				out.append(_row(chunk, pack_i, ss, "sheep", Vector2(spx, spy), entry_side, exit_x, rng))
		else:
			var gpx := entry_edge_x
			var gpy := origin.y + rng.randf_range(140.0, ChunkUtils.CHUNK_SIZE - 140.0)
			out.append(_row(chunk, pack_i, 0, "goat", Vector2(gpx, gpy), entry_side, exit_x, rng))
	return out


static func _row(chunk: Vector2i, pack_i: int, index: int, kind: String, pos: Vector2, entry_side: int, exit_x: float, rng: RandomNumberGenerator) -> Dictionary:
	return {
		"type": kind,
		"position": pos,
		"seed_key": "fauna:%d:%d:%d:%d" % [chunk.x, chunk.y, pack_i, index],
		"entry_side": entry_side,
		"exit_x": exit_x,
		"tint": rng.randf_range(0.15, 1.0),
		"pack_i": pack_i,
		"index": index,
	}


static func _corridor(origin: Vector2, rng: RandomNumberGenerator) -> Dictionary:
	var entry_side: int = (-1 if rng.randf() < 0.5 else 1)
	var margin: float = 115.0
	var west_edge: float = origin.x + margin
	var east_edge: float = origin.x + ChunkUtils.CHUNK_SIZE - margin
	var entry_edge_x: float = west_edge if entry_side == -1 else east_edge
	var exit_x_val: float = east_edge if entry_side == -1 else west_edge
	return {"entry_side": entry_side, "entry_edge_x": entry_edge_x, "exit_x": exit_x_val}


static func _autoload(node_name: String) -> Node:
	var tree := Engine.get_main_loop()
	if tree == null or not (tree is SceneTree):
		return null
	return (tree as SceneTree).root.get_node_or_null(node_name)
