extends Node

# BalanceConfig - Playtest balance values (autoload)
# Edit here for easy tuning during playtesting

# Spawn counts (1 caveman = 1v1 vs player; increase for more AI clans)
var caveman_count: int = 4
# When false, cavemen spawn alone and must find women (no boost woman+baby in claim)
var caveman_spawn_with_boost: bool = false
var woman_initial: int = 12
var sheep_initial: int = 3
var goat_initial: int = 3
var deer_initial: int = 4

# Respawn intervals (seconds)
var woman_respawn_interval_sec: float = 60.0
var sheep_goat_respawn_interval_sec: float = 60.0

# Respawn caps
var women_respawn_cap: int = 12
var sheep_respawn_cap: int = 15
var goat_respawn_cap: int = 15
var deer_respawn_cap: int = 12

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
var starvation_safety_seconds: float = 45.0

# --- Hunger (game mode — BalanceConfig is source of truth; NPCConfig syncs in _ready) ---
## Hunger points lost per real minute (100 max ≈ 10 min from full to empty at 10/min).
var hunger_deplete_rate_per_min: float = 10.0
var hunger_start_percent: float = 85.0
var hunger_eat_threshold_percent: float = 80.0
var hunger_gather_threshold_percent: float = 80.0
## When hunger hits 0, health drains until death (~50s at 2/min from full HP).
var hunger_health_drain_per_min: float = 2.0
## Vitals bar color thresholds (0-1 fill ratio).
var vitals_bar_yellow_above: float = 0.65
var vitals_bar_red_above: float = 0.25
## Player combat HP (HealthComponent on Player.tscn).
var player_max_health: int = 100
## Hydration placeholder until water sim exists (0-100%).
var hydration_start_percent: float = 100.0
## AI clan members spawn with full hunger (player uses hunger_start_percent above).
var ai_hunger_start_percent: float = 100.0

# --- Simulation economy (ClanBrain food_days_buffer + deposit/eat/breed gates) ---
## One instrumented playtest window (e.g. 10 min) ≈ one sim "day" for buffer labels.
var sim_day_length_minutes: float = 10.0
## Food items one clan member consumes per sim-day (aligns buffer math with hunger loop).
var food_items_per_capita_per_sim_day: float = 5.0
## Target / critical buffers (sim-days of food in claim storage).
var clan_food_buffer_target_days: float = 1.0
var clan_food_buffer_critical_days: float = 0.5
## New pregnancies only when claim buffer ≥ this (reduces pop outpacing food).
var reproduction_min_food_buffer_days: float = 0.28
## Early clans with this many food items in claim may breed below min buffer (keeps pop growing).
var reproduction_food_items_bypass_min: int = 3
## If designated herder-father stays outside claim this long, woman may pick in-claim mate.
var reproduction_father_absent_fallback_sec: float = 90.0
## Personal food kept on auto-deposit when claim is well stocked.
var deposit_food_keep_default: int = 1
## Below this claim buffer, deposit ALL food (keep 0 for personal snacking).
var deposit_zero_food_keep_buffer_days: float = 0.75
## Allow 1-fighter hunt parties when food buffer is critical (early clans with one caveman).
## Default false — hunts need a full party (see NPCConfig.hunt_party_min_size, usually 2+).
var hunt_allow_solo_when_food_critical: bool = false
## Solo hunts also allowed when buffer drops below this (sim-days), before full critical.
var hunt_solo_food_buffer_days: float = 0.15
## AI land claims start with this many berries in storage (bootstrap breeding; player claims unchanged).
var ai_claim_starting_food_berries: int = 5
## Herders deposit all personal food until claim food count reaches this (matches repro bypass min).
var claim_food_bootstrap_min_items: int = 3
## Berries storage target in claim = max(min, population × this).
var berries_storage_target_min: int = 8
var berries_storage_target_per_capita: float = 0.45

# Food hunger restore (percent of max hunger, 0-100)
var berries_hunger_percent: float = 8.0
var grain_hunger_percent: float = 10.0
var meat_hunger_percent: float = 18.0
var cooked_meat_hunger_percent: float = 24.0
var bread_hunger_percent: float = 22.0
var milk_hunger_percent: float = 10.0
var mushroom_hunger_percent: float = 8.0
var bugs_hunger_percent: float = 6.0
var nuts_hunger_percent: float = 9.0

