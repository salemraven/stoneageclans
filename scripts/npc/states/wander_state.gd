extends "res://scripts/npc/states/base_state.gd"

# Wander state - NPC moves randomly within a radius
# For cavemen: Also handles automatic land claim placement

var wander_radius: float = 300.0  # Increased wander radius

func enter() -> void:
	# Sheep/goats headed to Farm/Dairy: do NOT overwrite steering - let them reach assigned building
	var npc_type_enter: String = npc.get("npc_type") if npc else ""
	var ab = OccupationSystem.get_workplace(npc) if (OccupationSystem and npc) else null
	if (npc_type_enter == "sheep" or npc_type_enter == "goat") and ab and is_instance_valid(ab):
		return  # Keep current steering target (building)
	
	# PRODUCTIVITY RULE: Track when caveman/clansman enters wander state
	var now_enter: float = Time.get_ticks_msec() / 1000.0
	if npc_type_enter == "caveman":
		npc.set_meta("wander_start_time", now_enter)
	if npc_type_enter == "caveman" or npc_type_enter == "clansman":
		npc.set_meta("wander_enter_time", now_enter)  # Long-duration tracking for 60s stuck recovery
	
	if npc and npc.steering_agent:
		var center: Vector2 = npc.global_position
		var radius: float = wander_radius
		
		# Log wander entry for cavemen
		var npc_type_str: String = npc.get("npc_type") if npc else ""
		if npc_type_str == "caveman":
			var clan_name_prop = npc.get("clan_name")
			var clan_name: String = clan_name_prop as String if clan_name_prop != null else ""
			var reason: String = "no_resources_in_perception"
			if clan_name == "":
				reason = "no_land_claim_wandering"
			
			# Throttle repeated wander spam (log at most every 2 seconds)
			var now: float = Time.get_ticks_msec() / 1000.0
			var last_log: float = npc.get_meta("last_wander_log_time", 0.0)
			if now - last_log >= 2.0:
				npc.set_meta("last_wander_log_time", now)
				UnifiedLogger.log_npc("Action started: wander", {
					"npc": npc.npc_name,
					"action": "wander",
					"reason": reason,
					"clan": clan_name if clan_name != "" else "none"
				})
		
		# Get clan name for all NPCs
		var clan_name_prop = npc.get("clan_name")
		var clan_name: String = clan_name_prop as String if clan_name_prop != null else ""
		
		# Cavemen and clansmen with a land claim: wander around claim but radius EXTENDS outside
		# so they can leave to gather and herd (not trapped inside); resources inside claim are valid
		if (npc_type_str == "caveman" or npc_type_str == "clansman") and clan_name != "":
			var claim = npc.get_my_land_claim() if npc.has_method("get_my_land_claim") else null
			if claim and is_instance_valid(claim):
				center = claim.global_position
				var claim_radius_val: float = 400.0
				var rp = claim.get("radius")
				if rp != null:
					claim_radius_val = rp as float
				# Radius 1.5x claim so they wander outside and can reach resources
				radius = claim_radius_val * 1.5
			else:
				center = npc.global_position
				radius = wander_radius * 2.0
		elif npc_type_str == "caveman":
			# Caveman without claim: explore from current position
			center = npc.global_position
			radius = wander_radius * 2.0
		elif (npc_type_str == "woman" or npc_type_str == "sheep" or npc_type_str == "goat" or npc_type_str == "baby") and clan_name != "":
			# For women/animals in land claims, use land claim center and radius for wandering
			var claim = npc.get_my_land_claim() if npc.has_method("get_my_land_claim") else null
			if claim and is_instance_valid(claim):
				center = claim.global_position
				var claim_radius_prop = claim.get("radius")
				if claim_radius_prop != null:
					radius = (claim_radius_prop as float) * 0.8  # Wander within 80% of land claim radius (leave buffer near boundary)
		elif npc.is_wild():
			# Chunk-bound roaming: use chunk center and roam radius (replaces spawn anchoring)
			if ChunkUtils and npc.roam_radius > 0:
				center = npc.chunk_center
				radius = npc.roam_radius
			else:
				# Fallback if chunk not yet initialized
				var spawn_pos: Vector2 = npc.spawn_position if npc.get("spawn_position") != null else Vector2.ZERO
				if spawn_pos != Vector2.ZERO:
					center = spawn_pos
					radius = wander_radius * 2.0

			# Clan avoidance: if center too close to land claim, push center away
			var land_claims := get_tree().get_nodes_in_group("land_claims")
			var avoid_radius: float = 800.0 if npc_type_str == "woman" else 600.0
			if ChunkUtils:
				avoid_radius = ChunkUtils.WOMAN_CLAN_AVOID_RADIUS if npc_type_str == "woman" else ChunkUtils.CLAN_AVOID_RADIUS
			if npc_type_str == "mammoth" and NPCConfig:
				var mammoth_prop = NPCConfig.get("mammoth_land_claim_avoid_distance")
				if mammoth_prop != null:
					avoid_radius = mammoth_prop as float
			var closest_claim: Node2D = null
			var closest_distance: float = INF
			for claim in land_claims:
				if not is_instance_valid(claim):
					continue
				var claim_pos: Vector2 = claim.global_position
				var claim_radius_prop = claim.get("radius")
				var claim_radius: float = claim_radius_prop as float if claim_radius_prop != null else 400.0
				var total_avoid: float = claim_radius + avoid_radius
				var dist: float = center.distance_to(claim_pos)
				if dist < total_avoid and dist < closest_distance:
					closest_distance = dist
					closest_claim = claim
			if closest_claim:
				var claim_pos: Vector2 = closest_claim.global_position
				var claim_radius_prop = closest_claim.get("radius")
				var claim_radius: float = claim_radius_prop as float if claim_radius_prop != null else 400.0
				var total_avoid: float = claim_radius + avoid_radius
				var dir: Vector2 = (center - claim_pos).normalized()
				if dir.length_squared() < 0.01:
					dir = Vector2(cos(randf() * TAU), sin(randf() * TAU))
				center = claim_pos + dir * total_avoid
		
		# For cavemen: Ensure wander center is not inside enemy land claim
		if npc_type_str == "caveman":
			# Check if center is in enemy land claim - if so, adjust it
			if _is_position_in_enemy_land_claim(center):
				# Find a safe position outside enemy land claims
				var safe_center: Vector2 = center
				var attempts: int = 0
				# Try to find a position outside enemy land claims
				while _is_position_in_enemy_land_claim(safe_center) and attempts < 20:
					var random_angle := randf() * TAU
					safe_center = center + Vector2(cos(random_angle), sin(random_angle)) * (radius * 0.5)
					attempts += 1
				center = safe_center
				# Reduce radius to prevent wandering into enemy territory
				radius = radius * 0.7  # Smaller radius to stay safer
		
		# Cavemen/clansmen with claim already have center=claim, radius=1.5*claim (can leave to gather)
		npc.steering_agent.set_wander(center, radius)
		# Ensure NPC starts moving immediately
		if npc.velocity.length_squared() < 1.0:
			# Give a small initial push
			var random_angle := randf() * TAU
			npc.velocity = Vector2(cos(random_angle), sin(random_angle)) * 20.0

