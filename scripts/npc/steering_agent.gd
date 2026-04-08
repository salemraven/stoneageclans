extends Node
class_name SteeringAgent

# Steering behaviors for NPC movement
# Implements: seek, arrive, separate, flee

var npc: Node = null
var target_position: Vector2 = Vector2.ZERO
var target_node: Node2D = null
var max_speed: float = 115.0  # Default (smoother; see guides/Phase4/config.md)
var original_max_speed: float = 115.0  # Store original speed to restore later
var max_force: float = 45.0  # Further reduced for smoother, more natural movement
var arrive_radius: float = 60.0  # Larger radius for smoother stopping
var separation_radius: float = 64.0

# Steering weights
var seek_weight: float = 1.0
var arrive_weight: float = 1.0
var separate_weight: float = 1.5
var flee_weight: float = 1.0

# Current steering mode
enum SteeringMode {
	SEEK,
	ARRIVE,
	FLEE,
	WANDER
}
var current_mode: SteeringMode = SteeringMode.WANDER

# Wander properties
var wander_radius: float = 200.0
var wander_center: Vector2 = Vector2.ZERO
var wander_target: Vector2 = Vector2.ZERO
var wander_change_time: float = 0.0
var wander_change_interval: float = 3.0

# Pathfinding stuck detection
var last_position: Vector2 = Vector2.ZERO
var stuck_check_time: float = 0.0
var stuck_threshold: float = 1.0  # Seconds before considered stuck (faster detection for quicker recovery)
var stuck_distance_threshold: float = 50.0  # Pixels - if moved less than this, might be stuck
var pathfinding_attempts: int = 0  # Track how many land claims we're trying to navigate around
var max_pathfinding_attempts: int = 4  # If blocked by this many land claims, give up and go different direction (increased for better pathfinding)

# Efficient oscillation prevention - prevent at source instead of detecting after
var last_target_change_time: float = 0.0
var min_target_change_interval: float = 0.5  # Minimum time between target changes
var last_velocity: Vector2 = Vector2.ZERO  # Track last velocity to detect direction reversals
var velocity_reversal_count: int = 0  # Count rapid velocity reversals
var last_force_direction: Vector2 = Vector2.ZERO  # Track force direction to prevent conflicting forces
var force_dead_zone: float = 5.0  # Forces below this threshold are ignored (prevents micro-movements)

# Phase 3: Per-frame cached NPC traits (avoid repeated npc.get() calls in loops)
var _cached: Dictionary = {}  # Refreshed once per get_steering_force() call

# Phase 3 Part B: Movement feel
var _pending_target_pos: Vector2 = Vector2.ZERO
var _pending_target_node: Node2D = null
var _pending_mode: SteeringMode = SteeringMode.WANDER
var _pending_intent_time: float = 0.0
var _intent_delay: float = 0.0  # Randomized per NPC in initialize()
const INTENT_DELAY_MIN: float = 0.1
const INTENT_DELAY_MAX: float = 0.3
const ARRIVAL_OFFSET_RANGE: float = 6.0  # ±6px random offset for arrival targets

func initialize(npc_ref: Node) -> void:
	npc = npc_ref
	
	if npc and npc.stats_component:
		var agility: float = npc.stats_component.get_stat("agility")
		# All NPCs use agility multiplier for smoother, consistent movement
		if NPCConfig:
			var speed_mult = NPCConfig.get("speed_agility_multiplier")
			if speed_mult != null:
				max_speed = agility * (speed_mult as float)
			else:
				max_speed = NPCConfig.max_speed_base
		else:
			max_speed = 95.0  # Fallback (NPCConfig.max_speed_base)
		# Apply config values for steering (all NPCs get smoother movement)
		if NPCConfig:
			max_force = NPCConfig.max_force if "max_force" in NPCConfig else 40.0
			arrive_radius = NPCConfig.arrive_radius if "arrive_radius" in NPCConfig else 100.0
	else:
		# Fallback: use reduced base speed (one-third slower)
		max_speed = 95.0
	original_max_speed = max_speed  # Store original speed
	wander_center = npc.global_position if npc else Vector2.ZERO
	wander_target = _get_random_wander_point()
	
	# Phase 3 Part B: Randomize intent delay per NPC (100-300ms)
	_intent_delay = randf_range(INTENT_DELAY_MIN, INTENT_DELAY_MAX)
	_pending_intent_time = 0.0

func _apply_arrival_offset(pos: Vector2) -> Vector2:
	"""Add small random offset so NPCs don't stop perfectly on spot (foot shuffle)."""
	return pos + Vector2(randf_range(-ARRIVAL_OFFSET_RANGE, ARRIVAL_OFFSET_RANGE), randf_range(-ARRIVAL_OFFSET_RANGE * 0.5, ARRIVAL_OFFSET_RANGE * 0.5))

func _commit_pending_target() -> void:
	"""Commit pending target after intent delay."""
	target_position = _pending_target_pos
	target_node = _pending_target_node
	current_mode = _pending_mode
	velocity_reversal_count = 0
	last_force_direction = Vector2.ZERO
	last_velocity = Vector2.ZERO
	_pending_intent_time = 0.0  # Clear pending

