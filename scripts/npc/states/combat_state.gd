extends "res://scripts/npc/states/base_state.gd"

# Preload PerceptionArea so it resolves (avoids "Could not find type" when run from CLI)
const PerceptionArea = preload("res://scripts/npc/components/perception_area.gd")
const CombatAllyCheck = preload("res://scripts/systems/combat_ally_check.gd")

# Combat State - NPCs attack enemies when agro_meter >= 70
# Agro meter increases when attacked, decreases over time when not in combat

var combat_target: Node2D = null  # NPCBase or player when defending vs intruders
var attack_range: float = 100.0
const TARGET_CHECK_INTERVAL := 2.0  # Check for new targets every 2 seconds (reduced frequency)
var next_target_check_time := 0

# Defenders: max distance from claim center to chase (prevents kiting)
const DEFENDER_PURSUIT_FACTOR := 1.4  # claim_radius * this = max chase distance (e.g. 560px for 400 radius)
static var _raid_blocked_logged: bool = false
# RTS-style: spread attackers around target so they don't stack on one spot
const COMBAT_SPREAD_RADIUS := 48.0  # px offset per NPC (stable angle from instance_id)

func _combat_spread_offset(npc_node: Node) -> Vector2:
	var angle: float = fmod(npc_node.get_instance_id() * 0.618033988749, TAU)
	return Vector2(cos(angle), sin(angle)) * COMBAT_SPREAD_RADIUS

func _clear_combat_target_and_exit() -> void:
	"""Clear combat target and force FSM re-evaluation (used when target is invalid e.g. player when following)."""
	if npc:
		npc.set("combat_target_id", -1)
		npc.set("combat_target", null)
		if "combat_target_id" in npc:
			npc.combat_target_id = -1
		if "combat_target" in npc:
			npc.combat_target = null
		if fsm and fsm.has_method("force_evaluation"):
			fsm.force_evaluation()
	combat_target = null

func enter() -> void:
	if not npc:
		return
	
	# Task System - Step 18: Cancel current job when entering combat
	_cancel_tasks_if_active()
	if npc and npc.task_runner and npc.task_runner.has_method("has_job") and npc.task_runner.has_job():
		var npc_name_safe: String = "unknown"
		if npc:
			var name_val = npc.get("npc_name")
			if name_val != null:
				npc_name_safe = str(name_val)
		UnifiedLogger.log_npc("COMBAT: %s cancelled gather job due to combat" % npc_name_safe, {
			"npc": npc_name_safe,
			"event": "job_cancelled_combat"
		})
	
	# Get combat target (set by FSM or intrusion) — NPCBase or player
	var target_prop = npc.get("combat_target")
	if target_prop != null and target_prop is Node2D:
		combat_target = target_prop as Node2D
	
	# Never enter combat vs allies (clan, herder, shared claim, player membership — see CombatAllyCheck)
	if combat_target and npc and is_instance_valid(combat_target) and CombatAllyCheck.is_ally(npc, combat_target):
		_clear_combat_target_and_exit()
		return
	
	# Set target in combat component
	var combat_comp: CombatComponent = npc.get_node_or_null("CombatComponent")
	if combat_comp:
		combat_comp.set_target(combat_target)
	
	var target_name: String = "none"
	var npc_clan: String = ""
	var target_clan: String = ""
	if npc:
		npc_clan = npc.get_clan_name() if npc.has_method("get_clan_name") else ""
	if combat_target:
		if combat_target is NPCBase:
			target_name = combat_target.npc_name
			target_clan = combat_target.get_clan_name() if combat_target.has_method("get_clan_name") else ""
		elif combat_target.is_in_group("player"):
			target_name = "Player"
			target_clan = combat_target.get_clan_name() if combat_target.has_method("get_clan_name") else ""
		else:
			target_name = "unknown"
	# Only log combat entry once (not every frame)
	var last_combat_entry = npc.get_meta("last_combat_entry_logged", null) if npc and npc.has_meta("last_combat_entry_logged") else null
	if not last_combat_entry or last_combat_entry != combat_target:
		var npc_name_safe: String = "NPC"
		if npc and is_instance_valid(npc):
			var name_val = npc.get("npc_name")
			if name_val != null:
				npc_name_safe = str(name_val)
		print("⚔️ %s entering COMBAT state (target: %s, npc_clan: %s, target_clan: %s)" % [
			npc_name_safe,
			target_name,
			npc_clan,
			target_clan
		])
		if npc:
			npc.set_meta("last_combat_entry_logged", combat_target)
		var pi = npc.get_node_or_null("/root/PlaytestInstrumentor")
		if pi and pi.is_enabled():
			var ff: bool = combat_target != null and is_instance_valid(combat_target) and CombatAllyCheck.is_ally(npc, combat_target)
			pi.combat_started(npc_name_safe, target_name, npc_clan, target_clan, ff)
	
	if npc.hostile_indicator:
		npc.hostile_indicator.visible = true
	
	if npc.steering_agent and npc.steering_agent.has_method("restore_original_speed"):
		npc.steering_agent.restore_original_speed()

