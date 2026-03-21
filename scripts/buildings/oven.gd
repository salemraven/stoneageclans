extends "res://scripts/buildings/building_base.gd"

# Oven Building - Produces bread from wood and grain
# Requires 1 woman NPC to operate

var production_component: ProductionComponent = null

func _ready() -> void:
	# Set building type
	building_type = ResourceData.ResourceType.OVEN
	requires_woman = true  # Oven requires a woman to operate
	
	# Call parent _ready
	super._ready()
	
	# Create production component with bread recipe
	production_component = ProductionComponent.new(self, _get_bread_recipe())
	add_child(production_component)
	
	print("🔵 Oven._ready() completed - production component created")

func _get_bread_recipe() -> Dictionary:
	# Recipe: 1 Wood + 1 Grain → 1 Bread (60 seconds)
	return {
		"inputs": [
			{"type": ResourceData.ResourceType.WOOD, "quantity": 1},
			{"type": ResourceData.ResourceType.GRAIN, "quantity": 1}
		],
		"output": {"type": ResourceData.ResourceType.BREAD, "quantity": 1},
		"craft_time": BalanceConfig.bread_craft_time if BalanceConfig else 90.0,
		"requires_woman": true
	}

func _process(_delta: float) -> void:
	# Production component handles its own _process
	# This is just here for any oven-specific logic if needed
	pass