func set_target_position(pos: Vector2) -> void:
	var current_time: float = Time.get_ticks_msec() / 1000.0
	# Bypass throttle for sheep/goats heading to Farm/Dairy - they need immediate response
	var ab = OccupationSystem.get_workplace(npc) if (OccupationSystem and npc) else null
	var has_building_target: bool = ab != null and is_instance_valid(ab)
	if not has_building_target and current_time - last_target_change_time < min_target_change_interval:
		return
	
	last_target_change_time = current_time
	# Building targets: commit immediately. Others: intent delay to prevent oscillation.
	if has_building_target:
		target_position = pos
		target_node = null
		current_mode = SteeringMode.SEEK
		_pending_intent_time = 0.0
		velocity_reversal_count = 0
		stuck_check_time = 0.0
		pathfinding_attempts = 0
	else:
		_pending_target_pos = pos
		_pending_target_node = null
		_pending_mode = SteeringMode.SEEK
		_pending_intent_time = current_time + _intent_delay
	_log_steering_change("SEEK", "position", pos)

func set_target_position_immediate(pos: Vector2) -> void:
	"""Commit target immediately with full reset. Caller explicitly opts in - no inference of urgency."""
	target_position = pos
	target_node = null
	current_mode = SteeringMode.SEEK
	_pending_target_pos = pos
	_pending_target_node = null
	_pending_mode = SteeringMode.SEEK
	_pending_intent_time = 0.0
	last_target_change_time = Time.get_ticks_msec() / 1000.0
	velocity_reversal_count = 0
	last_force_direction = Vector2.ZERO
	last_velocity = Vector2.ZERO
	pathfinding_attempts = 0
	stuck_check_time = 0.0
	if npc:
		npc.velocity = Vector2.ZERO
	_log_steering_change("SEEK", "position_immediate", pos)

func set_target_node(node: Node2D) -> void:
	var current_time: float = Time.get_ticks_msec() / 1000.0
	if node and is_instance_valid(node):
		# Phase 3 Part B: Intent delay for target node
		_pending_target_pos = node.global_position
		_pending_target_node = node
		_pending_mode = SteeringMode.SEEK
		_pending_intent_time = current_time + _intent_delay
		pathfinding_attempts = 0
		stuck_check_time = 0.0
		_log_steering_change("SEEK", str(node.name) if node else "unknown", node.global_position)
	else:
		# Immediate commit when clearing target
		target_node = null
		target_position = Vector2.ZERO
		current_mode = SteeringMode.WANDER
		_pending_intent_time = 0.0
		_log_steering_change("WANDER", "none", Vector2.ZERO)

func set_arrive_target(pos: Vector2) -> void:
	# CRITICAL: Prevent rapid target switching that causes oscillation
	var current_time: float = Time.get_ticks_msec() / 1000.0
	if current_time - last_target_change_time < min_target_change_interval:
		return
	
	last_target_change_time = current_time
	# Phase 3 Part B: Intent delay + random arrival offset (foot shuffle)
	var offset_pos: Vector2 = _apply_arrival_offset(pos)
	_pending_target_pos = offset_pos
	_pending_target_node = null
	_pending_mode = SteeringMode.ARRIVE
	_pending_intent_time = current_time + _intent_delay

# Set a temporary speed multiplier (for deposit movement, etc.)
func set_speed_multiplier(multiplier: float) -> void:
	max_speed = original_max_speed * multiplier

# Restore original speed
func restore_original_speed() -> void:
	max_speed = original_max_speed

func set_flee_target(pos: Vector2) -> void:
	# Flee is immediate - no intent delay (urgency)
	target_position = pos
	target_node = null
	current_mode = SteeringMode.FLEE
	_pending_intent_time = 0.0  # Clear any pending
	_log_steering_change("FLEE", "position", pos)

func set_wander(center: Vector2, radius: float) -> void:
	wander_center = center
	wander_radius = radius
	current_mode = SteeringMode.WANDER
	target_node = null
	_pending_intent_time = 0.0  # Clear any pending
	wander_target = _get_random_wander_point()
	# Reset stuck detection when switching to wander
	pathfinding_attempts = 0
	stuck_check_time = 0.0
	# Reset oscillation prevention when switching to wander
	velocity_reversal_count = 0
	last_force_direction = Vector2.ZERO
	last_velocity = Vector2.ZERO
	last_target_change_time = Time.get_ticks_msec() / 1000.0
	_log_steering_change("WANDER", "center", center, {"radius": "%.1f" % radius})

func _log_steering_change(behavior: String, target: String, position: Vector2, details: Dictionary = {}) -> void:
	if npc:
		# Phase 3: Use cached npc_name if available, else fallback to npc.get()
		var npc_name: String = _cached.get("npc_name", npc.get("npc_name") if npc else "unknown")
		var log_details: Dictionary = {
			"position": "%.1f,%.1f" % [position.x, position.y]
		}
		log_details.merge(details)
		var final_details := {
			"npc": npc_name,
			"behavior": behavior,
			"target": target
		}
		final_details.merge(log_details)
		UnifiedLogger.log_npc("Steering behavior: %s - %s" % [behavior, target], final_details, UnifiedLogger.Level.DEBUG)

