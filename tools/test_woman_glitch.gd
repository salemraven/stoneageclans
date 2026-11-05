extends SceneTree
## Clan woman with a living hut, standing where the campfire is.
## Records who owns her movement. Fails if she jitters in place instead of settling at the hut.
## Run: godot --headless --path . -s res://tools/test_woman_glitch.gd -- --skip-single-instance

const FRAMES := 360

var _failed := 0


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	await process_frame
	var occ: Node = root.get_node_or_null("OccupationSystem")
	if occ == null or not occ.has_method("force_assign"):
		_fail("OccupationSystem missing")
		_finish()
		return
	var world := Node2D.new()
	world.name = "WomanGlitchWorld"
	root.add_child(world)
	var hut := BuildingBase.new()
	hut.name = "GlitchHut"
	hut.building_type = ResourceData.ResourceType.LIVING_HUT
	hut.clan_name = "TEST"
	world.add_child(hut)
	hut.global_position = Vector2(220.0, 0.0)
	var npc_scene: PackedScene = load("res://scenes/NPC.tscn") as PackedScene
	var woman: Node = npc_scene.instantiate()
	woman.set("npc_type", "woman")
	woman.set("npc_name", "GLITCH")
	world.add_child(woman)
	woman.global_position = Vector2(0.0, 40.0)
	if woman.has_method("set_clan_name"):
		woman.set_clan_name("TEST", "test_woman_glitch")
	for _i in 8:
		await process_frame
	if not occ.force_assign(woman, hut, 0, "woman"):
		_fail("force_assign living hut")
		_finish()
		return
	var presence: Node = root.get_node("HutWomanWorkPresence")
	var home: Node = occ.get_home_living_hut(woman)
	print("WOMAN_GLITCH_ASSIGN occupant=%s home=%s ref_state=%s" % [
		presence.is_living_hut_occupant(woman),
		home,
		occ.get_ref_state(woman),
	])
	var fsm_now: Node = woman.get("fsm")
	if fsm_now and fsm_now.get("states") is Dictionary:
		var occ_state: Node = (fsm_now.get("states") as Dictionary).get("occupy_building")
		if occ_state and occ_state.has_method("can_enter"):
			print("WOMAN_GLITCH_OCCUPY_CAN_ENTER %s" % occ_state.can_enter())
		if fsm_now.has_method("_evaluate_states"):
			fsm_now._evaluate_states()
	var fsm: Node = woman.get("fsm")
	if fsm and fsm.has_method("force_evaluation"):
		fsm.force_evaluation()
	for _i in 5:
		await physics_frame
	var rows: Array = []
	for _i in FRAMES:
		await physics_frame
		if not is_instance_valid(woman):
			_fail("woman freed during sample")
			_finish()
			return
		rows.append(_sample(woman))
	_report(rows, hut)
	world.queue_free()
	_finish()


func _sample(woman: Node) -> Dictionary:
	var state := ""
	var fsm: Node = woman.get("fsm")
	if fsm and fsm.has_method("get_current_state_name"):
		state = str(fsm.get_current_state_name())
	var mode := "none"
	var tgt := Vector2.ZERO
	var steer: Node = woman.get("steering_agent")
	if steer:
		mode = _mode_name(steer)
		tgt = steer.target_position
	return {
		"x": woman.global_position.x,
		"y": woman.global_position.y,
		"spd": woman.velocity.length(),
		"state": state,
		"mode": mode,
		"tx": tgt.x,
		"ty": tgt.y,
		"presence": bool(woman.get_meta("hut_work_presence_active", false)),
	}


func _mode_name(steer: Node) -> String:
	var mode: int = int(steer.get("current_mode"))
	if steer.get("SteeringMode") == null:
		return str(mode)
	match mode:
		steer.SteeringMode.SEEK:
			return "SEEK"
		steer.SteeringMode.ARRIVE:
			return "ARRIVE"
		steer.SteeringMode.FLEE:
			return "FLEE"
		steer.SteeringMode.WANDER:
			return "WANDER"
		steer.SteeringMode.HOLD:
			return "HOLD"
		_:
			return str(mode)


func _report(rows: Array, hut: Node2D) -> void:
	var presence: Node = root.get_node("HutWomanWorkPresence")
	var stand: Vector2 = presence.hut_approach_position(hut)
	var states := {}
	var modes := {}
	var reversals := 0
	var min_x := INF
	var max_x := -INF
	var min_y := INF
	var max_y := -INF
	var spd_sum := 0.0
	for i in rows.size():
		var row: Dictionary = rows[i]
		states[row["state"]] = int(states.get(row["state"], 0)) + 1
		modes[row["mode"]] = int(modes.get(row["mode"], 0)) + 1
		min_x = minf(min_x, row["x"])
		max_x = maxf(max_x, row["x"])
		min_y = minf(min_y, row["y"])
		max_y = maxf(max_y, row["y"])
		spd_sum += float(row["spd"])
		if i >= 2:
			var a := Vector2(rows[i - 1]["x"] - rows[i - 2]["x"], rows[i - 1]["y"] - rows[i - 2]["y"])
			var b := Vector2(row["x"] - rows[i - 1]["x"], row["y"] - rows[i - 1]["y"])
			if a.length_squared() > 0.25 and b.length_squared() > 0.25 and a.dot(b) < 0.0:
				reversals += 1
	var last: Dictionary = rows[rows.size() - 1]
	var end_d: float = Vector2(last["x"], last["y"]).distance_to(stand)
	var bbox := Vector2(max_x - min_x, max_y - min_y)
	var dominant := _top_key(states)
	print("WOMAN_GLITCH_TRACE state=%s modes=%s reversals=%d bbox=%.1f,%.1f mean_spd=%.1f end_dist_to_hut_foot=%.1f presence_end=%s stand=%.1f,%.1f" % [
		states, modes, reversals, bbox.x, bbox.y, spd_sum / rows.size(), end_d, str(last["presence"]), stand.x, stand.y
	])
	print("WOMAN_GLITCH_SAMPLES first=%s last=%s" % [rows[0], last])
	var jitter: bool = bbox.length() < 48.0 and reversals >= 4
	var never_arrived: bool = end_d > 36.0 and not bool(last["presence"])
	if jitter or never_arrived:
		_fail("woman did not settle at the hut (dominant_state=%s jitter=%s never_arrived=%s)" % [dominant, jitter, never_arrived])
	else:
		print("WOMAN_GLITCH_PASS settled at hut")


func _top_key(counts: Dictionary) -> String:
	var best := ""
	var n := -1
	for k in counts.keys():
		if int(counts[k]) > n:
			n = int(counts[k])
			best = str(k)
	return best


func _fail(msg: String) -> void:
	_failed += 1
	print("WOMAN_GLITCH_FAIL %s" % msg)


func _finish() -> void:
	print("WOMAN_GLITCH_TEST failed=%d" % _failed)
	quit(0 if _failed == 0 else 1)
