# ClanBrain - AI Controller for NPC Clans
# Phase 3 Part C: Strategic decision-making for clans
#
# Responsibilities:
# - Evaluate clan state periodically (every 5-10 seconds)
# - Track resources, clan members, and threats
# - Set defense vs gather ratios
# - Make strategic decisions (defend, raid, expand)
# - Coordinate clan members through assignments
#
# Key principle: ClanBrain sets INTENT, NPCs react. No micromanagement.
#
# === Tuning Guide ===
# - EVALUATION_INTERVAL: How often the brain thinks (5s default, lower = more responsive but more CPU)
# - THREAT_CACHE_INTERVAL: How often enemy strength is recalculated (30s default)
# - BASE/MIN/MAX_DEFENSE_RATIO: Scales defender count under INTRUDER+ (with 3:1 baseline = n/4)
# - MIN_RAID_PARTY_SIZE: Minimum raiders needed to start raid (2 default)
# - RAID_COOLDOWN: Time between raids (60s default)
# - RAID_DISTANCE_MAX: Max distance to consider raid targets (1500px default)

class_name ClanBrain
extends RefCounted

# === Signals for UI/Visual Feedback ===
# Note: RefCounted doesn't support signals directly, but land_claim can emit them
# These are documented for future UI integration

# === Configuration ===
const EVALUATION_INTERVAL: float = 5.0  # Seconds between state evaluations
const THREAT_CACHE_INTERVAL: float = 30.0  # Seconds between enemy threat re-evaluation
const THREAT_DISTANCE_MAX: float = 2000.0  # Distance at which threats are ignored

# Defense ratio bounds
const BASE_DEFENSE_RATIO: float = 0.2  # 20% default defense
const MIN_DEFENSE_RATIO: float = 0.1  # 10% minimum defense
const MAX_DEFENSE_RATIO: float = 0.6  # 60% maximum defense

# Resource thresholds
const CRITICAL_RESOURCE_THRESHOLD: float = 0.2  # 20% of target = critical

# Minimum land claim stock before allowing defenders (prioritize gathering first)
const MIN_STONE_FOR_DEFEND: int = 10
const MIN_WOOD_FOR_DEFEND: int = 10
const MIN_FOOD_FOR_DEFEND: int = 10  # Total of berries + grain + bread

# === Core State ===
var clan_name: String = ""
var land_claim: LandClaim = null  # Reference to the clan's land claim
## "settled" = full Land Claim AI; "nomadic" = higher herd/search/gather, lower defense (player nomad phase)
var brain_mode: String = "settled"

# === Cached References ===
var clan_members: Array = []  # All NPCs in this clan (cavemen, clansmen, women, animals)
var cavemen: Array = []  # Cavemen and clansmen only (fighters/workers)
var nearby_enemy_claims: Array = []  # Enemy land claims within threat range

# === Strategic Pressures (0.0 – 1.0) ===
var defend_pressure: float = 0.2  # How much to prioritize defense
var search_pressure: float = 0.5  # How much to prioritize searching for wild NPCs (higher = more cavemen herd; 0.5 = ~half of cavemen can herd)
var gather_pressure: float = 0.6  # How much to prioritize gathering

# === Threat Intelligence ===
var threat_level: float = 0.0  # Overall threat (0.0 = safe, 1.0 = critical)
var cached_threats: Dictionary = {}  # LandClaim -> { score: float, last_updated: float }

# === Resource Status ===
var resource_status: Dictionary = {
	"wood": { "current": 0, "target": 50, "critical": 10 },
	"stone": { "current": 0, "target": 30, "critical": 5 },
	"fiber": { "current": 0, "target": 20, "critical": 5 },
	"berries": { "current": 0, "target": 20, "critical": 5 }
}

# === Clan Metrics (evaluated each cycle, drives quota/weight updates) ===
var clan_metrics: Dictionary = {
	"population": 0,           # Total clan members (cavemen + clansmen + women + animals)
	"breeding_females": 0,     # Women in clan
	"food_total": 0,           # Berries + grain + bread in claim
	"food_days_buffer": 0.0,   # Proxy: food_total / max(1, population * FOOD_PER_DAY_PROXY)
	"herd_value": 0,           # Women + sheep + goats in clan
	"building_count": 0,       # Buildings (non-claim) with same clan_name
	"recent_losses": 0         # From land_claim meta "recent_herd_losses" (future: increment on herd steal)
}
const FOOD_PER_DAY_PROXY: float = 2.0  # Used for food_days_buffer calculation

# === Economic Priority Weights (0.0–1.0, stored on land_claim for FSM/job selection) ===
var economic_priority_weights: Dictionary = {
	"food_weight": 1.0,
	"resource_weight": 0.8,
	"build_weight": 0.5,
	"herd_weight": 0.7
}

# === Alert System ===
enum AlertLevel { NONE, INTRUDER, SKIRMISH, RAID }
var alert_level: AlertLevel = AlertLevel.NONE
var alert_decay_timer: float = 0.0
const ALERT_DECAY_TIME: float = 10.0  # Seconds before alert decays

# === Strategic State ===
enum StrategicState { PEACEFUL, DEFENSIVE, AGGRESSIVE, RAIDING, RECOVERING }
var strategic_state: StrategicState = StrategicState.PEACEFUL

# === Raid Personality Stats (Data-Driven) ===
# These are clan traits that affect raid behavior - tunable per-clan
var raid_aggression: float = 0.5      # 0.0-1.0: How willing to fight (hostile clans higher)
var raid_risk_tolerance: float = 0.3  # 0.0-1.0: Casualties tolerated before retreat
var raid_organization: float = 0.5    # 0.0-1.0: How tightly raiders stick together
var raid_loot_focus: float = 0.5      # 0.0=burn/kill, 1.0=steal resources

# === Raid Trigger Thresholds ===
var raid_hunger_threshold: float = 0.3     # Food ratio below this increases raid desire
var raid_population_pressure: float = 0.7  # Population pressure weight in raid scoring
var raid_opportunity_weight: float = 0.4   # Weight for weak enemy opportunity

# === Player Emergency Defend ===
# When player clicks DEFEND on land claim dropdown = last resort. Keep everyone defending
# until PLAYER_EMERGENCY_DEFEND_COOLDOWN seconds have passed since the last intrusion.
var player_emergency_defend: bool = false
var last_intrusion_time: float = 0.0  # Time.get_ticks_msec()/1000.0 when last enemy entered
const PLAYER_EMERGENCY_DEFEND_COOLDOWN: float = 30.0  # Seconds with no intrusion before releasing (testing value)

# === Timers ===
var _evaluation_timer: float = 0.0
var _threat_cache_timer: float = 0.0
var _last_evaluation_time: float = 0.0

# === Initialization ===

func _init(claim: LandClaim = null) -> void:
	if claim:
		initialize(claim)

func set_mode(mode: String) -> void:
	brain_mode = mode if mode == "nomadic" or mode == "settled" else "settled"


func initialize(claim: LandClaim) -> void:
	"""Initialize ClanBrain with a land claim."""
	land_claim = claim
	clan_name = claim.clan_name if claim else ""
	if land_claim and land_claim.get_meta("start_in_nomadic_brain", false):
		brain_mode = "nomadic"
		land_claim.remove_meta("start_in_nomadic_brain")
	
	# Initial state
	_evaluation_timer = randf_range(0.0, EVALUATION_INTERVAL)  # Stagger evaluations
	_threat_cache_timer = randf_range(0.0, THREAT_CACHE_INTERVAL)
	
	# Run one full evaluation immediately so quotas/weights are set from frame 0 (no 0-5s delay)
	_evaluate_clan_state()
	_update_land_claim_ratios()
	
	print("🧠 ClanBrain initialized for clan: %s" % clan_name)

# === Main Update Loop ===

func update(delta: float) -> void:
	"""Called periodically by the land claim or a manager. Updates clan state."""
	if not land_claim or not is_instance_valid(land_claim):
		return
	
	var is_player_clan: bool = land_claim.get("player_owned") == true
	
	# Update alert decay
	_update_alert_decay(delta)
	
	# Phase 3: Update active raid - skip for player clans (they don't raid)
	if not is_player_clan:
		_update_raid()
	
	# Periodic state evaluation
	_evaluation_timer += delta
	if _evaluation_timer >= EVALUATION_INTERVAL:
		_evaluation_timer = 0.0
		_evaluate_clan_state()
		if not is_player_clan:
			_make_strategic_decisions()
		_update_land_claim_ratios()
	
	# Periodic threat cache refresh - skip for player clans (no raid targeting)
	if not is_player_clan:
		_threat_cache_timer += delta
		if _threat_cache_timer >= THREAT_CACHE_INTERVAL:
			_threat_cache_timer = 0.0
			_refresh_threat_cache()

