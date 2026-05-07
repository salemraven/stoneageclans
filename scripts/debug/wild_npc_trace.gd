extends Node

## Lightweight JSONL trace for wild / migratory NPC spawns and motion (debug only).
## Enable: `--wild-npc-trace` or set `DebugConfig.enable_wild_npc_trace` in the inspector.
## Output: `user://wild_npc_trace_YYYYMMDD_HHMMSS.jsonl` (one JSON object per line).

var _enabled: bool = false
var _file: FileAccess = null
var _file_path: String = ""
var _t0: float = 0.0
var _last_sample: Dictionary = {}  # instance_id -> last wall time (sec)

func _ready() -> void:
	if OS.get_name() == "Web":
		return
	var dc: Node = get_node_or_null("/root/DebugConfig")
	if dc and dc.get("enable_wild_npc_trace") == true:
		_enabled = true
	if _enabled:
		_open_log()

func is_enabled() -> bool:
	return _enabled


func _interval_sec() -> float:
	var dc: Node = get_node_or_null("/root/DebugConfig")
	if dc == null or dc.get("wild_npc_trace_interval_sec") == null:
		return 2.5
	var iv: float = float(dc.wild_npc_trace_interval_sec)
	return maxf(0.2, iv)


func _open_log() -> void:
	var now: Dictionary = Time.get_datetime_dict_from_system()
	_file_path = "user://wild_npc_trace_%04d%02d%02d_%02d%02d%02d.jsonl" % [
		now.year, now.month, now.day, now.hour, now.minute, now.second
	]
	_file = FileAccess.open(_file_path, FileAccess.WRITE)
	_t0 = Time.get_ticks_msec() / 1000.0
	if _file:
		_emit({"evt": "trace_session_start", "path": _file_path})
		print("✓ Wild NPC trace file: %s" % ProjectSettings.globalize_path(_file_path))


func _emit(obj: Dictionary) -> void:
	if not _enabled or _file == null or not _file.is_open():
		return
	obj["t"] = (Time.get_ticks_msec() / 1000.0) - _t0
	_file.store_string(JSON.stringify(obj) + "\n")
	_file.flush()


## Any one-off event (spawn, chunk batch, migration despawn).
func trace(evt: String, data: Dictionary = {}) -> void:
	if not _enabled:
		return
	if _file == null or not _file.is_open():
		_open_log()
		if _file == null or not _file.is_open():
			return
	var row: Dictionary = {"evt": evt}
	for k in data:
		row[k] = data[k]
	_emit(row)


func maybe_sample_migratory(npc: Node) -> void:
	if not _enabled or npc == null or not is_instance_valid(npc):
		return
	if npc.get("migration_active") != true:
		return
	var oid: int = npc.get_instance_id()
	var now_s: float = Time.get_ticks_msec() / 1000.0
	if _last_sample.size() > 480:
		_last_sample.clear()
	var last: float = float(_last_sample.get(oid, -999.0))
	if now_s - last < _interval_sec():
		return
	_last_sample[oid] = now_s
	var nm: String = str(npc.get("npc_name")) if npc.get("npc_name") != null else str(npc.name)
	var ntype: String = str(npc.get("npc_type")) if npc.get("npc_type") != null else "?"
	var vel: Vector2 = Vector2.ZERO
	if npc is CharacterBody2D:
		vel = (npc as CharacterBody2D).velocity
	trace("wild_migratory_tick", {
		"name": nm,
		"type": ntype,
		"x": snappedf(npc.global_position.x, 1.0),
		"y": snappedf(npc.global_position.y, 1.0),
		"vx": snappedf(vel.x, 1.0),
		"vy": snappedf(vel.y, 1.0),
		"entry_side": int(npc.get("migration_entry_side")),
		"exit_x": snappedf(float(npc.get("migration_exit_x")), 1.0),
		"herded": npc.get("is_herded") == true,
	})