func exit() -> void:
	_cancel_tasks_if_active()
	if npc:
		var combat_comp: CombatComponent = npc.get_node_or_null("CombatComponent")
		if combat_comp:
			combat_comp.clear_target()
		# CRITICAL: Clear combat_target when exiting combat state
		# This prevents NPCs from retaining invalid targets (like dead enemies or same-clan players)
		npc.set("combat_target_id", -1)
		npc.set("combat_target", null)
		combat_target = null
		if "combat_target_id" in npc:
			npc.combat_target_id = -1
		if npc.hostile_indicator:
			npc.hostile_indicator.visible = false
		if npc.has_method("reset_agro_after_combat"):
			npc.reset_agro_after_combat()
			var pi_ar: Node = npc.get_node_or_null("/root/PlaytestInstrumentor")
			if pi_ar and pi_ar.is_enabled():
				var _ctx_ar: Dictionary = npc.get("command_context") if npc.get("command_context") != null else {}
				var _mode_ar: String = str(_ctx_ar.get("mode", "NONE"))
				var _new_agro: float = npc.get("agro_meter") as float if npc.get("agro_meter") != null else 0.0
				pi_ar.clansman_agro_reset(str(npc.get("npc_name")), _mode_ar, _new_agro)
		# Clear combat entry logging meta when exiting
		if npc.has_meta("last_combat_entry_logged"):
			npc.remove_meta("last_combat_entry_logged")
		# Safe access to npc_name (might be null if NPC is being destroyed)
		var npc_name_str: String = "unknown"
		if npc and is_instance_valid(npc):
			var name_value = npc.get("npc_name")
			if name_value != null:
				npc_name_str = str(name_value)
		print("⚔️ %s exiting COMBAT state" % npc_name_str)
		var pi = npc.get_node_or_null("/root/PlaytestInstrumentor")
		if pi and pi.is_enabled():
			pi.combat_ended(npc_name_str, "unknown")

