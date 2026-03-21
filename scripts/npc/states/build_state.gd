extends "res://scripts/npc/states/base_state.gd"

# Build state = place LAND CLAIM (territory marker), not buildings/structures.
# Cavemen spawn with a LANDCLAIM item; placing it creates their clan and claim so they can gather/deposit.
# Only restrictions: cooldown from spawn, minimum distance from existing claims, and no overlap with other claims.

# Land claim spacing: use BalanceConfig (same as player placement in main.gd)

var last_overlap_position: Vector2 = Vector2.ZERO  # Track last position where overlap was detected
var overlap_cooldown: float = 0.0  # Cooldown before trying to build again after overlap
const OVERLAP_COOLDOWN_DURATION: float = 3.0  # Wait 3 seconds before trying again after overlap

func update(delta: float) -> void:
	if not npc:
		return
	
	# Only cavemen can build
	if npc.get("npc_type") != "caveman":
		return
	
	# Update overlap cooldown
	if overlap_cooldown > 0.0:
		overlap_cooldown -= delta
		# If still in cooldown, exit to wander to let caveman move
		if overlap_cooldown > 0.0:
			if fsm:
				fsm.change_state("wander")
			return
	
	# Check if caveman has a land claim item
	if not npc.inventory:
		return
	
	var has_landclaim: bool = npc.inventory.has_item(ResourceData.ResourceType.LANDCLAIM, 1)
	if not has_landclaim:
		# No land claim item, exit build state
		if fsm:
			fsm.evaluation_timer = 0.0
		return
	
	# Check if already has a land claim (can only have one)
	if npc.get("clan_name") != null and npc.clan_name != "":
		# Already has a land claim, exit to wander for brief reset, then gather
		if fsm:
			fsm.change_state("wander")
			# Set a timer to force gather state after brief reset
			npc.set_meta("wander_reset_timer", 0.1)  # Very short reset (0.1s)
			npc.set_meta("next_state_after_wander_reset", "gather")  # Then go to gather
			print("✓ Build State: %s already has land claim, transitioning to gather via wander reset (clan: '%s')" % [npc.npc_name, npc.clan_name])
		return
	
	# Removed center distance check - cavemen spawn at 600px but need to place claims
	# The overlap check is sufficient to prevent claims from being too close together
	
	# Check if snapped position overlaps with any existing land claim
	var place_pos: Vector2 = npc.global_position
	place_pos.x = round(place_pos.x / 64.0) * 64.0  # Snap to 64px grid
	place_pos.y = round(place_pos.y / 64.0) * 64.0
	
	# Check if we're still at the same position where we detected overlap before
	var min_position_change: float = 500.0  # Must move at least 500px before retry (matches MIN_CLAIM_GAP + buffer)
	if last_overlap_position != Vector2.ZERO:
		var distance_moved: float = place_pos.distance_to(last_overlap_position)
		if distance_moved < min_position_change:
			# Still too close to last overlap position, exit to wander
			if fsm:
				fsm.change_state("wander")
			return
	
	if _would_overlap_land_claim(place_pos):
		# Overlap detected, can't place here - exit to wander so caveman moves to a new position
		UnifiedLogger.log_npc("Action failed: build_land_claim (overlap_detected)", {
			"npc": npc.npc_name,
			"action": "build_land_claim",
			"reason": "overlap_detected",
			"position": "%.1f,%.1f" % [place_pos.x, place_pos.y]
		})
		# Record position and cooldown so we don't re-enter build from same spot (thrashing)
		last_overlap_position = place_pos
		overlap_cooldown = OVERLAP_COOLDOWN_DURATION
		npc.set_meta("build_overlap_exit_time", Time.get_ticks_msec() / 1000.0)  # Persist on NPC; build_state.update() won't run in wander
		# Exit to wander so the caveman moves away; can_enter() will block re-entry for OVERLAP_COOLDOWN_DURATION
		if fsm:
			fsm.change_state("wander")
		return
	
	# Clear overlap tracking if we're at a new valid position
	if last_overlap_position != Vector2.ZERO:
		last_overlap_position = Vector2.ZERO
	
	# No overlap, place immediately at snapped position
	UnifiedLogger.log_npc("Action started: build_land_claim", {
		"npc": npc.npc_name,
		"action": "build_land_claim",
		"position": "%.1f,%.1f" % [place_pos.x, place_pos.y]
	})
	_place_land_claim(place_pos)

