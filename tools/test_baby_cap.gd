extends SceneTree
# Headless Dynamic Baby Cap tests
# SKIP_SINGLE_INSTANCE=1 godot --headless --path . --script res://tools/test_baby_cap.gd

const NPC_SCENE := preload("res://scenes/NPC.tscn")
const STUB_MAIN := preload("res://tools/baby_cap_test_stub_main.gd")

const CLAN := "TESTBABYCAP"
const PHYS_DELTA := 1.0 / 60.0


func _init() -> void:
	call_deferred("_run")


func _fail(msg: String) -> void:
	push_error("TEST_BABY_CAP_FAIL: %s" % msg)


func _pass(label: String) -> void:
	print("  ok: %s" % label)


func _ensure_stub_main() -> Node:
	var existing := get_first_node_in_group("main")
	if existing:
		return existing
	var stub := STUB_MAIN.new()
	stub.name = "BabyCapTestStubMain"
	root.add_child(stub)
	await process_frame
	return stub


func _spawn_baby_npc(parent: Node, clan: String, name_suffix: String = "") -> NPCBase:
	var inst = NPC_SCENE.instantiate()
	var baby := inst as NPCBase
	if baby == null:
		return null
	baby.npc_type = "baby"
	baby.npc_name = "TestBaby%s" % name_suffix
	baby.clan_name = clan
	parent.add_child(baby)
	await process_frame
	return baby


func _spawn_woman(parent: Node, clan: String = CLAN) -> NPCBase:
	var inst = NPC_SCENE.instantiate()
	var woman := inst as NPCBase
	if woman == null:
		return null
	woman.npc_type = "woman"
	woman.npc_name = "TestWoman"
	woman.clan_name = clan
	parent.add_child(woman)
	for _i in 4:
		await process_frame
	return woman


func _make_land_claim(parent: Node, clan: String) -> Node2D:
	var scene := load("res://scenes/LandClaim.tscn") as PackedScene
	if scene == null:
		return null
	var claim := scene.instantiate() as Node2D
	if claim == null:
		return null
	claim.set("clan_name", clan)
	claim.global_position = Vector2.ZERO
	claim.set_meta("calories_days_buffer", 1.0)
	claim.add_to_group("land_claims")
	parent.add_child(claim)
	await process_frame
	return claim


func _run() -> void:
	for _i in 12:
		await process_frame

	var ok := true
	ok = await _test_capacity_enforce_off() and ok
	ok = await _test_capacity_enforce_on() and ok
	ok = await _test_living_hut_bonus() and ok
	ok = await _test_fertility_stub_bonus() and ok
	ok = await _test_become_wild_cancels() and ok
	ok = await _test_starvation_cancel() and ok
	ok = await _test_cap_does_not_block_birth() and ok
	ok = await _test_nomad_freeze_not_cancel() and ok
	ok = await _test_wild_cannot_conceive() and ok

	if ok:
		print("All Baby Cap tests passed")
		quit(0)
	else:
		quit(1)


func _test_capacity_enforce_off() -> bool:
	var stub := await _ensure_stub_main()
	var pool: BabyPoolManager = stub.get_baby_pool_manager()
	pool.config.enforce_baby_cap = false
	var world := Node2D.new()
	stub.add_child(world)
	for i in 4:
		var b := await _spawn_baby_npc(world, CLAN, str(i))
		if b == null:
			world.queue_free()
			_fail("spawn baby for enforce off")
			return false
	if not pool.has_baby_room(CLAN):
		world.queue_free()
		_fail("enforce off should always have room")
		return false
	world.queue_free()
	_pass("enforce off allows room beyond capacity")
	return true


