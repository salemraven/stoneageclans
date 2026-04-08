extends Node
class_name CombatComponent

const CombatAllyCheck = preload("res://scripts/systems/combat_ally_check.gd")

# Combat Component - handles attack logic, damage calculation, combat state
# Now with event-driven windup/recovery system

enum CombatState { IDLE, WINDUP, RECOVERY }

var npc: Node2D = null  # Can be NPCBase or Player (CharacterBody2D)
var attack_range: float = 100.0
var current_target: Node2D = null  # Can be NPCBase or Player (CharacterBody2D)
var base_damage: int = 10  # Base damage per hit (3 hits = 30 HP to kill)

# New event-driven combat timing
var state: CombatState = CombatState.IDLE
var windup_time: float = 0.45  # Windup before hit (telegraphs attack)
var recovery_time: float = 0.8  # Recovery after hit (prevents spam)
var base_recovery_time: float = 0.8  # Base recovery (resets after stagger)

# Attack profiles (weapon-specific timings)
var attack_arc: float = 7.0 * PI / 6.0  # 210° total cone (slightly wider than 180°)
var stagger_time: float = 0.0  # Stagger duration when hit (0 = no stagger)

# Legacy cooldown variables (kept for can_attack() method compatibility)
# Note: Event-driven system doesn't use these, but can_attack() still references them
var attack_cooldown: float = 2.0
var last_attack_time: float = 0.0

# Sprite sheet animation (swingclub.png: 4 frames, 3 cols x 2 rows)
var attack_sprite_sheet: Texture2D = null
var sprite_sheet_frame_width: int = 0  # Width of each frame
var sprite_sheet_frame_height: int = 0  # Height of each frame
var sprite_sheet_cols: int = 3
var sprite_sheet_rows: int = 2
var sprite_sheet_frame_count: int = 4  # Frames used: (0,0), (1,0), (2,0), (0,1)
var use_sprite_sheet_animation: bool = false  # Enable sprite sheet animation
var default_sprite_texture: Texture2D = null  # Store original sprite texture

# Safety timeout tracking
var windup_start_time: int = 0  # Track when windup started (for timeout detection)

func initialize(npc_ref: Node2D) -> void:
	npc = npc_ref
	# Update attack profile based on weapon (will be called again when weapon changes)
	_update_attack_profile_from_weapon()
	
	# Try to load attack sprite sheet
	_load_attack_sprite_sheet()
	
	# Set up process callback for timeout detection
	set_process(true)

var recovery_start_time: int = 0  # Track when recovery started (for timeout detection)

func _process(_delta: float) -> void:
	# Safety check: If stuck in WINDUP for too long, force hit frame
	if state == CombatState.WINDUP and windup_start_time > 0:
		var now = Time.get_ticks_msec()
		var elapsed = now - windup_start_time
		var max_windup = int((windup_time + 0.5) * 1000)  # Allow 0.5s extra buffer
		
		if elapsed > max_windup:
			print("⚠️ COMBAT: WINDUP timeout detected! (elapsed=%dms, max=%dms, windup_time=%.2fs) Forcing hit frame..." % [elapsed, max_windup, windup_time])
			windup_start_time = 0  # Reset to prevent spam
			
			# Verify we're still in WINDUP before forcing
			if state == CombatState.WINDUP:
				print("🔧 COMBAT: Forcing hit frame due to timeout")
				_on_hit_frame()  # Force the hit frame
			else:
				print("⚠️ COMBAT: State changed during timeout check (now=%s), skipping force" % CombatState.keys()[state] if state < CombatState.size() else "INVALID")
	
	# Safety check: If stuck in RECOVERY for too long, force recovery end
	# CRITICAL: Check even if recovery_start_time is 0 (might have been reset but still in RECOVERY)
	if state == CombatState.RECOVERY:
		var now = Time.get_ticks_msec()
		
		# If recovery_start_time is 0, set it now (recovery event might have been cancelled)
		if recovery_start_time == 0:
			print("⚠️ COMBAT: RECOVERY state detected but recovery_start_time is 0! Setting it now (recovery event may have been cancelled)")
			recovery_start_time = now - int(recovery_time * 1000)  # Assume recovery started recovery_time ago
		
		var elapsed = now - recovery_start_time
		var max_recovery = int((recovery_time + 1.0) * 1000)  # Allow 1s extra buffer
		
		if elapsed > max_recovery:
			print("⚠️ COMBAT: RECOVERY timeout detected! (elapsed=%dms, max=%dms, recovery_time=%.2fs) Forcing recovery end..." % [elapsed, max_recovery, recovery_time])
			recovery_start_time = 0  # Reset to prevent spam
			
			# Verify we're still in RECOVERY before forcing
			if state == CombatState.RECOVERY:
				print("🔧 COMBAT: Forcing recovery end due to timeout")
				_on_recovery_end()  # Force recovery end
			else:
				print("⚠️ COMBAT: State changed during recovery timeout check (now=%s), skipping force" % CombatState.keys()[state] if state < CombatState.size() else "INVALID")
		
		# CRITICAL: Check if we've been in RECOVERY for a while but sprite is still on wrong frame
		# This handles cases where recovery_end was cancelled but state wasn't reset
		# Force sprite update to recovery frame if we're stuck on hit frame
		if elapsed > 200 and use_sprite_sheet_animation and sprite_sheet_frame_width > 0:  # After 200ms, we should be on recovery frame
			var sprite: Sprite2D = npc.get_node_or_null("Sprite") if npc else null
			if sprite and sprite.texture and sprite.texture is AtlasTexture:
				var atlas = sprite.texture as AtlasTexture
				var current_frame_x = atlas.region.position.x
				var hit_frame_x = sprite_sheet_frame_width * 2  # Frame 3 (hit) is at col 2
				# Check if we're on hit frame (within 5 pixels tolerance)
				if abs(current_frame_x - hit_frame_x) < 5:
					print("🔧 ANIMATION: Detected stuck on HIT frame (frame 3) during RECOVERY - forcing recovery frame")
					_set_combat_frame(4)  # Force recovery frame

