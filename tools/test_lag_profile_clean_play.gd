extends SceneTree

## After boot (t>=5, no chunk_loads): avg frame < 16.7ms.
## Fail only if every post-boot second is over 20ms.

const DEFAULT_GLOB := "lag_profile_"


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var path := _resolve_path()
	if path.is_empty():
		push_error("TEST_LAG_PROFILE_CLEAN: no lag_profile JSONL under user://")
		quit(1)
		return
	var lines: PackedStringArray = FileAccess.get_file_as_string(path).split("\n", false)
	var intervals: Array[Dictionary] = []
	for line in lines:
		if line.strip_edges().is_empty():
			continue
		var parsed: Variant = JSON.parse_string(line)
		if typeof(parsed) != TYPE_DICTIONARY:
			continue
		var row: Dictionary = parsed as Dictionary
		if str(row.get("evt", "")) == "interval":
			intervals.append(row)
	if intervals.is_empty():
		push_error("TEST_LAG_PROFILE_CLEAN: no intervals in %s" % path)
		quit(1)
		return
	var post: Array[Dictionary] = []
	for row in intervals:
		if float(row.get("t", 0.0)) < 5.0:
			continue
		if int(row.get("chunk_loads", 0)) > 0:
			continue
		post.append(row)
	if post.is_empty():
		push_error("TEST_LAG_PROFILE_CLEAN: no post-boot intervals (t>=5, no chunk_loads)")
		quit(1)
		return
	var sum_ms: float = 0.0
	var all_over_20: bool = true
	for row in post:
		var avg: float = float(row.get("frame_ms_avg", 99.0))
		sum_ms += avg
		if avg <= 20.0:
			all_over_20 = false
	var mean: float = sum_ms / float(post.size())
	print("TEST_LAG_PROFILE_CLEAN: file=%s post=%d mean_ms=%.2f" % [path, post.size(), mean])
	if all_over_20:
		push_error("TEST_LAG_PROFILE_CLEAN: every post-boot second > 20ms")
		quit(1)
		return
	if mean >= 16.7:
		push_error("TEST_LAG_PROFILE_CLEAN: post-boot avg frame %.2fms (want < 16.7)" % mean)
		quit(1)
		return
	print("TEST_LAG_PROFILE_CLEAN: ok")
	quit(0)


func _resolve_path() -> String:
	var user_dir := DirAccess.open("user://")
	if user_dir == null:
		return ""
	var latest := ""
	var latest_mtime := 0
	user_dir.list_dir_begin()
	var fname := user_dir.get_next()
	while fname != "":
		if not user_dir.current_is_dir() and fname.begins_with(DEFAULT_GLOB) and fname.ends_with(".jsonl"):
			var full := "user://%s" % fname
			var mtime := FileAccess.get_modified_time(full)
			if mtime >= latest_mtime:
				latest_mtime = mtime
				latest = full
		fname = user_dir.get_next()
	user_dir.list_dir_end()
	return latest
