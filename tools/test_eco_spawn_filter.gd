extends SceneTree

const ClimateEvalRes = preload("res://scripts/world/climate_eval.gd")

var _failed := 0


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	print("=== ECO_SPAWN_FILTER start ===")
	await process_frame
	var tq: Node = root.get_node_or_null("/root/TerrainQuery")
	var cs: Node = root.get_node_or_null("/root/ClimateState")
	cs.enable_for_tests()
	cs.reset_knobs()
	var Catalog: Node = root.get_node_or_null("/root/BiomeLifeCatalog")
	if Catalog == null:
		_fail("BiomeLifeCatalog missing")
		quit(1)
		return
	Catalog.reload()
	var pts: Array[Vector2] = [
		Vector2(32768, 32768), Vector2(40000, 18000), Vector2(18000, 45000), Vector2(50000, 20000),
		Vector2(20000, 20000), Vector2(48000, 48000), Vector2(1000, 1000), Vector2(64000, 64000),
		Vector2(32768, 20000), Vector2(20000, 32768), Vector2(40000, 40000), Vector2(25000, 40000),
		Vector2(45000, 25000), Vector2(30000, 50000), Vector2(50000, 30000), Vector2(35000, 35000),
	]
	var path := ProjectSettings.globalize_path("res://Tests/logs/eco_spawn_sample.jsonl")
	DirAccess.make_dir_recursive_absolute(path.get_base_dir())
	var f := FileAccess.open(path, FileAccess.WRITE)
	for p in pts:
		var base: int = tq.get_base_biome(p)
		var eff: int = tq.get_effective_biome(p)
		var near_w: bool = tq.river_distance_01(p) < 0.14
		var rec := {
			"t": "eco_spawn_sample",
			"pos": [p.x, p.y],
			"base": base,
			"effective": eff,
			"flora": Catalog.legal_flora(eff, near_w),
			"fauna": Catalog.legal_fauna(eff),
		}
		if f:
			f.store_line(JSON.stringify(rec))
		if Catalog.can_spawn_fauna("mammoth", ClimateEvalRes.BIOME_DESERT):
			_fail("mammoth on desert")
		var palms: Array = Catalog.legal_flora(ClimateEvalRes.BIOME_DESERT, true)
		var palm_ok := false
		for fl in palms:
			if str(fl.get("id")) == "palm_wood":
				palm_ok = true
		if not palm_ok:
			_fail("palm only desert+water missing")
		var palms_dry: Array = Catalog.legal_flora(ClimateEvalRes.BIOME_DESERT, false)
		for fl2 in palms_dry:
			if str(fl2.get("id")) == "palm_wood":
				_fail("palm without water")
	if f:
		f.close()
	var w_sav: float = float(Catalog.spawn_weight("deer", ClimateEvalRes.BIOME_SAVANNA))
	var w_des: float = float(Catalog.spawn_weight("deer", ClimateEvalRes.BIOME_DESERT))
	if w_des >= w_sav:
		_fail("herdables should be rarer in desert")
	else:
		print("PASS sparse desert weight %s < %s" % [w_des, w_sav])
	print("=== ECO_SPAWN_FILTER done failed=%d ===" % _failed)
	quit(0 if _failed == 0 else 1)


func _fail(msg: String) -> void:
	_failed += 1
	print("FAIL %s" % msg)
