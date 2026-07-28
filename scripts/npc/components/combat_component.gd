extends Node
class_name CombatComponent

const CombatAllyCheck = preload("res://scripts/systems/combat_ally_check.gd")
const SoundDetection = preload("res://scripts/systems/sound_detection.gd")
const WeaponOverlayCombat = preload("res://scripts/systems/weapon_overlay_combat.gd")

# Combat Component - handles attack logic, damage calculation, combat state
# Now with event-driven windup/recovery system

enum CombatState { IDLE, READY, WINDUP, RECOVERY }

var aim_dir: Vector2 = Vector2(1, 0)
var locked_strike_dir: Vector2 = Vector2(1, 0)

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

# Sprite sheets: swingclub.png = 4 frames (3×2 grid). spearattack.png = 4 frames (2×2, 1060×700 sheet).
var attack_sprite_sheet: Texture2D = null
var sprite_sheet_frame_width: int = 0  # Width of each frame
var sprite_sheet_frame_height: int = 0  # Height of each frame
var sprite_sheet_cols: int = 3
var sprite_sheet_rows: int = 2
var sprite_sheet_frame_count: int = 4  # Combat frames 1–4 (windup, windup_mid, hit, recovery)
var sprite_sheet_hit_col: int = 2  # Combat frame 3 (“hit”) cell column in grid (club uses col 2)
var sprite_sheet_hit_row: int = 0
var use_sprite_sheet_animation: bool = false  # Enable sprite sheet animation
var default_sprite_texture: Texture2D = null  # Store original sprite texture

# Safety timeout tracking
var windup_start_time: int = 0  # Track when windup started (for timeout detection)
var recovery_start_time: int = 0  # Track when recovery started (for timeout detection)

## Hit-frame slack: both combatants move during windup; strict range/arc at impact caused mass whiffs + windup spam.
const STRIKE_RANGE_SLACK_MULT: float = 1.28
const STRIKE_ARC_MIN_HALF_RAD: float = 0.96  # ~55° — floor so narrow club profile still lands in pack fights

func _combat_d(msg: String) -> void:
	UnifiedLogger.log(msg, UnifiedLogger.Category.COMBAT, UnifiedLogger.Level.DEBUG)

func _combat_e(msg: String) -> void:
	UnifiedLogger.log(msg, UnifiedLogger.Category.COMBAT, UnifiedLogger.Level.ERROR)

func initialize(npc_ref: Node2D) -> void:
	npc = npc_ref
	# Update attack profile based on weapon (will be called again when weapon changes)
	_update_attack_profile_from_weapon()
	
	# Try to load attack sprite sheet
	_load_attack_sprite_sheet()
	
	# Set up process callback for timeout detection
	set_process(true)

func _process(_delta: float) -> void:
	# Safety check: If stuck in WINDUP for too long, force hit frame
	if state == CombatState.WINDUP and windup_start_time > 0:
		var now = Time.get_ticks_msec()
		var elapsed = now - windup_start_time
		var max_windup = int((windup_time + 0.5) * 1000)  # Allow 0.5s extra buffer
		
		if elapsed > max_windup:
			push_warning("COMBAT: WINDUP timeout — forcing hit frame (elapsed=%dms, max=%dms, windup=%.2fs)" % [elapsed, max_windup, windup_time])
			windup_start_time = 0  # Reset to prevent spam
			
			# Verify we're still in WINDUP before forcing
			if state == CombatState.WINDUP:
				_combat_d("COMBAT: Forcing hit frame due to timeout")
				_on_hit_frame()  # Force the hit frame
			else:
				push_warning("COMBAT: State changed during windup timeout (now=%s), skipping force" % CombatState.keys()[state] if state < CombatState.size() else "INVALID")
	
	# Safety check: If stuck in RECOVERY for too long, force recovery end
	# CRITICAL: Check even if recovery_start_time is 0 (might have been reset but still in RECOVERY)
	if state == CombatState.RECOVERY:
		var now = Time.get_ticks_msec()
		
		# If recovery_start_time is 0, set it now (recovery event might have been cancelled)
		if recovery_start_time == 0:
			push_warning("COMBAT: RECOVERY but recovery_start_time is 0 — estimating start (event may have been cancelled)")
			recovery_start_time = now - int(recovery_time * 1000)  # Assume recovery started recovery_time ago
		
		var elapsed = now - recovery_start_time
		var max_recovery = int((recovery_time + 1.0) * 1000)  # Allow 1s extra buffer
		
		if elapsed > max_recovery:
			push_warning("COMBAT: RECOVERY timeout — forcing end (elapsed=%dms, max=%dms, recovery=%.2fs)" % [elapsed, max_recovery, recovery_time])
			recovery_start_time = 0  # Reset to prevent spam
			
			# Verify we're still in RECOVERY before forcing
			if state == CombatState.RECOVERY:
				_combat_d("COMBAT: Forcing recovery end due to timeout")
				_on_recovery_end()  # Force recovery end
			else:
				push_warning("COMBAT: State changed during recovery timeout (now=%s), skipping force" % CombatState.keys()[state] if state < CombatState.size() else "INVALID")
		
		# CRITICAL: Check if we've been in RECOVERY for a while but sprite is still on wrong frame
		# This handles cases where recovery_end was cancelled but state wasn't reset
		# Force sprite update to recovery frame if we're stuck on hit frame
		if elapsed > 200 and use_sprite_sheet_animation and attack_sprite_sheet and sprite_sheet_frame_width > 0:
			var sprite: Sprite2D = npc.get_node_or_null("Sprite") if npc else null
			if sprite and sprite.texture and sprite.texture is AtlasTexture:
				var atlas = sprite.texture as AtlasTexture
				var expected_x: int = sprite_sheet_hit_col * sprite_sheet_frame_width
				var expected_y: int = sprite_sheet_hit_row * sprite_sheet_frame_height
				var pos: Vector2 = atlas.region.position
				if abs(pos.x - expected_x) < 5 and abs(pos.y - expected_y) < 5:
					push_warning("COMBAT ANIM: stuck on HIT frame during RECOVERY; forcing frame 4")
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

func _uses_overlay_combat() -> bool:
	if not npc or not is_instance_valid(npc):
		return false
	if not PlaceholderCardService:
		return false
	return PlaceholderCardService.uses_placeholder_cards(npc)


