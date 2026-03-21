extends "res://scripts/npc/states/base_state.gd"

# Eat state - NPC consumes food to restore hunger

var food_target: Node2D = null
var eat_duration: float = 2.0
var eat_timer: float = 0.0
var exit_check_timer: float = 0.0  # Cooldown to prevent rapid state switching
var exit_check_interval: float = 0.5  # Check exit conditions every 0.5 seconds

# State completion: done when we finished this eat cycle (timer reached)
func is_complete() -> bool:
	return eat_timer >= eat_duration

func enter() -> void:
	eat_timer = 0.0
	# NPCConfig is an autoload, should always be available
	if NPCConfig:
		eat_duration = NPCConfig.eat_duration
	else:
		eat_duration = 2.0  # Fallback
	
	# Log action start
	if npc:
		var food_type: String = "from_inventory"
		if food_target and food_target.has("resource_type"):
			var resource_type = food_target.get("resource_type")
			food_type = ResourceData.get_resource_name(resource_type)
		UnifiedLogger.log_npc("Action started: eat (food: %s)" % food_type, {
			"npc": npc.npc_name,
			"action": "eat",
			"target": food_type
		})
	
	# Show progress display
	if npc and npc.progress_display:
		var icon: Texture2D = null
		var resource_type = ResourceData.ResourceType.BERRIES
		if food_target and food_target.has("resource_type"):
			resource_type = food_target.get("resource_type")
		# Get icon for this resource type
		var icon_path: String = ResourceData.get_resource_icon_path(resource_type)
		if icon_path != "":
			icon = load(icon_path) as Texture2D
		npc.progress_display.start_collection(icon)
		npc.progress_display.collection_time = eat_duration
	
	# Only move to food target if we need to collect from map
	if npc and npc.steering_agent and food_target:
		npc.steering_agent.set_arrive_target(food_target.global_position)
	# If food_target is null, we're eating from inventory (no movement needed)

