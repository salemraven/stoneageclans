extends SceneTree

const BenchMath = preload("res://tools/bench_math.gd")

const DEFAULT_WARMUP := 45.0


func _init() -> void:
	var warmup := _env_float("BENCH_WARMUP", DEFAULT_WARMUP)
	var label := OS.get_environment("BENCH_LABEL")
	if label == "":
		label = "unlabeled"
	var requested := _env_float("BENCH_SECONDS", 180.0)
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
	var stats := _summarize(rows)
	var valid: Dictionary = BenchMath.validate_run(
		rows,
		int(stats["peak_fighters"]),
		int(stats["births"]),
		int(stats["combat_entries"]),
		requested,
		warmup
	)
	_report(label, path, rows, stats)
	_write_history(label, path, stats)
	var against := OS.get_environment("BENCH_AGAINST")
	var compare_ok := true
	if against != "":
		compare_ok = _compare_against(against, warmup, rows)
	if not bool(valid["ok"]):
		push_error("BENCH_NPC_TICK: invalid run: %s" % str(valid["reasons"]))
		quit(1)
		return
	if not compare_ok:
		quit(1)
		return
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


func _read_intervals(path: String, warmup: float) -> Array:
	var out: Array = []
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
		if not row.has("npc_physics_usec"):
			continue
		out.append(row)
	file.close()
	return out


func _summarize(rows: Array) -> Dictionary:
	var usec_total := 0.0
	var ticks_total := 0.0
	var awake_total := 0.0
	var steps_total := 0.0
	var fighters_peak := 0
	var sec_fsm := 0
	var sec_sep := 0
	var sec_sheep := 0
	var sec_combat := 0
	var sec_move := 0
	var sec_claim := 0
	var sec_all := 0
	var phys_usec := 0
	var births := 0
	var combat_entries := 0
	var flee_entries := 0
	var last: Dictionary = rows[-1]
	for r in rows:
		usec_total += float(r.get("npc_physics_usec", 0))
		ticks_total += float(r.get("npc_physics_ticks", 0))
		awake_total += float(r.get("npcs_physics_process", 0))
		steps_total += float(r.get("physics_steps_per_frame", 0.0))
		fighters_peak = maxi(fighters_peak, int(r.get("npcs_awake_fighters", 0)))
		sec_fsm += int(r.get("section_fsm_usec", 0))
		sec_sep += int(r.get("section_separation_usec", 0))
		sec_sheep += int(r.get("section_sheep_usec", 0))
		sec_combat += int(r.get("section_combat_query_usec", 0))
		sec_move += int(r.get("section_move_usec", 0))
		sec_claim += int(r.get("section_claim_usec", 0))
		sec_all += int(r.get("section_usec_sum", 0))
		phys_usec += int(r.get("npc_physics_usec", 0))
	births = int(last.get("lifetime_births", 0))
	combat_entries = int(last.get("lifetime_combat_entries", 0))
	flee_entries = int(last.get("lifetime_flee_combat_entries", 0))
	if births == 0:
		for r in rows:
			births += int(r.get("births", 0))
	if combat_entries == 0:
		for r in rows:
			combat_entries += int(r.get("combat_entries", 0))
	if flee_entries == 0:
		for r in rows:
			flee_entries += int(r.get("flee_combat_entries", 0))
	var n := float(rows.size())
	var cover := 0.0
	if phys_usec > 0:
		cover = float(sec_all) / float(phys_usec)
	return {
		"usec_per_tick": usec_total / maxf(ticks_total, 1.0),
		"mean_awake": awake_total / n,
		"peak_fighters": fighters_peak,
		"steps_per_frame": steps_total / n,
		"section_fsm_usec": sec_fsm,
		"section_separation_usec": sec_sep,
		"section_sheep_usec": sec_sheep,
		"section_combat_query_usec": sec_combat,
		"section_move_usec": sec_move,
		"section_claim_usec": sec_claim,
		"section_cover": cover,
		"births": births,
		"combat_entries": combat_entries,
		"flee_combat_entries": flee_entries,
		"samples": rows.size(),
	}


