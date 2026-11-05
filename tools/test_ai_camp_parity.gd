extends SceneTree
## Dormant camps herd, build, birth, and craft on the settlement slice.
## Run: godot --path . --headless -s res://tools/test_ai_camp_parity.gd

const SettlementRosterScript = preload("res://scripts/systems/settlement_roster.gd")
const DormantProgressScript = preload("res://scripts/systems/dormant_camp_progress.gd")
const ChunkGeneratorScript = preload("res://scripts/world/chunk_generator.gd")
const AbstractGatherScript = preload("res://scripts/systems/abstract_gather.gd")
const HutStateScript = preload("res://scripts/npc/states/build_hut_for_woman_state.gd")

var _passed := 0
var _failed := 0
var _claim_n := 0


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	print("=== AI_CAMP_PARITY start ===")
	var err := change_scene_to_file("res://scenes/Main.tscn")
	if err != OK:
		_fail("load Main.tscn", "err=%s" % err)
		_summary()
		quit(1)
		return
	for _i in 8:
		await process_frame
	_test_herd_pace()
	_test_one_owner()
	_test_hut_birth_growth()
	_test_two_women_second_hut()
	_test_farm_milestone()
	_test_gather_log()
	_summary()
	quit(0 if _failed == 0 else 1)


func _test_herd_pace() -> void:
	var trip_400 := DormantProgressScript.trip_seconds(400.0)
	var brain := _brain_with(["Tor"], [400.0])
	_slice(brain, 1.0)
	if _women(brain) == 0:
		_pass("one second does not deliver")
	else:
		_fail("one second does not deliver", "women=%d" % _women(brain))
	_slice(brain, trip_400)
	if _women(brain) == 1 and _huts(brain.territory).is_empty():
		_pass("one trip delivers and does not place the hut", "trip=%.2f" % trip_400)
	else:
		_fail("one trip delivers and does not place the hut", "women=%d huts=%d" % [_women(brain), _huts(brain.territory).size()])
	_free(brain)

	brain = _brain_with(["Tor"], [400.0, 500.0, 700.0])
	_slice(brain, DormantProgressScript.trip_seconds(400.0))
	if _women(brain) == 1:
		_pass("one slot delivers one woman per trip")
	else:
		_fail("one slot delivers one woman per trip", "women=%d" % _women(brain))
	_free(brain)

	brain = _brain_with(["Tor", "Ren"], [400.0, 400.0, 400.0])
	_slice(brain, DormantProgressScript.trip_seconds(400.0))
	if _women(brain) == 2:
		_pass("two slots deliver two women, not three")
	else:
		_fail("two slots deliver two women, not three", "women=%d" % _women(brain))
	_free(brain)

	brain = _brain_with(["Tor"], [1701.0])
	_slice(brain, DormantProgressScript.trip_seconds(1701.0) * 3.0)
	if _women(brain) == 0:
		_pass("woman past herd range is not recruited")
	else:
		_fail("woman past herd range is not recruited", "women=%d" % _women(brain))
	_free(brain)

	brain = _brain_with(["Tor"], [400.0])
	brain.territory.set_meta("parity_herd_candidates", [
		_animal("sheep", brain.territory.global_position + Vector2(400, 0), "near_sheep"),
		_animal("woman", brain.territory.global_position + Vector2(500, 0), "near_woman"),
	])
	_slice(brain, DormantProgressScript.trip_seconds(500.0))
	if _women(brain) == 1 and int(brain.roster.call("count_herd_animals", "sheep")) == 0:
		_pass("women are chosen before nearer sheep")
	else:
		_fail("women are chosen before nearer sheep", "women=%d sheep=%d" % [_women(brain), int(brain.roster.call("count_herd_animals", "sheep"))])
	_free(brain)

	var claim_pos := _next_pos()
	brain = _make_brain(["Tor", "Ren"], claim_pos)
	brain.territory.set_meta("parity_herd_candidates", [
		_animal("sheep", claim_pos + Vector2(500, 0), "s1"),
		_animal("goat", claim_pos + Vector2(600, 0), "g1"),
		_animal("woman", claim_pos + Vector2(1701, 0), "far"),
	])
	_slice(brain, DormantProgressScript.trip_seconds(600.0))
	var sheep := int(brain.roster.call("count_herd_animals", "sheep"))
	var goats := int(brain.roster.call("count_herd_animals", "goat"))
	if sheep == 1 and goats == 1 and _women(brain) == 0:
		_pass("sheep and goat join; a woman outside range is not a substitute")
	else:
		_fail("sheep and goat join; a woman outside range is not a substitute", "sheep=%d goats=%d women=%d" % [sheep, goats, _women(brain)])
	_free(brain)


