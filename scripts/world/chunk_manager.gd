extends Node
## Chunk load/unload + streaming content. Expects Main bound via bind_main before use.

const RESOURCE_SCENE := preload("res://scenes/GatherableResource.tscn")
const _NAMING_SCRIPT: Script = preload("res://scripts/naming_utils.gd")
const GrassBatchScript := preload("res://scripts/world/grass_batch.gd")
const TreeDecorSpriteScript := preload("res://scripts/world/tree_decor_sprite.gd")
const GrassBugPatchScript := preload("res://scripts/world/grass_bug_patch.gd")

var _main: Node2D
var _wgc: Node
var _ms: Node
var _chunk_generator: RefCounted
var _loaded: Dictionary = {}  # Vector2i -> Node2D chunk root
var _lost_interest_at_msec: Dictionary = {}  # Vector2i -> int
var _clan_spawned_chunks: Dictionary = {}  # Vector2i -> bool (session; cleared on unload)
var _pending_loads: Array[Vector2i] = []
var _density_accum: float = 0.0


func _ready() -> void:
	_wgc = get_node_or_null("/root/WorldGenConfig")
	_ms = get_node_or_null("/root/MutationStore")
	_chunk_generator = (preload("res://scripts/world/chunk_generator.gd") as GDScript).new() as RefCounted


func bind_main(m: Node2D) -> void:
	_main = m


func is_chunk_loaded(chunk: Vector2i) -> bool:
	return _loaded.has(chunk)


func get_loaded_chunk_coords() -> Array[Vector2i]:
	var out: Array[Vector2i] = []
	for k in _loaded.keys():
		out.append(k)
	return out


func ensure_initial_load(main_node: Node2D) -> void:
	bind_main(main_node)
	if _wgc and int(_wgc.world_seed) == 0:
		_wgc.world_seed = randi()
	if not _main or not is_instance_valid(_main):
		return
	var player: Node2D = _main.get("player") as Node2D
	if not player:
		return
	var radius: int = int(_wgc.call("get_effective_load_radius")) if _wgc and _wgc.has_method("get_effective_load_radius") else 1
	if _wgc:
		radius = maxi(radius, int(_wgc.single_player_initial_load_radius))
	var center := ChunkUtils.get_chunk_coords(player.global_position)
	_queue_disk(center, radius)
	_process_pending_loads(false)


func update_streaming(player_world_pos: Vector2, delta: float) -> void:
	if not _main or not is_instance_valid(_main):
		return
	if _wgc == null:
		_wgc = get_node_or_null("/root/WorldGenConfig")
	if not _wgc or not bool(_wgc.use_chunk_content_streaming):
		return
	var interest: Node = get_node_or_null("/root/WorldInterestManager")
	if interest and interest.has_method("recompute"):
		interest.call("recompute", _main)
	var stream_centers: Array[Vector2] = []
	if interest and interest.has_method("get_stream_centers_for_main"):
		for c in interest.call("get_stream_centers_for_main", _main) as Array:
			if c is Vector2:
				stream_centers.append(c as Vector2)
	if stream_centers.is_empty():
		stream_centers.append(player_world_pos)
	var r: int = int(_wgc.call("get_effective_load_radius")) if _wgc.has_method("get_effective_load_radius") else 1
	for center_pos in stream_centers:
		var cc := ChunkUtils.get_chunk_coords(center_pos)
		_queue_disk(cc, r)
	_process_pending_loads(false)
	_process_unloads_multi(stream_centers, r, delta)
	_process_density_timer(delta)
	var dormancy: Node = get_node_or_null("/root/SimDormancyController")
	if dormancy and dormancy.has_method("apply"):
		dormancy.call("apply", _main)


func _queue_disk(center: Vector2i, radius: int) -> void:
	for dx in range(-radius, radius + 1):
		for dy in range(-radius, radius + 1):
			var c := center + Vector2i(dx, dy)
			if _loaded.has(c):
				continue
			if c not in _pending_loads:
				_pending_loads.append(c)


func _process_pending_loads(immediate: bool) -> void:
	var per_frame: int = 9999 if immediate else (int(_wgc.chunks_load_per_frame) if _wgc else 2)
	var budget := per_frame
	while budget > 0 and not _pending_loads.is_empty():
		var c: Vector2i = _pending_loads.pop_front() as Vector2i
		if _loaded.has(c):
			continue
		_load_chunk(c)
		budget -= 1


func _process_unloads(center: Vector2i, radius: int, delta: float) -> void:
	var center_pos := ChunkUtils.get_chunk_center(center) if ChunkUtils else Vector2.ZERO
	_process_unloads_multi([center_pos], radius, delta)