func _would_overlap_land_claim(pos: Vector2) -> bool:
	# Min center-to-center matches main._validate_building_placement (BalanceConfig)
	var land_claims := get_tree().get_nodes_in_group("land_claims")
	var min_distance: float = 1200.0
	if BalanceConfig and BalanceConfig.has_method("get_land_claim_min_center_distance"):
		min_distance = BalanceConfig.get_land_claim_min_center_distance()
	
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
	
	# Get main scene to access land claim creation
	var main: Node2D = get_tree().get_first_node_in_group("main")
	if not main:
		print("ERROR: Could not find main scene to place land claim")
		return
	
	# Clear overlap cooldown meta on successful placement path so it doesn't linger
	if npc.has_meta("build_overlap_exit_time"):
		npc.remove_meta("build_overlap_exit_time")
	
	# Generate a random 4-letter clan name
	var clan_name: String = _generate_random_clan_name()
	
	# Position is already snapped to grid (passed from update())
	
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
	# We'll need to call a function on main to place it
	var used_main_method: bool = false
	if main.has_method("_place_npc_land_claim"):
		main._place_npc_land_claim(clan_name, place_pos, npc)
		used_main_method = true
		# Timer-setting code is below, after the else block
	else:
		# Fallback: create directly
		var LAND_CLAIM_SCENE = preload("res://scenes/LandClaim.tscn")
		var land_claim: LandClaim = LAND_CLAIM_SCENE.instantiate() as LandClaim
		if land_claim:
			land_claim.global_position = place_pos
			land_claim.set_clan_name(clan_name)
			land_claim.owner_npc = npc  # CRITICAL: Set owner_npc so fallback lookup can find it
			land_claim.owner_npc_name = npc.npc_name  # CRITICAL: Store NPC name as backup (persists even if reference is lost)
			land_claim.set_meta("owner_npc_name", npc.npc_name)  # Also store in meta for extra persistence
			
			# Create building inventory (6 slots, stacking enabled, no stack limit for testing)
			var building_inventory := InventoryData.new(6, true, 999999)  # 6 slots, stacking enabled, very high stack limit for testing
			land_claim.inventory = building_inventory
			
			# Add to land claims container
			var world_objects: Node2D = main.get_node_or_null("WorldObjects")
			if world_objects:
				world_objects.add_child(land_claim)
				land_claim.visible = true
				# Phase 3: Register land claim for cache tracking
				if main.has_method("register_land_claim"):
					main.register_land_claim(land_claim)
			
			# Set caveman's clan name (CRITICAL: Must be set BEFORE state transition)
			# Use helper function to ensure proper syncing
			var old_clan: String = npc.get_clan_name() if npc.has_method("get_clan_name") else (npc.clan_name if npc else "")
			print("🔵 BUILD_STATE: Setting %s.clan_name from '%s' to '%s' (has_method: %s)" % [npc.npc_name, old_clan, clan_name, npc.has_method("set_clan_name") if npc else false])
			if npc.has_method("set_clan_name"):
				npc.set_clan_name(clan_name, "build_state.gd")  # Use helper function
			else:
				# Fallback if helper doesn't exist
				npc.clan_name = clan_name
				npc.set_meta("clan_name", clan_name)
				print("⚠️ BUILD_STATE: Helper function not found, using direct assignment")
			# CRITICAL: Store clan_name in MULTIPLE places for maximum persistence
			npc.set_meta("clan_name", clan_name)  # Always set meta (even if helper was used)
			npc.set_meta("has_land_claim", true)  # Flag for quick checking
			npc.set_meta("land_claim_clan_name", clan_name)  # Extra backup with different key
			# Also store NPC name on land claim for reverse lookup
			land_claim.set_meta("owner_npc_name", npc.npc_name)
			
			# VERIFY meta properties were set
			var meta_clan_check = npc.get_meta("clan_name", "") if npc.has_meta("clan_name") else ""
			var meta_backup_check = npc.get_meta("land_claim_clan_name", "") if npc.has_meta("land_claim_clan_name") else ""
			print("🔵 BUILD_STATE META VERIFY: %s - meta('clan_name')='%s', meta('land_claim_clan_name')='%s', direct='%s'" % [npc.npc_name, meta_clan_check, meta_backup_check, npc.clan_name])
			
			# TRACK: Store verification timestamp and state
			npc.set_meta("meta_verified_at", Time.get_ticks_msec())
			npc.set_meta("meta_verified_clan", clan_name)
			print("🔵 BUILD_STATE TRACK: %s - Meta verified, tracking state before transition (clan='%s')" % [npc.npc_name, clan_name])
			
			# Immediate verification after setting
			var verify_immediate: String = npc.get_clan_name()  # Use helper function
			print("🔵 BUILD_STATE: Immediate verify - %s.clan_name = '%s'" % [npc.npc_name, verify_immediate])
			
			# Emit signal to notify states of clan_name change
			if npc.has_signal("clan_name_changed"):
				npc.emit_signal("clan_name_changed", old_clan, clan_name)
			
			# Verify it's set correctly (for debugging) - use helper function
			var verify_clan: String = npc.get_clan_name()
			if verify_clan != clan_name:
				push_error("CRITICAL: Failed to set clan_name in build_state! Expected '%s', got '%s'" % [clan_name, verify_clan])
			else:
				print("✓ Build State: %s.clan_name = '%s' (verified via helper, meta property also set)" % [npc.npc_name, verify_clan])
			
			print("✓ Caveman %s placed land claim at %s with name: %s" % [npc.npc_name, place_pos, clan_name])
			
			# Log successful placement
			UnifiedLogger.log_npc("Land claim placed: %s placed claim '%s' at %s" % [npc.npc_name, clan_name, place_pos], {
				"npc": npc.npc_name,
				"clan": clan_name,
				"pos": "%.1f,%.1f" % [place_pos.x, place_pos.y]
			})
			
			# After placing, check if caveman has 8+ items - if so, auto-deposit
			# When caveman gets close to the land claim, they automatically deposit their inventory
			# (except 1 food item for consuming)
			if npc and npc.inventory:
				var total_items: int = 0
				for i in range(npc.inventory.slot_count):
					var slot = npc.inventory.slots[i]
					if slot != null and slot.get("count", 0) > 0:
						total_items += slot.get("count", 0)
				
				if total_items >= 8:
					# Has 8+ items - auto-deposit will handle depositing when NPC enters land claim
					# No need to transition to deposit state (removed - auto-deposit in npc_base.gd handles this)
					if fsm:
						# Verify clan_name is still set
						if npc.clan_name != clan_name:
							push_error("CRITICAL: clan_name lost! Expected '%s', got '%s'" % [clan_name, npc.clan_name])
							npc.clan_name = clan_name  # Re-set it
						# Auto-deposit will handle depositing when NPC enters land claim (400px range)
						UnifiedLogger.log_npc("Action completed: build_land_claim (success)", {
							"npc": npc.npc_name,
							"action": "build_land_claim",
							"success": true,
							"clan_name": clan_name,
							"position": "%.1f,%.1f" % [place_pos.x, place_pos.y],
							"items_count": str(total_items),
							"auto_deposit": "true"
						})
					return
			
			# No items or less than 8 items - transition to gather state
			if fsm:
				# CRITICAL: Exit current state first, then transition to gather
				# This ensures gather_state.enter() is called fresh with the new clan_name
				# Also verify clan_name is set
				if npc.clan_name != clan_name:
					push_error("CRITICAL: clan_name lost before gather transition! Expected '%s', got '%s'" % [clan_name, npc.clan_name])
					npc.clan_name = clan_name  # Re-set it
				
				# Exit build state first, then enter gather state
				# This ensures a clean state transition
				# TRACK: Check meta before state change
				var meta_before_change = npc.get_meta("clan_name", "") if npc.has_meta("clan_name") else ""
				var backup_before_change = npc.get_meta("land_claim_clan_name", "") if npc.has_meta("land_claim_clan_name") else ""
				var direct_before_change = npc.clan_name if npc else ""
				print("🔵 BUILD_STATE PRE-CHANGE: %s - Before state change: direct='%s', meta='%s', backup='%s'" % [npc.npc_name, direct_before_change, meta_before_change, backup_before_change])
				
				fsm.change_state("wander")  # Brief wander to reset
				npc.set_meta("wander_reset_timer", 0.1)  # Very short reset (0.1s)
				npc.set_meta("next_state_after_wander_reset", "gather")  # Then go to gather
				print("✓ Build State: %s placed claim, transitioning to gather via wander reset (clan: '%s')" % [npc.npc_name, npc.clan_name])
				
				# TRACK: Check meta immediately after state change
				var meta_after_change = npc.get_meta("clan_name", "") if npc.has_meta("clan_name") else ""
				var backup_after_change = npc.get_meta("land_claim_clan_name", "") if npc.has_meta("land_claim_clan_name") else ""
				var direct_after_change = npc.clan_name if npc else ""
				print("🔵 BUILD_STATE POST-CHANGE: %s - After state change: direct='%s', meta='%s', backup='%s'" % [npc.npc_name, direct_after_change, meta_after_change, backup_after_change])
				UnifiedLogger.log_npc("Action completed: build_land_claim (success)", {
					"npc": npc.npc_name,
					"action": "build_land_claim",
					"success": true,
					"clan_name": clan_name,
					"position": "%.1f,%.1f" % [place_pos.x, place_pos.y],
					"next_state": "gather_via_wander"
				})
	
	# CRITICAL: If land claim was placed via main._place_npc_land_claim, set timer and transition here
	# (The else block handles the fallback path, but we need to handle the main path too)
	if used_main_method:
		# Land claim was placed via main._place_npc_land_claim
		# Now set timer and transition to gather state (same logic as fallback path)
		if npc and npc.inventory:
			var total_items: int = 0
			for i in range(npc.inventory.slot_count):
				var slot = npc.inventory.slots[i]
				if slot != null and slot.get("count", 0) > 0:
					total_items += slot.get("count", 0)
			
			if total_items >= 8:
				# Has 8+ items - auto-deposit will handle depositing when NPC enters land claim
				# No need to transition to deposit state (removed - auto-deposit in npc_base.gd handles this)
				if npc.clan_name != clan_name:
					push_error("CRITICAL: clan_name lost! Expected '%s', got '%s'" % [clan_name, npc.clan_name])
					npc.clan_name = clan_name
					UnifiedLogger.log_npc("Action completed: build_land_claim (success)", {
						"npc": npc.npc_name,
						"action": "build_land_claim",
						"success": true,
						"clan_name": clan_name,
						"position": "%.1f,%.1f" % [place_pos.x, place_pos.y],
						"items_count": str(total_items),
						"auto_deposit": "true"
					})
				return
		
		# No items or less than 8 items - transition to gather state
		if fsm:
			if npc.clan_name != clan_name:
				push_error("CRITICAL: clan_name lost before gather transition! Expected '%s', got '%s'" % [clan_name, npc.clan_name])
				npc.clan_name = clan_name
			
			var meta_before_change = npc.get_meta("clan_name", "") if npc.has_meta("clan_name") else ""
			var backup_before_change = npc.get_meta("land_claim_clan_name", "") if npc.has_meta("land_claim_clan_name") else ""
			var direct_before_change = npc.clan_name if npc else ""
			print("🔵 BUILD_STATE PRE-CHANGE: %s - Before state change: direct='%s', meta='%s', backup='%s'" % [npc.npc_name, direct_before_change, meta_before_change, backup_before_change])
			
			fsm.change_state("wander")  # Brief wander to reset
			npc.set_meta("wander_reset_timer", 0.1)  # Very short reset (0.1s)
			npc.set_meta("next_state_after_wander_reset", "gather")  # Then go to gather
			print("✓ Build State: %s placed claim, transitioning to gather via wander reset (clan: '%s')" % [npc.npc_name, npc.clan_name])
			
			var meta_after_change = npc.get_meta("clan_name", "") if npc.has_meta("clan_name") else ""
			var backup_after_change = npc.get_meta("land_claim_clan_name", "") if npc.has_meta("land_claim_clan_name") else ""
			var direct_after_change = npc.clan_name if npc else ""
			print("🔵 BUILD_STATE POST-CHANGE: %s - After state change: direct='%s', meta='%s', backup='%s'" % [npc.npc_name, direct_after_change, meta_after_change, backup_after_change])
			UnifiedLogger.log_npc("Action completed: build_land_claim (success)", {
				"npc": npc.npc_name,
				"action": "build_land_claim",
				"success": true,
				"clan_name": clan_name,
				"position": "%.1f,%.1f" % [place_pos.x, place_pos.y],
				"next_state": "gather_via_wander"
			})
	
	# Exit build state
	if fsm:
		fsm.evaluation_timer = 0.0