# === State Evaluation ===

const MIN_CLANSMEN_FOR_BRAIN: int = 2  # Defender/searcher assignments only when 2+ cavemen (single caveman stays free to herd/gather)
## No defender quota until this many cavemen/clansmen (everyone works first). RAID + player emergency defend bypass.
const MIN_FIGHTERS_BEFORE_DEFEND: int = 3

func _evaluate_clan_state() -> void:
	"""Evaluate the current state of the clan."""
	_last_evaluation_time = Time.get_ticks_msec() / 1000.0
	
	# Refresh cached data
	_refresh_clan_members()
	_refresh_resource_status()
	
	# Metric-driven: populate clan_metrics and economic weights
	_evaluate_metrics()
	_update_economic_weights()
	
	var is_player_clan: bool = land_claim and land_claim.get("player_owned") == true
	var in_emergency: bool = player_emergency_defend or alert_level >= AlertLevel.RAID
	
	# Skip raid-related logic for player clans
	if not is_player_clan:
		_refresh_nearby_enemies()
	
	# Milestone buildings: run even for single-caveman clans so Living Hut etc. can spawn when thresholds met
	if not is_player_clan:
		_evaluate_milestone_buildings()
	
	# ClanBrain assignments: single caveman stays free EXCEPT during emergency (player or NPC)
	if cavemen.size() < MIN_CLANSMEN_FOR_BRAIN and not in_emergency:
		if land_claim:
			land_claim.set_meta("breeding_females", clan_metrics["breeding_females"])
			land_claim.set_meta("defender_quota", 0)
			var to_evict: Array = []
			for d in land_claim.assigned_defenders:
				if is_instance_valid(d):
					to_evict.append(d)
			for d in to_evict:
				d.set("defend_target", null)
				land_claim.remove_defender(d)
			land_claim._prune_defenders()
			# Single caveman: always allow 1 searcher so they go out herding (more women/sheep/goats)
			land_claim.set_meta("searcher_quota", 1)
			land_claim.set_meta("defenders_can_search", true)
			land_claim._prune_searchers()
		return
	
	# Calculate threat and pressures - skip for player clans (player uses n/4 + drag pool)
	if not is_player_clan:
		_calculate_threat_level()
		_update_pressures()
	
	# Phase 2: Update defender assignments
	_update_defender_assignments()
	
	# Phase 4: Update searcher assignments
	_update_searcher_assignments()
	
	# Debug: invariant asserts (guarded by OS.is_debug_build)
	if OS.is_debug_build() and land_claim:
		var dq: int = land_claim.get_meta("defender_quota", 0)
		var sq: int = land_claim.get_meta("searcher_quota", 0)
		if dq > cavemen.size():
			push_error("ClanBrain %s: invariant failed defender_quota(%d) > cavemen.size(%d)" % [clan_name, dq, cavemen.size()])
		if sq > cavemen.size():
			push_error("ClanBrain %s: invariant failed searcher_quota(%d) > cavemen.size(%d)" % [clan_name, sq, cavemen.size()])

func _refresh_clan_members() -> void:
	"""Refresh the list of clan members."""
	clan_members.clear()
	cavemen.clear()
	
	if not land_claim:
		return
	
	# Get all NPCs in the game
	var main = land_claim.get_tree().get_first_node_in_group("main") if land_claim.get_tree() else null
	if not main:
		return
	
	var all_npcs = land_claim.get_tree().get_nodes_in_group("npcs")
	
	for npc in all_npcs:
		if not is_instance_valid(npc):
			continue
		
		# Get NPC's clan name
		var npc_clan: String = ""
		if npc.has_method("get_clan_name"):
			npc_clan = npc.get_clan_name()
		else:
			var clan_prop = npc.get("clan_name")
			npc_clan = clan_prop as String if clan_prop != null else ""
		
		# Check if NPC belongs to this clan (case-insensitive so babies aren't excluded by casing)
		if npc_clan.to_lower() == clan_name.to_lower():
			clan_members.append(npc)
			
			# Track cavemen/clansmen separately (fighters/workers)
			var npc_type: String = npc.get("npc_type") if "npc_type" in npc else ""
			if npc_type == "caveman" or npc_type == "clansman":
				cavemen.append(npc)


func _refresh_resource_status() -> void:
	"""Refresh resource counts from land claim inventory."""
	if not land_claim or not land_claim.inventory:
		return
	
	# Reset current counts
	for key in resource_status:
		resource_status[key]["current"] = 0
	
	# Count resources in land claim inventory
	var inventory = land_claim.inventory
	for i in range(inventory.slot_count):
		var slot = inventory.slots[i] if i < inventory.slots.size() else null
		if slot == null:
			continue
		
		var item_type = slot.get("item_type")
		var count: int = slot.get("count", 0)
		
		if item_type == null or count <= 0:
			continue
		
		# Map ResourceType to our tracking keys
		var resource_name: String = _get_resource_name(item_type)
		if resource_name in resource_status:
			resource_status[resource_name]["current"] += count

func _get_resource_name(item_type) -> String:
	"""Convert ResourceData.ResourceType to string key."""
	# ResourceType enum values (from resource_data.gd)
	match item_type:
		0: return "wood"  # WOOD
		1: return "stone"  # STONE
		2: return "fiber"  # FIBER
		3: return "berries"  # BERRIES
		_: return ""

func _evaluate_metrics() -> void:
	"""Populate clan_metrics from clan_members, resources, buildings."""
	clan_metrics["population"] = clan_members.size()
	clan_metrics["breeding_females"] = 0
	clan_metrics["herd_value"] = 0
	
	for npc in clan_members:
		if not is_instance_valid(npc):
			continue
		var nt: String = npc.get("npc_type") if npc.get("npc_type") != null else ""
		if nt == "woman":
			clan_metrics["breeding_females"] += 1
			clan_metrics["herd_value"] += 1
		elif nt == "sheep" or nt == "goat":
			clan_metrics["herd_value"] += 1
	
	if land_claim and land_claim.inventory and land_claim.inventory.has_method("get_count"):
		var inv = land_claim.inventory
		clan_metrics["food_total"] = (
			inv.get_count(ResourceData.ResourceType.BERRIES)
			+ inv.get_count(ResourceData.ResourceType.GRAIN)
			+ inv.get_count(ResourceData.ResourceType.BREAD)
			+ inv.get_count(ResourceData.ResourceType.MUSHROOM)
			+ inv.get_count(ResourceData.ResourceType.BUGS)
			+ inv.get_count(ResourceData.ResourceType.NUTS)
		)
	
	var pop: int = maxi(1, clan_metrics["population"])
	clan_metrics["food_days_buffer"] = float(clan_metrics["food_total"]) / maxf(1.0, float(pop) * FOOD_PER_DAY_PROXY)
	
	clan_metrics["building_count"] = 0
	if land_claim and land_claim.get_tree():
		for bld in land_claim.get_tree().get_nodes_in_group("buildings"):
			if not is_instance_valid(bld) or bld == land_claim:
				continue
			var bc: String = bld.get("clan_name") if "clan_name" in bld else ""
			if bc == clan_name:
				clan_metrics["building_count"] += 1
	
	clan_metrics["recent_losses"] = land_claim.get_meta("recent_herd_losses", 0) if land_claim else 0

func _update_economic_weights() -> void:
	"""Adjust economic_priority_weights - population maxing: herd first, food when critical."""
	var bf: int = clan_metrics["breeding_females"]
	var fdb: float = clan_metrics["food_days_buffer"]
	var pop: int = clan_metrics["population"]
	
	# Base: herd dominates, gather supports
	economic_priority_weights["food_weight"] = 1.0
	economic_priority_weights["herd_weight"] = 0.8
	economic_priority_weights["resource_weight"] = 0.6
	economic_priority_weights["build_weight"] = 0.5
	
	# Herd-first tiers by breeding females
	if bf < 2:
		economic_priority_weights["herd_weight"] = 1.2
	if bf == 0 and pop >= 1:
		economic_priority_weights["herd_weight"] = 1.4
	# Food only when critical
	if fdb < 2.0:
		economic_priority_weights["food_weight"] = 1.3
	if fdb < 1.0:
		economic_priority_weights["food_weight"] = 1.5
	
	if brain_mode == "nomadic":
		economic_priority_weights["herd_weight"] *= 1.35
		economic_priority_weights["resource_weight"] *= 1.15
		economic_priority_weights["build_weight"] *= 0.45
	
	if land_claim:
		land_claim.set_meta("economic_priority_weights", economic_priority_weights.duplicate())

