extends Node
class_name BabyGrowthComponent

# Baby Growth Component - Babies grow to clansmen after 1 minute (testing) or at 13 years (normal)

var npc: NPCBase = null
var growth_timer: float = 0.0
var growth_time: float = 60.0  # 1 minute for testing (will be 13 years normal mode)

func initialize(npc_ref: NPCBase) -> void:
	npc = npc_ref
	# Load config for growth time
	var config = ReproductionConfig.new()
	growth_time = config.baby_growth_time_testing

func update(delta: float) -> void:
	if not npc:
		return
	
	# Only for babies
	if npc.get("npc_type") != "baby":
		return
	
	# Must be in clan
	if not npc.clan_name or npc.clan_name == "":
		return
	
	var previous_timer = growth_timer
	growth_timer += delta
	
	# Update age for display (0-13 years during growth phase only)
	if growth_timer < growth_time and growth_time > 0:
		var age_years: int = int((growth_timer / growth_time) * 13.0)
		npc.set("age", age_years)
	
	# Log progress at 25%, 50%, 75%, and right before growth
	var progress_pct: int = int((growth_timer / growth_time) * 100.0)
	var prev_progress_pct: int = int((previous_timer / growth_time) * 100.0) if growth_time > 0 else 0
	
	# Log milestone progress
	if (progress_pct >= 25 and prev_progress_pct < 25) or \
	   (progress_pct >= 50 and prev_progress_pct < 50) or \
	   (progress_pct >= 75 and prev_progress_pct < 75) or \
	   (growth_timer >= growth_time - 0.1 and previous_timer < growth_time - 0.1):
		UnifiedLogger.log_npc("Baby growth progress: %s is %.0f%% grown (%.1fs/%.1fs remaining)" % [
			npc.npc_name, progress_pct, growth_time - growth_timer, growth_time
		], {
			"npc": npc.npc_name,
			"progress_pct": progress_pct,
			"timer": growth_timer,
			"max_time": growth_time,
			"remaining": growth_time - growth_timer
		}, UnifiedLogger.Level.DEBUG)
	
	if growth_timer >= growth_time:
		_grow_to_clansman()

