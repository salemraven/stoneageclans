extends SceneTree
## Headless spawn-flow checks after legacy minigame removal.
## Run: godot --path . --headless -s res://tools/test_spawn_flow.gd

const WAIT_SEC := 8.0
const FIXED_SEED := 424242

var _passed := 0
var _failed := 0


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	print("=== SPAWN_FLOW_TEST start (seed=%d) ===" % FIXED_SEED)
	var err := change_scene_to_file("res://scenes/Main.tscn")
	if err != OK:
		_fail("load Main.tscn", "err=%s" % err)
		_summary()
		quit(1)
		return
	await create_timer(WAIT_SEC).timeout
	await process_frame
	_check_player_spawn()
	_check_chunks_loaded()
	_check_no_minigame_ring()
	_check_chunk_seeded_npcs()
	_summary()
	quit(0 if _failed == 0 else 1)


func _check_player_spawn() -> void:
	var main: Node = current_scene
	if main == null:
		_fail("main scene exists")
		return
	var player: Node2D = main.get("player") as Node2D
	if player == null:
		_fail("player exists")
		return
	var pos: Vector2 = player.global_position
	print("SPAWN_FLOW_METRIC player_pos=%s" % str(pos))
	if pos.distance_to(Vector2.ZERO) < 128.0:
		_pass("player at origin (single-player)", "pos=%s" % str(pos))
	else:
		_fail("player at origin", "pos=%s (expected near 0,0)" % str(pos))


func _check_chunks_loaded() -> void:
	var cm: Node = root.get_node_or_null("/root/ChunkManager")
	if cm == null or not cm.has_method("get_loaded_chunk_coords"):
		_fail("ChunkManager present")
		return
	var loaded: Array = cm.call("get_loaded_chunk_coords") as Array
	print("SPAWN_FLOW_METRIC loaded_chunks=%d" % loaded.size())
	if loaded.size() >= 1:
		_pass("chunks loaded around player", "count=%d" % loaded.size())
	else:
		_fail("chunks loaded around player", "count=0")


func _check_no_minigame_ring() -> void:
	## Old minigame placed exactly BalanceConfig.caveman_count cavemen in a ring — default 4.
	var cavemen: Array = []
	for node in get_nodes_in_group("npcs"):
		if not is_instance_valid(node):
			continue
		if str(node.get("npc_type")) != "caveman":
			continue
		cavemen.append(node)
	var player: Node2D = null
	var main: Node = current_scene
	if main:
		player = main.get("player") as Node2D
	if player == null:
		_fail("player for ring check")
		return
	var ring_count := 0
	var r_min: float = 850.0
	var r_max: float = 1300.0
	for c in cavemen:
		if not is_instance_valid(c):
			continue
		var d: float = (c as Node2D).global_position.distance_to(player.global_position)
		if d >= r_min and d <= r_max:
			ring_count += 1
	print("SPAWN_FLOW_METRIC cavemen_total=%d ring_band=%d" % [cavemen.size(), ring_count])
	if ring_count <= 1:
		_pass("no minigame ring (<=1 caveman in old radius band)", "ring=%d total=%d" % [ring_count, cavemen.size()])
	else:
		_fail("no minigame ring", "ring=%d (old minigame placed ~4 in 900-1200 band)" % ring_count)


func _check_chunk_seeded_npcs() -> void:
	var women := 0
	var wildlife := 0
	for node in get_nodes_in_group("npcs"):
		if not is_instance_valid(node):
			continue
		var t: String = str(node.get("npc_type"))
		if t == "woman":
			women += 1
		elif t in ["deer", "sheep", "goat"]:
			wildlife += 1
	print("SPAWN_FLOW_METRIC women=%d wildlife=%d" % [women, wildlife])
	if women + wildlife >= 1:
		_pass("chunk-seeded NPCs present", "women=%d wildlife=%d" % [women, wildlife])
	else:
		_fail("chunk-seeded NPCs present", "women=0 wildlife=0 (may need higher woman chance or wait)")


func _pass(label: String, detail: String = "") -> void:
	_passed += 1
	if detail.is_empty():
		print("SPAWN_FLOW_PASS: %s" % label)
	else:
		print("SPAWN_FLOW_PASS: %s (%s)" % [label, detail])


func _fail(label: String, detail: String = "") -> void:
	_failed += 1
	if detail.is_empty():
		print("SPAWN_FLOW_FAIL: %s" % label)
	else:
		print("SPAWN_FLOW_FAIL: %s — %s" % [label, detail])


func _summary() -> void:
	print("=== SPAWN_FLOW_TEST done: passed=%d failed=%d ===" % [_passed, _failed])
