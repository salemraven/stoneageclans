extends SceneTree

## Brain loot rule, no world. Run:
## godot --headless --path . --script res://tools/hunt_loot_verify.gd

func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var brain_script = load("res://scripts/ai/clan_brain.gd")
	var brain = brain_script.new()
	var man := Node.new()
	root.add_child(man)
	man.set_meta("hunt_joined", true)
	var failed: int = 0
	if brain.is_hunt_looting():
		failed += 1
		print("HUNT_LOOT idle looting ok=no")
	else:
		print("HUNT_LOOT idle looting ok=yes")
	brain.hunt_intent["state"] = brain.HuntIntentState.ACTIVE
	if not brain.should_npc_hunt(man):
		failed += 1
		print("HUNT_LOOT active joined ok=no")
	else:
		print("HUNT_LOOT active joined ok=yes")
	brain.hunt_intent["state"] = brain.HuntIntentState.LOOTING
	if not brain.is_hunt_looting() or brain.should_npc_hunt(man):
		failed += 1
		print("HUNT_LOOT looting blocks joined ok=no")
	else:
		print("HUNT_LOOT looting blocks joined ok=yes")
	var stall_sec: float = brain.LOOT_STALL_SEC
	if brain_script.loot_yield_stalled(5, 5, 10.0, 10.0 + stall_sec - 0.1, stall_sec):
		failed += 1
		print("HUNT_LOOT stall waits ok=no")
	else:
		print("HUNT_LOOT stall waits ok=yes")
	if not brain_script.loot_yield_stalled(5, 5, 10.0, 10.0 + stall_sec, stall_sec):
		failed += 1
		print("HUNT_LOOT stall fires ok=no")
	else:
		print("HUNT_LOOT stall fires ok=yes")
	if brain_script.loot_yield_stalled(4, 5, 10.0, 100.0, stall_sec):
		failed += 1
		print("HUNT_LOOT slice resets stall ok=no")
	else:
		print("HUNT_LOOT slice resets stall ok=yes")
	if brain_script.loot_yield_stalled(0, 0, 10.0, 100.0, stall_sec):
		failed += 1
		print("HUNT_LOOT empty is complete ok=no")
	else:
		print("HUNT_LOOT empty is complete ok=yes")
	var claim := Node2D.new()
	var corpse := Node2D.new()
	root.add_child(claim)
	root.add_child(corpse)
	corpse.set_meta("meat_remaining", 4)
	var jobs = load("res://scripts/systems/corpse_job_service.gd")
	jobs.register_site(claim, corpse)
	brain.territory = claim
	brain.hunt_intent["start_time"] = 1.0
	brain._complete_hunt("loot_stalled", true)
	if brain.is_hunting() or not jobs.is_site_active(claim) or int(corpse.get_meta("meat_remaining")) != 4:
		failed += 1
		print("HUNT_LOOT stall keeps carcass ok=no")
	else:
		print("HUNT_LOOT stall keeps carcass ok=yes")
	man.queue_free()
	claim.queue_free()
	corpse.queue_free()
	if failed > 0:
		push_error("HUNT_LOOT failed %d" % failed)
		quit(1)
	else:
		print("HUNT_LOOT_OK")
		quit(0)
