extends RefCounted
## Herd, hut, and milestone work for a camp that is asleep.
## Called only from ClanBrain._run_settlement_slice. An awake camp keeps the live FSM.

const ChunkGeneratorScript = preload("res://scripts/world/chunk_generator.gd")
const WildlifeRollScript = preload("res://scripts/world/wildlife_chunk_roll.gd")
const HutStateScript = preload("res://scripts/npc/states/build_hut_for_woman_state.gd")
const NPC_SCENE = preload("res://scenes/NPC.tscn")

const MIN_TRAVEL_PX := 32.0
## Same band the live herder must close before she attaches.
const ATTACH_PX := 150.0


static func walk_speed() -> float:
	var agility := 10.0
	var mult := 9.5
	if NPCConfig and "speed_agility_multiplier" in NPCConfig:
		mult = float(NPCConfig.speed_agility_multiplier)
	return maxf(agility * mult, 1.0)


static func trip_seconds(distance_px: float) -> float:
	## Straight walk if she stood still, or the measured chase if she wanders.
	## A standing son, empty camp: 500px joined at 23.0s, 950px joined at 25.2s.
	## He left within 3s both times. She walked off, so the catch is most of the trip.
	var travel := maxf(distance_px, MIN_TRAVEL_PX)
	var outbound := maxf(travel - ATTACH_PX, MIN_TRAVEL_PX)
	var follow := 0.85
	if NPCConfig and "herd_follower_speed_multiplier" in NPCConfig:
		follow = float(NPCConfig.herd_follower_speed_multiplier)
	var home_speed := maxf(walk_speed() * follow, 1.0)
	var standing := outbound / walk_speed() + travel / home_speed
	var chased := 23.0 + (travel - 500.0) * ((25.2 - 23.0) / 450.0)
	# He gathers before he leaves. Two standing runs, first son to the wife coming home:
	# 36s and 60s. The chase above is about 23s of that, so the camp wait is the middle of the rest.
	var depart := 25.0
	return maxf(standing, chased) + depart


static func detection_range() -> float:
	if NPCConfig and "herd_detection_range" in NPCConfig:
		return float(NPCConfig.herd_detection_range)
	return 1700.0


static func advance(brain: RefCounted, elapsed: float) -> void:
	if brain == null or elapsed <= 0.0:
		return
	if not bool(brain.get("is_dormant")):
		return
	var claim: Node = brain.get("territory")
	if claim == null or not is_instance_valid(claim):
		return
	if claim.get("player_owned") == true:
		return
	var roster: RefCounted = brain.get("roster")
	if roster == null:
		return
	_advance_slots(brain, claim, roster, elapsed)
	_advance_milestone_builds(brain, claim, roster, elapsed)
	_advance_building_craft(claim, elapsed)


static func _advance_slots(brain: RefCounted, claim: Node, roster: RefCounted, elapsed: float) -> void:
	var slots: int = int(brain.call("dormant_herder_slots"))
	var state: Array = brain.get("_herd_slots")
	while state.size() < slots:
		state.append({"phase": "travel", "progress": 0.0, "key": "", "member_id": 0})
	while state.size() > slots:
		state.pop_back()
	brain.set("_herd_slots", state)
	var remaining := elapsed
	var guard := 0
	while remaining > 0.0 and guard < 64:
		guard += 1
		for i in state.size():
			var slot: Dictionary = state[i]
			if str(slot.get("phase", "travel")) == "done":
				continue
			if str(slot.get("phase", "travel")) == "travel" and str(slot.get("key", "")) == "":
				var nxt := _pick_candidate(brain, claim, roster, state)
				if not nxt.is_empty():
					var new_key := str(nxt.get("seed_key", ""))
					slot["key"] = new_key
					slot["progress"] = 0.0
					slot["distance"] = _claim_pos(claim).distance_to(nxt.get("position", Vector2.ZERO) as Vector2)
					if MutationStore and not new_key.is_empty():
						MutationStore.spend_herd_seed(new_key)
		var step := remaining
		var busy := false
		for slot in state:
			var row: Dictionary = slot
			var need := _slot_need(row)
			if need < 0.0:
				continue
			busy = true
			step = minf(step, need)
		if not busy:
			break
		for i in state.size():
			var slot: Dictionary = state[i]
			var need := _slot_need(slot)
			if need < 0.0:
				continue
			var arriving := step + 0.0001 >= need
			slot["progress"] = float(slot.get("progress", 0.0)) + step
			if not arriving:
				continue
			if str(slot.get("phase", "travel")) == "build":
				if _finish_hut(brain, claim, roster, int(slot.get("member_id", 0))):
					# He walked one wife home. A live son does not take a second search.
					slot["phase"] = "done"
					slot["progress"] = 0.0
					slot["key"] = ""
					slot["member_id"] = 0
				else:
					slot["progress"] = float(HutStateScript.BUILD_DURATION)
			else:
				var trip_key := str(slot.get("key", ""))
				var target := _candidate_by_key(brain, claim, roster, state, trip_key)
				var joined_id := 0
				if not target.is_empty():
					joined_id = _deliver(brain, claim, roster, target)
				elif not trip_key.is_empty() and MutationStore:
					MutationStore.unspend_herd_seed(trip_key)
				slot["key"] = ""
				slot["progress"] = 0.0
				if joined_id > 0 and str(target.get("type", "")) == "woman":
					slot["phase"] = "build"
					slot["member_id"] = joined_id
				else:
					slot["phase"] = "travel"
					slot["member_id"] = 0
		remaining -= step


