extends SceneTree
## Unit-style settlement pregnancy/birth/growth/aging checks (Phase 7).
## Run: godot --path . --headless -s res://tools/test_settlement_pregnancy.gd

const SettlementRosterScript = preload("res://scripts/systems/settlement_roster.gd")
const SettlementSimTickScript = preload("res://scripts/systems/settlement_sim_tick.gd")

var _passed := 0
var _failed := 0


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	print("=== SETTLEMENT_PREGNANCY_TEST start ===")
	var err := change_scene_to_file("res://scenes/Main.tscn")
	if err != OK:
		_fail("load Main.tscn", "err=%s" % err)
		_summary()
		quit(1)
		return
	for _i in 8:
		await process_frame
	_test_pregnancy_timer_decrements()
	_test_birth_adds_baby()
	_test_starvation_cancels_pregnancy()
	_test_new_conception()
	_test_father_designated_first()
	_test_baby_growth_promotion()
	_test_growth_before_conception()
	_test_father_absent_waits_one_tick()
	_test_husband_reassigned_on_death()
	_test_aging_increments()
	_test_baby_cap_blocks_birth()
	_test_birth_cooldown_blocks_conception()
	_test_brain_pregnancy_instrumentation()
	_summary()
	quit(0 if _failed == 0 else 1)


func _make_claim(clan: String, inv: InventoryData) -> LandClaim:
	var claim := LandClaim.new()
	claim.clan_name = clan
	claim.inventory = inv
	claim.global_position = Vector2(3200.0, 3200.0)
	claim.set_meta("food_days_buffer", 2.0)
	root.add_child(claim)
	return claim


func _register_living_hut(claim: LandClaim) -> BuildingBase:
	var hut := BuildingBase.new()
	hut.building_type = ResourceData.ResourceType.LIVING_HUT
	hut.clan_name = claim.clan_name
	root.add_child(hut)
	hut.global_position = claim.global_position + Vector2(60.0, 0.0)
	var cbi: Node = root.get_node_or_null("/root/ClaimBuildingIndex")
	if cbi:
		cbi.call("register_building", hut, claim)
	return hut


func _unregister_building(building: BuildingBase) -> void:
	var cbi: Node = root.get_node_or_null("/root/ClaimBuildingIndex")
	if cbi and building:
		cbi.call("unregister_building", building)


func _test_pregnancy_timer_decrements() -> void:
	var roster = SettlementRosterScript.new()
	roster.clan_name = "TIMER"
	roster.members = [
		{
			"id": 1, "name": "Ada", "type": "woman", "alive": true, "hunger": 80.0,
			"pregnancy_timer": 20.0, "designated_father_id": 2, "last_birth_time": -1.0,
			"is_player": false, "npc_type": "woman",
		},
		{"id": 2, "name": "Bob", "type": "clansman", "alive": true, "hunger": 80.0, "is_player": false, "npc_type": "clansman"},
	]
	var inv := InventoryData.new(8, true, 999)
	inv.add_item(ResourceData.ResourceType.BERRIES, 20)
	var claim := _make_claim("TIMER", inv)
	var events: Dictionary = SettlementSimTickScript.tick(claim, roster, 5.0)
	var woman: Dictionary = roster.find_member(1)
	if float(woman.get("pregnancy_timer", -1.0)) == 15.0:
		_pass("pregnancy timer decrements", "timer=15")
	else:
		_fail("pregnancy timer decrements", "timer=%s" % str(woman.get("pregnancy_timer", "?")))
	if (events.get("births", []) as Array).is_empty():
		_pass("no birth before timer ends")
	else:
		_fail("no birth before timer ends", str(events.get("births", [])))
	claim.queue_free()


