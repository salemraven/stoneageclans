extends SceneTree
# Invariants for E3: TerritoryJobService rejects invalid inputs.
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
	print("TERRITORY_JOB_SERVICE_VERIFY_OK")
	quit(0)