func _test_capacity_enforce_on() -> bool:
	var stub := await _ensure_stub_main()
	var pool: BabyPoolManager = stub.get_baby_pool_manager()
	pool.config.enforce_baby_cap = true
	pool.config.baby_pool_base_capacity = 3
	var world := Node2D.new()
	stub.add_child(world)
	for i in 3:
		var b := await _spawn_baby_npc(world, CLAN, "cap%d" % i)
		if b == null:
			world.queue_free()
			_fail("spawn baby for enforce on")
			return false
	if pool.has_baby_room(CLAN):
		world.queue_free()
		_fail("enforce on: expected no room at base cap")
		return false
	var bd: Dictionary = pool.get_capacity_breakdown(CLAN)
	if int(bd.get("current", 0)) != 3 or int(bd.get("total", 0)) != 3:
		world.queue_free()
		_fail("breakdown current/total mismatch")
		return false
	world.queue_free()
	_pass("enforce on blocks at base cap")
	return true


func _add_fake_hut(world: Node, woman: Node, clan: String) -> BuildingBase:
	var hut := BuildingBase.new()
	hut.name = "FakeLivingHut"
	hut.building_type = ResourceData.ResourceType.LIVING_HUT
	hut.clan_name = clan
	hut.add_to_group("buildings")
	world.add_child(hut)
	if woman:
		woman.set_meta("home_living_hut", hut)
	return hut


func _test_living_hut_bonus() -> bool:
	var stub := await _ensure_stub_main()
	var pool: BabyPoolManager = stub.get_baby_pool_manager()
	pool.config.enforce_baby_cap = true
	pool.config.baby_pool_base_capacity = 3
	pool.config.living_hut_capacity_bonus = 5
	var world := Node2D.new()
	stub.add_child(world)
	var dummy := Node2D.new()
	world.add_child(dummy)
	_add_fake_hut(world, dummy, CLAN)
	await process_frame
	pool.refresh_clan_modifiers(CLAN)
	if pool.get_effective_capacity(CLAN) != 8:
		world.queue_free()
		_fail("living hut should add +5 capacity")
		return false
	world.queue_free()
	_pass("living hut capacity bonus")
	return true


func _test_fertility_stub_bonus() -> bool:
	var stub := await _ensure_stub_main()
	var pool: BabyPoolManager = stub.get_baby_pool_manager()
	pool.config.baby_pool_base_capacity = 3
	var world := Node2D.new()
	stub.add_child(world)
	var woman := await _spawn_woman(world, CLAN)
	if woman == null:
		world.queue_free()
		_fail("spawn woman for fertility")
		return false
	woman.set_meta(&"baby_cap_bonus", 2)
	if pool.get_effective_capacity(CLAN) != 5:
		world.queue_free()
		_fail("fertility stub should add +2")
		return false
	world.queue_free()
	_pass("fertility stub baby_cap_bonus")
	return true


func _test_become_wild_cancels() -> bool:
	var world := Node2D.new()
	root.add_child(world)
	var woman := await _spawn_woman(world, CLAN)
	if woman == null:
		world.queue_free()
		_fail("woman spawn for wild cancel")
		return false
	var repro = woman.get_node_or_null("ReproductionComponent")
	if repro == null:
		world.queue_free()
		_fail("missing ReproductionComponent")
		return false
	repro.is_pregnant = true
	repro.birth_timer = 10.0
	woman.become_wild()
	if repro.is_pregnant:
		world.queue_free()
		_fail("become_wild should cancel pregnancy")
		return false
	if woman.clan_name != "":
		world.queue_free()
		_fail("become_wild should clear clan")
		return false
	world.queue_free()
	_pass("become_wild cancels pregnancy")
	return true


func _test_starvation_cancel() -> bool:
	var stub := await _ensure_stub_main()
	var world := Node2D.new()
	stub.add_child(world)
	var claim := await _make_land_claim(world, CLAN)
	if claim == null:
		world.queue_free()
		_fail("land claim for starvation test")
		return false
	claim.set_meta("calories_days_buffer", 0.01)
	var woman := await _spawn_woman(world, CLAN)
	if woman == null:
		world.queue_free()
		_fail("woman for starvation")
		return false
	woman.global_position = Vector2.ZERO
	_add_fake_hut(world, woman, CLAN)
	var repro = woman.get_node_or_null("ReproductionComponent")
	if repro == null:
		world.queue_free()
		_fail("ReproductionComponent missing")
		return false
	repro.config = ReproductionConfig.new()
	repro.config.pregnancy_cancel_food_buffer_days = 0.28
	repro.is_pregnant = true
	repro.birth_timer = 5.0
	repro.call("_update_birth_timer", PHYS_DELTA)
	if repro.is_pregnant:
		world.queue_free()
		_fail("starvation should cancel pregnancy")
		return false
	world.queue_free()
	_pass("starvation cancels pregnancy")
	return true


