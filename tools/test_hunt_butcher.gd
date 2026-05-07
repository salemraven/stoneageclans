extends SceneTree
# Headless butcher yield test (`godot --script`). Spawns butcher via load(...).new() (global class ctor not always available early).
#
# SKIP_SINGLE_INSTANCE=1 godot --headless --path <repo> --script res://tools/test_hunt_butcher.gd

const NPC_SCENE := preload("res://scenes/NPC.tscn")


func _init() -> void:
	call_deferred("_run")


func _fail(msg: String) -> void:
	push_error("TEST_HUNT_BUTCHER_FAIL: %s" % msg)


func _cleanup(a: Node, b: Node) -> void:
	if a != null and is_instance_valid(a):
		a.queue_free()
	if b != null and is_instance_valid(b):
		b.queue_free()


func _corpse_yield_sum(n: Node) -> int:
	if n == null or not is_instance_valid(n):
		return 0
	return int(n.get_meta("meat_remaining", 0)) + int(n.get_meta("hide_remaining", 0)) + int(n.get_meta("bone_remaining", 0))


func _spawn_butcher_task(corpse_node: Node) -> Task:
	var scr: GDScript = load("res://scripts/ai/tasks/butcher_task.gd") as GDScript
	if scr == null:
		return null
	return scr.new(corpse_node) as Task


func _spawn_job_with_task(task_ref: Task) -> Job:
	var scrj: GDScript = load("res://scripts/ai/jobs/job.gd") as GDScript
	if scrj == null:
		return null
	var jo: Job = scrj.new() as Job
	jo.add_task(task_ref)
	return jo


## Run butcher once to completion via TaskRunner (~1 extraction per job).
func _await_butcher_via_runner(npc: NPCBase, runner: Node, corpse: Node) -> bool:
	var task_ref := _spawn_butcher_task(corpse)
	if task_ref == null:
		hunt_pause_abort(npc, false)
		return false
	var job_ref := _spawn_job_with_task(task_ref)
	if job_ref == null:
		hunt_pause_abort(npc, false)
		return false
	hunt_pause_abort(npc, true)
	runner.assign_job(job_ref)
	var i := 0
	while runner.has_job():
		await physics_frame
		i += 1
		if i > 2000:
			hunt_pause_abort(npc, false)
			return false
	hunt_pause_abort(npc, false)
	return true


## Toggle meta so butcher movement/slice isn’t aborted by ordered-follow guards in tests.
func hunt_pause_abort(npc: NPCBase, on: bool) -> void:
	if on:
		npc.set_meta("hunt_butchering", true)
	else:
		if npc.has_meta("hunt_butchering"):
			npc.remove_meta("hunt_butchering")


