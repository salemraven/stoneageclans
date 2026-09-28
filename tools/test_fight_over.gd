extends SceneTree
## Fight-over: everyone targeting a corpse leaves combat. No orbit.

const NPC_SCENE := preload("res://scenes/NPC.tscn")
const FightOverScript := preload("res://scripts/systems/fight_over.gd")

var _failed := 0
var _passed := 0
var _world: Node2D


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	await process_frame
	_world = Node2D.new()
	_world.name = "FightOverWorld"
	root.add_child(_world)

	_test_one_killer()
	_test_combat_locked()
	_test_two_killers()
	_test_combat_can_enter_corpse()
	_test_agro_no_reenter_corpse()
	_test_fight_over_latch()
	_test_break_blocks_reagro()

	if _failed == 0:
		print("TEST_FIGHT_OVER: all checks passed (%d)" % _passed)
		quit(0)
	else:
		print("TEST_FIGHT_OVER: FAIL %d (passed %d)" % [_failed, _passed])
		quit(1)


func _spawn(name_s: String, pos: Vector2) -> NPCBase:
	var n: NPCBase = NPC_SCENE.instantiate() as NPCBase
	n.npc_name = name_s
	n.npc_type = "caveman"
	n.clan_name = "TestClan"
	_world.add_child(n)
	n.global_position = pos
	return n


func _assert(ok: bool, label: String) -> void:
	if ok:
		_passed += 1
		print("FIGHT_OVER_PASS: %s" % label)
	else:
		_failed += 1
		print("FIGHT_OVER_FAIL: %s" % label)


func _not_combat_agro(n: NPCBase) -> bool:
	if n.combat_target != null:
		return false
	if n.agro_target != null:
		return false
	if n.fsm and n.fsm.has_method("get_current_state_name"):
		var st: String = str(n.fsm.get_current_state_name())
		if st == "combat" or st == "agro":
			return false
	return true


func _test_one_killer() -> void:
	var killer := _spawn("Killer", Vector2(0, 0))
	var victim := _spawn("Victim", Vector2(40, 0))
	victim.set_meta("is_corpse", true)
	killer.combat_target = victim
	killer.agro_target = victim
	killer.agro_meter = 100.0
	if killer.fsm and killer.fsm.has_method("change_state"):
		killer.fsm.change_state("combat", true)
	killer.end_fight_target_dead(victim)
	_assert(killer.combat_target == null and killer.agro_target == null, "one killer: targets cleared")
	_assert(_not_combat_agro(killer), "one killer: not combat/agro")
	killer.queue_free()
	victim.queue_free()


func _test_combat_locked() -> void:
	var killer := _spawn("Locked", Vector2(0, 80))
	var victim := _spawn("V2", Vector2(40, 80))
	victim.set_meta("is_corpse", true)
	killer.combat_locked = true
	killer.combat_target = victim
	killer.end_fight_target_dead(victim)
	_assert(not killer.combat_locked, "locked: unlocked")
	_assert(killer.combat_target == null, "locked: target cleared")
	killer.queue_free()
	victim.queue_free()


func _test_two_killers() -> void:
	var a := _spawn("A", Vector2(0, 160))
	var b := _spawn("B", Vector2(20, 160))
	var v := _spawn("V", Vector2(40, 160))
	v.set_meta("is_corpse", true)
	a.combat_target = v
	b.combat_target = v
	a.agro_target = v
	b.agro_target = v
	if a.fsm and a.fsm.has_method("change_state"):
		a.fsm.change_state("combat", true)
	if b.fsm and b.fsm.has_method("change_state"):
		b.fsm.change_state("combat", true)
	var n: int = FightOverScript.end_fight_for_all_targeting(v)
	_assert(n >= 2, "two killers: broadcast count %d" % n)
	_assert(a.combat_target == null and b.combat_target == null, "two killers: both targets null")
	_assert(_not_combat_agro(a) and _not_combat_agro(b), "two killers: both left")
	a.queue_free()
	b.queue_free()
	v.queue_free()


func _test_combat_can_enter_corpse() -> void:
	var fighter := _spawn("F", Vector2(0, 240))
	var corpse := _spawn("C", Vector2(30, 240))
	corpse.set_meta("is_corpse", true)
	var hc: Node = corpse.get_node_or_null("HealthComponent")
	if hc:
		hc.is_dead = true
	fighter.combat_target = corpse
	fighter.agro_meter = 100.0
	_assert(not FightOverScript.is_living_attack_target(corpse), "combat: corpse is not a living target")
	fighter.queue_free()
	corpse.queue_free()


func _test_fight_over_latch() -> void:
	var killer := _spawn("LatchK", Vector2(0, 400))
	var victim := _spawn("LatchV", Vector2(40, 400))
	victim.set_meta("is_corpse", true)
	killer.combat_target = victim
	killer.agro_meter = 100.0
	killer.end_fight_target_dead(victim)
	var first: int = int(killer.fight_over_emit_count)
	killer.combat_target = victim
	killer.agro_meter = 100.0
	killer.end_fight_target_dead(victim)
	killer.end_fight_target_dead(null)
	_assert(int(killer.fight_over_emit_count) == first, "latch: second end_fight does not emit")
	_assert(killer.is_fight_over_latched(), "latch: still latched")
	_assert(killer.combat_target == null, "latch: target stays clear")
	killer.queue_free()
	victim.queue_free()


func _test_break_blocks_reagro() -> void:
	var a := _spawn("BreakA", Vector2(0, 520))
	var b := _spawn("BreakB", Vector2(30, 520))
	a.agro_meter = 90.0
	a.combat_target = b
	var tick: Node = root.get_node_or_null("CombatTick")
	if tick == null or not tick.has_method("break_contact"):
		_assert(false, "break: CombatTick missing")
		a.queue_free()
		b.queue_free()
		return
	tick.break_contact(a)
	_assert(a.combat_target == null, "break: target cleared")
	_assert(float(a.agro_meter) <= 0.01, "break: agro cleared")
	_assert(tick.is_disengaged(a), "break: disengaged")
	tick.push_agro_event(a, 80.0, "proximity", b)
	tick._on_tick()
	_assert(float(a.agro_meter) <= 0.01, "break: proximity cannot refill")
	a.queue_free()
	b.queue_free()


func _test_agro_no_reenter_corpse() -> void:
	var cav := _spawn("Ag", Vector2(0, 320))
	var corpse := _spawn("C2", Vector2(30, 320))
	corpse.set_meta("is_corpse", true)
	cav.agro_target = corpse
	cav.agro_meter = 100.0
	# Same gate agro can_enter uses (no state new() — combat/agro scripts need autoloads).
	_assert(not FightOverScript.is_living_attack_target(corpse), "agro: corpse not living")
	cav.set("agro_target", null)
	cav.set("agro_meter", 0.0)
	_assert(float(cav.agro_meter) <= 0.0001, "agro meter zeroed on corpse")
	cav.queue_free()
	corpse.queue_free()
