extends Node

# BalanceConfig - Playtest balance values (autoload)
# Edit here for easy tuning during playtesting

# Spawn counts (1 caveman = 1v1 vs player; increase for more AI clans)
var caveman_count: int = 4
# When false, cavemen spawn alone and must find women (no boost woman+baby in claim)
var caveman_spawn_with_boost: bool = false
var woman_initial: int = 6
var sheep_initial: int = 6
var goat_initial: int = 6

# Respawn intervals (seconds)
var woman_respawn_interval_sec: float = 60.0
var sheep_goat_respawn_interval_sec: float = 60.0

# Respawn caps
var women_respawn_cap: int = 12
var sheep_respawn_cap: int = 15
var goat_respawn_cap: int = 15

# Cavemen spawn spread - wide band so clans are not clustered in center
var caveman_spawn_radius_min: float = 1800.0
var caveman_spawn_radius_max: float = 3600.0

# Wild women spawn spread - band outside inner ring so they're not grouped in center
var woman_spawn_radius_min: float = 1200.0
var woman_spawn_radius_max: float = 2800.0

# Resources and animals - spread across map
var resource_spawn_radius: float = 3200.0
var resource_min_distance: float = 1000.0
var sheep_goat_spawn_radius: float = 2200.0
var sheep_goat_group_distance_min: float = 800.0

# Starvation safety (seconds) - NPCs don't die from hunger in first N seconds after spawn
var starvation_safety_seconds: float = 20.0

# Production times (seconds)
var bread_craft_time: float = 90.0
var wool_craft_time: float = 45.0
var milk_craft_time: float = 45.0

# Food hunger restore (percent, 0-100)
var berries_hunger_percent: float = 5.0
var grain_hunger_percent: float = 7.0
var meat_hunger_percent: float = 10.0
var bread_hunger_percent: float = 15.0
var milk_hunger_percent: float = 6.0

# Hunger depletion (per minute)
var hunger_deplete_rate_per_min: float = 15.0

# Oldowan slower than specialized tools (multiplier on collection time)
var oldowan_gather_multiplier: float = 1.5

# Reproduction
var pregnancy_seconds: float = 30.0
var baby_growth_seconds: float = 35.0

# Resource cooldown
var resource_cooldown_seconds: float = 120.0
var gathers_before_cooldown: int = 3

# Gather job lease - job expires after N seconds (releases resource if NPC stalls)
var lease_expire_seconds: float = 90.0  # Extended from 60s for distant resources

# Land claim placement — one rule for player and AI (center-to-center minimum)
# Min gap between circle edges = land_claim_min_edge_gap_px; radius matches land_claim.gd default
var land_claim_radius: float = 400.0
var land_claim_min_edge_gap_px: float = 400.0  # Space between claim borders (matches build_state MIN_CLAIM_GAP)

func get_land_claim_min_center_distance() -> float:
	return 2.0 * land_claim_radius + land_claim_min_edge_gap_px

# Campfire -> Land Claim (click upgrade on building UI tile). Amounts 0 = not required.
# TESTING: 1 wood + 1 stone only. For full recipe set cordage/hide/wood/stone each to 1.
var campfire_upgrade_cordage: int = 0
var campfire_upgrade_hide: int = 0
var campfire_upgrade_wood: int = 1
var campfire_upgrade_stone: int = 1
