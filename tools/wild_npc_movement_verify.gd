extends SceneTree
# Headless checks for WildMovement / profiles / migratory finalize + exit despawn contract.
# Run: SKIP_SINGLE_INSTANCE=1 godot --headless --path <repo> --script res://tools/wild_npc_movement_verify.gd
# Exit 0 on success, 1 on failure.

const NPC_SCENE := preload("res://scenes/NPC.tscn")

func _init() -> void:
	call_deferred("_run")


func _fail(msg: String) -> void:
	push_error("WILD_NPC_MOVEMENT_VERIFY_FAIL: %s" % msg)


func _run() -> void:
	await process_frame
	var nc = get_root().get_node_or_null("/root/NPCConfig")
	if nc == null:
		_fail("/root/NPCConfig autoload missing")
		quit(1)
		return

	var mig: int = nc.WildMovement.MIGRATORY
	var terr: int = nc.WildMovement.TERRITORIAL
	if mig == terr:
		_fail("WildMovement enum degenerate")
		quit(1)
		return

	for type_key in ["deer", "sheep", "goat", "mammoth"]:
		var pd: Variant = nc.call("get_wild_profile", type_key)
		if pd is Dictionary and int(pd.get("movement", -99)) != nc.WildMovement.MIGRATORY:
			_fail("profile movement for %s" % type_key)
			quit(1)
			return
	var wom: Variant = nc.call("get_wild_profile", "woman")
	if wom is Dictionary and int(wom.get("movement", -99)) != nc.WildMovement.TERRITORIAL:
		_fail("woman profile not TERRITORIAL")
		quit(1)
		return

	# Instance NPC: migration corridor + profile (Phase 2/3-style contract).
	var npc: Node = NPC_SCENE.instantiate()
	if npc == null:
		_fail("NPC_SCENE.instantiate() null")
		quit(1)
		return
	get_root().add_child(npc)
	await process_frame

	npc.set("npc_type", "deer")
	npc.set("npc_name", "VerifyDeer")
	npc.set("migration_entry_side", -1)
	npc.set("migration_exit_x", 0.0)
	npc.global_position = Vector2(-1000.0, 0.0)
	if npc.has_method("_apply_wild_profile"):
		npc.call("_apply_wild_profile")
	else:
		npc.queue_free()
		_fail("NPC missing _apply_wild_profile")
		quit(1)
		return

	var ok_profile: bool = bool(npc.call("is_migratory")) and bool(npc.get("migration_active"))
	if not ok_profile:
		npc.queue_free()
		_fail("deer not migratory or migration inactive after profile")
		quit(1)
		return

	# Explicit F7-style log line is optional; migration props must match west entry.
	var side_i: int = int(npc.get("migration_entry_side"))
	var exit_x: float = float(npc.get("migration_exit_x"))
	if side_i != -1:
		npc.queue_free()
		_fail("expected migration_entry_side -1 got %s" % side_i)
		quit(1)
		return

	# Despawn: past eastern exit (+ margin).
	var margin_v: Variant = nc.get("migration_despawn_margin")
	var margin: float = float(margin_v) if margin_v != null else 200.0
	npc.global_position = Vector2(exit_x + margin + 250.0, npc.global_position.y)
	if npc.has_method("_check_migration_despawn"):
		npc.call("_check_migration_despawn")
	await process_frame

	if is_instance_valid(npc):
		npc.queue_free()
		_fail("migratory NPC should have queued free after crossing exit (+margin)")
		quit(1)
		return

	print("WILD_NPC_MOVEMENT_VERIFY_OK: enums+profiles+profile_apply+despawn (west entry exit_x=%.0f)" % exit_x)
	quit(0)
