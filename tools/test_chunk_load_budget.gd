extends SceneTree

## Count cap + time budget stop `_process_pending_loads(false)` early.


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	await process_frame
	var src := FileAccess.get_file_as_string("res://scripts/world/chunk_manager.gd")
	var cfg := FileAccess.get_file_as_string("res://scripts/config/world_gen_config.gd")
	if not cfg.contains("chunk_load_time_budget_ms"):
		push_error("TEST_CHUNK_LOAD_BUDGET: missing WorldGenConfig.chunk_load_time_budget_ms")
		quit(1)
		return
	if not src.contains("time_budget_ms"):
		push_error("TEST_CHUNK_LOAD_BUDGET: chunk_manager missing time budget")
		quit(1)
		return
	if not src.contains("elapsed_ms >= time_budget_ms"):
		push_error("TEST_CHUNK_LOAD_BUDGET: missing early stop")
		quit(1)
		return
	var loaded := _simulate_pending(20, 6, 8000.0, 0.2)
	if loaded > 6:
		push_error("TEST_CHUNK_LOAD_BUDGET: count cap failed loaded=%d" % loaded)
		quit(1)
		return
	var timed := _simulate_pending(20, 6, 0.0, 1.0)
	if timed > 1:
		push_error("TEST_CHUNK_LOAD_BUDGET: time budget should stop after first load, got %d" % timed)
		quit(1)
		return
	print("TEST_CHUNK_LOAD_BUDGET: ok count=%d time_stop=%d" % [loaded, timed])
	quit(0)


func _simulate_pending(pending_n: int, per_frame: int, time_budget_ms: float, fake_ms_per_load: float) -> int:
	var pending: int = pending_n
	var budget: int = per_frame
	var loaded: int = 0
	var elapsed: float = 0.0
	while budget > 0 and pending > 0:
		pending -= 1
		loaded += 1
		budget -= 1
		elapsed += fake_ms_per_load
		if elapsed >= time_budget_ms:
			break
	return loaded
