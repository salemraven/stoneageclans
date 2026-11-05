extends SceneTree
## Living-camp record: owed process time, player camps stay awake, same hut, staggered spawn.
## Run: godot --path . --headless -s res://tools/test_living_camp_record.gd

var _passed := 0
var _failed := 0


class TickBrain extends RefCounted:
	var ticks: int = 0
	var paid: float = 0.0
	func set_dormant(_value: bool) -> void:
		pass
	func dormant_update(owed: float, _alert_delta: float = -1.0) -> void:
		ticks += 1
		paid += owed


class Probe extends Node2D:
	var player_owned: bool = false
	var clan_name: String = ""
	var clan_brain: TickBrain


class FakeMain extends Node:
	var npcs_container: Node = null
	var player: Node2D = null
	func spawn_npc_from_sleep_data(data: Dictionary, parent: Node) -> void:
		var body := NPCBase.new()
		body.npc_type = str(data.get("npc_type", "clansman"))
		body.clan_name = str(data.get("clan_name", ""))
		body.npc_name = str(data.get("npc_name", "N"))
		body.global_position = data.get("position", Vector2.ZERO)
		parent.add_child(body)
		body.add_to_group("npcs")
		if int(data.get("settlement_member_id", 0)) != 0:
			body.set_meta("settlement_member_id", int(data.get("settlement_member_id", 0)))


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	print("=== LIVING_CAMP_RECORD_TEST start ===")
	var log_path := "user://living_camp_record_test.jsonl"
	var pi: Node = root.get_node("PlaytestInstrumentor")
	pi.set("_enabled", true)
	pi.set("_file", FileAccess.open(log_path, FileAccess.WRITE))
	pi.set("_start_time", Time.get_ticks_msec() / 1000.0)
	_test_real_time()
	_test_catch_up_and_alert()
	_test_player_stays_awake()
	_test_physics_off()
	_test_same_hut_and_stagger()
	_test_no_early_village()
	(pi.get("_file") as FileAccess).flush()
	var text := FileAccess.get_file_as_string(log_path)
	_check("camp_tick is logged", text.contains("\"evt\":\"camp_tick\""), "")
	_check("camp_materialize is logged", text.contains("\"evt\":\"camp_materialize\""), "")
	_check("a refused player sleep is logged", text.contains("\"evt\":\"camp_dormant_refused\""), "")
	_check("a far restore is logged as not awake", text.contains("\"woke\":false"), "")
	pi.set("_enabled", false)
	print("LIVING_CAMP_RECORD_TEST passed=%d failed=%d" % [_passed, _failed])
	quit(0 if _failed == 0 else 1)


func _test_real_time() -> void:
	var camps: Node = root.get_node("OffscreenCamps")
	var probes: Array = []
	for i in 3:
		var probe := Probe.new()
		probe.clan_name = "TIME%d" % i
		probe.clan_brain = TickBrain.new()
		root.add_child(probe)
		camps.call("park_claim", probe, Vector2i(40 + i, 3))
		probes.append(probe)
	for _i in 20:
		camps._process(0.05)
	var ok := true
	var detail := ""
	for probe in probes:
		var paid: float = (probe as Probe).clan_brain.paid
		var still: float = float(camps._owed_sec.get((probe as Probe).get_instance_id(), 0.0))
		detail += " paid=%.2f still=%.2f" % [paid, still]
		if paid + still < 0.95 or paid < 0.7:
			ok = false
	_check("three parked camps each receive about one second", ok, detail)
	for probe in probes:
		camps._parked.erase(probe)
		camps._owed_sec.erase((probe as Probe).get_instance_id())
		probe.queue_free()


func _test_catch_up_and_alert() -> void:
	var claim := LandClaim.new()
	claim.clan_name = "CATCHUP"
	claim.player_owned = false
	root.add_child(claim)
	var brain = claim.clan_brain
	brain.is_dormant = true
	var roster = brain.roster if brain.roster else preload("res://scripts/systems/settlement_roster.gd").new()
	brain.roster = roster
	roster.members = [{
		"id": 1, "type": "woman", "npc_type": "woman", "name": "W", "alive": true, "hunger": 80.0, "away": false,
	}]
	brain._settlement_accum = 0.0
	brain.alert_level = brain.AlertLevel.RAID
	brain.alert_decay_timer = 0.0
	brain.dormant_update(150.0, 0.016)
	var slices: int = int(brain._last_settlement_slices)
	var accum: float = float(brain._settlement_accum)
	_check("a 150s gap runs 4 slices and keeps the rest", slices == 4 and is_equal_approx(accum, 30.0), "slices=%d accum=%s" % [slices, accum])
	brain.dormant_update(0.0, 0.016)
	_check("the next tick spends the leftover slice", int(brain._last_settlement_slices) == 1 and float(brain._settlement_accum) < 1.0, "slices=%s accum=%s" % [brain._last_settlement_slices, brain._settlement_accum])
	_check("alert decay sees one frame, not the gap", brain.alert_level == brain.AlertLevel.RAID and float(brain.alert_decay_timer) < 1.0, "level=%s timer=%s" % [brain.alert_level, brain.alert_decay_timer])
	claim.queue_free()


