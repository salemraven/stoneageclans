extends SceneTree

## Raid motive + goal rules, no world. Run:
## godot --headless --path . --script res://tools/raid_motive_verify.gd

const Picker = preload("res://scripts/ai/raid_motive_picker.gd")

func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var failed: int = 0
	var tune: Dictionary = Picker.DEFAULT_TUNE.duplicate()
	var now: float = 1000.0

	# Hunger beats restless (food fires while restless would need 3+ pantry days).
	var hungry: Dictionary = Picker.pick({
		"living_fighters": 8,
		"food_days": 0.5,
		"morale": 80.0,
		"temper": 0.0,
		"neighbors": [{"claim": null, "clan": "B", "distance": 100.0, "their_fighters": 4, "has_food": true, "has_woman": false, "has_animal": false}],
		"wrongs": [],
		"last_quiet_at": 0.0,
		"now": now,
		"tune": tune,
		"alert": false,
		"hunting": false,
		"cooldown_ok": true,
		"trade_blocked": false,
	})
	if not hungry.get("ok") or str(hungry.get("why")) != Picker.WHY_FOOD:
		failed += 1
		print("RAID_MOTIVE hungry ok=no why=%s" % str(hungry.get("why", "?")))
	else:
		print("RAID_MOTIVE hungry ok=yes")

	# Larger grudge target does not fire blood.
	var blood: Dictionary = Picker.pick({
		"living_fighters": 8,
		"food_days": 5.0,
		"morale": 80.0,
		"temper": 0.0,
		"neighbors": [{"claim": null, "clan": "BIG", "distance": 100.0, "their_fighters": 20, "need": {}}],
		"wrongs": [{"enemy": "BIG", "kind": Picker.KIND_KILLED, "at": now - 10.0}],
		"last_quiet_at": 0.0,
		"now": now,
		"tune": tune,
		"alert": false,
		"hunting": false,
		"cooldown_ok": true,
		"trade_blocked": false,
	})
	if blood.get("ok") and str(blood.get("why")) == Picker.WHY_BLOOD:
		failed += 1
		print("RAID_MOTIVE blood_vs_big ok=no")
	else:
		print("RAID_MOTIVE blood_vs_big ok=yes")

	# Peaceful temper skips thin and restless.
	var peaceful: Dictionary = Picker.pick({
		"living_fighters": 8,
		"food_days": 5.0,
		"morale": 80.0,
		"temper": -1.0,
		"neighbors": [{"claim": null, "clan": "B", "distance": 100.0, "their_fighters": 2, "need": {"women": true}}],
		"wrongs": [],
		"last_quiet_at": 0.0,
		"now": now + 10000.0,
		"tune": tune,
		"alert": false,
		"hunting": false,
		"cooldown_ok": true,
		"trade_blocked": false,
	})
	if peaceful.get("ok") and (str(peaceful.get("why")) == Picker.WHY_THIN or str(peaceful.get("why")) == Picker.WHY_RESTLESS):
		failed += 1
		print("RAID_MOTIVE peaceful ok=no why=%s" % str(peaceful.get("why")))
	else:
		print("RAID_MOTIVE peaceful ok=yes")

	# Sheltered woman not raidable until building is gone.
	var woman := Node.new()
	woman.set_meta("assigned_building", Node.new())
	if Picker.prize_raidable(woman, true, true):
		failed += 1
		print("RAID_MOTIVE sheltered ok=no")
	else:
		print("RAID_MOTIVE sheltered ok=yes")
	if not Picker.prize_raidable(woman, true, false):
		failed += 1
		print("RAID_MOTIVE loose_after_hut ok=no")
	else:
		print("RAID_MOTIVE loose_after_hut ok=yes")
	woman.free()

	# Two kills complete weaken.
	if not Picker.is_weaken_goal_done(2, tune):
		failed += 1
		print("RAID_MOTIVE weaken_two ok=no")
	else:
		print("RAID_MOTIVE weaken_two ok=yes")
	if Picker.is_weaken_goal_done(1, tune):
		failed += 1
		print("RAID_MOTIVE weaken_one ok=no")
	else:
		print("RAID_MOTIVE weaken_one ok=yes")

	# Bag not full and store has food => food goal not done (legacy 2-arg helper removed; use 3-arg).
	if Picker.is_food_goal_done(true, false, true):
		failed += 1
		print("RAID_MOTIVE food_partial ok=no")
	else:
		print("RAID_MOTIVE food_partial ok=yes")
	if Picker.is_food_goal_done(false, false, true):
		failed += 1
		print("RAID_MOTIVE food_before_arrive ok=no")
	else:
		print("RAID_MOTIVE food_before_arrive ok=yes")

	if Picker.skip_signature("cooldown", "sec=30") != Picker.skip_signature("cooldown", "sec=25"):
		failed += 1
		print("RAID_MOTIVE cooldown_sig ok=no")
	else:
		print("RAID_MOTIVE cooldown_sig ok=yes")
	if not Picker.skip_signature("short_handed", "free=1") == "short_handed|free=1":
		failed += 1
		print("RAID_MOTIVE other_sig ok=no")
	else:
		print("RAID_MOTIVE other_sig ok=yes")

	if not Picker.cooldown_blocks(100.0, 50.0, 60.0):
		failed += 1
		print("RAID_MOTIVE cooldown_10s ok=no")
	else:
		print("RAID_MOTIVE cooldown_10s ok=yes")
	if Picker.cooldown_blocks(120.0, 50.0, 60.0):
		failed += 1
		print("RAID_MOTIVE cooldown_61s ok=no")
	else:
		print("RAID_MOTIVE cooldown_61s ok=yes")

	var theft: Dictionary = Picker.pick({
		"living_fighters": 8,
		"food_days": 5.0,
		"morale": 80.0,
		"temper": 0.0,
		"neighbors": [{"claim": null, "clan": "V", "distance": 100.0, "their_fighters": 4, "has_woman": true, "has_animal": false, "has_food": true}],
		"wrongs": [{"enemy": "V", "kind": Picker.KIND_STOLE, "at": now - 10.0, "stole_goal": Picker.GOAL_TAKE_WOMEN}],
		"last_quiet_at": 0.0,
		"now": now,
		"tune": tune,
		"alert": false,
		"hunting": false,
		"cooldown_ok": true,
		"trade_blocked": false,
	})
	if not theft.get("ok") or str(theft.get("why")) != Picker.WHY_THEFT:
		failed += 1
		print("RAID_MOTIVE theft ok=no")
	else:
		print("RAID_MOTIVE theft ok=yes")

	var theft_no_prize: Dictionary = Picker.pick({
		"living_fighters": 8,
		"food_days": 5.0,
		"morale": 80.0,
		"temper": 0.0,
		"neighbors": [{"claim": null, "clan": "V", "distance": 100.0, "their_fighters": 4, "has_woman": false, "has_animal": false, "has_food": true}],
		"wrongs": [{"enemy": "V", "kind": Picker.KIND_STOLE, "at": now - 10.0, "stole_goal": Picker.GOAL_TAKE_WOMEN}],
		"last_quiet_at": 0.0,
		"now": now,
		"tune": tune,
		"alert": false,
		"hunting": false,
		"cooldown_ok": true,
		"trade_blocked": false,
	})
	if str(theft_no_prize.get("skip", "")) != "no_prize":
		failed += 1
		print("RAID_MOTIVE theft_no_prize ok=no skip=%s" % str(theft_no_prize.get("skip")))
	else:
		print("RAID_MOTIVE theft_no_prize ok=yes")

	var hungry_no_food: Dictionary = Picker.pick({
		"living_fighters": 8,
		"food_days": 0.5,
		"morale": 80.0,
		"temper": 0.0,
		"neighbors": [{"claim": null, "clan": "B", "distance": 100.0, "their_fighters": 4, "has_food": false, "has_woman": false, "has_animal": false}],
		"wrongs": [],
		"last_quiet_at": 0.0,
		"now": now,
		"tune": tune,
		"alert": false,
		"hunting": false,
		"cooldown_ok": true,
		"trade_blocked": false,
	})
	if str(hungry_no_food.get("skip", "")) != "no_prize":
		failed += 1
		print("RAID_MOTIVE hungry_no_food ok=no")
	else:
		print("RAID_MOTIVE hungry_no_food ok=yes")

	var thin_anim: Dictionary = Picker.pick({
		"living_fighters": 8,
		"food_days": 5.0,
		"morale": 80.0,
		"temper": 0.0,
		"our_need": "women",
		"neighbors": [{"claim": null, "clan": "B", "distance": 100.0, "their_fighters": 2, "has_woman": false, "has_animal": true, "has_food": false}],
		"wrongs": [],
		"last_quiet_at": 0.0,
		"now": now + 10000.0,
		"tune": tune,
		"alert": false,
		"hunting": false,
		"cooldown_ok": true,
		"trade_blocked": false,
	})
	if not thin_anim.get("ok") or str(thin_anim.get("goal")) != Picker.GOAL_TAKE_ANIMALS:
		failed += 1
		print("RAID_MOTIVE thin_fallback ok=no goal=%s" % str(thin_anim.get("goal")))
	else:
		print("RAID_MOTIVE thin_fallback ok=yes")

	# Empty enemy wrong does not pick theft (grudge filter).
	var wrong_empty: Dictionary = Picker.pick({
		"living_fighters": 8,
		"food_days": 5.0,
		"morale": 80.0,
		"temper": 0.0,
		"neighbors": [{"claim": null, "clan": "V", "distance": 100.0, "their_fighters": 4, "has_woman": true, "has_food": true}],
		"wrongs": [{"enemy": "", "kind": Picker.KIND_STOLE, "at": now - 10.0}],
		"last_quiet_at": 0.0,
		"now": now,
		"tune": tune,
		"alert": false,
		"hunting": false,
		"cooldown_ok": true,
		"trade_blocked": false,
	})
	if wrong_empty.get("ok") and str(wrong_empty.get("why")) == Picker.WHY_THEFT:
		failed += 1
		print("RAID_MOTIVE empty_wrong ok=no")
	else:
		print("RAID_MOTIVE empty_wrong ok=yes")

	# Capture prize state machine
	var pen_one_joined: Dictionary = Picker.evaluate_capture_prizes([
		{"state": "pending"}, {"state": "joined"},
	])
	if pen_one_joined.get("done") or pen_one_joined.get("failed"):
		failed += 1
		print("RAID_MOTIVE pen_partial ok=no")
	else:
		print("RAID_MOTIVE pen_partial ok=yes")
	var pen_done: Dictionary = Picker.evaluate_capture_prizes([
		{"state": "joined"}, {"state": "joined"},
	])
	if not pen_done.get("done", false):
		failed += 1
		print("RAID_MOTIVE pen_two ok=no")
	else:
		print("RAID_MOTIVE pen_two ok=yes")
	var pen_fail: Dictionary = Picker.evaluate_capture_prizes([{"state": "lost"}, {"state": "lost"}])
	if not pen_fail.get("failed", false) or pen_fail.get("done", false):
		failed += 1
		print("RAID_MOTIVE pen_fail ok=no")
	else:
		print("RAID_MOTIVE pen_fail ok=yes")

	if Picker.is_food_goal_done(false, true, false):
		failed += 1
		print("RAID_MOTIVE food_all_full_before_arrive ok=no")
	else:
		print("RAID_MOTIVE food_all_full_before_arrive ok=yes")
	if not Picker.is_food_goal_done(true, true, true):
		failed += 1
		print("RAID_MOTIVE food_all_full_after ok=no")
	else:
		print("RAID_MOTIVE food_all_full_after ok=yes")

	var brain_src: String = FileAccess.get_file_as_string("res://scripts/ai/clan_brain.gd")
	if brain_src.contains("_try_raid_herd_loose_prizes") and brain_src.split("set(\"is_herded\"").size() > 1:
		var herd_fn_start: int = brain_src.find("func _try_raid_herd_loose_prizes")
		if herd_fn_start >= 0:
			var chunk: String = brain_src.substr(herd_fn_start, 800)
			if chunk.contains("set(\"is_herded\""):
				failed += 1
				print("RAID_MOTIVE no_direct_herd ok=no")
			else:
				print("RAID_MOTIVE no_direct_herd ok=yes")
		else:
			print("RAID_MOTIVE no_direct_herd ok=yes")
	else:
		print("RAID_MOTIVE no_direct_herd ok=yes")

	if failed > 0:
		push_error("RAID_MOTIVE failed %d" % failed)
		quit(1)
	else:
		print("RAID_MOTIVE_OK")
		quit(0)