func _process_unloads_multi(centers: Array[Vector2], radius: int, _delta: float) -> void:
	var hysteresis: int = int(_wgc.chunk_unload_hysteresis) if _wgc else 1
	var r_out: int = radius + maxi(hysteresis, 0)
	var want: Dictionary = {}
	for center_pos in centers:
		if ChunkUtils == null:
			continue
		var center := ChunkUtils.get_chunk_coords(center_pos)
		for dx in range(-r_out, r_out + 1):
			for dy in range(-r_out, r_out + 1):
				want[center + Vector2i(dx, dy)] = true
	var now_ms: int = Time.get_ticks_msec()
	var grace_ms: float = float(_wgc.chunk_unload_no_interest_grace_ms) if _wgc else 500.0
	var to_unload: Array[Vector2i] = []
	for chunk in _loaded.keys():
		if want.has(chunk):
			_lost_interest_at_msec.erase(chunk)
			continue
		if not _lost_interest_at_msec.has(chunk):
			_lost_interest_at_msec[chunk] = now_ms
		elif float(now_ms - int(_lost_interest_at_msec[chunk])) >= grace_ms:
			to_unload.append(chunk)
	var max_u: int = int(_wgc.chunks_unload_per_frame) if _wgc else 2
	for i in mini(max_u, to_unload.size()):
		_unload_chunk(to_unload[i])


func _load_chunk(chunk: Vector2i) -> void:
	var load_t0_usec: int = Time.get_ticks_usec()
	if _wgc == null:
		_wgc = get_node_or_null("/root/WorldGenConfig")
	if _ms == null:
		_ms = get_node_or_null("/root/MutationStore")
	if not _wgc:
		return
	var wo: Node2D = _main.get("world_objects") as Node2D
	if not wo:
		return
	var root := Node2D.new()
	root.name = "Chunk_%d_%d" % [chunk.x, chunk.y]
	root.set_meta(&"chunk_coords", chunk)
	wo.add_child(root)
	_loaded[chunk] = root
	var world_seed_val: int = int(_wgc.world_seed) if _wgc else 0
	var data: Dictionary = _chunk_generator.call("generate_chunk", world_seed_val, chunk, _wgc) as Dictionary
	if _ms and _wgc:
		if int(_ms.call("get_clan_deaths_in_chunk", chunk)) >= int(_wgc.clan_max_deaths_per_chunk):
			data["clans"] = []
	var visual_root := Node2D.new()
	visual_root.name = "VisualRoot"
	root.add_child(visual_root)
	var sim_root := Node2D.new()
	sim_root.name = "SimRoot"
	root.add_child(sim_root)
	_spawn_resources(sim_root, chunk, data.get("resources", []))
	_spawn_tree_groups(visual_root, sim_root, chunk, data.get("tree_groups", []))
	_spawn_tallgrass_layers(visual_root, sim_root, chunk, data.get("tallgrass_clusters", []), data.get("grass_bug_patches", []))
	_spawn_ground_items(sim_root, chunk, data.get("ground_items", []))
	_spawn_clans(root, chunk, data.get("clans", []))
	if _main and _main.has_method("_spawn_wildlife_for_loaded_chunk"):
		_main.call("_spawn_wildlife_for_loaded_chunk", chunk)
	var sleep_mgr: Node = get_node_or_null("/root/NPCSleepManager")
	if sleep_mgr and sleep_mgr.has_method("wake_npcs_in_chunk") and _main:
		var wo_parent: Node2D = _main.get("world_objects") as Node2D
		sleep_mgr.call("wake_npcs_in_chunk", chunk, wo_parent, _main)
	if LagProfiler and LagProfiler.is_enabled():
		LagProfiler.record_chunk_load(chunk, Time.get_ticks_usec() - load_t0_usec)


func _unload_chunk(chunk: Vector2i) -> void:
	if LagProfiler and LagProfiler.is_enabled():
		LagProfiler.record_chunk_unload(chunk)
	var sleep_mgr: Node = get_node_or_null("/root/NPCSleepManager")
	if sleep_mgr and sleep_mgr.has_method("sleep_npcs_in_chunk") and _main:
		sleep_mgr.call("sleep_npcs_in_chunk", chunk, _main)
	var root: Node = _loaded.get(chunk) as Node
	if root and is_instance_valid(root):
		root.queue_free()
	_loaded.erase(chunk)
	_lost_interest_at_msec.erase(chunk)
	_clan_spawned_chunks.erase(chunk)


