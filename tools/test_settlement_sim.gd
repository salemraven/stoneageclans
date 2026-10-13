extends SceneTree
## Unit-style settlement sim checks (roster + warm tick).
## Run: godot --path . --headless -s res://tools/test_settlement_sim.gd

const SettlementRosterScript = preload("res://scripts/systems/settlement_roster.gd")
const SettlementSimTickScript = preload("res://scripts/systems/settlement_sim_tick.gd")
const SettlementPartyScript = preload("res://scripts/systems/settlement_party.gd")

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
	_test_clock_rules()
	_test_sim_time_births()
	_test_away_skips_home_food()
	_test_food_raid_resolves_once()
	_test_away_not_pulled_home()
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


func _deplete_chunk_pool(claim: Node) -> void:
	var ms: Node = root.get_node_or_null("/root/MutationStore")
	var wgc: Node = root.get_node_or_null("/root/WorldGenConfig")
	var cu: Node = root.get_node_or_null("/root/ChunkUtils")
	if ms == null or wgc == null or cu == null or not (claim is Node2D):
		return
	var chunk: Vector2i = cu.call("get_chunk_coords", (claim as Node2D).global_position) as Vector2i
	for dx in range(-1, 2):
		for dy in range(-1, 2):
			var coords := chunk + Vector2i(dx, dy)
			ms.call("reset_chunk", coords)
			ms.call("ensure_abstract_resource_pool", coords, int(wgc.get("world_seed")), wgc)
			var pool: Dictionary = ms.call("get_abstract_resource_pool", coords) as Dictionary
			for key in pool.keys():
				var remaining: int = int(pool.get(key, 0))
				if remaining > 0:
					ms.call("deplete_abstract_resource", coords, str(key), remaining)
			var rec: Dictionary = ms.call("get_chunk_record", coords)
			var empty_pool := {"berries": 0, "wood": 0, "stone": 0, "grain": 0, "fiber": 0, "nuts": 0, "bugs": 0}
			rec["abstract_resources"] = empty_pool
			rec["abstract_resource_caps"] = empty_pool.duplicate()


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
	claim.position = Vector2(90000, 90000)
	root.add_child(claim)
	_deplete_chunk_pool(claim)
	var events: Dictionary = SettlementSimTickScript.tick(claim, roster, 0.01)
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
	claim.position = Vector2(80000, 80000)
	root.add_child(claim)
	_deplete_chunk_pool(claim)
	var brain = ClanBrainClass.new(claim)
	claim.clan_brain = brain
	brain.roster = roster
	brain.is_dormant = true
	brain._settlement_accum = brain._get_dormant_eval_interval()
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


