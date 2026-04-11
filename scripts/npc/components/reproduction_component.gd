extends Node
class_name ReproductionComponent

# Reproduction Component for Women NPCs
# Handles birth timers, mate detection, pregnancy state

var npc: NPCBase = null
var config: ReproductionConfig = null

var is_pregnant: bool = false
var birth_timer: float = 0.0
var last_birth_time: float = 0.0
var current_mate: Node = null  # Can be player (Node) or NPCBase
# Herder who delivered this woman + built hut: father for all babies until he dies; then _try_find_mate picks a new one.
var designated_father: Node = null

func initialize(npc_ref: NPCBase) -> void:
	var npc_name = npc_ref.get("npc_name") if npc_ref and npc_ref.has_method("get") else "unknown"
	UnifiedLogger.log_system("REPRODUCTION_INIT: Initializing reproduction component", {
		"npc": npc_name,
		"npc_valid": npc_ref != null and is_instance_valid(npc_ref),
		"clan": npc_ref.clan_name if npc_ref else "none"
	})
	
	npc = npc_ref
	config = ReproductionConfig.new()
	if config and BalanceConfig:
		config.birth_timer_base = BalanceConfig.pregnancy_seconds
		config.birth_cooldown = BalanceConfig.birth_cooldown_seconds
	
	if not config:
		UnifiedLogger.log_system("REPRODUCTION_INIT: ERROR - Failed to create ReproductionConfig for %s" % npc_name, {
			"npc": npc_name
		})
	else:
		UnifiedLogger.log_system("REPRODUCTION_INIT: Successfully initialized for %s" % npc_name, {
			"npc": npc_name,
			"clan": npc_ref.clan_name if npc_ref else "none"
		})

func update(delta: float) -> void:
	# Only update if woman is in clan and inside land claim
	if not npc or not is_instance_valid(npc):
		UnifiedLogger.log_system("REPRODUCTION_UPDATE: Skipping - npc is null or invalid", {})
		return
	
	var npc_name = npc.get("npc_name") if npc.has_method("get") else "unknown"
	
	# Ensure config is initialized
	if not config:
		UnifiedLogger.log_system("REPRODUCTION_UPDATE: Config is null, initializing for %s" % npc_name, {
			"npc": npc_name
		})
		config = ReproductionConfig.new()
		if config and BalanceConfig:
			config.birth_timer_base = BalanceConfig.pregnancy_seconds
			config.birth_cooldown = BalanceConfig.birth_cooldown_seconds
		if not config:
			UnifiedLogger.log_system("REPRODUCTION_UPDATE: ERROR - Failed to create config for %s" % npc_name, {
				"npc": npc_name
			})
			return
	
	# Ensure we're in the scene tree
	if not is_inside_tree():
		UnifiedLogger.log_system("REPRODUCTION_UPDATE: Skipping - not in scene tree for %s" % npc_name, {
			"npc": npc_name
		})
		return
	
	# Only women can reproduce
	if not npc.has_method("get"):
		UnifiedLogger.log_system("REPRODUCTION_UPDATE: Skipping - npc has no get method for %s" % npc_name, {
			"npc": npc_name
		})
		return
	
	var npc_type = npc.get("npc_type")
	if npc_type != "woman":
		return  # Not a woman, skip silently
	
	# Must be in clan (wild NPCs cannot reproduce)
	var clan_name: String = ""
	if npc:
		if npc is NPCBase:
			clan_name = npc.clan_name if npc.clan_name else ""
		elif npc.has_method("get") and npc.get("clan_name"):
			clan_name = npc.get("clan_name")
	
	if not clan_name or clan_name == "":
		return  # Wild women cannot reproduce
	
	_refresh_designated_father_if_invalid()
	
	# Must be inside land claim (reproduction only happens inside land claim)
	if not _is_in_land_claim():
		return
	
	# Pregnancy requires Living Hut (or Oven/Farm/Dairy - special Living Huts)
	if not _has_living_hut_assigned():
		# Cancel pregnancy if woman lost hut
		if is_pregnant:
			is_pregnant = false
			birth_timer = 0.0
		return
	
	# Update birth timer if pregnant
	if is_pregnant:
		_update_birth_timer(delta)
	# Try to find mate and start pregnancy if not pregnant and cooldown expired
	elif _can_reproduce():
		_try_find_mate()

