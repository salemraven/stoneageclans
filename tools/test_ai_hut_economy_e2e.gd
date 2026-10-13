extends SceneTree
## Real Main scene: an AI camp starts with a crop hut and an oven, its women carry and bake while
## the player watches, and the parked camp keeps baking off-screen.
## Run: godot --path . --headless -s res://tools/test_ai_hut_economy_e2e.gd -- --skip-single-instance

const HutCarryScript = preload("res://scripts/buildings/hut_carry.gd")

var _passed := 0
var _failed := 0


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	print("=== AI_HUT_ECONOMY_E2E start ===")
	var bc: Node = root.get_node("BalanceConfig")
	bc.set("crop_hut_grain_interval", 4.0)
	bc.set("bread_craft_time", 6.0)
	root.get_node("WorldGenConfig").set("settlement_tick_interval_sec", 5.0)
	if change_scene_to_file("res://scenes/Main.tscn") != OK:
		_check("load Main", false, "")
		_finish()
		return
	await _wait_real(4000)
	var main: Node = get_first_node_in_group("main")
	var player: Node2D = main.get("player") as Node2D if main else null
	var claim: LandClaim = null
	var home := player.global_position if player else Vector2.ZERO
	for step in 12:
		claim = _first_ai_claim_with_huts()
		if claim:
			break
		if player:
			player.global_position = home + Vector2(2048.0 * float(step + 1), 2048.0 * float(step % 3))
		await _wait_real(1500)
	_check("an AI camp with huts is loaded", claim != null, "")
	if claim == null or player == null:
		_finish()
		return
	var index: Node = root.get_node("ClaimBuildingIndex")
	var crop: Node = null
	var oven: Node = null
	for b in index.call("get_buildings_in_claim", claim):
		match str(b.get("hut_specialty")):
			"crop":
				crop = b
			"oven":
				oven = b
	_check("the camp starts with a crop hut and an oven", crop != null and oven != null, "")
	if crop == null or oven == null:
		_finish()
		return
	_check("no stone was left over from paying for the huts", claim.inventory.get_count(ResourceData.ResourceType.STONE) == 0, str(claim.inventory.get_count(ResourceData.ResourceType.STONE)))

	# Watch from just outside the claim so the camp is live but not alarmed.
	player.global_position = claim.global_position + Vector2(claim.radius + 300.0, 0.0)
	var bread_start := _bread(claim, oven)
	await _wait_real(30000)
	var bread_live := _bread(claim, oven)
	var oven_woman: Node = HutCarryScript.home_woman(oven)
	_check("the oven has a home woman", oven_woman != null, "")
	_check("women carry and the oven bakes while the player watches", bread_live > bread_start, "%d -> %d (oven grain=%d wood=%d bread=%d)" % [bread_start, bread_live, _count(oven, ResourceData.ResourceType.GRAIN), _count(oven, ResourceData.ResourceType.WOOD), _count(oven, ResourceData.ResourceType.BREAD)])
	print("AI_HUT live crop=%s oven=%s claim_grain=%d claim_bread=%d" % [_dump(crop), _dump(oven), claim.inventory.get_count(ResourceData.ResourceType.GRAIN), claim.inventory.get_count(ResourceData.ResourceType.BREAD)])

	var camps: Node = root.get_node("OffscreenCamps")
	player.global_position = claim.global_position + Vector2(2048.0 * 40.0, 0.0)
	for _i in 40:
		await _wait_real(250)
		if claim.get_parent() == camps:
			break
	_check("the camp parks", claim.get_parent() == camps, "")
	var bakes_parked: int = int(oven.get_meta("hut_crafts", 0))
	var crops_parked: int = int(crop.get_meta("hut_crafts", 0))
	await _wait_real(25000)
	var bakes_away: int = int(oven.get_meta("hut_crafts", 0))
	var crops_away: int = int(crop.get_meta("hut_crafts", 0))
	print("AI_HUT parked crop=%s oven=%s claim_grain=%d claim_bread=%d bakes %d->%d crops %d->%d" % [_dump(crop), _dump(oven), claim.inventory.get_count(ResourceData.ResourceType.GRAIN), claim.inventory.get_count(ResourceData.ResourceType.BREAD), bakes_parked, bakes_away, crops_parked, crops_away])
	_check("the parked oven keeps baking off-screen", bakes_away > bakes_parked, "%d -> %d" % [bakes_parked, bakes_away])
	_check("the parked crop hut keeps growing grain off-screen", crops_away > crops_parked, "%d -> %d" % [crops_parked, crops_away])

	player.global_position = claim.global_position + Vector2(claim.radius + 300.0, 0.0)
	await _wait_real(6000)
	_check("coming back shows the same oven, still counting its bakes", is_instance_valid(oven) and oven.get_parent() != camps and int(oven.get_meta("hut_crafts", 0)) >= bakes_away, str(oven.get_meta("hut_crafts", 0)))
	_finish()


func _bread(claim: LandClaim, oven: Node) -> int:
	return claim.inventory.get_count(ResourceData.ResourceType.BREAD) + _count(oven, ResourceData.ResourceType.BREAD)


func _count(b: Node, t: int) -> int:
	var inv: InventoryData = b.get("inventory") as InventoryData
	return inv.get_count(t) if inv else 0


func _dump(b: Node) -> String:
	var inv: InventoryData = b.get("inventory") as InventoryData
	var parts: Array = []
	if inv:
		for s in inv.slots:
			if s is Dictionary and not (s as Dictionary).is_empty():
				parts.append("%s:%d" % [ResourceData.get_resource_name(int(s["type"])), int(s["count"])])
	return "[" + ",".join(parts) + "]"


func _first_ai_claim_with_huts() -> LandClaim:
	var index: Node = root.get_node("ClaimBuildingIndex")
	for n in get_nodes_in_group("land_claims"):
		if not (n is LandClaim) or not is_instance_valid(n) or (n as LandClaim).player_owned:
			continue
		if (index.call("get_buildings_in_claim", n) as Array).size() >= 2:
			return n as LandClaim
	return null


func _wait_real(ms: int) -> void:
	var end := Time.get_ticks_msec() + ms
	while Time.get_ticks_msec() < end:
		await process_frame


func _finish() -> void:
	print("AI_HUT_ECONOMY_E2E passed=%d failed=%d" % [_passed, _failed])
	quit(0 if _failed == 0 else 1)


func _check(name: String, ok: bool, detail: String) -> void:
	if ok:
		_passed += 1
		print("PASS %s" % name)
	else:
		_failed += 1
		print("FAIL %s %s" % [name, detail])