func _refresh_nearby_enemies() -> void:
	"""Refresh list of nearby enemy land claims."""
	nearby_enemy_claims.clear()
	
	if not land_claim:
		return
	
	var claim_pos: Vector2 = land_claim.global_position
	
	# Use cached land claims from main if available
	var main = land_claim.get_tree().get_first_node_in_group("main") if land_claim.get_tree() else null
	var all_claims: Array = []
	
	if main and main.has_method("get_cached_land_claims"):
		all_claims = main.get_cached_land_claims()
	else:
		all_claims = land_claim.get_tree().get_nodes_in_group("land_claims") if land_claim.get_tree() else []
	
	for claim in all_claims:
		if not is_instance_valid(claim) or claim == land_claim:
			continue
		# Campfire (and any duck-typed nodes) share group "land_claims" but are not LandClaim — threat/raid logic needs real claims only
		if not (claim is LandClaim):
			continue
		
		# Check if enemy (different clan)
		var claim_clan: String = claim.get("clan_name") if "clan_name" in claim else ""
		if claim_clan == clan_name or claim_clan == "":
			continue
		
		# Check distance
		var distance: float = claim_pos.distance_to(claim.global_position)
		if distance <= THREAT_DISTANCE_MAX:
			nearby_enemy_claims.append(claim)

func _refresh_threat_cache() -> void:
	"""Refresh cached threat scores for enemy claims (expensive, done less often)."""
	cached_threats.clear()
	var current_time: float = Time.get_ticks_msec() / 1000.0
	
	for enemy_claim in nearby_enemy_claims:
		if not is_instance_valid(enemy_claim):
			continue
		
		var threat_score: float = _evaluate_enemy_threat(enemy_claim)
		cached_threats[enemy_claim] = {
			"score": threat_score,
			"last_updated": current_time
		}

func _evaluate_enemy_threat(enemy_claim: LandClaim) -> float:
	"""Evaluate threat level from a single enemy clan."""
	if not land_claim or not is_instance_valid(enemy_claim):
		return 0.0
	
	var threat: float = 0.0
	var claim_pos: Vector2 = land_claim.global_position
	var enemy_pos: Vector2 = enemy_claim.global_position
	
	# Distance factor (closer = more threatening)
	var distance: float = claim_pos.distance_to(enemy_pos)
	var distance_factor: float = 1.0 - clampf(distance / THREAT_DISTANCE_MAX, 0.0, 1.0)
	threat += distance_factor * 0.4
	
	# Enemy strength factor (count their cavemen)
	var enemy_strength: int = _count_enemy_fighters(enemy_claim)
	var our_strength: int = cavemen.size()
	var strength_ratio: float = float(enemy_strength) / maxf(1.0, float(our_strength))
	threat += clampf(strength_ratio * 0.3, 0.0, 0.3)
	
	# Enemy defense count factor
	var enemy_defenders: int = enemy_claim.assigned_defenders.size() if enemy_claim else 0
	threat += clampf(float(enemy_defenders) / maxf(1.0, float(enemy_strength)) * 0.2, 0.0, 0.2)
	
	# Activity factor (are they raiding us?) - check alert level
	if alert_level >= AlertLevel.SKIRMISH:
		threat += 0.1
	
	return clampf(threat, 0.0, 1.0)

func _count_enemy_fighters(enemy_claim: LandClaim) -> int:
	"""Count cavemen/clansmen in an enemy clan."""
	if not enemy_claim:
		return 0
	
	var enemy_clan: String = enemy_claim.get("clan_name") if "clan_name" in enemy_claim else ""
	if enemy_clan == "":
		return 0
	
	var count: int = 0
	var all_npcs = land_claim.get_tree().get_nodes_in_group("npcs") if land_claim and land_claim.get_tree() else []
	
	for npc in all_npcs:
		if not is_instance_valid(npc):
			continue
		
		var npc_clan: String = ""
		if npc.has_method("get_clan_name"):
			npc_clan = npc.get_clan_name()
		else:
			var clan_prop = npc.get("clan_name")
			npc_clan = clan_prop as String if clan_prop != null else ""
		
		if npc_clan != enemy_clan:
			continue
		
		var npc_type: String = npc.get("npc_type") if "npc_type" in npc else ""
		if npc_type == "caveman" or npc_type == "clansman":
			count += 1
	
	return count

func _calculate_threat_level() -> void:
	"""Calculate overall threat level from all sources."""
	threat_level = 0.0
	
	# Sum threat from all nearby enemies
	for enemy_claim in nearby_enemy_claims:
		if not is_instance_valid(enemy_claim):
			continue
		
		var threat: float = 0.0
		if enemy_claim in cached_threats:
			threat = cached_threats[enemy_claim].get("score", 0.0)
		else:
			threat = _evaluate_enemy_threat(enemy_claim)
		
		threat_level += threat
	
	# Alert level increases threat
	match alert_level:
		AlertLevel.INTRUDER:
			threat_level += 0.1
		AlertLevel.SKIRMISH:
			threat_level += 0.3
		AlertLevel.RAID:
			threat_level += 0.5
	
	threat_level = clampf(threat_level, 0.0, 1.0)

func _update_pressures() -> void:
	"""Update strategic pressures - population maxing: search dominates, gather supports."""
	# Base pressures: search primary, gather support only
	defend_pressure = BASE_DEFENSE_RATIO
	search_pressure = 0.6  # Primary work - get women for population growth
	gather_pressure = 0.35  # Support only - feed the population
	
	# Adjust for threat level
	defend_pressure += threat_level * 0.4
	
	# Adjust for resource needs
	var resource_urgency: float = _calculate_resource_urgency()
	gather_pressure += resource_urgency * 0.2
	
	# Metric-driven: boost search when we need women (population maxing)
	var bf: int = clan_metrics["breeding_females"]
	if bf < 2:
		search_pressure += 0.35
	if bf == 0 and clan_metrics["population"] >= 1:
		search_pressure += 0.3
	# Metric-driven: gather only when food critical
	var fdb: float = clan_metrics["food_days_buffer"]
	if fdb < 2.0:
		gather_pressure += 0.25
	if fdb < 1.0:
		gather_pressure += 0.15
	
	# Normalize pressures
	var total: float = defend_pressure + search_pressure + gather_pressure
	if total > 0:
		defend_pressure /= total
		search_pressure /= total
		gather_pressure /= total
	
	# Clamp defense to bounds
	defend_pressure = clampf(defend_pressure, MIN_DEFENSE_RATIO, MAX_DEFENSE_RATIO)
	
	if brain_mode == "nomadic":
		defend_pressure *= 0.55
		search_pressure *= 1.2
		gather_pressure *= 1.1
		var t2: float = defend_pressure + search_pressure + gather_pressure
		if t2 > 0.0:
			defend_pressure /= t2
			search_pressure /= t2
			gather_pressure /= t2
		defend_pressure = clampf(defend_pressure, MIN_DEFENSE_RATIO, MAX_DEFENSE_RATIO)

func _calculate_resource_urgency() -> float:
	"""Calculate how urgently we need resources (0.0 = fine, 1.0 = critical)."""
	var urgency: float = 0.0
	var count: int = 0
	
	for key in resource_status:
		var status = resource_status[key]
		var current: int = status["current"]
		var target: int = status["target"]
		var critical: int = status["critical"]
		
		if current < critical:
			urgency += 1.0
		elif current < target:
			urgency += 0.5 * (1.0 - float(current) / float(target))
		
		count += 1
	
	return clampf(urgency / maxf(1.0, float(count)), 0.0, 1.0)

func _calculate_food_ratio() -> float:
	"""Calculate food availability ratio (0.0 = starving, 1.0 = fully stocked)."""
	if "berries" not in resource_status:
		return 1.0  # No food tracking, assume fine
	
	var berries = resource_status["berries"]
	var current: int = berries["current"]
	var target: int = berries["target"]
	
	if target <= 0:
		return 1.0
	
	return clampf(float(current) / float(target), 0.0, 1.0)

