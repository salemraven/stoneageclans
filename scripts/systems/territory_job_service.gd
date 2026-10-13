# Shared gather/craft job generation for any territory node (LandClaim, Campfire, future tiers).
# Campfire is Node2D + land_claims group but does not extend LandClaim — same logic must apply.
extends RefCounted

const GatherJobScript = preload("res://scripts/ai/jobs/gather_job.gd")

const _EDIBLE_TYPES: Array[int] = [
	ResourceData.ResourceType.BERRIES,
	ResourceData.ResourceType.WHEAT,
	ResourceData.ResourceType.GRAIN,
	ResourceData.ResourceType.NUTS,
	ResourceData.ResourceType.BUGS,
	ResourceData.ResourceType.MUSHROOM,
]
const _CHUNK_ARRIVE_PX: float = 160.0

## Rate-limit SESSION lines when session instrumentation is on (avoids 40k+ WORK_GATHER_NO_RESOURCE lines per long run).
const _SESSION_NO_RES_MIN_INTERVAL_SEC: float = 4.0
static var _last_work_gather_no_resource_log: Dictionary = {} # worker_instance_id -> unix time

static func _should_log_work_gather_no_resource(worker: Node) -> bool:
	if not worker:
		return true
	var wid: int = worker.get_instance_id()
	var now: float = Time.get_ticks_msec() / 1000.0
	var last: float = float(_last_work_gather_no_resource_log.get(wid, -999.0))
	if now - last < _SESSION_NO_RES_MIN_INTERVAL_SEC:
		return false
	_last_work_gather_no_resource_log[wid] = now
	if _last_work_gather_no_resource_log.size() > 800:
		_last_work_gather_no_resource_log.clear()
	return true

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
		if DebugConfig and DebugConfig.enable_session_instrumentation and _should_log_work_gather_no_resource(worker):
			var wtype: String = str(worker.get("npc_type")) if worker.get("npc_type") != null else ""
			UnifiedLogger.log_session("WORK_GATHER_NO_RESOURCE", {
				"worker": worker_name,
				"type": wtype,
				"clan": claim_clan
			}, UnifiedLogger.Level.INFO)
			var tree = worker.get_tree() if worker else null
			if tree:
				var pi = tree.root.get_node_or_null("PlaytestInstrumentor")
				if pi and pi.is_enabled() and pi.has_method("gather_no_resource"):
					pi.gather_no_resource(worker_name, claim_clan, "no_resource")
		return null
	if resource.has_method("reserve"):
		if not resource.reserve(worker):
			if DebugConfig and DebugConfig.enable_session_instrumentation and _should_log_work_gather_no_resource(worker):
				var wn: String = worker.get("npc_name") if "npc_name" in worker else "unknown"
				var wt: String = str(worker.get("npc_type")) if worker.get("npc_type") != null else ""
				UnifiedLogger.log_session("WORK_GATHER_RESERVE_FAIL", {
					"worker": wn,
					"type": wt,
					"clan": claim_clan,
					"resource_id": str(resource.get_instance_id())
				}, UnifiedLogger.Level.INFO)
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
	if DebugConfig and DebugConfig.enable_session_instrumentation:
		var wname: String = worker.get("npc_name") if "npc_name" in worker else "unknown"
		var wttp: String = str(worker.get("npc_type")) if worker.get("npc_type") != null else ""
		UnifiedLogger.log_session("WORK_GATHER_BUILT", {
			"worker": wname,
			"type": wttp,
			"clan": claim_clan,
			"skip_deposit": str(skip_deposit),
			"resource_id": str(resource.get_instance_id())
		}, UnifiedLogger.Level.INFO)
	return job

static func generate_craft_job(claim: Node2D, worker: Node) -> Job:
	if NPCConfig and not bool(NPCConfig.npc_blade_craft_enabled):
		return null
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
	if DebugConfig and DebugConfig.enable_session_instrumentation:
		var wn_c: String = worker.get("npc_name") if "npc_name" in worker else "unknown"
		UnifiedLogger.log_session("WORK_CRAFT_BUILT", {
			"worker": wn_c,
			"type": npc_type,
			"clan": claim_clan
		}, UnifiedLogger.Level.INFO)
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


