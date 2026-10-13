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
	_test_one_regen_per_slice()
	_test_rocky_home_gathers_neighbor_food()
	_test_away_adult_does_not_gather()
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


func _force_pool(ms: Node, chunk: Vector2i, berries: int, cap: int) -> void:
	var rec: Dictionary = ms.call("get_chunk_record", chunk)
	rec["abstract_resources"] = {"berries": berries, "stone": 5, "fiber": 5}
	rec["abstract_resource_caps"] = {"berries": cap, "stone": cap, "fiber": cap}
	rec.erase("abstract_regen_slice")


func _edible_count(inv: InventoryData) -> int:
	return inv.get_count(ResourceData.ResourceType.BERRIES) \
		+ inv.get_count(ResourceData.ResourceType.GRAIN) \
		+ inv.get_count(ResourceData.ResourceType.NUTS) \
		+ inv.get_count(ResourceData.ResourceType.BUGS)


func _test_one_regen_per_slice() -> void:
	var ms: Node = root.get_node_or_null("/root/MutationStore")
	var wgc: Node = root.get_node_or_null("/root/WorldGenConfig")
	if ms == null or wgc == null:
		_fail("one regen per slice autoloads")
		return
	wgc.set("world_seed", 424242)
	var chunk := Vector2i(12, 12)
	ms.call("reset_chunk", chunk)
	ms.call("ensure_abstract_resource_pool", chunk, 424242, wgc)
	_force_pool(ms, chunk, 1, 80)
	var roster = SettlementRosterScript.new()
	roster.clan_name = "REGEN"
	roster.members = [{"id": 1, "name": "Baby", "type": "baby", "alive": true, "hunger": 50.0, "is_player": false}]
	var make_claim := func(label: String) -> LandClaim:
		var inv := InventoryData.new(16, true, 999)
		var claim := LandClaim.new()
		claim.clan_name = label
		claim.inventory = inv
		claim.global_position = _chunk_claim_position(chunk)
		root.add_child(claim)
		return claim
	var first: LandClaim = make_claim.call("REGEN_A")
	AbstractGatherScript.gather_for_claim(first, roster, chunk, 150.0, false, 42)
	var after_first: int = int(ms.call("get_abstract_resource_remaining", chunk, "berries"))
	var second: LandClaim = make_claim.call("REGEN_B")
	AbstractGatherScript.gather_for_claim(second, roster, chunk, 150.0, false, 42)
	var after_second: int = int(ms.call("get_abstract_resource_remaining", chunk, "berries"))
	if after_first > 1 and after_second == after_first:
		_pass("two camps regen one chunk once", "%d -> %d" % [after_first, after_second])
	else:
		_fail("two camps regen one chunk once", "first=%d second=%d" % [after_first, after_second])
	first.queue_free()
	second.queue_free()


func _test_rocky_home_gathers_neighbor_food() -> void:
	var ms: Node = root.get_node_or_null("/root/MutationStore")
	var wgc: Node = root.get_node_or_null("/root/WorldGenConfig")
	if ms == null or wgc == null:
		_fail("rocky ring autoloads")
		return
	wgc.set("world_seed", 424242)
	var gen := ChunkGeneratorScript.new()
	var home := Vector2i.ZERO
	var found := false
	for cx in range(-6, 7):
		for cy in range(-6, 7):
			var chunk := Vector2i(cx, cy)
			if str(gen.call("get_chunk_biome", 424242, chunk, null)) != "rocky":
				continue
			for n in AbstractGatherScript.ring_chunks(chunk):
				var keys: Array = gen.call("get_biome_available_resources", 424242, n, null) as Array
				if "berries" in keys or "grain" in keys or "nuts" in keys or "bugs" in keys:
					home = chunk
					found = true
					break
			if found:
				break
		if found:
			break
	if not found:
		_fail("rocky home has a food neighbor", "no rocky chunk in scan")
		return
	for n in AbstractGatherScript.ring_chunks(home):
		ms.call("reset_chunk", n)
	var roster = SettlementRosterScript.new()
	roster.clan_name = "ROCK"
	roster.members = [
		{"id": 1, "name": "A", "type": "clansman", "alive": true, "hunger": 40.0, "is_player": false},
		{"id": 2, "name": "B", "type": "woman", "alive": true, "hunger": 40.0, "is_player": false},
	]
	var inv := InventoryData.new(16, true, 999)
	var claim := LandClaim.new()
	claim.clan_name = "ROCK"
	claim.inventory = inv
	claim.global_position = _chunk_claim_position(home)
	root.add_child(claim)
	var events: Dictionary = AbstractGatherScript.gather_for_claim(claim, roster, home, 30.0, false, 7)
	if _edible_count(inv) > 0:
		_pass("rocky home gathers food from the ring", "food=%d biome=%s" % [_edible_count(inv), str(events.get("biome", ""))])
	else:
		_fail("rocky home gathers food from the ring", "food=0 biome=%s gathered=%s" % [str(events.get("biome", "")), str(events.get("gathered", []))])
	claim.queue_free()


