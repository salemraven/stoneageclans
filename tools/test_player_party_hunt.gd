extends SceneTree
## Player RTS HUNT: followers acquire nearest huntable prey when the party is close.
## Run: godot --headless --path . -s res://tools/test_player_party_hunt.gd -- --skip-single-instance

const PlayerPartyHunt = preload("res://scripts/systems/player_party_hunt.gd")

var _failed := 0
var _worlds: Array = []


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	await process_frame
	await _test_picks_and_engages_deer()
	await _test_token_survives_exit_and_latch()
	await _test_hysteresis_and_hide_yields()
	print("PLAYER_PARTY_HUNT_TEST failed=%d" % _failed)
	quit(0 if _failed == 0 else 1)


func _test_picks_and_engages_deer() -> void:
	await _drop_worlds()
	var world := Node2D.new()
	_worlds.append(world)
	root.add_child(world)
	var player := CharacterBody2D.new()
	player.add_to_group("player")
	world.add_child(player)
	player.global_position = Vector2.ZERO
	var scene: PackedScene = load("res://scenes/NPC.tscn") as PackedScene
	if scene == null:
		_fail("NPC scene missing")
		return
	var clansman: Node = scene.instantiate()
	clansman.set("npc_type", "clansman")
	clansman.set("npc_name", "HUNTER")
	clansman.set("follow_is_ordered", true)
	clansman.set("is_herded", true)
	clansman.set("herder", player)
	clansman.set("command_context", {
		"mode": "ARC",
		"commander_id": 1,
		"is_hostile": true,
		"rts_hunt": true,
	})
	world.add_child(clansman)
	clansman.global_position = Vector2(40.0, 0.0)
	var deer: Node = scene.instantiate()
	deer.set("npc_type", "deer")
	deer.set("npc_name", "DEER1")
	world.add_child(deer)
	deer.global_position = Vector2(200.0, 0.0)
	var deer_far: Node = scene.instantiate()
	deer_far.set("npc_type", "deer")
	deer_far.set("npc_name", "DEER_FAR")
	world.add_child(deer_far)
	deer_far.global_position = Vector2(9000.0, 0.0)
	for _i in 4:
		await process_frame
	var picked: Node2D = PlayerPartyHunt.pick_nearest_prey(clansman)
	if picked == null or picked != deer:
		_fail("expected nearest deer in range, got %s" % str(picked))
		return
	PlayerPartyHunt.engage(clansman, picked)
	var ct: Variant = clansman.get("combat_target")
	if ct != deer:
		_fail("combat_target not deer after engage")
	if not clansman.has_meta("volley_prey") or clansman.get_meta("volley_prey") != deer:
		_fail("volley_prey meta missing")
	var ag: float = float(clansman.get("agro_meter"))
	if ag < 99.0:
		_fail("agro not set for hunt engage got %.1f" % ag)


func _test_token_survives_exit_and_latch() -> void:
	var built: Dictionary = await _hunt_pair(Vector2(200, 0))
	var man: Node = built["man"]
	var deer: Node = built["deer"]
	if not PlayerPartyHunt.refresh(man):
		_fail("refresh did not acquire deer")
		return
	var combat: Node = man.get_node_or_null("FSM")
	if combat and combat.has_method("_get_state"):
		var st: Node = combat._get_state("combat")
		if st and st.has_method("exit"):
			st.exit()
	if not PlayerPartyHunt.token_is_live(man):
		_fail("combat exit cleared a living in-range hunt token")
	if man.get("combat_target") != deer:
		_fail("combat exit dropped the deer target")
	if man.has_method("leave_combat_lost_target"):
		man.leave_combat_lost_target()
	if man.has_method("is_fight_over_latched") and man.is_fight_over_latched():
		_fail("lost-target latch fired while hunt token was live")
	man.set("fight_over_latched", true)
	man.set("fight_over_latched_until", Time.get_ticks_msec() / 1000.0 + 5.0)
	if not PlayerPartyHunt.refresh(man):
		_fail("latch blocked a live hunt token")
	var fsm: Node = man.get_node_or_null("FSM")
	if fsm and fsm.has_method("_get_state"):
		var cst: Node = fsm._get_state("combat")
		if cst and cst.has_method("can_enter") and not cst.can_enter():
			_fail("combat can_enter false while token live and latched")


func _test_hysteresis_and_hide_yields() -> void:
	var acquire: float = PlayerPartyHunt.acquire_radius_px()
	var release: float = PlayerPartyHunt.release_radius_px()
	var built: Dictionary = await _hunt_pair(Vector2(acquire - 30.0, 0))
	var man: Node = built["man"]
	var deer: Node2D = built["deer"] as Node2D
	man.set("command_context", {
		"mode": "AMBUSH",
		"commander_id": 1,
		"is_hostile": true,
		"rts_hunt": true,
	})
	if not PlayerPartyHunt.refresh(man):
		_fail("deer inside acquire radius was not taken")
		return
	deer.global_position = Vector2((acquire + release) * 0.5, 0)
	if not PlayerPartyHunt.token_is_live(man):
		_fail("token dropped between acquire and release radii")
	deer.global_position = Vector2(release + 80.0, 0)
	if PlayerPartyHunt.refresh(man):
		_fail("prey past release radius stayed engaged")
	if PlayerPartyHunt.token_is_live(man):
		_fail("token still live past release radius")
	deer.global_position = Vector2(acquire - 30.0, 0)
	PlayerPartyHunt.engage(man, deer)
	var hide: Node = load("res://scripts/npc/states/hide_state.gd").new()
	built["world"].add_child(hide)
	hide.npc = man
	if hide.has_method("can_enter") and hide.can_enter():
		_fail("hide entered while hunt token was live")
	PlayerPartyHunt.release(man, "mode_exit")
	if hide.has_method("can_enter") and not hide.can_enter():
		_fail("hide stayed blocked after the hunt token was released")


func _drop_worlds() -> void:
	for w in _worlds:
		if is_instance_valid(w):
			w.queue_free()
	_worlds.clear()
	await process_frame


func _hunt_pair(deer_pos: Vector2) -> Dictionary:
	await _drop_worlds()
	var world := Node2D.new()
	_worlds.append(world)
	root.add_child(world)
	var player := CharacterBody2D.new()
	player.add_to_group("player")
	world.add_child(player)
	var scene: PackedScene = load("res://scenes/NPC.tscn") as PackedScene
	var man: Node = scene.instantiate()
	man.set("npc_type", "clansman")
	man.set("npc_name", "HUNTER")
	man.set("follow_is_ordered", true)
	man.set("is_herded", true)
	man.set("herder", player)
	man.set("command_context", {"mode": "ARC", "rts_hunt": true, "is_hostile": true})
	world.add_child(man)
	man.global_position = Vector2.ZERO
	var deer: Node = scene.instantiate()
	deer.set("npc_type", "deer")
	deer.set("npc_name", "DEER")
	world.add_child(deer)
	deer.global_position = deer_pos
	for _i in 3:
		await process_frame
	return {"world": world, "man": man, "deer": deer}


func _fail(msg: String) -> void:
	_failed += 1
	push_error("PLAYER_PARTY_HUNT_TEST: %s" % msg)