func _refresh_cached_traits() -> void:
	# Phase 3: Cache NPC traits once per frame to avoid repeated npc.get() in loops
	if not npc:
		_cached.clear()
		return
	
	# Basic identity
	_cached.npc_name = npc.get("npc_name") if npc else "unknown"
	var npc_type_prop = npc.get("npc_type")
	_cached.npc_type = npc_type_prop as String if npc_type_prop != null else ""
	_cached.is_caveman = _cached.npc_type == "caveman"
	_cached.is_clansman = _cached.npc_type == "clansman"
	_cached.is_mammoth = _cached.npc_type == "mammoth"
	
	# Clan
	var clan_prop = npc.get("clan_name")
	_cached.clan_name = clan_prop as String if clan_prop != null else ""
	_cached.in_clan = _cached.clan_name != ""
	_cached.is_part_of_clan = npc.is_part_of_clan() if npc.has_method("is_part_of_clan") else false
	
	# Herding
	var herded_prop = npc.get("is_herded")
	_cached.is_herded = herded_prop as bool if herded_prop != null else false
	_cached.herder = npc.get("herder") if npc else null
	
	# Traits
	_cached.is_solitary = npc.has_trait("solitary") if npc.has_method("has_trait") else false
	
	# FSM state
	_cached.current_state = ""
	if npc.fsm and npc.fsm.has_method("get_current_state_name"):
		_cached.current_state = npc.fsm.get_current_state_name()
	_cached.is_in_herd_mode = _cached.is_herded or _cached.current_state == "herd" or _cached.current_state == "party"
	_cached.is_gathering = _cached.current_state == "gather"
	
	# Position
	_cached.npc_pos = npc.global_position if npc else Vector2.ZERO

func get_steering_force(delta: float = 0.016) -> Vector2:
	# Main steering function - combines all steering behaviors
	# delta: time since last frame (defaults to ~60fps if not provided)
	if not npc:
		return Vector2.ZERO
	
	# Phase 3: Refresh cached traits once per frame
	_refresh_cached_traits()
	
	# Phase 3 Part B: Intent delay - commit pending target when timer expires
	var current_time: float = Time.get_ticks_msec() / 1000.0
	if _pending_intent_time > 0.0 and current_time >= _pending_intent_time:
		_commit_pending_target()
	
	# Update target position from target_node (if node-based target)
	if target_node and is_instance_valid(target_node):
		target_position = target_node.global_position
	
	# Check if NPC is stuck (not moving much)
	var current_pos: Vector2 = npc.global_position if npc else Vector2.ZERO
	var moved_distance: float = current_pos.distance_to(last_position)
	
	# Update stuck detection
	if moved_distance < stuck_distance_threshold:
		stuck_check_time += delta
	else:
		stuck_check_time = 0.0
		pathfinding_attempts = 0  # Reset if moving
		velocity_reversal_count = 0  # Reset reversal count if moving
		
	last_position = current_pos
	
	# If stuck for too long and trying to pathfind through multiple land claims, give up
	# EXCEPT: Sheep/goats heading to Farm/Dairy - let them keep trying (building re-assigns each frame)
	var ab_stuck = OccupationSystem.get_workplace(npc) if (OccupationSystem and npc) else null
	var has_building_target: bool = ab_stuck != null and is_instance_valid(ab_stuck)
	var is_test_leader: bool = npc and npc.has_meta("agro_combat_test_leader")
	if stuck_check_time > stuck_threshold and pathfinding_attempts >= max_pathfinding_attempts and not has_building_target and not is_test_leader:
		# Too difficult to pathfind - go in a different direction (skip for agro combat test leaders - main drives them)
		if current_mode != SteeringMode.WANDER:
			# Switch to wander mode to break out of stuck state
			set_wander(current_pos, wander_radius)
			pathfinding_attempts = 0
			stuck_check_time = 0.0
			# Phase 3: Use cached npc_name
			var npc_name: String = _cached.get("npc_name", "unknown")
			UnifiedLogger.log_npc("Action failed: pathfind (too_difficult)", {
				"npc": npc_name,
				"action": "pathfind",
				"reason": "too_difficult",
				"land_claims_blocking": str(pathfinding_attempts),
				"stuck_time": "%.1f" % stuck_check_time
			})
	
	var force := Vector2.ZERO
	
	match current_mode:
		SteeringMode.SEEK:
			force = _seek(target_position)
		SteeringMode.ARRIVE:
			force = _arrive(target_position)
		SteeringMode.FLEE:
			force = _flee(target_position)
		SteeringMode.WANDER:
			force = _wander()
	
	# Add separation (but only if we have a force, to avoid canceling out)
	if force.length() > 0.1:
		force += _separate() * separate_weight
	
	# Add land claim avoidance (wild NPCs flee from land claims)
	force += _avoid_land_claims()
	
	# Add boundary force for clan members to keep them inside land claim
	# EXCEPT for cavemen and clansmen - they can leave to gather and deposit items
	# Phase 3: Use cached traits
	if _cached.in_clan and not _cached.is_caveman and not _cached.is_clansman:
		force += _keep_inside_clan_land_claim()
	
	# EFFICIENT OSCILLATION PREVENTION: Dead zone for small forces
	# If force is too small, ignore it completely (prevents micro-movements that cause oscillation)
	# CRITICAL: Don't apply dead zone if NPC is herded (herded NPCs need to follow even with small forces)
	# Phase 3: Use cached traits
	var is_herded: bool = _cached.is_herded
	var is_caveman: bool = _cached.is_caveman
	
	# Apply dead zone to all NPCs (including cavemen) when not herded
	# Cavemen get larger dead zone to prevent oscillation when gathering
	var effective_dead_zone: float = force_dead_zone
	if is_caveman and not is_herded:
		effective_dead_zone = force_dead_zone * 2.0  # Larger dead zone for cavemen (10px instead of 5px)
	
	if not is_herded and force.length() < effective_dead_zone:
		force = Vector2.ZERO
	
	# EFFICIENT OSCILLATION PREVENTION: Detect conflicting force directions
	# If force direction reversed rapidly, it's likely oscillation - stop movement
	# CRITICAL: Don't apply to herded NPCs (they need to follow their leader)
	if not is_herded and force.length() > 0.1 and last_force_direction.length() > 0.1:
		var current_force_dir: Vector2 = force.normalized()
		var last_force_dir: Vector2 = last_force_direction.normalized()
		var dot_product: float = current_force_dir.dot(last_force_dir)
		
		# If force direction reversed (dot product < -0.5), count as reversal
		if dot_product < -0.5:
			velocity_reversal_count += 1
			# If 3+ rapid reversals, stop movement (oscillation detected)
			if velocity_reversal_count >= 3:
				force = Vector2.ZERO
				velocity_reversal_count = 0
		else:
			velocity_reversal_count = 0  # Reset if not reversing
	
	last_force_direction = force  # Store for next frame
	
	# Limit force
	if force.length() > max_force:
		force = force.normalized() * max_force
	
	# Leaders with followers move slower in guard/combat so clansmen protect center
	var effective_max_speed: float = max_speed
	# Carrying travois: move slower (2-handed load)
	if npc and npc.has_method("has_travois") and npc.has_travois():
		effective_max_speed *= 0.7
	var herded_count_val = npc.get("herded_count") if npc else null
	var is_leader_with_followers: bool = npc and herded_count_val != null and int(herded_count_val) > 0
	if is_leader_with_followers and NPCConfig:
		var fsm = npc.get("fsm")
		var in_combat: bool = fsm and fsm.has_method("get_current_state_name") and fsm.get_current_state_name() == "combat"
		var in_guard_formation: bool = npc.has_meta("formation_guard")
		if in_combat or in_guard_formation:
			var mult = NPCConfig.get("leader_speed_multiplier")
			if mult != null:
				effective_max_speed = max_speed * (mult as float)
	
	# Convert to velocity - allow zero velocity if no force (prevents oscillation)
	var desired_velocity: Vector2
	if force.length() > 0.1:
		desired_velocity = force.normalized() * effective_max_speed
		
		# DELIBERATE MOVEMENT: Apply momentum to resist sudden direction changes
		# If NPC is already moving, blend current momentum with desired direction
		if not is_herded and last_velocity.length() > 30.0:
			var current_dir: Vector2 = last_velocity.normalized()
			var desired_dir: Vector2 = desired_velocity.normalized()
			var direction_change: float = current_dir.dot(desired_dir)
			
			# If changing direction significantly, apply momentum resistance
			if direction_change < 0.6:  # More than ~53 degree turn
				var momentum_weight: float = 0.3  # 30% momentum, 70% desired
				var momentum_component: Vector2 = current_dir * last_velocity.length() * momentum_weight
				var desired_component: Vector2 = desired_dir * effective_max_speed * (1.0 - momentum_weight)
				desired_velocity = momentum_component + desired_component
		
		# EFFICIENT OSCILLATION PREVENTION: Detect velocity direction reversals
		# If velocity direction reversed rapidly, it's oscillation - stop
		# CRITICAL: Don't apply to herded NPCs (they need to follow their leader)
		if not is_herded and last_velocity.length() > 10.0 and desired_velocity.length() > 10.0:
			var current_vel_dir: Vector2 = desired_velocity.normalized()
			var last_vel_dir: Vector2 = last_velocity.normalized()
			var vel_dot: float = current_vel_dir.dot(last_vel_dir)
			
			# If velocity reversed (dot product < -0.7), stop to prevent oscillation
			if vel_dot < -0.7:
				desired_velocity = Vector2.ZERO
				# Clear steering target to stop oscillation
				target_node = null
				target_position = current_pos
	else:
		# No force - return zero velocity to allow NPCs to idle in place
		desired_velocity = Vector2.ZERO
	
	last_velocity = desired_velocity  # Store for next frame
	
	return desired_velocity