func exit() -> void:
	# Cancel any active tasks
	_cancel_tasks_if_active()
	
	# Restore speed multiplier if it was changed during deposit movement
	if npc and npc.steering_agent and npc.steering_agent.has_method("restore_original_speed"):
		npc.steering_agent.restore_original_speed()
	
	# Clear deposit movement flag
	if npc and npc.has_meta("moving_to_deposit"):
		npc.remove_meta("moving_to_deposit")
	# Clear long-duration tracking for stuck recovery
	if npc and npc.has_meta("wander_enter_time"):
		npc.remove_meta("wander_enter_time")

func can_enter() -> bool:
	var npc_name: String = npc.get("npc_name") if npc else "unknown"
	
	if not npc:
		UnifiedLogger.log_npc("Can enter check: %s cannot enter wander (npc_is_null)" % npc_name, {
			"npc": npc_name,
			"state": "wander",
			"can_enter": false,
			"reason": "npc_is_null"
		}, UnifiedLogger.Level.DEBUG)
		return false
	
	# CRITICAL: NPCs being herded CANNOT wander - they must follow their leader
	# This prevents wild NPCs from walking away from the leader
	if npc.get("is_herded") == true:
		var herder = npc.get("herder") if npc else null
		if herder and is_instance_valid(herder):
			var herder_name: String = herder.name if herder else "unknown"
			UnifiedLogger.log_npc("Can enter check: %s cannot enter wander (is_herded_cannot_wander)" % npc_name, {
				"npc": npc_name,
				"state": "wander",
				"can_enter": false,
				"reason": "is_herded_cannot_wander",
				"herder": herder_name
			}, UnifiedLogger.Level.DEBUG)
			return false  # Being herded - cannot wander, must follow leader
	
	# CRITICAL: NPCs with ordered follow CANNOT wander - they must follow the player
	if _is_following():
		UnifiedLogger.log_npc("Can enter check: %s cannot enter wander (follow_is_ordered)" % npc_name, {
			"npc": npc_name,
			"state": "wander",
			"can_enter": false,
			"reason": "follow_is_ordered"
		}, UnifiedLogger.Level.DEBUG)
		return false  # Following - cannot wander
	
	# Women, sheep, and goats in land claims CAN wander (for immersion and lifelike behavior)
	# They will wander within their land claim boundaries
	var npc_type_str: String = npc.get("npc_type") if npc else ""
	var clan_name_prop = npc.get("clan_name")
	var clan_name: String = clan_name_prop as String if clan_name_prop != null else ""
	
	# Allow women, sheep, goats, and babies in clans to wander (they're restricted by land claim boundaries)
	if (npc_type_str == "woman" or npc_type_str == "sheep" or npc_type_str == "goat" or npc_type_str == "baby") and clan_name != "":
		var reason_name = "baby_in_clan_can_wander" if npc_type_str == "baby" else "woman_in_clan_can_wander"
		UnifiedLogger.log_npc("Can enter check: %s can enter wander (%s)" % [npc_name, reason_name], {
			"npc": npc_name,
			"state": "wander",
			"can_enter": true,
			"reason": reason_name,
			"clan": clan_name
		}, UnifiedLogger.Level.DEBUG)
		return true
	
	# Other clan members (non-women, non-babies, non-cavemen, non-clansmen) cannot wander - they idle and eat from storage
	# Cavemen and clansmen CAN wander (they need to gather outside their land claim)
	if clan_name != "" and npc_type_str != "caveman" and npc_type_str != "baby" and npc_type_str != "clansman":
		UnifiedLogger.log_npc("Can enter check: %s cannot enter wander (clan_member_cannot_wander)" % npc_name, {
			"npc": npc_name,
			"state": "wander",
			"can_enter": false,
			"reason": "clan_member_cannot_wander",
			"clan": clan_name,
			"npc_type": npc_type_str
		}, UnifiedLogger.Level.DEBUG)
		return false  # Other clan members don't wander (but cavemen can)
	
	# SIMPLIFIED: Cavemen and clansmen can ALWAYS wander - wander state handles deposit movement internally
	# Don't block entry here - let wander state's update() handle deposit movement when inventory full
	# However, wander should have LOW priority - clansmen/cavemen should prioritize gathering/herding
	if npc_type_str == "clansman":
		return true  # Allow clansmen to wander (but with low priority)
	# This allows deposit movement to happen (wander state moves NPC to land claim for deposit)
	if npc_type_str == "caveman":
		UnifiedLogger.log_npc("Can enter check: %s can enter wander (caveman_can_always_wander)" % npc_name, {
			"npc": npc_name,
			"state": "wander",
			"can_enter": true,
			"reason": "caveman_can_always_wander"
		}, UnifiedLogger.Level.DEBUG)
		return true  # Always allow wander (needed for deposit movement when inventory full)
	
	# Wild NPCs can wander (only if not being herded - checked above)
	UnifiedLogger.log_npc("Can enter check: %s can enter wander (no_higher_priority_needs)" % npc_name, {
		"npc": npc_name,
		"state": "wander",
		"can_enter": true,
		"reason": "no_higher_priority_needs"
	}, UnifiedLogger.Level.DEBUG)
	return true

