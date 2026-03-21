extends Node
class_name BabyPoolManager

# Baby Pool Manager - Tracks baby pool capacity per clan
# Handles capacity calculation (base + Living Hut bonuses)

var baby_pools: Dictionary = {}  # {clan_name: {capacity: int, current: int}}
var config: ReproductionConfig = null

func _ready() -> void:
	# Load config
	config = ReproductionConfig.new()
	
	# Initialize baby pools for existing clans (if any)
	_initialize_existing_clans()

func _initialize_existing_clans() -> void:
	# Find all existing land claims and initialize their baby pools
	var claims = get_tree().get_nodes_in_group("land_claims")
	for claim in claims:
		var clan_name = claim.get("clan_name")
		if clan_name and clan_name != "":
			if not baby_pools.has(clan_name):
				baby_pools[clan_name] = {
					"capacity": get_capacity(clan_name),
					"current": 0
				}

func get_capacity(clan_name: String) -> int:
	# Calculate capacity: base (3) + (living_hut_count * 5)
	# For now, just return base until Living Huts are implemented
	if not config:
		config = ReproductionConfig.new()
	
	var base_capacity = config.baby_pool_base_capacity
	var living_hut_count = _get_living_hut_count(clan_name)
	var capacity = base_capacity + (living_hut_count * config.living_hut_capacity_bonus)
	
	# Update pool entry
	if not baby_pools.has(clan_name):
		baby_pools[clan_name] = {"capacity": capacity, "current": 0}
	else:
		baby_pools[clan_name]["capacity"] = capacity
	
	return capacity

func _get_living_hut_count(clan_name: String) -> int:
	# Count Living Huts for this clan
	var count: int = 0
	var all_buildings = get_tree().get_nodes_in_group("buildings")
	for building in all_buildings:
		if not is_instance_valid(building):
			continue
		if building.has("building_type") and building.has("clan_name"):
			if building.building_type == ResourceData.ResourceType.LIVING_HUT:
				if building.clan_name == clan_name:
					count += 1
	return count

func get_current_count(clan_name: String) -> int:
	# Count actual baby NPCs in clan
	if not baby_pools.has(clan_name):
		return 0
	
	# Count babies in clan
	var babies: Array = []
	var all_npcs = get_tree().get_nodes_in_group("npcs")
	for npc in all_npcs:
		if not is_instance_valid(npc):
			continue
		if npc.get("npc_type") == "baby" and npc.get("clan_name") == clan_name:
			babies.append(npc)
	
	baby_pools[clan_name]["current"] = babies.size()
	return babies.size()

func can_add_baby(clan_name: String) -> bool:
	# Baby cap disabled - always allow babies
	return true
	# Original code (disabled):
	# var capacity = get_capacity(clan_name)
	# var current = get_current_count(clan_name)
	# return current < capacity

func on_living_hut_built(clan_name: String) -> void:
	# Called when Living Hut is built for a clan
	# Recalculate capacity
	get_capacity(clan_name)

func on_living_hut_destroyed(clan_name: String) -> void:
	# Called when Living Hut is destroyed for a clan
	# Recalculate capacity
	get_capacity(clan_name)
