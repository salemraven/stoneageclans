extends SceneTree
## Headless integration checks for visual vs sim layer (grass batch, DecorIndex, mutations, dormant).
## Run: godot --path . --headless -s res://tools/test_visual_sim_layer.gd

const WAIT_SEC := 10.0

var _passed := 0
var _failed := 0


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	print("=== VISUAL_SIM_TEST start ===")
	var err := change_scene_to_file("res://scenes/Main.tscn")
	if err != OK:
		_fail("load Main.tscn", "err=%s" % err)
		_summary()
		quit(1)
		return
	await create_timer(WAIT_SEC).timeout
	await process_frame
	_check_node_counts()
	_check_chunk_visual_layers()
	_check_decor_index()
	_check_mutation_persistence()
	_check_dormant_brains()
	_summary()
	quit(0 if _failed == 0 else 1)


func _check_node_counts() -> void:
	var wgc: Node = root.get_node_or_null("/root/WorldGenConfig")
	var streaming: bool = wgc != null and bool(wgc.get("use_chunk_content_streaming"))
	var tallgrass: int = get_nodes_in_group("tallgrass").size()
	var deco_trees: int = get_nodes_in_group("decorative_trees").size()
	var total := _count_nodes(current_scene)
	print("VISUAL_SIM_METRIC tallgrass=%d decorative_trees=%d total_nodes=%d streaming=%s" % [
		tallgrass, deco_trees, total, streaming
	])
	if streaming:
		if tallgrass == 0:
			_pass("tallgrass group empty under chunk streaming")
		else:
			_fail("tallgrass group empty", "count=%d" % tallgrass)
		if deco_trees == 0:
			_pass("decorative_trees group empty (batched)")
		else:
			_fail("decorative_trees group empty", "count=%d" % deco_trees)
		if total < 22000:
			_pass("total node count reduced", "total=%d" % total)
		else:
			_fail("total node count reduced", "total=%d (expected <22000)" % total)
	else:
		_pass("chunk streaming off — skip tallgrass=0 gate")


func _check_chunk_visual_layers() -> void:
	var counts := {"grass_batches": 0, "tree_batches": 0, "multimesh": 0, "bug_patches": 0, "choppable_trees": 0}
	var main: Node = current_scene
	var wo: Node = main.get("world_objects") if main else null
	if wo == null:
		_fail("world_objects exists")
		return
	_scan_world(wo, counts)
	print("VISUAL_SIM_METRIC grass_batches=%d tree_batches=%d multimesh=%d bug_patches=%d choppable_trees=%d" % [
		counts.grass_batches, counts.tree_batches, counts.multimesh, counts.bug_patches, counts.choppable_trees
	])
	if counts.grass_batches > 0:
		_pass("GrassBatch nodes present", "count=%d" % counts.grass_batches)
	else:
		_fail("GrassBatch nodes present", "count=0")
	if counts.multimesh > 0:
		_pass("MultiMeshInstance2D grass rendering", "count=%d" % counts.multimesh)
	else:
		_fail("MultiMeshInstance2D grass rendering", "count=0")
	if counts.bug_patches > 0:
		_pass("GrassBugPatch sim markers", "count=%d" % counts.bug_patches)
	else:
		_fail("GrassBugPatch sim markers", "count=0")
	if counts.choppable_trees > 0:
		_pass("choppable tree sim nodes", "count=%d" % counts.choppable_trees)
	else:
		_fail("choppable tree sim nodes", "count=0")


func _scan_world(n: Node, counts: Dictionary) -> void:
	if n.name == "GrassBatch":
		counts.grass_batches = int(counts.grass_batches) + 1
	elif n.name == "TreeBatch":
		counts.tree_batches = int(counts.tree_batches) + 1
	if n is MultiMeshInstance2D:
		counts.multimesh = int(counts.multimesh) + 1
	if n.has_method("is_forageable") and n.get("decor_kind") == &"grass_bug":
		counts.bug_patches = int(counts.bug_patches) + 1
	if n is GatherableResource and n.resource_type == ResourceData.ResourceType.WOOD:
		counts.choppable_trees = int(counts.choppable_trees) + 1
	for ch in n.get_children():
		_scan_world(ch, counts)


