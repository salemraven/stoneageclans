extends Node
# Note: This is an autoload singleton, so we don't use class_name
# Access it globally as CombatScheduler

# CombatScheduler - Event-driven combat timing system
# Schedules and resolves combat events (hit frames, recovery, morale checks)
# Uses simple Array + sort for MVP (upgrade to PriorityQueue later if needed)

var events := []  # Array of {time: int, callable: Callable, entity_id: int}

# Debug counters
var events_processed_this_second := 0
var event_count_this_second := 0
var last_second_time := 0

func _ready() -> void:
	if DebugConfig.enable_debug_mode:
		UnifiedLogger.log("CombatScheduler initialized", UnifiedLogger.Category.DEBUG, UnifiedLogger.Level.DEBUG)
	set_process(true)  # Ensure _process() is enabled
	if DebugConfig.enable_debug_mode:
		UnifiedLogger.log("CombatScheduler _process enabled", UnifiedLogger.Category.DEBUG, UnifiedLogger.Level.DEBUG)

func _process(_delta: float) -> void:
	if multiplayer.has_multiplayer_peer() and not multiplayer.is_server():
		return
	var now: int = Time.get_ticks_msec()
	if SimClock:
		now = SimClock.get_authoritative_ticks_msec()
	
	# Debug counter reset (every second)
	if now - last_second_time >= 1000:
		events_processed_this_second = event_count_this_second
		event_count_this_second = 0
		last_second_time = now
		if DebugConfig.enable_debug_mode and events.size() > 0:
			UnifiedLogger.log("SCHEDULER _process: pending=%d next_t=%d now=%d" % [events.size(), events[0].time, now], UnifiedLogger.Category.DEBUG, UnifiedLogger.Level.DEBUG)
	
	# Process events that are due
	# CRITICAL: Check if events exist and are due
	if DebugConfig.enable_debug_mode and events.size() > 0:
		var next_time = events[0].time
		if next_time <= now:
			UnifiedLogger.log("SCHEDULER event due: next=%d now=%d diff=%d" % [next_time, now, now - next_time], UnifiedLogger.Category.DEBUG, UnifiedLogger.Level.DEBUG)
	
	while events.size() > 0 and events[0].time <= now:
		var event = events.pop_front()
		event_count_this_second += 1
		
		# Validate callable before calling
		if event.callable.is_valid():
			if DebugConfig.enable_debug_mode:
				UnifiedLogger.log("SCHEDULER execute: t=%d now=%d entity=%d" % [event.time, now, event.entity_id], UnifiedLogger.Category.DEBUG, UnifiedLogger.Level.DEBUG)
			# GDScript doesn't have try/except, but we can validate before calling
			var callable_obj = event.callable.get_object()
			var method_name = event.callable.get_method()
			
			if DebugConfig.enable_debug_mode:
				UnifiedLogger.log("SCHEDULER callable: %s obj=%s" % [method_name, callable_obj], UnifiedLogger.Category.DEBUG, UnifiedLogger.Level.DEBUG)
			
			if callable_obj and is_instance_valid(callable_obj):
				if DebugConfig.enable_debug_mode:
					UnifiedLogger.log("SCHEDULER call %s" % method_name, UnifiedLogger.Category.DEBUG, UnifiedLogger.Level.DEBUG)
				# Try to call - if it crashes, we'll see it in the logs
				event.callable.call()
				if DebugConfig.enable_debug_mode:
					UnifiedLogger.log("SCHEDULER done: %s" % method_name, UnifiedLogger.Category.DEBUG, UnifiedLogger.Level.DEBUG)
			else:
				var error_msg = "CRASH: Invalid callable object for event at time %d (entity_id=%d, obj=%s, method=%s)" % [event.time, event.entity_id, callable_obj, method_name]
				if DebugConfig.enable_debug_mode:
					UnifiedLogger.log(error_msg, UnifiedLogger.Category.DEBUG, UnifiedLogger.Level.DEBUG)
				push_error(error_msg)
		elif DebugConfig.enable_debug_mode:
			UnifiedLogger.log("SCHEDULER invalid callable at t=%d" % event.time, UnifiedLogger.Category.DEBUG, UnifiedLogger.Level.DEBUG)

# Schedule an event to fire at a specific time
# time_msec: milliseconds from now (use Time.get_ticks_msec() + delay)
# callable: function to call when event fires
# entity_id: optional, for cancelling all events for a specific entity
func schedule(time_msec: int, callable: Callable, entity_id: int = -1) -> void:
	var event = {
		"time": time_msec,
		"callable": callable,
		"entity_id": entity_id
	}
	
	events.append(event)
	# Keep sorted by time (insertion sort for small arrays, or full sort if needed)
	events.sort_custom(func(a, b): return a.time < b.time)
	
	if DebugConfig.enable_debug_mode:
		UnifiedLogger.log("SCHEDULER schedule: t=%d entity=%d pending=%d" % [time_msec, entity_id, events.size()], UnifiedLogger.Category.DEBUG, UnifiedLogger.Level.DEBUG)

# Cancel all events for a specific entity
func cancel_all_for_entity(entity_id: int) -> void:
	events = events.filter(func(e): return e.entity_id != entity_id)
	# Re-sort after filtering
	events.sort_custom(func(a, b): return a.time < b.time)

# Cancel all events (useful for cleanup)
func cancel_all() -> void:
	events.clear()

# Get number of pending events
func get_pending_count() -> int:
	return events.size()

# Get debug stats
func get_debug_stats() -> Dictionary:
	return {
		"pending_events": events.size(),
		"events_per_second": events_processed_this_second
	}
