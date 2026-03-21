extends Resource
class_name ProductionConfig

# Configuration for production/crafting systems
# Used by production buildings (Oven, Farm, Dairy, Armory, etc.)

@export var default_craft_time: float = 60.0  # Base crafting time in seconds
@export var occupation_range: float = 500.0  # Auto-assignment range for women to find buildings
@export var max_stack_size: int = 999  # Max items per stack (unlimited for buildings)

# Oven slot counts and recipe
var oven_woman_slots: int = 1
var oven_animal_slots: int = 0

# Farm slot counts and recipe
var farm_woman_slots: int = 2
var farm_sheep_slots: int = 3

# Dairy slot counts and recipe
var dairy_woman_slots: int = 2
var dairy_goat_slots: int = 3

# Recipes (craft time in seconds)
static func get_oven_recipe() -> Dictionary:
	return {
		"inputs": [
			{"type": ResourceData.ResourceType.WOOD, "quantity": 1},
			{"type": ResourceData.ResourceType.GRAIN, "quantity": 1}
		],
		"output": {"type": ResourceData.ResourceType.BREAD, "quantity": 1},
		"craft_time": 15.0,
		"requires_woman": true
	}

static func get_farm_recipe() -> Dictionary:
	var ct: float = BalanceConfig.wool_craft_time if BalanceConfig else 45.0
	return {
		"inputs": [
			{"type": ResourceData.ResourceType.FIBER, "quantity": 1}
		],
		"output": {"type": ResourceData.ResourceType.WOOL, "quantity": 1},
		"craft_time": ct,
		"requires_woman": true
	}

static func get_dairy_recipe() -> Dictionary:
	var ct: float = BalanceConfig.milk_craft_time if BalanceConfig else 45.0
	return {
		"inputs": [
			{"type": ResourceData.ResourceType.FIBER, "quantity": 1}
		],
		"output": {"type": ResourceData.ResourceType.MILK, "quantity": 1},
		"craft_time": ct,
		"requires_woman": true
	}
