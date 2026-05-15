extends "res://scripts/npc/states/base_state.gd"

# Herder builds one Living Hut per delivered woman. Jobs are queued on herder meta "build_hut_queue".
# NPC is fully frozen in place for the entire duration (can_enter requires in-range).

const BUILD_DURATION: float = 20.0
const META_QUEUE := "build_hut_queue"
## Extra px beyond claim radius — herders can be shoved out by CharacterBody collisions while still "at home".
const CLAIM_ENTER_MARGIN_PX: float = 140.0
## Match main.gd AI_BUILDING_MIN_FROM_CLAIM / herder hut ring (not magic — same ring as _place_herder_hut).
const APPROACH_MIN_FROM_CLAIM: float = 120.0
const _PHASE_APPROACH: int = 0
const _PHASE_BUILDING: int = 1
## Stop walking when this close to approach anchor or already in the interior ring.
const APPROACH_ARRIVE_PX: float = 44.0

var woman: Node = null
var claim: Node = null
var build_timer: float = 0.0
var _exit_progress_cancelled: bool = false
var _phase: int = _PHASE_BUILDING
var _approach_anchor: Vector2 = Vector2.ZERO

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


func _claim_ring_bounds(claim: Node) -> Vector2:
	"""Returns (min_r, max_r) distance from claim center — same as main._place_herder_hut ring."""
	var radius: float = claim.get("radius") if claim.get("radius") != null else 400.0
	var min_r: float = APPROACH_MIN_FROM_CLAIM
	var max_r: float = maxf(min_r + 10.0, radius - 60.0)
	return Vector2(min_r, max_r)


func _in_interior_build_zone(claim: Node, pos: Vector2) -> bool:
	var c: Vector2 = claim.global_position
	var b: Vector2 = _claim_ring_bounds(claim)
	var d: float = pos.distance_to(c)
	# Margins so we are clearly off the claim edge and not hugging center.
	return d >= b.x + 12.0 and d <= b.y - 28.0


func _anchor_toward_interior(claim: Node, pos: Vector2) -> Vector2:
	"""Point on the valid hut ring along the spoke from claim center through the NPC (inward from border)."""
	var c: Vector2 = claim.global_position
	var b: Vector2 = _claim_ring_bounds(claim)
	var radial: Vector2 = pos - c
	if radial.length_squared() < 4.0:
		radial = Vector2.RIGHT.rotated(_npc_rngf() * TAU)
	else:
		radial = radial.normalized()
	var target_dist: float = (b.x + b.y) * 0.5
	return c + radial * clampf(target_dist, b.x, b.y)


func _try_begin_approach_or_build() -> void:
	if not npc or not claim or not is_instance_valid(claim):
		return
	if not woman or not is_instance_valid(woman):
		return
	if OccupationSystem and OccupationSystem.get_workplace(woman) != null:
		return
	if _in_interior_build_zone(claim, npc.global_position):
		_phase = _PHASE_BUILDING
		_freeze_npc()
		if npc.progress_display:
			_start_progress_manual()
		return
	_phase = _PHASE_APPROACH
	npc.set("is_building_hut", false)
	_approach_anchor = _anchor_toward_interior(claim, npc.global_position)
	if npc.steering_agent:
		npc.steering_agent.set_target_position_immediate(_approach_anchor)


func enter() -> void:
	_exit_progress_cancelled = false
	build_timer = 0.0
	_phase = _PHASE_BUILDING
	_sync_job_from_queue_head()
	if woman and OccupationSystem and OccupationSystem.get_workplace(woman) != null:
		woman = null
	_try_begin_approach_or_build()
	# If we never entered approach and never got a building freeze (e.g. invalid job), match old behavior.
	if _phase == _PHASE_BUILDING and npc and npc.get("is_building_hut") != true:
		_freeze_npc()

func _freeze_npc() -> void:
	if not npc:
		return
	npc.set("is_building_hut", true)
	npc.velocity = Vector2.ZERO
	if npc.steering_agent:
		npc.steering_agent.target_position = npc.global_position
		npc.steering_agent.target_node = null

func _start_progress_manual() -> void:
	if not npc or not npc.progress_display:
		return
	var icon_path: String = ResourceData.get_resource_icon_path(ResourceData.ResourceType.LIVING_HUT)
	var icon: Texture2D = load(icon_path) as Texture2D if icon_path else null
	npc.progress_display.collection_time = BUILD_DURATION
	npc.progress_display.start_collection(icon)
	# Kill the auto-tween so we can drive progress manually each frame
	if npc.progress_display.get("_collection_tween") and npc.progress_display._collection_tween:
		npc.progress_display._collection_tween.kill()
		npc.progress_display._collection_tween = null