func update(delta: float) -> void:
	if not npc:
		return
	
	# Sheep/goats pathing to Farm/Dairy: don't overwrite steering
	var npc_type_upd: String = npc.get("npc_type") if npc else ""
	if (npc_type_upd == "sheep" or npc_type_upd == "goat"):
		var ab_upd = OccupationSystem.get_workplace(npc) if (OccupationSystem and npc) else null
		if ab_upd and is_instance_valid(ab_upd):
			return  # Let npc_base._check_and_assign_to_building handle movement
	
	# CRITICAL: Exit immediately if following - party (fighters) vs herd (wild herdables)
	if _is_following():
		if fsm:
			var nt_f: String = str(npc.get("npc_type")) if npc.get("npc_type") != null else ""
			if nt_f == "caveman" or nt_f == "clansman":
				fsm.change_state("party")
			else:
				fsm.change_state("herd")
		return
	
	# LOGGING: Position tracking for oscillation detection
	_log_position_if_needed()
	
	# Get current time once for the entire function
	var current_time: float = Time.get_ticks_msec() / 1000.0
	
	# FIX: Reset wander timer when entering wander state (not just on first check)
	if not npc.has_meta("wander_start_time"):
		npc.set_meta("wander_start_time", current_time)
	
	var npc_type_wander: String = npc.get("npc_type") if npc else ""
	
	# BREAK: steer directly toward land claim until arriving, then let normal wander + re-evaluation take over
	if npc_type_wander == "clansman" and npc.has_meta("returning_from_break"):
		var until: float = npc.get_meta("returning_from_break") as float
		if Time.get_ticks_msec() / 1000.0 < until:
			var break_claim: Node2D = _get_land_claim()
			if break_claim and is_instance_valid(break_claim) and npc.steering_agent:
				var dist_to_claim: float = npc.global_position.distance_to(break_claim.global_position)
				if dist_to_claim > 120.0:
					npc.steering_agent.set_arrive_target(break_claim.global_position)
					if npc.steering_agent.has_method("set_speed_multiplier"):
						npc.steering_agent.set_speed_multiplier(1.0)
					return
				else:
					# Arrived — clear the flag early so normal re-evaluation can resume work
					npc.remove_meta("returning_from_break")
	
	# Handle deposit movement EVERY frame for cavemen/clansmen (was only first frame - they never reached the claim)
	if npc_type_wander == "caveman" or npc_type_wander == "clansman":
		var land_claim: Node2D = _get_land_claim()
		if land_claim:
			var used_slots: int = _get_used_slots()
			var max_slots: int = npc.inventory.slot_count if npc.inventory else 5
			var deposit_pct: float = NPCConfig.gather_deposit_threshold if NPCConfig else 0.4
			var deposit_threshold: int = max(2, int(ceil(max_slots * deposit_pct)))  # Match gather_state
			var herd_size_trigger: bool = (npc.herded_count >= 2) if "herded_count" in npc else false
			var should_move: bool = npc.has_meta("moving_to_deposit") or (used_slots >= deposit_threshold) or herd_size_trigger
			if should_move:
				if not npc.has_meta("moving_to_deposit"):
					npc.set_meta("moving_to_deposit", true)
					npc.set_meta("is_depositing", true)  # Block herd_wildnpc from taking over until deposit done
				var distance: float = npc.global_position.distance_to(land_claim.global_position)
				var deposit_range: float = NPCConfig.deposit_range if NPCConfig else 100.0
				if distance > deposit_range:
					_cancel_tasks_if_active()
					if npc.steering_agent:
						# TESTING: deposit movement at full speed (was 0.4x)
						if npc.steering_agent.has_method("set_speed_multiplier"):
							npc.steering_agent.set_speed_multiplier(1.0)
						npc.steering_agent.set_arrive_target(land_claim.global_position)
					return
				else:
					npc.remove_meta("moving_to_deposit")
					if npc.has_meta("is_depositing"):
						npc.remove_meta("is_depositing")
					if npc.steering_agent and npc.steering_agent.has_method("restore_original_speed"):
						npc.steering_agent.restore_original_speed()
					return
		
		# PRODUCTIVITY RULE: Force re-evaluate quickly when NOT moving to deposit - cavemen must exit wander ASAP
		if not npc.has_meta("moving_to_deposit"):
			var wander_enter: float = npc.get_meta("wander_enter_time", current_time)
			var wander_duration: float = current_time - wander_enter
			var reeval_sec: float = 0.1  # Re-eval every 0.1s so they grab gather/herd as soon as available
			# Stuck recovery: if in wander > 60s, force evaluation (use wander_enter_time - never reset by reeval)
			if wander_duration >= 60.0:
				var last_stuck_log: float = npc.get_meta("wander_stuck_last_log", 0.0)
				if current_time - last_stuck_log >= 10.0:
					UnifiedLogger.log_npc("WANDER_STUCK_RECOVERY: %s in wander %.0fs - forcing re-evaluation" % [npc.npc_name, wander_duration], {
						"npc": npc.npc_name, "duration_s": wander_duration
					}, UnifiedLogger.Level.WARNING)
					npc.set_meta("wander_stuck_last_log", current_time)
				npc.remove_meta("wander_enter_time")  # Reset so we don't spam; will be set again on next wander enter
			# Reeval throttle: use last_reeval_time so we don't reset wander_enter_time
			var last_reeval: float = npc.get_meta("last_wander_reeval_time", 0.0)
			if current_time - last_reeval >= reeval_sec:
				if fsm:
					fsm.evaluation_timer = 0.0
					fsm._evaluate_states()
				npc.set_meta("last_wander_reeval_time", current_time)
		
		_try_place_land_claim(delta)
	
	# For wild NPCs: Natural animal-like behavior with pauses and idle moments
	if npc.is_wild():
		# NATURAL BEHAVIOR: Wild NPCs should have idle/pause moments (like real animals)
		# current_time already declared at function start
		
		# Track idle state
		if not npc.has_meta("wild_npc_idle_end_time"):
			npc.set_meta("wild_npc_idle_end_time", 0.0)
		
		var idle_end_time: float = npc.get_meta("wild_npc_idle_end_time", 0.0)
		
		# Check if we should be idle (brief pause like animals looking around)
		if current_time < idle_end_time:
			# Currently idle/paused - don't move (like animal looking around or grazing)
			if npc.steering_agent:
				# Stop movement during idle
				npc.steering_agent.set_target_position(npc.global_position)
			return  # Don't do normal wander logic while idle
		
		# Roll chance to enter idle state (like animals pausing)
		var idle_chance: float = 0.0015  # Reduced from 0.003 for less downtime
		var npc_type_wild: String = npc.get("npc_type") if npc else ""
		if npc_type_wild == "sheep" or npc_type_wild == "goat":
			idle_chance = 0.0025  # Reduced from 0.005
		
		if randf() < idle_chance:
			var min_dur: float = 1.0
			var max_dur: float = 3.0
			if NPCConfig:
				if "idle_duration_min" in NPCConfig:
					min_dur = NPCConfig.idle_duration_min as float
				if "idle_duration_max" in NPCConfig:
					max_dur = NPCConfig.idle_duration_max as float
			var idle_duration: float = randf_range(min_dur, max_dur)
			npc.set_meta("wild_npc_idle_end_time", current_time + idle_duration)
			if npc.steering_agent:
				npc.steering_agent.set_target_position(npc.global_position)
			return
		
		# Variable wander intervals - change target less frequently (more natural)
		if not npc.has_meta("last_wander_target_update"):
			npc.set_meta("last_wander_target_update", current_time)
			# Set initial wander interval (3-6 seconds)
			npc.set_meta("wander_update_interval", randf_range(3.0, 6.0))
		
		var last_wander_update: float = npc.get_meta("last_wander_target_update", 0.0)
		var wander_update_interval: float = npc.get_meta("wander_update_interval", 4.0)  # Default 4s
		
		# Update wander target periodically (not every frame)
		if current_time - last_wander_update >= wander_update_interval:
			npc.set_meta("last_wander_target_update", current_time)
			# Set new interval for next update
			npc.set_meta("wander_update_interval", randf_range(3.0, 6.0))
			
			# Get current wander center and radius
			var wander_center: Vector2 = npc.global_position
			var wander_radius_current: float = wander_radius

			# Wild NPCs: chunk-bound roaming (replaces spawn anchoring)
			if npc.is_wild() and ChunkUtils and npc.roam_radius > 0:
				wander_center = npc.chunk_center
				wander_radius_current = npc.roam_radius
			else:
				var spawn_pos = npc.get("spawn_position")
				if spawn_pos != null and spawn_pos != Vector2.ZERO:
					wander_center = spawn_pos as Vector2

			# Clan avoidance for wild NPCs: push center away if too close to land claim
			if npc.is_wild():
				var npc_type_here: String = npc.get("npc_type") as String if npc.get("npc_type") != null else ""
				var avoid_radius: float = 800.0 if npc_type_here == "woman" else 600.0
				if ChunkUtils:
					avoid_radius = ChunkUtils.WOMAN_CLAN_AVOID_RADIUS if npc_type_here == "woman" else ChunkUtils.CLAN_AVOID_RADIUS
				if npc_type_here == "mammoth" and NPCConfig:
					var mp = NPCConfig.get("mammoth_land_claim_avoid_distance")
					if mp != null:
						avoid_radius = mp as float
				var land_claims_wu := get_tree().get_nodes_in_group("land_claims")
				for claim in land_claims_wu:
					if not is_instance_valid(claim):
						continue
					var claim_pos_wu: Vector2 = claim.global_position
					var claim_r: float = claim.get("radius") as float if claim.get("radius") != null else 400.0
					var total_avoid: float = claim_r + avoid_radius
					if wander_center.distance_to(claim_pos_wu) < total_avoid:
						var dir_away: Vector2 = (wander_center - claim_pos_wu).normalized()
						if dir_away.length_squared() < 0.01:
							dir_away = Vector2(cos(randf() * TAU), sin(randf() * TAU))
						wander_center = claim_pos_wu + dir_away * total_avoid
						break
			
			# Set new wander target with natural variation
			if npc.steering_agent:
				npc.steering_agent.set_wander(wander_center, wander_radius_current)
		
		# NATURAL BEHAVIOR: Active land claim avoidance during wandering (WILD NPCs only)
		# Clan members (cavemen, clansmen, women, animals) must NOT avoid - they belong there
		var closest_claim: Node2D = null
		var closest_distance: float = INF
		var total_avoidance_radius_val: float = 1000.0
		var avoidance_radius: float = 600.0
		if npc.is_wild():
			var land_claims := get_tree().get_nodes_in_group("land_claims")
			var npc_type_avoid: String = npc.get("npc_type") as String if npc.get("npc_type") != null else ""
			if npc_type_avoid == "mammoth" and NPCConfig:
				var mammoth_prop = NPCConfig.get("mammoth_land_claim_avoid_distance")
				if mammoth_prop != null:
					avoidance_radius = mammoth_prop as float
			for claim in land_claims:
				if not is_instance_valid(claim):
					continue
				var claim_pos: Vector2 = claim.global_position
				var claim_radius_prop = claim.get("radius")
				var claim_radius: float = claim_radius_prop as float if claim_radius_prop != null else 400.0
				var distance: float = npc.global_position.distance_to(claim_pos)
				var total_avoidance_radius: float = claim_radius + avoidance_radius
				total_avoidance_radius_val = total_avoidance_radius
				if distance < total_avoidance_radius and distance < closest_distance:
					closest_distance = distance
					closest_claim = claim
		
		# HYSTERESIS: Prevent oscillation at boundary. Enter avoid when < 900px; exit when > 1200px.
		var was_avoiding: bool = npc.get_meta("wild_avoiding_claim", false)
		var enter_threshold: float = total_avoidance_radius_val - 100.0  # 900px
		var exit_threshold: float = total_avoidance_radius_val + 200.0   # 1200px
		var should_avoid: bool = false
		if closest_claim:
			var dist: float = npc.global_position.distance_to(closest_claim.global_position)
			if was_avoiding:
				should_avoid = (dist < exit_threshold)  # Stay avoiding until we're clearly out
			else:
				should_avoid = (dist < enter_threshold)  # Only start avoiding when clearly in
			npc.set_meta("wild_avoiding_claim", should_avoid)
		else:
			npc.set_meta("wild_avoiding_claim", false)
		
		# If too close to a land claim, actively move away
		if closest_claim and should_avoid:
			var claim_pos: Vector2 = closest_claim.global_position
			var claim_radius_prop = closest_claim.get("radius")
			var claim_radius: float = claim_radius_prop as float if claim_radius_prop != null else 400.0
			var total_avoidance_radius: float = claim_radius + avoidance_radius
			
			# Move away from land claim
			var direction_away: Vector2 = (npc.global_position - claim_pos).normalized()
			if direction_away.length_squared() < 0.01:
				# If exactly at claim center, pick random direction
				var random_angle := randf() * TAU
				direction_away = Vector2(cos(random_angle), sin(random_angle))
			
			var safe_distance: float = total_avoidance_radius + 100.0  # Add buffer
			var escape_pos: Vector2 = claim_pos + direction_away * safe_distance
			if npc.steering_agent:
				npc.steering_agent.set_arrive_target(escape_pos)
			return  # Don't do normal wander logic while avoiding
	
	# Check for wander reset timer (set when exiting herd/deposit states)
	if npc.has_meta("wander_reset_timer"):
		var reset_timer: float = npc.get_meta("wander_reset_timer", 0.0)
		reset_timer -= delta
		if reset_timer <= 0.0:
			# Reset period complete, remove timer
			var npc_name: String = npc.get("npc_name") if npc else "unknown"
			npc.remove_meta("wander_reset_timer")
			
			# Check if there's a specific next state to transition to
			var next_state: String = npc.get_meta("next_state_after_wander_reset", "") if npc.has_meta("next_state_after_wander_reset") else ""
			if next_state != "":
				npc.remove_meta("next_state_after_wander_reset")
				print("🔄 WANDER→%s: %s reset complete, transitioning to '%s'" % [next_state.to_upper(), npc_name, next_state])
				# Transition directly to the specified state
				if fsm:
					fsm.change_state(next_state)
			else:
				# No specific next state - force FSM evaluation to find best state
				print("🔵 WANDER RESET TIMER: %s - Timer expired, forcing FSM evaluation" % npc_name)
				if fsm:
					fsm.evaluation_timer = 0.0  # Force immediate evaluation
					fsm._evaluate_states()
		else:
			# Still in reset period, update timer
			npc.set_meta("wander_reset_timer", reset_timer)
	
	# PRODUCTIVITY RULE: Wander should only last 1 second max
	# The 1-second timer above (line 242) forces immediate FSM evaluation for cavemen
	# This ensures wander is only used as a brief reset after task completion