# --- Calorie system (kcal) — source of truth for food economy ---
var berries_calories: int = 40
var grain_calories: int = 60
var fiber_calories: int = 20
var meat_calories: int = 250
var bread_calories: int = 300
var cooked_meat_calories: int = 320
var milk_calories: int = 100
var mushroom_calories: int = 30
var bugs_calories: int = 25
var nuts_calories: int = 80

var base_daily_calories_caveman: int = 2200
var base_daily_calories_clansman: int = 2200
var base_daily_calories_woman: int = 1800
var base_daily_calories_baby: int = 720
var base_daily_calories_player: int = 2000

var pregnancy_calorie_multiplier: float = 1.35
var strength_calorie_modifier: float = 0.10
var intelligence_calorie_modifier: float = 0.05

var farm_daily_calories_per_sheep: int = 600
var dairy_daily_calories_per_goat: int = 650
var animal_building_calories_max: float = 5000.0

## Herbivore feed types (dev-tunable): grain and/or fiber from building stockpile.
var herbivore_feed_types: Array[int] = [
	ResourceData.ResourceType.FIBER,
	ResourceData.ResourceType.GRAIN,
]

var simulation_tick_interval_seconds: float = 120.0
var simulation_ticks_per_sim_day: int = 5

# Production times (seconds)
var bread_craft_time: float = 90.0
var wool_craft_time: float = 45.0
var milk_craft_time: float = 45.0

# --- Production economy (ClanBrain allocation) ---
var abundance_threshold: float = 2.5
var safety_buffer_days: float = 0.5
var allocation_eval_interval: int = 3
var work_request_expire_seconds: float = 90.0
var daily_need_grain_per_capita: float = 2.0
var daily_need_wood_per_capita: float = 2.0
var daily_need_hide_per_capita: float = 0.5
var campfire_cooking_interval: float = 30.0
var drying_rack_process_time: float = 120.0

# Oldowan slower than specialized tools (multiplier on collection time)
var oldowan_gather_multiplier: float = 1.5

# Reproduction (2x speed vs prior playtest defaults for faster iteration)
var pregnancy_seconds: float = 15.0
var baby_growth_seconds: float = 17.5
var birth_cooldown_seconds: float = 10.0  # Min time after birth before next pregnancy

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

# Building storage (campfire / land claim inventories — tuned in one place)
var campfire_inventory_slots: int = 20
var campfire_inventory_max_stack: int = 999
var land_claim_inventory_slots: int = 40
var land_claim_inventory_max_stack: int = 999999

# Campfire -> Land Claim (click upgrade on building UI tile). Amounts 0 = not required.
# TESTING: 1 wood + 1 stone only. For full recipe set cordage/hide/wood/stone each to 1.
var campfire_upgrade_cordage: int = 0
var campfire_upgrade_hide: int = 0
var campfire_upgrade_wood: int = 1
var campfire_upgrade_stone: int = 1

# --- Stage 1 nomadic campfire / Nomad Mode ---
var campfire_wood_burn_interval: float = 60.0
var campfire_panic_threshold_wood: int = 0
var campfire_panic_threshold_food: int = 0
var campfire_building_grace_period: float = 60.0
var campfire_max_living_huts: int = 3
var nomad_formation_spacing: float = 45.0
var ai_nomad_wood_threshold: int = 2
var ai_nomad_food_threshold: int = 3
var nomad_cooldown_sec: float = 30.0
var ai_nomad_low_resource_sec: float = 60.0
var ai_nomad_reloc_min_dist: float = 800.0
var ai_nomad_reloc_max_dist: float = 1500.0
var ai_nomad_arrival_radius: float = 50.0

# --- AI milestone buildings (ClanBrain auto-building triggers) ---
## Oven: built when claim has this much GRAIN (not stone). Changed from stone >= 10 to grain-based.
var milestone_oven_min_grain: int = 1
## Drying rack: built when claim has this many HIDE.
var milestone_drying_rack_min_hide: int = 3
## Farm: built when clan has this many SHEEP (lowered from 3 to enable earlier farms).
var milestone_farm_min_sheep: int = 1
## Dairy: built when clan has this many GOATS (lowered from 3 to enable earlier dairies).
var milestone_dairy_min_goats: int = 1
## Living hut: built when clan has this many BABIES.
var milestone_living_hut_min_babies: int = 2
## Duration (seconds) for a clansman to visibly construct an AI milestone building.
var ai_milestone_build_duration_sec: float = 18.0