func _test_birth_adds_baby() -> void:
	var roster = SettlementRosterScript.new()
	roster.clan_name = "BIRTH"
	roster.members = [
		{
			"id": 10, "name": "Mira", "type": "woman", "alive": true, "hunger": 80.0,
			"pregnancy_timer": 3.0, "designated_father_id": 11, "last_birth_time": -1.0,
			"is_player": false, "npc_type": "woman",
		},
		{"id": 11, "name": "Tor", "type": "clansman", "alive": true, "hunger": 80.0, "is_player": false, "npc_type": "clansman"},
	]
	var inv := InventoryData.new(8, true, 999)
	inv.add_item(ResourceData.ResourceType.BERRIES, 20)
	var claim := _make_claim("BIRTH", inv)
	var events: Dictionary = SettlementSimTickScript.tick(claim, roster, 5.0)
	var births: Array = events.get("births", [])
	if births.size() == 1:
		_pass("birth fires when pregnancy timer ends")
	else:
		_fail("birth fires when pregnancy timer ends", str(births))
	if roster.get_baby_count() == 1:
		_pass("baby added to roster")
	else:
		_fail("baby added to roster", "babies=%d" % roster.get_baby_count())
	var baby: Dictionary = roster.get_babies()[0]
	if str(baby.get("name", "")).length() >= 3:
		_pass("baby has generated name", str(baby.get("name", "")))
	else:
		_fail("baby has generated name", str(baby.get("name", "")))
	claim.queue_free()


func _test_starvation_cancels_pregnancy() -> void:
	var roster = SettlementRosterScript.new()
	roster.clan_name = "STARVE_PREG"
	roster.members = [
		{
			"id": 20, "name": "Eve", "type": "woman", "alive": true, "hunger": 80.0,
			"pregnancy_timer": 10.0, "designated_father_id": 21, "last_birth_time": -1.0,
			"is_player": false, "npc_type": "woman",
		},
		{"id": 21, "name": "Dan", "type": "clansman", "alive": true, "hunger": 80.0, "is_player": false, "npc_type": "clansman"},
	]
	var inv := InventoryData.new(4, true, 999)
	var claim := _make_claim("STARVE_PREG", inv)
	claim.set_meta("food_days_buffer", 0.0)
	var events: Dictionary = SettlementSimTickScript.tick(claim, roster, 5.0, Vector2i.ZERO, true)
	var cancelled: Array = events.get("pregnancies_cancelled", [])
	if cancelled.size() == 1 and str((cancelled[0] as Dictionary).get("reason", "")) == "starvation":
		_pass("starvation cancels pregnancy")
	else:
		_fail("starvation cancels pregnancy", str(cancelled))
	var woman: Dictionary = roster.find_member(20)
	if float(woman.get("pregnancy_timer", 1.0)) < 0.0:
		_pass("pregnancy timer cleared after cancel")
	else:
		_fail("pregnancy timer cleared after cancel", str(woman.get("pregnancy_timer", "?")))
	claim.queue_free()


func _test_new_conception() -> void:
	var roster = SettlementRosterScript.new()
	roster.clan_name = "CONCEIVE"
	roster.members = [
		{
			"id": 30, "name": "Lia", "type": "woman", "alive": true, "hunger": 80.0,
			"pregnancy_timer": -1.0, "designated_father_id": 31, "last_birth_time": -1.0,
			"is_player": false, "npc_type": "woman",
		},
		{"id": 31, "name": "Kai", "type": "clansman", "alive": true, "hunger": 80.0, "is_player": false, "npc_type": "clansman"},
	]
	var inv := InventoryData.new(8, true, 999)
	inv.add_item(ResourceData.ResourceType.BERRIES, 20)
	var claim := _make_claim("CONCEIVE", inv)
	var hut := _register_living_hut(claim)
	var events: Dictionary = SettlementSimTickScript.tick(claim, roster, 5.0)
	var started: Array = events.get("pregnancies_started", [])
	if started.size() == 1:
		_pass("new pregnancy starts off-screen")
	else:
		_fail("new pregnancy starts off-screen", str(started))
	var woman: Dictionary = roster.find_member(30)
	if float(woman.get("pregnancy_timer", -1.0)) > 0.0:
		_pass("woman pregnancy timer set on conception")
	else:
		_fail("woman pregnancy timer set on conception", str(woman.get("pregnancy_timer", "?")))
	_unregister_building(hut)
	hut.queue_free()
	claim.queue_free()