## One assignment. Deliver, a reserved loaded-disk node, a herd already in hand,
## the next unsearched loaded chunk, or a hunt. Never "stand here."
static func next_job(claim: Node2D, worker: Node, disk_override: Array = []) -> Dictionary:
	if claim == null or worker == null or not is_instance_valid(claim) or not is_instance_valid(worker):
		return _assignment("none", Vector2.ZERO)
	if worker.has_method("is_dead") and worker.is_dead():
		return _assignment("none", Vector2.ZERO)
	var fsm: Node = worker.get("fsm") as Node if worker.get("fsm") != null else null
	if fsm:
		var state_name: String = str(fsm.get("current_state_name"))
		if state_name in ["combat", "defend", "raid", "flee_combat"]:
			return _assignment(state_name, worker.global_position)
	if worker.get("follow_is_ordered") == true:
		return _assignment("order", worker.global_position)
	var worker_clan: String = _clan_of(worker)
	var claim_clan: String = _clan_of(claim)
	if worker_clan == "" or worker_clan != claim_clan:
		return _assignment("none", claim.global_position)
	var disk: Array[Vector2i] = _loaded_disk(claim, disk_override)
	var deliver_pos: Vector2 = _deliver_position(claim, worker)
	if deliver_pos != Vector2.INF:
		return _assignment("deliver", deliver_pos)
	var held: Dictionary = _existing_gather(worker)
	if not held.is_empty():
		return held
	var node: Node2D = _reserve_disk_node(claim, worker, disk)
	if node:
		var job: Job = _build_gather_job(claim, worker, node)
		return _assignment("gather", node.global_position, node, job)
	if int(worker.get("herded_count") if worker.get("herded_count") != null else 0) > 0:
		return _assignment("herd", claim.global_position)
	if _herd_slot_open(claim, worker) and _herdable_in_disk(claim, worker, disk):
		return _assignment("herd", claim.global_position)
	var walked: Dictionary = _continue_chunk_walk(claim, worker)
	if not walked.is_empty():
		return walked
	var fresh: Dictionary = _assign_chunk(claim, worker, disk, false)
	if not fresh.is_empty():
		return fresh
	var prey: Vector2 = _prey_in_disk(worker, disk)
	if prey != Vector2.INF:
		return _assignment("hunt", prey)
	return _assign_chunk(claim, worker, disk, true)


static func apply_assignment(worker: Node, assignment: Dictionary) -> void:
	if worker == null or not is_instance_valid(worker):
		return
	var kind: String = str(assignment.get("kind", "none"))
	var target: Vector2 = assignment.get("target", Vector2.ZERO) as Vector2
	worker.set_meta("next_job_kind", kind)
	worker.set_meta("next_job_at", Time.get_ticks_msec() / 1000.0)
	worker.set_meta("next_job_pos", target)
	if assignment.has("chunk_key"):
		worker.set_meta("next_job_chunk", str(assignment.get("chunk_key", "")))
	match kind:
		"gather":
			var job: Job = assignment.get("job") as Job
			var runner: Node = worker.get("task_runner") as Node if worker.get("task_runner") != null else null
			if job and runner and runner.has_method("assign_job"):
				runner.assign_job(job)
			_change_state_if(worker, "gather")
		"deliver":
			worker.set_meta("moving_to_deposit", true)
			worker.set_meta("is_depositing", true)
			_steer(worker, target)
		"chunk":
			if worker.has_meta("moving_to_deposit"):
				worker.remove_meta("moving_to_deposit")
			if worker.has_meta("is_depositing"):
				worker.remove_meta("is_depositing")
			_steer(worker, target)
		"herd":
			_change_state_if(worker, "herd_wildnpc")
		"hunt":
			_change_state_if(worker, "hunt")
		_:
			pass


static func _assignment(kind: String, target: Vector2, node: Node = null, job: Job = null, chunk: Vector2i = Vector2i.ZERO, include_chunk: bool = false) -> Dictionary:
	var row: Dictionary = {"kind": kind, "target": target, "node": node, "job": job}
	if include_chunk:
		row["chunk"] = chunk
		row["chunk_key"] = _chunk_key(chunk)
	return row


static func _clan_of(node: Node) -> String:
	if node.has_method("get_clan_name"):
		return str(node.get_clan_name())
	if node.get("clan_name") != null:
		return str(node.get("clan_name"))
	return ""


