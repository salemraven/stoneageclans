extends SceneTree
## Next-job assignment. A clansman always gets deliver, a reserved node, a herd,
## a loaded chunk center, or a hunt. Run: godot --path . --headless -s res://tools/test_next_job.gd

const JobService = preload("res://scripts/systems/territory_job_service.gd")
const AbstractGatherScript = preload("res://scripts/systems/abstract_gather.gd")
const SettlementRosterScript = preload("res://scripts/systems/settlement_roster.gd")

var _passed := 0
var _failed := 0


class StubResource extends Node2D:
	var resource_type: int = ResourceData.ResourceType.BERRIES
	var max_workers: int = 1
	var reserved_workers: Array = []

	func has_capacity() -> bool:
		return reserved_workers.size() < max_workers

	func reserve(worker: Node) -> bool:
		if worker in reserved_workers:
			return true
		if reserved_workers.size() >= max_workers:
			return false
		reserved_workers.append(worker)
		return true

	func is_in_cooldown_state() -> bool:
		return false


class StubWorker extends Node2D:
	var npc_name: String = "Worker"
	var npc_type: String = "clansman"
	var clan_name: String = "NEXT"
	var inventory: InventoryData
	var herded_count: int = 0
	var steering_agent = null

	func get_clan_name() -> String:
		return clan_name


class StubSteer extends RefCounted:
	var target: Vector2 = Vector2.ZERO

	func set_arrive_target(pos: Vector2) -> void:
		target = pos


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	print("=== NEXT_JOB_TEST start ===")
	var err := change_scene_to_file("res://scenes/Main.tscn")
	if err != OK:
		_fail("load Main.tscn", "err=%s" % err)
		_summary()
		quit(1)
		return
	for _i in 8:
		await process_frame
	_test_full_bush_skipped()
	_test_two_workers_do_not_share_one_slot()
	_test_claim_full_of_stone_is_not_assigned_stone()
	_test_hungry_claim_prefers_berries()
	_test_node_beyond_old_radius()
	_test_no_node_returns_chunk_center()
	_test_herd_in_hand_ignores_cap()
	_test_away_chunk_skipped_and_deposits_once()
	if _failed == 0:
		_deep_crowded_camp()
	else:
		print("DEEP_TEST skipped — unit failure")
	_summary()
	quit(0 if _failed == 0 else 1)


func _resources() -> Node:
	return root.get_node("/root/ResourceIndex")


func _pos(chunk: Vector2i, offset: Vector2 = Vector2(1000, 1000)) -> Vector2:
	return Vector2(chunk) * 2048.0 + offset


func _make_claim(clan: String, chunk: Vector2i, inv: InventoryData) -> LandClaim:
	var claim := LandClaim.new()
	claim.clan_name = clan
	claim.position = _pos(chunk)
	root.add_child(claim)
	claim.inventory = inv
	return claim


func _make_worker(clan: String, chunk: Vector2i, inv: InventoryData) -> StubWorker:
	var worker := StubWorker.new()
	worker.clan_name = clan
	worker.inventory = inv
	worker.position = _pos(chunk)
	root.add_child(worker)
	return worker


func _make_node(chunk: Vector2i, offset: Vector2, item_type: int) -> StubResource:
	var node := StubResource.new()
	node.resource_type = item_type
	node.position = _pos(chunk, offset)
	root.add_child(node)
	_resources().call("register", node)
	return node


func _test_full_bush_skipped() -> void:
	var chunk := Vector2i(180, 180)
	var claim := _make_claim("NEXT_FULL", chunk, InventoryData.new(8, true, 20))
	var worker := _make_worker("NEXT_FULL", chunk, InventoryData.new(8, false, 1))
	var full := _make_node(chunk, Vector2(1100, 1000), ResourceData.ResourceType.BERRIES)
	var open := _make_node(chunk, Vector2(1400, 1000), ResourceData.ResourceType.BERRIES)
	var blocker := StubWorker.new()
	full.reserved_workers.append(blocker)
	var assignment: Dictionary = JobService.next_job(claim, worker, [chunk])
	if str(assignment.get("kind", "")) == "gather" and assignment.get("node") == open and worker in open.reserved_workers:
		_pass("full bush skipped, second node reserved")
	else:
		_fail("full bush skipped, second node reserved", "kind=%s node=%s" % [str(assignment.get("kind", "")), str(assignment.get("node"))])
	_free_job(claim, worker, [full, open])


