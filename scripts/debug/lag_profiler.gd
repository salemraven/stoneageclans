extends Node

## Frame + world-composition profiler → user://lag_profile_*.jsonl
## Enable: `--lag-profile` (optional `--session-quit-after N` for timed capture).

var _enabled: bool = false
var _file: FileAccess
var _file_path: String = ""
var _t0_sec: float = 0.0
var _interval_sec: float = 1.0
var _spike_ms: float = 20.0
var _interval_accum: float = 0.0

var _frame_count: int = 0
var _frame_ms_sum: float = 0.0
var _frame_ms_max: float = 0.0
var _spike_count: int = 0

var _gatherable_process_calls: int = 0
var _arm_process_calls: int = 0
var _npc_physics_ticks: int = 0
var _npc_fsm_ticks: int = 0
var _perception_process_ticks: int = 0
var _herd_influence_physics_ticks: int = 0
var _chunk_loads: int = 0
var _chunk_unloads: int = 0
var _chunk_load_usec_total: int = 0
var _chunk_load_usec_max: int = 0
var _memory_rows: Array[Dictionary] = []
const _MEMORY_ROW_CAP := 60


func _ready() -> void:
	call_deferred("_boot")


func _boot() -> void:
	var dc: Node = get_node_or_null("/root/DebugConfig")
	if dc and dc.get("enable_lag_profiling") == true:
		_enabled = true
		if dc.get("lag_profile_interval_sec") != null:
			_interval_sec = maxf(0.25, float(dc.lag_profile_interval_sec))
		if dc.get("lag_profile_spike_ms") != null:
			_spike_ms = maxf(5.0, float(dc.lag_profile_spike_ms))
	if _enabled:
		_open_log()


func is_enabled() -> bool:
	return _enabled


func get_summary_dict() -> Dictionary:
	if _memory_rows.is_empty():
		return {}
	var rows := _memory_rows.duplicate()
	var steady: Array[Dictionary] = []
	for row in rows:
		if str(row.get("evt", "")) == "interval" and float(row.get("t", 0.0)) >= 3.0:
			steady.append(row)
	if steady.is_empty():
		for row in rows:
			if str(row.get("evt", "")) == "interval":
				steady.append(row)
	if steady.is_empty():
		return {}
	var n := steady.size()
	var avg_frame := 0.0
	var areas := 0.0
	var pairs := 0.0
	for row in steady:
		avg_frame += float(row.get("frame_ms_avg", 0.0))
		areas += float(row.get("areas_monitoring", 0.0))
		pairs += float(row.get("physics_2d_collision_pairs", 0.0))
	avg_frame /= float(n)
	areas /= float(n)
	pairs /= float(n)
	return {
		"interval_count": n,
		"fps": snappedf(1000.0 / maxf(avg_frame, 0.001), 0.1),
		"frame_ms_avg": snappedf(avg_frame, 0.1),
		"areas_monitoring": snappedf(areas, 0.0),
		"collision_pairs": snappedf(pairs, 0.0),
	}


func record_gatherable_process() -> void:
	if _enabled:
		_gatherable_process_calls += 1


func record_arm_process() -> void:
	if _enabled:
		_arm_process_calls += 1


func record_npc_physics_process() -> void:
	if _enabled:
		_npc_physics_ticks += 1


func record_npc_fsm_update() -> void:
	if _enabled:
		_npc_fsm_ticks += 1


func record_perception_process() -> void:
	if _enabled:
		_perception_process_ticks += 1


func record_herd_influence_physics() -> void:
	if _enabled:
		_herd_influence_physics_ticks += 1


func record_chunk_load(chunk: Vector2i, elapsed_usec: int) -> void:
	if not _enabled:
		return
	_chunk_loads += 1
	_chunk_load_usec_total += elapsed_usec
	_chunk_load_usec_max = maxi(_chunk_load_usec_max, elapsed_usec)
	trace_event("chunk_load", {
		"chunk_x": chunk.x,
		"chunk_y": chunk.y,
		"usec": elapsed_usec,
	})


