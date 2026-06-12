extends Node
class_name Stats

# Stats component for NPCs
# Calories are the food meter; hunger/hunger_max stay as 0-100% display for legacy AI/UI.

var npc: Node = null

@export var health_max: float = 100.0
@export var health: float = 100.0
@export var hunger_max: float = 100.0
@export var hunger: float = 100.0
@export var calories: float = 1000.0
@export var calories_max: float = 2000.0
@export var strength: float = 10.0
@export var stamina_max: float = 100.0
@export var stamina: float = 100.0
@export var agility: float = 10.0
@export var endurance: float = 10.0
@export var perception: float = 10.0
@export var intelligence: float = 10.0
@export var social: float = 10.0
@export var pain_tolerance: float = 10.0
@export var fertility: float = 50.0
@export var carry_capacity: float = 10.0
@export var morale: float = 100.0
@export var aggression: float = 10.0

@export var hunger_deplete_rate: float = 1.0
@export var stamina_deplete_rate: float = 5.0
@export var stamina_regen_rate: float = 10.0

var diet_type: ResourceData.DietType = ResourceData.DietType.OMNIVORE
var _cached_daily_need: float = 2000.0
var _uses_calorie_sim: bool = false
var _sim_tick_connected: bool = false
var hydration: float = 100.0
var hydration_max: float = 100.0

var base_stats: Dictionary = {}


func initialize(npc_ref: Node) -> void:
	npc = npc_ref
	health = health_max

	var start_percent: float = 75.0
	var config := get_node_or_null("/root/NPCConfig")
	if config != null:
		start_percent = float(config.hunger_start_percent)

	if npc != null and not npc.is_in_group("player"):
		var nt: String = str(npc.get("npc_type")) if npc.get("npc_type") != null else ""
		var wild_npc: bool = npc.has_method("is_wild") and npc.is_wild()
		if not wild_npc and nt in ["caveman", "clansman", "woman", "baby"]:
			var bc := get_node_or_null("/root/BalanceConfig")
			if bc:
				start_percent = float(bc.ai_hunger_start_percent)

	_setup_diet_for_npc_type()
	_cached_daily_need = get_daily_calorie_need()
	calories_max = maxf(_cached_daily_need, 1.0)
	calories = calories_max * (start_percent / 100.0)
	_sync_hunger_from_calories()
	if BalanceConfig:
		hydration_max = 100.0
		hydration = hydration_max * (BalanceConfig.hydration_start_percent / 100.0)
	stamina = stamina_max

	hunger_deplete_rate = 0.0
	if npc != null:
		var nt2: String = npc.get("npc_type") if npc.get("npc_type") != null else ""
		match nt2:
			"deer", "mammoth":
				pass
			_:
				var uses_food_need: bool = nt2 in ["caveman", "clansman", "woman", "human", "baby", "sheep", "goat"]
				if uses_food_need:
					var wild_npc2: bool = npc.has_method("is_wild") and npc.is_wild()
					if not wild_npc2:
						_uses_calorie_sim = _should_track_calories()
						if not _uses_calorie_sim and config != null:
							hunger_deplete_rate = maxf(0.0, float(config.hunger_deplete_rate))

	base_stats = {
		"health_max": health_max,
		"strength": strength,
		"stamina_max": stamina_max,
		"agility": agility,
		"endurance": endurance,
		"perception": perception,
		"intelligence": intelligence,
		"social": social,
		"pain_tolerance": pain_tolerance,
		"fertility": fertility,
		"carry_capacity": carry_capacity,
		"morale": morale,
		"aggression": aggression
	}

	_apply_quality_tier()
	_cached_daily_need = get_daily_calorie_need()
	calories_max = maxf(_cached_daily_need, 1.0)
	_sync_hunger_from_calories()
	_connect_simulation_tick()


func _setup_diet_for_npc_type() -> void:
	if not npc:
		return
	var nt: String = str(npc.get("npc_type")) if npc.get("npc_type") != null else ""
	match nt:
		"caveman", "clansman", "woman", "baby", "human":
			diet_type = ResourceData.DietType.OMNIVORE
		"sheep", "goat", "deer", "mammoth":
			diet_type = ResourceData.DietType.HERBIVORE
		_:
			diet_type = ResourceData.DietType.OMNIVORE


func _should_track_calories() -> bool:
	if not npc:
		return false
	if npc.has_method("is_wild") and npc.is_wild():
		return false
	var nt: String = str(npc.get("npc_type")) if npc.get("npc_type") != null else ""
	return nt in ["caveman", "clansman", "woman", "baby", "human"]


func _connect_simulation_tick() -> void:
	if _sim_tick_connected or not _uses_calorie_sim:
		return
	var sm := get_node_or_null("/root/SimulationManager")
	if sm and sm.has_signal("simulation_tick"):
		if not sm.simulation_tick.is_connected(_on_simulation_tick):
			sm.simulation_tick.connect(_on_simulation_tick)
		_sim_tick_connected = true