func _check_decor_index() -> void:
	var decor: Node = root.get_node_or_null("/root/DecorIndex")
	if decor == null:
		_fail("DecorIndex autoload")
		return
	var main: Node = current_scene
	var player: Node2D = main.get("player") as Node2D if main else null
	if player == null:
		_fail("player for DecorIndex query")
		return
	var hits: Array = decor.call("query_near", player.global_position, 800.0, {
		"kind": &"grass_bug",
		"forageable_only": true,
	}) as Array
	if hits.size() > 0:
		_pass("DecorIndex bug query near player", "hits=%d" % hits.size())
	else:
		_fail("DecorIndex bug query near player", "hits=0")
	var nearest: Node2D = decor.call("query_nearest_node", player.global_position, 800.0, {
		"kind": &"grass_bug",
		"forageable_only": true,
	}) as Node2D
	if nearest != null and nearest.has_method("is_forageable"):
		_pass("DecorIndex query_nearest_node", nearest.name)
	else:
		_fail("DecorIndex query_nearest_node")


func _check_mutation_persistence() -> void:
	var ms: Node = root.get_node_or_null("/root/MutationStore")
	var chunk_utils: Node = root.get_node_or_null("/root/ChunkUtils")
	if ms == null or chunk_utils == null:
		_fail("MutationStore / ChunkUtils for persistence test")
		return
	var wgc: Node = root.get_node_or_null("/root/WorldGenConfig")
	if wgc == null:
		_fail("WorldGenConfig for persistence test")
		return
	var gen: RefCounted = (preload("res://scripts/world/chunk_generator.gd") as GDScript).new() as RefCounted
	var chunk := Vector2i(0, 0)
	var seed_val := 424242
	wgc.world_seed = seed_val
	var data: Dictionary = gen.call("generate_chunk", seed_val, chunk, wgc) as Dictionary
	var patches: Array = data.get("grass_bug_patches", []) as Array
	if patches.is_empty():
		_fail("generator produces grass_bug_patches")
		return
	var sid: String = str((patches[0] as Dictionary).get("stable_id", ""))
	if sid.is_empty():
		_fail("grass_bug stable_id")
		return
	ms.call("deplete_stable_id", sid)
	if not bool(ms.call("is_depleted", sid)):
		_fail("MutationStore.deplete_stable_id", sid)
		return
	_pass("MutationStore depletes stable_id", sid)
	var snap: Dictionary = ms.call("to_dict") as Dictionary
	ms.call("load_from_dict", {})
	if bool(ms.call("is_depleted", sid)):
		_fail("MutationStore load_from_dict restores depletion")
	else:
		ms.call("load_from_dict", snap)
		if bool(ms.call("is_depleted", sid)):
			_pass("MutationStore snapshot round-trip")
		else:
			_fail("MutationStore snapshot round-trip")


func _check_dormant_brains() -> void:
	var interest: Node = root.get_node_or_null("/root/WorldInterestManager")
	if interest == null:
		_fail("WorldInterestManager autoload")
		return
	_pass("WorldInterestManager autoload present")
	var main: Node = current_scene
	if main and interest.has_method("recompute"):
		interest.call("recompute", main)
		var chunks: Array = interest.call("get_active_chunk_list") as Array
		if chunks.size() > 0:
			_pass("WorldInterestManager active chunks", "count=%d" % chunks.size())
		else:
			_fail("WorldInterestManager active chunks", "count=0")
	var dormant := 0
	var active := 0
	for claim in get_nodes_in_group("land_claims"):
		if not is_instance_valid(claim):
			continue
		var brain = claim.get("clan_brain")
		if brain == null:
			continue
		if brain.get("is_dormant") == true:
			dormant += 1
		else:
			active += 1
	print("VISUAL_SIM_METRIC clan_brains active=%d dormant=%d" % [active, dormant])
	if active + dormant > 0:
		_pass("ClanBrain instances on land claims", "active=%d dormant=%d" % [active, dormant])
	else:
		_fail("ClanBrain instances on land claims")
	var sleep_mgr: Node = root.get_node_or_null("/root/NPCSleepManager")
	if sleep_mgr:
		_pass("NPCSleepManager autoload", "sleeping=%d" % int(sleep_mgr.call("get_sleeping_count")))
	else:
		_fail("NPCSleepManager autoload")


func _count_nodes(n: Node) -> int:
	var c := 1
	for ch in n.get_children():
		c += _count_nodes(ch)
	return c


func _pass(label: String, detail: String = "") -> void:
	_passed += 1
	if detail.is_empty():
		print("VISUAL_SIM_PASS %s" % label)
	else:
		print("VISUAL_SIM_PASS %s (%s)" % [label, detail])


func _fail(label: String, detail: String = "") -> void:
	_failed += 1
	if detail.is_empty():
		print("VISUAL_SIM_FAIL %s" % label)
	else:
		print("VISUAL_SIM_FAIL %s — %s" % [label, detail])


func _summary() -> void:
	print("=== VISUAL_SIM_TEST done passed=%d failed=%d ===" % [_passed, _failed])
