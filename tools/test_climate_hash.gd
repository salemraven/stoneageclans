extends SceneTree
## Gate B: integer hash stability + golden coords.

const ClimateHashRes = preload("res://scripts/world/climate_hash.gd")
const GOLDEN := "res://Tests/logs/climate_golden_coords.json"

var _failed := 0


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	print("=== CLIMATE_HASH_TEST start ===")
	var a: int = ClimateHashRes.hash_u32(10, 20, 882001)
	var b: int = ClimateHashRes.hash_u32(10, 20, 882001)
	if a != b:
		_fail("same input twice")
	else:
		print("PASS same input twice %d" % a)
	var txt := FileAccess.get_file_as_string(GOLDEN)
	var parsed: Variant = JSON.parse_string(txt)
	if typeof(parsed) != TYPE_DICTIONARY:
		_fail("golden json missing")
		quit(1)
		return
	var seed: int = int(parsed.get("seed", 882001))
	for row in parsed.get("coords", []):
		var x: int = int(row["x"])
		var y: int = int(row["y"])
		var expect: int = int(row["h"])
		var got: int = ClimateHashRes.hash_u32(x, y, seed)
		if got != expect:
			_fail("golden (%d,%d) got %d expect %d" % [x, y, got, expect])
		else:
			print("PASS golden %d,%d" % [x, y])
	print("=== CLIMATE_HASH_TEST done failed=%d ===" % _failed)
	quit(0 if _failed == 0 else 1)


func _fail(msg: String) -> void:
	_failed += 1
	print("FAIL %s" % msg)
