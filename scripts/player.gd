extends CharacterBody2D

const WalkAnimation = preload("res://scripts/systems/walk_animation.gd")
const SoundDetection = preload("res://scripts/systems/sound_detection.gd")
const WeaponOverlayCombat = preload("res://scripts/systems/weapon_overlay_combat.gd")

@export var move_speed := 110.0  # Matches clansman pace (agility 10 * 9.5 = 95; formation_speed_mult brings both in sync)
@export var sprite_texture_path := "res://assets/sprites/PlayerB.png"
## Flat textures only (male1a / pick / travois). Sheet animations (walk/club/spear) use WalkAnimation scale — spear sheet is matched to walk cell size in walk_animation.gd.
@export var sprite_equipment_scale: float = 0.46
@export var bounce_amplitude := 2.0
@export var bounce_speed := 8.0

@onready var sprite: Sprite2D = $"Sprite"
@onready var combat_component: CombatComponent = $"CombatComponent"
var _sprite_base_position := Vector2.ZERO
var _bounce_time := 0.0
var _walk_timer := 0.0
var _equipped_item: ResourceData.ResourceType = ResourceData.ResourceType.NONE as ResourceData.ResourceType
var _can_move := true
var _leader_lines_container: Node2D = null
## Pooled Line2D nodes — updated in place each frame (avoid queue_free + alloc per follower per frame).
var _leader_line_pool: Array[Line2D] = []
var herded_count: int = 0  # Deprecated: use HerdManager.get_herd_size(self); kept for save/tools compatibility
var last_facing: Vector2 = Vector2(0, 1)  # For formation when stationary (followers stay behind)
var aim_dir: Vector2 = Vector2(1, 0)  # Cursor aim while weapon ready

const WEAPON_READY_SPEED_MULT := 0.6

# Player food meter (calories — hunger is derived 0-100% for UI/debuffs)
var calories: float = 2000.0
var calories_max: float = 2000.0
var hunger: float = 100.0
var hunger_max: float = 100.0
var hunger_deplete_rate: float = 12.0  # Legacy; tick drain uses SimulationManager
var _player_sim_connected: bool = false
var hydration: float = 100.0
var hydration_max: float = 100.0
var _starvation_damage_accum: float = 0.0

@onready var health_component: HealthComponent = $"HealthComponent"

# Eat progress display (world-space pie timer, same pattern as NPCs)
var eat_progress_display: Node2D = null

# Player name - defaults to clan name (will be set when clan is created)
var player_name: String = ""
var _player_name_meta_key: String = "player_name"
var card_index: int = 0
var genetics_profile: Dictionary = {}
var _card_foot_y: float = -28.0
var _card_bounce_time: float = 0.0

