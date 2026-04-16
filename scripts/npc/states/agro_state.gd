extends "res://scripts/npc/states/base_state.gd"

# Aggressive/Hostile state for cavemen - two types:
# 1. Agro Defend: Land claim defense (when intruder enters land claim)
# 2. Agro Recover: Lost wild NPC recovery (when wild NPC stops following)
# Higher agro level triggers hostile mode with "!!!" indicator

var lost_wildnpc: Node2D = null  # The wild NPC that was lost
var agro_target: Node2D = null  # The person who took the woman (or nearest threat)
var approach_mode: bool = true  # True when approaching, false when retreating
var approach_distance: float = 50.0  # Distance to approach wild NPC (from config) - updated for recover mode
var retreat_distance: float = 150.0  # Distance to retreat from wild NPC (from config) - updated for recover mode
var agro_increase_rate: float = 10.0  # Agro level increase per second (from config) - updated to 10.0/sec
var hostile_threshold: float = 60.0  # Agro level needed for hostile mode in recover mode (from config) - updated to 60.0
var hostile_threshold_defend: float = 70.0  # Agro level needed for hostile mode in defend mode (from config)
var hostile_duration: float = 0.0  # How long in hostile mode
var hostile_duration_max: float = 10.0  # Max duration of hostile indicator (from config)

func _safe_target_name(target: Node2D) -> String:
	if not target or not is_instance_valid(target):
		return "unknown"
	if target.is_in_group("player"):
		return "Player"
	var n: Variant = target.get("npc_name")
	return str(n) if n != null else str(target.name)

func _safe_wildnpc_name(wildnpc: Node2D) -> String:
	if not wildnpc or not is_instance_valid(wildnpc):
		return "unknown"
	var n: Variant = wildnpc.get("npc_name")
	return str(n) if n != null else str(wildnpc.name)

## Drop freed-node refs so FSM does not re-enter agro recover every evaluation (spam + job-cancel loops).
func _sanitize_agro_refs_on_npc() -> void:
	if not npc:
		return
	var lw: Variant = npc.get("lost_wildnpc")
	if lw != null and not is_instance_valid(lw):
		npc.set("lost_wildnpc", null)
	var at: Variant = npc.get("agro_target")
	if at != null and not is_instance_valid(at):
		npc.set("agro_target", null)

## Console only; keeps UnifiedLogger entries unchanged. key should be unique per message class.
func _agro_console_throttled(key: String, min_interval_sec: float) -> bool:
	if not npc:
		return true
	var now_sec: float = Time.get_ticks_msec() / 1000.0
	var meta_key: String = "agro_console_" + key
	var last: float = float(npc.get_meta(meta_key, -99999.0))
	if now_sec - last < min_interval_sec:
		return false
	npc.set_meta(meta_key, now_sec)
	return true

