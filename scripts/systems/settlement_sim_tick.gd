class_name SettlementSimTick
extends RefCounted
## Warm-tier settlement simulation — food, gather, passive buildings, starvation.

const SettlementRosterScript = preload("res://scripts/systems/settlement_roster.gd")
const AbstractGatherScript = preload("res://scripts/systems/abstract_gather.gd")
const AbstractHuntScript = preload("res://scripts/systems/abstract_hunt.gd")
const AbstractSlaughterScript = preload("res://scripts/systems/abstract_slaughter.gd")
const ClanFoodBufferScript = preload("res://scripts/systems/clan_food_buffer.gd")
const HutSpecialtyScript = preload("res://scripts/buildings/hut_specialty.gd")
const HutCarryScript = preload("res://scripts/buildings/hut_carry.gd")

const FOOD_FEED_PRIORITY: Array = [
	ResourceData.ResourceType.COOKED_MEAT,
	ResourceData.ResourceType.BREAD,
	ResourceData.ResourceType.MEAT,
	ResourceData.ResourceType.BERRIES,
	ResourceData.ResourceType.MILK,
	ResourceData.ResourceType.MUSHROOM,
	ResourceData.ResourceType.NUTS,
	ResourceData.ResourceType.BUGS,
]


static func tick(
	claim: Node,
	roster: RefCounted,
	elapsed_sec: float,
	chunk_coords: Vector2i = Vector2i.ZERO,
	clan_starving: bool = false,
	hunt_intent_state: int = AbstractHuntScript.HUNT_INTENT_NONE,
	include_hunt_and_slaughter: bool = true,
	skip_member_ids: Dictionary = {},
	player_father_alive: bool = false,
	slice_id: int = -1
) -> Dictionary:
	var events: Dictionary = {
		"fed": [],
		"died": [],
		"produced": [],
		"burned_wood": 0,
		"gathered": [],
		"depleted": [],
		"biome": "",
		"hunt": {},
		"slaughter": {},
		"regen": [],
		"births": [],
		"pregnancies_started": [],
		"pregnancies_cancelled": [],
		"births_blocked": [],
		"grew_up": [],
		"husband_reassigned": [],
	}
	if claim == null or not is_instance_valid(claim) or roster == null:
		return events
	if not claim.get("inventory"):
		return events
	var inventory: InventoryData = claim.get("inventory") as InventoryData
	if inventory == null:
		return events
	var clan: String = str(claim.get("clan_name") if claim.get("clan_name") != null else roster.clan_name)
	var passive_state := _get_passive_state(claim)
	var skip := skip_member_ids.duplicate()
	for m in roster.members:
		if m is Dictionary and bool((m as Dictionary).get("away", false)):
			skip[int((m as Dictionary).get("id", 0))] = true

	for m in roster.members:
		if bool(m.get("alive", false)) and not skip.has(int(m.get("id", 0))):
			roster.drain_hunger(m, elapsed_sec)

	var coords: Vector2i = chunk_coords
	if coords == Vector2i.ZERO and ChunkUtils and claim is Node2D:
		coords = ChunkUtils.get_chunk_coords((claim as Node2D).global_position)
	var gather_events: Dictionary = AbstractGatherScript.gather_for_claim(
		claim, roster, coords, elapsed_sec, clan_starving, slice_id
	)
	events["gathered"] = gather_events.get("gathered", [])
	events["depleted"] = gather_events.get("depleted", [])
	events["biome"] = str(gather_events.get("biome", ""))
	events["regen"] = gather_events.get("regen", [])

	var hunt_events: Dictionary = {}
	if include_hunt_and_slaughter:
		hunt_events = AbstractHuntScript.hunt_for_claim(
			claim, roster, coords, clan_starving, hunt_intent_state
		)
		events["hunt"] = hunt_events
		var slaughter_events: Dictionary = AbstractSlaughterScript.slaughter_for_claim(
			claim, clan_starving, hunt_events, inventory
		)
		events["slaughter"] = slaughter_events

	# One second at a time so a birth only grows for the time after it happens,
	# and a cooldown can start another pregnancy inside the same interval.
	var people_left: float = elapsed_sec
	while people_left > 0.0001:
		var step: float = minf(1.0, people_left)
		roster.sim_clock += step
		_tick_baby_growth(roster, step, events, skip)
		_tick_pregnancies(claim, roster, step, events, clan_starving, skip, player_father_alive)
		_tick_new_conceptions(claim, roster, events, skip, player_father_alive)
		_tick_aging(roster, step, skip)
		people_left -= step

	_run_passive_production(claim, inventory, passive_state, elapsed_sec, events)
	_burn_wood(claim, inventory, passive_state, elapsed_sec, events)

	_feed_roster(inventory, roster, events, skip)
	_haul_asleep_specialty_huts(claim, inventory)
	_resolve_starvation(clan, roster, events, skip)

	claim.set_meta("settlement_passive_state", passive_state)
	return events