static func _loaded_disk(claim: Node2D, disk_override: Array) -> Array[Vector2i]:
	var out: Array[Vector2i] = []
	if disk_override.size() > 0:
		for item in disk_override:
			if item is Vector2i:
				out.append(item as Vector2i)
		if not out.is_empty():
			return out
	if ChunkManager and ChunkManager.has_method("get_loaded_chunk_coords"):
		var loaded: Array = ChunkManager.get_loaded_chunk_coords()
		for item in loaded:
			if item is Vector2i:
				out.append(item as Vector2i)
	if out.is_empty():
		out.append(ChunkUtils.get_chunk_coords(claim.global_position))
	return out


static func _deliver_position(claim: Node2D, worker: Node) -> Vector2:
	var inv: Variant = worker.get("inventory")
	var claim_inv: Variant = claim.get("inventory")
	if inv == null or claim_inv == null:
		return Vector2.INF
	if not inv.has_method("get_used_slots") or not claim_inv.has_method("can_add_item"):
		return Vector2.INF
	var used: int = int(inv.get_used_slots())
	var slots: int = int(inv.get("slot_count") if inv.get("slot_count") != null else 5)
	var pct: float = NPCConfig.gather_deposit_threshold if NPCConfig else 0.4
	var threshold: int = max(3, int(ceil(float(slots) * pct)))
	if used < threshold:
		return Vector2.INF
	var acceptable: bool = false
	var slot_list: Array = inv.get("slots") if inv.get("slots") is Array else []
	for slot in slot_list:
		if slot == null or not (slot is Dictionary):
			continue
		var count: int = int((slot as Dictionary).get("count", 0))
		if count <= 0 or not (slot as Dictionary).has("type"):
			continue
		var item_type: int = int((slot as Dictionary).get("type"))
		if claim_inv.can_add_item(item_type, 1):
			acceptable = true
			break
	if not acceptable:
		return Vector2.INF
	return claim.global_position


static func _existing_gather(worker: Node) -> Dictionary:
	var runner: Node = worker.get("task_runner") as Node if worker.get("task_runner") != null else null
	if runner == null or not runner.has_method("has_job") or not runner.has_job():
		return {}
	var job: Job = runner.get("current_job") as Job if runner.get("current_job") != null else null
	if job == null:
		return {}
	var node: Node2D = job.get("resource_node") as Node2D if job.get("resource_node") != null else null
	if node == null or not is_instance_valid(node):
		return {}
	return _assignment("gather", node.global_position, node, job)


static func _reserve_disk_node(claim: Node2D, worker: Node, disk: Array[Vector2i]) -> Node2D:
	if ResourceIndex == null:
		return null
	var on_disk: Dictionary = {}
	for chunk in disk:
		on_disk[_chunk_key(chunk)] = true
	var hungry: bool = _pantry_thin(claim)
	var held: Node2D = null
	var best: Node2D = null
	var best_edible: int = 2
	var best_dist: float = INF
	var worker_pos: Vector2 = worker.global_position
	var claims: Array = []
	if worker.is_inside_tree():
		claims = worker.get_tree().get_nodes_in_group("land_claims")
	var clan_name: String = _clan_of(claim)
	for chunk in disk:
		var center: Vector2 = ChunkUtils.get_chunk_center(chunk)
		var found: Array = ResourceIndex.query_near(center, ChunkUtils.CHUNK_SIZE * 0.8, {
			"exclude_cooldown": true,
			"exclude_no_capacity": false,
			"exclude_empty": true,
		})
		for pair in found:
			if not (pair is Dictionary):
				continue
			var node: Node2D = (pair as Dictionary).get("node") as Node2D
			if node == null or not is_instance_valid(node):
				continue
			var node_chunk: String = _chunk_key(ChunkUtils.get_chunk_coords(node.global_position))
			if not on_disk.has(node_chunk):
				continue
			if node.has_method("is_in_cooldown_state") and node.is_in_cooldown_state():
				continue
			if ResourceIndex.is_position_in_enemy_claim(claims, node.global_position, clan_name):
				continue
			var item_type: int = _node_resource_type(node)
			if item_type < 0 or not _claim_can_store(claim, item_type):
				continue
			var mine: bool = _worker_holds(node, worker)
			if not mine and node.has_method("has_capacity") and not node.has_capacity():
				continue
			if mine:
				held = node
				continue
			var edible_rank: int = 0 if (hungry and item_type in _EDIBLE_TYPES) else 1
			var dist: float = worker_pos.distance_to(node.global_position)
			if edible_rank < best_edible or (edible_rank == best_edible and dist < best_dist):
				best_edible = edible_rank
				best_dist = dist
				best = node
	var chosen: Node2D = held if held else best
	if chosen == null:
		return null
	if _worker_holds(chosen, worker):
		return chosen
	if chosen.has_method("reserve") and not chosen.reserve(worker):
		return null
	return chosen