func get_daily_calorie_need() -> float:
	if not npc:
		return 2000.0
	var nt: String = str(npc.get("npc_type")) if npc.get("npc_type") != null else ""
	var base: float = 2000.0
	if BalanceConfig:
		base = float(BalanceConfig.get_base_daily_calories(nt))
	var str_mod: float = 1.0
	var int_mod: float = 1.0
	if BalanceConfig:
		str_mod = 1.0 + maxf(0.0, (strength - 10.0) / 10.0) * float(BalanceConfig.strength_calorie_modifier)
		int_mod = 1.0 + maxf(0.0, (intelligence - 10.0) / 10.0) * float(BalanceConfig.intelligence_calorie_modifier)
	var total: float = base * str_mod * int_mod
	if npc.has_node("ReproductionComponent"):
		var rc = npc.get_node("ReproductionComponent")
		if rc and rc.get("is_pregnant") == true and BalanceConfig:
			total *= float(BalanceConfig.pregnancy_calorie_multiplier)
	return maxf(total, 1.0)


func get_hunger_percent() -> float:
	if BalanceConfig:
		return BalanceConfig.get_hunger_percent_from_calories(calories, calories_max)
	if calories_max <= 0.0:
		return 0.0
	return clampf((calories / calories_max) * 100.0, 0.0, 100.0)


func get_calorie_percent() -> float:
	if calories_max <= 0.0:
		return 0.0
	return clampf(calories / calories_max, 0.0, 1.0)


func get_hydration_percent() -> float:
	if hydration_max <= 0.0:
		return 0.0
	return clampf(hydration / hydration_max, 0.0, 1.0)


func _sync_hunger_from_calories() -> void:
	hunger = get_hunger_percent()
	hunger_max = 100.0


func add_calories(amount: float) -> void:
	if amount <= 0.0:
		return
	var old_hunger: float = hunger
	calories = minf(calories + amount, calories_max)
	_sync_hunger_from_calories()
	if npc and old_hunger != hunger:
		npc.stat_changed.emit("hunger", old_hunger, hunger)


func eat_food(food_type: ResourceData.ResourceType) -> bool:
	if not ResourceData.can_eat(diet_type, food_type):
		return false
	var cal: int = ResourceData.get_food_calories(food_type)
	if cal <= 0:
		return false
	add_calories(float(cal))
	return true


func _on_simulation_tick(_delta_game_time: float) -> void:
	if not _uses_calorie_sim or not npc or not is_instance_valid(npc):
		return
	_cached_daily_need = get_daily_calorie_need()
	calories_max = maxf(_cached_daily_need, 1.0)
	var ticks_per_day: int = 5
	if SimulationManager:
		ticks_per_day = maxi(1, SimulationManager.ticks_per_sim_day)
	var drain_per_tick: float = _cached_daily_need / float(ticks_per_day)
	calories = maxf(0.0, calories - drain_per_tick)
	_sync_hunger_from_calories()


func update(delta: float) -> void:
	var old_hunger_percent: float = get_hunger_percent()

	if not _uses_calorie_sim and hunger_deplete_rate > 0.0:
		var hunger_deplete := hunger_deplete_rate * delta / 60.0
		hunger = max(0.0, hunger - hunger_deplete)
		calories = BalanceConfig.get_calories_from_hunger_percent(hunger, calories_max) if BalanceConfig else calories

	var new_hunger_percent: float = get_hunger_percent()
	var npc_name: String = npc.get("npc_name") if npc else "unknown"
	var pi: Node = npc.get_node_or_null("/root/PlaytestInstrumentor") if npc else null
	var clan_str: String = str(npc.get("clan_name")) if npc and npc.get("clan_name") != null else ""

	if old_hunger_percent >= 80.0 and new_hunger_percent < 80.0:
		UnifiedLogger.log_npc("Hunger threshold crossed: 80% (below)", {
			"npc": npc_name, "threshold": "80%", "direction": "below",
			"hunger": "%.1f%%" % new_hunger_percent
		}, UnifiedLogger.Level.DEBUG)
		if pi and pi.has_method("npc_hunger_threshold"):
			pi.npc_hunger_threshold(npc_name, clan_str, 80, "below", new_hunger_percent)
	elif old_hunger_percent < 80.0 and new_hunger_percent >= 80.0:
		if pi and pi.has_method("npc_hunger_threshold"):
			pi.npc_hunger_threshold(npc_name, clan_str, 80, "above", new_hunger_percent)

	if old_hunger_percent >= 50.0 and new_hunger_percent < 50.0:
		if pi and pi.has_method("npc_hunger_threshold"):
			pi.npc_hunger_threshold(npc_name, clan_str, 50, "below", new_hunger_percent)
	elif old_hunger_percent < 50.0 and new_hunger_percent >= 50.0:
		if pi and pi.has_method("npc_hunger_threshold"):
			pi.npc_hunger_threshold(npc_name, clan_str, 50, "above", new_hunger_percent)

	if old_hunger_percent >= 30.0 and new_hunger_percent < 30.0:
		if pi and pi.has_method("npc_hunger_threshold"):
			pi.npc_hunger_threshold(npc_name, clan_str, 30, "below", new_hunger_percent)
	elif old_hunger_percent < 30.0 and new_hunger_percent >= 30.0:
		if pi and pi.has_method("npc_hunger_threshold"):
			pi.npc_hunger_threshold(npc_name, clan_str, 30, "above", new_hunger_percent)

	if calories <= 0.0 or hunger <= 0.0:
		var drain_per_min: float = 2.0
		if BalanceConfig:
			drain_per_min = maxf(0.0, float(BalanceConfig.hunger_health_drain_per_min))
		var health_deplete := drain_per_min * delta / 60.0
		health = max(0.0, health - health_deplete)