func _test_two_workers_do_not_share_one_slot() -> void:
	var chunk := Vector2i(181, 180)
	var claim := _make_claim("NEXT_SHARE", chunk, InventoryData.new(8, true, 20))
	var first := _make_worker("NEXT_SHARE", chunk, InventoryData.new(8, false, 1))
	var second := _make_worker("NEXT_SHARE", chunk, InventoryData.new(8, false, 1))
	var bush := _make_node(chunk, Vector2(1200, 1000), ResourceData.ResourceType.BERRIES)
	var a: Dictionary = JobService.next_job(claim, first, [chunk])
	var b: Dictionary = JobService.next_job(claim, second, [chunk])
	if a.get("node") == bush and b.get("node") != bush:
		_pass("two workers do not share one slot")
	else:
		_fail("two workers do not share one slot", "a=%s b=%s" % [str(a.get("node")), str(b.get("node"))])
	_free_job(claim, first, [bush])
	second.queue_free()


func _test_claim_full_of_stone_is_not_assigned_stone() -> void:
	var chunk := Vector2i(182, 180)
	var inv := InventoryData.new(1, true, 5)
	inv.add_item(ResourceData.ResourceType.STONE, 5)
	var claim := _make_claim("NEXT_STONE", chunk, inv)
	var worker := _make_worker("NEXT_STONE", chunk, InventoryData.new(8, false, 1))
	var stone := _make_node(chunk, Vector2(1200, 1000), ResourceData.ResourceType.STONE)
	var assignment: Dictionary = JobService.next_job(claim, worker, [chunk])
	var node: Node = assignment.get("node") as Node
	var took_stone: bool = node == stone
	if not took_stone and str(assignment.get("kind", "")) != "none":
		_pass("claim that cannot take stone is not assigned stone", "kind=%s" % str(assignment.get("kind", "")))
	else:
		_fail("claim that cannot take stone is not assigned stone", "kind=%s" % str(assignment.get("kind", "")))
	_free_job(claim, worker, [stone])


func _test_hungry_claim_prefers_berries() -> void:
	var chunk := Vector2i(183, 180)
	var claim := _make_claim("NEXT_HUNGRY", chunk, InventoryData.new(8, true, 20))
	claim.set_meta("food_days_buffer", 0.0)
	var worker := _make_worker("NEXT_HUNGRY", chunk, InventoryData.new(8, false, 1))
	var wood := _make_node(chunk, Vector2(1100, 1000), ResourceData.ResourceType.WOOD)
	var berries := _make_node(chunk, Vector2(1600, 1000), ResourceData.ResourceType.BERRIES)
	var assignment: Dictionary = JobService.next_job(claim, worker, [chunk])
	if assignment.get("node") == berries:
		_pass("hungry claim prefers berries over wood")
	else:
		_fail("hungry claim prefers berries over wood", "node=%s kind=%s" % [str(assignment.get("node")), str(assignment.get("kind", ""))])
	_free_job(claim, worker, [wood, berries])


func _test_node_beyond_old_radius() -> void:
	var home := Vector2i(184, 180)
	var far := Vector2i(186, 180)
	var claim := _make_claim("NEXT_FAR", home, InventoryData.new(8, true, 20))
	var worker := _make_worker("NEXT_FAR", home, InventoryData.new(8, false, 1))
	var node := _make_node(far, Vector2(1024, 1024), ResourceData.ResourceType.BERRIES)
	var dist: float = worker.global_position.distance_to(node.global_position)
	var assignment: Dictionary = JobService.next_job(claim, worker, [home, far])
	if dist > 2400.0 and assignment.get("node") == node:
		_pass("node outside 2400px but inside the loaded disk is assigned", "dist=%.0f" % dist)
	else:
		_fail("node outside 2400px but inside the loaded disk is assigned", "dist=%.0f kind=%s" % [dist, str(assignment.get("kind", ""))])
	_free_job(claim, worker, [node])


func _test_no_node_returns_chunk_center() -> void:
	var chunk := Vector2i(187, 180)
	var claim := _make_claim("NEXT_CHUNK", chunk, InventoryData.new(8, true, 20))
	var worker := _make_worker("NEXT_CHUNK", chunk, InventoryData.new(8, false, 1))
	var steer := StubSteer.new()
	worker.steering_agent = steer
	var assignment: Dictionary = JobService.next_job(claim, worker, [chunk])
	JobService.apply_assignment(worker, assignment)
	var center: Vector2 = root.get_node("/root/ChunkUtils").call("get_chunk_center", chunk)
	var target: Vector2 = assignment.get("target", Vector2.ZERO)
	if str(assignment.get("kind", "")) == "chunk" and target.distance_to(center) < 1.0 and steer.target.distance_to(center) < 1.0:
		_pass("no node returns a loaded chunk center")
	else:
		_fail("no node returns a loaded chunk center", "kind=%s target=%s steer=%s" % [str(assignment.get("kind", "")), str(target), str(steer.target)])
	claim.queue_free()
	worker.queue_free()