func get_priority() -> float:
	# CRITICAL: When moving to deposit, stay in wander until we reach the claim (above herd_wildnpc 11.5)
	if npc and npc.has_meta("moving_to_deposit"):
		return 12.0  # Above herd_wildnpc so deposit wins when inventory full
	var npc_type_str: String = npc.get("npc_type") if npc else ""
	# Clansmen returning from BREAK: high priority so gather/herd cannot steal them back
	if npc_type_str == "clansman" and npc.has_meta("returning_from_break"):
		var until: float = npc.get_meta("returning_from_break") as float
		if Time.get_ticks_msec() / 1000.0 < until:
			return 13.0  # Above herd (11) and gather (4) — forces return-to-claim walk
		else:
			npc.remove_meta("returning_from_break")
	# Cavemen/clansmen: wander is NEVER productive - pure fallback when no gather/herd/defend can enter
	if npc_type_str == "caveman" or npc_type_str == "clansman":
		return 0.01  # Only enter when literally no other state can_enter
	
	# Default state for NPCs - medium priority when no other needs
	return 1.0

func get_data() -> Dictionary:
	return {
		"wander_radius": wander_radius,
		"wander_center": npc.steering_agent.wander_center if npc and npc.steering_agent else Vector2.ZERO
	}

# Land claim placement logic (moved from build_state)
var last_overlap_position: Vector2 = Vector2.ZERO
var overlap_cooldown: float = 0.0
const OVERLAP_COOLDOWN_DURATION: float = 3.0
const LAND_CLAIM_RADIUS: float = 400.0
const MIN_CLAIM_GAP: float = 400.0  # Minimum gap (px) between claim edges - matches build_state.gd

