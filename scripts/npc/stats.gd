extends Node
class_name Stats

# Stats component for NPCs
# All stats are exposed and editable

var npc: Node = null

# Core stats (exposed in inspector)
@export var health_max: float = 100.0
@export var health: float = 100.0
@export var hunger_max: float = 100.0
@export var hunger: float = 100.0
@export var strength: float = 10.0
@export var stamina_max: float = 100.0
@export var stamina: float = 100.0
@export var agility: float = 10.0
@export var endurance: float = 10.0
@export var perception: float = 10.0
@export var intelligence: float = 10.0
@export var social: float = 10.0
@export var pain_tolerance: float = 10.0
@export var fertility: float = 50.0  # Humans only
@export var carry_capacity: float = 10.0
@export var morale: float = 100.0
@export var aggression: float = 10.0

# Depletion rates (per minute)
@export var hunger_deplete_rate: float = 1.0
@export var stamina_deplete_rate: float = 5.0  # When moving/fighting
@export var stamina_regen_rate: float = 10.0  # When idle/eating

# Base values (for quality tier calculations)
var base_stats: Dictionary = {}

func initialize(npc_ref: Node) -> void:
	npc = npc_ref
	health = health_max
	
	# Initialize hunger at a percentage of max (default 75%), configurable via NPCConfig autoload
	var start_percent: float = 75.0
	var config := get_node_or_null("/root/NPCConfig")
	if config != null:
		# NPCConfig has an exported 'hunger_start_percent' variable
		start_percent = float(config.hunger_start_percent)
	hunger = hunger_max * (start_percent / 100.0)
	stamina = stamina_max
	
	# Store base values
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
	
	# Apply quality tier multiplier
	_apply_quality_tier()

func update(delta: float) -> void:
	# Track old hunger for logging
	var old_hunger: float = hunger
	var old_hunger_percent: float = (old_hunger / hunger_max) * 100.0 if hunger_max > 0 else 0.0
	
	# Deplete hunger
	var hunger_deplete := hunger_deplete_rate * delta / 60.0  # Convert to per-second
	hunger = max(0.0, hunger - hunger_deplete)
	
	var new_hunger_percent: float = (hunger / hunger_max) * 100.0 if hunger_max > 0 else 0.0
	
	# Log hunger changes and threshold crossings
	var npc_name: String = npc.get("npc_name") if npc else "unknown"
	
	# Log threshold crossings (80%, 50%, 30%)
	if old_hunger_percent >= 80.0 and new_hunger_percent < 80.0:
		UnifiedLogger.log_npc("Hunger threshold crossed: 80% (below)", {
			"npc": npc_name,
			"threshold": "80%",
			"direction": "below",
			"hunger": "%.1f%%" % new_hunger_percent
		}, UnifiedLogger.Level.DEBUG)
	elif old_hunger_percent < 80.0 and new_hunger_percent >= 80.0:
		UnifiedLogger.log_npc("Hunger threshold crossed: 80% (above)", {
			"npc": npc_name,
			"threshold": "80%",
			"direction": "above",
			"hunger": "%.1f%%" % new_hunger_percent
		}, UnifiedLogger.Level.DEBUG)
	
	if old_hunger_percent >= 50.0 and new_hunger_percent < 50.0:
		UnifiedLogger.log_npc("Hunger threshold crossed: 50% (below)", {
			"npc": npc_name,
			"threshold": "50%",
			"direction": "below",
			"hunger": "%.1f%%" % new_hunger_percent
		}, UnifiedLogger.Level.DEBUG)
	elif old_hunger_percent < 50.0 and new_hunger_percent >= 50.0:
		UnifiedLogger.log_npc("Hunger threshold crossed: 50% (above)", {
			"npc": npc_name,
			"threshold": "50%",
			"direction": "above",
			"hunger": "%.1f%%" % new_hunger_percent
		}, UnifiedLogger.Level.DEBUG)
	
	if old_hunger_percent >= 30.0 and new_hunger_percent < 30.0:
		UnifiedLogger.log_npc("Hunger threshold crossed: 30% (below)", {
			"npc": npc_name,
			"threshold": "30%",
			"direction": "below",
			"hunger": "%.1f%%" % new_hunger_percent
		}, UnifiedLogger.Level.DEBUG)
	elif old_hunger_percent < 30.0 and new_hunger_percent >= 30.0:
		UnifiedLogger.log_npc("Hunger threshold crossed: 30% (above)", {
			"npc": npc_name,
			"threshold": "30%",
			"direction": "above",
			"hunger": "%.1f%%" % new_hunger_percent
		}, UnifiedLogger.Level.DEBUG)
	
	# Log significant hunger depletion (every 10% change)
	var old_threshold: int = int(old_hunger_percent / 10.0)
	var new_threshold: int = int(new_hunger_percent / 10.0)
	if old_threshold != new_threshold:
		UnifiedLogger.log_npc("Hunger changed: %.1f%% → %.1f%% (depletion)" % [old_hunger_percent, new_hunger_percent], {
			"npc": npc_name,
			"old_hunger": "%.1f%%" % old_hunger_percent,
			"new_hunger": "%.1f%%" % new_hunger_percent,
			"change": "%.1f%%" % (new_hunger_percent - old_hunger_percent),
			"reason": "depletion",
			"deplete_rate": "%.2f/min" % hunger_deplete_rate
		}, UnifiedLogger.Level.DEBUG)
	
	# Health depletes from hunger
	if hunger <= 0.0:
		var health_deplete := 0.5 * delta / 60.0  # 0.5 per minute
		health = max(0.0, health - health_deplete)
	
	# Stamina depletion/regen (handled by FSM based on activity)
	# This is called by FSM when moving/fighting

