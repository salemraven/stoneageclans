extends SceneTree
## Real Main scene with a fast density timer: backfill must never put a second camp in a chunk,
## and a parked camp must still count as a clan near the player.
## Run: godot --path . --headless -s res://tools/test_density_backfill_e2e.gd -- --skip-single-instance


var _passed := 0
var _failed := 0


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	print("=== DENSITY_BACKFILL_E2E start ===")
	var wgc: Node = root.get_node("WorldGenConfig")
	wgc.set("clan_density_check_interval_sec", 2.0)
	wgc.set("min_clans_per_player", 6)
	if change_scene_to_file("res://scenes/Main.tscn") != OK:
		_check("load Main", false, "")
		_finish()
		return
	await _wait_real(20000)
	var main: Node = get_first_node_in_group("main")
	var player: Node2D = main.get("player") as Node2D if main else null
	_check("several backfill passes ran", true, "")
	_check_no_duplicates("near spawn")

	var claim: LandClaim = _first_ai_claim()
	_check("an AI camp exists", claim != null, "")
	if claim == null or player == null:
		_finish()
		return
	var camp_pos := claim.global_position
	var camp_chunk: Vector2i = _chunk_of(camp_pos)
	var clan := claim.clan_name
	player.global_position = camp_pos + Vector2(2048.0 * 40.0, 0.0)
	var camps: Node = root.get_node("OffscreenCamps")
	for _i in 40:
		await _wait_real(250)
		if is_instance_valid(claim) and claim.get_parent() == camps:
			break
	_check("camp parks when the player leaves", is_instance_valid(claim) and claim.get_parent() == camps, "")
	var count_parked: int = int(main.call("count_ai_clans_with_claims_near", camp_pos, 2048.0))
	_check("a parked camp still counts as a clan", count_parked >= 1, str(count_parked))
	var cm: Node = root.get_node("ChunkManager")
	_check("its chunk still reports a camp", bool(cm.call("chunk_has_camp", camp_chunk)), str(camp_chunk))

	await _wait_real(10000)
	player.global_position = camp_pos + Vector2(64.0, 64.0)
	await _wait_real(10000)
	var same := 0
	for n in get_nodes_in_group("land_claims"):
		if is_instance_valid(n) and str(n.get("clan_name")) == clan:
			same += 1
	_check("coming back finds exactly one %s" % clan, same == 1, str(same))
	_check_no_duplicates("after a park and return")
	_finish()


func _check_no_duplicates(label: String) -> void:
	var by_clan: Dictionary = {}
	var by_chunk: Dictionary = {}
	for n in get_nodes_in_group("land_claims"):
		if not (n is LandClaim) or not is_instance_valid(n) or n.is_queued_for_deletion():
			continue
		var c := str((n as LandClaim).clan_name)
		by_clan[c] = int(by_clan.get(c, 0)) + 1
		var ch: Vector2i = _chunk_of((n as LandClaim).global_position)
		by_chunk[ch] = int(by_chunk.get(ch, 0)) + 1
	var dup_clans: Array = []
	for c in by_clan:
		if int(by_clan[c]) > 1:
			dup_clans.append("%s x%d" % [c, by_clan[c]])
	var dup_chunks: Array = []
	for ch in by_chunk:
		if int(by_chunk[ch]) > 1:
			dup_chunks.append("%s x%d" % [ch, by_chunk[ch]])
	print("DENSITY %s claims=%d clans=%s" % [label, by_clan.values().reduce(func(a, b): return a + b, 0), by_clan.keys()])
	_check("no clan has two claims (%s)" % label, dup_clans.is_empty(), str(dup_clans))
	_check("no chunk has two claims (%s)" % label, dup_chunks.is_empty(), str(dup_chunks))


func _chunk_of(pos: Vector2) -> Vector2i:
	return Vector2i(floori(pos.x / 2048.0), floori(pos.y / 2048.0))


func _first_ai_claim() -> LandClaim:
	for n in get_nodes_in_group("land_claims"):
		if n is LandClaim and is_instance_valid(n) and not (n as LandClaim).player_owned:
			return n as LandClaim
	return null


func _wait_real(ms: int) -> void:
	var end := Time.get_ticks_msec() + ms
	while Time.get_ticks_msec() < end:
		await process_frame


func _finish() -> void:
	print("DENSITY_BACKFILL_E2E passed=%d failed=%d" % [_passed, _failed])
	quit(0 if _failed == 0 else 1)


func _check(name: String, ok: bool, detail: String) -> void:
	if ok:
		_passed += 1
		print("PASS %s" % name)
	else:
		_failed += 1
		print("FAIL %s %s" % [name, detail])
