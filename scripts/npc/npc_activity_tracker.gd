extends Node
# NPC Activity Tracker - Comprehensive tracking for efficiency testing
# Tracks all NPC activities, states, resources, and performance metrics

const TRACKER_LOG_FILE := "user://npc_activity_tracker.log"
const METRICS_LOG_FILE := "user://npc_metrics.log"

# When set (e.g. by RUN_AI_CLAN_TEST.sh), logs are written here so test runner doesn't depend on user:// path
var _test_log_base: String = ""

var tracker_log_file: FileAccess = null
var metrics_log_file: FileAccess = null
var tracking_enabled: bool = false

# NPC data storage
var npc_data: Dictionary = {}  # npc_id -> NPCData
var npc_state_history: Dictionary = {}  # npc_id -> Array[StateChange]
var npc_activity_log: Array[ActivityEvent] = []

# Performance tracking
var frame_times: Array[float] = []
var memory_usage: Array[Dictionary] = []
var performance_sample_interval: float = 1.0
var last_performance_sample: float = 0.0
var _last_flush_time: float = 0.0
const FLUSH_INTERVAL: float = 2.0

# Summary stats
var summary_stats: Dictionary = {
	"total_npcs": 0,
	"total_state_changes": 0,
	"total_gathers": 0,
	"total_deposits": 0,
	"total_herds_formed": 0,
	"total_items_collected": 0,
	"test_start_time": 0.0,
	"test_duration": 0.0
}

class NPCData:
	var npc_id: String
	var npc_name: String
	var npc_type: String
	var clan_name: String
	var current_state: String
	var state_start_time: float
	var inventory_count: int
	var inventory_capacity: int
	var position: Vector2
	var land_claim_distance: float
	var herd_size: int
	var hunger_level: float
	var last_activity: String
	var last_activity_time: float
	
	func _init(id: String, name: String, type: String):
		npc_id = id
		npc_name = name
		npc_type = type
		current_state = "unknown"
		state_start_time = Time.get_ticks_msec() / 1000.0
		inventory_count = 0
		inventory_capacity = 10
		position = Vector2.ZERO
		land_claim_distance = -1.0
		herd_size = 0
		hunger_level = 100.0
		last_activity = "none"
		last_activity_time = Time.get_ticks_msec() / 1000.0

class StateChange:
	var npc_id: String
	var from_state: String
	var to_state: String
	var timestamp: float
	var reason: String
	
	func _init(id: String, from: String, to: String, reason_str: String = ""):
		npc_id = id
		from_state = from
		to_state = to
		timestamp = Time.get_ticks_msec() / 1000.0
		reason = reason_str

class ActivityEvent:
	var npc_id: String
	var activity_type: String  # "gather", "deposit", "herd", "state_change", "inventory"
	var details: Dictionary
	var timestamp: float
	
	func _init(id: String, type: String, event_details: Dictionary = {}):
		npc_id = id
		activity_type = type
		details = event_details
		timestamp = Time.get_ticks_msec() / 1000.0

func _ready() -> void:
	# Check if tracking should be enabled: test env, DebugConfig, or command line
	var env_dir := OS.get_environment("GODOT_TEST_LOG_DIR").strip_edges().trim_suffix("/")
	if not env_dir.is_empty():
		tracking_enabled = true
		# Use env_dir directly if already absolute (Unix / or Windows C:)
		var is_absolute := env_dir.begins_with("/") or (env_dir.length() > 1 and env_dir.substr(1, 1) == ":")
		if is_absolute:
			_test_log_base = env_dir
		else:
			var project_root := ProjectSettings.globalize_path("res://").get_base_dir()
			_test_log_base = project_root.path_join(env_dir)
	if has_node("/root/DebugConfig"):
		var debug_config = get_node("/root/DebugConfig")
		var debug_mode = debug_config.get("enable_debug_mode")
		if debug_mode == true:
			tracking_enabled = true
	var args = OS.get_cmdline_args()
	if "--debug" in args or "--verbose" in args or "--headless" in args:
		tracking_enabled = true
	if tracking_enabled and _test_log_base != "":
		print("NPCActivityTracker: writing logs to ", _test_log_base)
	if tracking_enabled:
		_initialize_logging()
		summary_stats["test_start_time"] = Time.get_ticks_msec() / 1000.0
		log_activity("SYSTEM", "NPC Activity Tracker initialized", {})

func _get_tracker_path() -> String:
	if _test_log_base != "":
		return _test_log_base + "/npc_activity_tracker.log"
	return TRACKER_LOG_FILE

func _get_metrics_path() -> String:
	if _test_log_base != "":
		return _test_log_base + "/npc_metrics.log"
	return METRICS_LOG_FILE

