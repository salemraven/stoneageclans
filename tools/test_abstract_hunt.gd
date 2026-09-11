extends SceneTree
## Unit-style abstract hunt checks (Phase 4).
## Run: godot --path . --headless -s res://tools/test_abstract_hunt.gd

const AbstractHuntScript = preload("res://scripts/systems/abstract_hunt.gd")
const SettlementRosterScript = preload("res://scripts/systems/settlement_roster.gd")
const SettlementSimTickScript = preload("res://scripts/systems/settlement_sim_tick.gd")

var _passed := 0
var _failed := 0


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	print("=== ABSTRACT_HUNT_TEST start ===")
	var err := change_scene_to_file("res://scenes/Main.tscn")
	if err != OK:
		_fail("load Main.tscn", "err=%s" % err)
		_summary()
		quit(1)
		return
	for _i in 8:
		await process_frame
	_test_hunt_despawns_prey_and_adds_loot()
	_test_skip_when_meat_sufficient()
	_test_skip_when_live_hunt_active()
	_test_skip_herded_prey()
	_test_settlement_tick_integration()
	_test_brain_hunt_instrumentation()
	_summary()
	quit(0 if _failed == 0 else 1)


func _chunk_world_pos(chunk: Vector2i) -> Vector2:
	return Vector2(float(chunk.x) * 2048.0 + 1000.0, float(chunk.y) * 2048.0 + 1000.0)


func _make_roster(clan: String) -> RefCounted:
	var roster = SettlementRosterScript.new()
	roster.clan_name = clan
	roster.members = [
		{"id": 1, "name": "Hunter", "type": "clansman", "alive": true, "hunger": 50.0, "is_player": false},
		{"id": 2, "name": "Hunter2", "type": "clansman", "alive": true, "hunger": 50.0, "is_player": false},
	]
	return roster


func _make_claim(clan: String, chunk: Vector2i, inv: InventoryData) -> LandClaim:
	var claim := LandClaim.new()
	claim.clan_name = clan
	claim.inventory = inv
	claim.global_position = _chunk_world_pos(chunk)
	root.add_child(claim)
	return claim


func _spawn_prey(parent: Node, prey_type: String, chunk: Vector2i, herded: bool = false) -> Node2D:
	var npc := Node2D.new()
	npc.set_script(load("res://tools/test_abstract_hunt_prey_stub.gd"))
	npc.set("npc_type", prey_type)
	npc.set("is_herded", herded)
	npc.set("clan_name", "")
	npc.name = "Test%s" % prey_type.capitalize()
	npc.global_position = _chunk_world_pos(chunk) + Vector2(120.0, 40.0)
	npc.set_meta(&"stable_id", "%d_%d_wildlife_%s" % [chunk.x, chunk.y, prey_type])
	npc.add_to_group("npcs")
	parent.add_child(npc)
	return npc


func _test_hunt_despawns_prey_and_adds_loot() -> void:
	var chunk := Vector2i(4, 4)
	var inv := InventoryData.new(16, true, 999)
	var claim := _make_claim("HUNT", chunk, inv)
	_spawn_prey(root, "deer", chunk, false)
	var roster = _make_roster("HUNT")
	var events: Dictionary = AbstractHuntScript.hunt_for_claim(claim, roster, chunk, false, 0)
	if bool(events.get("hunted", false)):
		_pass("abstract hunt succeeds with prey", str(events.get("prey_type", "")))
	else:
		_fail("abstract hunt succeeds with prey", "skip=%s" % str(events.get("skip_reason", "?")))
	var meat: int = inv.get_count(ResourceData.ResourceType.MEAT)
	var hide: int = inv.get_count(ResourceData.ResourceType.HIDE)
	if meat >= 5 and hide >= 4:
		_pass("abstract hunt adds CorpseConfig loot", "meat=%d hide=%d" % [meat, hide])
	else:
		_fail("abstract hunt adds CorpseConfig loot", "meat=%d hide=%d" % [meat, hide])
	claim.queue_free()


func _test_skip_when_meat_sufficient() -> void:
	var chunk := Vector2i(5, 5)
	var inv := InventoryData.new(16, true, 999)
	inv.add_item(ResourceData.ResourceType.MEAT, 5)
	var claim := _make_claim("FULL", chunk, inv)
	_spawn_prey(root, "deer", chunk, false)
	var roster = _make_roster("FULL")
	var events: Dictionary = AbstractHuntScript.hunt_for_claim(claim, roster, chunk, false, 0)
	if str(events.get("skip_reason", "")) == "meat_sufficient":
		_pass("abstract hunt skips when meat sufficient")
	else:
		_fail("abstract hunt skips when meat sufficient", str(events))
	claim.queue_free()


