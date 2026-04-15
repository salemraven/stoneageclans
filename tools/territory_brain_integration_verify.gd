extends SceneTree
# Headless integration check: LandClaim ClanBrain sees nearby enemy Campfire in land_claims group.
# Run: godot --headless --path <repo> --script res://tools/territory_brain_integration_verify.gd -- --playtest-capture [--playtest-log-dir <abs_dir>]
# Exit 0 on success, 1 on failure.

func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	await process_frame

	var win := get_root()
	var container := Node2D.new()
	container.name = "Main"
	container.add_to_group("main")
	win.add_child(container)

	var scene_cf: PackedScene = load("res://scenes/Campfire.tscn") as PackedScene
	var scene_lc: PackedScene = load("res://scenes/LandClaim.tscn") as PackedScene
	if scene_cf == null or scene_lc == null:
		push_error("TERRITORY_BRAIN_INTEGRATION_FAIL: could not load scenes")
		quit(1)
		return

	# Enemy first so our LandClaim._ready / ClanBrain init sees them in group land_claims.
	var enemy: Node2D = scene_cf.instantiate()
	enemy.set("clan_name", "TBIV_Enemy")
	enemy.position = Vector2(500, 0)
	container.add_child(enemy)

	var ours: Node2D = scene_lc.instantiate()
	ours.set("clan_name", "TBIV_Home")
	ours.position = Vector2.ZERO
	container.add_child(ours)

	await process_frame

	var brain = ours.get("clan_brain")
	if brain == null:
		push_error("TERRITORY_BRAIN_INTEGRATION_FAIL: clan_brain missing on LandClaim")
		quit(1)
		return

	# Deterministic refresh (same as eval cycle).
	brain._refresh_nearby_enemies()

	var claims: Array = brain.nearby_enemy_claims
	var found_enemy_cf := false
	for n in claims:
		# Use group check (not `is Campfire`) so this tool script compiles before autoload globals exist in campfire.gd.
		if n and n.is_in_group("campfires") and str(n.get("clan_name")) == "TBIV_Enemy":
			found_enemy_cf = true
			break

	if not found_enemy_cf:
		push_error("TERRITORY_BRAIN_INTEGRATION_FAIL: expected enemy Campfire in nearby_enemy_claims, count=%d" % claims.size())
		quit(1)
		return

	print("TERRITORY_BRAIN_INTEGRATION_OK: nearby enemy Campfire detected (count=%d)" % claims.size())
	quit(0)
