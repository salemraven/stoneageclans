extends SceneTree
## Same-herder recapture must not reset influence, and a woman on the hut mark
## with a leftover stack must deposit and hold instead of seeking in place.
## Run: godot --headless --path . -s res://tools/test_zaif_settle.gd -- --skip-single-instance

var _failed := 0


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	await process_frame
	_test_same_herder_is_not_a_new_catch()
	await _test_outer_band_does_not_catch()
	await _test_brother_does_not_steal()
	await _test_leash_needs_a_moment()
	await _test_leader_waits_inside_band()
	await _test_influence_does_not_reaward()
	await _test_woman_on_hut_mark_deposits_and_holds()
	print("ZAIF_SETTLE_TEST failed=%d" % _failed)
	quit(0 if _failed == 0 else 1)


func _test_same_herder_is_not_a_new_catch() -> void:
	var hm: Node = root.get_node_or_null("HerdManager")
	if hm == null or not hm.has_method("try_transfer"):
		_fail("HerdManager missing")
		return
	var woman := Node2D.new()
	woman.set("npc_type", "woman")
	woman.set("is_herded", true)
	var man := Node2D.new()
	woman.set("herder", man)
	root.add_child(woman)
	root.add_child(man)
	if hm.try_transfer(woman, man):
		_fail("already-following herder was treated as a new catch")
	else:
		print("ZAIF_SAME_HERDER_PASS")
	woman.queue_free()
	man.queue_free()


func _test_outer_band_does_not_catch() -> void:
	var world := Node2D.new()
	world.name = "ZaifOuterWorld"
	world.add_to_group("main")
	root.add_child(world)
	var scene: PackedScene = load("res://scenes/NPC.tscn") as PackedScene
	var woman: Node = scene.instantiate()
	woman.set("npc_type", "woman")
	woman.set("npc_name", "OUTER")
	woman.set("traits", ["herd"])
	world.add_child(woman)
	if not woman.is_in_group("npcs"):
		woman.add_to_group("npcs")
	woman.global_position = Vector2(400.0, 0.0)
	var man: Node = scene.instantiate()
	man.set("npc_type", "clansman")
	man.set("npc_name", "EDGE")
	world.add_child(man)
	if not man.is_in_group("npcs"):
		man.add_to_group("npcs")
	if man.has_method("set_clan_name"):
		man.set_clan_name("TEST", "zaif_settle")
	for _i in 8:
		await process_frame
	man.global_position = woman.global_position + Vector2(305.0, 0.0)
	var caught_outside := false
	for _i in 45:
		await physics_frame
		man.global_position = woman.global_position + Vector2(305.0, 0.0)
		if bool(woman.get("is_herded")):
			caught_outside = true
			break
	if caught_outside:
		_fail("caught her past the follow leash")
	else:
		print("ZAIF_OUTER_HOLD_PASS")
	man.global_position = woman.global_position + Vector2(200.0, 0.0)
	var caught_at_200 := false
	for _i in 30:
		await physics_frame
		man.global_position = woman.global_position + Vector2(200.0, 0.0)
		if bool(woman.get("is_herded")):
			caught_at_200 = true
			break
	if caught_at_200:
		_fail("caught her outside the follow band")
	else:
		print("ZAIF_BAND_EDGE_PASS")
	man.global_position = woman.global_position + Vector2(120.0, 0.0)
	var held := false
	var dropped := false
	for _i in 90:
		await physics_frame
		man.global_position = woman.global_position + Vector2(120.0, 0.0)
		if bool(woman.get("is_herded")) and woman.get("herder") == man:
			held = true
			var fsm: Node = woman.get("fsm")
			var state := ""
			if fsm and fsm.has_method("get_current_state_name"):
				state = str(fsm.get_current_state_name())
			if state == "herd":
				for _j in 20:
					await physics_frame
					man.global_position = woman.global_position + Vector2(120.0, 0.0)
					var st := ""
					if fsm.has_method("get_current_state_name"):
						st = str(fsm.get_current_state_name())
					if st != "herd" or woman.get("herder") != man:
						dropped = true
						break
				break
	if not held:
		_fail("did not catch her once he was inside the follow band")
	elif dropped:
		_fail("follow dropped while he was inside the follow band")
	else:
		print("ZAIF_INNER_HOLD_PASS")
	world.queue_free()


