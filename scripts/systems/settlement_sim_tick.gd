class_name SettlementSimTick
extends RefCounted
## Warm-tier settlement simulation — food, passive buildings, starvation (Phase 2).

const SettlementRosterScript = preload("res://scripts/systems/settlement_roster.gd")

const FOOD_FEED_PRIORITY: Array = [
	ResourceData.ResourceType.COOKED_MEAT,
	ResourceData.ResourceType.BREAD,
	ResourceData.ResourceType.MEAT,
	ResourceData.ResourceType.GRAIN,
	ResourceData.ResourceType.BERRIES,
	ResourceData.ResourceType.MILK,
	ResourceData.ResourceType.MUSHROOM,
	ResourceData.ResourceType.NUTS,
	ResourceData.ResourceType.BUGS,
]


static func tick(claim: Node, roster: RefCounted, elapsed_sec: float) -> Dictionary:
	var events: Dictionary = {
		"fed": [],
		"died": [],
		"produced": [],
		"burned_wood": 0,
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

	_run_passive_production(claim, inventory, passive_state, elapsed_sec, events)
	_burn_wood(claim, inventory, passive_state, elapsed_sec, events)

	for m in roster.members:
		if bool(m.get("alive", false)):
			roster.drain_hunger(m, elapsed_sec)

	_feed_roster(inventory, roster, events)
	_resolve_starvation(clan, roster, events)

	claim.set_meta("settlement_passive_state", passive_state)
	return events


static func _get_passive_state(claim: Node) -> Dictionary:
	if claim.has_meta("settlement_passive_state"):
		var existing = claim.get_meta("settlement_passive_state")
		if existing is Dictionary:
			return (existing as Dictionary).duplicate()
	return {"cook": 0.0, "wood": 0.0, "rack": 0.0}


static func _run_passive_production(
	claim: Node,
	inventory: InventoryData,
	passive_state: Dictionary,
	elapsed_sec: float,
	events: Dictionary
) -> void:
	var cook_interval: float = BalanceConfig.campfire_cooking_interval if BalanceConfig else 30.0
	var rack_interval: float = BalanceConfig.drying_rack_process_time if BalanceConfig else 120.0
	passive_state["cook"] = float(passive_state.get("cook", 0.0)) + elapsed_sec
	passive_state["rack"] = float(passive_state.get("rack", 0.0)) + elapsed_sec

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

	if _claim_has_drying_rack(claim):
		while float(passive_state.get("rack", 0.0)) >= rack_interval:
			passive_state["rack"] = float(passive_state.get("rack", 0.0)) - rack_interval
			if not _process_one_drying_rack(claim, events):
				break


static func _process_one_drying_rack(claim: Node, events: Dictionary) -> bool:
	if not ClaimBuildingIndex or not (claim is LandClaim):
		return false
	var buildings: Array = ClaimBuildingIndex.get_buildings_in_claim(claim)
	for b in buildings:
		if not is_instance_valid(b):
			continue
		if b.building_type != ResourceData.ResourceType.DRYING_RACK:
			continue
		if not b.inventory:
			continue
		if b.inventory.get_count(ResourceData.ResourceType.HIDE) <= 0:
			continue
		if not b.inventory.has_space():
			if b.inventory.get_count(ResourceData.ResourceType.LEATHER) >= b.inventory.max_stack:
				continue
		b.inventory.remove_item(ResourceData.ResourceType.HIDE, 1)
		b.inventory.add_item(ResourceData.ResourceType.LEATHER, 1)
		events["produced"].append({
			"building_type": "drying_rack",
			"item_type": ResourceData.ResourceType.LEATHER,
			"count": 1,
		})
		return true
	return false


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


static func _feed_roster(inventory: InventoryData, roster: RefCounted, events: Dictionary) -> void:
	var fed_ids: Dictionary = {}
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


static func _resolve_starvation(_clan: String, roster: RefCounted, events: Dictionary) -> void:
	var victim: Dictionary = roster.call("get_next_to_die") as Dictionary
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


static func _claim_is_campfire_claim(claim: Node) -> bool:
	return claim is Campfire