func _test_player_stays_awake() -> void:
	var camps: Node = root.get_node("OffscreenCamps")
	var claim := LandClaim.new()
	claim.clan_name = "PLAYERKEEP"
	claim.player_owned = true
	root.add_child(claim)
	claim.clan_brain.set_dormant(true)
	_check("a player claim refuses sleep", not claim.clan_brain.is_dormant, "")
	camps.call("park_claim", claim, Vector2i(8, 8))
	_check("a player claim is not parked", not bool(camps.call("has_parked_chunk", Vector2i(8, 8))), "")
	var fire := Campfire.new()
	fire.clan_name = "PLAYERFIRE"
	fire.player_owned = true
	root.add_child(fire)
	if fire.clan_brain:
		fire.clan_brain.set_dormant(true)
		_check("a player campfire refuses sleep", not fire.clan_brain.is_dormant, "")
	else:
		_check("a player campfire refuses sleep", false, "no brain")
	claim.queue_free()
	fire.queue_free()


func _test_physics_off() -> void:
	var camps: Node = root.get_node("OffscreenCamps")
	var claim := LandClaim.new()
	claim.clan_name = "PHYSICS"
	claim.player_owned = false
	var chunk := Node2D.new()
	root.add_child(chunk)
	chunk.add_child(claim)
	var hut := BuildingBase.new()
	hut.building_type = ResourceData.ResourceType.LIVING_HUT
	hut.clan_name = "PHYSICS"
	root.add_child(hut)
	root.get_node("ClaimBuildingIndex").call("register_building", hut, claim)
	camps.call("park_claim", claim, Vector2i(11, 2))
	_check("parked claim and hut leave the process tree", claim.process_mode == Node.PROCESS_MODE_DISABLED and hut.process_mode == Node.PROCESS_MODE_DISABLED, "")
	_check("the off-screen driver still processes", camps.is_processing(), "")
	camps.call("restore_chunk", Vector2i(11, 2), chunk)
	_check("restore turns processing back on", claim.process_mode == Node.PROCESS_MODE_INHERIT and hut.process_mode == Node.PROCESS_MODE_INHERIT and claim.is_processing(), "")
	claim.queue_free()
	hut.queue_free()
	chunk.queue_free()


