extends SceneTree
## Eval camp layout: player claim + 2 huts + food, 3 AI cavemen, 8 women.
## Run: godot --path . --headless --eval-camp -s res://tools/test_eval_camp.gd

const LIVING_HUT_TYPE := 11
const PLAYER_CLAN := "EVALCAMP"

var _passed := 0
var _failed := 0


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	print("=== EVAL_CAMP_TEST start ===")
	var err := change_scene_to_file("res://scenes/Main.tscn")
	if err != OK:
		_fail("load Main.tscn", "err=%s" % err)
		_summary()
		quit(1)
		return
	for _i in 180:
		await process_frame
		var main: Node = get_first_node_in_group("main")
		if main == null:
			main = root.get_node_or_null("Main")
		if main and bool(main.get_meta("eval_camp_ready", false)):
			break
	_test_player_claim_food_and_huts()
	_test_headcounts()
	_summary()
	quit(0 if _failed == 0 else 1)


func _player_claim() -> Node:
	for claim in get_nodes_in_group("land_claims"):
		if not is_instance_valid(claim):
			continue
		if bool(claim.get("player_owned")):
			return claim
		var clan: String = str(claim.get("clan_name") if claim.get("clan_name") != null else "")
		if clan.to_upper() == PLAYER_CLAN:
			return claim
	return null


func _food_total(inv: Variant) -> int:
	if inv == null or not inv.has_method("get_count"):
		return 0
	var types: Array[int] = [3, 5, 7, 17, 19, 28, 29, 30]
	var total := 0
	for t in types:
		total += int(inv.get_count(t))
	return total


func _hut_count_for_clan(clan_u: String) -> int:
	var n := 0
	for node in get_nodes_in_group("buildings"):
		if not is_instance_valid(node):
			continue
		var raw: Variant = node.get("building_type")
		if raw == null:
			continue
		if int(raw) != LIVING_HUT_TYPE:
			continue
		var bc: String = str(node.get("clan_name") if node.get("clan_name") != null else "").to_upper()
		if bc == clan_u:
			n += 1
	return n


func _test_player_claim_food_and_huts() -> void:
	var claim := _player_claim()
	if claim == null:
		_fail("player claim exists")
		return
	_pass("player claim exists")
	var food := _food_total(claim.get("inventory"))
	if food >= 3:
		_pass("player claim has food (%d)" % food)
	else:
		_fail("player claim has food", "total=%d" % food)
	var huts := _hut_count_for_clan(str(claim.get("clan_name")).to_upper())
	if huts >= 2:
		_pass("player claim has 2 Living Huts (%d)" % huts)
	else:
		_fail("player claim has 2 Living Huts", "count=%d" % huts)


func _test_headcounts() -> void:
	var women := 0
	var cavemen := 0
	var claims := 0
	for npc in get_nodes_in_group("npcs"):
		if not is_instance_valid(npc):
			continue
		var t: String = str(npc.get("npc_type") if npc.get("npc_type") != null else "")
		if t == "woman":
			women += 1
		elif t == "caveman":
			cavemen += 1
	for claim in get_nodes_in_group("land_claims"):
		if is_instance_valid(claim):
			claims += 1
	if cavemen == 3:
		_pass("3 AI cavemen")
	else:
		_fail("3 AI cavemen", "count=%d" % cavemen)
	if women == 8:
		_pass("8 clan women (2 per man)")
	else:
		_fail("8 clan women", "count=%d" % women)
	var awake_ai := 0
	for npc in get_nodes_in_group("npcs"):
		if not is_instance_valid(npc):
			continue
		if str(npc.get("npc_type")) != "caveman":
			continue
		if npc.has_method("is_sim_dormant") and not bool(npc.call("is_sim_dormant")):
			awake_ai += 1
	if awake_ai >= 3:
		_pass("3 AI cavemen sim-awake (%d)" % awake_ai)
	else:
		_fail("3 AI cavemen sim-awake", "count=%d" % awake_ai)
	if claims >= 4:
		_pass("4 land claims (player + 3 AI) got %d" % claims)
	else:
		_fail("4 land claims", "count=%d" % claims)
	var player_food := 0
	var pc: Node = _player_claim()
	if pc:
		player_food = _food_total(pc.get("inventory"))
	var ai_food_ok := 0
	var min_sep := INF
	var player_pos := Vector2.ZERO
	if pc is Node2D:
		player_pos = (pc as Node2D).global_position
	var ai_pos: Array[Vector2] = []
	for claim in get_nodes_in_group("land_claims"):
		if not is_instance_valid(claim) or claim == pc:
			continue
		if bool(claim.get("player_owned")):
			continue
		if _food_total(claim.get("inventory")) == player_food and player_food >= 3:
			ai_food_ok += 1
		if claim is Node2D:
			ai_pos.append((claim as Node2D).global_position)
	if ai_food_ok >= 3:
		_pass("AI claims match player pantry (%d items)" % player_food)
	else:
		_fail("AI claims match player pantry", "matched=%d player_food=%d" % [ai_food_ok, player_food])
	for i in range(ai_pos.size()):
		min_sep = minf(min_sep, ai_pos[i].distance_to(player_pos))
		for j in range(i + 1, ai_pos.size()):
			min_sep = minf(min_sep, ai_pos[i].distance_to(ai_pos[j]))
	if min_sep >= 1500.0:
		_pass("AI camps spread out (min sep %.0fpx)" % min_sep)
	else:
		_fail("AI camps spread out", "min sep=%.0f" % min_sep)


func _pass(label: String) -> void:
	_passed += 1
	print("  PASS: %s" % label)


func _fail(label: String, detail: String = "") -> void:
	_failed += 1
	print("  FAIL: %s — %s" % [label, detail])


func _summary() -> void:
	print("=== EVAL_CAMP_TEST: %d passed, %d failed ===" % [_passed, _failed])
	if _failed == 0:
		print("TEST_EVAL_CAMP_PASS")
	else:
		print("TEST_EVAL_CAMP_FAIL")
