extends Resource
class_name ProductionChain

## Data-driven production chain definition for ClanBrain-directed economy.

@export var chain_id: String = ""
@export var display_name: String = ""
@export var building_type: ResourceData.ResourceType = ResourceData.ResourceType.OVEN

@export var inputs: Array[Dictionary] = []
@export var output: Dictionary = {}
@export var craft_time: float = 60.0

@export var is_passive: bool = false
@export var priority_category: String = "preservation"
@export var min_stage: int = 2


func get_input_types() -> Array[int]:
	var types: Array[int] = []
	for inp in inputs:
		if inp.has("type"):
			types.append(int(inp["type"]))
	return types


func get_total_input_quantity() -> int:
	var total := 0
	for inp in inputs:
		total += int(inp.get("quantity", 1))
	return total


func get_output_type() -> ResourceData.ResourceType:
	return output.get("type", ResourceData.ResourceType.NONE) as ResourceData.ResourceType


func get_output_quantity() -> int:
	return int(output.get("quantity", 1))
