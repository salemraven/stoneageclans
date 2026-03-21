extends "res://scripts/npc/states/base_state.gd"

# Simplified Herd State - NPC follows the herder with simple distance-based logic
# SIMPLIFIED: Removed comfort zones, hysteresis, and movement detection for cleaner code

var needs_catchup: bool = false  # True when herder is too far away (>300px)
var last_target_update_time: float = 0.0  # Track when we last updated follow target
var target_update_interval: float = 0.3  # Update target every 0.3s (smoother, less jerky)
var current_target: Vector2 = Vector2.ZERO  # Current follow target

func enter() -> void:
	if not npc or not npc.herder or not is_instance_valid(npc.herder):
		if npc:
			# Phase 3: Use _clear_herd to keep herded_count in sync
			npc._clear_herd()
		return
	
	# Task System - Step 18: Cancel current job when entering herd (following takes priority)
	_cancel_tasks_if_active()
	if npc.task_runner and npc.task_runner.has_method("has_job") and npc.task_runner.has_job():
		UnifiedLogger.log_npc("HERD: %s cancelled job due to following" % npc.npc_name, {
			"npc": npc.npc_name,
			"event": "job_cancelled_herd"
		})
	
	last_target_update_time = Time.get_ticks_msec() / 1000.0
	var herder_name: String = npc.herder.name if is_instance_valid(npc.herder) else "unknown"
	UnifiedLogger.log_npc("NPC entered herd mode, following %s" % herder_name, {
		"npc": npc.npc_name,
		"leader": herder_name
	}, UnifiedLogger.Level.INFO)

