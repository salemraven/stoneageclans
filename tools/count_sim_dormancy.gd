extends SceneTree

func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	await process_frame
	var main_scene: PackedScene = load("res://scenes/Main.tscn") as PackedScene
	var main: Node = main_scene.instantiate()
	root.add_child(main)
	for _i in 300:
		await process_frame
	var resources: Array = get_nodes_in_group("resources")
	var mon := 0
	var sim_off := 0
	for node in resources:
		if node is Area2D:
			if (node as Area2D).monitoring:
				mon += 1
			if node.has_method("apply_sim_monitoring"):
				# check internal state via monitoring as proxy
				pass
		if node is GatherableResource or node is GroundItem:
			if node is Area2D and not (node as Area2D).monitoring:
				sim_off += 1
	var npcs: Array = get_nodes_in_group("npcs")
	var npc_phys := 0
	var npc_dormant := 0
	for npc in npcs:
		if npc is CharacterBody2D:
			if (npc as CharacterBody2D).is_physics_processing():
				npc_phys += 1
			else:
				npc_dormant += 1
	print("MONITOR_CHECK resources=%d monitoring=%d sim_monitoring_off=%d npcs=%d phys=%d dormant=%d" % [
		resources.size(), mon, sim_off, npcs.size(), npc_phys, npc_dormant
	])
	quit(0)