# === Strategic Decisions ===

func _make_strategic_decisions() -> void:
	"""Make high-level strategic decisions based on current state."""
	var previous_state: StrategicState = strategic_state
	
	# Don't change state while raiding (unless under attack)
	if strategic_state == StrategicState.RAIDING and alert_level < AlertLevel.SKIRMISH:
		return
	
	# Don't change state while recovering (give time to rebuild)
	if strategic_state == StrategicState.RECOVERING:
		var time_since_raid: float = (Time.get_ticks_msec() / 1000.0) - _last_raid_time
		if time_since_raid < 30.0:  # Recover for 30 seconds
			return
	
	# Determine new strategic state
	if alert_level >= AlertLevel.RAID:
		strategic_state = StrategicState.DEFENSIVE
	elif threat_level > 0.6:
		strategic_state = StrategicState.DEFENSIVE
	elif threat_level > 0.3:
		# Could be defensive or aggressive based on strength
		if cavemen.size() > 3:
			strategic_state = StrategicState.AGGRESSIVE
		else:
			strategic_state = StrategicState.DEFENSIVE
	else:
		strategic_state = StrategicState.PEACEFUL
	
	# Log state change
	if strategic_state != previous_state:
		print("🧠 ClanBrain %s: State changed from %s to %s" % [
			clan_name,
			StrategicState.keys()[previous_state],
			StrategicState.keys()[strategic_state]
		])
	
	# Phase 3: Evaluate raid opportunities when aggressive
	if strategic_state == StrategicState.AGGRESSIVE or strategic_state == StrategicState.PEACEFUL:
		_evaluate_raid_opportunity()

func _update_land_claim_ratios() -> void:
	"""Push updated ratios to the land claim."""
	if not land_claim or not is_instance_valid(land_claim):
		return
	
	# Defend ratio for UI/telemetry: actual quota vs fighters (player uses auto 3:1 + drag, not slider)
	var n_f: int = cavemen.size()
	var dq: int = land_claim.get_meta("defender_quota", 0)
	land_claim.defend_ratio = float(dq) / maxf(1.0, float(n_f)) if n_f > 0 else 0.0
	land_claim.search_ratio = search_pressure

# === Alert System ===

func on_alert(level: AlertLevel) -> void:
	"""Called when an alert is triggered (intruder, skirmish, raid)."""
	# Track last intrusion time for player emergency defend cooldown
	var now: float = Time.get_ticks_msec() / 1000.0
	last_intrusion_time = now
	
	if level > alert_level:
		alert_level = level
		alert_decay_timer = 0.0
		
		print("🚨 ClanBrain %s: Alert level raised to %s" % [
			clan_name,
			AlertLevel.keys()[alert_level]
		])
		
		# Immediate response to alerts - bypass 5s evaluation timer
		_recalculate_quotas_immediately(level)

func _recalculate_quotas_immediately(level: AlertLevel) -> void:
	"""Immediate quota recalculation on alert - bypasses normal evaluation timer."""
	match level:
		AlertLevel.INTRUDER:
			# Slight increase in defense
			defend_pressure = clampf(defend_pressure + 0.1, MIN_DEFENSE_RATIO, MAX_DEFENSE_RATIO)
			_update_defender_assignments()
			_update_searcher_assignments()
		AlertLevel.SKIRMISH:
			# Significant increase in defense
			defend_pressure = clampf(defend_pressure + 0.2, MIN_DEFENSE_RATIO, MAX_DEFENSE_RATIO)
			_update_defender_assignments()
			_update_searcher_assignments()
		AlertLevel.RAID:
			# Maximum defense, cancel outgoing raids
			defend_pressure = MAX_DEFENSE_RATIO
			strategic_state = StrategicState.DEFENSIVE
			if is_raiding():
				_cancel_raid("under_attack")
			force_defend_all()
			_update_searcher_assignments()  # Set searcher quota to 0 during raids
	
	_update_land_claim_ratios()

func _update_alert_decay(delta: float) -> void:
	"""Decay alert level over time when no threats detected."""
	if alert_level == AlertLevel.NONE:
		return
	
	alert_decay_timer += delta
	if alert_decay_timer >= ALERT_DECAY_TIME:
		alert_decay_timer = 0.0
		
		# Decay one level
		var _old_level: AlertLevel = alert_level  # Kept for debugging if needed
		match alert_level:
			AlertLevel.RAID:
				alert_level = AlertLevel.SKIRMISH
			AlertLevel.SKIRMISH:
				alert_level = AlertLevel.INTRUDER
			AlertLevel.INTRUDER:
				alert_level = AlertLevel.NONE
		
		print("🧠 ClanBrain %s: Alert decayed to %s" % [
			clan_name,
			AlertLevel.keys()[alert_level]
		])
		
		# Recalculate quotas on decay (excess defenders can self-evict)
		_update_pressures()
		_update_defender_assignments()
		_update_searcher_assignments()
		_update_land_claim_ratios()

# === Public API ===

func get_clan_members() -> Array:
	"""Get all NPCs in this clan."""
	return clan_members

func get_fighters() -> Array:
	"""Get cavemen/clansmen (fighters/workers)."""
	return cavemen

func get_threat_level() -> float:
	"""Get current threat level (0.0 - 1.0)."""
	return threat_level

func get_strategic_state() -> StrategicState:
	"""Get current strategic state."""
	return strategic_state

func get_defend_ratio() -> float:
	"""Effective defenders / fighters (quota-based; not the internal defend_pressure curve)."""
	if not land_claim or cavemen.is_empty():
		return 0.0
	return float(get_defender_quota()) / float(cavemen.size())

func get_search_ratio() -> float:
	"""Get current search ratio."""
	return search_pressure

func get_gather_ratio() -> float:
	"""Get current gather ratio."""
	return gather_pressure

func get_resource_status() -> Dictionary:
	"""Get resource tracking status."""
	return resource_status

func is_resource_critical(resource_name: String) -> bool:
	"""Check if a resource is below critical threshold."""
	if resource_name not in resource_status:
		return false
	
	var status = resource_status[resource_name]
	return status["current"] < status["critical"]

func needs_resources() -> bool:
	"""Check if clan needs any resources."""
	for key in resource_status:
		if resource_status[key]["current"] < resource_status[key]["target"]:
			return true
	return false

# === Phase 2: Defense System ===
# Note: Defenders are tracked in land_claim.assigned_defenders
# ClanBrain sets quotas, NPCs self-assign by calling land_claim.add_defender(self)

func _claim_has_minimum_stock_for_defend(claim: Node) -> bool:
	"""True when claim has at least MIN_STONE, MIN_WOOD, and MIN_FOOD (total) - then auto-defender is allowed."""
	if not claim or not is_instance_valid(claim):
		return false
	var inv = claim.get("inventory")
	if not inv or not inv.has_method("get_count"):
		return false
	var stone: int = inv.get_count(ResourceData.ResourceType.STONE)
	var wood: int = inv.get_count(ResourceData.ResourceType.WOOD)
	var food: int = inv.get_count(ResourceData.ResourceType.BERRIES) + inv.get_count(ResourceData.ResourceType.GRAIN) + inv.get_count(ResourceData.ResourceType.BREAD)
	return stone >= MIN_STONE_FOR_DEFEND and wood >= MIN_WOOD_FOR_DEFEND and food >= MIN_FOOD_FOR_DEFEND

func _claim_has_building_type(claim: Node, building_type: ResourceData.ResourceType) -> bool:
	"""True if this clan already has at least one building of the given type."""
	if not claim or not claim.get_tree():
		return false
	var cn: String = claim.get("clan_name") if "clan_name" in claim else ""
	if cn.is_empty():
		return false
	for bld in claim.get_tree().get_nodes_in_group("buildings"):
		if not is_instance_valid(bld) or bld is LandClaim:
			continue
		if bld.get("clan_name") == cn and bld.get("building_type") == building_type:
			return true
	return false