func _normalize_strike_aim(raw: Vector2) -> Vector2:
	if raw.length_squared() < 0.0001:
		return _get_default_facing_dir()
	var wt: ResourceData.ResourceType = _get_equipped_weapon_type()
	if PlaceholderCardService and _uses_overlay_combat():
		var registry = PlaceholderCardService.registry
		if registry and WeaponOverlayCombat.is_thrust_weapon(registry, wt):
			return WeaponOverlayCombat.resolve_thrust_aim(raw, registry, wt, npc)
	return raw.normalized()


func enter_ready(new_aim: Vector2) -> void:
	if state != CombatState.IDLE:
		return
	if _get_equipped_weapon_type() == ResourceData.ResourceType.NONE:
		return
	if new_aim.length_squared() > 0.0001:
		aim_dir = _normalize_strike_aim(new_aim)
	else:
		aim_dir = _get_default_facing_dir()
	state = CombatState.READY
	if PlaceholderCardService and _uses_overlay_combat():
		var wt: ResourceData.ResourceType = _get_equipped_weapon_type()
		if not WeaponOverlayCombat.uses_aim_facing_flip(PlaceholderCardService.registry, wt):
			var body_sprite: Sprite2D = npc.get_node_or_null("Sprite") as Sprite2D
			WeaponOverlayCombat.sync_swing_body_facing(npc, body_sprite)
		_sync_overlay_facing_from_aim()
		PlaceholderCardService.set_overlay_combat_state(npc, WeaponOverlayCombat.OverlayState.READY)
		PlaceholderCardService.sync_weapon_overlay(npc, _get_equipped_weapon_type(), true)
		PlaceholderCardService.update_weapon_overlay_combat(npc, _get_equipped_weapon_type(), aim_dir)
	_combat_d("COMBAT: enter READY aim=%s" % aim_dir)


func update_ready_aim(new_aim: Vector2) -> void:
	if state != CombatState.READY:
		return
	if new_aim.length_squared() > 0.0001:
		aim_dir = _normalize_strike_aim(new_aim)
	if PlaceholderCardService and _uses_overlay_combat():
		var wt: ResourceData.ResourceType = _get_equipped_weapon_type()
		if not WeaponOverlayCombat.uses_aim_facing_flip(PlaceholderCardService.registry, wt):
			var body_sprite: Sprite2D = npc.get_node_or_null("Sprite") as Sprite2D
			WeaponOverlayCombat.sync_swing_body_facing(npc, body_sprite)
		_sync_overlay_facing_from_aim()
		PlaceholderCardService.update_weapon_overlay_combat(npc, _get_equipped_weapon_type(), aim_dir)


func _sync_overlay_facing_from_aim() -> void:
	if not npc or aim_dir.length_squared() < 0.0001:
		return
	if PlaceholderCardService and _uses_overlay_combat():
		var wt: ResourceData.ResourceType = _get_equipped_weapon_type()
		if not WeaponOverlayCombat.uses_aim_facing_flip(PlaceholderCardService.registry, wt):
			return
	var sprite: Sprite2D = npc.get_node_or_null("Sprite") as Sprite2D
	if sprite:
		sprite.flip_h = aim_dir.x < 0.0


func _should_hold_weapon_ready() -> bool:
	if not npc or not is_instance_valid(npc):
		return false
	return WeaponOverlayCombat.should_hold_weapon_ready(npc)


func _resolve_post_recovery_aim() -> Vector2:
	if not npc:
		return aim_dir
	var fallback: Vector2 = locked_strike_dir if locked_strike_dir.length_squared() > 0.0001 else aim_dir
	return WeaponOverlayCombat.resolve_recovery_aim(npc, fallback)


func _apply_overlay_ready_after_recovery(recovery_aim: Vector2) -> void:
	if recovery_aim.length_squared() > 0.0001:
		aim_dir = recovery_aim.normalized()
	var wt: ResourceData.ResourceType = _get_equipped_weapon_type()
	if PlaceholderCardService and _uses_overlay_combat():
		if not WeaponOverlayCombat.uses_aim_facing_flip(PlaceholderCardService.registry, wt):
			var body_sprite: Sprite2D = npc.get_node_or_null("Sprite") as Sprite2D
			WeaponOverlayCombat.sync_swing_body_facing(npc, body_sprite)
	_sync_overlay_facing_from_aim()
	PlaceholderCardService.set_overlay_combat_state(npc, WeaponOverlayCombat.OverlayState.READY)
	if wt != ResourceData.ResourceType.NONE:
		PlaceholderCardService.sync_weapon_overlay(npc, wt, true)
		PlaceholderCardService.update_weapon_overlay_combat(npc, wt, aim_dir)


func cancel_ready() -> void:
	if state != CombatState.READY:
		return
	state = CombatState.IDLE
	if PlaceholderCardService and _uses_overlay_combat():
		PlaceholderCardService.set_overlay_combat_state(npc, WeaponOverlayCombat.OverlayState.IDLE)
		var wt: ResourceData.ResourceType = _get_equipped_weapon_type()
		if wt != ResourceData.ResourceType.NONE:
			PlaceholderCardService.sync_weapon_overlay(npc, wt, true)
	_combat_d("COMBAT: cancel READY")


func commit_strike(strike_aim: Vector2) -> void:
	if state != CombatState.READY:
		_combat_d("COMBAT: commit_strike rejected — not READY (state=%s)" % CombatState.keys()[state])
		return
	if not npc or not is_instance_valid(npc):
		return
	_update_attack_profile_from_weapon()
	if strike_aim.length_squared() > 0.0001:
		strike_aim = _normalize_strike_aim(strike_aim)
	elif aim_dir.length_squared() > 0.0001:
		strike_aim = _normalize_strike_aim(aim_dir)
	else:
		strike_aim = _get_default_facing_dir()
	if npc.is_in_group("player") and npc.has_method("_get_cursor_aim_direction"):
		var fresh: Vector2 = npc._get_cursor_aim_direction()
		if fresh.length_squared() > 0.0001:
			strike_aim = _normalize_strike_aim(fresh)
			npc.set("aim_dir", strike_aim)
	locked_strike_dir = strike_aim
	aim_dir = locked_strike_dir
	current_target = _find_strike_target(locked_strike_dir)
	state = CombatState.WINDUP
	windup_start_time = Time.get_ticks_msec()
	_sync_overlay_facing_from_aim()
	if npc:
		SoundDetection.emit_attack_swing(npc)
	if _uses_overlay_combat() and PlaceholderCardService:
		var wt: ResourceData.ResourceType = _get_equipped_weapon_type()
		PlaceholderCardService.play_weapon_overlay_strike(
			npc,
			wt,
			locked_strike_dir,
			_on_hit_frame,
			_on_overlay_strike_recovery_done
		)
	else:
		_update_combat_sprite(CombatState.WINDUP)
		var now := Time.get_ticks_msec()
		var hit_time := now + int(windup_time * 1000.0)
		var hit_callable := _on_hit_frame.bind()
		if hit_callable.is_valid():
			CombatScheduler.schedule(hit_time, hit_callable, npc.get_instance_id())
		var mid_windup_time := now + int(windup_time * 0.5 * 1000.0)
		var mid_callable := _on_windup_mid.bind()
		if mid_callable.is_valid():
			CombatScheduler.schedule(mid_windup_time, mid_callable, npc.get_instance_id())
	_combat_d("COMBAT: commit_strike dir=%s target=%s" % [locked_strike_dir, current_target])


