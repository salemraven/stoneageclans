extends Node2D
class_name LandClaim

signal claim_destroyed(clan_name: String)

@export var clan_name: String = "CLAN"
@export var radius: float = 400.0
@export var player_owned: bool = false  # True if this land claim belongs to the player
var owner_npc: Node2D = null  # Reference to the NPC (caveman or player) who owns this land claim
var owner_npc_name: String = ""  # Store NPC name as backup (persists even if reference is lost)

var sprite: Sprite2D = null
var radius_indicator: Node2D = null
var _radius_circle: Line2D = null
var _collision_area: Area2D = null
var inventory: InventoryData = null
var _clan_name_label: Label = null

# Clan death decay system (inherits from BuildingBase health system)
var is_decaying: bool = false
var decay_health: float = 100.0  # Building health (0 = destroyed) - legacy, use current_health from BuildingBase
var decay_rate: float = 0.5  # Health lost per second (land claim decays slowest)
const DECAY_MAX_HEALTH: float = 100.0
var is_raidable: bool = false  # Whether building inventory can be raided (clan died)

# OPTIMIZATION: Throttle health bar updates during decay
var _health_bar_update_frame: int = 0
const HEALTH_BAR_UPDATE_INTERVAL: int = 5  # Update every 5 frames (~12 times per second at 60fps)

# Step 11: Role pools (player overrides). Default 20% defend, 20% search when unassigned.
var assigned_defenders: Array = []  # Node refs; prune invalid when used
var assigned_searchers: Array = []
var defend_ratio: float = 0.2
var search_ratio: float = 0.2

# Legacy export; defender quota is auto 3:1 (1 slot per 4 fighters) + drag out/in (see ClanBrain).
@export var player_defend_ratio: float = 0.0
var _player_quota_timer: float = 0.0
const PLAYER_QUOTA_UPDATE_INTERVAL: float = 1.5  # Throttle NPC scans

# Phase 3 Part C: ClanBrain reference (AI controller for NPC clans)
# Note: Type is RefCounted (ClanBrain extends RefCounted) - loaded dynamically
var clan_brain: RefCounted = null

# Item reservations for production jobs (prevents two workers picking up same items from claim)
# Key: worker.get_instance_id(), Value: Dictionary {ResourceType (int): amount}
var _reserved_items: Dictionary = {}

# Alert throttling to avoid spam from per-NPC intrusion checks
var _last_alert_time: float = 0.0
var _last_alert_level: int = 0
const ALERT_THROTTLE_SEC: float = 0.5

# Step 5: EnemiesInClaim - event-driven list of enemies inside claim (body_entered/exited)
var _enemies_in_claim: Array = []
var _enemies_zone: Area2D = null

signal emergency_defend_triggered

func _ready() -> void:
	if EntityRegistry:
		EntityRegistry.register(self)
	# Get nodes safely
	sprite = get_node_or_null("Sprite") as Sprite2D
	radius_indicator = get_node_or_null("RadiusIndicator") as Node2D
	
	# Create inventory (6 slots, stacking enabled, no stack limit for testing) if not already set
	# CRITICAL: Only create if not already set (main.gd might have set it before _ready() runs)
	if not inventory:
		var n: int = BalanceConfig.land_claim_inventory_slots if BalanceConfig else 40
		var mx: int = BalanceConfig.land_claim_inventory_max_stack if BalanceConfig else 999999
		inventory = InventoryData.new(n, true, mx)
		if DebugConfig.enable_debug_mode:
			print("🔵 LAND_CLAIM._READY: Created NEW inventory for %s (inventory=%s)" % [clan_name, inventory])
	else:
		if DebugConfig.enable_debug_mode:
			print("🔵 LAND_CLAIM._READY: Using EXISTING inventory for %s (inventory=%s, slot_count=%d)" % [clan_name, inventory, inventory.slot_count if inventory else 0])

	# Playtest: buildings spawn empty (no starting GRAIN/WOOD)
	
	# Create collision area for interaction
	_setup_collision()
	_setup_visuals()
	_setup_clan_name_label()
	_draw_radius()
	
	# Manual z_index by sprite foot + offset so player stays in front until past building
	if sprite:
		sprite.z_as_relative = false
		YSortUtils.update_building_draw_order(sprite, self)
	
	# Add to group for easy finding
	add_to_group("buildings")
	add_to_group("land_claims")
	
	# Step 5: EnemiesInClaim zone (body_entered/exited)
	_setup_enemies_in_claim()
	
	# Setup health bar
	_setup_health_bar()
	
	# Phase 3 Part C: Initialize ClanBrain for all clans (limited mode for player-owned)
	_initialize_clan_brain()
	
	# Enable processing for decay and ClanBrain updates
	set_process(true)
	if ClaimBuildingIndex:
		claim_destroyed.connect(ClaimBuildingIndex._on_claim_destroyed)