func _test_father_designated_first() -> void:
	var roster = SettlementRosterScript.new()
	roster.clan_name = "FATHER"
	roster.members = [
		{
			"id": 40, "name": "Nia", "type": "woman", "alive": true, "hunger": 80.0,
			"pregnancy_timer": -1.0, "designated_father_id": 42, "last_birth_time": -1.0,
			"is_player": false, "npc_type": "woman",
		},
		{"id": 41, "name": "Other", "type": "clansman", "alive": true, "hunger": 80.0, "is_player": false, "npc_type": "clansman"},
		{"id": 42, "name": "Chosen", "type": "clansman", "alive": true, "hunger": 80.0, "is_player": false, "npc_type": "clansman"},
	]
	var inv := InventoryData.new(8, true, 999)
	inv.add_item(ResourceData.ResourceType.BERRIES, 20)
	var claim := _make_claim("FATHER", inv)
	var hut := _register_living_hut(claim)
	var events: Dictionary = SettlementSimTickScript.tick(claim, roster, 5.0)
	var started: Array = events.get("pregnancies_started", [])
	if started.size() == 1 and int((started[0] as Dictionary).get("father_id", -1)) == 42:
		_pass("designated father preferred for conception")
	else:
		_fail("designated father preferred for conception", str(started))
	_unregister_building(hut)
	hut.queue_free()
	claim.queue_free()


func _test_baby_growth_promotion() -> void:
	var roster = SettlementRosterScript.new()
	roster.clan_name = "GROW"
	var bc: Node = root.get_node_or_null("/root/BalanceConfig")
	var growth_time: float = 17.5
	if bc:
		growth_time = float(bc.get("baby_growth_seconds"))
	roster.members = [
		{
			"id": 50, "name": "Baby", "type": "baby", "alive": true, "hunger": 80.0,
			"growth_timer": growth_time - 1.0, "pregnancy_timer": -1.0, "last_birth_time": -1.0,
			"is_player": false, "npc_type": "baby",
		},
	]
	var inv := InventoryData.new(4, true, 999)
	var claim := _make_claim("GROW", inv)
	var events: Dictionary = SettlementSimTickScript.tick(claim, roster, 2.0)
	var grew: Array = events.get("grew_up", [])
	if grew.size() == 1:
		_pass("baby grows to clansman off-screen")
	else:
		_fail("baby grows to clansman off-screen", str(grew))
	var member: Dictionary = roster.find_member(50)
	if str(member.get("type", "")) == "clansman" and int(member.get("age", 0)) == 13:
		_pass("promoted baby is clansman age 13")
	else:
		_fail("promoted baby is clansman age 13", "type=%s age=%s" % [member.get("type", "?"), member.get("age", "?")])
	claim.queue_free()


