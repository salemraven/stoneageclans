extends Node

## Autoload: canonical list of production chains for ClanBrain allocation.

var _chains: Dictionary = {}


func _ready() -> void:
	_register_builtin_chains()


func _register_builtin_chains() -> void:
	var bread := ProductionChain.new()
	bread.chain_id = "bread"
	bread.display_name = "Bread"
	bread.building_type = ResourceData.ResourceType.OVEN
	bread.inputs = [
		{"type": ResourceData.ResourceType.WOOD, "quantity": 1},
		{"type": ResourceData.ResourceType.GRAIN, "quantity": 1},
	]
	bread.output = {"type": ResourceData.ResourceType.BREAD, "quantity": 1}
	bread.craft_time = BalanceConfig.bread_craft_time if BalanceConfig else 90.0
	bread.is_passive = false
	bread.priority_category = "human_food"
	bread.min_stage = 2
	register_chain(bread)

	var leather := ProductionChain.new()
	leather.chain_id = "leather"
	leather.display_name = "Leather"
	leather.building_type = ResourceData.ResourceType.DRYING_RACK
	leather.inputs = [
		{"type": ResourceData.ResourceType.HIDE, "quantity": 1},
	]
	leather.output = {"type": ResourceData.ResourceType.LEATHER, "quantity": 1}
	leather.craft_time = BalanceConfig.drying_rack_process_time if BalanceConfig else 120.0
	leather.is_passive = true
	leather.priority_category = "preservation"
	leather.min_stage = 2
	register_chain(leather)


func register_chain(chain: ProductionChain) -> void:
	if not chain or chain.chain_id.is_empty():
		return
	_chains[chain.chain_id] = chain


func get_chain(chain_id: String) -> ProductionChain:
	return _chains.get(chain_id, null) as ProductionChain


func get_all_chains() -> Array:
	return _chains.values()


func get_chains_for_building(building_type: ResourceData.ResourceType) -> Array:
	var result: Array = []
	for chain in _chains.values():
		if chain is ProductionChain and chain.building_type == building_type:
			result.append(chain)
	return result