func update(delta: float) -> void:
	if not npc:
		return
	
	# If in herd mode, check if herder is too far - stop eating to catch up
	if npc.get("is_herded") != null and npc.is_herded and npc.get("herder") != null and npc.herder:
		var herder: Node2D = npc.herder
		if is_instance_valid(herder):
			var distance_to_herder: float = npc.global_position.distance_to(herder.global_position)
			var area_radius: float = 300.0
			if NPCConfig:
				area_radius = NPCConfig.herd_area_radius
			
			# If herder is outside follow area, stop eating and catch up
			if distance_to_herder > area_radius:
				# Stop eating to catch up
				UnifiedLogger.log_npc("Action failed: eat (herder_too_far)", {
					"npc": npc.npc_name,
					"action": "eat",
					"reason": "herder_too_far",
					"distance_to_herder": "%.1f" % distance_to_herder,
					"max_distance": "%.1f" % area_radius
				})
				eat_timer = 0.0
				food_target = null
				if npc.progress_display:
					npc.progress_display.stop_collection()
				if fsm:
					fsm.evaluation_timer = 0.0  # Force evaluation to switch to herd state
				return
	
	# Only check exit conditions periodically to prevent rapid state switching
	exit_check_timer += delta
	var should_check_exit: bool = exit_check_timer >= exit_check_interval
	if should_check_exit:
		exit_check_timer = 0.0
	
		# Check if we should exit eat state (hunger >= 80% and have 1 food item)
		# BUT only if we're not actively eating (timer not running)
		if should_check_exit and npc.stats_component and eat_timer <= 0.0:
			var hunger: float = npc.stats_component.get_stat("hunger")
			var hunger_max: float = npc.stats_component.get_stat("hunger_max")
			var hunger_percent: float = (hunger / hunger_max) * 100.0 if hunger_max > 0 else 0.0
			var eat_threshold: float = 80.0  # Default
			if NPCConfig:
				eat_threshold = NPCConfig.hunger_eat_threshold
			
			# If hunger is above threshold, check if we have enough food
			if hunger_percent >= eat_threshold:
				var npc_type_check: String = npc.get("npc_type") if npc else ""
				var food_in_inventory: int = 0
				# Check inventory
				if npc.inventory:
					# Sheep and goats only count berries
					if npc_type_check == "sheep" or npc_type_check == "goat":
						food_in_inventory = npc.inventory.get_count(ResourceData.ResourceType.BERRIES)
					else:
						# Other NPCs count all food types
						for food_type in [ResourceData.ResourceType.BERRIES, ResourceData.ResourceType.GRAIN]:
							if ResourceData.is_food(food_type):
								food_in_inventory += npc.inventory.get_count(food_type)
				# Also check hotbar (slots 9 and 0 are consumables - indices 8 and 9)
				if npc.hotbar:
					for slot_index in [8, 9]:
						var slot_data = npc.hotbar.get_slot(slot_index)
						if not slot_data.is_empty():
							var item_type = slot_data.get("type", ResourceData.ResourceType.NONE) as ResourceData.ResourceType
							if ResourceData.is_food(item_type):
								food_in_inventory += slot_data.get("count", 1) as int
				
				var food_to_keep: int = 1  # Default
				if NPCConfig:
					food_to_keep = NPCConfig.food_items_to_keep_in_inventory
				
				# If we have enough food, exit eat state to allow wander
				# BUT only if we're not actively eating (don't interrupt mid-eat)
				if food_in_inventory >= food_to_keep:
					# Hide progress display
					if npc.progress_display:
						npc.progress_display.stop_collection()
					food_target = null
					# Don't force immediate evaluation - let it happen naturally
					# This prevents rapid state switching
					if fsm:
						fsm.evaluation_timer = fsm.evaluation_interval * 0.9  # Trigger soon but not immediately
					return
	
	# If we have a food target, check if we're close enough
	if food_target:
		var distance: float = npc.global_position.distance_to(food_target.global_position)
		var eat_dist: float = 32.0  # Default
		if NPCConfig:
			eat_dist = NPCConfig.eat_distance
		if distance >= eat_dist:  # Not close enough yet
			return  # Keep moving toward food
	
	# We're either close to food target OR eating from inventory
	# Start progress display if not already started (for eating from inventory)
	if npc and npc.progress_display and not npc.progress_display.is_collecting():
		var icon: Texture2D = null
		var resource_type = ResourceData.ResourceType.BERRIES
		if food_target and food_target.has("resource_type"):
			resource_type = food_target.get("resource_type")
		var icon_path: String = ResourceData.get_resource_icon_path(resource_type)
		if icon_path != "":
			icon = load(icon_path) as Texture2D
		npc.progress_display.start_collection(icon)
		npc.progress_display.collection_time = eat_duration
	
	eat_timer += delta
	
	# Update progress display
	if npc and npc.progress_display:
		var progress: float = eat_timer / eat_duration
		npc.progress_display.set_progress(progress)
	
	if eat_timer >= eat_duration:
		# If in a clan, get food from storage buildings (land claim inventory)
		if npc and npc.get("clan_name") != null and npc.clan_name != "":
			# Find the land claim for this clan
			var land_claims := get_tree().get_nodes_in_group("land_claims")
			var my_claim: Node2D = null
			for claim in land_claims:
				if not is_instance_valid(claim):
					continue
				var claim_clan: String = ""
				var clan_name_prop = claim.get("clan_name")
				if clan_name_prop != null:
					claim_clan = clan_name_prop as String
				if claim_clan == npc.clan_name:
					my_claim = claim
					break
			
			# Get food from land claim inventory
			if my_claim and my_claim.get("inventory") != null:
				var claim_inventory = my_claim.inventory
				if claim_inventory:
					# Find best food in storage
					# For sheep/goats, prioritize grain > berries
					# Note: FIBER is NOT a consumable - it's a crafting resource
					var npc_type_check: String = npc.get("npc_type") if npc else ""
					var best_food_type: ResourceData.ResourceType = ResourceData.ResourceType.NONE
					var best_nutrient: int = 0
					var food_types_to_check: Array
					if npc_type_check == "sheep" or npc_type_check == "goat":
						food_types_to_check = [ResourceData.ResourceType.GRAIN, ResourceData.ResourceType.BERRIES]
					else:
						food_types_to_check = [ResourceData.ResourceType.BERRIES, ResourceData.ResourceType.GRAIN]
					
					for food_type in food_types_to_check:
						if ResourceData.is_food(food_type):
							var count: int = claim_inventory.get_count(food_type)
							if count > 0:
								var nutrient: int = ResourceData.get_food_nutrient_value(food_type)
								if nutrient > best_nutrient:
									best_nutrient = nutrient
									best_food_type = food_type
					
					# Take food from storage and add to NPC inventory
					if best_food_type != ResourceData.ResourceType.NONE:
						if claim_inventory.remove_item(best_food_type, 1):
							if npc.inventory:
								npc.inventory.add_item(best_food_type, 1)
		
		# Find the best food in inventory OR hotbar to eat (highest nutrient)
		# NPCs can eat from both inventory and hotbar (slots 9 and 0 are consumables)
		# Sheep and goats can ONLY eat berries (not meat or other foods)
		var npc_type_str: String = npc.get("npc_type") if npc else ""
		var resource_type: ResourceData.ResourceType = ResourceData.ResourceType.BERRIES  # Default to berries
		var best_nutrient: int = 0
		var food_source: String = "inventory"  # Track where food came from
		
		# Find best food in inventory
		if npc.inventory:
			# For sheep and goats, check for grain (medium) or berries (least)
			# Prioritize by nutrients: grain (7) > berries (5)
			# Note: FIBER is NOT a consumable - it's a crafting resource
			if npc_type_str == "sheep" or npc_type_str == "goat":
				# Check all food types and pick the one with highest nutrients
				for food_type in [ResourceData.ResourceType.GRAIN, ResourceData.ResourceType.BERRIES]:
					if ResourceData.is_food(food_type):
						var count: int = npc.inventory.get_count(food_type)
						if count > 0:
							var nutrient: int = ResourceData.get_food_nutrient_value(food_type)
							if nutrient > best_nutrient:
								best_nutrient = nutrient
								resource_type = food_type
			else:
				# For other NPCs, check all food types (berries, grain, meat, bread)
				for food_type in [ResourceData.ResourceType.BERRIES, ResourceData.ResourceType.GRAIN, ResourceData.ResourceType.MEAT, ResourceData.ResourceType.BREAD]:
					if ResourceData.is_food(food_type):
						var count: int = npc.inventory.get_count(food_type)
						if count > 0:
							var nutrient: int = ResourceData.get_food_nutrient_value(food_type)
							if nutrient > best_nutrient:
								best_nutrient = nutrient
								resource_type = food_type
								food_source = "inventory"
		
		# Also check hotbar for food (slots 9 and 0 are consumables - indices 8 and 9)
		if npc.hotbar:
			var hotbar_slots_to_check: Array[int] = [8, 9]  # Slots 9 and 0 (indices 8 and 9)
			for slot_index in hotbar_slots_to_check:
				var slot_data = npc.hotbar.get_slot(slot_index)
				if not slot_data.is_empty():
					var item_type = slot_data.get("type", ResourceData.ResourceType.NONE) as ResourceData.ResourceType
					if ResourceData.is_food(item_type):
						# Check if this food is better than what we found in inventory
						var nutrient: int = ResourceData.get_food_nutrient_value(item_type)
						if nutrient > best_nutrient:
							best_nutrient = nutrient
							resource_type = item_type
							food_source = "hotbar"
		
		# If we have a food target (wild NPCs), get its type and collect it first
		if food_target and food_target.has("resource_type"):
			var target_type = food_target.get("resource_type")
			# Collect from map into inventory (resource stays on map)
			if npc.inventory:
				npc.inventory.add_item(target_type, 1)
			# Use the collected food if it's better
			if ResourceData.get_food_nutrient_value(target_type) > best_nutrient:
				resource_type = target_type
		
		# Consume one item from inventory or hotbar
		var has_food: bool = false
		var resource_name: String = ResourceData.get_resource_name(resource_type)
		
		if food_source == "hotbar" and npc.hotbar:
			# Check hotbar slots 9 and 0 (indices 8 and 9) for the food type
			var hotbar_slots_to_check: Array[int] = [8, 9]
			for slot_index in hotbar_slots_to_check:
				var slot_data = npc.hotbar.get_slot(slot_index)
				if not slot_data.is_empty():
					var item_type = slot_data.get("type", ResourceData.ResourceType.NONE) as ResourceData.ResourceType
					if item_type == resource_type:
						has_food = true
						# Remove 1 item from hotbar slot
						var item_count = slot_data.get("count", 1) as int
						if item_count > 1:
							slot_data["count"] = item_count - 1
							npc.hotbar.set_slot(slot_index, slot_data)
						else:
							# Last item - clear slot
							npc.hotbar.set_slot(slot_index, {})
						break
		elif food_source == "inventory" and npc.inventory:
			has_food = npc.inventory.get_count(resource_type) >= 1
			if has_food:
				# Remove from inventory
				npc.inventory.remove_item(resource_type, 1)
		
		if has_food:
			UnifiedLogger.log_npc("Inventory operation: remove 1 %s (source: eat, from: %s)" % [resource_name, food_source], {
				"npc": npc.npc_name,
				"operation": "remove",
				"item": resource_name,
				"amount": 1,
				"source": "eat",
				"from": food_source,
				"hunger_before": "%.1f%%" % ((npc.stats_component.get_stat("hunger") / npc.stats_component.hunger_max) * 100.0)
			})
			# Restore hunger (from eating) - use food-specific restore amount
			if npc.stats_component:
				var restore_percent: float = ResourceData.get_food_hunger_restore_percent(resource_type)
				if restore_percent <= 0.0:
					restore_percent = 5.0  # Fallback to 5% if food type not found
				var restore_amount: float = (npc.stats_component.hunger_max * restore_percent) / 100.0
				npc.stats_component.modify_stat("hunger", restore_amount)
				
				# Check if hunger is still below 80% - if so, stay in eat state to eat another berry
				var new_hunger: float = npc.stats_component.get_stat("hunger")
				var new_hunger_percent: float = (new_hunger / npc.stats_component.hunger_max) * 100.0
				print("NPC %s ate 1 berry, hunger now: %.1f%%" % [npc.npc_name, new_hunger_percent])
				
				# Log successful eat completion
				UnifiedLogger.log_npc("Action completed: eat (success)", {
					"npc": npc.npc_name,
					"action": "eat",
					"success": true,
					"food": resource_name,
					"hunger_after": "%.1f" % new_hunger_percent
				})
				
				# If still below 80% and we have more food, stay in eat state
				# Otherwise, exit to allow gather state to gather food to maintain inventory
				var eat_threshold: float = 80.0  # Default
				if NPCConfig:
					eat_threshold = NPCConfig.hunger_eat_threshold
				if new_hunger_percent < eat_threshold:
					var has_more_food: bool = false
					# Check both inventory and hotbar for more food
					# Sheep and goats check for grain or berries
					# Note: FIBER is NOT a consumable - it's a crafting resource
					if npc_type_str == "sheep" or npc_type_str == "goat":
						# Check inventory
						has_more_food = (
							(npc.inventory and (npc.inventory.get_count(ResourceData.ResourceType.GRAIN) > 0 or
							npc.inventory.get_count(ResourceData.ResourceType.BERRIES) > 0)))
						# Also check hotbar
						if not has_more_food and npc.hotbar:
							for slot_index in [8, 9]:  # Slots 9 and 0
								var slot_data = npc.hotbar.get_slot(slot_index)
								if not slot_data.is_empty():
									var item_type = slot_data.get("type", ResourceData.ResourceType.NONE) as ResourceData.ResourceType
									if item_type == ResourceData.ResourceType.GRAIN or item_type == ResourceData.ResourceType.BERRIES:
										has_more_food = true
										break
					else:
						# Other NPCs check all food types in inventory
						if npc.inventory:
							for food_type in [ResourceData.ResourceType.BERRIES, ResourceData.ResourceType.GRAIN]:
								if ResourceData.is_food(food_type) and npc.inventory.get_count(food_type) > 0:
									has_more_food = true
									break
						# Also check hotbar
						if not has_more_food and npc.hotbar:
							for slot_index in [8, 9]:  # Slots 9 and 0
								var slot_data = npc.hotbar.get_slot(slot_index)
								if not slot_data.is_empty():
									var item_type = slot_data.get("type", ResourceData.ResourceType.NONE) as ResourceData.ResourceType
									if ResourceData.is_food(item_type):
										has_more_food = true
										break
					if has_more_food:
						# Reset timer to eat another food item
						eat_timer = 0.0
						return  # Stay in eat state
				else:
					# Hunger is now above 80%, exit state naturally (don't force immediate evaluation)
					# The FSM will evaluate on its normal interval
					pass
			else:
				# No food in inventory - shouldn't happen, but handle gracefully
				UnifiedLogger.log_npc("Action failed: eat (no_food_in_inventory)", {
					"npc": npc.npc_name,
					"action": "eat",
					"reason": "no_food_in_inventory"
				})
				print("NPC %s tried to eat but has no food in inventory" % npc.npc_name)
		
		# Don't remove the resource from the map (unlimited resources)
		# The food was consumed from inventory, resource stays on map
		
		# Hide progress display
		if npc and npc.progress_display:
			npc.progress_display.stop_collection()
		
		food_target = null
		# Reset timer so FSM can switch states
		eat_timer = 0.0
		# Exit state (will evaluate new state)
		if fsm:
			fsm.evaluation_timer = 0.0  # Force immediate evaluation to exit state

