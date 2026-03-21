extends Node

# Unified Logger - Single logging system for entire game
# Replaces: Logger, ConsoleLogger, MinigameLogger, DragDropLogger
# 
# Usage:
#   UnifiedLogger.log("message", UnifiedLogger.Category.SYSTEM)
#   UnifiedLogger.log_error("error", UnifiedLogger.Category.NPC)
#   UnifiedLogger.log_npc("NPC state changed", {"npc": "name", "state": "gather"})
#   UnifiedLogger.log_inventory("Item moved", {"from": "player", "to": "flag"})

# Log categories for filtering
enum Category {
	SYSTEM,      # General system messages
	NPC,         # NPC states, FSM, behavior
	INVENTORY,   # Inventory operations, drag-drop
	DRAG_DROP,   # Drag and drop specific (subset of inventory)
	HERDING,     # Herding mechanics
	COMBAT,      # Combat, agro, fighting
	BUILDING,    # Building placement, construction
	RESOURCE,    # Resource gathering, collection
	ERROR,       # Errors (always logged)
	WARNING,     # Warnings
	DEBUG,       # Debug messages
	PERFORMANCE  # Performance metrics
}

# Log levels
enum Level {
	DEBUG,
	INFO,
	WARNING,
	ERROR
}

# Configuration
const LOG_FILE := "user://game_logs.txt"
const MAX_LOG_SIZE := 10485760  # 10MB max log size
const FLUSH_INTERVAL := 1.0  # Flush every second
const THROTTLE_MAX_PER_SECOND := 10  # Max logs per category per second (drops excess to prevent lag)
const THROTTLE_WINDOW := 1.0  # Seconds

# State
var log_file: FileAccess = null
var log_buffer: Array[String] = []
var last_flush_time: float = 0.0
var _throttle: Dictionary = {}  # category -> { count: int, window_start: float }

# Settings (controlled by DebugConfig)
var file_logging_enabled: bool = false
var console_logging_enabled: bool = false
var min_log_level: Level = Level.WARNING  # Only log WARNING and ERROR by default (reduced verbosity)

# Category filters (can disable specific categories)
var enabled_categories: Dictionary = {}  # Category -> bool, empty = all enabled

func _ready() -> void:
	# Get settings from DebugConfig if available
	if has_node("/root/DebugConfig"):
		var debug_config = get_node("/root/DebugConfig")
		if "enable_file_logging" in debug_config:
			file_logging_enabled = debug_config.enable_file_logging
		if "enable_console_logging" in debug_config:
			console_logging_enabled = debug_config.enable_console_logging
		if ("enable_debug_mode" in debug_config and debug_config.enable_debug_mode) or ("enable_verbose_npc_logging" in debug_config and debug_config.enable_verbose_npc_logging):
			min_log_level = Level.DEBUG
		
		# Enable all categories by default, except NPC (too verbose)
		for category in Category.values():
			enabled_categories[category] = true
		
		# Disable NPC category by default (too verbose)
		enabled_categories[Category.NPC] = false
		enabled_categories[Category.DRAG_DROP] = false  # Also disable drag/drop (too verbose)
		enabled_categories[Category.INVENTORY] = false  # Also disable inventory (too verbose)
		
		# Apply category-specific settings (NPC only when explicitly verbose - prevents flood when only console/file logging is on)
		if "enable_verbose_npc_logging" in debug_config:
			var verbose_npc = debug_config.enable_verbose_npc_logging
			enabled_categories[Category.NPC] = verbose_npc
		
		if "enable_herd_logging" in debug_config:
			var herd_logging = debug_config.enable_herd_logging
			enabled_categories[Category.HERDING] = herd_logging or file_logging_enabled or console_logging_enabled
	
	# Initialize file if needed
	if file_logging_enabled:
		_open_log_file()
	
	last_flush_time = Time.get_ticks_msec() / 1000.0
	
	# Only run _process when we have buffer to flush
	set_process(false)
	
	if file_logging_enabled or console_logging_enabled:
		write_log_entry("=== Unified Logger Started ===", Category.SYSTEM, Level.INFO)
		write_log_entry("File logging: %s, Console logging: %s" % [file_logging_enabled, console_logging_enabled], Category.SYSTEM, Level.INFO)

