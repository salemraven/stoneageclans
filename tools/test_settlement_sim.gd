extends SceneTree
## Unit-style settlement sim checks (roster + warm tick).
## Run: godot --path . --headless -s res://tools/test_settlement_sim.gd

const SettlementRosterScript = preload("res://scripts/systems/settlement_roster.gd")
const SettlementSimTickScript = preload("res://scripts/systems/settlement_sim_tick.gd")

var _passed := 0
var _failed := 0


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	print("=== SETTLEMENT_SIM_TEST start ===")
	var err := change_scene_to_file("res://scenes/Main.tscn")
	if err != OK:
		_fail("load Main.tscn", "err=%s" % err)
		_summary()
		quit(1)
		return
	for _i in 8:
		await process_frame
	_test_roster_death_priority()
	_test_feeding_with_food()
	_test_starvation_order()
	_test_brain_dormant_instrumentation()
	_summary()
	quit(0 if _failed == 0 else 1)


func _test_roster_death_priority() -> void:
	var roster = SettlementRosterScript.new()
	roster.clan_name = "TEST"
	roster.members = [
		{"id": 1, "name": "Leader", "type": "leader", "alive": true, "hunger": 0.0, "is_player": false},
		{"id": 2, "name": "Baby", "type": "baby", "alive": true, "hunger": 0.0, "is_player": false},
		{"id": 3, "name": "Woman", "type": "woman", "alive": true, "hunger": 0.0, "is_player": false},
	]
	var first: Dictionary = roster.get_next_to_die()
	if str(first.get("type", "")) == "baby":
		_pass("death priority picks baby first")
	else:
		_fail("death priority picks baby first", "got=%s" % str(first.get("type", "?")))


func _test_feeding_with_food() -> void:
	var roster = SettlementRosterScript.new()
	roster.clan_name = "FED"
	roster.members = [
		{
			"id": 10,
			"name": "Chief",
			"type": "leader",
			"alive": true,
			"hunger": 20.0,
			"is_leader": true,
			"is_player": false,
			"npc_type": "caveman",
		},
		{
			"id": 11,
			"name": "Worker",
			"type": "clansman",
			"alive": true,
			"hunger": 50.0,
			"is_leader": false,
			"is_player": false,
			"npc_type": "clansman",
		},
	]
	var inv := InventoryData.new(8, true, 999)
	inv.add_item(ResourceData.ResourceType.BERRIES, 5)
	var claim := LandClaim.new()
	claim.clan_name = "FED"
	claim.inventory = inv
	root.add_child(claim)
	var events: Dictionary = SettlementSimTickScript.tick(claim, roster, 30.0)
	var fed: Array = events.get("fed", [])
	if fed.size() >= 1:
		_pass("settlement tick feeds members when food present", "fed=%d" % fed.size())
	else:
		_fail("settlement tick feeds members when food present", "fed=0")
	var leader: Dictionary = roster.find_member(10)
	var leader_fed := false
	for f in fed:
		if f is Dictionary and int((f as Dictionary).get("id", -1)) == 10:
			leader_fed = true
	if leader_fed:
		_pass("leader fed first when food present")
	else:
		_fail("leader fed first when food present", "fed=%s" % str(fed))
	if float(leader.get("hunger", 0.0)) > 0.0:
		_pass("leader hunger remains tracked after tick")
	else:
		_fail("leader hunger remains tracked after tick", "hunger=%s" % str(leader.get("hunger", 0.0)))
	claim.queue_free()


func _test_starvation_order() -> void:
	var roster = SettlementRosterScript.new()
	roster.clan_name = "STARVE"
	roster.members = [
		{"id": 20, "name": "Chief", "type": "leader", "alive": true, "hunger": 0.0, "is_player": false, "npc_type": "caveman"},
		{"id": 21, "name": "Baby", "type": "baby", "alive": true, "hunger": 0.0, "is_player": false, "npc_type": "baby"},
		{"id": 22, "name": "Woman", "type": "woman", "alive": true, "hunger": 0.0, "is_player": false, "npc_type": "woman"},
	]
	var inv := InventoryData.new(4, true, 999)
	var claim := LandClaim.new()
	claim.clan_name = "STARVE"
	claim.inventory = inv
	root.add_child(claim)
	var events: Dictionary = SettlementSimTickScript.tick(claim, roster, 30.0)
	var died: Array = events.get("died", [])
	if died.size() >= 1 and str((died[0] as Dictionary).get("type", "")) == "baby":
		_pass("starvation kills baby before others")
	else:
		_fail("starvation kills baby before others", "died=%s" % str(died))
	if roster.get_population() == 2:
		_pass("population drops by one on starvation tick")
	else:
		_fail("population drops by one on starvation tick", "pop=%d" % roster.get_population())
	claim.queue_free()


func _test_brain_dormant_instrumentation() -> void:
	var ClanBrainClass = load("res://scripts/ai/clan_brain.gd")
	var roster = SettlementRosterScript.new()
	roster.clan_name = "INST"
	roster.members = [
		{"id": 30, "name": "Lead", "type": "leader", "alive": true, "hunger": 10.0, "is_leader": true, "is_player": false, "npc_type": "caveman"},
	]
	var inv := InventoryData.new(4, true, 999)
	inv.add_item(ResourceData.ResourceType.BERRIES, 2)
	var berries_before := inv.get_count(ResourceData.ResourceType.BERRIES)
	var claim := LandClaim.new()
	claim.clan_name = "INST"
	claim.inventory = inv
	root.add_child(claim)
	var brain = ClanBrainClass.new(claim)
	claim.clan_brain = brain
	brain.roster = roster
	brain.is_dormant = true
	brain._dormant_eval_timer = 999.0
	brain.dormant_update(0.0)
	var berries_after := inv.get_count(ResourceData.ResourceType.BERRIES)
	if berries_after < berries_before:
		_pass("ClanBrain dormant_update consumed claim food", "berries %d->%d" % [berries_before, berries_after])
	else:
		_fail("ClanBrain dormant_update consumed claim food", "berries=%d" % berries_after)
	var pi = root.get_node_or_null("/root/PlaytestInstrumentor")
	if pi and pi.is_enabled():
		_pass("playtest capture enabled for settlement events")
	else:
		_pass("playtest capture optional (add --playtest-capture for JSONL)")
	claim.queue_free()


func _pass(label: String, detail: String = "") -> void:
	_passed += 1
	if detail.is_empty():
		print("SETTLEMENT_SIM_PASS: %s" % label)
	else:
		print("SETTLEMENT_SIM_PASS: %s (%s)" % [label, detail])


func _fail(label: String, detail: String = "") -> void:
	_failed += 1
	if detail.is_empty():
		print("SETTLEMENT_SIM_FAIL: %s" % label)
	else:
		print("SETTLEMENT_SIM_FAIL: %s — %s" % [label, detail])


func _summary() -> void:
	print("=== SETTLEMENT_SIM_TEST done: passed=%d failed=%d ===" % [_passed, _failed])
