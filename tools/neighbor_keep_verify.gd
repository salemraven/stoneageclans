extends SceneTree

## Floor 3, ceiling 10, extras only within 3x the nearest neighbor.
## Run: godot --headless --path . --script res://tools/neighbor_keep_verify.gd

func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var brain = load("res://scripts/ai/clan_brain.gd")
	var cases: Array = [
		["two far camps", [5000.0, 9000.0], 2],
		["cluster of four", [100.0, 110.0, 120.0], 3],
		["cluster ignores a far camp", [100.0, 110.0, 120.0, 900.0], 3],
		["nearby camps fill past 3", [100.0, 120.0, 140.0, 200.0, 250.0, 280.0], 6],
		["cap at 10", [100.0, 110.0, 120.0, 130.0, 140.0, 150.0, 160.0, 170.0, 180.0, 190.0, 200.0], 10],
	]
	var failed: int = 0
	for row in cases:
		var got: int = brain.neighbor_keep_count(row[1])
		var ok: bool = got == int(row[2])
		if not ok:
			failed += 1
		print("NEIGHBOR_KEEP %s got=%d want=%d ok=%s" % [row[0], got, int(row[2]), "yes" if ok else "no"])
	if failed > 0:
		push_error("NEIGHBOR_KEEP failed %d" % failed)
		quit(1)
	else:
		print("NEIGHBOR_KEEP_OK")
		quit(0)