func _grow_to_clansman() -> void:
	if not npc or not is_instance_valid(npc):
		UnifiedLogger.log_npc("ERROR: Cannot grow baby - npc is invalid", {}, UnifiedLogger.Level.ERROR)
		return
	
	var clan_name = npc.clan_name
	var baby_name = npc.npc_name
	var old_npc_type = npc.get("npc_type")
	var old_age = npc.get("age")
	var current_state = npc.fsm.current_state_name if npc.fsm else "unknown"
	
	UnifiedLogger.log_npc("🌱 BABY GROWTH START: %s growing to clansman (current state: %s, clan: %s)" % [
		baby_name, current_state, clan_name
	], {
		"npc": baby_name,
		"event": "baby_growth_start",
		"old_type": old_npc_type,
		"old_age": old_age,
		"clan": clan_name,
		"current_state": current_state,
		"growth_timer": growth_timer,
		"growth_time": growth_time
	}, UnifiedLogger.Level.INFO)
	
	# Preserve lineage information before type change - try both get() and meta
	var father_name = npc.get("father_name") if npc else null
	var mother_name = npc.get("mother_name") if npc else null
	
	# Fallback to meta if direct property not found
	if (father_name == null or not father_name is String) and npc and npc.has_meta("father_name"):
		father_name = npc.get_meta("father_name")
	if (mother_name == null or not mother_name is String) and npc and npc.has_meta("mother_name"):
		mother_name = npc.get_meta("mother_name")
	
	# Change NPC type to clansman (update both property and set() for consistency)
	npc.npc_type = "clansman"
	npc.set("npc_type", "clansman")  # Also use set() to ensure all references are updated
	npc.set("age", 13)
	
	# Preserve lineage information (father_name and mother_name) when baby becomes clansman
	# Use both set() and meta for maximum persistence
	if father_name != null and father_name is String:
		npc.set("father_name", father_name)
		npc.set_meta("father_name", father_name)
	if mother_name != null and mother_name is String:
		npc.set("mother_name", mother_name)
		npc.set_meta("mother_name", mother_name)
	
	# Verify npc_type was set correctly
	var verify_type = npc.get("npc_type")
	if verify_type != "clansman":
		UnifiedLogger.log_npc("CRITICAL: Failed to set npc_type to 'clansman' for %s! Got: '%s'" % [baby_name, verify_type], {
			"npc": baby_name,
			"expected": "clansman",
			"actual": verify_type
		}, UnifiedLogger.Level.ERROR)
		push_error("CRITICAL: Failed to set npc_type to 'clansman' for %s! Got: '%s'" % [baby_name, verify_type])
	else:
		UnifiedLogger.log_npc("✓ Verified: %s.npc_type = 'clansman' (was: '%s')" % [baby_name, old_npc_type], {
			"npc": baby_name,
			"old_type": old_npc_type,
			"new_type": verify_type
		}, UnifiedLogger.Level.DEBUG)
		print("✓ Verified: %s.npc_type = 'clansman'" % baby_name)
	
	var pi = npc.get_tree().root.get_node_or_null("PlaytestInstrumentor") if npc.get_tree() else null
	if pi and pi.has_method("is_enabled") and pi.is_enabled() and pi.has_method("baby_grew_to_clansman"):
		pi.baby_grew_to_clansman(baby_name, clan_name)
	
	# Change sprite to caveman sprite
	var sprite: Sprite2D = npc.get_node_or_null("Sprite")
	if sprite:
		var texture: Texture2D = AssetRegistry.get_player_sprite()
		if texture:
			sprite.texture = texture
			sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
			if npc.has_method("apply_sprite_offset_for_texture"):
				npc.apply_sprite_offset_for_texture()
			UnifiedLogger.log_npc("✓ Sprite updated: %s sprite changed to caveman sprite" % baby_name, {
				"npc": baby_name,
				"sprite_path": "res://assets/sprites/PlayerB.png"
			}, UnifiedLogger.Level.DEBUG)
		else:
			UnifiedLogger.log_npc("WARNING: Failed to load caveman sprite for %s" % baby_name, {
				"npc": baby_name,
				"sprite_path": "res://assets/sprites/PlayerB.png"
			}, UnifiedLogger.Level.WARNING)
	else:
		UnifiedLogger.log_npc("WARNING: No sprite node found for %s" % baby_name, {
			"npc": baby_name
		}, UnifiedLogger.Level.WARNING)
	
	# Upgrade inventory to standard size (10 slots) when baby grows to clansman
	if npc.inventory:
		var old_slot_count = npc.inventory.slot_count
		var items_to_preserve: Array[Dictionary] = []
		# Preserve existing items
		for i in range(old_slot_count):
			var slot = npc.inventory.slots[i]
			if slot != null and slot is Dictionary and slot.get("count", 0) > 0:
				items_to_preserve.append(slot.duplicate())
		
		# Create new 10-slot inventory (standard size for adults)
		npc.inventory = InventoryData.new(10, false, 1)  # 10 slots, no stacking, max stack 1
		
		# Restore preserved items to new inventory
		for i in range(min(items_to_preserve.size(), 10)):
			npc.inventory.set_slot(i, items_to_preserve[i])
		
		UnifiedLogger.log_npc("Baby inventory upgraded: %d -> 10 slots" % old_slot_count, {
			"npc": baby_name,
			"old_slots": str(old_slot_count),
			"new_slots": "10"
		}, UnifiedLogger.Level.INFO)
	
	# Give clansman hotbar, wood (club) in hotbar slot 1 (right hand), and Combat/Weapon/Health so they can equip and fight (defend/hostile)
	_setup_clansman_combat_and_club()
	
	# Force FSM re-evaluation so clansman can transition to gather/herd_wildnpc states
	# (babies can only wander/idle, but clansmen can gather/herd)
	var fsm_state_before = npc.fsm.current_state_name if npc.fsm else "no_fsm"
	if npc.fsm:
		npc.fsm.evaluation_timer = 0.0  # Force immediate FSM evaluation
		# Also reset state change cooldown so transition can happen immediately
		npc.fsm.last_state_change_time = 0.0
		UnifiedLogger.log_npc("✓ FSM reset: %s FSM evaluation forced (previous state: %s)" % [baby_name, fsm_state_before], {
			"npc": baby_name,
			"previous_state": fsm_state_before,
			"fsm_ready": true
		}, UnifiedLogger.Level.DEBUG)
	else:
		UnifiedLogger.log_npc("ERROR: %s has no FSM! Cannot transition to clansman states" % baby_name, {
			"npc": baby_name
		}, UnifiedLogger.Level.ERROR)
	
	# Verify clansman can now gather/deposit/herd
	var can_gather = false
	var can_herd = false
	var clan_check = npc.get_clan_name() != ""
	var type_check = npc.get("npc_type") == "clansman"
	var is_wild_check = not npc.is_wild()
	
	if npc.fsm:
		var gather_state = npc.fsm._get_state("gather")
		if gather_state:
			can_gather = gather_state.can_enter()
		var herd_state = npc.fsm._get_state("herd_wildnpc")
		if herd_state:
			can_herd = herd_state.can_enter()
	
	UnifiedLogger.log_npc("✅ BABY GROWTH COMPLETE: %s is now a functional clansman (clan: %s)" % [baby_name, clan_name], {
		"npc": baby_name,
		"event": "baby_growth_complete",
		"clan": clan_name,
		"npc_type": verify_type,
		"age": npc.get("age"),
		"inventory_slots": npc.inventory.slot_count if npc.inventory else 0,
		"can_gather": can_gather,
		"can_herd": can_herd,
		"clan_valid": clan_check,
		"type_valid": type_check,
		"not_wild": is_wild_check,
		"fsm_state": npc.fsm.current_state_name if npc.fsm else "no_fsm"
	}, UnifiedLogger.Level.INFO)
	
	# Remove baby growth component
	queue_free()
	
	print("✓ Baby %s grew to clansman (clan: %s, inventory upgraded to 10 slots, club equipped)" % [baby_name, clan_name])