func _on_overlay_strike_recovery_done() -> void:
	if not npc or not is_instance_valid(npc):
		return
	state = CombatState.RECOVERY
	recovery_start_time = Time.get_ticks_msec()
	windup_start_time = 0
	_on_recovery_end()


func _find_strike_target(strike_aim: Vector2) -> Node2D:
	if not npc or not is_instance_valid(npc):
		return null
	var best: Node2D = null
	var best_score: float = INF
	var origin: Vector2 = npc.global_position
	var range_allow: float = attack_range * STRIKE_RANGE_SLACK_MULT
	if npc.is_in_group("player"):
		range_allow = attack_range * STRIKE_RANGE_SLACK_MULT
	var candidates: Array = []
	candidates.append_array(get_tree().get_nodes_in_group("npcs"))
	candidates.append_array(get_tree().get_nodes_in_group("buildings"))
	for node in candidates:
		if not is_instance_valid(node) or node == npc:
			continue
		if not _is_valid_strike_candidate(node):
			continue
		var to_target: Vector2 = (node as Node2D).global_position - origin
		var dist: float = to_target.length()
		if dist > range_allow or dist < 0.001:
			continue
		var dir := to_target / dist
		var ang: float = abs(dir.angle_to(strike_aim))
		var half_allow: float = maxf(attack_arc * 0.5, STRIKE_ARC_MIN_HALF_RAD)
		if ang > half_allow:
			continue
		var score: float = dist + ang * 40.0
		if score < best_score:
			best_score = score
			best = node as Node2D
	return best


func _is_valid_strike_candidate(node: Node) -> bool:
	if CombatAllyCheck.is_ally(npc, node):
		return false
	if node.is_in_group("buildings"):
		return _is_damageable_enemy_building(node)
	var hc: HealthComponent = node.get_node_or_null("HealthComponent")
	if hc and hc.is_dead:
		return false
	return node is NPCBase or node.is_in_group("player")


func _attacker_clan_name() -> String:
	if not npc or not is_instance_valid(npc):
		return ""
	if npc.has_method("get_clan_name"):
		var cn: String = npc.get_clan_name()
		if cn != "":
			return cn
	if npc.is_in_group("player"):
		var pn = npc.get("player_name")
		if pn != null and str(pn) != "":
			return str(pn)
		if npc.has_meta("player_clan_name"):
			return str(npc.get_meta("player_clan_name", ""))
	return ""


func _is_damageable_enemy_building(node: Node) -> bool:
	if node == null or not is_instance_valid(node):
		return false
	if not node.has_method("take_damage"):
		return false
	if node.get("player_owned") == true and npc != null and npc.is_in_group("player"):
		return false
	var building_clan: String = str(node.get("clan_name")) if node.get("clan_name") != null else ""
	var attacker_clan: String = _attacker_clan_name()
	if building_clan != "" and attacker_clan != "" and building_clan == attacker_clan:
		return false
	return true


func _get_default_facing_dir() -> Vector2:
	var sprite: Sprite2D = npc.get_node_or_null("Sprite") if npc else null
	if sprite:
		return Vector2(-1.0 if sprite.flip_h else 1.0, 0.0)
	return Vector2(1, 0)


# Event-driven attack system
func request_attack(target: Node2D) -> void:
	_combat_d("🔵 COMBAT: request_attack() called - state=%s, npc=%s, target=%s" % [
		CombatState.keys()[state] if state < CombatState.size() else "INVALID",
		"valid" if npc and is_instance_valid(npc) else "null/invalid",
		"valid" if target and is_instance_valid(target) else "null/invalid"
	])
	
	# CRITICAL: Only allow attack requests when IDLE (legacy NPC sheet path)
	if state != CombatState.IDLE:
		_combat_d("⚠️ COMBAT: Rejecting attack - not in IDLE state (state=%s). Current attack must finish first." % CombatState.keys()[state] if state < CombatState.size() else "INVALID")
		return  # Reject - already attacking, wait for current attack to complete
	
	if _uses_overlay_combat():
		current_target = target
		var to_t: Vector2 = target.global_position - npc.global_position
		if to_t.length_squared() > 0.0001:
			aim_dir = to_t.normalized()
		enter_ready(aim_dir)
		commit_strike(aim_dir)
		return
	
	if not npc or not is_instance_valid(target):
		_combat_e("COMBAT: Invalid npc or target")
		return
	
	_update_attack_profile_from_weapon()
	_load_attack_sprite_sheet()
	
	# Check range (player gets slack — click-to-attack from normal hunting distance)
	var distance = npc.global_position.distance_to(target.global_position)
	var range_allow: float = attack_range
	if npc.is_in_group("player"):
		range_allow = attack_range * STRIKE_RANGE_SLACK_MULT
	if distance > range_allow:
		_combat_d("⚠️ COMBAT: Target out of range (distance=%.1f, range=%.1f)" % [distance, range_allow])
		return
	
	_combat_d("✅ COMBAT: Starting attack - distance=%.1f, windup=%.2fs" % [distance, windup_time])
	
	# Start windup
	state = CombatState.WINDUP
	current_target = target
	windup_start_time = Time.get_ticks_msec()  # Track windup start for timeout detection
	if npc:
		SoundDetection.emit_attack_swing(npc)
	
	# Store default texture before switching to combat frame (fallback if _load_attack_sprite_sheet ran when sprite was null)
	if not default_sprite_texture:
		var spr: Sprite2D = npc.get_node_or_null("Sprite") if npc else null
		if spr and spr.texture:
			default_sprite_texture = spr.texture
	
	# Update sprite to windup frame
	_combat_d("🔵 COMBAT: Updating sprite to WINDUP frame")
	_update_combat_sprite(CombatState.WINDUP)
	
	# Set combat lock (prevents FSM from switching states) - only for NPCs
	if npc and npc.has_method("get") and npc.get("combat_locked") != null:
		npc.combat_locked = true
		_combat_d("🔒 COMBAT: Combat lock set")
	
	# Schedule hit event
	var now = Time.get_ticks_msec()
	var hit_time = now + int(windup_time * 1000)
	var windup_ms = int(windup_time * 1000)
	_combat_d("⏰ COMBAT: Scheduling hit event at %d (now=%d, windup=%dms, delay=%dms)" % [hit_time, now, windup_ms, hit_time - now])
	
	# Create bound callable and verify it's valid
	var hit_callable = _on_hit_frame.bind()
	if not hit_callable.is_valid():
		_combat_e("COMBAT: Failed to create valid callable for hit frame!")
		_cancel_attack()
		return
	
	_combat_d("✅ COMBAT: Hit frame callable is valid, scheduling...")
	CombatScheduler.schedule(hit_time, hit_callable, npc.get_instance_id())
	_combat_d("✅ COMBAT: Hit event scheduled successfully")
	
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