func _test_same_hut_and_stagger() -> void:
	var main := FakeMain.new()
	main.add_to_group("main")
	root.add_child(main)
	var people := Node2D.new()
	main.add_child(people)
	main.npcs_container = people
	var watcher := Node2D.new()
	main.add_child(watcher)
	main.player = watcher
	var claim := LandClaim.new()
	claim.clan_name = "HUTS"
	claim.player_owned = false
	root.add_child(claim)
	watcher.global_position = claim.global_position
	var oven := BuildingBase.new()
	oven.building_type = ResourceData.ResourceType.LIVING_HUT
	oven.hut_specialty = "oven"
	oven.clan_name = "HUTS"
	root.add_child(oven)
	oven.global_position = claim.global_position + Vector2(80, 0)
	var crop := BuildingBase.new()
	crop.building_type = ResourceData.ResourceType.LIVING_HUT
	crop.hut_specialty = "crop"
	crop.clan_name = "HUTS"
	root.add_child(crop)
	crop.global_position = claim.global_position + Vector2(-80, 0)
	var index: Node = root.get_node("ClaimBuildingIndex")
	index.call("register_building", oven, claim)
	index.call("register_building", crop, claim)
	var oven_id := str(oven.get_meta("hut_net_id"))
	var crop_id := str(crop.get_meta("hut_net_id"))
	var brain = claim.clan_brain
	brain.is_dormant = true
	var roster = preload("res://scripts/systems/settlement_roster.gd").new()
	brain.roster = roster
	roster.clan_name = "HUTS"
	var members: Array = []
	members.append({"id": 1, "type": "woman", "npc_type": "woman", "name": "OvenW", "alive": true, "hunger": 90.0, "away": false, "home_hut_id": oven_id, "position": claim.global_position})
	members.append({"id": 2, "type": "woman", "npc_type": "woman", "name": "CropW", "alive": true, "hunger": 90.0, "away": false, "home_hut_id": crop_id, "position": claim.global_position})
	members.append({"id": 3, "type": "baby", "npc_type": "baby", "name": "Babe", "alive": true, "hunger": 90.0, "away": false, "mother_id": 1, "mother_name": "OvenW", "position": claim.global_position})
	for i in 10:
		members.append({"id": 10 + i, "type": "clansman", "npc_type": "clansman", "name": "M%d" % i, "alive": true, "hunger": 90.0, "away": false, "position": claim.global_position})
	roster.members = members
	brain._write_record_places()
	var baby_pos: Vector2 = roster.find_member(3).get("position", Vector2.ZERO)
	var mother_pos: Vector2 = roster.find_member(1).get("position", Vector2.ZERO)
	_check("a baby place stays with her mother", baby_pos.distance_to(mother_pos) < 40.0 and baby_pos.distance_to(claim.global_position) > 40.0, "baby=%s mother=%s" % [baby_pos, mother_pos])
	var first: Dictionary = brain._materialize_people_from_record()
	var spawned_first := 0
	for n in get_nodes_in_group("npcs"):
		if is_instance_valid(n) and str(n.get("clan_name")) == "HUTS":
			spawned_first += 1
	_check("the first materialize spawns at most 4", int(first.get("spawned", 0)) <= 4 and spawned_first <= 4, str(first))
	var babe_live := false
	for n in get_nodes_in_group("npcs"):
		if is_instance_valid(n) and str(n.get("npc_name")) == "Babe":
			babe_live = true
	_check("the baby waits until a later batch", not babe_live, "")
	brain._materialize_people_from_record()
	var spawned_second := 0
	for n in get_nodes_in_group("npcs"):
		if is_instance_valid(n) and str(n.get("clan_name")) == "HUTS":
			spawned_second += 1
	_check("the next call spawns more people", spawned_second > spawned_first, "%d -> %d" % [spawned_first, spawned_second])
	brain.materialize_clan_for_combat()
	var after_stamp := 0
	for n in get_nodes_in_group("npcs"):
		if is_instance_valid(n) and str(n.get("clan_name")) == "HUTS":
			after_stamp += 1
	brain.materialize_clan_for_combat()
	var after_again := 0
	for n in get_nodes_in_group("npcs"):
		if is_instance_valid(n) and str(n.get("clan_name")) == "HUTS":
			after_again += 1
	_check("the short debounce does not freeze the rest of the roster", after_again > after_stamp, "%d -> %d" % [after_stamp, after_again])
	for _i in 8:
		brain.materialize_clan_for_combat()
	var oven_woman: Node = null
	var crop_woman: Node = null
	for n in get_nodes_in_group("npcs"):
		if not is_instance_valid(n):
			continue
		if str(n.get("npc_name")) == "OvenW":
			oven_woman = n
		elif str(n.get("npc_name")) == "CropW":
			crop_woman = n
	var occ: Node = root.get_node("OccupationSystem")
	var oven_home: Node = occ.call("get_home_living_hut", oven_woman) if oven_woman else null
	var crop_home: Node = occ.call("get_home_living_hut", crop_woman) if crop_woman else null
	_check("each woman is back on her own hut", oven_home == oven and crop_home == crop, "oven=%s crop=%s" % [oven_home, crop_home])
	claim.queue_free()
	oven.queue_free()
	crop.queue_free()
	main.queue_free()


func _test_no_early_village() -> void:
	var camps: Node = root.get_node("OffscreenCamps")
	var claim := LandClaim.new()
	claim.clan_name = "FAR"
	claim.player_owned = false
	var chunk := Node2D.new()
	root.add_child(chunk)
	chunk.add_child(claim)
	claim.global_position = Vector2(9000, 9000)
	var brain = claim.clan_brain
	brain.is_dormant = true
	var roster = preload("res://scripts/systems/settlement_roster.gd").new()
	brain.roster = roster
	roster.members = [{"id": 5, "type": "woman", "npc_type": "woman", "name": "FarW", "alive": true, "hunger": 90.0, "away": false, "position": claim.global_position}]
	camps.call("park_claim", claim, Vector2i(15, 15))
	var before := 0
	for n in get_nodes_in_group("npcs"):
		if is_instance_valid(n) and str(n.get("npc_name")) == "FarW":
			before += 1
	camps.call("restore_chunk", Vector2i(15, 15), chunk)
	var after := 0
	for n in get_nodes_in_group("npcs"):
		if is_instance_valid(n) and str(n.get("npc_name")) == "FarW":
			after += 1
	_check("a far restore puts the camp back and spawns nobody", claim.get_parent() == chunk and after == before, "before=%d after=%d" % [before, after])
	claim.queue_free()
	chunk.queue_free()


func _check(name: String, ok: bool, detail: String) -> void:
	if ok:
		_passed += 1
		print("PASS %s" % name)
	else:
		_failed += 1
		print("FAIL %s %s" % [name, detail])