static func _slot_need(slot: Dictionary) -> float:
	if str(slot.get("phase", "travel")) == "done":
		return -1.0
	if str(slot.get("phase", "travel")) == "build":
		return maxf(float(HutStateScript.BUILD_DURATION) - float(slot.get("progress", 0.0)), 0.0)
	if str(slot.get("key", "")) == "":
		return -1.0
	return maxf(trip_seconds(float(slot.get("distance", MIN_TRAVEL_PX))) - float(slot.get("progress", 0.0)), 0.0)


static func _deliver(brain: RefCounted, claim: Node, roster: RefCounted, target: Dictionary) -> int:
	var kind := str(target.get("type", ""))
	var seed_key := str(target.get("seed_key", ""))
	var node := _claim_live_node(claim, target)
	if node != null:
		var existing_clan := str(node.get("clan_name")) if node.get("clan_name") != null else ""
		if existing_clan != "":
			if MutationStore and not seed_key.is_empty():
				MutationStore.unspend_herd_seed(seed_key)
			return 0
	if kind == "woman":
		if node == null:
			node = _spawn_herdable(claim, target, kind)
		if node != null:
			_bring_home(node, claim, kind)
		var leader: Node = claim.get("owner_npc") if claim.get("owner_npc") != null else null
		if node != null:
			roster.call("upsert_from_live_npc", node, leader, {})
			var mid := 0
			if node.has_meta("settlement_member_id"):
				mid = int(node.get_meta("settlement_member_id"))
			roster.call("note_awaiting_hut", mid, _father_id(roster))
			return mid
		if MutationStore and not seed_key.is_empty():
			MutationStore.unspend_herd_seed(seed_key)
		return 0
	if node == null:
		node = _spawn_herdable(claim, target, kind)
	if node != null:
		_bring_home(node, claim, kind)
		var animal_name := str(target.get("name", kind))
		if node.get("npc_name") != null:
			animal_name = str(node.get("npc_name"))
		roster.call("add_herd_animal", kind, animal_name, seed_key)
		return 0
	if MutationStore and not seed_key.is_empty():
		MutationStore.unspend_herd_seed(seed_key)
	return 0


static func _finish_hut(brain: RefCounted, claim: Node, roster: RefCounted, member_id: int) -> bool:
	if member_id <= 0:
		return true
	var woman := _node_for_member(claim, member_id)
	if woman == null:
		roster.call("clear_awaiting_hut", member_id, "")
		return true
	var main := _main(claim)
	if main == null or not main.has_method("_place_herder_hut"):
		return false
	var father := _node_for_member(claim, _father_id(roster))
	if OccupationSystem and OccupationSystem.has_method("unassign"):
		OccupationSystem.unassign(woman, "dormant_hut")
	var placed: bool = bool(main.call("_place_herder_hut", claim, woman, father))
	if not placed:
		return false
	var hut_id := ""
	if OccupationSystem and OccupationSystem.has_method("get_workplace"):
		var hut: Node = OccupationSystem.get_workplace(woman)
		if hut and hut.has_meta("hut_net_id"):
			hut_id = str(hut.get_meta("hut_net_id"))
	roster.call("clear_awaiting_hut", member_id, hut_id)
	return true