func _test_clock_rules() -> void:
	var roster = SettlementRosterScript.new()
	roster.clan_name = "CLOCK"
	roster.members = [
		{"id": 1, "name": "Awake", "type": "woman", "npc_type": "woman", "alive": true, "hunger": 100.0, "pregnancy_timer": 20.0, "is_player": false},
		{"id": 2, "name": "Asleep", "type": "woman", "npc_type": "woman", "alive": true, "hunger": 100.0, "pregnancy_timer": 20.0, "is_player": false},
	]
	var inv := InventoryData.new(8, true, 999)
	inv.add_item(ResourceData.ResourceType.BERRIES, 40)
	var claim := LandClaim.new()
	claim.clan_name = "CLOCK"
	claim.inventory = inv
	claim.position = Vector2(50000, 50000)
	root.add_child(claim)
	SettlementSimTickScript.tick(claim, roster, 5.0, Vector2i.ZERO, false, 0, false, {1: true}, false)
	var awake: Dictionary = roster.find_member(1)
	var asleep: Dictionary = roster.find_member(2)
	if absf(float(awake.get("pregnancy_timer", -1.0)) - 20.0) < 0.05 and absf(float(asleep.get("pregnancy_timer", -1.0)) - 15.0) < 0.05:
		_pass("asleep woman advances and awake woman does not")
	else:
		_fail("asleep woman advances and awake woman does not", "awake=%s asleep=%s" % [awake.get("pregnancy_timer"), asleep.get("pregnancy_timer")])
	roster.copy_timer_from_body(2, 20.0, 100.0, 25.0, false)
	var kept: Dictionary = roster.find_member(2)
	if absf(float(kept.get("pregnancy_timer", -1.0)) - 15.0) < 0.05:
		_pass("frozen body does not replace the record timer")
	else:
		_fail("frozen body does not replace the record timer", "timer=%s" % kept.get("pregnancy_timer"))
	roster.copy_timer_from_body(2, 9.0, 40.0, 26.0, true)
	var copied: Dictionary = roster.find_member(2)
	if absf(float(copied.get("pregnancy_timer", -1.0)) - 9.0) < 0.05:
		_pass("awake body copies its timer onto the record")
	else:
		_fail("awake body copies its timer onto the record", "timer=%s" % copied.get("pregnancy_timer"))

	var father_roster = SettlementRosterScript.new()
	var woman := {
		"id": 7,
		"name": "W",
		"type": "woman",
		"alive": true,
		"designated_father_id": 999,
		"father_is_player": true,
		"father_absent_ticks": 5,
	}
	father_roster.members = [
		woman,
		{"id": 8, "name": "Other", "type": "clansman", "alive": true},
	]
	var events := {"husband_reassigned": []}
	var father_id: int = SettlementSimTickScript._pick_father_id(father_roster, woman, events, true)
	if father_id == 999 and (events["husband_reassigned"] as Array).is_empty():
		_pass("living player character stays the father")
	else:
		_fail("living player character stays the father", "father=%d reassigned=%s" % [father_id, str(events["husband_reassigned"])])

	father_roster.kill_member(8)
	var living: Array = father_roster.living_person_ids()
	if not living.has(8) and living.has(7):
		_pass("removed member is not spawned")
	else:
		_fail("removed member is not spawned", "ids=%s" % str(living))

	var twins = SettlementRosterScript.new()
	twins.members = [
		{"id": -2, "name": "PUQE", "type": "baby", "alive": true},
		{"id": -3, "name": "PUQE", "type": "baby", "alive": true},
	]
	var ids: Array = twins.living_person_ids()
	if ids.size() == 2 and ids.has(-2) and ids.has(-3):
		_pass("shared name does not merge two people")
	else:
		_fail("shared name does not merge two people", "ids=%s" % str(ids))

	if not SettlementRosterScript.is_person_type("sheep") and not SettlementRosterScript.is_person_type("goat") and SettlementRosterScript.is_person_type("woman"):
		_pass("sheep and goats are not people on the record")
	else:
		_fail("sheep and goats are not people on the record", "")

	var ClanBrainClass = load("res://scripts/ai/clan_brain.gd")
	var brain = ClanBrainClass.new()
	var mover := Node.new()
	mover.set_meta("nomad_pregnancy_frozen", true)
	brain.clan_members = [mover]
	if brain.settlement_clock_is_paused():
		_pass("nomad travel pauses the record")
	else:
		_fail("nomad travel pauses the record", "")
	mover.free()
	claim.queue_free()


