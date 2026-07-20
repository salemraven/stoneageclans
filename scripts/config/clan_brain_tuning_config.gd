extends Node
## Live-tunable ClanBrain / economy knobs for dev balancing.
## Gameplay reads this autoload; defaults mirror BalanceConfig / NPCConfig.
## Do not hardcode balance in ClanBrain — read via get_* helpers here.

signal tuning_changed(property: StringName)

# --- Workforce mode thresholds (drive GROWTH / BALANCED / STARVING) ---
var food_buffer_target_days: float = 1.0
var food_buffer_critical_days: float = 0.5
## When STARVING: max share of fighters allowed in herd_wildnpc (searcher quota cap).
var starving_max_searcher_fraction: float = 0.34
## When STARVING: max active herders cap = ceil(n * this).
var starving_max_herder_fraction: float = 0.25
## When BALANCED (below target, above critical): searcher cap fraction.
var balanced_max_searcher_fraction: float = 0.67

# --- Hunt parties ---
var hunt_party_min_size: int = 2
var hunt_party_max_size: int = 8
var hunt_party_fighter_fraction: float = 0.55
var hunt_cooldown_sec: float = 45.0
var hunt_cooldown_hungry_sec: float = 20.0
## Solo 1-fighter hunt when food buffer critical (early caveman + deer in AoH).
var hunt_allow_solo_when_food_critical: bool = true
var hunt_solo_food_buffer_days: float = 0.15

# --- Defenders / stock gates ---
var defender_slots_per_fighters: int = 4
var min_food_items_for_defend: int = 10
var min_stone_for_defend: int = 10
var min_wood_for_defend: int = 10

# --- Reproduction (gates only; bypass is system behavior) ---
var reproduction_min_food_buffer_days: float = 0.28
var reproduction_food_items_bypass_min: int = 3

# --- Milestones (system switches) ---
## When true and workforce_mode == STARVING, skip Farm/Dairy/Living Hut queue (Oven/Rack only).
var food_critical_block_luxury_milestones: bool = true

# --- FSM bias when STARVING (gather beats far-target herd search) ---
var starving_gather_priority_boost: float = 0.4


func _ready() -> void:
	sync_defaults_from_balance_config()


func sync_defaults_from_balance_config() -> void:
	if not BalanceConfig:
		return
	food_buffer_target_days = float(BalanceConfig.clan_food_buffer_target_days)
	food_buffer_critical_days = float(BalanceConfig.clan_food_buffer_critical_days)
	reproduction_min_food_buffer_days = float(BalanceConfig.reproduction_min_food_buffer_days)
	reproduction_food_items_bypass_min = int(BalanceConfig.reproduction_food_items_bypass_min)
	min_food_items_for_defend = 10
	if NPCConfig:
		hunt_party_min_size = int(NPCConfig.hunt_party_min_size)
		hunt_party_max_size = int(NPCConfig.hunt_party_max_size)
		if "hunt_party_fighter_fraction" in NPCConfig:
			hunt_party_fighter_fraction = float(NPCConfig.hunt_party_fighter_fraction)
		hunt_cooldown_hungry_sec = float(NPCConfig.hunt_cooldown_hungry_sec)
	hunt_allow_solo_when_food_critical = bool(BalanceConfig.hunt_allow_solo_when_food_critical)
	hunt_solo_food_buffer_days = float(BalanceConfig.hunt_solo_food_buffer_days)


func set_tuned(property: StringName, value: Variant) -> void:
	var known: bool = false
	for entry in get_editable_fields():
		if entry.get("prop", "") == str(property):
			known = true
			break
	if not known:
		push_warning("ClanBrainTuningConfig: unknown property %s" % str(property))
		return
	set(property, value)
	tuning_changed.emit(property)


func get_food_buffer_target_days() -> float:
	return maxf(food_buffer_target_days, 0.05)


func get_food_buffer_critical_days() -> float:
	return maxf(food_buffer_critical_days, 0.01)