static func _advance_milestone_builds(brain: RefCounted, claim: Node, roster: RefCounted, elapsed: float) -> void:
	if not (claim is LandClaim):
		return
	var jobs: Array = brain.get("_dormant_milestones")
	_queue_milestone_jobs(brain, claim, roster, jobs)
	var duration := 18.0
	if BalanceConfig:
		duration = float(BalanceConfig.ai_milestone_build_duration_sec)
	var keep: Array = []
	for job in jobs:
		if not (job is Dictionary):
			continue
		var row: Dictionary = job
		if _claim_has_type(claim, int(row.get("building_type", -1))):
			continue
		row["progress"] = float(row.get("progress", 0.0)) + elapsed
		if float(row["progress"]) + 0.0001 < duration:
			keep.append(row)
			continue
		var main := _main(claim)
		if main == null or not main.has_method("_place_ai_building_at"):
			row["progress"] = duration
			keep.append(row)
			continue
		var site: Vector2 = row.get("site", Vector2.ZERO)
		var placed: bool = bool(main.call("_place_ai_building_at", claim, int(row.get("building_type", -1)), site))
		if not placed:
			row["progress"] = duration
			keep.append(row)
	brain.set("_dormant_milestones", keep)


static func _queue_milestone_jobs(brain: RefCounted, claim: Node, roster: RefCounted, jobs: Array) -> void:
	var sheep := int(roster.call("count_herd_animals", "sheep"))
	var goats := int(roster.call("count_herd_animals", "goat"))
	var babies := int(roster.call("get_baby_count"))
	var grain := 0
	var hide := 0
	var inv = claim.get("inventory")
	if inv:
		grain = int(inv.get_count(ResourceData.ResourceType.GRAIN))
		hide = int(inv.get_count(ResourceData.ResourceType.HIDE))
	var oven_grain: int = BalanceConfig.milestone_oven_min_grain if BalanceConfig else 1
	var rack_hide: int = BalanceConfig.milestone_drying_rack_min_hide if BalanceConfig else 3
	var farm_sheep: int = BalanceConfig.milestone_farm_min_sheep if BalanceConfig else 1
	var dairy_goats: int = BalanceConfig.milestone_dairy_min_goats if BalanceConfig else 1
	var hut_babies: int = BalanceConfig.milestone_living_hut_min_babies if BalanceConfig else 2
	if grain >= oven_grain:
		_ensure_job(claim, jobs, ResourceData.ResourceType.OVEN)
	if hide >= rack_hide:
		_ensure_job(claim, jobs, ResourceData.ResourceType.DRYING_RACK)
	var block_luxury := false
	if ClanBrainTuningConfig:
		block_luxury = bool(ClanBrainTuningConfig.food_critical_block_luxury_milestones)
	if block_luxury and brain.get("workforce_mode") == ClanBrain.WorkforceMode.STARVING:
		return
	if sheep >= farm_sheep:
		_ensure_job(claim, jobs, ResourceData.ResourceType.FARM)
	if goats >= dairy_goats:
		_ensure_job(claim, jobs, ResourceData.ResourceType.DAIRY_FARM)
	if babies >= hut_babies:
		_ensure_job(claim, jobs, ResourceData.ResourceType.LIVING_HUT)


static func _ensure_job(claim: Node, jobs: Array, building_type: int) -> void:
	if _claim_has_type(claim, building_type):
		return
	for job in jobs:
		if job is Dictionary and int((job as Dictionary).get("building_type", -1)) == building_type:
			return
	var main := _main(claim)
	if main == null or not main.has_method("_find_ai_building_site"):
		return
	var site: Vector2 = main.call("_find_ai_building_site", claim, building_type)
	if site == Vector2.ZERO:
		return
	jobs.append({
		"building_type": building_type,
		"site": site,
		"progress": 0.0,
	})


static func _advance_building_craft(claim: Node, elapsed: float) -> void:
	if ClaimBuildingIndex == null or not (claim is LandClaim):
		return
	var inv = claim.get("inventory")
	for building in ClaimBuildingIndex.get_buildings_in_claim(claim):
		if building == null or not is_instance_valid(building):
			continue
		var btype := int(building.get("building_type"))
		if btype == int(ResourceData.ResourceType.LIVING_HUT):
			continue
		_move_recipe_inputs(building, inv)
		var prod = building.get_node_or_null("ProductionComponent")
		if prod and prod.has_method("advance_while_asleep"):
			prod.call("advance_while_asleep", elapsed)
		var passive = building.get_node_or_null("PassiveProductionComponent")
		if passive and passive.has_method("advance_while_asleep"):
			passive.call("advance_while_asleep", elapsed)


