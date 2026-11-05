extends SceneTree
## A player-camp clansman must walk a wild woman home and start her hut.
## Run: godot --headless --path . -s res://tools/test_clansman_brings_wife.gd -- --skip-single-instance

const FRAMES := 300

var _failed := 0


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	await process_frame
	var world := Node2D.new()
	world.name = "WifeWorld"
	world.add_to_group("main")
	root.add_child(world)
	var claim := LandClaim.new()
	claim.clan_name = "HUTW"
	claim.player_owned = true
	claim.position = Vector2.ZERO
	world.add_child(claim)
	var clan: String = str(claim.clan_name)
	var scene: PackedScene = load("res://scenes/NPC.tscn") as PackedScene
	var man_a: Node = _man(scene, world, "SONA", clan, Vector2(40.0, 0.0))
	var man_b: Node = _man(scene, world, "SONB", clan, Vector2(40.0, 40.0))
	var woman: Node = scene.instantiate()
	woman.set("npc_type", "woman")
	woman.set("npc_name", "WILDW")
	woman.set("traits", ["herd"])
	world.add_child(woman)
	if not woman.is_in_group("npcs"):
		woman.add_to_group("npcs")
	woman.global_position = Vector2(900.0, 0.0)
	for _i in 8:
		await process_frame
	var brain = claim.clan_brain
	if brain == null:
		_fail("claim has no clan brain")
		_finish()
		return
	if brain.has_method("_refresh_clan_members"):
		brain._refresh_clan_members()
	if brain.has_method("_update_searcher_assignments"):
		brain._update_searcher_assignments()
	var quota: int = int(claim.get_meta("searcher_quota", -1))
	var herder_cap: int = int(claim.get_meta("max_active_herders", -1))
	print("WIFE_QUOTA searcher=%d herders=%d fighters=%d brain_clan=%s" % [quota, herder_cap, brain.cavemen.size(), brain.clan_name])
	print("WIFE_MEN a=%s/%s group=%s b=%s/%s woman=%s" % [
		man_a.get("npc_type"), man_a.get_clan_name() if man_a.has_method("get_clan_name") else "?", man_a.is_in_group("npcs"),
		man_b.get("npc_type"), man_b.get_clan_name() if man_b.has_method("get_clan_name") else "?",
		woman.get("npc_type"),
	])
	if quota < 2 or herder_cap < 2:
		_fail("both sons are not allowed to search")
	for man in [man_a, man_b]:
		var fsm: Node = man.get("fsm")
		if fsm and fsm.has_method("_evaluate_states"):
			fsm._evaluate_states()
	var herder: Node = null
	for man in [man_a, man_b]:
		var fsm_m: Node = man.get("fsm")
		var st: String = str(fsm_m.get_current_state_name()) if fsm_m and fsm_m.has_method("get_current_state_name") else ""
		print("WIFE_STATE %s %s" % [man.get("npc_name"), st])
		if st == "herd_wildnpc":
			herder = man
	if herder == null:
		_fail("neither son entered herd_wildnpc with a wild woman nearby")
		_finish()
		return
	# Step into her influence the way a searcher does when he closes the last gap.
	herder.global_position = woman.global_position + Vector2(320.0, 0.0)
	await physics_frame
	herder.global_position = woman.global_position + Vector2(80.0, 0.0)
	var brought := false
	var area: Node = woman.get_node_or_null("HerdInfluenceArea")
	for _i in FRAMES:
		await physics_frame
		if bool(woman.get("is_herded")) and woman.get("herder") == herder:
			brought = true
			break
	if not brought:
		var watching: int = area.get("_herder_data").size() if area and "_herder_data" in area else -1
		var mon: bool = bool(area.get("monitoring")) if area else false
		var ticking: bool = area.is_physics_processing() if area else false
		_fail("son did not take the wild woman (herded=%s herder=%s area_watch=%d monitoring=%s physics=%s wild=%s)" % [
			woman.get("is_herded"), woman.get("herder"), watching, mon, ticking,
			woman.is_wild() if woman.has_method("is_wild") else "?",
		])
		_finish()
		return
	woman.global_position = claim.global_position + Vector2(40.0, 0.0)
	herder.global_position = claim.global_position + Vector2(20.0, 0.0)
	for _i in 30:
		await physics_frame
		if str(woman.get("clan_name")) != "":
			break
	var queued: bool = herder.has_meta("build_hut_queue") and (herder.get_meta("build_hut_queue") as Array).size() > 0
	var marked: bool = bool(herder.get_meta("wife_brought_home", false))
	var joined: bool = str(woman.get("clan_name")) == clan
	print("WIFE_HOME herder=%s joined=%s queued=%s marked=%s clan=%s" % [herder.get("npc_name"), joined, queued, marked, woman.get("clan_name")])
	if not joined or not queued or not marked:
		_fail("delivery did not start his hut")
	var other: Node = man_b if herder == man_a else man_a
	var herd_st: Node = other.get("fsm")._get_state("herd_wildnpc") if other.get("fsm") else null
	var other_can: bool = herd_st != null and herd_st.has_method("can_enter") and herd_st.can_enter()
	var done_st: Node = herder.get("fsm")._get_state("herd_wildnpc")
	var done_can: bool = done_st != null and done_st.can_enter()
	print("WIFE_NEXT other_can_search=%s delivered_can_search=%s" % [other_can, done_can])
	if not other_can:
		_fail("the other son was blocked from searching")
	if done_can:
		_fail("the son who already brought a wife can still search")
	if _failed == 0:
		print("WIFE_PASS")
	world.queue_free()
	_finish()


func _man(scene: PackedScene, world: Node, npc_name: String, clan: String, pos: Vector2) -> Node:
	var man: Node = scene.instantiate()
	man.set("npc_type", "clansman")
	man.set("npc_name", npc_name)
	world.add_child(man)
	if not man.is_in_group("npcs"):
		man.add_to_group("npcs")
	man.global_position = pos
	if man.has_method("set_clan_name"):
		man.set_clan_name(clan, "test_clansman_brings_wife")
	return man


func _fail(msg: String) -> void:
	_failed += 1
	print("WIFE_FAIL %s" % msg)


func _finish() -> void:
	print("WIFE_TEST failed=%d" % _failed)
	quit(0 if _failed == 0 else 1)