func _transition_windup_to_whiff_recovery() -> void:
	if state != CombatState.WINDUP:
		return
	if _uses_overlay_combat():
		return
	state = CombatState.RECOVERY
	recovery_start_time = Time.get_ticks_msec()
	windup_start_time = 0
	_update_combat_sprite(CombatState.RECOVERY)
	var now := Time.get_ticks_msec()
	var whiff_recovery_time := recovery_time * 0.5
	var recovery_end_time := now + int(whiff_recovery_time * 1000.0)
	var recovery_callable := _on_recovery_end.bind()
	if recovery_callable.is_valid():
		CombatScheduler.schedule(recovery_end_time, recovery_callable, npc.get_instance_id())


func _on_windup_mid() -> void:
	# Switch to frame 2 (mid-windup) so windup animates instead of freezing on frame 1
	_combat_d("🎨 ANIMATION: _on_windup_mid() called - state=%s" % CombatState.keys()[state] if state < CombatState.size() else "INVALID")
	if state != CombatState.WINDUP:
		_combat_d("⚠️ ANIMATION: _on_windup_mid skipped - not in WINDUP state (state=%s)" % CombatState.keys()[state] if state < CombatState.size() else "INVALID")
		return  # Cancelled or already hit
	if not npc or not is_instance_valid(npc):
		_combat_d("⚠️ ANIMATION: _on_windup_mid skipped - npc invalid")
		return
	_combat_d("🎨 ANIMATION: Updating to mid-windup frame (frame 2)")
	_set_combat_frame(2)

