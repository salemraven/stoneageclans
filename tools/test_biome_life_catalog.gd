extends SceneTree

var _failed := 0


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	print("=== BIOME_LIFE_CATALOG start ===")
	await process_frame
	var path := "res://data/biome_life.json"
	if not FileAccess.file_exists(path):
		_fail("missing json")
		quit(1)
		return
	var f := FileAccess.open(path, FileAccess.READ)
	var parsed: Variant = JSON.parse_string(f.get_as_text())
	f.close()
	if not parsed is Dictionary:
		_fail("json not object")
		quit(1)
		return
	var data: Dictionary = parsed
	var fauna: Array = data.get("fauna", [])
	var flora: Array = data.get("flora", [])
	for e in fauna:
		if not e is Dictionary:
			_fail("fauna row")
			continue
		if str(e.get("id", "")) == "":
			_fail("fauna id")
		var homes: Array = e.get("home_biomes", [])
		if homes.is_empty():
			_fail("fauna %s missing home_biomes" % e.get("id"))
		var spr := str(e.get("sprite", ""))
		if spr != "" and not FileAccess.file_exists(spr) and not ResourceLoader.exists(spr):
			_fail("sprite missing %s" % spr)
	print("fauna=%d flora=%d" % [fauna.size(), flora.size()])
	print("=== BIOME_LIFE_CATALOG done failed=%d ===" % _failed)
	quit(0 if _failed == 0 else 1)


func _fail(msg: String) -> void:
	_failed += 1
	print("FAIL %s" % msg)