func _ready() -> void:
	add_to_group("player")
	if BalanceConfig:
		hunger_deplete_rate = BalanceConfig.hunger_deplete_rate_per_min
		calories_max = float(BalanceConfig.base_daily_calories_player)
		calories = calories_max * (BalanceConfig.hunger_start_percent / 100.0)
		hydration_max = 100.0
		hydration = hydration_max * (BalanceConfig.hydration_start_percent / 100.0)
		_sync_hunger_from_calories()
	_connect_player_simulation_tick()
	_setup_health_component()
	if not sprite:
		print("ERROR: Player sprite is null in _ready()!")
		return
	
	_sprite_base_position = sprite.position
	sprite.visible = true
	_setup_texture()
	if EntityRegistry:
		EntityRegistry.register(self)
	
	# Debug: Verify sprite setup
	print("Player._ready() - sprite visible: %s, texture: %s, position: %s" % [
		sprite.visible,
		"valid" if sprite.texture else "null",
		sprite.position
	])
	
	# Load player name from meta if it exists (persistence)
	if has_meta(_player_name_meta_key):
		player_name = get_meta(_player_name_meta_key, "")
	else:
		# No name set yet - will be set when clan is created
		player_name = ""
	if player_name != "" and not has_meta("player_clan_name"):
		set_meta("player_clan_name", player_name)
	
	# Initialize combat component (player-specific: shorter windup for responsiveness)
	if combat_component:
		combat_component.initialize(self)
		# Player gets responsive timings (will be overridden by weapon profile if weapon equipped)
		combat_component.windup_time = 0.1  # Very short windup for player (responsive)
		combat_component.recovery_time = 0.3  # Short recovery
		# Update profile when weapon changes (handled by _update_attack_profile_from_weapon)
	
	# Create leader lines container for drawing lines to followers
	_leader_lines_container = Node2D.new()
	_leader_lines_container.name = "LeaderLines"
	add_child(_leader_lines_container)
	
	# Create eat progress display (world-space pie, same pattern as NPCs)
	eat_progress_display = Node2D.new()
	eat_progress_display.name = "EatProgress"
	eat_progress_display.position = Vector2(0, -88)
	eat_progress_display.visible = false
	eat_progress_display.z_as_relative = false
	if YSortUtils:
		eat_progress_display.z_index = YSortUtils.Z_ABOVE_WORLD
	add_child(eat_progress_display)
	var progress_script := load("res://scripts/collection_progress.gd")
	if progress_script:
		eat_progress_display.set_script(progress_script)

	if progress_script:
		eat_progress_display.set_script(progress_script)


func _connect_player_simulation_tick() -> void:
	if _player_sim_connected:
		return
	var sm := get_node_or_null("/root/SimulationManager")
	if sm and sm.has_signal("simulation_tick") and not sm.simulation_tick.is_connected(_on_player_simulation_tick):
		sm.simulation_tick.connect(_on_player_simulation_tick)
		_player_sim_connected = true


func _on_player_simulation_tick(_delta_game_time: float) -> void:
	if BalanceConfig:
		calories_max = float(BalanceConfig.base_daily_calories_player)
	var ticks_per_day: int = 5
	if SimulationManager:
		ticks_per_day = maxi(1, SimulationManager.ticks_per_sim_day)
	var drain: float = calories_max / float(ticks_per_day)
	calories = maxf(0.0, calories - drain)
	_sync_hunger_from_calories()


func _sync_hunger_from_calories() -> void:
	if BalanceConfig:
		hunger = BalanceConfig.get_hunger_percent_from_calories(calories, calories_max)
	else:
		hunger = clampf((calories / maxf(calories_max, 1.0)) * 100.0, 0.0, 100.0)


func add_calories(amount: float) -> void:
	if amount <= 0.0:
		return
	calories = minf(calories + amount, calories_max)
	_sync_hunger_from_calories()


func get_hunger_percent() -> float:
	return hunger


func get_daily_calorie_need() -> float:
	return calories_max if calories_max > 0.0 else float(BalanceConfig.base_daily_calories_player if BalanceConfig else 2000)


func get_calorie_percent() -> float:
	if calories_max <= 0.0:
		return 0.0
	return clampf(calories / calories_max, 0.0, 1.0)


func get_hydration_percent() -> float:
	if hydration_max <= 0.0:
		return 0.0
	return clampf(hydration / hydration_max, 0.0, 1.0)


func get_health_percent() -> float:
	if health_component and is_instance_valid(health_component):
		var mx: int = maxi(health_component.max_hp, 1)
		return clampf(float(health_component.current_hp) / float(mx), 0.0, 1.0)
	return 1.0


func _setup_health_component() -> void:
	if not health_component:
		return
	if BalanceConfig:
		health_component.max_hp = maxi(1, int(BalanceConfig.player_max_health))
	health_component.initialize(self)


func on_vitals_death(cause: String) -> void:
	_can_move = false
	velocity = Vector2.ZERO
	print("💀 Player died (%s)" % cause)