func rebuild_grass_in_loaded_chunks_near(world_pos: Vector2, radius: float) -> void:
	if ChunkUtils == null:
		return
	var center := ChunkUtils.get_chunk_coords(world_pos)
	var r_chunks: int = int(ceil(radius / ChunkUtils.CHUNK_SIZE)) + 1
	for dx in range(-r_chunks, r_chunks + 1):
		for dy in range(-r_chunks, r_chunks + 1):
			var c := center + Vector2i(dx, dy)
			if not _loaded.has(c):
				continue
			var root: Node2D = _loaded[c] as Node2D
			if root == null or not is_instance_valid(root):
				continue
			var visual: Node = root.get_node_or_null("VisualRoot")
			if visual == null:
				continue
			var old: Node = visual.get_node_or_null("GrassBatch")
			if old:
				old.queue_free()
			var world_seed_val: int = int(_wgc.world_seed) if _wgc else 0
			var data: Dictionary = _chunk_generator.call("generate_chunk", world_seed_val, c, _wgc) as Dictionary
			var all_pts: Array = []
			for cl in data.get("tallgrass_clusters", []) as Array:
				if typeof(cl) != TYPE_DICTIONARY:
					continue
				for pt in cl.get("points", []) as Array:
					all_pts.append(pt)
			if all_pts.is_empty():
				continue
			GrassBatchScript.build(visual as Node2D, all_pts, c)


func _spawn_resources(root: Node2D, chunk: Vector2i, list: Array) -> void:
	for desc in list:
		if typeof(desc) != TYPE_DICTIONARY:
			continue
		var sid: String = str(desc.get("stable_id", ""))
		if _ms and sid != "" and bool(_ms.call("is_depleted", sid)):
			continue
		var res: GatherableResource = RESOURCE_SCENE.instantiate() as GatherableResource
		res.resource_type = desc.get("type", ResourceData.ResourceType.STONE) as ResourceData.ResourceType
		match res.resource_type:
			ResourceData.ResourceType.WOOD:
				res.min_amount = 4
				res.max_amount = 6
			ResourceData.ResourceType.STONE:
				res.min_amount = 4
				res.max_amount = 6
			ResourceData.ResourceType.BERRIES:
				res.min_amount = 6
				res.max_amount = 10
			ResourceData.ResourceType.WHEAT:
				res.min_amount = 2
				res.max_amount = 5
			ResourceData.ResourceType.FIBER:
				res.min_amount = 1
				res.max_amount = 2
		res.global_position = desc.get("position", Vector2.ZERO) as Vector2
		res.set_meta(&"chunk_coords", chunk)
		if desc.has("stable_id"):
			res.set_meta(&"stable_id", str(desc["stable_id"]))
		root.add_child(res)


func _spawn_tree_groups(visual_root: Node2D, sim_root: Node2D, chunk: Vector2i, groups: Array) -> void:
	if not AssetRegistry.get_treess_sprite():
		return
	var sort_offset: float = YSortUtils.tree_sort_offset_y if YSortUtils else 0.0
	for group in groups:
		if typeof(group) != TYPE_ARRAY:
			continue
		for desc in group:
			if typeof(desc) != TYPE_DICTIONARY:
				continue
			var sid: String = str(desc.get("stable_id", ""))
			if _ms and sid != "" and bool(_ms.call("is_depleted", sid)):
				continue
			if bool(desc.get("choppable", false)):
				var pos: Vector2 = desc.get("position", Vector2.ZERO) as Vector2
				var tree_idx: int = int(desc.get("tree_idx", 0))
				var wrapper := Node2D.new()
				wrapper.global_position = pos + Vector2(0, sort_offset)
				wrapper.set_meta(&"chunk_coords", chunk)
				if sid != "":
					wrapper.set_meta(&"stable_id", sid)
				var wood: GatherableResource = RESOURCE_SCENE.instantiate() as GatherableResource
				wood.resource_type = ResourceData.ResourceType.WOOD
				wood.tree_sheet_index = tree_idx
				wood.min_amount = 4
				wood.max_amount = 6
				wood.position = Vector2(0, -sort_offset)
				wrapper.add_child(wood)
				sim_root.add_child(wrapper)
			else:
				var decor: Node2D = TreeDecorSpriteScript.new() as Node2D
				visual_root.add_child(decor)
				if decor.has_method("setup"):
					decor.call("setup", desc)


func _spawn_tallgrass_layers(visual_root: Node2D, sim_root: Node2D, chunk: Vector2i, clusters: Array, bug_patches: Array) -> void:
	var all_pts: Array = []
	for cl in clusters:
		if typeof(cl) != TYPE_DICTIONARY:
			continue
		for pt in cl.get("points", []) as Array:
			all_pts.append(pt)
	if not all_pts.is_empty():
		GrassBatchScript.build(visual_root, all_pts, chunk)
	for patch in bug_patches:
		if typeof(patch) != TYPE_DICTIONARY:
			continue
		var sid: String = str(patch.get("stable_id", ""))
		if _ms and sid != "" and bool(_ms.call("is_depleted", sid)):
			continue
		var pos: Vector2 = patch.get("position", Vector2.ZERO) as Vector2
		if MutationStore and MutationStore.is_position_grass_cleared(pos):
			continue
		var marker: Area2D = GrassBugPatchScript.new() as Area2D
		if marker.has_method("setup"):
			marker.call("setup", pos, sid, chunk, int(patch.get("bugs_remaining", 1)))
		sim_root.add_child(marker)


