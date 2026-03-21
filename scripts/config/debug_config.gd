extends Node

# Centralized debug configuration system
# Controls all debug features and logging behavior
# Can be set via command line arguments or programmatically

# Master switch - when false, disables all debug features
var enable_debug_mode: bool = false

# Woman transport test: only player + land claim + ovens + 2 women (no cavemen)
var enable_woman_transport_test: bool = false

# Agro/combat test: 2 clans x 10 clansmen (1 leader + 9 followers), clubs, follow, 2 claims; leaders walk toward each other → combat
var enable_agro_combat_test: bool = false

# Raid test: 2 NPC clans (no follow/guard), ClanBrain initiates raids; run 60–90s, auto-quit
var enable_raid_test: bool = false

# Playtest capture for normal play: when true, instrumentor records to user://playtest_*.jsonl (no --playtest-capture needed)
var playtest_capture_always: bool = false

# Test-only overrides (assert they never affect normal gameplay)
var test_overrides: Dictionary = {
	"allow_raid_without_player": true,  # Combat can_enter raid path when herder=leader
	"detection_range_boost": 700.0,     # Legacy enemy search range in agro combat test (raid path uses this)
	"auto_quit_seconds": 60.0,
	"raid_test_auto_quit_seconds": 90.0,  # Raid test: quit after N seconds
	"raid_cooldown_seconds": 15.0        # Raid test: faster raid cooldown (ClanBrain uses this if set)
}

# Step 7: Debug viz for agro/combat (agro value, formation bubble, target lines - wire in UI when needed)
var enable_agro_combat_debug_viz: bool = false

# Individual feature flags
var enable_file_logging: bool = false  # Disabled by default - too much data
var enable_console_logging: bool = false  # Disabled by default - too much data
var enable_performance_monitoring: bool = false
var enable_debug_ui: bool = false
var enable_verbose_npc_logging: bool = false
var enable_state_transition_logging: bool = false
var enable_herd_logging: bool = false
var enable_occupation_drag_logging: bool = false  # Building occupation slot drag-and-drop debug logs
var enable_occupation_diag: bool = false  # Full occupation flow diagnostic logging (land claim, farm, dairy, women, animals)

# Performance monitoring settings
var performance_log_interval: float = 1.0  # Log performance stats every N seconds
var frame_time_warning_threshold: float = 16.67  # Warn if frame time exceeds this (ms) - 60 FPS threshold

func _ready() -> void:
	_parse_command_line_args()
	_apply_debug_settings()

func _parse_command_line_args() -> void:
	# User args (after --) need get_cmdline_user_args; engine args need get_cmdline_args
	var args: PackedStringArray = OS.get_cmdline_args()
	var user_args = OS.get_cmdline_user_args()
	for a in user_args:
		if a not in args:
			args.append(a)
	
	# Check for --debug or --verbose flags (enable full debug mode)
	if "--debug" in args or "--verbose" in args:
		enable_debug_mode = true
		enable_file_logging = true
		enable_console_logging = true
		enable_performance_monitoring = true
		enable_verbose_npc_logging = true
		enable_state_transition_logging = true
		enable_herd_logging = true
		enable_occupation_drag_logging = true
		print("✓ Debug mode enabled via command line")
	
	# Check for --log-file flag (file logging only)
	if "--log-file" in args:
		enable_file_logging = true
		print("✓ File logging enabled")
	
	# Check for --log-console flag (console logging only)
	if "--log-console" in args:
		enable_console_logging = true
		print("✓ Console logging enabled")
	
	# Check for --performance flag (performance monitoring only)
	if "--performance" in args:
		enable_performance_monitoring = true
		print("✓ Performance monitoring enabled")
	
	# Check for --headless flag (implies debug mode for automated testing)
	if "--headless" in args:
		enable_debug_mode = true
		enable_file_logging = true
		enable_console_logging = true  # Enable console logging for headless tests
		enable_performance_monitoring = true
		enable_verbose_npc_logging = true
		enable_state_transition_logging = true
		enable_occupation_drag_logging = true
		print("✓ Headless debug mode enabled")

	# Woman transport test: only player, land claim + ovens + 2 women (no cavemen)
	if "--woman-test" in args:
		enable_woman_transport_test = true
		print("✓ Woman transport test mode (player only, no cavemen)")

	# Agro/combat test: 2 clans x 10 (1 leader + 9 followers), clubs, follow, 2 claims
	if "--agro-combat-test" in args:
		enable_agro_combat_test = true
		print("✓ Agro/combat test mode (2 clans x 10, 1 leader + 9 followers, clubs)")

	# Raid test: 2 NPC clans, no follow/guard, ClanBrain raids; auto-quit after 90s
	if "--raid-test" in args:
		enable_raid_test = true
		print("✓ Raid test mode (2 clans: raider 8–10, target 3–4; ClanBrain initiates raids)")

	# Occupation diagnostic: log land claim, farm, dairy placement + women/animal occupy flow
	if "--occupation-diag" in args:
		enable_occupation_diag = true
		print("✓ Occupation diagnostic logging enabled (Tests/occupation_diag_*.log)")

	# Playtest capture: structured herding/FSM events to user://playtest_*.jsonl
	if "--playtest-capture" in args or "--herd-capture" in args:
		enable_herd_logging = true
		enable_file_logging = true
		print("✓ Playtest capture enabled (user://playtest_*.jsonl)")

	# Timed playtests: disable herd resistance for deterministic transport validation
	if "--playtest-2min" in args or "--playtest-4min" in args:
		test_overrides["herd_resist_disabled"] = true
		print("✓ Herd resistance disabled for playtest (deterministic transport)")

func _apply_debug_settings() -> void:
	# Apply settings to UnifiedLogger if it exists
	if has_node("/root/UnifiedLogger"):
		var unified_logger = get_node("/root/UnifiedLogger")
		unified_logger.set_file_logging_enabled(enable_file_logging)
		unified_logger.set_console_logging_enabled(enable_console_logging)
		unified_logger.set_verbose_npc_logging_enabled(enable_verbose_npc_logging)
		unified_logger.set_state_transition_logging_enabled(enable_state_transition_logging)
		unified_logger.set_herd_logging_enabled(enable_herd_logging)
		unified_logger.set_drag_drop_logging_enabled(enable_debug_mode or enable_occupation_drag_logging)
		if enable_debug_mode or enable_verbose_npc_logging or enable_agro_combat_test:
			unified_logger.set_min_log_level(UnifiedLogger.Level.DEBUG)
		else:
			# Default: only show WARNING and ERROR, filter out DEBUG and INFO
			unified_logger.set_min_log_level(UnifiedLogger.Level.WARNING)
		print("✓ UnifiedLogger settings applied from DebugConfig")
	else:
		print("WARNING: UnifiedLogger not found, cannot apply settings from DebugConfig")

	# Occupation diagnostic logger
	if enable_occupation_diag and has_node("/root/OccupationDiagLogger"):
		get_node("/root/OccupationDiagLogger").enable()

# Helper function to check if any logging is enabled
func is_logging_enabled() -> bool:
	return enable_file_logging or enable_console_logging

# Helper function to check if debug mode is fully enabled
func is_debug_mode() -> bool:
	return enable_debug_mode