func _test_brother_does_not_steal() -> void:
	var world := _herd_world("BrotherWorld")
	var scene: PackedScene = load("res://scenes/NPC.tscn") as PackedScene
	var woman := _wild_woman(scene, world, "BRIDE", Vector2(500.0, 0.0))
	var first := _clansman(scene, world, "FIRST", Vector2(580.0, 0.0))
	var brother := _clansman(scene, world, "SECOND", Vector2(900.0, 0.0))
	for _i in 8:
		await process_frame
	var attached := false
	for _i in 90:
		await physics_frame
		first.global_position = woman.global_position + Vector2(80.0, 0.0)
		brother.global_position = woman.global_position + Vector2(800.0, 0.0)
		if woman.get("herder") == first:
			attached = true
			break
	var stole := false
	if attached:
		for _i in 90:
			await physics_frame
			first.global_position = woman.global_position + Vector2(80.0, 0.0)
			brother.global_position = woman.global_position + Vector2(40.0, 0.0)
			if woman.get("herder") == brother:
				stole = true
				break
	if not attached:
		_fail("first clansman never caught her")
	elif stole:
		_fail("same-clan brother took her")
	else:
		print("ZAIF_BROTHER_PASS")
	world.queue_free()


func _test_leash_needs_a_moment() -> void:
	var world := _herd_world("LeashWorld")
	var scene: PackedScene = load("res://scenes/NPC.tscn") as PackedScene
	var woman := _wild_woman(scene, world, "LEASH", Vector2(300.0, 0.0))
	var man := _clansman(scene, world, "LEAD", Vector2(380.0, 0.0))
	for _i in 8:
		await process_frame
	var caught := false
	for _i in 90:
		await physics_frame
		man.global_position = woman.global_position + Vector2(80.0, 0.0)
		if woman.get("herder") == man:
			caught = true
			break
	if not caught:
		_fail("leash setup never attached")
		world.queue_free()
		return
	var snapped_early := false
	for _i in 20:
		await physics_frame
		man.global_position = woman.global_position + Vector2(320.0, 0.0)
		if woman.get("herder") != man:
			snapped_early = true
			break
	if snapped_early:
		_fail("leash snapped in one moment")
	else:
		print("ZAIF_LEASH_GRACE_PASS")
	var snapped := false
	for _i in 50:
		await physics_frame
		man.global_position = woman.global_position + Vector2(320.0, 0.0)
		if woman.get("herder") != man:
			snapped = true
			break
	if not snapped:
		_fail("leash never snapped after it stayed open")
	else:
		print("ZAIF_LEASH_SNAP_PASS")
	world.queue_free()