func can_attack() -> bool:
	if not npc or not current_target:
		return false
	
	if not is_instance_valid(current_target):
		return false
	
	# Check cooldown
	var current_time = Time.get_ticks_msec() / 1000.0
	if current_time - last_attack_time < attack_cooldown:
		return false
	
	# Check range
	var distance = npc.global_position.distance_to(current_target.global_position)
	if distance > attack_range:
		return false
	
	return true

# Event-driven attack system
func request_attack(target: Node2D) -> void:
	print("🔵 COMBAT: request_attack() called - state=%s, npc=%s, target=%s" % [
		CombatState.keys()[state] if state < CombatState.size() else "INVALID",
		"valid" if npc and is_instance_valid(npc) else "null/invalid",
		"valid" if target and is_instance_valid(target) else "null/invalid"
	])
	
	# CRITICAL: Only allow attack requests when IDLE
	# If in WINDUP or RECOVERY, reject the request (don't cancel - let current attack finish)
	if state != CombatState.IDLE:
		print("⚠️ COMBAT: Rejecting attack - not in IDLE state (state=%s). Current attack must finish first." % CombatState.keys()[state] if state < CombatState.size() else "INVALID")
		return  # Reject - already attacking, wait for current attack to complete
	
	if not npc or not is_instance_valid(target):
		print("❌ COMBAT: Invalid npc or target")
		return
	
	# Check range
	var distance = npc.global_position.distance_to(target.global_position)
	if distance > attack_range:
		print("⚠️ COMBAT: Target out of range (distance=%.1f, range=%.1f)" % [distance, attack_range])
		return
	
	print("✅ COMBAT: Starting attack - distance=%.1f, windup=%.2fs" % [distance, windup_time])
	
	# Update attack profile from weapon (in case weapon changed)
	_update_attack_profile_from_weapon()
	
	# Start windup
	state = CombatState.WINDUP
	current_target = target
	windup_start_time = Time.get_ticks_msec()  # Track windup start for timeout detection
	
	# Store default texture before switching to combat frame (fallback if _load_attack_sprite_sheet ran when sprite was null)
	if not default_sprite_texture:
		var spr: Sprite2D = npc.get_node_or_null("Sprite") if npc else null
		if spr and spr.texture:
			default_sprite_texture = spr.texture
	
	# Update sprite to windup frame
	print("🔵 COMBAT: Updating sprite to WINDUP frame")
	_update_combat_sprite(CombatState.WINDUP)
	
	# Set combat lock (prevents FSM from switching states) - only for NPCs
	if npc and npc.has_method("get") and npc.get("combat_locked") != null:
		npc.combat_locked = true
		print("🔒 COMBAT: Combat lock set")
	
	# Schedule hit event
	var now = Time.get_ticks_msec()
	var hit_time = now + int(windup_time * 1000)
	var windup_ms = int(windup_time * 1000)
	print("⏰ COMBAT: Scheduling hit event at %d (now=%d, windup=%dms, delay=%dms)" % [hit_time, now, windup_ms, hit_time - now])
	
	# Create bound callable and verify it's valid
	var hit_callable = _on_hit_frame.bind()
	if not hit_callable.is_valid():
		print("❌ COMBAT: Failed to create valid callable for hit frame!")
		_cancel_attack()
		return
	
	print("✅ COMBAT: Hit frame callable is valid, scheduling...")
	CombatScheduler.schedule(hit_time, hit_callable, npc.get_instance_id())
	print("✅ COMBAT: Hit event scheduled successfully")
	
	# Schedule mid-windup frame (frame 2) so animation plays instead of freezing on frame 1
	var mid_windup_time = now + int(windup_time * 0.5 * 1000)
	var mid_windup_callable = _on_windup_mid.bind()
	if mid_windup_callable.is_valid():
		CombatScheduler.schedule(mid_windup_time, mid_windup_callable, npc.get_instance_id())
	
	# Debug logging (can be disabled for performance)
	# var attacker_name = "Player"
	# var target_name = "Target"
	# if npc and npc.has_method("get") and npc.get("npc_name"):
	# 	attacker_name = npc.get("npc_name")
	# if target and target.has_method("get") and target.get("npc_name"):
	# 	target_name = target.get("npc_name")
	# print("⚔️ %s starts windup attack on %s (hit in %.2fs)" % [attacker_name, target_name, windup_time])

func _on_windup_mid() -> void:
	# Switch to frame 2 (mid-windup) so windup animates instead of freezing on frame 1
	print("🎨 ANIMATION: _on_windup_mid() called - state=%s" % CombatState.keys()[state] if state < CombatState.size() else "INVALID")
	if state != CombatState.WINDUP:
		print("⚠️ ANIMATION: _on_windup_mid skipped - not in WINDUP state (state=%s)" % CombatState.keys()[state] if state < CombatState.size() else "INVALID")
		return  # Cancelled or already hit
	if not npc or not is_instance_valid(npc):
		print("⚠️ ANIMATION: _on_windup_mid skipped - npc invalid")
		return
	print("🎨 ANIMATION: Updating to mid-windup frame (frame 2)")
	_set_combat_frame(2)

