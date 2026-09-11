class_name ClanFoodBuffer
extends RefCounted
## Single source of truth for clan pantry "days of food" (RimWorld/ONI style).
## pantry_days = calories_in_claim_storage / daily_calorie_need_of_roster
## Personal NPC hunger still uses calories per bite — this is the claim-level gate only.

const SettlementRosterScript = preload("res://scripts/systems/settlement_roster.gd")


static func count_edible_items(inventory: InventoryData) -> int:
	if inventory == null or not inventory.has_method("get_count"):
		return 0
	var total := 0
	for food_type in ResourceData.EDIBLE_FOOD_TYPES:
		total += inventory.get_count(food_type)
	return total


static func calories_in_storage(inventory: InventoryData) -> int:
	if inventory == null or not inventory.has_method("get_count"):
		return 0
	var total := 0
	for food_type in ResourceData.EDIBLE_FOOD_TYPES:
		var count: int = inventory.get_count(food_type)
		if count > 0:
			total += ResourceData.get_food_calories(food_type) * count
	return total


static func pantry_days_from_calories(calories_stored: int, daily_need: int) -> float:
	if daily_need <= 0:
		return 99.0
	return float(calories_stored) / float(daily_need)


static func daily_need_from_roster(roster: RefCounted) -> int:
	if roster == null:
		return 0
	var total := 0
	for m in roster.get("members"):
		if not (m is Dictionary):
			continue
		var member: Dictionary = m as Dictionary
		if not bool(member.get("alive", false)):
			continue
		var member_type: String = str(member.get("type", "clansman"))
		total += _daily_calories_for_member_type(member_type)
	return total


static func daily_need_from_live_members(members: Array, claim: Node = null) -> int:
	var total := 0
	for member in members:
		if member == null or not is_instance_valid(member):
			continue
		if member.has_method("is_dead") and member.is_dead():
			continue
		if member.get("stats_component") != null:
			var stats: Stats = member.stats_component
			if stats and stats.has_method("get_daily_calorie_need"):
				total += int(stats.get_daily_calorie_need())
				continue
		var nt: String = str(member.get("npc_type")) if member.get("npc_type") != null else ""
		if nt.is_empty():
			nt = str(member.get("type")) if member.get("type") != null else "clansman"
		total += _daily_calories_for_npc_type(nt)
	if claim and claim.get("player_owned") == true:
		var tree: SceneTree = claim.get_tree() if claim.is_inside_tree() else null
		if tree:
			var player: Node = tree.get_first_node_in_group("player")
			if player and is_instance_valid(player):
				if player.has_method("get_daily_calorie_need"):
					total += int(player.get_daily_calorie_need())
				elif BalanceConfig:
					total += BalanceConfig.get_base_daily_calories("player")
	return total


static func daily_need_for_population(population: int, default_npc_type: String = "caveman") -> int:
	if population <= 0:
		return 0
	var per_capita: int = _daily_calories_for_npc_type(default_npc_type)
	return population * per_capita


static func compute(
	claim: Node,
	roster: RefCounted = null,
	live_members: Array = []
) -> Dictionary:
	var inventory: InventoryData = null
	if claim != null and claim.get("inventory") != null:
		inventory = claim.get("inventory") as InventoryData
	var stored: int = calories_in_storage(inventory)
	var food_total: int = count_edible_items(inventory)
	var daily: int = 0
	if not live_members.is_empty():
		daily = daily_need_from_live_members(live_members, claim)
	elif roster != null:
		daily = daily_need_from_roster(roster)
	else:
		if claim != null and claim.has_meta("calories_daily_need"):
			daily = int(claim.get_meta("calories_daily_need"))
		if daily <= 0:
			var pop: int = 1
			if claim != null and claim.has_meta("settlement_roster_pop"):
				pop = maxi(1, int(claim.get_meta("settlement_roster_pop")))
			daily = daily_need_for_population(pop)
	var days: float = pantry_days_from_calories(stored, daily)
	return {
		"pantry_days": days,
		"food_days_buffer": days,
		"calories_days_buffer": days,
		"calories_in_storage": stored,
		"calories_daily_need": daily,
		"food_total": food_total,
	}


static func get_pantry_days(
	claim: Node,
	roster: RefCounted = null,
	live_members: Array = []
) -> float:
	return float(compute(claim, roster, live_members).get("pantry_days", 99.0))


static func publish_to_claim(claim: Node, metrics: Dictionary) -> void:
	if claim == null:
		return
	var days: float = float(metrics.get("pantry_days", metrics.get("food_days_buffer", 0.0)))
	claim.set_meta("food_days_buffer", days)
	claim.set_meta("calories_days_buffer", days)
	claim.set_meta("calories_in_storage", int(metrics.get("calories_in_storage", 0)))
	claim.set_meta("calories_daily_need", int(metrics.get("calories_daily_need", 0)))


static func _daily_calories_for_member_type(member_type: String) -> int:
	match member_type:
		"leader":
			return _daily_calories_for_npc_type("caveman")
		"player":
			return _daily_calories_for_npc_type("player")
		_:
			return _daily_calories_for_npc_type(member_type)


static func _daily_calories_for_npc_type(npc_type: String) -> int:
	if BalanceConfig:
		return BalanceConfig.get_base_daily_calories(npc_type)
	match npc_type:
		"woman":
			return 1800
		"baby":
			return 720
		"player":
			return 2000
		_:
			return 2200