func _setup_collision() -> void:
	# Create an Area2D for clicking/interaction
	_collision_area = Area2D.new()
	_collision_area.name = "InteractionArea"
	
	var collision_shape := CollisionShape2D.new()
	var shape := CircleShape2D.new()
	shape.radius = 32.0  # Clickable area (native)
	collision_shape.shape = shape
	_collision_area.add_child(collision_shape)
	
	# Enable input detection
	_collision_area.input_event.connect(_on_input_event)
	# input_ray_pickable is deprecated in Godot 4 - input events work automatically
	
	add_child(_collision_area)

func _setup_enemies_in_claim() -> void:
	_enemies_zone = Area2D.new()
	_enemies_zone.name = "EnemiesInClaimZone"
	_enemies_zone.monitoring = true
	_enemies_zone.monitorable = false
	_enemies_zone.collision_mask = 3  # Layers 1+2: player and NPCs (AOP Phase 2 fix; mask=1 missed NPCs)
	var shape := CircleShape2D.new()
	shape.radius = radius
	var cs := CollisionShape2D.new()
	cs.shape = shape
	_enemies_zone.add_child(cs)
	_enemies_zone.body_entered.connect(_on_enemies_zone_body_entered)
	_enemies_zone.body_exited.connect(_on_enemies_zone_body_exited)
	add_child(_enemies_zone)

func _is_enemy_of_claim(body: Node) -> bool:
	if not body or not is_instance_valid(body):
		return false
	if body.is_in_group("npcs"):
		var bclan: String = body.get_clan_name() if body.has_method("get_clan_name") else (str(body.get("clan_name")) if body.get("clan_name") != null else "")
		if clan_name != "" and bclan == clan_name:
			return false
		var t: String = body.get("npc_type") as String if body.get("npc_type") != null else ""
		if t == "caveman" or t == "clansman":
			return true
	if body.is_in_group("player"):
		return not player_owned
	return false

func _on_enemies_zone_body_entered(body: Node2D) -> void:
	if _is_enemy_of_claim(body):
		if _enemies_in_claim.find(body) < 0:
			_enemies_in_claim.append(body)

func _on_enemies_zone_body_exited(body: Node2D) -> void:
	var idx: int = _enemies_in_claim.find(body)
	if idx >= 0:
		_enemies_in_claim.remove_at(idx)

func get_enemies_in_claim() -> Array:
	# Prune invalid refs
	var valid: Array = []
	for b in _enemies_in_claim:
		if is_instance_valid(b):
			var th = b.get_node_or_null("HealthComponent")
			if th and th.is_dead:
				continue
			valid.append(b)
	_enemies_in_claim = valid
	return _enemies_in_claim

func _on_input_event(_viewport: Node, _event: InputEvent, _shape_idx: int) -> void:
	# Left-click no longer opens inventory; use right-click context menu → Open Inventory.
	# Kept for potential future use (e.g. other input).
	pass

func _on_clicked() -> void:
	# Signal to main that this land claim was clicked
	# Main will handle showing the inventory
	var main: Node = get_tree().get_first_node_in_group("main")
	if main and main.has_method("_on_land_claim_clicked"):
		main._on_land_claim_clicked(self)

func _setup_visuals() -> void:
	if not sprite:
		return
	
	var texture := AssetRegistry.get_landclaim_sprite()
	if texture is Texture2D:
		sprite.texture = texture
		sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		sprite.scale = Vector2.ONE  # Land claim: 1:1 (no scale)
		sprite.position = Vector2.ZERO  # Land claim: centered on node

func _draw_radius() -> void:
	if not radius_indicator:
		return
	
	# Create a circle outline for the radius
	_radius_circle = Line2D.new()
	_radius_circle.width = 2.0
	_radius_circle.default_color = Color(1.0, 1.0, 1.0, 0.5)  # Semi-transparent white
	
	# Draw circle with 64 points
	var points := PackedVector2Array()
	var point_count := 64
	for i in point_count:
		var angle := (TAU * i) / point_count
		var point := Vector2(cos(angle), sin(angle)) * radius
		points.append(point)
	# Close the circle
	points.append(points[0])
	
	_radius_circle.points = points
	_radius_circle.visible = false  # Drawn by LandClaimCircles drawer (behind sprites, over ground)
	radius_indicator.add_child(_radius_circle)

