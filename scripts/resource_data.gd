extends RefCounted
class_name ResourceData

enum ResourceType {
	NONE,
	WOOD,
	STONE,
	BERRIES,
	WHEAT,
	GRAIN,
	FIBER,
	MEAT,
	AXE,
	PICK,
	LANDCLAIM,
	LIVING_HUT,
	SUPPLY_HUT,
	SHRINE,
	DAIRY_FARM,
	FARM,
	OVEN,
	BREAD,
	WOOL,
	MILK,
	BLADE,
	OLDOWAN,
	CORDAGE,
	CAMPFIRE,
	HIDE,
	BONE,
	TRAVOIS
}

static func get_resource_name(type: ResourceType) -> String:
	match type:
		ResourceType.WOOD: return "Wood"
		ResourceType.STONE: return "Stone"
		ResourceType.BERRIES: return "Berries"
		ResourceType.WHEAT: return "Wheat"
		ResourceType.GRAIN: return "Grain"
		ResourceType.FIBER: return "Fiber"
		ResourceType.AXE: return "Axe"
		ResourceType.PICK: return "Pick"
		ResourceType.LANDCLAIM: return "Land Claim"
		ResourceType.LIVING_HUT: return "Living Hut"
		ResourceType.SUPPLY_HUT: return "Supply Hut"
		ResourceType.SHRINE: return "Shrine"
		ResourceType.DAIRY_FARM: return "Dairy Farm"
		ResourceType.FARM: return "Farm"
		ResourceType.OVEN: return "Oven"
		ResourceType.BREAD: return "Bread"
		ResourceType.WOOL: return "Wool"
		ResourceType.MILK: return "Milk"
		ResourceType.BLADE: return "Blade"
		ResourceType.MEAT: return "Meat"
		ResourceType.OLDOWAN: return "Oldowan"
		ResourceType.CORDAGE: return "Cordage"
		ResourceType.CAMPFIRE: return "Campfire"
		ResourceType.HIDE: return "Hide"
		ResourceType.BONE: return "Bone"
		ResourceType.TRAVOIS: return "Travois"
		_: return "Unknown"

static func get_resource_color(type: ResourceType) -> Color:
	match type:
		ResourceType.WOOD: return Color(0.4, 0.25, 0.15) # Brown
		ResourceType.STONE: return Color(0.5, 0.5, 0.5) # Gray
		ResourceType.BERRIES: return Color(0.2, 0.6, 0.2) # Green
		ResourceType.WHEAT: return Color(0.9, 0.8, 0.3) # Yellow
		ResourceType.GRAIN: return Color(0.95, 0.85, 0.4) # Light yellow/gold
		ResourceType.BREAD: return Color(0.8, 0.65, 0.4) # Golden brown for bread
		ResourceType.WOOL: return Color(0.95, 0.95, 0.9) # Off-white for wool
		ResourceType.MILK: return Color(1.0, 1.0, 0.98) # Milk white
		ResourceType.FIBER: return Color(0.7, 0.5, 0.3) # Tan/brown for fiber
		ResourceType.AXE: return Color(0.3, 0.2, 0.15) # Dark brown for axe
		ResourceType.PICK: return Color(0.4, 0.4, 0.4) # Gray for pick
		ResourceType.BLADE: return Color(0.6, 0.55, 0.5) # Stone gray for blade
		ResourceType.MEAT: return Color(0.8, 0.35, 0.25) # Red-brown for meat
		ResourceType.OLDOWAN: return Color(0.55, 0.5, 0.45) # Stone gray for oldowan
		ResourceType.CORDAGE: return Color(0.6, 0.45, 0.3) # Tan for cordage
		ResourceType.CAMPFIRE: return Color(0.9, 0.4, 0.1) # Orange for campfire
		ResourceType.HIDE: return Color(0.7, 0.55, 0.4) # Leather brown for hide
		ResourceType.BONE: return Color(0.95, 0.92, 0.85) # Off-white for bone
		ResourceType.TRAVOIS: return Color(0.5, 0.4, 0.3) # Brown for travois
		_: return Color.WHITE

static func get_resource_icon_path(type: ResourceType) -> String:
	match type:
		ResourceType.WOOD: return "res://assets/sprites/wood.png"
		ResourceType.STONE: return "res://assets/sprites/stone.png"
		ResourceType.BERRIES: return "res://assets/sprites/berries.png"
		ResourceType.WHEAT: return "res://assets/sprites/wheat.png"
		ResourceType.GRAIN: return "res://assets/sprites/grain.png"
		ResourceType.FIBER: return "res://assets/sprites/fiber.png"
		ResourceType.AXE: return "res://assets/sprites/axe.png"
		ResourceType.PICK: return "res://assets/sprites/pick.png"
		ResourceType.BLADE: return "res://assets/sprites/blade.png"
		ResourceType.LANDCLAIM: return "res://assets/sprites/landclaim.png"
		ResourceType.LIVING_HUT: return "res://assets/sprites/hut.png"
		ResourceType.SUPPLY_HUT: return "res://assets/sprites/supply.png"
		ResourceType.SHRINE: return "res://assets/sprites/shrine.png"
		ResourceType.DAIRY_FARM: return "res://assets/sprites/dairy.png"
		ResourceType.FARM: return "res://assets/sprites/farm1.png"
		ResourceType.OVEN: return "res://assets/sprites/oven.png"
		ResourceType.BREAD: return "res://assets/sprites/bread.png"
		ResourceType.WOOL: return "res://assets/sprites/wool.png"
		ResourceType.MILK: return "res://assets/sprites/milk.png"
		ResourceType.MEAT: return "res://assets/sprites/meat.png"
		ResourceType.OLDOWAN: return "res://assets/sprites/oldowan.png"
		ResourceType.CORDAGE: return "res://assets/sprites/cordage.png"
		ResourceType.CAMPFIRE: return "res://assets/sprites/campfire.png"
		ResourceType.HIDE: return "res://assets/sprites/hide.png"
		ResourceType.BONE: return "res://assets/sprites/bone.png"
		ResourceType.TRAVOIS: return "res://assets/sprites/travois.png"
		_: return ""

