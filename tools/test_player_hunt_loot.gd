extends SceneTree
## Player hunt break butchers queued carcasses before the party follows again.
## Run: godot --headless --path . -s res://tools/test_player_hunt_loot.gd -- --skip-single-instance

const PlayerPartyHunt = preload("res://scripts/systems/player_party_hunt.gd")
const CorpseHarvest = preload("res://scripts/systems/corpse_harvest.gd")

var _failed := 0
var _worlds: Array = []


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	await process_frame
	await _test_kill_queues_until_break()
	await _test_break_without_kill_does_not_butcher()
	await _test_two_kills_share_one_slice()
	await _test_empty_corpse_ends_loot()
	await _test_unreachable_drops_the_body()
	print("PLAYER_HUNT_LOOT_TEST failed=%d" % _failed)
	quit(0 if _failed == 0 else 1)


func _test_kill_queues_until_break() -> void:
	var built: Dictionary = await _pair()
	var player: Node = built["player"]
	var man: Node = built["man"]
	var deer: Node = built["deer"]
	if not PlayerPartyHunt.refresh(man):
		_fail("did not acquire live deer")
		return
	_kill(deer, 3, 0, 0)
	if PlayerPartyHunt.refresh(man):
		_fail("dead deer stayed a fight target")
	if PlayerPartyHunt.loot_is_active(man):
		_fail("loot started before hunt break")
	var ids: Array = PlayerPartyHunt.kill_ids(player)
	if ids.size() != 1 or int(ids[0]) != deer.get_instance_id():
		_fail("kill was not queued on the player: %s" % str(ids))
		return
	PlayerPartyHunt.clear_hunt_engagement(man)
	PlayerPartyHunt.begin_butcher(player)
	if not PlayerPartyHunt.loot_is_active(man):
		_fail("hunt break did not start butcher")
		return
	if not PlayerPartyHunt.service_loot(man):
		_fail("service_loot dropped an open carcass")
		return
	var runner: Node = man.get("task_runner")
	if runner == null or not runner.has_method("has_job") or not runner.has_job():
		_fail("butcher job was not assigned")
		return
	if man.has_method("should_abort_work") and man.should_abort_work():
		_fail("ordered follow aborted the butcher")
	var fsm: Node = man.get_node_or_null("FSM")
	if fsm and fsm.has_method("_get_state"):
		var combat: Node = fsm._get_state("combat")
		if combat and combat.has_method("can_enter") and combat.can_enter():
			_fail("combat can_enter during butcher")
		var hide: Node = fsm._get_state("hide")
		if hide and hide.has_method("can_enter") and hide.can_enter():
			_fail("hide can_enter during butcher")


func _test_break_without_kill_does_not_butcher() -> void:
	var built: Dictionary = await _pair()
	var player: Node = built["player"]
	var man: Node = built["man"]
	if not PlayerPartyHunt.refresh(man):
		_fail("did not acquire deer for no-kill break")
		return
	PlayerPartyHunt.clear_hunt_engagement(man)
	PlayerPartyHunt.begin_butcher(player)
	if PlayerPartyHunt.loot_is_active(man):
		_fail("butcher started with no carcass")
	if not PlayerPartyHunt.kill_ids(player).is_empty():
		_fail("live deer was queued")


func _test_two_kills_share_one_slice() -> void:
	var built: Dictionary = await _pair()
	var player: Node = built["player"]
	var man: Node = built["man"]
	var deer: Node = built["deer"]
	var scene: PackedScene = load("res://scenes/NPC.tscn") as PackedScene
	var second: Node = scene.instantiate()
	second.set("npc_type", "clansman")
	second.set("npc_name", "HUNT2")
	second.set("follow_is_ordered", true)
	second.set("is_herded", true)
	second.set("herder", player)
	second.set("command_context", {"mode": "ARC", "rts_hunt": true})
	built["world"].add_child(second)
	second.global_position = Vector2(50, 10)
	var deer_b: Node = scene.instantiate()
	deer_b.set("npc_type", "deer")
	deer_b.set("npc_name", "DEERB")
	built["world"].add_child(deer_b)
	deer_b.global_position = Vector2(280, 0)
	for _i in 4:
		await process_frame
	PlayerPartyHunt.engage(man, deer)
	_kill(deer, 1, 0, 0)
	PlayerPartyHunt.release(man, "dead")
	PlayerPartyHunt.engage(second, deer_b)
	_kill(deer_b, 1, 0, 0)
	PlayerPartyHunt.release(second, "dead")
	var ids: Array = PlayerPartyHunt.kill_ids(player)
	if ids.size() != 2:
		_fail("expected two queued kills, got %d" % ids.size())
		return
	if int(ids[0]) != deer.get_instance_id() or int(ids[1]) != deer_b.get_instance_id():
		_fail("kill order was not first-dead first")
	PlayerPartyHunt.begin_butcher(player)
	PlayerPartyHunt.service_loot(man)
	PlayerPartyHunt.service_loot(second)
	var slice: Dictionary = CorpseHarvest.take_slice(deer, func(t): return man.inventory.add_item(t, 1), "HUNTER")
	if not bool(slice.get("ok", false)):
		_fail("first slice failed")
		return
	if CorpseHarvest.yield_total(deer) != 0:
		_fail("slice did not consume the only meat")
	var again: Dictionary = CorpseHarvest.take_slice(deer, func(t): return second.inventory.add_item(t, 1), "HUNT2")
	if bool(again.get("ok", false)):
		_fail("second hunter took meat from an empty carcass")
	if man.inventory.get_count(ResourceData.ResourceType.MEAT) != 1:
		_fail("meat was not kept once")


