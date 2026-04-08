extends Node
## World NPC/resource spawn orchestration extracted from main.gd (multiplayer readiness).
## Heavy spawn implementations remain on Main until further extraction; this node owns the ordered flow.

var main: Node2D


func bind_main(m: Node2D) -> void:
	main = m


func setup_npcs() -> void:
	if not main:
		push_error("SpawnManager: call bind_main() before setup_npcs()")
		return
	# NPCs and grass add directly to world_objects (YSort) for proper depth sorting
	main.npcs_container = main.world_objects
	main.decorations_container = main.world_objects
	await main._initialize_minigame()
	await main.get_tree().process_frame
	await main._spawn_initial_resources()
	main._spawn_tallgrass()
	main._spawn_decorative_trees()
	await main._spawn_rts_playtest_pack_if_requested()