static func _move_recipe_inputs(building: Node, claim_inv) -> void:
	if claim_inv == null or building == null or building.get("inventory") == null:
		return
	var prod = building.get_node_or_null("ProductionComponent")
	var recipe: Dictionary = {}
	if prod and prod.get("recipe") is Dictionary:
		recipe = prod.get("recipe")
	var passive = building.get_node_or_null("PassiveProductionComponent")
	if recipe.is_empty() and passive and passive.get("recipe") is Dictionary:
		recipe = passive.get("recipe")
	var bin = building.get("inventory")
	for input in recipe.get("inputs", []):
		if not (input is Dictionary):
			continue
		var input_type: int = int((input as Dictionary).get("type", 0))
		var qty: int = int((input as Dictionary).get("quantity", 1))
		if bin.get_count(input_type) >= qty:
			continue
		if claim_inv.get_count(input_type) < qty:
			continue
		claim_inv.remove_item(input_type, qty)
		bin.add_item(input_type, qty)


static func _candidates(brain: RefCounted, claim: Node, roster: RefCounted) -> Array:
	return _eligible_candidates(brain, claim, roster, {})


static func _eligible_candidates(brain: RefCounted, claim: Node, roster: RefCounted, reserved: Dictionary) -> Array:
	var by_key: Dictionary = {}
	_merge_candidate_rows(by_key, _injected_candidates(claim))
	_merge_candidate_rows(by_key, _world_candidates(claim))
	_merge_candidate_rows(by_key, _live_wild_candidates(claim))
	var range_px := detection_range()
	var origin := _claim_pos(claim)
	var kept: Array = []
	for key in by_key:
		var item: Dictionary = by_key[key]
		var pos: Vector2 = item.get("position", Vector2.ZERO)
		if origin.distance_to(pos) > range_px:
			continue
		var seed_key := str(item.get("seed_key", ""))
		if seed_key.is_empty():
			continue
		if reserved.has(seed_key):
			continue
		if _already_joined(roster, seed_key):
			continue
		if not _chunk_or_live_available(claim, item):
			continue
		if _wild_node_has_clan(claim, item):
			continue
		kept.append(item)
	return kept


static func _injected_candidates(claim: Node) -> Array:
	if claim == null or not claim.has_meta("parity_herd_candidates"):
		return []
	var injected = claim.get_meta("parity_herd_candidates")
	if injected is Array:
		return (injected as Array).duplicate()
	return []


static func _merge_candidate_rows(into: Dictionary, rows: Array) -> void:
	for row in rows:
		if not (row is Dictionary):
			continue
		var item: Dictionary = row
		var key := str(item.get("seed_key", ""))
		if key.is_empty():
			continue
		if not into.has(key):
			into[key] = item.duplicate()
			continue
		var existing: Dictionary = into[key]
		if existing.get("node", null) == null and item.get("node", null) != null:
			existing["node"] = item.get("node")
			into[key] = existing


static func _live_wild_candidates(claim: Node) -> Array:
	var out: Array = []
	var tree := claim.get_tree() if claim else null
	if tree == null:
		return out
	for npc in tree.get_nodes_in_group("npcs"):
		if not is_instance_valid(npc) or not (npc is Node2D):
			continue
		var kind := str(npc.get("npc_type"))
		if kind != "woman" and kind != "sheep" and kind != "goat":
			continue
		var clan := str(npc.get("clan_name")) if npc.get("clan_name") != null else ""
		if clan != "":
			continue
		if npc.has_method("can_join_clan") and not npc.can_join_clan():
			continue
		var key := str(npc.get_meta("herd_seed_key", ""))
		if key.is_empty():
			key = "live:%d:%s" % [npc.get_instance_id(), kind]
		out.append({
			"type": kind,
			"position": (npc as Node2D).global_position,
			"name": str(npc.get("npc_name")) if npc.get("npc_name") != null else kind,
			"age": int(npc.get("age")) if npc.get("age") != null else 25,
			"name_seed": 0,
			"seed_key": key,
			"node": npc,
		})
	return out


static func _chunk_or_live_available(claim: Node, item: Dictionary) -> bool:
	var key := str(item.get("seed_key", ""))
	if key.is_empty():
		return false
	if item.get("node", null) != null and is_instance_valid(item.get("node")):
		return true
	var live := _wild_node_for_key(claim, item)
	if live != null:
		return true
	if MutationStore and MutationStore.herd_seed_spent(key):
		return false
	return true