func _ready() -> void:
	apply_hunger_game_mode()
	apply_economy_sim()


func get_sim_ticks_per_day() -> int:
	return maxi(1, simulation_ticks_per_sim_day)


func get_food_calories(resource_type: ResourceData.ResourceType) -> int:
	match resource_type:
		ResourceData.ResourceType.BERRIES:
			return berries_calories
		ResourceData.ResourceType.GRAIN:
			return grain_calories
		ResourceData.ResourceType.FIBER:
			return fiber_calories
		ResourceData.ResourceType.MEAT:
			return meat_calories
		ResourceData.ResourceType.COOKED_MEAT:
			return cooked_meat_calories
		ResourceData.ResourceType.BREAD:
			return bread_calories
		ResourceData.ResourceType.MILK:
			return milk_calories
		ResourceData.ResourceType.MUSHROOM:
			return mushroom_calories
		ResourceData.ResourceType.BUGS:
			return bugs_calories
		ResourceData.ResourceType.NUTS:
			return nuts_calories
		_:
			return 0


func get_base_daily_calories(npc_type: String) -> int:
	match npc_type:
		"caveman":
			return base_daily_calories_caveman
		"clansman":
			return base_daily_calories_clansman
		"woman":
			return base_daily_calories_woman
		"baby":
			return base_daily_calories_baby
		"player":
			return base_daily_calories_player
		_:
			return 2000


func format_calories_short(cal: int) -> String:
	if cal >= 1000:
		return "%.1fk" % (float(cal) / 1000.0)
	return str(cal)


func get_hunger_percent_from_calories(calories: float, calories_max: float) -> float:
	if calories_max <= 0.0:
		return 0.0
	return clampf((calories / calories_max) * 100.0, 0.0, 100.0)


func get_calories_from_hunger_percent(hunger_percent: float, calories_max: float) -> float:
	return clampf(hunger_percent / 100.0, 0.0, 1.0) * calories_max


## Push hunger/food tuning into NPCConfig so one file (here) drives gameplay.
func apply_hunger_game_mode() -> void:
	if not NPCConfig:
		return
	NPCConfig.hunger_deplete_rate = hunger_deplete_rate_per_min
	NPCConfig.hunger_start_percent = hunger_start_percent
	NPCConfig.hunger_eat_threshold = hunger_eat_threshold_percent
	NPCConfig.hunger_gather_threshold = hunger_gather_threshold_percent
	NPCConfig.hunger_restore_percent = berries_hunger_percent
	NPCConfig.food_items_to_keep_in_inventory = deposit_food_keep_default


## Expose economy helpers for ClanBrain + NPC deposit/eat paths.
func get_food_per_capita_per_sim_day() -> float:
	return maxf(food_items_per_capita_per_sim_day, 0.5)


func get_deposit_food_keep_count(claim_food_days_buffer: float, claim_food_total: int = 9999) -> int:
	var bootstrap_min: int = maxi(1, claim_food_bootstrap_min_items)
	if claim_food_total < bootstrap_min:
		return 0
	if claim_food_days_buffer < deposit_zero_food_keep_buffer_days:
		return 0
	if claim_food_days_buffer < clan_food_buffer_critical_days:
		return 0
	return maxi(0, deposit_food_keep_default)


## Put starting food in a non-player land claim inventory (AI bootstrap).
func seed_ai_claim_starting_food(claim_inventory: InventoryData) -> void:
	if not claim_inventory or ai_claim_starting_food_berries <= 0:
		return
	claim_inventory.add_item(ResourceData.ResourceType.BERRIES, ai_claim_starting_food_berries)


func get_berries_storage_target(population: int) -> int:
	var pop: int = maxi(1, population)
	return maxi(berries_storage_target_min, int(ceil(float(pop) * berries_storage_target_per_capita)))


func apply_economy_sim() -> void:
	if not NPCConfig:
		return
	NPCConfig.food_items_to_keep_in_inventory = deposit_food_keep_default


func get_food_hunger_restore_percent(resource_type: ResourceData.ResourceType) -> float:
	# Derived from calorie values when possible (backward compat for legacy hunger UI).
	var cal: int = get_food_calories(resource_type)
	if cal <= 0:
		return 0.0
	var ref_daily: float = float(base_daily_calories_caveman)
	if ref_daily <= 0.0:
		ref_daily = 2200.0
	return clampf((float(cal) / ref_daily) * 100.0, 0.0, 100.0)

