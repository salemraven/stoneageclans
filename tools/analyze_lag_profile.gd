extends SceneTree

## Summarize lag_profile JSONL: steady-state FPS, bottleneck scores, ranked fix recommendations.
## Usage: godot --headless -s res://tools/analyze_lag_profile.gd [-- path/to/lag_profile.jsonl]

const DEFAULT_GLOB := "lag_profile_"

const FIX_NPC_SLEEP := "npc_sleep_wake"
const FIX_AREA_MONITORING := "area_monitoring_sleep"
const FIX_WORLD_DENSITY := "world_density_config"
const FIX_BOOT_CHUNKS := "boot_chunk_stagger"
const FIX_RESOURCE_PROCESS := "resource_process_sleep"
const FIX_PERCEPTION_SCRIPTS := "perception_script_cost"


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var path := _resolve_path()
	if path.is_empty():
		push_error("analyze_lag_profile: no lag_profile JSONL found under user://")
		quit(1)
		return
	var lines: PackedStringArray = FileAccess.get_file_as_string(path).split("\n", false)
	var intervals: Array[Dictionary] = []
	var spikes: Array[Dictionary] = []
	var chunk_loads: Array[Dictionary] = []
	var meta: Dictionary = {}
	for line in lines:
		if line.strip_edges().is_empty():
			continue
		var parsed: Variant = JSON.parse_string(line)
		if typeof(parsed) != TYPE_DICTIONARY:
			continue
		var row: Dictionary = parsed as Dictionary
		match str(row.get("evt", "")):
			"lag_profile_start":
				meta = row
			"interval":
				intervals.append(row)
			"frame_spike":
				spikes.append(row)
			"chunk_load":
				chunk_loads.append(row)
	if intervals.is_empty():
		push_error("analyze_lag_profile: no interval rows in %s" % path)
		quit(1)
		return

	var boot_intervals: Array[Dictionary] = []
	var steady_intervals: Array[Dictionary] = []
	for row in intervals:
		if float(row.get("t", 0.0)) < 3.0 or int(row.get("chunk_loads", 0)) > 0:
			boot_intervals.append(row)
		else:
			steady_intervals.append(row)
	if steady_intervals.is_empty():
		steady_intervals = intervals.duplicate()

	var steady: Dictionary = _avg_interval(steady_intervals)
	var boot: Dictionary = _avg_interval(boot_intervals) if not boot_intervals.is_empty() else steady
	steady["interval_sec"] = float(meta.get("interval_sec", 1.0))
	var scores: Dictionary = _score_fix_paths(steady, boot, chunk_loads, meta)

	intervals.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		return float(a.get("frame_ms_max", 0.0)) > float(b.get("frame_ms_max", 0.0))
	)

	print("=== LAG PROFILE ANALYSIS ===")
	print("file: %s" % path)
	print("intervals: %d  spikes: %d  chunk_load_events: %d" % [intervals.size(), spikes.size(), chunk_loads.size()])
	print("")
	_print_steady_summary(steady, boot)
	print("")
	print("Top 3 worst intervals (by max frame ms):")
	for i in mini(3, intervals.size()):
		_print_interval_row(i + 1, intervals[i])
	print("")
	print("=== BOTTLENECK BREAKDOWN (steady state) ===")
	_print_bottleneck_breakdown(steady)
	print("")
	print("=== RANKED FIX RECOMMENDATIONS ===")
	var ranked: Array = scores.keys()
	ranked.sort_custom(func(a: String, b: String) -> bool:
		return int(scores[a]["score"]) > int(scores[b]["score"])
	)
	for i in ranked.size():
		var key: String = ranked[i]
		var entry: Dictionary = scores[key]
		if int(entry.get("score", 0)) < 25:
			continue
		print("%d. [%d] %s" % [i + 1, int(entry["score"]), str(entry["title"])])
		print("   %s" % str(entry["why"]))
		print("   Evidence: %s" % str(entry["evidence"]))
		print("   Try: %s" % str(entry["action"]))
	print("")
	if chunk_loads.size() > 0:
		chunk_loads.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
			return int(a.get("usec", 0)) > int(b.get("usec", 0))
		)
		var slow: Dictionary = chunk_loads[0]
		print(
			"Slowest chunk_load: (%s,%s) %.2fms"
			% [str(slow.get("chunk_x")), str(slow.get("chunk_y")), int(slow.get("usec", 0)) / 1000.0]
		)
	print("ANALYZE_LAG_PROFILE_OK")
	quit(0)