func get_hunt_party_min_size() -> int:
	return maxi(hunt_party_min_size, 1)


func get_hunt_party_max_size() -> int:
	return maxi(hunt_party_max_size, get_hunt_party_min_size())


func get_hunt_party_fighter_fraction() -> float:
	return clampf(hunt_party_fighter_fraction, 0.1, 1.0)


func get_hunt_cooldown_hungry_sec() -> float:
	return maxf(hunt_cooldown_hungry_sec, 5.0)


func get_hunt_allow_solo_when_food_critical() -> bool:
	return hunt_allow_solo_when_food_critical


func get_hunt_solo_food_buffer_days() -> float:
	return maxf(hunt_solo_food_buffer_days, 0.05)


## Schema for DevBalanceMenu code generation (label, property, type, min, max, step).
func get_editable_fields() -> Array[Dictionary]:
	return [
		{"section": "Workforce"},
		{"label": "Food target (sim-days)", "prop": "food_buffer_target_days", "type": "float", "min": 0.1, "max": 5.0, "step": 0.05},
		{"label": "Food critical (sim-days)", "prop": "food_buffer_critical_days", "type": "float", "min": 0.05, "max": 2.0, "step": 0.05},
		{"label": "Starving max searchers (fraction)", "prop": "starving_max_searcher_fraction", "type": "float", "min": 0.05, "max": 1.0, "step": 0.05},
		{"label": "Starving max herders (fraction)", "prop": "starving_max_herder_fraction", "type": "float", "min": 0.05, "max": 1.0, "step": 0.05},
		{"label": "Balanced max searchers (fraction)", "prop": "balanced_max_searcher_fraction", "type": "float", "min": 0.1, "max": 1.0, "step": 0.05},
		{"section": "Hunt"},
		{"label": "Party min size", "prop": "hunt_party_min_size", "type": "int", "min": 1, "max": 8, "step": 1},
		{"label": "Party max size", "prop": "hunt_party_max_size", "type": "int", "min": 2, "max": 16, "step": 1},
		{"label": "Party size (% fighters)", "prop": "hunt_party_fighter_fraction", "type": "float", "min": 0.2, "max": 1.0, "step": 0.05},
		{"label": "Hunt cooldown (sec)", "prop": "hunt_cooldown_sec", "type": "float", "min": 5.0, "max": 120.0, "step": 5.0},
		{"label": "Hunt cooldown hungry (sec)", "prop": "hunt_cooldown_hungry_sec", "type": "float", "min": 5.0, "max": 90.0, "step": 5.0},
		{"label": "Allow solo hunt (food critical)", "prop": "hunt_allow_solo_when_food_critical", "type": "bool"},
		{"label": "Solo hunt food buffer max (days)", "prop": "hunt_solo_food_buffer_days", "type": "float", "min": 0.05, "max": 1.0, "step": 0.05},
		{"section": "Defend / stock"},
		{"label": "Defenders per N fighters (n/N)", "prop": "defender_slots_per_fighters", "type": "int", "min": 2, "max": 10, "step": 1},
		{"label": "Min food items to defend", "prop": "min_food_items_for_defend", "type": "int", "min": 0, "max": 50, "step": 1},
		{"section": "Reproduction"},
		{"label": "Min food buffer to breed", "prop": "reproduction_min_food_buffer_days", "type": "float", "min": 0.0, "max": 2.0, "step": 0.05},
		{"label": "Food items bypass min", "prop": "reproduction_food_items_bypass_min", "type": "int", "min": 0, "max": 20, "step": 1},
		{"section": "Systems"},
		{"label": "Block luxury milestones when starving", "prop": "food_critical_block_luxury_milestones", "type": "bool"},
		{"label": "Gather priority boost (starving)", "prop": "starving_gather_priority_boost", "type": "float", "min": 0.0, "max": 2.0, "step": 0.1},
	]
