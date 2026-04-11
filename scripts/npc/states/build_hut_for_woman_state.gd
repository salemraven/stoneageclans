extends "res://scripts/npc/states/base_state.gd"

# Herder builds one Living Hut per delivered woman. Jobs are queued on herder meta "build_hut_queue".

const BUILD_DURATION: float = 20.0
const META_QUEUE := "build_hut_queue"

var woman: Node = null
var claim: Node = null
var build_timer: float = 0.0

func _sync_job_from_queue_head() -> bool:
	woman = null
	claim = null
	if not npc or not npc.has_meta(META_QUEUE):
		return false
	var q: Array = npc.get_meta(META_QUEUE) as Array
	if q.is_empty():
		return false
	var job: Variant = q[0]
	if job is Dictionary:
		woman = job.get("woman") as Node
		claim = job.get("claim") as Node
	if woman and not is_instance_valid(woman):
		woman = null
	if claim and not is_instance_valid(claim):
		claim = null
	if not claim and npc.has_method("get_my_land_claim"):
		claim = npc.get_my_land_claim()
	return woman != null and is_instance_valid(woman) and claim != null and is_instance_valid(claim)

func enter() -> void:
	build_timer = 0.0
	_sync_job_from_queue_head()
	if woman and OccupationSystem and OccupationSystem.get_workplace(woman) != null:
		woman = null
	if npc and npc.progress_display and woman:
		_start_progress_icon()

func _start_progress_icon() -> void:
	if not npc or not npc.progress_display:
		return
	var icon_path: String = ResourceData.get_resource_icon_path(ResourceData.ResourceType.LIVING_HUT)
	var icon: Texture2D = load(icon_path) as Texture2D if icon_path else null
	npc.progress_display.collection_time = BUILD_DURATION
	npc.progress_display.start_collection(icon)

func exit() -> void:
	if npc and npc.progress_display:
		npc.progress_display.stop_collection()
	woman = null
	claim = null

func update(delta: float) -> void:
	if not npc:
		return
	if not npc.has_meta(META_QUEUE) or (npc.get_meta(META_QUEUE) as Array).is_empty():
		_fail_and_exit()
		return
	if not claim or not is_instance_valid(claim):
		_fail_and_exit()
		return
	var dist: float = npc.global_position.distance_to(claim.global_position)
	var claim_radius: float = claim.get("radius") if claim.get("radius") != null else 400.0
	if woman:
		if not is_instance_valid(woman):
			woman = null
		elif OccupationSystem and OccupationSystem.get_workplace(woman) != null:
			woman = null
	if dist <= claim_radius + 15.0:
		build_timer += delta
	if build_timer >= BUILD_DURATION:
		_finish_build()

func can_enter() -> bool:
	if not npc:
		return false
	if npc.get("npc_type") != "caveman" and npc.get("npc_type") != "clansman":
		return false
	if not npc.has_meta(META_QUEUE):
		return false
	var q: Array = npc.get_meta(META_QUEUE) as Array
	if q.is_empty():
		return false
	var job: Variant = q[0]
	if job is Dictionary:
		var w: Node = job.get("woman") as Node
		if not w or not is_instance_valid(w):
			return false
	var the_claim: Node = null
	if job is Dictionary:
		the_claim = job.get("claim") as Node
	if not the_claim or not is_instance_valid(the_claim):
		the_claim = npc.get_my_land_claim() if npc.has_method("get_my_land_claim") else null
	if not the_claim or not is_instance_valid(the_claim):
		return false
	var claim_pos: Vector2 = the_claim.global_position
	var radius: float = the_claim.get("radius") if the_claim.get("radius") != null else 400.0
	var dist: float = npc.global_position.distance_to(claim_pos)
	return dist <= radius

func get_priority() -> float:
	return 12.5

func _clear_queue_meta() -> void:
	if npc and npc.has_meta(META_QUEUE):
		npc.remove_meta(META_QUEUE)
	if npc and npc.has_meta("build_hut_for_woman"):
		npc.remove_meta("build_hut_for_woman")
	if npc and npc.has_meta("build_hut_for_woman_claim"):
		npc.remove_meta("build_hut_for_woman_claim")

func _fail_and_exit() -> void:
	_clear_queue_meta()
	if fsm:
		fsm.change_state("wander")

func _finish_build() -> void:
	var main = get_tree().get_first_node_in_group("main")
	if not main or not main.has_method("_place_herder_hut"):
		_fail_and_exit()
		return
	if not npc.has_meta(META_QUEUE):
		_fail_and_exit()
		return
	var q: Array = npc.get_meta(META_QUEUE) as Array
	if q.is_empty():
		_fail_and_exit()
		return

	if woman and is_instance_valid(woman) and claim and is_instance_valid(claim):
		if not OccupationSystem or OccupationSystem.get_workplace(woman) == null:
			main._place_herder_hut(claim, woman, npc)

	q.pop_front()
	npc.set_meta(META_QUEUE, q)

	if q.is_empty():
		_clear_queue_meta()
		if fsm:
			fsm.change_state("wander")
		return

	build_timer = 0.0
	_prepare_next_job_or_exit()

func _prepare_next_job_or_exit() -> void:
	while npc.has_meta(META_QUEUE):
		var q: Array = npc.get_meta(META_QUEUE) as Array
		if q.is_empty():
			break
		if not _sync_job_from_queue_head():
			q.pop_front()
			npc.set_meta(META_QUEUE, q)
			continue
		if not woman or not is_instance_valid(woman):
			q.pop_front()
			npc.set_meta(META_QUEUE, q)
			continue
		if OccupationSystem and OccupationSystem.get_workplace(woman) != null:
			q.pop_front()
			npc.set_meta(META_QUEUE, q)
			continue
		_start_progress_icon()
		return
	_clear_queue_meta()
	if fsm:
		fsm.change_state("wander")
