extends Node
class_name HealthComponent

# Health Component - tracks HP, handles death, sets corpse sprite

var npc: Node = null  # NPCBase; use Node to avoid circular parse dependency
var max_hp: int = 30  # 3 hits to kill (10 damage per hit)
var current_hp: int = 30
var is_dead: bool = false
var last_attacker: Node = null  # Who last attacked this NPC
var death_weapon: ResourceData.ResourceType = ResourceData.ResourceType.NONE  # Weapon used to kill

signal health_changed(current_hp: int, max_hp: int)
signal npc_died(npc: Node)

func initialize(npc_ref: Node) -> void:
	npc = npc_ref
	current_hp = max_hp
	is_dead = false

func take_damage(amount: int, attacker: Node = null, weapon_type: ResourceData.ResourceType = ResourceData.ResourceType.NONE) -> void:
	if is_dead:
		return
	
	# Track last attacker and weapon
	if attacker:
		last_attacker = attacker
		if weapon_type != ResourceData.ResourceType.NONE:
			death_weapon = weapon_type
		
		# Push agro event to CombatTick when attacked (Step 2); skip when combat disabled (testing)
		if npc:
			if not (NPCConfig and NPCConfig.get("combat_disabled")):
				if CombatTick:
					CombatTick.push_agro_event(npc, 50.0, "hit", attacker)
			# Set combat target to attacker ONLY if attacker is a valid enemy (not our herder/leader, not same-clan)
			var should_target_attacker: bool = true
			if attacker.is_in_group("player"):
				var herder_val = npc.get("herder")
				if herder_val == attacker:
					should_target_attacker = false  # Don't attack our leader (friendly fire)
				# Same clan - don't attack player (handles empty player_clan when defending player's claim)
				elif npc.has_method("get_clan_name") and attacker.has_method("get_clan_name"):
					var npc_clan: String = npc.get_clan_name()
					var attacker_clan: String = attacker.get_clan_name()
					if npc_clan != "" and attacker_clan != "" and npc_clan == attacker_clan:
						should_target_attacker = false
				# Defending or searching player's claim = player's clansman, never attack player
				if should_target_attacker:
					var dt = npc.get("defend_target")
					var shc = npc.get("search_home_claim")
					if (dt != null and is_instance_valid(dt) and dt.get("player_owned") == true) or (shc != null and is_instance_valid(shc) and shc.get("player_owned") == true):
						should_target_attacker = false
			if should_target_attacker:
				var tid: int = EntityRegistry.get_id(attacker) if EntityRegistry else -1
				npc.set("combat_target_id", tid)
				npc.set("combat_target", attacker)
				if "combat_target_id" in npc:
					npc.combat_target_id = tid
				if "combat_target" in npc:
					npc.combat_target = attacker
	
	current_hp = max(0, current_hp - amount)
	health_changed.emit(current_hp, max_hp)
	
	# Show red X hitmarker
	_show_hitmarker()
	
	if current_hp <= 0:
		die()

func heal(amount: int) -> void:
	if is_dead:
		return
	
	current_hp = min(max_hp, current_hp + amount)
	health_changed.emit(current_hp, max_hp)