func update(_delta: float) -> void:
	if not npc:
		return
	
	# Check if dead
	var health_comp: HealthComponent = npc.get_node_or_null("HealthComponent")
	if health_comp and health_comp.is_dead:
		return
	
	# Step 3: Resolve combat_target from combat_target_id; invalid target → agro 69, clear intent
	combat_target = npc.resolve_combat_target() as Node2D
	if not combat_target:
		return

	# Defenders: don't chase too far from border (prevents kiting)
	if combat_target and is_instance_valid(combat_target):
		var dt = npc.get("defend_target")
		if dt and is_instance_valid(dt):
			var claim_pos: Vector2 = dt.global_position
			var rp = dt.get("radius")
			var claim_radius: float = rp as float if rp != null else 400.0
			var pursuit_limit: float = claim_radius * DEFENDER_PURSUIT_FACTOR
			var target_dist: float = claim_pos.distance_to(combat_target.global_position)
			if target_dist > pursuit_limit:
				npc.set("combat_target_id", -1)
				npc.set("combat_target", null)
				combat_target = null
				if "combat_target_id" in npc:
					npc.combat_target_id = -1
				var combat_comp_drop: CombatComponent = npc.get_node_or_null("CombatComponent")
				if combat_comp_drop:
					combat_comp_drop.clear_target()
				if fsm and fsm.has_method("force_evaluation"):
					fsm.force_evaluation()
				return
	
	# Ordered followers: don't chase beyond mode-specific distance from leader
	if npc.get("follow_is_ordered") and npc.get("herder") and is_instance_valid(npc.get("herder")):
		var leader_pos: Vector2 = npc.herder.global_position
		var dist_from_leader: float = npc.global_position.distance_to(leader_pos)
		var ctx_leash: Dictionary = npc.get("command_context") if npc.get("command_context") != null else {}
		var mode_leash: String = str(ctx_leash.get("mode", "FOLLOW"))
		var max_chase: float = 150.0
		if mode_leash == "GUARD":
			max_chase = 200.0
		elif mode_leash == "ATTACK":
			max_chase = 400.0
		if dist_from_leader > max_chase:
			var pi_lb: Node = npc.get_node_or_null("/root/PlaytestInstrumentor")
			if pi_lb and pi_lb.is_enabled():
				pi_lb.clansman_leash_break(str(npc.get("npc_name")), mode_leash, dist_from_leader, max_chase)
			_clear_combat_target_and_exit()
			return
	
	# CRITICAL: Combat takes priority over following - life over orders
	# Even if NPC is following, combat (12.0) beats following (11.0)
	# This ensures NPCs defend themselves even when ordered to follow
	
	# OPTIMIZATION: Tasks are cancelled on enter() - no need to cancel every frame
	# Removed per-frame _cancel_tasks_if_active() call for performance
	
	# Log position for combat state (throttled to once per second)
	var now = Time.get_ticks_msec()
	if not npc.has_meta("last_combat_position_log"):
		npc.set_meta("last_combat_position_log", 0)
	var last_log = npc.get_meta("last_combat_position_log", 0)
	if now - last_log >= 1000:  # Log once per second
		var velocity = npc.get("velocity") as Vector2 if npc.has_method("get") else Vector2.ZERO
		var velocity_magnitude = velocity.length() if velocity else 0.0
		var distance_to_claim = 0.0
		var claim_radius = 400.0
		# Try to get land claim info if available
		var land_claims = npc.get_tree().get_nodes_in_group("land_claims") if npc.get_tree() else []
		for claim in land_claims:
			if claim and is_instance_valid(claim):
				var claim_clan = claim.get("clan_name") if claim else ""
				var npc_clan = npc.get("clan_name") if npc.has_method("get") else ""
				if claim_clan == npc_clan and npc_clan != "":
					var claim_pos = claim.global_position if claim else Vector2.ZERO
					distance_to_claim = npc.global_position.distance_to(claim_pos)
					claim_radius = claim.get("radius") if claim else 400.0
					break
		var npc_name_safe: String = "unknown"
		var npc_pos_x: float = 0.0
		var npc_pos_y: float = 0.0
		if npc and is_instance_valid(npc):
			var name_val = npc.get("npc_name")
			if name_val != null:
				npc_name_safe = str(name_val)
			npc_pos_x = npc.global_position.x
			npc_pos_y = npc.global_position.y
		UnifiedLogger.log_npc("POSITION: %s at (%.1f, %.1f), state=combat, distance_to_claim=%.1f/%.1f, velocity=%.1f" % [
			npc_name_safe,
			npc_pos_x,
			npc_pos_y,
			distance_to_claim,
			claim_radius,
			velocity_magnitude
		], {
			"npc": npc_name_safe,
			"pos": "%f,%f" % [npc_pos_x, npc_pos_y],
			"state": "combat",
			"distance_to_claim": distance_to_claim,
			"claim_radius": claim_radius,
			"velocity": velocity_magnitude
		})
		npc.set_meta("last_combat_position_log", now)
	
	# Update targeting (with throttling)
	_update_targeting()
	
	if not combat_target:
		return
	
	# Get combat component for attack range
	var combat_comp: CombatComponent = npc.get_node_or_null("CombatComponent")
	var optimal_attack_range = combat_comp.attack_range if combat_comp else attack_range
	
	# Calculate distances and direction
	var distance = npc.global_position.distance_to(combat_target.global_position)
	var direction_to_target = (combat_target.global_position - npc.global_position).normalized()
	var horizontal_distance = abs(combat_target.global_position.x - npc.global_position.x)
	var vertical_distance = abs(combat_target.global_position.y - npc.global_position.y)
	
	# Calculate optimal attack position (head-on, face-to-face)
	# ROOT FIX: Simplified logic with position stability to prevent infinite repositioning loop
	var needs_repositioning = false
	var target_position = combat_target.global_position
	
	# Track last target position to prevent constant recalculation
	if not npc.has_meta("last_combat_target_position"):
		npc.set_meta("last_combat_target_position", Vector2.ZERO)
		npc.set_meta("last_steering_target", Vector2.ZERO)
	
	var last_target_pos = npc.get_meta("last_combat_target_position", Vector2.ZERO)
	var last_steering_target = npc.get_meta("last_steering_target", Vector2.ZERO)
	var target_moved = combat_target.global_position.distance_to(last_target_pos) > 10.0  # Reduced threshold for more responsive tracking
	
	# Per-NPC spread offset (RTS-style: don't stack on same spot)
	var spread_offset: Vector2 = _combat_spread_offset(npc)
	# Simplified repositioning logic (more lenient to prevent oscillation)
	if distance > optimal_attack_range * 1.2:
		# Too far - move closer (but allow some range flexibility)
		needs_repositioning = true
		target_position = combat_target.global_position + spread_offset
	elif abs(vertical_distance) > 55.0:
		# Significant vertical misalignment - reposition to same Y level (55px tolerance for defenders)
		var preferred_y = combat_target.global_position.y
		var offset_x = sign(npc.global_position.x - combat_target.global_position.x) * optimal_attack_range * 0.7
		target_position = Vector2(combat_target.global_position.x + offset_x, preferred_y) + spread_offset
		needs_repositioning = true
	else:
		# In range - check if we're roughly head-on (more lenient)
		var sprite: Sprite2D = npc.get_node_or_null("Sprite")
		var facing_direction: Vector2 = Vector2(1, 0)
		if sprite:
			facing_direction = Vector2(-1 if sprite.flip_h else 1, 0)
		
		var angle_to_target = direction_to_target.angle_to(facing_direction)
		var is_head_on = abs(angle_to_target) < PI / 2.5  # ~72 degrees tolerance (more lenient)
		
		# Only reposition if severely misaligned (prevents oscillation; 50px for defenders)
		if not is_head_on and abs(vertical_distance) > 50.0:
			# Severely misaligned - reposition
			var preferred_y = combat_target.global_position.y
			var offset_x = sign(npc.global_position.x - combat_target.global_position.x) * optimal_attack_range * 0.7
			target_position = Vector2(combat_target.global_position.x + offset_x, preferred_y) + spread_offset
			needs_repositioning = true
	
	# CRITICAL: Only update steering target if position changed significantly (prevents infinite loop)
	if needs_repositioning:
		# Check if we're already close to the target position (position stability)
		var distance_to_steering_target = npc.global_position.distance_to(last_steering_target)
		var steering_target_changed = target_position.distance_to(last_steering_target) > 20.0  # Only update if >20px different
		
		# Only update steering if: target moved significantly OR steering target changed significantly
		# FIX: Reduced threshold from 30.0 to 15.0 to allow more responsive movement
		if target_moved or steering_target_changed or distance_to_steering_target > 15.0:
			if npc.steering_agent:
				npc.steering_agent.set_target_position(target_position)
				npc.set_meta("last_steering_target", target_position)
		
		# Update last target position
		npc.set_meta("last_combat_target_position", combat_target.global_position)
	else:
		# In range and head-on aligned - maintain position but allow tracking of moving target
		# CRITICAL FIX: Don't set target to current position - this causes NPCs to stop moving
		# Instead, always track target movement to maintain optimal combat range
		if npc.steering_agent:
			# If target moved, update steering to track it (maintains combat range)
			if target_moved:
				# Calculate position to maintain optimal range from moving target (RTS spread applied)
				var direction_to_target_normalized = direction_to_target
				var maintain_distance = optimal_attack_range * 0.85  # Slightly closer than max range
				var ideal_position = combat_target.global_position - direction_to_target_normalized * maintain_distance + _combat_spread_offset(npc)
				npc.steering_agent.set_target_position(ideal_position)
				npc.set_meta("last_steering_target", ideal_position)
			# If target hasn't moved much, check if we need small adjustment
			elif distance < optimal_attack_range * 0.7:
				# Too close - back up slightly
				var direction_away = -direction_to_target
				var back_off_position = npc.global_position + direction_away * 10.0
				npc.steering_agent.set_target_position(back_off_position)
				npc.set_meta("last_steering_target", back_off_position)
			elif distance > optimal_attack_range * 0.95:
				# Getting too far - move closer (RTS spread applied)
				var move_closer_position = combat_target.global_position - direction_to_target * optimal_attack_range * 0.85 + _combat_spread_offset(npc)
				npc.steering_agent.set_target_position(move_closer_position)
				npc.set_meta("last_steering_target", move_closer_position)
			# If in good range (70-95% of attack range), don't set steering target
			# This allows NPC to maintain position naturally without forced movement
		
		# In range and head-on aligned - request attack (event-driven system)
		# CRITICAL: Only request attack if combat component is IDLE (not already attacking)
		if combat_comp:
			# Only request attack if not already in windup/recovery
			if combat_comp.state == CombatComponent.CombatState.IDLE:
				# Additional validation: Check if target is actually attackable (range + arc + head-on)
				if distance <= combat_comp.attack_range:
					# Verify we're head-on aligned (not attacking from top/bottom)
					# More lenient check to prevent blocking valid attacks
					var sprite: Sprite2D = npc.get_node_or_null("Sprite")
					var facing_dir: Vector2 = Vector2(1, 0)
					if sprite:
						facing_dir = Vector2(-1 if sprite.flip_h else 1, 0)
					var angle_to_target = direction_to_target.angle_to(facing_dir)
					var is_head_on = abs(angle_to_target) < PI / 1.8  # ~100° tolerance (defenders need easier triggers)
					
					# Only attack if head-on and vertical offset is reasonable (55px for defenders)
					if is_head_on and abs(vertical_distance) <= 55.0:
						# Add a small cooldown after recovery to prevent unnatural rapid-fire attacks
						now = Time.get_ticks_msec()  # Reuse 'now' variable declared at function start
						if not npc.has_meta("last_attack_request_time"):
							npc.set_meta("last_attack_request_time", 0)
						var last_attack_time = npc.get_meta("last_attack_request_time", 0)
						var attack_cooldown = 50  # 50ms minimum between attacks (faster combat)
						
						if now - last_attack_time >= attack_cooldown:
							# Head-on aligned and in range - request attack
							combat_comp.request_attack(combat_target)
							npc.set_meta("last_attack_request_time", now)
			# If in WINDUP or RECOVERY, wait for current attack to complete

