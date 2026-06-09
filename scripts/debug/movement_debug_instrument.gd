extends RefCounted
class_name MovementDebugInstrument

## Rate-limited, filterable NPC movement samples for diagnosing odd walking / steering.
## Enable via DebugConfig.enable_movement_debug or --movement-debug (use with --log-console and/or --log-file).

static var _last_sample_time: Dictionary = {}  # Object ID -> unix time

## Long runs spawn many NPCs; instance IDs never removed — clear occasionally to cap memory.
static func prune_sample_time_cache_if_huge() -> void:
	if _last_sample_time.size() < 400:
		return
	_last_sample_time.clear()

static func try_log_physics_step(
	npc: CharacterBody2D,
	_delta: float,
	dbg_desired_velocity: Vector2,
	dbg_steering_used: bool,
	task_controls_movement: bool,
	is_idle_brake: bool
) -> void:
	var cfg: Node = _get_debug_config()
	if cfg == null or not (cfg.get("enable_movement_debug") as bool):
		return
	if UnifiedLogger == null:
		return
	if not npc:
		return
	var npc_type: String = str(npc.get("npc_type")) if npc.get("npc_type") != null else ""
	if not _npc_type_allowed(cfg, npc_type):
		return
	var interval: float = float(cfg.get("movement_debug_interval_sec")) if cfg.get("movement_debug_interval_sec") != null else 0.5
	if interval < 0.05:
		interval = 0.05
	var now: float = Time.get_ticks_msec() / 1000.0
	var oid: int = npc.get_instance_id()
	var last_t: float = float(_last_sample_time.get(oid, -1.0))
	if last_t >= 0.0 and (now - last_t) < interval:
		return
	_last_sample_time[oid] = now

	var npc_name: String = str(npc.get("npc_name")) if npc.get("npc_name") != null else "?"
	var fsm_state: String = ""
	if npc.get("fsm") and npc.fsm and npc.fsm.has_method("get_current_state_name"):
		fsm_state = str(npc.fsm.get_current_state_name())

	var steer: SteeringAgent = npc.steering_agent as SteeringAgent if npc.steering_agent else null
	var mode_s: String = _steering_mode_name(steer)
	var tgt: Vector2 = Vector2.ZERO
	var wander_ctr: Vector2 = Vector2.ZERO
	var wander_rad: float = 0.0
	var stuck_t: float = 0.0
	var path_attempts: int = 0
	if steer:
		tgt = steer.target_position
		wander_ctr = steer.wander_center
		wander_rad = steer.wander_radius
		stuck_t = steer.stuck_check_time
		path_attempts = steer.pathfinding_attempts

	var details: Dictionary = {
		"npc": npc_name,
		"type": npc_type,
		"fsm": fsm_state,
		"pos": "%.1f,%.1f" % [npc.global_position.x, npc.global_position.y],
		"vel": "%.1f,%.1f" % [npc.velocity.x, npc.velocity.y],
		"spd": "%.1f" % npc.velocity.length(),
		"task_mv": str(task_controls_movement),
		"idle_brk": str(is_idle_brake),
		"steer_used": str(dbg_steering_used),
		"des_vel": "%.1f,%.1f" % [dbg_desired_velocity.x, dbg_desired_velocity.y] if dbg_steering_used else "n/a",
		"mode": mode_s if steer else "no_agent",
		"tgt": "%.1f,%.1f" % [tgt.x, tgt.y] if steer else "",
		"w_ctr": "%.1f,%.1f" % [wander_ctr.x, wander_ctr.y] if steer else "",
		"w_rad": "%.0f" % wander_rad if steer else "",
		"stuck_s": "%.2f" % stuck_t if steer else "",
		"path_try": str(path_attempts) if steer else "",
	}
	UnifiedLogger.log_movement("NPC_MOVE", details, UnifiedLogger.Level.INFO)


static func _get_debug_config() -> Node:
	var st: SceneTree = Engine.get_main_loop() as SceneTree
	if st == null:
		return null
	return st.root.get_node_or_null("/root/DebugConfig")


static func _npc_type_allowed(cfg: Node, npc_type: String) -> bool:
	var raw: String = str(cfg.get("movement_debug_filter")) if cfg.get("movement_debug_filter") != null else "clansman"
	raw = raw.strip_edges()
	if raw.is_empty() or raw.to_lower() == "all":
		return true
	for part in raw.split(",", false):
		var p: String = part.strip_edges().to_lower()
		if p.is_empty():
			continue
		if npc_type.to_lower() == p:
			return true
	return false


static func _steering_mode_name(steer: SteeringAgent) -> String:
	if steer == null:
		return ""
	match steer.current_mode:
		SteeringAgent.SteeringMode.SEEK:
			return "SEEK"
		SteeringAgent.SteeringMode.ARRIVE:
			return "ARRIVE"
		SteeringAgent.SteeringMode.FLEE:
			return "FLEE"
		SteeringAgent.SteeringMode.WANDER:
			return "WANDER"
		_:
			return "?"