func record_chunk_unload(chunk: Vector2i) -> void:
	if not _enabled:
		return
	_chunk_unloads += 1
	trace_event("chunk_unload", {"chunk_x": chunk.x, "chunk_y": chunk.y})


func trace_event(evt: String, data: Dictionary = {}) -> void:
	if not _enabled:
		return
	var row: Dictionary = {"evt": evt}
	for k in data:
		row[k] = data[k]
	_emit(row)


func _process(delta: float) -> void:
	if not _enabled:
		return
	var frame_ms: float = delta * 1000.0
	_frame_count += 1
	_frame_ms_sum += frame_ms
	_frame_ms_max = maxf(_frame_ms_max, frame_ms)
	if frame_ms >= _spike_ms:
		_spike_count += 1
		_emit_spike(frame_ms)
	_interval_accum += delta
	if _interval_accum >= _interval_sec:
		_emit_interval()
		_reset_interval()
		_interval_accum = 0.0


func _open_log() -> void:
	if OS.get_name() == "Web":
		_memory_rows.clear()
		_t0_sec = Time.get_ticks_msec() / 1000.0
		_emit({
			"evt": "lag_profile_start",
			"path": "memory",
			"interval_sec": _interval_sec,
			"spike_ms": _spike_ms,
			"profiler_version": 2,
			"platform": "Web",
		})
		print("✓ Lag profiler (Web in-memory)")
		return
	var now: Dictionary = Time.get_datetime_dict_from_system()
	_file_path = "user://lag_profile_%04d%02d%02d_%02d%02d%02d.jsonl" % [
		now.year, now.month, now.day, now.hour, now.minute, now.second
	]
	_file = FileAccess.open(_file_path, FileAccess.WRITE)
	_t0_sec = Time.get_ticks_msec() / 1000.0
	if _file:
		_emit({
			"evt": "lag_profile_start",
			"path": _file_path,
			"interval_sec": _interval_sec,
			"spike_ms": _spike_ms,
			"profiler_version": 2,
		})
		print("✓ Lag profiler → %s" % ProjectSettings.globalize_path(_file_path))


func _emit(obj: Dictionary) -> void:
	obj["t"] = (Time.get_ticks_msec() / 1000.0) - _t0_sec
	if _enabled:
		_memory_rows.append(obj.duplicate())
		if _memory_rows.size() > _MEMORY_ROW_CAP:
			_memory_rows.pop_front()
	if _file == null or not _file.is_open():
		return
	_file.store_string(JSON.stringify(obj) + "\n")
	_file.flush()


func _emit_spike(frame_ms: float) -> void:
	var tree := get_tree()
	if tree == null:
		return
	var snap := _world_snapshot(tree)
	snap["evt"] = "frame_spike"
	snap["frame_ms"] = snappedf(frame_ms, 0.01)
	snap["engine_process_ms"] = snappedf(_monitor_ms(Performance.TIME_PROCESS), 0.01)
	snap["engine_physics_ms"] = snappedf(_monitor_ms(Performance.TIME_PHYSICS_PROCESS), 0.01)
	snap["gatherable_process_calls_since_last_interval"] = _gatherable_process_calls
	snap["arm_process_calls_since_last_interval"] = _arm_process_calls
	snap["npc_physics_ticks_since_last_interval"] = _npc_physics_ticks
	_emit(snap)