func _test_one_owner() -> void:
	var pos := _next_pos()
	var woman := _spawn_wild("AwakeWoman", pos + Vector2(400, 0))
	var brain := _make_brain(["Tor"], pos)
	brain.is_dormant = false
	brain.territory.set_meta("parity_herd_candidates", [_woman_row(woman, "awake-key")])
	_slice(brain, DormantProgressScript.trip_seconds(400.0) * 3.0)
	if _women(brain) == 0 and str(woman.clan_name) == "":
		_pass("awake camp does not recruit")
	else:
		_fail("awake camp does not recruit", "women=%d clan=%s" % [_women(brain), str(woman.clan_name)])
	_free(brain)
	woman.queue_free()

	var gen := ChunkGeneratorScript.new()
	var wgc: Node = root.get_node("/root/WorldGenConfig")
	var old_chance := float(wgc.get("wild_woman_chunk_chance"))
	var old_max := int(wgc.get("wild_woman_per_chunk_max"))
	wgc.set("wild_woman_chunk_chance", 1.0)
	wgc.set("wild_woman_per_chunk_max", 1)
	var found: Dictionary = {}
	var found_chunk := Vector2i.ZERO
	for cx in 12:
		var data: Dictionary = gen.generate_chunk(int(wgc.world_seed), Vector2i(cx, 40), wgc)
		var women: Array = data.get("wild_women", [])
		if not women.is_empty():
			found = women[0]
			found_chunk = Vector2i(cx, 40)
			break
	if found.is_empty():
		_fail("chunk has a seeded woman", "no woman")
	else:
		var woman_pos: Vector2 = found.get("position", Vector2.ZERO)
		var live := _spawn_wild("SeedWoman", woman_pos)
		live.set_meta("herd_seed_key", str(found.get("seed_key", "")))
		var claim_pos := woman_pos + Vector2(-400, 0)
		brain = _make_brain(["Tor"], claim_pos)
		brain.territory.set_meta("parity_herd_candidates", [_woman_row(live, str(found.get("seed_key", "")))])
		_slice(brain, DormantProgressScript.trip_seconds(400.0))
		var again: Dictionary = gen.generate_chunk(int(wgc.world_seed), found_chunk, wgc)
		var still := false
		for row in again.get("wild_women", []):
			if str((row as Dictionary).get("seed_key", "")) == str(found.get("seed_key", "")):
				still = true
		if str(live.clan_name) != "" and not still:
			_pass("dormant tick claims the live woman and spends her seed")
		else:
			_fail("dormant tick claims the live woman and spends her seed", "clan=%s still_listed=%s" % [str(live.clan_name), str(still)])
		_free(brain)
	wgc.set("wild_woman_chunk_chance", old_chance)
	wgc.set("wild_woman_per_chunk_max", old_max)

	pos = _next_pos()
	brain = _make_brain(["Tor"], pos)
	brain.territory.player_owned = true
	brain.territory.set_meta("parity_herd_candidates", [_animal("woman", pos + Vector2(400, 0), "player-w")])
	_slice(brain, DormantProgressScript.trip_seconds(400.0) * 2.0 + 30.0)
	if _women(brain) == 0 and _huts(brain.territory).is_empty():
		_pass("player claim is not recruited or built for")
	else:
		_fail("player claim is not recruited or built for", "women=%d huts=%d" % [_women(brain), _huts(brain.territory).size()])
	_free(brain)


