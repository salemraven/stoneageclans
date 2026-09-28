extends SceneTree

## Frozen throw geometry harness. Run:
##   godot --path . --headless -s res://tools/test_throw_hit.gd

const ThrowHitResolver = preload("res://scripts/combat/throw_hit_resolver.gd")

var _failures: Array[String] = []
var _world: Node2D


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	await process_frame
	print("=== Throw hit resolver lock-in ===")
	_world = Node2D.new()
	_world.name = "ThrowHitTestWorld"
	root.add_child(_world)

	_test_hit_point_offset()
	_test_range_clamp()
	_test_npc_lands_on_target_not_max_range()
	await _test_offset_matrix()
	await _test_snap()
	await _test_ally_skip()
	await _test_dead_skip()
	_test_hit_chance_always_one()

	if _failures.is_empty():
		print("TEST_THROW_HIT: all checks passed")
		print("recommended throw_land_hit_radius_px = %.1f (BalanceConfig)" % ThrowHitResolver.land_hit_radius_px())
		quit(0)
	else:
		print("TEST_THROW_HIT: FAIL (%d)" % _failures.size())
		for f in _failures:
			print("  - ", f)
		quit(1)


func _fail(msg: String) -> void:
	_failures.append(msg)
	print("FAIL: ", msg)


func _make_pawn(pawn_name: String, pos: Vector2, group: String, clan: String = "") -> Node2D:
	var n := Node2D.new()
	var scr := GDScript.new()
	scr.source_code = "extends Node2D\nvar clan_name: String = \"\"\n"
	var err := scr.reload()
	if err != OK:
		_fail("pawn script reload failed")
	n.set_script(scr)
	n.name = pawn_name
	n.clan_name = clan
	_world.add_child(n)
	n.add_to_group(group)
	n.global_position = pos
	return n


func _test_hit_point_offset() -> void:
	var target := _make_pawn("HitPoint", Vector2(100, 200), "npcs")
	var hp: Vector2 = ThrowHitResolver.get_hit_point(target)
	var expected_y: float = 200.0 - ThrowHitResolver.get_display_height(target) * ThrowHitResolver.torso_height_frac()
	if not is_equal_approx(hp.x, 100.0) or absf(hp.y - expected_y) > 0.05:
		_fail("hit point expected (100, %.2f) got %s" % [expected_y, hp])
	else:
		print("  hit_point torso offset OK y=%.2f" % hp.y)
	target.queue_free()


func _test_range_clamp() -> void:
	var origin := Vector2.ZERO
	var far := Vector2(800, 0)
	var land: Vector2 = ThrowHitResolver.clamp_land_to_range(origin, far)
	var cap: float = ThrowHitResolver.throw_range_px()
	if absf(land.x - cap) > 0.05 or absf(land.y) > 0.05:
		_fail("clamp expected x=%.1f got %s" % [cap, land])
	else:
		print("  range clamp OK (%.1f px)" % cap)


func _test_npc_lands_on_target_not_max_range() -> void:
	var thrower := _make_pawn("ThrowerNpc", Vector2.ZERO, "npcs", "A")
	var victim := _make_pawn("VictimNear", Vector2(200, 0), "npcs", "B")
	var land: Vector2 = ThrowHitResolver.resolve_npc_landing(thrower, victim, Vector2.RIGHT)
	var hp: Vector2 = ThrowHitResolver.get_hit_point(victim)
	if land.distance_to(hp) > 0.05:
		_fail("NPC land should be target hit point %s got %s" % [hp, land])
	if land.length() > 250.0:
		_fail("NPC land must not use max throw range when target is near: %s" % land)
	else:
		print("  NPC land-at-target OK dist=%.1f" % land.length())
	thrower.queue_free()
	victim.queue_free()