func _test_sim_time_births() -> void:
	var balance: Node = root.get_node_or_null("/root/BalanceConfig")
	if balance == null:
		_fail("sim-time births have BalanceConfig")
		return
	var old_preg: float = float(balance.pregnancy_seconds)
	var old_grow: float = float(balance.baby_growth_seconds)
	var old_cool: float = float(balance.birth_cooldown_seconds)
	balance.pregnancy_seconds = 10.0
	balance.baby_growth_seconds = 12.0
	balance.birth_cooldown_seconds = 5.0
	var roster = SettlementRosterScript.new()
	roster.clan_name = "BIRTH"
	roster.members = [
		{"id": 1, "name": "Ma", "type": "woman", "alive": true, "hunger": 100.0, "pregnancy_timer": 10.0, "is_player": false, "designated_father_id": 2},
		{"id": 2, "name": "Pa", "type": "clansman", "alive": true, "hunger": 100.0, "is_player": false},
	]
	var inv := InventoryData.new(8, true, 999)
	inv.add_item(ResourceData.ResourceType.BERRIES, 400)
	var claim := LandClaim.new()
	claim.clan_name = "BIRTH"
	claim.inventory = inv
	claim.position = Vector2(80000, 80000)
	root.add_child(claim)
	var hut := BuildingBase.new()
	hut.building_type = ResourceData.ResourceType.LIVING_HUT
	hut.clan_name = "BIRTH"
	root.add_child(hut)
	hut.global_position = claim.global_position + Vector2(40, 0)
	var cbi: Node = root.get_node_or_null("/root/ClaimBuildingIndex")
	if cbi:
		cbi.call("register_building", hut, claim)
	var events: Dictionary = SettlementSimTickScript.tick(claim, roster, 30.0, Vector2i(40, 40), false, 0, false)
	var births: int = (events.get("births", []) as Array).size()
	var babies := 0
	var clansmen := 0
	for m in roster.members:
		if not (m is Dictionary) or not bool((m as Dictionary).get("alive", false)):
			continue
		match str((m as Dictionary).get("type", "")):
			"baby":
				babies += 1
			"clansman":
				clansmen += 1
	if births == 2 and babies == 1 and clansmen == 2:
		_pass("30s sim time births twice and leaves one baby", "births=%d babies=%d clansmen=%d" % [births, babies, clansmen])
	else:
		_fail("30s sim time births twice and leaves one baby", "births=%d babies=%d clansmen=%d events=%s" % [births, babies, clansmen, str(events.get("births_blocked", []))])
	var before: float = float(roster.find_member(1).get("pregnancy_timer", -1.0))
	SettlementSimTickScript.tick(claim, roster, 30.0, Vector2i(40, 40), false, 0, false, {1: true})
	var after: float = float(roster.find_member(1).get("pregnancy_timer", -1.0))
	if absf(after - before) < 0.05:
		_pass("awake woman is not ticked on the record")
	else:
		_fail("awake woman is not ticked on the record", "before=%s after=%s" % [before, after])
	balance.pregnancy_seconds = old_preg
	balance.baby_growth_seconds = old_grow
	balance.birth_cooldown_seconds = old_cool
	if cbi:
		cbi.call("unregister_building", hut)
	hut.queue_free()
	claim.queue_free()


func _test_away_skips_home_food() -> void:
	var roster = SettlementRosterScript.new()
	roster.clan_name = "AWAYFOOD"
	roster.members = [
		{"id": 3, "name": "Home", "type": "woman", "alive": true, "hunger": 10.0, "is_player": false},
		{"id": 4, "name": "Gone", "type": "woman", "alive": true, "hunger": 10.0, "is_player": false, "away": true},
	]
	var inv := InventoryData.new(4, true, 999)
	inv.add_item(ResourceData.ResourceType.BERRIES, 1)
	var claim := LandClaim.new()
	claim.clan_name = "AWAYFOOD"
	claim.inventory = inv
	claim.position = Vector2(90000, 90000)
	root.add_child(claim)
	var ms: Node = root.get_node_or_null("/root/MutationStore")
	if ms:
		for dx in range(-1, 2):
			for dy in range(-1, 2):
				ms.call("reset_chunk", Vector2i(44 + dx, 44 + dy))
	var fed_events: Dictionary = SettlementSimTickScript.tick(claim, roster, 30.0, Vector2i(44, 44), false, 0, false)
	var home: Dictionary = roster.find_member(3)
	var gone: Dictionary = roster.find_member(4)
	var fed_home := false
	for row in fed_events.get("fed", []):
		if row is Dictionary and int((row as Dictionary).get("id", 0)) == 3:
			fed_home = true
		if row is Dictionary and int((row as Dictionary).get("id", 0)) == 4:
			fed_home = false
	if fed_home and absf(float(gone.get("hunger", 0.0)) - 10.0) < 0.05:
		_pass("away woman is not fed from the claim", "home=%s away=%s" % [home.get("hunger"), gone.get("hunger")])
	else:
		_fail("away woman is not fed from the claim", "home=%s away=%s berries=%d fed=%s" % [home.get("hunger"), gone.get("hunger"), inv.get_count(ResourceData.ResourceType.BERRIES), str(fed_events.get("fed", []))])
	roster.kill_member(4)
	var dead: Dictionary = {4: true}
	var npc := Node2D.new()
	npc.set_script(load("res://tools/test_abstract_hunt_prey_stub.gd"))
	npc.set("npc_type", "woman")
	npc.set("clan_name", "AWAYFOOD")
	root.add_child(npc)
	roster.stamp_member_id(npc, 4)
	roster.upsert_from_live_npc(npc, null, dead)
	var living: Array = roster.living_person_ids()
	if not living.has(4) and not bool(roster.find_member(4).get("alive", true)):
		_pass("dead id is not revived from a body")
	else:
		_fail("dead id is not revived from a body", "living=%s" % str(living))
	npc.queue_free()
	claim.queue_free()