func _test_empty_corpse_ends_loot() -> void:
	var built: Dictionary = await _pair()
	var player: Node = built["player"]
	var man: Node = built["man"]
	var deer: Node = built["deer"]
	PlayerPartyHunt.engage(man, deer)
	_kill(deer, 1, 0, 0)
	PlayerPartyHunt.release(man, "dead")
	PlayerPartyHunt.begin_butcher(player)
	CorpseHarvest.take_slice(deer, func(t): return man.inventory.add_item(t, 1), "HUNTER")
	var runner: Node = man.get("task_runner")
	if runner and runner.has_method("has_job") and runner.has_job() and runner.has_method("cancel_current_job"):
		runner.cancel_current_job("test_clear")
	if PlayerPartyHunt.service_loot(man):
		_fail("loot stayed active after the carcass was empty")
	if PlayerPartyHunt.loot_is_active(man):
		_fail("loot token remained after empty")
	var fsm: Node = man.get_node_or_null("FSM")
	if fsm and fsm.has_method("_get_state"):
		var party: Node = fsm._get_state("party")
		if party and party.has_method("can_enter") and not party.can_enter():
			_fail("party could not resume after the carcass was gone")


func _test_unreachable_drops_the_body() -> void:
	var built: Dictionary = await _pair()
	var player: Node = built["player"]
	var man: Node = built["man"]
	var deer: Node = built["deer"]
	PlayerPartyHunt.engage(man, deer)
	_kill(deer, 2, 0, 0)
	PlayerPartyHunt.release(man, "dead")
	deer.global_position = Vector2(4000, 0)
	PlayerPartyHunt.begin_butcher(player)
	var ago: float = Time.get_ticks_msec() / 1000.0 - PlayerPartyHunt.LOOT_GIVE_UP_SEC - 1.0
	player.set_meta(PlayerPartyHunt.WATCH_META, {"id": deer.get_instance_id(), "best": 3900.0, "at": ago})
	if PlayerPartyHunt.service_loot(man):
		_fail("unreachable carcass kept the butcher")
	if not PlayerPartyHunt.kill_ids(player).is_empty():
		_fail("unreachable carcass stayed queued")
	if PlayerPartyHunt.loot_is_active(man):
		_fail("loot token remained after unreachable abort")


func _pair() -> Dictionary:
	await _drop_worlds()
	var world := Node2D.new()
	_worlds.append(world)
	root.add_child(world)
	var player := CharacterBody2D.new()
	player.add_to_group("player")
	world.add_child(player)
	player.global_position = Vector2.ZERO
	var scene: PackedScene = load("res://scenes/NPC.tscn") as PackedScene
	var man: Node = scene.instantiate()
	man.set("npc_type", "clansman")
	man.set("npc_name", "HUNTER")
	man.set("follow_is_ordered", true)
	man.set("is_herded", true)
	man.set("herder", player)
	man.set("command_context", {"mode": "ARC", "commander_id": 1, "is_hostile": true, "rts_hunt": true})
	world.add_child(man)
	man.global_position = Vector2(40, 0)
	var deer: Node = scene.instantiate()
	deer.set("npc_type", "deer")
	deer.set("npc_name", "DEER1")
	world.add_child(deer)
	deer.global_position = Vector2(200, 0)
	for _i in 4:
		await process_frame
	return {"world": world, "player": player, "man": man, "deer": deer}


func _kill(deer: Node, meat: int, hide: int, bone: int) -> void:
	var health: Node = deer.get_node_or_null("HealthComponent")
	if health and "is_dead" in health:
		health.is_dead = true
	deer.set_meta("meat_remaining", meat)
	deer.set_meta("hide_remaining", hide)
	deer.set_meta("bone_remaining", bone)


func _drop_worlds() -> void:
	for w in _worlds:
		if is_instance_valid(w):
			w.queue_free()
	_worlds.clear()
	await process_frame


func _fail(msg: String) -> void:
	_failed += 1
	push_error("PLAYER_HUNT_LOOT_TEST: " + msg)