func _setup_clan_name_label() -> void:
	# Create a label to display the clan name above the land claim
	_clan_name_label = Label.new()
	_clan_name_label.name = "ClanNameLabel"
	_clan_name_label.text = clan_name
	_clan_name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_clan_name_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	
	# Position label above the land claim
	_clan_name_label.position = Vector2(0, -50)  # Above center
	
	# Style the label - white text with black outline for visibility
	_clan_name_label.add_theme_color_override("font_color", Color.WHITE)
	_clan_name_label.add_theme_color_override("font_shadow_color", Color.BLACK)
	_clan_name_label.add_theme_constant_override("shadow_offset_x", 2)
	_clan_name_label.add_theme_constant_override("shadow_offset_y", 2)
	
	# Make text larger
	var font_size: int = 24
	_clan_name_label.add_theme_font_size_override("font_size", font_size)
	
	add_child(_clan_name_label)

func set_clan_name(clan_name_param: String) -> void:
	clan_name = clan_name_param.to_upper()
	# Don't truncate - display full clan name (e.g., "DA KUEY", "HO GEEN")
	# The naming convention generates names like "Cv CvCv" or "Cv CvvC" which can be up to 7 characters
	
	# Update label if it exists
	if _clan_name_label:
		_clan_name_label.text = clan_name
		# Auto-size label to fit text
		_clan_name_label.autowrap_mode = TextServer.AUTOWRAP_OFF
		_clan_name_label.clip_contents = false
	
	queue_redraw()

# Item reservation for production jobs - prevents PickUpTask race when multiple buildings share same claim
func get_reserved_count(type: ResourceData.ResourceType) -> int:
	var total := 0
	for worker_id in _reserved_items:
		var items: Dictionary = _reserved_items[worker_id]
		if items.has(int(type)):
			total += items[int(type)]
	return total

func reserve_items(worker: Node, items: Dictionary) -> bool:
	"""Reserve items for a worker. items = {ResourceType (int): amount}. Returns false if not enough available."""
	if not worker or not inventory:
		return false
	_prune_reserved_items()
	for type_int in items:
		var amount: int = items[type_int]
		var type_enum: ResourceData.ResourceType = type_int as ResourceData.ResourceType
		var available: int = inventory.get_count(type_enum) - get_reserved_count(type_enum)
		if available < amount:
			return false
	var wid: int = worker.get_instance_id()
	if not _reserved_items.has(wid):
		_reserved_items[wid] = {}
	var my_res: Dictionary = _reserved_items[wid]
	for type_int in items:
		my_res[type_int] = my_res.get(type_int, 0) + items[type_int]
	return true

func release_items(worker: Node) -> void:
	if not worker:
		return
	_reserved_items.erase(worker.get_instance_id())
	_prune_reserved_items()

func release_items_by_id(worker_id: int) -> void:
	"""Release by worker instance ID - for death/invalid-npc when worker ref is gone."""
	if worker_id != 0:
		_reserved_items.erase(worker_id)
	_prune_reserved_items()

func release_items_partial(worker: Node, items: Dictionary) -> void:
	"""Partial release when items are consumed (e.g. PickUp succeeds). Reduces reservation by amount."""
	if not worker or items.is_empty():
		return
	var wid: int = worker.get_instance_id()
	if not _reserved_items.has(wid):
		return
	var my_res: Dictionary = _reserved_items[wid]
	for type_int in items:
		var amt: int = items[type_int]
		var current: int = my_res.get(type_int, 0)
		my_res[type_int] = max(0, current - amt)
		if my_res[type_int] <= 0:
			my_res.erase(type_int)
	if my_res.is_empty():
		_reserved_items.erase(wid)

func _prune_reserved_items() -> void:
	# Reservation cleanup happens via release_items() when job ends
	pass

# Step 11: Role pool helpers. Prune invalid refs when mutating.
func _prune_defenders() -> void:
	var valid: Array = []
	for n in assigned_defenders:
		if is_instance_valid(n) and not (n.has_method("is_dead") and n.is_dead()):
			valid.append(n)
	assigned_defenders = valid

func _prune_searchers() -> void:
	var valid: Array = []
	for n in assigned_searchers:
		if is_instance_valid(n) and not (n.has_method("is_dead") and n.is_dead()):
			valid.append(n)
	assigned_searchers = valid