func _open_log_file() -> void:
	if log_file and log_file.is_open():
		log_file.close()
	
	# Check file size and rotate if needed
	var file_path := ProjectSettings.globalize_path(LOG_FILE)
	if FileAccess.file_exists(file_path):
		var file_size := FileAccess.get_file_as_bytes(file_path).size()
		if file_size > MAX_LOG_SIZE:
			var old_path := file_path + ".old"
			if FileAccess.file_exists(old_path):
				DirAccess.remove_absolute(old_path)
			DirAccess.rename_absolute(file_path, old_path)
	
	# Open file for append
	log_file = FileAccess.open(LOG_FILE, FileAccess.WRITE)
	if not log_file:
		var dir := LOG_FILE.get_base_dir()
		DirAccess.open("user://").make_dir_recursive(dir)
		log_file = FileAccess.open(LOG_FILE, FileAccess.WRITE)
	
	if log_file:
		log_file.seek_end()
		log_file.store_string("\n")
	else:
		push_error("Failed to open log file: %s" % LOG_FILE)

func _flush_buffer() -> void:
	if not file_logging_enabled or not log_file:
		return
	
	if not log_file.is_open():
		_open_log_file()
		if not log_file or not log_file.is_open():
			return
	
	for line in log_buffer:
		log_file.store_string(line)
	
	log_file.flush()
	log_buffer.clear()
	
	# Stop _process when nothing left to flush
	set_process(false)

func _should_throttle(category: Category, level: Level) -> bool:
	if level >= Level.WARNING:
		return false  # Never throttle warnings/errors
	if not _throttle.has(category):
		_throttle[category] = {"count": 0, "window_start": 0.0}
	var data: Dictionary = _throttle[category]
	var now := Time.get_ticks_msec() / 1000.0
	if now - data.window_start >= THROTTLE_WINDOW:
		data.count = 0
		data.window_start = now
	data.count += 1
	return data.count > THROTTLE_MAX_PER_SECOND

func _process(_delta: float) -> void:
	# Periodic flush check
	if file_logging_enabled and log_buffer.size() > 0:
		var current_time = Time.get_ticks_msec() / 1000.0
		if current_time - last_flush_time >= FLUSH_INTERVAL:
			_flush_buffer()
			last_flush_time = current_time

func _get_category_name(category: Category) -> String:
	match category:
		Category.SYSTEM:
			return "SYSTEM"
		Category.NPC:
			return "NPC"
		Category.INVENTORY:
			return "INVENTORY"
		Category.DRAG_DROP:
			return "DRAG_DROP"
		Category.HERDING:
			return "HERDING"
		Category.COMBAT:
			return "COMBAT"
		Category.BUILDING:
			return "BUILDING"
		Category.RESOURCE:
			return "RESOURCE"
		Category.ERROR:
			return "ERROR"
		Category.WARNING:
			return "WARNING"
		Category.DEBUG:
			return "DEBUG"
		Category.PERFORMANCE:
			return "PERFORMANCE"
		_:
			return "UNKNOWN"

func _get_level_name(level: Level) -> String:
	match level:
		Level.DEBUG:
			return "DEBUG"
		Level.INFO:
			return "INFO"
		Level.WARNING:
			return "WARNING"
		Level.ERROR:
			return "ERROR"
		_:
			return "INFO"

# Main logging function (renamed from log() to avoid conflict with Godot's built-in log())
func write_log_entry(message: String, category: Category = Category.SYSTEM, level: Level = Level.INFO, details: Dictionary = {}) -> void:
	# Fast path: skip everything when no output and not an error
	if not file_logging_enabled and not console_logging_enabled and level < Level.ERROR:
		return
	
	# Early exit if logging disabled for this category
	if enabled_categories.has(category) and not enabled_categories[category]:
		return
	
	# Filter by log level
	if level < min_log_level:
		return
	
	# Rate limit to prevent lag (never throttle WARNING/ERROR)
	if _should_throttle(category, level):
		return
	
	# Build log line
	var timestamp := Time.get_datetime_string_from_system()
	var category_name: String = _get_category_name(category)
	var level_name: String = _get_level_name(level)
	
	var log_line := "[%s] [%s] [%s] %s" % [timestamp, level_name, category_name, message]
	
	# Add details if provided
	if details.size() > 0:
		var details_str := ""
		for key in details.keys():
			details_str += " %s=%s" % [key, str(details[key])]
		log_line += details_str
	
	# Console output
	if console_logging_enabled:
		print(log_line)
	elif level >= Level.ERROR:
		# Always print errors even if console logging is off
		print(log_line)
	
	# File output
	if file_logging_enabled:
		log_buffer.append(log_line + "\n")
		set_process(true)  # Ensure flush runs
		var current_time = Time.get_ticks_msec() / 1000.0
		if current_time - last_flush_time >= FLUSH_INTERVAL:
			_flush_buffer()
			last_flush_time = current_time

