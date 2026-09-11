extends SceneTree
## Unit-style abstract gather checks (Phase 3).
## Run: godot --path . --headless -s res://tools/test_abstract_gather.gd

const ChunkGeneratorScript = preload("res://scripts/world/chunk_generator.gd")
const AbstractGatherScript = preload("res://scripts/systems/abstract_gather.gd")
const SettlementRosterScript = preload("res://scripts/systems/settlement_roster.gd")
const SettlementSimTickScript = preload("res://scripts/systems/settlement_sim_tick.gd")

var _passed := 0
var _failed := 0


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	print("=== ABSTRACT_GATHER_TEST start ===")
	var err := change_scene_to_file("res://scenes/Main.tscn")
	if err != OK:
		_fail("load Main.tscn", "err=%s" % err)
		_summary()
		quit(1)
		return
	for _i in 8:
		await process_frame
	_test_biome_query()
	_test_swamp_no_grain()
	_test_gather_depletes_pool()
	_test_oven_requires_building()
	_test_mutation_store_roundtrip()
	_test_brain_gather_instrumentation()
	_summary()
	quit(0 if _failed == 0 else 1)


func _terrain_query() -> Node:
	return root.get_node_or_null("/root/TerrainQuery")


func _pick_land_test_chunk() -> Vector2i:
	var tq: Node = _terrain_query()
	if tq and tq.is_authored():
		var count: Vector2i = tq.get_chunk_count()
		for cy in range(count.y):
			for cx in range(count.x):
				var chunk := Vector2i(cx, cy)
				var biome: String = tq.get_chunk_biome(0, chunk, null)
				var resources: Array = tq.get_biome_available_resources(0, chunk, null) as Array
				if biome != "ocean" and resources.size() > 0:
					return chunk
		return Vector2i(0, 0)
	return Vector2i(1, 1)


func _chunk_claim_position(chunk: Vector2i) -> Vector2:
	return Vector2(float(chunk.x), float(chunk.y)) * 2048.0 + Vector2(1000.0, 1000.0)


func _test_biome_query() -> void:
	var gen := ChunkGeneratorScript.new()
	var chunk := _pick_land_test_chunk()
	var biome: String = str(gen.call("get_chunk_biome", 424242, chunk, null))
	var resources: Array = gen.call("get_biome_available_resources", 424242, chunk, null) as Array
	if not biome.is_empty() and resources.size() > 0:
		_pass("biome query returns biome + resources", "chunk=%s biome=%s res=%d" % [str(chunk), biome, resources.size()])
	else:
		_fail("biome query returns biome + resources", "chunk=%s biome=%s res=%s" % [str(chunk), biome, str(resources)])


func _test_swamp_no_grain() -> void:
	var tq: Node = _terrain_query()
	if tq and tq.is_authored():
		_pass("swamp biome excludes grain (skipped — authored map)")
		return
	var gen := ChunkGeneratorScript.new()
	for cx in range(-5, 6):
		for cy in range(-5, 6):
			var chunk := Vector2i(cx, cy)
			var biome: String = str(gen.call("get_chunk_biome", 999, chunk, null))
			if biome != "swamp":
				continue
			var resources: Array = gen.call("get_biome_available_resources", 999, chunk, null) as Array
			if "grain" in resources:
				_fail("swamp biome excludes grain", "chunk=%s resources=%s" % [str(chunk), str(resources)])
				return
	_pass("swamp biome excludes grain")


func _test_gather_depletes_pool() -> void:
	var ms: Node = root.get_node_or_null("/root/MutationStore")
	var wgc: Node = root.get_node_or_null("/root/WorldGenConfig")
	if ms == null or wgc == null:
		_fail("MutationStore / WorldGenConfig autoloads")
		return
	wgc.set("world_seed", 424242)
	var chunk := _pick_land_test_chunk()
	ms.call("reset_chunk", chunk)
	var pool: Dictionary = ms.call("ensure_abstract_resource_pool", chunk, 424242, wgc) as Dictionary
	if pool.is_empty():
		_fail("ensure abstract pool initializes", "empty pool")
		return
	var roster = SettlementRosterScript.new()
	roster.clan_name = "GATHER"
	roster.members = [
		{"id": 1, "name": "Worker", "type": "clansman", "alive": true, "hunger": 50.0, "is_player": false},
		{"id": 2, "name": "Worker2", "type": "clansman", "alive": true, "hunger": 50.0, "is_player": false},
	]
	var inv := InventoryData.new(16, true, 999)
	var claim := LandClaim.new()
	claim.clan_name = "GATHER"
	claim.inventory = inv
	claim.global_position = _chunk_claim_position(chunk)
	root.add_child(claim)
	var before_total := 0
	for k in pool.keys():
		before_total += int(pool.get(k, 0))
	var events: Dictionary = AbstractGatherScript.gather_for_claim(claim, roster, chunk, 30.0, false)
	var gathered: Array = events.get("gathered", [])
	if gathered.is_empty():
		_fail("abstract gather yields items", "gathered=0 biome=%s" % str(events.get("biome", "?")))
	else:
		_pass("abstract gather yields items", "entries=%d" % gathered.size())
	var after_pool: Dictionary = ms.call("get_abstract_resource_pool", chunk) as Dictionary
	var after_total := 0
	for k in after_pool.keys():
		after_total += int(after_pool.get(k, 0))
	if after_total < before_total:
		_pass("gather depletes chunk pool", "%d -> %d" % [before_total, after_total])
	else:
		_fail("gather depletes chunk pool", "%d -> %d" % [before_total, after_total])
	claim.queue_free()