func _avg_interval(rows: Array[Dictionary]) -> Dictionary:
	if rows.is_empty():
		return {}
	var keys: Array[String] = [
		"frame_ms_avg", "frame_ms_max", "engine_process_ms", "engine_physics_ms",
		"resources", "resources_process_enabled", "resources_monitoring",
		"gatherables", "ground_items", "areas_monitoring",
		"npcs", "npcs_physics_process", "npcs_near_800", "npcs_mid_800_to_half",
		"npcs_far_half_to_quarter", "npcs_very_far",
		"perception_areas_monitoring", "land_claim_zones_monitoring",
		"physics_2d_collision_pairs", "physics_2d_active_objects",
		"gatherable_process_calls", "npc_physics_ticks", "npc_fsm_ticks",
		"perception_process_ticks", "herd_influence_physics_ticks",
		"chunk_loads", "frames",
	]
	var out: Dictionary = {"interval_count": rows.size()}
	for key in keys:
		var sum := 0.0
		for row in rows:
			sum += float(row.get(key, 0.0))
		out[key] = sum / float(rows.size())
	return out


func _score_fix_paths(steady: Dictionary, boot: Dictionary, chunk_loads: Array, meta: Dictionary) -> Dictionary:
	var frame_ms: float = maxf(float(steady.get("frame_ms_avg", 16.0)), 1.0)
	var physics_ms: float = float(steady.get("engine_physics_ms", 0.0))
	var process_ms: float = float(steady.get("engine_process_ms", 0.0))
	var physics_share: float = physics_ms / frame_ms
	var process_share: float = process_ms / frame_ms

	var npcs: float = float(steady.get("npcs", 0.0))
	var physics_hz: float = 60.0
	var npc_phys_ticks: float = float(steady.get("npc_physics_ticks", 0.0))
	var npc_phys_per_sec: float = npc_phys_ticks
	var expected_npc_phys_per_sec: float = npcs * physics_hz
	var npc_phys_ratio: float = npc_phys_per_sec / maxf(expected_npc_phys_per_sec, 1.0)

	var npcs_very_far: float = float(steady.get("npcs_very_far", 0.0))
	var npcs_far_total: float = (
		float(steady.get("npcs_far_half_to_quarter", 0.0)) + npcs_very_far
	)
	var npc_far_ratio: float = npcs_far_total / maxf(npcs, 1.0)

	var areas_mon: float = float(steady.get("areas_monitoring", 0.0))
	var res_mon: float = float(steady.get("resources_monitoring", 0.0))
	var pairs: float = float(steady.get("physics_2d_collision_pairs", 0.0))
	var gather_ticks: float = float(steady.get("gatherable_process_calls", 0.0))
	var res_proc: float = float(steady.get("resources_process_enabled", 0.0))
	var resources: float = float(steady.get("resources", 0.0))
	var perception_ticks: float = float(steady.get("perception_process_ticks", 0.0))

	var boot_chunk_count := chunk_loads.size()
	var boot_frame: float = float(boot.get("frame_ms_avg", frame_ms))

	var scores: Dictionary = {}

	scores[FIX_NPC_SLEEP] = {
		"score": _score_sum([
			[npc_phys_ratio >= 0.9, 35],
			[npcs >= 60, 20],
			[physics_share >= 0.22, 30],
			[npc_far_ratio >= 0.35, 25],
			[npc_phys_per_sec >= 80, 15],
		]),
		"title": "NPC sleep/wake by chunk interest",
		"why": "Many NPCs still run full physics/AI every frame even when far from the player.",
		"evidence": "npcs=%.0f phys_ticks/sec=%.0f (%.0f%% of 60Hz budget), far=%.0f%%, physics=%.1fms (%.0f%% of frame)"
			% [npcs, npc_phys_per_sec, npc_phys_ratio * 100.0, npc_far_ratio * 100.0, physics_ms, physics_share * 100.0],
		"action": "Disable _physics_process + PerceptionArea monitoring for distant/off-screen NPCs; wake on chunk/player interest.",
	}

	scores[FIX_AREA_MONITORING] = {
		"score": _score_sum([
			[areas_mon >= 400, 25],
			[res_mon >= 300, 25],
			[physics_share >= 0.22, 25],
			[pairs >= 200, 20],
			[physics_ms > process_ms * 1.5, 20],
		]),
		"title": "Sleep Area2D monitoring on distant resources",
		"why": "Hundreds of gatherable/ground/perception/claim overlap areas keep physics busy even without _process.",
		"evidence": "areas_monitoring=%.0f (resources=%.0f), collision_pairs=%.0f, physics=%.1fms vs process=%.1fms"
			% [areas_mon, res_mon, pairs, physics_ms, process_ms],
		"action": "monitoring=false when chunk/player far; or player-side spatial gather query instead of per-tree Area2D.",
	}

	scores[FIX_WORLD_DENSITY] = {
		"score": _score_sum([
			[resources >= 1200, 25],
			[float(steady.get("gatherables", 0.0)) >= 800, 20],
			[frame_ms >= 100.0, 15],
			[physics_share >= 0.2, 15],
		]),
		"title": "Lower world density config (quick test)",
		"why": "High chunk resource density multiplies nodes, monitoring areas, and collision pairs.",
		"evidence": "resources=%.0f gatherables=%.0f ground=%.0f chunks=%.0f"
			% [
				resources,
				float(steady.get("gatherables", 0.0)),
				float(steady.get("ground_items", 0.0)),
				float(steady.get("chunks_loaded", 0.0)),
			],
		"action": "Try WorldGenConfig resource_density_multiplier 2.5→1.5 and single_player_initial_load_radius 2→1; re-profile.",
	}

	scores[FIX_BOOT_CHUNKS] = {
		"score": _score_sum([
			[boot_chunk_count >= 15, 30],
			[boot_frame >= 40.0, 20],
			[float(boot.get("chunk_loads", 0.0)) >= 5.0, 20],
		]),
		"title": "Stagger boot chunk loading",
		"why": "Loading many chunks at once causes startup hitches separate from steady-state FPS.",
		"evidence": "boot avg=%.1fms, chunk_load_events=%d, boot interval chunk_loads=%.1f"
			% [boot_frame, boot_chunk_count, float(boot.get("chunk_loads", 0.0))],
		"action": "Spread initial ensure_initial_load across more frames (chunks_load_per_frame already exists — verify first-load path uses it).",
	}

	scores[FIX_RESOURCE_PROCESS] = {
		"score": _score_sum([
			[gather_ticks >= 500, 40],
			[res_proc >= 50, 35],
		]),
		"title": "Resource _process sleep (gatherables / ground piles)",
		"why": "Per-resource Input polling scales with tree/bush count.",
		"evidence": "gatherable_ticks/sec=%.0f resources_with_process=%.0f"
			% [gather_ticks, res_proc],
		"action": "Already implemented — re-profile after changes; score high only if ticks remain.",
	}

	scores[FIX_PERCEPTION_SCRIPTS] = {
		"score": _score_sum([
			[perception_ticks >= npcs * 0.8, 20],
			[process_share >= 0.08, 15],
			[float(steady.get("perception_areas_processing", 0.0)) >= 40, 15],
		]),
		"title": "Reduce PerceptionArea script overhead",
		"why": "Perception _process is lighter than physics but still scales with NPC count.",
		"evidence": "perception_process_ticks/sec=%.0f perception_areas=%.0f"
			% [perception_ticks, float(steady.get("perception_areas_monitoring", 0.0))],
		"action": "Sleep perception _process when parent NPC sleeps; keep monitoring event-driven where possible.",
	}

	return scores