# Main public logging function (alias for write_log_entry)
func log(message: String, category: Category = Category.SYSTEM, level: Level = Level.INFO, details: Dictionary = {}) -> void:
	write_log_entry(message, category, level, details)

# Convenience methods
func log_info(message: String, category: Category = Category.SYSTEM, details: Dictionary = {}) -> void:
	write_log_entry(message, category, Level.INFO, details)

func log_warning(message: String, category: Category = Category.SYSTEM, details: Dictionary = {}) -> void:
	write_log_entry(message, category, Level.WARNING, details)

func log_error(message: String, category: Category = Category.SYSTEM, details: Dictionary = {}) -> void:
	write_log_entry(message, category, Level.ERROR, details)

func log_debug(message: String, category: Category = Category.SYSTEM, details: Dictionary = {}) -> void:
	write_log_entry(message, category, Level.DEBUG, details)

# Category-specific convenience methods
func log_npc(message: String, details: Dictionary = {}, level: Level = Level.INFO) -> void:
	write_log_entry(message, Category.NPC, level, details)

func log_inventory(message: String, details: Dictionary = {}, level: Level = Level.INFO) -> void:
	write_log_entry(message, Category.INVENTORY, level, details)

func log_drag_drop(message: String, details: Dictionary = {}, level: Level = Level.INFO) -> void:
	write_log_entry(message, Category.DRAG_DROP, level, details)

func log_herding(message: String, details: Dictionary = {}, level: Level = Level.INFO) -> void:
	write_log_entry(message, Category.HERDING, level, details)

func log_system(message: String, details: Dictionary = {}, level: Level = Level.INFO) -> void:
	write_log_entry(message, Category.SYSTEM, level, details)

# Backward compatibility methods (for migration period)
func write_log(message: String, level: String = "INFO") -> void:
	var log_level := Level.INFO
	match level.to_upper():
		"ERROR":
			log_level = Level.ERROR
		"WARNING":
			log_level = Level.WARNING
		"DEBUG":
			log_level = Level.DEBUG
	write_log_entry(message, Category.SYSTEM, log_level)

# Configuration methods
func set_file_logging(enabled: bool) -> void:
	set_file_logging_enabled(enabled)

func set_file_logging_enabled(enabled: bool) -> void:
	file_logging_enabled = enabled
	if enabled and not log_file:
		_open_log_file()
	elif not enabled and log_file:
		_flush_buffer()
		if log_file and log_file.is_open():
			log_file.close()
		log_file = null

func set_console_logging(enabled: bool) -> void:
	set_console_logging_enabled(enabled)

func set_console_logging_enabled(enabled: bool) -> void:
	console_logging_enabled = enabled

func set_category_enabled(category: Category, enabled: bool) -> void:
	enabled_categories[category] = enabled

func set_min_log_level(level: Level) -> void:
	min_log_level = level

# Category-specific enable/disable methods (for DebugConfig integration)
func set_verbose_npc_logging_enabled(enabled: bool) -> void:
	# Only enable NPC category when explicitly requested (avoids DEBUG flood from FSM/steering when only --log-console is on)
	enabled_categories[Category.NPC] = enabled

func set_state_transition_logging_enabled(enabled: bool) -> void:
	# State transitions are NPC category
	enabled_categories[Category.NPC] = enabled or file_logging_enabled or console_logging_enabled

func set_herd_logging_enabled(enabled: bool) -> void:
	enabled_categories[Category.HERDING] = enabled

func set_drag_drop_logging_enabled(enabled: bool) -> void:
	enabled_categories[Category.DRAG_DROP] = enabled

func _exit_tree() -> void:
	if file_logging_enabled:
		write_log_entry("=== Unified Logger Stopped ===", Category.SYSTEM, Level.INFO)
	
	if log_file:
		_flush_buffer()
		if log_file.is_open():
			log_file.flush()
		log_file.close()
		log_file = null