func _try_place_land_claim(delta: float) -> void:
	# Only place if conditions are met
	if not _can_place_land_claim():
		return
	
	# Update overlap cooldown
	if overlap_cooldown > 0.0:
		overlap_cooldown -= delta
		return
	
	# Place land claim where caveman is standing when cooldown ends
	var place_pos: Vector2 = npc.global_position
	place_pos.x = round(place_pos.x / 64.0) * 64.0  # Snap to 64px grid
	place_pos.y = round(place_pos.y / 64.0) * 64.0
	
	# Check if we're still at the same position where we detected overlap before
	var min_position_change: float = 500.0  # Must move at least 500px before retry (matches MIN_CLAIM_GAP + buffer)
	if last_overlap_position != Vector2.ZERO:
		var distance_moved: float = place_pos.distance_to(last_overlap_position)
		if distance_moved < min_position_change:
			return  # Still too close to last overlap position
	
	if _would_overlap_land_claim(place_pos):
		# Overlap detected, can't place here
		last_overlap_position = place_pos
		overlap_cooldown = OVERLAP_COOLDOWN_DURATION
		return
	
	# Clear overlap tracking if we're at a new valid position
	if last_overlap_position != Vector2.ZERO:
		last_overlap_position = Vector2.ZERO
	
	# No overlap, place immediately
	_place_land_claim(place_pos)

