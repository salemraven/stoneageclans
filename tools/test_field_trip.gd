extends SceneTree
## A gatherer past the wake line comes home with the goods once.
## Run: godot --headless --path . -s res://tools/test_field_trip.gd -- --skip-single-instance

var _failed := 0


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	await process_frame
	if not SettlementParty.scores_auto_hunt(true) and SettlementParty.scores_auto_hunt(false):
		print("FIELD_NO_PLAYER_HUNT_PASS")
	else:
		_fail("player camp would hunt on its own")
	await _test_haul_comes_home_once()
	await _test_bush_gather_comes_home_once()
	await _test_bush_job_is_not_frozen_without_a_ticket()
	await _test_spent_look_does_not_spend_again()
	print("FIELD_TRIP_TEST failed=%d" % _failed)
	quit(0 if _failed == 0 else 1)


func _test_haul_comes_home_once() -> void:
	var ms: Node = root.get_node_or_null("MutationStore")
	var cfg: Node = root.get_node_or_null("WorldGenConfig")
	if ms == null or cfg == null:
		_fail("pool autoloads missing")
		return
	var chunk := Vector2i(9, 9)
	ms.call("ensure_abstract_resource_pool", chunk, int(cfg.get("world_seed")), cfg)
	var before := _pool_sum(ms, chunk)
	var world := Node2D.new()
	root.add_child(world)
	var claim := LandClaim.new()
	claim.clan_name = "TEST"
	claim.player_owned = true
	claim.inventory = InventoryData.new(40, true, 99)
	world.add_child(claim)
	claim.global_position = Vector2.ZERO
	var scene: PackedScene = load("res://scenes/NPC.tscn") as PackedScene
	var man: Node = scene.instantiate()
	man.set("npc_type", "clansman")
	man.set("npc_name", "HAUL")
	world.add_child(man)
	if man.has_method("set_clan_name"):
		man.set_clan_name("TEST", "field_trip")
	for _i in 6:
		await process_frame
	man.global_position = Vector2(3000.0, 0.0)
	man.set_meta("next_job_kind", "chunk")
	man.set_meta("next_job_chunk", "9,9")
	if not SettlementParty.park_field_gather(claim, man):
		_fail("gatherer was not parked")
		world.queue_free()
		return
	if not man.has_method("is_sim_dormant") or not man.is_sim_dormant():
		_fail("parked gatherer kept simulating")
	var hands_before := _hands_sum(man)
	SettlementParty.step_field_trips(claim, 10000.0, Vector2.INF, 1200.0)
	var after_pay := _pool_sum(ms, chunk)
	SettlementParty.step_field_trips(claim, 10000.0, Vector2.INF, 1200.0)
	var home_dist: float = man.global_position.distance_to(Vector2.ZERO)
	var claim_sum := _claim_sum(claim)
	var hands := _hands_sum(man)
	print("FIELD_HAUL pool %d->%d hands %d->%d claim=%d dist=%.0f dormant=%s" % [
		before, after_pay, hands_before, hands, claim_sum, home_dist, man.is_sim_dormant()
	])
	var ok := true
	if after_pay >= before:
		_fail("chunk pool was not spent")
		ok = false
	if hands <= hands_before:
		_fail("goods did not go into his hands")
		ok = false
	if claim_sum != 0:
		_fail("goods were dropped in the claim early")
		ok = false
	if man.is_sim_dormant() or home_dist > 1200.0 or home_dist < 900.0:
		_fail("he did not wake on the circle")
		ok = false
	var pool_at_home := _pool_sum(ms, chunk)
	SettlementParty.step_field_trips(claim, 10000.0, Vector2.INF, 1200.0)
	if _pool_sum(ms, chunk) != pool_at_home:
		_fail("the same trip paid twice")
		ok = false
	if ok:
		print("FIELD_HAUL_PASS")
	world.queue_free()


func _test_bush_gather_comes_home_once() -> void:
	var ms: Node = root.get_node_or_null("MutationStore")
	var cfg: Node = root.get_node_or_null("WorldGenConfig")
	if ms == null or cfg == null:
		_fail("pool autoloads missing")
		return
	var chunk := Vector2i(8, 8)
	ms.call("ensure_abstract_resource_pool", chunk, int(cfg.get("world_seed")), cfg)
	var before := _pool_sum(ms, chunk)
	var world := Node2D.new()
	root.add_child(world)
	var claim := LandClaim.new()
	claim.clan_name = "TEST"
	claim.player_owned = true
	claim.inventory = InventoryData.new(40, true, 99)
	world.add_child(claim)
	claim.global_position = Vector2.ZERO
	var scene: PackedScene = load("res://scenes/NPC.tscn") as PackedScene
	var man: Node = scene.instantiate()
	man.set("npc_type", "clansman")
	man.set("npc_name", "BUSH")
	world.add_child(man)
	if man.has_method("set_clan_name"):
		man.set_clan_name("TEST", "field_trip")
	for _i in 6:
		await process_frame
	var bush_at := Vector2(17408.0, 17408.0)
	man.global_position = bush_at
	man.set_meta("next_job_kind", "gather")
	man.set_meta("next_job_pos", bush_at)
	if not SettlementParty.park_field_gather(claim, man):
		_fail("bush gatherer was not parked")
		world.queue_free()
		return
	var hands_before := _hands_sum(man)
	SettlementParty.step_field_trips(claim, 10000.0, Vector2.INF, 1200.0)
	var after_pay := _pool_sum(ms, chunk)
	SettlementParty.step_field_trips(claim, 10000.0, Vector2.INF, 1200.0)
	var home_dist: float = man.global_position.distance_to(Vector2.ZERO)
	print("FIELD_BUSH_HAUL pool %d->%d hands %d->%d dist=%.0f dormant=%s" % [
		before, after_pay, hands_before, _hands_sum(man), home_dist, man.is_sim_dormant()
	])
	var ok := true
	if after_pay >= before:
		_fail("bush trip did not spend the chunk")
		ok = false
	if _hands_sum(man) <= hands_before:
		_fail("bush trip did not fill his hands")
		ok = false
	if _claim_sum(claim) != 0:
		_fail("bush trip paid the claim instead of the man")
		ok = false
	if man.is_sim_dormant() or home_dist > 1200.0 or home_dist < 900.0:
		_fail("bush gatherer did not wake on the circle")
		ok = false
	if ok:
		print("FIELD_BUSH_HAUL_PASS")
	world.queue_free()


