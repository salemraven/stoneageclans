extends Node
## World spawn orchestration: player join placement + chunk streaming bootstrap.
## NPC/world content is chunk-seeded; no player-centered minigame ring.

var main: Node2D


func bind_main(m: Node2D) -> void:
	main = m


func setup_npcs() -> void:
	if not main:
		push_error("SpawnManager: call bind_main() before setup_npcs()")
		return
	main.npcs_container = main.world_objects
	main.decorations_container = main.world_objects

	var wgc: Node = main.get_node_or_null("/root/WorldGenConfig")
	var ws: int = int(wgc.world_seed) if wgc else 0
	var pi: Node = main.get_node_or_null("/root/PlaytestInstrumentor")
	var mode: String = "multiplayer" if main.has_method("_is_online_multiplayer") and main._is_online_multiplayer() else "single_player"
	var player_count: int = 1
	if mode == "multiplayer" and main.multiplayer.is_server():
		player_count = main.multiplayer.get_peers().size() + 1
	if pi and pi.has_method("session_started"):
		pi.call("session_started", mode, ws, player_count)
	UnifiedLogger.log_system("session_started", {"mode": mode, "world_seed": ws, "player_count": player_count})

	var harness_ran: bool = await main._try_run_dev_test_harness()
	if not harness_ran:
		var spawn_pos: Vector2 = main._resolve_player_spawn_location()
		main._place_player_at_spawn(spawn_pos, "single_player_origin" if mode == "single_player" else "mp_join")

	await main.get_tree().process_frame

	var cm: Node = main.get_node_or_null("/root/ChunkManager")
	if cm and cm.has_method("ensure_initial_load"):
		cm.call("ensure_initial_load", main)

	var dc: Node = main.get_node_or_null("/root/DebugConfig")
	if dc and bool(dc.get("enable_party_hunt_debug")) and main.has_method("_seed_party_hunt_debug_deer_near_claims"):
		await main._seed_party_hunt_debug_deer_near_claims(main.world_objects)

	await main._spawn_rts_playtest_pack_if_requested()
	main._log_spawn_flow_summary()
