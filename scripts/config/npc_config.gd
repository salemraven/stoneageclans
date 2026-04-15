extends Node
# NPC Configuration File
# This is an autoload singleton - access via NPCConfig in scripts
# Edit the values below to adjust NPC behavior
# This file is automatically loaded as a singleton (autoload)
# After editing, restart the game or reload the scene for changes to take effect

# ============================================
# HUNGER SYSTEM
# ============================================
@export_group("Hunger System")
@export var hunger_gather_threshold: float = 80.0  # NPCs gather berries when hunger drops below this %
@export var hunger_eat_threshold: float = 80.0  # NPCs eat when hunger drops below this %
@export var hunger_restore_percent: float = 5.0  # Each berry restores this % of max hunger
@export var hunger_deplete_rate: float = 20.0  # Hunger depletes this amount per minute (1 point every 3 seconds = 20 per minute)
@export var hunger_start_percent: float = 100.0  # Starting hunger percentage
@export var food_items_to_keep_in_inventory: int = 1  # NPCs keep this many food items in inventory before stopping collection
@export var prefer_higher_nutrient_food: bool = true  # NPCs prefer higher nutrient foods (meat > berries) when maintaining inventory

# ============================================
# PANIC SYSTEM
# ============================================
@export_group("Panic System")
@export var panic_max: float = 100.0  # Maximum panic level
@export var panic_start: float = 0.0  # Starting panic level
@export var panic_decay_rate: float = 5.0  # Panic decreases by this amount per minute
@export var panic_hide_threshold: float = 70.0  # NPCs enter hide mode when panic exceeds this %
@export var panic_break_herd_threshold: float = 80.0  # Herded NPCs break away when panic exceeds this %

# ============================================
# MOVEMENT & STEERING
# ============================================
@export_group("Movement & Steering")
@export var max_speed_base: float = 95.0  # Base max speed (smoother map movement; see guides/Phase4/config.md)
@export var speed_agility_multiplier: float = 9.5  # Speed = agility * this (see guides/Phase4/config.md)
@export var leader_speed_multiplier: float = 1.0  # Disabled (was 0.62)
@export var herd_leader_speed_multiplier: float = 0.97  # Just slightly slower when leading herd (3% slower)
@export var max_force: float = 40.0  # Maximum steering force (lower = more deliberate movement)
@export var acceleration: float = 1.8  # How quickly NPCs change direction (lower = more deliberate)
@export var arrive_radius: float = 100.0  # Distance at which NPCs start slowing down (increased for more deliberate arrival)
@export var arrive_slowdown_radius: float = 200.0  # Distance at which NPCs begin gradual slowdown
@export var direction_change_delay: float = 0.1  # Brief pause before changing direction (seconds) - makes movement more deliberate
@export var separation_radius: float = 64.0  # Distance NPCs try to maintain from each other

# Distance-based NPC update scaling (far NPCs run FSM/steering at reduced rate)
@export var distance_update_scale_enabled: bool = true
@export var distance_threshold_half_rate: float = 1500.0  # px - run at 0.5x beyond this
@export var distance_threshold_quarter_rate: float = 2500.0  # px - run at 0.25x beyond this

# Wander behavior
@export var wander_radius: float = 300.0  # Maximum distance NPCs wander from center
@export var wander_change_interval: float = 3.0  # How often wander target changes (seconds)
@export var max_wander_distance_from_spawn: float = 2500.0  # Maximum distance wild NPCs can wander from spawn (pixels) - increased to give more room for land claims

# ============================================
# ACTION DURATIONS
# ============================================
@export_group("Action Durations")
@export var eat_duration: float = 2.0  # Time to eat one berry (seconds)
@export var gather_duration: float = 0.5  # Time to gather a resource (seconds) - faster for more productive gathering
@export var craft_knap_duration: float = 30.0  # Time to knap stone into blade (seconds)
@export var action_speed_multiplier: float = 0.3  # Speed multiplier when eating/gathering (0.3 = 30% speed)

