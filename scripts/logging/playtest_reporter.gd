extends SceneTree

# Playtest reporter - summarize agro/combat (and herd) events from a playtest capture.
# Usage: Run --agro-combat-test (capture auto-enabled) or --playtest-capture; then run this script.
#   godot --path . -s scripts/logging/playtest_reporter.gd [path_to.jsonl]
#   If no path given, uses latest playtest_*.jsonl in user://.

var _counts: Dictionary = {}
var _agro_by_reason: Dictionary = {}  # reason -> count (aoa_wilderness, aoa, proximity, etc)
var _fps_samples: Array = []
var _session_agro_combat_test: bool = false
var _session_raid_test: bool = false
var _snapshot_in_combat_max: int = 0
var _snapshot_alive_final: int = -1
var _raid_evaluated_max_score: float = -1.0  # For invariant: score >= 1.0 but no raid_started

func _init() -> void:
	if OS.get_name() == "Web":
		print("Playtest reporter is not available on Web export.")
		quit(0)
		return
	var path: String = ""
	# 1) run_playtest.ps1 writes Tests/.playtest_reporter_path.txt (always; env can be missing on Windows)
	var sentinel: String = ProjectSettings.globalize_path("res://Tests/.playtest_reporter_path.txt")
	if FileAccess.file_exists(sentinel):
		var sf = FileAccess.open(sentinel, FileAccess.READ)
		if sf:
			var p = sf.get_as_text().strip_edges().replace("\\", "/")
			sf.close()
			if p != "" and FileAccess.file_exists(p):
				path = p
	# 2) GODOT_REPORT_JSONL from parent
	if path.is_empty():
		var env_path: String = OS.get_environment("GODOT_REPORT_JSONL").strip_edges()
		if env_path != "":
			env_path = env_path.replace("\\", "/")
			if FileAccess.file_exists(env_path):
				path = env_path
	# 2) User args after -- (may be empty with -s on some Godot builds)
	if path.is_empty():
		var args = OS.get_cmdline_user_args()
		for i in range(args.size()):
			if args[i] == "--" and i + 1 < args.size():
				path = args[i + 1]
				break
			elif not args[i].begins_with("-"):
				path = args[i]
				break
		if path.is_empty():
			for a in args:
				if not a.begins_with("-") and ".jsonl" in a:
					path = a
					break
	# 3) Full argv: any argument ending in .jsonl (headless -s sometimes puts path here)
	if path.is_empty():
		for a in OS.get_cmdline_args():
			if a.ends_with(".jsonl") and FileAccess.file_exists(a):
				path = a
				break
	if path.is_empty():
		path = _find_latest_playtest()
	if path.is_empty():
		print("No playtest file found. Run with --agro-combat-test (auto-capture) or --playtest-capture; then run this script with optional path.")
		quit(1)
		return
	_run(path)
	quit(0)

const MARKER_FILE := "user://last_playtest_path.txt"

func _find_latest_playtest() -> String:
	# Prefer marker file written by instrumentor when capture starts
	var marker = FileAccess.open(MARKER_FILE, FileAccess.READ)
	if marker:
		var path = marker.get_as_text().strip_edges()
		marker.close()
		if path != "":
			if path.begins_with("user://"):
				return path
			# GODOT_TEST_LOG_DIR writes absolute path; use if file exists
			if FileAccess.file_exists(path):
				return path
	# Fallback: most recent playtest_*.jsonl by mtime
	var user_dir = OS.get_user_data_dir()
	var da = DirAccess.open(user_dir)
	if not da:
		return ""
	var latest: String = ""
	var latest_mtime: int = 0
	da.list_dir_begin()
	var n = da.get_next()
	while n != "":
		if n.begins_with("playtest_") and n.ends_with(".jsonl"):
			var fp = user_dir.path_join(n)
			var m = FileAccess.get_modified_time(fp)
			if m > latest_mtime:
				latest_mtime = m
				latest = fp
		n = da.get_next()
	da.list_dir_end()
	return latest

func _run(file_path: String) -> void:
	_counts.clear()
	_agro_by_reason.clear()
	_fps_samples.clear()
	_snapshot_in_combat_max = 0
	_snapshot_alive_final = -1
	_session_raid_test = false
	_raid_evaluated_max_score = -1.0
	var f = FileAccess.open(file_path, FileAccess.READ)
	if not f:
		print("Cannot open: ", file_path)
		return
	print("Reading: ", file_path)
	while f.get_position() < f.get_length():
		var line = f.get_line()
		if line.is_empty():
			continue
		var j = JSON.new()
		var err = j.parse(line)
		if err != OK:
			continue
		var obj = j.get_data()
		if typeof(obj) != TYPE_DICTIONARY:
			continue
		var evt = obj.get("evt", "")
		if evt == "session_start":
			if obj.get("agro_combat_test"):
				_session_agro_combat_test = true
			if obj.get("raid_test"):
				_session_raid_test = true
		if evt == "raid_evaluated" and obj.get("score") != null:
			var s: float = float(obj.score)
			if s > _raid_evaluated_max_score:
				_raid_evaluated_max_score = s
		if evt.is_empty():
			continue
		if not _counts.has(evt):
			_counts[evt] = 0
		_counts[evt] += 1
		if evt == "agro_increased" and obj.get("reason") != null:
			var r: String = str(obj.reason)
			_agro_by_reason[r] = _agro_by_reason.get(r, 0) + 1
		if evt == "snapshot":
			if "fps" in obj:
				_fps_samples.append(float(obj.fps))
			if "in_combat" in obj:
				var ic: int = int(obj.in_combat)
				if ic > _snapshot_in_combat_max:
					_snapshot_in_combat_max = ic
			if "alive_npcs" in obj:
				_snapshot_alive_final = int(obj.alive_npcs)
	f.close()
	_print_summary()

