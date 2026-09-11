extends SceneTree
## Gate E: daily caps + spring return + JSONL.

const ClimateConstantsRes = preload("res://scripts/world/climate_constants.gd")

var _failed := 0


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	print("=== CLIMATE_SIM_TEST start ===")
	await process_frame
	var cs: Node = root.get_node_or_null("/root/ClimateState")
	var sim: Node = root.get_node_or_null("/root/ClimateSimulator")
	cs.enable_for_tests()
	cs.active_event = "ice_age"
	var prev_t: float = float(cs.temperature["CENTER"])
	for i in 30:
		sim.advance_day()
		var t: float = float(cs.temperature["CENTER"])
		var dt: float = absf(t - prev_t)
		if dt > ClimateConstantsRes.MAX_TEMP_DELTA_PER_DAY + 0.0001:
			_fail("temp delta %s day %d" % [dt, i])
		prev_t = t
	print("after 30 ice CENTER temp=%s" % cs.temperature["CENTER"])
	if float(cs.temperature["CENTER"]) > -0.4:
		_fail("ice age should cool CENTER")
	cs.active_event = ""
	var t_ice: float = float(cs.temperature["CENTER"])
	for i in 20:
		sim.advance_day()
	var t_spring: float = float(cs.temperature["CENTER"])
	if absf(t_spring) >= absf(t_ice):
		_fail("spring should pull toward 0 (%s -> %s)" % [t_ice, t_spring])
	else:
		print("PASS spring %s -> %s" % [t_ice, t_spring])
	print("=== CLIMATE_SIM_TEST done failed=%d ===" % _failed)
	quit(0 if _failed == 0 else 1)


func _fail(msg: String) -> void:
	_failed += 1
	print("FAIL %s" % msg)