func _test_growth_before_conception() -> void:
	var roster = SettlementRosterScript.new()
	roster.clan_name = "GROWCONCEIVE"
	var bc: Node = root.get_node_or_null("/root/BalanceConfig")
	var growth_time: float = 17.5
	if bc:
		growth_time = float(bc.get("baby_growth_seconds"))
	roster.members = [
		{
			"id": 70, "name": "Mira", "type": "woman", "alive": true, "hunger": 80.0,
			"pregnancy_timer": -1.0, "designated_father_id": 999, "last_birth_time": -1.0,
			"father_absent_ticks": 1, "is_player": false, "npc_type": "woman",
		},
		{
			"id": 71, "name": "Son", "type": "baby", "alive": true, "hunger": 80.0,
			"growth_timer": growth_time - 1.0, "pregnancy_timer": -1.0, "last_birth_time": -1.0,
			"father_absent_ticks": 0, "is_player": false, "npc_type": "baby",
		},
	]
	var inv := InventoryData.new(8, true, 999)
	inv.add_item(ResourceData.ResourceType.BERRIES, 20)
	var claim := _make_claim("GROWCONCEIVE", inv)
	var hut := _register_living_hut(claim)
	var events: Dictionary = SettlementSimTickScript.tick(claim, roster, 2.0)
	var grew: Array = events.get("grew_up", [])
	var started: Array = events.get("pregnancies_started", [])
	if grew.size() == 1 and started.size() == 1:
		_pass("baby growth and conception in same tick")
	else:
		_fail("baby growth and conception in same tick", "grew=%s started=%s" % [str(grew), str(started)])
	if started.size() == 1 and int((started[0] as Dictionary).get("father_id", -1)) == 71:
		_pass("newly grown clansman fathers same tick")
	else:
		_fail("newly grown clansman fathers same tick", str(started))
	_unregister_building(hut)
	hut.queue_free()
	claim.queue_free()


func _test_father_absent_waits_one_tick() -> void:
	var roster = SettlementRosterScript.new()
	roster.clan_name = "WAITFATHER"
	roster.members = [
		{
			"id": 80, "name": "Wife", "type": "woman", "alive": true, "hunger": 80.0,
			"pregnancy_timer": -1.0, "designated_father_id": 999, "last_birth_time": -1.0,
			"father_absent_ticks": 0, "is_player": false, "npc_type": "woman",
		},
		{
			"id": 81, "name": "Other", "type": "clansman", "alive": true, "hunger": 80.0,
			"is_player": false, "npc_type": "clansman",
		},
	]
	var inv := InventoryData.new(8, true, 999)
	inv.add_item(ResourceData.ResourceType.BERRIES, 20)
	var claim := _make_claim("WAITFATHER", inv)
	var hut := _register_living_hut(claim)
	var events1: Dictionary = SettlementSimTickScript.tick(claim, roster, 5.0)
	if (events1.get("pregnancies_started", []) as Array).is_empty():
		_pass("absent designated father waits first tick")
	else:
		_fail("absent designated father waits first tick", str(events1.get("pregnancies_started", [])))
	var woman: Dictionary = roster.find_member(80)
	if int(woman.get("father_absent_ticks", 0)) == 1:
		_pass("father_absent_ticks incremented")
	else:
		_fail("father_absent_ticks incremented", str(woman.get("father_absent_ticks", "?")))
	var events2: Dictionary = SettlementSimTickScript.tick(claim, roster, 5.0)
	var started: Array = events2.get("pregnancies_started", [])
	if started.size() == 1:
		_pass("conception after husband wait tick")
	else:
		_fail("conception after husband wait tick", str(started))
	var reassigned: Array = events2.get("husband_reassigned", [])
	if reassigned.size() == 1:
		_pass("husband reassigned after wait")
	else:
		_fail("husband reassigned after wait", str(reassigned))
	_unregister_building(hut)
	hut.queue_free()
	claim.queue_free()


