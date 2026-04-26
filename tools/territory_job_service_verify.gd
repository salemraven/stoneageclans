extends SceneTree
# Invariants for E3: TerritoryJobService rejects invalid inputs; same service for camp-like vs flag-like radius.
# Run: godot --headless --path <repo> --script res://tools/territory_job_service_verify.gd
# Load service at runtime (not preload) so autoloads like UnifiedLogger exist when the script compiles.

func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	await process_frame
	var TJS = load("res://scripts/systems/territory_job_service.gd")
	if TJS == null:
		push_error("TJS_VERIFY_FAIL: could not load territory_job_service.gd")
		quit(1)
		return
	if TJS.generate_gather_job(null, null) != null:
		push_error("TJS_VERIFY_FAIL: null claim/worker should return null")
		quit(1)
		return
	var claim := Node2D.new()
	claim.set("clan_name", "ClanA")
	var worker := Node2D.new()
	worker.set("clan_name", "ClanB")
	if TJS.generate_gather_job(claim, worker) != null:
		push_error("TJS_VERIFY_FAIL: mismatched clan should return null")
		quit(1)
		return
	if TJS.generate_craft_job(null, null) != null:
		push_error("TJS_VERIFY_FAIL: craft null claim/worker should return null")
		quit(1)
		return
	worker.set("clan_name", "ClanA")
	var _craft_try = TJS.generate_craft_job(claim, worker)
	# May be null (no blades/stone/npc_type); must not crash.

	# E3 parity: two in-tree claims, same clan — small radius (camp-like) vs large (flag-like).
	# With no map resources, gather returns null for both; craft returns null without inventory; must not crash.
	var root := get_root()
	var camp_like := Node2D.new()
	camp_like.set("clan_name", "TierParity")
	camp_like.set("radius", 100.0)
	var flag_like := Node2D.new()
	flag_like.set("clan_name", "TierParity")
	flag_like.set("radius", 400.0)
	var w2 := Node2D.new()
	w2.set("clan_name", "TierParity")
	w2.set("npc_type", "caveman")
	root.add_child(camp_like)
	root.add_child(flag_like)
	root.add_child(w2)
	if TJS.generate_gather_job(camp_like, w2) != null:
		push_error("TJS_VERIFY_FAIL: expected null gather (no resources) for small-radius claim")
		quit(1)
		return
	if TJS.generate_gather_job(flag_like, w2) != null:
		push_error("TJS_VERIFY_FAIL: expected null gather (no resources) for large-radius claim")
		quit(1)
		return
	# Craft without claim inventory: both must return null, no crash
	if TJS.generate_craft_job(camp_like, w2) != null or TJS.generate_craft_job(flag_like, w2) != null:
		push_error("TJS_VERIFY_FAIL: craft without claim inventory should be null for both claim sizes")
		quit(1)
		return
	for n: Node2D in [camp_like, flag_like, w2]:
		root.remove_child(n)
		n.free()
	claim.free()
	worker.free()

	print("TERRITORY_JOB_SERVICE_VERIFY_OK")
	quit(0)