func add_defender(npc: Node) -> void:
	if not npc or not is_instance_valid(npc):
		return
	_prune_defenders()
	if npc in assigned_defenders:
		return
	assigned_defenders.append(npc)

func remove_defender(npc: Node) -> void:
	_prune_defenders()
	assigned_defenders.erase(npc)

func add_searcher(npc: Node) -> void:
	if not npc or not is_instance_valid(npc):
		return
	_prune_searchers()
	if npc in assigned_searchers:
		return
	assigned_searchers.append(npc)

func remove_searcher(npc: Node) -> void:
	_prune_searchers()
	assigned_searchers.erase(npc)

func remove_npc_from_pools(npc: Node) -> void:
	"""Clear NPC from both pools (e.g. on Clear assignment or death)."""
	remove_defender(npc)
	remove_searcher(npc)

# Phase 3: Lazy eviction helpers - NPCs call these to check if they should stay in role
func should_i_defend(npc: Node) -> bool:
	"""Check if NPC should continue defending. Returns false if over quota."""
	if not npc or not is_instance_valid(npc):
		return false
	_prune_defenders()
	
	# If not in pool, can't defend
	if npc not in assigned_defenders:
		return false
	
	# Check quota
	var quota: int = get_meta("defender_quota", 1)
	var current_count: int = assigned_defenders.size()
	
	# If over quota and this NPC isn't one of the first N defenders, evict
	if current_count > quota:
		var npc_index: int = assigned_defenders.find(npc)
		if npc_index >= quota:
			return false  # This NPC should leave
	
	return true

func should_i_search(npc: Node) -> bool:
	"""Check if NPC should continue searching. Returns false if over quota."""
	if not npc or not is_instance_valid(npc):
		return false
	_prune_searchers()
	
	# If not in pool, can't search
	if npc not in assigned_searchers:
		return false
	
	# Check quota
	var quota: int = get_meta("searcher_quota", 0)
	var current_count: int = assigned_searchers.size()
	
	# If over quota and this NPC isn't one of the first N searchers, evict
	if current_count > quota:
		var npc_index: int = assigned_searchers.find(npc)
		if npc_index >= quota:
			return false  # This NPC should leave
	
	return true

func hide_area_circle() -> void:
	"""Hide the land claim area circle when clan dies"""
	set_meta("circle_hidden", true)  # LandClaimCircles drawer skips drawing
	if _radius_circle:
		_radius_circle.visible = false
		print("💀 Land claim area circle hidden for clan %s" % clan_name)

# === Phase 3 Part C: Alert System ===

func trigger_alert(level: int) -> void:
	"""Trigger an alert on this land claim's ClanBrain.
	level: 0=NONE, 1=INTRUDER, 2=SKIRMISH, 3=RAID"""
	var now: float = Time.get_ticks_msec() / 1000.0
	# Throttle: skip same level within 0.5s; allow escalation (higher level) immediately
	if level <= _last_alert_level and (now - _last_alert_time) < ALERT_THROTTLE_SEC:
		return
	_last_alert_level = level
	_last_alert_time = now
	if clan_brain:
		clan_brain.on_alert(level)
	# Emit for horn audio when RAID (auto or manual will call start_player_emergency_defend for manual)
	if level >= 3:
		emergency_defend_triggered.emit()

func report_intruder() -> void:
	"""Report an intruder detected in the land claim area."""
	trigger_alert(1)  # INTRUDER

func report_skirmish() -> void:
	"""Report combat started in the land claim area."""
	trigger_alert(2)  # SKIRMISH

func report_raid() -> void:
	"""Report a raid in progress (multiple enemies or building attacked)."""
	trigger_alert(3)  # RAID

func start_player_emergency_defend() -> void:
	"""Player clicked DEFEND from land claim dropdown (last resort). Tell ClanBrain to keep defenders until cooldown since last intrusion."""
	if clan_brain and clan_brain.has_method("start_player_emergency_defend"):
		clan_brain.start_player_emergency_defend()
		emergency_defend_triggered.emit()

func get_clan_brain() -> RefCounted:
	"""Get the ClanBrain controller for this land claim (ClanBrain extends RefCounted)."""
	return clan_brain

func get_threat_level() -> float:
	"""Get the current threat level (0.0 - 1.0) from ClanBrain."""
	if clan_brain:
		return clan_brain.get_threat_level()
	return 0.0