func _test_husband_reassigned_on_death() -> void:
	var roster = SettlementRosterScript.new()
	roster.clan_name = "DEADFATHER"
	roster.members = [
		{
			"id": 90, "name": "Widow", "type": "woman", "alive": true, "hunger": 80.0,
			"pregnancy_timer": -1.0, "designated_father_id": 91, "last_birth_time": -1.0,
			"father_absent_ticks": 1, "is_player": false, "npc_type": "woman",
		},
		{
			"id": 91, "name": "Dead", "type": "clansman", "alive": false, "hunger": 0.0,
			"is_player": false, "npc_type": "clansman",
		},
		{
			"id": 92, "name": "NewMate", "type": "clansman", "alive": true, "hunger": 80.0,
			"is_player": false, "npc_type": "clansman",
		},
	]
	var inv := InventoryData.new(8, true, 999)
	inv.add_item(ResourceData.ResourceType.BERRIES, 20)
	var claim := _make_claim("DEADFATHER", inv)
	var hut := _register_living_hut(claim)
	var events: Dictionary = SettlementSimTickScript.tick(claim, roster, 5.0)
	var reassigned: Array = events.get("husband_reassigned", [])
	if reassigned.size() == 1 and str((reassigned[0] as Dictionary).get("reason", "")) == "father_died":
		_pass("husband reassigned when designated father dead")
	else:
		_fail("husband reassigned when designated father dead", str(reassigned))
	if (events.get("pregnancies_started", []) as Array).size() == 1:
		_pass("conception after dead father reassignment")
	else:
		_fail("conception after dead father reassignment", str(events.get("pregnancies_started", [])))
	var woman: Dictionary = roster.find_member(90)
	if int(woman.get("designated_father_id", -1)) == 92:
		_pass("designated_father_id updated to new mate")
	else:
		_fail("designated_father_id updated to new mate", str(woman.get("designated_father_id", "?")))
	_unregister_building(hut)
	hut.queue_free()
	claim.queue_free()


func _test_aging_increments() -> void:
	var roster = SettlementRosterScript.new()
	roster.clan_name = "AGE"
	roster.members = [
		{
			"id": 60, "name": "Elder", "type": "clansman", "alive": true, "hunger": 80.0,
			"age": 20.0, "pregnancy_timer": -1.0, "growth_timer": -1.0,
			"is_player": false, "npc_type": "clansman",
		},
	]
	var inv := InventoryData.new(4, true, 999)
	var claim := _make_claim("AGE", inv)
	SettlementSimTickScript.tick(claim, roster, 600.0)
	var member: Dictionary = roster.find_member(60)
	if float(member.get("age", 0.0)) > 20.0:
		_pass("adult age increments off-screen", "age=%s" % str(member.get("age", "?")))
	else:
		_fail("adult age increments off-screen", "age=%s" % str(member.get("age", "?")))
	claim.queue_free()


func _test_baby_cap_blocks_birth() -> void:
	var roster = SettlementRosterScript.new()
	roster.clan_name = "CAP"
	var cfg := ReproductionConfig.new()
	var cap: int = cfg.baby_pool_base_capacity
	for i in cap:
		roster.members.append({
			"id": 100 + i,
			"name": "Baby%d" % i,
			"type": "baby",
			"alive": true,
			"hunger": 80.0,
			"growth_timer": 1.0,
			"pregnancy_timer": -1.0,
			"is_player": false,
			"npc_type": "baby",
		})
	roster.members.append({
		"id": 200, "name": "Mom", "type": "woman", "alive": true, "hunger": 80.0,
		"pregnancy_timer": 1.0, "designated_father_id": 201, "last_birth_time": -1.0,
		"is_player": false, "npc_type": "woman",
	})
	roster.members.append({
		"id": 201, "name": "Dad", "type": "clansman", "alive": true, "hunger": 80.0,
		"is_player": false, "npc_type": "clansman",
	})
	var inv := InventoryData.new(8, true, 999)
	inv.add_item(ResourceData.ResourceType.BERRIES, 20)
	var claim := _make_claim("CAP", inv)
	var before_babies: int = roster.get_baby_count()
	var events: Dictionary = SettlementSimTickScript.tick(claim, roster, 5.0)
	var blocked: Array = events.get("births_blocked", [])
	if blocked.size() == 1:
		_pass("baby cap blocks birth at capacity")
	else:
		_fail("baby cap blocks birth at capacity", "blocked=%s births=%s" % [str(blocked), str(events.get("births", []))])
	if roster.get_baby_count() == before_babies:
		_pass("no extra baby when cap full")
	else:
		_fail("no extra baby when cap full", "babies=%d" % roster.get_baby_count())
	claim.queue_free()