func enter() -> void:
	# Do NOT reset last_overlap_position or overlap_cooldown here.
	# Otherwise cavemen re-enter from the same spot, hit overlap again, and thrash build↔wander.
	# Cooldown is enforced via npc meta "build_overlap_exit_time" in can_enter(); 500px move check uses last_overlap_position.
	pass

func can_enter() -> bool:
	# Only cavemen can build
	if not npc:
		return false
	
	var npc_name: String = npc.get("npc_name") if npc else "unknown"
	var npc_type_str: String = npc.get("npc_type") if npc else ""
	if npc_type_str != "caveman":
		return false
	
	# Check spawn cooldown - must wait 15 seconds after spawning before can place land claim
	# BUT: If caveman has 8+ items, allow building immediately (bypass cooldown)
	var has_8_items: bool = false
	var total_items: int = 0
	if npc and npc.inventory and npc.inventory.slot_count > 0 and npc.inventory.has_method("get_slot"):
		for i in range(npc.inventory.slot_count):
			var slot: Dictionary = npc.inventory.get_slot(i)
			if not slot.is_empty():
				var c: int = int(slot.get("count", 0))
				if c > 0:
					total_items += c
		if total_items >= 8:
			has_8_items = true
	
	# If they have 8+ items, bypass cooldown check
	if not has_8_items:
		var spawn_time: float = npc.get("spawn_time") if npc else 0.0
		var build_cooldown: float = 6.0  # Faster placement, still gives time to spread out
		if NPCConfig:
			var cooldown_prop = NPCConfig.get("caveman_build_cooldown_after_spawn")
			if cooldown_prop != null:
				build_cooldown = cooldown_prop as float
		
		var current_time: float = Time.get_ticks_msec() / 1000.0
		var time_since_spawn: float = current_time - spawn_time
		
		if spawn_time == 0.0:
			# Spawn time not set - this shouldn't happen, but allow building anyway
			UnifiedLogger.log_npc("Can enter check: %s cannot enter build (spawn_time_not_set)" % npc_name, {
				"npc": npc_name,
				"state": "build",
				"can_enter": false,
				"reason": "spawn_time_not_set",
				"current_time": "%.2f" % current_time,
				"total_items": str(total_items)
			}, UnifiedLogger.Level.DEBUG)
			pass  # Allow building
		elif time_since_spawn < build_cooldown:
			UnifiedLogger.log_npc("Can enter check: %s cannot enter build (cooldown_active)" % npc_name, {
				"npc": npc_name,
				"state": "build",
				"can_enter": false,
				"reason": "cooldown_active",
				"spawn_time": "%.2f" % spawn_time,
				"current_time": "%.2f" % current_time,
				"time_since_spawn": "%.2f" % time_since_spawn,
				"cooldown": "%.2f" % build_cooldown,
				"total_items": str(total_items)
			}, UnifiedLogger.Level.DEBUG)
			return false
		
		# Spread out before placing a claim (avoid clustering)
		var max_spread_time: float = 12.0  # Don't block forever
		var min_distance_from_spawn: float = 150.0
		var min_caveman_spacing: float = 700.0  # Doubled - cavemen must be this far apart
		
		# Check distance from spawn (gives time to move away from start)
		var spawn_pos = npc.get("spawn_position") if npc else null
		if spawn_pos != null and spawn_pos is Vector2:
			var distance_from_spawn: float = npc.global_position.distance_to(spawn_pos)
			if distance_from_spawn < min_distance_from_spawn and time_since_spawn < max_spread_time:
				UnifiedLogger.log_npc("Can enter check: %s cannot enter build (too_close_to_spawn)" % npc_name, {
					"npc": npc_name,
					"state": "build",
					"can_enter": false,
					"reason": "too_close_to_spawn",
					"distance_from_spawn": "%.1f" % distance_from_spawn,
					"min_distance": "%.1f" % min_distance_from_spawn,
					"time_since_spawn": "%.2f" % time_since_spawn
				}, UnifiedLogger.Level.DEBUG)
				return false
		
		# Check spacing from other cavemen before placing
		var nearest_caveman_distance: float = INF
		var npcs := get_tree().get_nodes_in_group("npcs")
		for other in npcs:
			if not is_instance_valid(other) or other == npc:
				continue
			if other.get("npc_type") != "caveman":
				continue
			var dist: float = npc.global_position.distance_to(other.global_position)
			if dist < nearest_caveman_distance:
				nearest_caveman_distance = dist
		
		if nearest_caveman_distance < min_caveman_spacing and time_since_spawn < max_spread_time:
			UnifiedLogger.log_npc("Can enter check: %s cannot enter build (too_close_to_other_caveman)" % npc_name, {
				"npc": npc_name,
				"state": "build",
				"can_enter": false,
				"reason": "too_close_to_other_caveman",
				"nearest_caveman_distance": "%.1f" % nearest_caveman_distance,
				"min_spacing": "%.1f" % min_caveman_spacing,
				"time_since_spawn": "%.2f" % time_since_spawn
			}, UnifiedLogger.Level.DEBUG)
			return false
	
	# Must have a land claim item in inventory
	if not npc.inventory:
		UnifiedLogger.log_npc("Can enter check: %s cannot enter build (no_inventory)" % npc_name, {
			"npc": npc_name,
			"state": "build",
			"can_enter": false,
			"reason": "no_inventory"
		}, UnifiedLogger.Level.DEBUG)
		return false
	
	var has_landclaim: bool = npc.inventory.has_item(ResourceData.ResourceType.LANDCLAIM, 1)
	var landclaim_count: int = npc.inventory.get_count(ResourceData.ResourceType.LANDCLAIM) if npc.inventory else 0
	if not has_landclaim:
		UnifiedLogger.log_npc("Can enter check: %s cannot enter build (no_landclaim_item)" % npc_name, {
			"npc": npc_name,
			"state": "build",
			"can_enter": false,
			"reason": "no_landclaim_item",
			"has_landclaim": str(has_landclaim),
			"landclaim_count": str(landclaim_count),
			"total_items": str(total_items)
		}, UnifiedLogger.Level.DEBUG)
		return false
	
	# Block re-entry for OVERLAP_COOLDOWN_DURATION after exiting due to overlap (stored on NPC; build_state.update() doesn't run in wander)
	if npc.has_meta("build_overlap_exit_time"):
		var exit_time: float = npc.get_meta("build_overlap_exit_time", 0.0) as float
		var now: float = Time.get_ticks_msec() / 1000.0
		if now - exit_time < OVERLAP_COOLDOWN_DURATION:
			UnifiedLogger.log_npc("Can enter check: %s cannot enter build (overlap_cooldown)" % npc_name, {
				"npc": npc_name,
				"state": "build",
				"can_enter": false,
				"reason": "overlap_cooldown",
				"elapsed": "%.2f" % (now - exit_time)
			}, UnifiedLogger.Level.DEBUG)
			return false
	
	# Cannot build if already has a land claim
	var clan_name_check: String = npc.get_clan_name() if npc.has_method("get_clan_name") else (npc.clan_name if npc else "")
	if clan_name_check != null and clan_name_check != "":
		UnifiedLogger.log_npc("Can enter check: %s cannot enter build (already_has_claim)" % npc_name, {
			"npc": npc_name,
			"state": "build",
			"can_enter": false,
			"reason": "already_has_claim",
			"clan_name": clan_name_check
		}, UnifiedLogger.Level.DEBUG)
		return false
	
	# Can enter - overlap check happens in update(), not here (too expensive to run every second)
	UnifiedLogger.log_npc("Can enter check: %s can enter build (all_checks_passed)" % npc_name, {
		"npc": npc_name,
		"state": "build",
		"can_enter": true,
		"reason": "all_checks_passed",
		"total_items": str(total_items),
		"has_8_items": str(has_8_items),
			"landclaim_count": str(landclaim_count),
			"spawn_time": "%.2f" % (npc.get("spawn_time") if npc else 0.0)
		})
	return true