func _on_hit_frame() -> void:
	print("============================================================")
	print("🎯 COMBAT: _on_hit_frame() called")
	print("   State: %s" % CombatState.keys()[state] if state < CombatState.size() else "INVALID")
	print("   NPC: %s" % ("valid" if npc and is_instance_valid(npc) else "INVALID"))
	print("   Target: %s" % ("valid" if current_target and is_instance_valid(current_target) else "INVALID"))
	print("   Windup start time: %d" % windup_start_time)
	
	# CRITICAL: Must exit WINDUP state immediately
	if state != CombatState.WINDUP:
		print("⚠️ COMBAT: Hit frame called but not in WINDUP state (state=%s), cancelling" % CombatState.keys()[state] if state < CombatState.size() else "INVALID")
		_cancel_attack()
		return
	
	if not is_instance_valid(current_target):
		print("❌ COMBAT: Hit frame - target invalid, cancelling")
		_cancel_attack()
		return
	
	if not npc or not is_instance_valid(npc):
		print("❌ COMBAT: Hit frame - npc invalid, cancelling")
		_cancel_attack()
		return
	
	print("✅ COMBAT: Hit frame validation passed")
	
	print("🔵 COMBAT: Validating hit - target=%s, npc=%s" % [
		"valid" if is_instance_valid(current_target) else "invalid",
		"valid" if is_instance_valid(npc) else "invalid"
	])
	
	# Validate hit (target still alive, in range)
	print("🔍 COMBAT: Calling _validate_hit()...")
	var hit_valid = false
	if current_target and is_instance_valid(current_target):
		hit_valid = _validate_hit(current_target)
		print("🔍 COMBAT: _validate_hit() returned: %s" % hit_valid)
	else:
		print("❌ COMBAT: Target invalid before _validate_hit()!")
		_cancel_attack()
		return
	
	if not hit_valid:
		var whiff_reason: String = "invalid"
		if current_target and is_instance_valid(current_target):
			var dist: float = npc.global_position.distance_to(current_target.global_position)
			if dist > attack_range:
				whiff_reason = "out_of_range"
			elif not _is_target_in_attack_arc(current_target):
				whiff_reason = "out_of_arc"
		var pi = npc.get_node_or_null("/root/PlaytestInstrumentor")
		if pi and pi.is_enabled():
			var nn: String = npc.get("npc_name") if npc.get("npc_name") != null else "unknown"
			var tn: String = "unknown"
			if current_target is NPCBase:
				tn = (current_target as NPCBase).npc_name
			elif current_target.is_in_group("player"):
				tn = "Player"
			pi.combat_whiff(nn, tn, whiff_reason)
		print("❌ COMBAT: Hit validation failed")
		# CRITICAL: Instead of cancelling, transition to RECOVERY to complete the attack cycle
		# This prevents oscillation - caveman will complete recovery before next attack
		if state == CombatState.WINDUP:
			print("⚠️ COMBAT: Hit validation failed in WINDUP - transitioning to RECOVERY (whiff)")
			# Transition to RECOVERY instead of cancelling
			state = CombatState.RECOVERY
			recovery_start_time = Time.get_ticks_msec()
			windup_start_time = 0
			
			# Update sprite to recovery frame
			_update_combat_sprite(CombatState.RECOVERY)
			
			# Schedule recovery end (shorter recovery for whiff)
			var now = Time.get_ticks_msec()
			var whiff_recovery_time = recovery_time * 0.5  # Shorter recovery for whiff
			var recovery_end_time = now + int(whiff_recovery_time * 1000)
			var recovery_callable = _on_recovery_end.bind()
			if recovery_callable.is_valid():
				CombatScheduler.schedule(recovery_end_time, recovery_callable, npc.get_instance_id())
				print("⏰ COMBAT: Scheduled whiff recovery end at %d (recovery=%.2fs)" % [recovery_end_time, whiff_recovery_time])
		else:
			print("⚠️ COMBAT: Hit validation failed but not in WINDUP (state=%s), allowing recovery to complete" % CombatState.keys()[state] if state < CombatState.size() else "INVALID")
		return
	
	print("✅ COMBAT: Hit validated, applying damage")
	
	# Apply damage
	# Check if target is a building (can be damaged)
	if current_target.is_in_group("buildings"):
		# Building damage
		var building_damage: float = float(base_damage)
		if current_target.has_method("take_damage"):
			current_target.take_damage(building_damage)
			var pi = npc.get_node_or_null("/root/PlaytestInstrumentor")
			if pi and pi.is_enabled():
				var nn: String = npc.get("npc_name") if npc.get("npc_name") != null else "unknown"
				var ac_b: String = npc.get_clan_name() if npc.has_method("get_clan_name") else ""
				pi.combat_hit(nn, current_target.name if current_target else "building", ac_b, "", false)
			print("⚔️ Building %s took %.1f damage" % [current_target.name if current_target else "unknown", building_damage])
		# Transition to recovery (building attacks don't need full recovery)
		state = CombatState.RECOVERY
		recovery_start_time = Time.get_ticks_msec()
		windup_start_time = 0
		_update_combat_sprite(CombatState.RECOVERY)
		var now = Time.get_ticks_msec()
		var recovery_end_time = now + int(recovery_time * 1000)
		var recovery_callable = _on_recovery_end.bind()
		if recovery_callable.is_valid():
			CombatScheduler.schedule(recovery_end_time, recovery_callable, npc.get_instance_id())
		return
	
	# Get weapon info (NPCs use WeaponComponent, Player uses hotbar)
	var weapon_bonus = 0
	var weapon_type: ResourceData.ResourceType = ResourceData.ResourceType.NONE
	
	if npc.has_method("get") and npc.get("npc_type"):
		# NPC - use WeaponComponent
		var weapon_comp: WeaponComponent = npc.get_node_or_null("WeaponComponent")
		if weapon_comp:
			weapon_bonus = weapon_comp.get_damage_bonus()
			weapon_type = weapon_comp.equipped_weapon
	else:
		# Player - get weapon from slot 1 (right hand)
		if not is_inside_tree():
			print("❌ COMBAT: Not in scene tree, cannot get weapon")
			return
		
		var main: Node = get_tree().get_first_node_in_group("main")
		if main and "player_inventory_ui" in main:
			var player_inventory_ui = main.player_inventory_ui
			if player_inventory_ui and player_inventory_ui.hotbar_slots.size() > player_inventory_ui.RIGHT_HAND_SLOT_INDEX:
				var first_slot = player_inventory_ui.hotbar_slots[player_inventory_ui.RIGHT_HAND_SLOT_INDEX]
				var slot_item = first_slot.get("item_data")
				if slot_item:
					weapon_type = slot_item.get("type", ResourceData.ResourceType.NONE) as ResourceData.ResourceType
					# Player weapons give same bonus as NPC weapons (simplified)
					# In full implementation, use WeaponComponent for player too
					if weapon_type == ResourceData.ResourceType.AXE or weapon_type == ResourceData.ResourceType.PICK:
						weapon_bonus = 0  # Player weapons don't give bonus yet (same as base damage)
	
	var total_damage = base_damage + weapon_bonus
	print("💥 COMBAT: Applying damage - base=%d, bonus=%d, total=%d" % [base_damage, weapon_bonus, total_damage])
	
	print("🔍 COMBAT: Getting HealthComponent from target...")
	if not current_target or not is_instance_valid(current_target):
		print("❌ COMBAT: Target invalid before getting HealthComponent!")
		_cancel_attack()
		return
	
	var target_health: HealthComponent = current_target.get_node_or_null("HealthComponent")
	print("🔍 COMBAT: HealthComponent lookup result: %s" % ("found" if target_health else "null"))
	
	if target_health:
		print("💥 COMBAT: Target health component found, applying damage")
		if is_instance_valid(target_health):
			target_health.take_damage(total_damage, npc, weapon_type)
			var pi = npc.get_node_or_null("/root/PlaytestInstrumentor")
			if pi and pi.is_enabled():
				var nn: String = npc.get("npc_name") if npc.get("npc_name") != null else "unknown"
				var tn: String = "unknown"
				var tc_hit: String = ""
				if current_target is NPCBase:
					tn = (current_target as NPCBase).npc_name
					tc_hit = current_target.get_clan_name() if current_target.has_method("get_clan_name") else ""
				elif current_target.is_in_group("player"):
					tn = "Player"
					tc_hit = current_target.get_clan_name() if current_target.has_method("get_clan_name") else ""
				var ac_hit: String = npc.get_clan_name() if npc.has_method("get_clan_name") else ""
				var ff_hit: bool = CombatAllyCheck.is_ally(npc, current_target)
				pi.combat_hit(nn, tn, ac_hit, tc_hit, ff_hit)
			print("💥 COMBAT: Damage applied successfully")
		else:
			print("❌ COMBAT: HealthComponent became invalid!")
			_cancel_attack()
			return
	else:
		print("❌ COMBAT: Target health component not found!")
		_cancel_attack()
		return
	
	# Apply stagger to target (if they have CombatComponent)
	if stagger_time > 0.0 and current_target:
		print("💥 COMBAT: Applying stagger (%.2fs)" % stagger_time)
		_apply_stagger_to_target(current_target)
	
	# CRITICAL: Exit WINDUP state immediately - transition to RECOVERY
	state = CombatState.RECOVERY
	recovery_start_time = Time.get_ticks_msec()  # Track recovery start for timeout detection
	windup_start_time = 0  # Reset windup start time
	print("🔄 COMBAT: State transition: WINDUP → RECOVERY")
	
	# Update sprite to hit/impact frame (frame 3)
	print("🎨 ANIMATION: Updating sprite to HIT frame")
	_update_combat_sprite_hit()
	var now = Time.get_ticks_msec()
	
	# Show hit frame briefly (0.15s for impact), then switch to recovery frame
	var hit_display_duration = 150  # 0.15s to show hit frame (feels more impactful)
	var hit_display_time = now + hit_display_duration
	print("⏰ COMBAT: Scheduling hit frame display end at %d (duration=%dms)" % [hit_display_time, hit_display_duration])
	
	var hit_display_callable = _on_hit_frame_display_end.bind()
	if not hit_display_callable.is_valid():
		print("❌ COMBAT: Invalid callable for hit_display_end!")
		_cancel_attack()
		return
	CombatScheduler.schedule(hit_display_time, hit_display_callable, npc.get_instance_id())
	print("✅ COMBAT: Hit display end scheduled")
	
	var recovery_end_time = now + int(recovery_time * 1000)
	print("⏰ COMBAT: Scheduling recovery end at %d (recovery=%.2fs)" % [recovery_end_time, recovery_time])
	
	var recovery_callable = _on_recovery_end.bind()
	if not recovery_callable.is_valid():
		print("❌ COMBAT: Invalid callable for recovery_end!")
		_cancel_attack()
		return
	CombatScheduler.schedule(recovery_end_time, recovery_callable, npc.get_instance_id())
	print("✅ COMBAT: Recovery end scheduled")
	print("============================================================")