func _evaluate_milestone_buildings() -> void:
	"""When AI hits milestones, spawn buildings: 10 stone→Oven, 3 sheep→Farm, 3 goats→Dairy, 2 babies→Living Hut."""
	if not land_claim or not is_instance_valid(land_claim) or not land_claim.inventory:
		return
	var main_node = land_claim.get_tree().get_first_node_in_group("main") if land_claim.get_tree() else null
	if not main_node or not main_node.has_method("_place_ai_building"):
		return
	var inv = land_claim.inventory
	var stone: int = inv.get_count(ResourceData.ResourceType.STONE)
	var wood: int = inv.get_count(ResourceData.ResourceType.WOOD)
	var sheep_count: int = 0
	var goat_count: int = 0
	var baby_count: int = 0
	for npc in clan_members:
		if not is_instance_valid(npc):
			continue
		var nt: String = npc.get("npc_type") if npc.get("npc_type") != null else ""
		if nt == "sheep":
			sheep_count += 1
		elif nt == "goat":
			goat_count += 1
		elif nt == "baby":
			baby_count += 1
	# Milestones: 10 stone → Oven; 3 sheep → Farm; 3 goats → Dairy; 2 babies → Living Hut
	if stone >= 10 and not _claim_has_building_type(land_claim, ResourceData.ResourceType.OVEN):
		main_node._place_ai_building(land_claim, ResourceData.ResourceType.OVEN)
	if sheep_count >= 3 and not _claim_has_building_type(land_claim, ResourceData.ResourceType.FARM):
		main_node._place_ai_building(land_claim, ResourceData.ResourceType.FARM)
	if goat_count >= 3 and not _claim_has_building_type(land_claim, ResourceData.ResourceType.DAIRY_FARM):
		main_node._place_ai_building(land_claim, ResourceData.ResourceType.DAIRY_FARM)
	if baby_count >= 2 and not _claim_has_building_type(land_claim, ResourceData.ResourceType.LIVING_HUT):
		var placed: bool = main_node._place_ai_building(land_claim, ResourceData.ResourceType.LIVING_HUT)
		if not placed:
			print("🧠 ClanBrain %s: Living Hut milestone (baby_count=%d) but _place_ai_building returned false" % [clan_name, baby_count])

func _update_defender_assignments() -> void:
	"""Update defender quota - NPCs will pull this and self-assign."""
	if not land_claim:
		return
	if cavemen.size() == 0:
		land_claim.set_meta("defender_quota", 0)
		var to_evict: Array = []
		for d in land_claim.assigned_defenders:
			if is_instance_valid(d):
				to_evict.append(d)
		for d in to_evict:
			d.set("defend_target", null)
			land_claim.remove_defender(d)
		land_claim._prune_defenders()
		return
	
	var is_player_clan: bool = land_claim.get("player_owned") == true
	var in_emergency: bool = player_emergency_defend or alert_level >= AlertLevel.RAID
	
	# Hardening: lone caveman stays free unless RAID - prevents death spiral (INTRUDER/SKIRMISH)
	if cavemen.size() == 1 and alert_level < AlertLevel.RAID:
		land_claim.set_meta("defender_quota", 0)
		var to_evict: Array = []
		for d in land_claim.assigned_defenders:
			if is_instance_valid(d):
				to_evict.append(d)
		for d in to_evict:
			d.set("defend_target", null)
			land_claim.remove_defender(d)
		land_claim._prune_defenders()
		return
	
	# Keep everyone off defend until 3+ fighters (gather/herd first). RAID / player emergency defend exempt.
	if cavemen.size() < MIN_FIGHTERS_BEFORE_DEFEND and not in_emergency:
		land_claim.set_meta("defender_quota", 0)
		var to_evict_small: Array = []
		for d in land_claim.assigned_defenders:
			if is_instance_valid(d):
				to_evict_small.append(d)
		for d in to_evict_small:
			d.set("defend_target", null)
			land_claim.remove_defender(d)
		land_claim._prune_defenders()
		return
	
	# Freeze defender quota during raid (RECRUITING/ACTIVE) unless under attack - prevents oscillation
	var raid_state_val: int = raid_intent.get("state", RaidState.NONE)
	if (raid_state_val == RaidState.RECRUITING or raid_state_val == RaidState.ACTIVE) and alert_level < AlertLevel.SKIRMISH:
		return
	
	# Min-stock gate: AI clans only (so early clans gather first). Player clan always uses slider.
	if not is_player_clan and alert_level < AlertLevel.INTRUDER and not _claim_has_minimum_stock_for_defend(land_claim):
		land_claim.set_meta("defender_quota", 0)
		var to_evict: Array = []
		for d in land_claim.assigned_defenders:
			if is_instance_valid(d):
				to_evict.append(d)
		for d in to_evict:
			d.set("defend_target", null)
			land_claim.remove_defender(d)
		land_claim._prune_defenders()
		return
	
	# Player emergency defend: keep everyone defending until cooldown since last intrusion
	if player_emergency_defend:
		var now: float = Time.get_ticks_msec() / 1000.0
		if (now - last_intrusion_time) >= PLAYER_EMERGENCY_DEFEND_COOLDOWN:
			player_emergency_defend = false
			print("🛡️ ClanBrain %s: Player emergency defend ended (%.0fs since last intrusion) - releasing defenders" % [clan_name, PLAYER_EMERGENCY_DEFEND_COOLDOWN])
		else:
			# Still in emergency: quota = all fighters (including single clansman)
			land_claim.set_meta("defender_quota", cavemen.size())
			land_claim.set_meta("defender_pressure", 1.0)
			land_claim._prune_defenders()
			return
	
	# RAID alert: force all defenders (handled by _recalculate_quotas_immediately, but fallback)
	if alert_level >= AlertLevel.RAID:
		land_claim.set_meta("defender_quota", cavemen.size())
		land_claim.set_meta("defender_pressure", 1.0)
		land_claim._prune_defenders()
		return
	
	# 3:1 worker:defender default — 1 defender slot per 4 cavemen/clansmen (integer division).
	var n: int = cavemen.size()
	var base_quota: int = n / 4
	var target_defenders: int = base_quota
	if not is_player_clan:
		# Under threat, never go below 3:1 baseline; pressure can add more (up to n).
		if alert_level >= AlertLevel.INTRUDER and alert_level < AlertLevel.RAID:
			var pressure_slots: int = int(ceil(float(n) * defend_pressure))
			target_defenders = maxi(base_quota, pressure_slots)
	else:
		# Player: base = n/4 (e.g. 4 fighters → 1 defender). Drag worker to map outside claim → add_defender;
		# quota = max(base, pool) so 4 + one border drag → 2 defenders, 2 workers (2:2). Drag inside claim → work, pool shrinks.
		land_claim._prune_defenders()
		target_defenders = maxi(base_quota, land_claim.assigned_defenders.size())
	target_defenders = clampi(target_defenders, 0, n)
	
	# Store quota on land claim - NPCs will read this
	var ratio_display: float = float(target_defenders) / maxf(1.0, float(n))
	land_claim.set_meta("defender_quota", target_defenders)
	land_claim.set_meta("defender_pressure", ratio_display)
	
	# Prune invalid defenders from pool (NPCs add/remove themselves)
	land_claim._prune_defenders()

func get_defender_quota() -> int:
	"""Get how many defenders the clan needs."""
	if not land_claim:
		return 0
	return land_claim.get_meta("defender_quota", 0)

func get_current_defender_count() -> int:
	"""Get how many NPCs are currently defending (from pool)."""
	if not land_claim:
		return 0
	land_claim._prune_defenders()
	return land_claim.assigned_defenders.size()

func needs_more_defenders() -> bool:
	"""Check if clan needs more defenders (NPCs call this to decide if they should defend)."""
	return get_current_defender_count() < get_defender_quota()

func is_defender_slot_available() -> bool:
	"""Check if there's room for another defender."""
	return needs_more_defenders()

func force_defend_all() -> void:
	"""Emergency: set quota to 100% of fighters."""
	if land_claim:
		land_claim.set_meta("defender_quota", cavemen.size())
		land_claim.set_meta("defender_pressure", 1.0)
		print("🛡️ ClanBrain %s: EMERGENCY - all fighters to defend!" % clan_name)

func start_player_emergency_defend() -> void:
	"""Player clicked DEFEND on land claim dropdown (last resort). Keep everyone defending until PLAYER_EMERGENCY_DEFEND_COOLDOWN seconds since last intrusion."""
	player_emergency_defend = true
	last_intrusion_time = Time.get_ticks_msec() / 1000.0
	if land_claim:
		land_claim.set_meta("defender_quota", cavemen.size())
		land_claim.set_meta("defender_pressure", 1.0)
		land_claim._prune_defenders()
	print("🛡️ ClanBrain %s: Player emergency defend - defenders stay until %.0fs since last intrusion" % [clan_name, PLAYER_EMERGENCY_DEFEND_COOLDOWN])