# ============================================
# IDLE ANIMATIONS
# ============================================
@export_group("Idle Animations")
@export var idle_duration_min: float = 1.0  # Minimum idle duration (seconds) - reduced for less downtime
@export var idle_duration_max: float = 3.0  # Maximum idle duration (seconds) - reduced from 5
@export var animation_duration_min: float = 1.0  # Minimum time for each animation phase (look left/right/bounce)
@export var animation_duration_max: float = 2.0  # Maximum time for each animation phase
@export var bounce_amount: float = 2.0  # Vertical bounce distance (pixels)
@export var bounce_speed: float = 8.0  # Bounce animation speed
@export var idle_chance: float = 0.02  # Chance to enter idle state each evaluation (reduced for more productivity)

# ============================================
# INVENTORY
# ============================================
@export_group("Inventory")
@export var human_inventory_slots: int = 10  # Inventory slots for humans (cavemen, women)
@export var animal_inventory_slots: int = 5  # Inventory slots for animals (sheep, goats)
@export var baby_inventory_slots: int = 2  # Inventory slots for babies (food from land claim)
@export var default_inventory_slots: int = 5  # Default inventory slots for other NPC types

# ============================================
# HERD BEHAVIOR
# ============================================
@export_group("Herd Behavior")

# Caveman Herding Efficiency Settings
@export_subgroup("Caveman Herding Efficiency")
@export var herd_target_stick_distance: float = 400.0  # Don't switch targets within this range
@export var herd_min_distance_improvement: float = 100.0  # Only switch if new target is this much closer
@export var herd_target_grace_period: float = 2.0  # Seconds to keep target after slight range exit
@export var herd_sprint_distance: float = 500.0  # Sprint when target is this far
@export var herd_slow_down_distance: float = 200.0  # Slow down when this close
@export var herd_speed_multiplier_sprint: float = 1.0  # Speed multiplier when sprinting (disabled boost)
@export var herd_speed_multiplier_normal: float = 1.0  # Normal speed multiplier
@export var herd_speed_multiplier_slow: float = 0.8  # Speed multiplier when slow
@export var herd_speed_match_fast_targets: float = 1.0  # Speed multiplier to match fast-moving targets (disabled boost)
@export var herd_npc_type_priority_woman: float = 1.2  # Priority multiplier for women
@export var herd_npc_type_priority_sheep: float = 1.0  # Priority multiplier for sheep
@export var herd_npc_type_priority_goat: float = 1.0  # Priority multiplier for goats
@export var herd_velocity_toward_claim_bonus: float = 1.5  # Priority bonus for NPCs moving toward land claim
@export var herd_detection_range: float = 1700.0  # Caveman detection range for wild NPCs (px)
@export var herd_inventory_entry_threshold: float = 0.72  # Max inventory fill (0-1) to enter herd_wildnpc; 0.72 = allow when under 72% full (productivity: more herding)
@export var herd_max_no_target_time: float = 9.0  # Base no-target timeout; exit after 2x this (18s) - stay searching longer
@export var herd_delivery_cooldown_sec: float = 5.5  # Cooldown after delivery before re-entering herd_wildnpc (shorter = more herding)
@export var herd_wildnpc_reentry_cooldown_sec: float = 1.5  # Min time after exiting herd_wildnpc before FSM can enter again (stops boundary flicker; aligns with analyze_playtest.py)
@export var herd_rapid_move_timeout: float = 2.5  # Seconds before dropping a target that's moving away rapidly
@export var herd_ray_stride: float = 180.0  # px/s walking outward along ray (faster search coverage)
@export var herd_spiral_expansion_rate: float = 80.0  # Legacy; used as ray stride fallback if herd_ray_stride not set
@export var herd_search_spiral_speed: float = 0.1  # How fast to rotate search spiral (radians per update)
@export var herd_ideal_follow_distance: float = 175.0  # Ideal distance to maintain when leading (pixels)
@export var herd_max_follow_distance: float = 300.0  # Max distance before slowing down (pixels)
@export var herd_min_follow_distance: float = 150.0  # Min distance before backing up (pixels)
@export var max_herd_size: int = 8  # Maximum number of NPCs in a herd at once
@export var herd_follow_distance_min: float = 70.0  # Minimum follow distance (RTS-style: more spread, less clumping)
@export var herd_follow_distance_max: float = 220.0  # Maximum follow distance (wider formation when moving)
@export var herd_max_distance_from_claim: float = 2000.0 # Maximum distance caveman can travel from land claim before forced to return (5x claim radius)
@export var herd_return_to_claim_distance: float = 750.0 # When herder is farther than this (px) with no herded target, exit to wander for deposit (search farther before return)
# Attraction System (Charisma + Proximity + Time)
@export var attraction_base_rate: float = 8.0  # Base attraction gain per second when leader is in range (increased for faster following)
@export var attraction_charisma_multiplier: float = 1.0  # Multiplier for charisma stat (social stat) (increased)
@export var attraction_proximity_multiplier: float = 3.0  # How much closer distance increases attraction rate (increased)
@export var attraction_max_distance: float = 300.0  # Maximum distance for attraction to build
@export var attraction_decay_rate: float = 1.0  # Attraction decays per second when leader is out of range
@export var attraction_threshold: float = 50.0  # Attraction needed to start following (0-100) (reduced for faster following)
@export var herd_area_radius: float = 150.0  # Area radius NPCs can wander/idle/gather within around herder (reduced for closer following)
@export var herd_spread_when_stopped: float = 1.5  # How much NPCs spread out when herd stops (multiplier)
@export var herd_mentality_follow_chance: float = 0.5  # Base chance (0.0-1.0) for woman to follow when caveman/player enters perception (50/50 for now)
@export var herd_mentality_perception_multiplier: float = 200.0  # DEPRECATED: Now using fixed 200px range. This value is ignored.
@export var herd_mentality_detection_range: float = 250.0  # Detection range for HerdInfluenceArea; caveman within this triggers animal attach (was 200, 250 = more forgiving)
@export var herd_mentality_distance_bonus: float = 0.5  # Bonus to follow chance per 100 pixels of distance from current leader (0.0-1.0) - increased for minigame
@export var herd_mentality_closer_bonus: float = 0.4  # Bonus to follow chance if new leader is closer than current leader (0.0-1.0) - increased for minigame
@export var herd_catchup_priority: float = 15.0  # Priority when catching up to herder (very high, higher than eat state)
@export var herd_max_distance_before_break: float = 300.0  # Distance from herder before herd breaks - reduced from 600px to match NPC perception range (~200-300px)
@export var herd_follow_refresh_interval: float = 0.3  # Seconds between steering target updates for wild herdables (party uses tighter intervals)
@export var herd_follower_speed_multiplier: float = 0.85  # Wild herdable follow speed — between party FOLLOW (1.0) and GUARD (0.75)
@export var herdable_attraction_multiplier: float = 1.0  # Multiplier for sheep/goat attraction threshold (1.0 = same as women, making them herdable)
@export var herdable_switch_attraction_difference: float = 25.0  # Attraction difference needed for sheep/goats to switch leaders (harder to steal than women)
# Influence system (HerdInfluenceArea) - alias/override for attraction when using Area2D
@export var influence_base_rate: float = 40.0  # Base influence gain per second when herder in range (higher = quicker follow)
@export var influence_threshold: float = 50.0  # Influence needed to consider transfer (0-100)
@export var influence_decay_rate: float = 1.0  # Influence decay per second when herder out of range
@export var contest_min_duration: float = 0.08  # Seconds above threshold before transfer (0.08 = ~instant)
@export var initial_influence: float = 55.0  # Influence when herder first enters radius (above threshold = instant follow)
@export var herd_resist_chance_base: float = 0.0  # Disabled: herd animals always follow (was 0.03)
@export var herd_resist_cooldown_sec: float = 2.0  # Per-animal cooldown after resist before another resist roll

