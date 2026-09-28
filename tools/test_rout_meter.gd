extends SceneTree


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	await process_frame
	var src := FileAccess.get_file_as_string("res://scripts/systems/rout_meter.gd")
	if not src.contains("add_on_ally_death"):
		push_error("TEST_ROUT: missing add_on_ally_death")
		quit(1)
		return
	if not src.contains("MoraleBarScript"):
		push_error("TEST_ROUT: rout meter must delegate to morale bar")
		quit(1)
		return
	if not src.contains("add_on_ally_rout") or not src.contains("effective_flee_threshold"):
		push_error("TEST_ROUT: missing rout contagion")
		quit(1)
		return
	var npc_src := FileAccess.get_file_as_string("res://scripts/npc/npc_base.gd")
	if not npc_src.contains("var rout_meter"):
		push_error("TEST_ROUT: npc missing rout_meter")
		quit(1)
		return
	if not npc_src.contains("func try_rout_flee"):
		push_error("TEST_ROUT: missing try_rout_flee")
		quit(1)
		return
	if not npc_src.contains("func show_rout_flash") or not npc_src.contains("RoutIndicator"):
		push_error("TEST_ROUT: missing rout flash visual")
		quit(1)
		return
	var flee_src := FileAccess.get_file_as_string("res://scripts/npc/states/flee_combat_state.gd")
	if not flee_src.contains("show_rout_flash") or not flee_src.contains("hide_rout_flash"):
		push_error("TEST_ROUT: flee_combat must show/hide rout flash")
		quit(1)
		return
	if not npc_src.contains("agro_target = null"):
		push_error("TEST_ROUT: agro 0 must clear agro_target")
		quit(1)
		return
	print("TEST_ROUT: ok")
	quit(0)