func _spawn_ground_items(root: Node2D, chunk: Vector2i, list: Array) -> void:
	var types := [
		ResourceData.ResourceType.STONE,
		ResourceData.ResourceType.WOOD,
		ResourceData.ResourceType.MUSHROOM,
	]
	for desc in list:
		if typeof(desc) != TYPE_DICTIONARY:
			continue
		var sid: String = str(desc.get("stable_id", ""))
		if _ms and sid != "" and bool(_ms.call("is_depleted", sid)):
			continue
		var pos: Vector2 = desc.get("position", Vector2.ZERO) as Vector2
		var gi: GroundItem = GroundItem.new()
		gi.item_type = types[posmod(int(pos.x + pos.y), types.size())]
		var sprite := Sprite2D.new()
		sprite.name = "Sprite"
		gi.add_child(sprite)
		gi.global_position = pos
		gi.set_meta(&"chunk_coords", chunk)
		if sid != "":
			gi.set_meta(&"stable_id", sid)
		root.add_child(gi)


func _neighbors_block_clan_spawn(chunk: Vector2i) -> bool:
	var spacing: int = int(_wgc.clan_min_spacing_chunks) if _wgc else 2
	for dx in range(-spacing, spacing + 1):
		for dy in range(-spacing, spacing + 1):
			if dx == 0 and dy == 0:
				continue
			var n: Vector2i = chunk + Vector2i(dx, dy)
			if _clan_spawned_chunks.get(n, false):
				return true
	return false


func _spawn_clans(root: Node2D, chunk: Vector2i, clans: Array) -> void:
	if clans.is_empty():
		return
	if _neighbors_block_clan_spawn(chunk):
		return
	for cdesc in clans:
		if typeof(cdesc) != TYPE_DICTIONARY:
			continue
		var seed_name: int = int(cdesc.get("clan_name_seed", 0))
		var clan_name: String = str(_NAMING_SCRIPT.call("generate_landclaim_name_seeded", seed_name))
		var claim_c: Vector2 = cdesc.get("claim_center", Vector2.ZERO) as Vector2
		var off: Vector2 = cdesc.get("caveman_offset", Vector2.ZERO) as Vector2
		var cave_p: Vector2 = claim_c + off
		if _main.has_method("spawn_seeded_ai_clan_at"):
			_main.call("spawn_seeded_ai_clan_at", claim_c, cave_p, clan_name, root)
		_clan_spawned_chunks[chunk] = true
		break  # one clan pack per chunk max from generator list


func _process_density_timer(delta: float) -> void:
	if not _wgc or not bool(_wgc.clan_respawn_enabled):
		return
	if not _main or not is_instance_valid(_main):
		return
	_density_accum += delta
	var interval: float = float(_wgc.clan_density_check_interval_sec)
	if _density_accum < interval:
		return
	_density_accum = 0.0
	var player: Node2D = _main.get("player") as Node2D
	if not player:
		var tree := _main.get_tree()
		if tree:
			player = tree.get_first_node_in_group("player") as Node2D
	if not player:
		return
	var min_c: int = int(_wgc.min_clans_per_player)
	var r_chunks: int = int(_wgc.clan_check_radius_chunks)
	var r_px: float = float(r_chunks) * ChunkUtils.CHUNK_SIZE
	if _main.has_method("count_ai_clans_with_claims_near"):
		var cnt: int = int(_main.call("count_ai_clans_with_claims_near", player.global_position, r_px))
		if cnt >= min_c:
			return
	var candidates: Array[Vector2i] = []
	for c in _loaded.keys():
		if bool(_wgc.clan_respawn_avoid_player_chunk):
			var pc := ChunkUtils.get_chunk_coords(player.global_position)
			if c == pc:
				continue
		if _ms and int(_ms.call("get_clan_deaths_in_chunk", c)) >= int(_wgc.clan_max_deaths_per_chunk):
			continue
		candidates.append(c)
	if candidates.is_empty():
		return
	var pick: Vector2i = candidates[randi() % candidates.size()]
	if _main.has_method("spawn_density_fill_clan_at_chunk"):
		_main.call("spawn_density_fill_clan_at_chunk", pick, _loaded[pick] as Node2D)