func _apply_starvation_health_drain(delta: float) -> void:
	if calories > 0.0 or not health_component or health_component.is_dead:
		_starvation_damage_accum = 0.0
		return
	var drain_per_min: float = 2.0
	if BalanceConfig:
		drain_per_min = maxf(0.0, float(BalanceConfig.hunger_health_drain_per_min))
	_starvation_damage_accum += drain_per_min * delta / 60.0
	while _starvation_damage_accum >= 1.0:
		_starvation_damage_accum -= 1.0
		health_component.death_cause = "starvation"
		health_component.take_damage(1)


func get_player_name() -> String:
	# Return player name, or clan name if name not set yet
	if player_name != "":
		return player_name
	
	# Fallback: try to get clan name from player's land claim
	var clan: String = get_clan_name()
	if clan != "":
		return clan
	return ""

# Return clan name for ally checks (CombatAllyCheck). Must be stable when off-claim or before claim registers.
# player_name is set to the chosen clan when the campfire/flag dialog confirms — same string as claim.clan_name.
func get_clan_name() -> String:
	if player_name != "":
		return player_name
	if has_meta("player_clan_name"):
		var meta_cn = get_meta("player_clan_name", "")
		if meta_cn is String and (meta_cn as String) != "":
			return meta_cn as String
	var main: Node = get_tree().get_first_node_in_group("main")
	if main and main.has_method("_get_player_land_claim"):
		var land_claim = main._get_player_land_claim()
		if land_claim:
			var cn = land_claim.get("clan_name") if land_claim else null
			if cn != null and cn is String and (cn as String) != "":
				return cn as String
	# Also check any player-owned claim (player "owns" a clan even when not inside it)
	if main and main.has_method("_get_player_land_claim_any"):
		var any_claim = main._get_player_land_claim_any()
		if any_claim:
			var cn = any_claim.get("clan_name") if any_claim else null
			if cn != null and cn is String and (cn as String) != "":
				return cn as String
	return ""

func set_player_name(name: String) -> void:
	player_name = name
	set_meta(_player_name_meta_key, name)
	# Mirror for combat / ally resolution (same value as land claim clan_name)
	set_meta("player_clan_name", name)