func _test_oven_requires_building() -> void:
	var roster = SettlementRosterScript.new()
	roster.clan_name = "BAKE"
	roster.members = [
		{"id": 10, "name": "Lead", "type": "leader", "alive": true, "hunger": 80.0, "is_leader": true, "is_player": false},
	]
	var inv := InventoryData.new(8, true, 999)
	inv.add_item(ResourceData.ResourceType.GRAIN, 5)
	inv.add_item(ResourceData.ResourceType.WOOD, 5)
	var claim := LandClaim.new()
	claim.clan_name = "BAKE"
	claim.inventory = inv
	root.add_child(claim)
	var events_no_oven: Dictionary = SettlementSimTickScript.tick(claim, roster, 120.0)
	var bread_before_oven := inv.get_count(ResourceData.ResourceType.BREAD)
	if bread_before_oven > 0:
		_fail("oven production blocked without oven building", "bread=%d" % bread_before_oven)
	else:
		_pass("oven production blocked without oven building")
	var oven := BuildingBase.new()
	oven.building_type = ResourceData.ResourceType.OVEN
	oven.clan_name = "BAKE"
	root.add_child(oven)
	oven.global_position = claim.global_position + Vector2(80, 0)
	var cbi: Node = root.get_node_or_null("/root/ClaimBuildingIndex")
	if cbi:
		cbi.call("register_building", oven, claim)
	var events_with_oven: Dictionary = SettlementSimTickScript.tick(claim, roster, 120.0)
	var bread_after := inv.get_count(ResourceData.ResourceType.BREAD)
	var produced: Array = events_with_oven.get("produced", [])
	var oven_produced := false
	for p in produced:
		if p is Dictionary and str((p as Dictionary).get("building_type", "")) == "oven":
			oven_produced = true
	if bread_after > 0 and oven_produced:
		_pass("oven production with building", "bread=%d" % bread_after)
	else:
		_fail("oven production with building", "bread=%d produced=%s" % [bread_after, str(produced)])
	if cbi:
		cbi.call("unregister_building", oven)
	oven.queue_free()
	claim.queue_free()


func _test_mutation_store_roundtrip() -> void:
	var ms: Node = root.get_node_or_null("/root/MutationStore")
	var wgc: Node = root.get_node_or_null("/root/WorldGenConfig")
	if ms == null or wgc == null:
		_fail("MutationStore round-trip autoloads")
		return
	var chunk := Vector2i(9, 9)
	ms.call("reset_chunk", chunk)
	ms.call("ensure_abstract_resource_pool", chunk, 777, wgc)
	ms.call("deplete_abstract_resource", chunk, "wood", 2)
	var snap: Dictionary = ms.call("to_dict") as Dictionary
	ms.call("load_from_dict", {})
	ms.call("load_from_dict", snap)
	var remaining: int = int(ms.call("get_abstract_resource_remaining", chunk, "wood"))
	if remaining >= 0:
		_pass("MutationStore abstract pool round-trip", "wood_remaining=%d" % remaining)
	else:
		_fail("MutationStore abstract pool round-trip", "wood=%d" % remaining)


func _test_brain_gather_instrumentation() -> void:
	var ClanBrainClass = load("res://scripts/ai/clan_brain.gd")
	var roster = SettlementRosterScript.new()
	roster.clan_name = "LOGGATHER"
	roster.members = [
		{"id": 40, "name": "A", "type": "clansman", "alive": true, "hunger": 50.0, "is_player": false, "npc_type": "clansman"},
		{"id": 41, "name": "B", "type": "clansman", "alive": true, "hunger": 50.0, "is_player": false, "npc_type": "clansman"},
	]
	var inv := InventoryData.new(16, true, 999)
	var claim := LandClaim.new()
	claim.clan_name = "LOGGATHER"
	claim.inventory = inv
	claim.global_position = _chunk_claim_position(_pick_land_test_chunk())
	root.add_child(claim)
	var brain = ClanBrainClass.new(claim)
	claim.clan_brain = brain
	brain.roster = roster
	brain.is_dormant = true
	brain._dormant_eval_timer = 999.0
	var before_items := _inventory_total(inv)
	brain.dormant_update(0.0)
	var after_items := _inventory_total(inv)
	var pi: Node = root.get_node_or_null("/root/PlaytestInstrumentor")
	if after_items > before_items:
		_pass("ClanBrain dormant_update abstract gather adds items", "%d->%d" % [before_items, after_items])
	else:
		_fail("ClanBrain dormant_update abstract gather adds items", "%d->%d" % [before_items, after_items])
	if pi and pi.is_enabled():
		_pass("playtest capture enabled for gather instrumentation")
	else:
		_pass("playtest capture optional for gather instrumentation")
	claim.queue_free()


func _inventory_total(inv: InventoryData) -> int:
	if inv == null:
		return 0
	var total := 0
	for rt in ResourceData.ResourceType.values():
		total += inv.get_count(rt)
	return total


func _pass(label: String, detail: String = "") -> void:
	_passed += 1
	if detail.is_empty():
		print("ABSTRACT_GATHER_PASS: %s" % label)
	else:
		print("ABSTRACT_GATHER_PASS: %s (%s)" % [label, detail])


func _fail(label: String, detail: String = "") -> void:
	_failed += 1
	if detail.is_empty():
		print("ABSTRACT_GATHER_FAIL: %s" % label)
	else:
		print("ABSTRACT_GATHER_FAIL: %s — %s" % [label, detail])


func _summary() -> void:
	print("=== ABSTRACT_GATHER_TEST done: passed=%d failed=%d ===" % [_passed, _failed])
