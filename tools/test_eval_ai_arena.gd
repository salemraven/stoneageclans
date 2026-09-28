extends SceneTree
## SKIP_SINGLE_INSTANCE=1 godot --path . --headless --eval-ai-arena -s res://tools/test_eval_ai_arena.gd

var _passed := 0
var _failed := 0


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	print("=== EVAL_AI_ARENA_TEST start ===")
	var err := change_scene_to_file("res://scenes/Main.tscn")
	if err != OK:
		_fail("load Main.tscn", "err=%s" % err)
		_summary()
		quit(1)
		return
	var main: Node = null
	for _i in 300:
		await process_frame
		main = get_first_node_in_group("main")
		if main == null:
			main = root.get_node_or_null("Main")
		if main and bool(main.get_meta("eval_ai_arena_ready", false)):
			break
	if main == null or not bool(main.get_meta("eval_ai_arena_ready", false)):
		_fail("arena ready", "meta missing")
		_summary()
		quit(1)
		return
	for _j in 12:
		await process_frame
	var claims := 0
	var cavemen := 0
	var women := 0
	var awake := 0
	for claim in get_nodes_in_group("land_claims"):
		if is_instance_valid(claim) and not bool(claim.get("player_owned")):
			claims += 1
	for npc in get_nodes_in_group("npcs"):
		if not is_instance_valid(npc):
			continue
		var t: String = str(npc.get("npc_type"))
		if t == "caveman":
			cavemen += 1
			if npc.has_method("is_sim_dormant") and not bool(npc.call("is_sim_dormant")):
				awake += 1
		elif t == "woman" and str(npc.get("clan_name")).strip_edges() != "":
			women += 1
	if claims == 4:
		_pass("4 AI land claims")
	else:
		_fail("4 AI land claims", "count=%d" % claims)
	if cavemen >= 20:
		_pass("AI cavemen parties (%d)" % cavemen)
	else:
		_fail("AI cavemen parties (>=20)", "count=%d" % cavemen)
	if women == 8:
		_pass("8 clan women")
	else:
		_fail("8 clan women", "count=%d" % women)
	if awake >= 16:
		_pass("AI cavemen sim-awake (%d)" % awake)
	else:
		_fail("AI cavemen sim-awake (>=16)", "count=%d" % awake)
	_summary()
	quit(0 if _failed == 0 else 1)


func _pass(label: String) -> void:
	_passed += 1
	print("  PASS: %s" % label)


func _fail(label: String, detail: String = "") -> void:
	_failed += 1
	print("  FAIL: %s — %s" % [label, detail])


func _summary() -> void:
	print("=== EVAL_AI_ARENA_TEST: %d passed, %d failed ===" % [_passed, _failed])
	if _failed == 0:
		print("TEST_EVAL_AI_ARENA_PASS")
	else:
		print("TEST_EVAL_AI_ARENA_FAIL")
