extends Node
## Tunable chunk world generation + server tick (single autoload; see implementation plan).

# --- World ---
var world_seed: int = 0

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

# When true, SpawnManager uses ChunkManager for resources/trees/grass instead of radius spawn.
var use_chunk_content_streaming: bool = true

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