func enter() -> void:
	if not npc:
		return
	_sanitize_agro_refs_on_npc()
	
	# Task System - Step 18: Cancel current job when entering agro
	_cancel_tasks_if_active()
	if npc.task_runner and npc.task_runner.has_method("has_job") and npc.task_runner.has_job():
		UnifiedLogger.log_npc("AGRO: %s cancelled gather job due to agro" % npc.npc_name, {
			"npc": npc.npc_name,
			"event": "job_cancelled_agro"
		})
	
	# Load config values
	if NPCConfig:
		approach_distance = NPCConfig.agro_approach_distance
		retreat_distance = NPCConfig.agro_retreat_distance
		agro_increase_rate = NPCConfig.agro_state_meter_rise_per_second
		hostile_threshold = NPCConfig.hostile_threshold  # 60.0 for recover mode
		hostile_threshold_defend = NPCConfig.hostile_threshold_defend  # 70.0 for defend mode
		hostile_duration_max = NPCConfig.hostile_duration_max
	
	# Get lost wild NPC and agro target from NPC (validate refs - player has no npc_name)
	var lost_wildnpc_prop = npc.get("lost_wildnpc")
	if lost_wildnpc_prop != null and is_instance_valid(lost_wildnpc_prop as Node):
		lost_wildnpc = lost_wildnpc_prop as Node2D
	else:
		npc.set("lost_wildnpc", null)
	
	var agro_target_prop = npc.get("agro_target")
	if agro_target_prop != null and is_instance_valid(agro_target_prop as Node):
		agro_target = agro_target_prop as Node2D
	else:
		npc.set("agro_target", null)
	
	# Check if this is land claim defense (agro_target is another caveman or player)
	# Agro defend only works when caveman is in wander mode within own land claim
	var is_land_claim_defense: bool = false
	if agro_target and is_instance_valid(agro_target) and not lost_wildnpc:
		var tt_enter = agro_target.get("npc_type") if agro_target else null
		var target_type: String = (tt_enter as String) if tt_enter != null else ""
		var is_player: bool = agro_target.is_in_group("player") if agro_target else false
		if target_type == "caveman" or is_player:
			# Check if caveman is in wander mode within own land claim
			var cs_enter = fsm.get_current_state_name() if fsm else null
			var current_state: String = (cs_enter as String) if cs_enter != null else ""
			var nc_enter = npc.get("clan_name") if npc else null
			var npc_clan: String = (nc_enter as String) if nc_enter != null else ""
			if current_state == "wander" and npc_clan != "":
				# Check if inside own land claim
				if npc.has_method("is_inside_land_claim"):
					var inside_check: Dictionary = npc.is_inside_land_claim()
					if not inside_check.is_empty():
						var claim: Node2D = inside_check.get("land_claim")
						if claim:
							var claim_clan_prop = claim.get("clan_name")
							var claim_clan: String = claim_clan_prop as String if claim_clan_prop != null else ""
							if claim_clan == npc_clan:
								is_land_claim_defense = true
	
	if is_land_claim_defense:
		# Land claim defense - push intruder out (agro_target can be player - no npc_name)
		var intruder_name: String = _safe_target_name(agro_target)
		if _agro_console_throttled("defend_enter", 2.0):
			print("Caveman %s entering AGRO state (land claim defense), pushing intruder %s out" % [npc.npc_name, intruder_name])
		
		# Log agro state entry
		UnifiedLogger.log("Caveman agro triggered: entered_agro_land_claim_defense (target: %s, level: %.1f)" % [intruder_name, npc.agro_meter if npc else 0.0], UnifiedLogger.Category.COMBAT, UnifiedLogger.Level.INFO, {
			"npc": npc.npc_name,
			"trigger": "entered_agro_land_claim_defense",
			"target": intruder_name,
			"agro_meter": "%.1f" % (npc.agro_meter if npc else 0.0)
		})
	else:
		# Agro Recover: Lost wild NPC recovery logic
		# If no lost wild NPC, try to find one
		if not lost_wildnpc or not is_instance_valid(lost_wildnpc):
			_find_lost_wildnpc()
		
		if lost_wildnpc and is_instance_valid(lost_wildnpc):
			var wildnpc_name: String = _safe_wildnpc_name(lost_wildnpc)
			var _nname = npc.get("npc_name") if npc else null
			var _nname_safe: String = str(_nname) if _nname != null else "unknown"
			var _agro = npc.get("agro_meter") if npc else null
			var _agro_val: float = _agro as float if _agro != null else 0.0
			var throttle_key: String = "recover_enter_%s" % str(lost_wildnpc.get_instance_id())
			if _agro_console_throttled(throttle_key, 3.0):
				print("Caveman %s entering AGRO RECOVER state, trying to get wild NPC %s back" % [_nname_safe, wildnpc_name])
			approach_mode = true
			
			# Log agro state entry
			UnifiedLogger.log("Caveman agro triggered: entered_agro_recover (target: %s, level: %.1f)" % [wildnpc_name, _agro_val], UnifiedLogger.Category.COMBAT, UnifiedLogger.Level.INFO, {
				"npc": _nname_safe,
				"trigger": "entered_agro_recover",
				"target": wildnpc_name,
				"agro_meter": "%.1f" % _agro_val
			})
		else:
			if _agro_console_throttled("recover_no_target", 3.0):
				print("Caveman %s entering AGRO RECOVER state, no lost wild NPC found" % npc.npc_name)

func exit() -> void:
	_cancel_tasks_if_active()
	if npc:
		if _agro_console_throttled("exit_state", 2.0):
			print("Caveman %s exiting AGRO state" % npc.npc_name)
		# Hide hostile indicator
		if npc.hostile_indicator:
			npc.hostile_indicator.visible = false
		# Clear NPC props so wander/gather + priority do not immediately re-select agro recover.
		npc.set("lost_wildnpc", null)
		npc.set("agro_target", null)
	# Clear references
	lost_wildnpc = null
	agro_target = null
	hostile_duration = 0.0

