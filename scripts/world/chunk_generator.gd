extends RefCounted
## Deterministic descriptors for one chunk. Instantiating nodes is ChunkManager's job.

const _SALT_RESOURCES := &"res"
const _SALT_TREES := &"trees"
const _SALT_GRASS := &"grass"
const _SALT_GROUND := &"ground"
const _SALT_CLANS := &"clans"


func _rng(world_seed: int, cx: int, cy: int, salt: StringName) -> RandomNumberGenerator:
	var rng := RandomNumberGenerator.new()
	var h: int = hash(Vector3i(int(world_seed), cx, cy))
	h = hash(str(h) + str(salt))
	rng.seed = int(h) if h != 0 else 1
	return rng


func generate_chunk(world_seed: int, chunk: Vector2i, cfg: Node) -> Dictionary:
	var cx := chunk.x
	var cy := chunk.y
	var out := {
		"resources": [],
		"tree_groups": [],
		"tallgrass_clusters": [],
		"ground_items": [],
		"clans": [],
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
	var gci_min: int = int(cfg.get("tallgrass_per_cluster_min"))
	var gci_max: int = int(cfg.get("tallgrass_per_cluster_max"))
	var ground_n: int = maxi(1, int(ceili(float(cfg.get("ground_items_per_chunk")) * density_mult)))
	var clan_chance: float = float(cfg.get("clan_spawn_chance"))

	var origin := Vector2(float(cx), float(cy)) * ChunkUtils.CHUNK_SIZE

	var rng_res := _rng(world_seed, cx, cy, _SALT_RESOURCES)
	if rng_res.randf() < res_chance:
		for i in res_n:
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
	if rng_trees.randf() < tree_chance:
		for g in tree_groups:
			var gx := rng_trees.randf_range(200.0, ChunkUtils.CHUNK_SIZE - 200.0)
			var gy := rng_trees.randf_range(200.0, ChunkUtils.CHUNK_SIZE - 200.0)
			var gcenter := origin + Vector2(gx, gy)
			var cnt := rng_trees.randi_range(tmin, tmax)
			var group: Array = []
			for t in cnt:
				var off := Vector2(
					rng_trees.randf_range(-spread, spread),
					rng_trees.randf_range(-spread, spread)
				)
				group.append({
					"position": gcenter + off,
					"tree_idx": rng_trees.randi_range(0, 14),
					"stable_id": str(cfg.call("generate_stable_id", chunk, "tree_%d" % g, t)),
				})
			out["tree_groups"].append(group)

	var rng_grass := _rng(world_seed, cx, cy, _SALT_GRASS)
	for c in grass_clusters:
		var cx0 := rng_grass.randf_range(32.0, ChunkUtils.CHUNK_SIZE - 32.0)
		var cy0 := rng_grass.randf_range(32.0, ChunkUtils.CHUNK_SIZE - 32.0)
		var center := origin + Vector2(cx0, cy0)
		var ngrass := rng_grass.randi_range(gci_min, gci_max)
		var pts: Array[Vector2] = []
		for gi in ngrass:
			pts.append(center + Vector2(
				rng_grass.randf_range(-90.0, 90.0),
				rng_grass.randf_range(-90.0, 90.0)
			))
		out["tallgrass_clusters"].append({"points": pts, "has_bugs": rng_grass.randf() < 0.07})

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

	return out
