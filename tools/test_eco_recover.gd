extends SceneTree

const ClimateConstantsRes = preload("res://scripts/world/climate_constants.gd")

var _failed := 0


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	print("=== ECO_RECOVER start ===")
	await process_frame
	var cs: Node = root.get_node_or_null("/root/ClimateState")
	var sim: Node = root.get_node_or_null("/root/ClimateSimulator")
	var tq: Node = root.get_node_or_null("/root/TerrainQuery")
	cs.enable_for_tests()
	cs.reset_knobs()
	cs.active_event = "ice_age"
	for _i in 12:
		sim.advance_day()
	var knob := absf(float(cs.temperature["CENTER"]))
	var stress := absf(float(cs.cold_stress["CENTER"]))
	print("onset knob=%s stress=%s" % [knob, stress])
	if stress > knob + 0.02:
		_fail("stress should lag knobs on onset")
	cs.active_event = ""
	var s0 := absf(float(cs.cold_stress["CENTER"]))
	var k0 := absf(float(cs.temperature["CENTER"]))
	for _j in 8:
		sim.advance_day()
	var s1 := absf(float(cs.cold_stress["CENTER"]))
	var k1 := absf(float(cs.temperature["CENTER"]))
	var knob_drop := k0 - k1
	var stress_drop := s0 - s1
	print("recover knob_drop=%s stress_drop=%s" % [knob_drop, stress_drop])
	if stress_drop > knob_drop + 0.01:
		_fail("recover stress faster than knobs")
	cs.reset_knobs()
	cs.enable_for_tests()
	cs.active_event = ""
	var coast0 := float(tq.eco_hud_snapshot(56).get("glacier_coast", 0.0))
	for _k in 20:
		sim.advance_day()
	var coast1 := float(tq.eco_hud_snapshot(56).get("glacier_coast", 0.0))
	print("seasons coast glacier %s -> %s phase=%s" % [coast0, coast1, cs.season_phase])
	if coast1 > coast0 + 0.01:
		_fail("seasons alone raised coast glacier")
	else:
		print("PASS seasons no coast ice")
	print("=== ECO_RECOVER done failed=%d ===" % _failed)
	quit(0 if _failed == 0 else 1)


func _fail(msg: String) -> void:
	_failed += 1
	print("FAIL %s" % msg)