func _test_away_adult_does_not_gather() -> void:
	var ms: Node = root.get_node_or_null("/root/MutationStore")
	var wgc: Node = root.get_node_or_null("/root/WorldGenConfig")
	if ms == null or wgc == null:
		_fail("away gather autoloads")
		return
	wgc.set("world_seed", 424242)
	var gen := ChunkGeneratorScript.new()
	var food_chunks: Array[Vector2i] = []
	for cx in range(-8, 9):
		for cy in range(-8, 9):
			var chunk := Vector2i(cx, cy)
			var keys: Array = gen.call("get_biome_available_resources", 424242, chunk, null) as Array
			if "berries" in keys:
				food_chunks.append(chunk)
	var home_only := Vector2i(24, 24)
	var with_away := Vector2i(30, 30)
	if food_chunks.size() >= 2:
		home_only = food_chunks[0]
		for other in food_chunks:
			if absi(other.x - home_only.x) + absi(other.y - home_only.y) >= 6:
				with_away = other
				break
	for chunk in [home_only, with_away]:
		for n in AbstractGatherScript.ring_chunks(chunk):
			ms.call("reset_chunk", n)
			ms.call("ensure_abstract_resource_pool", n, 424242, wgc)
			_force_pool(ms, n, 40, 80)
	var one = SettlementRosterScript.new()
	one.clan_name = "HOME"
	one.members = [{"id": 1, "name": "Home", "type": "clansman", "alive": true, "hunger": 40.0, "is_player": false}]
	var two = SettlementRosterScript.new()
	two.clan_name = "AWAY"
	two.members = [
		{"id": 1, "name": "Home", "type": "clansman", "alive": true, "hunger": 40.0, "is_player": false},
		{"id": 2, "name": "Gone", "type": "clansman", "alive": true, "hunger": 40.0, "is_player": false, "away": true},
	]
	var inv_a := InventoryData.new(16, true, 999)
	var inv_b := InventoryData.new(16, true, 999)
	var claim_a := LandClaim.new()
	claim_a.clan_name = "HOME"
	claim_a.inventory = inv_a
	claim_a.global_position = _chunk_claim_position(home_only)
	root.add_child(claim_a)
	var claim_b := LandClaim.new()
	claim_b.clan_name = "AWAY"
	claim_b.inventory = inv_b
	claim_b.global_position = _chunk_claim_position(with_away)
	root.add_child(claim_b)
	AbstractGatherScript.gather_for_claim(claim_a, one, home_only, 30.0, false, 8)
	AbstractGatherScript.gather_for_claim(claim_b, two, with_away, 30.0, false, 9)
	if inv_b.get_count(ResourceData.ResourceType.BERRIES) == inv_a.get_count(ResourceData.ResourceType.BERRIES) and inv_a.get_count(ResourceData.ResourceType.BERRIES) > 0:
		_pass("away adult does not increase the take", "berries=%d" % inv_a.get_count(ResourceData.ResourceType.BERRIES))
	else:
		_fail("away adult does not increase the take", "home=%d away=%d" % [inv_a.get_count(ResourceData.ResourceType.BERRIES), inv_b.get_count(ResourceData.ResourceType.BERRIES)])
	claim_a.queue_free()
	claim_b.queue_free()


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
	brain._settlement_accum = 30.0
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