func _score_sum(rules: Array) -> int:
	var total := 0
	for rule in rules:
		if bool(rule[0]):
			total += int(rule[1])
	return mini(total, 100)


func _print_steady_summary(steady: Dictionary, boot: Dictionary) -> void:
	var fps: float = 1000.0 / maxf(float(steady.get("frame_ms_avg", 16.67)), 0.01)
	var boot_fps: float = 1000.0 / maxf(float(boot.get("frame_ms_avg", 16.67)), 0.01)
	print("Steady state (t>=3s, no chunk loads in interval):")
	print(
		"  FPS ~%.1f  (avg frame %.1fms, max %.1fms)"
		% [fps, float(steady.get("frame_ms_avg", 0.0)), float(steady.get("frame_ms_max", 0.0))]
	)
	print(
		"  Engine: physics %.1fms  process %.1fms  (%.0f%% / %.0f%% of frame)"
		% [
			float(steady.get("engine_physics_ms", 0.0)),
			float(steady.get("engine_process_ms", 0.0)),
			float(steady.get("engine_physics_ms", 0.0)) / maxf(float(steady.get("frame_ms_avg", 1.0)), 1.0) * 100.0,
			float(steady.get("engine_process_ms", 0.0)) / maxf(float(steady.get("frame_ms_avg", 1.0)), 1.0) * 100.0,
		]
	)
	print("Boot window (first ~3s or chunk-load intervals): FPS ~%.1f" % boot_fps)