func _emit_interval() -> void:
	var tree := get_tree()
	if tree == null:
		return
	var avg_ms: float = _frame_ms_sum / float(maxi(_frame_count, 1))
	var snap := _world_snapshot(tree)
	snap["evt"] = "interval"
	snap["frames"] = _frame_count
	snap["frame_ms_avg"] = snappedf(avg_ms, 0.01)
	snap["frame_ms_max"] = snappedf(_frame_ms_max, 0.01)
	snap["spike_count"] = _spike_count
	snap["engine_process_ms"] = snappedf(_monitor_ms(Performance.TIME_PROCESS), 0.01)
	snap["engine_physics_ms"] = snappedf(_monitor_ms(Performance.TIME_PHYSICS_PROCESS), 0.01)
	snap["engine_draw_calls"] = int(Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME))
	snap["physics_2d_active_objects"] = int(Performance.get_monitor(Performance.PHYSICS_2D_ACTIVE_OBJECTS))
	snap["physics_2d_collision_pairs"] = int(Performance.get_monitor(Performance.PHYSICS_2D_COLLISION_PAIRS))
	snap["physics_2d_islands"] = int(Performance.get_monitor(Performance.PHYSICS_2D_ISLAND_COUNT))
	snap["gatherable_process_calls"] = _gatherable_process_calls
	snap["arm_process_calls"] = _arm_process_calls
	snap["npc_physics_ticks"] = _npc_physics_ticks
	snap["npc_fsm_ticks"] = _npc_fsm_ticks
	snap["perception_process_ticks"] = _perception_process_ticks
	snap["herd_influence_physics_ticks"] = _herd_influence_physics_ticks
	snap["chunk_loads"] = _chunk_loads
	snap["chunk_unloads"] = _chunk_unloads
	snap["chunk_load_usec_avg"] = (
		int(_chunk_load_usec_total / _chunk_loads) if _chunk_loads > 0 else 0
	)
	snap["chunk_load_usec_max"] = _chunk_load_usec_max
	_emit(snap)
	if avg_ms > _spike_ms * 0.75:
		print(
			("⚠ Lag interval: avg %.1fms max %.1fms | physics=%.1fms process=%.1fms | "
			+ "npcs=%d (phys_ticks=%d) areas_mon=%d pairs=%d | gatherable_ticks=%d")
			% [
				avg_ms,
				_frame_ms_max,
				float(snap.get("engine_physics_ms", 0.0)),
				float(snap.get("engine_process_ms", 0.0)),
				snap.get("npcs", 0),
				_npc_physics_ticks,
				snap.get("areas_monitoring", 0),
				snap.get("physics_2d_collision_pairs", 0),
				_gatherable_process_calls,
			]
		)


func _world_snapshot(tree: SceneTree) -> Dictionary:
	var comp := _scan_world_composition(tree)
	var chunks_loaded := 0
	var cm: Node = get_node_or_null("/root/ChunkManager")
	if cm and cm.has_method("get_loaded_chunk_coords"):
		chunks_loaded = (cm.call("get_loaded_chunk_coords") as Array).size()
	var player: Node2D = tree.get_first_node_in_group("player") as Node2D
	var player_pos := Vector2.ZERO
	if player:
		player_pos = player.global_position
	comp["chunks_loaded"] = chunks_loaded
	comp["decorative_trees"] = tree.get_nodes_in_group("decorative_trees").size()
	comp["node_count"] = int(Performance.get_monitor(Performance.OBJECT_NODE_COUNT))
	comp["orphan_nodes"] = int(Performance.get_monitor(Performance.OBJECT_ORPHAN_NODE_COUNT))
	comp["player_x"] = snappedf(player_pos.x, 1.0)
	comp["player_y"] = snappedf(player_pos.y, 1.0)
	return comp