func _initialize_logging() -> void:
	var tracker_path := _get_tracker_path()
	tracker_log_file = FileAccess.open(tracker_path, FileAccess.WRITE)
	if tracker_log_file:
		tracker_log_file.store_string("=== NPC Activity Tracker Started ===\n")
		tracker_log_file.store_string("Timestamp: %s\n\n" % Time.get_datetime_string_from_system())
		tracker_log_file.flush()
	else:
		push_warning("NPCActivityTracker: failed to open %s" % tracker_path)
	
	var metrics_path := _get_metrics_path()
	metrics_log_file = FileAccess.open(metrics_path, FileAccess.WRITE)
	if metrics_log_file:
		metrics_log_file.store_string("=== NPC Metrics Log Started ===\n")
		metrics_log_file.store_string("Timestamp: %s\n\n" % Time.get_datetime_string_from_system())
		metrics_log_file.store_string("timestamp,npc_id,npc_name,npc_type,state,state_duration,inventory_count,inventory_capacity,hunger,herd_size,land_claim_distance\n")
		metrics_log_file.flush()
	else:
		push_warning("NPCActivityTracker: failed to open %s" % metrics_path)

func _process(delta: float) -> void:
	if not tracking_enabled:
		return
	if multiplayer.has_multiplayer_peer() and not multiplayer.is_server():
		return
	
	# Sample performance metrics periodically
	var current_time = Time.get_ticks_msec() / 1000.0
	if current_time - last_performance_sample >= performance_sample_interval:
		_sample_performance(delta)
		last_performance_sample = current_time
	
	# Update NPC data from active NPCs
	_update_npc_data()
	# Flush logs periodically so kill -9 doesn't lose data
	if current_time - _last_flush_time >= FLUSH_INTERVAL:
		_last_flush_time = current_time
		if tracker_log_file and tracker_log_file.is_open():
			tracker_log_file.flush()
		if metrics_log_file and metrics_log_file.is_open():
			metrics_log_file.flush()

func _sample_performance(delta: float) -> void:
	frame_times.append(delta * 1000.0)  # Convert to milliseconds
	
	# Sample memory (Godot 4.x approach)
	var memory_info = {
		"timestamp": Time.get_ticks_msec() / 1000.0,
		"objects": Performance.get_monitor(Performance.OBJECT_COUNT),
		"resources": Performance.get_monitor(Performance.OBJECT_RESOURCE_COUNT),
		"nodes": Performance.get_monitor(Performance.OBJECT_NODE_COUNT)
	}
	memory_usage.append(memory_info)
	
	# Keep only last 1000 samples
	if frame_times.size() > 1000:
		frame_times.remove_at(0)
	if memory_usage.size() > 1000:
		memory_usage.remove_at(0)

func _find_npc_by_id(npc_id: String) -> Node:
	# Try to find NPC by instance ID
	var npcs = get_tree().get_nodes_in_group("npcs")
	for npc_node in npcs:
		if not is_instance_valid(npc_node):
			continue
		if str(npc_node.get_instance_id()) == npc_id:
			return npc_node
	return null

func _update_npc_data() -> void:
	# Find all NPCs in the scene
	if not get_tree():
		return
	var npcs = get_tree().get_nodes_in_group("npcs")
	if not npcs:
		return
	summary_stats["total_npcs"] = npcs.size()
	
	for npc_node in npcs:
		if not is_instance_valid(npc_node):
			continue
		
		var npc_id = str(npc_node.get_instance_id())
		
		# Create entry if doesn't exist
		if not npc_data.has(npc_id):
			var npc_name = npc_node.get("npc_name") if npc_node.has_method("get") else "unknown"
			var npc_type = npc_node.get("npc_type") if npc_node.has_method("get") else "unknown"
			npc_data[npc_id] = NPCData.new(npc_id, npc_name, npc_type)
			log_activity(npc_id, "npc_registered", {"name": npc_name, "type": npc_type})
		
		var data = npc_data[npc_id]
		
		# Update NPC data (use "prop" in node — Node has no .has(), that's Dictionary)
		if "npc_name" in npc_node:
			data.npc_name = npc_node.npc_name
		if "npc_type" in npc_node:
			data.npc_type = npc_node.npc_type
		if "clan_name" in npc_node:
			data.clan_name = npc_node.get_clan_name() if npc_node.has_method("get_clan_name") else npc_node.clan_name
		if "position" in npc_node:
			data.position = npc_node.position
		
		# Get FSM state
		if "fsm" in npc_node:
			var fsm = npc_node.fsm
			if fsm and ("current_state_name" in fsm):
				var new_state = fsm.current_state_name
				if new_state != data.current_state:
					# State changed
					_on_state_changed(npc_id, data.current_state, new_state)
					data.current_state = new_state
					data.state_start_time = Time.get_ticks_msec() / 1000.0
		
		# Get inventory
		if "inventory" in npc_node:
			var inv = npc_node.inventory
			if inv and inv.has_method("get_item_count"):
				data.inventory_count = inv.get_item_count()
				data.inventory_capacity = inv.capacity if ("capacity" in inv) else 10
		
		# Get hunger
		if "stats_component" in npc_node:
			var stats = npc_node.stats_component
			if stats and stats.has_method("get_hunger_percent"):
				data.hunger_level = stats.get_hunger_percent()
		
		# Get herd size
		data.herd_size = _get_herd_size(npc_node)
		
		# Calculate distance to land claim
		data.land_claim_distance = _get_land_claim_distance(npc_node)
		
		# Log metrics periodically
		_log_npc_metrics(data)

