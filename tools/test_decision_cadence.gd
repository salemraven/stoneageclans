extends SceneTree

## Stagger is 1-of-6 physics ticks. Combat is not exempt.


func _init() -> void:
	var src := FileAccess.get_file_as_string("res://scripts/npc/npc_base.gd")
	if not src.contains("func _decision_slot_this_tick"):
		push_error("TEST_DECISION_CADENCE: missing _decision_slot_this_tick")
		quit(1)
		return
	if not src.contains("posmod(nid + Engine.get_physics_frames(), 6)") and not src.contains("% 6"):
		push_error("TEST_DECISION_CADENCE: expected % 6 stagger")
		quit(1)
		return
	if not src.contains("var run_decisions: bool = _decision_slot_this_tick()"):
		push_error("TEST_DECISION_CADENCE: FSM path must use the stagger")
		quit(1)
		return
	# Distance throttle used to skip combat; the stagger must still apply there.
	if src.contains("skip_throttle") and src.contains("run_decisions = skip_throttle"):
		push_error("TEST_DECISION_CADENCE: combat must not bypass the stagger")
		quit(1)
		return
	var hits := 0
	for frame in range(60):
		if posmod(7 + frame, 6) == 0:
			hits += 1
	if hits < 8 or hits > 14:
		push_error("TEST_DECISION_CADENCE: 60 frames should yield ~10 slots, got %d" % hits)
		quit(1)
		return
	print("TEST_DECISION_CADENCE: ok hits_per_60=%d" % hits)
	quit(0)