func _test_hut_birth_growth() -> void:
	var brain := _brain_with(["Tor"], [400.0])
	var trip := DormantProgressScript.trip_seconds(400.0)
	_slice(brain, trip)
	for _step in int(HutStateScript.BUILD_DURATION) - 1:
		_slice(brain, 1.0)
	if _huts(brain.territory).is_empty():
		_pass("hut waits out the build")
	else:
		_fail("hut waits out the build", "huts=%d" % _huts(brain.territory).size())
	_slice(brain, 1.0)
	var hut := _assigned_hut(brain)
	var dist := -1.0
	if hut is Node2D:
		dist = (hut as Node2D).global_position.distance_to(brain.territory.global_position)
	var radius := float(brain.territory.radius)
	if hut != null and dist >= HutStateScript.APPROACH_MIN_FROM_CLAIM and dist <= radius - 60.0:
		_pass("hut stands on the herder ring and she is assigned", "dist=%.1f" % dist)
	else:
		_fail("hut stands on the herder ring and she is assigned", "dist=%.1f hut=%s" % [dist, str(hut)])

	var preg := _balance("pregnancy_seconds", 15.0)
	var growth := _balance("baby_growth_seconds", 17.5)
	_slice(brain, 1.0)
	var timer := _pregnancy_timer(brain)
	if timer > 0.0:
		_pass("hut lets conception start")
	else:
		_fail("hut lets conception start", "timer=%s" % str(timer))
	_slice(brain, preg)
	if _babies(brain) == 1:
		_pass("birth at pregnancy_seconds")
	else:
		_fail("birth at pregnancy_seconds", "babies=%d" % _babies(brain))
	_slice(brain, growth)
	if _babies(brain) == 0 and _clansmen(brain) >= 2:
		_pass("baby grows into a clansman")
	else:
		_fail("baby grows into a clansman", "babies=%d clansmen=%d" % [_babies(brain), _clansmen(brain)])
	_free(brain)

	brain = _make_brain(["Dad"], _next_pos())
	brain.territory.set_meta("parity_herd_candidates", [])
	brain.roster.members.append({
		"id": 50, "name": "NoHut", "type": "woman", "alive": true, "hunger": 100.0,
		"pregnancy_timer": -1.0, "designated_father_id": 1, "last_birth_time": -1.0,
		"is_player": false, "npc_type": "woman", "awaiting_hut": false,
	})
	_slice(brain, preg + growth + 5.0)
	if _babies(brain) == 0:
		_pass("no hut means no birth")
	else:
		_fail("no hut means no birth", "babies=%d" % _babies(brain))
	_free(brain)


func _test_two_women_second_hut() -> void:
	var brain := _brain_with(["Tor"], [400.0, 400.0])
	var trip := DormantProgressScript.trip_seconds(400.0)
	var preg := _balance("pregnancy_seconds", 15.0)
	var queued: Array = brain.territory.get_meta("parity_herd_candidates")
	var second_row: Dictionary = (queued[1] as Dictionary).duplicate()
	_slice(brain, trip)
	var first_id := _woman_id(brain)
	brain.territory.set_meta("parity_herd_candidates", [])
	for _step in int(HutStateScript.BUILD_DURATION):
		_slice(brain, 1.0)
	_slice(brain, 1.0)
	_slice(brain, preg)
	if _huts(brain.territory).size() == 1 and _children_of(brain, first_id) == 1:
		_pass("first woman births from her hut")
	else:
		_fail("first woman births from her hut", "women=%d huts=%d children=%d" % [_women(brain), _huts(brain.territory).size(), _children_of(brain, first_id)])
	brain.territory.set_meta("parity_herd_candidates", [second_row])
	brain.roster.members.append({
		"id": 80, "name": "Ren", "type": "clansman", "alive": true, "hunger": 100.0,
		"is_player": false, "npc_type": "clansman", "away": false,
	})
	_slice(brain, trip)
	var second_id := _awaiting_woman_id(brain)
	if _women(brain) == 2 and _huts(brain.territory).size() == 1 and _children_of(brain, second_id) == 0:
		_pass("second birth waits while her hut is unfinished")
	else:
		_fail("second birth waits while her hut is unfinished", "women=%d huts=%d second=%d children=%d" % [_women(brain), _huts(brain.territory).size(), second_id, _children_of(brain, second_id)])
	_slice(brain, HutStateScript.BUILD_DURATION)
	if _huts(brain.territory).size() == 2 and _children_of(brain, second_id) == 1:
		_pass("second hut allows the second birth")
	else:
		_fail("second hut allows the second birth", "huts=%d children=%d" % [_huts(brain.territory).size(), _children_of(brain, second_id)])
	_free(brain)


