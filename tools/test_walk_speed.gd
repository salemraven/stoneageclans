extends SceneTree
## A refreshed walk must not wipe speed every frame.
## Run: godot --headless --path . -s res://tools/test_walk_speed.gd -- --skip-single-instance

var _failed := 0


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	await process_frame
	await _test_deposit_keeps_speed()
	await _test_break_return_keeps_speed()
	await _test_herder_keeps_speed()
	await _test_deer_keeps_speed()
	print("WALK_SPEED_TEST failed=%d" % _failed)
	quit(0 if _failed == 0 else 1)


func _test_deposit_keeps_speed() -> void:
	var built := await _clansman_near_claim("DEPO", Vector2(420.0, 0.0))
	if built.is_empty():
		return
	var man: Node = built["man"]
	var world: Node = built["world"]
	man.set_meta("moving_to_deposit", true)
	man.set_meta("is_depositing", true)
	var hands: Variant = man.get("inventory")
	if hands and hands.has_method("add_item"):
		hands.add_item(ResourceData.ResourceType.WOOD, 3)
	var wander := _state(man, "wander")
	if wander == null:
		_fail("deposit has no wander")
		world.queue_free()
		return
	man.velocity = Vector2(-90.0, 0.0)
	for _i in 8:
		wander.update(0.05)
	var kept: float = man.velocity.length()
	var start: Vector2 = man.global_position
	for _i in 45:
		await physics_frame
	var moved: float = man.global_position.distance_to(start)
	print("WALK_DEPOSIT kept=%.1f moved=%.1f" % [kept, moved])
	var ok := true
	if kept < 50.0:
		_fail("deposit walk cleared his speed")
		ok = false
	if moved < 25.0:
		_fail("deposit walk did not carry him home")
		ok = false
	if ok:
		print("WALK_DEPOSIT_PASS")
	world.queue_free()


func _test_break_return_keeps_speed() -> void:
	var built := await _clansman_near_claim("BREAK", Vector2(400.0, 40.0))
	if built.is_empty():
		return
	var man: Node = built["man"]
	var world: Node = built["world"]
	man.set_meta("returning_from_break", true)
	man.set_meta("returning_from_break_expire", 100000.0)
	var wander := _state(man, "wander")
	if wander == null:
		_fail("break return has no wander")
		world.queue_free()
		return
	man.velocity = Vector2(-90.0, 0.0)
	for _i in 8:
		wander.update(0.05)
	var kept: float = man.velocity.length()
	print("WALK_BREAK kept=%.1f" % kept)
	if kept < 50.0:
		_fail("break return cleared his speed")
	else:
		print("WALK_BREAK_PASS")
	world.queue_free()


func _test_herder_keeps_speed() -> void:
	var hm: Node = root.get_node_or_null("HerdManager")
	if hm == null or not hm.has_method("try_transfer"):
		_fail("HerdManager missing")
		return
	var built := await _clansman_near_claim("HERD", Vector2(1800.0, 0.0))
	if built.is_empty():
		return
	var man: Node = built["man"]
	var world: Node = built["world"]
	var scene: PackedScene = load("res://scenes/NPC.tscn") as PackedScene
	var woman: Node = scene.instantiate()
	woman.set("npc_type", "woman")
	woman.set("npc_name", "LAG")
	woman.set("traits", ["herd"])
	world.add_child(woman)
	woman.global_position = Vector2(1600.0, 0.0)
	for _i in 4:
		await process_frame
	if not hm.try_transfer(woman, man):
		_fail("could not attach the lagging woman")
		world.queue_free()
		return
	woman.global_position = Vector2(1600.0, 0.0)
	man.global_position = Vector2(1800.0, 0.0)
	man.set_meta("herd_leading_home", false)
	var herd := _state(man, "herd_wildnpc")
	if herd == null:
		_fail("herder has no herd state")
		world.queue_free()
		return
	man.velocity = Vector2(-80.0, 0.0)
	herd.update(0.05)
	herd.update(0.05)
	var kept: float = man.velocity.length()
	print("WALK_HERD kept=%.1f" % kept)
	if kept < 40.0:
		_fail("turning back for her cleared his speed")
	else:
		print("WALK_HERD_PASS")
	world.queue_free()


func _test_deer_keeps_speed() -> void:
	var world := Node2D.new()
	world.name = "DeerWorld"
	root.add_child(world)
	var scene: PackedScene = load("res://scenes/NPC.tscn") as PackedScene
	var deer: Node = scene.instantiate()
	deer.set("npc_type", "deer")
	deer.set("npc_name", "BOLT")
	world.add_child(deer)
	deer.global_position = Vector2(500.0, 200.0)
	for _i in 6:
		await process_frame
	var flee := _state(deer, "flee_prey")
	if flee == null or not flee.has_method("_apply_run_steering"):
		_fail("deer has no flee")
		world.queue_free()
		return
	deer.velocity = Vector2(85.0, 0.0)
	flee._apply_run_steering(deer.global_position + Vector2(-200.0, 0.0))
	flee._apply_run_steering(deer.global_position + Vector2(-200.0, 0.0))
	var kept: float = deer.velocity.length()
	print("WALK_DEER kept=%.1f" % kept)
	if kept < 50.0:
		_fail("deer flee cleared his speed")
	else:
		print("WALK_DEER_PASS")
	world.queue_free()


func _clansman_near_claim(npc_name: String, pos: Vector2) -> Dictionary:
	var world := Node2D.new()
	world.name = "WalkWorld" + npc_name
	root.add_child(world)
	var claim := LandClaim.new()
	claim.clan_name = "TEST"
	claim.player_owned = true
	world.add_child(claim)
	claim.global_position = Vector2.ZERO
	var scene: PackedScene = load("res://scenes/NPC.tscn") as PackedScene
	var man: Node = scene.instantiate()
	man.set("npc_type", "clansman")
	man.set("npc_name", npc_name)
	world.add_child(man)
	if man.has_method("set_clan_name"):
		man.set_clan_name("TEST", "walk_speed")
	for _i in 8:
		await process_frame
	man.global_position = pos
	var fsm: Node = man.get("fsm")
	if fsm and fsm.has_method("change_state"):
		fsm.change_state("wander")
		fsm.set("evaluation_interval", 1000.0)
	return {"man": man, "world": world}


func _state(npc: Node, state_name: String) -> Node:
	var fsm: Node = npc.get("fsm")
	if fsm and fsm.has_method("_get_state"):
		return fsm._get_state(state_name)
	return null


func _fail(msg: String) -> void:
	_failed += 1
	print("WALK_SPEED_FAIL %s" % msg)