func _physics_process(_delta: float) -> void:
	# Multiplayer: only authority runs input; remote players driven by sync (Phase 4).
	if multiplayer.has_multiplayer_peer() and not is_multiplayer_authority():
		velocity = Vector2.ZERO
		set_meta("formation_velocity", velocity)
		move_and_slide()
		if sprite:
			_update_entity_draw_order()
			_apply_player_equipment_sprite_scale()
		return
	# Calorie drain runs on SimulationManager tick — hunger is derived each frame for debuffs.
	_sync_hunger_from_calories()
	_apply_starvation_health_drain(_delta)
	
	if health_component and health_component.is_dead:
		velocity = Vector2.ZERO
		set_meta("formation_velocity", velocity)
		move_and_slide()
		return
	
	if not _can_move:
		velocity = Vector2.ZERO
		set_meta("formation_velocity", velocity)
		move_and_slide()
		if sprite:
			_apply_player_equipment_sprite_scale()
		return
	# Gathering: player may move; gatherable_resource / main cancel the timer and flash red
	# get_vector: consistent combined-axis handling (keyboard + gamepad) vs manual action_strength diffs.
	var input_vector := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	if input_vector.length_squared() > 1.0:
		input_vector = input_vector.normalized()
	if input_vector != Vector2.ZERO:
		last_facing = input_vector.normalized()

	# Speed debuff when very hungry
	var speed_mult: float = 0.7 if get_calorie_percent() < 0.3 else 1.0
	# Herding debuff when leading herd animals (women/sheep/goats). Ordered clansmen-only warbands do not slow the player.
	var herd_animal_n: int = HerdManager.get_herd_animal_count(self) if HerdManager else 0
	if herd_animal_n > 0 and not (DebugConfig and DebugConfig.disable_herd_leader_speed_debuff):
		var herd_mult: float = NPCConfig.herd_leader_speed_multiplier if NPCConfig and "herd_leader_speed_multiplier" in NPCConfig else 0.97
		speed_mult *= herd_mult
	# Formation debuff: match clansmen speed in GUARD (0.75x) or ATTACK (0.85x) so the group moves as a unit
	var formation_mult: float = get_meta("formation_speed_mult", 1.0)
	speed_mult *= formation_mult
	var in_weapon_ready: bool = combat_component != null and combat_component.state == CombatComponent.CombatState.READY
	var shift_ready: bool = false
	if InputMap.has_action("weapon_ready"):
		shift_ready = Input.is_action_pressed("weapon_ready")
	if shift_ready and combat_component != null:
		aim_dir = _get_cursor_aim_direction()
		if sprite and PlaceholderCardService and PlaceholderCardService.uses_placeholder_cards(self):
			if _weapon_overlay_uses_aim_facing_flip():
				last_facing = aim_dir
				sprite.flip_h = aim_dir.x < 0.0
			elif combat_component.state == CombatComponent.CombatState.READY or shift_ready:
				WeaponOverlayCombat.sync_swing_body_facing(self, sprite)
	if in_weapon_ready:
		speed_mult *= WEAPON_READY_SPEED_MULT
	velocity = input_vector * (move_speed * speed_mult)
	# Broadcast actual pixel velocity so ordered followers can match movement (RTS formation)
	set_meta("formation_velocity", velocity)
	
	# Prevent player from entering NPC caveman land claims (modify velocity before move_and_slide)
	_prevent_entering_npc_land_claims(_delta)
	
	move_and_slide()
	SoundDetection.maybe_emit_footstep(self)
	
	# Manual z_index by sprite foot (draw_order.md)
	if sprite:
		_update_entity_draw_order()
	
	# Player herding: animals attach via HerdInfluenceArea (animal-authoritative)
	# Draw lines to all followers
	_draw_leader_lines()

	if input_vector != Vector2.ZERO:
		if PlaceholderCardService and PlaceholderCardService.uses_placeholder_cards(self):
			if in_weapon_ready and _weapon_overlay_uses_aim_facing_flip():
				sprite.flip_h = aim_dir.x < 0.0
			else:
				sprite.flip_h = velocity.x < 0.0
				if in_weapon_ready or shift_ready:
					WeaponOverlayCombat.sync_swing_body_facing(self, sprite)
			PlaceholderCardService.tick_card_bounce(self, _delta, true)
		else:
			_update_bounce(true, _delta)
			var in_combat := combat_component and combat_component.state != CombatComponent.CombatState.IDLE
			if not in_combat:
				var show_club := _equipped_item == ResourceData.ResourceType.WOOD
				var show_spear := _equipped_item == ResourceData.ResourceType.SPEAR
				var dir_sheet: DirectionalSpriteSheet = null
				if show_club:
					dir_sheet = WalkAnimation.get_directional_club_sheet()
				elif show_spear:
					dir_sheet = WalkAnimation.get_directional_spear_sheet()
				else:
					dir_sheet = WalkAnimation.get_directional_walk_sheet()
				var used_directional := false
				if dir_sheet:
					_walk_timer += _delta
					var walk_index := int(_walk_timer * WalkAnimation.WALK_FPS) % dir_sheet.columns
					if WalkAnimation.apply_directional_walk_frame(sprite, dir_sheet, velocity, walk_index):
						used_directional = true
						sprite.flip_h = false
						_sprite_base_position = Vector2.ZERO
				if not used_directional:
					sprite.flip_h = velocity.x < 0
					if show_club:
						var club_sheet := WalkAnimation.get_club_walk_sheet()
						if club_sheet:
							_walk_timer += _delta
							var walk_index := int(_walk_timer * WalkAnimation.CLUB_WALK_FPS) % WalkAnimation.CLUB_WALK_FRAMES
							WalkAnimation.apply_club_walk_frame_by_index(sprite, walk_index)
							_sprite_base_position = Vector2.ZERO
					elif show_spear:
						var spear_sheet := WalkAnimation.get_spear_walk_sheet()
						if spear_sheet:
							_walk_timer += _delta
							var sp_index := int(_walk_timer * WalkAnimation.SPEAR_WALK_FPS) % WalkAnimation.SPEAR_WALK_FRAMES
							WalkAnimation.apply_spear_walk_frame_by_index(sprite, sp_index)
							_sprite_base_position = Vector2.ZERO
					else:
						var sheet := WalkAnimation.get_walk_sheet()
						if sheet:
							_walk_timer += _delta
							var frame_index := int(_walk_timer * WalkAnimation.WALK_FPS) % WalkAnimation.WALK_CYCLE_FRAMES
							WalkAnimation.apply_walk_frame_by_index(sprite, sheet, frame_index)
							_sprite_base_position = Vector2.ZERO
	else:
		if PlaceholderCardService and PlaceholderCardService.uses_placeholder_cards(self):
			if in_weapon_ready:
				aim_dir = _get_cursor_aim_direction()
				if _weapon_overlay_uses_aim_facing_flip():
					last_facing = aim_dir
					sprite.flip_h = aim_dir.x < 0.0
				else:
					WeaponOverlayCombat.sync_swing_body_facing(self, sprite)
			PlaceholderCardService.tick_card_bounce(self, _delta, false)
		else:
			_update_bounce(false, _delta)
			_walk_timer = 0.0
			var in_combat := combat_component and combat_component.state != CombatComponent.CombatState.IDLE
			if not in_combat:
				var show_club := _equipped_item == ResourceData.ResourceType.WOOD
				var show_spear := _equipped_item == ResourceData.ResourceType.SPEAR
				var dir_sheet: DirectionalSpriteSheet = null
				if show_club:
					dir_sheet = WalkAnimation.get_directional_club_sheet()
				elif show_spear:
					dir_sheet = WalkAnimation.get_directional_spear_sheet()
				else:
					dir_sheet = WalkAnimation.get_directional_idle_sheet()
				if dir_sheet and WalkAnimation.apply_directional_idle(sprite, dir_sheet, last_facing):
					sprite.position = Vector2.ZERO
					_sprite_base_position = sprite.position
					sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
					sprite.visible = true
				else:
					_update_sprite_texture()

	if sprite:
		if not (PlaceholderCardService and PlaceholderCardService.uses_placeholder_cards(self)):
			_apply_player_equipment_sprite_scale()
			sprite.position.x = _sprite_base_position.x
			var bounce_offset := sin(_bounce_time) * bounce_amplitude if input_vector != Vector2.ZERO else 0.0
			sprite.position.y = roundf(_sprite_base_position.y + bounce_offset)
		else:
			_sync_card_weapon_overlay()
			# Weapon overlay: legacy card offset path (layered body in game; full cards for women/babies).
			if not PlaceholderCardService.uses_procedural_mannequin(self):
				PlaceholderCardService.sync_weapon_overlay_flip(self)

