extends SceneTree

func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	await process_frame
	var main_scene: PackedScene = load("res://scenes/Main.tscn") as PackedScene
	var main: Node = main_scene.instantiate()
	root.add_child(main)
	for _i in 200:
		await process_frame
	var resources: Array = get_nodes_in_group("resources")
	var proc := 0
	var gatherable_proc := 0
	var ground_proc := 0
	var gatherable_class := 0
	var ground_class := 0
	for node in resources:
		if node is GatherableResource:
			gatherable_class += 1
			if (node as Node).is_processing():
				gatherable_proc += 1
		elif node is GroundItem:
			ground_class += 1
			if (node as Node).is_processing():
				ground_proc += 1
		if node is Node and (node as Node).is_processing():
			proc += 1
	print(
		"COUNT_RESOURCE_PROCESS total=%d proc=%d gatherables=%d gatherable_proc=%d ground=%d ground_proc=%d"
		% [resources.size(), proc, gatherable_class, gatherable_proc, ground_class, ground_proc]
	)
	quit(0)