func _on_recovery_end() -> void:
	print("🔄 COMBAT: _on_recovery_end() called - state=%s" % CombatState.keys()[state] if state < CombatState.size() else "INVALID")
	
	# Safety check: Only transition from RECOVERY to IDLE
	if state != CombatState.RECOVERY:
		print("⚠️ COMBAT: Recovery end called but not in RECOVERY state (state=%s), forcing to IDLE" % CombatState.keys()[state] if state < CombatState.size() else "INVALID")
	
	state = CombatState.IDLE
	current_target = null
	windup_start_time = 0  # Reset windup start time
	recovery_start_time = 0  # Reset recovery start time
	
	# Reset recovery time to base (in case it was extended by stagger)
	recovery_time = base_recovery_time
	
	# Reset sprite to default/idle
	print("🎨 ANIMATION: Resetting sprite to IDLE/default")
	_update_combat_sprite(CombatState.IDLE)
	
	# Release combat lock - only for NPCs
	if npc and npc.has_method("get") and npc.get("combat_locked") != null:
		npc.combat_locked = false
		print("🔓 COMBAT: Combat lock released")
	
	# Set cooldown timestamp to prevent immediate re-attack (prevents oscillation)
	if npc:
		var now = Time.get_ticks_msec()
		npc.set_meta("last_attack_request_time", now)
		print("⏱️ COMBAT: Attack cooldown set (prevents immediate re-attack)")
	
	print("✅ COMBAT: Recovery complete, back to IDLE")
	
	# Debug logging (can be disabled for performance)
	# var attacker_name = "Player"
	# if npc and npc.has_method("get") and npc.get("npc_name"):
	# 	attacker_name = npc.get("npc_name")
	# print("⚔️ %s recovery complete" % attacker_name)

