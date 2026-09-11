extends RefCounted
## Deterministic descriptors for one chunk. Instantiating nodes is ChunkManager's job.

const _SALT_RESOURCES := &"res"
const _SALT_TREES := &"trees"
const _SALT_GRASS := &"grass"
const _SALT_GROUND := &"ground"
const _SALT_CLANS := &"clans"
const _SALT_WOMEN := &"women"
const _SALT_BIOME := &"biome"

const BIOME_RESOURCE_KEYS: Dictionary = {
	"forest": ["wood", "berries", "fiber", "nuts"],
	"plains": ["grain", "fiber", "berries"],
	"swamp": ["fiber", "bugs"],
	"rocky": ["stone", "fiber"],
}

const _RESOURCE_TYPE_TO_KEY: Dictionary = {
	ResourceData.ResourceType.STONE: "stone",
	ResourceData.ResourceType.BERRIES: "berries",
	ResourceData.ResourceType.WHEAT: "grain",
	ResourceData.ResourceType.FIBER: "fiber",
	ResourceData.ResourceType.WOOD: "wood",
}


func _rng(world_seed: int, cx: int, cy: int, salt: StringName) -> RandomNumberGenerator:
	return ChunkRng.create(world_seed, cx, cy, salt)


func generate_chunk(world_seed: int, chunk: Vector2i, cfg: Node) -> Dictionary:
	var cx := chunk.x
	var cy := chunk.y
	var out := {
		"resources": [],
		"tree_groups": [],
		"tallgrass_clusters": [],
		"grass_bug_patches": [],
		"ground_items": [],
		"clans": [],
		"wild_women": [],
	}
	if cfg == null:
		return out

	# Resource density multiplier (does NOT affect clans/wildlife)
	var density_mult: float = maxf(0.1, float(cfg.get("resource_density_multiplier")) if cfg.get("resource_density_multiplier") != null else 1.0)
	var res_chance: float = float(cfg.get("resource_spawn_chance"))
	var res_n: int = maxi(1, int(ceili(float(cfg.get("resources_per_chunk")) * density_mult)))
	var tree_chance: float = float(cfg.get("tree_group_chance"))
	var tree_groups: int = maxi(1, int(ceili(float(cfg.get("tree_groups_per_chunk")) * density_mult)))
	var tmin: int = int(cfg.get("trees_per_group_min"))
	var tmax: int = int(cfg.get("trees_per_group_max"))
	var spread: float = float(cfg.get("tree_group_spread_radius"))
	var grass_clusters: int = maxi(1, int(ceili(float(cfg.get("tallgrass_clusters_per_chunk")) * density_mult)))
	var gci_min: int = maxi(1, int(ceili(float(cfg.get("tallgrass_per_cluster_min")) * density_mult / 2.0)))
	var gci_max: int = maxi(gci_min, int(ceili(float(cfg.get("tallgrass_per_cluster_max")) * density_mult / 2.0)))
	var ground_n: int = maxi(1, int(ceili(float(cfg.get("ground_items_per_chunk")) * density_mult)))
	var clan_chance: float = float(cfg.get("clan_spawn_chance"))

	var origin := Vector2(float(cx), float(cy)) * ChunkUtils.CHUNK_SIZE

	var rng_res := _rng(world_seed, cx, cy, _SALT_RESOURCES)
	var res_roll: float = rng_res.randf()
	var num_res: int = res_n if res_roll < res_chance else maxi(5, int(res_n * 0.55))
	num_res = maxi(5, num_res)
	for i in num_res:
			var lx := rng_res.randf_range(64.0, ChunkUtils.CHUNK_SIZE - 64.0)
			var ly := rng_res.randf_range(64.0, ChunkUtils.CHUNK_SIZE - 64.0)
			var pos := origin + Vector2(lx, ly)
			var rt: ResourceData.ResourceType = [
				ResourceData.ResourceType.STONE,
				ResourceData.ResourceType.BERRIES,
				ResourceData.ResourceType.WHEAT,
				ResourceData.ResourceType.FIBER,
				ResourceData.ResourceType.WOOD,
			][i % 5]
			out["resources"].append({
				"type": rt,
				"position": pos,
				"stable_id": str(cfg.call("generate_stable_id", chunk, "resource", i)),
			})

	var rng_trees := _rng(world_seed, cx, cy, _SALT_TREES)
	var num_groups: int = tree_groups if rng_trees.randf() < tree_chance else 1
	num_groups = maxi(1, num_groups)
	for g in num_groups:
			var gx := rng_trees.randf_range(200.0, ChunkUtils.CHUNK_SIZE - 200.0)
			var gy := rng_trees.randf_range(200.0, ChunkUtils.CHUNK_SIZE - 200.0)
			var gcenter := origin + Vector2(gx, gy)
			var scaled_tmin: int = maxi(1, int(ceili(float(tmin) * density_mult / 2.0)))
			var scaled_tmax: int = maxi(scaled_tmin, int(ceili(float(tmax) * density_mult / 2.0)))
			var cnt := rng_trees.randi_range(scaled_tmin, scaled_tmax)
			var group: Array = []
			var placed: Array[Vector2] = []
			const MIN_TREE_DIST := 88.0
			for t in cnt:
				var pos := gcenter
				for _attempt in 10:
					var angle := rng_trees.randf() * TAU
					var dist := rng_trees.randf_range(48.0, spread)
					var candidate := gcenter + Vector2(cos(angle), sin(angle)) * dist
					var too_close := false
					for p in placed:
						if candidate.distance_to(p) < MIN_TREE_DIST:
							too_close = true
							break
					if not too_close:
						pos = candidate
						break
				placed.append(pos)
				var sid: String = str(cfg.call("generate_stable_id", chunk, "tree_%d" % g, t))
				group.append({
					"position": pos,
					"tree_idx": rng_trees.randi_range(0, 14),
					"stable_id": sid,
					"choppable": rng_trees.randf() < 0.55,
					"scale_mult": rng_trees.randf_range(1.05, 1.28),
					"rotation": rng_trees.randf_range(-0.14, 0.14),
				})
			out["tree_groups"].append(group)

	var rng_grass := _rng(world_seed, cx, cy, _SALT_GRASS)
	var bug_patch_idx: int = 0
	for c in grass_clusters:
		var cx0 := rng_grass.randf_range(32.0, ChunkUtils.CHUNK_SIZE - 32.0)
		var cy0 := rng_grass.randf_range(32.0, ChunkUtils.CHUNK_SIZE - 32.0)
		var center := origin + Vector2(cx0, cy0)
		var ngrass := rng_grass.randi_range(gci_min, gci_max)
		var pts: Array = []
		var cluster_has_bugs: bool = rng_grass.randf() < 0.07
		for gi in ngrass:
			var pos := center + Vector2(
				rng_grass.randf_range(-90.0, 90.0),
				rng_grass.randf_range(-90.0, 90.0)
			)
			pts.append({
				"position": pos,
				"texture_idx": rng_grass.randi_range(0, 5),
			})
			if cluster_has_bugs and rng_grass.randf() < 0.35:
				var bug_sid: String = str(cfg.call("generate_stable_id", chunk, "grass_bug", bug_patch_idx))
				bug_patch_idx += 1
				out["grass_bug_patches"].append({
					"position": pos,
					"stable_id": bug_sid,
					"bugs_remaining": 1,
				})
		out["tallgrass_clusters"].append({"points": pts})

	var rng_ground := _rng(world_seed, cx, cy, _SALT_GROUND)
	for gi in ground_n:
		var px := rng_ground.randf_range(48.0, ChunkUtils.CHUNK_SIZE - 48.0)
		var py := rng_ground.randf_range(48.0, ChunkUtils.CHUNK_SIZE - 48.0)
		out["ground_items"].append({
			"position": origin + Vector2(px, py),
			"stable_id": str(cfg.call("generate_stable_id", chunk, "ground", gi)),
		})

	var rng_clan := _rng(world_seed, cx, cy, _SALT_CLANS)
	if rng_clan.randf() < clan_chance:
		out["clans"].append({
			"claim_center": origin + Vector2(
				rng_clan.randf_range(400.0, ChunkUtils.CHUNK_SIZE - 400.0),
				rng_clan.randf_range(400.0, ChunkUtils.CHUNK_SIZE - 400.0)
			),
			"caveman_offset": Vector2(rng_clan.randf_range(-120.0, 120.0), rng_clan.randf_range(-120.0, 120.0)),
			"clan_name_seed": rng_clan.randi(),
		})

	var woman_chance: float = float(cfg.get("wild_woman_chunk_chance"))
	var woman_max: int = maxi(1, int(cfg.get("wild_woman_per_chunk_max")))
	var rng_women := _rng(world_seed, cx, cy, _SALT_WOMEN)
	if rng_women.randf() < woman_chance:
		var count: int = rng_women.randi_range(1, woman_max)
		for wi in count:
			out["wild_women"].append({
				"position": origin + Vector2(
					rng_women.randf_range(64.0, ChunkUtils.CHUNK_SIZE - 64.0),
					rng_women.randf_range(64.0, ChunkUtils.CHUNK_SIZE - 64.0)
				),
				"name_seed": rng_women.randi(),
				"age": rng_women.randi_range(13, 50),
			})

	return out