func _test_herd_in_hand_ignores_cap() -> void:
	var chunk := Vector2i(188, 180)
	var claim := _make_claim("NEXT_HERD", chunk, InventoryData.new(8, true, 20))
	claim.set_meta("max_active_herders", 0)
	var worker := _make_worker("NEXT_HERD", chunk, InventoryData.new(8, false, 1))
	worker.herded_count = 1
	var assignment: Dictionary = JobService.next_job(claim, worker, [chunk])
	if str(assignment.get("kind", "")) == "herd":
		_pass("leading a woman returns herd while the cap is full")
	else:
		_fail("leading a woman returns herd while the cap is full", "kind=%s" % str(assignment.get("kind", "")))
	claim.queue_free()
	worker.queue_free()


func _test_away_chunk_skipped_and_deposits_once() -> void:
	var ms: Node = root.get_node_or_null("/root/MutationStore")
	var wgc: Node = root.get_node_or_null("/root/WorldGenConfig")
	if ms == null or wgc == null:
		_fail("away trip autoloads")
		return
	wgc.set("world_seed", 424242)
	var chunk := _pick_berry_chunk()
	ms.call("reset_chunk", chunk)
	ms.call("ensure_abstract_resource_pool", chunk, 424242, wgc)
	_force_pool(ms, chunk, 6, 6)
	var roster = SettlementRosterScript.new()
	roster.clan_name = "NEXT_AWAY"
	roster.members = [
		{"id": 1, "name": "Home", "type": "clansman", "alive": true, "hunger": 50.0, "is_player": false},
		{"id": 2, "name": "Scout", "type": "clansman", "alive": true, "hunger": 50.0, "is_player": false, "away": true},
	]
	var inv := InventoryData.new(16, true, 999)
	var claim := _make_claim("NEXT_AWAY", chunk, inv)
	var ring: Array = AbstractGatherScript.ring_chunks(chunk)
	claim.set_meta("away_trip_chunks", ring)
	var before: int = int(ms.call("get_abstract_resource_remaining", chunk, "berries"))
	AbstractGatherScript.gather_for_claim(claim, roster, chunk, 30.0, false, 77)
	var after: int = int(ms.call("get_abstract_resource_remaining", chunk, "berries"))
	if after == before and inv.get_count(ResourceData.ResourceType.BERRIES) == 0:
		_pass("away trip chunk is not gathered by the home ledger", "berries=%d" % after)
	else:
		_fail("away trip chunk is not gathered by the home ledger", "%d -> %d inv=%d" % [before, after, inv.get_count(ResourceData.ResourceType.BERRIES)])
	var first: int = SettlementParty.resolve_unwatched_trip(claim, roster, 2, chunk)
	var second: int = SettlementParty.resolve_unwatched_trip(claim, roster, 2, chunk)
	if first == 1 and second == 0 and inv.get_count(ResourceData.ResourceType.BERRIES) == 1:
		_pass("resolving an away trip deposits once")
	else:
		_fail("resolving an away trip deposits once", "first=%d second=%d inv=%d" % [first, second, inv.get_count(ResourceData.ResourceType.BERRIES)])
	claim.queue_free()