func _update_targeting() -> void:
	var combat_comp: CombatComponent = npc.get_node_or_null("CombatComponent")
	var radius: float = combat_comp.attack_range * 1.5 if combat_comp else 300.0
	
	# Step 1: When current target is valid but not in attack arc, switch to nearest enemy in arc
	if combat_target and is_instance_valid(combat_target) and _is_target_still_valid(combat_target) and combat_comp:
		if not combat_comp.is_target_in_attack_arc(combat_target):
			var candidates: Array = []
			if npc.has_method("get_combat_target_candidates"):
				candidates = npc.get_combat_target_candidates(npc.global_position, radius)
			var best_in_arc: Node2D = null
			var best_dist: float = INF
			for c in candidates:
				if not is_instance_valid(c) or c == combat_target:
					continue
				if not _is_target_still_valid(c):
					continue
				if not combat_comp.is_target_in_attack_arc(c):
					continue
				var d: float = npc.global_position.distance_squared_to(c.global_position)
				if d < best_dist:
					best_dist = d
					best_in_arc = c as Node2D
			if best_in_arc and best_in_arc != combat_target:
				var old_name: String = _target_display_name(combat_target)
				var new_name: String = _target_display_name(best_in_arc)
				var tid: int = EntityRegistry.get_id(best_in_arc) if EntityRegistry else -1
				combat_target = best_in_arc
				npc.set("combat_target_id", tid)
				npc.set("combat_target", best_in_arc)
				if "combat_target_id" in npc:
					npc.combat_target_id = tid
				combat_comp.set_target(best_in_arc)
				var pi = npc.get_node_or_null("/root/PlaytestInstrumentor")
				if pi and pi.is_enabled():
					var nn: String = npc.get("npc_name") if npc.get("npc_name") != null else "unknown"
					pi.combat_target_switch(nn, old_name, new_name, "out_of_arc")
				return
	
	# Throttle target checks to reduce frequency (2 seconds instead of 1)
	var now = Time.get_ticks_msec()
	if now < next_target_check_time:
		# Early exit if we have a valid target and check time hasn't elapsed
		if combat_target and is_instance_valid(combat_target):
			if _is_target_still_valid(combat_target):
				return
	
	# Update check time
	next_target_check_time = now + int(TARGET_CHECK_INTERVAL * 1000)
	
	# Re-validate existing target before searching for new one
	if combat_target and is_instance_valid(combat_target):
		if _is_target_still_valid(combat_target):
			return
	
	# Target invalid or missing - find new one
	_find_nearest_enemy()

