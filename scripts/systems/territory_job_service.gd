# Shared gather/craft job generation for any territory node (LandClaim, Campfire, future tiers).
# Campfire is Node2D + land_claims group but does not extend LandClaim — same logic must apply.
extends RefCounted

static func generate_gather_job(claim: Node2D, worker: Node) -> Job:
	if not claim or not worker:
		return null
	var claim_clan: String = claim.get("clan_name") if "clan_name" in claim else ""
	var worker_clan: String = worker.get("clan_name") if "clan_name" in worker else ""
	if worker_clan != claim_clan:
		return null
	var resource: Node2D = find_nearest_available_resource(claim, worker)
	if not resource:
		var worker_name: String = worker.get("npc_name") if "npc_name" in worker else "unknown"
		UnifiedLogger.log_npc("GATHER_JOB: %s no resource in claim range (clan=%s, claim_pos=%s)" % [
			worker_name, claim_clan, str(claim.global_position)
		], {"npc": worker_name, "clan": claim_clan, "claim_pos": str(claim.global_position)}, UnifiedLogger.Level.DEBUG)
		return null
	if resource.has_method("reserve"):
		if not resource.reserve(worker):
			return null
	var skip_deposit: bool = false
	if worker.has_method("get") and "inventory" in worker:
		var worker_inventory = worker.get("inventory")
		if worker_inventory:
			var used_slots: int = worker_inventory.get_used_slots() if worker_inventory.has_method("get_used_slots") else 0
			var max_slots: int = worker_inventory.slot_count if "slot_count" in worker_inventory else 5
			var pct: float = NPCConfig.gather_same_node_until_pct if NPCConfig else 1.0
			var threshold: int = int(ceil(max_slots * pct))
			skip_deposit = (used_slots < threshold)
			var worker_name: String = worker.get("npc_name") if "npc_name" in worker else "unknown"
			UnifiedLogger.log_npc("GATHER_JOB: %s - inventory %d/%d, threshold=%d, skip_deposit=%s" % [
				worker_name, used_slots, max_slots, threshold, skip_deposit
			], {
				"npc": worker_name,
				"used_slots": used_slots,
				"max_slots": max_slots,
				"threshold": threshold,
				"skip_deposit": skip_deposit
			})
	var gather_job_script = load("res://scripts/ai/jobs/gather_job.gd") as GDScript
	if not gather_job_script:
		push_error("TerritoryJobService.generate_gather_job: Failed to load GatherJob script")
		return null
	var job: Job = gather_job_script.new(resource, claim, skip_deposit) as Job
	if not job:
		return null
	job.building = claim
	return job

static func generate_craft_job(claim: Node2D, worker: Node) -> Job:
	if not claim or not worker:
		return null
	var claim_clan: String = claim.get("clan_name") if "clan_name" in claim else ""
	var worker_clan: String = worker.get("clan_name") if "clan_name" in worker else ""
	if worker_clan != claim_clan:
		return null
	var npc_type: String = worker.get("npc_type") if "npc_type" in worker else ""
	if npc_type != "clansman" and npc_type != "caveman":
		return null
	var inv = claim.get("inventory")
	if not inv or not inv.has_method("get_count"):
		return null
	const BLADE_RESERVE_TARGET: int = 4
	const STONES_REQUIRED_FOR_KNAP: int = 2
	if inv.get_count(ResourceData.ResourceType.BLADE) >= BLADE_RESERVE_TARGET:
		return null
	if inv.get_count(ResourceData.ResourceType.STONE) < STONES_REQUIRED_FOR_KNAP:
		return null
	var craft_job_script = load("res://scripts/ai/jobs/craft_job.gd") as GDScript
	if not craft_job_script:
		push_error("TerritoryJobService.generate_craft_job: Failed to load CraftJob script")
		return null
	var job: Job = craft_job_script.new(claim) as Job
	if not job:
		return null
	job.building = claim
	return job

static func find_nearest_available_resource(claim: Node2D, worker: Node) -> Node2D:
	if not worker or not ResourceIndex or not claim:
		return null
	if not claim.is_inside_tree():
		return null
	var tree: SceneTree = claim.get_tree()
	var clan_name: String = claim.get("clan_name") if "clan_name" in claim else ""
	var radius: float = float(claim.get("radius")) if claim.get("radius") != null else 400.0
	var worker_pos: Vector2 = worker.global_position if worker else claim.global_position
	var claim_pos: Vector2 = claim.global_position
	var gather_distance: float = 60.0
	var land_claims: Array = []
	var main_node = tree.current_scene if tree else null
	if main_node and main_node.has_method("get_cached_land_claims"):
		land_claims = main_node.get_cached_land_claims()
	else:
		land_claims = tree.get_nodes_in_group("land_claims")
	var exclude_enemy: Callable = func(pos: Vector2) -> bool:
		return ResourceIndex.is_position_in_enemy_claim(land_claims, pos, clan_name)
	var filters: Dictionary = {
		"exclude_cooldown": true,
		"exclude_no_capacity": true,
		"exclude_empty": true,
		"exclude_position_enemy_claim": exclude_enemy
	}
	var candidates: Array = []
	for range_mult in [3.0, 4.5, 6.0]:
		var search_range: float = radius * range_mult
		candidates = ResourceIndex.query_near(claim_pos, search_range, filters)
		if not candidates.is_empty():
			break
	var current_job_resource: Node2D = null
	if worker.has_method("get") and "task_runner" in worker:
		var task_runner = worker.get("task_runner")
		if task_runner and task_runner.has_method("has_job") and task_runner.has_job():
			var current_job = task_runner.get("current_job") if "current_job" in task_runner else null
			if current_job and "resource_node" in current_job:
				current_job_resource = current_job.resource_node
	for pair in candidates:
		var resource: Node2D = pair.node
		var distance_to_worker: float = worker_pos.distance_to(resource.global_position)
		var is_at_resource: bool = (distance_to_worker <= gather_distance)
		var is_current_job_resource: bool = (current_job_resource == resource)
		if is_at_resource or is_current_job_resource:
			if resource.has_method("has_capacity") and not resource.has_capacity():
				if not (resource.has_method("reserved_workers") and worker in resource.reserved_workers):
					continue
			return resource
	if candidates.is_empty():
		return null
	var spread_penalty: float = NPCConfig.clan_spread_penalty if NPCConfig else 50.0
	const CLAN_NEAR_RADIUS: float = 100.0
	var npcs: Array = tree.get_nodes_in_group("npcs")
	var best: Node2D = null
	var best_score: float = INF
	for pair in candidates:
		var resource: Node2D = pair.node
		var res_pos: Vector2 = resource.global_position
		var d: float = worker_pos.distance_to(res_pos)
		var nearby_clan_mates: int = 0
		for other in npcs:
			if other == worker or not is_instance_valid(other):
				continue
			var other_clan: String = other.get_clan_name() if other.has_method("get_clan_name") else (other.get("clan_name") as String if other.get("clan_name") != null else "")
			if other_clan != clan_name:
				continue
			if other.global_position.distance_to(res_pos) < CLAN_NEAR_RADIUS:
				nearby_clan_mates += 1
		var score: float = d + (nearby_clan_mates * spread_penalty)
		if score < best_score:
			best_score = score
			best = resource
	return best