# === Phase 3: Raiding System ===
# Pull-based: ClanBrain sets raid intent, NPCs discover and self-organize

# Raid configuration
const MIN_RAID_PARTY_SIZE: int = 2
const MAX_RAID_PARTY_SIZE: int = 8
const MIN_DEFENDERS_DURING_RAID: float = 0.3  # Keep 30% defending during raids
const RAID_COOLDOWN: float = 60.0  # Seconds between raids
const RAID_DISTANCE_MAX: float = 1500.0  # Max distance to consider for raid targets

# Raid intent (NPCs read this to decide if they should join)
enum RaidState { NONE, RECRUITING, ACTIVE, RETREATING }
var raid_intent: Dictionary = {
	"state": RaidState.NONE,
	"target": null,  # Enemy land claim to raid
	"target_position": Vector2.ZERO,
	"rally_point": Vector2.ZERO,
	"raider_quota": 0,  # How many raiders we want
	"start_time": 0.0
}
var _last_raid_time: float = -RAID_COOLDOWN  # Allow immediate first raid
var _raid_pressure: float = 0.0  # How much we want to raid (0.0 - 1.0)

func _evaluate_raid_opportunity() -> void:
	"""Evaluate if we should organize a raid using score-based multi-signal approach."""
	# Don't raid if already raiding
	if raid_intent["state"] != RaidState.NONE:
		return
	
	# Don't raid during high alert (we're being attacked)
	if alert_level >= AlertLevel.SKIRMISH:
		_raid_pressure = 0.0
		return
	
	# Check cooldown
	var current_time: float = Time.get_ticks_msec() / 1000.0
	if current_time - _last_raid_time < RAID_COOLDOWN:
		return
	
	# Don't raid with too few fighters
	if cavemen.size() < MIN_RAID_PARTY_SIZE + 1:  # Need at least 1 defender
		return
	
	# Safety gate: ensure defense quota is satisfied AFTER raid party leaves
	var defender_quota: int = get_defender_quota()
	var available_for_raid: int = cavemen.size() - defender_quota
	if available_for_raid < MIN_RAID_PARTY_SIZE:
		return
	
	# === Score-based multi-signal raid evaluation ===
	# Multiple weak signals compose into a raid decision
	var score: float = 0.0
	
	# 1. Food pressure (starving clans raid)
	var food_ratio: float = _calculate_food_ratio()
	if food_ratio < raid_hunger_threshold:
		score += clampf(1.0 - food_ratio, 0.0, 1.0) * 0.4
	
	# 2. Population pressure (too many mouths)
	var population_ratio: float = float(clan_members.size()) / 10.0  # Normalize to ~10 members
	score += clampf(population_ratio, 0.0, 1.0) * raid_population_pressure * 0.3
	
	# 3. Aggression personality (hostile clans raid even when stable)
	score += raid_aggression * 0.3
	
	# 4. Opportunity (weak nearby enemy)
	var weak_enemy: Node = _find_weak_enemy()
	var food_contrib: float = 0.0
	if food_ratio < raid_hunger_threshold:
		food_contrib = clampf(1.0 - food_ratio, 0.0, 1.0) * 0.4
	var population_contrib: float = clampf(population_ratio, 0.0, 1.0) * raid_population_pressure * 0.3
	var aggression_contrib: float = raid_aggression * 0.3
	var weak_enemy_contrib: float = raid_opportunity_weight if weak_enemy else 0.0
	var state_contrib: float = 0.0
	if strategic_state == StrategicState.AGGRESSIVE:
		state_contrib = 0.2
	elif strategic_state == StrategicState.DEFENSIVE:
		state_contrib = -0.3
	if weak_enemy:
		score += raid_opportunity_weight
	
	# 5. Strategic state modifier
	if strategic_state == StrategicState.AGGRESSIVE:
		score += 0.2
	elif strategic_state == StrategicState.DEFENSIVE:
		score -= 0.3
	
	# Store for debugging
	_raid_pressure = clampf(score, 0.0, 2.0)
	
	# Playtest instrumentation: emit raid_evaluated when capture enabled (raid test or normal play)
	var tree = land_claim.get_tree() if land_claim else null
	if tree:
		var pi = tree.root.get_node_or_null("PlaytestInstrumentor")
		if pi and pi.is_enabled() and pi.has_method("raid_evaluated"):
			var breakdown: Dictionary = {
				"food_contrib": food_contrib,
				"population_contrib": population_contrib,
				"aggression_contrib": aggression_contrib,
				"weak_enemy_contrib": weak_enemy_contrib,
				"state_contrib": state_contrib
			}
			pi.raid_evaluated(clan_name, score, breakdown)
	
	# Decide to raid if score is high enough (threshold = 1.0)
	if score >= 1.0:
		var target: Node = weak_enemy if weak_enemy else _find_best_raid_target()
		if target:
			print("⚔️ ClanBrain %s: Raid score %.2f >= 1.0, starting raid" % [clan_name, score])
			_start_raid(target)
		else:
			print("⚔️ ClanBrain %s: Raid score >= 1.0 but no valid target — block: no_weak_enemy" % clan_name)

func _find_weak_enemy() -> Node:
	"""Find an enemy land claim that has fewer defenders than we have raiders available."""
	var best_target: Node = null
	var best_score: float = 0.0
	
	for enemy_claim in nearby_enemy_claims:
		if not is_instance_valid(enemy_claim):
			continue
		
		# Calculate enemy strength
		var enemy_defenders: int = enemy_claim.assigned_defenders.size() if "assigned_defenders" in enemy_claim else 0
		var enemy_strength: int = _count_enemy_fighters(enemy_claim)
		
		# Calculate our available raid force (keep defenders)
		var defender_quota: int = get_defender_quota()
		var available_raiders: int = cavemen.size() - defender_quota
		
		# Skip if enemy is too strong
		if enemy_strength > available_raiders * 1.5:
			continue
		
		# Score based on weakness and distance
		var distance: float = land_claim.global_position.distance_to(enemy_claim.global_position)
		if distance > RAID_DISTANCE_MAX:
			continue
		
		var weakness_score: float = float(available_raiders - enemy_defenders) / maxf(1.0, float(available_raiders))
		var distance_score: float = 1.0 - (distance / RAID_DISTANCE_MAX)
		var score: float = weakness_score * 0.6 + distance_score * 0.4
		
		if score > best_score:
			best_score = score
			best_target = enemy_claim
	
	return best_target

func _find_best_raid_target() -> Node:
	"""Find the best raid target based on multiple factors."""
	return _find_weak_enemy()  # For now, same logic

func _start_raid(target: Node) -> void:
	"""Set raid intent - NPCs will discover this and self-organize."""
	if not target or not is_instance_valid(target):
		return
	
	var target_clan: String = target.get("clan_name") if "clan_name" in target else "enemy"
	print("⚔️ ClanBrain %s: Setting raid intent against %s" % [clan_name, target_clan])
	
	# Calculate raider quota (fighters not needed for defense)
	var defender_quota: int = get_defender_quota()
	var raider_quota: int = mini(MAX_RAID_PARTY_SIZE, cavemen.size() - defender_quota)
	
	if raider_quota < MIN_RAID_PARTY_SIZE:
		print("⚔️ ClanBrain %s: Not enough fighters for raid (need %d, have %d available)" % [
			clan_name, MIN_RAID_PARTY_SIZE, raider_quota
		])
		return
	
	# Calculate rally point (between our claim and target)
	var target_pos: Vector2 = target.global_position
	var our_pos: Vector2 = land_claim.global_position
	var rally_point: Vector2 = our_pos + (target_pos - our_pos).normalized() * (land_claim.radius + 50.0)
	
	# Set raid intent - NPCs will read this
	raid_intent["state"] = RaidState.RECRUITING
	raid_intent["target"] = target
	raid_intent["target_position"] = target_pos
	raid_intent["rally_point"] = rally_point
	raid_intent["raider_quota"] = raider_quota
	raid_intent["start_time"] = Time.get_ticks_msec() / 1000.0
	
	_last_raid_time = Time.get_ticks_msec() / 1000.0
	strategic_state = StrategicState.RAIDING
	
	# Raid test instrumentation
	var tree = land_claim.get_tree() if land_claim else null
	if tree:
		var pi = tree.root.get_node_or_null("PlaytestInstrumentor")
		if pi and pi.is_enabled() and pi.has_method("raid_started"):
			pi.raid_started(clan_name, target_clan)
	
	# Store intent on land claim so NPCs can discover it
	if land_claim:
		land_claim.set_meta("raid_intent", raid_intent.duplicate())
	
	_form_raid_party(raider_quota)

