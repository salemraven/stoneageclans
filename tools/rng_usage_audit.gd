extends SceneTree
## Fails if bare randf/randi/randi_range appear outside the VisualRng allowlist.

const ALLOWLIST: Array[String] = [
	"res://scripts/network/sim_rng.gd",
	"res://scripts/world/chunk_rng.gd",
	"res://scripts/tools/",
	"res://scripts/ground_item.gd",
	"res://scripts/buildings/building_base.gd",
]

const PATTERN := "\\b(randf|randi|randi_range|randf_range)\\s*\\("

var _pattern_re: RegEx


func _init() -> void:
	call_deferred("_run")


func _is_allowlisted(path: String) -> bool:
	for prefix in ALLOWLIST:
		if path.begins_with(prefix):
			return true
	return false


func _run() -> void:
	await process_frame
	_pattern_re = RegEx.new()
	_pattern_re.compile(PATTERN)
	var violations: Array[String] = []
	_scan_dir("res://scripts", violations)
	if violations.is_empty():
		print("RNG_USAGE_AUDIT: OK (no bare rand in gameplay scripts)")
		quit(0)
	else:
		for v in violations:
			print("RNG_VIOLATION: ", v)
		print("RNG_USAGE_AUDIT: FAIL (%d violations)" % violations.size())
		quit(1)


func _scan_dir(dir_path: String, violations: Array[String]) -> void:
	var dir := DirAccess.open(dir_path)
	if dir == null:
		return
	dir.list_dir_begin()
	while true:
		var entry := dir.get_next()
		if entry.is_empty():
			break
		if entry.begins_with("."):
			continue
		var full := dir_path.path_join(entry)
		if dir.current_is_dir():
			_scan_dir(full, violations)
			continue
		if not entry.ends_with(".gd"):
			continue
		if _is_allowlisted(full):
			continue
		_scan_file(full, violations)
	dir.list_dir_end()


func _scan_file(path: String, violations: Array[String]) -> void:
	var f := FileAccess.open(path, FileAccess.READ)
	if f == null:
		return
	var line_no := 0
	while not f.eof_reached():
		line_no += 1
		var line := f.get_line()
		var from := 0
		while true:
			var m: RegExMatch = _pattern_re.search(line, from)
			if m == null:
				break
			var start: int = m.get_start()
			if start <= 0 or line[start - 1] != ".":
				violations.append("%s:%d: %s" % [path, line_no, line.strip_edges()])
				break
			from = m.get_end()
	f.close()
