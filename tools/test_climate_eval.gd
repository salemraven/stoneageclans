extends SceneTree
## Gate D: Shared Evaluation Contract.

const ClimateEvalRes = preload("res://scripts/world/climate_eval.gd")
const BiomePaletteRes = preload("res://scripts/world/biome_palette.gd")

var _failed := 0


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	print("=== CLIMATE_EVAL_TEST start ===")
	await process_frame
	var tq: Node = root.get_node_or_null("/root/TerrainQuery")
	var cs: Node = root.get_node_or_null("/root/ClimateState")
	if tq == null or not tq.is_authored():
		_fail("TerrainQuery authored")
		quit(1)
		return
	cs.enable_for_tests()
	var samples: Array[Vector2] = [
		Vector2(100, 100),
		Vector2(32768, 32768),
		Vector2(40000, 18000),
		Vector2(18000, 48000),
		Vector2(50000, 22000),
		Vector2(8000, 8000),
	]
	for p in samples:
		var base: int = tq.get_base_biome(p)
		var eff: int = tq.get_effective_biome(p)
		if tq.is_base_water(p):
			if eff != ClimateEvalRes.BIOME_RIVER:
				_fail("knobs0 water %s eff=%d" % [p, eff])
		elif base == BiomePaletteRes.Biome.OCEAN:
			if eff != BiomePaletteRes.Biome.OCEAN:
				_fail("knobs0 ocean %s" % p)
		elif eff != base:
			_fail("knobs0 %s base=%d eff=%d" % [p, base, eff])
	var ocean_p := Vector2(80, 80)
	if tq.get_effective_biome(ocean_p) != BiomePaletteRes.Biome.OCEAN:
		print("note corner biome=%d" % tq.get_effective_biome(ocean_p))
	var hist0: Dictionary = tq.sample_climate_histogram(64)
	cs.set_region_knobs("CENTER", -1.0, 0.0)
	var hist_ice: Dictionary = tq.sample_climate_histogram(64)
	var g0 := float(hist0.get("5", 0.0))
	var g1 := float(hist_ice.get("5", 0.0))
	if g1 < g0:
		_fail("ice should raise glacier share %s -> %s" % [g0, g1])
	else:
		print("PASS glacier %s -> %s" % [g0, g1])
	cs.set_region_knobs("CENTER", 0.0, 0.0)
	cs.set_region_knobs("NE", 0.3, -1.0)
	var hist_d: Dictionary = tq.sample_climate_histogram(64)
	var d0 := float(hist0.get("2", 0.0))
	var d1 := float(hist_d.get("2", 0.0))
	if d1 < d0:
		_fail("drought desert share %s -> %s" % [d0, d1])
	else:
		print("PASS desert %s -> %s" % [d0, d1])
	cs.set_region_knobs("NE", 0.0, 0.0)
	cs.set_region_knobs("CENTER", 0.0, 1.0)
	var hist_f: Dictionary = tq.sample_climate_histogram(64)
	print("flood hist water/river key7=%s" % hist_f.get("7", 0.0))
	_write_hist_log(hist0, hist_ice, hist_d, hist_f)
	print("=== CLIMATE_EVAL_TEST done failed=%d ===" % _failed)
	quit(0 if _failed == 0 else 1)


func _write_hist_log(h0: Dictionary, hi: Dictionary, hd: Dictionary, hf: Dictionary) -> void:
	var path := ProjectSettings.globalize_path("res://Tests/logs/climate_eval.jsonl")
	DirAccess.make_dir_recursive_absolute(path.get_base_dir())
	var f := FileAccess.open(path, FileAccess.WRITE)
	if f:
		f.store_line(JSON.stringify({"t": "eval_hist", "zero": h0, "ice": hi, "drought": hd, "flood": hf}))
		f.close()


func _fail(msg: String) -> void:
	_failed += 1
	print("FAIL %s" % msg)
