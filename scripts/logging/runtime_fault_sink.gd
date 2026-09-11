extends Node
## Last autoload: boot audits for global classes / critical resources, exit marker, optional crash hook.
## Disable: env SKIP_RUNTIME_FAULT_SINK=1
## Extra stderr: --runtime-boot-audit (also audits a few ResourceLoader paths)
## Logs: user://runtime_boot_audit.log (overwrite each boot + append on tree exit)
## Exit trace lines prefixed GAME_EXIT for: grep GAME_EXIT Tests/logs/game_exit_*.log

const AUDIT_FILE := "user://runtime_boot_audit.log"
const EXIT_PREFIX := "GAME_EXIT"

var _verbose_audit: bool = false
var _boot_msec: int = 0
static var quit_reason: String = "unknown"
static var quit_detail: String = ""


static func mark_quit(reason: String, detail: String = "") -> void:
	quit_reason = reason if not reason.is_empty() else "unspecified"
	quit_detail = detail
	var line := "%s mark reason=%s detail=%s ticks=%s" % [
		EXIT_PREFIX, quit_reason, quit_detail, Time.get_ticks_msec()
	]
	print(line)
	var sink: Node = Engine.get_main_loop().root.get_node_or_null("RuntimeFaultSink") if Engine.get_main_loop() else null
	if sink:
		sink._append_exit_line(line)


func _ready() -> void:
	if OS.get_environment("SKIP_RUNTIME_FAULT_SINK") == "1":
		return
	_boot_msec = Time.get_ticks_msec()
	for a in OS.get_cmdline_user_args():
		if str(a) == "--runtime-boot-audit":
			_verbose_audit = true
			break
	call_deferred("_deferred_boot_audit")


func _exit_tree() -> void:
	var uptime_sec: float = (Time.get_ticks_msec() - _boot_msec) / 1000.0
	var line := (
		"%s exit_tree reason=%s detail=%s uptime_sec=%.2f ticks=%s frames=%s"
		% [
			EXIT_PREFIX,
			quit_reason,
			quit_detail,
			uptime_sec,
			Time.get_ticks_msec(),
			Engine.get_frames_drawn(),
		]
	)
	print(line)
	_append_exit_line(line)


func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		if quit_reason == "unknown":
			mark_quit("window_close_request", "RuntimeFaultSink_notification")
	# Engine may send this on fatal faults in some builds; harmless if never received.
	if what == 1015:
		mark_quit("notification_1015", "possible_engine_crash_hook")
		_append_exit_line("%s notification_1015 t=%s" % [EXIT_PREFIX, Time.get_ticks_msec()])


func _deferred_boot_audit() -> void:
	var lines: PackedStringArray = []
	lines.append("=== boot audit %s ===" % Time.get_datetime_string_from_system())
	# GDScript class_name types are not always visible to ClassDB.class_exists at runtime; load scripts instead.
	var script_audits: Array = [
		["PartyCommandUtils", "res://scripts/systems/party_command_utils.gd"],
		["FormationUtils", "res://scripts/systems/formation_utils.gd"],
		["FSM", "res://scripts/npc/fsm.gd"],
		["WorldMapEditor", "res://scripts/world_map_editor.gd"],
		["TerrainQuery", "res://scripts/world/terrain_query.gd"],
	]
	for row in script_audits:
		var cname: String = row[0]
		var path: String = row[1]
		var scr: Resource = load(path)
		var ok: bool = scr != null
		lines.append("script %s (%s): %s" % [cname, path, "ok" if ok else "MISSING"])
		if not ok:
			push_error("RuntimeFaultSink: failed to load %s" % path)
	var er_node: Node = get_node_or_null("/root/EntityRegistry")
	lines.append("autoload EntityRegistry: %s" % ("ok" if er_node != null else "MISSING"))
	if er_node == null:
		push_error("RuntimeFaultSink: EntityRegistry autoload missing")
	var main_ps: Resource = load("res://scenes/Main.tscn")
	lines.append("load Main.tscn: %s" % ("ok" if main_ps != null else "FAILED"))
	if main_ps == null:
		push_error("RuntimeFaultSink: res://scenes/Main.tscn failed to load")
	var map_ps: Resource = load("res://scenes/WorldMapEditor.tscn")
	lines.append("load WorldMapEditor.tscn: %s" % ("ok" if map_ps != null else "FAILED"))
	if map_ps == null:
		push_error("RuntimeFaultSink: res://scenes/WorldMapEditor.tscn failed to load")
	var shader_res: Resource = load("res://assets/shaders/biome_ground.gdshader")
	lines.append("load biome_ground.gdshader: %s" % ("ok" if shader_res != null else "FAILED"))
	if _verbose_audit:
		lines.append("--- verbose resource probe ---")
		var paths: Array[String] = [
			"res://scripts/npc/fsm.gd",
			"res://scripts/main.gd",
			"res://scripts/player.gd",
			"res://scenes/Player.tscn",
		]
		for p in paths:
			var r: Resource = load(p)
			lines.append("load %s: %s" % [p, "ok" if r != null else "FAILED"])
			if r == null:
				push_error("RuntimeFaultSink: failed load %s" % p)
	_write_audit(AUDIT_FILE, lines)
	for i in range(lines.size()):
		print("[RuntimeFaultSink] %s" % lines[i])


func _append_exit_line(line: String) -> void:
	_append_line(AUDIT_FILE, line)
	_mirror_exit_line_to_repo_log(line)


func _mirror_exit_line_to_repo_log(line: String) -> void:
	var repo_log := "res://Tests/logs/game_exit_latest.log"
	var abs_path: String = ProjectSettings.globalize_path(repo_log)
	if abs_path.is_empty():
		return
	var f: FileAccess = FileAccess.open(abs_path, FileAccess.READ_WRITE)
	if f == null:
		f = FileAccess.open(abs_path, FileAccess.WRITE)
	if f == null:
		return
	if f.get_length() > 0:
		f.seek_end()
	else:
		f.store_string("=== game exit trace (append per run) ===\n")
	f.store_string(line + "\n")
	f.flush()
	f.close()


func _write_audit(path: String, lines: PackedStringArray) -> void:
	var f: FileAccess = FileAccess.open(path, FileAccess.WRITE)
	if f == null:
		push_error("RuntimeFaultSink: cannot open %s for write" % path)
		return
	for line in lines:
		f.store_string(line + "\n")
	f.flush()
	f.close()


func _append_line(path: String, line: String) -> void:
	var f: FileAccess = FileAccess.open(path, FileAccess.READ_WRITE)
	if f == null:
		f = FileAccess.open(path, FileAccess.WRITE)
	if f == null:
		return
	f.seek_end()
	f.store_string(line + "\n")
	f.flush()
	f.close()