static func _get_passive_state(claim: Node) -> Dictionary:
	if claim.has_meta("settlement_passive_state"):
		var existing = claim.get_meta("settlement_passive_state")
		if existing is Dictionary:
			return (existing as Dictionary).duplicate()
	return {"cook": 0.0, "wood": 0.0, "rack": 0.0, "oven": 0.0}


static func _run_passive_production(
	claim: Node,
	inventory: InventoryData,
	passive_state: Dictionary,
	elapsed_sec: float,
	events: Dictionary
) -> void:
	var cook_interval: float = BalanceConfig.campfire_cooking_interval if BalanceConfig else 30.0
	passive_state["cook"] = float(passive_state.get("cook", 0.0)) + elapsed_sec
	passive_state["rack"] = float(passive_state.get("rack", 0.0)) + elapsed_sec
	passive_state["oven"] = float(passive_state.get("oven", 0.0)) + elapsed_sec

	var can_cook: bool = claim is Campfire or _claim_is_campfire_claim(claim)
	while can_cook and float(passive_state.get("cook", 0.0)) >= cook_interval:
		passive_state["cook"] = float(passive_state.get("cook", 0.0)) - cook_interval
		if inventory.get_count(ResourceData.ResourceType.MEAT) <= 0:
			break
		if not inventory.has_space() and inventory.get_count(ResourceData.ResourceType.COOKED_MEAT) >= inventory.max_stack:
			break
		inventory.remove_item(ResourceData.ResourceType.MEAT, 1)
		inventory.add_item(ResourceData.ResourceType.COOKED_MEAT, 1)
		events["produced"].append({
			"building_type": "campfire",
			"item_type": ResourceData.ResourceType.COOKED_MEAT,
			"count": 1,
		})

	_advance_asleep_specialty_huts(claim, elapsed_sec, events)


static func _haul_asleep_specialty_huts(claim: Node, inventory: InventoryData) -> void:
	if ClaimBuildingIndex == null or not (claim is LandClaim) or inventory == null:
		return
	for building in ClaimBuildingIndex.get_buildings_in_claim(claim):
		if building == null or not is_instance_valid(building):
			continue
		if int(building.get("building_type")) != int(ResourceData.ResourceType.LIVING_HUT):
			continue
		var kind := str(building.get("hut_specialty"))
		if not HutSpecialtyScript.is_known(kind):
			continue
		if HutSpecialtyScript.live_is_ticking(building) or _hut_carry_in_progress(claim, building):
			continue
		if building.inventory == null:
			continue
		var moved: Dictionary = HutCarryScript.apply_move(building.inventory, inventory, kind, _claim_reserved(claim))
		if int(moved.get("qty", 0)) > 0:
			HutSpecialtyScript.publish_stock(building)


static func _hut_carry_in_progress(claim: Node, building: Node) -> bool:
	var brain: Variant = claim.get("clan_brain")
	if brain == null:
		return false
	var rows: Variant = brain.get("work_requests")
	if not (rows is Array):
		return false
	for req in rows:
		if req is Dictionary and req.get("building") == building and str(req.get("state", "")) in ["CLAIMED", "IN_PROGRESS"]:
			return true
	return false


static func _claim_reserved(claim: Node) -> Dictionary:
	var out: Dictionary = {}
	if not claim.has_method("get_reserved_count"):
		return out
	for type in [ResourceData.ResourceType.GRAIN, ResourceData.ResourceType.WOOD, ResourceData.ResourceType.HIDE, ResourceData.ResourceType.FIBER, ResourceData.ResourceType.WOOL]:
		var held: int = int(claim.get_reserved_count(type))
		if held > 0:
			out[int(type)] = held
	return out