func _apply_player_equipment_sprite_scale() -> void:
	if not sprite:
		return
	if PlaceholderCardService and PlaceholderCardService.uses_placeholder_cards(self):
		return
	match _equipped_item:
		ResourceData.ResourceType.AXE, ResourceData.ResourceType.PICK, ResourceData.ResourceType.TRAVOIS:
			var seq: float = maxf(sprite_equipment_scale, 0.05)
			sprite.scale = Vector2(seq, seq)
		_:
			pass  # WalkAnimation / DirectionalSpriteSheet own scale for walk/club/spear/NONE.


func _setup_texture() -> void:
	if PlaceholderCardService:
		PlaceholderCardService.apply_to_player(self)
		_card_foot_y = float(_card_foot_y) if _card_foot_y != 0.0 else _sprite_base_position.y
		_sprite_base_position = sprite.position
		sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		_sync_card_weapon_overlay()
		return
	_update_sprite_texture()
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST


var _card_overlay_sync_weapon: ResourceData.ResourceType = ResourceData.ResourceType.NONE
var _card_overlay_sync_visible: bool = false


func _update_entity_draw_order() -> void:
	if not sprite or not YSortUtils:
		return
	if PlaceholderCardService and PlaceholderCardService.uses_placeholder_cards(self):
		YSortUtils.update_card_draw_order(sprite, self, _card_foot_y)
	else:
		YSortUtils.update_draw_order(sprite, self)