func exit() -> void:
	if npc:
		npc.set("is_building_hut", false)
		if npc.has_meta("_hut_approach_last_steer"):
			npc.remove_meta("_hut_approach_last_steer")
		if npc.progress_display:
			npc.progress_display.stop_collection(_exit_progress_cancelled)
	_phase = _PHASE_BUILDING
	woman = null
	claim = null

func update(delta: float) -> void:
	if not npc:
		return
	# Agro / combat / ordered follow override building — NPC must react
	if _is_defending():
		_exit_progress_cancelled = true
		if fsm:
			fsm.change_state("defend")
		return
	if _is_in_combat():
		_exit_progress_cancelled = true
		if fsm:
			fsm.change_state("combat")
		return
	if _is_following():
		_exit_progress_cancelled = true
		if fsm:
			var nt: String = str(npc.get("npc_type")) if npc.get("npc_type") != null else ""
			if nt == "caveman" or nt == "clansman":
				fsm.change_state("party")
			else:
				fsm.change_state("herd")
		return
	if not npc.has_meta(META_QUEUE) or (npc.get_meta(META_QUEUE) as Array).is_empty():
		_fail_and_exit()
		return
	if not claim or not is_instance_valid(claim):
		_fail_and_exit()
		return
	if woman:
		if not is_instance_valid(woman):
			woman = null
		elif OccupationSystem and OccupationSystem.get_workplace(woman) != null:
			woman = null

	if _phase == _PHASE_APPROACH and (not woman or not is_instance_valid(woman)):
		_fail_and_exit()
		return

	if _phase == _PHASE_APPROACH:
		npc.set("is_building_hut", false)
		if claim and is_instance_valid(claim):
			if _in_interior_build_zone(claim, npc.global_position):
				_phase = _PHASE_BUILDING
				build_timer = 0.0
				_freeze_npc()
				if npc.progress_display and woman and is_instance_valid(woman):
					_start_progress_manual()
				return
			var to_anchor: float = npc.global_position.distance_to(_approach_anchor)
			if to_anchor <= APPROACH_ARRIVE_PX:
				_phase = _PHASE_BUILDING
				build_timer = 0.0
				_freeze_npc()
				if npc.progress_display and woman and is_instance_valid(woman):
					_start_progress_manual()
				return
			if npc.steering_agent:
				var now_s: float = Time.get_ticks_msec() / 1000.0
				var last_s: float = npc.get_meta("_hut_approach_last_steer", 0.0)
				if now_s - last_s >= 0.65:
					npc.set_meta("_hut_approach_last_steer", now_s)
					npc.steering_agent.set_arrive_target(_approach_anchor)
		return

	# Building phase: stay frozen every tick
	_freeze_npc()

	build_timer += delta
	if npc.progress_display:
		npc.progress_display.set_progress(build_timer / BUILD_DURATION)
	if build_timer >= BUILD_DURATION:
		_finish_build()

func _herder_owns_claim(claim: Node) -> bool:
	if not npc or not claim or not is_instance_valid(claim):
		return false
	if not npc.has_method("get_clan_name"):
		return false
	var cn: String = str(npc.get_clan_name())
	var cc: String = str(claim.get("clan_name")) if claim.get("clan_name") != null else ""
	if cn == "" or cc == "":
		return false
	return cn == cc


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
	# Own-clan claim: do not require standing inside the circle (NPCs can push the herder across the edge).
	if _herder_owns_claim(the_claim):
		return true
	var claim_pos: Vector2 = the_claim.global_position
	var radius: float = the_claim.get("radius") if the_claim.get("radius") != null else 400.0
	var dist: float = npc.global_position.distance_to(claim_pos)
	return dist <= radius + CLAIM_ENTER_MARGIN_PX

func get_priority() -> float:
	if NPCConfig:
		return NPCConfig.priority_build_hut_for_woman
	return 12.5

func _clear_queue_meta() -> void:
	if npc and npc.has_meta(META_QUEUE):
		npc.remove_meta(META_QUEUE)
	if npc and npc.has_meta("build_hut_for_woman"):
		npc.remove_meta("build_hut_for_woman")
	if npc and npc.has_meta("build_hut_for_woman_claim"):
		npc.remove_meta("build_hut_for_woman_claim")

func _fail_and_exit() -> void:
	_exit_progress_cancelled = true
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
		_try_begin_approach_or_build()
		return
	_clear_queue_meta()
	if fsm:
		fsm.change_state("wander")
