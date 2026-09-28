extends SceneTree
## Corpse harvest API + safe closest butcher.

const CorpseHarvestScript := preload("res://scripts/systems/corpse_harvest.gd")
const CorpseJobs := preload("res://scripts/systems/corpse_job_service.gd")

var _failed := 0
var _passed := 0
var _world: Node2D


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	await process_frame
	_world = Node2D.new()
	root.add_child(_world)
	_test_slice_order()
	_test_human_yields()
	_test_idle_clears_site()
	_test_full_bag_undo()
	_test_closest()
	_test_own_clan_pantry()
	_test_own_clan_needs_meat()
	_test_threat_defers()
	_test_baby_no_site()

	if _failed == 0:
		print("TEST_CORPSE_HARVEST: all checks passed (%d)" % _passed)
		quit(0)
	else:
		print("TEST_CORPSE_HARVEST: FAIL %d (passed %d)" % [_failed, _passed])
		quit(1 if _failed > 0 else 0)


func _ok(cond: bool, label: String) -> void:
	if cond:
		_passed += 1
		print("HARVEST_PASS: %s" % label)
	else:
		_failed += 1
		print("HARVEST_FAIL: %s" % label)


func _dummy_corpse(nt: String, meat: int, hide: int, bone: int, pos: Vector2) -> Node2D:
	var n := Node2D.new()
	n.set("npc_type", nt)
	n.set_meta("npc_type", nt)
	n.set("npc_name", nt)
	n.set_meta("is_corpse", true)
	n.set_meta("meat_remaining", meat)
	n.set_meta("hide_remaining", hide)
	n.set_meta("bone_remaining", bone)
	_world.add_child(n)
	n.global_position = pos
	n.add_to_group("corpses")
	return n


func _test_slice_order() -> void:
	var bag: Array = []
	var corpse := _dummy_corpse("test", 2, 1, 1, Vector2.ZERO)
	var add := func(t):
		bag.append(t)
		return true
	for _i in 4:
		CorpseHarvestScript.take_slice(corpse, add, "t")
	_ok(bag.size() == 4, "four slices")
	_ok(bag[0] == ResourceData.ResourceType.MEAT and bag[1] == ResourceData.ResourceType.MEAT, "meat first")
	_ok(bag[2] == ResourceData.ResourceType.HIDE, "then hide")
	_ok(bag[3] == ResourceData.ResourceType.BONE, "then bone")
	_ok(not is_instance_valid(corpse) or corpse.is_queued_for_deletion(), "despawn after last")


func _test_human_yields() -> void:
	var n := Node2D.new()
	n.set("npc_type", "caveman")
	n.set_meta("npc_type", "caveman")
	var y: Dictionary = CorpseHarvestScript.apply_death_yields(n)
	_ok(int(y.get("meat", 0)) == 3 and int(n.get_meta("meat_remaining")) == 3, "caveman meat 3")
	n.set("npc_type", "woman")
	n.set_meta("npc_type", "woman")
	y = CorpseHarvestScript.apply_death_yields(n)
	_ok(int(y.get("meat", 0)) == 2 and int(y.get("bone", 0)) == 2, "woman yields")
	n.free()


func _test_idle_clears_site() -> void:
	var claim := Node2D.new()
	claim.add_to_group("land_claims")
	_world.add_child(claim)
	var corpse := _dummy_corpse("deer", 1, 0, 0, Vector2(10, 0))
	CorpseJobs.register_site(claim, corpse)
	_ok(CorpseJobs.is_site_active(claim), "site active")
	CorpseHarvestScript.despawn_idle(corpse)
	_ok(not CorpseJobs.is_site_active(claim), "idle despawn cleared site")
	claim.queue_free()


func _test_full_bag_undo() -> void:
	var corpse := _dummy_corpse("deer", 2, 0, 0, Vector2(80, 0))
	var slice: Dictionary = CorpseHarvestScript.take_slice(corpse, func(_t): return false, "full")
	_ok(not bool(slice.get("ok", false)) and bool(slice.get("undone", false)), "full bag undone")
	_ok(int(corpse.get_meta("meat_remaining")) == 2, "meat restored")
	corpse.queue_free()