func _setup_clansman_combat_and_club() -> void:
	"""Add hotbar, wood (club) in hotbar slot 1 (right hand), Combat/Weapon/Health components, and equip club."""
	if not npc or not is_instance_valid(npc):
		return
	var baby_name: String = npc.npc_name if npc else "unknown"
	# Hotbar (babies don't have one)
	if not npc.hotbar:
		npc.hotbar = InventoryData.new(10, false, 1)
	# Wood (club) in hotbar slot 1 / right hand — basic weapon, shown only when aggro/defense/combat
	if npc.hotbar:
		npc.hotbar.set_slot(0, {"type": ResourceData.ResourceType.WOOD, "count": 1, "quality": 0})
	if npc.inventory:
		npc.inventory.add_item(ResourceData.ResourceType.WOOD, 1)  # Ensure they have wood for club
	# Combat/Weapon/Health components (babies don't have them; reuse npc_base caveman logic)
	var health_comp = npc.get_node_or_null("HealthComponent")
	if not health_comp:
		var health_script = load("res://scripts/npc/components/health_component.gd") as GDScript
		if health_script:
			health_comp = health_script.new()
			health_comp.name = "HealthComponent"
			npc.add_child(health_comp)
	var combat_comp = npc.get_node_or_null("CombatComponent")
	if not combat_comp:
		var combat_script = load("res://scripts/npc/components/combat_component.gd") as GDScript
		if combat_script:
			combat_comp = combat_script.new()
			combat_comp.name = "CombatComponent"
			npc.add_child(combat_comp)
	var weapon_comp = npc.get_node_or_null("WeaponComponent")
	if not weapon_comp:
		var weapon_script = load("res://scripts/npc/components/weapon_component.gd") as GDScript
		if weapon_script:
			weapon_comp = weapon_script.new()
			weapon_comp.name = "WeaponComponent"
			npc.add_child(weapon_comp)
	# Initialize components (order: Health, Weapon, equip club, then Combat so attack profile uses weapon)
	if health_comp and health_comp.has_method("initialize"):
		health_comp.initialize(npc)
	if weapon_comp and weapon_comp.has_method("initialize"):
		weapon_comp.initialize(npc)
	if weapon_comp and weapon_comp.has_method("equip_weapon"):
		weapon_comp.equip_weapon(ResourceData.ResourceType.WOOD)
		UnifiedLogger.log_npc("✓ %s equipped club (melee weapon for defend/hostile)" % baby_name, {
			"npc": baby_name,
			"weapon": "club"
		}, UnifiedLogger.Level.DEBUG)
	if combat_comp and combat_comp.has_method("initialize"):
		combat_comp.initialize(npc)
