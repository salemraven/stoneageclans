extends SceneTree
## Real Main scene: walk away until an AI camp's chunk unloads, come back, and check it is the same camp.
## Run: godot --path . --headless -s res://tools/test_offscreen_camps_e2e.gd -- --skip-single-instance

var _passed := 0
var _failed := 0


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	print("=== OFFSCREEN_CAMPS_E2E start ===")
	if change_scene_to_file("res://scenes/Main.tscn") != OK:
		_check("load Main", false, "")
		_finish()
		return
	await _wait_real(4000)
	var main: Node = get_first_node_in_group("main")
	var player: Node2D = main.get("player") as Node2D if main else null
	if player == null:
		_check("player exists", false, "")
		_finish()
		return
	var camps: Node = root.get_node("OffscreenCamps")
	var index: Node = root.get_node("ClaimBuildingIndex")
	var claim: Node = _first_ai_claim()
	if claim == null:
		# Walk around until a seeded AI camp streams in.
		var home := player.global_position
		for step in 12:
			player.global_position = home + Vector2(2048.0 * float(step + 1), 2048.0 * float(step % 3))
			await _wait_real(1500)
			claim = _first_ai_claim()
			if claim:
				break
	_check("an AI camp is loaded", claim != null, "")
	if claim == null:
		_finish()
		return
	var clan: String = str(claim.get("clan_name"))
	var claim_id := claim.get_instance_id()
	var huts: Array = index.call("get_buildings_in_claim", claim) as Array
	var hut_ids: Array = []
	for h in huts:
		hut_ids.append((h as Node).get_instance_id())
	var camp_pos: Vector2 = (claim as Node2D).global_position
	print("E2E camp clan=%s huts=%d pos=%s" % [clan, huts.size(), camp_pos])
	var women_before := _count_people(clan, "woman")

	player.global_position = camp_pos + Vector2(2048.0 * 40.0, 0.0)
	var parked := false
	for _i in 40:
		await _wait_real(250)
		if is_instance_valid(claim) and claim.get_parent() == camps:
			parked = true
			break
	_check("walking away parks the camp", parked, "parent=%s" % (claim.get_parent() if is_instance_valid(claim) else "freed"))
	var huts_parked := true
	for h in huts:
		if not is_instance_valid(h) or (h as Node).get_parent() != camps:
			huts_parked = false
	_check("its huts are parked with it", huts_parked, "")
	_check("its women are off the map while parked", _count_people(clan, "woman") == 0, str(_count_people(clan, "woman")))
	var roster_women := 0
	var brain = claim.get("clan_brain")
	if brain and brain.roster:
		for m in brain.roster.members:
			if str(m.get("type", "")) == "woman" and bool(m.get("alive", false)):
				roster_women += 1
	_check("women are kept on the parked roster", roster_women >= women_before and roster_women > 0, "before=%d roster=%d" % [women_before, roster_women])
	var parked_owner: Variant = claim.get("owner_npc")
	_check("parked claim holds no freed leader", typeof(parked_owner) == TYPE_NIL or is_instance_valid(parked_owner), "")

	await _wait_real(3000)

	player.global_position = camp_pos + Vector2(64.0, 64.0)
	var restored := false
	for _i in 40:
		await _wait_real(250)
		if is_instance_valid(claim) and claim.get_parent() != camps and claim.get_parent() != null:
			restored = true
			break
	await _wait_real(1000)
	_check("coming back restores the camp", restored, "")
	var same_claims := 0
	for n in get_nodes_in_group("land_claims"):
		if is_instance_valid(n) and str(n.get("clan_name")) == clan:
			same_claims += 1
	_check("one claim for that clan, the same node", same_claims == 1 and is_instance_valid(claim) and claim.get_instance_id() == claim_id, str(same_claims))
	var same_huts := true
	for h in huts:
		if not is_instance_valid(h) or (h as Node).get_parent() == camps or not (h as Node).is_processing():
			same_huts = false
	_check("same huts are back and processing", same_huts and hut_ids.size() == huts.size(), "")
	var women_after := _count_people(clan, "woman")
	_check("women respawn from the roster with no duplicates", women_after == roster_women, "roster=%d live=%d" % [roster_women, women_after])
	var leader: Variant = claim.get("owner_npc")
	_check("restored claim points at the respawned leader", leader is Node and is_instance_valid(leader) and str((leader as Node).get("clan_name")).to_lower() == clan.to_lower(), str(leader))
	_finish()


func _first_ai_claim() -> Node:
	for n in get_nodes_in_group("land_claims"):
		if not is_instance_valid(n) or not (n is LandClaim):
			continue
		if bool(n.get("player_owned")):
			continue
		if n.get("clan_brain") == null:
			continue
		return n
	return null


func _count_people(clan: String, npc_type: String) -> int:
	var count := 0
	for n in get_nodes_in_group("npcs"):
		if not is_instance_valid(n) or n.is_queued_for_deletion():
			continue
		if str(n.get("clan_name")).to_lower() != clan.to_lower():
			continue
		if str(n.get("npc_type")) == npc_type:
			count += 1
	return count


func _wait_real(ms: int) -> void:
	var end := Time.get_ticks_msec() + ms
	while Time.get_ticks_msec() < end:
		await process_frame


func _finish() -> void:
	print("OFFSCREEN_CAMPS_E2E passed=%d failed=%d" % [_passed, _failed])
	quit(0 if _failed == 0 else 1)


func _check(name: String, ok: bool, detail: String) -> void:
	if ok:
		_passed += 1
		print("PASS %s" % name)
	else:
		_failed += 1
		print("FAIL %s %s" % [name, detail])