# ============================================
# DETECTION & RANGES
# ============================================
@export_group("Detection & Ranges")
@export var perception_range_multiplier: float = 200.0  # Detection range = perception * this value (pixels) - increased significantly to match new resource spacing (800px min distance requires 1600px+ detection)
@export var gather_distance: float = 48.0  # Distance needed to gather a resource (pixels) - increased for easier gathering
@export var gather_move_cancel_threshold: float = 32.0  # Pixels - moving beyond this during gather cancels (was 20, increased to reduce bump cancellations)
@export var eat_distance: float = 32.0  # Distance needed to eat from a resource (pixels)
@export var deposit_range: float = 100.0  # Distance from land claim center to deposit (pixels) - unified for gather, wander, auto-deposit
@export var gather_deposit_threshold: float = 0.5  # Inventory fill % to trigger deposit (50% = carry more before deposit, fewer trips)
@export var gather_same_node_until_pct: float = 1.0  # Stay at resource until inventory FULL (100%) or node exhausted - avoid "grab 2, deposit, come back for 1" waste
@export var clan_spread_penalty: float = 50.0  # Soft-cost: add this per clan mate near resource (spread workers)

# ============================================
# STATE PRIORITIES
# ============================================
@export_group("State Priorities")
# Priority order (highest to lowest):
# 1. Agro (10.0) - urgent threats/defense
# 2. Eat very hungry (10.0) - urgent survival
# 3. Herd (11.0) - NPCs following (not for cavemen)
# 4. Build (9.0) - place land claim (when no land claim, after herding)
# 5. Gather (8.0-9.5) - TOP PRIORITY after building (when has land claim)
# 6. Herd woman (8.5) - herd wild NPCs (can happen before or after land claim)
# 7. Eat hungry (7.0) - important but not urgent
# 8. Wander (1.0) - default/fallback/starting state
# 9. Idle (0.0) - lowest
@export var priority_eat_very_hungry: float = 10.0  # Priority when hunger < 30%
@export var priority_eat_hungry: float = 7.0  # Priority when hunger < 50%
@export var priority_eat_low: float = 5.0  # Priority when hunger < 80%
@export var priority_gather_berries: float = 4.0  # Priority when gathering berries (hunger < 90%)
@export var priority_gather_other: float = 5.5  # Base gather; herd_wildnpc_searching (6.0–6.1) beats when target/pressure high
@export var priority_wander: float = 1.0  # Priority for wandering
@export var priority_idle: float = 0.0  # Priority for idle (lowest)