func _cancel_attack() -> void:
	var cancel_entity_id = npc.get_instance_id() if npc else 0
	print("🚫 COMBAT: _cancel_attack() called - current_state=%s, entity_id=%d" % [CombatState.keys()[state] if state < CombatState.size() else "INVALID", cancel_entity_id])
	
	# CRITICAL: Always return to IDLE, regardless of current state
	state = CombatState.IDLE
	current_target = null
	windup_start_time = 0  # Reset windup start time
	recovery_start_time = 0  # Reset recovery start time
	
	# Reset sprite to default/idle
	print("🎨 ANIMATION: Resetting sprite to IDLE (cancelled)")
	_update_combat_sprite(CombatState.IDLE)
	
	# CRITICAL: If default texture is null, force clear combat frame
	# This prevents getting stuck on a combat frame when cancelling
	if not default_sprite_texture:
		var sprite: Sprite2D = npc.get_node_or_null("Sprite") if npc else null
		if sprite and sprite.texture and sprite.texture is AtlasTexture:
			print("🔧 ANIMATION: Default texture is null but sprite has AtlasTexture - clearing combat frame")
			# Try to restore from weapon component or use a fallback
			var weapon_comp = npc.get_node_or_null("WeaponComponent") if npc else null
			if weapon_comp and weapon_comp.has_method("_update_sprite_with_weapon"):
				weapon_comp._update_sprite_with_weapon()
			else:
				# No weapon component - just clear the AtlasTexture
				sprite.texture = null
				print("⚠️ ANIMATION: Cleared sprite texture (no default or weapon texture available)")
	
	# Release combat lock - only for NPCs
	if npc and npc.has_method("get") and npc.get("combat_locked") != null:
		npc.combat_locked = false
		print("🔓 COMBAT: Combat lock released (cancelled)")
	
	# Cancel scheduled events for this entity
	if npc:
		print("⏰ COMBAT: Cancelling all events for entity %d" % cancel_entity_id)
		CombatScheduler.cancel_all_for_entity(cancel_entity_id)
	
	print("✅ COMBAT: Attack cancelled - state reset to IDLE")

func _validate_hit(target: Node) -> bool:
	if not is_instance_valid(target):
		return false
	
	if not npc:
		return false
	
	# Allies never damage each other (safety net vs friendly fire)
	if CombatAllyCheck.is_ally(npc, target):
		return false
	
	# Check if target is alive
	var target_health: HealthComponent = target.get_node_or_null("HealthComponent")
	if not target_health or target_health.is_dead:
		return false
	
	# Check range
	var distance = npc.global_position.distance_to(target.global_position)
	if distance > attack_range:
		return false
	
	# Check attack arc (cone in front of attacker; see attack_arc)
	if not _is_target_in_attack_arc(target):
		return false  # Target moved out of arc - whiff
	
	return true

func _is_target_in_attack_arc(target: Node) -> bool:
	# Calculate direction to target
	var direction_to_target = (target.global_position - npc.global_position).normalized()
	
	# Get attacker's facing direction
	var facing_direction: Vector2
	if npc.has_method("get") and npc.get("velocity"):
		var velocity = npc.get("velocity") as Vector2
		if velocity.length_squared() > 0.1:
			# Use movement direction as facing
			facing_direction = velocity.normalized()
		else:
			# Not moving - use sprite flip or default
			var sprite: Sprite2D = npc.get_node_or_null("Sprite")
			if sprite:
				# Sprite flipped = facing left, not flipped = facing right
				facing_direction = Vector2(-1 if sprite.flip_h else 1, 0)
			else:
				# Default to right
				facing_direction = Vector2(1, 0)
	else:
		# Player or NPC without velocity - check sprite
		var sprite: Sprite2D = npc.get_node_or_null("Sprite")
		if sprite:
			facing_direction = Vector2(-1 if sprite.flip_h else 1, 0)
		else:
			facing_direction = Vector2(1, 0)
	
	# Calculate angle between facing direction and direction to target
	var angle = direction_to_target.angle_to(facing_direction)
	
	# Check if angle is within attack arc (half arc on each side)
	return abs(angle) <= attack_arc / 2.0

