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
		print("⚔️ CombatScheduler initialized")
	set_process(true)  # Ensure _process() is enabled
	if DebugConfig.enable_debug_mode:
		print("🔍 SCHEDULER: _process() enabled")

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
			print("🔍 SCHEDULER: _process() running - pending=%d, next_event_time=%d, now=%d" % [events.size(), events[0].time, now])
	
	# Process events that are due
	# CRITICAL: Check if events exist and are due
	if DebugConfig.enable_debug_mode and events.size() > 0:
		var next_time = events[0].time
		if next_time <= now:
			print("🔍 SCHEDULER: Event due! next_time=%d, now=%d, diff=%d" % [next_time, now, now - next_time])
	
	while events.size() > 0 and events[0].time <= now:
		var event = events.pop_front()
		event_count_this_second += 1
		
		# Validate callable before calling
		if event.callable.is_valid():
			if DebugConfig.enable_debug_mode:
				print("⏰ SCHEDULER: Executing event at time %d (now=%d, entity_id=%d)" % [event.time, now, event.entity_id])
			# GDScript doesn't have try/except, but we can validate before calling
			var callable_obj = event.callable.get_object()
			var method_name = event.callable.get_method()
			
			if DebugConfig.enable_debug_mode:
				print("🔍 SCHEDULER: Callable details - method='%s', obj=%s, valid=%s" % [
					method_name,
					callable_obj,
					"yes" if (callable_obj and is_instance_valid(callable_obj)) else "no"
				])
			
			if callable_obj and is_instance_valid(callable_obj):
				if DebugConfig.enable_debug_mode:
					print("⏰ SCHEDULER: Calling method '%s' on object %s" % [method_name, callable_obj])
				# Try to call - if it crashes, we'll see it in the logs
				event.callable.call()
				if DebugConfig.enable_debug_mode:
					print("✅ SCHEDULER: Event executed successfully (method: %s)" % method_name)
			else:
				var error_msg = "CRASH: Invalid callable object for event at time %d (entity_id=%d, obj=%s, method=%s)" % [event.time, event.entity_id, callable_obj, method_name]
				if DebugConfig.enable_debug_mode:
					print("❌ SCHEDULER: %s" % error_msg)
				push_error(error_msg)
		elif DebugConfig.enable_debug_mode:
			print("⚠️ SCHEDULER: Invalid callable for event at time %d (is_valid=%s)" % [event.time, event.callable.is_valid()])

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
		print("⏰ SCHEDULER: Scheduled event at time %d (entity_id=%d, pending=%d)" % [time_msec, entity_id, events.size()])

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
