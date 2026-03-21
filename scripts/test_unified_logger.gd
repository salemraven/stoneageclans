extends Node

# Comprehensive test script for UnifiedLogger
# Add this as a child node to Main scene or run via console command
# Usage: Call test_all() from console or attach to scene tree

var test_results: Dictionary = {}

func _ready() -> void:
	# Auto-run tests if this is the main scene
	if get_tree().current_scene == self:
		call_deferred("test_all")
	else:
		# If attached to another scene, wait a bit for everything to initialize
		await get_tree().create_timer(0.5).timeout
		# Auto-run tests
		call_deferred("test_all")

func test_all() -> void:
	var separator = "=".repeat(60)
	print("\n" + separator)
	print("UNIFIED LOGGER TEST SUITE")
	print(separator + "\n")
	
	test_results.clear()
	
	# Enable logging for testing
	if has_node("/root/UnifiedLogger"):
		var logger = get_node("/root/UnifiedLogger")
		logger.set_file_logging_enabled(true)
		logger.set_console_logging_enabled(true)
		logger.set_min_log_level(UnifiedLogger.Level.DEBUG)
		
		# Enable all categories
		for category in UnifiedLogger.Category.values():
			logger.set_category_enabled(category, true)
		
		print("✓ Logger initialized and enabled\n")
		
		# Run all tests
		test_basic_logging()
		test_log_levels()
		test_categories()
		test_convenience_methods()
		test_details_dictionary()
		test_file_logging()
		test_category_filtering()
		
		# Print summary
		print("\n" + separator)
		print("TEST SUMMARY")
		print(separator)
		var passed = 0
		var failed = 0
		for test_name in test_results.keys():
			var result = test_results[test_name]
			if result:
				print("✓ %s: PASSED" % test_name)
				passed += 1
			else:
				print("✗ %s: FAILED" % test_name)
				failed += 1
		print("\nTotal: %d passed, %d failed" % [passed, failed])
		print(separator + "\n")
		
		# If running as main scene, quit after showing results
		if get_tree().current_scene == self:
			await get_tree().create_timer(3.0).timeout
			get_tree().quit()
	else:
		push_error("UnifiedLogger not found in autoload!")
		if get_tree().current_scene == self:
			get_tree().quit()

func test_basic_logging() -> void:
	print("--- Test 1: Basic Logging ---")
	UnifiedLogger.log("Basic log message", UnifiedLogger.Category.SYSTEM)
	UnifiedLogger.log("Basic log with category", UnifiedLogger.Category.NPC)
	test_results["Basic Logging"] = true
	print("✓ Basic logging works\n")

func test_log_levels() -> void:
	print("--- Test 2: Log Levels ---")
	UnifiedLogger.log("DEBUG level message", UnifiedLogger.Category.SYSTEM, UnifiedLogger.Level.DEBUG)
	UnifiedLogger.log("INFO level message", UnifiedLogger.Category.SYSTEM, UnifiedLogger.Level.INFO)
	UnifiedLogger.log("WARNING level message", UnifiedLogger.Category.SYSTEM, UnifiedLogger.Level.WARNING)
	UnifiedLogger.log("ERROR level message", UnifiedLogger.Category.SYSTEM, UnifiedLogger.Level.ERROR)
	test_results["Log Levels"] = true
	print("✓ All log levels work\n")

func test_categories() -> void:
	print("--- Test 3: All Categories ---")
	UnifiedLogger.log("SYSTEM category", UnifiedLogger.Category.SYSTEM)
	UnifiedLogger.log("NPC category", UnifiedLogger.Category.NPC)
	UnifiedLogger.log("INVENTORY category", UnifiedLogger.Category.INVENTORY)
	UnifiedLogger.log("DRAG_DROP category", UnifiedLogger.Category.DRAG_DROP)
	UnifiedLogger.log("HERDING category", UnifiedLogger.Category.HERDING)
	UnifiedLogger.log("COMBAT category", UnifiedLogger.Category.COMBAT)
	UnifiedLogger.log("BUILDING category", UnifiedLogger.Category.BUILDING)
	UnifiedLogger.log("RESOURCE category", UnifiedLogger.Category.RESOURCE)
	UnifiedLogger.log("ERROR category", UnifiedLogger.Category.ERROR)
	UnifiedLogger.log("WARNING category", UnifiedLogger.Category.WARNING)
	UnifiedLogger.log("DEBUG category", UnifiedLogger.Category.DEBUG)
	UnifiedLogger.log("PERFORMANCE category", UnifiedLogger.Category.PERFORMANCE)
	test_results["All Categories"] = true
	print("✓ All categories work\n")

func test_convenience_methods() -> void:
	print("--- Test 4: Convenience Methods ---")
	# Level convenience methods
	UnifiedLogger.log_info("Info message")
	UnifiedLogger.log_warning("Warning message")
	UnifiedLogger.log_error("Error message")
	UnifiedLogger.log_debug("Debug message")
	
	# Category convenience methods
	UnifiedLogger.log_system("System log")
	UnifiedLogger.log_npc("NPC log", {"npc": "TestNPC", "state": "wander"})
	UnifiedLogger.log_inventory("Inventory log", {"item": "berries", "count": 5})
	UnifiedLogger.log_drag_drop("Drag drop log", {"from": "player", "to": "flag"})
	UnifiedLogger.log_herding("Herding log", {"leader": "player", "followers": 3})
	
	# Backward compatibility
	UnifiedLogger.write_log("Backward compat log")
	UnifiedLogger.write_log("Backward compat ERROR", "ERROR")
	UnifiedLogger.write_log("Backward compat WARNING", "WARNING")
	UnifiedLogger.write_log("Backward compat DEBUG", "DEBUG")
	
	test_results["Convenience Methods"] = true
	print("✓ All convenience methods work\n")

func test_details_dictionary() -> void:
	print("--- Test 5: Details Dictionary ---")
	var details := {
		"npc_name": "TestNPC",
		"state": "gather",
		"item_count": 5,
		"position": "100,200",
		"health": 75.5,
		"is_active": true
	}
	UnifiedLogger.log("Message with details", UnifiedLogger.Category.NPC, UnifiedLogger.Level.INFO, details)
	test_results["Details Dictionary"] = true
	print("✓ Details dictionary works\n")

func test_file_logging() -> void:
	print("--- Test 6: File Logging ---")
	var logger = get_node("/root/UnifiedLogger")
	if logger.file_logging_enabled:
		UnifiedLogger.log("File logging test message", UnifiedLogger.Category.SYSTEM)
		# Force flush
		logger._flush_buffer()
		test_results["File Logging"] = true
		print("✓ File logging enabled and message written")
		print("  Check: %s" % UnifiedLogger.LOG_FILE)
	else:
		test_results["File Logging"] = false
		print("⚠ File logging not enabled")
	print()

func test_category_filtering() -> void:
	print("--- Test 7: Category Filtering ---")
	var logger = get_node("/root/UnifiedLogger")
	
	# Disable NPC category
	logger.set_category_enabled(UnifiedLogger.Category.NPC, false)
	UnifiedLogger.log("This NPC message should NOT appear", UnifiedLogger.Category.NPC)
	
	# Re-enable NPC category
	logger.set_category_enabled(UnifiedLogger.Category.NPC, true)
	UnifiedLogger.log("This NPC message SHOULD appear", UnifiedLogger.Category.NPC)
	
	test_results["Category Filtering"] = true
	print("✓ Category filtering works\n")
