extends SceneTree
## Quickstart Living Hut + pregnancy regression (food buffer, preg start, birth).
## Run: godot --path . --headless --session-quickstart -s res://tools/test_session_quickstart_huts.gd

const LIVING_HUT_TYPE := 11  # ResourceData.ResourceType.LIVING_HUT
const TEST_CLAN := "TEST"
const BIRTH_WAIT_MS := 14000  # session quickstart preg ≈10s + margin

var _passed := 0
var _failed := 0


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	print("=== SESSION_QUICKSTART_HUTS_TEST start ===")
	var err := change_scene_to_file("res://scenes/Main.tscn")
	if err != OK:
		_fail("load Main.tscn", "err=%s" % err)
		_summary()
		quit(1)
		return
	for _i in 90:
		await process_frame
	_test_qs_women_alive()
	_test_living_huts_assigned()
	_test_claim_has_food_for_reproduction()
	_test_pregnancies_started()
	await _wait_for_birth_or_timeout()
	_test_baby_born_without_starvation_cancel()
	_summary()
	quit(0 if _failed == 0 else 1)


func _find_test_claim() -> Node:
	for claim in get_nodes_in_group("land_claims"):
		if not is_instance_valid(claim):
			continue
		var clan: String = str(claim.get("clan_name") if claim.get("clan_name") != null else "")
		if clan.to_upper() == TEST_CLAN:
			return claim
	return null


func _food_total_in_inventory(inv: Variant) -> int:
	if inv == null or not inv.has_method("get_count"):
		return 0
	var types: Array[int] = [3, 5, 7, 22, 24, 33, 34, 35]  # berries, grain, meat, bread, milk, mushroom, bugs, nuts
	var total := 0
	for t in types:
		total += int(inv.get_count(t))
	return total


func _test_qs_women_alive() -> void:
	var found: Dictionary = {"QS_A": false, "QS_B": false}
	for npc in get_nodes_in_group("npcs"):
		if not is_instance_valid(npc):
			continue
		var name: String = str(npc.get("npc_name") if npc.get("npc_name") != null else "")
		if found.has(name):
			found[name] = true
	if found["QS_A"] and found["QS_B"]:
		_pass("QS_A and QS_B alive after bootstrap")
	else:
		_fail("QS_A and QS_B alive after bootstrap", str(found))


func _test_living_huts_assigned() -> void:
	var huts_with_woman := 0
	for node in get_nodes_in_group("buildings"):
		if not is_instance_valid(node):
			continue
		var btype = node.get("building_type")
		if btype == null or int(btype) != LIVING_HUT_TYPE:
			continue
		var occupant: Node = null
		if node.has_method("get_primary_occupant"):
			occupant = node.call("get_primary_occupant") as Node
		if occupant and is_instance_valid(occupant):
			huts_with_woman += 1
			continue
		if node.has_meta("assigned_woman"):
			var aw: Variant = node.get_meta("assigned_woman")
			if aw is Object and is_instance_valid(aw):
				huts_with_woman += 1
	if huts_with_woman >= 2:
		_pass("both Living Huts have valid woman refs (%d)" % huts_with_woman)
	else:
		_fail("both Living Huts have valid woman refs", "count=%d" % huts_with_woman)


func _test_claim_has_food_for_reproduction() -> void:
	var claim := _find_test_claim()
	if claim == null:
		_fail("claim has food for reproduction", "TEST claim not found")
		return
	var inv = claim.get("inventory")
	var total := _food_total_in_inventory(inv)
	if total >= 3:
		_pass("claim food stock for reproduction (%d items)" % total)
	else:
		_fail("claim food stock for reproduction", "total=%d need>=3" % total)
	var buf: float = -1.0
	if claim.has_meta("calories_days_buffer"):
		buf = float(claim.get_meta("calories_days_buffer"))
	elif claim.has_meta("food_days_buffer"):
		buf = float(claim.get_meta("food_days_buffer"))
	if buf < 0.0:
		_pass("food buffer meta not ready yet (inventory stocked)")
	elif buf >= 0.28:
		_pass("food buffer %.2f days (>= 0.28)" % buf)
	else:
		_fail("food buffer for pregnancy", "buffer=%.2f days" % buf)


func _test_pregnancies_started() -> void:
	var pregnant := 0
	for npc in get_nodes_in_group("npcs"):
		if not is_instance_valid(npc):
			continue
		var name: String = str(npc.get("npc_name") if npc.get("npc_name") != null else "")
		if name != "QS_A" and name != "QS_B":
			continue
		var rc: Node = npc.get_node_or_null("ReproductionComponent")
		if rc and bool(rc.get("is_pregnant")):
			pregnant += 1
	if pregnant >= 2:
		_pass("both QS women pregnant (%d)" % pregnant)
	elif pregnant >= 1:
		_pass("at least one QS woman pregnant (%d)" % pregnant)
	else:
		_fail("QS women pregnancy started", "pregnant=%d" % pregnant)


func _wait_for_birth_or_timeout() -> void:
	var deadline := Time.get_ticks_msec() + BIRTH_WAIT_MS
	while Time.get_ticks_msec() < deadline:
		if _count_clan_babies() > 0:
			break
		await process_frame


func _count_clan_babies() -> int:
	var n := 0
	for npc in get_nodes_in_group("npcs"):
		if not is_instance_valid(npc):
			continue
		var clan: String = str(npc.get("clan_name") if npc.get("clan_name") != null else "")
		if clan.to_upper() != TEST_CLAN:
			continue
		var t: String = str(npc.get("npc_type") if npc.get("npc_type") != null else "")
		if t == "baby":
			n += 1
	return n


func _test_baby_born_without_starvation_cancel() -> void:
	var babies := _count_clan_babies()
	if babies >= 1:
		_pass("baby born in TEST clan (%d)" % babies)
	else:
		var still_pregnant := 0
		for npc in get_nodes_in_group("npcs"):
			if not is_instance_valid(npc):
				continue
			var name: String = str(npc.get("npc_name") if npc.get("npc_name") != null else "")
			if name != "QS_A" and name != "QS_B":
				continue
			var rc: Node = npc.get_node_or_null("ReproductionComponent")
			if rc and bool(rc.get("is_pregnant")):
				still_pregnant += 1
		if still_pregnant > 0:
			_fail("baby born within %.1fs" % (float(BIRTH_WAIT_MS) / 1000.0), "still pregnant=%d" % still_pregnant)
		else:
			_fail("baby born — pregnancy ended without baby", "babies=0")


func _pass(label: String) -> void:
	_passed += 1
	print("  PASS: %s" % label)


func _fail(label: String, detail: String = "") -> void:
	_failed += 1
	print("  FAIL: %s — %s" % [label, detail])


func _summary() -> void:
	print("=== SESSION_QUICKSTART_HUTS_TEST: %d passed, %d failed ===" % [_passed, _failed])