func _apply_quality_tier() -> void:
	if not npc:
		return
	
	var tier_mult := 1.0
	match npc.quality_tier:
		"Flawed":
			tier_mult = 0.8  # -20%
		"Good":
			tier_mult = 1.15  # +15%
		"Legendary":
			tier_mult = 1.6  # +60%
	
	# Apply multiplier to all stats
	for stat_name in base_stats:
		var base_value: float = base_stats[stat_name] as float
		set(stat_name, base_value * tier_mult)
	
	# Health max needs special handling
	health_max = base_stats["health_max"] * tier_mult
	health = health_max

func get_stat(stat_name: String) -> float:
	# Get stat value, applying buffs/debuffs
	var value: float = 0.0
	if get(stat_name) != null:
		value = get(stat_name) as float
	
	# Apply buffs/debuffs from NPC (debuffs disabled - only apply buffs)
	if npc:
		for buff in npc.buffs_debuffs:
			if buff.get("stat") == stat_name:
				var mult: float = buff.get("mult", 1.0)
				# Only apply if it's a buff (mult >= 1.0), skip debuffs (mult < 1.0)
				if mult >= 1.0:
					value *= mult
	
	# Apply hunger/stamina penalties
	if stat_name == "agility" or stat_name == "stamina":
		if hunger < 30.0:
			value *= 0.7  # -30% speed/stamina when very hungry
		if stamina < 50.0:
			value *= 0.8  # -20% when low stamina
	
	return value

func modify_stat(stat_name: String, amount: float) -> void:
	if get(stat_name) == null:
		return
	
	var old_value: float = get(stat_name) as float
	var max_val: float = INF
	if get(stat_name + "_max") != null:
		max_val = get(stat_name + "_max") as float
	var new_value: float = clamp(old_value + amount, 0.0, max_val)
	set(stat_name, new_value)
	
	# Log hunger restoration (when eating)
	if stat_name == "hunger" and amount > 0.0:
		var npc_name: String = npc.get("npc_name") if npc else "unknown"
		var old_percent: float = (old_value / max_val) * 100.0 if max_val > 0 else 0.0
		var new_percent: float = (new_value / max_val) * 100.0 if max_val > 0 else 0.0
		UnifiedLogger.log_npc("Hunger changed: %.1f%% → %.1f%% (restoration)" % [old_percent, new_percent], {
			"npc": npc_name,
			"old_hunger": "%.1f%%" % old_percent,
			"new_hunger": "%.1f%%" % new_percent,
			"change": "%.1f%%" % (new_percent - old_percent),
			"reason": "restoration",
			"amount": "%.1f" % amount
		}, UnifiedLogger.Level.DEBUG)
	
	# Emit signal if NPC exists
	if npc:
		npc.stat_changed.emit(stat_name, old_value, new_value)

func get_speed_multiplier() -> float:
	# Calculate speed multiplier based on stats and conditions
	var mult: float = 1.0
	
	# Hunger penalty
	if hunger < 30.0:
		mult *= 0.7
	
	# Stamina penalty
	if stamina < 50.0:
		mult *= 0.8
	
	# Morale penalty
	if morale < 30.0:
		mult *= 0.9
	
	return mult

func get_all_stats() -> Dictionary:
	# Return all stats for debug display
	return {
		"health": health,
		"health_max": health_max,
		"hunger": hunger,
		"hunger_max": hunger_max,
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
