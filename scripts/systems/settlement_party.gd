class_name SettlementParty
extends RefCounted
## A hunt or raid that has left the claim. The record stays home. Bodies are only the view.

const MARCH_PX_PER_SEC := 120.0
const CHUNK_PX := 2048.0


static func home_fighter_count(roster: RefCounted) -> int:
	if roster == null:
		return 0
	var count := 0
	for m in roster.get("members"):
		if not (m is Dictionary):
			continue
		var rec: Dictionary = m as Dictionary
		if not bool(rec.get("alive", false)) or bool(rec.get("away", false)):
			continue
		var kind: String = str(rec.get("type", ""))
		if kind in ["clansman", "caveman", "leader"]:
			count += 1
	return count


static func mark_away(roster: RefCounted, member_ids: Array, away: bool) -> void:
	if roster == null:
		return
	for mid in member_ids:
		var rec: Dictionary = roster.find_member(int(mid))
		if rec.is_empty():
			continue
		rec["away"] = away


static func should_spawn_at_claim(rec: Dictionary) -> bool:
	return bool(rec.get("alive", false)) and not bool(rec.get("away", false))


static func write_back_keeps_away(roster: RefCounted, member_ids: Array) -> void:
	mark_away(roster, member_ids, true)


## Unwatched scout: one gather from his chunk into the pantry, then he is home.
## A second call deposits nothing. The live pack is cleared so waking cannot deposit it again.
static func resolve_unwatched_trip(claim: Node, roster: RefCounted, member_id: int, chunk: Vector2i, worker: Node = null) -> int:
	if claim == null or roster == null:
		return 0
	var done: Dictionary = {}
	if claim.has_meta("away_trip_resolved"):
		var stored: Variant = claim.get_meta("away_trip_resolved")
		if stored is Dictionary:
			done = stored
	if done.has(member_id):
		return 0
	var rec: Dictionary = roster.find_member(member_id)
	if rec.is_empty() or not bool(rec.get("away", false)):
		return 0
	var taken: int = 0
	var added_type: int = ResourceData.ResourceType.BERRIES
	if MutationStore:
		var keys: Array[String] = ["berries", "grain", "nuts", "bugs"]
		var types: Array[int] = [
			ResourceData.ResourceType.BERRIES,
			ResourceData.ResourceType.GRAIN,
			ResourceData.ResourceType.NUTS,
			ResourceData.ResourceType.BUGS,
		]
		for i in keys.size():
			var n: int = int(MutationStore.deplete_abstract_resource(chunk, keys[i], 1))
			if n > 0:
				taken = n
				added_type = types[i]
				break
	var inv: Variant = claim.get("inventory")
	if taken > 0 and inv and inv.has_method("add_item"):
		inv.add_item(added_type, taken)
	done[member_id] = true
	claim.set_meta("away_trip_resolved", done)
	mark_away(roster, [member_id], false)
	if claim.has_meta("away_trip_chunks"):
		var blocked: Variant = claim.get_meta("away_trip_chunks")
		if blocked is Array:
			(blocked as Array).erase(chunk)
			claim.set_meta("away_trip_chunks", blocked)
	if worker != null and is_instance_valid(worker):
		_clear_worker_pack(worker)
	return taken


static func _clear_worker_pack(worker: Node) -> void:
	var inv: Variant = worker.get("inventory")
	if inv == null or not inv.has_method("remove_item") or not inv.has_method("get_count"):
		return
	var types: Array[int] = [
		ResourceData.ResourceType.BERRIES,
		ResourceData.ResourceType.GRAIN,
		ResourceData.ResourceType.NUTS,
		ResourceData.ResourceType.BUGS,
		ResourceData.ResourceType.WOOD,
		ResourceData.ResourceType.STONE,
		ResourceData.ResourceType.FIBER,
		ResourceData.ResourceType.MEAT,
	]
	for item_type in types:
		var count: int = int(inv.get_count(item_type))
		if count > 0:
			inv.remove_item(item_type, count)