func _on_hit_frame() -> void:
	_combat_d("_on_hit_frame: state=%s windup_start_ms=%d" % [
		CombatState.keys()[state] if state < CombatState.size() else "INVALID",
		windup_start_time
	])
	
	# CRITICAL: Must exit WINDUP state immediately
	if state != CombatState.WINDUP:
		_combat_d("⚠️ COMBAT: Hit frame called but not in WINDUP state (state=%s), cancelling" % CombatState.keys()[state] if state < CombatState.size() else "INVALID")
		_cancel_attack()
		return
	
	if not is_instance_valid(current_target):
		_combat_e("COMBAT: Hit frame - target invalid")
		if DebugConfig and DebugConfig.enable_session_instrumentation:
			var nn0: String = npc.get("npc_name") if npc and npc.get("npc_name") != null else "?"
			UnifiedLogger.log_session("COMBAT_HIT_ABORT", {
				"npc": nn0,
				"reason": "target_invalid_at_hit_frame"
			}, UnifiedLogger.Level.INFO)
		_transition_windup_to_whiff_recovery()
		return
	
	if not npc or not is_instance_valid(npc):
		_combat_e("COMBAT: Hit frame - npc invalid, cancelling")
		_cancel_attack()
		return
	
	_combat_d("✅ COMBAT: Hit frame validation passed")
	
	_combat_d("🔵 COMBAT: Validating hit - target=%s, npc=%s" % [
		"valid" if is_instance_valid(current_target) else "invalid",
		"valid" if is_instance_valid(npc) else "invalid"
	])
	
	# Validate hit (target still alive, in range)
	_combat_d("🔍 COMBAT: Calling _validate_hit()...")
	var hit_valid = false
	if current_target and is_instance_valid(current_target):
		hit_valid = _validate_hit(current_target)
		_combat_d("🔍 COMBAT: _validate_hit() returned: %s" % hit_valid)
	else:
		_combat_e("COMBAT: Target invalid before _validate_hit()!")
		_cancel_attack()
		return
	
	if not hit_valid:
		var whiff_reason: String = _hit_validation_failure_reason(current_target) if current_target else "no_target"
		if whiff_reason == "":
			whiff_reason = "unknown"
		if current_target and DebugConfig and DebugConfig.enable_session_instrumentation:
			var nnw: String = npc.get("npc_name") if npc and npc.get("npc_name") != null else "?"
			var tnw: String = "?"
			if current_target and is_instance_valid(current_target):
				if current_target is NPCBase:
					tnw = (current_target as NPCBase).npc_name
				elif current_target.is_in_group("player"):
					tnw = "Player"
				else:
					tnw = str(current_target.name)
			UnifiedLogger.log_session("COMBAT_WHIFF", {
				"attacker": nnw,
				"target": tnw,
				"reason": whiff_reason
			}, UnifiedLogger.Level.INFO)
		var pi = npc.get_node_or_null("/root/PlaytestInstrumentor")
		if pi and pi.is_enabled():
			var nn: String = npc.get("npc_name") if npc.get("npc_name") != null else "unknown"
			var tn: String = "unknown"
			if current_target is NPCBase:
				tn = (current_target as NPCBase).npc_name
			elif current_target.is_in_group("player"):
				tn = "Player"
			pi.combat_whiff(nn, tn, whiff_reason)
		_combat_d("COMBAT: Hit validation failed (whiff)")
		_transition_windup_to_whiff_recovery()
		return
	
	_combat_d("✅ COMBAT: Hit validated, applying damage")
	
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
			_combat_d("⚔️ Building %s took %.1f damage" % [current_target.name if current_target else "unknown", building_damage])
		# Transition to recovery (building attacks don't need full recovery)
		if _uses_overlay_combat():
			return
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
			_combat_e("COMBAT: Not in scene tree, cannot get weapon")
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
	_combat_d("💥 COMBAT: Applying damage - base=%d, bonus=%d, total=%d" % [base_damage, weapon_bonus, total_damage])
	
	_combat_d("🔍 COMBAT: Getting HealthComponent from target...")
	if not current_target or not is_instance_valid(current_target):
		_combat_e("COMBAT: Target invalid before getting HealthComponent!")
		_cancel_attack()
		return
	
	var target_health: HealthComponent = current_target.get_node_or_null("HealthComponent")
	_combat_d("🔍 COMBAT: HealthComponent lookup result: %s" % ("found" if target_health else "null"))
	
	if target_health:
		_combat_d("💥 COMBAT: Target health component found, applying damage")
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
			_combat_d("💥 COMBAT: Damage applied successfully")
		else:
			_combat_e("COMBAT: HealthComponent became invalid!")
			_cancel_attack()
			return
	else:
		_combat_e("COMBAT: Target health component not found!")
		_cancel_attack()
		return
	
	# Apply stagger to target (if they have CombatComponent)
	if stagger_time > 0.0 and current_target:
		_combat_d("💥 COMBAT: Applying stagger (%.2fs)" % stagger_time)
		_apply_stagger_to_target(current_target)
	
	# CRITICAL: Exit WINDUP state immediately - transition to RECOVERY
	if _uses_overlay_combat():
		# Overlay tween + _on_overlay_strike_recovery_done schedules recovery end.
		return
	
	state = CombatState.RECOVERY
	recovery_start_time = Time.get_ticks_msec()  # Track recovery start for timeout detection
	windup_start_time = 0  # Reset windup start time
	_combat_d("🔄 COMBAT: State transition: WINDUP → RECOVERY")
	
	# Update sprite to hit/impact frame (frame 3)
	_combat_d("🎨 ANIMATION: Updating sprite to HIT frame")
	_update_combat_sprite_hit()
	var now = Time.get_ticks_msec()
	
	# Show hit frame briefly (0.15s for impact), then switch to recovery frame
	var hit_display_duration = 150  # 0.15s to show hit frame (feels more impactful)
	var hit_display_time = now + hit_display_duration
	_combat_d("⏰ COMBAT: Scheduling hit frame display end at %d (duration=%dms)" % [hit_display_time, hit_display_duration])
	
	var hit_display_callable = _on_hit_frame_display_end.bind()
	if not hit_display_callable.is_valid():
		_combat_e("COMBAT: Invalid callable for hit_display_end!")
		_cancel_attack()
		return
	CombatScheduler.schedule(hit_display_time, hit_display_callable, npc.get_instance_id())
	_combat_d("✅ COMBAT: Hit display end scheduled")
	
	var recovery_end_time = now + int(recovery_time * 1000)
	_combat_d("⏰ COMBAT: Scheduling recovery end at %d (recovery=%.2fs)" % [recovery_end_time, recovery_time])
	
	var recovery_callable = _on_recovery_end.bind()
	if not recovery_callable.is_valid():
		_combat_e("COMBAT: Invalid callable for recovery_end!")
		_cancel_attack()
		return
	CombatScheduler.schedule(recovery_end_time, recovery_callable, npc.get_instance_id())
	_combat_d("✅ COMBAT: Recovery end scheduled")

func _on_recovery_end() -> void:
	_combat_d("🔄 COMBAT: _on_recovery_end() called - state=%s" % CombatState.keys()[state] if state < CombatState.size() else "INVALID")
	
	if state != CombatState.RECOVERY and state != CombatState.WINDUP:
		push_warning("COMBAT: recovery_end not in RECOVERY/WINDUP state (state=%s), forcing cleanup" % CombatState.keys()[state] if state < CombatState.size() else "INVALID")
	
	windup_start_time = 0
	recovery_start_time = 0
	recovery_time = base_recovery_time
	
	if _uses_overlay_combat() and _should_hold_weapon_ready():
		var recovery_aim: Vector2 = _resolve_post_recovery_aim()
		state = CombatState.READY
		_apply_overlay_ready_after_recovery(recovery_aim)
	else:
		state = CombatState.IDLE
		current_target = null
		_combat_d("🎨 ANIMATION: Resetting sprite to IDLE/default")
		if PlaceholderCardService and _uses_overlay_combat():
			PlaceholderCardService.set_overlay_combat_state(npc, WeaponOverlayCombat.OverlayState.IDLE)
			var wt: ResourceData.ResourceType = _get_equipped_weapon_type()
			if wt != ResourceData.ResourceType.NONE:
				PlaceholderCardService.sync_weapon_overlay(npc, wt, true)
		else:
			_update_combat_sprite(CombatState.IDLE)
	
	if npc and npc.has_method("get") and npc.get("combat_locked") != null:
		npc.combat_locked = false
		_combat_d("🔓 COMBAT: Combat lock released")
	
	if npc:
		var now = Time.get_ticks_msec()
		npc.set_meta("last_attack_request_time", now)
		_combat_d("⏱️ COMBAT: Attack cooldown set (prevents immediate re-attack)")
	
	if state == CombatState.READY:
		_combat_d("✅ COMBAT: Recovery complete, back to READY (weapon ready held)")
	else:
		_combat_d("✅ COMBAT: Recovery complete, back to IDLE")

