extends "res://scripts/npc/states/base_state.gd"

# Idle state - NPC does idle animations (look left, look right, bounce)

var idle_timer: float = 0.0
var idle_duration: float = 0.0  # Random duration between 2-5 seconds
var current_animation: String = "look_right"  # look_right, look_left, bounce
var animation_timer: float = 0.0
var animation_duration: float = 0.0  # Duration for current animation phase
var bounce_offset: Vector2 = Vector2.ZERO
var base_sprite_position: Vector2 = Vector2.ZERO

func enter() -> void:
	idle_timer = 0.0
	# Random idle duration from config (default 1-3s for less downtime)
	var min_dur: float = 1.0
	var max_dur: float = 3.0
	if NPCConfig:
		if "idle_duration_min" in NPCConfig:
			min_dur = NPCConfig.idle_duration_min as float
		if "idle_duration_max" in NPCConfig:
			max_dur = NPCConfig.idle_duration_max as float
	idle_duration = randf_range(min_dur, max_dur)
	current_animation = "look_right"  # Start by looking right
	animation_timer = 0.0
	animation_duration = randf_range(1.0, 2.0)  # Duration for first animation
	bounce_offset = Vector2.ZERO
	
	# Store base sprite position for bounce animation
	if npc and npc.sprite:
		base_sprite_position = npc.sprite.position
	
	# Stop movement during idle
	if npc and npc.steering_agent:
		npc.steering_agent.current_mode = npc.steering_agent.SteeringMode.WANDER
		# Set wander to zero so NPC doesn't move
		npc.steering_agent.max_speed = 0.0

func exit() -> void:
	_cancel_tasks_if_active()
	# Restore normal speed
	if npc and npc.steering_agent:
		if npc.stats_component:
			var agility: float = npc.stats_component.get_stat("agility")
			npc.steering_agent.max_speed = agility * NPCConfig.speed_agility_multiplier  # Match config (one-third slower)
		else:
			npc.steering_agent.max_speed = NPCConfig.max_speed_base  # Match the reduced default speed
	
	# Reset sprite position
	if npc and npc.sprite:
		npc.sprite.position = base_sprite_position

func update(delta: float) -> void:
	if not npc:
		return
	
	idle_timer += delta
	animation_timer += delta
	
	# Cycle through animations
	match current_animation:
		"look_right":
			# Look right for 1-2 seconds
			if npc.sprite:
				npc.sprite.flip_h = false  # Face right
			if animation_timer >= animation_duration:
				current_animation = "look_left"
				animation_timer = 0.0
				animation_duration = randf_range(1.0, 2.0)  # Set duration for next phase
		
		"look_left":
			# Look left for 1-2 seconds
			if npc.sprite:
				npc.sprite.flip_h = true  # Face left
			if animation_timer >= animation_duration:
				current_animation = "bounce"
				animation_timer = 0.0
				animation_duration = randf_range(1.0, 2.0)  # Set duration for next phase
		
		"bounce":
			# Bounce animation for 1-2 seconds
			if npc.sprite:
				var bounce_amount: float = 2.0
				var bounce_speed: float = 8.0
				bounce_offset.y = sin(animation_timer * bounce_speed) * bounce_amount
				npc.sprite.position = base_sprite_position + bounce_offset
			if animation_timer >= animation_duration:
				# Cycle back to look_right
				current_animation = "look_right"
				animation_timer = 0.0
				animation_duration = randf_range(1.0, 2.0)  # Set duration for next phase
				if npc.sprite:
					npc.sprite.position = base_sprite_position
					bounce_offset = Vector2.ZERO
	
	# Stop movement during idle
	if npc:
		npc.velocity = npc.velocity.lerp(Vector2.ZERO, 10.0 * delta)

func can_enter() -> bool:
	var npc_name: String = npc.get("npc_name") if npc else "unknown"
	
	# Can always enter idle (lowest priority)
	UnifiedLogger.log_npc("Can enter check: %s can enter idle (always_available)" % npc_name, {
		"npc": npc_name,
		"state": "idle",
		"can_enter": true,
		"reason": "always_available"
	}, UnifiedLogger.Level.DEBUG)
	return true

func get_priority() -> float:
	# CRITICAL: Cavemen should NEVER idle - they should always be doing a task (wander, gather, deposit, herd, etc.)
	# This prevents cavemen from glitching in one spot
	if npc:
		var npc_type_str: String = npc.get("npc_type") if npc else ""
		if npc_type_str == "caveman":
			return 0.0  # Cavemen should never enter idle - always have a task
		
		# CRITICAL FIX: Wild NPCs (women, sheep, goats) should also avoid idle when not herded
		# They should wander instead to prevent oscillation
		if npc_type_str == "woman" or npc_type_str == "sheep" or npc_type_str == "goat":
			var is_herded_prop = npc.get("is_herded")
			var is_herded: bool = is_herded_prop as bool if is_herded_prop != null else false
			if not is_herded:
				# Not herded - should wander, not idle
				return 0.0  # Very low priority - wander state will take precedence
	
	# Women in clans should wander instead of idle (for immersion)
	# Other clan members can idle when no buildings available and not eating
	if npc:
		var npc_type_str: String = npc.get("npc_type") if npc else ""
		var clan_name_prop = npc.get("clan_name")
		var clan_name: String = clan_name_prop as String if clan_name_prop != null else ""
		
		# Women in clans should wander (lower priority than wander state)
		if npc_type_str == "woman" and clan_name != "":
			return 0.1  # Very low priority - wander state (1.0) will take precedence
		
		# Other clan members can idle
		if clan_name != "":
			# Higher priority for other clan members to idle (they don't wander or gather)
			return 0.3
	# Lowest priority - only when NPC has no other actions
	var force_idle_chance: float = 0.02
	if NPCConfig and "idle_chance" in NPCConfig:
		force_idle_chance = NPCConfig.idle_chance as float
	if randf() < force_idle_chance:
		return 0.5  # Slightly higher priority to allow idle breaks
	return 0.0