func is_target_in_attack_arc(target: Node) -> bool:
	return _is_target_in_attack_arc(target)

# Legacy attack method - redirects to event-driven system
# Kept for backwards compatibility with any code that might still call it
func attack(target: NPCBase) -> void:
	request_attack(target)

func set_target(target: Node2D) -> void:
	# Accept NPCBase or player (CharacterBody2D) when defending vs intruders
	current_target = target

func clear_target() -> void:
	current_target = null

func get_target() -> Node2D:
	# Can return NPCBase or Player (CharacterBody2D)
	return current_target

func _apply_stagger_to_target(target: Node) -> void:
	# Apply stagger effect to target (interrupts their attack if in windup)
	if not target or not is_instance_valid(target):
		return
	# CRITICAL: Never stagger ourselves (would cancel our own attack)
	if target == npc:
		var pi = get_node_or_null("/root/PlaytestInstrumentor")
		if pi and pi.is_enabled() and pi.has_method("stagger_self_blocked"):
			pi.stagger_self_blocked(npc.get("npc_name") if npc else "?", target.get("npc_name") if target else "?")
		UnifiedLogger.write_log_entry("Stagger self-blocked (target==npc) - would cancel own attack", UnifiedLogger.Category.COMBAT, UnifiedLogger.Level.WARNING, {"npc": npc.get("npc_name") if npc else "?"})
		return
	
	var target_combat: CombatComponent = target.get_node_or_null("CombatComponent")
	if not target_combat:
		return
	
	# Redundant guard: target_combat == self would mean target is our npc (already caught above)
	if target_combat == self:
		return
	
	# If target is in windup, cancel their attack (stagger interrupt)
	if target_combat.state == CombatState.WINDUP:
		var attacker_id = npc.get_instance_id() if npc else 0
		var target_id = target.get_instance_id() if target else 0
		print("💥 COMBAT: Staggering target (attacker_id=%d, target_id=%d, target_combat=%s, self=%s)" % [attacker_id, target_id, target_combat, self])
		target_combat._cancel_attack()
		# Debug logging (can be disabled for performance)
		# print("⚔️ %s staggered %s (attack interrupted)" % [
		# 	npc.get("npc_name") if npc and npc.has_method("get") else "Attacker",
		# 	target.get("npc_name") if target.has_method("get") else "Target"
		# ])
	
	# Add stagger time to target's recovery (if they're in recovery)
	if target_combat.state == CombatState.RECOVERY:
		# Extend recovery time by adding stagger
		# Cancel current recovery event and reschedule with extended time
		var now = Time.get_ticks_msec()
		# Calculate remaining recovery time + stagger
		var remaining_recovery = target_combat.recovery_time  # This is the base recovery time
		var extended_recovery = remaining_recovery + stagger_time
		var new_recovery_end = now + int(extended_recovery * 1000)
		
		# Cancel only recovery events (not hit display events)
		# Find and cancel the recovery_end event specifically
		CombatScheduler.cancel_all_for_entity(target.get_instance_id())
		
		# Reschedule recovery end with extended time
		var recovery_callable = target_combat._on_recovery_end.bind()
		if recovery_callable.is_valid():
			CombatScheduler.schedule(new_recovery_end, recovery_callable, target.get_instance_id())
			print("💥 COMBAT: Extended recovery for %s by %.2fs (new end time: %d)" % [target.get("npc_name") if target else "target", stagger_time, new_recovery_end])
		
		# Store extended recovery time temporarily (will reset on recovery end)
		target_combat.recovery_time = extended_recovery

func _get_attack_profile_for_weapon(weapon_type: ResourceData.ResourceType) -> Dictionary:
	# Returns attack profile (windup, recovery, arc, stagger) for weapon type
	match weapon_type:
		ResourceData.ResourceType.AXE:
			return {
				"windup": 0.45,
				"recovery": 0.8,
				"arc": PI,  # 180 degrees (wider for better hit rate)
				"stagger": 0.2  # 0.2s stagger
			}
		ResourceData.ResourceType.PICK:
			return {
				"windup": 0.5,  # Slightly slower
				"recovery": 0.9,
				"arc": PI,  # 180 degrees (wider for better hit rate)
				"stagger": 0.25  # More stagger
			}
		ResourceData.ResourceType.WOOD:
			return {
				"windup": 0.4,
				"recovery": 0.7,
				"arc": PI / 4.0,  # Narrow club arc (directly in front) per AgroGuide Step 1
				"stagger": 0.15
			}
		_:
			# Default unarmed profile
			return {
				"windup": 0.4,
				"recovery": 0.7,
				"arc": PI / 2,
				"stagger": 0.15
			}