func get_strategic_state() -> int:
	"""Get the current strategic state from ClanBrain.
	Returns: 0=PEACEFUL, 1=DEFENSIVE, 2=AGGRESSIVE, 3=RAIDING, 4=RECOVERING"""
	if clan_brain:
		return clan_brain.get_strategic_state()
	return 0  # PEACEFUL

func is_raiding() -> bool:
	"""Check if this clan is currently raiding."""
	if clan_brain:
		return clan_brain.is_raiding()
	return false

func get_clan_strength() -> float:
	"""Get overall clan strength (0.0 - 1.0)."""
	if clan_brain:
		return clan_brain.get_clan_strength()
	return 0.0

func get_clan_brain_debug() -> Dictionary:
	"""Get debug info from the clan brain for UI/debugging."""
	if clan_brain:
		return clan_brain.get_debug_info()
	return {}

func take_damage(damage: float) -> void:
	"""Take damage from player/NPC attacks (enemy can damage land claim)"""
	decay_health -= damage
	decay_health = max(0.0, decay_health)
	if not is_decaying:
		is_decaying = true
		is_raidable = true
	_update_health_bar()
	if decay_health <= 0.0:
		_destroy_building()

func start_decay() -> void:
	"""Start building decay when clan dies"""
	if is_decaying:
		return  # Already decaying
	
	is_decaying = true
	decay_health = DECAY_MAX_HEALTH
	is_raidable = true  # Building inventory can now be raided
	print("💀 Land claim building for clan %s started decaying (raidable: %s)" % [clan_name, is_raidable])

func _initialize_clan_brain() -> void:
	"""Initialize the ClanBrain AI controller for this land claim."""
	if clan_brain != null:
		return  # Already initialized
	
	# Load and create ClanBrain
	var ClanBrainClass = load("res://scripts/ai/clan_brain.gd")
	if ClanBrainClass:
		clan_brain = ClanBrainClass.new(self)
	else:
		push_error("Failed to load ClanBrain script for land claim: %s" % clan_name)

func _update_player_defender_quota() -> void:
	"""Immediate quota from ClanBrain (drag defend/work, UI). Refreshes fighter list so n/4 matches current roster."""
	if clan_brain and clan_brain.has_method("_refresh_clan_members"):
		clan_brain._refresh_clan_members()
	if clan_brain and clan_brain.has_method("_update_defender_assignments"):
		clan_brain._update_defender_assignments()

func _process(delta: float) -> void:
	"""Process building decay and ClanBrain updates"""
	
	# Phase 3 Part C: Update ClanBrain (all clans; player quota = n/4 + drag pool)
	if clan_brain and not is_decaying:
		clan_brain.update(delta)
	
	if not is_decaying:
		return
	
	# Reduce health over time (land claim decays slowest: 0.5 health/second)
	decay_health -= decay_rate * delta
	decay_health = max(0.0, decay_health)
	
	# Visual feedback: make building darker as it decays
	if sprite:
		var health_percent: float = decay_health / DECAY_MAX_HEALTH
		sprite.modulate = Color(health_percent, health_percent, health_percent, 1.0)
	
	# OPTIMIZATION: Throttle health bar updates (update every N frames instead of every frame)
	_health_bar_update_frame += 1
	if _health_bar_update_frame >= HEALTH_BAR_UPDATE_INTERVAL:
		_health_bar_update_frame = 0
		_update_health_bar()
	
	# If health reaches 0, destroy the building
	if decay_health <= 0.0:
		_destroy_building()

func _destroy_building() -> void:
	"""Destroy the building when decay completes or is attacked (Phase 2)"""
	print("💀 Land claim building for clan %s has been destroyed" % clan_name)
	
	# Revert women and herd NPCs (sheep, goats) to wild
	_revert_clan_women_to_wild()
	
	# Despawn babies
	_despawn_clan_babies()
	
	# Other clan buildings switch to fast decay
	_start_fast_decay_on_clan_buildings()
	claim_destroyed.emit(clan_name)
	# Inventory despawns with building (no drop)
	# Remove the building
	queue_free()

