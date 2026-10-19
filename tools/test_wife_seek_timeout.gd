extends SceneTree
## Empty-hands wife chase ends on the clock even while a woman is still in sight.
## Run: godot --headless --path . -s res://tools/test_wife_seek_timeout.gd -- --skip-single-instance

var _failed := 0


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	await process_frame
	await _test_sighting_does_not_hold_the_chase()
	print("WIFE_SEEK_TIMEOUT_TEST failed=%d" % _failed)
	quit(0 if _failed == 0 else 1)


func _test_sighting_does_not_hold_the_chase() -> void:
	var scene: PackedScene = load("res://scenes/NPC.tscn") as PackedScene
	if scene == null:
		_fail("NPC scene missing")
		return
	var world := Node2D.new()
	root.add_child(world)
	var man: Node = scene.instantiate()
	man.set("npc_type", "clansman")
	man.set("npc_name", "SEEKER")
	man.set("herded_count", 0)
	world.add_child(man)
	man.global_position = Vector2.ZERO
	var woman: Node = scene.instantiate()
	woman.set("npc_type", "woman")
	woman.set("npc_name", "WIFE")
	world.add_child(woman)
	woman.global_position = Vector2(180, 0)
	for _i in 4:
		await process_frame
	var fsm: Node = man.get_node_or_null("FSM")
	if fsm == null or not fsm.has_method("_get_state"):
		_fail("FSM missing")
		return
	var herd: Node = fsm._get_state("herd_wildnpc")
	if herd == null:
		_fail("herd state missing")
		return
	var now: float = Time.get_ticks_msec() / 1000.0
	if herd.has_method("empty_hands_timed_out"):
		herd.no_target_time = now - 40.0
		herd.max_no_target_time = 7.0
		if not herd.empty_hands_timed_out(now, 30.0, 5.0, 0):
			_fail("empty hands should time out while a woman is still the seek target")
		if herd.empty_hands_timed_out(now, 30.0, 5.0, 1):
			_fail("an attached follower must not trip the empty-hands clock")
	if fsm.has_method("change_state"):
		fsm.change_state("herd_wildnpc")
	herd.search_start_time = now - 40.0
	herd.no_target_time = now - 40.0
	herd.max_no_target_time = 7.0
	man.set("herded_count", 0)
	if herd.has_method("update"):
		herd.update(0.1)
	var state_name := ""
	if fsm.has_method("get_current_state_name"):
		state_name = str(fsm.get_current_state_name())
	if state_name == "herd_wildnpc":
		_fail("chase stayed in herd_wildnpc after the empty-hands timeout")
	man.set("herded_count", 1)
	if fsm.has_method("change_state"):
		fsm.change_state("herd_wildnpc")
	herd.search_start_time = now - 40.0
	herd.no_target_time = now - 40.0
	if herd.has_method("update"):
		herd.update(0.1)
	if fsm.has_method("get_current_state_name"):
		state_name = str(fsm.get_current_state_name())
	if state_name != "herd_wildnpc":
		_fail("attached herd left herd_wildnpc, state=%s" % state_name)


func _fail(msg: String) -> void:
	_failed += 1
	push_error("WIFE_SEEK_TIMEOUT_TEST: %s" % msg)
