extends RefCounted

## Shared "corpse job site" for hunt LOOTING — any clansman can pull butcher trips until yield is gone.

const META_CORPSE_ID := "corpse_job_corpse_id"
const META_OPEN := "corpse_job_open"
const WORKER_META := "hunt_corpse_job_active"
const BUTCHER_JOB_PATH := "res://scripts/ai/jobs/butcher_corpse_job.gd"


static func corpse_yield_total(corpse: Node) -> int:
	if not corpse or not is_instance_valid(corpse):
		return 0
	return int(corpse.get_meta("meat_remaining", 0)) + int(corpse.get_meta("hide_remaining", 0)) + int(corpse.get_meta("bone_remaining", 0))


static func get_site_corpse(claim: Node) -> Node:
	if not claim or not bool(claim.get_meta(META_OPEN, false)):
		return null
	if not claim.has_meta(META_CORPSE_ID):
		return null
	var cid: int = int(claim.get_meta(META_CORPSE_ID))
	var cor: Node = instance_from_id(cid)
	if not cor or not is_instance_valid(cor):
		return null
	if corpse_yield_total(cor) <= 0:
		return null
	return cor


static func is_site_active(claim: Node) -> bool:
	return get_site_corpse(claim) != null


static func register_site(claim: Node, corpse: Node) -> void:
	if not claim or not corpse or not is_instance_valid(corpse):
		return
	claim.set_meta(META_CORPSE_ID, corpse.get_instance_id())
	claim.set_meta(META_OPEN, true)


static func clear_site(claim: Node) -> void:
	if not claim:
		return
	if claim.has_meta(META_CORPSE_ID):
		claim.remove_meta(META_CORPSE_ID)
	if claim.has_meta(META_OPEN):
		claim.remove_meta(META_OPEN)


static func _deposit_threshold(worker: Node) -> int:
	if not worker or not worker.get("inventory"):
		return 3
	var inv = worker.get("inventory")
	var max_slots: int = inv.slot_count if "slot_count" in inv else 5
	var pct: float = NPCConfig.gather_deposit_threshold if NPCConfig else 0.4
	return maxi(2, int(ceil(float(max_slots) * pct)))


static func _used_slots(worker: Node) -> int:
	if not worker or not worker.get("inventory"):
		return 0
	var inv = worker.get("inventory")
	if inv.has_method("get_used_slots"):
		return int(inv.get_used_slots())
	return 0


static func worker_can_pull(worker: Node, claim: Node) -> bool:
	if not worker or not claim or not is_site_active(claim):
		return false
	var nt: String = str(worker.get("npc_type")) if worker.get("npc_type") != null else ""
	if nt != "caveman" and nt != "clansman":
		return false
	if worker.get("defend_target") != null and is_instance_valid(worker.get("defend_target")):
		return false
	if worker.get("combat_target") != null and is_instance_valid(worker.get("combat_target")):
		return false
	if worker.get("is_herded") == true and worker.get("follow_is_ordered") == true:
		return false
	if not worker.get("inventory"):
		return false
	if not worker.get("inventory").has_space():
		return false
	if _used_slots(worker) >= _deposit_threshold(worker):
		return false
	if worker.get("task_runner") and worker.get("task_runner").has_method("has_job") and worker.get("task_runner").has_job():
		return false
	return true


static func try_assign_job(claim: Node, worker: Node) -> bool:
	if not worker_can_pull(worker, claim):
		return false
	var corpse: Node = get_site_corpse(claim)
	if not corpse:
		clear_site(claim)
		return false
	var job_script: GDScript = load(BUTCHER_JOB_PATH) as GDScript
	if not job_script:
		return false
	var job: Job = job_script.new(corpse, claim) as Job
	if not job:
		return false
	worker.set_meta(WORKER_META, true)
	if worker.has_method("equip_work_weapon_club"):
		worker.equip_work_weapon_club()
	var runner = worker.get("task_runner")
	if runner and runner.has_method("assign_job"):
		runner.assign_job(job)
		return true
	return false


static func clear_worker_meta(worker: Node) -> void:
	if not worker:
		return
	if worker.has_meta(WORKER_META):
		worker.remove_meta(WORKER_META)
	if worker.has_meta("hunt_butchering"):
		worker.remove_meta("hunt_butchering")