func _cancel_attack() -> void:
	var cancel_entity_id = npc.get_instance_id() if npc else 0
	_combat_d("🚫 COMBAT: _cancel_attack() called - current_state=%s, entity_id=%d" % [CombatState.keys()[state] if state < CombatState.size() else "INVALID", cancel_entity_id])
	
	var was_ready_only: bool = state == CombatState.READY
	# CRITICAL: Always return to IDLE, regardless of current state
	state = CombatState.IDLE
	current_target = null
	windup_start_time = 0  # Reset windup start time
	recovery_start_time = 0  # Reset recovery start time
	if PlaceholderCardService and _uses_overlay_combat():
		PlaceholderCardService.set_overlay_combat_state(npc, WeaponOverlayCombat.OverlayState.IDLE)
		var wt: ResourceData.ResourceType = _get_equipped_weapon_type()
		if wt != ResourceData.ResourceType.NONE:
			PlaceholderCardService.sync_weapon_overlay(npc, wt, true)
	
	if was_ready_only:
		if npc and npc.has_method("get") and npc.get("combat_locked") != null:
			npc.combat_locked = false
		if npc:
			CombatScheduler.cancel_all_for_entity(cancel_entity_id)
		return
	
	# Reset sprite to default/idle
	_combat_d("🎨 ANIMATION: Resetting sprite to IDLE (cancelled)")
	_update_combat_sprite(CombatState.IDLE)
	
	# CRITICAL: If default texture is null, force clear combat frame
	# This prevents getting stuck on a combat frame when cancelling
	if not default_sprite_texture:
		var sprite: Sprite2D = npc.get_node_or_null("Sprite") if npc else null
		if sprite and sprite.texture and sprite.texture is AtlasTexture:
			_combat_d("🔧 ANIMATION: Default texture is null but sprite has AtlasTexture - clearing combat frame")
			# Try to restore from weapon component or use a fallback
			var weapon_comp = npc.get_node_or_null("WeaponComponent") if npc else null
			if weapon_comp and weapon_comp.has_method("_update_sprite_with_weapon"):
				weapon_comp._update_sprite_with_weapon()
			else:
				# No weapon component - just clear the AtlasTexture
				sprite.texture = null
				_combat_d("⚠️ ANIMATION: Cleared sprite texture (no default or weapon texture available)")
	
	# Release combat lock - only for NPCs
	if npc and npc.has_method("get") and npc.get("combat_locked") != null:
		npc.combat_locked = false
		_combat_d("🔓 COMBAT: Combat lock released (cancelled)")
	
	# Cancel scheduled events for this entity
	if npc:
		_combat_d("⏰ COMBAT: Cancelling all events for entity %d" % cancel_entity_id)
		CombatScheduler.cancel_all_for_entity(cancel_entity_id)
	
	_combat_d("✅ COMBAT: Attack cancelled - state reset to IDLE")

func _hit_validation_failure_reason(target: Node) -> String:
	"""Empty string = would hit; else machine-readable reason for SESSION analysis."""
	if not is_instance_valid(target):
		return "invalid_target"
	if not npc:
		return "no_npc"
	if CombatAllyCheck.is_ally(npc, target):
		return "ally"
	if target.is_in_group("buildings"):
		if not target.has_method("take_damage"):
			return "not_damageable"
		if not _is_damageable_enemy_building(target):
			return "ally"
		var bdist: float = npc.global_position.distance_to(target.global_position)
		var bstrike_range: float = attack_range * STRIKE_RANGE_SLACK_MULT
		if bdist > bstrike_range:
			return "out_of_range"
		if not _is_target_in_strike_arc(target):
			return "out_of_arc"
		return ""
	var target_health: HealthComponent = target.get_node_or_null("HealthComponent")
	if not target_health or target_health.is_dead:
		return "dead"
	var distance: float = npc.global_position.distance_to(target.global_position)
	var strike_range: float = attack_range * STRIKE_RANGE_SLACK_MULT
	if distance > strike_range:
		return "out_of_range"
	if not _is_target_in_strike_arc(target):
		return "out_of_arc"
	return ""

func _validate_hit(target: Node) -> bool:
	return _hit_validation_failure_reason(target) == ""

func _get_melee_facing_direction() -> Vector2:
	if locked_strike_dir.length_squared() > 0.0001 and state != CombatState.IDLE:
		return locked_strike_dir.normalized()
	if aim_dir.length_squared() > 0.0001 and (state == CombatState.READY or state == CombatState.WINDUP):
		return aim_dir.normalized()
	# Player click-attack: face the target so thrust/swing arc matches intent (deer above/below, not only L/R flip).
	if npc and npc.is_in_group("player") and current_target and is_instance_valid(current_target):
		var to_target: Vector2 = current_target.global_position - npc.global_position
		if to_target.length_squared() > 4.0:
			return to_target.normalized()
	var facing_direction: Vector2
	if npc and npc.has_method("get") and npc.get("velocity") != null:
		var velocity: Vector2 = npc.get("velocity") as Vector2
		if velocity.length_squared() > 0.1:
			facing_direction = velocity.normalized()
		else:
			var sprite: Sprite2D = npc.get_node_or_null("Sprite")
			if sprite:
				facing_direction = Vector2(-1 if sprite.flip_h else 1, 0)
			else:
				facing_direction = Vector2(1, 0)
	elif npc:
		var sprite_fb: Sprite2D = npc.get_node_or_null("Sprite")
		if sprite_fb:
			facing_direction = Vector2(-1 if sprite_fb.flip_h else 1, 0)
		else:
			facing_direction = Vector2(1, 0)
	else:
		facing_direction = Vector2(1, 0)
	return facing_direction


func _is_target_in_attack_arc(target: Node) -> bool:
	var direction_to_target: Vector2 = (target.global_position - npc.global_position)
	if direction_to_target.length_squared() < 0.0001:
		return false
	direction_to_target = direction_to_target.normalized()
	var facing_direction: Vector2 = _get_melee_facing_direction()
	var angle: float = direction_to_target.angle_to(facing_direction)
	return abs(angle) <= attack_arc / 2.0


## At impact frame: tolerate facing drift / vertical offset vs side-view sprite forward (narrow weapon arc was trivially failing).
func _is_target_in_strike_arc(target: Node) -> bool:
	var direction_to_target: Vector2 = (target.global_position - npc.global_position)
	if direction_to_target.length_squared() < 0.0001:
		return false
	direction_to_target = direction_to_target.normalized()
	var facing_direction: Vector2 = _get_melee_facing_direction()
	var ang: float = abs(direction_to_target.angle_to(facing_direction))
	var half_allow: float = maxf(attack_arc * 0.5, STRIKE_ARC_MIN_HALF_RAD)
	return ang <= half_allow

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
	
	# If target is in windup or ready, cancel their attack (stagger interrupt)
	if target_combat.state == CombatState.WINDUP or target_combat.state == CombatState.READY:
		var attacker_id = npc.get_instance_id() if npc else 0
		var target_id = target.get_instance_id() if target else 0
		_combat_d("💥 COMBAT: Staggering target (attacker_id=%d, target_id=%d, target_combat=%s, self=%s)" % [attacker_id, target_id, target_combat, self])
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
			_combat_d("💥 COMBAT: Extended recovery for %s by %.2fs (new end time: %d)" % [target.get("npc_name") if target else "target", stagger_time, new_recovery_end])
		
		# Store extended recovery time temporarily (will reset on recovery end)
		target_combat.recovery_time = extended_recovery