static func begin_hunt(roster: RefCounted, home_chunk: Vector2i, inventory: InventoryData, active: Dictionary = {}) -> Dictionary:
	if roster == null or MutationStore == null:
		return {}
	if not active.is_empty() and str(active.get("phase", "")) != "done":
		return {}
	var fighter_ids: Array = _home_fighter_ids(roster)
	if fighter_ids.size() < 2:
		return {}
	var target := home_chunk
	var travel := 0.0
	if MutationStore.get_wildlife(home_chunk) <= 0:
		var found := false
		for dx in range(-1, 2):
			for dy in range(-1, 2):
				var coords := home_chunk + Vector2i(dx, dy)
				if MutationStore.get_wildlife(coords) <= 0:
					continue
				target = coords
				travel = Vector2(dx, dy).length() * CHUNK_PX / MARCH_PX_PER_SEC
				found = true
				break
			if found:
				break
		if not found:
			return {}
	var sent: Array = [fighter_ids[0], fighter_ids[1]]
	var bundle := _take_bundle(inventory, sent.size())
	mark_away(roster, sent, true)
	return {
		"kind": "hunt",
		"phase": "out",
		"member_ids": sent,
		"target_chunk": target,
		"travel_left": travel,
		"travel_total": travel,
		"bundle": bundle,
		"bundle_start": bundle,
		"resolved": false,
		"materialized": false,
	}


static func advance(token: Dictionary, roster: RefCounted, inventory: InventoryData, elapsed: float, watching: bool) -> void:
	if token.is_empty():
		return
	if watching:
		token["materialized"] = true
		return
	if bool(token.get("materialized", false)) or bool(token.get("resolved", false)) and str(token.get("phase", "")) == "done":
		return
	if int(token.get("bundle_start", 0)) > 0:
		token["bundle"] = maxi(int(token.get("bundle", 0)) - 1, 0)
		if int(token.get("bundle", 0)) <= 0 and str(token.get("phase", "")) == "out":
			token["phase"] = "back"
			token["travel_left"] = float(token.get("travel_total", 0.0))
	var left: float = float(token.get("travel_left", 0.0)) - elapsed
	token["travel_left"] = left
	if left > 0.0:
		return
	if str(token.get("phase", "")) == "out":
		if str(token.get("kind", "")) == "hunt":
			_resolve_hunt(token, inventory)
		token["phase"] = "back"
		token["travel_left"] = float(token.get("travel_total", 0.0))
		if float(token.get("travel_left", 0.0)) <= 0.0:
			_finish_party(token, roster)
		return
	_finish_party(token, roster)


static func resolve_food_once(attacker: InventoryData, defender: InventoryData, token: Dictionary) -> int:
	if attacker == null or defender == null or token.is_empty():
		return 0
	if bool(token.get("resolved", false)) or bool(token.get("materialized", false)):
		return 0
	var moved := 0
	var edible: Array = [
		ResourceData.ResourceType.BERRIES,
		ResourceData.ResourceType.GRAIN,
		ResourceData.ResourceType.MEAT,
		ResourceData.ResourceType.BREAD,
	]
	while moved < 8:
		var took := false
		for rt in edible:
			var food_type: ResourceData.ResourceType = rt
			if defender.get_count(food_type) <= 0:
				continue
			if not attacker.has_space() and attacker.get_count(food_type) >= attacker.max_stack:
				continue
			defender.remove_item(food_type, 1)
			attacker.add_item(food_type, 1)
			moved += 1
			took = true
			break
		if not took:
			break
	token["resolved"] = true
	token["phase"] = "back"
	return moved


