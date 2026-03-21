extends Task
class_name MoveToTask

# Task System - Step 15
# Moves an NPC to a target position using CharacterBody2D movement

# Target position (world coordinates)
var target_position: Vector2

# Arrival distance threshold (pixels) - NPC is considered "arrived" when within this distance
var arrival_distance: float = 50.0

# Movement speed (pixels per second) - normal NPC speed (reduced for smoother movement)
var move_speed: float = 180.0

# Whether to use steering behavior (for smoother movement)
var use_steering: bool = false

# Acceleration/deceleration for natural, deliberate movement
var acceleration: float = 250.0  # Slower acceleration for more deliberate movement
var deceleration: float = 350.0  # Slower deceleration for more deliberate stops
var momentum_resistance: float = 0.85  # How much momentum resists direction changes (0.0-1.0, higher = more momentum)

# Arrival slowdown distance - start slowing down when this close
var slowdown_distance: float = 200.0  # Start slowing down 200px before target (more deliberate)

# Deliberate movement - brief pause before starting (reduced for efficiency)
var start_delay: float = 0.05  # Brief pause before starting movement (seconds) - reduced for faster gathering
var _start_delay_timer: float = 0.0

# Internal state
var _started: bool = false
var _current_velocity: Vector2 = Vector2.ZERO  # Track current velocity for smooth acceleration
var _target_direction: Vector2 = Vector2.ZERO  # Store target direction for momentum

func _init(pos: Vector2, arrival_dist: float = 50.0, speed: float = 180.0, steering: bool = false) -> void:
	target_position = pos
	arrival_distance = arrival_dist
	move_speed = speed
	use_steering = steering

func _start_impl(actor: Node) -> void:
	if not actor is CharacterBody2D:
		status = TaskStatus.FAILED
		return
	
	_started = true
	_start_delay_timer = 0.0
	# Initialize current velocity from NPC's existing velocity for smooth transition
	if actor is CharacterBody2D:
		_current_velocity = (actor as CharacterBody2D).velocity
		# Calculate initial target direction
		var npc: CharacterBody2D = actor as CharacterBody2D
		var direction: Vector2 = (target_position - npc.global_position).normalized()
		_target_direction = direction
	status = TaskStatus.RUNNING

func _tick_impl(actor: Node, delta: float) -> TaskStatus:
	if not actor is CharacterBody2D:
		return TaskStatus.FAILED
	
	var npc: CharacterBody2D = actor as CharacterBody2D
	
	if npc is NPCBase and (npc as NPCBase).should_abort_work():
		return TaskStatus.FAILED
	
	var current_pos: Vector2 = npc.global_position
	var distance_to_target: float = current_pos.distance_to(target_position)
	
	# Check if we've arrived
	if distance_to_target <= arrival_distance:
		# Smoothly decelerate to stop
		_current_velocity = _current_velocity.move_toward(Vector2.ZERO, deceleration * delta)
		npc.velocity = _current_velocity
		npc.move_and_slide()
		
		# Only mark as arrived when fully stopped
		if _current_velocity.length() < 10.0:
			npc.velocity = Vector2.ZERO
			_current_velocity = Vector2.ZERO
		var npc_name: String = npc.get("npc_name") if "npc_name" in npc else "unknown"
		UnifiedLogger.log_npc("MoveToTask: %s arrived at target (distance=%.1f, speed=%.1f)" % [npc_name, distance_to_target, move_speed], {
			"npc": npc_name,
			"task": "move_to",
			"distance": distance_to_target,
			"speed": move_speed,
			"status": "arrived"
		}, UnifiedLogger.Level.DEBUG)
		return TaskStatus.SUCCESS
	
	# Deliberate pause before starting movement
	if _start_delay_timer < start_delay:
		_start_delay_timer += delta
		# Gradually slow down existing velocity during pause
		_current_velocity = _current_velocity.move_toward(Vector2.ZERO, deceleration * delta)
		npc.velocity = _current_velocity
		npc.move_and_slide()
		return TaskStatus.RUNNING
	
	# Calculate direction to target
	var direction: Vector2 = (target_position - current_pos).normalized()
	
	# Deliberate direction change - smooth transition to new direction (momentum)
	if _target_direction.dot(direction) < 0.9:  # If direction changed significantly
		# Gradually rotate towards new direction (more deliberate)
		_target_direction = _target_direction.lerp(direction, 2.0 * delta).normalized()
	else:
		_target_direction = direction
	
	# Calculate desired speed with arrival slowdown
	var desired_speed: float = move_speed
	# Carrying travois: move slower
	if actor is NPCBase and (actor as NPCBase).has_travois():
		desired_speed *= 0.7
	if distance_to_target < slowdown_distance:
		# Gradually slow down as approaching target (smooth curve)
		var slowdown_factor: float = distance_to_target / slowdown_distance
		# Use smooth curve (ease-out) for more natural deceleration
		slowdown_factor = slowdown_factor * slowdown_factor  # Quadratic ease-out
		desired_speed = move_speed * max(slowdown_factor, 0.15)  # Minimum 15% speed
	
	# Calculate desired velocity using smoothed direction
	var desired_velocity: Vector2 = _target_direction * desired_speed
	
	# Apply momentum - resist sudden direction changes
	var current_direction: Vector2 = _current_velocity.normalized() if _current_velocity.length() > 10.0 else _target_direction
	var direction_change: float = current_direction.dot(_target_direction)
	
	# If changing direction significantly, apply momentum resistance
	if direction_change < 0.7 and _current_velocity.length() > 20.0:
		# Blend between current momentum and desired direction (more deliberate)
		var momentum_component: Vector2 = current_direction * _current_velocity.length() * momentum_resistance
		var desired_component: Vector2 = _target_direction * desired_speed * (1.0 - momentum_resistance)
		desired_velocity = momentum_component + desired_component
	
	# Smooth acceleration/deceleration towards desired velocity
	var velocity_diff: Vector2 = desired_velocity - _current_velocity
	var accel_rate: float = acceleration if velocity_diff.length() > _current_velocity.length() else deceleration
	var max_change: float = accel_rate * delta
	var change: Vector2 = velocity_diff.normalized() * min(velocity_diff.length(), max_change)
	
	_current_velocity += change
	npc.velocity = _current_velocity
	npc.move_and_slide()
	
	# Debug logging every 1.0 seconds
	if not has_meta("_last_debug_time"):
		set_meta("_last_debug_time", 0.0)
	var last_time: float = get_meta("_last_debug_time", 0.0)
	var current_time: float = Time.get_ticks_msec() / 1000.0
	if current_time - last_time >= 1.0:
		set_meta("_last_debug_time", current_time)
		var npc_name: String = npc.get("npc_name") if "npc_name" in npc else "unknown"
		var velocity_magnitude: float = npc.velocity.length()
		UnifiedLogger.log_npc("MoveToTask: %s moving (distance=%.1f, speed=%.1f, velocity=%.1f)" % [
			npc_name, distance_to_target, move_speed, velocity_magnitude
		], {
			"npc": npc_name,
			"task": "move_to",
			"distance": distance_to_target,
			"speed": move_speed,
			"velocity": velocity_magnitude
		}, UnifiedLogger.Level.DEBUG)
	
	return TaskStatus.RUNNING

func _cancel_impl(actor: Node) -> void:
	if actor is CharacterBody2D:
		var npc: CharacterBody2D = actor as CharacterBody2D
		npc.velocity = Vector2.ZERO
		npc.move_and_slide()
