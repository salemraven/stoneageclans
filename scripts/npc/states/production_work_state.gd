extends "res://scripts/npc/states/base_state.gd"

## ClanBrain-directed production work for women (Oven bread + Drying Rack leather).
## Pulls WorkRequests from territory ClanBrain; uses TaskRunner for multi-step jobs.

var work_request: Dictionary = {}
var _brain: RefCounted = null
var _job_started: bool = false

const PRIORITY_IDLE: float = 9.6
const PRIORITY_ACTIVE: float = 10.0


func enter() -> void:
	work_request = {}
	_brain = _get_clan_brain()
	_job_started = false
	if not _brain:
		return
	work_request = _brain.claim_work_request(npc)
	if work_request.is_empty():
		return
	_brain.set_request_state(int(work_request.get("id", -1)), "IN_PROGRESS")
	_start_job_from_request()


func exit() -> void:
	if npc and npc.get_node_or_null("Sprite"):
		npc.get_node("Sprite").visible = true
	if npc and npc.task_runner and npc.task_runner.has_method("has_job") and npc.task_runner.has_job():
		npc.task_runner.cancel_current_job("production_work_exit")
	if _brain and not work_request.is_empty():
		var state: String = work_request.get("state", "")
		if state != "COMPLETED":
			_brain.release_work_request(int(work_request.get("id", -1)))
	work_request = {}
	_brain = null
	_job_started = false


func update(_delta: float) -> void:
	if not npc or npc.is_dead():
		return
	if npc.should_abort_work():
		fsm.change_state("wander")
		return
	if not _job_started:
		fsm.change_state("wander")
		return
	if _has_active_job():
		return
	if _brain and not work_request.is_empty():
		_brain.complete_work_request(int(work_request.get("id", -1)))
		work_request = {}
	# Job done — leave state so FSM can pick next behavior (or re-enter if more requests)
	fsm.change_state("wander")


func can_enter() -> bool:
	if not npc or npc.get("npc_type") != "woman":
		return false
	if npc.is_wild():
		return false
	if npc.should_abort_work():
		return false
	var brain := _get_clan_brain()
	return brain != null and brain.has_pending_work_request()


func get_priority() -> float:
	if not npc or npc.get("npc_type") != "woman":
		return 0.0
	if _has_active_job() or not work_request.is_empty():
		return PRIORITY_ACTIVE
	var brain := _get_clan_brain()
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


func _start_job_from_request() -> void:
	if work_request.is_empty() or not npc or not npc.task_runner:
		return
	var building: Node = work_request.get("building")
	if not is_instance_valid(building):
		return
	var claim := _get_territory() as LandClaim
	if not claim:
		return
	var chain_id: String = work_request.get("chain_id", "")
	var chain: ProductionChain = ProductionChainRegistry.get_chain(chain_id) if ProductionChainRegistry else null
	if chain == null:
		return
	var request_type: String = work_request.get("request_type", "delivery")
	var job: Job = null
	if request_type == "pickup" and building.has_method("generate_clanbrain_pickup_job"):
		job = building.generate_clanbrain_pickup_job(npc, claim, chain)
	elif request_type == "delivery" and building.has_method("generate_clanbrain_delivery_job"):
		job = building.generate_clanbrain_delivery_job(npc, claim, chain)
	if job:
		npc.task_runner.assign_job(job)
		_job_started = true
	else:
		if _brain:
			_brain.release_work_request(int(work_request.get("id", -1)))
		work_request = {}


func _has_active_job() -> bool:
	if not npc or not npc.task_runner:
		return false
	if npc.task_runner.has_method("has_job"):
		return npc.task_runner.has_job()
	return false


func _get_territory() -> Node:
	if not npc:
		return null
	var npc_clan: String = npc.get_clan_name() if npc.has_method("get_clan_name") else ""
	if npc_clan.is_empty():
		return null
	for claim in get_tree().get_nodes_in_group("land_claims"):
		if not is_instance_valid(claim):
			continue
		if claim.get("clan_name") == npc_clan:
			return claim
	return null


func _get_clan_brain() -> RefCounted:
	var territory := _get_territory()
	if territory and territory.has_method("get_clan_brain"):
		return territory.get_clan_brain()
	return null
