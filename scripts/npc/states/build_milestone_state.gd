extends "res://scripts/npc/states/base_state.gd"

# Clansman builds milestone buildings (Oven, Drying Rack, Farm, Dairy) for AI clans.
# Claims a pending build_request from ClanBrain, walks to site, shows progress ring, then places building.
# Follows same pattern as build_hut_for_woman_state.gd (approach + building phases).

const _PHASE_APPROACH: int = 0
const _PHASE_BUILDING: int = 1
const APPROACH_ARRIVE_PX: float = 44.0
const CLAIM_ENTER_MARGIN_PX: float = 140.0

var build_request: Dictionary = {}
var build_pos: Vector2 = Vector2.ZERO
var build_timer: float = 0.0
var build_duration: float = 18.0
var _phase: int = _PHASE_APPROACH
var _exit_progress_cancelled: bool = false
var _build_start_position: Vector2 = Vector2.ZERO
var _move_cancel_threshold: float = 32.0


func _get_clan_brain() -> RefCounted:
	if not npc:
		return null
	var claim: Node = npc.get_my_land_claim() if npc.has_method("get_my_land_claim") else null
	if not claim:
		return null
	return claim.get("brain") as RefCounted


func _sync_from_claimed_request() -> bool:
	build_request = {}
	build_pos = Vector2.ZERO
	var brain: RefCounted = _get_clan_brain()
	if not brain:
		return false
	if not brain.has_method("claim_build_request"):
		return false
	build_request = brain.claim_build_request(npc)
	if build_request.is_empty():
		return false
	build_pos = build_request.get("build_pos", Vector2.ZERO)
	if build_pos == Vector2.ZERO:
		return false
	if BalanceConfig:
		build_duration = float(BalanceConfig.ai_milestone_build_duration_sec)
	return true


func _load_move_cancel_threshold() -> void:
	if NPCConfig and "gather_move_cancel_threshold" in NPCConfig:
		_move_cancel_threshold = float(NPCConfig.gather_move_cancel_threshold)


func enter() -> void:
	_exit_progress_cancelled = false
	build_timer = 0.0
	_phase = _PHASE_APPROACH
	_load_move_cancel_threshold()
	if not _sync_from_claimed_request():
		_fail_and_exit()
		return
	_start_approach()


func _start_approach() -> void:
	_phase = _PHASE_APPROACH
	npc.set("is_building_milestone", false)
	if npc.steering_agent:
		npc.steering_agent.set_target_position_immediate(build_pos)


func _begin_building_phase() -> void:
	if not npc:
		return
	_phase = _PHASE_BUILDING
	build_timer = 0.0
	_build_start_position = npc.global_position
	_freeze_npc()
	_start_progress_manual()


func _freeze_npc() -> void:
	if not npc:
		return
	npc.set("is_building_milestone", true)
	npc.velocity = Vector2.ZERO
	if npc.steering_agent:
		npc.steering_agent.set_target_position_immediate(npc.global_position)


func _start_progress_manual() -> void:
	if not npc or not npc.progress_display:
		return
	var building_type: Variant = build_request.get("building_type")
	var icon_path: String = ResourceData.get_resource_icon_path(building_type) if building_type != null else ""
	var icon: Texture2D = load(icon_path) as Texture2D if icon_path else null
	npc.progress_display.collection_time = build_duration
	npc.progress_display.start_collection(icon)
	if npc.progress_display.get("_collection_tween") and npc.progress_display._collection_tween:
		npc.progress_display._collection_tween.kill()
		npc.progress_display._collection_tween = null


func _stop_build_progress(cancelled: bool) -> void:
	if npc and npc.progress_display:
		npc.progress_display.stop_collection(cancelled)


func exit() -> void:
	if npc:
		npc.set("is_building_milestone", false)
		if npc.progress_display:
			npc.progress_display.stop_collection(_exit_progress_cancelled)
	_phase = _PHASE_APPROACH
	build_request = {}
	build_pos = Vector2.ZERO