func _test_offset_matrix() -> void:
	var thrower := _make_pawn("Thrower", Vector2(-300, 0), "player")
	var target := _make_pawn("Frozen", Vector2.ZERO, "npcs", "WILD")
	await process_frame
	var hp: Vector2 = ThrowHitResolver.get_hit_point(target)
	var radius: float = ThrowHitResolver.land_hit_radius_px()
	var cases: Array = [
		{"off": 0.0, "want": true},
		{"off": 16.0, "want": true},
		{"off": 32.0, "want": true},
		{"off": radius, "want": true},
		{"off": radius + 16.0, "want": false},
		{"off": 80.0, "want": false},
	]
	print("  offset matrix radius=%.1f hit_point=%s" % [radius, hp])
	for c in cases:
		var off: float = float(c["off"])
		var land: Vector2 = hp + Vector2(off, 0.0)
		var found: Node2D = ThrowHitResolver.find_best_target_at_point(land, radius, thrower, self)
		var hit: bool = found == target
		var want: bool = bool(c["want"])
		print("    offset %.1f -> %s (want %s)" % [off, "HIT" if hit else "MISS", "HIT" if want else "MISS"])
		if hit != want:
			_fail("offset %.1f expected %s" % [off, "HIT" if want else "MISS"])
	thrower.queue_free()
	target.queue_free()


func _test_snap() -> void:
	var thrower := _make_pawn("SnapThrower", Vector2(-200, 0), "player")
	var target := _make_pawn("SnapTarget", Vector2.ZERO, "npcs", "WILD")
	await process_frame
	var hp: Vector2 = ThrowHitResolver.get_hit_point(target)
	var cursor: Vector2 = hp + Vector2(ThrowHitResolver.snap_radius_px() * 0.5, 0.0)
	var snapped: Vector2 = ThrowHitResolver.snap_landing_if_target(cursor, thrower, self)
	if snapped.distance_to(hp) > 0.05:
		_fail("snap expected hit point %s got %s" % [hp, snapped])
	else:
		print("  snap to torso OK")
	var miss_cursor: Vector2 = hp + Vector2(ThrowHitResolver.snap_radius_px() + 20.0, 0.0)
	var unsnapped: Vector2 = ThrowHitResolver.snap_landing_if_target(miss_cursor, thrower, self)
	if unsnapped.distance_to(miss_cursor) > 0.05:
		_fail("cursor outside snap radius should stay put")
	thrower.queue_free()
	target.queue_free()


func _test_ally_skip() -> void:
	var thrower := _make_pawn("AllyThrower", Vector2(-80, 0), "npcs", "SAME")
	var ally := _make_pawn("AllyVictim", Vector2.ZERO, "npcs", "SAME")
	await process_frame
	if ThrowHitResolver.is_valid_throw_victim(thrower, ally):
		_fail("same-clan NPC must not be a throw victim")
	else:
		print("  ally skip OK")
	var found: Node2D = ThrowHitResolver.find_best_target_at_point(
		ThrowHitResolver.get_hit_point(ally), ThrowHitResolver.land_hit_radius_px(), thrower, self
	)
	if found != null:
		_fail("find_best must skip ally, got %s" % found.name)
	thrower.queue_free()
	ally.queue_free()


func _test_dead_skip() -> void:
	var thrower := _make_pawn("DeadThrower", Vector2(-80, 0), "player")
	var corpse := _make_pawn("Corpse", Vector2.ZERO, "npcs", "WILD")
	var hc := Node.new()
	hc.name = "HealthComponent"
	var hc_scr := GDScript.new()
	hc_scr.source_code = "extends Node\nvar is_dead: bool = true\n"
	hc_scr.reload()
	hc.set_script(hc_scr)
	corpse.add_child(hc)
	await process_frame
	if ThrowHitResolver.is_valid_throw_victim(thrower, corpse):
		_fail("dead NPC must not be a throw victim")
	else:
		print("  dead skip OK")
	thrower.queue_free()
	corpse.queue_free()


func _test_hit_chance_always_one() -> void:
	if ThrowHitResolver.use_skill_hit_chance():
		print("  skip chance lock (throw_use_skill_hit_chance is on)")
		return
	if not ThrowHitResolver.roll_hit(null, Vector2.ZERO):
		_fail("skill gate off must always hit (no RNG)")
	else:
		print("  hit chance 100% (skill gate off) OK")