func _test_leader_waits_inside_band() -> void:
	var world := _herd_world("WaitWorld")
	var claim := LandClaim.new()
	claim.clan_name = "TEST"
	claim.player_owned = true
	world.add_child(claim)
	claim.global_position = Vector2.ZERO
	var scene: PackedScene = load("res://scenes/NPC.tscn") as PackedScene
	var woman := _wild_woman(scene, world, "WAITW", Vector2(1400.0, 0.0))
	var man := _clansman(scene, world, "WAITM", Vector2(1540.0, 0.0))
	for _i in 8:
		await process_frame
	var caught := false
	for _i in 90:
		await physics_frame
		man.global_position = woman.global_position + Vector2(140.0, 0.0)
		woman.global_position = Vector2(1400.0, 0.0)
		if woman.get("herder") == man:
			caught = true
			break
	if not caught:
		_fail("leader wait setup never attached")
		world.queue_free()
		return
	woman.global_position = Vector2(1400.0, 0.0)
	man.global_position = woman.global_position + Vector2(140.0, 0.0)
	man.set_meta("herd_leading_home", false)
	var aimed_home := false
	var herd_state: Node = null
	var fsm: Node = man.get("fsm")
	if fsm and fsm.get("states") is Dictionary:
		herd_state = (fsm.get("states") as Dictionary).get("herd_wildnpc")
	if herd_state and herd_state.has_method("update"):
		herd_state.update(0.05)
		var steer: Node = man.get("steering_agent")
		if steer and steer.target_position.distance_to(claim.global_position) < 200.0:
			aimed_home = true
	else:
		_fail("man has no herd_wildnpc state")
	if aimed_home:
		_fail("he headed home before she was in the follow band")
	else:
		print("ZAIF_LEADER_WAIT_PASS")
	world.queue_free()


func _herd_world(world_name: String) -> Node2D:
	var world := Node2D.new()
	world.name = world_name
	world.add_to_group("main")
	root.add_child(world)
	return world


func _wild_woman(scene: PackedScene, world: Node, npc_name: String, pos: Vector2) -> Node:
	var woman: Node = scene.instantiate()
	woman.set("npc_type", "woman")
	woman.set("npc_name", npc_name)
	woman.set("traits", ["herd"])
	world.add_child(woman)
	if not woman.is_in_group("npcs"):
		woman.add_to_group("npcs")
	woman.global_position = pos
	return woman


func _clansman(scene: PackedScene, world: Node, npc_name: String, pos: Vector2) -> Node:
	var man: Node = scene.instantiate()
	man.set("npc_type", "clansman")
	man.set("npc_name", npc_name)
	world.add_child(man)
	if not man.is_in_group("npcs"):
		man.add_to_group("npcs")
	if man.has_method("set_clan_name"):
		man.set_clan_name("TEST", "zaif_settle")
	man.global_position = pos
	return man


func _test_influence_does_not_reaward() -> void:
	var world := Node2D.new()
	world.name = "ZaifHerdWorld"
	world.add_to_group("main")
	root.add_child(world)
	var scene: PackedScene = load("res://scenes/NPC.tscn") as PackedScene
	var woman: Node = scene.instantiate()
	woman.set("npc_type", "woman")
	woman.set("npc_name", "ZAIF")
	woman.set("traits", ["herd"])
	world.add_child(woman)
	if not woman.is_in_group("npcs"):
		woman.add_to_group("npcs")
	woman.global_position = Vector2(900.0, 0.0)
	var man: Node = scene.instantiate()
	man.set("npc_type", "clansman")
	man.set("npc_name", "MIUN")
	world.add_child(man)
	if man.has_method("set_clan_name"):
		man.set_clan_name("TEST", "zaif_settle")
	man.global_position = woman.global_position + Vector2(320.0, 0.0)
	for _i in 8:
		await process_frame
	man.global_position = woman.global_position + Vector2(80.0, 0.0)
	var herded := false
	for _i in 180:
		await physics_frame
		if bool(woman.get("is_herded")) and woman.get("herder") == man:
			herded = true
			break
	if not herded:
		_fail("woman never attached to the clansman")
		world.queue_free()
		return
	var area: Node = woman.get_node_or_null("HerdInfluenceArea")
	var recovered := false
	var reset_after_recover := false
	for _i in 150:
		await physics_frame
		man.global_position = woman.global_position + Vector2(80.0, 0.0)
		var influence := _herder_influence(area, man)
		if influence > 40.0:
			recovered = true
		elif recovered and influence < 1.0:
			reset_after_recover = true
			break
	if not recovered:
		_fail("influence never climbed back after the first catch")
	elif reset_after_recover:
		_fail("influence reset while she was already following him")
	else:
		print("ZAIF_INFLUENCE_PASS")
	world.queue_free()