func _sync_card_weapon_overlay() -> void:
	if not PlaceholderCardService or not PlaceholderCardService.uses_placeholder_cards(self):
		return
	var weapon_type: ResourceData.ResourceType = ResourceData.ResourceType.NONE
	if ResourceData.is_equipment(_equipped_item) and _equipped_item != ResourceData.ResourceType.TRAVOIS:
		weapon_type = _equipped_item
	var should_show: bool = weapon_type != ResourceData.ResourceType.NONE
	if weapon_type != _card_overlay_sync_weapon or should_show != _card_overlay_sync_visible:
		PlaceholderCardService.sync_weapon_overlay(self, weapon_type, should_show)
		_card_overlay_sync_weapon = weapon_type
		_card_overlay_sync_visible = should_show
	if not should_show:
		return
	var ostate: int = WeaponOverlayCombat.get_overlay_state(self)
	if ostate == WeaponOverlayCombat.OverlayState.STRIKING:
		return
	var hold_ready: bool = false
	if InputMap.has_action("weapon_ready"):
		hold_ready = Input.is_action_pressed("weapon_ready")
	if hold_ready and ostate == WeaponOverlayCombat.OverlayState.READY:
		aim_dir = _get_cursor_aim_direction()
		PlaceholderCardService.update_weapon_overlay_combat(self, weapon_type, aim_dir)
		if combat_component and combat_component.state == CombatComponent.CombatState.READY:
			combat_component.update_ready_aim(aim_dir)
	elif combat_component and combat_component.state == CombatComponent.CombatState.READY:
		combat_component.update_ready_aim(aim_dir)
		PlaceholderCardService.update_weapon_overlay_combat(self, weapon_type, aim_dir)


func _get_cursor_aim_direction() -> Vector2:
	var main: Node = get_tree().get_first_node_in_group("main")
	var raw: Vector2 = Vector2.ZERO
	if main and main.has_method("_get_world_mouse_position"):
		var cursor: Vector2 = main._get_world_mouse_position()
		var delta: Vector2 = cursor - global_position
		if delta.length_squared() > 4.0:
			raw = delta.normalized()
	if raw.length_squared() < 0.0001:
		if last_facing.length_squared() > 0.0001:
			raw = last_facing.normalized()
		else:
			raw = Vector2(1, 0)
	if (
		_equipped_item == ResourceData.ResourceType.SPEAR
		and PlaceholderCardService
		and PlaceholderCardService.registry
	):
		return WeaponOverlayCombat.resolve_thrust_aim(
			raw, PlaceholderCardService.registry, ResourceData.ResourceType.SPEAR, self
		)
	return raw


func is_weapon_ready() -> bool:
	return combat_component != null and combat_component.state == CombatComponent.CombatState.READY