static func _advance_asleep_specialty_huts(claim: Node, elapsed_sec: float, events: Dictionary) -> void:
	if ClaimBuildingIndex == null or not (claim is LandClaim):
		return
	for building in ClaimBuildingIndex.get_buildings_in_claim(claim):
		if building == null or not is_instance_valid(building):
			continue
		if int(building.get("building_type")) != int(ResourceData.ResourceType.LIVING_HUT):
			continue
		if HutSpecialtyScript.advance_if_asleep(building, elapsed_sec):
			events["produced"].append({
				"building_type": "hut_specialty",
				"item_type": str(building.get("hut_specialty")),
				"count": 1,
			})


static func _burn_wood(
	claim: Node,
	inventory: InventoryData,
	passive_state: Dictionary,
	elapsed_sec: float,
	events: Dictionary
) -> void:
	if not (claim is Campfire):
		return
	var burn_interval: float = BalanceConfig.campfire_wood_burn_interval if BalanceConfig else 60.0
	passive_state["wood"] = float(passive_state.get("wood", 0.0)) + elapsed_sec
	while float(passive_state.get("wood", 0.0)) >= burn_interval:
		passive_state["wood"] = float(passive_state.get("wood", 0.0)) - burn_interval
		if inventory.get_count(ResourceData.ResourceType.WOOD) <= 0:
			break
		inventory.remove_item(ResourceData.ResourceType.WOOD, 1)
		events["burned_wood"] = int(events.get("burned_wood", 0)) + 1


static func _feed_roster(inventory: InventoryData, roster: RefCounted, events: Dictionary, skip_member_ids: Dictionary = {}) -> void:
	var fed_ids: Dictionary = {}
	for skip_id in skip_member_ids.keys():
		fed_ids[int(skip_id)] = true
	var leader: Dictionary = roster.get_leader()
	if not leader.is_empty():
		_try_feed_member(inventory, roster, leader, events, fed_ids)
	while true:
		var hungriest: Dictionary = roster.get_hungriest(fed_ids)
		if hungriest.is_empty():
			break
		if float(hungriest.get("hunger", 100.0)) >= 95.0:
			break
		var before_count := _total_food_count(inventory)
		if before_count <= 0:
			break
		if not _try_feed_member(inventory, roster, hungriest, events, fed_ids):
			break


static func _try_feed_member(
	inventory: InventoryData,
	roster: RefCounted,
	member: Dictionary,
	events: Dictionary,
	fed_ids: Dictionary
) -> bool:
	var member_id: int = int(member.get("id", -1))
	if member_id < 1:
		return false
	var food_type: ResourceData.ResourceType = _take_best_food(inventory)
	if food_type == ResourceData.ResourceType.NONE:
		return false
	var calories: int = BalanceConfig.get_food_calories(food_type) if BalanceConfig else 0
	if calories <= 0:
		return false
	var member_type: String = str(member.get("type", "clansman"))
	var hunger_gain: float = roster.feed_member(member_id, float(calories), member_type)
	fed_ids[member_id] = true
	events["fed"].append({
		"id": member_id,
		"type": member_type,
		"food": int(food_type),
		"calories": calories,
		"hunger_gain": hunger_gain,
	})
	return true


static func _take_best_food(inventory: InventoryData) -> ResourceData.ResourceType:
	for ft in FOOD_FEED_PRIORITY:
		if inventory.get_count(ft) > 0:
			inventory.remove_item(ft, 1)
			return ft
	return ResourceData.ResourceType.NONE


static func _resolve_starvation(_clan: String, roster: RefCounted, events: Dictionary, skip_member_ids: Dictionary = {}) -> void:
	var victim: Dictionary = roster.call("get_next_to_die", skip_member_ids) as Dictionary
	if victim.is_empty():
		return
	var killed: Dictionary = roster.call("kill_member", int(victim.get("id", -1))) as Dictionary
	if killed.is_empty():
		return
	events["died"].append({
		"id": int(killed.get("id", -1)),
		"type": str(killed.get("type", "?")),
		"name": str(killed.get("name", "?")),
	})


static func _total_food_count(inventory: InventoryData) -> int:
	var total := 0
	for ft in FOOD_FEED_PRIORITY:
		total += inventory.get_count(ft)
	return total


static func _claim_has_drying_rack(claim: Node) -> bool:
	if not ClaimBuildingIndex or not (claim is LandClaim):
		return false
	var buildings: Array = ClaimBuildingIndex.get_buildings_in_claim(claim)
	for b in buildings:
		if is_instance_valid(b) and b.building_type == ResourceData.ResourceType.DRYING_RACK:
			return true
	return false