func _update_raid() -> void:
	"""Update raid intent state based on NPC progress."""
	if raid_intent["state"] == RaidState.NONE:
		return
	
	# Check if target is still valid
	var target: Node = raid_intent["target"]
	if not target or not is_instance_valid(target):
		_complete_raid("target_destroyed")
		return
	
	# Hardening: target ownership changed (now friendly) - cancel raid
	if target.get("clan_name") == clan_name:
		_complete_raid("target_now_friendly")
		return
	
	# Count raiders who have joined (via land claim pool or meta)
	var raider_count: int = _count_active_raiders()
	
	match raid_intent["state"]:
		RaidState.RECRUITING:
			# Wait for raiders to join, then advance to ACTIVE
			if raider_count >= MIN_RAID_PARTY_SIZE:
				raid_intent["state"] = RaidState.ACTIVE
				if land_claim:
					land_claim.set_meta("raid_intent", raid_intent.duplicate())
				print("⚔️ ClanBrain %s: Raid active with %d raiders" % [clan_name, raider_count])
			else:
				# Timeout after 30 seconds of recruiting
				var elapsed: float = (Time.get_ticks_msec() / 1000.0) - raid_intent["start_time"]
				if elapsed > 30.0:
					_cancel_raid("recruitment_timeout")
		
		RaidState.ACTIVE:
			# Check if all enemies defeated
			var enemy_fighters: int = _count_enemy_fighters(target)
			if enemy_fighters == 0:
				raid_intent["state"] = RaidState.RETREATING
				if land_claim:
					land_claim.set_meta("raid_intent", raid_intent.duplicate())
				print("⚔️ ClanBrain %s: Enemies defeated, retreat intent set" % clan_name)
			# Check if we lost too many raiders
			elif raider_count < MIN_RAID_PARTY_SIZE:
				_cancel_raid("raiders_lost")
		
		RaidState.RETREATING:
			# NPCs will read this and return home
			# Complete raid after some time
			var elapsed: float = (Time.get_ticks_msec() / 1000.0) - raid_intent["start_time"]
			if elapsed > 60.0:  # 60 seconds total raid time max
				_complete_raid("timeout")

func _count_active_raiders() -> int:
	"""Count NPCs who have joined the raid (by checking their meta)."""
	var count: int = 0
	for npc in cavemen:
		if not is_instance_valid(npc):
			continue
		if npc.has_meta("raid_joined") and npc.get_meta("raid_joined") == true:
			count += 1
	return count

func _complete_raid(reason: String) -> void:
	"""Complete the current raid - clear intent."""
	print("⚔️ ClanBrain %s: Raid completed (%s)" % [clan_name, reason])
	_disband_raid_party(reason)
	
	# Explicit cleanup: remove raid_joined meta from all raiders
	for npc in cavemen:
		if is_instance_valid(npc) and npc.has_meta("raid_joined") and npc.get_meta("raid_joined") == true:
			npc_leave_raid(npc)
	
	# Reset raid intent
	raid_intent["state"] = RaidState.NONE
	raid_intent["target"] = null
	raid_intent["target_position"] = Vector2.ZERO
	raid_intent["rally_point"] = Vector2.ZERO
	raid_intent["raider_quota"] = 0
	
	# Clear intent from land claim
	if land_claim:
		land_claim.remove_meta("raid_intent")
	
	# Return to recovering state
	if strategic_state == StrategicState.RAIDING:
		strategic_state = StrategicState.RECOVERING

func _cancel_raid(reason: String) -> void:
	"""Cancel the current raid."""
	print("⚔️ ClanBrain %s: Raid cancelled (%s)" % [clan_name, reason])
	var tree = land_claim.get_tree() if land_claim else null
	if tree:
		var pi = tree.root.get_node_or_null("PlaytestInstrumentor")
		if pi and pi.is_enabled() and pi.has_method("raid_aborted"):
			pi.raid_aborted(clan_name, reason)
	_complete_raid(reason)

func is_raiding() -> bool:
	"""Check if a raid is in progress."""
	return raid_intent["state"] != RaidState.NONE

func get_raid_state() -> int:
	"""Get current raid state."""
	return raid_intent["state"]

func get_raid_intent() -> Dictionary:
	"""Get raid intent for NPCs to read."""
	return raid_intent

# === Pull-based API for NPCs ===

func should_npc_raid(npc: Node) -> bool:
	"""Check if an NPC should join the raid (NPC calls this)."""
	if raid_intent["state"] == RaidState.NONE:
		return false
	if not npc or not is_instance_valid(npc):
		return false
	
	# Don't raid if defending
	if land_claim and npc in land_claim.assigned_defenders:
		return false
	
	# Check if quota is met
	var current_raiders: int = _count_active_raiders()
	if current_raiders >= raid_intent["raider_quota"]:
		return false  # Quota full
	
	return true

func npc_join_raid(npc: Node) -> void:
	"""NPC joins the raid (NPC calls this when deciding to raid)."""
	if not npc or not is_instance_valid(npc):
		return
	npc.set_meta("raid_joined", true)

func npc_leave_raid(npc: Node) -> void:
	"""NPC leaves the raid (on death, flee, etc)."""
	if not npc or not is_instance_valid(npc):
		return
	npc.remove_meta("raid_joined")

func get_raid_target_position() -> Vector2:
	"""Get the raid target position (NPCs call this for navigation)."""
	return raid_intent["target_position"]

func get_raid_rally_point() -> Vector2:
	"""Get the raid rally point (NPCs call this for assembly)."""
	return raid_intent["rally_point"]


func _form_raid_party(max_raiders: int) -> void:
	"""NPC-led party: first non-defender fighter is leader; rest follow in party state (same as player formations)."""
	if not land_claim:
		return
	var candidates: Array = []
	for n in cavemen:
		if not is_instance_valid(n):
			continue
		if n in land_claim.assigned_defenders:
			continue
		var nt: String = str(n.get("npc_type")) if n.get("npc_type") != null else ""
		if nt != "caveman" and nt != "clansman":
			continue
		candidates.append(n)
	var total: int = mini(max_raiders, candidates.size())
	if total < 2:
		return
	var leader: Node = candidates[0]
	var followers: Array = []
	for i in range(1, total):
		followers.append(candidates[i])
	land_claim.set_meta("raid_party_leader", leader)
	land_claim.set_meta("raid_party_followers", followers.duplicate())
	leader.set("is_hostile", true)
	var lname: String = str(leader.get("npc_name")) if leader.get("npc_name") != null else str(leader.name)
	npc_join_raid(leader)
	for f in followers:
		if not is_instance_valid(f):
			continue
		f.set("is_herded", true)
		f.set("herder", leader)
		f.set("follow_is_ordered", true)
		f.set("herd_mentality_active", true)
		if f.has_method("set_follow_mode_from_string"):
			f.set_follow_mode_from_string("FOLLOW")
		PartyCommandUtils.apply_context_to_follower(leader, f)
		if HerdManager:
			HerdManager.register_follower(leader, f)
		var fsm = f.get_node_or_null("FSM")
		if fsm and fsm.has_method("change_state"):
			fsm.evaluation_timer = 0.0
			fsm.change_state("party")
		npc_join_raid(f)
	var tree = land_claim.get_tree() if land_claim else null
	if tree:
		var pi = tree.root.get_node_or_null("PlaytestInstrumentor")
		if pi and pi.is_enabled() and pi.has_method("party_formed"):
			pi.party_formed(lname, followers.size(), "raid_start")


func _disband_raid_party(reason: String) -> void:
	if not land_claim or not land_claim.has_meta("raid_party_leader"):
		return
	var leader: Node = land_claim.get_meta("raid_party_leader") as Node
	var followers: Array = land_claim.get_meta("raid_party_followers", []) as Array
	land_claim.remove_meta("raid_party_leader")
	land_claim.remove_meta("raid_party_followers")
	var lname: String = ""
	if leader and is_instance_valid(leader):
		lname = str(leader.get("npc_name")) if leader.get("npc_name") != null else str(leader.name)
		if leader.has_meta("formation_slots"):
			leader.remove_meta("formation_slots")
		if leader.has_meta("formation_velocity"):
			leader.remove_meta("formation_velocity")
		leader.set_meta("formation_speed_mult", 1.0)
	for f in followers:
		if not is_instance_valid(f):
			continue
		if HerdManager and leader and is_instance_valid(leader):
			HerdManager.unregister_follower(leader, f)
		f.set("follow_is_ordered", false)
		f.set("is_herded", false)
		f.set("herder", null)
		f.set("herd_mentality_active", false)
		var fsm = f.get_node_or_null("FSM")
		if fsm:
			fsm.evaluation_timer = 0.0
	var tree = land_claim.get_tree() if land_claim else null
	if tree:
		var pi = tree.root.get_node_or_null("PlaytestInstrumentor")
		if pi and pi.is_enabled() and pi.has_method("party_disbanded") and lname != "":
			pi.party_disbanded(lname, reason)