func _test_closest() -> void:
	var claim := Node2D.new()
	claim.set("clan_name", "C")
	_world.add_child(claim)
	claim.global_position = Vector2.ZERO
	var far := _dummy_corpse("deer", 1, 0, 0, Vector2(400, 0))
	var near := _dummy_corpse("deer", 1, 0, 0, Vector2(40, 0))
	CorpseHarvestScript.add_candidate(claim, far)
	CorpseHarvestScript.add_candidate(claim, near)
	var pick: Node = CorpseHarvestScript.pick_closest_allowed(claim, claim.global_position)
	_ok(pick == near, "closest corpse picked")
	far.queue_free()
	near.queue_free()
	claim.queue_free()


func _test_own_clan_pantry() -> void:
	var claim := Node2D.new()
	claim.set("clan_name", "C")
	claim.set_meta("clan_name", "C")
	var inv := InventoryData.new(20, true, 99)
	inv.add_item(ResourceData.ResourceType.MEAT, 10)
	claim.set_meta("inventory", inv)
	claim.set("inventory", inv)
	claim.set_meta("food_days_buffer", 5.0)
	_world.add_child(claim)
	var body := _dummy_corpse("caveman", 3, 1, 2, Vector2(20, 0))
	body.set("clan_name", "C")
	body.set_meta("clan_name", "C")
	_ok(not CorpseHarvestScript.corpse_allowed_for_claim(body, claim), "own-clan skipped when pantry high")
	body.queue_free()
	claim.queue_free()


func _test_own_clan_needs_meat() -> void:
	var claim := Node2D.new()
	claim.set("clan_name", "C")
	var inv := InventoryData.new(20, true, 99)
	claim.set_meta("inventory", inv)
	claim.set("inventory", inv)
	claim.set_meta("food_days_buffer", 0.1)
	_world.add_child(claim)
	var body := _dummy_corpse("caveman", 3, 1, 2, Vector2(20, 0))
	body.set("clan_name", "C")
	_ok(CorpseHarvestScript.clan_needs_meat(claim), "needs meat")
	_ok(CorpseHarvestScript.corpse_allowed_for_claim(body, claim), "own-clan allowed when hungry")
	body.queue_free()
	claim.queue_free()


func _test_threat_defers() -> void:
	var claim := Node2D.new()
	claim.set("clan_name", "C")
	claim.set_meta("clan_name", "C")
	_world.add_child(claim)
	var fighter := Node2D.new()
	fighter.set("clan_name", "C")
	fighter.set_meta("clan_name", "C")
	fighter.set("npc_name", "F")
	var enemy := Node2D.new()
	_world.add_child(enemy)
	fighter.set("combat_target", enemy)
	fighter.set_meta("combat_target", enemy)
	fighter.add_to_group("npcs")
	_world.add_child(fighter)
	var corpse := _dummy_corpse("deer", 2, 0, 0, Vector2(10, 0))
	CorpseHarvestScript.add_candidate(claim, corpse)
	var opened: bool = CorpseHarvestScript.try_refresh_safe_site(claim, "agro")
	_ok(not opened and not CorpseJobs.is_site_active(claim), "threat defers butcher")
	fighter.queue_free()
	enemy.queue_free()
	corpse.queue_free()
	claim.queue_free()


func _test_baby_no_site() -> void:
	var claim := Node2D.new()
	claim.set("clan_name", "C")
	_world.add_child(claim)
	var baby := _dummy_corpse("baby", 0, 0, 0, Vector2(5, 0))
	CorpseHarvestScript.add_candidate(claim, baby)
	_ok(CorpseHarvestScript.pick_closest_allowed(claim, Vector2.ZERO) == null, "baby not a candidate")
	baby.queue_free()
	claim.queue_free()