func update(delta: float) -> void:
	if not npc:
		return
	
	# Check if still agro (agro_meter drives is_agro on NPCBase)
	var am: float = npc.get("agro_meter") as float if npc.get("agro_meter") != null else 0.0
	if am <= 0.0001:
		fsm.change_state("wander")
		return
	
	# CRITICAL: For land claim defense, continuously check if target has left
	# This ensures agro drops immediately when target leaves, not just on state evaluation
	if agro_target and is_instance_valid(agro_target):
		var tt_prop = agro_target.get("npc_type") if agro_target else null
		var target_type: String = (tt_prop as String) if tt_prop != null else ""
		var is_player: bool = agro_target.is_in_group("player") if agro_target else false
		if (target_type == "caveman" or is_player) and not lost_wildnpc:
			# This is land claim defense - check if target left
			var npc_clan_prop = npc.get("clan_name") if npc else null
			var npc_clan: String = (npc_clan_prop as String) if npc_clan_prop != null else ""
			if npc_clan != "":
				var node_cache = get_node_or_null("/root/NodeCache")
				var land_claims: Array
				if node_cache:
					land_claims = node_cache.get_land_claims()
				else:
					land_claims = get_tree().get_nodes_in_group("land_claims")
				
				var my_claim: Node2D = null
				for claim in land_claims:
					if not is_instance_valid(claim):
						continue
					var claim_clan_prop = claim.get("clan_name")
					var claim_clan: String = claim_clan_prop as String if claim_clan_prop != null else ""
					if claim_clan == npc_clan:
						my_claim = claim
						break
				
				if my_claim:
					var claim_pos: Vector2 = my_claim.global_position
					var radius_prop = my_claim.get("radius")
					var claim_radius: float = radius_prop as float if radius_prop != null else 400.0
					var target_pos: Vector2 = agro_target.global_position
					var distance: float = claim_pos.distance_to(target_pos)
					
					# If target left, exit agro immediately (no cooldown - intruder should flee)
					if distance > claim_radius:
						var target_name: String = _safe_target_name(agro_target)
						print("Caveman %s: Intruder %s left land claim (distance: %.1f > %.1f). Exiting agro immediately." % [npc.npc_name, target_name, distance, claim_radius])
						
						# NO COOLDOWN - removed as per guide update
						# Intruder should flee instead
						
						npc.set("agro_meter", 0.0)
						if "agro_meter" in npc:
							npc.agro_meter = 0.0
						npc.set("is_hostile", false)
						if npc.hostile_indicator:
							npc.hostile_indicator.visible = false
						
						# Exit state - transition to gather or wander
						# Auto-deposit in npc_base.gd will handle depositing when NPC enters land claim (400px range)
						# No need to transition to deposit_state (removed - auto-deposit handles this)
						fsm.change_state("gather")
						return
	
	# Increase agro_meter over time (hostile indicator / pressure)
	var agro_m_prop = npc.get("agro_meter")
	if agro_m_prop != null:
		var current_agro: float = agro_m_prop as float
		current_agro += agro_increase_rate * delta
		var max_agro: float = 100.0  # Default
		if NPCConfig:
			max_agro = NPCConfig.agro_max as float
		current_agro = min(current_agro, max_agro)
		npc.set("agro_meter", current_agro)
		if "agro_meter" in npc:
			npc.agro_meter = current_agro
		
		# Check if should enter hostile mode
		# Use different threshold for defend vs recover
		var current_threshold: float = hostile_threshold
		if lost_wildnpc:
			# Agro Recover mode - use 60.0 threshold
			current_threshold = 60.0
		else:
			# Agro Defend mode - use 70.0 threshold
			current_threshold = hostile_threshold_defend
		
		var is_hostile: bool = current_agro >= current_threshold
		npc.set("is_hostile", is_hostile)
		
		# Update hostile indicator visibility
		if npc.hostile_indicator:
			if is_hostile:
				npc.hostile_indicator.visible = true
				hostile_duration += delta
				# Hide after max duration
				if hostile_duration >= hostile_duration_max:
					hostile_duration = 0.0
					# Reset agro level slightly but keep it high
					current_agro = current_threshold - 10.0
					npc.set("agro_meter", current_agro)
					if "agro_meter" in npc:
						npc.agro_meter = current_agro
					npc.set("is_hostile", false)
					npc.hostile_indicator.visible = false
			else:
				npc.hostile_indicator.visible = false
				hostile_duration = 0.0
	
	# Update lost wild NPC and agro target references (validate - clear stale refs)
	var lost_wildnpc_prop = npc.get("lost_wildnpc")
	if lost_wildnpc_prop != null and is_instance_valid(lost_wildnpc_prop as Node):
		lost_wildnpc = lost_wildnpc_prop as Node2D
	else:
		lost_wildnpc = null
		if lost_wildnpc_prop != null:
			npc.set("lost_wildnpc", null)
	
	var agro_target_prop = npc.get("agro_target")
	if agro_target_prop != null and is_instance_valid(agro_target_prop as Node):
		agro_target = agro_target_prop as Node2D
	else:
		agro_target = null
		if agro_target_prop != null:
			npc.set("agro_target", null)
	
	# Check if this is land claim defense (agro_target is another caveman or player, not a lost wild NPC)
	# Agro defend only works when caveman is in wander mode within own land claim
	var is_land_claim_defense: bool = false
	if agro_target and is_instance_valid(agro_target) and not lost_wildnpc:
		var tt2 = agro_target.get("npc_type") if agro_target else null
		var target_type: String = (tt2 as String) if tt2 != null else ""
		var is_player: bool = agro_target.is_in_group("player") if agro_target else false
		if target_type == "caveman" or is_player:
			# Check if caveman is in wander mode within own land claim
			var cs2 = fsm.get_current_state_name() if fsm else null
			var current_state: String = (cs2 as String) if cs2 != null else ""
			var nc3 = npc.get("clan_name") if npc else null
			var npc_clan: String = (nc3 as String) if nc3 != null else ""
			if current_state == "wander" and npc_clan != "":
				# Check if inside own land claim
				if npc.has_method("is_inside_land_claim"):
					var inside_check: Dictionary = npc.is_inside_land_claim()
					if not inside_check.is_empty():
						var claim: Node2D = inside_check.get("land_claim")
						if claim:
							var claim_clan_prop = claim.get("clan_name")
							var claim_clan: String = claim_clan_prop as String if claim_clan_prop != null else ""
							if claim_clan == npc_clan:
								is_land_claim_defense = true
	
	# If land claim defense, handle intruder pushing
	if is_land_claim_defense:
		# Push intruder out of land claim
		if agro_target and is_instance_valid(agro_target) and npc.steering_agent:
			# Move toward intruder to push them
			npc.steering_agent.set_target_node(agro_target)
		
		# Check if intruder has left our land claim
		var nc2 = npc.get("clan_name") if npc else null
		var npc_clan: String = (nc2 as String) if nc2 != null else ""
		if npc_clan != "":
			var node_cache = get_node_or_null("/root/NodeCache")
			var land_claims: Array
			if node_cache:
				land_claims = node_cache.get_land_claims()
			else:
				land_claims = get_tree().get_nodes_in_group("land_claims")
			
			var my_claim: Node2D = null
			for claim in land_claims:
				if not is_instance_valid(claim):
					continue
				var claim_clan_prop = claim.get("clan_name")
				var claim_clan: String = claim_clan_prop as String if claim_clan_prop != null else ""
				if claim_clan == npc_clan:
					my_claim = claim
					break
			
			if my_claim:
				var claim_pos: Vector2 = my_claim.global_position
				var radius_prop = my_claim.get("radius")
				var claim_radius: float = radius_prop as float if radius_prop != null else 400.0
				var intruder_pos: Vector2 = agro_target.global_position if agro_target else Vector2.ZERO
				var distance: float = claim_pos.distance_to(intruder_pos)
				
				# If intruder left, exit agro (no cooldown - intruder should flee)
				if distance > claim_radius:
					var intruder_name: String = _safe_target_name(agro_target)
					print("Caveman %s: Intruder %s left land claim. Exiting agro." % [npc.npc_name, intruder_name])
					
					# NO COOLDOWN - removed as per guide update
					# Intruder should flee instead
					
					npc.set("agro_meter", 0.0)
					if "agro_meter" in npc:
						npc.agro_meter = 0.0
					npc.set("is_hostile", false)
					if npc.hostile_indicator:
						npc.hostile_indicator.visible = false
					# Exit state - transition to gather or wander
					# Auto-deposit in npc_base.gd will handle depositing when NPC enters land claim (400px range)
					# No need to transition to deposit_state (removed - auto-deposit handles this)
					fsm.change_state("gather")
					return
		
		# Continue pushing intruder (don't check for lost woman)
		return
	
	# Agro Recover: Lost wild NPC logic (only if not land claim defense)
	# Check if lost wild NPC is still valid
	if not lost_wildnpc or not is_instance_valid(lost_wildnpc):
		# Try to find lost wild NPC again (clear stale ref if invalid)
		npc.set("lost_wildnpc", null)
		lost_wildnpc = null
		_find_lost_wildnpc()
		if not lost_wildnpc or not is_instance_valid(lost_wildnpc):
			# No lost wild NPC found, exit agro
			npc.set("agro_meter", 0.0)
			if "agro_meter" in npc:
				npc.agro_meter = 0.0
			npc.set("is_hostile", false)
			if npc.hostile_indicator:
				npc.hostile_indicator.visible = false
			fsm.change_state("wander")
			return
	
	# Check if lost wild NPC has joined a landclaim OR is inside a land claim - if so, ignore and exit agro
	var clan_prop = lost_wildnpc.get("clan_name") if lost_wildnpc else null
	var wildnpc_clan: String = (clan_prop as String) if clan_prop != null else ""
	var wildnpc_inside_claim: bool = false
	var wildnpc_inside_forbidden_claim: bool = false
	
	# Check if wild NPC is physically inside any land claim (even if not joined yet)
	if lost_wildnpc.has_method("is_inside_land_claim"):
		var inside_check: Dictionary = lost_wildnpc.is_inside_land_claim()
		if not inside_check.is_empty():
			wildnpc_inside_claim = true
			# Also check if wild NPC has a clan name from this claim
			var claim: Node2D = inside_check.get("land_claim")
			if claim:
				var claim_clan_prop = claim.get("clan_name")
				if claim_clan_prop != null:
					var claim_clan: String = claim_clan_prop as String
					if claim_clan != "":
						wildnpc_clan = claim_clan  # Update wildnpc_clan if in a claim
					
					# Check if this is a land claim the caveman cannot enter (another caveman's claim)
					# Cavemen cannot enter other cavemen's land claims, so if wild NPC is inside one, give up
					if npc.has_method("can_enter_land_claim"):
						if not npc.can_enter_land_claim(claim):
							wildnpc_inside_forbidden_claim = true
	
	# Exit agro if wild NPC is in a clan, inside any land claim, or inside a forbidden land claim
	if wildnpc_clan != "" or wildnpc_inside_claim or wildnpc_inside_forbidden_claim:
		# Wild NPC is in a clan or inside a land claim, can't get them back - exit agro
		var wildnpc_name: String = _safe_wildnpc_name(lost_wildnpc)
		var reason: String = ""
		if wildnpc_clan != "":
			reason = "joined clan %s" % wildnpc_clan
		elif wildnpc_inside_forbidden_claim:
			reason = "inside another caveman's land claim (cannot enter)"
		else:
			reason = "inside land claim"
		
		print("Caveman %s giving up on wild NPC %s - %s" % [npc.npc_name, wildnpc_name, reason])
		
		# Log giving up
		UnifiedLogger.log("Caveman agro triggered: gave_up_wildnpc_joined_clan (target: %s, level: %.1f)" % [wildnpc_name, npc.agro_meter if npc else 0.0], UnifiedLogger.Category.COMBAT, UnifiedLogger.Level.INFO, {
			"npc": npc.npc_name,
			"trigger": "gave_up_wildnpc_joined_clan",
			"target": wildnpc_name,
			"agro_meter": "%.1f" % (npc.agro_meter if npc else 0.0)
		})
		
		npc.set("agro_meter", 0.0)
		if "agro_meter" in npc:
			npc.agro_meter = 0.0
		npc.set("is_hostile", false)
		if npc.hostile_indicator:
			npc.hostile_indicator.visible = false
		fsm.change_state("wander")
		return
	
	# Check if wild NPC is back (following us again)
	if not lost_wildnpc or not is_instance_valid(lost_wildnpc):
		# Stale reference - clear and exit
		npc.set("lost_wildnpc", null)
		lost_wildnpc = null
		_find_lost_wildnpc()
		if not lost_wildnpc or not is_instance_valid(lost_wildnpc):
			npc.set("agro_meter", 0.0)
			if "agro_meter" in npc:
				npc.agro_meter = 0.0
			npc.set("is_hostile", false)
			if npc.hostile_indicator:
				npc.hostile_indicator.visible = false
			fsm.change_state("wander")
			return
	var wildnpc_herder = lost_wildnpc.get("herder")
	if wildnpc_herder == npc:
		# Wild NPC is back! Exit agro
		var wildnpc_name: String = _safe_wildnpc_name(lost_wildnpc)
		print("Caveman %s got wild NPC %s back! Exiting agro." % [npc.npc_name, wildnpc_name])
		npc.set("agro_meter", 0.0)
		if "agro_meter" in npc:
			npc.agro_meter = 0.0
		npc.set("is_hostile", false)
		if npc.hostile_indicator:
			npc.hostile_indicator.visible = false
		fsm.change_state("wander")
		return
	
	# Check if player is too close - back away from player
	var player_nodes := get_tree().get_nodes_in_group("player")
	var player_too_close: bool = false
	var player_position: Vector2 = Vector2.ZERO
	var flee_from_player_distance: float = 100.0  # Default
	if NPCConfig:
		flee_from_player_distance = NPCConfig.agro_flee_player_distance
	
	var player_node: Node2D = null
	for p_node in player_nodes:
		if not is_instance_valid(p_node):
			continue
		var distance_to_player: float = npc.global_position.distance_to(p_node.global_position)
		if distance_to_player < flee_from_player_distance:
			player_too_close = true
			player_position = p_node.global_position
			player_node = p_node
			break
	
	# If player is too close, push player away and flee
	if player_too_close and player_node:
		# Push player away with force
		var push_force: float = 400.0  # Force to push player away
		var push_direction: Vector2 = (player_position - npc.global_position).normalized()
		
		# Apply push force to player
		if player_node is CharacterBody2D:
			var player_velocity: Vector2 = player_node.velocity
			player_velocity += push_direction * push_force * delta
			player_node.velocity = player_velocity
		
		# Also flee from player
		if npc.steering_agent:
			npc.steering_agent.set_flee_target(player_position)
		
		# Only print occasionally to reduce log spam
		if not has_meta("last_flee_print_time"):
			set_meta("last_flee_print_time", 0.0)
		var current_time := Time.get_ticks_msec() / 1000.0
		var last_print: float = get_meta("last_flee_print_time", 0.0)
		if current_time - last_print > 2.0:  # Print at most once every 2 seconds
			print("Caveman %s pushing player away (too close)" % npc.npc_name)
			set_meta("last_flee_print_time", current_time)
		return  # Skip woman approach/retreat logic when player is close
	
	# Get wild NPC's perception range
	var wildnpc_perception: float = 50.0  # Default
	if lost_wildnpc.has_method("get_stat"):
		var pval = lost_wildnpc.get_stat("perception")
		wildnpc_perception = (pval as float) if pval != null else 50.0
	var _perception_range: float = wildnpc_perception * 20.0 * 1.5  # Reserved for tuning approach bands
	
	# Calculate distance to wild NPC
	var distance_to_wildnpc: float = npc.global_position.distance_to(lost_wildnpc.global_position)
	
	# Approach/retreat behavior: come in and out of wild NPC's perception radius
	# Proximity helps to switch leader - get close to wild NPC
	if approach_mode:
		# Approaching: move towards wild NPC (within 50px)
		if distance_to_wildnpc < approach_distance:
			# Close enough, switch to retreat
			approach_mode = false
			if _agro_console_throttled("approach_toggle", 4.0):
				print("Caveman %s reached approach distance (%.1fpx), retreating from wild NPC" % [npc.npc_name, distance_to_wildnpc])
		else:
			# Move towards wild NPC
			if npc.steering_agent:
				npc.steering_agent.set_target_node(lost_wildnpc)
	else:
		# Retreating: move away from wild NPC (to 150px)
		if distance_to_wildnpc > retreat_distance:
			# Far enough, switch to approach
			approach_mode = true
			if _agro_console_throttled("retreat_toggle", 4.0):
				print("Caveman %s reached retreat distance (%.1fpx), approaching wild NPC" % [npc.npc_name, distance_to_wildnpc])
		else:
			# Move away from wild NPC
			if npc.steering_agent:
				var away_direction: Vector2 = (npc.global_position - lost_wildnpc.global_position).normalized()
				var retreat_target: Vector2 = lost_wildnpc.global_position + away_direction * (retreat_distance + 50.0)
				npc.steering_agent.set_target_position(retreat_target)