func _test_cap_does_not_block_birth() -> bool:
	var stub := await _ensure_stub_main()
	var pool: BabyPoolManager = stub.get_baby_pool_manager()
	pool.config.enforce_baby_cap = true
	pool.config.baby_pool_base_capacity = 1
	var world := Node2D.new()
	stub.add_child(world)
	await _spawn_baby_npc(world, CLAN, "full")
	var woman := await _spawn_woman(world, CLAN)
	if woman == null:
		world.queue_free()
		_fail("woman for cap birth test")
		return false
	var repro = woman.get_node_or_null("ReproductionComponent")
	if repro == null:
		world.queue_free()
		_fail("ReproductionComponent missing")
		return false
	if repro._has_baby_room_for_conception():
		world.queue_free()
		_fail("conception should be blocked when cap full")
		return false
	var claim := await _make_land_claim(world, CLAN)
	if claim:
		claim.set_meta("calories_days_buffer", 2.0)
	woman.global_position = Vector2.ZERO
	_add_fake_hut(world, woman, CLAN)
	repro.config = ReproductionConfig.new()
	repro.is_pregnant = true
	repro.birth_timer = 0.01
	stub.spawn_calls = 0
	repro.call("_update_birth_timer", 0.02)
	if repro.is_pregnant:
		world.queue_free()
		_fail("birth timer should complete despite cap full")
		return false
	if stub.spawn_calls < 1:
		world.queue_free()
		_fail("main._spawn_baby should be called when cap full but pregnancy due")
		return false
	world.queue_free()
	_pass("cap blocks conception not birth")
	return true


func _test_nomad_freeze_not_cancel() -> bool:
	var world := Node2D.new()
	root.add_child(world)
	var woman := await _spawn_woman(world, CLAN)
	if woman == null:
		world.queue_free()
		_fail("woman for nomad freeze")
		return false
	var repro = woman.get_node_or_null("ReproductionComponent")
	if repro == null:
		world.queue_free()
		_fail("ReproductionComponent missing")
		return false
	repro.is_pregnant = true
	repro.birth_timer = 12.5
	woman.set_meta("nomad_pregnancy_frozen", true)
	woman.set_meta("nomad_pregnancy_timer", 12.5)
	var before: float = repro.birth_timer
	repro.call("_update_birth_timer", 1.0)
	if not repro.is_pregnant:
		world.queue_free()
		_fail("nomad freeze must not cancel pregnancy")
		return false
	if repro.birth_timer != before:
		world.queue_free()
		_fail("nomad freeze should pause timer")
		return false
	Campfire.resume_clan_after_nomad(CLAN, self)
	await process_frame
	if not repro.is_pregnant or absf(repro.birth_timer - 12.5) > 0.001:
		world.queue_free()
		_fail("nomad resume should restore pregnancy timer")
		return false
	world.queue_free()
	_pass("nomad freeze pauses; resume restores")
	return true


func _test_wild_cannot_conceive() -> bool:
	var world := Node2D.new()
	root.add_child(world)
	var woman := await _spawn_woman(world, "")
	if woman == null:
		world.queue_free()
		_fail("wild woman spawn")
		return false
	woman.clan_name = ""
	var repro = woman.get_node_or_null("ReproductionComponent")
	if repro == null:
		world.queue_free()
		_fail("ReproductionComponent missing")
		return false
	if repro._has_baby_room_for_conception():
		world.queue_free()
		_fail("wild woman should not have baby room for conception")
		return false
	if repro.can_hold_pregnancy():
		world.queue_free()
		_fail("wild woman cannot hold pregnancy")
		return false
	world.queue_free()
	_pass("wild woman blocked from conception")
	return true