func _target_display_name(t: Node2D) -> String:
	if not t or not is_instance_valid(t):
		return "unknown"
	if t is NPCBase:
		return (t as NPCBase).npc_name
	if t.is_in_group("player"):
		return "Player"
	return "unknown"

func _is_target_still_valid(t: Node2D) -> bool:
	if not t or not is_instance_valid(t):
		return false
	# Never target the player if we're following them, same clan, or defending/searching their claim
	if t.is_in_group("player") and npc:
		var herder_val = npc.get("herder")
		if herder_val == t:
			return false  # Invalid: we're following the player, can't attack them
		if npc.has_method("get_clan_name") and t.has_method("get_clan_name"):
			var npc_clan = npc.get_clan_name()
			var player_clan = t.get_clan_name()
			if npc_clan != "" and npc_clan == player_clan:
				return false  # Invalid: same clan as player
		# Defending or searching player's claim = player's clansman, never attack
		var dt = npc.get("defend_target")
		var shc = npc.get("search_home_claim")
		if (dt != null and is_instance_valid(dt) and dt.get("player_owned") == true) or (shc != null and is_instance_valid(shc) and shc.get("player_owned") == true):
			return false
		return true  # Player is valid target (not following, different clan, not player's clansman)
	# NPC target: same-clan allies invalid (e.g. joined clan mid-fight)
	if not t.is_in_group("player") and npc:
		if npc.has_method("get_clan_name") and t.has_method("get_clan_name"):
			var my_c: String = npc.get_clan_name()
			var tgt_c: String = t.get_clan_name()
			if my_c != "" and tgt_c != "" and my_c == tgt_c:
				return false
	var target_health: HealthComponent = t.get_node_or_null("HealthComponent")
	return target_health != null and not target_health.is_dead