func can_enter() -> bool:
	var npc_name: String = npc.get("npc_name") if npc else "unknown"
	
	# Wild NPCs don't eat - they don't have hunger/wants
	if not npc:
		return false
	
	if npc.is_wild():
		return false
	
	# If in a clan, check for food in storage buildings instead of gathering
	if npc and npc.get("clan_name") != null and npc.clan_name != "":
		# Clan members eat from storage buildings - check if there's food available
		if not npc.stats_component:
			UnifiedLogger.log_npc("Can enter check: %s cannot enter eat (no_stats_component)" % npc_name, {
				"npc": npc_name,
				"state": "eat",
				"can_enter": false,
				"reason": "no_stats_component"
			}, UnifiedLogger.Level.DEBUG)
			return false
		var hunger: float = npc.stats_component.get_stat("hunger")
		var hunger_max: float = npc.stats_component.get_stat("hunger_max")
		var hunger_percent: float = (hunger / hunger_max) * 100.0 if hunger_max > 0 else 0.0
		var eat_threshold: float = 80.0
		if NPCConfig:
			eat_threshold = NPCConfig.hunger_eat_threshold
		
		# Check if hungry
		if hunger_percent >= eat_threshold:
			UnifiedLogger.log_npc("Can enter check: %s cannot enter eat (not_hungry_enough)" % npc_name, {
				"npc": npc_name,
				"state": "eat",
				"can_enter": false,
				"reason": "not_hungry_enough",
				"hunger_percent": "%.1f%%" % hunger_percent,
				"threshold": "%.1f%%" % eat_threshold
			}, UnifiedLogger.Level.DEBUG)
			return false  # Not hungry enough
		
		# Check if there's food in storage (land claim inventory) OR in NPC inventory
		# Find the land claim for this clan
		var land_claims := get_tree().get_nodes_in_group("land_claims")
		for claim in land_claims:
			if not is_instance_valid(claim):
				continue
			var claim_clan: String = ""
			var clan_name_prop = claim.get("clan_name")
			if clan_name_prop != null:
				claim_clan = clan_name_prop as String
			if claim_clan == npc.clan_name:
				# Found our land claim - check if it has food
				if claim.get("inventory") != null:
					var claim_inventory = claim.inventory
					if claim_inventory:
						# Check for any food in storage
						# Sheep and goats can eat grain (medium) or berries (least)
						# Note: FIBER is NOT a consumable - it's a crafting resource
						var npc_type_check: String = npc.get("npc_type") if npc else ""
						if npc_type_check == "sheep" or npc_type_check == "goat":
							# Check for grain or berries (prioritize by nutrients: grain > berries)
							for food_type in [ResourceData.ResourceType.GRAIN, ResourceData.ResourceType.BERRIES]:
								if ResourceData.is_food(food_type) and claim_inventory.get_count(food_type) > 0:
									var food_name: String = ResourceData.get_resource_name(food_type)
									UnifiedLogger.log_npc("Can enter check: %s can enter eat (food_in_storage)" % npc_name, {
										"npc": npc_name,
										"state": "eat",
										"can_enter": true,
										"reason": "food_in_storage",
										"hunger_percent": "%.1f%%" % hunger_percent,
										"food": food_name,
										"clan": npc.clan_name
									}, UnifiedLogger.Level.DEBUG)
									return true  # Food available in storage
						else:
							# Other NPCs check all food types
							for food_type in [ResourceData.ResourceType.BERRIES, ResourceData.ResourceType.GRAIN]:
								if ResourceData.is_food(food_type):
									if claim_inventory.get_count(food_type) > 0:
										var food_name: String = ResourceData.get_resource_name(food_type)
										UnifiedLogger.log_npc("Can enter check: %s can enter eat (food_in_storage)" % npc_name, {
											"npc": npc_name,
											"state": "eat",
											"can_enter": true,
											"reason": "food_in_storage",
											"hunger_percent": "%.1f%%" % hunger_percent,
											"food": food_name,
											"clan": npc.clan_name
										}, UnifiedLogger.Level.DEBUG)
										return true  # Food available in storage
				break
		
		# Also check NPC's own inventory and hotbar (they might have food already)
		# Check inventory first
		if npc.inventory:
			for food_type in [ResourceData.ResourceType.BERRIES, ResourceData.ResourceType.GRAIN]:
				if ResourceData.is_food(food_type):
					if npc.inventory.get_count(food_type) > 0:
						var food_name: String = ResourceData.get_resource_name(food_type)
						UnifiedLogger.log_npc("Can enter check: %s can enter eat (food_in_inventory)" % npc_name, {
							"npc": npc_name,
							"state": "eat",
							"can_enter": true,
							"reason": "food_in_inventory",
							"hunger_percent": "%.1f%%" % hunger_percent,
							"food": food_name,
							"clan": npc.clan_name
						}, UnifiedLogger.Level.DEBUG)
						return true  # Food in inventory
		
		# Check hotbar (slots 9 and 0 are consumables - indices 8 and 9)
		if npc.hotbar:
			for slot_index in [8, 9]:
				var slot_data = npc.hotbar.get_slot(slot_index)
				if not slot_data.is_empty():
					var item_type = slot_data.get("type", ResourceData.ResourceType.NONE) as ResourceData.ResourceType
					if ResourceData.is_food(item_type):
						var food_name: String = ResourceData.get_resource_name(item_type)
						UnifiedLogger.log_npc("Can enter check: %s can enter eat (food_in_hotbar)" % npc_name, {
							"npc": npc_name,
							"state": "eat",
							"can_enter": true,
							"reason": "food_in_hotbar",
							"hunger_percent": "%.1f%%" % hunger_percent,
							"food": food_name,
							"clan": npc.clan_name
						}, UnifiedLogger.Level.DEBUG)
						return true  # Food in hotbar
		
		UnifiedLogger.log_npc("Can enter check: %s cannot enter eat (no_food_available)" % npc_name, {
			"npc": npc_name,
			"state": "eat",
			"can_enter": false,
			"reason": "no_food_available",
			"hunger_percent": "%.1f%%" % hunger_percent,
			"clan": npc.clan_name
		}, UnifiedLogger.Level.DEBUG)
		return false  # No food available
	# Can eat if hungry and we have food in inventory (don't collect during eat state)
	if not npc or not npc.stats_component:
		UnifiedLogger.log_npc("Can enter check: %s cannot enter eat (npc_or_stats_null)" % npc_name, {
			"npc": npc_name,
			"state": "eat",
			"can_enter": false,
			"reason": "npc_or_stats_null"
		}, UnifiedLogger.Level.DEBUG)
		return false
	
	# Safety check for NPCConfig (autoload should always exist, but check just in case)
	var config = get_node_or_null("/root/NPCConfig")
	if not config:
		UnifiedLogger.log_npc("Can enter check: %s cannot enter eat (npc_config_not_found)" % npc_name, {
			"npc": npc_name,
			"state": "eat",
			"can_enter": false,
			"reason": "npc_config_not_found"
		}, UnifiedLogger.Level.DEBUG)
		return false
	
	var hunger: float = npc.stats_component.get_stat("hunger")
	var hunger_percent: float = (hunger / npc.stats_component.hunger_max) * 100.0
	
	# Eat when hunger is below threshold (80%)
	var eat_threshold: float = 80.0  # Default
	if NPCConfig:
		eat_threshold = NPCConfig.hunger_eat_threshold
	if hunger_percent < eat_threshold:
		# Only eat if we have food in inventory (gather state will gather it first)
		# Sheep and goats can only eat berries
		var npc_type_str: String = npc.get("npc_type") if npc else ""
		# Check both inventory and hotbar for food
		var best_food_type: ResourceData.ResourceType = ResourceData.ResourceType.NONE
		var best_nutrient: int = 0
		var has_food: bool = false
		
		# Check inventory first
		if npc.inventory:
			# Sheep and goats check for grain or berries (FIBER is NOT a consumable)
			# Note: FIBER is NOT a consumable - it's a crafting resource
			if npc_type_str == "sheep" or npc_type_str == "goat":
				for food_type in [ResourceData.ResourceType.GRAIN, ResourceData.ResourceType.BERRIES]:
					if ResourceData.is_food(food_type):
						var count: int = npc.inventory.get_count(food_type)
						if count > 0:
							has_food = true
							var nutrient: int = ResourceData.get_food_nutrient_value(food_type)
							if nutrient > best_nutrient:
								best_nutrient = nutrient
								best_food_type = food_type
			else:
				# Other NPCs check all food types, prefer highest nutrient
				for food_type in [ResourceData.ResourceType.BERRIES, ResourceData.ResourceType.GRAIN]:
					if ResourceData.is_food(food_type):
						var count: int = npc.inventory.get_count(food_type)
						if count > 0:
							has_food = true
							var nutrient: int = ResourceData.get_food_nutrient_value(food_type)
							if nutrient > best_nutrient:
								best_nutrient = nutrient
								best_food_type = food_type
		
		# Also check hotbar (slots 9 and 0 are consumables - indices 8 and 9)
		if npc.hotbar:
			for slot_index in [8, 9]:
				var slot_data = npc.hotbar.get_slot(slot_index)
				if not slot_data.is_empty():
					var item_type = slot_data.get("type", ResourceData.ResourceType.NONE) as ResourceData.ResourceType
					if ResourceData.is_food(item_type):
						# Check if this food is better than what we found in inventory
						var nutrient: int = ResourceData.get_food_nutrient_value(item_type)
						if nutrient > best_nutrient:
							best_nutrient = nutrient
							best_food_type = item_type
							has_food = true
		
		if has_food:
			# We have food in inventory, can eat
			food_target = null  # No need for map resource
			var food_name: String = ResourceData.get_resource_name(best_food_type)
			UnifiedLogger.log_npc("Can enter check: %s can enter eat (has_food_in_inventory)" % npc_name, {
				"npc": npc_name,
				"state": "eat",
				"can_enter": true,
				"reason": "has_food_in_inventory",
				"hunger_percent": "%.1f%%" % hunger_percent,
				"food": food_name
			}, UnifiedLogger.Level.DEBUG)
			return true
		else:
			UnifiedLogger.log_npc("Can enter check: %s cannot enter eat (no_food_in_inventory)" % npc_name, {
				"npc": npc_name,
				"state": "eat",
				"can_enter": false,
				"reason": "no_food_in_inventory",
				"hunger_percent": "%.1f%%" % hunger_percent
			}, UnifiedLogger.Level.DEBUG)
	
	UnifiedLogger.log_npc("Can enter check: %s cannot enter eat (hunger_above_threshold)" % npc_name, {
		"npc": npc_name,
		"state": "eat",
		"can_enter": false,
		"reason": "hunger_above_threshold",
		"hunger_percent": "%.1f%%" % hunger_percent,
		"threshold": "%.1f%%" % eat_threshold
	}, UnifiedLogger.Level.DEBUG)
	return false

