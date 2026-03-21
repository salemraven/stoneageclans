extends Node
# Performance Monitor - Debug tool for combat system performance
# Add to autoload for runtime performance tracking

var detection_area_queries := 0
var get_nodes_in_group_calls := 0
var combat_events_processed := 0
var last_reset_time := 0

func _ready() -> void:
	last_reset_time = Time.get_ticks_msec()

func _process(_delta: float) -> void:
	# Reset counters every second
	var now = Time.get_ticks_msec()
	if now - last_reset_time >= 1000:
		_print_performance_stats()
		detection_area_queries = 0
		get_nodes_in_group_calls = 0
		combat_events_processed = 0
		last_reset_time = now

func _print_performance_stats() -> void:
	print("📊 Performance Stats (per second):")
	print("  DetectionArea queries: %d" % detection_area_queries)
	print("  get_nodes_in_group() calls: %d" % get_nodes_in_group_calls)
	print("  Combat events processed: %d" % combat_events_processed)
	
	if get_nodes_in_group_calls > 0:
		var improvement = float(get_nodes_in_group_calls) / max(detection_area_queries, 1)
		print("  Performance improvement: %.1fx reduction" % improvement)

func record_detection_query() -> void:
	detection_area_queries += 1

func record_get_nodes_call() -> void:
	get_nodes_in_group_calls += 1

func record_combat_event() -> void:
	combat_events_processed += 1