func _stance_combat_agro_threshold() -> float:
	"""Defenders / non-ordered: 70. Ordered: FOLLOW 90, GUARD 70, ATTACK 50."""
	if not npc or not npc.get("follow_is_ordered"):
		return 70.0
	var ctx: Dictionary = npc.get("command_context") if npc.get("command_context") != null else {}
	var mode: String = str(ctx.get("mode", "FOLLOW"))
	if mode == "GUARD":
		return 70.0
	elif mode == "ATTACK":
		return 50.0
	return 90.0

func can_enter() -> bool:
	if not npc:
		return false
	
	# Check if dead
	var health_comp: HealthComponent = npc.get_node_or_null("HealthComponent")
	if health_comp and health_comp.is_dead:
		return false
	
	# If combat_target already set (e.g. intrusion → player), validate it first
	var combat_target_prop = npc.get("combat_target")
	if combat_target_prop != null and is_instance_valid(combat_target_prop):
		combat_target = combat_target_prop as Node2D
		# CRITICAL: Validate target before allowing entry (prevents attacking player/friends)
		if _is_target_still_valid(combat_target):
			return true
		else:
			# Invalid target (e.g. player when following, dead enemy, same-clan)
			# Clear it and continue to normal target finding
			npc.set("combat_target_id", -1)
			npc.set("combat_target", null)
			combat_target = null
			if "combat_target_id" in npc:
				npc.combat_target_id = -1
	
	# When combat is disabled (testing), never enter combat
	if NPCConfig and NPCConfig.get("combat_disabled"):
		return false
	
	# Check if agro meets stance threshold (ordered followers: FOLLOW 90 / GUARD 70 / ATTACK 50)
	var agro_meter_prop = npc.get("agro_meter")
	var agro_meter: float = agro_meter_prop as float if agro_meter_prop != null else 0.0
	var agro_thr: float = _stance_combat_agro_threshold()
	
	# Debug logging (disabled to reduce console spam)
	# var npc_name = npc.get("npc_name") if npc else "unknown"
	# print("🔍 COMBAT_STATE: can_enter() check for %s - agro_meter=%.1f" % [npc_name, agro_meter])
	
	if agro_meter < agro_thr and npc.get("follow_is_ordered"):
		var _last_blocked_agro: float = npc.get_meta("_combat_blocked_last_agro", -1.0) if npc.has_meta("_combat_blocked_last_agro") else -1.0
		if abs(agro_meter - _last_blocked_agro) > 2.0:
			npc.set_meta("_combat_blocked_last_agro", agro_meter)
			var pi_cb: Node = npc.get_node_or_null("/root/PlaytestInstrumentor")
			if pi_cb and pi_cb.is_enabled():
				var _ctx_cb: Dictionary = npc.get("command_context") if npc.get("command_context") != null else {}
				pi_cb.clansman_combat_blocked(str(npc.get("npc_name")), str(_ctx_cb.get("mode", "FOLLOW")), agro_meter, agro_thr)
	if agro_meter >= agro_thr:
		# Use PerceptionArea (AOP) - node name "DetectionArea" in NPC.tscn
		var pa: PerceptionArea = npc.get_node_or_null("DetectionArea") as PerceptionArea
		if pa:
			if pa.has_enemies(npc):
				var raw: Node = pa.get_nearest_enemy(npc.global_position, npc)
				combat_target = raw as Node2D if raw else null
		else:
			var pi = get_node_or_null("/root/PlaytestInstrumentor")
			if pi and pi.is_enabled() and pi.has_method("combat_detection_null"):
				pi.combat_detection_null(npc.get("npc_name") if npc else "?")
			push_warning("Combat: DetectionArea null for %s - no target" % (npc.get("npc_name") if npc else "?"))
			combat_target = null
		
		# if combat_target:
		# 	print("✅ COMBAT_STATE: %s can enter combat (target: %s)" % [npc_name, combat_target.get("npc_name") if combat_target else "unknown"])
		# else:
		# 	print("❌ COMBAT_STATE: %s cannot enter combat - no valid target found" % npc_name)
		
		return combat_target != null
	
	# Raid path: Followers in Hostile Mode (herder == player, or agro-combat-test with herder == leader) attack enemy in range
	var hostile: bool = npc.get("is_hostile") as bool if npc.get("is_hostile") != null else false
	var h: Node = npc.get("herder")
	var ordered: bool = npc.get("follow_is_ordered") as bool if npc.get("follow_is_ordered") != null else false
	var raid_allow: bool = h != null and h.is_in_group("player")
	if not raid_allow and DebugConfig and DebugConfig.get("enable_agro_combat_test") and DebugConfig.get("test_overrides") is Dictionary:
		raid_allow = DebugConfig.test_overrides.get("allow_raid_without_player", true)
	var raid_ok: bool = hostile and h != null and is_instance_valid(h) and ordered and raid_allow
	if raid_ok and npc.get("follow_is_ordered"):
		if agro_meter < _stance_combat_agro_threshold():
			raid_ok = false
	if DebugConfig and DebugConfig.get("enable_agro_combat_test") and raid_allow and ordered and h != null and is_instance_valid(h) and not hostile:
		if not _raid_blocked_logged:
			_raid_blocked_logged = true
			print("⚠️ COMBAT: raid path blocked (is_hostile=false) — set npc.is_hostile when command_context.is_hostile")
	if raid_ok:
		# Agro combat test: use boosted range via get_combat_target_candidates so followers engage sooner
		var radius: float = 300.0
		if DebugConfig and DebugConfig.get("enable_agro_combat_test") and DebugConfig.get("test_overrides") is Dictionary:
			radius = DebugConfig.test_overrides.get("detection_range_boost", 300.0)
		if npc.has_method("get_combat_target_candidates") and radius > 300.0:
			var candidates: Array = npc.get_combat_target_candidates(npc.global_position, radius)
			if candidates.size() > 0:
				var nearest: Node2D = null
				var best_dist := INF
				for c in candidates:
					if is_instance_valid(c):
						var d: float = npc.global_position.distance_squared_to(c.global_position)
						if d < best_dist:
							best_dist = d
							nearest = c as Node2D
				if nearest:
					combat_target = nearest
					var tid: int = EntityRegistry.get_id(combat_target) if EntityRegistry else -1
					npc.set("combat_target_id", tid)
					npc.set("combat_target", combat_target)
					if "combat_target_id" in npc:
						npc.combat_target_id = tid
					return true
		# Use PerceptionArea (AOP) - node name "DetectionArea" in NPC.tscn
		var pa: PerceptionArea = npc.get_node_or_null("DetectionArea") as PerceptionArea
		if pa:
			var raw: Node = pa.get_nearest_enemy(npc.global_position, npc)
			combat_target = raw as Node2D if raw else null
			if combat_target:
				var tid: int = EntityRegistry.get_id(combat_target) if EntityRegistry else -1
				npc.set("combat_target_id", tid)
				npc.set("combat_target", combat_target)
				if "combat_target_id" in npc:
					npc.combat_target_id = tid
				return true
		else:
			var pi = get_node_or_null("/root/PlaytestInstrumentor")
			if pi and pi.is_enabled() and pi.has_method("combat_detection_null"):
				pi.combat_detection_null(npc.get("npc_name") if npc else "?")
		if combat_target:
			var tid: int = EntityRegistry.get_id(combat_target) if EntityRegistry else -1
			npc.set("combat_target_id", tid)
			npc.set("combat_target", combat_target)
			if "combat_target_id" in npc:
				npc.combat_target_id = tid
			return true
	
	return false

