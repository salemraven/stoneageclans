extends "res://scripts/npc/states/base_state.gd"

## ClanBrain-directed production work for women (Oven bread + Drying Rack leather).
## Pulls WorkRequests from territory ClanBrain; uses TaskRunner for multi-step jobs.

const ProductionChainScript = preload("res://scripts/data/production_chain.gd")

var work_request: Dictionary = {}
var _brain: RefCounted = null
var _job_started: bool = false
var _start_attempts: int = 0

const PRIORITY_IDLE: float = 11.8
const PRIORITY_ACTIVE: float = 12.0
const MAX_START_ATTEMPTS: int = 8
const START_RETRY_SEC: float = 0.75


func enter() -> void:
	_brain = _get_clan_brain()
	_job_started = false
	_start_attempts = 0
	if not _brain:
		return
	work_request = _brain.claim_work_request(npc)
	if work_request.is_empty():
		return
	if _brain.has_method("log_work_request_claimed"):
		_brain.log_work_request_claimed(work_request, npc)
	_brain.set_request_state(int(work_request.get("id", -1)), "IN_PROGRESS")
	_try_start_job()


func exit() -> void:
	if npc and npc.get_node_or_null("Sprite"):
		npc.get_node("Sprite").visible = true
	if npc and npc.task_runner and npc.task_runner.has_method("has_job") and npc.task_runner.has_job():
		npc.task_runner.cancel_current_job("production_work_exit")
	if _brain and not work_request.is_empty():
		var state: String = work_request.get("state", "")
		if state != "COMPLETED" and (_job_started or _has_active_job()):
			_brain.release_work_request(int(work_request.get("id", -1)), "production_work_exit")
	if OccupationSystem and OccupationSystem.has_method("restore_home_living_hut"):
		OccupationSystem.restore_home_living_hut(npc)
	work_request = {}
	_brain = null
	_job_started = false
	_start_attempts = 0


func update(_delta: float) -> void:
	if not npc or npc.is_dead():
		return
	if npc.should_abort_work():
		_release_and_wander("abort_work")
		return
	if _has_active_job():
		_job_started = true
		return
	if work_request.is_empty():
		if fsm:
			fsm.change_state("wander")
		return
	if not _job_started:
		var now_s: float = Time.get_ticks_msec() / 1000.0
		if _start_attempts < MAX_START_ATTEMPTS:
			if _start_attempts == 0 or now_s >= npc.get_meta("_prod_work_next_retry", 0.0):
				_start_attempts += 1
				npc.set_meta("_prod_work_next_retry", now_s + START_RETRY_SEC)
				if _try_start_job():
					return
		else:
			_release_and_wander("job_start_exhausted")
		return
	if _brain and not work_request.is_empty():
		_brain.complete_work_request(int(work_request.get("id", -1)))
		work_request = {}
	if OccupationSystem and OccupationSystem.has_method("restore_home_living_hut"):
		OccupationSystem.restore_home_living_hut(npc)
	if fsm:
		fsm.change_state("wander")


func can_enter() -> bool:
	if not npc or npc.get("npc_type") != "woman":
		return false
	if npc.is_wild():
		return false
	if npc.should_abort_work():
		return false
	if _is_following():
		return false
	var brain := _get_clan_brain()
	if brain == null:
		return false
	if brain.has_method("has_production_work_available"):
		return brain.has_production_work_available(npc)
	return brain.has_pending_work_request()


func get_priority() -> float:
	if not npc or npc.get("npc_type") != "woman":
		return 0.0
	if _has_active_job() or not work_request.is_empty():
		return PRIORITY_ACTIVE
	var brain := _get_clan_brain()
	if brain and brain.has_method("has_production_work_available") and brain.has_production_work_available(npc):
		return PRIORITY_IDLE
	if brain and brain.has_pending_work_request():
		return PRIORITY_IDLE
	return 0.0


func get_data() -> Dictionary:
	return {
		"state": "production_work",
		"request_id": work_request.get("id", -1),
		"request_type": work_request.get("request_type", ""),
		"chain_id": work_request.get("chain_id", ""),
	}


func _try_start_job() -> bool:
	if work_request.is_empty() or not npc or not npc.task_runner:
		return false
	var building: Node = work_request.get("building")
	if not is_instance_valid(building):
		return false
	var claim := _get_territory()
	if not claim:
		return false
	var chain_id: String = work_request.get("chain_id", "")
	var chain: Resource = ProductionChainRegistry.get_chain(chain_id) if ProductionChainRegistry else null
	if chain == null:
		return false
	var request_type: String = work_request.get("request_type", "delivery")
	var job: Job = null
	if request_type == "pickup" and building.has_method("generate_clanbrain_pickup_job"):
		job = building.generate_clanbrain_pickup_job(npc, claim, chain)
	elif request_type == "delivery" and building.has_method("generate_clanbrain_delivery_job"):
		job = building.generate_clanbrain_delivery_job(npc, claim, chain)
	if job:
		npc.task_runner.assign_job(job)
		_job_started = true
		return true
	return false


func _release_and_wander(reason: String) -> void:
	if _brain and not work_request.is_empty():
		_brain.release_work_request(int(work_request.get("id", -1)), reason)
	work_request = {}
	if fsm:
		fsm.change_state("wander")


func _has_active_job() -> bool:
	if not npc or not npc.task_runner:
		return false
	if npc.task_runner.has_method("has_job"):
		return npc.task_runner.has_job()
	return false


func _get_territory() -> Node:
	if _brain and _brain.get("territory") != null:
		var claim: Variant = _brain.get("territory")
		if claim is Node and is_instance_valid(claim):
			return claim as Node
	if not npc:
		return null
	if npc.has_method("get_my_land_claim"):
		var lc: Node = npc.get_my_land_claim()
		if lc and is_instance_valid(lc):
			return lc
	return null


func _get_clan_brain() -> RefCounted:
	var territory := _get_territory()
	if territory and territory.has_method("get_clan_brain"):
		return territory.get_clan_brain()
	if territory and "clan_brain" in territory:
		return territory.clan_brain as RefCounted
	return null