static func _pantry_thin(claim: Node) -> bool:
	if claim.has_meta("food_buffer_critical") and bool(claim.get_meta("food_buffer_critical")):
		return true
	if not claim.has_meta("food_days_buffer"):
		return false
	var days: float = float(claim.get_meta("food_days_buffer"))
	var critical: float = BalanceConfig.clan_food_buffer_critical_days if BalanceConfig else 0.5
	return days < critical


static func _claim_can_store(claim: Node, item_type: int) -> bool:
	var inv: Variant = claim.get("inventory")
	if inv == null or not inv.has_method("can_add_item"):
		return false
	return bool(inv.can_add_item(item_type, 1))


static func _node_resource_type(node: Node) -> int:
	var raw: Variant = node.get("resource_type")
	if raw == null:
		raw = node.get("item_type")
	if raw == null:
		return -1
	return int(raw)


static func _worker_holds(node: Node, worker: Node) -> bool:
	var reserved: Variant = node.get("reserved_workers")
	return reserved is Array and worker in (reserved as Array)


static func _build_gather_job(claim: Node2D, worker: Node, resource: Node2D) -> Job:
	var skip_deposit: bool = false
	var inv: Variant = worker.get("inventory")
	if inv:
		var used: int = int(inv.get_used_slots()) if inv.has_method("get_used_slots") else 0
		var slots: int = int(inv.get("slot_count") if inv.get("slot_count") != null else 5)
		var pct: float = NPCConfig.gather_same_node_until_pct if NPCConfig else 1.0
		skip_deposit = used < int(ceil(float(slots) * pct))
	var job: Job = GatherJobScript.new(resource, claim, skip_deposit) as Job
	if job:
		job.building = claim
	return job


static func _herd_slot_open(claim: Node, worker: Node) -> bool:
	var max_herders: int = int(claim.get_meta("max_active_herders", 2))
	var active: int = 0
	if not claim.is_inside_tree():
		return active < max_herders
	var clan_name: String = _clan_of(claim)
	for other in claim.get_tree().get_nodes_in_group("npcs"):
		if other == worker or not is_instance_valid(other):
			continue
		if _clan_of(other) != clan_name:
			continue
		var fsm: Node = other.get("fsm") as Node if other.get("fsm") != null else null
		if fsm and str(fsm.get("current_state_name")) == "herd_wildnpc":
			active += 1
	return active < max_herders


static func _herdable_in_disk(claim: Node, worker: Node, disk: Array[Vector2i]) -> bool:
	if not claim.is_inside_tree() or NPCConfig == null:
		return false
	var on_disk: Dictionary = {}
	for chunk in disk:
		on_disk[_chunk_key(chunk)] = true
	for other in claim.get_tree().get_nodes_in_group("npcs"):
		if other == worker or not is_instance_valid(other) or not (other is Node2D):
			continue
		var kind: String = str(other.get("npc_type") if other.get("npc_type") != null else "")
		var profile: Dictionary = NPCConfig.get_wild_profile(kind) if NPCConfig.has_method("get_wild_profile") else {}
		if not bool(profile.get("herdable", false)):
			continue
		if _clan_of(other) != "":
			continue
		var key: String = _chunk_key(ChunkUtils.get_chunk_coords((other as Node2D).global_position))
		if on_disk.has(key):
			return true
	return false