func update(delta: float) -> void:
	if not npc:
		return
	
	# Dead NPCs can't be herded
	if npc.is_dead():
		return
	
	# CRITICAL: If we have no herder, exit herd state immediately
	if not npc.herder or not is_instance_valid(npc.herder):
		# Phase 3: Use _clear_herd to keep herded_count in sync
		npc._clear_herd()
		if npc.progress_display:
			npc.progress_display.stop_collection()
		if fsm:
			fsm.evaluation_timer = 0.0
		return
	
	# CRITICAL: If herder is dead, break herd and exit
	if npc.herder.has_method("is_dead") and npc.herder.is_dead():
		var herder_name: String = npc.herder.name if npc.herder else "unknown"
		print("🔄 %s exiting herd state - herder %s is dead" % [npc.npc_name, herder_name])
		
		# Phase 3: Use _clear_herd to keep herded_count in sync
		npc._clear_herd()
		
		# Make wild again if in a clan
		var npc_type_str: String = npc.get("npc_type") if npc else ""
		if npc_type_str == "woman" or npc_type_str == "sheep" or npc_type_str == "goat":
			if npc.clan_name != "":
				var old_clan = npc.clan_name
				npc.clan_name = ""
				print("🔄 %s became wild (herder died, was in clan: %s)" % [npc.npc_name, old_clan])
			else:
				print("🔄 %s became wild (herder died)" % npc.npc_name)
		
		if npc.progress_display:
			npc.progress_display.stop_collection()
		if fsm:
			fsm.evaluation_timer = 0.0
		return
	
	# Check clan joining (only if inside a land claim)
	_check_clan_joining()
	
	# Sheep/goats pathing to Farm/Dairy: building assignment overrides following
	if npc.npc_type == "sheep" or npc.npc_type == "goat":
		var ab = OccupationSystem.get_workplace(npc) if OccupationSystem else null
		if ab and is_instance_valid(ab):
			if npc.steering_agent:
				npc.steering_agent.set_target_position(ab.global_position)
			return  # Let npc_base handle confirm_arrival when close
	
	# Wild herdables (woman, sheep, goat) following caveman/clansman: always move toward leader
	# With herd resistance disabled, herd should stay tight and always move toward claim with leader
	var herder_ref: Node2D = npc.herder
	if not is_instance_valid(herder_ref):
		npc._clear_herd()
		if fsm:
			fsm.evaluation_timer = 0.0
		return
	var herder_type: String = herder_ref.get("npc_type") as String if herder_ref.get("npc_type") != null else ""
	var herder_is_player: bool = herder_ref.is_in_group("player")
	var is_wild_following_leader: bool = (npc.npc_type in ["woman", "sheep", "goat"]) and (herder_type in ["caveman", "clansman"] or herder_is_player)
	if is_wild_following_leader and npc.steering_agent:
		var herder_pos: Vector2 = herder_ref.global_position
		var dist_to_herder: float = npc.global_position.distance_to(herder_pos)
		var herd_break_dist: float = 300.0
		if NPCConfig and "herd_max_distance_before_break" in NPCConfig:
			herd_break_dist = NPCConfig.herd_max_distance_before_break as float
		if dist_to_herder >= herd_break_dist:
			npc._clear_herd()
			if npc.progress_display:
				npc.progress_display.stop_collection()
			if fsm:
				fsm.evaluation_timer = 0.0
			return
		npc.steering_agent.set_target_position(herder_pos)
		if "speed_multiplier" in npc.steering_agent:
			npc.steering_agent.speed_multiplier = 1.0
		return
	
	# Step 6: Formation only when agro < 70; GUARD = tight, FOLLOW = loose
	var agro: float = npc.get("agro_meter") as float if npc.get("agro_meter") != null else 0.0
	var formation_active: bool = (agro < 70.0)
	var ctx: Dictionary = npc.get("command_context") if npc.get("command_context") != null else {}
	var mode: String = ctx.get("mode", "FOLLOW") as String
	
	# Get config values; Step 6: GUARD = tight, FOLLOW = loose
	var is_hostile: bool = npc.get("is_hostile") as bool if npc.get("is_hostile") != null else false
	var distance_min: float = 50.0
	var distance_max: float = 150.0  # FOLLOW = loose
	var max_distance: float = 300.0
	if mode == "GUARD":
		distance_min = 28.0
		distance_max = 80.0   # GUARD = tight around leader
	var follow_ordered: bool = npc.get("follow_is_ordered") as bool if npc.get("follow_is_ordered") != null else false
	if mode == "GUARD" and follow_ordered:
		distance_max = 45.0   # Clansmen stay with leader in guard mode (was 58)
	if is_hostile:
		distance_min = 40.0
		distance_max = 120.0 if mode != "GUARD" else 70.0
		max_distance = 250.0
		if mode == "GUARD" and follow_ordered:
			distance_min = 32.0   # Tighter band when hostile guard
			distance_max = 45.0
	if NPCConfig:
		if not is_hostile and mode != "GUARD":
			distance_min = NPCConfig.herd_follow_distance_min
			distance_max = NPCConfig.herd_follow_distance_max
		var config_range = NPCConfig.get("herd_max_distance_before_break")
		if config_range != null and not is_hostile:
			max_distance = config_range as float
	
	# CRITICAL: Exit if no longer herded (clan joined, etc.)
	if not npc.is_herded:
		print("🏠 HERD_STATE: %s no longer herded (likely joined clan) - exiting to wander" % npc.npc_name)
		npc._clear_herd()
		if npc.progress_display:
			npc.progress_display.stop_collection()
		if fsm:
			fsm.evaluation_timer = 0.0
			fsm.change_state("wander")
		return
	
	# CRITICAL: Re-check herder validity (it might have been cleared by _check_clan_joining())
	if not npc.herder or not is_instance_valid(npc.herder):
		print("🏠 HERD_STATE: %s has no valid herder - exiting" % npc.npc_name)
		# Phase 3: Use _clear_herd to keep herded_count in sync
		npc._clear_herd()
		if npc.progress_display:
			npc.progress_display.stop_collection()
		if fsm:
			fsm.evaluation_timer = 0.0
		return
	
	# herder_ref already captured above for wild herdables; re-capture for formation logic
	herder_ref = npc.herder
	if not is_instance_valid(herder_ref):
		npc._clear_herd()
		if fsm:
			fsm.evaluation_timer = 0.0
		return
	
	# Calculate distance to herder once
	var herder_pos: Vector2 = herder_ref.global_position
	var distance_to_herder: float = npc.global_position.distance_to(herder_pos)
	
	# Ordered follow: normally unbreakable until Break Follow or herder death
	# GUARD exception: max distance — break if too far, unless broken away for agro (in combat)
	if npc.get("follow_is_ordered") and mode == "GUARD":
		const MAX_GUARD_DISTANCE: float = 120.0  # Guards must stay within this of leader
		if distance_to_herder > MAX_GUARD_DISTANCE:
			var in_combat: bool = (agro >= 70.0)
			if not in_combat and npc.fsm:
				var st: String = npc.fsm.get_current_state_name() if npc.fsm.has_method("get_current_state_name") else ""
				in_combat = (st == "combat")
			if not in_combat:
				# Exceeded max guard distance and not in combat — break herd
				npc._clear_herd()
				if npc.progress_display:
					npc.progress_display.stop_collection()
				if fsm:
					fsm.evaluation_timer = 0.0
				return
	if npc.get("follow_is_ordered") and mode != "GUARD":
		# Non-GUARD ordered: no distance break
		pass
	elif not npc.get("follow_is_ordered"):
		# CRITICAL: Validate distance is reasonable (detect teleportation/position errors)
		# If distance is > 5000px, something is wrong (teleportation or invalid position)
		if distance_to_herder > 5000.0:
			print("⚠️ TELEPORTATION DETECTED: %s herder %s is %.1fpx away (likely teleported!)" % [
				npc.npc_name,
				herder_ref.name if is_instance_valid(herder_ref) else "unknown",
				distance_to_herder
			])
			# Phase 3: Use _clear_herd to keep herded_count in sync
			npc._clear_herd()
			if npc.progress_display:
				npc.progress_display.stop_collection()
			if fsm:
				fsm.evaluation_timer = 0.0
			return
		
		# Break herd if too far (600px)
		if distance_to_herder >= max_distance:
			var herder_name_brk: String = herder_ref.name if is_instance_valid(herder_ref) else "unknown"
			UnifiedLogger.log_npc("NPC lost herder %s (outside perception range: %.1f >= %.1f)" % [
				herder_name_brk,
				distance_to_herder,
				max_distance
			], {
				"npc": npc.npc_name,
				"leader": herder_name_brk,
				"distance": "%.1f" % distance_to_herder,
				"max_distance": "%.1f" % max_distance
			}, UnifiedLogger.Level.WARNING)
			var herder_name: String = herder_name_brk
			UnifiedLogger.log_herding("Herd detection: herd_broken_distance", {
				"npc": npc.npc_name,
				"leader": herder_name,
				"event": "herd_broken_distance",
				"distance": "%.1f" % distance_to_herder,
				"max_distance": "%.1f" % max_distance
			})
			# Phase 3: Use _clear_herd to keep herded_count in sync
			npc._clear_herd()
			if npc.progress_display:
				npc.progress_display.stop_collection()
			if fsm:
				fsm.evaluation_timer = 0.0
			return
	
	# SIMPLIFIED: Simple 3-band distance logic
	needs_catchup = distance_to_herder > distance_max
	
	# Step 6: Formation only when agro < 70 (combat ignores formation)
	var current_time: float = Time.get_ticks_msec() / 1000.0
	var update_interval: float = target_update_interval
	if mode == "GUARD" and follow_ordered:
		update_interval = 0.15  # Update often so clansmen stay with leader
	var should_update_target: bool = formation_active and (current_time - last_target_update_time >= update_interval)
	if needs_catchup or distance_to_herder < distance_min:
		should_update_target = should_update_target or formation_active
	if should_update_target and not formation_active:
		should_update_target = false
	
	if should_update_target:
		last_target_update_time = current_time
		
		var ideal_distance: float = (distance_min + distance_max) / 2.0  # Middle of band
		# GUARD + ordered: minimal variation so clansmen stay with leader
		var distance_variation: float = randf_range(-15.0, 15.0)
		if mode == "GUARD" and follow_ordered:
			distance_variation = randf_range(-6.0, 6.0)
		var target_distance: float = ideal_distance + distance_variation
		if mode == "GUARD" and follow_ordered:
			target_distance = clampf(target_distance, distance_min, distance_max)
		
		var target: Vector2
		var backing_up: bool = false  # Track if we're backing up (too close)
		
		# Formation: ordered followers stay behind player and spread in semicircle (herder_is_player from 98)
		if follow_ordered and mode == "GUARD" and not herder_is_player:
			# GUARD formation around NPC leader: clansmen form arc in front to protect leader
			var co_followers: Array = []
			var npcs_list = npc.get_tree().get_nodes_in_group("npcs")
			for n in npcs_list:
				if not is_instance_valid(n) or n.get("herder") != herder_ref:
					continue
				if not (n.get("is_herded") == true):
					continue
				co_followers.append(n)
			co_followers.sort_custom(func(a, b): return a.get_instance_id() < b.get_instance_id())
			var my_index: int = co_followers.find(npc)
			if my_index < 0:
				my_index = 0
			var count: int = co_followers.size()
			var facing: Vector2 = Vector2(1, 0)
			var leader_sa = herder_ref.get("steering_agent")
			if leader_sa:
				var leader_target: Vector2 = leader_sa.target_position
				var to_target: Vector2 = leader_target - herder_pos
				if to_target.length_squared() > 100.0:
					facing = to_target.normalized()
			var spread_angle: float = -PI / 2.0 + (PI * my_index) / max(1, count - 1) if count > 1 else 0.0
			var formation_dir: Vector2 = facing.rotated(spread_angle)
			target = herder_pos + formation_dir * target_distance
		elif follow_ordered and herder_is_player:
			# Match player movement speed
			var player_speed: float = herder_ref.get("move_speed") if herder_ref.get("move_speed") != null else 200.0
			if npc.steering_agent:
				npc.steering_agent.max_speed = player_speed
			var player_vel: Vector2 = herder_ref.velocity if "velocity" in herder_ref else Vector2.ZERO
			var player_stopped: bool = player_vel.length() < 1.0
			# When player stopped and we're close to formation position, skip target update so followers can stop
			var skip_update: bool = false
			if player_stopped and current_target != Vector2.ZERO:
				var dist_to_target: float = npc.global_position.distance_to(current_target)
				if dist_to_target < 25.0:
					skip_update = true
			if skip_update:
				target = current_target  # Keep last target so steering stops when close
			else:
				var co_followers: Array = []
				var npcs_list = npc.get_tree().get_nodes_in_group("npcs")
				for n in npcs_list:
					if not is_instance_valid(n) or n.get("herder") != herder_ref:
						continue
					if not (n.get("is_herded") == true):
						continue
					co_followers.append(n)
				co_followers.sort_custom(func(a, b): return a.get_instance_id() < b.get_instance_id())
				var my_index: int = co_followers.find(npc)
				if my_index < 0:
					my_index = 0
				var count: int = co_followers.size()
				var facing: Vector2
				if player_vel.length() > 0:
					facing = player_vel.normalized()
				else:
					facing = herder_ref.get("last_facing") as Vector2 if herder_ref.get("last_facing") != null else Vector2(0, 1)
					if facing == Vector2.ZERO:
						facing = Vector2(0, 1)
					else:
						facing = facing.normalized()
				var behind_dir: Vector2 = -facing
				var spread_angle: float = -PI / 2.0 + (PI * my_index) / max(1, count - 1) if count > 1 else 0.0
				var formation_dir: Vector2 = behind_dir.rotated(spread_angle)
				# When player stopped, use exact distance (no variation) so target is stable
				var formation_dist: float = ideal_distance if player_stopped else target_distance
				target = herder_pos + formation_dir * formation_dist
		elif distance_to_herder < distance_min:
			# Too close (<50px) - back up to ideal distance VERY SLOWLY
			# Slow backing up prevents triggering reverse herding (caveman won't follow slow movement)
			var direction: Vector2 = (npc.global_position - herder_pos).normalized()
			if direction == Vector2.ZERO:
				# If exactly on top, pick a random direction
				var angle: float = randf() * TAU
				direction = Vector2(cos(angle), sin(angle))
			target = herder_pos + direction * target_distance
			backing_up = true  # Mark that we're backing up
		elif distance_to_herder > distance_max:
			# Too far (>300px) - catch up directly to herder
			target = herder_pos
			if npc.progress_display:
				npc.progress_display.stop_collection()  # Stop gathering when catching up
		else:
			# Good distance (50-300px) - maintain ideal distance along herder-follower line
			# Line-based target: point at ideal distance from herder along the line to follower.
			# This always yields movement toward herder (no cone-induced jitter or FOLLOWER_MOVEMENT_FIXED).
			var direction_to_herder: Vector2 = (herder_pos - npc.global_position).normalized()
			target = herder_pos - direction_to_herder * target_distance
		
		current_target = target
		
		# Apply movement
		if npc.steering_agent:
			npc.steering_agent.set_target_position(current_target)
			# HOSTILE MODE: Faster speed to stay in AOP
			if "speed_multiplier" in npc.steering_agent:
				if backing_up:
					# Backing up - use VERY slow speed (0.15x = 15% of normal speed)
					# This prevents reverse herding - caveman won't follow such slow movement
					npc.steering_agent.speed_multiplier = 0.15  # Very slow when backing up
				else:
					# Normal following speed (speed boosts disabled)
					npc.steering_agent.speed_multiplier = 1.0
	else:
		# Continue moving toward last target (smoother, less jerky)
		if npc.steering_agent and current_target != Vector2.ZERO:
			npc.steering_agent.set_target_position(current_target)
			if "speed_multiplier" in npc.steering_agent:
				npc.steering_agent.speed_multiplier = 1.0  # Speed boosts disabled