func _report(label: String, path: String, rows: Array, stats: Dictionary) -> void:
	print("")
	print("=== BENCH_NPC_TICK RESULT ===")
	print("label             %s" % label)
	print("profile           %s" % path)
	print("samples           %d seconds" % int(stats["samples"]))
	print("mean awake NPCs   %.1f (peak fighters %d)" % [float(stats["mean_awake"]), int(stats["peak_fighters"])])
	print("usec_per_tick     %.2f   <-- compare this, lower is better" % float(stats["usec_per_tick"]))
	print("physics steps/frame %.2f" % float(stats["steps_per_frame"]))
	print("births            %d  combat_entries %d  flee_combat_entries %d" % [
		int(stats["births"]), int(stats["combat_entries"]), int(stats["flee_combat_entries"])
	])
	print("sections usec     fsm=%d sep=%d sheep=%d combat=%d move=%d claim=%d  cover=%.0f%%" % [
		int(stats["section_fsm_usec"]),
		int(stats["section_separation_usec"]),
		int(stats["section_sheep_usec"]),
		int(stats["section_combat_query_usec"]),
		int(stats["section_move_usec"]),
		int(stats.get("section_claim_usec", 0)),
		float(stats["section_cover"]) * 100.0,
	])
	print("awake bins (usec_per_tick):")
	var bins: Dictionary = BenchMath.bin_rows(rows)
	var keys: Array = bins.keys()
	keys.sort()
	for k in keys:
		var bag: Dictionary = bins[k]
		print("  %d-%d  %.2f  n=%d" % [int(k), int(k) + 4, float(bag["mean"]), int(bag["n"])])
	print("BENCH_NPC_TICK: ok label=%s usec_per_tick=%.2f awake=%.1f" % [
		label, float(stats["usec_per_tick"]), float(stats["mean_awake"])
	])


func _write_history(label: String, path: String, stats: Dictionary) -> void:
	var row := {
		"label": label,
		"git_sha": _git_sha(),
		"utc": Time.get_datetime_string_from_system(true),
		"profile": path,
		"usec_per_tick": snappedf(float(stats["usec_per_tick"]), 0.01),
		"peak_fighters": int(stats["peak_fighters"]),
		"mean_awake": snappedf(float(stats["mean_awake"]), 0.1),
		"steps_per_frame": snappedf(float(stats["steps_per_frame"]), 0.01),
		"births": int(stats["births"]),
		"combat_entries": int(stats["combat_entries"]),
		"flee_combat_entries": int(stats["flee_combat_entries"]),
		"section_fsm_usec": int(stats["section_fsm_usec"]),
		"section_separation_usec": int(stats["section_separation_usec"]),
		"section_sheep_usec": int(stats["section_sheep_usec"]),
		"section_combat_query_usec": int(stats["section_combat_query_usec"]),
		"section_move_usec": int(stats["section_move_usec"]),
		"section_cover": snappedf(float(stats["section_cover"]), 0.01),
	}
	var hist_path := "res://Tests/logs/perf_history.jsonl"
	var existing := ""
	if FileAccess.file_exists(hist_path):
		var old := FileAccess.open(hist_path, FileAccess.READ)
		if old:
			existing = old.get_as_text()
			old.close()
	var hist := FileAccess.open(hist_path, FileAccess.WRITE)
	if hist == null:
		push_warning("BENCH_NPC_TICK: could not write %s" % hist_path)
		return
	hist.store_string(existing)
	hist.store_string(JSON.stringify(row) + "\n")
	hist.close()
	print("history row -> %s" % hist_path)


func _git_sha() -> String:
	# Analyzer runs headless; sha is optional context for the scoreboard.
	return OS.get_environment("BENCH_GIT_SHA")


func _compare_against(against: String, warmup: float, after_rows: Array) -> bool:
	var before_rows := _read_intervals(against, warmup)
	if before_rows.is_empty():
		push_error("BENCH_NPC_TICK: BENCH_AGAINST has no usable intervals: %s" % against)
		return false
	var result: Dictionary = BenchMath.compare_bins(
		BenchMath.bin_rows(before_rows),
		BenchMath.bin_rows(after_rows)
	)
	print("compare vs %s:" % against)
	for item in result["bins"]:
		var b: Dictionary = item
		var mark := "FAIL" if bool(b.get("fail", false)) else "ok"
		print("  %s bin %d: %.2f -> %.2f (%+.1f%%)" % [
			mark, int(b["bin"]), float(b["before"]), float(b["after"]), float(b["frac"]) * 100.0
		])
	if not bool(result["ok"]):
		push_error("BENCH_NPC_TICK: regression >5% in at least one matched bin")
		return false
	return true
