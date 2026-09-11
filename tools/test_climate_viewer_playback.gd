extends SceneTree
## Viewer playback: skip days, log every day, assert grow/recede.

const ClimateConstantsRes = preload("res://scripts/world/climate_constants.gd")

var _failed := 0
var _log_path := ""


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	print("=== CLIMATE_VIEWER_PLAYBACK start ===")
	await process_frame
	var cs: Node = root.get_node_or_null("/root/ClimateState")
	var sim: Node = root.get_node_or_null("/root/ClimateSimulator")
	var tq: Node = root.get_node_or_null("/root/TerrainQuery")
	if cs == null or sim == null or tq == null or not tq.is_authored():
		print("FAIL missing autoloads")
		quit(1)
		return
	cs.enable_for_tests()
	_log_path = ProjectSettings.globalize_path("res://Tests/logs/climate_viewer_playback.jsonl")
	DirAccess.make_dir_recursive_absolute(_log_path.get_base_dir())
	var wf := FileAccess.open(_log_path, FileAccess.WRITE)
	if wf:
		wf.close()

	cs.reset_knobs()
	var base_g := _gshare(tq)
	var base_d := _dshare(tq)
	var base_w := _wshare(tq)
	_emit({"kind": "baseline", "glacier": base_g, "desert": base_d, "water": base_w})

	# Ice age: glacier share must not drop; CENTER colder than NE; no 50% jumps.
	cs.active_event = "ice_age"
	var prev_g := base_g
	var peak_g := base_g
	var prev_t := float(cs.temperature["CENTER"])
	for d in 40:
		sim.advance_day()
		var tnow := float(cs.temperature["CENTER"])
		var dt := absf(tnow - prev_t)
		if dt > ClimateConstantsRes.MAX_TEMP_DELTA_PER_DAY + 0.0001:
			_fail("ice day %d temp jump %s" % [d, dt])
		var crossed_snow := prev_t > ClimateConstantsRes.SNOW_TEMP and tnow <= ClimateConstantsRes.SNOW_TEMP
		prev_t = tnow
		var g := _gshare(tq)
		var dg := g - prev_g
		if dg < -0.002:
			_fail("ice day %d glacier receded %s -> %s" % [d, prev_g, g])
		if dg > 0.15 and not crossed_snow:
			_fail("ice day %d glacier jump %s (no snow-threshold cross)" % [d, dg])
		elif crossed_snow:
			print("NOTE snow threshold cross day %d glacier +%s" % [d, dg])
		var g_c := _gshare_uv(tq, Vector2(0.38, 0.38), Vector2(0.62, 0.62))
		var g_ne := _gshare_uv(tq, Vector2(0.66, 0.0), Vector2(1.0, 0.34))
		if g_ne > g_c + 0.02 and g_c > 0.0:
			_fail("ice day %d NE glacier %s > CENTER %s" % [d, g_ne, g_c])
		_emit({
			"kind": "ice_day",
			"day": cs.sim_day,
			"g": g,
			"dg": dg,
			"g_center": g_c,
			"g_ne": g_ne,
			"temp_c": tnow,
		})
		prev_g = g
		peak_g = maxf(peak_g, g)
	if peak_g <= base_g:
		_fail("ice age did not grow glacier %s -> %s" % [base_g, peak_g])
	else:
		print("PASS ice glacier %s -> %s" % [base_g, peak_g])

	# Recover: glacier should trend down over 30 days vs peak.
	cs.active_event = ""
	var g_after_ice := prev_g
	for d in 30:
		sim.advance_day()
		var g := _gshare(tq)
		_emit({"kind": "recover_day", "day": cs.sim_day, "g": g})
		prev_g = g
	if prev_g > g_after_ice + 0.002:
		_fail("recover grew glacier %s -> %s" % [g_after_ice, prev_g])
	else:
		print("PASS recover glacier %s -> %s" % [g_after_ice, prev_g])

	cs.reset_knobs()
	cs.enable_for_tests()
	base_d = _dshare(tq)
	cs.active_event = "drought"
	var prev_d := base_d
	for d in 35:
		sim.advance_day()
		var des := _dshare(tq)
		if des + 0.002 < prev_d:
			_fail("drought day %d desert drop %s -> %s" % [d, prev_d, des])
		var d_ne := _dshare_uv(tq, Vector2(0.66, 0.0), Vector2(1.0, 0.34))
		var d_sw := _dshare_uv(tq, Vector2(0.0, 0.66), Vector2(0.34, 1.0))
		_emit({"kind": "drought_day", "day": cs.sim_day, "desert": des, "d_ne": d_ne, "d_sw": d_sw})
		prev_d = des
	if prev_d <= base_d:
		_fail("drought did not grow desert %s -> %s" % [base_d, prev_d])
	else:
		print("PASS drought desert %s -> %s" % [base_d, prev_d])

	cs.reset_knobs()
	cs.enable_for_tests()
	base_w = _wshare(tq)
	cs.active_event = "flood"
	var prev_w := base_w
	for d in 25:
		sim.advance_day()
		var w := _wshare(tq)
		_emit({"kind": "flood_day", "day": cs.sim_day, "water": w})
		prev_w = w
	if prev_w + 0.0001 < base_w:
		_fail("flood shrank water %s -> %s" % [base_w, prev_w])
	else:
		print("PASS flood water %s -> %s" % [base_w, prev_w])

	print("=== CLIMATE_VIEWER_PLAYBACK done failed=%d ===" % _failed)
	quit(0 if _failed == 0 else 1)


func _gshare(tq: Node) -> float:
	return float(tq.sample_climate_histogram(48).get("5", 0.0))


func _dshare(tq: Node) -> float:
	return float(tq.sample_climate_histogram(48).get("2", 0.0))


func _wshare(tq: Node) -> float:
	return float(tq.sample_climate_histogram(48).get("7", 0.0))


func _gshare_uv(tq: Node, a: Vector2, b: Vector2) -> float:
	return float(tq.sample_histogram_uv(a, b, 24).get("5", 0.0))


func _dshare_uv(tq: Node, a: Vector2, b: Vector2) -> float:
	return float(tq.sample_histogram_uv(a, b, 24).get("2", 0.0))


func _emit(rec: Dictionary) -> void:
	rec["t"] = "viewer_playback"
	var f := FileAccess.open(_log_path, FileAccess.READ_WRITE)
	if f == null:
		f = FileAccess.open(_log_path, FileAccess.WRITE)
	else:
		f.seek_end()
	if f:
		f.store_line(JSON.stringify(rec))
		f.close()
	print(JSON.stringify(rec))


func _fail(msg: String) -> void:
	_failed += 1
	print("FAIL %s" % msg)