func update(delta: float) -> void:
	if not npc:
		return
	if _is_defending():
		_release_and_exit("defend")
		if fsm:
			fsm.change_state("defend")
		return
	if _is_in_combat():
		_release_and_exit("combat")
		if fsm:
			fsm.change_state("combat")
		return
	if _is_following() and _phase != _PHASE_BUILDING and build_timer <= 0.0:
		_release_and_exit("follow")
		if fsm:
			var nt: String = str(npc.get("npc_type")) if npc.get("npc_type") != null else ""
			if nt == "caveman" or nt == "clansman":
				fsm.change_state("party")
			else:
				fsm.change_state("herd")
		return

	if build_request.is_empty() or build_pos == Vector2.ZERO:
		_fail_and_exit()
		return

	if _phase == _PHASE_APPROACH:
		npc.set("is_building_milestone", false)
		var dist: float = npc.global_position.distance_to(build_pos)
		if dist <= APPROACH_ARRIVE_PX:
			_begin_building_phase()
			return
		if npc.steering_agent:
			var now_s: float = Time.get_ticks_msec() / 1000.0
			var last_s: float = npc.get_meta("_milestone_approach_last_steer", 0.0)
			if now_s - last_s >= 0.65:
				npc.set_meta("_milestone_approach_last_steer", now_s)
				npc.steering_agent.set_arrive_target(build_pos)
		return

	_freeze_npc()
	var moved: float = npc.global_position.distance_to(_build_start_position)
	if moved > _move_cancel_threshold:
		_restart_approach_after_move_interrupt()
		return

	build_timer += delta
	if npc.progress_display:
		npc.progress_display.set_progress(build_timer / build_duration)
	if build_timer >= build_duration:
		_finish_build()


func _restart_approach_after_move_interrupt() -> void:
	build_timer = 0.0
	_stop_build_progress(true)
	_phase = _PHASE_APPROACH
	npc.set("is_building_milestone", false)
	if npc.steering_agent:
		npc.steering_agent.set_target_position_immediate(build_pos)


func _finish_build() -> void:
	var main_node: Node = get_tree().get_first_node_in_group("main") if get_tree() else null
	var brain: RefCounted = _get_clan_brain()
	var claim: Node = npc.get_my_land_claim() if npc.has_method("get_my_land_claim") else null
	if not main_node or not main_node.has_method("_place_ai_building_at") or not claim:
		_fail_and_exit()
		return

	var building_type: Variant = build_request.get("building_type")
	var placed: bool = main_node._place_ai_building_at(claim, building_type, build_pos)
	if not placed:
		print("⚠️ build_milestone_state: placement failed at %s — releasing request" % build_pos)
		if brain and brain.has_method("release_build_request"):
			brain.release_build_request(build_request.get("id", -1), "placement_failed")
		_fail_and_exit()
		return

	if brain and brain.has_method("complete_build_request"):
		brain.complete_build_request(build_request.get("id", -1))

	_exit_progress_cancelled = false
	build_request = {}
	build_pos = Vector2.ZERO
	if fsm:
		fsm.change_state("wander")


func _release_and_exit(reason: String) -> void:
	_exit_progress_cancelled = true
	var brain: RefCounted = _get_clan_brain()
	if brain and brain.has_method("release_build_request") and build_request.get("id", -1) >= 0:
		brain.release_build_request(build_request.get("id", -1), reason)
	build_request = {}
	build_pos = Vector2.ZERO


func _fail_and_exit() -> void:
	_exit_progress_cancelled = true
	build_request = {}
	build_pos = Vector2.ZERO
	if fsm:
		fsm.change_state("wander")


func can_enter() -> bool:
	if not npc:
		return false
	var nt: String = str(npc.get("npc_type")) if npc.get("npc_type") != null else ""
	if nt != "caveman" and nt != "clansman":
		return false
	var brain: RefCounted = _get_clan_brain()
	if not brain or not brain.has_method("has_pending_build_request"):
		return false
	return brain.has_pending_build_request()


func get_priority() -> float:
	if NPCConfig and "priority_build_milestone" in NPCConfig:
		return float(NPCConfig.priority_build_milestone)
	return 12.0