func _revert_clan_women_to_wild() -> void:
	"""When land claim is destroyed, women and herd NPCs (sheep, goats) of this clan become wild again."""
	var npcs := get_tree().get_nodes_in_group("npcs")
	for n in npcs:
		if not is_instance_valid(n):
			continue
		var other_type: String = n.get("npc_type") if n.get("npc_type") != null else ""
		if other_type != "woman" and other_type != "sheep" and other_type != "goat":
			continue
		var npc_clan: String = n.get_clan_name() if n.has_method("get_clan_name") else (n.get("clan_name") as String if n.get("clan_name") != null else "")
		if npc_clan != clan_name:
			continue
		# Evict from building first (OccupationSystem or fallback for legacy)
		if OccupationSystem and OccupationSystem.has_ref(n):
			OccupationSystem.unassign(n, "claim_destroyed")
		else:
			# Fallback: legacy women/animals not yet in OccupationSystem
			var buildings := get_tree().get_nodes_in_group("buildings")
			for bld in buildings:
				if not is_instance_valid(bld) or not (bld is BuildingBase):
					continue
				var b: BuildingBase = bld as BuildingBase
				if b.clan_name != clan_name:
					continue
				if b.get_primary_occupant() == n or n in b.animal_slots:
					b.clear_occupant_for_npc(n)
					break
		if n.has_method("become_wild"):
			n.become_wild()
		else:
			n.set_clan_name("", "_destroy_building")
			if n.get("is_herded"):
				n.set("is_herded", false)
				n.set("herder", null)
				n.set("follow_is_ordered", false)
			var fsm = n.get_node_or_null("FSM")
			if fsm and fsm.has_method("_evaluate_states"):
				fsm._evaluate_states()
		print("🔄 %s reverted to wild (land claim destroyed)" % (n.get("npc_name") if n else other_type))

func _despawn_clan_babies() -> void:
	"""When land claim is destroyed, despawn all babies of this clan."""
	var npcs := get_tree().get_nodes_in_group("npcs")
	for n in npcs:
		if not is_instance_valid(n):
			continue
		if n.get("npc_type") != "baby":
			continue
		var npc_clan: String = n.get_clan_name() if n.has_method("get_clan_name") else (n.get("clan_name") as String if n.get("clan_name") != null else "")
		if npc_clan != clan_name:
			continue
		print("💀 Baby %s despawned (land claim destroyed)" % (n.get("npc_name") if n else "baby"))
		n.queue_free()

func _start_fast_decay_on_clan_buildings() -> void:
	"""When land claim is destroyed, other clan buildings switch to fast decay."""
	var buildings := get_tree().get_nodes_in_group("buildings")
	for bld in buildings:
		if not is_instance_valid(bld):
			continue
		if bld == self:
			continue  # Skip self (land claim is being destroyed)
		if bld.clan_name != clan_name:
			continue
		if bld.has_method("start_fast_decay"):
			bld.start_fast_decay()

func _setup_health_bar() -> void:
	"""Create health bar UI for land claim (same as BuildingBase)"""
	# Create health bar container
	var health_bar = Control.new()
	health_bar.name = "HealthBar"
	health_bar.set_anchors_preset(Control.PRESET_CENTER_TOP)
	health_bar.position = Vector2(-40, -60)  # Above building
	health_bar.size = Vector2(80, 8)
	health_bar.visible = false  # Hidden until damaged/decaying
	add_child(health_bar)
	
	# Background bar (red)
	var bg_bar = ColorRect.new()
	bg_bar.name = "Background"
	bg_bar.color = Color(0.3, 0.0, 0.0, 0.8)
	bg_bar.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg_bar.size = Vector2(80, 8)
	health_bar.add_child(bg_bar)
	
	# Health bar (green)
	var health_fill = ColorRect.new()
	health_fill.name = "HealthFill"
	health_fill.color = Color(0.0, 1.0, 0.0, 0.8)
	health_fill.set_anchors_preset(Control.PRESET_LEFT_WIDE)
	health_fill.position = Vector2(0, 0)
	health_fill.size = Vector2(80, 8)
	health_bar.add_child(health_fill)

func _update_health_bar() -> void:
	"""Update health bar visual"""
	var health_bar = get_node_or_null("HealthBar")
	if not health_bar:
		return
	
	var health_fill = health_bar.get_node_or_null("HealthFill")
	if not health_fill:
		return
	
	# Show health bar if damaged or decaying
	if decay_health < DECAY_MAX_HEALTH or is_decaying:
		health_bar.visible = true
	else:
		health_bar.visible = false
	
	# Update health bar width
	var health_percent: float = decay_health / DECAY_MAX_HEALTH
	health_fill.size.x = 80.0 * health_percent
	
	# Change color based on health
	if health_percent > 0.6:
		health_fill.color = Color(0.0, 1.0, 0.0, 0.8)  # Green
	elif health_percent > 0.3:
		health_fill.color = Color(1.0, 1.0, 0.0, 0.8)  # Yellow
	else:
		health_fill.color = Color(1.0, 0.0, 0.0, 0.8)  # Red