func can_enter() -> bool:
	if not npc:
		return false
	_sanitize_agro_refs_on_npc()
	
	# CRITICAL: Cannot enter agro while following - following takes priority
	if _is_following():
		return false  # Following - cannot agro
	
	# CRITICAL: Cannot enter agro while defending - defend takes priority
	if _is_defending():
		return false  # Defending - cannot agro
	
	# CRITICAL: Cannot enter agro while in combat - combat takes priority
	if _is_in_combat():
		return false  # In combat - cannot agro
	
	var npc_name_val = npc.get("npc_name") if npc else null
	var npc_name: String = str(npc_name_val) if npc_name_val != null else "unknown"
	
	# Only cavemen can enter agro state
	var npc_type_val = npc.get("npc_type") if npc else null
	var npc_type_str: String = (npc_type_val as String) if npc_type_val != null else ""
	if npc_type_str != "caveman":
		UnifiedLogger.log_npc("Can enter check: %s cannot enter agro (not_caveman)" % npc_name, {
			"npc": npc_name,
			"state": "agro",
			"can_enter": false,
			"reason": "not_caveman",
			"npc_type": npc_type_str
		}, UnifiedLogger.Level.DEBUG)
		return false
	
	var am_enter: float = npc.get("agro_meter") as float if npc.get("agro_meter") != null else 0.0
	if am_enter <= 0.0001:
		UnifiedLogger.log_npc("Can enter check: %s cannot enter agro (agro_meter_zero)" % npc_name, {
			"npc": npc_name,
			"state": "agro",
			"can_enter": false,
			"reason": "agro_meter_zero",
			"agro_meter": "%.1f" % am_enter
		}, UnifiedLogger.Level.DEBUG)
		return false
	
	var lw_log: Variant = npc.get("lost_wildnpc")
	var lost_wildnpc_name: String = ""
	if lw_log != null and is_instance_valid(lw_log):
		lost_wildnpc_name = _safe_wildnpc_name(lw_log as Node2D)
	UnifiedLogger.log_npc("Can enter check: %s can enter agro (agro_meter)" % npc_name, {
		"npc": npc_name,
		"state": "agro",
		"can_enter": true,
		"reason": "agro_meter",
		"agro_meter": "%.1f" % am_enter,
		"lost_wildnpc": lost_wildnpc_name
	}, UnifiedLogger.Level.DEBUG)
	
	return true