static func _claim_has_oven(claim: Node) -> bool:
	if not ClaimBuildingIndex or not (claim is LandClaim):
		return false
	var buildings: Array = ClaimBuildingIndex.get_buildings_in_claim(claim)
	for b in buildings:
		if is_instance_valid(b) and b.building_type == ResourceData.ResourceType.OVEN:
			return true
	return false


static func _claim_is_campfire_claim(claim: Node) -> bool:
	return claim is Campfire


static func _tick_pregnancies(
	claim: Node,
	roster: RefCounted,
	elapsed_sec: float,
	events: Dictionary,
	clan_starving: bool,
	skip_member_ids: Dictionary = {},
	player_father_alive: bool = false
) -> void:
	if WorldGenConfig == null or not bool(WorldGenConfig.abstract_pregnancy_enabled):
		return
	var food_buffer: float = _claim_food_days_buffer(claim, roster)
	var cancel_threshold: float = _pregnancy_cancel_food_buffer_days()
	if clan_starving or food_buffer < cancel_threshold:
		for woman in roster.call("get_pregnant_women") as Array:
			if not (woman is Dictionary):
				continue
			var w: Dictionary = woman as Dictionary
			if skip_member_ids.has(int(w.get("id", 0))):
				continue
			var cancelled: Dictionary = roster.call("cancel_pregnancy", int(w.get("id", -1))) as Dictionary
			if cancelled.is_empty():
				continue
			events["pregnancies_cancelled"].append({
				"mother_id": int(cancelled.get("id", -1)),
				"mother_name": str(cancelled.get("name", "?")),
				"reason": "starvation" if clan_starving else "low_food_buffer",
			})
		return

	var now_sec: float = float(roster.sim_clock)
	var fallback_pos: Vector2 = claim.global_position if claim is Node2D else Vector2.ZERO
	var pregnant: Array = roster.call("get_pregnant_women") as Array
	for woman in pregnant:
		if not (woman is Dictionary):
			continue
		var w: Dictionary = woman as Dictionary
		if skip_member_ids.has(int(w.get("id", 0))):
			continue
		var timer: float = float(w.get("pregnancy_timer", 0.0)) - elapsed_sec
		w["pregnancy_timer"] = timer
		if timer > 0.0:
			continue
		w["pregnancy_timer"] = -1.0
		if not _has_baby_room_at_birth(claim, roster):
			events["births_blocked"].append({
				"mother_id": int(w.get("id", -1)),
				"mother_name": str(w.get("name", "?")),
				"reason": "baby_cap",
			})
			continue
		var father_id: int = int(w.get("designated_father_id", -1))
		if father_id < 1 or bool(w.get("father_is_player", false)):
			father_id = _pick_father_id(roster, w, events, player_father_alive)
		var baby_salt: int = int(w.get("id", 0)) ^ int(roster.members.size()) ^ int(now_sec * 1000.0)
		var baby_name: String = str(roster.call("generate_baby_name", baby_salt))
		var baby: Dictionary = roster.call(
			"add_baby_member",
			int(w.get("id", -1)),
			father_id,
			baby_name,
			fallback_pos
		) as Dictionary
		w["last_birth_time"] = now_sec
		events["births"].append({
			"mother_id": int(w.get("id", -1)),
			"mother_name": str(w.get("name", "?")),
			"baby_id": int(baby.get("id", -1)),
			"baby_name": baby_name,
			"father_id": father_id,
			"father_name": roster.call("get_member_name", father_id),
		})