func set_designated_father_from_herder(herder: Node) -> void:
	if not herder or not is_instance_valid(herder):
		return
	designated_father = herder

func has_living_hut_assigned() -> bool:
	"""Public: Woman has a housing slot in Living Hut, Oven, Farm, or Dairy (all count for reproduction)."""
	return _has_living_hut_assigned()

func _refresh_designated_father_if_invalid() -> void:
	if designated_father == null:
		return
	if not is_instance_valid(designated_father):
		designated_father = null
		return
	if designated_father.has_method("is_dead") and designated_father.is_dead():
		designated_father = null
		return
	var hc = designated_father.get_node_or_null("HealthComponent")
	if hc and hc.is_dead:
		designated_father = null
		return
	var fclan: String = ""
	if designated_father.has_method("get_clan_name"):
		fclan = designated_father.get_clan_name()
	elif designated_father.get("clan_name") != null:
		fclan = str(designated_father.get("clan_name"))
	var wclan: String = npc.clan_name if npc else ""
	if fclan != wclan or fclan == "":
		designated_father = null

func _father_eligible_for_current_pregnancy(father: Node) -> bool:
	if not father or not is_instance_valid(father):
		return false
	if father.has_method("is_dead") and father.is_dead():
		return false
	var hcomp = father.get_node_or_null("HealthComponent")
	if hcomp and hcomp.is_dead:
		return false
	if not _is_npc_in_land_claim(father as Node2D):
		return false
	return true

func _has_living_hut_assigned() -> bool:
	"""Woman has a housing slot in Living Hut, Oven, Farm, or Dairy (all count for reproduction)."""
	if not npc or not OccupationSystem:
		return false
	var building = OccupationSystem.get_workplace(npc)
	if not building or not is_instance_valid(building):
		return false
	if not (building is BuildingBase):
		return false
	var bt = building.get("building_type")
	if bt == null:
		return false
	return bt == ResourceData.ResourceType.LIVING_HUT or bt == ResourceData.ResourceType.OVEN or bt == ResourceData.ResourceType.FARM or bt == ResourceData.ResourceType.DAIRY_FARM

func _is_in_land_claim() -> bool:
	# Check if woman is inside her clan's land claim
	if not npc:
		return false
	
	var clan: String = ""
	if npc:
		if npc is NPCBase:
			clan = npc.clan_name if npc.clan_name else ""
		elif npc.has_method("get") and npc.get("clan_name"):
			clan = npc.get("clan_name")
	
	if not clan or clan == "":
		return false
	
	var land_claim = _get_land_claim(clan)
	if not land_claim:
		return false
	
	var distance = npc.global_position.distance_to(land_claim.global_position)
	var radius: float = 400.0
	if land_claim and land_claim.has_method("get"):
		var radius_val = land_claim.get("radius")
		if radius_val != null:
			radius = radius_val as float
	var is_inside = distance <= radius
	
	return is_inside

func _get_land_claim(clan_name: String) -> Node2D:
	# Helper to get land claim for clan
	var tree = get_tree()
	if not tree:
		return null
	
	var claims = tree.get_nodes_in_group("land_claims")
	if not claims:
		return null
	
	for claim in claims:
		if not is_instance_valid(claim):
			continue
		if not claim.has_method("get"):
			continue
		var claim_clan = claim.get("clan_name")
		if claim_clan == clan_name:
			return claim
	return null

func _can_reproduce() -> bool:
	# Check if cooldown has expired
	if not config:
		config = ReproductionConfig.new()
		if not config:
			return false
	
	var time_since_last_birth = (Time.get_ticks_msec() / 1000.0) - last_birth_time
	return time_since_last_birth >= config.birth_cooldown

