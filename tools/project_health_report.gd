extends SceneTree
## Godot runtime health report — script compile, scene load, critical boots.
##
## Run:
##   SKIP_SINGLE_INSTANCE=1 godot --headless --path . -s res://tools/project_health_report.gd
##
## Writes: Tests/logs/project_health_godot_<timestamp>.json
## Also prints human-readable summary to stdout.

const LOG_DIR := "res://Tests/logs/"
const CRITICAL_SCENES: Array[String] = [
	"res://scenes/Main.tscn",
	"res://scenes/WorldMapEditor.tscn",
	"res://scenes/Player.tscn",
	"res://scenes/NPC.tscn",
]
const CRITICAL_SCRIPTS: Array[String] = [
	"res://scripts/main.gd",
	"res://scripts/world_map_editor.gd",
	"res://scripts/world/terrain_query.gd",
	"res://assets/shaders/biome_ground.gdshader",
]

var _findings: Array[Dictionary] = []
var _stamp: String = ""


func _init() -> void:
	_stamp = Time.get_datetime_string_from_system().replace(":", "").replace(" ", "_")
	call_deferred("_run")


func _run() -> void:
	print("=== project_health_report (Godot) start ===")
	await process_frame
	_check_critical_scripts()
	_check_critical_scenes()
	await _boot_scene_smoke("res://scenes/WorldMapEditor.tscn", 20)
	await _boot_scene_smoke("res://scenes/Main.tscn", 12)
	_scan_directory_scripts("res://scripts")
	_scan_directory_scripts("res://tools")
	_write_report()
	_print_summary()
	quit(0 if _error_count() == 0 else 1)


func _add(severity: String, category: String, path: String, message: String, fix_hint: String = "") -> void:
	_findings.append({
		"severity": severity,
		"category": category,
		"path": path,
		"message": message,
		"fix_hint": fix_hint,
	})


func _error_count() -> int:
	var n := 0
	for f in _findings:
		if f.get("severity") == "error":
			n += 1
	return n


func _check_critical_scripts() -> void:
	for path in CRITICAL_SCRIPTS:
		var res: Resource = load(path)
		if res == null:
			var hint := "Fix parse error or restore missing file — read Godot stderr above for line number"
			if path.ends_with(".gdshader"):
				hint = "Fix shader function order / syntax — run WorldMapEditor smoke"
			_add("error", "critical_script", path, "load() returned null", hint)
		else:
			_add("info", "critical_script", path, "ok")


func _check_critical_scenes() -> void:
	for path in CRITICAL_SCENES:
		var ps: PackedScene = load(path) as PackedScene
		if ps == null:
			_add(
				"error",
				"critical_scene",
				path,
				"PackedScene load failed — missing ext_resource or script error",
				"Run python3 tools/project_health_scan.py for missing PNG paths",
			)
		else:
			_add("info", "critical_scene", path, "ok")


func _boot_scene_smoke(scene_path: String, iterations: int) -> void:
	var ps: PackedScene = load(scene_path) as PackedScene
	if ps == null:
		_add("error", "scene_smoke", scene_path, "Skipped smoke — scene did not load")
		return
	var inst: Node = ps.instantiate()
	root.add_child(inst)
	for _i in range(iterations):
		await process_frame
	# Capture shader/material issues logged during _ready
	_add("info", "scene_smoke", scene_path, "instantiated %d frames" % iterations)
	inst.queue_free()
	await process_frame


func _scan_directory_scripts(dir_path: String) -> void:
	var stack: Array[String] = [dir_path]
	while not stack.is_empty():
		var current: String = stack.pop_back()
		var dir := DirAccess.open(current)
		if dir == null:
			continue
		dir.list_dir_begin()
		var entry_name := dir.get_next()
		while entry_name != "":
			if entry_name.begins_with("."):
				entry_name = dir.get_next()
				continue
			var full := current.path_join(entry_name)
			if dir.current_is_dir():
				stack.append(full)
			elif entry_name.ends_with(".gd") and not entry_name.ends_with(".gd.uid"):
				_probe_script(full)
			entry_name = dir.get_next()
		dir.list_dir_end()


func _probe_script(path: String) -> void:
	# Skip self
	if path.ends_with("project_health_report.gd"):
		return
	var scr: Resource = load(path)
	if scr == null:
		_add(
			"error",
			"script_parse",
			path,
			"GDScript failed to compile",
			"Fix parse/type errors — common: untyped := when type cannot be inferred",
		)


func _write_report() -> void:
	var summary := {"error": 0, "warning": 0, "info": 0}
	for f in _findings:
		var sev: String = f.get("severity", "info")
		summary[sev] = int(summary.get(sev, 0)) + 1
	var payload := {
		"tool": "project_health_report.gd",
		"timestamp": _stamp,
		"summary": summary,
		"findings": _findings,
	}
	var json_text := JSON.stringify(payload, "\t")
	var out_path := "%sproject_health_godot_%s.json" % [LOG_DIR, _stamp]
	var f := FileAccess.open(out_path, FileAccess.WRITE)
	if f:
		f.store_string(json_text)
		f.close()
		print("Wrote %s" % out_path)
	else:
		push_error("Could not write %s" % out_path)


func _print_summary() -> void:
	var err := _error_count()
	print("")
	print("=== project_health_report summary ===")
	print("errors=%d total_findings=%d" % [err, _findings.size()])
	if err > 0:
		print("\n--- ERRORS ---")
		for f in _findings:
			if f.get("severity") != "error":
				continue
			print("[%s] %s" % [f.get("category"), f.get("path")])
			print("  %s" % f.get("message"))
			if f.get("fix_hint"):
				print("  fix: %s" % f.get("fix_hint"))
	print("=== project_health_report %s ===" % ("FAIL" if err > 0 else "OK"))
