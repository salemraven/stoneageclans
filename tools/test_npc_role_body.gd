extends SceneTree
## NPC role body: sleep-order spawn, late type set, baby growth, combat target rules.

const NPC_SCENE := preload("res://scenes/NPC.tscn")
const NPCRoleBodyScript := preload("res://scripts/npc/npc_role_body.gd")
const FightOverScript := preload("res://scripts/systems/fight_over.gd")

var _failed := 0
var _passed := 0
var _world: Node2D


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	await process_frame
	_world = Node2D.new()
	_world.name = "RoleBodyWorld"
	root.add_child(_world)
	_test_sleep_order_spawn()
	_test_late_type_set()
	await _test_baby_promotion()
	await _test_baby_not_living_target()
	await _test_no_body_not_dead_whiff()
	if _failed == 0:
		print("TEST_NPC_ROLE_BODY: all checks passed (%d)" % _passed)
		quit(0)
	else:
		print("TEST_NPC_ROLE_BODY: FAIL %d (passed %d)" % [_failed, _passed])
		quit(1)


func _assert(ok: bool, label: String) -> void:
	if ok:
		_passed += 1
		print("ROLE_BODY_PASS: %s" % label)
	else:
		_failed += 1
		print("ROLE_BODY_FAIL: %s" % label)


func _test_sleep_order_spawn() -> void:
	var n: NPCBase = NPC_SCENE.instantiate() as NPCBase
	n.npc_name = "SleepOrder"
	n.set("npc_type", "clansman")
	n.set("clan_name", "TEST")
	_world.add_child(n)
	if n.has_method("apply_sleep_data"):
		n.apply_sleep_data({"npc_type": "clansman", "clan_name": "TEST"})
	_assert(n.role_body_complete(), "sleep-order: clansman has health body")
	var issue: String = NPCRoleBodyScript.attack_target_issue(n)
	_assert(issue == "", "sleep-order: attack issue empty got %s" % issue)


func _test_late_type_set() -> void:
	var n: NPCBase = NPC_SCENE.instantiate() as NPCBase
	n.npc_name = "LateType"
	_world.add_child(n)
	n.set_npc_type("clansman", "test_late")
	_assert(n.role_body_complete(), "late type: ensure_role after add_child")
	_assert(NPCRoleBodyScript.attack_target_issue(n) == "", "late type: hittable")


func _test_baby_promotion() -> void:
	var b: NPCBase = NPC_SCENE.instantiate() as NPCBase
	b.npc_name = "GrowUp"
	b.npc_type = "baby"
	b.clan_name = "TEST"
	_world.add_child(b)
	await process_frame
	b.set_npc_type("clansman", "test_promote")
	_assert(str(b.npc_type) == "clansman", "baby promote: type clansman")
	_assert(b.role_body_complete(), "baby promote: health body")
	_assert(NPCRoleBodyScript.attack_target_issue(b) == "", "baby promote: hittable")


func _test_baby_not_living_target() -> void:
	var b: NPCBase = NPC_SCENE.instantiate() as NPCBase
	b.npc_name = "BabySafe"
	b.npc_type = "baby"
	_world.add_child(b)
	await process_frame
	_assert(not NPCRoleBodyScript.is_living_attack_target(b), "baby: not living attack target")
	_assert(NPCRoleBodyScript.attack_target_issue(b) == "unhittable", "baby: unhittable issue")


func _test_no_body_not_dead_whiff() -> void:
	var n: NPCBase = NPC_SCENE.instantiate() as NPCBase
	n.npc_name = "Ghost"
	_world.add_child(n)
	n.set_npc_type("clansman", "test")
	var hc: Node = n.get_node_or_null("HealthComponent")
	if hc:
		hc.free()
	_assert(NPCRoleBodyScript.attack_target_issue(n) == "no_body", "no_body issue not dead")
	_assert(not NPCRoleBodyScript.is_living_attack_target(n), "no_body: not living target")
	n.ensure_role("test_repair")
	_assert(n.role_body_complete(), "ensure_role repairs missing body")
	_assert(NPCRoleBodyScript.attack_target_issue(n) == "", "repaired: hittable")