func _can_place_land_claim() -> bool:
	var npc_name: String = npc.get("npc_name") if npc else "unknown"
	
	# Check spawn cooldown - must wait 15 seconds after spawning (or bypass if 8+ items)
	var has_8_items: bool = false
	var total_items: int = 0
	if npc and npc.inventory:
		for i in range(npc.inventory.slot_count):
			var slot = npc.inventory.slots[i]
			if slot != null and slot.get("count", 0) > 0:
				total_items += slot.get("count", 0)
		if total_items >= 8:
			has_8_items = true
	
	if not has_8_items:
		var spawn_time: float = npc.get("spawn_time") if npc else 0.0
		var build_cooldown: float = 10.0  # Reduced from 15s to 10s for faster productivity
		if NPCConfig:
			var cooldown_prop = NPCConfig.get("caveman_build_cooldown_after_spawn")
			if cooldown_prop != null:
				build_cooldown = cooldown_prop as float
		var current_time: float = Time.get_ticks_msec() / 1000.0
		var time_since_spawn: float = current_time - spawn_time
		
		if spawn_time != 0.0 and time_since_spawn < build_cooldown:
			UnifiedLogger.log_npc("Can enter check: %s cannot place claim (cooldown_active)" % npc_name, {
				"npc": npc_name,
				"state": "wander_place_claim",
				"can_enter": false,
				"reason": "cooldown_active",
				"spawn_time": "%.2f" % spawn_time,
				"current_time": "%.2f" % current_time,
				"time_since_spawn": "%.2f" % time_since_spawn,
				"cooldown": "%.2f" % build_cooldown,
				"total_items": str(total_items)
			}, UnifiedLogger.Level.DEBUG)
			return false  # Still in cooldown
	
	# Must have a land claim item in inventory
	if not npc.inventory:
		UnifiedLogger.log_npc("Can enter check: %s cannot place claim (no_inventory)" % npc_name, {
			"npc": npc_name,
			"state": "wander_place_claim",
			"can_enter": false,
			"reason": "no_inventory"
		}, UnifiedLogger.Level.DEBUG)
		return false
	
	var has_landclaim: bool = npc.inventory.has_item(ResourceData.ResourceType.LANDCLAIM, 1)
	var landclaim_count: int = npc.inventory.get_count(ResourceData.ResourceType.LANDCLAIM) if npc.inventory else 0
	if not has_landclaim:
		UnifiedLogger.log_npc("Can enter check: %s cannot place claim (no_landclaim_item)" % npc_name, {
			"npc": npc_name,
			"state": "wander_place_claim",
			"can_enter": false,
			"reason": "no_landclaim_item",
			"has_landclaim": str(has_landclaim),
			"landclaim_count": str(landclaim_count),
			"total_items": str(total_items)
		}, UnifiedLogger.Level.DEBUG)
		return false
	
	# Cannot place if already has a land claim
	var clan_name_check: String = npc.get_clan_name() if npc.has_method("get_clan_name") else (npc.clan_name if npc else "")
	if clan_name_check != "" and clan_name_check != null:
		UnifiedLogger.log_npc("Can enter check: %s cannot place claim (already_has_claim)" % npc_name, {
			"npc": npc_name,
			"state": "wander_place_claim",
			"can_enter": false,
			"reason": "already_has_claim",
			"clan_name": clan_name_check
		}, UnifiedLogger.Level.DEBUG)
		return false
	
	UnifiedLogger.log_npc("Can enter check: %s can place claim (all_checks_passed)" % npc_name, {
		"npc": npc_name,
		"state": "wander_place_claim",
		"can_enter": true,
		"reason": "all_checks_passed",
		"total_items": str(total_items),
		"has_8_items": str(has_8_items),
		"landclaim_count": str(landclaim_count),
		"spawn_time": "%.2f" % (npc.get("spawn_time") if npc else 0.0)
	}, UnifiedLogger.Level.DEBUG)
	return true

func _would_overlap_land_claim(pos: Vector2) -> bool:
	# Check if placing a land claim at this position would be too close to any existing land claim
	# Min center-to-center = 2*radius + gap (e.g. 800 + 400 = 1200px) so claims have space between
	var land_claims := get_tree().get_nodes_in_group("land_claims")
	var min_distance: float = LAND_CLAIM_RADIUS * 2.0 + MIN_CLAIM_GAP
	for claim in land_claims:
		if not is_instance_valid(claim):
			continue
		var claim_pos: Vector2 = claim.global_position
		var distance: float = pos.distance_to(claim_pos)
		if distance < min_distance:
			return true
	return false