func die() -> void:
	if is_dead:
		return
	
	is_dead = true
	current_hp = 0
	
	# Emit combat_ended if NPC was in combat (for playtest instrumentation)
	if npc:
		var was_in_combat: bool = false
		var target_name: String = "unknown"
		if npc.fsm and npc.fsm.has_method("get_current_state_name"):
			was_in_combat = npc.fsm.get_current_state_name() == "combat"
		var ct = npc.get("combat_target")
		if ct and is_instance_valid(ct):
			was_in_combat = true
			var ct_name = ct.get("npc_name")
			if ct_name != null:
				target_name = str(ct_name)
		if was_in_combat:
			var pi = npc.get_node_or_null("/root/PlaytestInstrumentor")
			if pi and pi.has_method("is_enabled") and pi.is_enabled():
				var npc_name_str: String = "unknown"
				var name_val = npc.get("npc_name")
				if name_val != null:
					npc_name_str = str(name_val)
				pi.combat_ended(npc_name_str, target_name)
	# Playtest: emit npc_died for all deaths (combat, starvation, etc.)
	if npc:
		var pi = npc.get_node_or_null("/root/PlaytestInstrumentor")
		if pi and pi.has_method("is_enabled") and pi.is_enabled() and pi.has_method("npc_died"):
			var npc_name_str: String = "unknown"
			var clan_str: String = ""
			var cause_str: String = "unknown"
			if npc.get("npc_name") != null:
				npc_name_str = str(npc.get("npc_name"))
			if npc.get("clan_name") != null:
				clan_str = str(npc.get("clan_name"))
			if last_attacker:
				cause_str = "combat"
			pi.npc_died(npc_name_str, clan_str, cause_str)
	
	# Change sprite to corpse
	_set_corpse_sprite()
	
	# Stop FSM processing
	if npc and npc.fsm:
		npc.fsm.set_process(false)
		npc.fsm.set_physics_process(false)
	
	# Stop steering agent
	if npc and npc.steering_agent:
		if npc.steering_agent.has_method("set_enabled"):
			npc.steering_agent.set_enabled(false)
	
	# Stop weapon component from updating sprite (prevents overriding corpse sprite)
	var weapon_comp = npc.get_node_or_null("WeaponComponent") if npc else null
	if weapon_comp:
		weapon_comp.set_process(false)
	
	# Stop combat component from updating sprite
	# (Combat component doesn't have a _process, but we've already added death checks in _update_combat_sprite)
	
	# OPTIMIZATION: Cancel current job to release resource reservations
	# This ensures resource slots are freed when NPC dies
	if npc and npc.task_runner:
		if npc.task_runner.has_method("cancel_current_job"):
			npc.task_runner.cancel_current_job()
			var npc_name_str: String = "unknown"
			if npc:
				var name_value = npc.get("npc_name")
				if name_value != null:
					npc_name_str = str(name_value)
			print("💀 NPC %s died - job cancelled, resource reservations released" % npc_name_str)

	# OccupationSystem: clear occupation (reserved or occupied) when NPC dies
	if npc and OccupationSystem:
		OccupationSystem.unassign(npc, "death")
	
	# Drop carried travois at corpse position (like player death)
	if npc and npc.has_method("has_travois") and npc.has_travois():
		_drop_travois_at_corpse(npc)
	
	# Stop movement and clear overlay visuals (!!! and follow lines) immediately
	if npc:
		npc.velocity = Vector2.ZERO
		npc.set_meta("is_dead", true)
		if npc.has_method("_clear_overlay_visuals"):
			npc._clear_overlay_visuals()
	
	# Mark as corpse for loot system
	if npc:
		npc.set_meta("is_corpse", true)
		npc.add_to_group("corpses")
		# Corpse yields from CorpseConfig (meat, hide, bone)
		var npc_type_str: String = npc.get("npc_type") if npc else ""
		var yields: Dictionary = CorpseConfig.get_yields(npc_type_str)
		npc.set_meta("meat_remaining", yields.get("meat", 0))
		npc.set_meta("hide_remaining", yields.get("hide", 0))
		npc.set_meta("bone_remaining", yields.get("bone", 0))
		npc.set_meta("corpse_created_at", Time.get_ticks_msec() / 1000.0)
		
		# Store death info (killer and weapon) on the NPC for corpse UI display
		if last_attacker:
			npc.set_meta("killed_by", last_attacker)
			npc.set_meta("death_weapon", death_weapon)
		
		# Verify inventory is preserved for looting
		var npc_inventory = npc.get("inventory")
		if npc_inventory:
			print("💀 CORPSE: %s died - inventory preserved (%d slots, %d items)" % [
				npc.npc_name if npc else "NPC",
				npc_inventory.slot_count if npc_inventory else 0,
				npc_inventory.get_used_slots() if npc_inventory.has_method("get_used_slots") else 0
			])
		else:
			print("⚠️ CORPSE: %s died - WARNING: No inventory found!" % (npc.npc_name if npc else "NPC"))
	
	# Break herd relationships - if this NPC was herding others, release them
	_break_herd_relationships()
	
	# Remove NPC from defender/searcher pool (O(1) - no group lookup)
	var claim = npc.get("defend_target") if npc.get("defend_target") else npc.get("search_home_claim")
	if claim and is_instance_valid(claim) and claim.has_method("remove_npc_from_pools"):
		claim.remove_npc_from_pools(npc)
	
	# Leader succession: If caveman dies, promote oldest clansman to new leader
	if npc:
		var npc_type: String = npc.get("npc_type") if npc else ""
		if npc_type == "caveman":
			_select_new_leader()
	
	# Emit death signal
	npc_died.emit(npc)
	
	print("💀 %s died!" % (npc.npc_name if npc else "NPC"))