func get_priority() -> float:
	# TOP PRIORITY: If caveman has 8+ items, building becomes the highest priority
	# This ensures they place a land claim as soon as they have enough resources
	if npc and npc.inventory:
		var total_items: int = 0
		for i in range(npc.inventory.slot_count):
			var slot = npc.inventory.slots[i]
			if slot != null and slot.get("count", 0) > 0:
				total_items += slot.get("count", 0)
		
		if total_items >= 8:
			# TOP PRIORITY: Higher than agro (10.0), eat (10.0), and herd (11.0)
			return 25.0  # Highest priority - must build land claim now (higher than agro 10.0)
		
		# CRITICAL FIX: If NPC has land claim item and cooldown expired, give high priority
		# Check conditions directly (don't call can_enter() to avoid recursion issues)
		# Must have land claim item
		var has_landclaim: bool = npc.inventory.has_item(ResourceData.ResourceType.LANDCLAIM, 1)
		if not has_landclaim:
			# No land claim item - use default priority
			pass
		else:
			# Has land claim item - check cooldown
			var spawn_time: float = npc.get("spawn_time") if npc else 0.0
			var build_cooldown: float = 10.0  # Reduced from 15s to 10s for faster productivity
			if NPCConfig:
				var cooldown_prop = NPCConfig.get("caveman_build_cooldown_after_spawn")
				if cooldown_prop != null:
					build_cooldown = cooldown_prop as float
			
			var current_time: float = Time.get_ticks_msec() / 1000.0
			var time_since_spawn: float = current_time - spawn_time
			
			# Check if cooldown expired
			if spawn_time == 0.0 or time_since_spawn >= build_cooldown:
				# Cooldown expired - check if already has claim
				var clan_name_check: String = npc.get_clan_name() if npc.has_method("get_clan_name") else (npc.clan_name if npc else "")
				if clan_name_check == null or clan_name_check == "":
					# No existing claim - can build! Return high priority
					return 25.0  # Higher than agro (10.0) to ensure land claim placement happens first
	
	# High priority for building - cavemen should place land claims after herding wild NPCs
	# Only active when no land claim exists and 15s cooldown is done
	var priority: float = 9.5  # Default (higher than herd_wildnpc 9.0, but lower than when has 8+ items)
	if NPCConfig:
		var config_priority = NPCConfig.get("priority_build")
		if config_priority != null:
			priority = config_priority as float
	
	# Boost priority if actively herding a wild NPC (encourages building after herding)
	# This ensures cavemen build quickly when they have a wild NPC they're herding
	# Check if there are any wild NPCs nearby that we might be herding
	if npc:
		var perception: float = npc.get_stat("perception") if npc else 50.0
		var detection_range: float = perception * 36.0  # From NPCConfig
		var npcs := get_tree().get_nodes_in_group("npcs")
		var wild_npcs_nearby: int = 0
		for other_npc in npcs:
			if other_npc == npc or not is_instance_valid(other_npc):
				continue
			var other_type: String = other_npc.get("npc_type") if other_npc else ""
			if other_type != "woman" and other_type != "sheep" and other_type != "goat":
				continue
			var other_clan: String = other_npc.get("clan_name") if other_npc else ""
			if other_clan == "" and not other_npc.get("is_herded"):
				var distance: float = npc.global_position.distance_to(other_npc.global_position)
				if distance <= detection_range:
					wild_npcs_nearby += 1
		
		if wild_npcs_nearby > 0:
			priority += 0.5  # Boost to 9.5 when wild NPCs nearby (encourages building after herding)
	
	return priority