func get_priority() -> float:
	# Two types of agro:
	# 1. Agro Defend: Land claim defense (only when in wander mode within own land claim, requires 10+ of each resource)
	# 2. Agro Recover: Lost wild NPC recovery (always priority 10.0, NOT resource-dependent)
	
	if npc:
		_sanitize_agro_refs_on_npc()
		var nt = npc.get("npc_type") if npc else null
		var npc_type: String = (nt as String) if nt != null else ""
		if npc_type == "caveman":
			# Check if this is agro recover (lost wild NPC) or agro defend (intruder)
			var lost_wildnpc_prop = npc.get("lost_wildnpc")
			var has_lost_wildnpc: bool = (lost_wildnpc_prop != null and is_instance_valid(lost_wildnpc_prop as Node2D))
			
			if has_lost_wildnpc:
				# Agro Recover: Lost wild NPC recovery
				# Always priority 10.0 - resources have NO influence on herd defense
				return 10.0
			else:
				# Agro Defend: Land claim defense
				# Only high priority when land claim has 10+ of each resource
				# AND caveman is in wander mode within own land claim
				var gn = npc.get_clan_name() if npc else null
				var clan_name: String = (gn as String) if gn != null else ""
				if clan_name != "":
					# Check if land claim has 10+ of each resource type (ready for defense)
					var is_ready_for_defense: bool = _is_land_claim_ready_for_defense()
					
					if is_ready_for_defense:
						# Check if caveman is in wander mode within own land claim
						var cs3 = fsm.get_current_state_name() if fsm else null
						var current_state: String = (cs3 as String) if cs3 != null else ""
						var is_in_wander: bool = (current_state == "wander")
						var is_in_own_claim: bool = false
						
						if is_in_wander and npc.has_method("is_inside_land_claim"):
							var inside_check: Dictionary = npc.is_inside_land_claim()
							if not inside_check.is_empty():
								var claim: Node2D = inside_check.get("land_claim")
								if claim:
									var claim_clan_prop = claim.get("clan_name")
									var claim_clan: String = claim_clan_prop as String if claim_clan_prop != null else ""
									if claim_clan == clan_name:
										is_in_own_claim = true
						
						if is_in_wander and is_in_own_claim:
							# Land claim has 10+ stacks of each item AND in wander mode within own claim
							# HIGH priority for defense
							var priority: float = 10.0
							if NPCConfig:
								priority = NPCConfig.priority_agro
							
							# Land claim defense (targeting another caveman or player) gets even higher priority
							var agro_target_prop = npc.get("agro_target")
							if agro_target_prop != null:
								var target: Node2D = agro_target_prop as Node2D
								if target and is_instance_valid(target):
									var ttt = target.get("npc_type") if target else null
									var target_type: String = (ttt as String) if ttt != null else ""
									var is_player: bool = target.is_in_group("player") if target else false
									# If target is another caveman or player (land claim defense), boost priority
									if target_type == "caveman" or is_player:
										priority += 2.0  # Higher priority for land claim defense (12.0)
							
							return priority
						else:
							# Not in wander mode or not in own land claim - LOW priority
							return 3.0
					else:
						# Land claim has <10 stacks of each item - LOW priority (gathering takes precedence)
						return 3.0  # Lower than gather (8.0-9.5) so gathering happens first
				else:
					# No land claim - use low priority
					return 3.0
		else:
			# Not a caveman - use config value or default
			if NPCConfig:
				return NPCConfig.priority_agro
			else:
				return 10.0
	
	# Default to LOW priority
	return 3.0