static func _resolve_hunt(token: Dictionary, inventory: InventoryData) -> void:
	if bool(token.get("resolved", false)):
		return
	var chunk: Vector2i = token.get("target_chunk", Vector2i.ZERO)
	if MutationStore.take_wildlife(chunk, 1) <= 0:
		token["resolved"] = true
		return
	var yields: Dictionary = {}
	if CorpseConfig:
		yields = CorpseConfig.get_yields("deer")
	var meat: int = int(yields.get("meat", 2))
	var hide: int = int(yields.get("hide", 0))
	if inventory:
		for _i in maxi(meat, 0):
			inventory.add_item(ResourceData.ResourceType.MEAT, 1)
		for _i in maxi(hide, 0):
			inventory.add_item(ResourceData.ResourceType.HIDE, 1)
	token["resolved"] = true
	token["meat"] = meat


static func scores_auto_hunt(player_owned: bool) -> bool:
	return not player_owned


static func has_haul_job(worker: Node) -> bool:
	if worker == null or not is_instance_valid(worker):
		return false
	var kind := str(worker.get_meta("next_job_kind", ""))
	return kind == "chunk" or kind == "gather"


static func park_field_gather(claim: Node, worker: Node) -> bool:
	if claim == null or worker == null or not is_instance_valid(worker):
		return false
	if not has_haul_job(worker):
		return false
	var trips := _field_trips(claim)
	var body_id := worker.get_instance_id()
	for trip_v in trips:
		if trip_v is Dictionary and int((trip_v as Dictionary).get("body_id", 0)) == body_id:
			if worker.has_method("set_sim_dormant"):
				worker.set_sim_dormant(true)
			return true
	var chunk := Vector2i.ZERO
	var key := str(worker.get_meta("next_job_chunk", ""))
	var parts := key.split(",")
	if parts.size() == 2:
		chunk = Vector2i(int(parts[0]), int(parts[1]))
	elif worker.has_meta("next_job_pos") and worker.get_meta("next_job_pos") is Vector2 and ChunkUtils:
		chunk = ChunkUtils.get_chunk_coords(worker.get_meta("next_job_pos"))
	elif worker is Node2D and ChunkUtils:
		chunk = ChunkUtils.get_chunk_coords((worker as Node2D).global_position)
	var home := Vector2.ZERO
	if claim is Node2D:
		home = (claim as Node2D).global_position
	var there := home
	if ChunkUtils:
		there = ChunkUtils.get_chunk_center(chunk)
	var travel := maxf(there.distance_to(home) / MARCH_PX_PER_SEC, 1.0)
	trips.append({
		"body_id": body_id,
		"chunk": chunk,
		"phase": "out",
		"travel_left": travel,
		"travel_total": travel,
		"paid": false,
	})
	claim.set_meta("field_trips", trips)
	if worker.has_method("set_sim_dormant"):
		worker.set_sim_dormant(true)
	return true


static func release_unpaid_field_trip(claim: Node, worker: Node) -> void:
	if claim == null or worker == null:
		return
	var body_id := worker.get_instance_id()
	var trips := _field_trips(claim)
	var kept: Array = []
	for trip_v in trips:
		if not (trip_v is Dictionary):
			continue
		var trip: Dictionary = trip_v
		if int(trip.get("body_id", 0)) == body_id and not bool(trip.get("paid", false)):
			continue
		kept.append(trip)
	claim.set_meta("field_trips", kept)


static func advance_field_trips(claim: Node, delta: float, player_pos: Vector2, wake_r: float) -> void:
	if claim == null:
		return
	var accum := float(claim.get_meta("field_trip_accum", 0.0)) + delta
	var interval := 30.0
	if WorldGenConfig:
		interval = maxf(float(WorldGenConfig.settlement_tick_interval_sec), 1.0)
	if accum < interval:
		claim.set_meta("field_trip_accum", accum)
		return
	claim.set_meta("field_trip_accum", 0.0)
	step_field_trips(claim, accum, player_pos, wake_r)


