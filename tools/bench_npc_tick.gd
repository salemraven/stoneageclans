extends SceneTree

## Analyzer for the NPC tick benchmark. Reads a lag profile JSONL and reports
## microseconds of GDScript per NPC per physics tick.
##
## Why this metric instead of FPS: the eval arena is a live sim, so every run has a
## different crowd size, different fights, and different graduation timing. Frame rate
## moves with all of that plus vsync, so one run cannot rank two code changes. Dividing
## script time by tick count normalizes away population, making runs comparable.
##
## Usually invoked by tools/bench_npc_tick.sh. Direct use:
##   godot --path . --headless -s res://tools/bench_npc_tick.gd
##
## Env:
##   BENCH_FILE     lag profile to read (default: newest in user://)
##   BENCH_WARMUP   seconds to skip while camps spawn (default 45)
##   BENCH_LABEL    tag for the result line

const DEFAULT_WARMUP := 45.0


func _init() -> void:
	var warmup := _env_float("BENCH_WARMUP", DEFAULT_WARMUP)
	var label := OS.get_environment("BENCH_LABEL")
	if label == "":
		label = "unlabeled"
	var path := OS.get_environment("BENCH_FILE")
	if path == "":
		path = _newest_profile()
	if path == "":
		push_error("BENCH_NPC_TICK: no lag profile found in user:// — run with --lag-profile first")
		quit(1)
		return
	var rows := _read_intervals(path, warmup)
	if rows.is_empty():
		push_error("BENCH_NPC_TICK: no usable intervals after warmup in %s" % path)
		quit(1)
		return
	_report(label, path, rows)
	quit(0)


func _env_float(key: String, fallback: float) -> float:
	var raw := OS.get_environment(key)
	return float(raw) if raw.is_valid_float() else fallback


func _newest_profile() -> String:
	var dir := DirAccess.open("user://")
	if dir == null:
		return ""
	var best := ""
	for f in dir.get_files():
		if f.begins_with("lag_profile_") and f.ends_with(".jsonl") and f > best:
			best = f
	return "user://" + best if best != "" else ""


func _read_intervals(path: String, warmup: float) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return out
	while not file.eof_reached():
		var line := file.get_line()
		if line.is_empty() or not line.contains("\"interval\""):
			continue
		var parsed: Variant = JSON.parse_string(line)
		if parsed is not Dictionary:
			continue
		var row: Dictionary = parsed
		if float(row.get("t", 0.0)) < warmup:
			continue
		if int(row.get("npc_physics_ticks", 0)) <= 0:
			continue
		# Older captures predate the usec counters; skip rather than report zeros.
		if not row.has("npc_physics_usec"):
			continue
		out.append(row)
	file.close()
	return out


func _report(label: String, path: String, rows: Array[Dictionary]) -> void:
	var usec_total := 0.0
	var ticks_total := 0.0
	var awake_total := 0.0
	var steps_per_frame_total := 0.0
	var fighters_peak := 0
	var per_tick: Array[float] = []
	for r in rows:
		usec_total += float(r.get("npc_physics_usec", 0))
		ticks_total += float(r.get("npc_physics_ticks", 0))
		awake_total += float(r.get("npcs_physics_process", 0))
		steps_per_frame_total += float(r.get("physics_steps_per_frame", 0.0))
		fighters_peak = maxi(fighters_peak, int(r.get("npcs_awake_fighters", 0)))
		per_tick.append(float(r.get("npc_usec_per_tick", 0.0)))
	per_tick.sort()
	var n := rows.size()
	var mean_per_tick := usec_total / maxf(ticks_total, 1.0)
	var mean_awake := awake_total / float(n)
	var mean_steps_per_frame := steps_per_frame_total / float(n)
	# What actually decides frame rate: cost per tick * awake NPCs * 60 ticks per second.
	# Past 1_000_000 usec the physics loop cannot finish a second of sim in a second.
	var budget := mean_per_tick * mean_awake * 60.0
	print("")
	print("=== BENCH_NPC_TICK RESULT ===")
	print("label             %s" % label)
	print("profile           %s" % path)
	print("samples           %d seconds" % n)
	print("mean awake NPCs   %.1f (peak fighters %d)" % [mean_awake, fighters_peak])
	print("usec_per_tick     %.2f   <-- compare this, lower is better" % mean_per_tick)
	print("median            %.2f" % per_tick[n / 2])
	print("p10 / p90         %.2f / %.2f" % [
		per_tick[int(n * 0.1)], per_tick[mini(int(n * 0.9), n - 1)]
	])
	print("script usec/sec   %.0f of 1000000 (%.0f%% of the physics budget)" % [
		budget, budget / 10000.0
	])
	print("physics steps/frame %.2f (at max_physics_steps_per_frame the frame is clamped)"
		% mean_steps_per_frame)
	print("BENCH_NPC_TICK: ok label=%s usec_per_tick=%.2f awake=%.1f" % [
		label, mean_per_tick, mean_awake
	])