func _drop_inventory_items(drop_position: Vector2) -> void:
	"""Drop all inventory items as ground items when building is destroyed"""
	if not inventory:
		return
	
	var main = get_tree().get_first_node_in_group("main")
	if not main:
		return
	
	# Get ground item script
	var ground_item_script = load("res://scripts/ground_item.gd") as GDScript
	if not ground_item_script:
		print("⚠️ Failed to load ground_item.gd script")
		return
	
	# Drop each item in inventory
	for i in range(inventory.slot_count):
		var slot = inventory.slots[i]
		if slot == null:
			continue
		
		var item_type = slot.get("item_type")
		var count = slot.get("count", 0)
		
		if item_type != null and count > 0:
			# Spawn ground items in a small radius around the building
			var angle = (TAU * i) / max(1, inventory.slot_count)  # Spread items in a circle
			var offset = Vector2(cos(angle), sin(angle)) * 32.0  # 32px radius
			var item_pos = drop_position + offset
			
			# Create ground item
			var ground_item: Node2D = ground_item_script.new()
			ground_item.set("item_type", item_type)
			ground_item.set("count", count)
			ground_item.global_position = item_pos
			
			# Add to resources container
			var world_objects = main.get_node_or_null("WorldObjects")
			if world_objects:
				world_objects.add_child(ground_item)
				print("💀 Dropped %d %s from destroyed land claim" % [count, item_type])

# Gather Task System - Phase 1: Job generator for gathering
func generate_gather_job(worker: Node) -> Job:
	"""Generate a gather job for a worker NPC. Returns null if no resources available."""
	if not worker:
		return null
	
	# Check if worker is in same clan
	var worker_clan: String = worker.get("clan_name") if "clan_name" in worker else ""
	if worker_clan != clan_name:
		return null
	
	# Find nearest available resource (with capacity)
	var resource: Node2D = _find_nearest_available_resource(worker)
	if not resource:
		var worker_name: String = worker.get("npc_name") if "npc_name" in worker else "unknown"
		UnifiedLogger.log_npc("GATHER_JOB: %s no resource in claim range (clan=%s, claim_pos=%s)" % [
			worker_name, clan_name, str(global_position)
		], {"npc": worker_name, "clan": clan_name, "claim_pos": str(global_position)}, UnifiedLogger.Level.DEBUG)
		return null
	
	# RULE 2: Reserve a slot on the resource when creating the job
	if resource.has_method("reserve"):
		if not resource.reserve(worker):
			# Resource is full, can't create job
			return null
	
	# Check if worker inventory at threshold (config) - only deposit if at threshold
	var skip_deposit: bool = false
	if worker and worker.has_method("get") and "inventory" in worker:
		var worker_inventory = worker.get("inventory")
		if worker_inventory:
			var used_slots: int = worker_inventory.get_used_slots() if worker_inventory.has_method("get_used_slots") else 0
			var max_slots: int = worker_inventory.slot_count if "slot_count" in worker_inventory else 5
			var pct: float = NPCConfig.gather_same_node_until_pct if NPCConfig else 1.0
			var threshold: int = int(ceil(max_slots * pct))
			skip_deposit = (used_slots < threshold)
			# Debug logging
			var worker_name: String = worker.get("npc_name") if "npc_name" in worker else "unknown"
			UnifiedLogger.log_npc("GATHER_JOB: %s - inventory %d/%d, threshold=%d, skip_deposit=%s" % [
				worker_name, used_slots, max_slots, threshold, skip_deposit
			], {
				"npc": worker_name,
				"used_slots": used_slots,
				"max_slots": max_slots,
				"threshold": threshold,
				"skip_deposit": skip_deposit
			})
	
	# Load GatherJob script
	var gather_job_script = load("res://scripts/ai/jobs/gather_job.gd") as GDScript
	if not gather_job_script:
		push_error("LandClaim.generate_gather_job: Failed to load GatherJob script")
		return null
	
	# Create gather job (with skip_deposit flag)
	var job: Job = gather_job_script.new(resource, self, skip_deposit) as Job
	if not job:
		return null
	
	# Set metadata
	job.building = self

	return job

# Craft Task System - Job generator for knapping blades
const BLADE_RESERVE_TARGET: int = 4
const STONES_REQUIRED_FOR_KNAP: int = 2