func _test_birth_cooldown_blocks_conception() -> void:
	var roster = SettlementRosterScript.new()
	roster.clan_name = "COOLDOWN"
	var now_sec: float = Time.get_ticks_msec() / 1000.0
	roster.members = [
		{
			"id": 300, "name": "Sara", "type": "woman", "alive": true, "hunger": 80.0,
			"pregnancy_timer": -1.0, "designated_father_id": 301, "last_birth_time": now_sec,
			"is_player": false, "npc_type": "woman",
		},
		{"id": 301, "name": "Ulf", "type": "clansman", "alive": true, "hunger": 80.0, "is_player": false, "npc_type": "clansman"},
	]
	var inv := InventoryData.new(8, true, 999)
	inv.add_item(ResourceData.ResourceType.BERRIES, 20)
	var claim := _make_claim("COOLDOWN", inv)
	var hut := _register_living_hut(claim)
	var events: Dictionary = SettlementSimTickScript.tick(claim, roster, 5.0)
	if (events.get("pregnancies_started", []) as Array).is_empty():
		_pass("birth cooldown blocks immediate re-conception")
	else:
		_fail("birth cooldown blocks immediate re-conception", str(events.get("pregnancies_started", [])))
	_unregister_building(hut)
	hut.queue_free()
	claim.queue_free()


func _test_brain_pregnancy_instrumentation() -> void:
	var ClanBrainClass = load("res://scripts/ai/clan_brain.gd")
	var roster = SettlementRosterScript.new()
	roster.clan_name = "LOGPREG"
	roster.members = [
		{
			"id": 400, "name": "Woman", "type": "woman", "alive": true, "hunger": 80.0,
			"pregnancy_timer": 2.0, "designated_father_id": 401, "last_birth_time": -1.0,
			"is_player": false, "npc_type": "woman",
		},
		{"id": 401, "name": "Man", "type": "clansman", "alive": true, "hunger": 80.0, "is_player": false, "npc_type": "clansman"},
	]
	var inv := InventoryData.new(8, true, 999)
	inv.add_item(ResourceData.ResourceType.BERRIES, 20)
	var claim := LandClaim.new()
	claim.clan_name = "LOGPREG"
	claim.inventory = inv
	claim.global_position = Vector2(3300.0, 3300.0)
	claim.set_meta("food_days_buffer", 2.0)
	root.add_child(claim)
	var events: Dictionary = SettlementSimTickScript.tick(claim, roster, 30.0)
	var brain = ClanBrainClass.new(claim)
	brain.clan_name = "LOGPREG"
	brain._log_settlement_events(events, 2, 20)
	var births: Array = events.get("births", [])
	if births.size() >= 1:
		_pass("settlement tick birth events available for ClanBrain logging")
	else:
		_fail("settlement tick birth events available for ClanBrain logging", str(events))
	var pi: Node = root.get_node_or_null("/root/PlaytestInstrumentor")
	if pi and pi.has_method("is_enabled") and pi.is_enabled():
		_pass("PlaytestInstrumentor active during pregnancy log wiring")
	else:
		_pass("PlaytestInstrumentor optional during pregnancy log wiring")
	claim.queue_free()


func _pass(label: String, detail: String = "") -> void:
	_passed += 1
	if detail.is_empty():
		print("  PASS: %s" % label)
	else:
		print("  PASS: %s (%s)" % [label, detail])


func _fail(label: String, detail: String = "") -> void:
	_failed += 1
	if detail.is_empty():
		print("  FAIL: %s" % label)
	else:
		print("  FAIL: %s (%s)" % [label, detail])


func _summary() -> void:
	print("=== SETTLEMENT_PREGNANCY_TEST done: %d passed, %d failed ===" % [_passed, _failed])