func _place_land_claim(place_pos: Vector2) -> void:
	if not npc:
		return
	
	# Get main scene
	var main: Node2D = get_tree().get_first_node_in_group("main")
	if not main:
		print("ERROR: Could not find main scene to place land claim")
		return
	
	# Generate a random clan name
	var clan_name: String = _generate_random_clan_name()
	
	# Remove land claim from inventory
	if npc.inventory:
		var before_count: int = npc.inventory.get_count(ResourceData.ResourceType.LANDCLAIM) if npc.inventory else 0
		# CRITICAL FIX: Remove ALL land claims (999) instead of just 1
		# NPCs start with 2 land claims, we need to remove all of them
		var removed: bool = npc.inventory.remove_item(ResourceData.ResourceType.LANDCLAIM, 999)
		var after_count: int = npc.inventory.get_count(ResourceData.ResourceType.LANDCLAIM) if npc.inventory else 0
		print("🔧 LAND CLAIM REMOVAL: %s - before=%d, removed=%s, after=%d" % [npc.npc_name, before_count, removed, after_count])
		if after_count > 0:
			print("❌ ERROR: %s still has %d LANDCLAIM in inventory after placement!" % [npc.npc_name, after_count])
	
	# Create land claim using main scene's method
	var used_main_method: bool = false
	if main.has_method("_place_npc_land_claim"):
		main._place_npc_land_claim(clan_name, place_pos, npc)
		used_main_method = true
	else:
		# Fallback: create directly
		var LAND_CLAIM_SCENE = preload("res://scenes/LandClaim.tscn")
		var land_claim: LandClaim = LAND_CLAIM_SCENE.instantiate() as LandClaim
		if land_claim:
			land_claim.global_position = place_pos
			land_claim.set_clan_name(clan_name)
			land_claim.owner_npc = npc
			land_claim.owner_npc_name = npc.npc_name
			land_claim.set_meta("owner_npc_name", npc.npc_name)
			
			var building_inventory := InventoryData.new(6, true, 999999)
			land_claim.inventory = building_inventory
			
			var world_objects: Node2D = main.get_node_or_null("WorldObjects")
			if world_objects:
				world_objects.add_child(land_claim)
				land_claim.visible = true
				# Phase 3: Register land claim for cache tracking
				if main.has_method("register_land_claim"):
					main.register_land_claim(land_claim)
	
	# Set caveman's clan name
	if npc.has_method("set_clan_name"):
		npc.set_clan_name(clan_name, "wander_state.gd")
	else:
		npc.clan_name = clan_name
		npc.set_meta("clan_name", clan_name)
	
	npc.set_meta("clan_name", clan_name)
	npc.set_meta("has_land_claim", true)
	npc.set_meta("land_claim_clan_name", clan_name)
	
	# CRITICAL: Verify clan_name is set before transitioning
	var verify_clan: String = npc.get_clan_name() if npc.has_method("get_clan_name") else (npc.clan_name if npc else "")
	print("✓ Caveman %s placed land claim at %s with name: %s (verified: '%s')" % [npc.npc_name, place_pos, clan_name, verify_clan])
	
	# Log smart placement info
	var nearby_resources = _find_nearby_resources(place_pos, 1600.0)
	if nearby_resources.size() > 0:
		print("  📍 Smart placement: Found %d resources within 1600px" % nearby_resources.size())
	else:
		print("  ⚠️ Poor spot: No resources within 1600px - NPC will struggle")
	
	if verify_clan == "" or verify_clan != clan_name:
		print("⚠️ WARNING: %s - clan_name not set correctly after land claim placement! Expected '%s', got '%s'" % [npc.npc_name, clan_name, verify_clan])
		# Force set it again
		npc.clan_name = clan_name
		npc.set_meta("clan_name", clan_name)
		npc.set_meta("land_claim_clan_name", clan_name)
		verify_clan = npc.get_clan_name() if npc.has_method("get_clan_name") else (npc.clan_name if npc else "")
		print("✓ Retry: %s - clan_name now: '%s'" % [npc.npc_name, verify_clan])
	
	UnifiedLogger.log_npc("Land claim placed: %s placed claim '%s' at %s" % [npc.npc_name, clan_name, place_pos], {
		"npc": npc.npc_name,
		"clan": clan_name,
		"pos": "%.1f,%.1f" % [place_pos.x, place_pos.y]
	})
	
	# After placing, transition directly to gather state (no delay)
	# BUT: Wait one frame to ensure clan_name is fully synced
	if fsm:
		# Wait one frame to ensure clan_name is set before can_enter() is called
		await get_tree().process_frame
		# Verify again before transition
		var final_clan: String = npc.get_clan_name() if npc.has_method("get_clan_name") else (npc.clan_name if npc else "")
		if final_clan == "" or final_clan != clan_name:
			print("❌ ERROR: %s - clan_name lost before gather transition! Expected '%s', got '%s'" % [npc.npc_name, clan_name, final_clan])
			# Force set one more time
			npc.clan_name = clan_name
			npc.set_meta("clan_name", clan_name)
			npc.set_meta("land_claim_clan_name", clan_name)
		# Force FSM evaluation so herd_wildnpc can compete with gather (priority-based)
		fsm.evaluation_timer = 0.0
		fsm._evaluate_states()
		print("✓ Wander State: %s placed claim, triggering FSM evaluation (clan: '%s', verified: '%s')" % [npc.npc_name, clan_name, npc.get_clan_name() if npc.has_method("get_clan_name") else (npc.clan_name if npc else "")])

func _generate_random_clan_name() -> String:
	# Generate a landclaim name using naming conventions: Cv CvCv or Cv CvvC
	const CONSONANTS: String = "BCDFGHJKLMNPQRSTVWXYZ"
	const VOWELS: String = "AEIOU"
	
	var prefix: String = ""
	prefix += CONSONANTS[randi() % CONSONANTS.length()]
	prefix += VOWELS[randi() % VOWELS.length()]
	
	var name: String = ""
	for i in 4:
		if i % 2 == 0:
			name += CONSONANTS[randi() % CONSONANTS.length()]
		else:
			name += VOWELS[randi() % VOWELS.length()]
	
	return (prefix + " " + name).to_upper()