static func step_field_trips(claim: Node, elapsed: float, player_pos: Vector2, wake_r: float) -> void:
	if claim == null or not claim.has_meta("field_trips"):
		return
	var trips := _field_trips(claim)
	var kept: Array = []
	for trip_v in trips:
		if not (trip_v is Dictionary):
			continue
		var trip: Dictionary = trip_v
		var worker := _body_from_id(claim, int(trip.get("body_id", 0)))
		if worker == null:
			continue
		var chunk: Vector2i = trip.get("chunk", Vector2i.ZERO)
		if _player_reached_work(player_pos, chunk, worker, wake_r) and not bool(trip.get("paid", false)):
			if worker.has_method("set_sim_dormant"):
				worker.set_sim_dormant(false)
			continue
		var left := float(trip.get("travel_left", 0.0)) - elapsed
		trip["travel_left"] = left
		if left > 0.0:
			kept.append(trip)
			continue
		if str(trip.get("phase", "")) == "out":
			_pay_field_haul(claim, worker, chunk, trip)
			trip["phase"] = "back"
			trip["travel_left"] = float(trip.get("travel_total", 1.0))
			kept.append(trip)
			continue
		_wake_carrier_on_circle(claim, worker, chunk, player_pos, wake_r)
	claim.set_meta("field_trips", kept)


static func _field_trips(claim: Node) -> Array:
	if claim != null and claim.has_meta("field_trips"):
		var stored: Variant = claim.get_meta("field_trips")
		if stored is Array:
			return stored
	return []


static func _body_from_id(claim: Node, body_id: int) -> Node:
	if body_id == 0 or claim == null:
		return null
	var found: Variant = instance_from_id(body_id)
	if found is Node and is_instance_valid(found):
		return found as Node
	return null


static func _player_reached_work(player_pos: Vector2, chunk: Vector2i, worker: Node, wake_r: float) -> bool:
	if player_pos == Vector2.INF:
		return false
	if ChunkUtils and ChunkUtils.get_chunk_coords(player_pos) == chunk:
		return true
	if worker is Node2D and player_pos.distance_to((worker as Node2D).global_position) <= wake_r:
		return true
	return false


static func _pay_field_haul(claim: Node, worker: Node, chunk: Vector2i, trip: Dictionary) -> void:
	if bool(trip.get("paid", false)):
		return
	trip["paid"] = true
	var done: Dictionary = {}
	if claim.has_meta("away_trip_resolved"):
		var stored: Variant = claim.get_meta("away_trip_resolved")
		if stored is Dictionary:
			done = stored
	var key_id := str(worker.get_instance_id())
	if done.has(key_id):
		return
	done[key_id] = true
	claim.set_meta("away_trip_resolved", done)
	if MutationStore == null:
		return
	if WorldGenConfig:
		MutationStore.ensure_abstract_resource_pool(chunk, int(WorldGenConfig.world_seed), WorldGenConfig)
	var yields: Dictionary = {
		"berries": 2.0, "grain": 3.0, "wood": 1.0, "stone": 1.0, "fiber": 1.0, "nuts": 1.0, "bugs": 1.0,
	}
	if WorldGenConfig:
		yields = WorldGenConfig.gather_yield_per_population
	var keys: Array[String] = ["berries", "grain", "nuts", "bugs", "wood", "stone", "fiber"]
	var types: Array[int] = [
		ResourceData.ResourceType.BERRIES,
		ResourceData.ResourceType.GRAIN,
		ResourceData.ResourceType.NUTS,
		ResourceData.ResourceType.BUGS,
		ResourceData.ResourceType.WOOD,
		ResourceData.ResourceType.STONE,
		ResourceData.ResourceType.FIBER,
	]
	var hands: Variant = worker.get("inventory")
	for i in keys.size():
		var want := int(floor(float(yields.get(keys[i], 0.0))))
		if want <= 0:
			continue
		var got := int(MutationStore.deplete_abstract_resource(chunk, keys[i], want))
		if got > 0 and hands != null and hands.has_method("add_item"):
			hands.add_item(types[i], got)