static func _prey_in_disk(worker: Node, disk: Array[Vector2i]) -> Vector2:
	if not worker.is_inside_tree() or NPCConfig == null or not NPCConfig.has_method("is_ai_hunt_prey_type"):
		return Vector2.INF
	var on_disk: Dictionary = {}
	for chunk in disk:
		on_disk[_chunk_key(chunk)] = true
	var best: Vector2 = Vector2.INF
	var best_dist: float = INF
	for other in worker.get_tree().get_nodes_in_group("npcs"):
		if other == worker or not is_instance_valid(other) or not (other is Node2D):
			continue
		var kind: String = str(other.get("npc_type") if other.get("npc_type") != null else "")
		if not NPCConfig.is_ai_hunt_prey_type(kind):
			continue
		var pos: Vector2 = (other as Node2D).global_position
		if not on_disk.has(_chunk_key(ChunkUtils.get_chunk_coords(pos))):
			continue
		var dist: float = worker.global_position.distance_to(pos)
		if dist < best_dist:
			best_dist = dist
			best = pos
	return best


static func _continue_chunk_walk(claim: Node, worker: Node) -> Dictionary:
	if not worker.has_meta("next_job_chunk"):
		return {}
	var key: String = str(worker.get_meta("next_job_chunk"))
	if key.is_empty():
		return {}
	var chunk: Vector2i = _parse_chunk_key(key)
	var center: Vector2 = ChunkUtils.get_chunk_center(chunk)
	if worker.global_position.distance_to(center) > _CHUNK_ARRIVE_PX:
		return _assignment("chunk", center, null, null, chunk, true)
	_stamp_chunk_searched(claim, worker, chunk)
	worker.remove_meta("next_job_chunk")
	return {}


static func _assign_chunk(claim: Node, worker: Node, disk: Array[Vector2i], allow_repeat: bool) -> Dictionary:
	if disk.is_empty():
		return {}
	var searched: Dictionary = {}
	if claim.has_meta("next_job_searched"):
		var stored: Variant = claim.get_meta("next_job_searched")
		if stored is Dictionary:
			searched = stored
	var best: Vector2i = disk[0]
	var best_dist: float = INF
	var found_fresh: bool = false
	var oldest: Vector2i = disk[0]
	var oldest_time: float = INF
	for chunk in disk:
		var key: String = _chunk_key(chunk)
		var center: Vector2 = ChunkUtils.get_chunk_center(chunk)
		var dist: float = worker.global_position.distance_to(center)
		if not searched.has(key):
			if dist < best_dist:
				best_dist = dist
				best = chunk
				found_fresh = true
		else:
			var when: float = float(searched[key])
			if when < oldest_time:
				oldest_time = when
				oldest = chunk
	if not found_fresh and not allow_repeat:
		return {}
	var chosen: Vector2i = best if found_fresh else oldest
	worker.set_meta("next_job_chunk", _chunk_key(chosen))
	return _assignment("chunk", ChunkUtils.get_chunk_center(chosen), null, null, chosen, true)


static func _stamp_chunk_searched(claim: Node, worker: Node, chunk: Vector2i) -> void:
	if worker.has_method("is_dead") and worker.is_dead():
		return
	var searched: Dictionary = {}
	if claim.has_meta("next_job_searched"):
		var stored: Variant = claim.get_meta("next_job_searched")
		if stored is Dictionary:
			searched = (stored as Dictionary).duplicate()
	searched[_chunk_key(chunk)] = Time.get_ticks_msec() / 1000.0
	claim.set_meta("next_job_searched", searched)


static func _chunk_key(chunk: Vector2i) -> String:
	return "%d,%d" % [chunk.x, chunk.y]


static func _parse_chunk_key(key: String) -> Vector2i:
	var parts: PackedStringArray = key.split(",")
	if parts.size() != 2:
		return Vector2i.ZERO
	return Vector2i(int(parts[0]), int(parts[1]))


static func _steer(worker: Node, target: Vector2) -> void:
	var agent: Variant = worker.get("steering_agent")
	if agent != null and agent.has_method("set_arrive_target"):
		agent.set_arrive_target(target)


static func _change_state_if(worker: Node, state_name: String) -> void:
	var fsm: Node = worker.get("fsm") as Node if worker.get("fsm") != null else null
	if fsm == null or not fsm.has_method("change_state"):
		return
	if str(fsm.get("current_state_name")) == state_name:
		return
	fsm.change_state(state_name)
