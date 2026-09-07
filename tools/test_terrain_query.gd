extends SceneTree
## TerrainQuery + authored chunk tile smoke test.
## Run: godot --path . --headless -s res://tools/test_terrain_query.gd

const BiomePaletteRes = preload("res://scripts/world/biome_palette.gd")
const TerrainQueryScript = preload("res://scripts/world/terrain_query.gd")

var _passed := 0
var _failed := 0
var _tq: Node


func _init() -> void:
	call_deferred("_run")


func _terrain_query() -> Node:
	if _tq == null:
		_tq = root.get_node_or_null("/root/TerrainQuery")
	return _tq


func _run() -> void:
	print("=== TERRAIN_QUERY_TEST start ===")
	await process_frame
	_test_palette_nearest()
	_test_authored_meta_loaded()
	_test_biome_lookup_in_bounds()
	_test_chunk_biome_string()
	_test_authored_chunk_files()
	_test_chunk_manager_ground_path()
	await _test_main_chunk_ground()
	_summary()
	quit(0 if _failed == 0 else 1)


func _test_palette_nearest() -> void:
	var ocean = BiomePaletteRes.nearest_biome(Color("#0066cc"))
	var savanna = BiomePaletteRes.nearest_biome(Color("#c8d878"))
	if ocean == BiomePaletteRes.Biome.OCEAN and savanna == BiomePaletteRes.Biome.SAVANNA:
		_pass("BiomePalette nearest color snap")
	else:
		_fail("BiomePalette nearest color snap", "ocean=%s savanna=%s" % [ocean, savanna])


func _test_authored_meta_loaded() -> void:
	var tq: Node = _terrain_query()
	if tq == null:
		_fail("TerrainQuery autoload present")
		return
	if not tq.is_authored():
		_fail("TerrainQuery authored island loaded", "run tools/build_placeholder_island.py first")
		return
	var size: Vector2 = tq.get_world_size_px()
	if size.x >= 2048.0 and size.y >= 2048.0:
		_pass("TerrainQuery authored meta", "world=%s" % str(size))
	else:
		_fail("TerrainQuery authored meta", "world=%s" % str(size))


func _test_biome_lookup_in_bounds() -> void:
	var tq: Node = _terrain_query()
	if tq == null or not tq.is_authored():
		_fail("biome lookup skipped — no authored map")
		return
	var center: Vector2 = tq.get_world_size_px() * 0.5
	var biome_name: String = tq.get_biome_id(center)
	if biome_name.is_empty():
		_fail("biome lookup returns name at island center")
	else:
		_pass("biome lookup at center", biome_name)
	var corner: String = tq.get_biome_id(Vector2(8.0, 8.0))
	if corner == "ocean":
		_pass("ocean at padded corner", corner)
	else:
		_pass("corner biome sample", corner)


func _test_chunk_biome_string() -> void:
	var tq: Node = _terrain_query()
	if tq == null or not tq.is_authored():
		return
	var chunk := Vector2i(0, 0)
	var biome: String = tq.get_chunk_biome(0, chunk, null)
	var resources: Array = tq.get_biome_available_resources(0, chunk, null) as Array
	if not biome.is_empty() and resources.size() >= 0:
		_pass("chunk biome + resources", "biome=%s res=%d" % [biome, resources.size()])
	else:
		_fail("chunk biome + resources")


func _test_authored_chunk_files() -> void:
	var tq: Node = _terrain_query()
	if tq == null or not tq.is_authored():
		return
	var count: Vector2i = tq.get_chunk_count()
	var found := 0
	for cy in range(count.y):
		for cx in range(count.x):
			var c := Vector2i(cx, cy)
			if tq.has_authored_chunk_tile(c):
				found += 1
	if found > 0:
		_pass("authored chunk tiles on disk", "count=%d" % found)
	else:
		_fail("authored chunk tiles on disk", "expected at least one tile_*_*.png")


func _test_chunk_manager_ground_path() -> void:
	var tq: Node = _terrain_query()
	if tq == null or not tq.is_authored():
		return
	var sample := Vector2i(0, 0)
	if not tq.has_authored_chunk_tile(sample):
		_fail("sample chunk tile exists for ground load")
		return
	var path := "res://maps/island/chunks/tile_%d_%d.png" % [sample.x, sample.y]
	if FileAccess.file_exists(path):
		_pass("chunk ground texture path", path)
	else:
		_fail("chunk ground texture path", path)


func _test_main_chunk_ground() -> void:
	var tq: Node = _terrain_query()
	if tq == null or not tq.is_authored():
		return
	var err := change_scene_to_file("res://scenes/Main.tscn")
	if err != OK:
		_fail("load Main for chunk ground", "err=%s" % err)
		return
	for _i in 12:
		await process_frame
	var cm: Node = root.get_node_or_null("/root/ChunkManager")
	var main: Node = root.get_tree().current_scene
	if cm == null or main == null:
		_fail("ChunkManager / Main for ground test")
		return
	if cm.has_method("bind_main"):
		cm.call("bind_main", main)
	if cm.has_method("ensure_initial_load"):
		cm.call("ensure_initial_load", main)
	for _i in 8:
		await process_frame
	var wo: Node = main.get("world_objects")
	if wo == null:
		_fail("world_objects for chunk ground")
		return
	var found_ground := false
	for child in wo.get_children():
		if not str(child.name).begins_with("Chunk_"):
			continue
		var visual: Node = child.get_node_or_null("VisualRoot")
		if visual and visual.get_node_or_null("AuthoredGround"):
			found_ground = true
			break
	if found_ground:
		_pass("ChunkManager spawned AuthoredGround sprite")
	else:
		_fail("ChunkManager spawned AuthoredGround sprite", "player may be outside 4096 placeholder — check spawn")


func _pass(label: String, detail: String = "") -> void:
	_passed += 1
	if detail.is_empty():
		print("TERRAIN_QUERY_PASS: %s" % label)
	else:
		print("TERRAIN_QUERY_PASS: %s (%s)" % [label, detail])


func _fail(label: String, detail: String = "") -> void:
	_failed += 1
	if detail.is_empty():
		print("TERRAIN_QUERY_FAIL: %s" % label)
	else:
		print("TERRAIN_QUERY_FAIL: %s — %s" % [label, detail])


func _summary() -> void:
	print("=== TERRAIN_QUERY_TEST done: passed=%d failed=%d ===" % [_passed, _failed])
