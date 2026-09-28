extends SceneTree

## Source lock: converted hot-path helpers query the grid, not every NPC.


func _init() -> void:
	var src := FileAccess.get_file_as_string("res://scripts/npc/npc_base.gd")
	if src.is_empty():
		push_error("TEST_HOT_PATH_SCANS: cannot read npc_base.gd")
		quit(1)
		return
	for fn in ["_get_emergency_separation_force", "_apply_sheep_grouping_behavior", "_combat_target_candidates_inner"]:
		var body := _func_body(src, fn)
		if body.is_empty():
			push_error("TEST_HOT_PATH_SCANS: missing %s" % fn)
			quit(1)
			return
		if not body.contains("HostileEntityIndex"):
			push_error("TEST_HOT_PATH_SCANS: %s does not use HostileEntityIndex" % fn)
			quit(1)
			return
	if _func_body(src, "_find_agro_target").contains("get_nodes_in_group"):
		push_error("TEST_HOT_PATH_SCANS: _find_agro_target still scans npcs")
		quit(1)
		return
	print("TEST_HOT_PATH_SCANS: ok")
	quit(0)


func _func_body(src: String, fn: String) -> String:
	var needle := "func %s" % fn
	var start := src.find(needle)
	if start < 0:
		return ""
	var next_fn := src.find("\nfunc ", start + needle.length())
	if next_fn < 0:
		return src.substr(start)
	return src.substr(start, next_fn - start)
