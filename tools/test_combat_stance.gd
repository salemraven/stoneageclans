extends SceneTree
## Melee stance: stand once in range, walk a straight close, keep one target, hold cancels a delayed step.

const CombatStance = preload("res://scripts/systems/combat_stance.gd")

var _passed := 0
var _failed := 0


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	_assert(CombatStance.decide(90.0, 100.0) == "hold", "in range stands")
	_assert(CombatStance.decide(100.0, 100.0) == "hold", "on the range edge stands")
	_assert(CombatStance.decide(140.0, 100.0) == "approach", "outside range walks in")
	var stand: Vector2 = CombatStance.approach_point(Vector2(200, 0), Vector2(0, 0), 100.0)
	_assert(absf(stand.y) < 0.01, "close-in stays on the line (no height slide)")
	_assert(absf(stand.x - 85.0) < 0.01, "close-in stops short of the body")
	_assert(CombatStance.stalemate_break(6.0, 6.0, false), "no HP change breaks a stand")
	_assert(not CombatStance.stalemate_break(6.0, 6.0, true), "an HP change keeps the fight")
	_assert(not CombatStance.stalemate_break(2.0, 6.0, false), "a fresh stand is not a break")
	_assert(CombatStance.keep_target(true), "live enemy stays the target")
	_assert(not CombatStance.keep_target(false), "dead enemy is dropped")
	_test_hold_cancels_pending_step()
	if _failed == 0:
		print("TEST_COMBAT_STANCE: all checks passed (%d)" % _passed)
		quit(0)
	else:
		print("TEST_COMBAT_STANCE: FAIL %d (passed %d)" % [_failed, _passed])
		quit(1)


func _test_hold_cancels_pending_step() -> void:
	var SteeringAgent = load("res://scripts/npc/steering_agent.gd")
	var body := Node2D.new()
	root.add_child(body)
	body.global_position = Vector2(10, 10)
	var steer = SteeringAgent.new()
	body.add_child(steer)
	steer.npc = body
	steer._pending_intent_time = 10.0
	steer._pending_mode = SteeringAgent.SteeringMode.SEEK
	steer.current_mode = SteeringAgent.SteeringMode.SEEK
	_assert(steer._pending_intent_time > 0.0, "a walk order sits in the delay queue")
	steer.hold_still()
	_assert(steer._pending_intent_time == 0.0, "hold clears that delayed step")
	_assert(steer.current_mode == SteeringAgent.SteeringMode.HOLD, "hold mode")
	body.queue_free()


func _assert(ok: bool, label: String) -> void:
	if ok:
		_passed += 1
		print("COMBAT_STANCE_PASS: %s" % label)
	else:
		_failed += 1
		print("COMBAT_STANCE_FAIL: %s" % label)
