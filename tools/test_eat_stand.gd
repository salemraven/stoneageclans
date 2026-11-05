extends SceneTree
## Eating from the claim must hold the man where he is, and a deposit walk
## must aim at his own spot on the circle, not the claim center.
## Run: godot --headless --path . -s res://tools/test_eat_stand.gd -- --skip-single-instance

var _failed := 0


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	await process_frame
	await _test_eat_holds_still()
	await _test_deposit_does_not_aim_at_center()
	print("EAT_STAND_TEST failed=%d" % _failed)
	quit(0 if _failed == 0 else 1)


func _test_eat_holds_still() -> void:
	var world := Node2D.new()
	world.name = "EatStandWorld"
	root.add_child(world)
	var claim := LandClaim.new()
	claim.clan_name = "TEST"
	claim.player_owned = true
	world.add_child(claim)
	claim.global_position = Vector2.ZERO
	var inv: Variant = claim.get("inventory")
	if inv == null or not inv.has_method("add_item") or not inv.add_item(ResourceData.ResourceType.BREAD, 4):
		_fail("claim has no bread")
		world.queue_free()
		return
	var scene: PackedScene = load("res://scenes/NPC.tscn") as PackedScene
	var man: Node = scene.instantiate()
	man.set("npc_type", "clansman")
	man.set("npc_name", "BITE")
	world.add_child(man)
	if man.has_method("set_clan_name"):
		man.set_clan_name("TEST", "eat_stand")
	for _i in 8:
		await process_frame
	var stats: Node = man.get("stats_component")
	if stats:
		stats.set("calories", 0.0)
		if stats.has_method("_sync_hunger_from_calories"):
			stats._sync_hunger_from_calories()
	var start := Vector2(90.0, 40.0)
	man.global_position = start
	man.velocity = (Vector2.ZERO - start).normalized() * 80.0
	var steer: Node = man.get("steering_agent")
	if steer and steer.has_method("set_arrive_target"):
		steer.set_arrive_target(claim.global_position)
	var fsm: Node = man.get("fsm")
	if fsm == null or not fsm.has_method("change_state"):
		_fail("clansman has no fsm")
		world.queue_free()
		return
	fsm.change_state("eat")
	var moved := 0.0
	for _i in 40:
		await physics_frame
		moved = man.global_position.distance_to(start)
	var mode: int = int(steer.get("current_mode")) if steer else -1
	var hold: int = int(steer.SteeringMode.HOLD) if steer else -2
	var icon: Texture2D = null
	var progress: Node = man.get("progress_display")
	if progress:
		icon = progress.get("_item_icon") as Texture2D
	var icon_path := ""
	if icon:
		icon_path = icon.resource_path
	var bread_path := ResourceData.get_resource_icon_path(ResourceData.ResourceType.BREAD)
	var berry_path := ResourceData.get_resource_icon_path(ResourceData.ResourceType.BERRIES)
	var state_name := str(fsm.get_current_state_name()) if fsm.has_method("get_current_state_name") else "?"
	print("EAT_STAND moved=%.2f mode=%d state=%s icon=%s" % [moved, mode, state_name, icon_path])
	var ok := true
	if moved > 6.0:
		_fail("he kept walking while eating")
		ok = false
	if mode != hold:
		_fail("eat did not hold him")
		ok = false
	if icon_path == berry_path or icon_path != bread_path:
		_fail("meal icon was not the bread he is eating")
		ok = false
	if ok:
		print("EAT_STAND_PASS")
	world.queue_free()


func _test_deposit_does_not_aim_at_center() -> void:
	var world := Node2D.new()
	world.name = "DepositRingWorld"
	root.add_child(world)
	var claim := LandClaim.new()
	claim.clan_name = "TEST"
	claim.player_owned = true
	world.add_child(claim)
	claim.global_position = Vector2.ZERO
	var scene: PackedScene = load("res://scenes/NPC.tscn") as PackedScene
	var names := ["RINGA", "RINGB"]
	var targets: Array[Vector2] = []
	for npc_name in names:
		var man: Node = scene.instantiate()
		man.set("npc_type", "clansman")
		man.set("npc_name", npc_name)
		world.add_child(man)
		if man.has_method("set_clan_name"):
			man.set_clan_name("TEST", "eat_stand")
		for _i in 6:
			await process_frame
		var hands: Variant = man.get("inventory")
		if hands == null or not hands.has_method("add_item"):
			_fail("no inventory")
			world.queue_free()
			return
		hands.add_item(ResourceData.ResourceType.WOOD, 3)
		man.global_position = Vector2(420.0, 30.0 if npc_name == "RINGB" else -30.0)
		man.set_meta("moving_to_deposit", true)
		man.set_meta("is_depositing", true)
		var fsm: Node = man.get("fsm")
		var wander: Node = fsm._get_state("wander") if fsm and fsm.has_method("_get_state") else null
		if wander == null or not wander.has_method("update"):
			_fail("no wander state")
			world.queue_free()
			return
		fsm.change_state("wander")
		wander.update(0.05)
		var steer: Node = man.get("steering_agent")
		var aim: Vector2 = steer.get("target_position") if steer else Vector2.INF
		targets.append(aim)
		print("DEPOSIT_AIM %s %s" % [npc_name, aim])
	var ok := true
	for aim in targets:
		if aim.distance_to(Vector2.ZERO) < 70.0:
			_fail("deposit aimed at the claim center")
			ok = false
	if targets.size() == 2 and targets[0].distance_to(targets[1]) < 20.0:
		_fail("both men were sent to the same spot")
		ok = false
	if ok:
		print("DEPOSIT_RING_PASS")
	world.queue_free()


func _fail(msg: String) -> void:
	_failed += 1
	print("EAT_STAND_FAIL %s" % msg)