# Delegates to unified npc_base clan join. Handles caveman (cannot join) separately.
func _check_clan_joining() -> void:
	if not npc.can_join_clan():
		# Caveman in claim: release (can't join). Only when inside a claim.
		var inside: Dictionary = npc.is_inside_land_claim() if npc.has_method("is_inside_land_claim") else {}
		if inside.is_empty():
			return
		if npc.get("follow_is_ordered"):
			return
		npc._clear_herd()
		if npc.progress_display:
			npc.progress_display.stop_collection()
		if fsm:
			fsm.evaluation_timer = 0.0
		UnifiedLogger.log_npc("NPC (caveman) cannot join clan - released from herd mode", {
			"npc": npc.npc_name,
			"reason": "caveman_cannot_join"
		}, UnifiedLogger.Level.WARNING)
		return
	var skip_release: bool = npc.get("follow_is_ordered") as bool if npc.get("follow_is_ordered") != null else false
	if npc._try_join_clan_from_claim(skip_release):
		if not skip_release:
			if npc.progress_display and is_instance_valid(npc.progress_display):
				npc.progress_display.stop_collection()

func can_enter() -> bool:
	if not npc:
		return false
	
	# Dead NPCs can't be herded
	if npc.is_dead():
		return false
	
	# CRITICAL: Cannot herd while defending or in combat - these take priority
	if _is_defending():
		return false  # Defending - cannot herd
	
	if _is_in_combat():
		return false  # In combat - cannot herd
	
	var npc_name: String = npc.get("npc_name") if npc else "unknown"
	
	if not npc:
		UnifiedLogger.log_npc("Can enter check: %s cannot enter herd (npc_is_null)" % npc_name, {
			"npc": npc_name,
			"state": "herd",
			"can_enter": false,
			"reason": "npc_is_null"
		}, UnifiedLogger.Level.DEBUG)
		return false
	
	# Cavemen/clansmen cannot enter herd state unless ordered follow (player or agro-combat-test NPC leader)
	var npc_type_str: String = npc.get("npc_type") if npc else ""
	var herder_valid: bool = npc.herder != null and is_instance_valid(npc.herder)
	var ordered_follow_player: bool = npc.get("follow_is_ordered") and herder_valid and npc.herder.is_in_group("player")
	var agro_test_npc_leader: bool = npc.get("follow_is_ordered") and herder_valid and _is_agro_combat_test()
	if (npc_type_str == "caveman" or npc_type_str == "clansman") and not ordered_follow_player and not agro_test_npc_leader:
		if npc_type_str == "caveman":
			# Phase 3: Use _clear_herd to keep herded_count in sync
			npc._clear_herd()
		UnifiedLogger.log_npc("Can enter check: %s cannot enter herd (cavemen_clansmen_cannot_herd)" % npc_name, {
			"npc": npc_name,
			"state": "herd",
			"can_enter": false,
			"reason": "cavemen_clansmen_cannot_herd"
		}, UnifiedLogger.Level.DEBUG)
		return false
	
	var can_enter_result: bool = npc.is_herded and npc.herder != null and is_instance_valid(npc.herder)
	var reason: String = ""
	if not npc.is_herded:
		reason = "not_herded"
	elif npc.herder == null:
		reason = "herder_is_null"
	elif not is_instance_valid(npc.herder):
		reason = "herder_invalid"
	else:
		reason = "can_enter"
	var herder_name: String = npc.herder.name if npc.herder and is_instance_valid(npc.herder) else "unknown"
	UnifiedLogger.log_npc("Can enter check: %s %s enter herd (%s)" % [npc_name, "can" if can_enter_result else "cannot", reason], {
		"npc": npc_name,
		"state": "herd",
		"can_enter": can_enter_result,
		"reason": reason,
		"herder": herder_name
	}, UnifiedLogger.Level.DEBUG)
	
	return can_enter_result

