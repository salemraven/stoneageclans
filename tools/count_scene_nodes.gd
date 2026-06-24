extends SceneTree
## One-shot: load Main, wait, count nodes by group, quit.
## Run: godot --path . --headless -s res://tools/count_scene_nodes.gd

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	var err := change_scene_to_file("res://scenes/Main.tscn")
	if err != OK:
		push_error("Failed to load Main: %s" % err)
		quit(1)
		return
	await create_timer(8.0).timeout
	var root := current_scene
	if root == null:
		print("PERF_COUNT: no scene")
		quit(1)
		return
	var groups := ["npcs", "resources", "decorative_trees", "tallgrass", "ground_items", "land_claims", "buildings", "corpses"]
	var lines: PackedStringArray = []
	for g in groups:
		var n := get_nodes_in_group(g).size()
		lines.append("%s=%d" % [g, n])
	var total := _count_nodes(root)
	lines.append("total_nodes=%d" % total)
	print("PERF_COUNT " + " ".join(lines))
	quit(0)

func _count_nodes(n: Node) -> int:
	var c := 1
	for ch in n.get_children():
		c += _count_nodes(ch)
	return c