func _get_attack_profile_for_weapon(weapon_type: ResourceData.ResourceType) -> Dictionary:
	# Returns attack profile: windup, recovery, arc, stagger, attack_range (melee reach in px).
	# Spear = thrust only (longer range than club); throwing is not implemented.
	match weapon_type:
		ResourceData.ResourceType.AXE:
			return {
				"windup": 0.45,
				"recovery": 0.8,
				"arc": PI,
				"stagger": 0.2,
				"attack_range": 100.0
			}
		ResourceData.ResourceType.PICK:
			return {
				"windup": 0.5,
				"recovery": 0.9,
				"arc": PI,
				"stagger": 0.25,
				"attack_range": 100.0
			}
		ResourceData.ResourceType.WOOD:
			return {
				"windup": 0.4,
				"recovery": 0.7,
				"arc": PI / 4.0,  # Narrow club arc (directly in front) per AgroGuide Step 1
				"stagger": 0.15,
				"attack_range": 100.0
			}
		ResourceData.ResourceType.SPEAR:
			return {
				"windup": 0.18,
				"recovery": 0.14,
				"arc": PI / 5.0,  # Thrust cone (forward reach)
				"stagger": 0.16,
				"attack_range": 160.0  # Thrust — clearly longer than club/swing (100)
			}
		_:
			return {
				"windup": 0.4,
				"recovery": 0.7,
				"arc": PI / 2,
				"stagger": 0.15,
				"attack_range": 100.0
			}

func _get_equipped_weapon_type() -> ResourceData.ResourceType:
	if not npc or not is_instance_valid(npc):
		return ResourceData.ResourceType.NONE
	var nt: Variant = npc.get("npc_type")
	if nt != null and str(nt) != "":
		var weapon_comp: WeaponComponent = npc.get_node_or_null("WeaponComponent")
		var wt: ResourceData.ResourceType = ResourceData.ResourceType.NONE
		if weapon_comp:
			wt = weapon_comp.equipped_weapon
		if wt == ResourceData.ResourceType.NONE:
			var hb: Variant = npc.get("hotbar")
			if hb is InventoryData:
				var s0: Dictionary = (hb as InventoryData).get_slot(0)
				if not s0.is_empty():
					wt = s0.get("type", ResourceData.ResourceType.NONE) as ResourceData.ResourceType
		return wt
	# Player — equipped item on player node, then main hotbar
	if npc.is_in_group("player"):
		if npc.has_method("get_equipped_weapon_type"):
			var wt_player: ResourceData.ResourceType = npc.get_equipped_weapon_type()
			if wt_player != ResourceData.ResourceType.NONE:
				return wt_player
		if is_inside_tree():
			var main: Node = get_tree().get_first_node_in_group("main")
			if main:
				var player_inventory_ui: Variant = main.get("player_inventory_ui")
				if player_inventory_ui != null:
					var slots: Variant = player_inventory_ui.get("hotbar_slots")
					var rh_idx: int = int(player_inventory_ui.get("RIGHT_HAND_SLOT_INDEX")) if player_inventory_ui.get("RIGHT_HAND_SLOT_INDEX") != null else 0
					if slots is Array and (slots as Array).size() > rh_idx:
						var first_slot: Variant = (slots as Array)[rh_idx]
						var slot_item: Variant = null
						if first_slot is Dictionary:
							slot_item = (first_slot as Dictionary).get("item_data")
						elif first_slot is Object:
							slot_item = first_slot.get("item_data")
						if slot_item is Dictionary:
							var wt_hotbar: ResourceData.ResourceType = (slot_item as Dictionary).get("type", ResourceData.ResourceType.NONE) as ResourceData.ResourceType
							if wt_hotbar != ResourceData.ResourceType.NONE:
								return wt_hotbar
		return ResourceData.ResourceType.NONE
	return ResourceData.ResourceType.NONE

func refresh_attack_sprite_sheet() -> void:
	_update_attack_profile_from_weapon()
	_load_attack_sprite_sheet()

func _update_attack_profile_from_weapon() -> void:
	if not npc or not is_instance_valid(npc):
		return
	var weapon_type: ResourceData.ResourceType = _get_equipped_weapon_type()
	var profile = _get_attack_profile_for_weapon(weapon_type)
	windup_time = profile.windup
	recovery_time = profile.recovery
	base_recovery_time = profile.recovery  # Store base for reset after stagger
	attack_arc = profile.arc
	stagger_time = profile.stagger
	attack_range = profile.get("attack_range", 100.0)

func _load_attack_sprite_sheet() -> void:
	if not npc:
		return
	if _uses_overlay_combat():
		use_sprite_sheet_animation = false
		attack_sprite_sheet = null
		return
	var nt: String = npc.get("npc_type") as String if npc.get("npc_type") != null else ""
	if nt in ["sheep", "goat"]:
		return

	_combat_d("🎨 ANIMATION: _load_attack_sprite_sheet() called")

	var wt: ResourceData.ResourceType = _get_equipped_weapon_type()
	var sprite_sheet_path: String = "res://assets/sprites/swingclub.png"
	sprite_sheet_cols = 3
	sprite_sheet_rows = 2
	sprite_sheet_frame_count = 4
	sprite_sheet_hit_col = 2
	sprite_sheet_hit_row = 0
	if wt == ResourceData.ResourceType.SPEAR:
		sprite_sheet_path = "res://assets/sprites/spearattack.png"
		sprite_sheet_cols = 2
		sprite_sheet_rows = 2
		sprite_sheet_hit_col = 0
		sprite_sheet_hit_row = 1

	_combat_d("🎨 ANIMATION: Loading attack sheet: %s (weapon=%s)" % [sprite_sheet_path, ResourceData.get_resource_name(wt)])
	attack_sprite_sheet = load(sprite_sheet_path) as Texture2D

	if attack_sprite_sheet:
		_combat_d("✅ ANIMATION: Sprite sheet loaded successfully")
		use_sprite_sheet_animation = true
		var texture_width: int = attack_sprite_sheet.get_width()
		var texture_height: int = attack_sprite_sheet.get_height()
		_combat_d("🎨 ANIMATION: Texture dimensions - width=%d, height=%d" % [texture_width, texture_height])

		if texture_width > 0 and sprite_sheet_cols > 0 and texture_height > 0 and sprite_sheet_rows > 0:
			sprite_sheet_frame_width = texture_width / sprite_sheet_cols
			sprite_sheet_frame_height = texture_height / sprite_sheet_rows
			_combat_d("✅ ANIMATION: Frame size: %dx%d (grid %dx%d)" % [sprite_sheet_frame_width, sprite_sheet_frame_height, sprite_sheet_cols, sprite_sheet_rows])
		else:
			use_sprite_sheet_animation = false
			_combat_e("ANIMATION: Invalid sprite sheet dimensions")
			return

		var sprite: Sprite2D = npc.get_node_or_null("Sprite")
		if sprite:
			if sprite.texture:
				default_sprite_texture = sprite.texture
				_combat_d("✅ ANIMATION: Default sprite texture stored")
			else:
				_combat_d("⚠️ ANIMATION: Sprite has no texture to store as default")
		else:
			_combat_d("⚠️ ANIMATION: Sprite node not found")
	else:
		use_sprite_sheet_animation = false
		_combat_d("⚠️ ANIMATION: Sprite sheet not found: %s (using default sprites)" % sprite_sheet_path)