func _test_farm_milestone() -> void:
	var duration := _balance("ai_milestone_build_duration_sec", 18.0)
	var brain := _make_brain(["Tor"], _next_pos())
	brain.clan_members = []
	brain.roster.call("add_herd_animal", "sheep", "Woolly", "farm-sheep")
	brain.territory.set_meta("parity_herd_candidates", [])
	brain.territory.inventory.add_item(ResourceData.ResourceType.FIBER, 4)
	_slice(brain, maxf(duration - 0.5, 0.1))
	if _buildings(brain.territory, ResourceData.ResourceType.FARM).is_empty():
		_pass("farm is absent before the build duration")
	else:
		_fail("farm is absent before the build duration", "")
	_slice(brain, 1.0)
	var farms := _buildings(brain.territory, ResourceData.ResourceType.FARM)
	if farms.size() == 1:
		_pass("farm is present after the build duration")
	else:
		_fail("farm is present after the build duration", "farms=%d" % farms.size())
	if not farms.is_empty():
		var wool_before: int = int(farms[0].inventory.get_count(ResourceData.ResourceType.WOOL)) if farms[0].inventory else -1
		_slice(brain, _balance("wool_craft_time", 45.0))
		var wool_after: int = int(farms[0].inventory.get_count(ResourceData.ResourceType.WOOL)) if farms[0].inventory else -1
		if wool_after == wool_before + 1:
			_pass("next slice produces one farm output")
		else:
			_fail("next slice produces one farm output", "%d -> %d" % [wool_before, wool_after])
	_free(brain)

	brain = _make_brain(["Tor"], _next_pos())
	brain.clan_members = []
	brain.territory.set_meta("parity_herd_candidates", [])
	_slice(brain, duration + 2.0)
	if _buildings(brain.territory, ResourceData.ResourceType.FARM).is_empty():
		_pass("zero sheep does not build a farm")
	else:
		_fail("zero sheep does not build a farm", "")
	_free(brain)


func _test_gather_log() -> void:
	var roster = SettlementRosterScript.new()
	roster.clan_name = "GATHERLOG"
	roster.members = [
		{"id": 1, "name": "A", "type": "clansman", "alive": true, "hunger": 100.0, "npc_type": "clansman"},
		{"id": 2, "name": "B", "type": "clansman", "alive": true, "hunger": 100.0, "npc_type": "clansman"},
	]
	var inv := InventoryData.new(8, true, 999)
	var claim := LandClaim.new()
	claim.clan_name = "GATHERLOG"
	claim.inventory = inv
	claim.global_position = _next_pos()
	root.add_child(claim)
	var events: Dictionary = AbstractGatherScript.gather_for_claim(claim, roster, Vector2i(9, 9), 30.0, false, 1)
	var gathered: Array = events.get("gathered", [])
	print("ABSTRACT_GATHER workers=2 elapsed=30 yield=%s" % str(gathered))
	if events.has("gathered"):
		_pass("abstract gather yield printed")
	else:
		_fail("abstract gather yield printed", str(events))
	claim.queue_free()


func _brain_with(fighters: Array, distances: Array) -> RefCounted:
	var pos := _next_pos()
	var brain := _make_brain(fighters, pos)
	var rows: Array = []
	for i in distances.size():
		rows.append(_animal("woman", pos + Vector2(float(distances[i]), 0), "w-%d-%d" % [_claim_n, i]))
	brain.territory.set_meta("parity_herd_candidates", rows)
	return brain


func _make_brain(fighters: Array, pos: Vector2) -> RefCounted:
	var claim := LandClaim.new()
	_claim_n += 1
	claim.clan_name = "PARITY%d" % _claim_n
	claim.player_owned = false
	claim.global_position = pos
	root.add_child(claim)
	var inv: InventoryData = claim.inventory
	inv.add_item(ResourceData.ResourceType.BERRIES, 400)
	inv.add_item(ResourceData.ResourceType.GRAIN, 40)
	var roster = SettlementRosterScript.new()
	roster.clan_name = claim.clan_name
	var members: Array = []
	for i in fighters.size():
		members.append({
			"id": i + 1,
			"name": str(fighters[i]),
			"type": "clansman",
			"alive": true,
			"hunger": 100.0,
			"is_player": false,
			"npc_type": "clansman",
			"away": false,
		})
	roster.members = members
	var brain := ClanBrain.new()
	brain.territory = claim
	brain.clan_name = claim.clan_name
	brain.roster = roster
	brain.is_dormant = true
	claim.clan_brain = brain
	claim.set_meta("food_days_buffer", 5.0)
	return brain


func _animal(kind: String, pos: Vector2, key: String) -> Dictionary:
	return {"type": kind, "position": pos, "name": key, "age": 22, "seed_key": key}


func _woman_row(node: Node, key: String) -> Dictionary:
	return {
		"type": "woman",
		"position": node.global_position,
		"name": str(node.npc_name),
		"age": 22,
		"seed_key": key,
		"node": node,
	}


func _spawn_wild(npc_name: String, pos: Vector2) -> Node:
	var npc: Node = load("res://scenes/NPC.tscn").instantiate()
	npc.set_npc_type("woman", "parity_test")
	npc.npc_name = npc_name
	npc.clan_name = ""
	root.add_child(npc)
	npc.global_position = pos
	return npc


func _slice(brain: RefCounted, elapsed: float) -> void:
	var asleep := 1
	if brain.roster:
		asleep = maxi(int(brain.roster.call("get_population")), 1)
	brain._run_settlement_slice(elapsed, {}, asleep)