func get_data() -> Dictionary:
	return {
		"has_landclaim_item": npc.inventory.has_item(ResourceData.ResourceType.LANDCLAIM, 1) if npc and npc.inventory else false
	}

func _generate_random_clan_name() -> String:
	# Generate a landclaim name using naming conventions: Cv CvCv or Cv CvvC
	# (2-letter prefix + 4-letter name)
	const CONSONANTS: String = "BCDFGHJKLMNPQRSTVWXYZ"
	const VOWELS: String = "AEIOU"
	
	# First part: 2-letter prefix (Cv)
	var prefix_c: String = CONSONANTS[randi() % CONSONANTS.length()]
	var prefix_v: String = VOWELS[randi() % VOWELS.length()]
	var prefix: String = prefix_c + prefix_v
	
	# Generate 4-letter name (CvCv or CvvC)
	var pattern: int = randi() % 2  # 0 = CvCv, 1 = CvvC
	
	if pattern == 0:
		# CvCv format
		var c1: String = CONSONANTS[randi() % CONSONANTS.length()]
		var v1: String = VOWELS[randi() % VOWELS.length()]
		var c2: String = CONSONANTS[randi() % CONSONANTS.length()]
		var v2: String = VOWELS[randi() % VOWELS.length()]
		return prefix + " " + c1 + v1 + c2 + v2
	else:
		# CvvC format
		var c1: String = CONSONANTS[randi() % CONSONANTS.length()]
		var v1: String = VOWELS[randi() % VOWELS.length()]
		var v2: String = VOWELS[randi() % VOWELS.length()]
		var c2: String = CONSONANTS[randi() % CONSONANTS.length()]
		return prefix + " " + c1 + v1 + v2 + c2