func _get_herd_size(npc: Node) -> int:
	# Count NPCs following this NPC
	var herd_size = 0
	var npcs = get_tree().get_nodes_in_group("npcs")
	for other_npc in npcs:
		if not is_instance_valid(other_npc):
			continue
		if other_npc == npc:
			continue
		if ("herd_leader" in other_npc) and other_npc.herd_leader == npc:
			herd_size += 1
	return herd_size

func _get_land_claim_distance(npc: Node) -> float:
	var npc_clan = npc.get_clan_name() if npc.has_method("get_clan_name") else npc.clan_name
	if npc_clan == "":
		return -1.0
	
	var claims = get_tree().get_nodes_in_group("land_claims")
	var min_distance = -1.0
	
	for claim in claims:
		if not is_instance_valid(claim):
			continue
		var claim_clan = claim.get("clan_name") if ("clan_name" in claim) else ""
		if claim_clan == npc_clan:
			var distance = npc.position.distance_to(claim.position)
			if min_distance < 0.0 or distance < min_distance:
				min_distance = distance
	
	return min_distance

func _on_state_changed(npc_id: String, from_state: String, to_state: String, reason: String = "") -> void:
	if not tracking_enabled:
		return
	
	# Ensure NPC data exists (create if not found)
	if not npc_data.has(npc_id):
		# Try to find the NPC by instance ID
		var npc_node = _find_npc_by_id(npc_id)
		if npc_node:
			var npc_name = npc_node.get("npc_name") if ("npc_name" in npc_node) else "unknown"
			var npc_type = npc_node.get("npc_type") if ("npc_type" in npc_node) else "unknown"
			npc_data[npc_id] = NPCData.new(npc_id, npc_name, npc_type)
			log_activity(npc_id, "npc_registered", {"name": npc_name, "type": npc_type})
	
	var data = npc_data.get(npc_id)
	if not data:
		return
	
	summary_stats["total_state_changes"] += 1
	
	# Record state change
	var state_change = StateChange.new(npc_id, from_state, to_state, reason)
	if not npc_state_history.has(npc_id):
		npc_state_history[npc_id] = []
	npc_state_history[npc_id].append(state_change)
	
	# Log activity
	log_activity(npc_id, "state_change", {
		"from": from_state,
		"to": to_state,
		"reason": reason,
		"state_duration": Time.get_ticks_msec() / 1000.0 - data.state_start_time
	})
	
	# Keep only last 100 state changes per NPC
	if npc_state_history[npc_id].size() > 100:
		npc_state_history[npc_id].remove_at(0)

func log_activity(npc_id: String, activity_type: String, details: Dictionary = {}) -> void:
	if not tracking_enabled:
		return
	
	var event = ActivityEvent.new(npc_id, activity_type, details)
	npc_activity_log.append(event)
	
	# Keep only last 10000 events
	if npc_activity_log.size() > 10000:
		npc_activity_log.remove_at(0)
	
	# Write to log file
	if tracker_log_file and tracker_log_file.is_open():
		var timestamp = Time.get_time_string_from_system()
		var data = npc_data.get(npc_id)
		var npc_name = data.npc_name if data else "unknown"
		
		var log_line = "[%s] [%s] %s: %s" % [timestamp, npc_name, activity_type, JSON.stringify(details)]
		tracker_log_file.store_string(log_line + "\n")
		tracker_log_file.flush()