func _test_skip_when_live_hunt_active() -> void:
	var chunk := Vector2i(6, 6)
	var inv := InventoryData.new(16, true, 999)
	var claim := _make_claim("LIVE", chunk, inv)
	var deer := _spawn_prey(root, "deer", chunk, false)
	var roster = _make_roster("LIVE")
	var events: Dictionary = AbstractHuntScript.hunt_for_claim(claim, roster, chunk, false, 1)
	if str(events.get("skip_reason", "")) == "live_hunt_active" and is_instance_valid(deer):
		_pass("abstract hunt skips when live hunt active")
	else:
		_fail("abstract hunt skips when live hunt active", str(events))
	deer.queue_free()
	claim.queue_free()


func _test_skip_herded_prey() -> void:
	var chunk := Vector2i(7, 7)
	var inv := InventoryData.new(16, true, 999)
	var claim := _make_claim("HERD", chunk, inv)
	var deer := _spawn_prey(root, "deer", chunk, true)
	var roster = _make_roster("HERD")
	var events: Dictionary = AbstractHuntScript.hunt_for_claim(claim, roster, chunk, false, 0)
	if str(events.get("skip_reason", "")) == "no_prey" and is_instance_valid(deer):
		_pass("abstract hunt skips herded prey")
	else:
		_fail("abstract hunt skips herded prey", str(events))
	deer.queue_free()
	claim.queue_free()


func _test_settlement_tick_integration() -> void:
	var chunk := Vector2i(8, 8)
	var inv := InventoryData.new(16, true, 999)
	var claim := _make_claim("TICK", chunk, inv)
	_spawn_prey(root, "sheep", chunk, false)
	var roster = _make_roster("TICK")
	var events: Dictionary = SettlementSimTickScript.tick(claim, roster, 30.0, chunk, false, 0)
	var hunt: Dictionary = events.get("hunt", {}) as Dictionary
	if bool(hunt.get("hunted", false)) and str(hunt.get("prey_type", "")) == "sheep":
		_pass("SettlementSimTick runs abstract hunt", str(hunt.get("loot", {})))
	else:
		_fail("SettlementSimTick runs abstract hunt", str(hunt))
	claim.queue_free()


func _test_brain_hunt_instrumentation() -> void:
	var chunk := Vector2i(10, 10)
	var inv := InventoryData.new(16, true, 999)
	var claim := _make_claim("BRAINHUNT", chunk, inv)
	_spawn_prey(root, "goat", chunk, false)
	var roster = _make_roster("BRAINHUNT")
	var brain = claim.clan_brain
	if brain == null:
		_fail("ClanBrain exists on claim")
		claim.queue_free()
		return
	brain.roster = roster
	brain.is_dormant = true
	brain._dormant_eval_timer = 999.0
	if brain.get("hunt_intent") is Dictionary:
		brain.hunt_intent["state"] = 0
		brain.hunt_intent["target"] = null
	var items_before: int = _inventory_total(inv)
	brain.dormant_update(30.0)
	var items_after: int = _inventory_total(inv)
	if items_after > items_before:
		_pass("ClanBrain dormant_update abstract hunt adds loot", "%d->%d" % [items_before, items_after])
	else:
		_fail("ClanBrain dormant_update abstract hunt adds loot", "%d->%d" % [items_before, items_after])
	var pi: Node = root.get_node_or_null("/root/PlaytestInstrumentor")
	if pi and pi.is_enabled():
		_pass("playtest capture enabled for hunt instrumentation")
	else:
		_pass("playtest capture optional for hunt instrumentation")
	claim.queue_free()


func _inventory_total(inv: InventoryData) -> int:
	if inv == null:
		return 0
	var total := 0
	for rt in ResourceData.ResourceType.values():
		total += inv.get_count(rt)
	return total


func _pass(label: String, detail: String = "") -> void:
	_passed += 1
	if detail.is_empty():
		print("ABSTRACT_HUNT_PASS: %s" % label)
	else:
		print("ABSTRACT_HUNT_PASS: %s (%s)" % [label, detail])


func _fail(label: String, detail: String = "") -> void:
	_failed += 1
	if detail.is_empty():
		print("ABSTRACT_HUNT_FAIL: %s" % label)
	else:
		print("ABSTRACT_HUNT_FAIL: %s — %s" % [label, detail])


func _summary() -> void:
	print("=== ABSTRACT_HUNT_TEST done passed=%d failed=%d ===" % [_passed, _failed])