func get_priority() -> float:
	if not npc:
		return 0.0
	
	# CRITICAL: Following (player command) takes priority over defend (8.0)
	# Player orders override auto-defense assignments
	# However, combat (12.0) still beats following (11.0) - life over orders
	
	# High priority when catching up
	if needs_catchup:
		var catchup_priority: float = 15.0
		if NPCConfig:
			var config_priority = NPCConfig.get("herd_catchup_priority")
			if config_priority != null:
				catchup_priority = config_priority as float
		return max(catchup_priority, 11.0)
	
	# High priority for herding (higher than eat state)
	var priority: float = 11.0
	if NPCConfig:
		var config_priority = NPCConfig.get("priority_herd")
		if config_priority != null:
			priority = config_priority as float
		priority = max(priority, 11.0)
	
	return priority

func get_data() -> Dictionary:
	var data: Dictionary = {
		"is_herded": npc.is_herded if npc else false,
		"has_herder": npc.herder != null if npc else false,
		"needs_catchup": needs_catchup if npc else false
	}
	if npc and npc.herder:
		var distance: float = npc.global_position.distance_to(npc.herder.global_position) if is_instance_valid(npc.herder) else 0.0
		data["herder_distance"] = distance
		data["herder_name"] = npc.herder.name if is_instance_valid(npc.herder) else "unknown"
	return data

func _is_agro_combat_test() -> bool:
	"""Agro combat test: herder can be NPC leader (not just player)."""
	var dc = get_node_or_null("/root/DebugConfig")
	return dc != null and dc.get("enable_agro_combat_test") == true

func exit() -> void:
	_cancel_tasks_if_active()