func _set_combat_frame(frame_index: int) -> void:
	# Apply combat frames 1–4: windup, mid-windup, hit, recovery. Layout depends on sprite_sheet_cols/rows.
	if not npc or not is_instance_valid(npc):
		_combat_d("⚠️ ANIMATION: _set_combat_frame failed - npc invalid (frame=%d)" % frame_index)
		return
	if not use_sprite_sheet_animation or not attack_sprite_sheet or sprite_sheet_frame_width <= 0:
		_combat_d("⚠️ ANIMATION: _set_combat_frame failed - sprite sheet not available (frame=%d)" % frame_index)
		return
	if frame_index < 1 or frame_index > sprite_sheet_frame_count:
		_combat_d("⚠️ ANIMATION: _set_combat_frame failed - invalid frame index %d (max=%d)" % [frame_index, sprite_sheet_frame_count])
		return
	var sprite: Sprite2D = npc.get_node_or_null("Sprite")
	if not sprite or not is_instance_valid(sprite):
		_combat_d("⚠️ ANIMATION: _set_combat_frame failed - sprite node invalid (frame=%d)" % frame_index)
		return
	var col: int
	var row: int
	if sprite_sheet_cols == 2 and sprite_sheet_rows == 2:
		match frame_index:
			1: col = 0; row = 0
			2: col = 1; row = 0
			3: col = 0; row = 1
			4: col = 1; row = 1
			_: col = 0; row = 0
	else:
		match frame_index:
			1: col = 0; row = 0
			2: col = 1; row = 0
			3: col = 2; row = 0
			4: col = 0; row = 1
			_: col = 0; row = 0
	var frame_x: int = col * sprite_sheet_frame_width
	var frame_y = row * sprite_sheet_frame_height
	var atlas_texture = AtlasTexture.new()
	atlas_texture.atlas = attack_sprite_sheet
	atlas_texture.region = Rect2(frame_x, frame_y, sprite_sheet_frame_width, sprite_sheet_frame_height)
	sprite.texture = atlas_texture
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	if _get_equipped_weapon_type() == ResourceData.ResourceType.SPEAR and sprite_sheet_frame_height > 0:
		var sas: float = WalkAnimation.spear_attack_sprite_scale_for_frame_height(sprite_sheet_frame_height)
		sprite.scale = Vector2(sas, sas)
	if npc.has_method("apply_sprite_offset_for_texture"):
		npc.apply_sprite_offset_for_texture()
	_combat_d("✅ ANIMATION: Frame %d applied successfully" % frame_index)

func _update_combat_sprite(combat_state: CombatState) -> void:
	_combat_d("🎨 ANIMATION: _update_combat_sprite() called - state=%s" % CombatState.keys()[combat_state] if combat_state < CombatState.size() else "INVALID")
	
	if not npc or not is_instance_valid(npc):
		_combat_e("ANIMATION: npc invalid")
		return
	
	if not use_sprite_sheet_animation or not attack_sprite_sheet:
		_combat_d("⚠️ ANIMATION: Sprite sheet not available (use_sheet=%s, texture=%s)" % [use_sprite_sheet_animation, "valid" if attack_sprite_sheet else "null"])
		return
	
	if sprite_sheet_frame_width <= 0:
		_combat_e("ANIMATION: Invalid frame width (%d)" % sprite_sheet_frame_width)
		return
	
	var sprite: Sprite2D = npc.get_node_or_null("Sprite")
	if not sprite or not is_instance_valid(sprite):
		_combat_e("ANIMATION: Sprite node invalid")
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
			_combat_d("💀 ANIMATION: NPC is dead, keeping corpse sprite (not restoring default)")
			return
		
		if default_sprite_texture:
			sprite.texture = default_sprite_texture
			if npc.has_method("apply_sprite_offset_for_texture"):
				npc.apply_sprite_offset_for_texture()
			_combat_d("✅ ANIMATION: Restored default sprite texture")
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
	_combat_d("🎨 ANIMATION: _on_hit_frame_display_end() called - state=%s" % CombatState.keys()[state] if state < CombatState.size() else "INVALID")
	
	if not npc or not is_instance_valid(npc):
		_combat_e("ANIMATION: npc invalid in hit_frame_display_end")
		return
	
	# CRITICAL: Always switch to recovery frame if in RECOVERY state
	# This prevents getting stuck on HIT frame (frame 3)
	if state == CombatState.RECOVERY:
		_combat_d("🎨 ANIMATION: Switching to RECOVERY frame (frame 4)")
		_update_combat_sprite(CombatState.RECOVERY)
	else:
		_combat_d("⚠️ ANIMATION: Not in RECOVERY state, skipping frame update (state=%s)" % CombatState.keys()[state] if state < CombatState.size() else "INVALID")
		# If we're somehow not in RECOVERY but this was called, force recovery frame anyway
		# This is a safety net to prevent stuck frames
		if state == CombatState.IDLE:
			_combat_d("🔧 ANIMATION: State is IDLE but hit_frame_display_end called - attack may have been cancelled")
		else:
			_combat_d("🔧 ANIMATION: Forcing recovery frame update despite state mismatch")
			_set_combat_frame(4)  # Force frame 4 (recovery) to prevent stuck on frame 3