func _try_find_mate() -> void:
	var npc_name = npc.get("npc_name") if npc and npc.has_method("get") else "unknown"
	UnifiedLogger.log_system("REPRODUCTION_MATE: %s trying to find mate" % npc_name, {
		"npc": npc_name,
		"clan": npc.clan_name if npc else "none"
	})
	
	# Prefer designated father (herder who delivered her) until he dies; if alive but not in claim yet, wait.
	if designated_father and is_instance_valid(designated_father):
		if _father_eligible_for_current_pregnancy(designated_father):
			current_mate = designated_father
			_start_pregnancy()
			return
		return
	
	# Find nearby male cavemen (player or NPC) in same clan
	var tree = get_tree()
	if not tree:
		UnifiedLogger.log_system("REPRODUCTION_MATE: ERROR - get_tree() returned null for %s" % npc_name, {
			"npc": npc_name
		})
		return
	
	var all_npcs = tree.get_nodes_in_group("npcs")
	var player = tree.get_first_node_in_group("player")
	var candidates: Array = []
	
	UnifiedLogger.log_system("REPRODUCTION_MATE: Found %d NPCs, player: %s for %s" % [all_npcs.size() if all_npcs else 0, "found" if player else "not found", npc_name], {
		"npc": npc_name,
		"npc_count": all_npcs.size() if all_npcs else 0,
		"player_found": player != null
	})
	
	# Add player if in same clan (player is clan leader)
	if player and is_instance_valid(player):
		# Check if player has clan name (via land claim)
		var player_clan = _get_player_clan_name()
		var npc_clan: String = ""
		if npc:
			if npc is NPCBase:
				npc_clan = npc.clan_name if npc.clan_name else ""
			elif npc.has_method("get") and npc.get("clan_name"):
				npc_clan = npc.get("clan_name")
		
		if player_clan != "" and player_clan == npc_clan:
			# Player is in same clan - check if player is inside land claim
			if _is_player_in_land_claim():
				candidates.append(player)
	
	# Find NPC cavemen in same clan
	for candidate in all_npcs:
		if not is_instance_valid(candidate):
			continue
		
		# Male clan members (caveman or clansman)
		var ctype: String = str(candidate.get("npc_type")) if candidate.get("npc_type") != null else ""
		if ctype != "caveman" and ctype != "clansman":
			continue
		
		# Check same clan
		var candidate_clan = candidate.get("clan_name") if candidate.has_method("get") else ""
		var npc_clan: String = ""
		if npc:
			if npc is NPCBase:
				npc_clan = npc.clan_name if npc.clan_name else ""
			elif npc.has_method("get") and npc.get("clan_name"):
				npc_clan = npc.get("clan_name")
		
		if candidate_clan != npc_clan:
			continue
		
		# Check if inside land claim
		if not _is_npc_in_land_claim(candidate):
			continue
		
		candidates.append(candidate)
	
	# Select best mate (prefer player/clan leader, higher quality)
	if candidates.size() > 0:
		UnifiedLogger.log_system("REPRODUCTION_MATE: Found %d candidates for %s" % [candidates.size(), npc_name], {
			"npc": npc_name,
			"candidate_count": candidates.size()
		})
		current_mate = _select_best_mate(candidates)
		if current_mate:
			designated_father = current_mate
			var mate_name = "Player" if current_mate.is_in_group("player") else (current_mate.get("npc_name") if current_mate.has_method("get") else "unknown")
			UnifiedLogger.log_system("REPRODUCTION_MATE: Selected mate %s for %s" % [mate_name, npc_name], {
				"npc": npc_name,
				"mate": mate_name
			})
		_start_pregnancy()
	else:
		var npc_clan: String = "none"
		if npc:
			if npc is NPCBase:
				npc_clan = npc.clan_name if npc.clan_name else "none"
			elif npc.has_method("get") and npc.get("clan_name"):
				npc_clan = npc.get("clan_name")
		
		UnifiedLogger.log_system("REPRODUCTION_MATE: No candidates found for %s" % npc_name, {
			"npc": npc_name,
			"clan": npc_clan
		})

func _is_player_in_land_claim() -> bool:
	# Check if player is inside their land claim
	var tree = get_tree()
	if not tree:
		return false
	
	var player = tree.get_first_node_in_group("player")
	if not player or not is_instance_valid(player):
		return false
	
	var player_clan = _get_player_clan_name()
	if player_clan == "":
		return false
	
	var land_claim = _get_land_claim(player_clan)
	if not land_claim:
		return false
	
	var distance = player.global_position.distance_to(land_claim.global_position)
	return distance <= land_claim.radius