static func _wild_node_has_clan(claim: Node, item: Dictionary) -> bool:
	var node := _wild_node_for_key(claim, item)
	if node == null:
		return false
	var clan := str(node.get("clan_name")) if node.get("clan_name") != null else ""
	return clan != ""


static func _wild_node_for_key(claim: Node, item: Dictionary) -> Node:
	var preset: Variant = item.get("node", null)
	if preset is Node and is_instance_valid(preset):
		return preset
	return _claim_live_node(claim, item)


static func _reserved_keys(slots: Array) -> Dictionary:
	var reserved: Dictionary = {}
	for slot in slots:
		if not (slot is Dictionary):
			continue
		var row: Dictionary = slot
		if str(row.get("phase", "travel")) != "travel":
			continue
		var key := str(row.get("key", ""))
		if key != "":
			reserved[key] = true
	return reserved


static func _world_candidates(claim: Node) -> Array:
	var out: Array = []
	if WorldGenConfig == null or ChunkUtils == null:
		return out
	var origin := _claim_pos(claim)
	var reach := detection_range() + ChunkUtils.CHUNK_SIZE
	var center := ChunkUtils.get_chunk_coords(origin)
	var span := int(ceil(reach / ChunkUtils.CHUNK_SIZE))
	var gen := ChunkGeneratorScript.new()
	for dx in range(-span, span + 1):
		for dy in range(-span, span + 1):
			var chunk := Vector2i(center.x + dx, center.y + dy)
			var data: Dictionary = gen.generate_chunk(int(WorldGenConfig.world_seed), chunk, WorldGenConfig)
			for woman in data.get("wild_women", []):
				if not (woman is Dictionary):
					continue
				var w: Dictionary = woman
				out.append({
					"type": "woman",
					"position": w.get("position", Vector2.ZERO),
					"name": "",
					"age": int(w.get("age", 25)),
					"name_seed": int(w.get("name_seed", 0)),
					"seed_key": str(w.get("seed_key", "")),
				})
			for animal in WildlifeRollScript.describe(chunk):
				if not (animal is Dictionary):
					continue
				var a: Dictionary = animal
				var kind := str(a.get("type", ""))
				if kind != "sheep" and kind != "goat":
					continue
				out.append({
					"type": kind,
					"position": a.get("position", Vector2.ZERO),
					"name": kind,
					"seed_key": str(a.get("seed_key", "")),
				})
	return out


static func _pick_candidate(brain: RefCounted, claim: Node, roster: RefCounted, slots: Array) -> Dictionary:
	var reserved := _reserved_keys(slots)
	var origin := _claim_pos(claim)
	var pool := _eligible_candidates(brain, claim, roster, reserved)
	var women: Array = []
	var animals: Array = []
	for row in pool:
		var item: Dictionary = row
		var kind := str(item.get("type", ""))
		if kind == "woman":
			women.append(item)
		elif kind == "sheep" or kind == "goat":
			animals.append(item)
	var best := _nearest_row(women, origin)
	if not best.is_empty():
		return best
	return _nearest_row(animals, origin)


static func _nearest_row(rows: Array, origin: Vector2) -> Dictionary:
	var best: Dictionary = {}
	var best_d := INF
	for row in rows:
		if not (row is Dictionary):
			continue
		var item: Dictionary = row
		var d := origin.distance_to(item.get("position", Vector2.ZERO) as Vector2)
		if d < best_d:
			best_d = d
			best = item
	return best


static func _nearest_candidate(brain: RefCounted, claim: Node, roster: RefCounted, slots: Array) -> Dictionary:
	return _pick_candidate(brain, claim, roster, slots)


static func _candidate_by_key(brain: RefCounted, claim: Node, roster: RefCounted, slots: Array, key: String) -> Dictionary:
	if key.is_empty():
		return {}
	var reserved := _reserved_keys(slots)
	reserved.erase(key)
	for row in _eligible_candidates(brain, claim, roster, reserved):
		if str((row as Dictionary).get("seed_key", "")) == key:
			return row
	# Trip was reserved; deliver even if eligibility changed (e.g. live body moved).
	return _row_by_key_any(claim, key)


static func _row_by_key_any(claim: Node, key: String) -> Dictionary:
	var by_key: Dictionary = {}
	_merge_candidate_rows(by_key, _injected_candidates(claim))
	_merge_candidate_rows(by_key, _world_candidates(claim))
	_merge_candidate_rows(by_key, _live_wild_candidates(claim))
	if by_key.has(key):
		return (by_key[key] as Dictionary).duplicate()
	return {}


