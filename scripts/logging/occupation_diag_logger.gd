extends Node

# Force ResourceData to load before this script uses it (autoload order)
const _ResourceData = preload("res://scripts/resource_data.gd")

# Occupation Diagnostic Logger - Captures building occupation flow for debugging
# Enable via: godot --path . --occupation-diag
# Logs to: Tests/occupation_diag_<timestamp>.log
# No throttling - every event is captured for the diagnostic run

var enabled: bool = false
var _log_file: FileAccess = null
var _log_path: String = ""
var _session_start: float = 0.0
var _snapshot_interval: float = 5.0  # seconds
var _last_snapshot_time: float = 0.0

func enable() -> void:
	if enabled:
		return
	enabled = true
	_session_start = Time.get_ticks_msec() / 1000.0
	var ts := Time.get_datetime_string_from_system().replace(":", "-").replace(" ", "_")
	var base := ProjectSettings.globalize_path("res://").get_base_dir()
	var tests_dir := base.path_join("Tests")
	DirAccess.make_dir_absolute(tests_dir)
	_log_path = tests_dir.path_join("occupation_diag_%s.log" % ts)
	_log_file = FileAccess.open(_log_path, FileAccess.WRITE)
	if _log_file:
		_log_file.store_line("=== Occupation Diagnostic Log Started ===")
		_log_file.store_line("Time: %s | Session start: %.2f" % [Time.get_datetime_string_from_system(), _session_start])
		_log_file.store_line("Instructions: Place land claim, Farm, Dairy; herd in sheep/goats/women.")
		_log_file.store_line("")
		_log_file.flush()
		print("✓ Occupation diagnostic logging enabled -> %s" % _log_path)
	else:
		push_warning("OccupationDiagLogger: Failed to open log file: %s" % _log_path)

func disable() -> void:
	enabled = false
	if _log_file:
		_log_file.store_line("")
		_log_file.store_line("=== Occupation Diagnostic Log Stopped ===")
		_log_file.flush()
		_log_file.close()
		_log_file = null
	print("Occupation diagnostic logging disabled. Log saved to: %s" % _log_path)

func _session_sec() -> float:
	return (Time.get_ticks_msec() / 1000.0) - _session_start

func _process(delta: float) -> void:
	if not enabled:
		return
	var now := Time.get_ticks_msec() / 1000.0
	if now - _last_snapshot_time >= _snapshot_interval:
		_last_snapshot_time = now
		_write_snapshot()

func _write_snapshot() -> void:
	"""Dump current OccupationSystem state + building occupants for consistency check."""
	if not enabled or not _log_file or not _log_file.is_open():
		return
	var tree := get_tree()
	if not tree:
		return
	var buildings := tree.get_nodes_in_group("buildings")
	var b_lines: Array[String] = []
	for b in buildings:
		if not is_instance_valid(b):
			continue
		if not b.has_method("get_occupant") and not ("woman_slots" in b):
			continue
		var clan: String = b.get("clan_name") if "clan_name" in b else ""
		var bt: int = b.get("building_type") if "building_type" in b else -1
		var bt_name: String = ResourceData.get_resource_name(bt) if bt >= 0 else "?"
		var w_slots: Array = b.woman_slots if "woman_slots" in b else []
		var a_slots: Array = b.animal_slots if "animal_slots" in b else []
		var occupants: Array[String] = []
		for i in w_slots.size():
			var n = w_slots[i] if i < w_slots.size() else null
			if n and is_instance_valid(n):
				occupants.append("W%d:%s" % [i, str(n.get("npc_name") if n else "?")])
		for i in a_slots.size():
			var n = a_slots[i] if i < a_slots.size() else null
			if n and is_instance_valid(n):
				occupants.append("A%d:%s" % [i, str(n.get("npc_name") if n else "?")])
		if occupants.size() > 0 or clan != "":
			b_lines.append("  %s(%s) clan=%s [%s]" % [b.name, bt_name, clan, ", ".join(occupants)])
	var sec := _session_sec()
	_log_file.store_line("")
	_log_file.store_line("[%.2fs] SNAPSHOT buildings=%d" % [sec, buildings.size()])
	# OccupationSystem assignments
	if has_node("/root/OccupationSystem"):
		var occ = get_node("/root/OccupationSystem")
		if occ.has_method("get_diagnostic_summary"):
			var occ_lines: Array = occ.get_diagnostic_summary()
			_log_file.store_line("  OccupationSystem refs: %d" % occ_lines.size())
			for line in occ_lines:
				_log_file.store_line(line)
	_log_file.store_line("  Buildings:")
	for line in b_lines:
		_log_file.store_line(line)
	_log_file.store_line("")
	_log_file.flush()

func log(event: String, details: Dictionary = {}) -> void:
	if not enabled or not _log_file or not _log_file.is_open():
		return
	var sec := _session_sec()
	var parts: Array[String] = []
	parts.append("[%.2fs]" % sec)
	parts.append(event)
	for k in details.keys():
		parts.append("%s=%s" % [k, str(details[k])])
	_log_file.store_line(" ".join(parts))
	_log_file.flush()