func _seek(target: Vector2) -> Vector2:
	var desired: Vector2 = target - npc.global_position
	var distance: float = desired.length()
	if distance < 0.1:
		return Vector2.ZERO
	desired = desired.normalized() * max_speed
	var steer: Vector2 = desired - npc.velocity
	return steer * seek_weight

func _arrive(target: Vector2) -> Vector2:
	var desired: Vector2 = target - npc.global_position
	var distance: float = desired.length()
	
	# NATURAL HERDING: Larger dead zone for herded NPCs to prevent oscillation
	# If very close, return zero force to prevent oscillation
	# Phase 3: Use cached is_herded
	var is_herded: bool = _cached.get("is_herded", false)
	
	# Herded NPCs get larger dead zone (20px) to prevent oscillation when in comfort zone
	var dead_zone: float = 20.0 if is_herded else 5.0
	if distance < dead_zone:
		return Vector2.ZERO
	
	# Use smoother multi-stage slowdown for more natural arrival
	var slowdown_radius: float = arrive_radius * 2.0  # Start slowing down earlier (150px default)
	
	if distance < arrive_radius:
		# Close range - strong slowdown with smooth curve
		var speed_factor: float = distance / arrive_radius
		speed_factor = speed_factor * speed_factor  # Quadratic ease-out for smoother deceleration
		var speed: float = max_speed * max(speed_factor, 0.15)  # Minimum 15% speed
		desired = desired.normalized() * speed
	elif distance < slowdown_radius:
		# Medium range - gradual slowdown
		var speed_factor: float = 0.5 + (0.5 * (distance - arrive_radius) / (slowdown_radius - arrive_radius))
		var speed: float = max_speed * speed_factor
		desired = desired.normalized() * speed
	else:
		# Far range - full speed
		desired = desired.normalized() * max_speed
	
	var steer: Vector2 = desired - npc.velocity
	return steer * arrive_weight