static func _tick_new_conceptions(
	claim: Node,
	roster: RefCounted,
	events: Dictionary,
	skip_member_ids: Dictionary = {},
	player_father_alive: bool = false
) -> void:
	if WorldGenConfig == null or not bool(WorldGenConfig.abstract_pregnancy_enabled):
		return
	if not _claim_has_living_hut(claim):
		return
	if not _has_baby_room_for_conception(claim, roster):
		return
	var food_buffer: float = _claim_food_days_buffer(claim, roster)
	var min_buffer: float = _reproduction_min_food_buffer_days()
	if food_buffer < min_buffer and not _food_bypass_for_conception(claim, roster, min_buffer):
		return
	var birth_cooldown: float = BalanceConfig.birth_cooldown_seconds if BalanceConfig else 10.0
	var pregnancy_seconds: float = BalanceConfig.pregnancy_seconds if BalanceConfig else 15.0
	var now_sec: float = float(roster.sim_clock)
	var fertile: Array = roster.call("get_fertile_women", now_sec, birth_cooldown) as Array
	for woman in fertile:
		if not (woman is Dictionary):
			continue
		var w: Dictionary = woman as Dictionary
		if skip_member_ids.has(int(w.get("id", 0))):
			continue
		var father_id: int = _pick_father_id(roster, w, events, player_father_alive)
		if father_id < 1:
			continue
		if not bool(roster.call("start_pregnancy", int(w.get("id", -1)), father_id, pregnancy_seconds, now_sec)):
			continue
		events["pregnancies_started"].append({
			"mother_id": int(w.get("id", -1)),
			"mother_name": str(w.get("name", "?")),
			"father_id": father_id,
			"father_name": roster.call("get_member_name", father_id),
		})


static func _tick_baby_growth(roster: RefCounted, elapsed_sec: float, events: Dictionary, skip_member_ids: Dictionary = {}) -> void:
	if WorldGenConfig == null or not bool(WorldGenConfig.abstract_baby_growth_enabled):
		return
	var growth_time: float = BalanceConfig.baby_growth_seconds if BalanceConfig else 17.5
	for baby in roster.call("get_babies") as Array:
		if not (baby is Dictionary):
			continue
		var b: Dictionary = baby as Dictionary
		if skip_member_ids.has(int(b.get("id", 0))):
			continue
		var gt: float = float(b.get("growth_timer", 0.0))
		if gt < 0.0:
			gt = 0.0
		gt += elapsed_sec
		b["growth_timer"] = gt
		if growth_time > 0.0:
			b["age"] = int((gt / growth_time) * 13.0)
		if gt < growth_time:
			continue
		var grown: Dictionary = roster.call("promote_baby_to_clansman", int(b.get("id", -1))) as Dictionary
		if grown.is_empty():
			continue
		events["grew_up"].append({
			"id": int(grown.get("id", -1)),
			"name": str(grown.get("name", "?")),
		})


static func _tick_aging(roster: RefCounted, elapsed_sec: float, skip_member_ids: Dictionary = {}) -> void:
	if WorldGenConfig == null or not bool(WorldGenConfig.abstract_aging_enabled):
		return
	var sim_day_sec: float = 600.0
	if BalanceConfig:
		sim_day_sec = maxf(BalanceConfig.sim_day_length_minutes * 60.0, 60.0)
	var growth_time: float = BalanceConfig.baby_growth_seconds if BalanceConfig else 17.5
	var sim_days: float = elapsed_sec / sim_day_sec
	for m in roster.members:
		if not bool(m.get("alive", false)):
			continue
		if str(m.get("type", "")) == "baby":
			continue
		if skip_member_ids.has(int(m.get("id", 0))):
			continue
		var age_years_per_sim_day: float = 13.0 / maxf(growth_time / sim_day_sec, 0.001)
		m["age"] = float(m.get("age", 13.0)) + sim_days * age_years_per_sim_day


static func _pick_father_id(roster: RefCounted, woman: Dictionary, events: Dictionary, player_father_alive: bool = false) -> int:
	if bool(woman.get("father_is_player", false)) and player_father_alive:
		var player_id: int = int(woman.get("designated_father_id", -1))
		if player_id < 1:
			player_id = SettlementRosterScript.PLAYER_FATHER_ID
			woman["designated_father_id"] = player_id
		woman["father_absent_ticks"] = 0
		return player_id
	var designated: int = int(woman.get("designated_father_id", -1))
	if designated > 0:
		var df: Dictionary = roster.find_member(designated)
		if not df.is_empty() and bool(df.get("alive", false)):
			woman["father_absent_ticks"] = 0
			return designated
		var absent_ticks: int = int(woman.get("father_absent_ticks", 0))
		if absent_ticks <= 0:
			woman["father_absent_ticks"] = 1
			return -1
	else:
		for male in roster.call("get_alive_males") as Array:
			if not (male is Dictionary):
				continue
			var mid: int = int((male as Dictionary).get("id", -1))
			if mid > 0:
				return mid
		return -1

	var males: Array = roster.call("get_alive_males") as Array
	if males.is_empty():
		return -1
	var new_father: Dictionary = males[0] as Dictionary
	if new_father.is_empty():
		return -1
	var new_id: int = int(new_father.get("id", -1))
	if new_id < 1:
		return -1

	var old_name: String = "absent"
	var reason: String = "father_absent"
	if designated > 0:
		var old_m: Dictionary = roster.find_member(designated)
		if not old_m.is_empty():
			old_name = str(old_m.get("name", "?"))
			if not bool(old_m.get("alive", false)):
				reason = "father_died"
		else:
			old_name = "absent"

	woman["designated_father_id"] = new_id
	woman["father_absent_ticks"] = 0
	if events.has("husband_reassigned"):
		(events["husband_reassigned"] as Array).append({
			"mother_id": int(woman.get("id", -1)),
			"mother_name": str(woman.get("name", "?")),
			"old_father_id": designated,
			"old_father_name": old_name,
			"new_father_id": new_id,
			"new_father_name": str(new_father.get("name", "?")),
			"reason": reason,
		})
	return new_id