func generate_craft_job(worker: Node) -> Job:
	"""Generate a craft (knap) job when land claim has < 4 blades and 2+ stones in storage.
	Worker takes stones from claim, knaps, deposits blade + stone back."""
	if not worker:
		return null

	var worker_clan: String = worker.get("clan_name") if "clan_name" in worker else ""
	if worker_clan != clan_name:
		return null

	var npc_type: String = worker.get("npc_type") if "npc_type" in worker else ""
	if npc_type != "clansman" and npc_type != "caveman":
		return null

	if not inventory or not inventory.has_method("get_count"):
		return null

	var blade_count: int = inventory.get_count(ResourceData.ResourceType.BLADE)
	if blade_count >= BLADE_RESERVE_TARGET:
		return null

	# Claim must have 2+ stones in storage (worker will PickUp from claim)
	if inventory.get_count(ResourceData.ResourceType.STONE) < STONES_REQUIRED_FOR_KNAP:
		return null

	var craft_job_script = load("res://scripts/ai/jobs/craft_job.gd") as GDScript
	if not craft_job_script:
		push_error("LandClaim.generate_craft_job: Failed to load CraftJob script")
		return null

	var job: Job = craft_job_script.new(self) as Job
	if not job:
		return null

	job.building = self
	return job

func _find_nearest_available_resource(worker: Node) -> Node2D:
	"""Find the nearest harvestable resource within reasonable range of land claim.
	Prioritizes resources the worker is already at to finish them off."""
	if not worker or not ResourceIndex:
		return null
	
	var worker_pos: Vector2 = worker.global_position if worker else global_position
	var claim_pos: Vector2 = global_position
	var search_range: float = radius * 3.0
	var gather_distance: float = 60.0
	
	var land_claims: Array = []
	var main_node = get_tree().current_scene
	if main_node and main_node.has_method("get_cached_land_claims"):
		land_claims = main_node.get_cached_land_claims()
	else:
		land_claims = get_tree().get_nodes_in_group("land_claims")
	
	var exclude_enemy: Callable = func(pos: Vector2) -> bool:
		return ResourceIndex.is_position_in_enemy_claim(land_claims, pos, clan_name)
	
	var filters: Dictionary = {
		"exclude_cooldown": true,
		"exclude_no_capacity": true,
		"exclude_empty": true,
		"exclude_position_enemy_claim": exclude_enemy
	}
	
	var candidates: Array = ResourceIndex.query_near(claim_pos, search_range, filters)
	
	# First pass: worker already at a resource or current job resource
	var current_job_resource: Node2D = null
	if worker.has_method("get") and "task_runner" in worker:
		var task_runner = worker.get("task_runner")
		if task_runner and task_runner.has_method("has_job") and task_runner.has_job():
			var current_job = task_runner.get("current_job") if "current_job" in task_runner else null
			if current_job and "resource_node" in current_job:
				current_job_resource = current_job.resource_node
	
	for pair in candidates:
		var resource: Node2D = pair.node
		var distance_to_worker: float = worker_pos.distance_to(resource.global_position)
		var is_at_resource: bool = (distance_to_worker <= gather_distance)
		var is_current_job_resource: bool = (current_job_resource == resource)
		if is_at_resource or is_current_job_resource:
			if resource.has_method("has_capacity") and not resource.has_capacity():
				if not (resource.has_method("reserved_workers") and worker in resource.reserved_workers):
					continue
			return resource
	
	# Second pass: soft-cost scoring - prefer resources with fewer clan mates nearby
	if candidates.is_empty():
		return null
	var spread_penalty: float = NPCConfig.clan_spread_penalty if NPCConfig else 50.0
	const CLAN_NEAR_RADIUS: float = 100.0
	var npcs = get_tree().get_nodes_in_group("npcs")
	var best: Node2D = null
	var best_score: float = INF
	for pair in candidates:
		var resource: Node2D = pair.node
		var res_pos: Vector2 = resource.global_position
		var d: float = worker_pos.distance_to(res_pos)
		var nearby_clan_mates: int = 0
		for other in npcs:
			if other == worker or not is_instance_valid(other):
				continue
			var other_clan: String = other.get_clan_name() if other.has_method("get_clan_name") else (other.get("clan_name") as String if other.get("clan_name") != null else "")
			if other_clan != clan_name:
				continue
			if other.global_position.distance_to(res_pos) < CLAN_NEAR_RADIUS:
				nearby_clan_mates += 1
		var score: float = d + (nearby_clan_mates * spread_penalty)
		if score < best_score:
			best_score = score
			best = resource
	return best