func get_chunk_biome(world_seed: int, chunk: Vector2i, cfg: Node = null) -> String:
	var tq: Node = _get_terrain_query()
	if tq and tq.is_authored():
		return tq.get_chunk_biome(world_seed, chunk, cfg)
	var rng := _rng(world_seed, chunk.x, chunk.y, _SALT_BIOME)
	var roll: float = rng.randf()
	if roll < 0.34:
		return "forest"
	if roll < 0.58:
		return "plains"
	if roll < 0.78:
		return "rocky"
	return "swamp"


func get_biome_available_resources(world_seed: int, chunk: Vector2i, cfg: Node = null) -> Array:
	var tq: Node = _get_terrain_query()
	if tq and tq.is_authored():
		return tq.get_biome_available_resources(world_seed, chunk, cfg)
	var biome: String = get_chunk_biome(world_seed, chunk, cfg)
	var keys: Array = BIOME_RESOURCE_KEYS.get(biome, ["fiber", "berries"]) as Array
	return keys.duplicate()


func compute_abstract_resource_pool(world_seed: int, chunk: Vector2i, cfg: Node) -> Dictionary:
	var data: Dictionary = generate_chunk(world_seed, chunk, cfg)
	var pool: Dictionary = {
		"wood": 0,
		"stone": 0,
		"berries": 0,
		"grain": 0,
		"fiber": 0,
		"nuts": 0,
		"bugs": 0,
	}
	for group in data.get("tree_groups", []):
		if not (group is Array):
			continue
		for tree in group:
			if tree is Dictionary and bool(tree.get("choppable", false)):
				pool["wood"] = int(pool.get("wood", 0)) + 3
			else:
				pool["nuts"] = int(pool.get("nuts", 0)) + 1
	for res in data.get("resources", []):
		if not (res is Dictionary):
			continue
		var rt: int = int(res.get("type", -1))
		var key: String = str(_RESOURCE_TYPE_TO_KEY.get(rt as ResourceData.ResourceType, ""))
		if key.is_empty():
			continue
		pool[key] = int(pool.get(key, 0)) + 3
	pool["bugs"] = int(pool.get("bugs", 0)) + int(data.get("grass_bug_patches", []).size()) * 2
	pool["fiber"] = int(pool.get("fiber", 0)) + int(data.get("tallgrass_clusters", []).size()) * 2
	var biome: String = get_chunk_biome(world_seed, chunk, cfg)
	for key in BIOME_RESOURCE_KEYS.get(biome, []):
		if int(pool.get(key, 0)) <= 0:
			pool[key] = 5
	return pool


func _get_terrain_query() -> Node:
	var tree := Engine.get_main_loop()
	if tree == null or not (tree is SceneTree):
		return null
	return (tree as SceneTree).root.get_node_or_null("/root/TerrainQuery")
