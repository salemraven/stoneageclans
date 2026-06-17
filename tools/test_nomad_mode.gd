extends SceneTree
# Headless Nomad Mode tests
# SKIP_SINGLE_INSTANCE=1 godot --headless --path . --script res://tools/test_nomad_mode.gd

const NPC_SCENE := preload("res://scenes/NPC.tscn")
const STUB_MAIN_SCRIPT := preload("res://tools/nomad_test_stub_main.gd")
const PANIC_STATE_SCRIPT := preload("res://scripts/npc/states/panic_state.gd")

const CLAN := "TESTNOMAD"
const PHYS_DELTA := 1.0 / 60.0


func _init() -> void:
	call_deferred("_run")


func _fail(msg: String) -> void:
	push_error("TEST_NOMAD_MODE_FAIL: %s" % msg)


func _pass(label: String) -> void:
	print("  ok: %s" % label)


func _nomad_none() -> int:
	return 0


func _nomad_walking() -> int:
	return 2


func _make_campfire() -> Campfire:
	var scene := load("res://scenes/Campfire.tscn") as PackedScene
	if scene == null:
		return null
	return scene.instantiate() as Campfire


func _ensure_stub_main() -> Node:
	var existing := get_first_node_in_group("main")
	if existing:
		return existing
	var stub := Node.new()
	stub.name = "NomadTestStubMain"
	stub.set_script(STUB_MAIN_SCRIPT)
	root.add_child(stub)
	await process_frame
	return stub


func _world_parent(stub: Node) -> Node:
	var world := Node2D.new()
	world.name = "TestWorldObjects"
	stub.add_child(world)
	return world


func _run() -> void:
	for _i in 12:
		await process_frame

	var ok := true
	ok = _test_food_count_helper() and ok
	ok = _test_stone_despawn_removed() and ok
	ok = _test_nomad_state_enum() and ok
	ok = _test_building_orphan_grace() and ok
	ok = await _test_wood_depletion_extinguishes_fire() and ok
	ok = await _test_manual_fire_off_blocked() and ok
	ok = await _test_nomad_double_trigger_blocked() and ok
	ok = await _test_nomad_blocks_despawn_while_walking() and ok
	ok = await _test_nomad_collects_distant_clan_member() and ok
	ok = await _test_break_blocked_during_nomad() and ok
	ok = await _test_pregnancy_freeze_on_nomad_start() and ok
	ok = _test_panic_state_uses_set_speed_multiplier() and ok
	ok = await _test_panic_state_update_runtime() and ok

	if ok:
		print("All Nomad Mode tests passed")
		quit(0)
	else:
		quit(1)


func _test_food_count_helper() -> bool:
	var cf := _make_campfire()
	if cf == null:
		_fail("campfire create")
		return false
	cf.inventory = InventoryData.new(10, true, 999)
	cf.inventory.add_item(ResourceData.ResourceType.BERRIES, 2)
	cf.inventory.add_item(ResourceData.ResourceType.WOOD, 1)
	if cf.get_total_food_count() != 2 or not cf.has_panic_wood():
		_fail("food/wood count helper")
		cf.queue_free()
		return false
	cf.inventory.remove_item(ResourceData.ResourceType.WOOD, 1)
	if cf.has_panic_wood():
		cf.queue_free()
		_fail("expected wood depleted")
		return false
	cf.queue_free()
	_pass("food count helper")
	return true


func _test_stone_despawn_removed() -> bool:
	var src := load("res://scripts/campfire.gd") as GDScript
	if src == null:
		_fail("load campfire script")
		return false
	var text: String = src.source_code
	if text.contains("stone_count <= 0") or text.contains("total_items <= 0"):
		_fail("stone/empty inventory despawn still present")
		return false
	_pass("stone despawn removed")
	return true


func _test_nomad_state_enum() -> bool:
	if Campfire.NomadState.NONE != _nomad_none() or Campfire.NomadState.WALKING != _nomad_walking():
		_fail("NomadState enum values")
		return false
	_pass("NomadState enum")
	return true


func _test_building_orphan_grace() -> bool:
	var bb := BuildingBase.new()
	bb.building_type = ResourceData.ResourceType.LIVING_HUT
	bb.set_orphaned(true)
	if not bb.is_orphaned or bb.orphaned_at_game_time < 0.0:
		bb.queue_free()
		_fail("orphan grace fields")
		return false
	bb.set_orphaned(false)
	bb.queue_free()
	_pass("building orphan grace fields")
	return true