func _print_summary() -> void:
	if _session_agro_combat_test:
		print("--- Session: agro/combat raid test ---")
	if _session_raid_test:
		print("--- Session: raid test (ClanBrain) ---")
		print("--- Raid test ---")
		var raid_evts = ["raid_evaluated", "raid_started", "raid_joined", "raid_aborted", "test_run_ended_raid"]
		for evt in raid_evts:
			print("  %s: %d" % [evt, _counts.get(evt, 0)])
		const MIN_RAID_PARTY_SIZE: int = 2
		var rs: int = _counts.get("raid_started", 0)
		var rj: int = _counts.get("raid_joined", 0)
		if rs == 0:
			print("  FAIL: no raid_started (check score or target)")
		if rj < MIN_RAID_PARTY_SIZE and rs > 0:
			print("  FAIL: raid_joined=%d < %d (recruitment blocked)" % [rj, MIN_RAID_PARTY_SIZE])
		if _raid_evaluated_max_score >= 1.0 and rs == 0:
			print("  INVARIANT WARNING: raid_evaluated max score %.2f >= 1.0 but no raid_started (expected block logged)" % _raid_evaluated_max_score)
	if _session_agro_combat_test or _session_raid_test:
		pass  # fall through to agro/combat or other
	# Land claim placement (min distance verification)
	var lcp: int = _counts.get("land_claim_placed", 0)
	if lcp > 0:
		print("--- Land claim placement ---")
		print("  land_claim_placed: %d (check nearest_dist >= 1200 in JSONL)" % lcp)
	var agro_combat_evts = [
		"agro_increased", "agro_threshold_crossed",
		"combat_started", "combat_ended", "combat_target_switch", "combat_hit", "combat_whiff"
	]
	print("--- Agro/combat events ---")
	for evt in agro_combat_evts:
		print("  %s: %d" % [evt, _counts.get(evt, 0)])
	if _agro_by_reason.size() > 0:
		print("  (agro by reason: aoa_wilderness=personal space, aoa=on claim, proximity=380px)")
		for r in _agro_by_reason.keys():
			print("    %s: %d" % [r, _agro_by_reason[r]])
	var tuning_evts = ["npc_died", "task_no_job", "competition_complete"]
	var has_tuning = false
	for evt in tuning_evts:
		if _counts.get(evt, 0) > 0:
			has_tuning = true
			break
	if has_tuning:
		print("--- Tuning (normal play) ---")
		for evt in tuning_evts:
			print("  %s: %d" % [evt, _counts.get(evt, 0)])
	if _session_agro_combat_test and _snapshot_alive_final >= 0:
		print("  (snapshot: peak in_combat=%d, final alive_npcs=%d)" % [_snapshot_in_combat_max, _snapshot_alive_final])
	var cs: int = _counts.get("combat_started", 0)
	var ce: int = _counts.get("combat_ended", 0)
	if _session_agro_combat_test and cs > ce:
		print("  ⚠️ INVARIANT: combat_started=%d > combat_ended=%d (dangling combats)" % [cs, ce])
	if _session_agro_combat_test and cs == 0:
		print("  ⚠️ ZERO COMBATS: test_failed_no_engagements")
	const MIN_ENGAGEMENT_PASS: int = 12  # ≥67%% of 18 followers (interim; target 15 for 83%%)
	if _session_agro_combat_test and cs > 0 and cs < MIN_ENGAGEMENT_PASS:
		print("  ❌ TEST FAIL: combat_started=%d < %d (expected ≥67%% of 18 followers to engage)" % [cs, MIN_ENGAGEMENT_PASS])
	var herd_deposit_evts = ["deposit_while_herding"]
	var has_herd_deposit = false
	for evt in herd_deposit_evts:
		if _counts.get(evt, 0) > 0:
			has_herd_deposit = true
			break
	if has_herd_deposit:
		print("--- Herd deposit (herded_count>=2) verification ---")
		for evt in herd_deposit_evts:
			print("  %s: %d" % [evt, _counts.get(evt, 0)])
	var campfire_evts = ["campfire_opened", "campfire_placed", "campfire_upgraded", "campfire_despawned", "campfire_fire_toggled", "campfire_building_built"]
	var has_campfire = false
	for evt in campfire_evts:
		if _counts.get(evt, 0) > 0:
			has_campfire = true
			break
	if has_campfire:
		print("--- Campfire events ---")
		for evt in campfire_evts:
			print("  %s: %d" % [evt, _counts.get(evt, 0)])
	print("--- Other events (sample) ---")
	var skip_evts = agro_combat_evts + tuning_evts + herd_deposit_evts + campfire_evts + ["snapshot", "land_claim_placed"]
	if _session_raid_test:
		skip_evts.append_array(["raid_evaluated", "raid_started", "raid_joined", "raid_aborted", "test_run_ended_raid"])
	for evt in _counts.keys():
		if evt in skip_evts:
			continue
		print("  %s: %d" % [evt, _counts[evt]])
	print("  snapshot: %d" % _counts.get("snapshot", 0))
	if _fps_samples.size() > 0:
		var sum_fps = 0.0
		var min_fps = _fps_samples[0]
		var max_fps = _fps_samples[0]
		for v in _fps_samples:
			sum_fps += v
			min_fps = minf(min_fps, v)
			max_fps = maxf(max_fps, v)
		var avg = sum_fps / float(_fps_samples.size())
		print("--- FPS (from snapshots) ---")
		print("  min: %.1f  avg: %.1f  max: %.1f  n: %d" % [min_fps, avg, max_fps, _fps_samples.size()])
	else:
		print("--- FPS --- (no snapshot fps data)")
