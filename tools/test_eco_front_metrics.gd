extends SceneTree
## Front geometry: new ice at the margin, drought walks toward water, hysteresis.

const C = preload("res://scripts/world/climate_constants.gd")

var _failed := 0
var _log_path := ""


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	print("=== ECO_FRONT_METRICS start ===")
	await process_frame
	var cs: Node = root.get_node_or_null("/root/ClimateState")
	var sim: Node = root.get_node_or_null("/root/ClimateSimulator")
	var bf: Node = root.get_node_or_null("/root/BiomeFronts")
	cs.enable_for_tests()
	_log_path = ProjectSettings.globalize_path("res://Tests/logs/front_metrics_run.jsonl")
	DirAccess.make_dir_recursive_absolute(_log_path.get_base_dir())
	var wf := FileAccess.open(_log_path, FileAccess.WRITE)
	if wf:
		wf.close()

	cs.reset_knobs()
	cs.active_event = "ice_age"
	var ice_interior_days := 0
	var ice_margin_days := 0
	var ice_pop := 0
	for d in 22:
		sim.advance_day()
		var m: Dictionary = bf.get_last_metrics()
		m["phase"] = "ice"
		m["day"] = cs.sim_day
		_emit(m)
		if float(m.get("new_ice_share", 0.0)) > C.ICE_POP_HARD + 0.001:
			_fail("ice pop %s day %d" % [m.get("new_ice_share"), d])
			ice_pop += 1
		if d >= 6 and int(m.get("new_ice", 0)) >= 16:
			if float(m.get("new_ice_interior_frac", 0.0)) > 0.55:
				ice_interior_days += 1
			if float(m.get("new_ice_margin_frac", 0.0)) >= 0.5:
				ice_margin_days += 1
			var r: float = float(m.get("ice_radius", 0.0))
			var mx: float = float(m.get("ice_max_dfc", 0.0))
			if mx > r + C.TUNDRA_RING + 0.04:
				_fail("ice jumped past radius day %d max_dfc=%s r=%s" % [d, mx, r])
	if ice_interior_days > 8:
		_fail("new ice filled interior too often (%d days)" % ice_interior_days)
	else:
		print("PASS ice interior-fill days=%d margin days=%d" % [ice_interior_days, ice_margin_days])

	cs.reset_knobs()
	cs.enable_for_tests()
	cs.active_event = "drought"
	var first_des_rd := -1.0
	var last_des_rd := -1.0
	var wet0 := -1
	for d in 36:
		sim.advance_day()
		var m2: Dictionary = bf.get_last_metrics()
		m2["phase"] = "drought"
		m2["day"] = cs.sim_day
		_emit(m2)
		if wet0 < 0:
			wet0 = int(m2.get("wet", 0))
		if float(m2.get("new_dry_share", 0.0)) > C.ICE_POP_HARD + 0.001:
			_fail("dry pop %s day %d" % [m2.get("new_dry_share"), d])
		if int(m2.get("new_des", 0)) >= 8:
			var rd: float = float(m2.get("new_des_mean_rd", 0.0))
			if first_des_rd < 0.0:
				first_des_rd = rd
			last_des_rd = rd
	var wet_end := int(bf.get_last_metrics().get("wet", 0))
	if first_des_rd < 0.0:
		_fail("no desert formed")
	elif last_des_rd > first_des_rd + 0.02:
		_fail("desert walked away from rivers %s -> %s" % [first_des_rd, last_des_rd])
	else:
		print("PASS drought walk rd %s -> %s wet %s -> %s" % [first_des_rd, last_des_rd, wet0, wet_end])
	if wet_end > wet0:
		_fail("drought should not gain river cells")

	var dry4_peak := int(bf.get_last_metrics().get("dry4", 0))
	cs.active_event = ""
	for _r in 18:
		sim.advance_day()
		var m3: Dictionary = bf.get_last_metrics()
		m3["phase"] = "recover"
		m3["day"] = cs.sim_day
		_emit(m3)
	var dry4_rec := int(bf.get_last_metrics().get("dry4", 0))
	if dry4_peak > 80 and dry4_rec >= int(float(dry4_peak) * 0.95):
		_fail("recover did not shrink desert %s -> %s" % [dry4_peak, dry4_rec])
	elif dry4_peak > 80 and dry4_rec < 20:
		_fail("18d recover cleared desert before the wet line finished %s -> %s" % [dry4_peak, dry4_rec])
	else:
		print("PASS recover dry4 %s -> %s" % [dry4_peak, dry4_rec])

	print("=== ECO_FRONT_METRICS done failed=%d ===" % _failed)
	quit(0 if _failed == 0 else 1)


func _emit(rec: Dictionary) -> void:
	rec["t"] = "front_metrics_run"
	var f := FileAccess.open(_log_path, FileAccess.READ_WRITE)
	if f == null:
		f = FileAccess.open(_log_path, FileAccess.WRITE)
	else:
		f.seek_end()
	if f:
		f.store_line(JSON.stringify(rec))
		f.close()


func _fail(msg: String) -> void:
	_failed += 1
	print("FAIL %s" % msg)