func _test_wood_depletion_extinguishes_fire() -> bool:
	var stub := await _ensure_stub_main()
	var world := _world_parent(stub)
	var cf := _make_campfire()
	if cf == null:
		world.queue_free()
		_fail("campfire create for wood test")
		return false
	cf.clan_name = CLAN
	cf.inventory = InventoryData.new(10, true, 999)
	cf.inventory.add_item(ResourceData.ResourceType.WOOD, 1)
	cf.inventory.add_item(ResourceData.ResourceType.BERRIES, 3)
	cf.is_fire_on = true
	world.add_child(cf)
	await process_frame
	# First burn interval consumes last wood; second interval extinguishes fire when wood=0.
	var burn: float = cf.get_wood_burn_interval()
	cf._wood_consume_timer = burn
	cf._process(1.0)
	cf._wood_consume_timer = burn
	cf._process(1.0)
	var succeeded: bool = (cf.is_fire_on == false and cf.get_wood_count() == 0)
	world.queue_free()
	if not succeeded:
		_fail("wood depletion should extinguish fire")
		return false
	_pass("wood depletion extinguishes fire")
	return true


func _test_manual_fire_off_blocked() -> bool:
	var stub := await _ensure_stub_main()
	var world := _world_parent(stub)
	var cf := _make_campfire()
	if cf == null:
		world.queue_free()
		_fail("campfire create for manual fire-off test")
		return false
	cf.clan_name = CLAN
	cf.inventory = InventoryData.new(10, true, 999)
	cf.inventory.add_item(ResourceData.ResourceType.WOOD, 5)
	cf.inventory.add_item(ResourceData.ResourceType.BERRIES, 3)
	world.add_child(cf)
	await process_frame
	cf.set_fire_on(true)
	cf.set_fire_on(false)
	var succeeded: bool = cf.is_fire_on == true
	world.queue_free()
	if not succeeded:
		_fail("manual fire-off should be blocked while wood remains")
		return false
	_pass("manual fire-off blocked")
	return true


func _test_nomad_double_trigger_blocked() -> bool:
	var stub := await _ensure_stub_main()
	var world := _world_parent(stub)
	var cf := _make_campfire()
	if cf == null:
		world.queue_free()
		_fail("campfire create for double trigger")
		return false
	cf.clan_name = CLAN
	cf.inventory = InventoryData.new(10, true, 999)
	world.add_child(cf)
	await process_frame
	cf.nomad_state = _nomad_walking()
	cf.begin_nomad_mode("player")
	var succeeded: bool = (cf.nomad_state == _nomad_walking())
	world.queue_free()
	if not succeeded:
		_fail("double nomad trigger should be blocked")
		return false
	_pass("double nomad trigger blocked")
	return true


func _test_nomad_blocks_despawn_while_walking() -> bool:
	var stub := await _ensure_stub_main()
	var world := _world_parent(stub)
	var cf := _make_campfire()
	if cf == null:
		world.queue_free()
		_fail("campfire create for despawn test")
		return false
	cf.clan_name = CLAN
	cf.nomad_state = _nomad_walking()
	cf.is_fire_on = false
	cf.set("_abandonment_timer", 999.0)
	world.add_child(cf)
	await process_frame
	cf._process(5.0)
	var succeeded: bool = is_instance_valid(cf)
	world.queue_free()
	if not succeeded:
		_fail("campfire should not despawn during nomad walk")
		return false
	_pass("nomad walk blocks abandonment despawn")
	return true


func _spawn_clansman(world: Node, clan: String, pos: Vector2, npc_name: String) -> NPCBase:
	var inst = NPC_SCENE.instantiate()
	var npc := inst as NPCBase
	if npc == null:
		return null
	npc.npc_type = "clansman"
	npc.npc_name = npc_name
	npc.clan_name = clan
	npc.set_meta("clan_name", clan)
	npc.global_position = pos
	npc.is_herded = false
	npc.herder = null
	npc.follow_is_ordered = false
	world.add_child(npc)
	return npc


func _test_nomad_collects_distant_clan_member() -> bool:
	var stub := await _ensure_stub_main()
	var world := _world_parent(stub)
	var cf := _make_campfire()
	if cf == null:
		world.queue_free()
		_fail("campfire create for collect test")
		return false
	cf.clan_name = CLAN
	cf.player_owned = true
	cf.global_position = Vector2(100, 100)
	cf.inventory = InventoryData.new(10, true, 999)
	world.add_child(cf)
	await process_frame

	var near_npc := _spawn_clansman(world, CLAN, Vector2(120, 120), "NearClansman")
	var far_npc := _spawn_clansman(world, CLAN, Vector2(5000, 5000), "FarClansman")
	if near_npc == null or far_npc == null:
		world.queue_free()
		_fail("failed to spawn test clansmen")
		return false
	await process_frame
	await process_frame

	cf.begin_nomad_mode("player")
	await process_frame

	var succeeded: bool = near_npc.follow_is_ordered and near_npc.herder != null
	succeeded = succeeded and far_npc.follow_is_ordered and far_npc.herder != null
	world.queue_free()
	if not succeeded:
		_fail("all clan members should follow after nomad start")
		return false
	_pass("nomad collects all clan members regardless of distance")
	return true