func _get_player_clan_name() -> String:
	# Get player's clan name from their land claim
	var tree = get_tree()
	if not tree:
		return ""
	
	var claims = tree.get_nodes_in_group("land_claims")
	if not claims:
		return ""
	
	for claim in claims:
		if not is_instance_valid(claim):
			continue
		if not claim.has_method("get"):
			continue
		if claim.get("player_owned") == true:
			var clan = claim.get("clan_name")
			if clan:
				return clan
	return ""

func _is_npc_in_land_claim(npc_ref: Node2D) -> bool:
	# Check if NPC is inside land claim
	if not npc_ref or not is_instance_valid(npc_ref):
		return false
	
	if not npc_ref.has_method("get") or not npc_ref.get("clan_name"):
		return false
	
	var clan_name = npc_ref.get("clan_name")
	if not clan_name or clan_name == "":
		return false
	
	var land_claim = _get_land_claim(clan_name)
	if not land_claim:
		return false
	
	if not land_claim.has_method("get") or not land_claim.get("radius"):
		return false
	
	var distance = npc_ref.global_position.distance_to(land_claim.global_position)
	var radius = land_claim.get("radius") if land_claim.has_method("get") else 400.0
	return distance <= radius

func _get_clan_leader() -> Node:
	"""For player clan return player (if in claim); for AI clan return land_claim.owner_npc."""
	var clan: String = npc.clan_name if npc else ""
	if clan.is_empty():
		return null
	var claim = _get_land_claim(clan)
	if not claim or not is_instance_valid(claim):
		return null
	# Player clan: leader is player if in claim
	var player = get_tree().get_first_node_in_group("player")
	if player and is_instance_valid(player) and _get_player_clan_name() == clan and _is_player_in_land_claim():
		return player
	# AI clan: owner_npc is leader
	var owner_npc = claim.get("owner_npc") if claim.get("owner_npc") != null else null
	if owner_npc and is_instance_valid(owner_npc):
		return owner_npc
	return null

func _select_best_mate(candidates: Array) -> Node:
	# Favor clan leader; else prefer player, then first NPC
	if candidates.is_empty():
		return null
	var leader = _get_clan_leader()
	if leader and is_instance_valid(leader) and leader in candidates:
		return leader
	for candidate in candidates:
		if candidate and is_instance_valid(candidate) and candidate.is_in_group("player"):
			return candidate
	return candidates[0] if candidates.size() > 0 else null

func _start_pregnancy() -> void:
	UnifiedLogger.log_system("REPRODUCTION_PREGNANCY: _start_pregnancy() called", {
		"npc_valid": npc != null and is_instance_valid(npc) if npc else false,
		"is_pregnant": is_pregnant,
		"has_config": config != null
	})
	
	if not npc or not is_instance_valid(npc):
		UnifiedLogger.log_system("REPRODUCTION_PREGNANCY: ERROR - npc is null or invalid", {
			"npc_valid": false
		})
		return
	
	var npc_name = npc.get("npc_name") if npc.has_method("get") else "unknown"
	
	UnifiedLogger.log_system("REPRODUCTION_PREGNANCY: Checking _can_reproduce()", {
		"npc": npc_name,
		"is_pregnant": is_pregnant
	})
	
	var can_reproduce_result = false
	if not is_pregnant:
		can_reproduce_result = _can_reproduce()
		UnifiedLogger.log_system("REPRODUCTION_PREGNANCY: _can_reproduce() returned %s" % can_reproduce_result, {
			"npc": npc_name,
			"result": can_reproduce_result
		})
	
	if not is_pregnant and can_reproduce_result:
		is_pregnant = true
		birth_timer = config.birth_timer_base
		last_birth_time = Time.get_ticks_msec() / 1000.0
		var mate_name: String = "unknown"
		if current_mate and is_instance_valid(current_mate):
			if current_mate.is_in_group("player"):
				mate_name = "Player"
			elif current_mate is NPCBase:
				mate_name = current_mate.npc_name if current_mate.npc_name else "unknown"
			elif current_mate.has_method("get") and current_mate.get("npc_name"):
				mate_name = current_mate.get("npc_name")
		
		var clan_name: String = "none"
		if npc:
			if npc is NPCBase:
				clan_name = npc.clan_name if npc.clan_name else "none"
			elif npc.has_method("get") and npc.get("clan_name"):
				clan_name = npc.get("clan_name")
		
		UnifiedLogger.log_system("REPRODUCTION_PREGNANCY: %s started pregnancy (mate: %s, clan: %s, timer: %.1fs)" % [npc_name, mate_name, clan_name, birth_timer], {
			"npc": npc_name,
			"mate": mate_name,
			"clan": clan_name,
			"timer": birth_timer
		})
		print("✓ REPRODUCTION: %s started pregnancy (mate: %s, clan: %s, timer: %.1fs)" % [npc_name, mate_name, clan_name, birth_timer])