func _scan_world_composition(tree: SceneTree) -> Dictionary:
	var resources: Array = tree.get_nodes_in_group("resources")
	var resources_proc := 0
	var resources_monitoring := 0
	var gatherables := 0
	var ground_items := 0
	for node in resources:
		if node is GatherableResource:
			gatherables += 1
		elif node is GroundItem:
			ground_items += 1
		if node is Node:
			if (node as Node).is_processing():
				resources_proc += 1
		if node is Area2D and (node as Area2D).monitoring:
			resources_monitoring += 1

	var npcs: Array = tree.get_nodes_in_group("npcs")
	var npcs_physics := 0
	var npcs_dormant := 0
	var npcs_near := 0
	var npcs_mid := 0
	var npcs_far := 0
	var npcs_very_far := 0
	var perception_monitoring := 0
	var perception_processing := 0
	var herd_influence_physics := 0
	var half_dist: float = 1500.0
	var quarter_dist: float = 2500.0
	if NPCConfig:
		half_dist = float(NPCConfig.distance_threshold_half_rate)
		quarter_dist = float(NPCConfig.distance_threshold_quarter_rate)
	var player: Node2D = tree.get_first_node_in_group("player") as Node2D
	var player_pos := player.global_position if player else Vector2.ZERO

	for npc in npcs:
		if not (npc is Node):
			continue
		var n := npc as Node
		if n is CharacterBody2D:
			if (n as CharacterBody2D).is_physics_processing():
				npcs_physics += 1
			else:
				npcs_dormant += 1
		if player:
			var dist: float = (npc as Node2D).global_position.distance_to(player_pos)
			if dist <= 800.0:
				npcs_near += 1
			elif dist <= half_dist:
				npcs_mid += 1
			elif dist <= quarter_dist:
				npcs_far += 1
			else:
				npcs_very_far += 1
		for child in n.get_children():
			if child is PerceptionArea:
				var pa := child as PerceptionArea
				if pa.monitoring:
					perception_monitoring += 1
				if pa.is_processing():
					perception_processing += 1
			elif child is HerdInfluenceArea:
				if (child as Node).is_physics_processing():
					herd_influence_physics += 1

	var land_claims: Array = tree.get_nodes_in_group("land_claims")
	var claim_zones_monitoring := land_claims.size() * 2  # AoH + EnemiesInClaim per claim

	return {
		"resources": resources.size(),
		"resources_process_enabled": resources_proc,
		"resources_monitoring": resources_monitoring,
		"gatherables": gatherables,
		"ground_items": ground_items,
		"npcs": npcs.size(),
		"npcs_physics_process": npcs_physics,
		"npcs_sim_dormant": npcs_dormant,
		"npcs_near_800": npcs_near,
		"npcs_mid_800_to_half": npcs_mid,
		"npcs_far_half_to_quarter": npcs_far,
		"npcs_very_far": npcs_very_far,
		"perception_areas_monitoring": perception_monitoring,
		"perception_areas_processing": perception_processing,
		"herd_influence_physics": herd_influence_physics,
		"land_claims": land_claims.size(),
		"land_claim_zones_monitoring": claim_zones_monitoring,
		"areas_monitoring": resources_monitoring + perception_monitoring + claim_zones_monitoring,
	}


func _monitor_ms(monitor: int) -> float:
	return float(Performance.get_monitor(monitor)) * 1000.0


func _reset_interval() -> void:
	_frame_count = 0
	_frame_ms_sum = 0.0
	_frame_ms_max = 0.0
	_spike_count = 0
	_gatherable_process_calls = 0
	_arm_process_calls = 0
	_npc_physics_ticks = 0
	_npc_fsm_ticks = 0
	_perception_process_ticks = 0
	_herd_influence_physics_ticks = 0
	_chunk_loads = 0
	_chunk_unloads = 0
	_chunk_load_usec_total = 0
	_chunk_load_usec_max = 0


func _exit_tree() -> void:
	if not _enabled:
		return
	_emit({"evt": "lag_profile_end"})
	if _file and _file.is_open():
		_file.close()
		print("✓ Lag profiler closed: %s" % ProjectSettings.globalize_path(_file_path))
	elif OS.get_name() == "Web":
		var summary := get_summary_dict()
		print("✓ Lag profiler (Web) summary: %s" % JSON.stringify(summary))
		print("ANALYZE_LAG_PROFILE_OK")