func _set_corpse_sprite() -> void:
	if not npc:
		return
	
	var sprite: Sprite2D = npc.get_node_or_null("Sprite")
	if not sprite:
		print("⚠️ CORPSE: No sprite node found for %s" % (npc.npc_name if npc else "NPC"))
		return
	
	var npc_type: String = npc.get("npc_type") if npc else ""
	if npc_type in ["woman", "sheep", "goat"]:
		# Dark grey modulate of original sprite (keep texture)
		sprite.modulate = Color(0.35, 0.35, 0.35)
		var name_str: String = npc.get("npc_name") if npc else "NPC"
		print("💀 CORPSE: Dark grey modulate for %s (%s)" % [name_str, npc_type])
	else:
		# Cavemen: corpsecm.png
		var corpse_texture = AssetRegistry.get_corpse_caveman_sprite()
		if corpse_texture:
			sprite.texture = corpse_texture
			sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
			if npc.has_method("apply_sprite_offset_for_texture"):
				npc.apply_sprite_offset_for_texture()
			print("💀 CORPSE: Set corpse sprite for %s" % (npc.npc_name if npc else "NPC"))
		else:
			print("❌ CORPSE: Failed to load corpse texture for %s" % (npc.npc_name if npc else "NPC"))

func _drop_travois_at_corpse(npc_ref: Node) -> void:
	"""Spawn TravoisGround at corpse position, transfer carried inventory, clear carried state"""
	if not npc_ref or not npc_ref.get("carried_travois_inventory"):
		return
	var inv = npc_ref.get("carried_travois_inventory")
	if not inv:
		return
	var scene = load("res://scenes/TravoisGround.tscn") as PackedScene
	if not scene:
		return
	var tg = scene.instantiate()
	if not tg is TravoisGround:
		tg.queue_free()
		return
	tg.global_position = npc_ref.global_position
	tg.inventory = inv
	npc_ref.set("carried_travois_inventory", null)
	var hb = npc_ref.get("hotbar")
	if hb and hb.has_method("set_slot"):
		hb.set_slot(0, {})
		hb.set_slot(1, {})
	var parent = npc_ref.get_parent()
	if parent:
		parent.add_child(tg)
		print("💀 %s died - dropped travois at corpse" % (npc_ref.get("npc_name") if npc_ref else "NPC"))

func _break_herd_relationships() -> void:
	"""Break herd relationships when this NPC dies - release all NPCs that were following this herder"""
	if not npc:
		return
	
	# Find all NPCs that have this NPC as their herder
	var all_npcs = npc.get_tree().get_nodes_in_group("npcs")
	var released_count = 0
	
	for other_npc in all_npcs:
		if not is_instance_valid(other_npc):
			continue
		if other_npc == npc:
			continue
		
		# Check if this NPC is their herder
		var other_herder = other_npc.get("herder")
		if other_herder == npc:
			# This NPC was herding them - break the relationship
			other_npc.set("is_herded", false)
			other_npc.set("herder", null)
			other_npc.set("herd_mentality_active", false)
			
			# If they were in a clan because of the herder, make them wild again
			# Only clear clan_name if they're herdable NPCs (women, sheep, goats)
			var other_type: String = other_npc.get("npc_type") if other_npc else ""
			if other_type == "woman" or other_type == "sheep" or other_type == "goat":
				# Make them wild again (clear clan_name)
				var old_clan = other_npc.get("clan_name") if other_npc else ""
				if old_clan != "":
					other_npc.set("clan_name", "")
					print("🔄 %s released from herd - became wild (was in clan: %s)" % [
						other_npc.get("npc_name") if other_npc else "NPC",
						old_clan
					])
				else:
					print("🔄 %s released from herd - became wild" % (other_npc.get("npc_name") if other_npc else "NPC"))
			
			# Force FSM to re-evaluate state
			var other_fsm = other_npc.get("fsm")
			if other_fsm:
				other_fsm.evaluation_timer = 0.0
			
			released_count += 1
	
	if released_count > 0:
		print("💀 Herder %s died - released %d NPCs from herd" % [npc.npc_name if npc else "NPC", released_count])

func _get_land_claims() -> Array:
	"""Get land claims - use main's cache when available, else fallback to group lookup."""
	if not npc or not npc.get_tree():
		return []
	var main = npc.get_tree().get_first_node_in_group("main")
	if main and main.has_method("get_cached_land_claims"):
		return main.get_cached_land_claims()
	return npc.get_tree().get_nodes_in_group("land_claims")