func _print_bottleneck_breakdown(steady: Dictionary) -> void:
	print(
		"World: resources=%.0f (gatherables=%.0f ground=%.0f) areas_monitoring=%.0f collision_pairs=%.0f"
		% [
			float(steady.get("resources", 0.0)),
			float(steady.get("gatherables", 0.0)),
			float(steady.get("ground_items", 0.0)),
			float(steady.get("areas_monitoring", 0.0)),
			float(steady.get("physics_2d_collision_pairs", 0.0)),
		]
	)
	var physics_hz: float = 60.0
	var npc_phys_per_sec: float = float(steady.get("npc_physics_ticks", 0.0))
	var npcs_total: float = float(steady.get("npcs", 0.0))
	print(
		"NPCs: total=%.0f physics_active=%.0f phys_ticks/sec=%.0f (expect ~%.0f @60Hz) | near=%.0f mid=%.0f far=%.0f very_far=%.0f"
		% [
			npcs_total,
			float(steady.get("npcs_physics_process", 0.0)),
			npc_phys_per_sec,
			npcs_total * 60.0,
			float(steady.get("npcs_near_800", 0.0)),
			float(steady.get("npcs_mid_800_to_half", 0.0)),
			float(steady.get("npcs_far_half_to_quarter", 0.0)),
			float(steady.get("npcs_very_far", 0.0)),
		]
	)
	print(
		"Hot paths: gatherable_ticks=%.0f npc_phys_ticks=%.0f fsm_ticks=%.0f perception_ticks=%.0f herd_phys=%.0f"
		% [
			float(steady.get("gatherable_process_calls", 0.0)),
			float(steady.get("npc_physics_ticks", 0.0)),
			float(steady.get("npc_fsm_ticks", 0.0)),
			float(steady.get("perception_process_ticks", 0.0)),
			float(steady.get("herd_influence_physics_ticks", 0.0)),
		]
	)


func _print_interval_row(rank: int, r: Dictionary) -> void:
	print(
		"  #%d t=%.1fs avg=%.1fms max=%.1fms phys=%.1fms proc=%.1fms npcs=%s areas_mon=%s pairs=%s"
		% [
			rank,
			float(r.get("t", 0.0)),
			float(r.get("frame_ms_avg", 0.0)),
			float(r.get("frame_ms_max", 0.0)),
			float(r.get("engine_physics_ms", 0.0)),
			float(r.get("engine_process_ms", 0.0)),
			str(r.get("npcs", "?")),
			str(r.get("areas_monitoring", "?")),
			str(r.get("physics_2d_collision_pairs", "?")),
		]
	)


func _resolve_path() -> String:
	var user_args := OS.get_cmdline_user_args()
	for i in range(user_args.size()):
		if user_args[i] == "--" and i + 1 < user_args.size():
			return user_args[i + 1]
		if user_args[i].ends_with(".jsonl"):
			return user_args[i]
	var user_dir := OS.get_user_data_dir()
	var best_path := ""
	var best_mtime := 0
	var dir := DirAccess.open(user_dir)
	if dir:
		dir.list_dir_begin()
		var fn := dir.get_next()
		while fn != "":
			if fn.begins_with(DEFAULT_GLOB) and fn.ends_with(".jsonl"):
				var full := user_dir.path_join(fn)
				var mtime: int = FileAccess.get_modified_time(full)
				if mtime >= best_mtime:
					best_mtime = mtime
					best_path = full
			fn = dir.get_next()
		dir.list_dir_end()
	return best_path