# Testing: 1.0 = min wander (0.01), 0.5s re-eval; 0 = normal wander. Keep 1.0 for productive cavemen (gather > herd-search).
@export var caveman_productivity_test: float = 1.0  # 1.0 = productive (gather 5.6, wander 0.01); herd_search 5.7 so cavemen can commit to herding
@export var priority_herd: float = 11.0  # Priority for herd state (following) - higher than eat state (NPCs go hungry before giving up following)
@export var priority_herd_wildnpc: float = 11.5  # Above deposit (11) - cavemen interrupt deposit to herd when wild NPCs nearby
@export var priority_herd_wildnpc_woman: float = 12.0  # Highest: when leading or targeting a woman (above deposit 11, above normal herd 11.5)
@export var priority_herd_wildnpc_searching: float = 6.0  # Beats gather (5.5) when herdables in range; 6.1 when reproduction_pressure >= 0.8
@export var priority_deposit: float = 11.0  # Protected - core gather→deposit loop, never interrupted by herding
@export var priority_agro: float = 15.0  # Priority for agro state (highest - interrupts all other states)
@export var priority_build: float = 9.5  # Priority for build state (place land claim - only when no land claim, 15.0 when has 8+ items)

# ============================================
# STEERING WEIGHTS
# ============================================
@export_group("Steering Weights")
@export var seek_weight: float = 1.0  # Weight for seek behavior
@export var arrive_weight: float = 1.0  # Weight for arrive behavior
@export var separate_weight: float = 1.5  # Weight for separation behavior
@export var flee_weight: float = 1.0  # Weight for flee behavior

