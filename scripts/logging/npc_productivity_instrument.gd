extends Node
## Periodic SESSION snapshots for worker productivity (clansmen/cavemen): task jobs, FSM state histogram, per clan.
## Enable with playtest capture (--playtest-capture) or --session-instrument.

var _elapsed: float = 0.0
var _prune_elapsed: float = 0.0

func _process(delta: float) -> void:
	var dc: Node = get_node_or_null("/root/DebugConfig")
	if dc == null:
		return
	# Long session: cap MovementDebugInstrument instance-id map (same as movement samples enabled).
	if dc.get("enable_movement_debug") or dc.get("enable_session_instrumentation"):
		_prune_elapsed += delta
		if _prune_elapsed >= 120.0:
			_prune_elapsed = 0.0
			MovementDebugInstrument.prune_sample_time_cache_if_huge()
	var snapshots_on: bool = bool(dc.get("enable_npc_productivity_snapshots"))
	if not snapshots_on and not dc.get("enable_session_instrumentation"):
		return
	if not snapshots_on:
		return
	var interval: float = float(dc.get("npc_productivity_snapshot_interval_sec")) if dc.get("npc_productivity_snapshot_interval_sec") != null else 30.0
	if interval < 5.0:
		interval = 5.0
	_elapsed += delta
	if _elapsed < interval:
		return
	_elapsed = 0.0
	_emit_snapshot()

func _emit_snapshot() -> void:
	var tree: SceneTree = get_tree()
	if tree == null:
		return
	var npcs: Array = tree.get_nodes_in_group("npcs")
	var by_clan: Dictionary = {}
	var global_workers: Dictionary = {
		"worker_total": 0,
		"with_task_job": 0,
		"idle_worker_no_job": 0,
		"clansman_total": 0,
		"clansman_with_job": 0,
	}
	var state_hist: Dictionary = {}
	var clansman_state_hist: Dictionary = {}
	for n in npcs:
		if not is_instance_valid(n):
			continue
		if n.has_method("is_dead") and n.is_dead():
			continue
		var nt: String = str(n.get("npc_type")) if n.get("npc_type") != null else ""
		if nt != "clansman" and nt != "caveman":
			continue
		global_workers["worker_total"] = int(global_workers["worker_total"]) + 1
		if nt == "clansman":
			global_workers["clansman_total"] = int(global_workers["clansman_total"]) + 1
		var clan: String = ""
		if n.has_method("get_clan_name"):
			clan = n.get_clan_name()
		if clan.is_empty() and n.get("clan_name") != null:
			clan = str(n.get("clan_name"))
		if clan.is_empty():
			clan = "_none"
		if not by_clan.has(clan):
			by_clan[clan] = {"workers": 0, "clansmen": 0, "with_task_job": 0, "clansmen_with_job": 0, "states": {}}
		var row: Dictionary = by_clan[clan]
		row["workers"] = int(row["workers"]) + 1
		if nt == "clansman":
			row["clansmen"] = int(row.get("clansmen", 0)) + 1
		var task_runner = n.get("task_runner")
		var has_job: bool = task_runner and task_runner.has_method("has_job") and task_runner.has_job()
		if has_job:
			row["with_task_job"] = int(row["with_task_job"]) + 1
			global_workers["with_task_job"] = int(global_workers["with_task_job"]) + 1
			if nt == "clansman":
				row["clansmen_with_job"] = int(row.get("clansmen_with_job", 0)) + 1
				global_workers["clansman_with_job"] = int(global_workers["clansman_with_job"]) + 1
		else:
			global_workers["idle_worker_no_job"] = int(global_workers["idle_worker_no_job"]) + 1
		var stname: String = ""
		if n.get("fsm") and n.fsm and n.fsm.has_method("get_current_state_name"):
			stname = str(n.fsm.get_current_state_name())
		if stname.is_empty():
			stname = "?"
		var states: Dictionary = row["states"]
		if not states.has(stname):
			states[stname] = 0
		states[stname] = int(states[stname]) + 1
		if not state_hist.has(stname):
			state_hist[stname] = 0
		state_hist[stname] = int(state_hist[stname]) + 1
		if nt == "clansman":
			if not clansman_state_hist.has(stname):
				clansman_state_hist[stname] = 0
			clansman_state_hist[stname] = int(clansman_state_hist[stname]) + 1
	var productivity_pct: float = 0.0
	var wt: int = int(global_workers["worker_total"])
	if wt > 0:
		productivity_pct = 100.0 * float(global_workers["with_task_job"]) / float(wt)
	UnifiedLogger.log_session("NPC_PRODUCTIVITY_SNAPSHOT", {
		"worker_total": str(wt),
		"with_task_job": str(global_workers["with_task_job"]),
		"idle_worker_no_job": str(global_workers["idle_worker_no_job"]),
		"clansman_total": str(global_workers["clansman_total"]),
		"clansman_with_job": str(global_workers["clansman_with_job"]),
		"pct_workers_with_job": "%.1f" % productivity_pct,
		"fsm_states": str(state_hist),
		"clansman_fsm_states": str(clansman_state_hist),
		"by_clan": str(by_clan),
	}, UnifiedLogger.Level.INFO)
	var pi = get_node_or_null("/root/PlaytestInstrumentor")
	if pi and pi.is_enabled() and pi.has_method("npc_productivity_snapshot"):
		pi.npc_productivity_snapshot(
			wt,
			int(global_workers["with_task_job"]),
			int(global_workers["idle_worker_no_job"]),
			productivity_pct,
			int(global_workers["clansman_total"]),
			int(global_workers["clansman_with_job"]),
			state_hist,
			clansman_state_hist,
			by_clan
		)