static func _already_joined(roster: RefCounted, seed_key: String) -> bool:
	for row in roster.get("herd_animals"):
		if row is Dictionary and str((row as Dictionary).get("seed_key", "")) == seed_key:
			return true
	return false


static func _claim_live_node(claim: Node, target: Dictionary) -> Node:
	var tree := claim.get_tree()
	if tree == null:
		return null
	var key := str(target.get("seed_key", ""))
	var kind := str(target.get("type", ""))
	var pos: Vector2 = target.get("position", Vector2.ZERO)
	var preset: Variant = target.get("node", null)
	if preset is Node and is_instance_valid(preset):
		return preset
	for npc in tree.get_nodes_in_group("npcs"):
		if not is_instance_valid(npc):
			continue
		if str(npc.get_meta("herd_seed_key", "")) == key and key != "":
			return npc
		if str(npc.get("npc_type")) != kind:
			continue
		var clan := str(npc.get("clan_name")) if npc.get("clan_name") != null else ""
		if clan != "":
			continue
		if npc is Node2D and (npc as Node2D).global_position.distance_to(pos) <= 64.0:
			return npc
	return null


static func _spawn_herdable(claim: Node, target: Dictionary, kind: String) -> Node:
	var parent := _npc_parent(claim)
	if parent == null:
		return null
	var npc: Node = NPC_SCENE.instantiate()
	if npc == null:
		return null
	var animal_name := str(target.get("name", ""))
	if animal_name.is_empty():
		var seed := int(target.get("name_seed", 0))
		if seed != 0:
			animal_name = NamingUtils.generate_caveman_name_seeded(seed)
		else:
			animal_name = kind
	npc.set("npc_type", kind)
	npc.set("npc_name", animal_name)
	npc.set("age", int(target.get("age", 25)))
	if kind == "sheep":
		npc.set("traits", ["herd", "group"])
	elif kind == "woman" or kind == "goat":
		npc.set("traits", ["herd"])
	npc.set_meta("herd_seed_key", str(target.get("seed_key", "")))
	parent.add_child(npc)
	return npc


static func _bring_home(npc: Node, claim: Node, kind: String) -> void:
	var clan := str(claim.get("clan_name")) if claim.get("clan_name") != null else ""
	if npc.has_method("set_clan_name"):
		npc.call("set_clan_name", clan, "dormant_herd")
	else:
		npc.set("clan_name", clan)
	if npc is Node2D:
		var home: Vector2 = _claim_pos(claim)
		if kind == "woman":
			home += Vector2(48, 0)
		else:
			home += Vector2(80, 24)
		(npc as Node2D).global_position = home


static func _father_id(roster: RefCounted) -> int:
	for m in roster.get("members"):
		if not (m is Dictionary):
			continue
		var rec: Dictionary = m
		if not bool(rec.get("alive", false)):
			continue
		var kind := str(rec.get("type", ""))
		if kind in ["clansman", "caveman", "leader"]:
			return int(rec.get("id", 0))
	return 0


static func _node_for_member(claim: Node, member_id: int) -> Node:
	if member_id <= 0:
		return null
	var tree := claim.get_tree()
	if tree == null:
		return null
	for npc in tree.get_nodes_in_group("npcs"):
		if is_instance_valid(npc) and int(npc.get_meta("settlement_member_id", 0)) == member_id:
			return npc
	return null


static func _npc_parent(claim: Node) -> Node:
	var main := _main(claim)
	if main and main.get("world_objects") != null:
		return main.get("world_objects")
	return claim.get_parent()


static func _main(claim: Node) -> Node:
	var tree := claim.get_tree()
	if tree == null:
		return null
	return tree.get_first_node_in_group("main")


static func _claim_pos(claim: Node) -> Vector2:
	if claim is Node2D:
		return (claim as Node2D).global_position
	return Vector2.ZERO


static func _claim_has_type(claim: Node, building_type: int) -> bool:
	if claim.get_tree() == null:
		return false
	var clan := str(claim.get("clan_name")) if claim.get("clan_name") != null else ""
	for bld in claim.get_tree().get_nodes_in_group("buildings"):
		if not is_instance_valid(bld) or bld is LandClaim:
			continue
		if str(bld.get("clan_name")) == clan and int(bld.get("building_type")) == building_type:
			return true
	return false
