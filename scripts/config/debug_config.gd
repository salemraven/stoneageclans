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
## When false, --agro-combat-test and --party-test are ignored (normal game). Set true to run combat/party tests or CI.
var allow_agro_combat_test_from_cli: bool = false

# Raid test: 2 NPC clans (no follow/guard), ClanBrain initiates raids; run 60–90s, auto-quit
var enable_raid_test: bool = false

# Playtest capture for normal play: when true, instrumentor records to user://playtest_*.jsonl (no --playtest-capture needed)
var playtest_capture_always: bool = false

## Deprecated flag (no longer set by CLI). Hunts always use normal food need pressure.
var npc_only_world_hunt_stress: bool = false


# Test-only overrides (assert they never affect normal gameplay)
var test_overrides: Dictionary = {
	"allow_raid_without_player": true,  # Combat can_enter raid path when herder=leader
	"detection_range_boost": 700.0,     # Legacy enemy search range in agro combat test (raid path uses this)
	"auto_quit_seconds": 60.0,
	"raid_test_auto_quit_seconds": 90.0,  # Raid test: quit after N seconds
	"raid_cooldown_seconds": 15.0,       # Raid test: faster raid cooldown (ClanBrain uses this if set)
	# NPC party / agro combat test: wider claims, phased leaders (march -> hold -> engage)
	"agro_test_claim_distance": 1500.0,   # Half-spacing from player; total gap ~2x this (was 1000)
	"agro_test_rally_outer_px": 280.0,   # Start HOLD when leader within claim.radius + this of enemy claim center
	"agro_test_follower_avg_max": 130.0, # End HOLD early when avg follower distance to leader <= this (px)
	"agro_test_hold_timeout_sec": 12.0,  # Max time in HOLD before ENGAGE anyway
	"agro_test_hold_max_speed": 35.0,    # Cap leader speed while holding rally point
	"agro_test_enemy_seek_radius": 550.0, # Phase ENGAGE: same-clan skip; seek nearest foe within this range
	# Party/hunt debug (`--party-hunt-debug`): FSM traces + party group scan only (no gameplay cheats).
}

# Step 7: Debug viz for agro/combat (agro value, formation bubble, target lines - wire in UI when needed)
var enable_agro_combat_debug_viz: bool = false

# Individual feature flags
var enable_file_logging: bool = false  # Disabled by default - too much data
var enable_console_logging: bool = false  # Disabled by default - too much data
var enable_performance_monitoring: bool = false
var enable_debug_ui: bool = false
## ClanBrain test tools (clan camera jumper). CLI: `--godmode` or `--npc-only-world` observer runs.
var enable_godmode: bool = false
## NPCs do not agro, flee, hunt, or claim-defend against the player. Spectator / eval default.
var npcs_ignore_player: bool = false


func is_ignored_by_npcs(node: Node) -> bool:
	if not npcs_ignore_player or node == null or not is_instance_valid(node):
		return false
	return node.is_in_group("player")
## Live ClanBrain balance panel (F10). CLI: `--dev-balance`; also on with `--debug` / `--godmode`.
var enable_dev_balance_menu: bool = false
var enable_verbose_npc_logging: bool = false

func allow_gameplay_prints() -> bool:
	return enable_verbose_npc_logging or enable_debug_mode
var enable_state_transition_logging: bool = false
var enable_herd_logging: bool = false
var enable_occupation_drag_logging: bool = false  # Building occupation slot drag-and-drop debug logs
var enable_occupation_diag: bool = false  # Full occupation flow diagnostic logging (land claim, farm, dairy, women, animals)

## Hunt butcher pipeline: console lines for butcher tasks + hunt LOOTING. CLI: `--hunt-butcher-debug`
var enable_hunt_butcher_debug: bool = false

## AI party / hunt / raid stuck-debug: console FSM traces + periodic group scan. CLI: `--party-hunt-debug`
var enable_party_hunt_debug: bool = false

## Migratory wild NPC trace: spawn + throttled ticks → user://wild_npc_trace_*.jsonl. CLI: `--wild-npc-trace`
var enable_wild_npc_trace: bool = false
## Seconds between `wild_migratory_tick` lines per NPC instance.
var wild_npc_trace_interval_sec: float = 2.5

## Player starts with club (WOOD) in hotbar slot 1 instead of spear. CLI: `--start-club`
var enable_start_club: bool = false
## Player starts with a stone stack in hotbar slot 1. CLI: `--start-stone`
var enable_start_stone: bool = false
var start_stone_count: int = 10
## Player starts with a land-claim flag instead of a campfire. CLI: `--start-landclaim`
var enable_start_landclaim: bool = false
## Draw throw land circle + THROW_HIT/WHIFF logs. CLI: `--throw-debug`
var enable_throw_debug: bool = false

