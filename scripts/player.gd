extends CharacterBody2D

const WalkAnimation = preload("res://scripts/systems/walk_animation.gd")

@export var move_speed := 200.0  # Smoother map movement (was 280)
@export var sprite_texture_path := "res://assets/sprites/PlayerB.png"
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
var herded_count: int = 0  # Phase 3: Number of NPCs currently following this player (event-based counter)
var last_facing: Vector2 = Vector2(0, 1)  # For formation when stationary (followers stay behind)

# Player hunger (does NOT die from starvation - only penalties)
var hunger: float = 100.0
var hunger_max: float = 100.0
var hunger_deplete_rate: float = 15.0  # Per minute (BalanceConfig or default)

# Eat progress display (world-space pie timer, same pattern as NPCs)
var eat_progress_display: Node2D = null

# Player name - defaults to clan name (will be set when clan is created)
var player_name: String = ""
var _player_name_meta_key: String = "player_name"

func _ready() -> void:
	if not sprite:
		print("ERROR: Player sprite is null in _ready()!")
		return
	
	_sprite_base_position = sprite.position
	sprite.visible = true
	_setup_texture()
	add_to_group("player")
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
	eat_progress_display.position = Vector2(0, -50)
	eat_progress_display.visible = false
	eat_progress_display.z_as_relative = false
	if YSortUtils:
		eat_progress_display.z_index = YSortUtils.Z_ABOVE_WORLD
	add_child(eat_progress_display)
	var progress_script := load("res://scripts/collection_progress.gd")
	if progress_script:
		eat_progress_display.set_script(progress_script)

func get_player_name() -> String:
	# Return player name, or clan name if name not set yet
	if player_name != "":
		return player_name
	
	# Fallback: try to get clan name from player's land claim
	var clan: String = get_clan_name()
	if clan != "":
		return clan
	return ""

# Return clan name of the player's land claim (for same-clan checks so defenders don't attack player)
func get_clan_name() -> String:
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

func _physics_process(_delta: float) -> void:
	# Hunger depletion (player does NOT die from starvation)
	var rate: float = hunger_deplete_rate
	if BalanceConfig:
		rate = BalanceConfig.hunger_deplete_rate_per_min
	hunger = max(0.0, hunger - (rate * _delta / 60.0))
	
	if not _can_move:
		velocity = Vector2.ZERO
		move_and_slide()
		return
	# Gathering: must stay in place; moving cancels (set by gatherable_resource)
	if get("is_gathering") == true:
		velocity = Vector2.ZERO
		move_and_slide()
		return
	
	var input_vector := Vector2(
		_get_axis_strength("move_right", "move_left"),
		_get_axis_strength("move_down", "move_up")
	)

	if input_vector.length_squared() > 1.0:
		input_vector = input_vector.normalized()
	if input_vector != Vector2.ZERO:
		last_facing = input_vector.normalized()

	# Speed debuff when very hungry (player does not die)
	var speed_mult: float = 0.7 if hunger < 30.0 else 1.0
	# Herding debuff: same as caveman (does not stack with follower count)
	if herded_count > 0:
		var herd_mult: float = NPCConfig.herd_leader_speed_multiplier if NPCConfig and "herd_leader_speed_multiplier" in NPCConfig else 0.97
		speed_mult *= herd_mult
	velocity = input_vector * (move_speed * speed_mult)
	
	# Prevent player from entering NPC caveman land claims (modify velocity before move_and_slide)
	_prevent_entering_npc_land_claims(_delta)
	
	move_and_slide()
	
	# Manual z_index by sprite foot (draw_order.md)
	if sprite:
		YSortUtils.update_draw_order(sprite, self)
	
	# Player herding: animals attach via HerdInfluenceArea (animal-authoritative)
	# Draw lines to all followers
	_draw_leader_lines()

	if input_vector != Vector2.ZERO:
		_update_bounce(true, _delta)
		var in_combat := combat_component and combat_component.state != CombatComponent.CombatState.IDLE
		if not in_combat:
			var show_club := _equipped_item == ResourceData.ResourceType.WOOD
			var dir_sheet: DirectionalSpriteSheet = WalkAnimation.get_directional_club_sheet() if show_club else WalkAnimation.get_directional_walk_sheet()
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
				else:
					var sheet := WalkAnimation.get_walk_sheet()
					if sheet:
						_walk_timer += _delta
						var frame_index := int(_walk_timer * WalkAnimation.WALK_FPS) % WalkAnimation.WALK_CYCLE_FRAMES
						WalkAnimation.apply_walk_frame_by_index(sprite, sheet, frame_index)
						_sprite_base_position = Vector2.ZERO
	else:
		_update_bounce(false, _delta)
		_walk_timer = 0.0
		var in_combat := combat_component and combat_component.state != CombatComponent.CombatState.IDLE
		if not in_combat:
			var show_club := _equipped_item == ResourceData.ResourceType.WOOD
			var dir_sheet: DirectionalSpriteSheet = WalkAnimation.get_directional_club_sheet() if show_club else WalkAnimation.get_directional_idle_sheet()
			if dir_sheet and WalkAnimation.apply_directional_idle(sprite, dir_sheet, last_facing):
				sprite.position = Vector2.ZERO
				_sprite_base_position = sprite.position
				sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
				sprite.visible = true
			else:
				_update_sprite_texture()

	# Snap sprite position to prevent sub-pixel blurring
	sprite.position.x = _sprite_base_position.x
	var bounce_offset := sin(_bounce_time) * bounce_amplitude if input_vector != Vector2.ZERO else 0.0
	sprite.position.y = roundf(_sprite_base_position.y + bounce_offset)

func _get_axis_strength(positive: StringName, negative: StringName) -> float:
	return Input.get_action_strength(positive) - Input.get_action_strength(negative)

func _setup_texture() -> void:
	_update_sprite_texture()
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST

func _update_sprite_texture() -> void:
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
		sprite.scale = Vector2.ONE
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
	_update_sprite_texture()

func _ensure_sprite_scale() -> void:
	if sprite:
		sprite.scale = Vector2.ONE
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

func _draw_leader_lines() -> void:
	# Draw lines from player to all NPCs following the player
	if not _leader_lines_container:
		return
	
	# Clear existing lines
	for child in _leader_lines_container.get_children():
		child.queue_free()
	
	# Find all NPCs following the player
	var all_npcs := get_tree().get_nodes_in_group("npcs")
	var followers: Array[Node2D] = []
	
	for npc_check in all_npcs:
		if not is_instance_valid(npc_check):
			continue
		
		var is_herded_prop = npc_check.get("is_herded")
		var npc_is_herded: bool = is_herded_prop as bool if is_herded_prop != null else false
		var herder_prop = npc_check.get("herder")
		var npc_herder = herder_prop if herder_prop != null else null
		
		if npc_is_herded and npc_herder == self:
			followers.append(npc_check)
	
	# Draw a line to each follower
	for follower in followers:
		if not is_instance_valid(follower):
			continue
		
		var line = Line2D.new()
		line.width = 2.0
		line.default_color = Color(1.0, 1.0, 1.0, 0.35)  # White, more transparent, behind entities
		line.z_as_relative = false
		line.z_index = YSortUtils.Z_BEHIND_ENTITIES
		
		# Line goes from player (origin in local space) to follower position (in local coordinates)
		var player_pos: Vector2 = Vector2.ZERO
		var follower_pos: Vector2 = to_local(follower.global_position)
		line.points = PackedVector2Array([player_pos, follower_pos])
		
		_leader_lines_container.add_child(line)

# Player herding removed - animals attach via HerdInfluenceArea when player enters radius