func log_gather(npc_id: String, resource_type: String, quantity: int = 1) -> void:
	if not tracking_enabled:
		return
	
	# Ensure NPC data exists
	if not npc_data.has(npc_id):
		var npc_node = _find_npc_by_id(npc_id)
		if npc_node:
			var npc_name = npc_node.get("npc_name") if ("npc_name" in npc_node) else "unknown"
			var npc_type = npc_node.get("npc_type") if ("npc_type" in npc_node) else "unknown"
			npc_data[npc_id] = NPCData.new(npc_id, npc_name, npc_type)
	
	summary_stats["total_gathers"] += 1
	summary_stats["total_items_collected"] += quantity
	log_activity(npc_id, "gather", {"resource": resource_type, "quantity": quantity})

func log_deposit(npc_id: String, item_count: int) -> void:
	if not tracking_enabled:
		return
	
	# Ensure NPC data exists
	if not npc_data.has(npc_id):
		var npc_node = _find_npc_by_id(npc_id)
		if npc_node:
			var npc_name = npc_node.get("npc_name") if ("npc_name" in npc_node) else "unknown"
			var npc_type = npc_node.get("npc_type") if ("npc_type" in npc_node) else "unknown"
			npc_data[npc_id] = NPCData.new(npc_id, npc_name, npc_type)
	
	summary_stats["total_deposits"] += 1
	log_activity(npc_id, "deposit", {"items": item_count})

func log_herd_formed(npc_id: String, herd_size: int) -> void:
	summary_stats["total_herds_formed"] += 1
	log_activity(npc_id, "herd_formed", {"herd_size": herd_size})

func _log_npc_metrics(data: NPCData) -> void:
	# Log metrics every 5 seconds per NPC (throttled)
	var current_time = Time.get_ticks_msec() / 1000.0
	var time_in_state = current_time - data.state_start_time
	
	if metrics_log_file and metrics_log_file.is_open():
		var csv_line = "%.2f,%s,%s,%s,%s,%.2f,%d,%d,%.1f,%d,%.1f\n" % [
			current_time,
			data.npc_id,
			data.npc_name,
			data.npc_type,
			data.current_state,
			time_in_state,
			data.inventory_count,
			data.inventory_capacity,
			data.hunger_level,
			data.herd_size,
			data.land_claim_distance
		]
		metrics_log_file.store_string(csv_line)
		metrics_log_file.flush()

func get_summary_stats() -> Dictionary:
	var current_time = Time.get_ticks_msec() / 1000.0
	summary_stats["test_duration"] = current_time - summary_stats["test_start_time"]
	return summary_stats.duplicate()

func get_state_distribution() -> Dictionary:
	var distribution = {}
	for npc_id in npc_data:
		var data = npc_data[npc_id]
		var state = data.current_state
		if not distribution.has(state):
			distribution[state] = 0
		distribution[state] += 1
	return distribution

func get_performance_stats() -> Dictionary:
	if frame_times.size() == 0:
		return {"avg_frame_time": 0.0, "max_frame_time": 0.0, "min_frame_time": 0.0}
	
	var sum = 0.0
	var max_time = 0.0
	var min_time = 9999.0
	for time in frame_times:
		sum += time
		if time > max_time:
			max_time = time
		if time < min_time:
			min_time = time
	
	return {
		"avg_frame_time": sum / frame_times.size(),
		"max_frame_time": max_time,
		"min_frame_time": min_time,
		"sample_count": frame_times.size()
	}

func _exit_tree() -> void:
	if tracking_enabled:
		log_activity("SYSTEM", "NPC Activity Tracker shutting down", {})
		_write_final_summary()
	
	if tracker_log_file:
		if tracker_log_file.is_open():
			tracker_log_file.flush()
		tracker_log_file.close()
	
	if metrics_log_file:
		if metrics_log_file.is_open():
			metrics_log_file.flush()
		metrics_log_file.close()

func _write_final_summary() -> void:
	if not tracker_log_file or not tracker_log_file.is_open():
		return
	
	tracker_log_file.store_string("\n=== FINAL SUMMARY ===\n")
	var stats = get_summary_stats()
	for key in stats:
		tracker_log_file.store_string("%s: %s\n" % [key, stats[key]])
	
	var state_dist = get_state_distribution()
	tracker_log_file.store_string("\nState Distribution:\n")
	for state in state_dist:
		tracker_log_file.store_string("  %s: %d\n" % [state, state_dist[state]])
	
	var perf_stats = get_performance_stats()
	tracker_log_file.store_string("\nPerformance Stats:\n")
	tracker_log_file.store_string("  Avg Frame Time: %.2f ms\n" % perf_stats["avg_frame_time"])
	tracker_log_file.store_string("  Max Frame Time: %.2f ms\n" % perf_stats["max_frame_time"])
	tracker_log_file.store_string("  Min Frame Time: %.2f ms\n" % perf_stats["min_frame_time"])