func _update_attack_profile_from_weapon() -> void:
	# Update attack timings based on equipped weapon
	var weapon_type: ResourceData.ResourceType = ResourceData.ResourceType.NONE
	
	if npc.has_method("get") and npc.get("npc_type"):
		# NPC - use WeaponComponent
		var weapon_comp: WeaponComponent = npc.get_node_or_null("WeaponComponent")
		if weapon_comp:
			weapon_type = weapon_comp.equipped_weapon
	else:
		# Player - get weapon from slot 1 (right hand)
		if not is_inside_tree():
			print("⚠️ COMBAT: Not in scene tree for weapon profile update")
			return
		
		var main: Node = get_tree().get_first_node_in_group("main")
		if main and "player_inventory_ui" in main:
			var player_inventory_ui = main.player_inventory_ui
			if player_inventory_ui and player_inventory_ui.hotbar_slots.size() > player_inventory_ui.RIGHT_HAND_SLOT_INDEX:
				var first_slot = player_inventory_ui.hotbar_slots[player_inventory_ui.RIGHT_HAND_SLOT_INDEX]
				var slot_item = first_slot.get("item_data")
				if slot_item:
					weapon_type = slot_item.get("type", ResourceData.ResourceType.NONE) as ResourceData.ResourceType
	
	# Apply profile
	var profile = _get_attack_profile_for_weapon(weapon_type)
	windup_time = profile.windup
	recovery_time = profile.recovery
	base_recovery_time = profile.recovery  # Store base for reset after stagger
	attack_arc = profile.arc
	stagger_time = profile.stagger

func _load_attack_sprite_sheet() -> void:
	if not npc:
		return
	var nt: String = npc.get("npc_type") as String if npc.get("npc_type") != null else ""
	if nt in ["sheep", "goat"]:
		return  # Sheep and goats do not melee attack

	print("🎨 ANIMATION: _load_attack_sprite_sheet() called")

	# Load swingclub.png (4 frames: 3 cols x 2 rows)
	var sprite_sheet_path = "res://assets/sprites/swingclub.png"
	print("🎨 ANIMATION: Loading sprite sheet from: %s" % sprite_sheet_path)
	attack_sprite_sheet = load(sprite_sheet_path) as Texture2D
	
	if attack_sprite_sheet:
		print("✅ ANIMATION: Sprite sheet loaded successfully")
		use_sprite_sheet_animation = true
		var texture_width = attack_sprite_sheet.get_width()
		var texture_height = attack_sprite_sheet.get_height()
		print("🎨 ANIMATION: Texture dimensions - width=%d, height=%d" % [texture_width, texture_height])
		
		if texture_width > 0 and sprite_sheet_cols > 0 and texture_height > 0 and sprite_sheet_rows > 0:
			sprite_sheet_frame_width = texture_width / sprite_sheet_cols
			sprite_sheet_frame_height = texture_height / sprite_sheet_rows
			print("✅ ANIMATION: Frame size: %dx%d (grid %dx%d)" % [sprite_sheet_frame_width, sprite_sheet_frame_height, sprite_sheet_cols, sprite_sheet_rows])
		else:
			use_sprite_sheet_animation = false
			print("❌ ANIMATION: Invalid sprite sheet dimensions")
			return
		
		# Store default sprite texture (important for restoring after combat)
		var sprite: Sprite2D = npc.get_node_or_null("Sprite")
		if sprite:
			if sprite.texture:
				default_sprite_texture = sprite.texture
				print("✅ ANIMATION: Default sprite texture stored")
			else:
				print("⚠️ ANIMATION: Sprite has no texture to store as default")
		else:
			print("⚠️ ANIMATION: Sprite node not found")
	else:
		use_sprite_sheet_animation = false
		print("⚠️ ANIMATION: Sprite sheet not found: %s (using default sprites)" % sprite_sheet_path)

func _set_combat_frame(frame_index: int) -> void:
	# Internal helper: apply frame 1-4. Grid layout: 1=(0,0), 2=(1,0), 3=(2,0), 4=(0,1)
	if not npc or not is_instance_valid(npc):
		print("⚠️ ANIMATION: _set_combat_frame failed - npc invalid (frame=%d)" % frame_index)
		return
	if not use_sprite_sheet_animation or not attack_sprite_sheet or sprite_sheet_frame_width <= 0:
		print("⚠️ ANIMATION: _set_combat_frame failed - sprite sheet not available (frame=%d)" % frame_index)
		return
	if frame_index < 1 or frame_index > sprite_sheet_frame_count:
		print("⚠️ ANIMATION: _set_combat_frame failed - invalid frame index %d (max=%d)" % [frame_index, sprite_sheet_frame_count])
		return
	var sprite: Sprite2D = npc.get_node_or_null("Sprite")
	if not sprite or not is_instance_valid(sprite):
		print("⚠️ ANIMATION: _set_combat_frame failed - sprite node invalid (frame=%d)" % frame_index)
		return
	# Map frame_index 1-4 to grid: (0,0), (1,0), (2,0), (0,1)
	var col: int
	var row: int
	match frame_index:
		1: col = 0; row = 0
		2: col = 1; row = 0
		3: col = 2; row = 0
		4: col = 0; row = 1
		_: col = 0; row = 0
	var frame_x = col * sprite_sheet_frame_width
	var frame_y = row * sprite_sheet_frame_height
	var atlas_texture = AtlasTexture.new()
	atlas_texture.atlas = attack_sprite_sheet
	atlas_texture.region = Rect2(frame_x, frame_y, sprite_sheet_frame_width, sprite_sheet_frame_height)
	sprite.texture = atlas_texture
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	if npc.has_method("apply_sprite_offset_for_texture"):
		npc.apply_sprite_offset_for_texture()
	print("✅ ANIMATION: Frame %d applied successfully" % frame_index)

