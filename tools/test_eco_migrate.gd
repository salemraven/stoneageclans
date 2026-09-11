extends SceneTree

const EcoMigrateRes = preload("res://scripts/world/eco_migrate.gd")

var _failed := 0


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	print("=== ECO_MIGRATE start ===")
	await process_frame
	var tq: Node = root.get_node_or_null("/root/TerrainQuery")
	var cs: Node = root.get_node_or_null("/root/ClimateState")
	cs.enable_for_tests()
	cs.reset_knobs()
	cs.set_region_knobs("CENTER", -0.95, 0.0)
	cs.ice_radius = 0.3
	cs.invalidate_cache()
	var start := Vector2(56000, 56000)
	var rec: Dictionary = EcoMigrateRes.step_toward_legal("mammoth", start, tq)
	print(rec)
	var path := ProjectSettings.globalize_path("res://Tests/logs/eco_migrate.jsonl")
	DirAccess.make_dir_recursive_absolute(path.get_base_dir())
	var f := FileAccess.open(path, FileAccess.WRITE)
	if f:
		f.store_line(JSON.stringify(rec))
		f.close()
	if rec.is_empty() or str(rec.get("from_biome", "")) == "":
		_fail("no migrate line")
	elif str(rec.get("to_biome", "")) in ["glacier", "tundra", "despawn"]:
		print("PASS migrate logged")
	else:
		_fail("expected walk to ice/tundra or despawn got %s" % rec.get("to_biome"))
	print("=== ECO_MIGRATE done failed=%d ===" % _failed)
	quit(0 if _failed == 0 else 1)


func _fail(msg: String) -> void:
	_failed += 1
	print("FAIL %s" % msg)