# ============================================
# AGRO SYSTEM (Caveman Aggression)
# ============================================
@export_group("Agro System")
@export var combat_disabled: bool = false  # When true, agro stays 0 and combat never triggers (for testing gather/herd)
@export var agro_enter_threshold: float = 70.0  # Step 8: Enter combat when agro >= this
@export var agro_exit_threshold: float = 60.0   # Step 8: Exit combat (hysteresis) when agro < this
@export var agro_max: float = 100.0              # Agro cap
@export var agro_decay_combat: float = 2.0       # Decay per second while in combat
@export var agro_decay_idle: float = 5.0         # Decay per second when not in combat
@export var agro_state_meter_rise_per_second: float = 10.0  # While in agro_state, agro_meter rise per second (hostile indicator)
@export var agro_absolute_max_seconds: float = 45.0  # Safety: force-clear agro_meter if positive this long (CombatTick)
@export var hostile_threshold: float = 70.0  # agro_meter needed for hostile mode in recover (shows "!!!" indicator)
@export var hostile_threshold_defend: float = 70.0  # Agro level for hostile mode in defend mode (agro_state)
@export var hostile_duration_max: float = 10.0  # Max duration of hostile indicator display (seconds)
@export var agro_approach_distance: float = 150.0  # Distance to approach lost woman (pixels)
@export var agro_retreat_distance: float = 250.0  # Distance to retreat from lost woman (pixels)
@export var agro_flee_player_distance: float = 100.0  # Distance from player to trigger flee in agro mode (pixels)
@export var agro_steal_attempt: float = 20.0  # Agro meter increase when steal attempt fails (challenger tried to steal)
@export var agro_steal_success: float = 40.0  # Agro meter increase when steal succeeds (old herder lost the animal)
@export var agro_perception_range: float = 300.0  # Max distance (px) from NPC to target to trigger agro; NPCs cannot agro on things outside this.
# Chase break: pumps suppressed while in combat/flee; extra decay when target is out of range
@export var agro_outranged_extra_decay: float = 18.0  # Extra decay per second when combat target is beyond agro_perception_range (runner is getting away).
@export var agro_far_instant_break_distance: float = 560.0  # Beyond this distance to combat target, drop agro and clear target immediately (hard leash).
@export var agro_lost_target_give_up_seconds: float = 7.0  # If combat target stays beyond perception this long, force-clear (failsafe if decay tuning changes)

# ============================================
# Flee combat (disengage)
# ============================================
@export_group("Flee System")
@export var flee_hp_threshold: float = 0.30  # Base HP ratio to flee (scaled by bravery)
@export var flee_outnumber_ratio: float = 2.0  # Enemy:ally ratio that triggers flee (scaled by bravery)
@export var flee_speed_multiplier: float = 1.4  # Sprint while fleeing
@export var flee_duration_seconds: float = 5.0  # Base flee duration before re-eval
@export var flee_combat_cooldown: float = 10.0  # Seconds before willing to re-enter combat after flee
@export var flee_scatter_angle_deg: float = 30.0  # Random +/- degrees on flee heading
@export var flee_non_combatant_types: Array[String] = ["woman", "sheep", "goat", "baby"]
@export var flee_default_bravery: float = 0.5  # 0=coward, 1=fearless until trait system assigns per NPC
@export var flee_check_interval_sec: float = 0.5  # How often combat_state re-checks _should_flee