func _flee(target: Vector2) -> Vector2:
	var desired: Vector2 = npc.global_position - target
	var distance: float = desired.length()
	if distance > 200.0:  # Too far to flee
		return Vector2.ZERO
	desired = desired.normalized() * max_speed
	var steer: Vector2 = desired - npc.velocity
	return steer * flee_weight

# Phase 3 Item 4: Split separation by intent
func _should_avoid_obstacle(obstacle: Node2D, is_caveman: bool, is_solitary: bool, is_gathering: bool, is_in_herd_mode: bool) -> bool:
	"""Check if this NPC should avoid the given obstacle based on NPC type and role."""
	if is_caveman:
		# Cavemen only avoid other cavemen and players
		var obstacle_type_prop = obstacle.get("npc_type") if obstacle else null
		var obstacle_type: String = obstacle_type_prop as String if obstacle_type_prop != null else ""
		var is_player: bool = obstacle.is_in_group("player")
		return (obstacle_type == "caveman") or is_player
	elif (is_solitary and not is_gathering) or is_in_herd_mode:
		# Solitary NPCs and herd mode NPCs only avoid other NPCs (not buildings/resources)
		return obstacle.is_in_group("npcs")
	else:
		# Regular NPCs: avoid all obstacles
		return true

func _apply_separation_force(diff: Vector2, distance: float, effective_radius: float, multiplier: float) -> Vector2:
	"""Compute separation force given diff vector, distance, radius, and strength multiplier."""
	var min_distance: float = 20.0  # Minimum distance to maintain
	if distance < min_distance:
		# Very close - apply very strong push away force
		var push_strength: float = (min_distance - distance) * 10.0 * multiplier
		return diff.normalized() * push_strength
	else:
		# Normal separation force
		var strength: float = (effective_radius / distance) * multiplier
		return diff.normalized() / distance * strength

func _separate() -> Vector2:
	# Separation behavior:
	# - Regular NPCs: Only separate when arriving/stopping (can walk through each other)
	# - Solitary NPCs: Always separate from other NPCs (avoid close contact), except when gathering
	# - NPCs in herd mode: Always separate from other NPCs to avoid stacking
	# - Cavemen: Always separate from other cavemen and players (maintain distance)
	var separation_force := Vector2.ZERO
	var neighbor_count := 0
	
	# Phase 3: Use cached traits instead of repeated npc.get() calls
	var is_caveman: bool = _cached.get("is_caveman", false)
	var is_solitary: bool = _cached.get("is_solitary", false)
	var is_in_herd_mode: bool = _cached.get("is_in_herd_mode", false)
	var is_gathering: bool = _cached.get("is_gathering", false)
	
	# Determine if this NPC should separate at all
	var should_separate: bool = false
	if is_caveman:
		should_separate = true
	elif is_solitary and not is_gathering:
		should_separate = true
	elif is_in_herd_mode:
		should_separate = true
	else:
		# Regular NPCs only separate when arriving/stopping
		var is_arriving: bool = false
		if current_mode == SteeringMode.ARRIVE:
			var distance_to_target: float = npc.global_position.distance_to(target_position)
			is_arriving = distance_to_target < arrive_radius * 1.5
		elif current_mode == SteeringMode.SEEK:
			var distance_to_target: float = npc.global_position.distance_to(target_position)
			is_arriving = distance_to_target < 32.0
		elif current_mode == SteeringMode.WANDER:
			var distance_to_target: float = npc.global_position.distance_to(wander_target)
			is_arriving = distance_to_target < 50.0
		should_separate = is_arriving
	
	if not should_separate:
		return Vector2.ZERO
	
	# Get nearby obstacles
	var nearby_obstacles := _get_nearby_obstacles()
	
	# For cavemen: also check for players
	if is_caveman:
		var player_nodes := get_tree().get_nodes_in_group("player")
		for player_node in player_nodes:
			if is_instance_valid(player_node):
				nearby_obstacles.append(player_node)
	
	# Compute effective radius and multiplier based on NPC type
	var effective_separation_radius: float = separation_radius
	var separation_multiplier: float = 1.0
	if is_caveman:
		effective_separation_radius = separation_radius * 2.0
		separation_multiplier = 2.5
	elif is_solitary and not is_gathering:
		effective_separation_radius = separation_radius * 1.5
		separation_multiplier = 2.0
	elif is_in_herd_mode:
		effective_separation_radius = separation_radius * 1.2
		separation_multiplier = 1.5
	
	# Phase 3 Item 4: Clean loop using helper functions
	for obstacle in nearby_obstacles:
		var diff: Vector2 = npc.global_position - obstacle.global_position
		var distance: float = diff.length()
		
		if not _should_avoid_obstacle(obstacle, is_caveman, is_solitary, is_gathering, is_in_herd_mode):
			continue
		
		if distance > 0.0 and distance < effective_separation_radius:
			separation_force += _apply_separation_force(diff, distance, effective_separation_radius, separation_multiplier)
			neighbor_count += 1
	
	if neighbor_count > 0:
		separation_force /= neighbor_count
	
	return separation_force

