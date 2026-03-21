extends SceneTree
# Run from command line: godot --headless --script res://scripts/test/implementation_checklist_verify.gd
# Verifies implementation checklist code paths exist and don't error on basic use.

func _init() -> void:
	var ok: bool = true
	# 1) NodeCache API (method existence; full behavior needs game run)
	var NodeCacheScript = load("res://scripts/npc/node_cache.gd") as GDScript
	if NodeCacheScript:
		var cache = NodeCacheScript.new()
		if not cache.has_method("get_land_claims"):
			print("FAIL NodeCache missing get_land_claims")
			ok = false
		if not cache.has_method("get_npcs_near_position"):
			print("FAIL NodeCache missing get_npcs_near_position")
			ok = false
		cache.free()
	else:
		print("FAIL could not load node_cache.gd")
		ok = false

	# 2) BaseState is_complete
	var BaseStateScript = load("res://scripts/npc/states/base_state.gd") as GDScript
	if BaseStateScript:
		var base_state = Node.new()
		base_state.set_script(BaseStateScript)
		if base_state.has_method("is_complete"):
			var c = base_state.is_complete()
			if c != false:
				print("FAIL BaseState.is_complete() should be false by default, got ", c)
				ok = false
		else:
			print("FAIL BaseState missing is_complete")
			ok = false
		base_state.free()
	else:
		print("FAIL could not load base_state.gd")
		ok = false

	# 3) State memory API - check npc_base.gd source contains the methods (avoids loading full script + autoloads)
	var npc_base_path = "res://scripts/npc/npc_base.gd"
	var npc_base_file = FileAccess.open(npc_base_path, FileAccess.READ)
	if npc_base_file:
		var script_text = npc_base_file.get_as_text()
		npc_base_file.close()
		if "get_state_memory" in script_text and "set_state_memory" in script_text and "validate_state_memory_target" in script_text and "state_memory" in script_text:
			pass  # OK
		else:
			print("FAIL NPCBase missing state_memory methods")
			ok = false
	else:
		print("FAIL could not open npc_base.gd")
		ok = false

	if ok:
		print("Implementation checklist verify: OK")
	quit(0 if ok else 1)
