extends SceneTree
# Headless Clan Death → MutationStore tests
# SKIP_SINGLE_INSTANCE=1 godot --headless --path . --script res://tools/test_clan_death_mutation.gd

const CLAN := "TESTCLANDEATH"
const CLAN_B := "TESTCLANDEATHB"
const WORLD_POS := Vector2(512.0, 512.0)


func _init() -> void:
	call_deferred("_run")


func _fail(msg: String) -> void:
	push_error("TEST_CLAN_DEATH_FAIL: %s" % msg)


func _pass(label: String) -> void:
	print("  ok: %s" % label)


func _chunk_for_pos(pos: Vector2) -> Vector2i:
	var cu: Node = get_root().get_node_or_null("/root/ChunkUtils")
	if cu and cu.has_method("get_chunk_coords"):
		return cu.get_chunk_coords(pos)
	return Vector2i(floor(pos.x / 2048.0), floor(pos.y / 2048.0))


func _mutation_store() -> Node:
	return get_root().get_node_or_null("/root/MutationStore")


func _deaths_at(pos: Vector2) -> int:
	var ms := _mutation_store()
	if ms == null:
		return 0
	return int(ms.call("get_clan_deaths_in_chunk", _chunk_for_pos(pos)))


func _reset_clan(clan: String, pos: Vector2) -> void:
	var chunk := _chunk_for_pos(pos)
	var ms := _mutation_store()
	if ms and ms.has_method("reset_chunk"):
		ms.reset_chunk(chunk)
	LandClaim.clear_extinction_record_for_tests(clan)


func _make_claim(parent: Node, clan: String, pos: Vector2) -> LandClaim:
	var claim := LandClaim.new()
	claim.clan_name = clan
	parent.add_child(claim)
	claim.global_position = pos
	return claim


func _run() -> void:
	for _i in 8:
		await process_frame

	var ok := true
	ok = await _test_flag_destroy_records() and ok
	ok = await _test_soft_death_records() and ok
	ok = await _test_no_double_count_same_reason() and ok
	ok = await _test_soft_then_hard_once() and ok
	ok = await _test_separate_clans_separate_counts() and ok
	ok = await _test_chunk_death_cap_threshold() and ok

	if ok:
		print("All Clan Death MutationStore tests passed")
		quit(0)
	else:
		quit(1)


func _test_flag_destroy_records() -> bool:
	_reset_clan(CLAN, WORLD_POS)
	var world := Node2D.new()
	root.add_child(world)
	var claim := _make_claim(world, CLAN, WORLD_POS)
	await process_frame
	var before := _deaths_at(WORLD_POS)
	if not claim.try_record_clan_extinction("flag_destroyed"):
		world.queue_free()
		_fail("flag_destroyed should record first time")
		return false
	if _deaths_at(WORLD_POS) != before + 1:
		world.queue_free()
		_fail("flag_destroyed should increment chunk deaths")
		return false
	world.queue_free()
	_pass("flag_destroyed records MutationStore death")
	return true


func _test_soft_death_records() -> bool:
	_reset_clan(CLAN, WORLD_POS)
	var world := Node2D.new()
	root.add_child(world)
	var claim := _make_claim(world, CLAN, WORLD_POS)
	await process_frame
	var before := _deaths_at(WORLD_POS)
	if not claim.try_record_clan_extinction("soft_last_caveman"):
		world.queue_free()
		_fail("soft_last_caveman should record first time")
		return false
	if _deaths_at(WORLD_POS) != before + 1:
		world.queue_free()
		_fail("soft_last_caveman should increment chunk deaths")
		return false
	world.queue_free()
	_pass("soft_last_caveman records MutationStore death")
	return true


func _test_no_double_count_same_reason() -> bool:
	_reset_clan(CLAN, WORLD_POS)
	var world := Node2D.new()
	root.add_child(world)
	var claim := _make_claim(world, CLAN, WORLD_POS)
	await process_frame
	if not claim.try_record_clan_extinction("flag_destroyed"):
		world.queue_free()
		_fail("first record should succeed")
		return false
	var after_first := _deaths_at(WORLD_POS)
	if claim.try_record_clan_extinction("flag_destroyed"):
		world.queue_free()
		_fail("second record should be blocked")
		return false
	if _deaths_at(WORLD_POS) != after_first:
		world.queue_free()
		_fail("second record should not increment deaths")
		return false
	world.queue_free()
	_pass("duplicate extinction blocked for same clan")
	return true


func _test_soft_then_hard_once() -> bool:
	_reset_clan(CLAN, WORLD_POS)
	var world := Node2D.new()
	root.add_child(world)
	var claim := _make_claim(world, CLAN, WORLD_POS)
	await process_frame
	var before := _deaths_at(WORLD_POS)
	if not claim.try_record_clan_extinction("soft_last_caveman"):
		world.queue_free()
		_fail("soft path should record")
		return false
	if claim.try_record_clan_extinction("flag_destroyed"):
		world.queue_free()
		_fail("hard path after soft should not record again")
		return false
	if _deaths_at(WORLD_POS) != before + 1:
		world.queue_free()
		_fail("soft+hard should count once total")
		return false
	world.queue_free()
	_pass("soft then hard counts once")
	return true


func _test_separate_clans_separate_counts() -> bool:
	_reset_clan(CLAN, WORLD_POS)
	_reset_clan(CLAN_B, WORLD_POS)
	var world := Node2D.new()
	root.add_child(world)
	var claim_a := _make_claim(world, CLAN, WORLD_POS)
	var claim_b := _make_claim(world, CLAN_B, WORLD_POS + Vector2(64, 0))
	await process_frame
	var before := _deaths_at(WORLD_POS)
	if not claim_a.try_record_clan_extinction("flag_destroyed"):
		world.queue_free()
		_fail("clan A should record")
		return false
	if not claim_b.try_record_clan_extinction("flag_destroyed"):
		world.queue_free()
		_fail("clan B should record separately")
		return false
	if _deaths_at(WORLD_POS) != before + 2:
		world.queue_free()
		_fail("two clans same chunk should add two deaths")
		return false
	world.queue_free()
	_pass("separate clans increment separately")
	return true


func _test_chunk_death_cap_threshold() -> bool:
	var wgc: Node = get_root().get_node_or_null("/root/WorldGenConfig")
	var cap: int = 3
	if wgc and wgc.get("clan_max_deaths_per_chunk") != null:
		cap = int(wgc.clan_max_deaths_per_chunk)
	var pos := Vector2(9000.0, 9000.0)
	var chunk := _chunk_for_pos(pos)
	var ms := _mutation_store()
	if ms and ms.has_method("reset_chunk"):
		ms.reset_chunk(chunk)
	for i in cap:
		var clan_name := "CAPTEST%d" % i
		LandClaim.clear_extinction_record_for_tests(clan_name)
		var world := Node2D.new()
		root.add_child(world)
		var claim := _make_claim(world, clan_name, pos + Vector2(float(i), 0.0))
		await process_frame
		if not claim.try_record_clan_extinction("flag_destroyed"):
			world.queue_free()
			_fail("cap test record %d" % i)
			return false
		world.queue_free()
	var ms2 := _mutation_store()
	var deaths := int(ms2.call("get_clan_deaths_in_chunk", chunk)) if ms2 else 0
	if deaths < cap:
		_fail("expected deaths >= cap, got %d" % deaths)
		return false
	var exhausted: bool = deaths >= cap
	if not exhausted:
		_fail("chunk should be exhausted at cap")
		return false
	_pass("chunk death cap threshold reached at %d deaths" % cap)
	return true