func _select_new_leader() -> void:
	"""When a caveman dies, select the oldest clansman in the same clan as the new leader"""
	if not npc:
		return
	
	var dead_caveman_clan: String = npc.get("clan_name") if npc else ""
	if dead_caveman_clan == "":
		return  # No clan, no succession needed
	
	# Find all clansmen in the same clan
	var all_npcs = npc.get_tree().get_nodes_in_group("npcs")
	var candidates: Array = []
	
	for other_npc in all_npcs:
		if not is_instance_valid(other_npc):
			continue
		if other_npc == npc:
			continue  # Skip the dead caveman
		if other_npc.has_method("is_dead") and other_npc.is_dead():
			continue  # Skip dead NPCs
		
		var other_type: String = other_npc.get("npc_type") if other_npc else ""
		var other_clan: String = other_npc.get("clan_name") if other_npc else ""
		
		# Only consider clansmen in the same clan
		if other_type == "clansman" and other_clan == dead_caveman_clan:
			candidates.append(other_npc)
	
	if candidates.size() == 0:
		# No cavemen, no clansmen - clan dies (Phase 1). Babies persist until land claim building destroyed.
		print("💀 CLAN DEATH: Clan %s has no cavemen and no clansmen - clan dies" % dead_caveman_clan)
		_handle_clan_death(dead_caveman_clan)
		return
	
	# Find the oldest clansman
	var oldest_clansman: Node2D = null
	var oldest_age: int = -1
	
	for candidate in candidates:
		if not is_instance_valid(candidate):
			continue
		var candidate_age: int = candidate.get("age") if candidate else 0
		if candidate_age > oldest_age:
			oldest_age = candidate_age
			oldest_clansman = candidate
	
	if not oldest_clansman:
		print("💀 Leader succession: Failed to find oldest clansman")
		return
	
	# Promote the oldest clansman to caveman
	var new_leader_name: String = oldest_clansman.get("npc_name") if oldest_clansman else "unknown"
	oldest_clansman.set("npc_type", "caveman")
	print("👑 Leader succession: %s (age %d) promoted to caveman (new leader of clan %s)" % [
		new_leader_name, oldest_age, dead_caveman_clan
	])
	
	# Update land claim ownership if the dead caveman owned it
	var land_claims = _get_land_claims()
	for claim in land_claims:
		if not is_instance_valid(claim):
			continue
		var claim_clan_prop = claim.get("clan_name")
		var claim_clan: String = claim_clan_prop as String if claim_clan_prop != null else ""
		if claim_clan == dead_caveman_clan:
			# Update owner reference
			var old_owner = claim.get("owner_npc")
			if old_owner == npc:
				claim.set("owner_npc", oldest_clansman)
				claim.set("owner_npc_name", new_leader_name)
				print("👑 Leader succession: Land claim ownership transferred to %s" % new_leader_name)
			# If old_owner doesn't match, land claim ownership remains unchanged

func _show_hitmarker() -> void:
	# Red X above hurt NPC. Use UI layer + screen position so it's always visible.
	if not npc or not is_instance_valid(npc) or not npc.is_inside_tree():
		return
	
	var tree = npc.get_tree()
	var main = tree.current_scene
	var ui = main.get_node_or_null("UI") if main else null
	
	var hitmarker = Label.new()
	hitmarker.text = "X"
	hitmarker.add_theme_color_override("font_color", Color.RED)
	hitmarker.add_theme_font_size_override("font_size", 36)
	# When added to UI (CanvasLayer): z_index 100 is fine. When fallback to NPC: needs Z_ABOVE_WORLD
	hitmarker.z_index = 100
	
	if ui:
		# Viewport/screen position above NPC (always visible)
		var xform: Transform2D = npc.get_viewport().get_canvas_transform()
		var pos: Vector2 = xform * npc.global_position
		pos -= Vector2(14, 44)  # Center X, above head
		hitmarker.set_anchors_preset(Control.PRESET_TOP_LEFT)
		ui.add_child(hitmarker)
		hitmarker.position = pos
		var end_pos := pos + Vector2(0, -36)
		var tween = hitmarker.create_tween()
		if tween:
			tween.tween_property(hitmarker, "position", end_pos, 0.4)
			tween.tween_callback(func():
				if is_instance_valid(hitmarker):
					hitmarker.queue_free()
			)
	else:
		# Fallback: attach to NPC (may be less visible) - needs high z to appear above Y-sorted sprite
		hitmarker.z_as_relative = false
		hitmarker.z_index = YSortUtils.Z_ABOVE_WORLD
		npc.add_child(hitmarker)
		hitmarker.position = Vector2(-12, -36)
		var tween = create_tween()
		if tween:
			tween.tween_property(hitmarker, "position", hitmarker.position + Vector2(0, -24), 0.4)
			tween.tween_callback(func():
				if is_instance_valid(hitmarker):
					hitmarker.queue_free()
			)