func _wander() -> Vector2:
	# Update wander center to current position (so NPCs don't wander too far)
	# EXCEPT: If NPC is herded, keep wander center fixed (don't update it)
	# This allows herded NPCs to wander around their leader
	# Phase 3: Use cached is_herded
	var is_herded: bool = _cached.get("is_herded", false)
	# Only update wander center if NOT herded (herded NPCs should wander around leader, not drift)
	if npc and not is_herded:
		wander_center = npc.global_position
	
	# Check if wander target is inside a forbidden land claim
	if npc:
		var inside_claim: Dictionary = npc.is_inside_land_claim()
		if not inside_claim.is_empty():
			# Inside a land claim we can't enter, pick a new target outside
			var claim: Node2D = inside_claim.get("land_claim")
			var radius: float = inside_claim.get("radius", 400.0)
			# Pick a point outside the land claim
			var angle := randf() * TAU
			var safe_distance: float = radius + 100.0  # Safe distance outside
			wander_target = claim.global_position + Vector2(cos(angle), sin(angle)) * safe_distance
			wander_change_time = Time.get_ticks_msec() / 1000.0
		else:
			# Check if wander target would be inside a forbidden land claim
			# Phase 3: Use cached land claims
			var main_node = get_node_or_null("/root/Main")
			var land_claims: Array
			if main_node and main_node.has_method("get_cached_land_claims"):
				land_claims = main_node.get_cached_land_claims()
			else:
				land_claims = get_tree().get_nodes_in_group("land_claims")
			for claim in land_claims:
				if not is_instance_valid(claim):
					continue
				var claim_pos: Vector2 = claim.global_position
				var distance_to_claim: float = wander_target.distance_to(claim_pos)
				var claim_radius: float = 400.0
				var radius_prop = claim.get("radius")
				if radius_prop != null:
					claim_radius = radius_prop as float
				
				# If wander target is inside a land claim we can't enter, pick a new one
				if distance_to_claim < claim_radius:
					if not npc.can_enter_land_claim(claim):
						# Pick a new target outside this land claim
						var angle := randf() * TAU
						var safe_distance: float = claim_radius + 100.0
						wander_target = claim_pos + Vector2(cos(angle), sin(angle)) * safe_distance
						wander_change_time = Time.get_ticks_msec() / 1000.0
						break
	
	# Update wander target periodically or when we reach it
	var current_time := Time.get_ticks_msec() / 1000.0
	var distance_to_target: float = npc.global_position.distance_to(wander_target) if npc else INF
	
	if distance_to_target < 50.0 or (current_time - wander_change_time > wander_change_interval):
		wander_target = _get_random_wander_point()
		wander_change_time = current_time
	
	# Seek the wander target with smooth arrival
	return _arrive(wander_target)

func _get_random_wander_point() -> Vector2:
	var angle := randf() * TAU
	var distance := randf() * wander_radius
	var point: Vector2 = wander_center + Vector2(cos(angle), sin(angle)) * distance
	
	# If NPC is part of a clan, restrict wander point to stay inside their land claim
	# EXCEPT for cavemen and clansmen - they can wander outside to gather and herd
	# Phase 3: Use cached traits
	var clan_name: String = _cached.get("clan_name", "")
	var is_caveman: bool = _cached.get("is_caveman", false)
	var is_clansman: bool = _cached.get("is_clansman", false)
	# Only restrict non-caveman, non-clansman NPCs
	if npc and clan_name != "" and not is_caveman and not is_clansman:
			# Find the land claim for this clan
			# Phase 3: Use cached land claims
			var main_node = get_node_or_null("/root/Main")
			var land_claims: Array
			if main_node and main_node.has_method("get_cached_land_claims"):
				land_claims = main_node.get_cached_land_claims()
			else:
				land_claims = get_tree().get_nodes_in_group("land_claims")
			for claim in land_claims:
				if not is_instance_valid(claim):
					continue
				
				var claim_clan: String = ""
				var clan_name_prop = claim.get("clan_name")
				if clan_name_prop != null:
					claim_clan = clan_name_prop as String
				
				if claim_clan == clan_name:
					# Found our land claim - ensure point is inside
					var claim_pos: Vector2 = claim.global_position
					var claim_radius: float = 400.0
					var radius_prop = claim.get("radius")
					if radius_prop != null:
						claim_radius = radius_prop as float
					
					var distance_to_claim: float = point.distance_to(claim_pos)
					if distance_to_claim >= claim_radius:
						# Point is outside - clamp it to inside the radius
						var direction: Vector2 = (point - claim_pos).normalized()
						point = claim_pos + direction * (claim_radius * 0.9)  # 90% of radius to stay inside
					break
	
	return point

func _get_nearby_npcs() -> Array:
	var nearby := []
	if not npc:
		return nearby
	
	var npcs := get_tree().get_nodes_in_group("npcs")
	for other_npc in npcs:
		if other_npc == npc:
			continue
		if not is_instance_valid(other_npc):
			continue
		var distance: float = npc.global_position.distance_to(other_npc.global_position)
		if distance < separation_radius * 2.0:  # Check slightly larger radius
			nearby.append(other_npc)
	
	return nearby

func _get_nearby_obstacles() -> Array:
	# Get all obstacles (NPCs, buildings, resources) that NPCs should avoid stopping on
	# OPTIMIZED: Use NodeCache if available for better performance
	var obstacles := []
	if not npc:
		return obstacles
	
	var npc_pos: Vector2 = npc.global_position
	var check_radius: float = separation_radius * 2.0
	
	# Use NodeCache for better performance (spatial partitioning)
	var node_cache = get_node_or_null("/root/NodeCache")
	if node_cache:
		# Get nearby NPCs using cache
		var nearby_npcs: Array = node_cache.get_npcs_near_position(npc_pos, check_radius)
		for other_npc in nearby_npcs:
			if other_npc == npc or not is_instance_valid(other_npc):
				continue
			obstacles.append(other_npc)
	else:
		# Fallback: Get all NPCs and filter
		var npcs := get_tree().get_nodes_in_group("npcs")
		for other_npc in npcs:
			if other_npc == npc:
				continue
			if not is_instance_valid(other_npc):
				continue
			var distance: float = npc_pos.distance_to(other_npc.global_position)
			if distance < check_radius:
				obstacles.append(other_npc)
	
	# Get nearby buildings (land claims) - only check if close enough
	var buildings := get_tree().get_nodes_in_group("land_claims")
	for building in buildings:
		if not is_instance_valid(building):
			continue
		var distance: float = npc_pos.distance_to(building.global_position)
		if distance < check_radius:
			obstacles.append(building)
	
	# Resources are usually not obstacles for pathfinding (NPCs can walk through them)
	# Only include if very close and blocking movement
	# Removed resource checking for better performance - resources don't block movement
	
	return obstacles

