extends SceneTree
## Off-screen camp park/restore through the real chunk unload and settlement clock.
## Run: godot --path . --headless -s res://tools/test_offscreen_camps.gd

const HutSpecialtyScript = preload("res://scripts/buildings/hut_specialty.gd")
const ChunkUtilsScript = preload("res://scripts/world/chunk_utils.gd")

const CLAN := "OFFSCREEN"
const CHUNK := Vector2i(3, 2)

var _passed := 0
var _failed := 0


class FakeMain extends Node2D:
	var npcs_container: Node = null
	var player: Node2D = null
	var spawned: Array = []
	func spawn_npc_from_sleep_data(data: Dictionary, parent: Node) -> void:
		var body := NPCBase.new()
		body.npc_type = str(data.get("npc_type", "woman"))
		body.clan_name = str(data.get("clan_name", ""))
		body.npc_name = str(data.get("name", "restored"))
		parent.add_child(body)
		body.add_to_group("npcs")
		spawned.append(body)


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	print("=== OFFSCREEN_CAMPS_TEST start ===")
	var log_path := "user://offscreen_camps_test.jsonl"
	var pi: Node = root.get_node("PlaytestInstrumentor")
	pi.set("_enabled", true)
	pi.set("_file", FileAccess.open(log_path, FileAccess.WRITE))
	pi.set("_start_time", Time.get_ticks_msec() / 1000.0)

	var camps: Node = root.get_node("OffscreenCamps")
	var cm: Node = root.get_node("ChunkManager")
	var index: Node = root.get_node("ClaimBuildingIndex")

	var main := FakeMain.new()
	main.add_to_group("main")
	root.add_child(main)
	var people := Node2D.new()
	main.add_child(people)
	main.npcs_container = people
	var world_objects := Node2D.new()
	main.add_child(world_objects)

	var origin := Vector2(CHUNK) * ChunkUtilsScript.CHUNK_SIZE
	var chunk_root := Node2D.new()
	chunk_root.name = "Chunk_test"
	world_objects.add_child(chunk_root)
	var claim := LandClaim.new()
	claim.clan_name = CLAN
	claim.player_owned = false
	chunk_root.add_child(claim)
	claim.global_position = origin + Vector2(1000, 1000)
	var stock := claim.inventory
	stock.add_item(ResourceData.ResourceType.BERRIES, 200)

	var hut := BuildingBase.new()
	hut.building_type = ResourceData.ResourceType.LIVING_HUT
	hut.clan_name = CLAN
	world_objects.add_child(hut)
	hut.global_position = claim.global_position + Vector2(120, 0)
	hut.hut_specialty = "crop"
	index.call("register_building", hut, claim)
	var oven := BuildingBase.new()
	oven.building_type = ResourceData.ResourceType.LIVING_HUT
	oven.clan_name = CLAN
	world_objects.add_child(oven)
	oven.global_position = claim.global_position + Vector2(-120, 0)
	oven.hut_specialty = "oven"
	index.call("register_building", oven, claim)

	var woman := NPCBase.new()
	woman.npc_type = "woman"
	woman.clan_name = CLAN
	woman.npc_name = "OffWoman"
	woman.add_to_group("npcs")
	world_objects.add_child(woman)
	woman.global_position = claim.global_position + Vector2(40, 40)

	var id_a := str(hut.get_meta("hut_net_id", ""))
	var id_b := str(oven.get_meta("hut_net_id", ""))
	_check("two huts of one claim get different stable ids", id_a != "" and id_b != "" and id_a != id_b, "%s %s" % [id_a, id_b])

	await process_frame
	await process_frame

	# Real unload path: park, sleep women onto the parked roster, free the chunk root.
	cm.set("_main", main)
	(cm.get("_loaded") as Dictionary)[CHUNK] = chunk_root
	cm.call("_unload_chunk", CHUNK)
	await process_frame
	await process_frame

	_check("claim survives the chunk being freed", is_instance_valid(claim) and claim.get_parent() == camps, str(claim.get_parent() if is_instance_valid(claim) else "freed"))
	_check("chunk root is freed", not is_instance_valid(chunk_root), "")
	_check("both huts moved with the claim", hut.get_parent() == camps and oven.get_parent() == camps, "")
	_check("claim and huts stop processing and hide", not claim.is_processing() and not hut.is_processing() and not oven.is_processing() and not claim.visible and not hut.visible, "")
	_check("the woman was freed by the sleep path", not is_instance_valid(woman), "")
	var brain = claim.clan_brain
	var women_on_roster := 0
	if brain and brain.roster:
		for m in brain.roster.members:
			if str(m.get("type", "")) == "woman" and bool(m.get("alive", false)):
				women_on_roster += 1
	_check("the woman is kept on the parked roster", women_on_roster == 1, str(women_on_roster))
	_check("brain is dormant with no walk requests", brain.is_dormant and brain.work_requests.is_empty(), "")
	_check("a parked camp is found for its chunk", bool(camps.call("has_parked_chunk", CHUNK)), "")

	# Time passes off-screen: drive only the OffscreenCamps clock.
	var interval: float = maxf(float(root.get_node("WorldGenConfig").get("settlement_tick_interval_sec")), 1.0)
	var grain_before: int = hut.inventory.get_count(ResourceData.ResourceType.GRAIN) + stock.get_count(ResourceData.ResourceType.GRAIN)
	var berries_before: int = stock.get_count(ResourceData.ResourceType.BERRIES)
	for _i in 12:
		camps._process(interval)
	var grain_after: int = hut.inventory.get_count(ResourceData.ResourceType.GRAIN) + stock.get_count(ResourceData.ResourceType.GRAIN)
	var berries_after: int = stock.get_count(ResourceData.ResourceType.BERRIES)
	_check("crop hut grows grain while parked", grain_after > grain_before, "%d -> %d" % [grain_before, grain_after])
	_check("clan eats from the pantry while parked", berries_after != berries_before, "%d -> %d" % [berries_before, berries_after])
	_check("asleep haul moved crop grain to the claim or oven", stock.get_count(ResourceData.ResourceType.GRAIN) > 0 or oven.inventory.get_count(ResourceData.ResourceType.GRAIN) > 0, "claim=%d oven=%d hut=%d" % [stock.get_count(ResourceData.ResourceType.GRAIN), oven.inventory.get_count(ResourceData.ResourceType.GRAIN), hut.inventory.get_count(ResourceData.ResourceType.GRAIN)])

	# Reload: same nodes come back, people respawn from the roster.
	var new_root := Node2D.new()
	world_objects.add_child(new_root)
	var restored: bool = bool(camps.call("restore_chunk", CHUNK, new_root))
	await process_frame
	var claims := 0
	for n in get_nodes_in_group("land_claims"):
		if is_instance_valid(n) and str(n.get("clan_name")) == CLAN:
			claims += 1
	var women := 0
	for n in get_nodes_in_group("npcs"):
		if is_instance_valid(n) and not n.is_queued_for_deletion() and str(n.get("clan_name")) == CLAN and str(n.get("npc_type")) == "woman":
			women += 1
	_check("load restores the same claim and huts", restored and claim.get_parent() == new_root and hut.get_parent() == new_root and oven.get_parent() == new_root, "")
	_check("restored claim and huts process and show again", claim.is_processing() and hut.is_processing() and claim.visible and hut.visible, "")
	_check("one claim for the clan after load", claims == 1, str(claims))
	_check("exactly one woman after load", women == 1, str(women))
	_check("nothing is left parked for that chunk", not bool(camps.call("has_parked_chunk", CHUNK)), "")

	# A player-owned claim is never parked.
	var own_root := Node2D.new()
	world_objects.add_child(own_root)
	var own := LandClaim.new()
	own.clan_name = "PLAYERCLAN"
	own.player_owned = true
	own_root.add_child(own)
	camps.call("park_chunk_root", own_root, Vector2i(7, 7))
	_check("player claim is not parked", own.get_parent() == own_root and not bool(camps.call("has_parked_chunk", Vector2i(7, 7))), "")

	# Stock that arrives on a client before the hut exists is applied when the hut registers.
	camps.call("stash_stock", "LATE#1", CLAN, [{"type": int(ResourceData.ResourceType.BREAD), "count": 3}], [])
	var late := BuildingBase.new()
	late.building_type = ResourceData.ResourceType.LIVING_HUT
	late.clan_name = CLAN
	world_objects.add_child(late)
	late.set_meta("hut_net_id", "LATE#1")
	index.call("register_building", late, claim)
	_check("stashed stock is applied when the hut registers", late.inventory.get_count(ResourceData.ResourceType.BREAD) == 3, str(late.inventory.get_count(ResourceData.ResourceType.BREAD)))

	(pi.get("_file") as FileAccess).flush()
	var text := FileAccess.get_file_as_string(log_path)
	_check("camp_parked is logged", text.contains("\"evt\":\"camp_parked\"") and text.contains(CLAN), "")
	_check("camp_restored is logged", text.contains("\"evt\":\"camp_restored\""), "")
	pi.set("_enabled", false)

	print("OFFSCREEN_CAMPS_TEST passed=%d failed=%d" % [_passed, _failed])
	quit(0 if _failed == 0 else 1)


func _check(name: String, ok: bool, detail: String) -> void:
	if ok:
		_passed += 1
		print("PASS %s" % name)
	else:
		_failed += 1
		print("FAIL %s %s" % [name, detail])