func _run() -> void:
	await process_frame
	const PHYS_DELTA := 1.0 / 60.0

	var rr := get_root()
	if rr.get_node_or_null("/root/NPCConfig") == null:
		_fail("/root/NPCConfig missing")
		quit(1)
		return

	var corpse := Node2D.new()
	corpse.name = "TestCorpseDeer"
	corpse.set_meta("npc_type", "deer")
	corpse.set_meta("meat_remaining", 2)
	corpse.set_meta("hide_remaining", 1)
	corpse.set_meta("bone_remaining", 0)
	rr.add_child(corpse)
	corpse.global_position = Vector2(40.0, 0.0)

	var npc_inst = NPC_SCENE.instantiate()
	var npc := npc_inst as NPCBase
	if npc == null:
		corpse.queue_free()
		_fail("NPC instantiate / cast")
		quit(1)
		return

	npc.npc_type = "caveman"
	npc.npc_name = "TestButcher"
	# Default caveman fills 5 slots with berry + land claim; keep room for butcher yields.
	npc.set_meta("has_land_claim", true)
	npc.follow_is_ordered = true
	npc.global_position = Vector2.ZERO
	rr.add_child(npc)

	await process_frame
	await process_frame

	var runner: Node = npc.task_runner
	if runner == null:
		_fail("task_runner null")
		_cleanup(npc, corpse)
		quit(1)
		return

	while _corpse_yield_sum(corpse) > 0:
		if npc.inventory and not npc.inventory.has_space():
			_fail("inventory full early")
			_cleanup(npc, corpse)
			quit(1)
			return

		hunt_pause_abort(npc, true)
		var butcher: Task = _spawn_butcher_task(corpse)
		if butcher == null:
			_cleanup(npc, corpse)
			quit(1)
			return
		butcher.start(npc)
		var step: Task.TaskStatus = Task.TaskStatus.RUNNING
		while step == Task.TaskStatus.RUNNING:
			await physics_frame
			step = butcher.tick(npc, PHYS_DELTA)
		hunt_pause_abort(npc, false)
		if step != Task.TaskStatus.SUCCESS:
			_fail("butcher task did not succeed (status=%s)" % str(step))
			_cleanup(npc, corpse)
			quit(1)
			return

	# Deferred free — flush at least one frame before asserting gone.
	await physics_frame
	await physics_frame

	if npc.inventory == null:
		_fail("inventory missing")
		_cleanup(npc, corpse)
		quit(1)
		return

	var meat_c: int = npc.inventory.get_count(ResourceData.ResourceType.MEAT)
	var hide_c: int = npc.inventory.get_count(ResourceData.ResourceType.HIDE)
	if meat_c != 2 or hide_c != 1:
		_fail("yield counts meat=%d hide=%d" % [meat_c, hide_c])
		_cleanup(npc, corpse)
		quit(1)
		return

	if is_instance_valid(corpse):
		_fail("expected corpse freed when depleted")
		_cleanup(npc, corpse)
		quit(1)
		return

	# ── TaskRunner path: hunt_butchering meta allows ordered followers to butcher ──
	var corpse_abort := Node2D.new()
	corpse_abort.name = "TestCorpseAbort"
	corpse_abort.set_meta("npc_type", "deer")
	corpse_abort.set_meta("meat_remaining", 1)
	corpse_abort.set_meta("hide_remaining", 0)
	corpse_abort.set_meta("bone_remaining", 0)
	rr.add_child(corpse_abort)
	corpse_abort.global_position = npc.global_position + Vector2(28.0, 0.0)

	var meat0: int = npc.inventory.get_count(ResourceData.ResourceType.MEAT)
	if not await _await_butcher_via_runner(npc, runner, corpse_abort):
		_fail("butcher_via_runner timed out")
		_cleanup(npc, corpse_abort)
		quit(1)
		return
	if npc.inventory.get_count(ResourceData.ResourceType.MEAT) <= meat0:
		_fail("expected at least one meat extracted via hunt_butchering bypass")
		_cleanup(npc, corpse_abort)
		quit(1)
		return

	# Without hunt_butchering, TaskRunner should cancel the job (no inventory change).
	var meat1: int = npc.inventory.get_count(ResourceData.ResourceType.MEAT)
	var block_corp := Node2D.new()
	block_corp.name = "TestBlockingCorpse"
	block_corp.set_meta("npc_type", "deer")
	block_corp.set_meta("meat_remaining", 8)
	block_corp.set_meta("hide_remaining", 0)
	block_corp.set_meta("bone_remaining", 0)
	rr.add_child(block_corp)
	block_corp.global_position = npc.global_position + Vector2(32.0, 0.0)

	var bt := _spawn_butcher_task(block_corp)
	if bt == null:
		block_corp.queue_free()
		_cleanup(npc, corpse_abort)
		quit(1)
		return
	var jb := _spawn_job_with_task(bt)
	if jb == null:
		block_corp.queue_free()
		_cleanup(npc, corpse_abort)
		quit(1)
		return
	runner.assign_job(jb)
	for _i in range(24):
		await physics_frame

	if runner.has_job():
		_fail("expected job cancelled when follow_is_ordered without hunt_butchering")
		if is_instance_valid(block_corp):
			block_corp.queue_free()
		_cleanup(npc, corpse_abort)
		quit(1)
		return
	var meat_after: int = npc.inventory.get_count(ResourceData.ResourceType.MEAT)
	if meat_after != meat1:
		_fail("inventory changed after abort path (want %d got %d)" % [meat1, meat_after])
		if is_instance_valid(block_corp):
			block_corp.queue_free()
		_cleanup(npc, corpse_abort)
		quit(1)
		return

	if is_instance_valid(block_corp):
		block_corp.queue_free()
	if is_instance_valid(corpse_abort):
		corpse_abort.queue_free()

	print("TEST_HUNT_BUTCHER_OK")
	_cleanup(npc, null)
	quit(0)