func _herder_influence(area: Node, herder: Node) -> float:
	if area == null:
		return -1.0
	var data: Variant = area.get("_herder_data")
	if data is Dictionary:
		var row: Variant = (data as Dictionary).get(herder.get_instance_id())
		if row is Dictionary:
			return float((row as Dictionary).get("influence", 0.0))
	return -1.0


func _test_woman_on_hut_mark_deposits_and_holds() -> void:
	var occ: Node = root.get_node_or_null("OccupationSystem")
	var presence: Node = root.get_node_or_null("HutWomanWorkPresence")
	if occ == null or presence == null or not occ.has_method("force_assign"):
		_fail("hut autoloads missing")
		return
	var world := Node2D.new()
	world.name = "ZaifHutWorld"
	root.add_child(world)
	var claim := LandClaim.new()
	claim.clan_name = "TEST"
	claim.player_owned = true
	world.add_child(claim)
	claim.global_position = Vector2.ZERO
	var hut := BuildingBase.new()
	hut.name = "ZaifHut"
	hut.building_type = ResourceData.ResourceType.LIVING_HUT
	hut.clan_name = "TEST"
	world.add_child(hut)
	hut.global_position = Vector2(80.0, 0.0)
	var scene: PackedScene = load("res://scenes/NPC.tscn") as PackedScene
	var woman: Node = scene.instantiate()
	woman.set("npc_type", "woman")
	woman.set("npc_name", "ZAIF")
	world.add_child(woman)
	if woman.has_method("set_clan_name"):
		woman.set_clan_name("TEST", "zaif_settle")
	var stand: Vector2 = presence.hut_approach_position(hut)
	woman.global_position = stand
	for _i in 8:
		await process_frame
	if not occ.force_assign(woman, hut, 0, "woman"):
		_fail("force_assign living hut")
		world.queue_free()
		return
	var inv: Variant = woman.get("inventory")
	if inv == null or not inv.has_method("add_item") or not inv.add_item(ResourceData.ResourceType.BERRIES, 1):
		_fail("could not put berries in her hands")
		world.queue_free()
		return
	var fsm: Node = woman.get("fsm")
	if fsm == null or not fsm.has_method("change_state"):
		_fail("woman has no fsm")
		world.queue_free()
		return
	fsm.change_state("work_at_building")
	var seek_while_planted := 0
	for _i in 40:
		await physics_frame
		var steer: Node = woman.get("steering_agent")
		var mode: int = int(steer.get("current_mode")) if steer else -1
		var planted: bool = woman.global_position.distance_to(stand) <= 18.0
		if planted and steer and mode == int(steer.SteeringMode.SEEK):
			seek_while_planted += 1
	var claim_inv: Variant = claim.get("inventory")
	var claim_berries := 0
	var still_holding := true
	if claim_inv and claim_inv.has_method("get_count"):
		claim_berries = int(claim_inv.get_count(ResourceData.ResourceType.BERRIES))
	if inv.has_method("get_count"):
		still_holding = int(inv.get_count(ResourceData.ResourceType.BERRIES)) > 0
	var presence_on: bool = bool(woman.get_meta("hut_work_presence_active", false))
	print("ZAIF_HUT berries_in_claim=%d holding=%s presence=%s seek_frames=%d" % [
		claim_berries, still_holding, presence_on, seek_while_planted
	])
	var hut_ok := true
	if still_holding or claim_berries < 1:
		_fail("berries stayed in her hands")
		hut_ok = false
	if seek_while_planted > 8:
		_fail("she kept seeking the mark she was already standing on")
		hut_ok = false
	if not presence_on:
		_fail("hut never took her after the stack was empty")
		hut_ok = false
	if hut_ok:
		print("ZAIF_HUT_PASS")
	world.queue_free()


func _fail(msg: String) -> void:
	_failed += 1
	print("ZAIF_SETTLE_FAIL %s" % msg)