func _update_combat_sprite(combat_state: CombatState) -> void:
	print("🎨 ANIMATION: _update_combat_sprite() called - state=%s" % CombatState.keys()[combat_state] if combat_state < CombatState.size() else "INVALID")
	
	if not npc or not is_instance_valid(npc):
		print("❌ ANIMATION: npc invalid")
		return
	
	if not use_sprite_sheet_animation or not attack_sprite_sheet:
		print("⚠️ ANIMATION: Sprite sheet not available (use_sheet=%s, texture=%s)" % [use_sprite_sheet_animation, "valid" if attack_sprite_sheet else "null"])
		return
	
	if sprite_sheet_frame_width <= 0:
		print("❌ ANIMATION: Invalid frame width (%d)" % sprite_sheet_frame_width)
		return
	
	var sprite: Sprite2D = npc.get_node_or_null("Sprite")
	if not sprite or not is_instance_valid(sprite):
		print("❌ ANIMATION: Sprite node invalid")
		return
	
	# If IDLE, restore default texture instead
	# CRITICAL: Don't restore sprite if NPC is dead (corpse sprite should stay)
	if combat_state == CombatState.IDLE:
		# Check if NPC is dead before restoring sprite
		var health_comp = npc.get_node_or_null("HealthComponent") if npc else null
		var is_dead: bool = false
		if health_comp and health_comp.has_method("get") and health_comp.get("is_dead") != null:
			is_dead = health_comp.is_dead
		elif npc and npc.has_meta("is_dead"):
			is_dead = npc.get_meta("is_dead", false)
		
		if is_dead:
			# NPC is dead - don't restore sprite, keep corpse sprite
			print("💀 ANIMATION: NPC is dead, keeping corpse sprite (not restoring default)")
			return
		
		if default_sprite_texture:
			sprite.texture = default_sprite_texture
			if npc.has_method("apply_sprite_offset_for_texture"):
				npc.apply_sprite_offset_for_texture()
			print("✅ ANIMATION: Restored default sprite texture")
		else:
			# Default texture is null - try to restore from weapon component
			var weapon_comp = npc.get_node_or_null("WeaponComponent") if npc else null
			if weapon_comp and weapon_comp.has_method("_update_sprite_with_weapon"):
				weapon_comp._update_sprite_with_weapon()
			else:
				# Fallback: load texture by npc_type and cache as default
				var npc_type: String = npc.get("npc_type") if npc.get("npc_type") != null else ""
				var fallback_path: String = "res://assets/sprites/male1.png"
				match npc_type:
					"woman":
						fallback_path = "res://assets/sprites/woman.png"
					"baby":
						fallback_path = "res://assets/sprites/baby.png"
					"sheep":
						fallback_path = "res://assets/sprites/sheep.png"
					"goat":
						fallback_path = "res://assets/sprites/goat.png"
					"mammoth":
						fallback_path = "res://assets/sprites/mammoth.png"
					_:  # caveman, clansman, default
						fallback_path = "res://assets/sprites/male1.png"
				var fallback_tex := load(fallback_path) as Texture2D
				if fallback_tex:
					default_sprite_texture = fallback_tex
					sprite.texture = fallback_tex
					if npc.has_method("apply_sprite_offset_for_texture"):
						npc.apply_sprite_offset_for_texture()
				elif sprite.texture and sprite.texture is AtlasTexture:
					sprite.texture = null
		return
	
	# Map combat states to frames: 1=windup, 2=windup_mid (via _on_windup_mid), 3=hit (via _update_combat_sprite_hit), 4=recovery
	var frame_index: int = 1
	match combat_state:
		CombatState.WINDUP:
			frame_index = 1
		CombatState.RECOVERY:
			frame_index = 4
		_:
			return
	_set_combat_frame(frame_index)

func _update_combat_sprite_hit() -> void:
	# Show hit/impact frame (frame 3) at exact moment of hit
	if use_sprite_sheet_animation and attack_sprite_sheet and sprite_sheet_frame_width > 0:
		_set_combat_frame(3)
	else:
		_flash_sprite_fallback()

func _flash_sprite_fallback() -> void:
	"""Brief modulate flash when sprite sheet unavailable (swing feedback)."""
	if not npc or not is_instance_valid(npc):
		return
	var sp: Sprite2D = npc.get_node_or_null("Sprite")
	if not sp:
		return
	var orig: Color = sp.modulate
	sp.modulate = Color(1.4, 1.4, 1.4)
	var tween = sp.create_tween()
	tween.tween_property(sp, "modulate", orig, 0.15)

func _on_hit_frame_display_end() -> void:
	# Switch from hit frame to recovery frame
	print("🎨 ANIMATION: _on_hit_frame_display_end() called - state=%s" % CombatState.keys()[state] if state < CombatState.size() else "INVALID")
	
	if not npc or not is_instance_valid(npc):
		print("❌ ANIMATION: npc invalid in hit_frame_display_end")
		return
	
	# CRITICAL: Always switch to recovery frame if in RECOVERY state
	# This prevents getting stuck on HIT frame (frame 3)
	if state == CombatState.RECOVERY:
		print("🎨 ANIMATION: Switching to RECOVERY frame (frame 4)")
		_update_combat_sprite(CombatState.RECOVERY)
	else:
		print("⚠️ ANIMATION: Not in RECOVERY state, skipping frame update (state=%s)" % CombatState.keys()[state] if state < CombatState.size() else "INVALID")
		# If we're somehow not in RECOVERY but this was called, force recovery frame anyway
		# This is a safety net to prevent stuck frames
		if state == CombatState.IDLE:
			print("🔧 ANIMATION: State is IDLE but hit_frame_display_end called - attack may have been cancelled")
		else:
			print("🔧 ANIMATION: Forcing recovery frame update despite state mismatch")
			_set_combat_frame(4)  # Force frame 4 (recovery) to prevent stuck on frame 3