func _test_break_blocked_during_nomad() -> bool:
	var stub := await _ensure_stub_main()
	var world := _world_parent(stub)
	var player: Node = stub.player
	var dummy := _spawn_clansman(world, CLAN, Vector2(20, 0), "BreakTestClansman")
	if dummy == null:
		world.queue_free()
		_fail("dummy clansman spawn failed")
		return false
	stub._set_ordered_follow(dummy, "test_setup")
	await process_frame
	if stub._follower_cache.is_empty():
		world.queue_free()
		_fail("setup follower cache for break test")
		return false

	player.set_meta("nomad_state", _nomad_walking())
	player.set_meta("nomad_clan_name", CLAN)
	if not stub.is_player_in_nomad_mode():
		world.queue_free()
		_fail("is_player_in_nomad_mode should be true")
		return false

	var cache_before: int = stub._follower_cache.size()
	stub._break_and_dismiss_all()
	var cache_after: int = stub._follower_cache.size()
	var succeeded: bool = cache_after >= cache_before and dummy.follow_is_ordered
	player.remove_meta("nomad_state")
	player.remove_meta("nomad_clan_name")
	world.queue_free()
	if not succeeded:
		_fail("BREAK should not clear followers during nomad mode")
		return false
	_pass("BREAK blocked during nomad mode")
	return true


func _test_pregnancy_freeze_on_nomad_start() -> bool:
	var stub := await _ensure_stub_main()
	var world := _world_parent(stub)
	var cf := _make_campfire()
	if cf == null:
		world.queue_free()
		_fail("campfire create for pregnancy test")
		return false
	cf.clan_name = CLAN
	cf.inventory = InventoryData.new(10, true, 999)
	world.add_child(cf)

	var woman_inst = NPC_SCENE.instantiate()
	var woman := woman_inst as NPCBase
	if woman == null:
		world.queue_free()
		_fail("woman spawn failed")
		return false
	woman.npc_type = "woman"
	woman.npc_name = "TestWoman"
	woman.clan_name = CLAN
	woman.set_meta("clan_name", CLAN)
	world.add_child(woman)
	for _i in 6:
		await process_frame

	var repro = woman.get_node_or_null("ReproductionComponent")
	if repro == null:
		world.queue_free()
		woman.queue_free()
		_fail("ReproductionComponent missing on woman")
		return false
	repro.is_pregnant = true
	repro.birth_timer = 12.5

	cf.begin_nomad_mode("ai")
	await process_frame

	var succeeded: bool = woman.has_meta("nomad_pregnancy_frozen") and float(woman.get_meta("nomad_pregnancy_timer")) == 12.5
	world.queue_free()
	if not succeeded:
		_fail("pregnancy should freeze on nomad start")
		return false
	_pass("pregnancy frozen on nomad start")
	return true


func _test_panic_state_uses_set_speed_multiplier() -> bool:
	var src := load("res://scripts/npc/states/panic_state.gd") as GDScript
	if src == null:
		_fail("load panic_state script")
		return false
	var text: String = src.source_code
	if text.contains("steering_agent.speed_multiplier"):
		_fail("panic_state must not assign steering_agent.speed_multiplier property")
		return false
	if not text.contains("set_speed_multiplier"):
		_fail("panic_state missing set_speed_multiplier() call")
		return false
	_pass("panic_state uses set_speed_multiplier API")
	return true


func _test_panic_state_update_runtime() -> bool:
	var woman := NPC_SCENE.instantiate()
	if woman == null:
		_fail("panic runtime: NPC instantiate failed")
		return false
	woman.set("npc_type", "woman")
	woman.set("npc_name", "PanicTestW")
	if woman.has_method("set_clan_name"):
		woman.set_clan_name(CLAN, "panic_test")
	var world := Node2D.new()
	world.name = "PanicTestWorld"
	root.add_child(world)
	world.add_child(woman)
	woman.global_position = Vector2(100.0, 100.0)
	for _i in 6:
		await process_frame
	var panic_state: Object = PANIC_STATE_SCRIPT.new()
	if panic_state == null:
		world.queue_free()
		_fail("panic runtime: instantiate state")
		return false
	panic_state.set("npc", woman)
	panic_state.call("enter")
	panic_state.call("update", PHYS_DELTA)
	panic_state.call("update", PHYS_DELTA)
	panic_state.call("exit")
	world.queue_free()
	_pass("panic_state update runtime (no crash)")
	return true