func _deep_crowded_camp() -> void:
	var chunk := Vector2i(210, 210)
	var inv := InventoryData.new(8, true, 20)
	inv.add_item(ResourceData.ResourceType.STONE, 20)
	inv.add_item(ResourceData.ResourceType.BERRIES, 2)
	var claim := _make_claim("NEXT_DEEP", chunk, inv)
	var disk: Array = [chunk]
	var bushes: Array = [
		_make_node(chunk, Vector2(1200, 1000), ResourceData.ResourceType.BERRIES),
		_make_node(chunk, Vector2(1500, 1100), ResourceData.ResourceType.BERRIES),
	]
	var stone := _make_node(chunk, Vector2(1300, 1400), ResourceData.ResourceType.STONE)
	var workers: Array = []
	for i in 8:
		workers.append(_make_worker("NEXT_DEEP", chunk, InventoryData.new(8, false, 1)))
	var start_food: int = inv.get_count(ResourceData.ResourceType.BERRIES)
	var idle_failures: int = 0
	var food_off_deposit: int = 0
	var away_first: int = -1
	var away_second: int = -1
	var ms: Node = root.get_node_or_null("/root/MutationStore")
	var away_chunk := Vector2i(211, 211)
	if ms:
		_force_pool(ms, away_chunk, 4, 4)
	for tick in 180:
		var food_before: int = inv.get_count(ResourceData.ResourceType.BERRIES)
		var deposited: int = 0
		for worker in workers:
			var assignment: Dictionary = JobService.next_job(claim, worker, disk)
			var kind: String = str(assignment.get("kind", "none"))
			if kind != "deliver" and kind != "gather" and kind != "herd" and kind != "chunk" and kind != "hunt":
				idle_failures += 1
			if kind == "deliver":
				var carried: int = worker.inventory.get_count(ResourceData.ResourceType.BERRIES)
				if carried > 0:
					var before_add: int = inv.get_count(ResourceData.ResourceType.BERRIES)
					worker.inventory.remove_item(ResourceData.ResourceType.BERRIES, carried)
					inv.add_item(ResourceData.ResourceType.BERRIES, carried)
					deposited += inv.get_count(ResourceData.ResourceType.BERRIES) - before_add
			elif kind == "gather":
				worker.inventory.add_item(ResourceData.ResourceType.BERRIES, 1)
		if tick == 90 and ms:
			var roster = SettlementRosterScript.new()
			roster.members = [{"id": 9, "name": "Scout", "type": "clansman", "alive": true, "hunger": 40.0, "is_player": false, "away": true}]
			claim.set_meta("away_trip_chunks", [away_chunk])
			away_first = SettlementParty.resolve_unwatched_trip(claim, roster, 9, away_chunk)
			away_second = SettlementParty.resolve_unwatched_trip(claim, roster, 9, away_chunk)
			deposited += away_first
		var food_after: int = inv.get_count(ResourceData.ResourceType.BERRIES)
		if food_after - food_before != deposited:
			food_off_deposit += 1
	var end_food: int = inv.get_count(ResourceData.ResourceType.BERRIES)
	var ok: bool = idle_failures == 0 and food_off_deposit == 0 and away_first == 1 and away_second == 0 and end_food > start_food
	if ok:
		_pass("crowded camp stays working and ends with more food", "food %d -> %d" % [start_food, end_food])
	else:
		_fail("crowded camp stays working and ends with more food", "idle=%d off_deposit=%d away=%d/%d food %d -> %d" % [idle_failures, food_off_deposit, away_first, away_second, start_food, end_food])
	print("DEEP_TEST idle=%d off_deposit=%d away=%d/%d food %d -> %d" % [idle_failures, food_off_deposit, away_first, away_second, start_food, end_food])
	for worker in workers:
		worker.queue_free()
	_free_job(claim, null, bushes)
	if stone:
		_resources().call("unregister", stone)
		stone.queue_free()


func _pick_berry_chunk() -> Vector2i:
	var tq: Node = root.get_node_or_null("/root/TerrainQuery")
	if tq and tq.has_method("is_authored") and tq.is_authored():
		var count: Vector2i = tq.get_chunk_count()
		for cy in range(count.y):
			for cx in range(count.x):
				var chunk := Vector2i(cx, cy)
				var resources: Array = tq.get_biome_available_resources(0, chunk, null) as Array
				if resources.has("berries"):
					return chunk
	return Vector2i(12, 12)


func _force_pool(ms: Node, chunk: Vector2i, berries: int, cap: int) -> void:
	var rec: Dictionary = ms.call("get_chunk_record", chunk)
	rec["abstract_resources"] = {"berries": berries, "stone": 0, "fiber": 0}
	rec["abstract_resource_caps"] = {"berries": cap, "stone": cap, "fiber": cap}
	rec.erase("abstract_regen_slice")


func _free_job(claim: Node, worker: Node, nodes: Array) -> void:
	for node in nodes:
		if node and is_instance_valid(node):
			_resources().call("unregister", node)
			node.queue_free()
	if worker and is_instance_valid(worker):
		worker.queue_free()
	if claim and is_instance_valid(claim):
		claim.queue_free()


func _pass(name: String, detail: String = "") -> void:
	_passed += 1
	print("PASS %s %s" % [name, detail])


func _fail(name: String, detail: String = "") -> void:
	_failed += 1
	print("FAIL %s %s" % [name, detail])


func _summary() -> void:
	print("=== NEXT_JOB_TEST %d passed, %d failed ===" % [_passed, _failed])