## Session / productivity instruments (main.gd, FSM, task_runner, player herd debuff).
var enable_session_quickstart: bool = false
## Spawn N AI caveman+claim clans in a ring around the player on a normal start (not harnesses). CLI: `--eval-ai-claims` / `--eval-ai-claims 0` to off.
var eval_ai_claims_near_start: int = 0
## Wild women in a ring around player spawn so you can see female mannequins. CLI: `--eval-wild-women N`
var eval_wild_women_near_start: int = 0
## Ring of pawns at 240px: one of each hair style, cycling colors. CLI: `--eval-hair N`
var eval_hair_gallery_count: int = 0
## Two clansmen in front of the player: max vs min body height. CLI: `--eval-height`
var enable_eval_height_pair: bool = false
## Two clansmen: max vs min body width, mid height. CLI: `--eval-width`
var enable_eval_width_pair: bool = false
## Four women: tall/short/wide/narrow. CLI: `--eval-women`
var enable_eval_women_build: bool = false
## Adult mid clansman + four babies. CLI: `--eval-babies`
var enable_eval_babies: bool = false
## Temporary eval camp: player claim + 2 huts + food, 3 AI cavemen, 8 women. CLI: `--eval-camp`
var enable_eval_camp: bool = false
## Spectator: 4 AI clans (claim + 2 huts + 2 women + spear/stones). CLI: `--eval-ai-arena`
var enable_eval_ai_arena: bool = false
## Two AI clans, no player fight. CLI: `--ai-combat-observe`
var enable_ai_combat_observe: bool = false
## Place one enemy man inside the other claim. CLI: `--ai-village-probe`
var enable_ai_village_probe: bool = false
## One clan raids the other. No deer. CLI: `--ai-raid-probe`
var enable_ai_raid_probe: bool = false
var eval_ai_arena_clan_count: int = 4
## Extra cavemen per AI claim in the arena (leader already spawned). 5 extras = 6-man parties.
var eval_ai_arena_extra_fighters: int = 5
## Print SKIN_GENE lines for founders/births. CLI: `--skin-genes`
var enable_skin_gene_log: bool = false
## Spawn N AI caveman+claim clans in a ring around the player (session quickstart). CLI: `--session-nearby-clans` or `--session-nearby-clans 4`
var session_nearby_clans_count: int = 0
## Auto-teleport player to each nearby AI claim then away (collect dormant/tick JSONL). CLI: `--session-ai-clan-tour`
var session_ai_clan_tour: bool = false
## Seconds to wait far from claims after tour visits (off-screen settlement ticks). CLI: `--session-ai-clan-tour-away-sec N`
var session_ai_clan_tour_away_sec: float = 45.0
## When true, player stays far until session quit (no return home). CLI: `--session-ai-clan-tour-stay-away`
var session_ai_clan_tour_stay_away: bool = false
var session_quit_after_seconds: float = 0.0
var enable_session_instrumentation: bool = false
## Periodic worker snapshots (clansmen/cavemen job + FSM histogram) → JSONL when playtest capture is on.
var enable_npc_productivity_snapshots: bool = false
var npc_productivity_snapshot_interval_sec: float = 30.0
var enable_agro_session_logs: bool = false
var disable_herd_leader_speed_debuff: bool = false

## Movement debug samples (MovementDebugInstrument reads via .get — must exist to avoid cast errors).
var enable_movement_debug: bool = false
var movement_debug_interval_sec: float = 0.5
var movement_debug_filter: String = "clansman"

## Procedural arm IK debug markers (shoulder/elbow/hand). CLI: `--arms-debug`; F9 toggles in-game.
var enable_procedural_arms_debug: bool = false

## Lag root-cause profiler → user://lag_profile_*.jsonl. CLI: `--lag-profile`
var enable_lag_profiling: bool = false
var lag_profile_interval_sec: float = 1.0
var lag_profile_spike_ms: float = 20.0

# Performance monitoring settings
var performance_log_interval: float = 1.0  # Log performance stats every N seconds
var frame_time_warning_threshold: float = 16.67  # Warn if frame time exceeds this (ms) - 60 FPS threshold

func _ready() -> void:
	_parse_command_line_args()
	_apply_debug_settings()