func _update_sprite_texture() -> void:
	if PlaceholderCardService and PlaceholderCardService.uses_placeholder_cards(self):
		PlaceholderCardService.apply_to_player(self)
		return
	if not sprite:
		print("ERROR: Sprite is null in _update_sprite_texture")
		return
	
	if not is_instance_valid(sprite):
		print("ERROR: Sprite is not valid in _update_sprite_texture")
		return
	
	if _equipped_item == ResourceData.ResourceType.NONE:
		# Default idle: frame 0 of walk.png (scale 0.46 set by apply_walk_idle to match walk)
		WalkAnimation.apply_walk_idle(sprite)
		sprite.position = Vector2.ZERO
		_sprite_base_position = sprite.position
		sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		sprite.visible = true
		return
	if _equipped_item == ResourceData.ResourceType.WOOD:
		# Club: idle = frame 0 of clubwalk.png (scale 0.46 set by apply_club_idle to match walk)
		WalkAnimation.apply_club_idle(sprite)
		sprite.position = Vector2.ZERO
		_sprite_base_position = sprite.position
		sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		sprite.visible = true
		return
	if _equipped_item == ResourceData.ResourceType.SPEAR:
		if WalkAnimation.get_spear_walk_sheet():
			WalkAnimation.apply_spear_idle(sprite)
		else:
			WalkAnimation.apply_walk_idle(sprite)
		sprite.position = Vector2.ZERO
		_sprite_base_position = sprite.position
		sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		sprite.visible = true
		return
	var texture_path: String
	if _equipped_item == ResourceData.ResourceType.AXE:
		texture_path = "res://assets/sprites/male1a.png"
	elif _equipped_item == ResourceData.ResourceType.PICK:
		texture_path = "res://assets/sprites/male1p.png"
	elif _equipped_item == ResourceData.ResourceType.TRAVOIS:
		texture_path = "res://assets/sprites/trav.png"
	else:
		return
	var texture := load(texture_path) as Texture2D
	if texture:
		sprite.texture = texture
		var seq: float = maxf(sprite_equipment_scale, 0.05)
		sprite.scale = Vector2(seq, seq)
		sprite.position = Vector2.ZERO
		_sprite_base_position = sprite.position
		sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		sprite.visible = true
		if sprite.has_method("set_region_enabled"):
			sprite.set_region_enabled(false)
		call_deferred("_ensure_sprite_scale")
	else:
		print("ERROR: Failed to load texture from: %s" % texture_path)
		WalkAnimation.apply_walk_idle(sprite)
		sprite.position = Vector2.ZERO
		_sprite_base_position = sprite.position
		sprite.visible = true
		print("Player: Using walk idle fallback")

func set_equipment(item_type: ResourceData.ResourceType) -> void:
	var effective: ResourceData.ResourceType = item_type if ResourceData.is_equipment(item_type) else ResourceData.ResourceType.NONE
	if effective == _equipped_item:
		return
	_equipped_item = effective
	_card_overlay_sync_weapon = ResourceData.ResourceType.NONE
	_card_overlay_sync_visible = not ResourceData.is_equipment(effective)
	_update_sprite_texture()
	_sync_card_weapon_overlay()
	if combat_component:
		combat_component.refresh_attack_sprite_sheet()


func get_equipped_weapon_type() -> ResourceData.ResourceType:
	if ResourceData.is_equipment(_equipped_item) and _equipped_item != ResourceData.ResourceType.TRAVOIS:
		return _equipped_item
	return ResourceData.ResourceType.NONE


func _weapon_overlay_uses_aim_facing_flip() -> bool:
	if not PlaceholderCardService or not PlaceholderCardService.uses_placeholder_cards(self):
		return false
	return WeaponOverlayCombat.uses_aim_facing_flip(PlaceholderCardService.registry, get_equipped_weapon_type())

func _ensure_sprite_scale() -> void:
	if sprite:
		var seq: float = maxf(sprite_equipment_scale, 0.05)
		sprite.scale = Vector2(seq, seq)
		sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST

func set_can_move(can_move: bool) -> void:
	_can_move = can_move
	if not can_move:
		velocity = Vector2.ZERO

func _update_bounce(is_moving: bool, delta: float) -> void:
	if is_moving:
		_bounce_time += delta * bounce_speed
	else:
		_bounce_time = 0.0