static func _claim_food_days_buffer(claim: Node, roster: RefCounted) -> float:
	if claim == null:
		return 99.0
	return ClanFoodBufferScript.get_pantry_days(claim, roster, [])


static func _food_bypass_for_conception(claim: Node, roster: RefCounted, min_buffer: float) -> bool:
	if _claim_food_days_buffer(claim, roster) >= min_buffer:
		return true
	var bypass_min: int = 3
	if ClanBrainTuningConfig:
		bypass_min = maxi(1, int(ClanBrainTuningConfig.reproduction_food_items_bypass_min))
	elif BalanceConfig:
		bypass_min = maxi(1, int(BalanceConfig.reproduction_food_items_bypass_min))
	if not claim.get("inventory"):
		return false
	var inventory: InventoryData = claim.get("inventory") as InventoryData
	if inventory == null:
		return false
	return _total_food_count(inventory) >= bypass_min


static func _reproduction_min_food_buffer_days() -> float:
	if ClanBrainTuningConfig:
		return maxf(float(ClanBrainTuningConfig.reproduction_min_food_buffer_days), 0.0)
	if BalanceConfig:
		return maxf(float(BalanceConfig.reproduction_min_food_buffer_days), 0.0)
	return 0.28


static func _pregnancy_cancel_food_buffer_days() -> float:
	var cfg := ReproductionConfig.new()
	var min_buffer: float = cfg.pregnancy_cancel_food_buffer_days
	if ClanBrainTuningConfig:
		min_buffer = maxf(min_buffer, float(ClanBrainTuningConfig.reproduction_min_food_buffer_days))
	elif BalanceConfig:
		min_buffer = maxf(min_buffer, float(BalanceConfig.reproduction_min_food_buffer_days))
	return min_buffer


static func _baby_capacity(claim: Node, roster: RefCounted) -> int:
	var cfg := ReproductionConfig.new()
	var base_cap: int = cfg.baby_pool_base_capacity
	var hut_bonus: int = _living_hut_count(claim) * cfg.living_hut_capacity_bonus
	var fertility_bonus: int = 0
	for m in roster.members:
		if not bool(m.get("alive", false)):
			continue
		if str(m.get("type", "")) != "woman":
			continue
		var traits_val = m.get("traits", [])
		if traits_val is Array:
			for t in traits_val:
				if t is Dictionary and str((t as Dictionary).get("id", "")) == "baby_cap_bonus":
					fertility_bonus += 1
	return maxi(0, base_cap + hut_bonus + fertility_bonus)


static func _has_baby_room_at_birth(claim: Node, roster: RefCounted) -> bool:
	return int(roster.call("get_baby_count")) < _baby_capacity(claim, roster)


static func _has_baby_room_for_conception(claim: Node, roster: RefCounted) -> bool:
	return _has_baby_room_at_birth(claim, roster)


static func _living_hut_count(claim: Node) -> int:
	if not ClaimBuildingIndex or not (claim is LandClaim):
		return 0
	var count := 0
	for b in ClaimBuildingIndex.get_buildings_in_claim(claim):
		if is_instance_valid(b) and b.building_type == ResourceData.ResourceType.LIVING_HUT:
			count += 1
	return count


static func _claim_has_living_hut(claim: Node) -> bool:
	return _living_hut_count(claim) > 0