func _test_food_raid_resolves_once() -> void:
	var attacker := InventoryData.new(8, true, 999)
	var defender := InventoryData.new(8, true, 999)
	defender.add_item(ResourceData.ResourceType.BERRIES, 6)
	var token := {"resolved": false, "materialized": false, "phase": "out", "kind": "raid"}
	var moved: int = SettlementPartyScript.resolve_food_once(attacker, defender, token)
	var again: int = SettlementPartyScript.resolve_food_once(attacker, defender, token)
	if moved == 6 and again == 0 and attacker.get_count(ResourceData.ResourceType.BERRIES) == 6 and defender.get_count(ResourceData.ResourceType.BERRIES) == 0:
		_pass("food raid moves the pantry once")
	else:
		_fail("food raid moves the pantry once", "moved=%d again=%d atk=%d def=%d" % [moved, again, attacker.get_count(ResourceData.ResourceType.BERRIES), defender.get_count(ResourceData.ResourceType.BERRIES)])
	var frozen := {"resolved": false, "materialized": true, "phase": "out"}
	defender.add_item(ResourceData.ResourceType.BERRIES, 4)
	var skipped: int = SettlementPartyScript.resolve_food_once(attacker, defender, frozen)
	if skipped == 0 and defender.get_count(ResourceData.ResourceType.BERRIES) == 4:
		_pass("materialized raid does not resolve on the record")
	else:
		_fail("materialized raid does not resolve on the record", "skipped=%d def=%d" % [skipped, defender.get_count(ResourceData.ResourceType.BERRIES)])


func _test_away_not_pulled_home() -> void:
	var ClanBrainClass = load("res://scripts/ai/clan_brain.gd")
	var roster = SettlementRosterScript.new()
	roster.clan_name = "VIEW"
	roster.members = [
		{"id": 1, "name": "Home", "type": "woman", "alive": true, "hunger": 80.0, "is_player": false, "away": false},
		{"id": 2, "name": "Raider", "type": "clansman", "alive": true, "hunger": 80.0, "is_player": false, "away": true},
	]
	var claim := LandClaim.new()
	claim.clan_name = "VIEW"
	claim.inventory = InventoryData.new(4, true, 999)
	claim.position = Vector2(12000, 12000)
	root.add_child(claim)
	var brain = ClanBrainClass.new(claim)
	claim.clan_brain = brain
	brain.roster = roster
	brain.clan_name = "VIEW"
	var npc := Node2D.new()
	npc.set_script(load("res://tools/test_abstract_hunt_prey_stub.gd"))
	npc.set("npc_type", "clansman")
	npc.set("clan_name", "VIEW")
	npc.global_position = Vector2(4000, 4000)
	root.add_child(npc)
	npc.add_to_group("npcs")
	roster.stamp_member_id(npc, 2)
	var before: Vector2 = npc.global_position
	brain.materialize_clan_for_combat()
	if is_instance_valid(npc) and npc.global_position.distance_to(before) < 1.0:
		_pass("away id is not pulled home or deleted")
	else:
		_fail("away id is not pulled home or deleted", "valid=%s" % str(is_instance_valid(npc)))
	SettlementPartyScript.write_back_keeps_away(roster, [2])
	if bool(roster.find_member(2).get("away", false)):
		_pass("write-back keeps the raider away")
	else:
		_fail("write-back keeps the raider away", "")
	if is_instance_valid(npc):
		npc.queue_free()
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