# Phase 3 Item 5: Split _avoid_land_claims by intent
func _should_avoid_land_claim(claim: Node2D, is_herding: bool) -> bool:
	"""Check if this NPC should avoid the given land claim."""
	if not npc:
		return false
	# If NPC can enter the claim, don't avoid (unless herding and need to protect herd)
	if npc.can_enter_land_claim(claim):
		return is_herding  # Only avoid if herding (to protect herd buffer zone)
	return true

func _compute_land_claim_force(claim_pos: Vector2, npc_pos: Vector2, distance: float, radius: float, buffer_zone: float, is_herding: bool) -> Vector2:
	"""Compute the avoidance force for a land claim based on distance."""
	var effective_radius: float = radius + buffer_zone
	if distance >= effective_radius:
		return Vector2.ZERO
	
	var flee_direction: Vector2 = (npc_pos - claim_pos)
	if flee_direction.length() < 0.1:
		return Vector2.ZERO
	flee_direction = flee_direction.normalized()
	
	# Calculate avoidance strength
	var strength: float = 0.0
	if distance < radius:
		# Inside land claim - strong avoidance
		strength = 1.0 - (distance / radius)
	else:
		# Inside buffer zone - moderate avoidance
		var buffer_distance: float = distance - radius
		strength = 1.0 - (buffer_distance / buffer_zone)
	
	strength = clamp(strength, 0.0, 1.0)
	
	# Stronger avoidance when herding to protect herd
	var avoidance_multiplier: float = 1.2 if is_herding else 0.8
	
	return flee_direction * strength * max_force * avoidance_multiplier

func _compute_caveman_detour(claim_pos: Vector2, npc_pos: Vector2, current_target: Vector2, radius: float, effective_radius: float, distance: float) -> Dictionary:
	"""Compute detour info for caveman pathfinding around a land claim.
	Returns: {should_detour: bool, force: Vector2, light_force: bool}"""
	var result := {"should_detour": false, "force": Vector2.ZERO, "light_force": false, "attempts": 0}
	
	var target_distance: float = current_target.distance_to(claim_pos)
	var npc_to_target: Vector2 = current_target - npc_pos
	var npc_to_target_distance: float = npc_to_target.length()
	
	# Check if target is on the other side of the land claim
	if target_distance <= radius:
		return result  # Target is inside the claim, no detour needed
	
	# Check if line from NPC to target intersects the land claim
	var to_target_dir: Vector2 = npc_to_target.normalized()
	var claim_to_npc: Vector2 = npc_pos - claim_pos
	var projection_length: float = claim_to_npc.dot(to_target_dir)
	var closest_point: Vector2 = npc_pos - to_target_dir * projection_length
	var distance_to_closest: float = closest_point.distance_to(claim_pos)
	
	if distance_to_closest >= effective_radius:
		return result  # Path doesn't intersect the claim
	
	result.should_detour = true
	result.attempts = 1
	
	# Calculate path around land claim (tangent points)
	var direct_path_distance: float = npc_to_target_distance
	var direction_to_target_from_claim: Vector2 = (current_target - claim_pos).normalized()
	var perpendicular: Vector2 = Vector2(-direction_to_target_from_claim.y, direction_to_target_from_claim.x)
	var tangent_offset: float = effective_radius + 30.0
	var tangent_point_1: Vector2 = claim_pos + (direction_to_target_from_claim + perpendicular).normalized() * tangent_offset
	var tangent_point_2: Vector2 = claim_pos + (direction_to_target_from_claim - perpendicular).normalized() * tangent_offset
	
	# Choose the closer tangent point
	var dist_to_tangent_1: float = npc_pos.distance_to(tangent_point_1)
	var dist_to_tangent_2: float = npc_pos.distance_to(tangent_point_2)
	var tangent_point: Vector2 = tangent_point_1 if dist_to_tangent_1 < dist_to_tangent_2 else tangent_point_2
	var dist_to_tangent: float = min(dist_to_tangent_1, dist_to_tangent_2)
	var around_path_distance: float = dist_to_tangent + tangent_point.distance_to(current_target)
	
	# If going around is too long (>1.5x direct), allow crossing with light force
	if around_path_distance > direct_path_distance * 1.5:
		if distance < radius * 0.5:  # Only when deep inside
			result.force = (npc_pos - claim_pos).normalized() * max_force * 0.2
		result.light_force = true
	else:
		# Steer toward tangent point
		var to_tangent: Vector2 = tangent_point - npc_pos
		if to_tangent.length() > 10.0:
			result.force = to_tangent.normalized() * max_force * 0.8
	
	return result

