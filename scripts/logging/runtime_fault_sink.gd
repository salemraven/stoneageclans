extends Node
## Last autoload: boot audits for global classes / critical resources, exit marker, optional crash hook.
## Disable: env SKIP_RUNTIME_FAULT_SINK=1
## Extra stderr: --runtime-boot-audit (also audits a few ResourceLoader paths)
## Logs: user://runtime_boot_audit.log (overwrite each boot + append on tree exit)

const AUDIT_FILE := "user://runtime_boot_audit.log"

var _verbose_audit: bool = false


func _ready() -> void:
	if OS.get_environment("SKIP_RUNTIME_FAULT_SINK") == "1":
		return
	for a in OS.get_cmdline_user_args():
		if str(a) == "--runtime-boot-audit":
			_verbose_audit = true
			break
	call_deferred("_deferred_boot_audit")


func _exit_tree() -> void:
	_append_line(
		AUDIT_FILE,
		"runtime_fault_sink_exit ticks=%s frames=%s" % [Time.get_ticks_msec(), Engine.get_frames_drawn()]
	)


func _notification(what: int) -> void:
	# Engine may send this on fatal faults in some builds; harmless if never received.
	if what == 1015:
		_append_line(AUDIT_FILE, "notification_1015 (possible crash hook) t=%s" % Time.get_ticks_msec())


func _deferred_boot_audit() -> void:
	var lines: PackedStringArray = []
	lines.append("=== boot audit %s ===" % Time.get_datetime_string_from_system())
	# GDScript class_name types are not always visible to ClassDB.class_exists at runtime; load scripts instead.
	var script_audits: Array = [
		["PartyCommandUtils", "res://scripts/systems/party_command_utils.gd"],
		["FormationUtils", "res://scripts/systems/formation_utils.gd"],
		["FSM", "res://scripts/npc/fsm.gd"],
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