func _clan_has_babies(clan_name: String) -> bool:
	"""Check if clan has any babies (potential future leaders)"""
	if not npc or clan_name == "":
		return false
	
	var all_npcs = npc.get_tree().get_nodes_in_group("npcs")
	for other_npc in all_npcs:
		if not is_instance_valid(other_npc):
			continue
		if other_npc.has_method("is_dead") and other_npc.is_dead():
			continue  # Skip dead NPCs
		
		var other_type: String = other_npc.get("npc_type") if other_npc else ""
		var other_clan: String = other_npc.get("clan_name") if other_npc else ""
		
		# Check for babies in the same clan
		if other_type == "baby" and other_clan == clan_name:
			return true
	
	return false

func _handle_clan_death(clan_name: String) -> void:
	"""Handle clan death: make women/animals wild, hide land claim circle, start building decay"""
	if not npc or clan_name == "":
		return
	
	# Make all women and animals in the clan wild again (herdable)
	_make_clan_members_wild(clan_name)
	
	# Find land claim and all buildings for this clan
	var land_claims = _get_land_claims()
	var buildings = npc.get_tree().get_nodes_in_group("buildings")
	
	for claim in land_claims:
		if not is_instance_valid(claim):
			continue
		var claim_clan_prop = claim.get("clan_name")
		var claim_clan: String = claim_clan_prop as String if claim_clan_prop != null else ""
		if claim_clan == clan_name:
			# Hide the area circle
			if claim.has_method("hide_area_circle"):
				claim.hide_area_circle()
			# Start building decay (land claim decays slowest)
			if claim.has_method("start_decay"):
				claim.start_decay()
			print("💀 CLAN DEATH: Land claim for clan %s is now decaying" % clan_name)
	
	# Start decay for all buildings in the clan
	for building in buildings:
		if not is_instance_valid(building):
			continue
		var building_clan_prop = building.get("clan_name")
		var building_clan: String = building_clan_prop as String if building_clan_prop != null else ""
		if building_clan == clan_name:
			# Start building decay (different rates per building type)
			if building.has_method("start_decay"):
				building.start_decay()
			print("💀 CLAN DEATH: Building for clan %s is now decaying" % clan_name)

func _make_clan_members_wild(clan_name: String) -> void:
	"""Make all women and animals in the clan wild again (herdable)"""
	if not npc:
		return
	
	var all_npcs = npc.get_tree().get_nodes_in_group("npcs")
	var made_wild_count = 0
	
	for other_npc in all_npcs:
		if not is_instance_valid(other_npc):
			continue
		if other_npc.has_method("is_dead") and other_npc.is_dead():
			continue  # Skip dead NPCs
		
		var other_type: String = other_npc.get("npc_type") if other_npc else ""
		var other_clan: String = other_npc.get("clan_name") if other_npc else ""
		
		# Only make women, sheep, and goats wild (herdable NPCs)
		if other_clan == clan_name and (other_type == "woman" or other_type == "sheep" or other_type == "goat"):
			# Clear clan name (make wild)
			other_npc.set("clan_name", "")
			# Clear herd relationships
			other_npc.set("is_herded", false)
			other_npc.set("herder", null)
			other_npc.set("herd_mentality_active", false)
			
			# Force FSM to re-evaluate state
			var other_fsm = other_npc.get("fsm")
			if other_fsm:
				other_fsm.evaluation_timer = 0.0
			
			made_wild_count += 1
			print("🔄 %s became wild (clan %s died)" % [
				other_npc.get("npc_name") if other_npc else "NPC",
				clan_name
			])
	
	if made_wild_count > 0:
		print("💀 CLAN DEATH: Made %d NPCs wild from clan %s" % [made_wild_count, clan_name])