func _test_bush_job_is_not_frozen_without_a_ticket() -> void:
	var ctrl: Node = root.get_node_or_null("SimDormancyController")
	if ctrl == null or not ctrl.has_method("apply"):
		_fail("dormancy controller missing")
		return
	var world := Node2D.new()
	root.add_child(world)
	var player := CharacterBody2D.new()
	player.add_to_group("player")
	world.add_child(player)
	player.global_position = Vector2.ZERO
	var stub := _MainStub.new()
	stub.player = player
	root.add_child(stub)
	stub.add_to_group("main")
	var scene: PackedScene = load("res://scenes/NPC.tscn") as PackedScene
	var man: Node = scene.instantiate()
	man.set("npc_type", "clansman")
	man.set("npc_name", "NOTICKET")
	world.add_child(man)
	for _i in 4:
		await process_frame
	man.global_position = Vector2(4000.0, 0.0)
	man.set_meta("next_job_kind", "gather")
	man.set_meta("next_job_pos", Vector2(4000.0, 0.0))
	ctrl.apply(stub)
	if man.has_method("is_sim_dormant") and man.is_sim_dormant():
		_fail("bush job with no camp was frozen")
	else:
		print("FIELD_NO_TICKET_PASS")
	stub.queue_free()
	world.queue_free()


class _MainStub extends Node:
	var player: Node = null


func _test_spent_look_does_not_spend_again() -> void:
	var ms: Node = root.get_node_or_null("MutationStore")
	var cfg: Node = root.get_node_or_null("WorldGenConfig")
	if ms == null or cfg == null:
		_fail("pool autoloads missing")
		return
	var chunk := Vector2i(4, 4)
	ms.call("ensure_abstract_resource_pool", chunk, int(cfg.get("world_seed")), cfg)
	ms.call("deplete_abstract_resource", chunk, "berries", 100000)
	var left := int(ms.call("get_abstract_resource_remaining", chunk, "berries"))
	var scene: PackedScene = load("res://scenes/GatherableResource.tscn") as PackedScene
	var bush: Node = scene.instantiate()
	bush.set("resource_type", ResourceData.ResourceType.BERRIES)
	root.add_child(bush)
	bush.set_meta("chunk_coords", chunk)
	for _i in 4:
		await process_frame
	if bush.has_method("show_spent_without_recording"):
		bush.show_spent_without_recording()
	var after := int(ms.call("get_abstract_resource_remaining", chunk, "berries"))
	var cooled := bush.has_method("is_in_cooldown_state") and bool(bush.is_in_cooldown_state())
	print("FIELD_BUSH left=%d after=%d cooled=%s" % [left, after, cooled])
	if not cooled or after != left:
		_fail("spent bush changed the pool or did not look used")
	else:
		print("FIELD_BUSH_PASS")
	bush.queue_free()


func _pool_sum(ms: Node, chunk: Vector2i) -> int:
	var total := 0
	for key in ["berries", "grain", "nuts", "bugs", "wood", "stone", "fiber"]:
		total += int(ms.call("get_abstract_resource_remaining", chunk, key))
	return total


func _hands_sum(man: Node) -> int:
	var inv: Variant = man.get("inventory")
	if inv == null or not inv.has_method("get_count"):
		return 0
	var total := 0
	for rt in [
		ResourceData.ResourceType.BERRIES,
		ResourceData.ResourceType.GRAIN,
		ResourceData.ResourceType.NUTS,
		ResourceData.ResourceType.BUGS,
		ResourceData.ResourceType.WOOD,
		ResourceData.ResourceType.STONE,
		ResourceData.ResourceType.FIBER,
	]:
		total += int(inv.get_count(rt))
	return total


func _claim_sum(claim: Node) -> int:
	var inv: Variant = claim.get("inventory")
	if inv == null:
		return 0
	var total := 0
	for rt in [
		ResourceData.ResourceType.BERRIES,
		ResourceData.ResourceType.GRAIN,
		ResourceData.ResourceType.NUTS,
		ResourceData.ResourceType.BUGS,
		ResourceData.ResourceType.WOOD,
		ResourceData.ResourceType.STONE,
		ResourceData.ResourceType.FIBER,
	]:
		total += int(inv.get_count(rt))
	return total


func _fail(msg: String) -> void:
	_failed += 1
	print("FIELD_TRIP_FAIL %s" % msg)