func _parse_command_line_args() -> void:
	if OS.get_name() == "Web":
		var search: String = ""
		if typeof(JavaScriptBridge) != TYPE_NIL:
			var raw: Variant = JavaScriptBridge.eval("window.location.search", true)
			if raw != null:
				search = str(raw)
		if search.contains("lag_profile=1") or search.contains("lag-profile=1"):
			enable_lag_profiling = true
			print("✓ Lag profiler enabled (Web URL param)")
		return
	# User args (after --) need get_cmdline_user_args; engine args need get_cmdline_args
	var args: PackedStringArray = OS.get_cmdline_args()
	var user_args = OS.get_cmdline_user_args()
	for a in user_args:
		if a not in args:
			args.append(a)
	
	# Check for --debug or --verbose flags (enable full debug mode)
	if "--debug" in args or "--verbose" in args:
		enable_debug_mode = true
		enable_dev_balance_menu = true
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

	if "--lag-profile" in args:
		enable_lag_profiling = true
		print("✓ Lag profiler enabled (user://lag_profile_*.jsonl; analyze with tools/analyze_lag_profile.gd)")
	
	# Headless implies debug mode for automated testing
	if "--headless" in args:
		enable_debug_mode = true
		enable_file_logging = true
		enable_console_logging = true  # Enable console logging for headless tests
		enable_performance_monitoring = true
		enable_verbose_npc_logging = true
		enable_state_transition_logging = true
		enable_occupation_drag_logging = true
		print("✓ Headless debug mode enabled")

	# Session instrumentation: SESSION + MOVEMENT logs to user://game_logs.txt
	if "--session-instrument" in args:
		enable_session_instrumentation = true
		enable_file_logging = true
		enable_movement_debug = true
		movement_debug_filter = "woman,clansman"
		print("✓ Session instrumentation enabled (SESSION + MOVEMENT)")
		if "--session-quickstart" in args:
			print("✓ Phase 7 JSONL auto-enabled (playtest_*.jsonl + [PHASE7] console tags)")

	if "--eval-height" in args:
		enable_eval_height_pair = true
		eval_hair_gallery_count = 0
		eval_wild_women_near_start = 0
		eval_ai_claims_near_start = 0
		print("✓ Eval height pair: tallest + shortest clansmen in front of player")

	if "--eval-width" in args:
		enable_eval_width_pair = true
		eval_hair_gallery_count = 0
		eval_wild_women_near_start = 0
		eval_ai_claims_near_start = 0
		print("✓ Eval width pair: widest + narrowest clansmen in front of player")

	if "--eval-women" in args:
		enable_eval_women_build = true
		eval_hair_gallery_count = 0
		eval_wild_women_near_start = 0
		eval_ai_claims_near_start = 0
		print("✓ Eval women build: tall/short/wide/narrow in front of player")

	if "--eval-babies" in args:
		enable_eval_babies = true
		eval_hair_gallery_count = 0
		eval_wild_women_near_start = 0
		eval_ai_claims_near_start = 0
		print("✓ Eval babies: adult mid + tall/short/wide/narrow babies")

	if "--eval-camp" in args:
		enable_eval_camp = true
		eval_hair_gallery_count = 0
		eval_wild_women_near_start = 0
		eval_ai_claims_near_start = 0
		if BalanceConfig:
			BalanceConfig.ai_use_dev_food_bootstrap = true
		var wgc: Node = get_node_or_null("/root/WorldGenConfig")
		if wgc:
			wgc.wild_woman_chunk_chance = 0.45
			wgc.wild_woman_per_chunk_max = 3
		print("✓ Eval camp: player claim + 2 huts + food; 3 AI cavemen; 8 women; wilderness wild women + denser chunk women")

	if "--ai-raid-probe" in args:
		enable_ai_raid_probe = true
		enable_ai_combat_observe = true
		print("✓ AI raid probe: one clan will march on the other, no deer")

	if "--ai-village-probe" in args:
		enable_ai_village_probe = true
		print("✓ AI village probe: one enemy man will be placed inside the other claim")

	if "--ai-combat-observe" in args or enable_ai_raid_probe:
		enable_ai_combat_observe = true
		eval_hair_gallery_count = 0
		eval_wild_women_near_start = 0
		eval_ai_claims_near_start = 0
		if BalanceConfig:
			BalanceConfig.ai_use_dev_food_bootstrap = true
		npcs_ignore_player = true
		playtest_capture_always = true
		enable_herd_logging = true
		enable_file_logging = true
		enable_session_instrumentation = true
		enable_npc_productivity_snapshots = true
		npc_productivity_snapshot_interval_sec = 10.0
		print("✓ AI combat observe: 2 clans, 5 fighters + 2 women each, deer outside camp, player hidden")
		print("✓ NPCs ignore the player. CLAN_COMBAT lines print while a clan is hunting, raiding, or fighting.")

	if "--eval-ai-arena" in args:
		enable_eval_ai_arena = true
		enable_godmode = true
		eval_hair_gallery_count = 0
		eval_wild_women_near_start = 0
		eval_ai_claims_near_start = 0
		if BalanceConfig:
			BalanceConfig.ai_use_dev_food_bootstrap = true
		npcs_ignore_player = true
		playtest_capture_always = true
		enable_herd_logging = true
		enable_file_logging = true
		enable_session_instrumentation = true
		enable_npc_productivity_snapshots = true
		npc_productivity_snapshot_interval_sec = 10.0
		print("✓ Eval AI arena: player + 4 AI clans (claim, 2 huts, 2 women, 6 fighters, spear + stones)")
		print("✓ NPCs ignore the player (spectator)")
		print("✓ Eval behavior JSONL capture on")

	for i in range(args.size()):
		if args[i] == "--eval-behavior-sec" and i + 1 < args.size():
			session_quit_after_seconds = maxf(float(args[i + 1]), 5.0)
			print("✓ Eval behavior auto-quit after %.0fs" % session_quit_after_seconds)
			break

	# Session quickstart: player claim + 2 women + 2 Living Huts (reproduction smoke)
	if "--session-quickstart" in args:
		enable_session_quickstart = true
		if BalanceConfig:
			BalanceConfig.ai_use_dev_food_bootstrap = true
		print("✓ Session quickstart enabled (claim + women + Living Huts; dev AI food bootstrap)")

	if "--ai-dev-food-bootstrap" in args:
		if BalanceConfig:
			BalanceConfig.ai_use_dev_food_bootstrap = true
		print("✓ AI dev food bootstrap enabled (ai_claim_starting_food_berries_dev)")

	for i in range(args.size()):
		if args[i] == "--eval-ai-claims":
			var n_eval: int = 3
			if i + 1 < args.size():
				var next_eval: String = str(args[i + 1])
				if next_eval.is_valid_int():
					n_eval = maxi(int(next_eval), 0)
			eval_ai_claims_near_start = n_eval
			print("✓ Eval AI land claims near start: %d" % n_eval)
			break

	for i in range(args.size()):
		if args[i] == "--eval-wild-women":
			var n_w: int = 6
			if i + 1 < args.size():
				var next_w: String = str(args[i + 1])
				if next_w.is_valid_int():
					n_w = maxi(int(next_w), 0)
			eval_wild_women_near_start = n_w
			print("✓ Eval wild women near start: %d" % n_w)
			break

	for i in range(args.size()):
		if args[i] == "--eval-hair":
			var n_h: int = 15
			if i + 1 < args.size():
				var next_h: String = str(args[i + 1])
				if next_h.is_valid_int():
					n_h = maxi(int(next_h), 0)
			eval_hair_gallery_count = n_h
			print("✓ Eval hair gallery near start: %d" % n_h)
			break

	for i in range(args.size()):
		if args[i] == "--session-nearby-clans":
			var n: int = 3
			if i + 1 < args.size():
				var next_arg: String = str(args[i + 1])
				if next_arg.is_valid_int():
					n = maxi(int(next_arg), 1)
			session_nearby_clans_count = n
			print("✓ Session nearby AI clans: %d (ring around player; use with --session-quickstart)" % n)
			break

	if "--session-ai-clan-tour" in args:
		session_ai_clan_tour = true
		print("✓ Session AI clan tour: auto-visit nearby claims for settlement sim data")

	for i in range(args.size()):
		if args[i] == "--session-ai-clan-tour-away-sec" and i + 1 < args.size():
			session_ai_clan_tour_away_sec = maxf(float(args[i + 1]), 5.0)
			print("✓ Session AI clan tour away: %.0fs off-screen" % session_ai_clan_tour_away_sec)
			break

	if "--session-ai-clan-tour-stay-away" in args:
		session_ai_clan_tour_stay_away = true
		print("✓ Session AI clan tour: stay away until session quit (no return home)")

	# Woman transport test: only player, land claim + ovens + 2 women (no cavemen)
	if "--woman-test" in args:
		enable_woman_transport_test = true
		print("✓ Woman transport test mode (player only, no cavemen)")

	# Agro/combat test: 2 clans x 10 (1 leader + 9 followers), clubs, follow, 2 claims
	if "--agro-combat-test" in args:
		if allow_agro_combat_test_from_cli:
			enable_agro_combat_test = true
			print("✓ Agro/combat test mode (2 clans x 10, 1 leader + 9 followers, clubs)")
		else:
			print("✓ --agro-combat-test ignored (set DebugConfig.allow_agro_combat_test_from_cli = true to enable)")

	# Party test: same world as agro combat test; use with --playtest-capture for party_formation_tick / NPC-led party JSONL
	if "--party-test" in args:
		if allow_agro_combat_test_from_cli:
			enable_agro_combat_test = true
			print("✓ Party test mode (NPC party formations — same setup as agro combat test)")
		else:
			print("✓ --party-test ignored (set DebugConfig.allow_agro_combat_test_from_cli = true to enable)")

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
		enable_session_instrumentation = true
		enable_npc_productivity_snapshots = true
		print("✓ Playtest capture enabled (user://playtest_*.jsonl + worker JSONL instruments)")

	# Timed playtests: disable herd resistance for deterministic transport validation
	if "--playtest-2min" in args or "--playtest-4min" in args or "--playtest-5min" in args or "--playtest-10min" in args or "--playtest-15min" in args or "--playtest-30min" in args:
		test_overrides["herd_resist_disabled"] = true
		print("✓ Herd resistance disabled for playtest (deterministic transport)")
	if "--playtest-10min" in args or "--playtest-15min" in args or "--playtest-30min" in args:
		npc_productivity_snapshot_interval_sec = 30.0

	for i in range(args.size()):
		if args[i] == "--session-quit-after" and i + 1 < args.size():
			session_quit_after_seconds = float(args[i + 1])
			print("✓ Session auto-quit after %.0fs" % session_quit_after_seconds)
			break

	if "--wild-npc-trace" in args:
		enable_wild_npc_trace = true
		print("✓ Wild NPC trace: spawn + migratory ticks → user://wild_npc_trace_*.jsonl (WildNpcTrace.trace)")

	if "--hunt-butcher-debug" in args:
		enable_hunt_butcher_debug = true
		print("✓ Hunt butcher debug: extra console logs for butcher / LOOTING")

	if "--party-hunt-debug" in args:
		enable_party_hunt_debug = true
		print("✓ Party/hunt debug enabled (FSM traces + test deer seeded in AoH rings)")

	if "--arms-debug" in args:
		enable_procedural_arms_debug = true
		print("✓ Procedural arms debug markers enabled (F9 toggles in-game)")

	if "--npcs-ignore-player" in args:
		npcs_ignore_player = true
		print("✓ NPCs ignore the player")
	if "--npcs-see-player" in args:
		npcs_ignore_player = false
		print("✓ NPCs can see the player")

	if "--godmode" in args:
		enable_godmode = true
		enable_dev_balance_menu = true
		if "--npcs-see-player" not in args:
			npcs_ignore_player = true
		print("✓ ClanBrain godmode: clan camera jumper (top-right)")
		if npcs_ignore_player:
			print("✓ NPCs ignore the player (spectator)")

	if "--dev-balance" in args:
		enable_dev_balance_menu = true
		print("✓ Dev balance menu enabled (F10 toggles ClanBrain tuning panel)")

	if "--skin-genes" in args:
		enable_skin_gene_log = true
		print("✓ Skin gene console log (SKIN_GENE founder/birth)")

	if "--player-move-debug" in args:
		print("✓ Player movement debug overlay will auto-enable (F8 to toggle)")

	if "--movement-stress-test" in args:
		print("✓ Movement stress test will run after boot (auto quit)")

	if "--start-club" in args:
		enable_start_club = true
		print("✓ Start club: hotbar slot 1 = WOOD (club overlay + pivot swing)")

	if "--start-stone" in args:
		enable_start_stone = true
		print("✓ Start stone: hotbar slot 2 stack size = STONE x%d" % start_stone_count)

	if "--start-landclaim" in args:
		enable_start_landclaim = true
		print("✓ Start land-claim flag in inventory (no campfire)")

	if "--throw-debug" in args:
		enable_throw_debug = true
		print("✓ Throw debug: land circle + THROW_HIT/WHIFF logs")

	if "--hair2" in args:
		CharacterCardPartsRegistry.set_runtime_hair_texture_path(CharacterCardPartsRegistry.HAIR2_PATH)
		print("✓ Hair preview: 02hair.png (same attach pivot for all styles)")
	elif "--hair1" in args:
		CharacterCardPartsRegistry.set_runtime_hair_texture_path(CharacterCardPartsRegistry.HAIR1_PATH)
		print("✓ Hair preview: 01hair.png")

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