func get_priority() -> float:
	# Higher priority if very hungry
	if not npc or not npc.stats_component:
		return 0.0
	
	var hunger: float = npc.stats_component.get_stat("hunger")
	var hunger_percent: float = (hunger / npc.stats_component.hunger_max) * 100.0
	
	# Only return priority if hunger is below threshold
	var eat_threshold: float = 80.0  # Default
	if NPCConfig:
		eat_threshold = NPCConfig.hunger_eat_threshold
	if hunger_percent < eat_threshold:
		# Check if we have any food to eat (inventory or hotbar)
		var has_food: bool = false
		# Check inventory
		if npc.inventory:
			for food_type in [ResourceData.ResourceType.BERRIES, ResourceData.ResourceType.GRAIN]:
				if ResourceData.is_food(food_type) and npc.inventory.get_count(food_type) > 0:
					has_food = true
					break
		# Check hotbar (slots 9 and 0 are consumables - indices 8 and 9)
		if not has_food and npc.hotbar:
			for slot_index in [8, 9]:
				var slot_data = npc.hotbar.get_slot(slot_index)
				if not slot_data.is_empty():
					var item_type = slot_data.get("type", ResourceData.ResourceType.NONE) as ResourceData.ResourceType
					if ResourceData.is_food(item_type):
						has_food = true
						break
			if has_food:
				# Use config priorities
				if NPCConfig:
					if hunger_percent < 30.0:
						return NPCConfig.priority_eat_very_hungry
					elif hunger_percent < 50.0:
						return NPCConfig.priority_eat_hungry
					else:
						return NPCConfig.priority_eat_low
				else:
					# Fallback priorities
					if hunger_percent < 30.0:
						return 10.0
					elif hunger_percent < 50.0:
						return 7.0
					else:
						return 5.0
	
	return 0.0