func get_data() -> Dictionary:
	return {
		"lost_wildnpc": _safe_wildnpc_name(lost_wildnpc) if lost_wildnpc else "none",
		"agro_target": _safe_target_name(agro_target) if agro_target else "none",
		"approach_mode": approach_mode
	}

func _find_lost_wildnpc() -> void:
	# Find the wild NPC that was lost (woman, sheep, or goat)
	if not npc:
		return
	
	var lost_wildnpc_prop = npc.get("lost_wildnpc")
	if lost_wildnpc_prop != null:
		lost_wildnpc = lost_wildnpc_prop as Node2D
		if lost_wildnpc and is_instance_valid(lost_wildnpc):
			return
	
	# Try to find a wild NPC that was following us but now isn't
	var all_npcs := get_tree().get_nodes_in_group("npcs")
	for npc_check in all_npcs:
		if not is_instance_valid(npc_check):
			continue
		var nt_prop = npc_check.get("npc_type") if npc_check else null
		var npc_type_str: String = (nt_prop as String) if nt_prop != null else ""
		# Check for wild NPCs: woman, sheep, or goat
		if npc_type_str == "woman" or npc_type_str == "sheep" or npc_type_str == "goat":
			# IGNORE wild NPCs that have joined a landclaim - they can't be retrieved
			var wc_prop = npc_check.get("clan_name") if npc_check else null
			var wildnpc_clan: String = (wc_prop as String) if wc_prop != null else ""
			if wildnpc_clan != "":
				# Wild NPC is in a clan, ignore them
				continue
			
			var npc_herder = npc_check.get("herder")
			# Check if this wild NPC is following someone else (not us)
			if npc_herder != null and npc_herder != npc:
				# This might be our lost wild NPC
				lost_wildnpc = npc_check
				npc.set("lost_wildnpc", lost_wildnpc)
				agro_target = npc_herder
				npc.set("agro_target", agro_target)
				var wildnpc_name: String = _safe_wildnpc_name(lost_wildnpc)
				var target_name: String = _safe_target_name(agro_target)
				print("Caveman %s found lost wild NPC: %s (following %s)" % [npc.npc_name, wildnpc_name, target_name])
				break
