extends Node
## Tunable chunk world generation + server tick (single autoload; see implementation plan).

# --- World ---
var world_seed: int = 0
## When false (default): classic Main — repeating DirtBase tiles + procedural chunk resources.
## When true: load maps/island (biome_mask, water, optional chunk ground art). CLI: --island-map
var use_authored_island_map: bool = false

# --- Chunk load / unload ---
var chunk_load_radius_base: int = 1
var chunk_unload_hysteresis: int = 1
var chunk_unload_delay_sec: float = 0.0
var single_player_initial_load_radius: int = 2
## Loaded chunks within this radius of a player run full NPC physics + resource monitoring.
var sim_active_chunk_radius: int = 1
## Always keep sim hot within this distance (px) of any player.
var sim_wake_player_radius_px: float = 450.0
var chunks_load_per_frame: int = 6
var chunks_unload_per_frame: int = 3
var chunk_unload_no_interest_grace_ms: float = 500.0
var chunk_defer_unload_if_npcs_active: bool = true
var chunk_defer_unload_if_player_building: bool = true

# --- Player spawn (MP join) ---
## Minimum distance (px) between joining players when picking a spawn location.
var player_spawn_min_distance_px: float = 3000.0

# --- Wild women (chunk-seeded) ---
var wild_woman_chunk_chance: float = 0.15
var wild_woman_per_chunk_max: int = 2

# --- Settlement sim (warm tier / dormant claims) ---
## Seconds between off-screen settlement ticks per claim (food, passive buildings, starvation).
var settlement_tick_interval_sec: float = 30.0
## Items gathered per alive roster member per settlement tick (tunable per resource key).
## Grain/nuts: higher per harvest; berries/bugs: lower per harvest but faster regen (see gather_regen_per_sim_day).
var gather_yield_per_population: Dictionary = {
	"berries": 2.0,
	"grain": 3.5,
	"wood": 1.5,
	"stone": 1.0,
	"fiber": 1.5,
	"nuts": 1.5,
	"bugs": 1.5,
	"hide": 0.0,
}
## Wall-clock seconds of settlement sim ≈ one abstract regen sim-day (5 ticks × settlement_tick_interval_sec).
var abstract_regen_sim_day_sec: float = 150.0
## Pool units restored per sim-day when below chunk cap (per resource type).
var gather_regen_per_sim_day: Dictionary = {
	"berries": 14.0,
	"grain": 5.0,
	"nuts": 4.0,
	"bugs": 6.0,
	"fiber": 3.0,
	"wood": 2.0,
	"stone": 1.0,
}
## Multiplier on population when computing abstract gather workers (diminishing returns hook).
var gather_population_efficiency: float = 0.8
## Optional gather rate multiplier when clan is in starving workforce mode (1.0 = no penalty).
var gather_starvation_penalty: float = 1.0

## Abstract hunting (dormant clans) — hunt live prey in chunk when meat is low.
var abstract_hunt_enabled: bool = true
## Only hunt when raw+cooked meat in claim inventory is below this count.
var abstract_hunt_meat_threshold: int = 2

## Abstract pregnancy/birth (dormant clans) — advance pregnancy timers, spawn babies off-screen.
var abstract_pregnancy_enabled: bool = true
## Abstract baby growth (dormant clans) — babies grow into clansmen off-screen.
var abstract_baby_growth_enabled: bool = true
## Abstract aging (dormant clans) — NPCs age proportionally to elapsed sim time.
var abstract_aging_enabled: bool = true

# --- Adaptive radius (MP) ---
var adaptive_load_radius_enabled: bool = true
var load_radius_tier_1_players: int = 5
var load_radius_tier_2_players: int = 20
var load_radius_tier_3_players: int = 50
var load_radius_tier_3_value: int = 0

# --- MP spawn zones (chunk coords) ---
var player_spawn_grid_spacing: int = 15
var player_spawn_zones: Array[Vector2i] = [
	Vector2i(0, 0), Vector2i(15, 0), Vector2i(-15, 0),
	Vector2i(0, 15), Vector2i(0, -15), Vector2i(15, 15),
	Vector2i(-15, -15), Vector2i(15, -15), Vector2i(-15, 15)
]

# --- Seeded clans ---
var clan_spawn_chance: float = 0.08
var clan_min_spacing_chunks: int = 2
var clans_per_spawn: int = 1

# --- Clan respawn / density ---
var clan_respawn_enabled: bool = true
var clan_respawn_delay_sec: float = 300.0
var clan_max_deaths_per_chunk: int = 3
var min_clans_per_player: int = 2
var clan_check_radius_chunks: int = 5
var clan_density_check_interval_sec: float = 30.0
var clan_respawn_avoid_player_chunk: bool = true

# --- Resources / trees / decor ---
## Multiplier for gatherable resources (trees, bushes, ground items, tallgrass).
## Does NOT affect NPC spawns (clans, migratory wildlife).
var resource_density_multiplier: float = 2.5
var resource_spawn_chance: float = 0.85
var resources_per_chunk: int = 12
var tree_group_chance: float = 0.92
var tree_groups_per_chunk: int = 3
var trees_per_group_min: int = 4
var trees_per_group_max: int = 8
var tree_group_spread_radius: float = 280.0
var tallgrass_clusters_per_chunk: int = 4
var tallgrass_per_cluster_min: int = 6
var tallgrass_per_cluster_max: int = 12
var ground_items_per_chunk: int = 6

# --- Wild migratory NPCs (chunk streaming load) ---
# Seeded rolls per chunk (world_seed + chunk_coords). NPCs parent to Main.world_objects, not chunk root.
var wild_migratory_chunk_spawns_enabled: bool = true
## Probability [0–1] that this chunk emits at least one migratory herd when loaded.
var wild_migratory_chunk_pass_chance: float = 0.52
var wild_migratory_packs_min: int = 2
var wild_migratory_packs_max: int = 4

# --- MP / replication ---
var server_tick_rate: int = 30
var server_current_tick: int = 0
var server_tick_accumulator_sec: float = 0.0
var expected_bandwidth_per_player_kb_s: float = 3.0

# --- Stable IDs ---
var stable_id_format: String = "%d_%d_%s_%d"


func _ready() -> void:
	for a in OS.get_cmdline_args():
		if a in ["--island-map", "--authored-island"]:
			use_authored_island_map = true
	set_process(true)


func _process(delta: float) -> void:
	_step_server_tick(delta)


func _step_server_tick(delta: float) -> void:
	if multiplayer.has_multiplayer_peer() and not multiplayer.is_server():
		return
	server_tick_accumulator_sec += delta
	var step := 1.0 / float(maxi(server_tick_rate, 1))
	while server_tick_accumulator_sec >= step:
		server_tick_accumulator_sec -= step
		server_current_tick += 1


func get_effective_load_radius() -> int:
	if not adaptive_load_radius_enabled:
		return chunk_load_radius_base
	if not multiplayer.has_multiplayer_peer():
		return maxi(single_player_initial_load_radius, chunk_load_radius_base)
	var player_count: int = multiplayer.get_peers().size() + 1
	if player_count <= load_radius_tier_1_players:
		return chunk_load_radius_base
	elif player_count <= load_radius_tier_2_players:
		return chunk_load_radius_base
	else:
		return load_radius_tier_3_value


func generate_stable_id(chunk: Vector2i, layer: String, index: int) -> String:
	return stable_id_format % [chunk.x, chunk.y, layer, index]
