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
		"grass_bug_patches": [],
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

	return out