func _apply_quality_tier() -> void:
	if not npc:
		return
	var tier_mult := 1.0
	match npc.quality_tier:
		"Flawed":
			tier_mult = 0.8
		"Good":
			tier_mult = 1.15
		"Legendary":
			tier_mult = 1.6
	for stat_name in base_stats:
		var base_value: float = base_stats[stat_name] as float
		set(stat_name, base_value * tier_mult)
	health_max = base_stats["health_max"] * tier_mult
	health = health_max


func get_stat(stat_name: String) -> float:
	if stat_name == "hunger":
		return get_hunger_percent()
	if stat_name == "hunger_max":
		return 100.0
	var value: float = 0.0
	if get(stat_name) != null:
		value = get(stat_name) as float
	if npc:
		for buff in npc.buffs_debuffs:
			if buff.get("stat") == stat_name:
				var mult: float = buff.get("mult", 1.0)
				if mult >= 1.0:
					value *= mult
	if stat_name == "agility" or stat_name == "stamina":
		if get_hunger_percent() < 30.0:
			value *= 0.7
		if stamina < 50.0:
			value *= 0.8
	return value


func modify_stat(stat_name: String, amount: float) -> void:
	if stat_name == "hunger":
		var old_pct: float = get_hunger_percent()
		if amount > 0.0 and _uses_calorie_sim:
			# Legacy eat path passes hunger points on 0-100 scale — convert via percent of daily need.
			var pct_add: float = (amount / maxf(hunger_max, 1.0)) * 100.0 if hunger_max > 0 else amount
			add_calories((pct_add / 100.0) * calories_max)
		else:
			hunger = clamp(old_pct + amount, 0.0, 100.0)
			if BalanceConfig:
				calories = BalanceConfig.get_calories_from_hunger_percent(hunger, calories_max)
		if amount > 0.0 and npc:
			UnifiedLogger.log_npc("Hunger changed via modify_stat", {
				"npc": npc.get("npc_name") if npc else "unknown",
				"new_hunger": "%.1f%%" % get_hunger_percent()
			}, UnifiedLogger.Level.DEBUG)
		if npc:
			npc.stat_changed.emit("hunger", old_pct, get_hunger_percent())
		return

	if get(stat_name) == null:
		return
	var old_value: float = get(stat_name) as float
	var max_val: float = INF
	if get(stat_name + "_max") != null:
		max_val = get(stat_name + "_max") as float
	var new_value: float = clamp(old_value + amount, 0.0, max_val)
	set(stat_name, new_value)
	if npc:
		npc.stat_changed.emit(stat_name, old_value, new_value)


func get_speed_multiplier() -> float:
	var mult: float = 1.0
	if get_hunger_percent() < 30.0:
		mult *= 0.7
	if stamina < 50.0:
		mult *= 0.8
	if morale < 30.0:
		mult *= 0.9
	return mult


func get_all_stats() -> Dictionary:
	return {
		"health": health,
		"health_max": health_max,
		"hunger": get_hunger_percent(),
		"hunger_max": 100.0,
		"calories": calories,
		"calories_max": calories_max,
		"hydration": hydration,
		"hydration_max": hydration_max,
		"daily_calorie_need": get_daily_calorie_need(),
		"diet": ResourceData.get_diet_label(diet_type),
		"strength": strength,
		"stamina": stamina,
		"stamina_max": stamina_max,
		"agility": agility,
		"endurance": endurance,
		"perception": perception,
		"intelligence": intelligence,
		"social": social,
		"pain_tolerance": pain_tolerance,
		"fertility": fertility,
		"carry_capacity": carry_capacity,
		"morale": morale,
		"aggression": aggression
	}