func _women(brain: RefCounted) -> int:
	var n := 0
	for m in brain.roster.members:
		if m is Dictionary and str((m as Dictionary).get("type", "")) == "woman" and bool((m as Dictionary).get("alive", false)):
			n += 1
	return n


func _babies(brain: RefCounted) -> int:
	var n := 0
	for m in brain.roster.members:
		if m is Dictionary and str((m as Dictionary).get("type", "")) == "baby" and bool((m as Dictionary).get("alive", false)):
			n += 1
	return n


func _clansmen(brain: RefCounted) -> int:
	var n := 0
	for m in brain.roster.members:
		if m is Dictionary and str((m as Dictionary).get("type", "")) == "clansman" and bool((m as Dictionary).get("alive", false)):
			n += 1
	return n


func _woman_id(brain: RefCounted) -> int:
	for m in brain.roster.members:
		if m is Dictionary and str((m as Dictionary).get("type", "")) == "woman" and bool((m as Dictionary).get("alive", false)):
			return int((m as Dictionary).get("id", 0))
	return 0


func _awaiting_woman_id(brain: RefCounted) -> int:
	for m in brain.roster.members:
		if m is Dictionary and bool((m as Dictionary).get("awaiting_hut", false)):
			return int((m as Dictionary).get("id", 0))
	return 0


func _children_of(brain: RefCounted, mother_id: int) -> int:
	var n := 0
	for m in brain.roster.members:
		if m is Dictionary and int((m as Dictionary).get("mother_id", 0)) == mother_id and bool((m as Dictionary).get("alive", false)):
			n += 1
	return n


func _pregnancy_timer(brain: RefCounted) -> float:
	for m in brain.roster.members:
		if m is Dictionary and str((m as Dictionary).get("type", "")) == "woman":
			return float((m as Dictionary).get("pregnancy_timer", -1.0))
	return -1.0


func _huts(claim: Node) -> Array:
	return _buildings(claim, ResourceData.ResourceType.LIVING_HUT)


func _buildings(claim: Node, kind: int) -> Array:
	var out: Array = []
	for b in get_nodes_in_group("buildings"):
		if not is_instance_valid(b) or b is LandClaim:
			continue
		if str(b.get("clan_name")) == str(claim.get("clan_name")) and int(b.get("building_type")) == kind:
			out.append(b)
	return out


func _assigned_hut(brain: RefCounted) -> Node:
	var jobs: Node = root.get_node_or_null("/root/OccupationSystem")
	for n in get_nodes_in_group("npcs"):
		if not is_instance_valid(n):
			continue
		if str(n.get("npc_type")) != "woman":
			continue
		if n.has_meta("home_living_hut"):
			var home: Variant = n.get_meta("home_living_hut")
			if home is Node and is_instance_valid(home) and str(home.get("clan_name")) == brain.clan_name:
				return home
		if str(n.get("clan_name")) != brain.clan_name:
			continue
		if jobs and jobs.has_method("get_workplace"):
			var workplace: Node = jobs.get_workplace(n)
			if workplace and is_instance_valid(workplace):
				return workplace
	for hut in _huts(brain.territory):
		var slots: Variant = hut.get("woman_slots")
		if not (slots is Array):
			continue
		for seat in slots:
			if seat is Node and is_instance_valid(seat) and str(seat.get("clan_name")) == brain.clan_name:
				return hut
	return null


func _woman_node(brain: RefCounted) -> Node:
	for n in get_nodes_in_group("npcs"):
		if is_instance_valid(n) and str(n.get("clan_name")) == brain.clan_name and str(n.get("npc_type")) == "woman":
			return n
	return null


func _next_pos() -> Vector2:
	_claim_n += 1
	return Vector2(20000.0 + float(_claim_n) * 3000.0, 20000.0)


func _free(brain: RefCounted) -> void:
	if brain and brain.territory and is_instance_valid(brain.territory):
		brain.territory.queue_free()


func _balance(field: String, fallback: float) -> float:
	var bc: Node = root.get_node_or_null("/root/BalanceConfig")
	if bc and field in bc:
		return float(bc.get(field))
	return fallback


func _pass(label: String, detail: String = "") -> void:
	_passed += 1
	print("PASS %s %s" % [label, detail])


func _fail(label: String, detail: String) -> void:
	_failed += 1
	print("FAIL %s %s" % [label, detail])


func _summary() -> void:
	print("AI_CAMP_PARITY passed=%d failed=%d" % [_passed, _failed])