func _prevent_entering_npc_land_claims(delta: float) -> void:
	# Player CAN enter enemy land claims (raiding mechanics)
	# This function now only triggers agro for defending clansmen
	# Check all land claims
	var land_claims := get_tree().get_nodes_in_group("land_claims")
	
	for claim in land_claims:
		if not is_instance_valid(claim):
			continue
		
		var claim_clan_prop = claim.get("clan_name")
		var claim_clan: String = claim_clan_prop as String if claim_clan_prop != null else ""
		var radius_prop = claim.get("radius")
		var claim_radius: float = radius_prop as float if radius_prop != null else 400.0
		var claim_pos: Vector2 = claim.global_position
		
		# Skip if this is the player's own land claim
		var is_player_owned: bool = claim.get("player_owned") if claim else false
		if is_player_owned:
			continue  # Player's own land claim - no agro needed
		
		# Check if player is inside enemy land claim
		var distance: float = global_position.distance_to(claim_pos)
		
		if distance < claim_radius:
			# Player is inside enemy land claim - trigger agro for defending clansmen
			# This is handled in npc_base.gd _check_land_claim_intrusion()
			# No movement restriction - player can freely enter and raid
			pass

func _get_herd_followers_for_lines() -> Array[Node2D]:
	var followers: Array[Node2D] = []
	if HerdManager:
		followers.assign(HerdManager.get_herd(self))
	else:
		var all_npcs := get_tree().get_nodes_in_group("npcs")
		for npc_check in all_npcs:
			if not is_instance_valid(npc_check):
				continue
			var is_herded_prop = npc_check.get("is_herded")
			var npc_is_herded: bool = is_herded_prop as bool if is_herded_prop != null else false
			var herder_prop = npc_check.get("herder")
			var npc_herder = herder_prop if herder_prop != null else null
			if npc_is_herded and npc_herder == self:
				followers.append(npc_check)
	return followers


func _follower_is_party_rts_line(follower: Node) -> bool:
	if not follower or not is_instance_valid(follower):
		return false
	var t: String = str(follower.get("npc_type")) if follower.get("npc_type") != null else ""
	if t != "caveman" and t != "clansman":
		return false
	return follower.get("follow_is_ordered") == true


func _leader_line_color_for_follower(follower: Node) -> Color:
	if _follower_is_party_rts_line(follower):
		return YSortUtils.WORLD_OVERLAY_LINE_PARTY_COLOR
	return YSortUtils.WORLD_OVERLAY_LINE_HERD_COLOR


func _ensure_leader_line(i: int) -> Line2D:
	while _leader_line_pool.size() <= i:
		var line := Line2D.new()
		line.width = YSortUtils.WORLD_OVERLAY_LINE_WIDTH_PX
		line.default_color = YSortUtils.WORLD_OVERLAY_LINE_HERD_COLOR
		line.z_as_relative = false
		line.z_index = YSortUtils.Z_BEHIND_ENTITIES
		_leader_lines_container.add_child(line)
		_leader_line_pool.append(line)
	return _leader_line_pool[i]


func _draw_leader_lines() -> void:
	if not _leader_lines_container:
		return
	var followers: Array[Node2D] = _get_herd_followers_for_lines()
	var n: int = followers.size()
	if n == 0:
		for line in _leader_line_pool:
			line.visible = false
		return
	for i in range(n):
		var follower: Node2D = followers[i]
		var line: Line2D = _ensure_leader_line(i)
		if not is_instance_valid(follower):
			line.visible = false
			continue
		line.visible = true
		line.default_color = _leader_line_color_for_follower(follower)
		line.points = PackedVector2Array([Vector2.ZERO, to_local(follower.global_position)])
	for i in range(n, _leader_line_pool.size()):
		_leader_line_pool[i].visible = false

# Player herding removed - animals attach via HerdInfluenceArea when player enters radius