func _find_food() -> Node2D:
	# Find nearest food resource (berries only for humans, berries and wheat for animals)
	if not npc:
		return null
	
	var perception: float = npc.get_stat("perception")
	var multiplier: float = 20.0  # Default
	if NPCConfig:
		multiplier = NPCConfig.perception_range_multiplier
	var detection_range: float = perception * multiplier
	
	# Check if this is a human (caveman or woman) - they can't eat raw wheat
	var is_human: bool = npc.get("npc_type") == "human" or npc.get("npc_type") == "caveman" or npc.get("npc_type") == "woman"
	
	# Get all resources
	var resources := get_tree().get_nodes_in_group("resources")
	var nearest: Node2D = null
	var nearest_distance := INF
	
	for resource in resources:
		if not is_instance_valid(resource):
			continue
		
		var distance: float = npc.global_position.distance_to(resource.global_position)
		if distance < detection_range and distance < nearest_distance:
			# Check if it's edible
			if resource.has_method("is_edible") and resource.is_edible():
				# For humans, only berries are edible (wheat needs cooking)
				if is_human:
					# Check if it's berries (not wheat)
					var resource_type = resource.get("resource_type")
					if resource_type == ResourceData.ResourceType.BERRIES:
						nearest = resource
						nearest_distance = distance
				else:
					# Animals can eat both berries and wheat
					nearest = resource
					nearest_distance = distance
	
	return nearest

func get_data() -> Dictionary:
	var data: Dictionary = {
		"has_food_target": food_target != null,
		"eat_timer": eat_timer,
		"eat_duration": eat_duration
	}
	if npc and npc.stats_component:
		var hunger: float = npc.stats_component.get_stat("hunger")
		var hunger_max: float = npc.stats_component.get_stat("hunger_max")
		var hunger_percent: float = (hunger / hunger_max) * 100.0 if hunger_max > 0 else 0.0
		data["hunger_percent"] = hunger_percent
	if food_target:
		var resource_type = food_target.get("resource_type")
		if resource_type != null:
			var resource_name: String = ResourceData.get_resource_name(resource_type) if ResourceData else str(resource_type)
			data["target_resource"] = resource_name
	return data