# === Phase 4: Strategic AI Enhancements ===

# Search/herd system
# Note: Searchers are tracked in land_claim.assigned_searchers
# ClanBrain sets quotas, NPCs self-assign by calling land_claim.add_searcher(self)

func _update_searcher_assignments() -> void:
	"""Update searcher quota - NPCs will pull this and self-assign."""
	if not land_claim:
		return
	if cavemen.size() == 0:
		land_claim.set_meta("searcher_quota", 0)
		land_claim.set_meta("max_active_herders", 0)
		land_claim.set_meta("reproduction_pressure", 0.0)
		land_claim.set_meta("defenders_can_search", false)
		land_claim._prune_searchers()
		return

	# Don't search while raiding or under attack
	if strategic_state == StrategicState.RAIDING or alert_level >= AlertLevel.SKIRMISH:
		land_claim.set_meta("searcher_quota", 0)
		land_claim.set_meta("max_active_herders", 0)
		land_claim.set_meta("defenders_can_search", false)
		return

	# Reproduction pressure (0-1): drives search radius, persistence, herder cap
	var pressure: float = get_reproduction_pressure()
	land_claim.set_meta("reproduction_pressure", pressure)
	# breeding_females: states use this to force herd-search when 0 (caveman MUST get a woman)
	land_claim.set_meta("breeding_females", clan_metrics["breeding_females"])

	# Cap active herders: 1 + pop/6 (prevents swarm, preserves competition)
	var max_herders: int = get_max_active_herders()

	# Population maxing: when we need women, more searchers (capped by max_herders)
	var bf: int = clan_metrics["breeding_females"]
	var target_searchers: int
	if bf < 2:
		target_searchers = cavemen.size()
	else:
		target_searchers = int(ceil(cavemen.size() * search_pressure))
		target_searchers = clampi(target_searchers, 1, cavemen.size())
		if cavemen.size() >= 2:
			target_searchers = maxi(target_searchers, 2)
		target_searchers = clampi(target_searchers, 1, cavemen.size())
	target_searchers = mini(target_searchers, max_herders)

	# Small clan optimization: defenders can also search (no exclusive roles)
	var defenders_can_search: bool = cavemen.size() <= 3

	# Store quota on land claim - NPCs will read this
	land_claim.set_meta("searcher_quota", target_searchers)
	land_claim.set_meta("max_active_herders", max_herders)
	land_claim.set_meta("searcher_pressure", search_pressure)
	land_claim.set_meta("defenders_can_search", defenders_can_search)
	
	# Prune invalid searchers from pool
	land_claim._prune_searchers()

func get_searcher_quota() -> int:
	"""Get how many searchers the clan needs."""
	if not land_claim:
		return 0
	return land_claim.get_meta("searcher_quota", 0)

func get_current_searcher_count() -> int:
	"""Get how many NPCs are currently searching (from pool)."""
	if not land_claim:
		return 0
	land_claim._prune_searchers()
	return land_claim.assigned_searchers.size()

func needs_more_searchers() -> bool:
	"""Check if clan needs more searchers (NPCs call this)."""
	return get_current_searcher_count() < get_searcher_quota()

func is_searcher_slot_available() -> bool:
	"""Check if there's room for another searcher."""
	return needs_more_searchers()

# Gathering priorities

func get_gathering_priorities() -> Array:
	"""Get list of resource types to prioritize gathering, in order of urgency."""
	var priorities: Array = []
	
	# First: critical resources (below critical threshold)
	for key in resource_status:
		var status = resource_status[key]
		if status["current"] < status["critical"]:
			priorities.append(key)
	
	# Second: below target (but not critical)
	for key in resource_status:
		if key in priorities:
			continue
		var status = resource_status[key]
		if status["current"] < status["target"]:
			priorities.append(key)
	
	return priorities

func get_most_needed_resource() -> String:
	"""Get the resource type we need most urgently."""
	var priorities: Array = get_gathering_priorities()
	if priorities.size() > 0:
		return priorities[0]
	return ""

# Strategic planning helpers

func should_expand() -> bool:
	"""Check if clan should consider expanding (placing new buildings, etc.)."""
	# Expand when: peaceful, resources healthy, clan size reasonable
	if strategic_state != StrategicState.PEACEFUL:
		return false
	if _calculate_resource_urgency() > 0.3:
		return false
	if clan_members.size() < 3:
		return false
	return true

func should_search_for_npcs() -> bool:
	"""Check if clan should actively search for wild NPCs to recruit."""
	# Search when: clan is small, not under attack, resources ok
	if alert_level >= AlertLevel.INTRUDER:
		return false
	if clan_members.size() >= 10:  # Big enough
		return false
	return true

# === Reproduction Pressure System ===
# Continuous pressure (0.0-1.0) - clans always want women when below desired ratio.
# No binary emergency mode. Scales naturally with population.

func get_reproduction_pressure() -> float:
	"""How much the clan needs women (0.0 = fine, 1.0 = critical). Scales with population."""
	var population: int = clan_metrics["population"]
	var women: int = clan_metrics["breeding_females"]
	var desired_women: int = maxi(2, int(population * 0.4))
	if desired_women <= 0:
		return 0.0
	return clampf(float(desired_women - women) / float(desired_women), 0.0, 1.0)

func get_max_active_herders() -> int:
	"""Max NPCs allowed in herd_wildnpc at once. Prevents swarm, preserves competition.
	When breeding_females < 2, allow more herders (2 + pop/4) for faster population growth."""
	var bf: int = clan_metrics["breeding_females"]
	if bf < 2:
		return maxi(2, 2 + int(clan_metrics["population"] / 4))
	return 1 + int(clan_metrics["population"] / 6)

func get_clan_strength() -> float:
	"""Get overall clan strength (0.0 - 1.0) based on fighters, resources, state."""
	var strength: float = 0.0
	
	# Fighter count contributes 40%
	var fighter_score: float = clampf(cavemen.size() / 5.0, 0.0, 1.0)
	strength += fighter_score * 0.4
	
	# Resource health contributes 30%
	var resource_score: float = 1.0 - _calculate_resource_urgency()
	strength += resource_score * 0.3
	
	# Clan member count contributes 20%
	var member_score: float = clampf(clan_members.size() / 10.0, 0.0, 1.0)
	strength += member_score * 0.2
	
	# Strategic state contributes 10%
	var state_score: float = 0.5
	match strategic_state:
		StrategicState.PEACEFUL:
			state_score = 1.0
		StrategicState.DEFENSIVE:
			state_score = 0.6
		StrategicState.AGGRESSIVE:
			state_score = 0.8
		StrategicState.RAIDING:
			state_score = 0.7
		StrategicState.RECOVERING:
			state_score = 0.3
	strength += state_score * 0.1
	
	return clampf(strength, 0.0, 1.0)

func get_debug_info() -> Dictionary:
	"""Get debug information about the clan brain state."""
	return {
		"clan_name": clan_name,
		"strategic_state": StrategicState.keys()[strategic_state],
		"alert_level": AlertLevel.keys()[alert_level],
		"threat_level": threat_level,
		"clan_strength": get_clan_strength(),
		"clan_members": clan_members.size(),
		"cavemen": cavemen.size(),
		"defender_quota": get_defender_quota(),
		"defender_count": get_current_defender_count(),
		"searcher_quota": get_searcher_quota(),
		"searcher_count": get_current_searcher_count(),
		"defend_pressure": defend_pressure,
		"search_pressure": search_pressure,
		"gather_pressure": gather_pressure,
		"raid_state": RaidState.keys()[raid_intent["state"]],
		"raider_quota": raid_intent["raider_quota"],
		"raider_count": _count_active_raiders(),
		"resource_status": resource_status.duplicate(),
		"nearby_enemies": nearby_enemy_claims.size()
	}