func _update_birth_timer(delta: float) -> void:
	# Cancel pregnancy if woman lost hut
	if not _has_living_hut_assigned():
		is_pregnant = false
		birth_timer = 0.0
		return
	birth_timer -= delta
	if birth_timer <= 0.0:
		_spawn_baby()

func _spawn_baby() -> void:
	var npc_name = npc.get("npc_name") if npc and npc.has_method("get") else "unknown"
	UnifiedLogger.log_system("REPRODUCTION_SPAWN: Attempting to spawn baby for %s" % npc_name, {
		"npc": npc_name
	})
	
	if not npc or not is_instance_valid(npc):
		UnifiedLogger.log_system("REPRODUCTION_SPAWN: ERROR - npc is null or invalid for %s" % npc_name, {
			"npc": npc_name
		})
		return
	
	if not npc.has_method("get"):
		UnifiedLogger.log_system("REPRODUCTION_SPAWN: ERROR - npc has no get method for %s" % npc_name, {
			"npc": npc_name
		})
		return
	
	if not npc.get("clan_name"):
		UnifiedLogger.log_system("REPRODUCTION_SPAWN: ERROR - npc has no clan_name for %s" % npc_name, {
			"npc": npc_name
		})
		return
	
	var clan_name = npc.get("clan_name")
	if not clan_name or clan_name == "":
		UnifiedLogger.log_system("REPRODUCTION_SPAWN: ERROR - clan_name is empty for %s" % npc_name, {
			"npc": npc_name
		})
		return
	
	# Ensure we're in the scene tree
	if not is_inside_tree():
		UnifiedLogger.log_system("REPRODUCTION_SPAWN: ERROR - not in scene tree for %s" % npc_name, {
			"npc": npc_name,
			"clan": clan_name
		})
		return
	
	var tree = get_tree()
	if not tree:
		UnifiedLogger.log_system("REPRODUCTION_SPAWN: ERROR - get_tree() returned null for %s" % npc_name, {
			"npc": npc_name,
			"clan": clan_name
		})
		return
	
	# Get land claim
	var land_claim = _get_land_claim(clan_name)
	if not land_claim:
		UnifiedLogger.log_system("REPRODUCTION_SPAWN: ERROR - no land claim found for clan %s (npc: %s)" % [clan_name, npc_name], {
			"npc": npc_name,
			"clan": clan_name
		})
		return
	
	# Check baby pool capacity and spawn baby
	var main = tree.get_first_node_in_group("main")
	if not main:
		UnifiedLogger.log_system("REPRODUCTION_SPAWN: ERROR - main node not found for %s" % npc_name, {
			"npc": npc_name,
			"clan": clan_name
		})
		print("ERROR: Cannot spawn baby - main node not found")
		return
	
	UnifiedLogger.log_system("REPRODUCTION_SPAWN: All checks passed, proceeding to spawn for %s" % npc_name, {
		"npc": npc_name,
		"clan": clan_name,
		"land_claim_valid": land_claim != null,
		"main_valid": main != null
	})
	
	# Check baby pool capacity
	if main.has_method("get_baby_pool_manager"):
		var pool_manager = main.get_baby_pool_manager()
		if not pool_manager:
			UnifiedLogger.log_system("REPRODUCTION_SPAWN: WARNING - Baby pool manager not initialized, spawning baby anyway for %s" % npc_name, {
				"npc": npc_name,
				"clan": clan_name
			})
			print("WARNING: Baby pool manager not initialized, spawning baby anyway")
		else:
			var can_add = pool_manager.can_add_baby(clan_name)
			UnifiedLogger.log_system("REPRODUCTION_SPAWN: Baby pool check for %s (clan: %s) - can_add: %s" % [npc_name, clan_name, can_add], {
				"npc": npc_name,
				"clan": clan_name,
				"can_add": can_add
			})
			if not can_add:
				UnifiedLogger.log_system("REPRODUCTION_SPAWN: Baby pool full for clan %s - baby not spawned (npc: %s)" % [clan_name, npc_name], {
					"npc": npc_name,
					"clan": clan_name
				})
				print("⚠ Baby pool full for clan %s - baby not spawned" % clan_name)
				# Reset pregnancy state even if baby can't be spawned
				is_pregnant = false
				birth_timer = 0.0
				last_birth_time = Time.get_ticks_msec() / 1000.0
				current_mate = null
				return
	
	# Spawn baby at land claim center
	if main.has_method("_spawn_baby"):
		# Convert current_mate to NPCBase if it's the player
		var father: NPCBase = null
		if current_mate and is_instance_valid(current_mate):
			if current_mate.is_in_group("player"):
				# Player is the father - pass null or create a dummy NPCBase reference
				# For now, pass null since player isn't an NPCBase
				father = null
			elif current_mate is NPCBase:
				father = current_mate as NPCBase
			else:
				# Try to get NPCBase from node
				father = current_mate as NPCBase if current_mate.has_method("get") else null
		
		if main.has_method("_spawn_baby"):
			UnifiedLogger.log_system("REPRODUCTION_SPAWN: Calling main._spawn_baby for %s" % npc_name, {
				"npc": npc_name,
				"clan": clan_name,
				"father_valid": father != null
			})
			main._spawn_baby(clan_name, land_claim.global_position, npc, father)
			UnifiedLogger.log_system("REPRODUCTION_SPAWN: Successfully called _spawn_baby for %s" % npc_name, {
				"npc": npc_name,
				"clan": clan_name
			})
		else:
			UnifiedLogger.log_system("REPRODUCTION_SPAWN: ERROR - Main node does not have _spawn_baby method for %s" % npc_name, {
				"npc": npc_name,
				"clan": clan_name
			})
			print("ERROR: Main node does not have _spawn_baby method")
	
	# Reset pregnancy
	is_pregnant = false
	birth_timer = 0.0
	last_birth_time = Time.get_ticks_msec() / 1000.0
	current_mate = null
	var npc_name_final = npc.get("npc_name") if npc and npc.has_method("get") else "unknown"
	if npc is NPCBase:
		npc_name_final = npc.npc_name if npc.npc_name else "unknown"
	
	var clan_name_final: String = "none"
	if npc:
		if npc is NPCBase:
			clan_name_final = npc.clan_name if npc.clan_name else "none"
		elif npc.has_method("get") and npc.get("clan_name"):
			clan_name_final = npc.get("clan_name")
	
	print("✓ REPRODUCTION: %s gave birth to baby (clan: %s)" % [npc_name_final, clan_name_final])

func get_pregnancy_status() -> Dictionary:
	# Return pregnancy status for UI/debug
	var mate_name: String = "none"
	if current_mate and is_instance_valid(current_mate):
		if current_mate.is_in_group("player"):
			mate_name = "Player"
		elif current_mate is NPCBase:
			mate_name = current_mate.npc_name if current_mate.npc_name else "unknown"
		elif current_mate.has_method("get") and current_mate.get("npc_name"):
			mate_name = current_mate.get("npc_name")
	
	return {
		"is_pregnant": is_pregnant,
		"birth_timer": birth_timer,
		"birth_timer_max": config.birth_timer_base if config else 90.0,
		"time_remaining": max(0.0, birth_timer),
		"mate": mate_name
	}