func _avoid_land_claims() -> Vector2:
	# Wild NPCs and cavemen avoid/flee from land claims they don't belong to
	# OPTIMIZED: Uses helper functions for cleaner code
	if not npc:
		return Vector2.ZERO
	
	# Get buffer zone size from config (mammoths use much larger distance)
	var buffer_zone: float = 150.0
	var is_mammoth: bool = _cached.get("is_mammoth", false)
	if NPCConfig:
		if is_mammoth:
			var mammoth_prop = NPCConfig.get("mammoth_land_claim_avoid_distance")
			if mammoth_prop != null:
				buffer_zone = mammoth_prop as float
		else:
			var buffer_prop = NPCConfig.get("land_claim_buffer_zone")
			if buffer_prop != null:
				buffer_zone = buffer_prop as float
	
	# Phase 3: Use cached traits
	var is_herded: bool = _cached.get("is_herded", false)
	var is_part_of_clan: bool = _cached.get("is_part_of_clan", false)
	var is_caveman: bool = _cached.get("is_caveman", false)
	var npc_pos: Vector2 = _cached.get("npc_pos", Vector2.ZERO)
	
	# Phase 3: Use herded_count instead of scanning nearby NPCs
	var is_herding: bool = npc.herded_count > 0 if npc and "herded_count" in npc else false
	
	# If NPC is part of a clan or being herded (not herding), don't avoid
	if is_part_of_clan or (is_herded and not is_herding):
		return Vector2.ZERO
	
	# Get cached land claims
	var main_node = get_node_or_null("/root/Main")
	var land_claims: Array
	if main_node and main_node.has_method("get_cached_land_claims"):
		land_claims = main_node.get_cached_land_claims()
	else:
		land_claims = get_tree().get_nodes_in_group("land_claims")
	
	# Get current target position
	var current_target: Vector2 = target_position
	if target_node and is_instance_valid(target_node):
		current_target = target_node.global_position
	
	var avoidance_force := Vector2.ZERO
	var current_pathfinding_attempts: int = 0
	
	# Phase 3 Item 5: Clean loop using helper functions
	for claim in land_claims:
		if not is_instance_valid(claim):
			continue
		
		var claim_pos: Vector2 = claim.global_position
		var distance: float = npc_pos.distance_to(claim_pos)
		var radius: float = 400.0
		var radius_prop = claim.get("radius")
		if radius_prop != null:
			radius = radius_prop as float
		var effective_radius: float = radius + buffer_zone
		
		# Check if we should avoid this claim
		if not _should_avoid_land_claim(claim, is_herding):
			# Can enter, but if herding, still need buffer zone protection
			if is_herding and distance < effective_radius:
				avoidance_force += _compute_land_claim_force(claim_pos, npc_pos, distance, radius, buffer_zone, is_herding)
			continue
		
		# For cavemen: try to compute detour around the claim
		if is_caveman and current_mode != SteeringMode.WANDER:
			if current_pathfinding_attempts >= max_pathfinding_attempts:
				pathfinding_attempts = current_pathfinding_attempts
				break
			
			var detour: Dictionary = _compute_caveman_detour(claim_pos, npc_pos, current_target, radius, effective_radius, distance)
			if detour.should_detour:
				current_pathfinding_attempts += detour.attempts
				if current_pathfinding_attempts >= max_pathfinding_attempts:
					pathfinding_attempts = current_pathfinding_attempts
					break
				avoidance_force += detour.force
				if not detour.light_force:
					pathfinding_attempts = current_pathfinding_attempts
					continue
				continue  # Skip normal avoidance if doing light force
		
		# Normal avoidance force
		avoidance_force += _compute_land_claim_force(claim_pos, npc_pos, distance, radius, buffer_zone, is_herding)
	
	pathfinding_attempts = current_pathfinding_attempts
	return avoidance_force

func _keep_inside_clan_land_claim() -> Vector2:
	# Apply boundary force to keep clan members inside their land claim
	# EXCEPT for cavemen and clansmen - they can leave to gather and deposit items
	if not npc:
		return Vector2.ZERO
	
	# Phase 3: Use cached traits
	if _cached.get("is_caveman", false) or _cached.get("is_clansman", false):
		return Vector2.ZERO  # Cavemen and clansmen can leave their land claim
	
	var clan_name: String = _cached.get("clan_name", "")
	if clan_name == "":
		return Vector2.ZERO  # Not in a clan
	
	# Find the land claim for this clan
	# Phase 3: Use cached land claims
	var main_node = get_node_or_null("/root/Main")
	var land_claims: Array
	if main_node and main_node.has_method("get_cached_land_claims"):
		land_claims = main_node.get_cached_land_claims()
	else:
		land_claims = get_tree().get_nodes_in_group("land_claims")
	var my_claim: Node2D = null
	var claim_radius: float = 400.0
	
	for claim in land_claims:
		if not is_instance_valid(claim):
			continue
		var claim_clan: String = ""
		var clan_name_prop = claim.get("clan_name")
		if clan_name_prop != null:
			claim_clan = clan_name_prop as String
		if claim_clan == clan_name:
			my_claim = claim
			var radius_prop = claim.get("radius")
			if radius_prop != null:
				claim_radius = radius_prop as float
			break
	
	if not my_claim:
		return Vector2.ZERO  # No land claim found
	
	# Check if we're near or at the boundary
	var claim_pos: Vector2 = my_claim.global_position
	var distance: float = npc.global_position.distance_to(claim_pos)
	var boundary_threshold: float = claim_radius * 0.95  # Start applying force at 95% of radius
	
	if distance >= boundary_threshold:
		# Near or at boundary - apply force toward center
		var direction_to_center: Vector2 = (claim_pos - npc.global_position).normalized()
		# Stronger force when past boundary to prevent leaving
		var force_strength: float = 300.0  # Base force
		if distance >= claim_radius:
			force_strength = 500.0  # Much stronger force when past boundary
		return direction_to_center * force_strength
	
	return Vector2.ZERO