static func _wake_carrier_on_circle(claim: Node, worker: Node, chunk: Vector2i, player_pos: Vector2, wake_r: float) -> void:
	if not (worker is Node2D) or not (claim is Node2D):
		return
	var home: Vector2 = (claim as Node2D).global_position
	var there := home + Vector2(wake_r, 0.0)
	if ChunkUtils:
		there = ChunkUtils.get_chunk_center(chunk)
	var away := there - home
	if away.length_squared() < 1.0:
		away = Vector2.RIGHT
	var spot := home + away.normalized() * maxf(wake_r - 48.0, 32.0)
	if player_pos != Vector2.INF and spot.distance_to(player_pos) > wake_r - 16.0:
		var from_player := spot - player_pos
		if from_player.length_squared() < 1.0:
			from_player = away
		spot = player_pos + from_player.normalized() * maxf(wake_r - 48.0, 32.0)
	(worker as Node2D).global_position = spot
	if worker.has_method("set_sim_dormant"):
		worker.set_sim_dormant(false)
	worker.set_meta("moving_to_deposit", true)
	worker.set_meta("is_depositing", true)
	worker.set_meta("next_job_kind", "")
	var steer: Variant = worker.get("steering_agent")
	if steer != null and steer.has_method("retarget_seek"):
		steer.retarget_seek(home)


static func wake_party_on_circle(claim: Node, roster: RefCounted, token: Dictionary, wake_r: float) -> void:
	if claim == null or roster == null or token.is_empty() or bool(token.get("materialized", false)):
		return
	token["materialized"] = true
	if not (claim is Node2D):
		return
	var home: Vector2 = (claim as Node2D).global_position
	var aim := home + Vector2(wake_r, 0.0)
	var chunk_v: Variant = token.get("target_chunk", token.get("chunk", null))
	if chunk_v is Vector2i and ChunkUtils:
		aim = ChunkUtils.get_chunk_center(chunk_v)
	elif token.get("target") is Node2D and is_instance_valid(token.get("target")):
		aim = (token.get("target") as Node2D).global_position
	var away := aim - home
	if away.length_squared() < 1.0:
		away = Vector2.RIGHT
	var spot := home + away.normalized() * maxf(wake_r - 48.0, 32.0)
	var ids: Array = token.get("member_ids", [])
	for mid_v in ids:
		var mid := int(mid_v)
		var rec: Dictionary = roster.find_member(mid)
		if rec.is_empty():
			continue
		rec["position"] = spot
		rec["away"] = false
	mark_away(roster, ids, false)
	var tree := claim.get_tree()
	if tree == null:
		return
	for npc in tree.get_nodes_in_group("npcs"):
		if npc == null or not is_instance_valid(npc):
			continue
		if int(SettlementRoster.read_member_id(npc)) not in _int_list(ids):
			continue
		if npc is Node2D:
			(npc as Node2D).global_position = spot
		if npc.has_method("set_sim_dormant"):
			npc.set_sim_dormant(false)
		npc.set_meta("moving_to_deposit", true)


static func _int_list(ids: Array) -> Array:
	var out: Array = []
	for mid_v in ids:
		out.append(int(mid_v))
	return out


static func _finish_party(token: Dictionary, roster: RefCounted) -> void:
	mark_away(roster, token.get("member_ids", []), false)
	token["phase"] = "done"
	token["away"] = false


static func _home_fighter_ids(roster: RefCounted) -> Array:
	var ids: Array = []
	for m in roster.get("members"):
		if not (m is Dictionary):
			continue
		var rec: Dictionary = m as Dictionary
		if not bool(rec.get("alive", false)) or bool(rec.get("away", false)):
			continue
		if str(rec.get("type", "")) in ["clansman", "caveman", "leader"]:
			ids.append(int(rec.get("id", 0)))
	return ids


static func _take_bundle(inventory: InventoryData, people: int) -> int:
	if inventory == null or people <= 0:
		return 0
	var taken := 0
	while taken < people and inventory.get_count(ResourceData.ResourceType.BERRIES) > 0:
		inventory.remove_item(ResourceData.ResourceType.BERRIES, 1)
		taken += 1
	return taken