# CAVEMAN SIM: Find smart land claim position near resources
func _find_smart_land_claim_position() -> Vector2:
	var current_pos: Vector2 = npc.global_position
	
	# Find nearby resources (within 1200-1600px detection range)
	var nearby_resources = _find_nearby_resources(current_pos, 1600.0)
	
	# If no resources found, use current position (bad spot - NPC will struggle)
	if nearby_resources.size() == 0:
		return current_pos
	
	# Find the closest resource cluster
	var best_resource: Node2D = null
	var best_distance: float = INF
	for resource in nearby_resources:
		if not is_instance_valid(resource):
			continue
		var distance: float = current_pos.distance_to(resource.global_position)
		if distance < best_distance:
			best_distance = distance
			best_resource = resource
	
	if not best_resource:
		return current_pos
	
	# Place land claim within 800-1200px of the resource (good spot)
	# This simulates cavemen settling near resources they find
	var resource_pos: Vector2 = best_resource.global_position
	var direction: Vector2 = (current_pos - resource_pos).normalized()
	if direction.length_squared() < 0.1:
		# If at same position, use random direction
		var angle := randf() * TAU
		direction = Vector2(cos(angle), sin(angle))
	
	# Place claim at 1000px from resource (optimal distance)
	var optimal_distance: float = 1000.0
	var claim_pos: Vector2 = resource_pos + direction * optimal_distance
	
	# Ensure claim is not too far from current position (max 2000px)
	var distance_from_current: float = current_pos.distance_to(claim_pos)
	if distance_from_current > 2000.0:
		# Too far, place closer to current position but still near resource
		var blend_factor: float = 2000.0 / distance_from_current
		claim_pos = current_pos.lerp(claim_pos, blend_factor)
	
	return claim_pos

# Find nearby resources within detection range
func _find_nearby_resources(center_pos: Vector2, detection_range: float) -> Array:
	var nearby: Array = []
	var resources := get_tree().get_nodes_in_group("resources")
	
	for resource in resources:
		if not is_instance_valid(resource):
			continue
		
		var distance: float = center_pos.distance_to(resource.global_position)
		
		# Only consider resources within detection range
		if distance <= detection_range:
			# Skip resources in enemy land claims (can't gather from them)
			if _is_position_in_enemy_land_claim(resource.global_position):
				continue
			
			nearby.append(resource)
	
	return nearby

# Check if position is in enemy land claim
func _is_position_in_enemy_land_claim(pos: Vector2) -> bool:
	var npc_clan: String = npc.get_clan_name() if npc and npc.has_method("get_clan_name") else (npc.clan_name if npc else "")
	if npc_clan == "":
		return false  # No clan yet, can't be in enemy claim
	
	var land_claims := get_tree().get_nodes_in_group("land_claims")
	for claim in land_claims:
		if not is_instance_valid(claim):
			continue
		
		var claim_clan_prop = claim.get("clan_name")
		var claim_clan: String = claim_clan_prop as String if claim_clan_prop != null else ""
		
		# Skip own land claim
		if claim_clan == npc_clan:
			continue
		
		# Check if position is within this land claim's radius
		var claim_pos: Vector2 = claim.global_position
		var claim_radius_prop = claim.get("radius")
		var claim_radius: float = claim_radius_prop as float if claim_radius_prop != null else 400.0
		
		var distance: float = pos.distance_to(claim_pos)
		if distance <= claim_radius:
			return true  # In enemy land claim
	
	return false

# LOGGING: Position tracking for oscillation detection
func _log_position_if_needed() -> void:
	var current_time: float = Time.get_ticks_msec() / 1000.0
	var last_log: float = npc.get_meta("last_position_log", 0.0)
	
	# Log every 0.5 seconds
	if current_time - last_log >= 0.5:
		var pos: Vector2 = npc.global_position
		var land_claim = _get_land_claim()
		var distance_to_claim: float = 0.0
		var claim_radius: float = 400.0
		
		if land_claim:
			distance_to_claim = pos.distance_to(land_claim.global_position)
			var radius_prop = land_claim.get("radius")
			if radius_prop != null:
				claim_radius = radius_prop as float
		
		var state_name: String = fsm.current_state_name if fsm else "none"
		var velocity: float = 0.0
		# Use npc.velocity directly if available, otherwise calculate from position change
		var npc_velocity_prop = npc.get("velocity")
		if npc_velocity_prop != null:
			velocity = (npc_velocity_prop as Vector2).length() if npc_velocity_prop is Vector2 else 0.0
		else:
			# Fallback: use position delta if velocity not available
			var last_pos: Vector2 = npc.get_meta("last_logged_position", pos)
			velocity = pos.distance_to(last_pos) / 0.5  # Distance / time (0.5s interval)
			npc.set_meta("last_logged_position", pos)
		
		UnifiedLogger.log_npc("POSITION: %s at (%.1f, %.1f), state=%s, distance_to_claim=%.1f/%.1f, velocity=%.1f" % [
			npc.npc_name, pos.x, pos.y, state_name, distance_to_claim, claim_radius, velocity
		], {
			"npc": npc.npc_name,
			"pos": "%.1f,%.1f" % [pos.x, pos.y],
			"state": state_name,
			"distance_to_claim": "%.1f" % distance_to_claim,
			"claim_radius": "%.1f" % claim_radius,
			"velocity": "%.1f" % velocity
		}, UnifiedLogger.Level.INFO)
		npc.set_meta("last_position_log", current_time)

# SIMPLIFIED: Helper functions - single responsibility

# Get used inventory slots (same pattern as gather_state)
func _get_used_slots() -> int:
	if not npc or not npc.inventory:
		return 0
	if npc.inventory.has_method("get_used_slots"):
		return npc.inventory.get_used_slots()
	var count: int = 0
	for i in range(npc.inventory.slot_count):
		var slot = npc.inventory.slots[i]
		if slot != null and slot.get("count", 0) > 0:
			count += 1
	return count

# Get land claim for this NPC (uses NPC's cached get_my_land_claim)
func _get_land_claim() -> Node2D:
	if not npc:
		return null
	var c = npc.get_my_land_claim() if npc.has_method("get_my_land_claim") else null
	return c as Node2D if c else null