# ============================================
# CAVEMAN BEHAVIOR
# ============================================
@export_group("Caveman Behavior")
@export var caveman_flee_player_distance: float = 80.0  # Distance from player to trigger flee (pixels, non-agro states)
@export var caveman_push_radius: float = 60.0  # Radius for push/bump detection (pixels)
@export var caveman_push_force: float = 500.0  # Force applied when pushing (higher = stronger push)
@export var caveman_push_agro_multiplier: float = 1.5  # Push force multiplier when in agro mode
@export var area_of_agro_radius: float = 200.0  # AOA: Trigger agro when enemy enters this range (px). Must be <= AOP (claim radius).
@export var proximity_agro_radius: float = 380.0  # Proximity agro: enemy within this range (px) builds agro so whole formations engage. No claim required.
@export var proximity_agro_rate: float = 50.0  # Agro per second when enemy in proximity_agro_radius (same as intrusion so groups cross 70 quickly).
@export var aop_radius_default: float = 380.0  # Default AOP (matches proximity_agro_radius). Used for caveman, clansman, woman, sheep, goat.
@export var aop_radius_mammoth: float = 600.0  # Mammoth AOP - agro when threats enter
@export var aop_radius_gather: float = 800.0  # AOP for gather resource queries (opportunistic gather)
@export var aop_radius_leader: float = 0.0  # Trait override: leader AOP (0 = unused)
@export var aop_radius_searcher: float = 0.0  # Trait override: searcher AOP (0 = unused)
@export var mammoth_aop_radius: float = 600.0  # Mammoth AOP (legacy; npc_base uses this; PerceptionArea uses aop_radius_mammoth)
@export var mammoth_base_agro_rate: float = 30.0  # Base agro increase per second (scales with threat count)
@export var mammoth_scale: float = 0.6  # Mammoth visual scale (10x smaller than original 6.0)
@export var mammoth_land_claim_avoid_distance: float = 800.0  # Mammoths stay this far from land claims (pixels beyond claim radius)
@export var caveman_seek_push_range: float = 200.0  # Range to actively seek targets to push (pixels)
@export var caveman_push_seek_priority: float = 0.3  # How often cavemen seek to push (0.0-1.0, higher = more aggressive)
@export var caveman_build_cooldown_after_spawn: float = 10.0  # Seconds after spawn before cavemen can place land claims (reduced from 15s to 10s)
@export var land_claim_min_distance: float = 1600.0  # Minimum distance between land claims (doubled for caveman spread)
@export var land_claim_buffer_zone: float = 150.0  # Buffer zone around land claims that NPCs avoid (pixels) - prevents losing herded NPCs
@export var inventory_nearly_full_threshold: float = 0.8  # Inventory fill percentage to trigger deposit (80% = 8/10 slots for cavemen) - triggers deposit at 80% full

# ============================================
# ClanBrain — Area of Hunt & hunting party (AI clans)
# ============================================
@export_group("ClanBrain / Hunt")
@export var aoh_radius_base: float = 800.0
@export var aoh_radius_min: float = 500.0
@export var aoh_radius_max: float = 1200.0
@export var hunt_party_min_size: int = 2
@export var hunt_party_max_size: int = 4

# ============================================
# FSM (Finite State Machine)
# ============================================
@export_group("FSM Settings")
@export var evaluation_interval: float = 1.0  # How often FSM evaluates states (seconds)
@export var assignment_check_interval: float = 0.4  # Seconds between building assignment checks per animal

# ============================================
# HELPER FUNCTIONS
# ============================================
# Helper functions to access config values
# These can be called from anywhere: NPCConfig.get_max_speed(agility)
static func get_max_speed(agility: float) -> float:
	return agility * NPCConfig.speed_agility_multiplier

static func get_idle_duration() -> float:
	return randf_range(NPCConfig.idle_duration_min, NPCConfig.idle_duration_max)

static func get_animation_duration() -> float:
	return randf_range(NPCConfig.animation_duration_min, NPCConfig.animation_duration_max)

static func get_detection_range(perception: float) -> float:
	return perception * NPCConfig.perception_range_multiplier

static func get_hunger_restore_amount(hunger_max: float) -> float:
	return (hunger_max * NPCConfig.hunger_restore_percent) / 100.0

# ============================================
# USAGE NOTES
# ============================================
# To use these values in scripts, access them via the NPCConfig singleton:
#   NPCConfig.hunger_gather_threshold
#   NPCConfig.max_speed_base
#   NPCConfig.eat_duration
#   etc.
#
# Example usage in other scripts:
#   var config = NPCConfig
#   if hunger_percent < config.hunger_gather_threshold:
#       # gather berries