static func is_equipment(type: ResourceType) -> bool:
	return type == ResourceType.AXE or type == ResourceType.PICK or type == ResourceType.WOOD or type == ResourceType.BLADE or type == ResourceType.OLDOWAN or type == ResourceType.TRAVOIS

static func get_resource_tier(_type: ResourceType) -> int:
	# All basic resources are tier 0 (grey border)
	match _type:
		ResourceType.AXE: return 1
		ResourceType.PICK: return 1
		ResourceType.LANDCLAIM: return 1
		ResourceType.LIVING_HUT: return 1
		ResourceType.SUPPLY_HUT: return 1
		ResourceType.SHRINE: return 1
		ResourceType.DAIRY_FARM: return 1
		ResourceType.FARM: return 1
		ResourceType.OVEN: return 1
		ResourceType.BREAD: return 1
		ResourceType.WOOL: return 1
		ResourceType.MILK: return 1
		ResourceType.BLADE: return 1
		ResourceType.MEAT: return 1
		ResourceType.OLDOWAN: return 1
		ResourceType.CORDAGE: return 1
		ResourceType.CAMPFIRE: return 1
		ResourceType.HIDE: return 0
		ResourceType.BONE: return 0
		ResourceType.TRAVOIS: return 1
		_: return 0

static func get_tier_border_color(tier: int) -> Color:
	match tier:
		0: return Color(0.6, 0.6, 0.6) # Grey
		1: return Color(0.9, 0.9, 0.9) # White
		2: return Color(0.6, 0.8, 1.0) # Light blue
		3: return Color(0.8, 0.6, 1.0) # Purple
		_: return Color(0.6, 0.6, 0.6)

static func get_resource_description(type: ResourceType) -> String:
	match type:
		ResourceType.AXE: return "Tool for wood. Basic weapon."
		ResourceType.LANDCLAIM: return "Place to start a clan."
		ResourceType.BERRIES: return "Consumable"
		ResourceType.WOOD: return "Resource. Equip in slot 1 to use as club."
		ResourceType.STONE: return "Resource"
		ResourceType.GRAIN: return "Consumable"
		ResourceType.FIBER: return "Resource"
		ResourceType.PICK: return "Tool for stone."
		ResourceType.WHEAT: return "Resource"
		ResourceType.LIVING_HUT: return "Provides +5 Baby Pool."
		ResourceType.SUPPLY_HUT: return "Provides extra storage."
		ResourceType.SHRINE: return "A place of worship."
		ResourceType.DAIRY_FARM: return "Fiber to milk. Requires goats and women."
		ResourceType.FARM: return "Fiber to wool. Requires sheep and women."
		ResourceType.OVEN: return "Produces bread from wood and grain. Requires 1 woman."
		ResourceType.BREAD: return "Best food in the game. Made from wood and grain."
		ResourceType.WOOL: return "From sheep at farm. Used for cloth."
		ResourceType.MILK: return "From goats at dairy. Used for cheese and butter."
		ResourceType.BLADE: return "Stone blade. Gather meat from corpses. Crafted by knapping stones."
		ResourceType.MEAT: return "Consumable from animals. Gather with blade from corpses."
		ResourceType.OLDOWAN: return "Crude hand axe. Gather wood, stone, meat, hide. Crafted from 2 stone."
		ResourceType.CORDAGE: return "Twisted fiber rope. Used for land claim. Crafted from 3 fiber."
		ResourceType.CAMPFIRE: return "Place to cook and upgrade to land claim. Crafted from 2 wood, 2 stone."
		ResourceType.HIDE: return "Animal hide from corpses. Used for land claim."
		ResourceType.BONE: return "Bone from corpses. Used for future crafts."
		ResourceType.TRAVOIS: return "Portable storage. 2 wood + 2 cordage. 2-handed."
		_: return ""

# Get nutrient value for food items (higher = better)
# NPCs prefer higher nutrient foods when maintaining inventory
# Nutrition values:
#   Berries = 5 points (least)
#   Grain = 7 points (medium)
#   Meat = 10 points (highest) - when implemented
# Note: FIBER is NOT a food item - it's a crafting resource
static func get_food_nutrient_value(type: ResourceType) -> int:
	match type:
		ResourceType.BERRIES: return 5
		ResourceType.GRAIN: return 7
		ResourceType.MEAT: return 10
		ResourceType.BREAD: return 15
		ResourceType.MILK: return 6  # Milk consumable for humans
		_: return 0

# Get hunger restoration amount for food items (as percentage of max hunger)
static func get_food_hunger_restore_percent(type: ResourceType) -> float:
	match type:
		ResourceType.BERRIES: return 5.0
		ResourceType.GRAIN: return 7.0
		ResourceType.MEAT: return 10.0
		ResourceType.BREAD: return 15.0
		ResourceType.MILK: return 6.0  # Milk consumable for humans
		_: return 0.0

# Check if a resource type is edible food
static func is_food(type: ResourceType) -> bool:
	return type == ResourceType.BERRIES or type == ResourceType.GRAIN or type == ResourceType.BREAD or type == ResourceType.MEAT or type == ResourceType.MILK
	# Note: GRAIN comes from harvesting WHEAT, but GRAIN is the food item stored in inventory
	# FIBER is NOT a consumable - it's a resource used for crafting