func get_priority() -> float:
	# High priority - combat overrides most states
	return 12.0

func _find_nearest_enemy() -> void:
	if not npc:
		return
	
	combat_target = null
	
	# Use PerceptionArea (AOP) - node name "DetectionArea" in NPC.tscn
	var pa: PerceptionArea = npc.get_node_or_null("DetectionArea") as PerceptionArea
	if pa:
		var raw: Node = pa.get_nearest_enemy(npc.global_position, npc)
		combat_target = raw as Node2D if raw else null
	else:
		# DetectionArea null - should never happen. Log and fail gracefully.
		var pi = get_node_or_null("/root/PlaytestInstrumentor")
		if pi and pi.is_enabled() and pi.has_method("combat_detection_null"):
			pi.combat_detection_null(npc.get("npc_name") if npc else "?")
		push_warning("Combat: DetectionArea null for %s - no target" % (npc.get("npc_name") if npc else "?"))
		return
	
	if combat_target:
		var tid: int = EntityRegistry.get_id(combat_target) if EntityRegistry else -1
		npc.set("combat_target_id", tid)
		npc.set("combat_target", combat_target)
		if "combat_target_id" in npc:
			npc.combat_target_id = tid
		var combat_comp: CombatComponent = npc.get_node_or_null("CombatComponent")
		if combat_comp:
			combat_comp.set_target(combat_target)

