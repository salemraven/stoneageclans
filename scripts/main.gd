extends Node2D

# Phase 3: Land claims cache signals
signal land_claims_changed  # Emitted when land claims are added or removed

@onready var world_objects: Node2D = $"WorldObjects"
@onready var player: CharacterBody2D = $"WorldObjects/Player"
@onready var camera: Camera2D = $"WorldObjects/Player/Camera2D"
@onready var world: TileMap = $"WorldLayer/World"
@onready var resources_container := $"WorldObjects/Resources"
@onready var land_claims_container := $"WorldObjects/LandClaims"
@onready var world_area: Area2D = $"WorldArea"
@onready var ui_layer: CanvasLayer = $"UI"

# Phase 3: Land claims cache
var _land_claims_cache: Array = []
var _land_claims_cache_valid: bool = false

# NPCs cache (invalidate when NPCs spawn/die)
var _npcs_cache: Array = []
var _npcs_cache_valid: bool = false

var active_collection_resource: Node2D = null  # Only one resource can be collected at a time (GatherableResource or GroundItem)
var _player_is_eating: bool = false
var _eating_slot_index: int = -1
var nearby_building: Node = null  # Building player is near (LandClaim or BuildingBase)
var nearby_corpse: Node = null  # Corpse player is near (for looting)
var nearby_travois_ground: Node = null  # Placed travois on ground
# Corpse butcher: gather meat from sheep/goat with stone blade in left hand
var butchering_corpse: Node = null
var butcher_timer: float = 0.0
const BUTCHER_DURATION: float = 1.0
const CORPSE_DESPAWN_SEC: float = 120.0  # Corpse despawns after this many seconds without player interaction
var butcher_start_pos: Vector2 = Vector2.ZERO
const BUTCHER_MOVE_CANCEL: float = 20.0

var player_inventory_ui: PlayerInventoryUI = null
var building_inventory_ui: BuildingInventoryUI = null
var npc_inventory_ui: NPCInventoryUI = null
var character_menu_ui: CharacterMenuUI = null  # Character menu (NPC info panel)
var dropdown_menu_ui: Node = null  # DropdownMenuUI; context menu (right-click); Step 1 integration_plan
var drag_manager: Node = null  # Changed from DragManager to Node to avoid parse error
var npc_debug_ui: NPCDebugUI = null
var npcs_container: Node2D = null  # Empty; NPCs add to world_objects for YSort
var decorations_container: Node2D = null  # Empty; grass adds to world_objects for YSort
var clicked_npc: Node = null  # NPC currently being clicked
var baby_pool_manager: BabyPoolManager = null  # Baby pool manager for reproduction system
var active_clan_name_dialog: AcceptDialog = null  # Track active dialog to prevent duplicates
var combat_hud: Control = null  # Step 9 / Step 4: HUD panel (FOLLOW|GUARD, BREAK) left of hotbar
var follow_guard_mode: String = "FOLLOW"  # Step 4: FOLLOW | GUARD (formation mode for ordered followers)
var _follower_cache: Array = []  # Step 4: commander's list of follower entity IDs (for BREAK)
var _followers_hostile_timer: float = 0.0  # Throttle weapon-derived is_hostile updates

# Step 10: NPC drag (left-click hold → drop on player/land claim)
var npc_drag_source: Node = null
var npc_dragging: bool = false
var npc_drag_hold_timer: float = 0.0
var npc_drag_preview: Control = null
const NPC_DRAG_HOLD_SEC := 0.2

# RTS: Drag-box selection for multiple clansmen (Option B)
var selection_box_active: bool = false
var selection_box_start: Vector2 = Vector2.ZERO
var selection_box_end: Vector2 = Vector2.ZERO
var selection_box_visual: ColorRect = null
var selected_clansmen: Array = []  # Node refs

# TASK SYSTEM TEST: Periodic logger for women, land claim, and ovens
var task_system_log_timer: float = 0.0
const TASK_SYSTEM_LOG_INTERVAL := 3.0  # Log every 3 seconds

# Emergency defend horn (sounds when raid or manual DEFEND)
var _horn_audio: AudioStreamPlayer = null
var _emergency_defend_connections: Dictionary = {}  # claim -> connected (avoid duplicate connects)

# GATHER TEST: Periodic logger for NPC movement, logic, and resource tracking
var gather_test_log_timer: float = 0.0
const GATHER_TEST_LOG_INTERVAL := 2.0  # Log every 2 seconds
var gather_test_enabled: bool = false
var gather_test_npc_positions: Dictionary = {}  # Track previous positions for movement detection

# Agro/combat test (Part 0): leaders and claims for driving leaders toward each other
var _agro_combat_test_leaders: Array = []  # [leader_a, leader_b] Node refs
var _agro_combat_test_claims: Array = []   # [claim_a, claim_b] LandClaim refs
var _agro_combat_test_start_time: float = -1.0  # set when setup done; auto-quit after AGRO_COMBAT_TEST_DURATION

# Raid test: ClanBrain raid test; auto-quit after N seconds
var _raid_test_start_time: float = -1.0

# 2-min playtest: productivity monitoring; auto-quit after 120s
var _playtest_2min_start_time: float = -1.0

const RESOURCE_SCENE = preload("res://scenes/GatherableResource.tscn")
const LAND_CLAIM_SCENE = preload("res://scenes/LandClaim.tscn")
const CAMPFIRE_SCENE = preload("res://scenes/Campfire.tscn")
const CampfireScript = preload("res://scripts/campfire.gd")
const TRAVOIS_GROUND_SCENE = preload("res://scenes/TravoisGround.tscn")
const NPC_SCENE = preload("res://scenes/NPC.tscn")
const BUILDING_SCENE = preload("res://scenes/Building.tscn")
const DROPDOWN_MENU_UI_SCRIPT = preload("res://scripts/ui/dropdown_menu_ui.gd")
const ProgressPieOverlay = preload("res://scripts/ui/progress_pie_overlay.gd")

# Building placement duration (seconds) - pie timer on slot icon
const BUILDING_PLACEMENT_DURATION := 1.5
const EAT_DURATION := 0.4  # Player eating pie timer (seconds)
const LAND_CLAIM_PLACEMENT_DURATION := 2.0
const CAMPFIRE_PLACEMENT_DURATION := 1.5
const TRAVOIS_PLACEMENT_DURATION := 1.0

# Building placement safety
const BUILDING_MIN_DISTANCE: float = 50.0  # Minimum distance between buildings
const AI_BUILDING_MIN_FROM_CLAIM: float = 120.0  # AI buildings: keep off land claim center (ring around it)
# Land claim spacing: use BalanceConfig.get_land_claim_min_center_distance() (was 200px; now matches AI / build_state)
const BUILDING_SAFE_ZONE_OFFSET: Vector2 = Vector2(0, -20)  # Offset safe zone anchor point up 20px

# Debug helper: only prints when --debug (clean console for playtest)
func _dbg(msg: String) -> void:
	if DebugConfig.enable_debug_mode:
		print(msg)

# Phase 3: Land claims cache functions
func get_cached_land_claims() -> Array:
	"""Get cached list of land claims. Use this instead of get_nodes_in_group('land_claims') for performance."""
	if not _land_claims_cache_valid:
		_refresh_land_claims_cache()
	return _land_claims_cache

func _refresh_land_claims_cache() -> void:
	"""Refresh the land claims cache from the group."""
	_land_claims_cache = get_tree().get_nodes_in_group("land_claims")
	_land_claims_cache_valid = true

func invalidate_land_claims_cache() -> void:
	"""Call this when land claims are added or removed to force cache refresh."""
	_land_claims_cache_valid = false
	land_claims_changed.emit()

# NPCs cache
func get_cached_npcs() -> Array:
	"""Get cached list of NPCs. Use instead of get_nodes_in_group('npcs') for performance."""
	if not _npcs_cache_valid:
		_refresh_npcs_cache()
	return _npcs_cache

func _refresh_npcs_cache() -> void:
	_npcs_cache = get_tree().get_nodes_in_group("npcs")
	_npcs_cache_valid = true

func invalidate_npcs_cache() -> void:
	"""Call when NPCs are spawned or removed."""
	_npcs_cache_valid = false

func _on_world_child_changed(_node: Node) -> void:
	invalidate_npcs_cache()

func _on_land_claim_tree_exiting(_claim: Node) -> void:
	"""Called when a land claim is about to be removed from the tree."""
	invalidate_land_claims_cache()

func register_land_claim(claim: Node) -> void:
	"""Register a new land claim for cache tracking. Call after adding to tree."""
	if claim and not claim.tree_exiting.is_connected(_on_land_claim_tree_exiting):
		claim.tree_exiting.connect(_on_land_claim_tree_exiting.bind(claim))
	# AI claim destroyed -> spawn replacement caveman
	if claim and claim.get("player_owned") == false:
		if claim.has_signal("claim_destroyed") and not claim.claim_destroyed.is_connected(_on_ai_claim_destroyed):
			claim.claim_destroyed.connect(_on_ai_claim_destroyed)
	invalidate_land_claims_cache()

func _on_ai_claim_destroyed(_clan_name: String) -> void:
	"""When AI land claim destroyed, spawn replacement caveman."""
	_spawn_replacement_caveman()

func _spawn_replacement_caveman() -> void:
	"""Spawn 1 land claim + 1 caveman when AI claim destroyed (same as initial spawn: claim and caveman together)."""
	if not player or not world_objects:
		return
	
	var center_pos := player.global_position
	var min_from_player: float = 1200.0
	var min_from_claims: float = NPCConfig.land_claim_min_distance if NPCConfig else 1600.0
	var radius_min: float = BalanceConfig.caveman_spawn_radius_min if BalanceConfig else 900.0
	var radius_max: float = BalanceConfig.caveman_spawn_radius_max if BalanceConfig else 1200.0
	
	var pos: Vector2 = Vector2.ZERO
	for attempt in 15:
		var angle := randf() * TAU
		var distance := randf_range(radius_min, radius_max)
		pos = Vector2(cos(angle), sin(angle)) * distance + center_pos
		if pos.distance_to(center_pos) < min_from_player:
			continue
		var valid: bool = true
		for claim in get_cached_land_claims():
			if not is_instance_valid(claim):
				continue
			if pos.distance_to(claim.global_position) < min_from_claims:
				valid = false
				break
		if valid:
			break
	
	var claim_pos := Vector2(round(pos.x / 64.0) * 64.0, round(pos.y / 64.0) * 64.0)
	var clan_name: String = _generate_random_clan_name()
	
	var land_claim: LandClaim = LAND_CLAIM_SCENE.instantiate() as LandClaim
	if not land_claim:
		return
	land_claim.global_position = claim_pos
	land_claim.set_clan_name(clan_name)
	land_claim.player_owned = false
	if not land_claim.inventory:
		land_claim.inventory = InventoryData.new(12, true, 999999)
	world_objects.add_child(land_claim)
	_despawn_tallgrass_near(claim_pos, land_claim.radius)
	_despawn_decorative_trees_near(claim_pos, land_claim.radius)
	register_land_claim(land_claim)
	land_claim.visible = true
	
	var npc: Node = NPC_SCENE.instantiate()
	if not npc:
		return
	var npc_name: String = _generate_caveman_name()
	npc.set("npc_name", npc_name)
	npc.set("npc_type", "caveman")
	npc.set("age", randi_range(13, 50))
	npc.set("traits", ["solitary"])
	npc.set("agro_meter", 0.0)
	npc.set("clan_name", clan_name)
	npc.set_meta("clan_name", clan_name)
	npc.set_meta("land_claim_clan_name", clan_name)
	npc.set_meta("has_land_claim", true)
	
	world_objects.add_child(npc)
	npc.global_position = pos
	npc.set("spawn_position", pos)
	npc.set("spawn_time", Time.get_ticks_msec() / 1000.0)
	if npc.has_method("set_clan_name"):
		npc.set_clan_name(clan_name, "main._spawn_replacement_caveman")
	
	land_claim.owner_npc = npc
	land_claim.owner_npc_name = npc_name
	land_claim.set_meta("owner_npc_name", npc_name)
	
	await get_tree().process_frame
	
	var sprite: Sprite2D = npc.get_node_or_null("Sprite")
	if sprite:
		var texture: Texture2D = AssetRegistry.get_player_sprite()
		if texture:
			sprite.texture = texture
			sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
			sprite.visible = true
			if npc.has_method("apply_sprite_offset_for_texture"):
				npc.apply_sprite_offset_for_texture()
	
	var npc_inventory = npc.get("inventory")
	if npc_inventory:
		npc_inventory.add_item(ResourceData.ResourceType.WOOD, 1)
	
	_equip_club_to_npc(npc)
	npc.visible = true
	print("✓ Spawned replacement Caveman: %s at %s with land claim '%s' (AI claim destroyed)" % [npc_name, pos, clan_name])

func _use_hotbar_consumable(slot_index: int) -> void:
	# Use consumable from hotbar slot (9 or 0 only)
	if slot_index != 8 and slot_index != 9:
		return
	if not player_inventory_ui:
		return
	if _player_is_eating:
		return  # Ignore second 9/0 press until first pie completes
	
	# Get hotbar data
	var hotbar_data = player_inventory_ui.get_meta("hotbar_data", null) as InventoryData
	if not hotbar_data:
		return
	
	# Check if slot has an item
	var slot_data = hotbar_data.get_slot(slot_index)
	if slot_data.is_empty():
		var slot_num: String = str((slot_index + 1) % 10)  # 1-9 for indices 0-8, 0 for index 9
		print("🔔 Hotbar slot %s is empty" % slot_num)
		return
	
	# Get item type
	var item_type: ResourceData.ResourceType = slot_data.get("type", -1) as ResourceData.ResourceType
	if item_type == -1 or item_type == ResourceData.ResourceType.NONE:
		return
	
	# Check if item is consumable (food)
	if not ResourceData.is_food(item_type):
		var slot_num: String = str((slot_index + 1) % 10)  # 1-9 for indices 0-8, 0 for index 9
		print("🔔 Hotbar slot %s does not contain consumable food" % slot_num)
		return
	
	# Start eating pie timer (defer consume until pie completes)
	_player_is_eating = true
	_eating_slot_index = slot_index
	
	if player and player.get("eat_progress_display"):
		var icon: Texture2D = null
		var icon_path: String = ResourceData.get_resource_icon_path(item_type)
		if icon_path != "":
			icon = load(icon_path) as Texture2D
		player.eat_progress_display.collection_time = EAT_DURATION
		player.eat_progress_display.start_collection(icon)
	
	var timer := get_tree().create_timer(EAT_DURATION)
	timer.timeout.connect(_on_eat_complete)

func _on_eat_complete() -> void:
	_player_is_eating = false
	var slot_index: int = _eating_slot_index
	_eating_slot_index = -1
	
	if player and player.get("eat_progress_display"):
		player.eat_progress_display.stop_collection()
	
	if not player_inventory_ui:
		return
	var hotbar_data = player_inventory_ui.get_meta("hotbar_data", null) as InventoryData
	if not hotbar_data:
		return
	
	var slot_data = hotbar_data.get_slot(slot_index)
	if slot_data.is_empty():
		return  # Slot was cleared during eat
	
	var item_type: ResourceData.ResourceType = slot_data.get("type", -1) as ResourceData.ResourceType
	if not ResourceData.is_food(item_type):
		return
	
	var item_count: int = slot_data.get("count", 1) as int
	var new_count: int = item_count - 1
	var slot_num: String = str((slot_index + 1) % 10)
	
	if new_count <= 0:
		hotbar_data.set_slot(slot_index, {})
		print("🍽️ Consumed %s from hotbar slot %s (slot now empty)" % [
			ResourceData.get_resource_name(item_type),
			slot_num
		])
	else:
		var updated_item = slot_data.duplicate()
		updated_item["count"] = new_count
		hotbar_data.set_slot(slot_index, updated_item)
		print("🍽️ Consumed %s from hotbar slot %s (%d remaining)" % [
			ResourceData.get_resource_name(item_type),
			slot_num,
			new_count
		])
	
	if player and player.get("hunger_max") != null:
		var restore_pct: float = ResourceData.get_food_hunger_restore_percent(item_type)
		var max_h: float = player.hunger_max
		var restore: float = restore_pct * 0.01 * max_h
		player.hunger = min(max_h, player.hunger + restore)
		print("🍽️ Restored %.1f%% hunger (now %.1f%%)" % [restore_pct, (player.hunger / max_h) * 100.0 if max_h > 0 else 0])
	
	player_inventory_ui._update_hotbar_slots()

func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		# Print competition leaderboard and clan deposits before exit
		var competition_tracker = get_node_or_null("/root/CompetitionTracker")
		if competition_tracker:
			competition_tracker.print_leaderboard()
			competition_tracker.print_clan_deposits()
		get_tree().quit()

func _ready() -> void:
	# Log startup
	UnifiedLogger.log_system("Main._ready() called")
	
	add_to_group("main")
	
	_configure_input()
	_setup_world_area()
	_setup_inventory_ui()
	
	if camera:
		camera.make_current()
		UnifiedLogger.log_system("Camera set as current")
	else:
		UnifiedLogger.log_error("Camera is null!", UnifiedLogger.Category.SYSTEM)
	
	if world and player:
		world.ensure_chunks_for_position(player.global_position)
		UnifiedLogger.log_system("World chunks initialized for player position")
	else:
		UnifiedLogger.log_error("World or player is null! world=%s player=%s" % [world != null, player != null], UnifiedLogger.Category.SYSTEM)
	
	_setup_node_cache()  # Initialize NodeCache for performance
	
	# NPCs cache: invalidate when world_objects gains/loses children (NPCs spawn/die)
	if world_objects:
		world_objects.child_entered_tree.connect(_on_world_child_changed)
		world_objects.child_exiting_tree.connect(_on_world_child_changed)
	
	# Use DebugConfig for logging (playtest: clean console; use --debug for verbose)
	
	_setup_npcs()
	# FLOW FIX: Resources now spawn AFTER NPCs (see _ready() - moved to after _initialize_minigame())
	# _spawn_initial_resources()  # Moved to after NPCs spawn
	_spawn_ground_items()
	_give_starting_items()
	_setup_debug_ui()
	_setup_baby_pool_manager()
	_setup_combat_hud()  # Step 9: Hostile toggle, Break Follow (left of hotbar)
	
	# Connect emergency defend horn to player land claims
	_connect_emergency_defend_horns()
	land_claims_changed.connect(_on_land_claims_changed_for_horn)

	# Timed playtest (2min/4min): start timer for auto-quit
	var pi = get_node_or_null("/root/PlaytestInstrumentor")
	if pi and pi.has_method("is_playtest_timed") and pi.is_playtest_timed():
		_playtest_2min_start_time = Time.get_ticks_msec() / 1000.0

func _connect_emergency_defend_horns() -> void:
	"""Connect emergency_defend_triggered signal on all player-owned land claims."""
	var claims = get_tree().get_nodes_in_group("land_claims")
	for claim in claims:
		if not is_instance_valid(claim) or not claim is LandClaim:
			continue
		var lc: LandClaim = claim as LandClaim
		if lc.player_owned:
			var id := lc.get_instance_id()
			if id not in _emergency_defend_connections:
				lc.emergency_defend_triggered.connect(_on_emergency_defend_triggered.bind(lc))
				_emergency_defend_connections[id] = true

func _on_land_claims_changed_for_horn() -> void:
	"""When land claims change, connect any new player claims."""
	_connect_emergency_defend_horns()

func _on_emergency_defend_triggered(claim: LandClaim) -> void:
	"""Play horn when emergency defend triggers (player away, raid; or manual DEFEND)."""
	if not claim or not claim.player_owned:
		return
	_play_emergency_horn()

func _handle_war_horn() -> void:
	"""War Horn (H): Rally idle clansmen from player-owned claim to follow player."""
	if not player or not is_instance_valid(player):
		return
	var player_pos: Vector2 = player.global_position
	const WAR_HORN_RANGE: float = 500.0
	var near_claim: LandClaim = null
	for claim in get_tree().get_nodes_in_group("land_claims"):
		if not is_instance_valid(claim) or not claim is LandClaim:
			continue
		var lc: LandClaim = claim as LandClaim
		if not lc.player_owned:
			continue
		if player_pos.distance_to(lc.global_position) <= WAR_HORN_RANGE:
			near_claim = lc
			break
	if not near_claim:
		return
	var clan_name: String = near_claim.clan_name if "clan_name" in near_claim else ""
	if clan_name == "":
		return
	var rallied: int = 0
	for n in get_tree().get_nodes_in_group("npcs"):
		if not is_instance_valid(n):
			continue
		if n.has_method("is_dead") and n.is_dead():
			continue
		var t = n.get("npc_type")
		if t != "clansman" and t != "caveman":
			continue
		var c: String = n.get_clan_name() if n.has_method("get_clan_name") else (str(n.get("clan_name")) if n.get("clan_name") != null else "")
		if c != clan_name:
			continue
		if n.get("combat_target") != null and n.get("combat_target") != false:
			continue
		if n.get("defend_target") != null and n.get("defend_target") != false:
			continue
		if n.get("follow_is_ordered") and n.get("herder") == player:
			continue
		_set_ordered_follow(n)
		rallied += 1
	if rallied > 0:
		_play_emergency_horn()
	var pi = get_node_or_null("/root/PlaytestInstrumentor")
	if pi and pi.has_method("war_horn_triggered"):
		pi.war_horn_triggered(clan_name, rallied, true)

func _play_emergency_horn() -> void:
	"""Play horn sound so player knows to return to land claim."""
	if not _horn_audio:
		_horn_audio = AudioStreamPlayer.new()
		_horn_audio.name = "EmergencyHornAudio"
		add_child(_horn_audio)
		var horn_path := "res://assets/sounds/horn.mp3"
		if ResourceLoader.exists(horn_path):
			_horn_audio.stream = load(horn_path) as AudioStream
		else:
			# No horn file - use placeholder beep (AudioStreamGenerator or skip)
			pass
	if _horn_audio.stream:
		_horn_audio.play()
	else:
		print("HORN: Emergency defend! (Add res://assets/sounds/horn.mp3 for audio)")

func _process(delta: float) -> void:
	if not player:
		return
	# Step 4: Periodically update followers' is_hostile from player weapon (sustain 70 agro when hostile)
	_followers_hostile_timer += delta
	if _followers_hostile_timer >= 0.2:
		_followers_hostile_timer = 0.0
		_update_followers_hostile()
	# Timed playtest: auto-quit after duration
	if _playtest_2min_start_time >= 0.0:
		var inst = get_node_or_null("/root/PlaytestInstrumentor")
		var duration: float = inst.get_playtest_duration_sec() if (inst and inst.has_method("get_playtest_duration_sec")) else 120.0
		var now_sec: float = Time.get_ticks_msec() / 1000.0
		if (now_sec - _playtest_2min_start_time) >= duration:
			print("Playtest: %.0fs elapsed — quitting (data in playtest log)" % duration)
			if inst and inst.has_method("end_playtest_2min"):
				inst.end_playtest_2min()
			get_tree().quit(0)
			return
	# Agro/combat test: leaders move toward enemy claim; clansmen stay close (GUARD) and move as a unit
	# Raid test: auto-quit after N seconds
	if DebugConfig.enable_raid_test and _raid_test_start_time >= 0.0:
		var now_sec: float = Time.get_ticks_msec() / 1000.0
		var duration: float = 90.0
		var dc = get_node_or_null("/root/DebugConfig")
		if dc and dc.get("test_overrides") is Dictionary and dc.test_overrides.has("raid_test_auto_quit_seconds"):
			duration = dc.test_overrides.raid_test_auto_quit_seconds
		if (now_sec - _raid_test_start_time) >= duration:
			print("Raid test: %d s elapsed — quitting (data in user://playtest_*.jsonl)" % [int(duration)])
			var pi = get_node_or_null("/root/PlaytestInstrumentor")
			if pi and pi.has_method("end_raid_test"):
				pi.end_raid_test()
			get_tree().quit(0)
			return
	# Agro/combat test: leaders move toward enemy claim; clansmen stay close (GUARD) and move as a unit
	if DebugConfig.enable_agro_combat_test and _agro_combat_test_leaders.size() >= 2 and _agro_combat_test_claims.size() >= 2:
		var leader_a = _agro_combat_test_leaders[0]
		var leader_b = _agro_combat_test_leaders[1]
		var claim_a = _agro_combat_test_claims[0]
		var claim_b = _agro_combat_test_claims[1]
		if is_instance_valid(leader_a) and is_instance_valid(leader_b) and is_instance_valid(claim_a) and is_instance_valid(claim_b):
			var now_sec: float = Time.get_ticks_msec() / 1000.0
			var duration: float = 90.0
			var dc = get_node_or_null("/root/DebugConfig")
			if dc and dc.get("enable_agro_combat_test") and dc.get("test_overrides") is Dictionary and dc.test_overrides.has("auto_quit_seconds"):
				duration = dc.test_overrides.auto_quit_seconds
			if _agro_combat_test_start_time >= 0.0 and (now_sec - _agro_combat_test_start_time) >= duration:
				print("Agro/combat test: %d s elapsed — quitting (data in user://playtest_*.jsonl)" % [int(duration)])
				var pi = get_node_or_null("/root/PlaytestInstrumentor")
				if pi and pi.has_method("end_agro_combat_test"):
					pi.end_agro_combat_test()
				get_tree().quit(0)
				return
			for idx in [0, 1]:
				var leader = _agro_combat_test_leaders[idx]
				var target_claim = _agro_combat_test_claims[1 - idx]
				if not is_instance_valid(leader) or not is_instance_valid(target_claim):
					continue
				var sa = leader.get("steering_agent")
				if not sa:
					continue
				# Stop advancing when enemies in range so formation stays in engagement zone
				var my_clan: String = leader.get_clan_name() if leader.has_method("get_clan_name") else ""
				var nearest_enemy: Node2D = null
				var nearest_d: float = 550.0  # Retarget earlier so formation has time to engage
				for n in get_tree().get_nodes_in_group("npcs"):
					if not is_instance_valid(n) or n == leader or (n.has_method("is_dead") and n.is_dead()):
						continue
					var nc: String = n.get_clan_name() if n.has_method("get_clan_name") else ""
					if my_clan != "" and nc == my_clan:
						continue
					var d: float = leader.global_position.distance_to(n.global_position)
					if d < nearest_d:
						nearest_d = d
						nearest_enemy = n as Node2D
				if nearest_enemy:
					sa.target_position = nearest_enemy.global_position  # Close in on enemy
					# Slow leader when closing so formation stays in engagement zone (more overlap)
					if sa.max_speed > 35.0:
						sa.max_speed = maxf(35.0, sa.max_speed * 0.6)
				else:
					sa.target_position = target_claim.global_position
				sa.current_mode = SteeringAgent.SteeringMode.SEEK
				sa._pending_intent_time = 0.0
				if sa.max_speed <= 5.0 and leader.get("stats_component"):
					var ag: float = leader.stats_component.get_stat("agility")
					sa.max_speed = ag * (NPCConfig.speed_agility_multiplier if NPCConfig else 9.5)
				elif sa.max_speed <= 5.0:
					sa.max_speed = NPCConfig.max_speed_base if NPCConfig else 95.0
				var fsm = leader.get("fsm")
				if fsm and fsm.has_method("get_current_state_name") and fsm.get_current_state_name() == "idle" and fsm.has_method("change_state"):
					fsm.change_state("wander")
				if sa.max_speed <= 0.0 and leader.get("stats_component"):
					var ag: float = leader.stats_component.get_stat("agility")
					sa.max_speed = ag * (NPCConfig.speed_agility_multiplier if NPCConfig else 9.5)
				elif sa.max_speed <= 0.0:
					sa.max_speed = NPCConfig.max_speed_base if NPCConfig else 95.0
	camera.global_position = player.global_position
	world.ensure_chunks_for_position(player.global_position)
	_check_nearby_buildings()
	_check_nearby_corpses()
	_check_nearby_travois_ground()
	
	# Corpse butcher: gather meat with blade in left hand (takes priority over resource gather)
	if butchering_corpse:
		_process_butcher(delta)
	elif Input.is_action_just_pressed("gather") and nearby_corpse and is_butcher_tool_equipped():
		var meat_left: int = nearby_corpse.get_meta("meat_remaining", 0) as int
		var hide_left: int = nearby_corpse.get_meta("hide_remaining", 0) as int
		var bone_left: int = nearby_corpse.get_meta("bone_remaining", 0) as int
		var has_yield: bool = meat_left > 0 or hide_left > 0 or bone_left > 0
		if has_yield and is_instance_valid(nearby_corpse):
			butchering_corpse = nearby_corpse
			butcher_timer = 0.0
			butcher_start_pos = player.global_position
			player.set("is_gathering", true)
			active_collection_resource = null  # Prevent gatherable from also consuming gather
	_spawn_ground_items_around_player()  # Continuously spawn ground items as player moves
	# Step 10: NPC drag hold timer + preview follow
	if npc_drag_source and not npc_dragging:
		npc_drag_hold_timer += delta
		if npc_drag_hold_timer >= NPC_DRAG_HOLD_SEC:
			npc_dragging = true
			_npc_drag_show_preview()
	if npc_dragging and npc_drag_preview:
		npc_drag_preview.global_position = get_viewport().get_mouse_position() + Vector2(16, 16)

	# Hover outline for items and NPCs (white/tan outline when mouse over)
	_update_hover_outline()
	
	# Task system logger: only when --debug (clean console for playtest)
	if DebugConfig.enable_debug_mode:
		task_system_log_timer += delta
		if task_system_log_timer >= TASK_SYSTEM_LOG_INTERVAL:
			task_system_log_timer = 0.0
			_log_task_system_data()
	
	# GATHER TEST: Periodic logging for NPC movement, logic, and resources
	if gather_test_enabled:
		gather_test_log_timer += delta
		if gather_test_log_timer >= GATHER_TEST_LOG_INTERVAL:
			gather_test_log_timer = 0.0
			_log_gather_test_data()

const CAMERA_ZOOM_MIN := 0.5
const CAMERA_ZOOM_MAX := 3.0
const CAMERA_ZOOM_STEP := 0.15

func _input(event: InputEvent) -> void:
	# Scroll wheel / +/- keys: zoom camera
	if camera:
		var zoom_in := false
		var zoom_out := false
		if event is InputEventMouseButton:
			var mb := event as InputEventMouseButton
			if mb.pressed:
				if mb.button_index == MOUSE_BUTTON_WHEEL_UP:
					zoom_in = true
				elif mb.button_index == MOUSE_BUTTON_WHEEL_DOWN:
					zoom_out = true
		elif event is InputEventKey and event.pressed:
			if event.keycode in [KEY_EQUAL, KEY_PLUS]:
				zoom_in = true
			elif event.keycode == KEY_MINUS:
				zoom_out = true
		if zoom_in:
			var z := camera.zoom.x
			camera.zoom = Vector2(clampf(z + CAMERA_ZOOM_STEP, CAMERA_ZOOM_MIN, CAMERA_ZOOM_MAX), clampf(z + CAMERA_ZOOM_STEP, CAMERA_ZOOM_MIN, CAMERA_ZOOM_MAX))
			get_viewport().set_input_as_handled()
		elif zoom_out:
			var z := camera.zoom.x
			camera.zoom = Vector2(clampf(z - CAMERA_ZOOM_STEP, CAMERA_ZOOM_MIN, CAMERA_ZOOM_MAX), clampf(z - CAMERA_ZOOM_STEP, CAMERA_ZOOM_MIN, CAMERA_ZOOM_MAX))
			get_viewport().set_input_as_handled()

	# Mouse motion: update selection box while dragging
	if selection_box_active and event is InputEventMouseMotion:
		selection_box_end = get_viewport().get_mouse_position()
		_selection_box_update_visual()
		return
	
	if event.is_action_pressed("toggle_inventory"):
		_handle_inventory_toggle()
		get_viewport().set_input_as_handled()

	if event.is_action_pressed("war_horn"):
		_handle_war_horn()
		get_viewport().set_input_as_handled()
	
	# B key build menu removed - building icons now integrated into land claim inventory
	
	# ESC: Clear selection
	if event is InputEventKey and event.keycode == KEY_ESCAPE and event.pressed:
		if selection_box_active:
			_selection_box_cancel()
		else:
			_clear_selection()
		get_viewport().set_input_as_handled()
		return
	
	# F1 for debug UI
	if event is InputEventKey and event.keycode == KEY_F1 and event.pressed:
		if npc_debug_ui:
			npc_debug_ui.toggle()
		get_viewport().set_input_as_handled()

	# F2: test context menu. Same resolution + options as right-click (Step 2/4).
	if event is InputEventKey and event.keycode == KEY_F2 and event.pressed:
		if dropdown_menu_ui and ui_layer:
			var mp := get_viewport().get_mouse_position()
			var resolved := _resolve_click_target()
			var target = resolved.get("target")
			var target_type: String = resolved.get("target_type", "none")
			var opts := _get_dropdown_options_for_target(target, target_type)
			if opts.size() > 0:
				dropdown_menu_ui.show_at(target, mp, opts)
		get_viewport().set_input_as_handled()

	# B: Break Follow (Step 6) — clear ordered follow for all followers. Step 9: also via HUD button.
	if event is InputEventKey and event.keycode == KEY_B and event.pressed:
		_break_follow_all()
		get_viewport().set_input_as_handled()

	# F3: Debug — set DEFEND for NPC under cursor (Step 7). Uses player's land claim.
	if event is InputEventKey and event.keycode == KEY_F3 and event.pressed:
		_debug_set_defend_for_npc_under_cursor()
		get_viewport().set_input_as_handled()

	# F4: Debug — spawn 1 caveman + 2 wild women near player (for Follow/Defend testing).
	if event is InputEventKey and event.keycode == KEY_F4 and event.pressed:
		_debug_spawn_test_npcs()
		get_viewport().set_input_as_handled()
	
	# L: TASK SYSTEM TEST — manually trigger logger
	if event is InputEventKey and event.keycode == KEY_L and event.pressed:
		_log_task_system_data()
		get_viewport().set_input_as_handled()
	
	# T: TASK SYSTEM TEST — test Task base class (Step 12)
	if event is InputEventKey and event.keycode == KEY_T and event.pressed:
		_test_task_base_class()
		get_viewport().set_input_as_handled()
	
	# R: TASK SYSTEM TEST — test TaskRunner component (Step 13)
	if event is InputEventKey and event.keycode == KEY_R and event.pressed:
		_test_task_runner()
		get_viewport().set_input_as_handled()
	
	# Number keys 9 and 0 for consumables from hotbar slots 9 and 0
	if event is InputEventKey and event.pressed:
		if event.keycode == KEY_9:
			_use_hotbar_consumable(8)  # Slot 9 is index 8
			get_viewport().set_input_as_handled()
		elif event.keycode == KEY_0:
			_use_hotbar_consumable(9)  # Slot 0 is index 9
			get_viewport().set_input_as_handled()
	
	# Handle NPC and land claim click and hold for inventory
	# Block world interactions when any inventory UI or context menu is open
	# Phase 4: Allow LMB through when building occupation drag is active (map-to-slot)
	if _is_any_inventory_open():
		if not _is_building_occupation_drag_allowed():
			return
	if dropdown_menu_ui and dropdown_menu_ui.is_menu_open():
		return

	# Right-click → context menu (Step 2). Clear selection when clicking ground.
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_RIGHT and event.pressed:
		if drag_manager and drag_manager.is_dragging:
			return
		# Cancel selection box if active
		if selection_box_active:
			_selection_box_cancel()
			return
		# Clear selected clansmen when right-clicking
		_clear_selection()
		# Step 10: cancel NPC drag when opening menu
		if npc_drag_source or npc_dragging:
			_npc_drag_hide_preview()
			npc_drag_source = null
			npc_dragging = false
			npc_drag_hold_timer = 0.0
		var mp := get_viewport().get_mouse_position()
		if _is_mouse_over_ui(mp):
			return
		var resolved := _resolve_click_target()
		var target = resolved.get("target")
		var target_type: String = resolved.get("target_type", "none")
		if target != null and target_type != "none" and dropdown_menu_ui:
			var opts := _get_dropdown_options_for_target(target, target_type)
			if opts.size() > 0:
				dropdown_menu_ui.show_at(target, mp, opts)
				get_viewport().set_input_as_handled()
		return

	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			if event.pressed:
				# Step 10: left-click hold on clansman → NPC drag; else → selection box
				# Phase 4: When occupation drag allowed, only start npc_drag_source (never selection box)
				if not (drag_manager and drag_manager.is_dragging):
					var mp := get_viewport().get_mouse_position()
					if not _is_mouse_over_ui(mp):
						var npc := _get_npc_under_cursor()
						if npc and is_instance_valid(npc) and _is_npc_draggable(npc):
							npc_drag_source = npc
							npc_drag_hold_timer = 0.0
							if _is_building_occupation_drag_allowed():
								UnifiedLogger.write_log_entry("Occupation drag start (map)", UnifiedLogger.Category.DRAG_DROP, UnifiedLogger.Level.DEBUG, {"npc_type": npc.get("npc_type")})
						elif not _is_building_occupation_drag_allowed():
							# Start selection box (RTS drag-box) only when NOT in occupation drag mode
							selection_box_start = mp
							selection_box_end = mp
							selection_box_active = true
							_selection_box_show()
			else:
				# LMB release
				if selection_box_active:
					_selection_box_complete()
					get_viewport().set_input_as_handled()
					return
				if npc_dragging:
					_handle_npc_drag_release()
					get_viewport().set_input_as_handled()
					return
				# Phase 5: Slot-to-map - resolve occupation drag release (from slot, to slot or map)
				var occ_building = get("dragged_occupation_building")
				if occ_building and building_inventory_ui:
					var mp := get_viewport().get_mouse_position()
					if building_inventory_ui.try_resolve_occupation_drag_release(mp):
						clicked_npc = null
						set("dragged_occupation_building", null)
						set("dragged_occupation_slot_index", -1)
						set("dragged_occupation_is_woman", false)
						get_viewport().set_input_as_handled()
						return
				if npc_drag_source:
					npc_drag_source = null
					npc_drag_hold_timer = 0.0
				# Left-click release: attack NPC or enemy building if weapon in slot 1 (axe, pick, club)
				if not (drag_manager and drag_manager.is_dragging):
					var mp := get_viewport().get_mouse_position()
					if not _is_mouse_over_ui(mp) and player_inventory_ui:
						var first_slot = player_inventory_ui.hotbar_slots[player_inventory_ui.RIGHT_HAND_SLOT_INDEX] if player_inventory_ui.hotbar_slots.size() > player_inventory_ui.RIGHT_HAND_SLOT_INDEX else null
						var has_weapon := false
						if first_slot:
							var slot_item = first_slot.get_item()
							if not slot_item.is_empty():
								var it = slot_item.get("type", ResourceData.ResourceType.NONE) as ResourceData.ResourceType
								if it == ResourceData.ResourceType.AXE or it == ResourceData.ResourceType.PICK or it == ResourceData.ResourceType.WOOD:
									has_weapon = true
						if has_weapon:
							var npc := _get_npc_under_cursor()
							if npc and is_instance_valid(npc):
								_player_attack_target(npc)
								get_viewport().set_input_as_handled()
								return
							var building := _get_enemy_building_under_cursor()
							if building and is_instance_valid(building):
								_player_attack_target(building)
								get_viewport().set_input_as_handled()
								return
				# Mouse button released - hide NPC and building inventories
				# Unfreeze NPC first (if it was frozen)
				if clicked_npc and is_instance_valid(clicked_npc):
					_freeze_npc_for_inspection(clicked_npc, false)
				
				# Close character menu (merged with inventory - it also unfreezes)
				if character_menu_ui and character_menu_ui.is_open:
					character_menu_ui.hide_menu()
				
				# Hide building inventory (NPC inventory is now in character menu)
				if building_inventory_ui:
					building_inventory_ui.hide_inventory()
				# Phase 6: Clear occupation drag state when closing inventory
				clicked_npc = null
				set("dragged_occupation_building", null)
				set("dragged_occupation_slot_index", -1)
				set("dragged_occupation_is_woman", false)
				nearby_building = null
				
				# Handle building placement from inventory
				# This runs after inventory UI handles its input, so we check if drag is still active
				if drag_manager and drag_manager.is_dragging:
					# Small delay to ensure UI input was processed first
					await get_tree().process_frame
					if drag_manager and drag_manager.is_dragging:
						_try_place_building_from_inventory()
				
				# Click NPC to inspect (if debug UI is open)
				if npc_debug_ui and npc_debug_ui.debug_visible:
					_try_select_npc_for_debug()

func _check_nearby_buildings() -> void:
	if not player:
		return
	
	var player_pos := player.global_position
	var closest_building: Node = null
	var closest_distance := 100.0  # Interaction range
	
	# Check all land claims and campfires
	var land_claims := get_tree().get_nodes_in_group("land_claims")
	for claim in land_claims:
		if claim is LandClaim or claim is CampfireScript:
			var distance := player_pos.distance_to(claim.global_position)
			if distance < closest_distance:
				closest_distance = distance
				closest_building = claim
	
	# Check all regular buildings (Oven, Living Hut, etc.)
	var buildings := get_tree().get_nodes_in_group("buildings")
	for bld in buildings:
		if bld is BuildingBase:
			var distance := player_pos.distance_to(bld.global_position)
			if distance < closest_distance:
				closest_distance = distance
				closest_building = bld
	
	nearby_building = closest_building

func _check_nearby_travois_ground() -> void:
	if not player:
		return
	var player_pos := player.global_position
	var closest: Node = null
	var closest_dist := 80.0
	for tg in get_tree().get_nodes_in_group("travois_ground"):
		if not is_instance_valid(tg):
			continue
		var d := player_pos.distance_to(tg.global_position)
		if d < closest_dist:
			closest_dist = d
			closest = tg
	nearby_travois_ground = closest

func _check_nearby_corpses() -> void:
	if not player:
		return
	
	var player_pos := player.global_position
	var closest_corpse: Node = null
	var closest_distance := 50.0  # Interaction range (reduced from 100px per UI.md spec)
	
	# Corpse despawn: remove corpses that have been idle too long without player interaction
	var now_sec: float = Time.get_ticks_msec() / 1000.0
	var corpses_all := get_tree().get_nodes_in_group("corpses")
	for corpse in corpses_all:
		if not is_instance_valid(corpse):
			continue
		var created: float = corpse.get_meta("corpse_created_at", 0.0) as float
		var last_interact: float = corpse.get_meta("last_butcher_time", created) as float
		if now_sec - last_interact >= CORPSE_DESPAWN_SEC:
			corpse.queue_free()
			continue
	
	# Check all corpses
	var corpses := get_tree().get_nodes_in_group("corpses")
	for corpse in corpses:
		if not is_instance_valid(corpse):
			continue
		
		# Check if it's actually a corpse
		if not corpse.has_meta("is_corpse") or not corpse.get_meta("is_corpse"):
			continue
		# Skip corpses pending despawn
		var created_at: float = corpse.get_meta("corpse_created_at", 0.0) as float
		var last_int: float = corpse.get_meta("last_butcher_time", created_at) as float
		if now_sec - last_int >= CORPSE_DESPAWN_SEC:
			continue
		
		# Also check health component to verify it's dead (if it has one)
		var health_comp: HealthComponent = corpse.get_node_or_null("HealthComponent")
		if health_comp and not health_comp.is_dead:
			continue
		
		var distance := player_pos.distance_to(corpse.global_position)
		
		if distance < closest_distance:
			closest_distance = distance
			closest_corpse = corpse
	
	nearby_corpse = closest_corpse
	
	# Debug: Log if corpse found
	if nearby_corpse:
		var corpse_name = nearby_corpse.get("npc_name") if nearby_corpse else "unknown"
		var corpse_inv = nearby_corpse.get("inventory")
		print("🔍 CORPSE DETECTED: %s at distance %.1f (inventory: %s)" % [corpse_name, closest_distance, "found" if corpse_inv else "missing"])

func _process_butcher(delta: float) -> void:
	if not butchering_corpse or not is_instance_valid(butchering_corpse):
		_clear_butcher()
		return
	# Cancel if player moved
	var moved := player.global_position.distance_to(butcher_start_pos)
	if moved > BUTCHER_MOVE_CANCEL:
		_clear_butcher()
		return
	butcher_timer += delta
	if butcher_timer < BUTCHER_DURATION:
		return
	# Yield meat first, then hide, then bone (sequential)
	var meat_left: int = butchering_corpse.get_meta("meat_remaining", 0) as int
	var hide_left: int = butchering_corpse.get_meta("hide_remaining", 0) as int
	var bone_left: int = butchering_corpse.get_meta("bone_remaining", 0) as int
	if meat_left > 0:
		add_to_inventory(ResourceData.ResourceType.MEAT, 1)
		butchering_corpse.set_meta("meat_remaining", meat_left - 1)
		butchering_corpse.set_meta("last_butcher_time", Time.get_ticks_msec() / 1000.0)
		print("🥩 Butchered 1 meat from %s (%d remaining)" % [butchering_corpse.get("npc_name"), meat_left - 1])
	elif hide_left > 0:
		add_to_inventory(ResourceData.ResourceType.HIDE, 1)
		butchering_corpse.set_meta("hide_remaining", hide_left - 1)
		butchering_corpse.set_meta("last_butcher_time", Time.get_ticks_msec() / 1000.0)
		print("🦌 Butchered 1 hide from %s (%d remaining)" % [butchering_corpse.get("npc_name"), hide_left - 1])
	elif bone_left > 0:
		add_to_inventory(ResourceData.ResourceType.BONE, 1)
		var new_bone: int = bone_left - 1
		butchering_corpse.set_meta("bone_remaining", new_bone)
		butchering_corpse.set_meta("last_butcher_time", Time.get_ticks_msec() / 1000.0)
		print("🦴 Butchered 1 bone from %s (%d remaining)" % [butchering_corpse.get("npc_name"), new_bone])
	# Corpse fully butchered when all yields exhausted
	var m: int = butchering_corpse.get_meta("meat_remaining", 0) as int
	var h: int = butchering_corpse.get_meta("hide_remaining", 0) as int
	var b: int = butchering_corpse.get_meta("bone_remaining", 0) as int
	if m <= 0 and h <= 0 and b <= 0:
		butchering_corpse.queue_free()
	_clear_butcher()

func _clear_butcher() -> void:
	butchering_corpse = null
	butcher_timer = 0.0
	if player:
		player.set("is_gathering", false)

func _configure_input() -> void:
	_define_action("move_up", [KEY_W, KEY_UP])
	_define_action("move_down", [KEY_S, KEY_DOWN])
	_define_action("move_left", [KEY_A, KEY_LEFT])
	_define_action("move_right", [KEY_D, KEY_RIGHT])
	_define_action("toggle_inventory", [KEY_I])
	# B key build menu removed - building icons now integrated into land claim inventory
	_define_action("gather", [KEY_SPACE])
	_define_action("war_horn", [KEY_H])

func _define_action(action_name: StringName, keys: Array) -> void:
	if not InputMap.has_action(action_name):
		InputMap.add_action(action_name)
	
	# Always add keys (in case action existed but keys weren't set)
	for key in keys:
		var event := InputEventKey.new()
		event.keycode = key
		# Check if event already exists to avoid duplicates
		var events := InputMap.action_get_events(action_name)
		var exists := false
		for e in events:
			if e is InputEventKey and e.keycode == key:
				exists = true
				break
		if not exists:
			InputMap.action_add_event(action_name, event)

func _give_starting_items() -> void:
	# Player starts empty - must gather and craft (Oldowan, Cordage, Campfire, Travois)
	await get_tree().process_frame
	
	# Give player a campfire in inventory (for testing - place it to use)
	add_building_item_to_player_inventory(ResourceData.ResourceType.CAMPFIRE)
	
	if player_inventory_ui:
		player_inventory_ui._update_all_slots()
		player_inventory_ui._update_hotbar_slots()
		print("Starting items: 1 campfire in inventory")

func _spawn_initial_resources() -> void:
	# Wait a frame to ensure player position is set
	await get_tree().process_frame
	
	# Spawn resources randomly across the game map (spread out, not clustered in center)
	var spawn_count := 75  # Total resources to spawn (reduced by half)
	var spawn_radius: float = BalanceConfig.resource_spawn_radius if BalanceConfig else 3200.0
	var center_pos := player.global_position
	var min_resource_distance: float = BalanceConfig.resource_min_distance if BalanceConfig else 1000.0
	
	print("Spawning %d resources randomly across map (radius: %.0f) around position: %s" % [spawn_count, spawn_radius, center_pos])
	var max_attempts: int = 50  # More attempts to find valid positions when spread out
	
	for i in spawn_count:
		var resource_type: ResourceData.ResourceType
		match i % 5:
			0:
				resource_type = ResourceData.ResourceType.WOOD
			1:
				resource_type = ResourceData.ResourceType.STONE
			2:
				resource_type = ResourceData.ResourceType.BERRIES
			3:
				resource_type = ResourceData.ResourceType.WHEAT
			4:
				resource_type = ResourceData.ResourceType.FIBER
		
		# Try to find a position that's not too close to other resources
		# Random distribution across the map
		var pos: Vector2 = Vector2.ZERO
		var _found_valid_pos: bool = false
		
		for attempt in max_attempts:
			# Random distance and angle for true random distribution
			var distance := randf() * spawn_radius
			var angle := randf() * TAU
			pos = Vector2(cos(angle), sin(angle)) * distance + center_pos
			
			# Check if this position is far enough from existing resources
			var too_close: bool = false
			for existing_resource in get_tree().get_nodes_in_group("resources"):
				if not is_instance_valid(existing_resource):
					continue
				if existing_resource.is_in_group("ground_items"):
					continue
				var existing_pos: Vector2 = existing_resource.global_position
				if pos.distance_to(existing_pos) < min_resource_distance:
					too_close = true
					break
			
			if not too_close:
				_found_valid_pos = true
				break
		
		# Spawn the resource at the found position (always spawn, even if position isn't perfect)
		_spawn_resource(resource_type, pos)
	
		print("Resources spawned!")

func _spawn_tallgrass() -> void:
	"""Spawn tallgrass sprites in groups of 8-16 in random areas across the map (spread out)."""
	if not world_objects or not player:
		return
	var center_pos := player.global_position
	var spawn_radius: float = BalanceConfig.resource_spawn_radius if BalanceConfig else 3200.0
	var group_count := randi_range(65, 85)  # Number of tallgrass clusters
	var texture_paths := [
		"res://assets/sprites/tallgrass1.png",
		"res://assets/sprites/tallgrass2.png",
		"res://assets/sprites/tallgrass3.png",
		"res://assets/sprites/tallgrass4.png",
		"res://assets/sprites/tallgrass5.png",
		"res://assets/sprites/tallgrass6.png"
	]
	var textures: Array = []
	for p in texture_paths:
		var t := load(p) as Texture2D
		if t != null:
			textures.append(t)
	if textures.is_empty():
		return
	print("Spawning tallgrass in %d groups (radius: %.0f)" % [group_count, spawn_radius])
	for _g in group_count:
		var group_center_angle := randf() * TAU
		var group_center_dist := randf() * spawn_radius
		var group_center := Vector2(cos(group_center_angle), sin(group_center_angle)) * group_center_dist + center_pos
		var count_in_group := randi_range(8, 16)
		var cluster_radius := 90.0  # Slightly looser spacing
		for _i in count_in_group:
			var offset := Vector2(randf_range(-cluster_radius, cluster_radius), randf_range(-cluster_radius, cluster_radius))
			var pos := group_center + offset
			var node := Node2D.new()
			var sprite := Sprite2D.new()
			var tex: Texture2D = textures[randi() % textures.size()]
			sprite.texture = tex
			sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
			sprite.centered = true
			sprite.position = YSortUtils.get_grass_sprite_position_for_texture(tex)
			sprite.name = "Sprite"
			node.add_child(sprite)
			node.global_position = pos
			node.add_to_group("tallgrass")
			world_objects.add_child(node)
			sprite.z_as_relative = false
			YSortUtils.update_draw_order(sprite, node)
	print("Tallgrass spawned!")

func _spawn_decorative_trees() -> void:
	"""Spawn decorative trees from trees.png sprite sheet (5 cols x 3 rows = 15 trees), spread out."""
	if not world_objects or not player:
		return
	var tex := AssetRegistry.get_treess_sprite()
	if not tex:
		return
	var center_pos := player.global_position
	var spawn_radius: float = (BalanceConfig.resource_spawn_radius * 1.1) if BalanceConfig else 3500.0
	var cols := 5
	var rows := 3
	var cell_w := tex.get_width() / cols
	var cell_h := tex.get_height() / rows
	var group_count := randi_range(12, 20)
	var min_tree_dist := 150.0
	var existing_positions: Array[Vector2] = []
	print("Spawning decorative trees from sprite sheet in %d groups (radius: %.0f)" % [group_count, spawn_radius])
	for _g in group_count:
		var group_center_angle := randf() * TAU
		var group_center_dist := randf() * spawn_radius
		var group_center := Vector2(cos(group_center_angle), sin(group_center_angle)) * group_center_dist + center_pos
		var count_in_group := randi_range(2, 4)
		var cluster_radius := 300.0
		for _i in count_in_group:
			var offset := Vector2(randf_range(-cluster_radius, cluster_radius), randf_range(-cluster_radius, cluster_radius))
			var pos := group_center + offset
			var too_close := false
			for ep in existing_positions:
				if pos.distance_to(ep) < min_tree_dist:
					too_close = true
					break
			if too_close:
				continue
			existing_positions.append(pos)
			var tree_idx := randi_range(0, 14)
			var col := tree_idx % cols
			var row := tree_idx / cols
			var sort_offset: float = YSortUtils.tree_sort_offset_y if YSortUtils else 0.0
			# Wrapper: parent at pos+offset for y_sort (tree draws in front for larger zone), child at -offset so visual stays at pos
			var wrapper := Node2D.new()
			wrapper.global_position = pos + Vector2(0, sort_offset)
			wrapper.add_to_group("decorative_trees")
			var node := Node2D.new()
			node.position = Vector2(0, -sort_offset)
			var sprite := Sprite2D.new()
			sprite.texture = tex
			sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
			sprite.centered = true
			sprite.region_enabled = true
			sprite.region_rect = Rect2(col * cell_w, row * cell_h, cell_w, cell_h)
			sprite.scale = Vector2(1.15, 1.15)
			sprite.position = YSortUtils.get_tree_sprite_position_for_cell_height(cell_h, sprite.scale.y)
			sprite.name = "Sprite"
			node.add_child(sprite)
			wrapper.add_child(node)
			world_objects.add_child(wrapper)
			sprite.z_as_relative = false
			YSortUtils.update_tree_draw_order(sprite, node, tex)
	print("Decorative trees spawned!")

func _get_random_sheep_goat_tint() -> Color:
	"""White to almost-black grayscale for sheep/goat color variation."""
	var v := randf_range(0.15, 1.0)
	return Color(v, v, v)

func _despawn_tallgrass_near(center_pos: Vector2, radius: float) -> void:
	"""Remove tall grass nodes within radius of the given position."""
	var nodes := get_tree().get_nodes_in_group("tallgrass")
	for node in nodes:
		if not is_instance_valid(node):
			continue
		if node.global_position.distance_to(center_pos) <= radius:
			node.queue_free()

func _despawn_decorative_trees_near(center_pos: Vector2, radius: float) -> void:
	"""Remove decorative tree nodes within radius of the given position."""
	var nodes := get_tree().get_nodes_in_group("decorative_trees")
	for node in nodes:
		if not is_instance_valid(node):
			continue
		if node.global_position.distance_to(center_pos) <= radius:
			node.queue_free()

func _spawn_ground_items() -> void:
	# Spawn sparse ground items (stone and wood) spread across the map
	await get_tree().process_frame
	
	if not player:
		return
	
	var spawn_count := 40  # Increased for better coverage
	var spawn_radius: float = BalanceConfig.resource_spawn_radius if BalanceConfig else 3200.0
	var center_pos := player.global_position
	
	print("Spawning %d ground items across map (radius: %.0f) around position: %s" % [spawn_count, spawn_radius, center_pos])
	
	for i in spawn_count:
		var angle := randf() * TAU
		var distance := randf() * spawn_radius
		var pos := Vector2(cos(angle), sin(angle)) * distance + center_pos
		
		# Alternate between stone and wood
		var item_type: ResourceData.ResourceType
		if i % 2 == 0:
			item_type = ResourceData.ResourceType.STONE
		else:
			item_type = ResourceData.ResourceType.WOOD
		
		_spawn_ground_item(item_type, pos)
	
	print("Ground items spawned!")

func _spawn_ground_items_around_player() -> void:
	# Continuously spawn ground items as player explores
	# Only spawn in new areas (check if already spawned nearby)
	if not player:
		return
	
	# Spawn occasionally (not every frame)
	if randf() > 0.01:  # 1% chance per frame
		return
	
	var spawn_radius := 1000.0  # Increased radius for exploration
	var center_pos := player.global_position
	
	# Check if there are already ground items nearby
	var nearby_items := 0
	var ground_items := get_tree().get_nodes_in_group("ground_items")
	for item in ground_items:
		if not is_instance_valid(item):
			continue
		var distance: float = center_pos.distance_to(item.global_position)
		if distance < spawn_radius:
			nearby_items += 1
	
	# Only spawn if there are few items nearby (keep it sparse)
	if nearby_items < 5:
		var angle := randf() * TAU
		var distance := randf_range(400.0, spawn_radius)
		var pos := Vector2(cos(angle), sin(angle)) * distance + center_pos
		
		# Randomly choose stone or wood
		var item_type: ResourceData.ResourceType
		if randf() < 0.5:
			item_type = ResourceData.ResourceType.STONE
		else:
			item_type = ResourceData.ResourceType.WOOD
		
		_spawn_ground_item(item_type, pos)

func _spawn_ground_item(type: ResourceData.ResourceType, spawn_pos: Vector2) -> void:
	# Snap position to tile grid (64x64 tiles) to prevent overlap
	var tile_size: float = 64.0
	var snapped_pos := Vector2(
		floor(spawn_pos.x / tile_size) * tile_size + tile_size / 2.0,
		floor(spawn_pos.y / tile_size) * tile_size + tile_size / 2.0
	)
	
	# Check if there's already a resource at this position
	if _is_position_occupied(snapped_pos):
		# Try nearby positions in a spiral pattern around the original
		var found_position := false
		
		for radius in range(1, 4):
			for angle_offset in range(0, 8):
				var test_angle := (angle_offset * TAU / 8.0)
				var test_pos := snapped_pos + Vector2(cos(test_angle), sin(test_angle)) * (tile_size * radius)
				
				if not _is_position_occupied(test_pos):
					snapped_pos = test_pos
					found_position = true
					break
			
			if found_position:
				break
		
		# If still no position found, skip spawning
		if not found_position:
			return
	
	# Create ground item manually (no scene needed)
	var ground_item: GroundItem = GroundItem.new()
	ground_item.item_type = type
	
	# Create sprite node
	var sprite := Sprite2D.new()
	sprite.name = "Sprite"
	ground_item.add_child(sprite)
	
	ground_item.global_position = snapped_pos
	world_objects.add_child(ground_item)

func _is_position_occupied(pos: Vector2) -> bool:
	# Check if there's already a resource (ground item or gatherable resource) at this position
	var min_distance: float = 32.0  # Minimum distance between resources (half a tile)
	
	# Check ground items
	var ground_items := get_tree().get_nodes_in_group("ground_items")
	for item in ground_items:
		if not is_instance_valid(item):
			continue
		var distance: float = pos.distance_to(item.global_position)
		if distance < min_distance:
			return true
	
	# Check gatherable resources (trees, boulders, bushes, etc.)
	var resources := get_tree().get_nodes_in_group("resources")
	for resource in resources:
		if not is_instance_valid(resource):
			continue
		# Skip ground items (already checked above)
		if resource.is_in_group("ground_items"):
			continue
		var distance: float = pos.distance_to(resource.global_position)
		if distance < min_distance:
			return true
	
	return false

func _spawn_resource(type: ResourceData.ResourceType, spawn_pos: Vector2) -> void:
	var resource: GatherableResource = RESOURCE_SCENE.instantiate() as GatherableResource
	resource.resource_type = type
	
	# Set amounts based on type
	match type:
		ResourceData.ResourceType.WOOD:
			resource.min_amount = 4
			resource.max_amount = 6
		ResourceData.ResourceType.STONE:
			resource.min_amount = 4
			resource.max_amount = 6
		ResourceData.ResourceType.BERRIES:
			resource.min_amount = 6
			resource.max_amount = 10
		ResourceData.ResourceType.WHEAT:
			resource.min_amount = 2
			resource.max_amount = 5
		ResourceData.ResourceType.FIBER:
			resource.min_amount = 1
			resource.max_amount = 2
	
	resource.global_position = spawn_pos
	world_objects.add_child(resource)

func _setup_world_area() -> void:
	# Create an invisible area that covers the entire world for drop detection
	if not world_area:
		world_area = Area2D.new()
		world_area.name = "WorldArea"
		add_child(world_area)
		
		var collision := CollisionShape2D.new()
		var shape := RectangleShape2D.new()
		shape.size = Vector2(10000, 10000)  # Large area
		collision.shape = shape
		world_area.add_child(collision)
		
		# Enable input detection
		world_area.mouse_entered.connect(_on_world_mouse_entered)
		world_area.input_event.connect(_on_world_input_event)
	
	world_area.monitoring = true
	world_area.monitorable = true

func _on_world_mouse_entered() -> void:
	pass

func _on_world_input_event(_viewport: Node, _event: InputEvent, _shape_idx: int) -> void:
	# World drops will be handled by new inventory system
	pass

func _setup_inventory_ui() -> void:
	if not ui_layer:
		return
	
	# Get or create drag manager (optional - game can run without it)
	drag_manager = get_node_or_null("/root/DragManager")
	if not drag_manager:
		# Try to create DragManager - if it fails, continue without it
		var drag_manager_script = load("res://scripts/inventory/drag_manager.gd")
		if drag_manager_script and drag_manager_script.can_instantiate():
			drag_manager = drag_manager_script.new()
			if drag_manager:
				drag_manager.name = "DragManager"
				get_tree().root.add_child.call_deferred(drag_manager)
			else:
				UnifiedLogger.log_warning("Failed to instantiate DragManager - continuing without drag/drop", UnifiedLogger.Category.SYSTEM)
		else:
			UnifiedLogger.log_warning("DragManager script not available - continuing without drag/drop", UnifiedLogger.Category.SYSTEM)
	
	# Create player inventory UI (only if drag_manager is available)
	if drag_manager:
		player_inventory_ui = PlayerInventoryUI.new()
		player_inventory_ui.name = "PlayerInventoryUI"
		ui_layer.add_child(player_inventory_ui)
		player_inventory_ui.item_dropped.connect(_on_item_dropped)
	else:
		UnifiedLogger.log_warning("Skipping player inventory UI creation - DragManager not available", UnifiedLogger.Category.SYSTEM)
	
	# Create building inventory UI
	building_inventory_ui = BuildingInventoryUI.new()
	building_inventory_ui.name = "BuildingInventoryUI"
	ui_layer.add_child(building_inventory_ui)
	building_inventory_ui.item_dropped.connect(_on_item_dropped)
	
	# Create NPC inventory UI
	npc_inventory_ui = NPCInventoryUI.new()
	npc_inventory_ui.name = "NPCInventoryUI"
	ui_layer.add_child(npc_inventory_ui)
	npc_inventory_ui.item_dropped.connect(_on_item_dropped)
	
	# Create Character Menu UI
	character_menu_ui = CharacterMenuUI.new()
	character_menu_ui.name = "CharacterMenuUI"
	ui_layer.add_child(character_menu_ui)

	# Context menu (dropdown) — Step 1 integration_plan
	dropdown_menu_ui = DROPDOWN_MENU_UI_SCRIPT.new()
	dropdown_menu_ui.name = "DropdownMenuUI"
	ui_layer.add_child(dropdown_menu_ui)
	dropdown_menu_ui.option_selected.connect(_on_dropdown_option_selected)
	
	# Step 9: Combat HUD (Hostile, Break Follow) is added in _setup_combat_hud()
	
	# Build menu removed - building icons now integrated into building inventory UI
	
	# Connect drag manager for building placement
	if drag_manager:
		if drag_manager.drag_ended.is_connected(_on_drag_ended):
			_dbg("🔵 Main._ready(): drag_ended signal already connected")
		else:
			drag_manager.drag_ended.connect(_on_drag_ended)
			_dbg("🔵 Main._ready(): Connected drag_ended signal to _on_drag_ended")
	else:
		print("❌ Main._ready(): drag_manager is null, cannot connect signal")

func _setup_combat_hud() -> void:
	"""Step 4: HUD panel — FOLLOW | GUARD toggle, BREAK. Hostile = leader weapon equipped."""
	if not ui_layer:
		return
	var panel := Panel.new()
	panel.name = "CombatHUD"
	UITheme.apply_panel_style(panel)
	panel.mouse_filter = Control.MOUSE_FILTER_STOP
	var hud_w := 200
	var hud_h := 56
	panel.set_anchors_preset(Control.PRESET_BOTTOM_LEFT)
	panel.anchor_left = 0.0
	panel.anchor_top = 1.0
	panel.anchor_right = 0.0
	panel.anchor_bottom = 1.0
	panel.offset_left = 12
	panel.offset_top = -hud_h - 8
	panel.offset_right = 12 + hud_w
	panel.offset_bottom = -8
	panel.custom_minimum_size = Vector2(hud_w, hud_h)
	var box := HBoxContainer.new()
	box.add_theme_constant_override("separation", 8)
	box.set_anchors_preset(Control.PRESET_FULL_RECT)
	box.offset_left = 8
	box.offset_top = 8
	box.offset_right = -8
	box.offset_bottom = -8
	panel.add_child(box)
	var follow_btn := Button.new()
	follow_btn.name = "FollowBtn"
	follow_btn.text = "FOLLOW"
	follow_btn.toggle_mode = true
	follow_btn.button_pressed = (follow_guard_mode == "FOLLOW")
	follow_btn.pressed.connect(_on_follow_pressed)
	box.add_child(follow_btn)
	var guard_btn := Button.new()
	guard_btn.name = "GuardBtn"
	guard_btn.text = "GUARD"
	guard_btn.toggle_mode = true
	guard_btn.button_pressed = (follow_guard_mode == "GUARD")
	guard_btn.pressed.connect(_on_guard_pressed)
	box.add_child(guard_btn)
	var break_btn := Button.new()
	break_btn.name = "BreakFollow"
	break_btn.text = "BREAK"
	break_btn.pressed.connect(_break_follow_all)
	box.add_child(break_btn)
	ui_layer.add_child(panel)
	panel.z_index = 100
	combat_hud = panel
	_update_follow_guard_buttons()

func _update_follow_guard_buttons() -> void:
	if not combat_hud:
		return
	var follow_btn = combat_hud.find_child("FollowBtn", true, false)
	var guard_btn = combat_hud.find_child("GuardBtn", true, false)
	if follow_btn is Button:
		follow_btn.button_pressed = (follow_guard_mode == "FOLLOW")
	if guard_btn is Button:
		guard_btn.button_pressed = (follow_guard_mode == "GUARD")

func _on_follow_pressed() -> void:
	follow_guard_mode = "FOLLOW"
	_update_follow_guard_buttons()
	_apply_command_context_to_followers()

func _on_guard_pressed() -> void:
	follow_guard_mode = "GUARD"
	_update_follow_guard_buttons()
	_apply_command_context_to_followers()

func _apply_command_context_to_followers() -> void:
	"""Update command_context.mode and is_hostile for all cached followers."""
	var commander_id: int = EntityRegistry.get_id(player) if EntityRegistry and player else -1
	var is_hostile: bool = _player_has_weapon_equipped()
	for id in _follower_cache:
		var n = EntityRegistry.get_entity_node(id) if EntityRegistry else null
		if not n or not is_instance_valid(n):
			continue
		var ctx: Dictionary = n.get("command_context") if n.get("command_context") != null else {}
		ctx["commander_id"] = commander_id
		ctx["mode"] = follow_guard_mode
		ctx["is_hostile"] = is_hostile
		ctx["issued_at_time"] = Time.get_ticks_msec() / 1000.0
		n.set("command_context", ctx)
		if "command_context" in n:
			n.command_context = ctx
		n.set("is_hostile", is_hostile)
		if "agro_meter" in n and is_hostile:
			n.set("agro_meter", 70.0)
			n.agro_meter = 70.0
	if player:
		if follow_guard_mode == "GUARD" and _follower_cache.size() > 0:
			player.set_meta("formation_guard", true)  # Leader slower so clansmen protect center
		else:
			player.remove_meta("formation_guard")

func _player_has_weapon_equipped() -> bool:
	"""Step 4: Hostile = leader weapon equipped (right hand slot)."""
	if not player_inventory_ui or player_inventory_ui.hotbar_slots.size() <= player_inventory_ui.RIGHT_HAND_SLOT_INDEX:
		return false
	var slot = player_inventory_ui.hotbar_slots[player_inventory_ui.RIGHT_HAND_SLOT_INDEX]
	var item = slot.get("item_data") if slot else null
	if not item:
		return false
	var t = item.get("type") if item.get("type") != null else -1
	return t == ResourceData.ResourceType.AXE or t == ResourceData.ResourceType.PICK or t == ResourceData.ResourceType.WOOD

func _update_followers_hostile() -> void:
	"""Step 4: Derive is_hostile from player weapon; sustain 70 agro when hostile."""
	if not player:
		return
	var is_hostile: bool = _player_has_weapon_equipped()
	var commander_id: int = EntityRegistry.get_id(player) if EntityRegistry and player else -1
	for id in _follower_cache:
		var n = EntityRegistry.get_entity_node(id) if EntityRegistry else null
		if not n or not is_instance_valid(n):
			continue
		n.set("is_hostile", is_hostile)
		if "command_context" in n and n.get("command_context") != null:
			var ctx: Dictionary = n.command_context.duplicate()
			ctx["is_hostile"] = is_hostile
			ctx["commander_id"] = commander_id
			n.set("command_context", ctx)
			n.command_context = ctx
		if is_hostile:
			n.set("agro_meter", 70.0)
			if "agro_meter" in n:
				n.agro_meter = 70.0

func _is_npc_draggable(npc: Node) -> bool:
	"""Step 10: Caveman/clansman for follow/defend. Phase 4: Woman/sheep/goat for building occupation."""
	if not npc:
		return false
	var t: String = npc.get("npc_type") if npc.get("npc_type") != null else ""
	if t == "caveman" or t == "clansman":
		return true
	# Phase 4: occupation drag - woman when building has woman slots; sheep for Farm; goat for Dairy
	if _is_building_occupation_drag_allowed():
		var b = building_inventory_ui.building as BuildingBase
		if b.get_woman_slot_count() > 0 and t == "woman":
			return true
		if b.building_type == ResourceData.ResourceType.FARM and t == "sheep":
			return true
		if b.building_type == ResourceData.ResourceType.DAIRY_FARM and t == "goat":
			return true
	return false

func _npc_drag_show_preview() -> void:
	if not ui_layer or not npc_drag_source:
		return
	_npc_drag_hide_preview()
	var icon := TextureRect.new()
	icon.custom_minimum_size = Vector2(32, 32)
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	var tex: Texture2D = null
	# Phase 7: Use woman/sheep/goat icon for occupation drag
	if _is_building_occupation_drag_allowed():
		var t: String = npc_drag_source.get("npc_type") as String if npc_drag_source.get("npc_type") != null else ""
		if t == "woman":
			tex = AssetRegistry.get_woman_sprite()
		elif t == "sheep":
			tex = AssetRegistry.get_sheep_sprite()
		elif t == "goat":
			tex = AssetRegistry.get_goat_sprite()
	if not tex:
		tex = AssetRegistry.get_player_sprite()
	if tex:
		icon.texture = tex
	icon.position = get_viewport().get_mouse_position() + Vector2(16, 16)
	icon.z_index = 200
	ui_layer.add_child(icon)
	npc_drag_preview = icon

func _npc_drag_hide_preview() -> void:
	if npc_drag_preview and is_instance_valid(npc_drag_preview):
		npc_drag_preview.queue_free()
	npc_drag_preview = null

func _resolve_npc_drop_target() -> String:
	"""Step 10 + guide: 'player' | 'land_claim' | 'outside_land_claim' | '' (UI)."""
	var mp := get_viewport().get_mouse_position()
	if _is_mouse_over_ui(mp):
		return ""
	var world_pos := _get_world_mouse_position()
	if player and world_pos.distance_to(player.global_position) < 56.0:
		return "player"
	var claims := get_tree().get_nodes_in_group("land_claims")
	for c in claims:
		if not is_instance_valid(c):
			continue
		if not c.get("player_owned"):
			continue
		var r: float = c.get("radius") if c.get("radius") != null else 400.0
		if world_pos.distance_to(c.global_position) <= r:
			return "land_claim"
	return "outside_land_claim"

func _handle_npc_drag_release() -> void:
	var src = npc_drag_source
	_npc_drag_hide_preview()
	npc_drag_source = null
	npc_dragging = false
	npc_drag_hold_timer = 0.0
	if not src or not is_instance_valid(src):
		return
	# Phase 4: Map-to-slot drop - try drop on occupation slot before player/land_claim
	if building_inventory_ui and building_inventory_ui.visible and building_inventory_ui.building:
		var mp := get_viewport().get_mouse_position()
		var panel_rect := Rect2(building_inventory_ui.get_global_rect())
		if panel_rect.has_point(mp):
			if building_inventory_ui.try_drop_npc_from_map(mp, src):
				return
			UnifiedLogger.write_log_entry("Occupation drop fail (map→slot)", UnifiedLogger.Category.DRAG_DROP, UnifiedLogger.Level.DEBUG, {"npc_type": src.get("npc_type")})
	var where := _resolve_npc_drop_target()
	# Option B: Apply command to all selected, or just src if not in selection
	var targets: Array = []
	if src in selected_clansmen:
		for n in selected_clansmen:
			if is_instance_valid(n) and _is_npc_draggable(n):
				targets.append(n)
	else:
		targets.append(src)
	if where == "player":
		for n in targets:
			_set_ordered_follow(n)
	elif where == "land_claim":
		for n in targets:
			_clear_role_assignment(n)
	elif where == "outside_land_claim":
		var claim: LandClaim = _get_player_land_claim_any()
		if claim:
			for n in targets:
				_set_defend(n, claim)

func _screen_to_world(screen_pos: Vector2) -> Vector2:
	"""Convert screen position to world (camera) coordinates."""
	var cam = get_viewport().get_camera_2d()
	if not cam:
		return _get_world_mouse_position()
	var inv = cam.get_screen_transform().affine_inverse()
	return inv * screen_pos

func _selection_box_show() -> void:
	if not ui_layer:
		return
	_selection_box_hide()
	selection_box_visual = ColorRect.new()
	selection_box_visual.name = "SelectionBox"
	selection_box_visual.color = Color(0.3, 0.6, 1.0, 0.25)
	selection_box_visual.mouse_filter = Control.MOUSE_FILTER_IGNORE
	selection_box_visual.z_index = 100
	ui_layer.add_child(selection_box_visual)
	_selection_box_update_visual()

func _selection_box_update_visual() -> void:
	if not selection_box_visual or not is_instance_valid(selection_box_visual):
		return
	var r := Rect2(selection_box_start, Vector2.ZERO)
	r = r.expand(selection_box_end)
	if r.size.x < 4 or r.size.y < 4:
		r.size = Vector2(4, 4)
	selection_box_visual.position = r.position
	selection_box_visual.size = r.size

func _selection_box_hide() -> void:
	if selection_box_visual and is_instance_valid(selection_box_visual):
		selection_box_visual.queue_free()
	selection_box_visual = null

func _selection_box_complete() -> void:
	selection_box_active = false
	var r := Rect2(selection_box_start, Vector2.ZERO)
	r = r.expand(selection_box_end)
	if r.size.x < 4 or r.size.y < 4:
		_selection_box_hide()
		return
	var world_min := _screen_to_world(r.position)
	var world_max := _screen_to_world(r.position + r.size)
	var world_rect := Rect2(world_min, world_max - world_min)
	if world_rect.size.x < 0:
		world_rect.position.x += world_rect.size.x
		world_rect.size.x = -world_rect.size.x
	if world_rect.size.y < 0:
		world_rect.position.y += world_rect.size.y
		world_rect.size.y = -world_rect.size.y
	_selection_box_hide()
	_clear_selection()
	var claim: LandClaim = _get_player_land_claim_any()
	var player_clan: String = claim.clan_name if claim else ""
	if player_clan == "":
		_apply_selection_outline()
		return
	var npcs = get_tree().get_nodes_in_group("npcs")
	for n in npcs:
		if not is_instance_valid(n):
			continue
		var nt: String = n.get("npc_type") as String if n.get("npc_type") != null else ""
		if nt != "caveman" and nt != "clansman":
			continue
		if not world_rect.has_point(n.global_position):
			continue
		var npc_clan: String = ""
		if n.has_method("get_clan_name"):
			npc_clan = n.get_clan_name()
		else:
			var cn = n.get("clan_name")
			npc_clan = str(cn) if cn != null else ""
		if npc_clan == player_clan:
			selected_clansmen.append(n)
	_apply_selection_outline()

func _selection_box_cancel() -> void:
	selection_box_active = false
	_selection_box_hide()

func _clear_selection() -> void:
	selected_clansmen.clear()
	_apply_selection_outline()

func _apply_selection_outline() -> void:
	"""Outline selected clansmen; restore original color on others (preserves skin tone, sheep/goat tint)."""
	var npcs = get_tree().get_nodes_in_group("npcs")
	for n in npcs:
		if not is_instance_valid(n):
			continue
		var sp: Sprite2D = n.get_node_or_null("Sprite")
		if sp:
			if n in selected_clansmen:
				sp.modulate = Color(1.2, 1.2, 1.0)
			elif n.has_method("restore_sprite_modulate"):
				n.restore_sprite_modulate()
			else:
				sp.modulate = Color.WHITE

func _handle_inventory_toggle() -> void:
	if nearby_travois_ground:
		player_inventory_ui.toggle()
		if nearby_travois_ground.has_method("get") and nearby_travois_ground.get("inventory"):
			building_inventory_ui.setup_travois_ground(nearby_travois_ground)
		if player_inventory_ui.is_open:
			building_inventory_ui.show_inventory()
		else:
			building_inventory_ui.hide_inventory()
		if player and player.has_method("set_can_move"):
			player.set_can_move(not player_inventory_ui.is_open)
		return
	if nearby_building:
		# Toggle both inventories
		player_inventory_ui.toggle()
		
		# Setup building inventory with land claim or building reference
		if nearby_building is LandClaim:
			building_inventory_ui.setup_land_claim(nearby_building)
		elif nearby_building is CampfireScript:
			building_inventory_ui.setup_campfire(nearby_building)
		elif nearby_building is BuildingBase:
			# Regular building (Oven, Living Hut, etc.)
			var building_inventory: InventoryData = nearby_building.inventory
			if building_inventory:
				building_inventory_ui.setup_inventory(building_inventory, null, nearby_building)
				_dbg("🔵 Building inventory opened for %s" % ResourceData.get_resource_name(nearby_building.building_type))
		
		if player_inventory_ui.is_open:
			building_inventory_ui.show_inventory()
		else:
			building_inventory_ui.hide_inventory()
		
		# Prevent player movement when open
		if player and player.has_method("set_can_move"):
			player.set_can_move(not player_inventory_ui.is_open)
	elif nearby_corpse:
		# Toggle both inventories (player and corpse)
		player_inventory_ui.toggle()
		
		# Setup building inventory UI to show corpse inventory (reuse the same UI)
		var corpse_inventory: InventoryData = nearby_corpse.get("inventory")
		if corpse_inventory:
			var corpse_name = nearby_corpse.get("npc_name") if nearby_corpse else "unknown"
			var used_slots = 0
			if corpse_inventory.has_method("get_used_slots"):
				used_slots = corpse_inventory.get_used_slots()
			print("🔍 CORPSE LOOT: Found corpse inventory for %s (slots: %d/%d, items: %d)" % [
				corpse_name,
				used_slots,
				corpse_inventory.slot_count,
				used_slots
			])
			
			# Setup inventory with corpse NPC reference for title
			building_inventory_ui.setup_inventory(corpse_inventory, nearby_corpse)
			
			# Show inventory if player inventory is open
			if player_inventory_ui.is_open:
				building_inventory_ui.show_inventory()
			else:
				building_inventory_ui.hide_inventory()
		else:
			print("❌ CORPSE LOOT: No inventory found on corpse %s" % (nearby_corpse.get("npc_name") if nearby_corpse else "unknown"))
			# Hide building inventory if no corpse inventory
			building_inventory_ui.hide_inventory()
		
		# Prevent player movement when open
		if player and player.has_method("set_can_move"):
			player.set_can_move(not player_inventory_ui.is_open)
	else:
		# Just toggle player inventory
		player_inventory_ui.toggle()
		building_inventory_ui.hide_inventory()
		
		# Prevent player movement when open
		if player and player.has_method("set_can_move"):
			player.set_can_move(not player_inventory_ui.is_open)

# Build menu removed - building icons now integrated into building inventory UI
# Buildings can be built directly from the land claim inventory window

# Check if player is inside their own land claim radius (returns LandClaim or Campfire)
func _get_player_land_claim() -> Node2D:
	if not player:
		return null
	
	var player_pos := player.global_position
	var land_claims := get_tree().get_nodes_in_group("land_claims")
	
	for claim in land_claims:
		if not is_instance_valid(claim):
			continue
		# Accept both LandClaim and Campfire (Campfire has land_claims interface)
		var base := claim as Node2D
		if not base:
			continue
		var owned = base.get("player_owned")
		if not owned:
			continue
		var r: float = base.get("radius") if base.get("radius") != null else 400.0
		var distance := player_pos.distance_to(base.global_position)
		if distance <= r:
			return base
	
	return null

func _get_player_land_claim_any() -> LandClaim:
	"""First player-owned land claim (for Defend assignment). No 'player inside' check."""
	var land_claims := get_tree().get_nodes_in_group("land_claims")
	for claim in land_claims:
		if not is_instance_valid(claim):
			continue
		var lc := claim as LandClaim
		if lc and lc.player_owned:
			return lc
	return null

func _get_player_land_claim_at_position(world_pos: Vector2) -> LandClaim:
	"""Player-owned claim containing world_pos (for drag → Defend)."""
	var land_claims := get_tree().get_nodes_in_group("land_claims")
	for claim in land_claims:
		if not is_instance_valid(claim):
			continue
		var lc := claim as LandClaim
		if not lc or not lc.player_owned:
			continue
		var r: float = lc.get("radius") if lc.get("radius") != null else 400.0
		if world_pos.distance_to(lc.global_position) <= r:
			return lc
	return null

func _set_player_name(clan_name: String) -> void:
	"""Set player's name to clan name (player name = clan name)"""
	if not player:
		return
	
	if player.has_method("set_player_name"):
		player.set_player_name(clan_name)
		print("✓ Player name set to: %s" % clan_name)
	else:
		# Fallback: set meta directly
		player.set_meta("player_name", clan_name)
		print("✓ Player name (meta) set to: %s" % clan_name)

func _get_player_name_for_baby() -> String:
	"""Get player's name for use in baby lineage (returns clan name)"""
	if not player:
		return "Player"
	
	# Try to get player name using the method
	if player.has_method("get_player_name"):
		var pname: String = player.get_player_name()
		if pname != "":
			return pname
	
	# Fallback: try to get from meta
	if player.has_meta("player_name"):
		return player.get_meta("player_name", "Player")
	
	# Fallback: try to get clan name from land claim
	var player_land_claim = _get_player_land_claim()
	if player_land_claim:
		var clan_name = player_land_claim.get("clan_name") if player_land_claim else null
		if clan_name != null and clan_name is String and clan_name != "":
			return clan_name as String
	
	return "Player"

# Add building item to player inventory (called by BuildingInventoryUI)
func add_building_item_to_player_inventory(building_type: ResourceData.ResourceType) -> bool:
	if not player_inventory_ui:
		return false
	
	var inventory_data := player_inventory_ui.inventory_data
	if not inventory_data:
		return false
	
	# Find empty slot or stackable slot
	var building_item := {"type": building_type, "count": 1}
	
	# Try to add to inventory
	for i in range(inventory_data.slot_count):
		var slot_data = inventory_data.get_slot(i)
		if slot_data.is_empty():
			inventory_data.set_slot(i, building_item)
			player_inventory_ui._update_all_slots()
			return true
	
	# Try hotbar if inventory full
	var hotbar_data := player_inventory_ui.get_meta("hotbar_data", null) as InventoryData
	if hotbar_data:
		for i in range(hotbar_data.slot_count):
			var slot_data = hotbar_data.get_slot(i)
			if slot_data.is_empty():
				hotbar_data.set_slot(i, building_item)
				player_inventory_ui._update_hotbar_slots()
				return true
	
	print("Main: Player inventory full!")
	return false

func add_to_inventory(type: ResourceData.ResourceType, amount: int = 1) -> void:
	if player_inventory_ui:
		if ResourceData.is_food(type):
			player_inventory_ui.add_item_preferring_food_slots(type, amount)
		else:
			player_inventory_ui.add_item(type, amount)
		if player_inventory_ui.is_open:
			player_inventory_ui._update_all_slots()

func is_axe_equipped() -> bool:
	if not player_inventory_ui:
		return false
	var slot: Dictionary = player_inventory_ui.get_hotbar_slot(player_inventory_ui.RIGHT_HAND_SLOT_INDEX)
	return (slot.get("type", ResourceData.ResourceType.NONE) as ResourceData.ResourceType) == ResourceData.ResourceType.AXE

func is_pick_equipped() -> bool:
	if not player_inventory_ui:
		return false
	var slot: Dictionary = player_inventory_ui.get_hotbar_slot(player_inventory_ui.RIGHT_HAND_SLOT_INDEX)
	return (slot.get("type", ResourceData.ResourceType.NONE) as ResourceData.ResourceType) == ResourceData.ResourceType.PICK

func is_oldowan_equipped() -> bool:
	if not player_inventory_ui:
		return false
	var slot: Dictionary = player_inventory_ui.get_hotbar_slot(player_inventory_ui.RIGHT_HAND_SLOT_INDEX)
	return (slot.get("type", ResourceData.ResourceType.NONE) as ResourceData.ResourceType) == ResourceData.ResourceType.OLDOWAN

func has_tool_for_gather(resource_type: ResourceData.ResourceType) -> bool:
	match resource_type:
		ResourceData.ResourceType.WOOD:
			return is_axe_equipped() or is_oldowan_equipped()
		ResourceData.ResourceType.STONE:
			return is_pick_equipped() or is_oldowan_equipped()
		_:
			return true  # Berries, wheat, fiber, ground items — no tool

func is_butcher_tool_equipped() -> bool:
	if not player_inventory_ui:
		return false
	var slot: Dictionary = player_inventory_ui.get_hotbar_slot(player_inventory_ui.LEFT_HAND_SLOT_INDEX)
	var t: ResourceData.ResourceType = slot.get("type", ResourceData.ResourceType.NONE) as ResourceData.ResourceType
	return t == ResourceData.ResourceType.BLADE or t == ResourceData.ResourceType.OLDOWAN

func _on_item_dropped(_item_data: Dictionary, from_slot: InventorySlot, to_slot: InventorySlot) -> void:
	# Check if equipment changed (slot 1 / right hand)
	if to_slot.is_hotbar and to_slot.slot_index == player_inventory_ui.RIGHT_HAND_SLOT_INDEX:
		_update_equipment()
	elif from_slot.is_hotbar and from_slot.slot_index == player_inventory_ui.RIGHT_HAND_SLOT_INDEX:
		_update_equipment()

func _on_dropdown_option_selected(id: String) -> void:
	var target = dropdown_menu_ui.get_target() if dropdown_menu_ui else null
	if id == "info" and target != null and is_instance_valid(target):
		# INFO: NPCs → character menu; buildings/land claims → inventory
		if target is CampfireScript:
			if building_inventory_ui:
				building_inventory_ui.setup_campfire(target)
				building_inventory_ui.show_inventory()
				nearby_building = target
		elif target is LandClaim or target is BuildingBase:
			if building_inventory_ui:
				if target is LandClaim:
					building_inventory_ui.setup_land_claim(target)
					building_inventory_ui.show_inventory()
					nearby_building = target
				elif target is BuildingBase:
					var inv: InventoryData = target.inventory
					if inv:
						building_inventory_ui.setup_inventory(inv, null, target)
						building_inventory_ui.show_inventory()
						nearby_building = target
		else:
			# NPC: character menu
			if character_menu_ui:
				character_menu_ui.setup(target)
				character_menu_ui.show_menu()
				clicked_npc = target
		return
	if id == "follow" and target != null and is_instance_valid(target) and player != null:
		_set_ordered_follow(target)
		return
	if id == "assign_defend" and target != null and is_instance_valid(target):
		_set_defend(target)
		return
	if id == "assign_searching" and target != null and is_instance_valid(target):
		_set_searching(target)
		return
	if id == "hunt" and target != null and is_instance_valid(target):
		_player_attack_target(target)
		return
	if id == "work" and target != null and is_instance_valid(target):
		_clear_role_assignment(target)
		return
	if id == "call_defend" and target != null and is_instance_valid(target) and target is LandClaim:
		_call_defend_for_claim(target as LandClaim)
		return

func _set_ordered_follow(npc: Node) -> void:
	"""Step 6 / Step 4: Ordered follow with CommandContext; add to follower cache."""
	if not npc or not player or not is_instance_valid(npc):
		return
	if "is_herded" not in npc or "herder" not in npc or "follow_is_ordered" not in npc:
		return
	npc.set("is_herded", true)
	npc.set("herder", player)
	npc.set("follow_is_ordered", true)
	npc.set("herd_mentality_active", true)
	var commander_id: int = EntityRegistry.get_id(player) if EntityRegistry else -1
	var is_hostile: bool = _player_has_weapon_equipped()
	var ctx: Dictionary = {
		"commander_id": commander_id,
		"mode": follow_guard_mode,
		"is_hostile": is_hostile,
		"issued_at_time": Time.get_ticks_msec() / 1000.0
	}
	npc.set("command_context", ctx)
	if "command_context" in npc:
		npc.command_context = ctx
	npc.set("is_hostile", is_hostile)
	if is_hostile and "agro_meter" in npc:
		npc.set("agro_meter", 70.0)
		npc.agro_meter = 70.0
	var fid: int = EntityRegistry.get_id(npc) if EntityRegistry else -1
	if fid >= 0 and _follower_cache.find(fid) < 0:
		_follower_cache.append(fid)
	if follow_guard_mode == "GUARD" and player:
		player.set_meta("formation_guard", true)
	var fsm = npc.get_node_or_null("FSM")
	if fsm and fsm.has_method("change_state"):
		fsm.evaluation_timer = 0.0
		fsm.change_state("herd")

func _break_follow_all() -> void:
	"""Step 4: BREAK — clear ordered follow using follower cache; clear CommandContext."""
	if not player:
		return
	for id in _follower_cache:
		var n = EntityRegistry.get_entity_node(id) if EntityRegistry else null
		if not n or not is_instance_valid(n):
			continue
		if n.has_method("_clear_herd"):
			n._clear_herd()
		else:
			n.set("is_herded", false)
			n.set("herder", null)
			n.set("follow_is_ordered", false)
			n.set("herd_mentality_active", false)
		n.set("command_context", {})
		if "command_context" in n:
			n.command_context = {}
		if "is_hostile" in n:
			n.set("is_hostile", false)
		var fsm = n.get_node_or_null("FSM")
		if fsm:
			fsm.evaluation_timer = 0.0
			if fsm.has_method("_evaluate_states"):
				fsm._evaluate_states()
	_follower_cache.clear()
	if player:
		player.remove_meta("formation_guard")

func _remove_npc_from_all_player_claim_pools(npc: Node) -> void:
	"""Step 11: Remove NPC from defenders/searchers of all player-owned claims."""
	var claims := get_tree().get_nodes_in_group("land_claims")
	for c in claims:
		if not is_instance_valid(c) or not c is LandClaim:
			continue
		var lc: LandClaim = c as LandClaim
		if lc.player_owned:
			lc.remove_npc_from_pools(npc)

func _call_defend_for_claim(claim: LandClaim) -> void:
	"""Call all clansmen of this claim's clan back inside to defend (used when invaders approach)."""
	if not claim or not is_instance_valid(claim) or not claim.player_owned:
		return
	var clan_name: String = claim.clan_name if "clan_name" in claim else ""
	if clan_name == "":
		return
	var npcs = get_tree().get_nodes_in_group("npcs")
	var count: int = 0
	for n in npcs:
		if not is_instance_valid(n):
			continue
		var t = n.get("npc_type")
		if t != "clansman" and t != "caveman":
			continue
		var c: String = n.get_clan_name() if n.has_method("get_clan_name") else (str(n.get("clan_name")) if n.get("clan_name") != null else "")
		if c != clan_name:
			continue
		_set_defend(n, claim)
		count += 1
	if count > 0:
		claim.start_player_emergency_defend()
		print("DEFEND: Called %d clansmen back to land claim '%s' (emergency defend - release after %.0fs since last intrusion)" % [count, clan_name, 30.0])

func _set_defend(npc: Node, claim: LandClaim = null) -> void:
	"""Step 8: Set NPC to DEFEND player's land claim. Step 11: register in assigned_defenders. claim = specific (e.g. drag) or null → any."""
	if not npc or not is_instance_valid(npc):
		return
	if not claim:
		claim = _get_player_land_claim_any()
	if not claim:
		return
	_remove_npc_from_all_player_claim_pools(npc)
	claim.add_defender(npc)
	npc.set("defend_target", claim)
	npc.set("assigned_to_search", false)
	npc.set("search_home_claim", null)
	npc.set("is_herded", false)
	npc.set("herder", null)
	npc.set("follow_is_ordered", false)
	npc.set("herd_mentality_active", false)
	var fsm = npc.get_node_or_null("FSM")
	if fsm:
		fsm.evaluation_timer = 0.0
		if fsm.has_method("_evaluate_states"):
			fsm._evaluate_states()

func _set_searching(npc: Node) -> void:
	"""Step 11: Assign NPC to SEARCHING. search_home_claim = claim for ant-style loop."""
	if not npc or not is_instance_valid(npc):
		return
	var claim: LandClaim = _get_player_land_claim_any()
	if not claim:
		return
	_remove_npc_from_all_player_claim_pools(npc)
	claim.add_searcher(npc)
	npc.set("assigned_to_search", true)
	npc.set("search_home_claim", claim)
	npc.set("defend_target", null)
	npc.set("is_herded", false)
	npc.set("herder", null)
	npc.set("follow_is_ordered", false)
	npc.set("herd_mentality_active", false)
	var fsm = npc.get_node_or_null("FSM")
	if fsm:
		fsm.evaluation_timer = 0.0
		if fsm.has_method("_evaluate_states"):
			fsm._evaluate_states()

func _clear_role_assignment(npc: Node) -> void:
	"""Step 11: Clear DEFEND/SEARCHING override; NPC returns to auto (WORKING). Work also breaks follow (guide)."""
	if not npc or not is_instance_valid(npc):
		return
	_remove_npc_from_all_player_claim_pools(npc)
	npc.set("defend_target", null)
	npc.set("assigned_to_search", false)
	npc.set("search_home_claim", null)
	# Work clears role + breaks follow (authoritative guide)
	npc.set("is_herded", false)
	npc.set("herder", null)
	npc.set("follow_is_ordered", false)
	npc.set("herd_mentality_active", false)
	if "is_hostile" in npc:
		npc.set("is_hostile", false)
	var fsm = npc.get_node_or_null("FSM")
	if fsm:
		fsm.evaluation_timer = 0.0
		if fsm.has_method("_evaluate_states"):
			fsm._evaluate_states()

func _debug_spawn_test_npcs() -> void:
	"""F4: Spawn 1 caveman + 2 wild women near player (Follow/Defend testing)."""
	if not player or not world_objects:
		return
	var center := player.global_position

	# 1 caveman
	var a0 := randf() * TAU
	var d0 := randf_range(200.0, 400.0)
	var p0 := center + Vector2(cos(a0), sin(a0)) * d0
	var caveman: Node = NPC_SCENE.instantiate()
	if caveman:
		var name_c: String = NamingUtils.generate_caveman_name()
		caveman.set("npc_name", name_c)
		caveman.set("npc_type", "caveman")
		caveman.set("age", randi_range(13, 50))
		caveman.set("traits", ["solitary"])
		caveman.set("agro_meter", 0.0)
		caveman.set("spawn_time", Time.get_ticks_msec() / 1000.0)
		caveman.set("spawn_position", p0)
		var sp: Sprite2D = caveman.get_node_or_null("Sprite")
		if sp:
			var tex: Texture2D = AssetRegistry.get_player_sprite()
			if tex:
				sp.texture = tex
				sp.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
				sp.visible = true
		world_objects.add_child(caveman)
		caveman.global_position = p0
		var inv = caveman.get("inventory")
		if inv:
			inv.add_item(ResourceData.ResourceType.LANDCLAIM, 1)
			inv.add_item(ResourceData.ResourceType.WOOD, 1)  # Club (basic weapon)
		await get_tree().process_frame
		_equip_club_to_npc(caveman)
		caveman.visible = true
		print("✓ F4: Spawned Caveman %s at %s" % [name_c, p0])

	# 2 wild women
	for idx in 2:
		var a := randf() * TAU
		var d := randf_range(200.0, 400.0)
		var pos := center + Vector2(cos(a), sin(a)) * d
		var npc: Node = NPC_SCENE.instantiate()
		if not npc:
			continue
		var name_w: String = NamingUtils.generate_caveman_name()
		npc.set("npc_name", name_w)
		npc.set("npc_type", "woman")
		npc.set("traits", ["herd"])
		npc.set("age", randi_range(13, 50))
		var sprite: Sprite2D = npc.get_node_or_null("Sprite")
		if sprite:
			var tex: Texture2D = AssetRegistry.get_woman_sprite()
			if tex:
				sprite.texture = tex
				sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
				sprite.visible = true
				if npc.has_method("apply_sprite_offset_for_texture"):
					npc.apply_sprite_offset_for_texture()
		world_objects.add_child(npc)
		npc.global_position = pos
		npc.set("spawn_position", pos)
		npc.visible = true
		print("✓ F4: Spawned Wild Woman %s at %s" % [name_w, pos])

func _debug_set_defend_for_npc_under_cursor() -> void:
	"""F3 debug: set DEFEND for clansman/caveman under cursor. Step 7."""
	var resolved := _resolve_click_target()
	var target = resolved.get("target")
	var target_type: String = resolved.get("target_type", "none")
	if target_type != "npc" or not target or not is_instance_valid(target):
		return
	var t = target.get("npc_type")
	if t != "clansman" and t != "caveman":
		return
	_set_defend(target)
	var name_str: String = str(target.get("npc_name")) if target else "?"
	var claim: LandClaim = _get_player_land_claim_any()
	print("🛡️ DEFEND set for %s (claim: %s)" % [name_str, str(claim.name) if claim else "?"])

func _update_equipment() -> void:
	if not player_inventory_ui:
		return
	
	var first_slot: Dictionary = player_inventory_ui.get_hotbar_slot(player_inventory_ui.RIGHT_HAND_SLOT_INDEX)
	var second_slot: Dictionary = player_inventory_ui.get_hotbar_slot(player_inventory_ui.LEFT_HAND_SLOT_INDEX)
	var item_type: ResourceData.ResourceType = first_slot.get("type", ResourceData.ResourceType.NONE) as ResourceData.ResourceType
	if first_slot.is_empty() and second_slot.is_empty():
		if player and player.has_method("set_equipment"):
			player.set_equipment(ResourceData.ResourceType.NONE)
	elif item_type == ResourceData.ResourceType.TRAVOIS or (second_slot.get("type", ResourceData.ResourceType.NONE) as ResourceData.ResourceType) == ResourceData.ResourceType.TRAVOIS:
		if player and player.has_method("set_equipment"):
			player.set_equipment(ResourceData.ResourceType.TRAVOIS)
	else:
		if ResourceData.is_equipment(item_type):
			if player and player.has_method("set_equipment"):
				player.set_equipment(item_type)

func _on_drag_ended() -> void:
	_dbg("🔵 _on_drag_ended() called")
	# Check if we need to handle world placement (e.g., landclaim)
	# The drag_manager clears from_slot after emitting, so we need to check before that
	# Actually, the signal is emitted before clearing, so we can access it
	if not drag_manager:
		_dbg("🔵 _on_drag_ended: drag_manager is null")
		return
	
	# Store references before they're cleared
	var from_slot: InventorySlot = drag_manager.from_slot
	var dragged_item: Dictionary = drag_manager.dragged_item.duplicate()
	
	_dbg("🔵 _on_drag_ended: from_slot=%s, dragged_item=%s" % [from_slot, dragged_item])
	
	if not from_slot or dragged_item.is_empty():
		_dbg("🔵 _on_drag_ended: Missing from_slot or empty dragged_item, returning")
		return
	
	var item_type: ResourceData.ResourceType = dragged_item.get("type", -1) as ResourceData.ResourceType
	_dbg("🔵 _on_drag_ended: item_type=%s (%s)" % [item_type, ResourceData.get_resource_name(item_type)])
	
	# Check if it's a placeable building (land claim, campfire, or building)
	var is_placeable_building: bool = (
		item_type == ResourceData.ResourceType.LANDCLAIM or
		item_type == ResourceData.ResourceType.CAMPFIRE or
		item_type == ResourceData.ResourceType.TRAVOIS or
		item_type == ResourceData.ResourceType.LIVING_HUT or
		item_type == ResourceData.ResourceType.SUPPLY_HUT or
		item_type == ResourceData.ResourceType.SHRINE or
		item_type == ResourceData.ResourceType.FARM or
		item_type == ResourceData.ResourceType.DAIRY_FARM or
		item_type == ResourceData.ResourceType.OVEN
	)
	_dbg("🔵 _on_drag_ended: is_placeable_building=%s" % is_placeable_building)
	if not is_placeable_building:
		# Regular item (not a building) - check if dropped on world map (cancellation)
		var mouse_pos := get_viewport().get_mouse_position()
		var over_ui = _is_mouse_over_ui(mouse_pos)
		
		if not over_ui:
			# Dropped on world map (outside inventory slots) - cancel drag
			_dbg("🔵 _on_drag_ended: Regular item dropped on world map - cancelling drag")
			if drag_manager:
				drag_manager.end_drag(true)  # Restore item to source slot
			return
		else:
			# Dropped over UI - let inventory UI handle it
			return
	
	# For placeable buildings: always attempt placement (validation handles invalid positions).
	# Dropping over building-inventory UI was incorrectly cancelling placement.
	var mouse_pos := get_viewport().get_mouse_position()
	var over_ui = _is_mouse_over_ui(mouse_pos)
	if over_ui and not is_placeable_building:
		# Restore item to inventory since placement was cancelled (non-building item)
		if from_slot:
			from_slot.set_item(dragged_item)
			# Update slot display
			if from_slot.is_hotbar:
				player_inventory_ui._update_hotbar_slots()
			else:
				player_inventory_ui._update_all_slots()
		return
	
	# Get world position
	var world_pos := _get_world_mouse_position()
	
	# Show pie timer on slot icon, then place after duration
	var duration := _get_building_placement_duration(item_type)
	var overlay := ProgressPieOverlay.new()
	overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	from_slot.add_child(overlay)
	overlay.start_progress(duration)
	await overlay.progress_completed
	overlay.queue_free()
	
	if item_type == ResourceData.ResourceType.LANDCLAIM:
		_place_land_claim(world_pos, from_slot)
	elif item_type == ResourceData.ResourceType.CAMPFIRE:
		_place_campfire(world_pos, from_slot)
	elif item_type == ResourceData.ResourceType.TRAVOIS:
		_place_travois(world_pos, from_slot)
	else:
		_dbg("🔵 BUILDING PLACEMENT: from_slot valid: %s" % (from_slot != null))
		_place_building(world_pos, from_slot, item_type, dragged_item)

func _get_building_placement_duration(item_type: ResourceData.ResourceType) -> float:
	match item_type:
		ResourceData.ResourceType.LANDCLAIM: return LAND_CLAIM_PLACEMENT_DURATION
		ResourceData.ResourceType.CAMPFIRE: return CAMPFIRE_PLACEMENT_DURATION
		ResourceData.ResourceType.TRAVOIS: return TRAVOIS_PLACEMENT_DURATION
		_: return BUILDING_PLACEMENT_DURATION

func _try_place_building_from_inventory() -> void:
	# This function is now handled directly in _on_drag_ended()
	pass

func _is_any_inventory_open() -> bool:
	"""Check if any inventory UI is currently open - blocks world interactions"""
	if player_inventory_ui and player_inventory_ui.is_open:
		return true
	if building_inventory_ui and building_inventory_ui.visible:
		return true
	if npc_inventory_ui and npc_inventory_ui.visible:
		return true
	if character_menu_ui and character_menu_ui.is_open:
		return true
	return false

func _is_mouse_over_ui(mouse_pos: Vector2) -> bool:
	# Check if mouse is over any inventory UI panels (not just the root control)
	if player_inventory_ui:
		# Check inventory panel (only if open)
		if player_inventory_ui.is_open:
			var inventory_panel: Panel = player_inventory_ui.inventory_panel
			if inventory_panel and inventory_panel.visible:
				var inv_rect := Rect2(inventory_panel.get_global_rect())
				if inv_rect.has_point(mouse_pos):
					return true
		
		# Check hotbar panel - but only if mouse is actually over a slot
		# We want to allow world drops even if mouse is near hotbar
		# So we'll check individual slots instead
		var hotbar_panel: Panel = player_inventory_ui.hotbar_panel
		if hotbar_panel and hotbar_panel.visible:
			var hotbar_rect := Rect2(hotbar_panel.get_global_rect())
			# Only block if mouse is directly over hotbar slots area
			if hotbar_rect.has_point(mouse_pos):
				# Check if mouse is actually over a slot
				for slot in player_inventory_ui.hotbar_slots:
					var slot_rect := Rect2(slot.get_global_rect())
					if slot_rect.has_point(mouse_pos):
						return true
	
	if building_inventory_ui and building_inventory_ui.visible:
		var rect := Rect2(building_inventory_ui.get_global_rect())
		if rect.has_point(mouse_pos):
			return true
	
	# Check character menu UI (if open and visible)
	if character_menu_ui and character_menu_ui.is_open and character_menu_ui.visible:
		var rect := Rect2(character_menu_ui.get_global_rect())
		if rect.has_point(mouse_pos):
			return true
	
	# Step 9: Combat HUD (Hostile, Break Follow)
	if combat_hud and combat_hud.visible:
		var rect := Rect2(combat_hud.get_global_rect())
		if rect.has_point(mouse_pos):
			return true
	
	return false

func _get_world_mouse_position() -> Vector2:
	# Use viewport canvas transform (handles Camera2D zoom correctly)
	var vp := get_viewport()
	if not vp:
		return Vector2.ZERO
	var world_pos := vp.get_canvas_transform().affine_inverse() * vp.get_mouse_position()
	# Guard against NaN/Inf when zoom is 0 or transform is invalid
	if not is_finite(world_pos.x) or not is_finite(world_pos.y):
		return player.global_position if (player and is_instance_valid(player)) else Vector2.ZERO
	return world_pos

const CONTEXT_MENU_CLICK_RADIUS := 32.0
const HOVER_OUTLINE_RADIUS := 40.0  # Slightly larger for easier targeting
const HOVER_OUTLINE_COLOR := Color(1.0, 0.95, 0.88)  # White/tan outline
const HOVER_OUTLINE_SHADER := preload("res://assets/shaders/sprite_outline.gdshader")

var _hovered_entity: Node = null  # Entity with outline (NPC, ground item, resource)

func _get_npc_under_cursor() -> Node:
	"""Return NPC within 32px of world mouse, or null. Used for F2 context menu and Step 2 right-click. Excludes corpses."""
	if not camera or not is_instance_valid(camera):
		return null
	var world_pos := _get_world_mouse_position()
	var npcs := get_tree().get_nodes_in_group("npcs")
	for npc in npcs:
		if not is_instance_valid(npc):
			continue
		if npc.has_method("is_dead") and npc.is_dead():
			continue
		if npc.global_position.distance_to(world_pos) < CONTEXT_MENU_CLICK_RADIUS:
			return npc
	return null

func _get_enemy_building_under_cursor() -> Node:
	"""Return enemy building (not player-owned) within 32px of world mouse, or null."""
	if not camera or not is_instance_valid(camera):
		return null
	var world_pos := _get_world_mouse_position()
	var buildings := get_tree().get_nodes_in_group("buildings")
	for b in buildings:
		if not is_instance_valid(b):
			continue
		if b.get("player_owned"):
			continue
		if b.global_position.distance_to(world_pos) < CONTEXT_MENU_CLICK_RADIUS:
			return b
	# Also check land claims (large radius)
	var land_claims := get_tree().get_nodes_in_group("land_claims")
	for lc in land_claims:
		if not is_instance_valid(lc) or not (lc is LandClaim):
			continue
		if lc.player_owned:
			continue
		var claim: LandClaim = lc as LandClaim
		var rad: float = claim.radius if claim else 400.0
		if claim.global_position.distance_to(world_pos) <= rad:
			return lc
	return null

func _get_entity_under_cursor_for_outline() -> Node:
	"""Return closest NPC (incl. corpses), ground item, or resource under cursor for outline."""
	if not camera or not is_instance_valid(camera):
		return null
	var world_pos := _get_world_mouse_position()
	var best: Node = null
	var best_dist := HOVER_OUTLINE_RADIUS

	# Check NPCs (including corpses - for looting feedback)
	var npcs := get_tree().get_nodes_in_group("npcs")
	for npc in npcs:
		if not is_instance_valid(npc):
			continue
		var d: float = npc.global_position.distance_to(world_pos)
		if d < best_dist:
			best_dist = d
			best = npc

	# Check corpses (in case they're not in npcs)
	var corpses := get_tree().get_nodes_in_group("corpses")
	for c in corpses:
		if not is_instance_valid(c) or c == best:
			continue
		var d: float = c.global_position.distance_to(world_pos)
		if d < best_dist:
			best_dist = d
			best = c

	# Check ground items
	var ground_items := get_tree().get_nodes_in_group("ground_items")
	for item in ground_items:
		if not is_instance_valid(item) or item.get("is_picked_up"):
			continue
		var d: float = item.global_position.distance_to(world_pos)
		if d < best_dist:
			best_dist = d
			best = item

	# Check gatherable resources
	var resources := get_tree().get_nodes_in_group("resources")
	for res in resources:
		if not is_instance_valid(res) or res.is_in_group("ground_items"):
			continue
		if res.get("gathered"):
			continue
		var d: float = res.global_position.distance_to(world_pos)
		if d < best_dist:
			best_dist = d
			best = res

	return best

func _get_sprite_for_outline(node: Node) -> CanvasItem:
	"""Get the sprite to apply outline effect to."""
	if not node:
		return null
	if node is GroundItem:
		return node.get_node_or_null("Sprite")
	if node is GatherableResource:
		return node.get_node_or_null("Sprite")
	# NPC or corpse - has "Sprite" child
	return node.get_node_or_null("Sprite")

func _clear_entity_outline(node: Node) -> void:
	if not node or not is_instance_valid(node):
		return
	var spr := _get_sprite_for_outline(node)
	if not spr:
		return
	# Restore original material and modulate (skin tone for NPCs)
	if node.has_meta("pre_outline_material"):
		spr.material = node.get_meta("pre_outline_material")
		node.remove_meta("pre_outline_material")
	else:
		spr.material = null
	if node.has_meta("pre_outline_modulate"):
		spr.modulate = node.get_meta("pre_outline_modulate")
		node.remove_meta("pre_outline_modulate")

func _apply_entity_outline(node: Node) -> void:
	if not node or not is_instance_valid(node):
		return
	var spr := _get_sprite_for_outline(node)
	if not spr:
		return
	if not spr.texture:
		return
	# Store original material and modulate (preserve skin tone when clearing)
	if not node.has_meta("pre_outline_material"):
		node.set_meta("pre_outline_material", spr.material)
	if not node.has_meta("pre_outline_modulate"):
		node.set_meta("pre_outline_modulate", spr.modulate)
	var mat := ShaderMaterial.new()
	mat.shader = HOVER_OUTLINE_SHADER
	mat.set_shader_parameter("outline_color", HOVER_OUTLINE_COLOR)
	mat.set_shader_parameter("outline_width", 2.0)
	mat.set_shader_parameter("tint", spr.modulate)  # Apply skin tone in shader (avoids double-apply)
	spr.modulate = Color.WHITE  # Engine won't apply again; shader uses tint uniform
	spr.material = mat

func _is_building_occupation_drag_allowed() -> bool:
	"""Phase 4: Building inventory open with Farm/Dairy/Oven that has woman or animal slots."""
	if not building_inventory_ui or not building_inventory_ui.visible:
		return false
	var b = building_inventory_ui.building
	if not b or not is_instance_valid(b) or not (b is BuildingBase):
		return false
	var bt = b.building_type
	if bt != ResourceData.ResourceType.FARM and bt != ResourceData.ResourceType.DAIRY_FARM and bt != ResourceData.ResourceType.OVEN:
		return false
	var w_count: int = b.get_woman_slot_count()
	var a_count: int = b.get_animal_slot_count()
	return w_count > 0 or a_count > 0

func _is_npc_valid_for_open_building(npc: Node) -> bool:
	"""When building inventory is open with occupation slots, only outline NPCs valid for that building."""
	if not building_inventory_ui or not building_inventory_ui.visible or not building_inventory_ui.building:
		return true  # No filter when no building UI
	var b: Node = building_inventory_ui.building
	if not is_instance_valid(b) or not (b is BuildingBase):
		return true
	var bt = b.get("building_type")
	var npc_type: String = npc.get("npc_type") as String if npc.get("npc_type") != null else ""
	if bt == ResourceData.ResourceType.FARM:
		return npc_type == "woman" or npc_type == "sheep"
	if bt == ResourceData.ResourceType.DAIRY_FARM:
		return npc_type == "woman" or npc_type == "goat"
	if bt == ResourceData.ResourceType.OVEN:
		return npc_type == "woman"
	return true

func _update_hover_outline() -> void:
	if _hovered_entity and not is_instance_valid(_hovered_entity):
		_hovered_entity = null
	if _is_mouse_over_ui(get_viewport().get_mouse_position()):
		if _hovered_entity:
			_clear_entity_outline(_hovered_entity)
			_hovered_entity = null
		return
	var under := _get_entity_under_cursor_for_outline()
	# Phase 3: When building occupation UI is open, only outline NPCs valid for that building
	if under and (under is NPCBase or under.is_in_group("npcs")):
		if not _is_npc_valid_for_open_building(under):
			under = null
	if under != _hovered_entity:
		if _hovered_entity:
			_clear_entity_outline(_hovered_entity)
		_hovered_entity = under
		if _hovered_entity:
			_apply_entity_outline(_hovered_entity)

func _resolve_click_target() -> Dictionary:
	"""Resolve single target under world mouse. Priority: NPC > building > land_claim. Step 2."""
	var result := { "target": null, "target_type": "none" }
	if not camera or not is_instance_valid(camera):
		return result
	var world_pos := _get_world_mouse_position()

	var npc := _get_npc_under_cursor()
	if npc:
		result["target"] = npc
		result["target_type"] = "npc"
		return result

	var buildings := get_tree().get_nodes_in_group("buildings")
	for b in buildings:
		if not is_instance_valid(b):
			continue
		if b is LandClaim:
			continue
		if b is BuildingBase:
			if b.global_position.distance_to(world_pos) < CONTEXT_MENU_CLICK_RADIUS:
				result["target"] = b
				result["target_type"] = "building"
				return result

	# Campfires are in group "land_claims" but are not LandClaim — tight hit first (same ~32px as InteractionArea)
	var land_claims := get_tree().get_nodes_in_group("land_claims")
	for claim in land_claims:
		if not is_instance_valid(claim) or not (claim is CampfireScript):
			continue
		if claim.global_position.distance_to(world_pos) <= CONTEXT_MENU_CLICK_RADIUS:
			result["target"] = claim
			result["target_type"] = "campfire"
			return result
	for claim in land_claims:
		if not is_instance_valid(claim) or not (claim is LandClaim):
			continue
		var lc: LandClaim = claim as LandClaim
		var radius: float = lc.radius if lc else 400.0
		if lc.global_position.distance_to(world_pos) <= radius:
			result["target"] = claim
			result["target_type"] = "land_claim"
			return result

	return result

func _get_dropdown_options_for_target(target: Variant, target_type: String) -> Array:
	"""Options per target type. Enemy = Info only. Same-clan women = Info only (no Follow). Step 11: DEFEND, SEARCH, WORK."""
	var opts: Array[Dictionary] = []
	if target_type == "npc" and target is Node:
		var npc: Node = target as Node
		var t_val = npc.get("npc_type")
		var t: String = str(t_val) if t_val != null else ""
		var claim: LandClaim = _get_player_land_claim_any()
		var player_clan: String = claim.clan_name if claim else ""
		var npc_clan: String = ""
		if npc.has_method("get_clan_name"):
			npc_clan = npc.get_clan_name()
		else:
			var cn = npc.get("clan_name")
			npc_clan = str(cn) if cn != null else ""
		if player_clan == "" or npc_clan != player_clan:
			opts.append({ "id": "info", "label": "INFO" })
			return opts
		# Same clan: women get Info only (no Follow); others get Follow + type-specific
		if t != "woman":
			opts.append({ "id": "follow", "label": "FOLLOW" })
		if t == "sheep" or t == "goat":
			opts.append({ "id": "hunt", "label": "HUNT" })
		if t == "clansman" or t == "caveman":
			if claim:
				opts.append({ "id": "assign_defend", "label": "DEFEND" })
				opts.append({ "id": "assign_searching", "label": "SEARCH" })
				var dt = npc.get("defend_target")
				var searching: bool = npc.get("assigned_to_search") as bool if npc.get("assigned_to_search") != null else false
				if (dt != null and is_instance_valid(dt)) or searching:
					opts.append({ "id": "work", "label": "WORK" })
		opts.append({ "id": "info", "label": "INFO" })
	elif target_type == "building" or target_type == "land_claim":
		opts = [
			{ "id": "info", "label": "INFO" },
		]
		# Defend: call all clansmen back inside this land claim (for invaders)
		var claim := target as LandClaim
		if claim and claim.player_owned:
			opts.append({ "id": "call_defend", "label": "DEFEND" })
	elif target_type == "campfire":
		opts = [{ "id": "info", "label": "INFO" }]
	return opts

func _animate_building_placement(building: Node2D) -> void:
	# "Plop" animation: scale from 0 to 1.2, then back to 1.0
	# Also add a slight bounce effect
	if not building:
		print("WARNING: _animate_building_placement: building is null")
		return
	
	# Check if building is still valid and in the scene tree
	if not is_instance_valid(building):
		print("WARNING: _animate_building_placement: building is invalid")
		return
	
	if not building.is_inside_tree():
		print("WARNING: _animate_building_placement: building not in scene tree")
		return
	
	# Start at scale 0 (invisible)
	building.scale = Vector2.ZERO
	
	# Create tween for plop animation
	var tween := create_tween()
	if not tween:
		print("ERROR: Failed to create tween for building animation")
		return
	
	tween.set_ease(Tween.EASE_OUT)
	tween.set_trans(Tween.TRANS_BACK)
	
	# Scale up to 1.2 (overshoot) - check building is still valid
	if is_instance_valid(building) and building.is_inside_tree():
		tween.tween_property(building, "scale", Vector2(1.2, 1.2), 0.15)
		# Then settle to normal size
		tween.tween_property(building, "scale", Vector2.ONE, 0.1)
	else:
		print("WARNING: _animate_building_placement: building became invalid during tween setup")
		return
	
	# Optional: Add a slight rotation wobble for more impact
	var sprite: Sprite2D = building.get_node_or_null("Sprite")
	if sprite and is_instance_valid(sprite) and sprite.is_inside_tree():
		var rotation_tween := create_tween()
		if rotation_tween:
			rotation_tween.tween_property(sprite, "rotation", deg_to_rad(5), 0.1)
			rotation_tween.tween_property(sprite, "rotation", deg_to_rad(-5), 0.1)
			rotation_tween.tween_property(sprite, "rotation", 0.0, 0.1)
	else:
		# Sprite might not exist yet - that's okay, just skip rotation animation
		if not sprite:
			print("INFO: _animate_building_placement: No sprite found for building (this is okay)")

func _place_land_claim(world_pos: Vector2, from_slot: InventorySlot) -> void:
	_show_clan_name_dialog(world_pos, from_slot, "land_claim")

func _place_campfire(world_pos: Vector2, from_slot: InventorySlot) -> void:
	_show_clan_name_dialog(world_pos, from_slot, "campfire")

func _show_clan_name_dialog(world_pos: Vector2, from_slot: InventorySlot, place_type: String = "land_claim") -> void:
	# Prevent duplicate dialogs
	if active_clan_name_dialog and is_instance_valid(active_clan_name_dialog):
		print("⚠️ Clan name dialog already open, ignoring duplicate request")
		return
	
	var dialog_scene: PackedScene = load("res://ui/ClanNameDialog.tscn") as PackedScene
	if not dialog_scene:
		print("ERROR: Failed to load ClanNameDialog scene")
		return
	
	var dialog: AcceptDialog = dialog_scene.instantiate() as AcceptDialog
	if not dialog:
		print("ERROR: Failed to instantiate dialog")
		return
	
	# Store reference to prevent duplicates
	active_clan_name_dialog = dialog
	
	get_tree().root.add_child(dialog)
	
	# Connect signals
	if dialog.has_signal("name_confirmed"):
		dialog.name_confirmed.connect(_on_clan_name_dialog_confirmed.bind(world_pos, from_slot, place_type))
	if dialog.has_signal("dialog_cancelled"):
		dialog.dialog_cancelled.connect(_on_clan_name_cancelled.bind(from_slot))
	
	# Connect to dialog cleanup to clear reference
	dialog.tree_exiting.connect(func(): active_clan_name_dialog = null)
	
	dialog.visible = true
	dialog.popup_centered()

func _on_clan_name_dialog_confirmed(clan_name: String, world_pos: Vector2, from_slot: InventorySlot, place_type: String) -> void:
	if place_type == "campfire":
		_on_campfire_clan_name_confirmed(clan_name, world_pos, from_slot)
	else:
		_on_clan_name_confirmed(clan_name, world_pos, from_slot)

func _on_clan_name_confirmed(clan_name: String, world_pos: Vector2, from_slot: InventorySlot) -> void:
	# Clear dialog reference
	active_clan_name_dialog = null
	# Remove from inventory first (before placing building)
	if from_slot and drag_manager:
		var from_data: InventoryData = null
		if from_slot.is_hotbar:
			from_data = player_inventory_ui.get_meta("hotbar_data", null) as InventoryData
		else:
			from_data = player_inventory_ui.inventory_data
		
		if from_data:
			from_data.set_slot(from_slot.slot_index, {})
			from_slot.set_item({})
			# Update display
			if from_slot.is_hotbar:
				player_inventory_ui._update_hotbar_slots()
	else:
				player_inventory_ui._update_all_slots()
	
	# Cancel drag
	if drag_manager:
		drag_manager.cancel_drag()
	
	# Set player's name to clan name (player name = clan name)
	_set_player_name(clan_name)
	
	# Create land claim building FIRST (before eviction, so we can check for herded NPCs)
	var land_claim: LandClaim = LAND_CLAIM_SCENE.instantiate() as LandClaim
	if not land_claim:
		print("ERROR: Failed to instantiate land claim")
		return
	
	land_claim.global_position = world_pos
	land_claim.set_clan_name(clan_name)
	land_claim.player_owned = true  # Mark as player-owned
	
	# Create building inventory (will be set in land_claim._ready())
	# Use same settings as land_claim._ready(): 12 slots for testing, stacking enabled, high stack limit
	var building_inventory := InventoryData.new(12, true, 999999)
	land_claim.inventory = building_inventory
	
	# NORMAL CONFIGURATION: Land claim starts with empty inventory
	# (No resources pre-populated)
	
	var nearest_dist: float = INF
	for c in get_tree().get_nodes_in_group("land_claims"):
		if is_instance_valid(c):
			var d: float = world_pos.distance_to(c.global_position)
			if d < nearest_dist:
				nearest_dist = d
	world_objects.add_child(land_claim)
	_despawn_tallgrass_near(world_pos, land_claim.radius)
	_despawn_decorative_trees_near(world_pos, land_claim.radius)
	
	# Phase 3: Register land claim for cache tracking
	register_land_claim(land_claim)
	
	var pi_claim = get_node_or_null("/root/PlaytestInstrumentor")
	if pi_claim and pi_claim.is_enabled() and pi_claim.has_method("land_claim_placed"):
		pi_claim.land_claim_placed(clan_name, world_pos.x, world_pos.y, nearest_dist if nearest_dist < INF else -1.0, "player")
	
	# Add placement animation: "plop" effect
	_animate_building_placement(land_claim)
	
	land_claim.visible = true
	
	print("✓ Land claim placed at ", world_pos, " with name: ", clan_name)
	print("[MONITOR] Land claim placed at ", world_pos, " clan=", clan_name)
	print("  Building inventory created with 12 slots (stacking enabled)")
	OccupationDiagLogger.log("LAND_CLAIM_PLACED", {"clan": clan_name, "pos": "%.1f,%.1f" % [world_pos.x, world_pos.y]})
	
	# Log player land claim placement
	UnifiedLogger.log_system("Player interaction: placed_land_claim", {
		"action": "placed_land_claim",
		"clan": clan_name,
		"position": "%.1f,%.1f" % [world_pos.x, world_pos.y]
	})
	
	# Now handle NPCs inside the land claim:
	# 1. Women herded by player should join the clan (land claim placed around them)
	# 2. Cavemen should always be evicted (they can't join clans)
	# 3. Other NPCs that can't join should be evicted
	# Safe property access for radius
	var claim_radius_prop = land_claim.get("radius")
	var claim_radius: float = claim_radius_prop as float if claim_radius_prop != null else 400.0
	_handle_npcs_in_new_land_claim(world_pos, claim_radius, clan_name, true, null)  # true = player owned, no owner NPC

func _on_campfire_clan_name_confirmed(clan_name: String, world_pos: Vector2, from_slot: InventorySlot) -> void:
	active_clan_name_dialog = null
	if from_slot and drag_manager:
		var from_data: InventoryData = player_inventory_ui.get_meta("hotbar_data", null) as InventoryData if from_slot.is_hotbar else player_inventory_ui.inventory_data
		if from_data:
			from_data.set_slot(from_slot.slot_index, {})
			from_slot.set_item({})
			if from_slot.is_hotbar:
				player_inventory_ui._update_hotbar_slots()
			else:
				player_inventory_ui._update_all_slots()
	if drag_manager:
		drag_manager.cancel_drag()
	_set_player_name(clan_name)
	var campfire: CampfireScript = CAMPFIRE_SCENE.instantiate() as CampfireScript
	if not campfire:
		print("ERROR: Failed to instantiate campfire")
		return
	campfire.global_position = world_pos
	campfire.clan_name = clan_name
	campfire.player_owned = true
	campfire.inventory = InventoryData.new(6, true, 999)
	campfire.inventory.add_item(ResourceData.ResourceType.WOOD, 2)
	campfire.inventory.add_item(ResourceData.ResourceType.STONE, 2)
	world_objects.add_child(campfire)
	_despawn_tallgrass_near(world_pos, campfire.radius)
	_despawn_decorative_trees_near(world_pos, campfire.radius)
	register_land_claim(campfire)
	_animate_building_placement(campfire)
	campfire.visible = true
	var pi = get_node_or_null("/root/PlaytestInstrumentor")
	if pi and pi.has_method("campfire_placed"):
		pi.campfire_placed(clan_name, world_pos.x, world_pos.y)
	print("✓ Campfire placed at ", world_pos, " clan: ", clan_name)
	_handle_npcs_in_new_land_claim(world_pos, campfire.radius, clan_name, true, null)

func _place_travois(world_pos: Vector2, from_slot: InventorySlot) -> void:
	# Remove travois from player FIRST (2-handed: slots 0+1 when in hotbar)
	var hotbar_data = player_inventory_ui.get_meta("hotbar_data", null) as InventoryData
	var inv_data = player_inventory_ui.inventory_data
	if from_slot.is_hotbar and hotbar_data:
		hotbar_data.set_slot(0, {})
		hotbar_data.set_slot(1, {})
	elif from_slot and inv_data:
		inv_data.remove_item(ResourceData.ResourceType.TRAVOIS, 1)
	if drag_manager:
		drag_manager.cancel_drag()
	var tg = TRAVOIS_GROUND_SCENE.instantiate()
	if not tg:
		if from_slot.is_hotbar and hotbar_data:
			hotbar_data.add_item(ResourceData.ResourceType.TRAVOIS, 1)
		else:
			inv_data.add_item(ResourceData.ResourceType.TRAVOIS, 1)
		return
	tg.global_position = world_pos
	world_objects.add_child(tg)
	player_inventory_ui._update_all_slots()
	player_inventory_ui._update_hotbar_slots()
	print("✓ Travois placed at ", world_pos)

func _on_travois_pickup(tg: Node) -> void:
	if not tg or not is_instance_valid(tg) or not tg.has_method("is_empty") or not tg.is_empty():
		return
	var hotbar_data = player_inventory_ui.get_meta("hotbar_data", null) as InventoryData
	var inv_data = player_inventory_ui.inventory_data
	var slot0_free = hotbar_data.get_slot(0).is_empty()
	var slot1_free = hotbar_data.get_slot(1).is_empty()
	if not (slot0_free and slot1_free):
		if not inv_data.add_item(ResourceData.ResourceType.TRAVOIS, 1):
			print("Inventory full - cannot pickup travois")
			return
	else:
		hotbar_data.add_item(ResourceData.ResourceType.TRAVOIS, 1)
	if building_inventory_ui:
		building_inventory_ui.hide_inventory()
	tg.queue_free()
	nearby_travois_ground = null
	player_inventory_ui._update_all_slots()
	player_inventory_ui._update_hotbar_slots()
	print("✓ Picked up travois")

func _on_travois_ground_clicked(tg: Node) -> void:
	if building_inventory_ui and tg.has_method("get") and tg.get("inventory"):
		building_inventory_ui.setup_travois_ground(tg)
		building_inventory_ui.show_inventory()
		nearby_building = tg

func _on_building_clicked(building_ref: BuildingBase) -> void:
	if _is_any_inventory_open():
		return
	if not building_ref or not is_instance_valid(building_ref) or not building_inventory_ui:
		return
	if building_ref.inventory:
		building_inventory_ui.setup_inventory(building_ref.inventory, null, building_ref)
		building_inventory_ui.show_inventory()
		nearby_building = building_ref

func _on_campfire_clicked(campfire: CampfireScript) -> void:
	# Prefer right-click → INFO (_resolve_click_target "campfire"); kept for callers/tests.
	if building_inventory_ui and is_instance_valid(campfire):
		building_inventory_ui.setup_campfire(campfire)
		building_inventory_ui.show_inventory()
		nearby_building = campfire

func _on_campfire_upgrade_with_landclaim(campfire_ref: CampfireScript) -> void:
	"""Upgrade campfire using LANDCLAIM item (dropped in upgrade slot). Item already removed from player by drag."""
	_perform_campfire_to_land_claim(campfire_ref, false)

func _on_campfire_upgrade_confirmed(campfire_ref: CampfireScript) -> void:
	if not campfire_ref or not is_instance_valid(campfire_ref) or not campfire_ref.inventory:
		return
	var inv = campfire_ref.inventory
	if inv.get_count(ResourceData.ResourceType.CORDAGE) < 1 or inv.get_count(ResourceData.ResourceType.HIDE) < 1 or inv.get_count(ResourceData.ResourceType.WOOD) < 1 or inv.get_count(ResourceData.ResourceType.STONE) < 1:
		return
	inv.remove_item(ResourceData.ResourceType.CORDAGE, 1)
	inv.remove_item(ResourceData.ResourceType.HIDE, 1)
	inv.remove_item(ResourceData.ResourceType.WOOD, 1)
	inv.remove_item(ResourceData.ResourceType.STONE, 1)
	_perform_campfire_to_land_claim(campfire_ref, true)

func _perform_campfire_to_land_claim(campfire_ref: CampfireScript, _consumed_materials: bool) -> void:
	if not campfire_ref or not is_instance_valid(campfire_ref) or not campfire_ref.inventory:
		return
	var world_pos := campfire_ref.global_position
	var clan_name := campfire_ref.clan_name
	var new_land_claim: LandClaim = LAND_CLAIM_SCENE.instantiate() as LandClaim
	if not new_land_claim:
		return
	new_land_claim.global_position = world_pos
	new_land_claim.set_clan_name(clan_name)
	new_land_claim.player_owned = true
	new_land_claim.inventory = campfire_ref.inventory
	for npc in get_tree().get_nodes_in_group("npcs"):
		if not is_instance_valid(npc):
			continue
		if npc.get("defend_target") == campfire_ref:
			npc.set("defend_target", new_land_claim)
			new_land_claim.add_defender(npc)
		if npc.get("search_home_claim") == campfire_ref:
			npc.set("search_home_claim", new_land_claim)
			new_land_claim.add_searcher(npc)
		if campfire_ref.assigned_defenders.has(npc):
			new_land_claim.add_defender(npc)
			npc.set("defend_target", new_land_claim)
		if campfire_ref.assigned_searchers.has(npc):
			new_land_claim.add_searcher(npc)
			npc.set("search_home_claim", new_land_claim)
	for npc in get_tree().get_nodes_in_group("npcs"):
		if not is_instance_valid(npc):
			continue
		var npc_clan: String = npc.get("clan_name") if npc.get("clan_name") != null else ""
		if npc_clan == clan_name:
			npc.set("_cached_land_claim", null)
			npc.set("_cached_land_claim_clan", "")
	if building_inventory_ui and building_inventory_ui.campfire == campfire_ref:
		building_inventory_ui.hide_inventory()
		building_inventory_ui.campfire = null
	var pi = get_node_or_null("/root/PlaytestInstrumentor")
	if pi and pi.has_method("campfire_upgraded"):
		pi.campfire_upgraded(clan_name)
	campfire_ref.queue_free()
	world_objects.add_child(new_land_claim)
	_despawn_tallgrass_near(world_pos, new_land_claim.radius)
	_despawn_decorative_trees_near(world_pos, new_land_claim.radius)
	register_land_claim(new_land_claim)
	nearby_building = new_land_claim
	print("✓ Campfire upgraded to Land Claim at ", world_pos, " clan: ", clan_name)

var _last_placement_failure_message: String = ""  # Set when campfire rules fail; cleared after use

func _get_living_hut_count_near_claim(claim: Node2D) -> int:
	"""Count Living Huts within claim radius. Uses ClaimBuildingIndex for LandClaim, distance scan for Campfire."""
	var count := 0
	var claim_clan: String = claim.get("clan_name") if claim.get("clan_name") != null else ""
	var claim_pos: Vector2 = claim.global_position
	var claim_radius: float = claim.get("radius") if claim.get("radius") != null else 400.0
	var buildings: Array = []
	if claim is LandClaim and ClaimBuildingIndex:
		buildings = ClaimBuildingIndex.get_buildings_in_claim(claim)
	else:
		buildings = get_tree().get_nodes_in_group("buildings")
	for b in buildings:
		if not is_instance_valid(b) or not (b is BuildingBase):
			continue
		var building: BuildingBase = b as BuildingBase
		if building.building_type != ResourceData.ResourceType.LIVING_HUT:
			continue
		if building.clan_name != claim_clan:
			continue
		if building.global_position.distance_to(claim_pos) > claim_radius:
			continue
		count += 1
	return count

func _validate_building_placement(world_pos: Vector2, building_type: ResourceData.ResourceType) -> bool:
	# Calculate offset positions for safe zone checks (anchor point moved up 20px)
	var world_pos_offset: Vector2 = world_pos + BUILDING_SAFE_ZONE_OFFSET
	
	# Special handling for land claims — same min center-to-center as AI (BalanceConfig)
	if building_type == ResourceData.ResourceType.LANDCLAIM:
		var min_center: float = 1200.0
		if BalanceConfig and BalanceConfig.has_method("get_land_claim_min_center_distance"):
			min_center = BalanceConfig.get_land_claim_min_center_distance()
		var land_claims := get_tree().get_nodes_in_group("land_claims")
		for existing_claim in land_claims:
			if not is_instance_valid(existing_claim):
				continue
			
			var claim_anchor: Vector2 = existing_claim.global_position + BUILDING_SAFE_ZONE_OFFSET
			var claim_distance: float = world_pos_offset.distance_to(claim_anchor)
			if claim_distance < min_center:
				return false
		
		# Land claims can be placed anywhere (no radius restrictions for validation)
		return true
	
	# For regular buildings, check all placement rules
	# Check if player is inside their own land claim radius (use actual position, not offset)
	var player_land_claim := _get_player_land_claim()
	if not player_land_claim:
		return false
	
	# Campfire: only Living Huts, max 3 (use cast to avoid LandClaim/Campfire type error)
	var as_campfire := player_land_claim as Campfire
	if as_campfire:
		if building_type != ResourceData.ResourceType.LIVING_HUT:
			_last_placement_failure_message = "Only Living Huts at campfire. Upgrade to Land Claim for Oven, Farm, etc."
			return false
		if _get_living_hut_count_near_claim(player_land_claim) >= 3:
			_last_placement_failure_message = "Campfire can only support 3 Living Huts. Upgrade to Land Claim for more!"
			return false
	
	# Check if position is inside land claim radius (use actual position, not offset)
	var distance := world_pos.distance_to(player_land_claim.global_position)
	var radius_prop = player_land_claim.get("radius")
	var radius: float = radius_prop as float if radius_prop != null else 400.0
	if distance > radius:
		return false
	
	# Check if position is too close to land claim center (safety area for land claim, use offset)
	var land_claim_anchor: Vector2 = player_land_claim.global_position + BUILDING_SAFE_ZONE_OFFSET
	var land_claim_distance: float = world_pos_offset.distance_to(land_claim_anchor)
	if land_claim_distance < BUILDING_MIN_DISTANCE:
		return false
	
	# Check if position is too close to existing buildings (safety area, use offset)
	var buildings := get_tree().get_nodes_in_group("buildings")
	for existing_building in buildings:
		if not is_instance_valid(existing_building):
			continue
		
		# Skip land claims (they're in the buildings group but aren't actual buildings)
		if existing_building is LandClaim:
			continue
		
		# Check distance to existing building (using offset anchor point)
		var building_anchor: Vector2 = existing_building.global_position + BUILDING_SAFE_ZONE_OFFSET
		var building_distance: float = world_pos_offset.distance_to(building_anchor)
		if building_distance < BUILDING_MIN_DISTANCE:
			return false
	
	return true

func _validate_building_placement_near_claim_node(world_pos: Vector2, building_type: ResourceData.ResourceType, claim_node: Node, min_from_claim_center: float = -1.0) -> bool:
	"""Validate placement near any claim-like node (Campfire or LandClaim). Uses global_position and radius."""
	if not claim_node or not is_instance_valid(claim_node):
		return false
	var world_pos_offset: Vector2 = world_pos + BUILDING_SAFE_ZONE_OFFSET
	var distance := world_pos.distance_to(claim_node.global_position)
	var radius: float = claim_node.get("radius") if claim_node.get("radius") != null else 400.0
	if distance > radius:
		return false
	var claim_anchor: Vector2 = claim_node.global_position + BUILDING_SAFE_ZONE_OFFSET
	var min_dist: float = AI_BUILDING_MIN_FROM_CLAIM if min_from_claim_center >= 0 else BUILDING_MIN_DISTANCE
	if world_pos_offset.distance_to(claim_anchor) < min_dist:
		return false
	var buildings := get_tree().get_nodes_in_group("buildings")
	for existing_building in buildings:
		if not is_instance_valid(existing_building) or existing_building is LandClaim:
			continue
		var building_anchor: Vector2 = existing_building.global_position + BUILDING_SAFE_ZONE_OFFSET
		if world_pos_offset.distance_to(building_anchor) < BUILDING_MIN_DISTANCE:
			return false
	return true

func _validate_building_placement_for_claim(world_pos: Vector2, building_type: ResourceData.ResourceType, land_claim: LandClaim, min_from_claim_center: float = -1.0) -> bool:
	"""Same as _validate_building_placement but for an arbitrary land claim (e.g. AI). min_from_claim_center: use AI_BUILDING_MIN_FROM_CLAIM for AI to avoid placing on land claim."""
	if not land_claim or not is_instance_valid(land_claim):
		return false
	var world_pos_offset: Vector2 = world_pos + BUILDING_SAFE_ZONE_OFFSET
	var distance := world_pos.distance_to(land_claim.global_position)
	var radius: float = land_claim.radius if land_claim else 400.0
	if distance > radius:
		return false
	var land_claim_anchor: Vector2 = land_claim.global_position + BUILDING_SAFE_ZONE_OFFSET
	var min_dist: float = AI_BUILDING_MIN_FROM_CLAIM if min_from_claim_center >= 0 else BUILDING_MIN_DISTANCE
	if world_pos_offset.distance_to(land_claim_anchor) < min_dist:
		return false
	var buildings := get_tree().get_nodes_in_group("buildings")
	for existing_building in buildings:
		if not is_instance_valid(existing_building) or existing_building is LandClaim:
			continue
		var building_anchor: Vector2 = existing_building.global_position + BUILDING_SAFE_ZONE_OFFSET
		if world_pos_offset.distance_to(building_anchor) < BUILDING_MIN_DISTANCE:
			return false
	return true

func _place_ai_building(land_claim: LandClaim, building_type: ResourceData.ResourceType) -> bool:
	"""Place a building for an AI clan when milestone is met. Free (no cost). Returns true if placed."""
	if not land_claim or not is_instance_valid(land_claim) or not world_objects:
		return false
	var claim_center: Vector2 = land_claim.global_position
	var radius: float = land_claim.radius if land_claim else 400.0
	# Keep buildings in ring around claim - NOT on the land claim center (min 120px from center)
	var min_from_center: float = AI_BUILDING_MIN_FROM_CLAIM
	var max_dist: float = maxf(min_from_center + 10.0, radius - 60.0)
	var step_angle: float = 0.5
	var place_pos: Vector2 = Vector2.ZERO
	var r_start: int = int(min_from_center)
	var r_end: int = int(max_dist)
	for r in range(r_start, r_end, 70):
		var dist: float = clampf(float(r), min_from_center, max_dist)
		for k in range(20):
			var angle: float = k * step_angle + randf() * 0.2
			var cand: Vector2 = claim_center + Vector2(cos(angle * TAU), sin(angle * TAU)) * dist
			if _validate_building_placement_for_claim(cand, building_type, land_claim, AI_BUILDING_MIN_FROM_CLAIM):
				place_pos = cand
				break
		if place_pos != Vector2.ZERO:
			break
	if place_pos == Vector2.ZERO:
		return false
	var building: BuildingBase = BUILDING_SCENE.instantiate() as BuildingBase
	if not building:
		return false
	building.building_type = building_type
	building.clan_name = land_claim.clan_name
	building.player_owned = false
	building.global_position = place_pos
	world_objects.add_child(building)
	_despawn_tallgrass_near(place_pos, 150.0)
	_despawn_decorative_trees_near(place_pos, 150.0)
	building.visible = true
	_handle_building_placed(building, land_claim)
	print("🏠 Milestone: %s placed %s at %s" % [land_claim.clan_name, ResourceData.get_resource_name(building_type), place_pos])
	var pi = get_node_or_null("/root/PlaytestInstrumentor")
	if pi and pi.is_enabled() and pi.has_method("milestone_building_placed"):
		pi.milestone_building_placed(land_claim.clan_name, building_type, place_pos)
	return true

func _place_herder_hut(world_pos: Vector2, claim: Node, woman: Node) -> void:
	"""Place Living Hut for herder-delivered woman. No cost. Assigns woman to new hut. claim: Campfire or LandClaim."""
	if not claim or not is_instance_valid(claim) or not world_objects:
		return
	# Validate woman: alive and not already in hut
	if woman and is_instance_valid(woman) and OccupationSystem and OccupationSystem.get_workplace(woman) != null:
		woman = null  # Already assigned
	var place_pos: Vector2 = world_pos
	if not _validate_building_placement_near_claim_node(place_pos, ResourceData.ResourceType.LIVING_HUT, claim, AI_BUILDING_MIN_FROM_CLAIM):
		# Find valid position near herder
		var claim_center: Vector2 = claim.global_position
		var radius: float = claim.get("radius") if claim.get("radius") != null else 400.0
		var min_from_center: float = AI_BUILDING_MIN_FROM_CLAIM
		var max_dist: float = maxf(min_from_center + 10.0, radius - 60.0)
		place_pos = Vector2.ZERO
		for r in range(int(min_from_center), int(max_dist), 70):
			var dist: float = clampf(float(r), min_from_center, max_dist)
			for k in range(20):
				var angle: float = k * 0.5 + randf() * 0.2
				var cand: Vector2 = claim_center + Vector2(cos(angle * TAU), sin(angle * TAU)) * dist
				if _validate_building_placement_near_claim_node(cand, ResourceData.ResourceType.LIVING_HUT, claim, AI_BUILDING_MIN_FROM_CLAIM):
					place_pos = cand
					break
			if place_pos != Vector2.ZERO:
				break
		if place_pos == Vector2.ZERO:
			print("⚠️ Herder could not find valid position for Living Hut")
			return
	var building: BuildingBase = BUILDING_SCENE.instantiate() as BuildingBase
	if not building:
		return
	building.building_type = ResourceData.ResourceType.LIVING_HUT
	building.clan_name = claim.get("clan_name") if claim.get("clan_name") != null else ""
	building.player_owned = claim.get("player_owned") if claim.get("player_owned") != null else false
	building.global_position = place_pos
	world_objects.add_child(building)
	_despawn_tallgrass_near(place_pos, 150.0)
	_despawn_decorative_trees_near(place_pos, 150.0)
	building.visible = true
	_handle_building_placed(building, claim)
	if woman and is_instance_valid(woman) and OccupationSystem:
		OccupationSystem.force_assign(woman, building, 0, "woman")
	print("🏠 Herder placed Living Hut at %s for clan %s" % [place_pos, claim.get("clan_name") if claim.get("clan_name") != null else ""])

func _handle_building_placement_failure(message: String, from_slot: InventorySlot, original_item: Dictionary) -> void:
	_dbg("🔴 _handle_building_placement_failure: message=%s, from_slot=%s, original_item=%s" % [message, from_slot, original_item])
	
	# Show visual warning
	_show_placement_warning(message)
	
	# Cancel drag
	if drag_manager:
		_dbg("🔴 Cancelling drag...")
		drag_manager.cancel_drag()
	
	# Return item to inventory
	if from_slot:
		_dbg("🔴 from_slot is valid, original_item.is_empty()=%s" % original_item.is_empty())
		if not original_item.is_empty():
			_dbg("🔴 Restoring item to slot: %s" % original_item)
			from_slot.set_item(original_item)
			# Update slot display
			if from_slot.is_hotbar and player_inventory_ui:
				player_inventory_ui._update_hotbar_slots()
			elif player_inventory_ui:
				player_inventory_ui._update_all_slots()
			_dbg("🔴 Item restored to slot")
		else:
			_dbg("🔴 WARNING: original_item is empty, cannot restore!")
	else:
		_dbg("🔴 WARNING: from_slot is null, cannot restore item!")

func _show_placement_warning(message: String) -> void:
	# Create a temporary warning label
	if not ui_layer:
		return
	
	var warning_label := Label.new()
	warning_label.text = message
	warning_label.add_theme_color_override("font_color", Color.RED)
	warning_label.add_theme_color_override("font_outline_color", Color.BLACK)
	warning_label.add_theme_constant_override("outline_size", 4)
	warning_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	warning_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	
	# Position at center of screen (use anchors for proper centering)
	var viewport_size := get_viewport().get_visible_rect().size
	warning_label.set_anchors_preset(Control.PRESET_CENTER_TOP)
	warning_label.position = Vector2(0, viewport_size.y * 0.3)  # 30% from top
	warning_label.z_index = 1000  # Above everything
	
	ui_layer.add_child(warning_label)
	
	# Animate fade out and remove
	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(warning_label, "modulate:a", 0.0, 2.0)
	tween.tween_property(warning_label, "position:y", warning_label.position.y - 50.0, 2.0)
	tween.tween_callback(warning_label.queue_free).set_delay(2.0)

func _place_building(world_pos: Vector2, from_slot: InventorySlot, building_type: ResourceData.ResourceType, dragged_item_data: Dictionary = {}) -> void:
	_dbg("🔵 _place_building() called: type=%s, pos=%s, from_slot=%s, dragged_item_data=%s" % [ResourceData.get_resource_name(building_type), world_pos, from_slot, dragged_item_data])
	
	# Store original item data for restoration if placement fails
	# Use dragged_item_data if provided (from drag manager), otherwise try to get from slot
	var original_item: Dictionary = dragged_item_data if not dragged_item_data.is_empty() else {}
	if original_item.is_empty() and from_slot:
		original_item = from_slot.get_item() if from_slot.has_method("get_item") else {"type": building_type, "count": 1}
	
	# Fallback: create item dict from building_type if still empty
	if original_item.is_empty():
		original_item = {"type": building_type, "count": 1}
	
	_dbg("🔵 _place_building: original_item=%s" % original_item)
	
	# Validate placement first (reuse validation logic)
	_last_placement_failure_message = ""
	if not _validate_building_placement(world_pos, building_type):
		var msg: String = _last_placement_failure_message
		if msg.is_empty():
			var player_land_claim := _get_player_land_claim()
			if not player_land_claim:
				msg = "Cannot place building - not inside your land claim!"
			else:
				var distance := world_pos.distance_to(player_land_claim.global_position)
				var radius_prop = player_land_claim.get("radius")
				var radius: float = radius_prop as float if radius_prop != null else 400.0
				if distance > radius:
					msg = "Cannot place building - position outside land claim!"
				elif distance < BUILDING_MIN_DISTANCE:
					msg = "Cannot place building - too close to land claim center!"
				else:
					msg = "Cannot place building - too close to another building!"
		_handle_building_placement_failure(msg, from_slot, original_item)
		return
	
	# Validation passed - continue with placement
	var player_land_claim := _get_player_land_claim()
	_dbg("🔵 _place_building: player_land_claim = %s" % player_land_claim)
	
	if not player_land_claim:
		print("ERROR: _place_building: player_land_claim is null after validation passed!")
		_handle_building_placement_failure("Cannot place building - no land claim found!", from_slot, original_item)
		return
	
	_dbg("✅ _place_building: Validation passed, creating building...")
	
	# Remove item from inventory NOW (after validation passed)
	# This ensures item is consumed when building is successfully placed
	if from_slot and drag_manager:
		var from_data: InventoryData = null
		if from_slot.is_hotbar:
			from_data = player_inventory_ui.get_meta("hotbar_data", null) as InventoryData
		else:
			from_data = player_inventory_ui.inventory_data
		
		if from_data:
			from_data.set_slot(from_slot.slot_index, {})
			from_slot.set_item({})
			# Update display
			if from_slot.is_hotbar:
				player_inventory_ui._update_hotbar_slots()
			else:
				player_inventory_ui._update_all_slots()
	
	# Cancel drag (item is consumed)
	if drag_manager:
		drag_manager.cancel_drag()
	
	# Create actual building at world_pos
	var building: BuildingBase = null
	_dbg("🔵 _place_building: Instantiating building scene...")
	building = BUILDING_SCENE.instantiate() as BuildingBase
	if not building:
		print("ERROR: Failed to instantiate building")
		_handle_building_placement_failure("Failed to create building", from_slot, original_item)
		return
	
	# Note: Oven-specific setup is handled in building_base.gd's _ready() method
	# No need to swap scripts - building_base handles oven production component setup
	
	_dbg("🔵 _place_building: Building instantiated successfully")
	
	# Validate player_land_claim before accessing properties
	if not player_land_claim or not is_instance_valid(player_land_claim):
		print("ERROR: player_land_claim is null or invalid when placing building")
		building.queue_free()
		_handle_building_placement_failure("Land claim invalid", from_slot, original_item)
		return
	
	# Set properties BEFORE adding to scene (so _ready() gets correct values)
	_dbg("🔵 _place_building: Setting building properties...")
	
	# Set building_type first (safest property)
	# Note: oven.gd will set this again in _ready(), but that's fine
	_dbg("🔵 _place_building: Setting building_type...")
	building.building_type = building_type
	_dbg("🔵 _place_building: building_type set successfully")
	
	# Safe property access for clan_name
	_dbg("🔵 _place_building: Getting clan_name from land claim...")
	var claim_clan_name: String = ""
	if player_land_claim and is_instance_valid(player_land_claim):
		# Since LandClaim extends Node2D and has clan_name as @export property,
		# we can access it directly after casting
		if player_land_claim is LandClaim:
			var land_claim: LandClaim = player_land_claim as LandClaim
			if land_claim:
				claim_clan_name = land_claim.clan_name
				_dbg("🔵 _place_building: Got clan_name via direct property: %s" % claim_clan_name)
		else:
			# Fallback: try get() method (works for any property)
			var clan_name_prop = player_land_claim.get("clan_name")
			if clan_name_prop != null:
				claim_clan_name = str(clan_name_prop)
				_dbg("🔵 _place_building: Got clan_name via get(): %s" % claim_clan_name)
	
	# Default to empty string if we couldn't get it
	if claim_clan_name == "":
		_dbg("⚠️ _place_building: Could not get clan_name, using empty string")
		claim_clan_name = ""
	
	_dbg("🔵 _place_building: Setting clan_name=%s..." % claim_clan_name)
	building.clan_name = claim_clan_name
	_dbg("🔵 _place_building: clan_name set successfully")
	
	_dbg("🔵 _place_building: Setting player_owned=true...")
	building.player_owned = true
	_dbg("🔵 _place_building: player_owned set successfully")
	
	_dbg("🔵 _place_building: Setting global_position=%s..." % world_pos)
	building.global_position = world_pos
	_dbg("🔵 _place_building: global_position set successfully")
	
	_dbg("🔵 _place_building: All properties set - type=%s, clan=%s, pos=%s" % [
		ResourceData.get_resource_name(building_type),
		claim_clan_name,
		world_pos
	])
	
	# Validate land_claims_container before adding
	if not land_claims_container or not is_instance_valid(land_claims_container):
		print("ERROR: land_claims_container is null or invalid")
		building.queue_free()
		_handle_building_placement_failure("Cannot add building", from_slot, original_item)
		return
	
	# Add to land claims container (buildings and land claims in same container for now)
	# _ready() will be called automatically when added to scene tree
	_dbg("🔵 _place_building: Adding building to scene tree...")
	world_objects.add_child(building)
	_despawn_tallgrass_near(world_pos, 150.0)
	_despawn_decorative_trees_near(world_pos, 150.0)
	_dbg("🔵 _place_building: Building added to scene tree, _ready() should have been called")
	
	# Ensure building is visible
	building.visible = true
	
	# Add placement animation: "plop" effect (use call_deferred to ensure _ready() completed)
	# Note: call_deferred already ensures _ready() has completed
	call_deferred("_animate_building_placement", building)
	
	print("Building %s placed at %s (inside land claim: %s)" % [
		ResourceData.get_resource_name(building_type),
		world_pos,
		player_land_claim.clan_name
	])
	OccupationDiagLogger.log("BUILDING_PLACED", {
		"type": ResourceData.get_resource_name(building_type),
		"clan": player_land_claim.clan_name,
		"pos": "%.1f,%.1f" % [world_pos.x, world_pos.y]
	})
	# MONITOR: building occupation playtest
	if building_type == ResourceData.ResourceType.FARM:
		print("[MONITOR] Farm placed at ", world_pos, " clan=", player_land_claim.clan_name)
	elif building_type == ResourceData.ResourceType.DAIRY_FARM:
		print("[MONITOR] Dairy placed at ", world_pos, " clan=", player_land_claim.clan_name)
	
	# Handle special building effects (e.g., Living Hut increases baby pool capacity)
	_handle_building_placed(building, player_land_claim)
	
	# Store building reference in land claim (optional, for tracking)
	# Buildings are tracked in the buildings group
	
	# Log building placement
	UnifiedLogger.log_system("Player interaction: placed_building", {
		"action": "placed_building",
		"building_type": ResourceData.get_resource_name(building_type),
		"clan": player_land_claim.clan_name,
		"position": "%.1f,%.1f" % [world_pos.x, world_pos.y]
	})

func _handle_building_placed(building: BuildingBase, land_claim: Node) -> void:
	# Handle building-specific effects. land_claim can be LandClaim or Campfire.
	if not building or not is_instance_valid(building):
		print("WARNING: _handle_building_placed: building is null or invalid")
		return
	
	if not land_claim or not is_instance_valid(land_claim):
		print("WARNING: _handle_building_placed: land_claim is null or invalid")
		return
	
	# ClaimBuildingIndex only supports LandClaim; skip for Campfire
	if land_claim is LandClaim:
		ClaimBuildingIndex.register_building(building, land_claim)
	match building.building_type:
		ResourceData.ResourceType.LIVING_HUT:
			# Living Hut increases baby pool capacity by +5
			# DISABLED: Caps are disabled for now
			# if baby_pool_manager:
			# 	baby_pool_manager.on_living_hut_built(land_claim.clan_name)
			# 	var new_capacity = baby_pool_manager.get_capacity(land_claim.clan_name)
			# 	print("Living Hut placed! Baby pool capacity now: %d" % new_capacity)
			print("Living Hut placed! (Baby pool capacity increase disabled)")
		ResourceData.ResourceType.OVEN:
			# Oven requires a woman to operate - women will auto-occupy
			print("Oven placed! Women will auto-occupy when available.")
		_:
			pass  # Other buildings have no immediate effects

func _place_npc_land_claim(clan_name: String, world_pos: Vector2, npc: Node) -> void:
	# Place land claim for an NPC (caveman)
	# Create land claim building FIRST
	var land_claim: LandClaim = LAND_CLAIM_SCENE.instantiate() as LandClaim
	if not land_claim:
		print("ERROR: Failed to instantiate land claim for NPC")
		return
	
	land_claim.global_position = world_pos
	land_claim.set_clan_name(clan_name)
	land_claim.player_owned = false  # NPC-owned
	
	# Create building inventory (6 slots, stacking enabled, no stack limit for testing)
	# CRITICAL: Check if inventory already exists (from _ready()) before creating new one
	if not land_claim.inventory:
		var building_inventory := InventoryData.new(12, true, 999999)  # 12 slots for testing
		land_claim.inventory = building_inventory
		_dbg("🔵 MAIN._PLACE_NPC_LAND_CLAIM: Created NEW inventory for %s (inventory=%s)" % [clan_name, building_inventory])
	else:
		_dbg("🔵 MAIN._PLACE_NPC_LAND_CLAIM: Using EXISTING inventory for %s (inventory=%s, slot_count=%d)" % [clan_name, land_claim.inventory, land_claim.inventory.slot_count if land_claim.inventory else 0])
	
	var nearest_dist: float = INF
	for c in get_tree().get_nodes_in_group("land_claims"):
		if is_instance_valid(c):
			var d: float = world_pos.distance_to(c.global_position)
			if d < nearest_dist:
				nearest_dist = d
	world_objects.add_child(land_claim)
	_despawn_tallgrass_near(world_pos, land_claim.radius)
	_despawn_decorative_trees_near(world_pos, land_claim.radius)
	# Phase 3: Register land claim for cache tracking
	register_land_claim(land_claim)
	land_claim.visible = true
	var pi_npc_claim = get_node_or_null("/root/PlaytestInstrumentor")
	if pi_npc_claim and pi_npc_claim.is_enabled() and pi_npc_claim.has_method("land_claim_placed"):
		pi_npc_claim.land_claim_placed(clan_name, world_pos.x, world_pos.y, nearest_dist if nearest_dist < INF else -1.0, "ai")
	
	# Set NPC's clan name (CRITICAL: Use helper function + set ALL meta properties for maximum persistence)
	if npc:
		var old_clan: String = npc.clan_name
		
		# Use helper function if available (ensures proper syncing)
		if npc.has_method("set_clan_name"):
			npc.set_clan_name(clan_name, "main._place_npc_land_claim")
		else:
			# Fallback: direct assignment + meta
			npc.clan_name = clan_name
			npc.set_meta("clan_name", clan_name)
		
		# CRITICAL: Store clan_name in MULTIPLE places for maximum persistence
		npc.set_meta("clan_name", clan_name)  # Always set (even if helper was used)
		npc.set_meta("land_claim_clan_name", clan_name)  # Extra backup with different key
		if npc.get("npc_type") == "caveman":
			npc.set_meta("has_land_claim", true)  # Flag for quick checking
		
		# Also store NPC name on land claim for reverse lookup
		land_claim.owner_npc = npc
		land_claim.owner_npc_name = npc.get("npc_name") if npc else ""
		land_claim.set_meta("owner_npc_name", npc.get("npc_name") if npc else "")
		
		# Emit signal to notify states of clan_name change
		if npc.has_signal("clan_name_changed"):
			npc.emit_signal("clan_name_changed", old_clan, clan_name)
		
		# Verify assignment worked - check all sources
		var verify_clan: String = npc.clan_name if npc else ""
		var verify_meta: String = npc.get_meta("clan_name", "") if npc.has_meta("clan_name") else ""
		var verify_backup: String = npc.get_meta("land_claim_clan_name", "") if npc.has_meta("land_claim_clan_name") else ""
		
		if verify_clan != clan_name:
			push_error("FAILED to assign clan_name to %s: expected '%s', got '%s' (meta='%s', backup='%s')" % [npc.get("npc_name") if npc else "unknown", clan_name, verify_clan, verify_meta, verify_backup])
		else:
			print("✓ Verified: %s.clan_name = '%s' (meta='%s', backup='%s')" % [npc.get("npc_name") if npc else "unknown", verify_clan, verify_meta, verify_backup])
			# Also print BUILD_STATE META VERIFY format for consistency
			_dbg("🔵 MAIN META VERIFY: %s - meta('clan_name')='%s', meta('land_claim_clan_name')='%s', direct='%s'" % [npc.get("npc_name") if npc else "unknown", verify_meta, verify_backup, verify_clan])
			
			# TRACK: Store verification timestamp
			if npc:
				npc.set_meta("main_meta_verified_at", Time.get_ticks_msec())
				npc.set_meta("main_meta_verified_clan", clan_name)
				_dbg("🔵 MAIN TRACK: %s - Meta verified in main, tracking (clan='%s')" % [npc.get("npc_name"), clan_name])
	
	print("✓ NPC land claim placed at ", world_pos, " with name: ", clan_name)
	print("  Building inventory created with 6 slots (stacking enabled, no stack limit)")
	
	# Log NPC land claim placement (already logged in build_state, but log here too for consistency)
	if npc:
		var npc_name: String = npc.get("npc_name") if npc else "unknown"
		UnifiedLogger.log_npc("Land claim placed: %s placed claim '%s' at %s" % [npc_name, clan_name, world_pos], {
			"npc": npc_name,
			"clan": clan_name,
			"pos": "%.1f,%.1f" % [world_pos.x, world_pos.y]
		})
	
	# Log NPCs in radius (before they join clan) - will be logged again when they actually join
	
	# Now handle NPCs inside the land claim:
	# 1. Cavemen should always be evicted (they can't join other clans)
	# 2. NPCs herded by this caveman should join the clan
	# 3. Other NPCs that can't join should be evicted
	# Safe property access for radius
	var npc_claim_radius_prop = land_claim.get("radius")
	var npc_claim_radius: float = npc_claim_radius_prop as float if npc_claim_radius_prop != null else 400.0
	_handle_npcs_in_new_land_claim(world_pos, npc_claim_radius, clan_name, false, npc)  # false = NPC owned, pass the caveman who placed it

func _on_clan_name_cancelled(_from_slot: InventorySlot) -> void:
	# Clear dialog reference
	active_clan_name_dialog = null
	# Cancel drag, item stays in inventory
	if drag_manager:
		drag_manager.cancel_drag()

func _handle_npcs_in_new_land_claim(center: Vector2, radius: float, clan_name: String, is_player_owned: bool, _owner_npc: Node = null) -> void:
	# Handle NPCs when a new land claim is placed:
	# - For PLAYER-owned claims: NPCs herded by player join the player's clan
	# - For NPC-owned claims: ALL NPCs within radius join the caveman's clan (stealing behavior)
	# - Cavemen should always be evicted (they can't join clans)
	# owner_npc: The NPC (caveman) who placed the claim (for NPC-owned claims)
	
	if not world_objects:
		return
	
	for npc in get_tree().get_nodes_in_group("npcs"):
		if not is_instance_valid(npc):
			continue
		
		var npc_pos: Vector2 = npc.global_position
		var distance: float = npc_pos.distance_to(center)
		
		# Only process NPCs inside the land claim radius
		if distance > radius:
			continue
		
		var npc_type: String = npc.get("npc_type") if npc else ""
		var is_herded: bool = npc.get("is_herded") if npc else false
		var herder = npc.get("herder") if npc else null
		
		# Check if herder is valid before accessing
		var herder_valid: bool = is_instance_valid(herder)
		
		# Check if this NPC is herded by the player (for player-owned claims)
		var is_herded_by_player: bool = false
		if is_player_owned and is_herded and herder_valid:
			var player_nodes := get_tree().get_nodes_in_group("player")
			if player_nodes.size() > 0 and herder == player_nodes[0]:
				is_herded_by_player = true
		
		# CAVEMEN: Can enter land claims now - don't evict them
		# They can cross into land claims for gathering/resources
		if npc_type == "caveman":
			continue  # Cavemen can stay in land claims
		
		# For NPC-owned claims: NPCs do NOT auto-join when land claim is placed
		# They must be herded and brought into the land claim to join (handled by herd_state.gd)
		# This allows proper competition - NPCs must be actively herded to join
		if not is_player_owned:
			# NPCs that can join clans can stay in the land claim (they'll join when herded in)
			if npc.has_method("can_join_clan") and npc.can_join_clan():
				# Don't auto-join - let them stay wild so they can be herded later
				# They will join the clan when herded and brought into the land claim via herd_state.gd
				continue
			# NPCs that can't join are evicted
			continue
		
		# For PLAYER-owned claims: Auto-join wild NPCs OR herded NPCs
		# WOMEN: Never evict - they can always stay in land claims
		if npc_type == "woman":
			# Use get_clan_name() method to properly check clan (checks meta as backup)
			var npc_clan_check = ""
			if npc.has_method("get_clan_name"):
				npc_clan_check = npc.get_clan_name()
			else:
				npc_clan_check = npc.get("clan_name") if npc else ""
			var is_wild = (npc_clan_check == "" or npc_clan_check == null)
			
			# Auto-join wild women OR herded women to the clan
			# FIX: Wild women should auto-join when land claim is placed on them
			if is_wild or is_herded_by_player:
				# Use set_clan_name to ensure reproduction component is notified
				if npc.has_method("set_clan_name"):
					npc.set_clan_name(clan_name, "main._handle_npcs_in_new_land_claim")
				else:
					npc.set("clan_name", clan_name)
					# Also set meta as backup
					npc.set_meta("clan_name", clan_name)
					npc.set_meta("land_claim_clan_name", clan_name)
				
				var npc_name: String = npc.get("npc_name") if npc else "unknown"
				var reason = "land claim placed on them (wild)" if is_wild else "land claim placed around them while herded"
				print("NPC %s joined clan %s (%s)" % [npc_name, clan_name, reason])
				var main_pi = get_node_or_null("/root/PlaytestInstrumentor")
				if main_pi and main_pi.is_enabled() and main_pi.has_method("npc_joined_clan"):
					main_pi.npc_joined_clan(npc_name, clan_name, "woman", "placed_claim")
				OccupationDiagLogger.log("NPC_JOINED_CLAN", {"npc": npc_name, "type": "woman", "clan": clan_name, "reason": reason})
				
				# Release from herd mode AFTER joining clan (if was herded)
				if is_herded_by_player:
					npc.set("is_herded", false)
					npc.set("herder", null)
					print("NPC %s released from herd mode (now part of clan)" % npc_name)
			# If already in a clan, woman can stay (might be visiting)
			continue
		
		# For other NPCs that can join clans: Handle player-owned claims
		if npc.has_method("can_join_clan") and npc.can_join_clan():
			var npc_clan = npc.get("clan_name") if npc else ""
			var is_wild = (npc_clan == "" or npc_clan == null)
			
			# Auto-join wild NPCs OR herded NPCs to the clan
			if is_wild or is_herded_by_player:
				# Use helper function if available (ensures proper syncing)
				if npc.has_method("set_clan_name"):
					npc.set_clan_name(clan_name, "main._handle_npcs_in_new_land_claim")
				else:
					npc.set("clan_name", clan_name)
				
				var npc_name: String = npc.get("npc_name") if npc else "unknown"
				var reason = "land claim placed on them (wild)" if is_wild else "land claim placed around them while herded"
				print("NPC %s joined clan %s (%s)" % [npc_name, clan_name, reason])
				var main_pi2 = get_node_or_null("/root/PlaytestInstrumentor")
				if main_pi2 and main_pi2.is_enabled() and main_pi2.has_method("npc_joined_clan"):
					main_pi2.npc_joined_clan(npc_name, clan_name, npc_type, "placed_claim")
				OccupationDiagLogger.log("NPC_JOINED_CLAN", {"npc": npc_name, "type": npc_type, "clan": clan_name, "reason": reason})
				
				# Release from herd mode AFTER joining clan (if was herded)
				if is_herded_by_player:
					npc.set("is_herded", false)
					npc.set("herder", null)
			# Other NPCs already in a clan can stay (might be visiting)
			continue
		
		# Only evict NPCs that can't join clans (other than cavemen, which are already handled)
		_evict_npc_from_land_claim(npc, center, radius)

func _evict_npc_from_land_claim(npc: Node2D, center: Vector2, radius: float) -> void:
	# Evict a single NPC from a land claim area
	var npc_pos: Vector2 = npc.global_position
	var distance: float = npc_pos.distance_to(center)
	
	if distance > radius:
		return  # Already outside
	
	# Calculate direction away from center
	var direction: Vector2 = (npc_pos - center)
	if direction.length() < 0.1:
		# NPC is exactly at center, pick random direction
		var angle := randf() * TAU
		direction = Vector2(cos(angle), sin(angle))
	else:
		direction = direction.normalized()
	
	# Move NPC to a safe position outside the radius
	var safe_distance: float = radius + 50.0
	var new_pos: Vector2 = center + direction * safe_distance
	npc.global_position = new_pos
	
	# Reset their wander target to be outside
	if npc.steering_agent:
		npc.steering_agent.wander_center = new_pos
		npc.steering_agent.wander_target = new_pos + direction * 100.0
	
	print("Evicted NPC %s from land claim area" % npc.npc_name)

func _evict_npcs_from_land_claim_area(center: Vector2, radius: float) -> void:
	# Legacy function - kept for compatibility but now uses new logic
	# This function is deprecated - use _handle_npcs_in_new_land_claim instead
	# Force all NPCs inside the land claim area to move outside
	var npcs := get_tree().get_nodes_in_group("npcs")
	
	for npc in npcs:
		if not is_instance_valid(npc):
			continue
		
		var npc_pos: Vector2 = npc.global_position
		var distance: float = npc_pos.distance_to(center)
		
		if distance < radius:
			# NPC is inside the land claim area
			# Get the land claim if it exists (for checking permissions and joining clan)
			var land_claims := get_tree().get_nodes_in_group("land_claims")
			var nearest_claim: Node2D = null
			var nearest_distance: float = INF
			for claim in land_claims:
				if not is_instance_valid(claim):
					continue
				var claim_pos: Vector2 = claim.global_position
				var claim_dist: float = npc_pos.distance_to(claim_pos)
				if claim_dist < nearest_distance:
					nearest_distance = claim_dist
					nearest_claim = claim
			
			# If NPC is herded and there's a land claim, join the clan (if they can)
			# Only women and herdable animals can join clans (cavemen cannot)
			if npc.is_herded and nearest_claim:
				if npc.can_join_clan():
					# Get the clan name from the land claim
					var claim_clan: String = ""
					var clan_name_prop = nearest_claim.get("clan_name")
					if clan_name_prop != null:
						claim_clan = clan_name_prop as String
					
					# Join the clan FIRST (before releasing herd mode)
					if claim_clan != "" and npc.get("clan_name") != claim_clan:
						npc.clan_name = claim_clan
						print("NPC %s joined clan %s (land claim created around them)" % [npc.get("npc_name"), claim_clan])
					
					# Phase 3: Use _clear_herd to keep herded_count in sync
					if npc.has_method("_clear_herd"):
						npc._clear_herd()
					else:
						npc.is_herded = false
						npc.herder = null
					print("NPC %s released from herd mode (land claim created around them)" % npc.get("npc_name"))
				else:
					# Cavemen cannot join clans - just release from herd mode
					# They will be evicted since they can't enter
					# Phase 3: Use _clear_herd to keep herded_count in sync
					if npc.has_method("_clear_herd"):
						npc._clear_herd()
					else:
						npc.is_herded = false
						npc.herder = null
					print("NPC %s (caveman) cannot join clan - released from herd mode" % npc.get("npc_name"))
			
			# Check if NPC is now part of the clan (after joining above)
			var npc_clan: String = str(npc.get("clan_name")) if npc else ""
			var claim_clan_check: String = ""
			if nearest_claim:
				var clan_name_prop = nearest_claim.get("clan_name")
				if clan_name_prop != null:
					claim_clan_check = clan_name_prop as String
			
			# Only evict if they're not part of the clan and can't enter
			# CAVEMEN CAN ENTER LAND CLAIMS - don't evict them
			var npc_type_check: String = npc.get("npc_type") if npc else ""
			if npc_type_check == "caveman":
				# Cavemen can enter land claims - don't evict
				continue
			
			if nearest_claim and npc_clan != claim_clan_check and not npc.can_enter_land_claim(nearest_claim):
				# Calculate direction away from center
				var direction: Vector2 = (npc_pos - center)
				if direction.length() < 0.1:
					# NPC is exactly at center, pick random direction
					var angle := randf() * TAU
					direction = Vector2(cos(angle), sin(angle))
				else:
					direction = direction.normalized()
				
				# Move NPC to a safe position outside the radius
				var safe_distance: float = radius + 50.0
				var new_pos: Vector2 = center + direction * safe_distance
				npc.global_position = new_pos
				
				# Reset their wander target to be outside
				if npc.steering_agent:
					npc.steering_agent.wander_center = new_pos
					npc.steering_agent.wander_target = new_pos + direction * 100.0
				
				print("Evicted NPC %s from land claim area" % npc.npc_name)

func _setup_npcs() -> void:
	# NPCs and grass add directly to world_objects (YSort) for proper depth sorting
	npcs_container = world_objects  # Alias for code that references it
	decorations_container = world_objects  # Alias for grass spawn check
	
	# Initialize minigame: spawn 3 cavemen + 6 women (no sheep/goats)
	# Spawn NPCs first, then spawn resources randomly across map
	await _initialize_minigame()
	# After NPCs are spawned, spawn resources randomly across the map
	await get_tree().process_frame  # Wait a frame for NPCs to be fully initialized
	_spawn_initial_resources()
	_spawn_tallgrass()
	_spawn_decorative_trees()

# TASK SYSTEM TEST: Set up ideal test environment
func _setup_task_system_test_environment() -> void:
	print("=== TASK SYSTEM TEST: Setting up ideal test environment ===")
	
	if not player:
		print("ERROR: Player is null, cannot set up test environment")
		return
	
	var center_pos := player.global_position
	var test_clan_name := "Test"
	
	# 1. Create land claim named "Test" east of player
	var land_claim_pos := center_pos + Vector2(200, 0)  # 200px east
	var land_claim: LandClaim = LAND_CLAIM_SCENE.instantiate() as LandClaim
	if not land_claim:
		print("ERROR: Failed to instantiate land claim for test environment")
		return
	
	land_claim.global_position = land_claim_pos
	land_claim.set_clan_name(test_clan_name)
	land_claim.player_owned = true
	
	# Create inventory and add resources
	var building_inventory := InventoryData.new(12, true, 999999)  # 12 slots for testing
	land_claim.inventory = building_inventory
	
	# DEBUG: Verify inventory before adding
	_dbg("DEBUG setup: Inventory created, slot_count=%d, adding 20 Wood + 20 Grain" % building_inventory.slot_count)
	
	var wood_added = building_inventory.add_item(ResourceData.ResourceType.WOOD, 20)
	var grain_added = building_inventory.add_item(ResourceData.ResourceType.GRAIN, 20)
	
	# DEBUG: Verify items were added
	var wood_count = building_inventory.get_count(ResourceData.ResourceType.WOOD)
	var grain_count = building_inventory.get_count(ResourceData.ResourceType.GRAIN)
	_dbg("DEBUG setup: Items added - Wood: add_item()=%s, count=%d | Grain: add_item()=%s, count=%d" % [wood_added, wood_count, grain_added, grain_count])
	
	# DEBUG: Verify inventory on land claim after assignment
	if land_claim.inventory:
		var claim_wood = land_claim.inventory.get_count(ResourceData.ResourceType.WOOD)
		var claim_grain = land_claim.inventory.get_count(ResourceData.ResourceType.GRAIN)
		_dbg("DEBUG setup: Land claim inventory after assignment - Wood: %d, Grain: %d" % [claim_wood, claim_grain])
	
	world_objects.add_child(land_claim)
	_despawn_tallgrass_near(land_claim_pos, land_claim.radius)
	_despawn_decorative_trees_near(land_claim_pos, land_claim.radius)
	# Phase 3: Register land claim for cache tracking
	register_land_claim(land_claim)
	land_claim.visible = true
	
	# DEBUG: Final verification after adding to tree
	await get_tree().process_frame  # Wait a frame for everything to initialize
	if land_claim.inventory:
		var final_wood = land_claim.inventory.get_count(ResourceData.ResourceType.WOOD)
		var final_grain = land_claim.inventory.get_count(ResourceData.ResourceType.GRAIN)
		_dbg("DEBUG setup: Final check after tree add - Wood: %d, Grain: %d" % [final_wood, final_grain])
	
	print("✓ Created land claim '%s' at %s with 20 Wood + 20 Grain" % [test_clan_name, land_claim_pos])
	
	# 2. Place 4 ovens near the land claim (to test if all 4 women will occupy them)
	var oven_offsets: Array[Vector2] = [
		Vector2(150, -100),   # North-east of land claim
		Vector2(150, 100),    # South-east of land claim
		Vector2(150, -200),   # Further north-east
		Vector2(150, 200)     # Further south-east
	]
	
	for i in range(4):
		var oven_pos: Vector2 = land_claim_pos + oven_offsets[i]
		var building: BuildingBase = BUILDING_SCENE.instantiate() as BuildingBase
		if not building:
			print("ERROR: Failed to instantiate oven %d" % (i + 1))
			continue
		
		building.building_type = ResourceData.ResourceType.OVEN
		building.clan_name = test_clan_name
		building.player_owned = true
		building.global_position = oven_pos
		if building.has_method("set_active"):
			building.set_active(true)  # Optimal: ovens on so women can occupy/transport immediately
		world_objects.add_child(building)
		_despawn_tallgrass_near(oven_pos, 150.0)
		_despawn_decorative_trees_near(oven_pos, 150.0)
		building.visible = true
		ClaimBuildingIndex.register_building(building, land_claim)
		print("✓ Placed oven %d at %s (active)" % [i + 1, oven_pos])
	
	# Wait a frame for buildings to initialize
	await get_tree().process_frame
	
	# 3. Spawn 2 women in Test clan (for woman transport/occupation test)
	var woman_offsets: Array[Vector2] = [
		Vector2(-50, -80),
		Vector2(-50, 80),
	]
	for i in range(2):
		var woman_pos: Vector2 = land_claim_pos + woman_offsets[i]
		var npc: Node = NPC_SCENE.instantiate()
		if not npc:
			continue
		var npc_name: String = NamingUtils.generate_caveman_name()
		npc.set("npc_name", npc_name)
		npc.set("npc_type", "woman")
		npc.set("traits", ["herd"])
		npc.set("age", randi_range(13, 50))
		npc.set("clan_name", test_clan_name)
		var sprite: Sprite2D = npc.get_node_or_null("Sprite")
		if sprite:
			var texture: Texture2D = AssetRegistry.get_woman_sprite()
			if texture:
				sprite.texture = texture
				sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
				sprite.visible = true
				if npc.has_method("apply_sprite_offset_for_texture"):
					npc.apply_sprite_offset_for_texture()
		world_objects.add_child(npc)
		npc.global_position = woman_pos
		npc.set("spawn_position", woman_pos)
		await get_tree().process_frame
		var stats: Node = npc.get_node_or_null("Stats")
		if stats and stats.has_method("set_stat"):
			stats.set_stat("agility", 9.0)
		elif stats:
			stats.agility = 9.0
		npc.visible = true
		print("✓ Created Woman: %s at %s (clan: %s)" % [npc_name, woman_pos, test_clan_name])
	
	# No women respawn in test mode - keep exactly 2 women for predictable testing
	# _start_women_respawn_system()  # DISABLED for woman-test
	
	print("=== TASK SYSTEM TEST: Test environment setup complete ===")
	print("  → Walk east to the land claim. 2 women will move wood/grain to ovens, produce bread, and deliver to claim.")

func _setup_agro_combat_test_environment() -> void:
	"""Test process for overhaul combat/agro: 2 land claims, 2 clans of 10 (1 leader + 9 in GUARD mode). Clansmen stay tight around the slower leader; leaders move at the other clan; raiding parties meet head-on for melee."""
	print("=== AGRO/COMBAT TEST (overhaul validation): 2 clans × 10, GUARD mode — clansmen tight around leader → meet head-on → melee ===")
	_agro_combat_test_leaders.clear()
	_agro_combat_test_claims.clear()

	if not player or not world_objects:
		print("ERROR: Player or world_objects is null")
		return

	var center_pos := player.global_position
	const CLAIM_DISTANCE := 1000.0  # ~2000px apart – RTS-style longer approach, less clumping at spawn
	var claim_a_pos := center_pos + Vector2(-CLAIM_DISTANCE, 0)
	var claim_b_pos := center_pos + Vector2(CLAIM_DISTANCE, 0)

	# 1. Land claim ClanA (west)
	var claim_a: LandClaim = LAND_CLAIM_SCENE.instantiate() as LandClaim
	if not claim_a:
		print("ERROR: Failed to instantiate land claim A")
		return
	claim_a.global_position = claim_a_pos
	claim_a.set_clan_name("ClanA")
	claim_a.player_owned = false
	if not claim_a.inventory:
		claim_a.inventory = InventoryData.new(12, true, 999999)
	world_objects.add_child(claim_a)
	_despawn_tallgrass_near(claim_a_pos, claim_a.radius)
	_despawn_decorative_trees_near(claim_a_pos, claim_a.radius)
	register_land_claim(claim_a)
	claim_a.visible = true
	_agro_combat_test_claims.append(claim_a)

	# 2. Land claim ClanB (east)
	var claim_b: LandClaim = LAND_CLAIM_SCENE.instantiate() as LandClaim
	if not claim_b:
		print("ERROR: Failed to instantiate land claim B")
		return
	claim_b.global_position = claim_b_pos
	claim_b.set_clan_name("ClanB")
	claim_b.player_owned = false
	if not claim_b.inventory:
		claim_b.inventory = InventoryData.new(12, true, 999999)
	world_objects.add_child(claim_b)
	_despawn_tallgrass_near(claim_b_pos, claim_b.radius)
	_despawn_decorative_trees_near(claim_b_pos, claim_b.radius)
	register_land_claim(claim_b)
	claim_b.visible = true
	_agro_combat_test_claims.append(claim_b)

	await get_tree().process_frame

	const PER_CLAN := 10  # 1 leader + 9 followers per clan (ideal combat test)
	var offset_spread := 80.0  # Spread 10 units behind leader

	# 3. Spawn ClanA clansmen (west of claim A)
	var clan_a_leader: Node = null
	for i in PER_CLAN:
		var pos := claim_a_pos + Vector2(-offset_spread - i * 12, (i - 4.5) * 22.0)  # 10 in loose block
		var npc: Node = NPC_SCENE.instantiate()
		if not npc:
			continue
		var npc_name: String = _generate_caveman_name()
		npc.set("npc_name", npc_name)
		npc.set("npc_type", "clansman")
		npc.set("age", randi_range(13, 50))
		npc.set("traits", ["solitary"])
		npc.set("agro_meter", 0.0)
		if npc.has_method("set_clan_name"):
			npc.set_clan_name("ClanA", "main._setup_agro_combat_test")
		else:
			npc.set("clan_name", "ClanA")
			npc.set_meta("clan_name", "ClanA")
		world_objects.add_child(npc)
		npc.global_position = pos
		npc.set("spawn_position", pos)
		npc.set("spawn_time", Time.get_ticks_msec() / 1000.0)
		await get_tree().process_frame
		var sprite: Sprite2D = npc.get_node_or_null("Sprite")
		if sprite:
			var tex: Texture2D = AssetRegistry.get_player_sprite()
			if tex:
				sprite.texture = tex
				sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
				sprite.visible = true
				if npc.has_method("apply_sprite_offset_for_texture"):
					npc.apply_sprite_offset_for_texture()
		var inv = npc.get("inventory")
		if inv:
			inv.add_item(ResourceData.ResourceType.WOOD, 1)
		_equip_club_to_npc(npc)
		npc.visible = true
		if i == 0:
			clan_a_leader = npc
		else:
			npc.set("herder", clan_a_leader)
			npc.set("follow_is_ordered", true)
			if npc.has_method("_start_herd"):
				npc._start_herd(clan_a_leader)
			# Guard mode: faster clansmen stay tight around the slower leader
			var commander_id_a: int = EntityRegistry.get_id(clan_a_leader) if EntityRegistry else -1
			var ctx_a: Dictionary = {
				"commander_id": commander_id_a,
				"mode": "GUARD",
				"is_hostile": true,
				"issued_at_time": Time.get_ticks_msec() / 1000.0
			}
			npc.set("command_context", ctx_a)
			npc.set("is_hostile", true)  # Enable raid path for agro combat test
			if "command_context" in npc:
				npc.command_context = ctx_a
			var fsm = npc.get_node_or_null("FSM")
			if fsm and fsm.has_method("change_state"):
				fsm.evaluation_timer = 0.0
				fsm.change_state("herd")
		print("  ClanA: %s at %s" % [npc_name, pos])
	clan_a_leader.set_meta("agro_combat_test_leader", true)  # Skip defend so main can drive them
	clan_a_leader.set_meta("formation_guard", true)  # Leader slower so clansmen protect center
	_agro_combat_test_leaders.append(clan_a_leader)

	# 4. Spawn ClanB clansmen (east of claim B)
	var clan_b_leader: Node = null
	for i in PER_CLAN:
		var pos := claim_b_pos + Vector2(offset_spread + i * 12, (i - 4.5) * 22.0)
		var npc: Node = NPC_SCENE.instantiate()
		if not npc:
			continue
		var npc_name: String = _generate_caveman_name()
		npc.set("npc_name", npc_name)
		npc.set("npc_type", "clansman")
		npc.set("age", randi_range(13, 50))
		npc.set("traits", ["solitary"])
		npc.set("agro_meter", 0.0)
		if npc.has_method("set_clan_name"):
			npc.set_clan_name("ClanB", "main._setup_agro_combat_test")
		else:
			npc.set("clan_name", "ClanB")
			npc.set_meta("clan_name", "ClanB")
		world_objects.add_child(npc)
		npc.global_position = pos
		npc.set("spawn_position", pos)
		npc.set("spawn_time", Time.get_ticks_msec() / 1000.0)
		await get_tree().process_frame
		var sprite: Sprite2D = npc.get_node_or_null("Sprite")
		if sprite:
			var tex: Texture2D = AssetRegistry.get_player_sprite()
			if tex:
				sprite.texture = tex
				sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
				sprite.visible = true
				if npc.has_method("apply_sprite_offset_for_texture"):
					npc.apply_sprite_offset_for_texture()
		var inv = npc.get("inventory")
		if inv:
			inv.add_item(ResourceData.ResourceType.WOOD, 1)
		_equip_club_to_npc(npc)
		npc.visible = true
		if i == 0:
			clan_b_leader = npc
		else:
			npc.set("herder", clan_b_leader)
			npc.set("follow_is_ordered", true)
			if npc.has_method("_start_herd"):
				npc._start_herd(clan_b_leader)
			# Guard mode: faster clansmen stay tight around the slower leader
			var commander_id_b: int = EntityRegistry.get_id(clan_b_leader) if EntityRegistry else -1
			var ctx_b: Dictionary = {
				"commander_id": commander_id_b,
				"mode": "GUARD",
				"is_hostile": true,
				"issued_at_time": Time.get_ticks_msec() / 1000.0
			}
			npc.set("command_context", ctx_b)
			npc.set("is_hostile", true)  # Enable raid path for agro combat test
			if "command_context" in npc:
				npc.command_context = ctx_b
			var fsm = npc.get_node_or_null("FSM")
			if fsm and fsm.has_method("change_state"):
				fsm.evaluation_timer = 0.0
				fsm.change_state("herd")
		print("  ClanB: %s at %s" % [npc_name, pos])
	clan_b_leader.set_meta("agro_combat_test_leader", true)  # Skip defend so main can drive them
	clan_b_leader.set_meta("formation_guard", true)  # Leader slower so clansmen protect center
	_agro_combat_test_leaders.append(clan_b_leader)

	print("=== AGRO/COMBAT TEST: 2 land claims, 2 clans × 10 (GUARD mode — clansmen tight around leader). Leaders move at each other → raiding parties meet head-on → melee → capture data. ===")
	_agro_combat_test_start_time = Time.get_ticks_msec() / 1000.0

func _setup_raid_test_environment() -> void:
	"""Raid test: 2 NPC clans, no follow/guard; ClanBrain initiates raids. Claims ~1300px apart; Clan A 9, Clan B 4."""
	print("=== RAID TEST: 2 clans (ClanA raider 9, ClanB target 4), no follow/guard — ClanBrain initiates raids ===")
	if not player or not world_objects:
		print("ERROR: Player or world_objects is null")
		return
	var center_pos := player.global_position
	const CLAIM_DISTANCE := 650.0  # ~1300px apart — inside THREAT_DISTANCE_MAX and RAID_DISTANCE_MAX
	var claim_a_pos := center_pos + Vector2(-CLAIM_DISTANCE, 0)
	var claim_b_pos := center_pos + Vector2(CLAIM_DISTANCE, 0)

	# 1. Land claim ClanA (west)
	var claim_a: LandClaim = LAND_CLAIM_SCENE.instantiate() as LandClaim
	if not claim_a:
		print("ERROR: Failed to instantiate land claim A")
		return
	claim_a.global_position = claim_a_pos
	claim_a.set_clan_name("ClanA")
	claim_a.player_owned = false
	if not claim_a.inventory:
		claim_a.inventory = InventoryData.new(12, true, 999999)
	# Optional: low food so raid score gets a boost
	claim_a.inventory.add_item(ResourceData.ResourceType.BERRIES, 2)
	world_objects.add_child(claim_a)
	_despawn_tallgrass_near(claim_a_pos, claim_a.radius)
	_despawn_decorative_trees_near(claim_a_pos, claim_a.radius)
	register_land_claim(claim_a)
	claim_a.visible = true

	# 2. Land claim ClanB (east)
	var claim_b: LandClaim = LAND_CLAIM_SCENE.instantiate() as LandClaim
	if not claim_b:
		print("ERROR: Failed to instantiate land claim B")
		return
	claim_b.global_position = claim_b_pos
	claim_b.set_clan_name("ClanB")
	claim_b.player_owned = false
	if not claim_b.inventory:
		claim_b.inventory = InventoryData.new(12, true, 999999)
	world_objects.add_child(claim_b)
	_despawn_tallgrass_near(claim_b_pos, claim_b.radius)
	_despawn_decorative_trees_near(claim_b_pos, claim_b.radius)
	register_land_claim(claim_b)
	claim_b.visible = true

	await get_tree().process_frame

	const CLAN_A_COUNT := 9  # Raider clan
	const CLAN_B_COUNT := 4  # Target clan
	var offset_spread := 60.0

	# 3. Spawn ClanA (no herder, no follow_is_ordered, no command_context)
	for i in CLAN_A_COUNT:
		var pos := claim_a_pos + Vector2(-offset_spread - i * 14, (i - 4) * 20.0)
		var npc: Node = NPC_SCENE.instantiate()
		if not npc:
			continue
		var npc_name: String = _generate_caveman_name()
		npc.set("npc_name", npc_name)
		npc.set("npc_type", "clansman")
		npc.set("age", randi_range(13, 50))
		npc.set("traits", ["solitary"])
		npc.set("agro_meter", 0.0)
		if npc.has_method("set_clan_name"):
			npc.set_clan_name("ClanA", "main._setup_raid_test")
		else:
			npc.set("clan_name", "ClanA")
			npc.set_meta("clan_name", "ClanA")
		world_objects.add_child(npc)
		npc.global_position = pos
		npc.set("spawn_position", pos)
		npc.set("spawn_time", Time.get_ticks_msec() / 1000.0)
		await get_tree().process_frame
		var sprite: Sprite2D = npc.get_node_or_null("Sprite")
		if sprite:
			var tex: Texture2D = AssetRegistry.get_player_sprite()
			if tex:
				sprite.texture = tex
				sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
				sprite.visible = true
				if npc.has_method("apply_sprite_offset_for_texture"):
					npc.apply_sprite_offset_for_texture()
		var inv = npc.get("inventory")
		if inv:
			inv.add_item(ResourceData.ResourceType.WOOD, 1)
		_equip_club_to_npc(npc)
		npc.visible = true
		print("  ClanA: %s at %s" % [npc_name, pos])

	# 4. Spawn ClanB (same: no follow/guard)
	for i in CLAN_B_COUNT:
		var pos := claim_b_pos + Vector2(offset_spread + i * 14, (i - 2) * 20.0)
		var npc: Node = NPC_SCENE.instantiate()
		if not npc:
			continue
		var npc_name: String = _generate_caveman_name()
		npc.set("npc_name", npc_name)
		npc.set("npc_type", "clansman")
		npc.set("age", randi_range(13, 50))
		npc.set("traits", ["solitary"])
		npc.set("agro_meter", 0.0)
		if npc.has_method("set_clan_name"):
			npc.set_clan_name("ClanB", "main._setup_raid_test")
		else:
			npc.set("clan_name", "ClanB")
			npc.set_meta("clan_name", "ClanB")
		world_objects.add_child(npc)
		npc.global_position = pos
		npc.set("spawn_position", pos)
		npc.set("spawn_time", Time.get_ticks_msec() / 1000.0)
		await get_tree().process_frame
		var sprite: Sprite2D = npc.get_node_or_null("Sprite")
		if sprite:
			var tex: Texture2D = AssetRegistry.get_player_sprite()
			if tex:
				sprite.texture = tex
				sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
				sprite.visible = true
				if npc.has_method("apply_sprite_offset_for_texture"):
					npc.apply_sprite_offset_for_texture()
		var inv = npc.get("inventory")
		if inv:
			inv.add_item(ResourceData.ResourceType.WOOD, 1)
		_equip_club_to_npc(npc)
		npc.visible = true
		print("  ClanB: %s at %s" % [npc_name, pos])

	await get_tree().process_frame

	# Set ClanA brain aggression so raid score crosses threshold
	var brain_a = claim_a.get_clan_brain()
	if brain_a != null and "raid_aggression" in brain_a:
		brain_a.raid_aggression = 0.9
	var defender_quota_a: int = brain_a.get_defender_quota() if brain_a and brain_a.has_method("get_defender_quota") else 2
	var available_raid: int = CLAN_A_COUNT - defender_quota_a
	print("  ClanA: cavemen=%d defenders=%d available_for_raid=%d" % [CLAN_A_COUNT, defender_quota_a, available_raid])

	_raid_test_start_time = Time.get_ticks_msec() / 1000.0
	print("=== RAID TEST: Run 90s; ClanBrain evaluates every 5s. Expect raid_started, raid_joined, then combat. ===")

func _setup_gather_test_environment() -> void:
	print("=== GATHER TASK SYSTEM TEST: Setting up ideal test environment ===")
	
	if not player:
		print("ERROR: Player is null, cannot set up gather test environment")
		return
	
	if not world_objects:
		print("ERROR: WorldObjects (YSort) is null")
		return
	
	var center_pos := player.global_position
	var test_clan_name := "TEST"
	
	# 1. Create land claim named "TEST" east of player
	var land_claim_pos := center_pos + Vector2(200, 0)  # 200px east
	var land_claim: LandClaim = LAND_CLAIM_SCENE.instantiate() as LandClaim
	if not land_claim:
		print("ERROR: Failed to instantiate land claim for gather test environment")
		return
	
	land_claim.global_position = land_claim_pos
	land_claim.set_clan_name(test_clan_name)
	land_claim.player_owned = true
	
	# Create inventory (empty to start - resources will come from gathering)
	var building_inventory := InventoryData.new(20, true, 999999)
	land_claim.inventory = building_inventory
	
	world_objects.add_child(land_claim)
	_despawn_tallgrass_near(land_claim_pos, land_claim.radius)
	_despawn_decorative_trees_near(land_claim_pos, land_claim.radius)
	# Phase 3: Register land claim for cache tracking
	register_land_claim(land_claim)
	land_claim.visible = true
	
	# Wait a frame for land claim to initialize
	await get_tree().process_frame
	
	print("✓ Created land claim '%s' at %s" % [test_clan_name, land_claim_pos])
	
	# 2. Spawn resources around the land claim for gathering
	var resource_offsets: Array[Vector2] = [
		Vector2(100, -80),   # North-east
		Vector2(100, 80),    # South-east
		Vector2(150, -120),  # Further north-east
		Vector2(150, 120),   # Further south-east
		Vector2(80, -150),   # North
		Vector2(80, 150),    # South
		Vector2(-50, -100),  # North-west (inside claim)
		Vector2(-50, 100),   # South-west (inside claim)
	]
	
	var resource_types: Array[ResourceData.ResourceType] = [
		ResourceData.ResourceType.WOOD,
		ResourceData.ResourceType.STONE,
		ResourceData.ResourceType.BERRIES,
		ResourceData.ResourceType.WHEAT,
	]
	
	for i in range(resource_offsets.size()):
		var resource_pos: Vector2 = land_claim_pos + resource_offsets[i]
		var resource_type: ResourceData.ResourceType = resource_types[i % resource_types.size()]
		_spawn_resource(resource_type, resource_pos)
		print("✓ Spawned %s resource at %s" % [ResourceData.get_resource_name(resource_type), resource_pos])
	
	# Wait a frame for resources to initialize
	await get_tree().process_frame
	
	# 3. Create 2 women already part of the landclaim (TEST clan)
	var woman_positions: Array[Vector2] = [
		land_claim_pos + Vector2(-30, -30),  # Inside claim, north-west
		land_claim_pos + Vector2(-30, 30),   # Inside claim, south-west
	]
	
	for i in range(2):
		var woman_pos: Vector2 = woman_positions[i]
		var npc: Node = NPC_SCENE.instantiate()
		if not npc:
			print("ERROR: Failed to instantiate woman NPC %d" % (i + 1))
			continue
		
		var npc_name: String = NamingUtils.generate_caveman_name()
		npc.set("npc_name", npc_name)
		npc.set("npc_type", "woman")
		npc.set("traits", ["herd"])
		npc.set("age", randi_range(13, 50))
		
		# Assign to TEST clan immediately
		npc.set("clan_name", test_clan_name)
		
		# Set sprite
		var sprite: Sprite2D = npc.get_node_or_null("Sprite")
		if sprite:
			var texture: Texture2D = AssetRegistry.get_woman_sprite()
			if texture:
				sprite.texture = texture
				sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
				sprite.visible = true
				if npc.has_method("apply_sprite_offset_for_texture"):
					npc.apply_sprite_offset_for_texture()
		
		world_objects.add_child(npc)
		npc.global_position = woman_pos
		npc.set("spawn_position", woman_pos)
		
		await get_tree().process_frame
		
		# Set agility (women move slower)
		var stats: Node = npc.get_node_or_null("Stats")
		if stats and stats.has_method("set_stat"):
			stats.set_stat("agility", 9.0)
		elif stats:
			stats.agility = 9.0
		
		npc.visible = true
		print("✓ Created Woman: %s at %s (clan: %s)" % [npc_name, woman_pos, test_clan_name])
		
		# Log woman creation
		UnifiedLogger.log_npc("GATHER_TEST: Created woman %s in clan %s at %s" % [npc_name, test_clan_name, woman_pos], {
			"npc": npc_name,
			"type": "woman",
			"clan": test_clan_name,
			"position": "%s" % woman_pos,
			"test": "gather_setup"
		})
	
	# 4. Create 2 clansmen that belong to TEST clan
	var clansman_positions: Array[Vector2] = [
		land_claim_pos + Vector2(30, -30),  # Inside claim, north-east
		land_claim_pos + Vector2(30, 30),   # Inside claim, south-east
	]
	
	for i in range(2):
		var clansman_pos: Vector2 = clansman_positions[i]
		var npc: Node = NPC_SCENE.instantiate()
		if not npc:
			print("ERROR: Failed to instantiate clansman NPC %d" % (i + 1))
			continue
		
		var npc_name: String = NamingUtils.generate_caveman_name()
		npc.set("npc_name", npc_name)
		npc.set("npc_type", "clansman")
		npc.set("age", randi_range(13, 50))
		npc.set("traits", [])
		npc.set("agro_meter", 0.0)
		
		# Assign to TEST clan immediately
		npc.set("clan_name", test_clan_name)
		
		# Set sprite
		var sprite: Sprite2D = npc.get_node_or_null("Sprite")
		if sprite:
			var texture: Texture2D = AssetRegistry.get_player_sprite()
			if texture:
				sprite.texture = texture
				sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
				sprite.visible = true
				if npc.has_method("apply_sprite_offset_for_texture"):
					npc.apply_sprite_offset_for_texture()
		
		world_objects.add_child(npc)
		npc.global_position = clansman_pos
		npc.set("spawn_position", clansman_pos)
		npc.set("spawn_time", Time.get_ticks_msec() / 1000.0)
		
		await get_tree().process_frame
		
		# Equip club (add wood to inventory first)
		var inv = npc.get("inventory")
		if inv:
			inv.add_item(ResourceData.ResourceType.WOOD, 1)
		_equip_club_to_npc(npc)
		
		npc.visible = true
		print("✓ Created Clansman: %s at %s (clan: %s)" % [npc_name, clansman_pos, test_clan_name])
		
		# Log clansman creation
		UnifiedLogger.log_npc("GATHER_TEST: Created clansman %s in clan %s at %s" % [npc_name, test_clan_name, clansman_pos], {
			"npc": npc_name,
			"type": "clansman",
			"clan": test_clan_name,
			"position": "%s" % clansman_pos,
			"test": "gather_setup"
		})
	
	# 5. Set up periodic logging for NPC movement, logic, and resources
	_setup_gather_test_logging()
	
	print("=== GATHER TASK SYSTEM TEST: Test environment setup complete ===")
	print("  - Land claim: %s at %s" % [test_clan_name, land_claim_pos])
	print("  - 2 Women in clan %s" % test_clan_name)
	print("  - 2 Clansmen in clan %s" % test_clan_name)
	print("  - 8 Resources spawned around land claim")
	print("  - Logging enabled for NPC movement, logic, and resource tracking")

func _setup_gather_test_logging() -> void:
	# Enable relevant logging categories
	UnifiedLogger.set_category_enabled(UnifiedLogger.Category.NPC, true)
	UnifiedLogger.set_category_enabled(UnifiedLogger.Category.INVENTORY, true)
	UnifiedLogger.set_category_enabled(UnifiedLogger.Category.RESOURCE, true)
	
	# Enable gather test logging
	gather_test_enabled = true
	gather_test_npc_positions.clear()
	
	# Start periodic logging timer
	# This will be called from _process() to log NPC states and resource flows
	print("✓ Gather test logging enabled (logs every %.1f seconds)" % GATHER_TEST_LOG_INTERVAL)

func _initialize_minigame() -> void:
	# Wait a frame to ensure player position is set
	await get_tree().process_frame
	
	# Headless: extra frame so scene tree is fully ready
	if "--headless" in OS.get_cmdline_args() or "--headless" in OS.get_cmdline_user_args():
		await get_tree().process_frame
	
	# Resolve spawn center and parent - fallbacks for headless/edge cases
	var center_pos: Vector2
	var spawn_parent: Node2D
	if player and is_instance_valid(player):
		center_pos = player.global_position
	else:
		center_pos = Vector2.ZERO
		print("WARNING: Player null, using fallback center (0,0) for NPC spawn")
	
	if world_objects and is_instance_valid(world_objects):
		spawn_parent = world_objects
	else:
		spawn_parent = get_node_or_null("WorldObjects") as Node2D
		if not spawn_parent:
			spawn_parent = get_node_or_null("WorldLayer") as Node2D
		if not spawn_parent:
			print("ERROR: WorldObjects is null, cannot spawn NPCs")
			return
		print("WARNING: Using fallback spawn parent: %s" % spawn_parent.name)
	
	# GATHER TASK SYSTEM TEST: Enable test environment
	# await _setup_gather_test_environment()  # DISABLED - normal play
	# Woman transport test: only player + land claim + ovens + 2 women (no cavemen)
	if DebugConfig.enable_woman_transport_test:
		await _setup_task_system_test_environment()
		return
	# Agro/combat test: 2 clans x 10 clansmen (1 leader + 9 followers), clubs, follow, 2 claims
	if DebugConfig.enable_agro_combat_test:
		await _setup_agro_combat_test_environment()
		return
	# Raid test: 2 NPC clans (no follow/guard), ClanBrain initiates raids
	if DebugConfig.enable_raid_test:
		await _setup_raid_test_environment()
		return

	# Playtest: 4 cavemen spread far apart
	var caveman_count := BalanceConfig.caveman_count if BalanceConfig else 4
	var caveman_spawn_radius_min := BalanceConfig.caveman_spawn_radius_min if BalanceConfig else 900.0
	var caveman_spawn_radius_max := BalanceConfig.caveman_spawn_radius_max if BalanceConfig else 1200.0
	var caveman_angle_step: float = TAU / float(max(caveman_count, 1))
	
	# Spawn land claim + caveman together (no LANDCLAIM item; caveman is assigned to claim at spawn)
	print("Spawning %d cavemen with land claims" % caveman_count)
	
	for i in caveman_count:
		var base_angle := i * caveman_angle_step
		var angle_offset := randf_range(-PI / 6, PI / 6)
		var angle := base_angle + angle_offset
		var distance := randf_range(caveman_spawn_radius_min, caveman_spawn_radius_max)
		var pos := Vector2(cos(angle), sin(angle)) * distance + center_pos
		# Snap claim position to 64px grid (matches build_state placement)
		var claim_pos := Vector2(round(pos.x / 64.0) * 64.0, round(pos.y / 64.0) * 64.0)
		
		var clan_name: String = _generate_random_clan_name()
		# 1) Create land claim first
		var land_claim: LandClaim = LAND_CLAIM_SCENE.instantiate() as LandClaim
		if not land_claim:
			print("ERROR: Failed to instantiate land claim for AI caveman")
			continue
		land_claim.global_position = claim_pos
		land_claim.set_clan_name(clan_name)
		land_claim.player_owned = false
		if not land_claim.inventory:
			land_claim.inventory = InventoryData.new(12, true, 999999)
		spawn_parent.add_child(land_claim)
		_despawn_tallgrass_near(claim_pos, land_claim.radius)
		_despawn_decorative_trees_near(claim_pos, land_claim.radius)
		register_land_claim(land_claim)
		land_claim.visible = true
		
		# 2) Spawn caveman and assign to claim (set clan/meta BEFORE add_child so npc_base doesn't add LANDCLAIM)
		var npc: Node = NPC_SCENE.instantiate()
		if not npc:
			print("ERROR: Failed to instantiate NPC scene")
			continue
		var npc_name: String = _generate_caveman_name()
		npc.set("npc_name", npc_name)
		npc.set("npc_type", "caveman")
		npc.set("age", randi_range(13, 50))
		# Trait-driven defend: ~30% protective (fill defender slot when 2+), 70% solitary (prefer herd/gather)
		npc.set("traits", ["protective"] if randf() < 0.3 else ["solitary"])
		npc.set("agro_meter", 0.0)
		npc.set("clan_name", clan_name)
		npc.set_meta("clan_name", clan_name)
		npc.set_meta("land_claim_clan_name", clan_name)
		npc.set_meta("has_land_claim", true)
		
		spawn_parent.add_child(npc)
		npc.global_position = pos
		npc.set("spawn_position", pos)
		npc.set("spawn_time", Time.get_ticks_msec() / 1000.0)
		if npc.has_method("set_clan_name"):
			npc.set_clan_name(clan_name, "main._initialize_minigame")
		
		land_claim.owner_npc = npc
		land_claim.owner_npc_name = npc_name
		land_claim.set_meta("owner_npc_name", npc_name)
		
		await get_tree().process_frame
		
		var sprite: Sprite2D = npc.get_node_or_null("Sprite")
		if sprite:
			var texture: Texture2D = AssetRegistry.get_player_sprite()
			if texture:
				sprite.texture = texture
				sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
				sprite.visible = true
				if npc.has_method("apply_sprite_offset_for_texture"):
					npc.apply_sprite_offset_for_texture()
		
		var npc_inventory = npc.get("inventory")
		if npc_inventory:
			npc_inventory.add_item(ResourceData.ResourceType.WOOD, 1)  # Club (basic weapon); no LANDCLAIM - already have claim
		
		_equip_club_to_npc(npc)
		npc.visible = true
		print("✓ Spawned Caveman: %s at %s with land claim '%s'" % [npc_name, pos, clan_name])
		
		# Boost: 1 woman + 1 baby inside this claim (optional - when false, caveman must find women)
		if BalanceConfig and BalanceConfig.get("caveman_spawn_with_boost") == true:
			var woman_pos := claim_pos + Vector2(randf_range(-80.0, 80.0), randf_range(-80.0, 80.0))
			var woman_npc: Node = NPC_SCENE.instantiate()
			if woman_npc:
				woman_npc.set("npc_name", NamingUtils.generate_caveman_name())
				woman_npc.set("npc_type", "woman")
				woman_npc.set("traits", ["herd"])
				woman_npc.set("age", randi_range(13, 50))
				woman_npc.set("clan_name", clan_name)
				woman_npc.set_meta("clan_name", clan_name)
				var ws: Sprite2D = woman_npc.get_node_or_null("Sprite")
				if ws:
					var wt: Texture2D = AssetRegistry.get_woman_sprite()
					if wt:
						ws.texture = wt
						ws.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
						ws.visible = true
						if woman_npc.has_method("apply_sprite_offset_for_texture"):
							woman_npc.apply_sprite_offset_for_texture()
				spawn_parent.add_child(woman_npc)
				woman_npc.global_position = woman_pos
				woman_npc.set("spawn_position", woman_pos)
				if woman_npc.has_method("set_clan_name"):
					woman_npc.set_clan_name(clan_name, "main._initialize_minigame")
				await get_tree().process_frame
				woman_npc.visible = true
				var stats_node = woman_npc.get_node_or_null("Stats")
				if stats_node and stats_node.has_method("set_stat"):
					stats_node.set_stat("agility", 9.0)
				elif stats_node:
					stats_node.agility = 9.0
				var baby_pos := claim_pos + Vector2(randf_range(-60.0, 60.0), randf_range(-60.0, 60.0))
				await _spawn_baby(clan_name, baby_pos, woman_npc as NPCBase, npc as NPCBase)
				print("✓ Boost: 1 woman + 1 baby in claim '%s'" % clan_name)
	
	# Playtest: wild women spread in a band (not clustered in center)
	var woman_count := BalanceConfig.woman_initial if BalanceConfig else 3
	var woman_radius_min: float = BalanceConfig.woman_spawn_radius_min if BalanceConfig else 1200.0
	var woman_radius_max: float = BalanceConfig.woman_spawn_radius_max if BalanceConfig else 2800.0
	print("Spawning %d women" % woman_count)
	
	for i in woman_count:
		var angle := randf() * TAU
		var distance := randf_range(woman_radius_min, woman_radius_max)
		var pos := Vector2(cos(angle), sin(angle)) * distance + center_pos
		
		var npc: Node = NPC_SCENE.instantiate()
		if not npc:
			print("ERROR: Failed to instantiate NPC scene")
			continue
		
		var npc_name: String = NamingUtils.generate_caveman_name()
		
		# Set properties
		npc.set("npc_name", npc_name)
		npc.set("npc_type", "woman")
		# Women need the "herd" trait to follow cavemen/player
		# Set traits directly (has_trait may not be available until _ready() is called)
		npc.set("traits", ["herd"])  # Women have herd mentality
		npc.set("age", randi_range(13, 50))
		# Set sprite texture
		var sprite: Sprite2D = npc.get_node_or_null("Sprite")
		if sprite:
			var texture: Texture2D = AssetRegistry.get_woman_sprite()
			if texture:
				sprite.texture = texture
				sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
				sprite.visible = true
				if npc.has_method("apply_sprite_offset_for_texture"):
					npc.apply_sprite_offset_for_texture()
		
		spawn_parent.add_child(npc)
		npc.global_position = pos
		npc.set("spawn_position", pos)
		
		await get_tree().process_frame
		
		# NORMAL CONFIGURATION: Women spawn as wild (no clan assignment)
		# They can be assigned to clans by player later
		
		# Women move slightly slower than player/cavemen (agility 9.0 = 288.0 speed vs 320.0)
		var stats: Node = npc.get_node_or_null("Stats")
		if stats and stats.has_method("set_stat"):
			stats.set_stat("agility", 9.0)
		elif stats:
			stats.agility = 9.0
		
		npc.visible = true
		print("✓ Spawned Woman: %s at %s (agility 9.0 = 288.0 speed)" % [npc_name, pos])
	
	# Spawn mammoths (wild, non-herdable, agro at threats in AOP)
	# _spawn_mammoths(center_pos)  # DISABLED - for testing
	
	# Spawn sheep and goats (huntable, meat from corpses)
	_spawn_sheep_and_goats(center_pos, spawn_parent)
	
	# NORMAL MODE: Enable respawn systems
	_start_women_respawn_system()
	_start_sheep_goats_respawn_system()

func _spawn_mammoths(center_pos: Vector2) -> void:
	var mammoth_count := 2  # Spawn 2 mammoths
	var spawn_radius := 1200.0  # Far from center - wild megafauna
	
	print("Spawning %d mammoths" % mammoth_count)
	
	for i in mammoth_count:
		var angle := randf() * TAU
		var distance := randf_range(800.0, spawn_radius)
		var pos := Vector2(cos(angle), sin(angle)) * distance + center_pos
		
		var npc: Node = NPC_SCENE.instantiate()
		if not npc:
			continue
		
		var npc_name: String = "Mammoth %d" % (i + 1)
		npc.set("npc_name", npc_name)
		npc.set("npc_type", "mammoth")
		npc.set("traits", [])  # No herd trait - cannot be herded
		npc.set("age", 20)
		npc.set("agro_meter", 0.0)
		
		# Mammoth scale (0.6 = 10x smaller than original 6.0)
		var mammoth_scale: float = 0.6
		if NPCConfig:
			var s = NPCConfig.get("mammoth_scale")
			if s != null:
				mammoth_scale = s as float
		npc.scale = Vector2(mammoth_scale, mammoth_scale)
		
		var sprite: Sprite2D = npc.get_node_or_null("Sprite")
		if sprite:
			var texture: Texture2D = AssetRegistry.get_mammoth_sprite()
			if texture:
				sprite.texture = texture
				sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
				sprite.visible = true
		
		world_objects.add_child(npc)
		npc.global_position = pos
		npc.set("spawn_position", pos)
		npc.visible = true
		print("✓ Spawned Mammoth: %s at %s (wild, 256x256, agro at threats)" % [npc_name, pos])

func _spawn_sheep_and_goats(center_pos: Vector2, parent: Node2D = null) -> void:
	var spawn_parent := parent if parent else world_objects
	# Spawn sheep (group together) and goats (solitary) spread across map
	var sheep_count := BalanceConfig.sheep_initial if BalanceConfig else 3
	var goat_count := BalanceConfig.goat_initial if BalanceConfig else 3
	var spawn_radius: float = BalanceConfig.sheep_goat_spawn_radius if BalanceConfig else 2200.0
	var group_min: float = BalanceConfig.sheep_goat_group_distance_min if BalanceConfig else 800.0
	
	print("Spawning %d sheep and %d goats around center" % [sheep_count, goat_count])
	
	# Spawn sheep in groups (2-3 per group)
	var sheep_per_group := 2
	var sheep_spawned := 0
	
	while sheep_spawned < sheep_count:
		# Start a new group position (spread out band)
		var group_angle := randf() * TAU
		var group_distance := randf_range(group_min, spawn_radius)
		var group_center := Vector2(cos(group_angle), sin(group_angle)) * group_distance + center_pos
		
		# Spawn 2-3 sheep in this group
		var remaining: int = sheep_count - sheep_spawned
		var group_size: int = sheep_per_group if sheep_per_group < remaining else remaining
		for j in group_size:
			var offset_angle := randf() * TAU
			var offset_distance := randf_range(20.0, 80.0)  # Sheep group close together
			var sheep_pos := group_center + Vector2(cos(offset_angle), sin(offset_angle)) * offset_distance
			
			var npc: Node = NPC_SCENE.instantiate()
			if not npc:
				continue
			
			var npc_name: String = "Sheep %d" % (Time.get_ticks_msec() + sheep_spawned * 100 + j)
			
			npc.set("npc_name", npc_name)
			npc.set("npc_type", "sheep")
			# Sheep need the "herd" trait and group together
			npc.set("traits", ["herd", "group"])  # Set traits directly
			
			# Set sprite texture and random tint (white to almost-black)
			var sprite: Sprite2D = npc.get_node_or_null("Sprite")
			if sprite:
				var texture: Texture2D = AssetRegistry.get_sheep_sprite()
				if texture:
					sprite.texture = texture
					sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
					var tint := _get_random_sheep_goat_tint()
					sprite.modulate = tint
					npc.set_meta("sheep_goat_tint", tint)
					sprite.visible = true
					if npc.has_method("apply_sprite_offset_for_texture"):
						npc.apply_sprite_offset_for_texture()
			
			spawn_parent.add_child(npc)
			npc.global_position = sheep_pos
			npc.set("spawn_position", sheep_pos)
			npc.visible = true
			print("✓ Spawned Sheep: %s at %s" % [npc_name, sheep_pos])
			sheep_spawned += 1
	
	# Spawn goats (solitary, spread out)
	for i in goat_count:
		var angle := randf() * TAU
		var distance := randf_range(group_min, spawn_radius)
		var pos := Vector2(cos(angle), sin(angle)) * distance + center_pos
		
		var npc: Node = NPC_SCENE.instantiate()
		if not npc:
			continue
		
		var npc_name: String = "Goat %d" % (Time.get_ticks_msec() + i * 100)
		
		npc.set("npc_name", npc_name)
		npc.set("npc_type", "goat")
		# Goats need the "herd" trait but are solitary (no group trait)
		npc.set("traits", ["herd"])  # Set traits directly - no "group" trait, goats are solitary
		
		# Set sprite texture and random tint (white to almost-black)
		var sprite: Sprite2D = npc.get_node_or_null("Sprite")
		if sprite:
			var texture: Texture2D = AssetRegistry.get_goat_sprite()
			if texture:
				sprite.texture = texture
				sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
				var tint := _get_random_sheep_goat_tint()
				sprite.modulate = tint
				npc.set_meta("sheep_goat_tint", tint)
				sprite.visible = true
				if npc.has_method("apply_sprite_offset_for_texture"):
					npc.apply_sprite_offset_for_texture()
		
		spawn_parent.add_child(npc)
		npc.global_position = pos
		npc.set("spawn_position", pos)
		npc.visible = true
		print("✓ Spawned Goat: %s at %s" % [npc_name, pos])

func _start_women_respawn_system() -> void:
	# Spawn 1 woman every 60 seconds (BalanceConfig)
	var timer := Timer.new()
	timer.wait_time = BalanceConfig.woman_respawn_interval_sec if BalanceConfig else 60.0
	timer.timeout.connect(_spawn_single_woman)
	timer.autostart = true
	add_child(timer)
	timer.name = "WomenRespawnTimer"

func _spawn_single_woman() -> void:
	# Respawn cap: skip if at or above cap
	var cap: int = BalanceConfig.women_respawn_cap if BalanceConfig else 12
	var wild_women: int = 0
	for n in get_tree().get_nodes_in_group("npcs"):
		if is_instance_valid(n) and n.get("npc_type") == "woman":
			var h = n.get("herder")
			if h == null or not is_instance_valid(h):
				wild_women += 1
	if wild_women >= cap:
		return
	_spawn_wild_woman(1)

func _spawn_wild_woman(count: int) -> void:
	if not player or not world_objects:
		return
	
	var center_pos := player.global_position
	var radius_min: float = BalanceConfig.woman_spawn_radius_min if BalanceConfig else 1200.0
	var radius_max: float = BalanceConfig.woman_spawn_radius_max if BalanceConfig else 2800.0
	
	for i in count:
		var angle := randf() * TAU
		var distance := randf_range(radius_min, radius_max)
		var pos := Vector2(cos(angle), sin(angle)) * distance + center_pos
		
		var npc: Node = NPC_SCENE.instantiate()
		if not npc:
			continue
		
		var npc_name: String = NamingUtils.generate_caveman_name()  # Random name
		
		npc.set("npc_name", npc_name)
		npc.set("npc_type", "woman")
		# Women need the "herd" trait to follow cavemen/player
		if not npc.has_trait("herd"):
			npc.traits.append("herd")
		npc.set("age", randi_range(13, 50))
		npc.set("traits", ["herd"])
		
		var sprite: Sprite2D = npc.get_node_or_null("Sprite")
		if sprite:
			var texture: Texture2D = AssetRegistry.get_woman_sprite()
			if texture:
				sprite.texture = texture
				sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
				sprite.visible = true
				if npc.has_method("apply_sprite_offset_for_texture"):
					npc.apply_sprite_offset_for_texture()
		
		world_objects.add_child(npc)
		npc.global_position = pos
		npc.set("spawn_position", pos)
		
		await get_tree().process_frame
		
		# Women move slightly slower than player/cavemen (agility 9.0 = 288.0 speed vs 320.0)
		var stats: Node = npc.get_node_or_null("Stats")
		if stats and stats.has_method("set_stat"):
			stats.set_stat("agility", 9.0)
		elif stats:
			stats.agility = 9.0
		
		npc.visible = true
		print("✓ Respawned Wild Woman: %s at %s (agility 9.0 = 288.0 speed)" % [npc_name, pos])

func _equip_club_to_npc(npc: Node) -> void:
	"""Equip club (wood) to caveman/clansman. Club shown only when in aggro/defense/combat."""
	if not npc or not is_instance_valid(npc):
		return
	
	await get_tree().process_frame
	
	# Ensure NPC has wood in hotbar slot 0 (right hand)
	var hotbar = npc.get("hotbar")
	if hotbar:
		hotbar.set_slot(0, {"type": ResourceData.ResourceType.WOOD, "count": 1, "quality": 0})
	
	var weapon_comp = npc.get_node_or_null("WeaponComponent")
	if not weapon_comp:
		await get_tree().process_frame
		weapon_comp = npc.get_node_or_null("WeaponComponent")
	
	if weapon_comp and weapon_comp.has_method("equip_weapon"):
		weapon_comp.equip_weapon(ResourceData.ResourceType.WOOD)
		var npc_name = npc.get("npc_name") if npc.has_method("get") else "unknown"
		print("⚔️ Equipped %s with club (wood)" % npc_name)
	else:
		var npc_name = npc.get("npc_name") if npc.has_method("get") else "unknown"
		print("⚠️ Could not equip club to %s - WeaponComponent not found" % npc_name)

func _spawn_baby(clan_name: String, spawn_pos: Vector2, mother: NPCBase, father: NPCBase = null) -> void:
	var mother_name = mother.get("npc_name") if mother and mother.has_method("get") else "unknown"
	if mother_name == null or mother_name == "":
		mother_name = "unknown"
	var father_name = _get_player_name_for_baby()
	if father:
		if father.has_method("get"):
			father_name = father.get("npc_name") if father.get("npc_name") else "unknown"
		elif father.is_in_group("player"):
			father_name = _get_player_name_for_baby()
	
	UnifiedLogger.log_system("SPAWN_BABY: Starting baby spawn", {
		"clan": clan_name,
		"mother": mother_name,
		"father": father_name,
		"position": "%.1f,%.1f" % [spawn_pos.x, spawn_pos.y]
	})
	
	# Spawn baby NPC at land claim center
	if not world_objects:
		UnifiedLogger.log_system("SPAWN_BABY: ERROR - world_objects is null", {
			"clan": clan_name,
			"mother": mother_name
		})
		print("ERROR: Cannot spawn baby - world_objects is null")
		return
	
	# Safety check: mother must be valid
	if not mother or not is_instance_valid(mother):
		UnifiedLogger.log_system("SPAWN_BABY: ERROR - mother is null or invalid", {
			"clan": clan_name,
			"mother": mother_name
		})
		print("ERROR: Cannot spawn baby - mother is null or invalid")
		return
	
	# Safety check: Ensure baby pool manager is initialized
	if not baby_pool_manager:
		UnifiedLogger.log_system("SPAWN_BABY: Baby pool manager not initialized, creating it", {
			"clan": clan_name,
			"mother": mother_name
		})
		_setup_baby_pool_manager()
	
	# Double-check capacity before spawning
	if baby_pool_manager:
		var can_add = baby_pool_manager.can_add_baby(clan_name)
		UnifiedLogger.log_system("SPAWN_BABY: Baby pool check - can_add: %s" % can_add, {
			"clan": clan_name,
			"mother": mother_name,
			"can_add": can_add
		})
		if not can_add:
			UnifiedLogger.log_system("SPAWN_BABY: Baby pool full for clan %s - spawn cancelled" % clan_name, {
				"clan": clan_name,
				"mother": mother_name
			})
			print("⚠ Baby pool full for clan %s - baby spawn cancelled" % clan_name)
			return
	
	var npc: Node = NPC_SCENE.instantiate()
	if not npc:
		UnifiedLogger.log_system("SPAWN_BABY: ERROR - Failed to instantiate NPC scene", {
			"clan": clan_name,
			"mother": mother_name
		})
		print("ERROR: Failed to instantiate NPC scene for baby")
		return
	
	# Generate random name for baby
	var npc_name: String = NamingUtils.generate_caveman_name()
	
	UnifiedLogger.log_system("SPAWN_BABY: Baby NPC instantiated, setting properties", {
		"clan": clan_name,
		"mother": mother_name,
		"baby_name": npc_name
	})
	
	# Set properties
	npc.set("npc_name", npc_name)
	npc.set("npc_type", "baby")
	npc.set("clan_name", clan_name)
	npc.set("age", 0)  # Babies start at age 0
	
	# Set lineage (father and mother names) - babies have lineage
	# Ensure father_name and mother_name are never null (prevents BABY LINEAGE warning)
	if father_name == "" or father_name == null:
		father_name = _get_player_name_for_baby()
	if father_name == "" or father_name == null:
		father_name = "unknown"
	if mother_name == "" or mother_name == null:
		mother_name = "unknown"
	
	# Set lineage (father and mother names) - use both set() and meta for persistence
	npc.set("father_name", father_name)
	npc.set("mother_name", mother_name)
	npc.set_meta("father_name", father_name)
	npc.set_meta("mother_name", mother_name)
	
	# Verify lineage persisted (warn only if set failed)
	var verify_father = npc.get("father_name")
	var verify_mother = npc.get("mother_name")
	if verify_father == null or verify_mother == null:
		push_warning("BABY LINEAGE: %s - lineage may not have persisted (father=%s, mother=%s)" % [npc_name, verify_father, verify_mother])
	
	# Set sprite - use baby.png (64x64 pixels)
	var sprite: Sprite2D = npc.get_node_or_null("Sprite")
	if sprite:
		var texture: Texture2D = AssetRegistry.get_baby_sprite()
		if texture:
			sprite.texture = texture
			sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
			sprite.visible = true
			if npc.has_method("apply_sprite_offset_for_texture"):
				npc.apply_sprite_offset_for_texture()
		else:
			print("WARNING: baby.png sprite not found, using default")
	
	# Add to scene
	UnifiedLogger.log_system("SPAWN_BABY: Adding baby to scene tree", {
		"clan": clan_name,
		"mother": mother_name,
		"baby_name": npc_name,
		"position": "%.1f,%.1f" % [spawn_pos.x, spawn_pos.y]
	})
	
	world_objects.add_child(npc)
	npc.global_position = spawn_pos
	npc.set("spawn_position", spawn_pos)
	
	# Wait for components to initialize
	await get_tree().process_frame
	
	# Babies get club when they grow to clansman (via baby_growth_component)
	
	npc.visible = true
	
	UnifiedLogger.log_system("SPAWN_BABY: Baby added to scene, updating baby pool count", {
		"clan": clan_name,
		"mother": mother_name,
		"baby_name": npc_name
	})
	
	# Update baby pool count after spawning
	if baby_pool_manager:
		baby_pool_manager.get_current_count(clan_name)  # This updates the count
	
	# Baby inventory: slot count set in npc_base._initialize_inventory() from NPCConfig.baby_inventory_slots
	await get_tree().process_frame
	
	# Update father_name on NPC if it changed (e.g., if father was determined after spawning)
	# This ensures the property is set correctly even if father wasn't known at spawn time
	if father and is_instance_valid(father):
		var updated_father_name = ""
		if father.has_method("get"):
			updated_father_name = father.get("npc_name") if father.get("npc_name") else "unknown"
		elif father.is_in_group("player"):
			updated_father_name = _get_player_name_for_baby()
		
		if updated_father_name != "" and updated_father_name != father_name:
			npc.set("father_name", updated_father_name)
			father_name = updated_father_name
	
	UnifiedLogger.log_system("SPAWN_BABY: SUCCESS - Baby spawned", {
		"clan": clan_name,
		"mother": mother_name,
		"father": father_name,
		"baby_name": npc_name,
		"position": "%.1f,%.1f" % [spawn_pos.x, spawn_pos.y]
	})
	print("✓ Spawned Baby: %s at %s (clan: %s, mother: %s, father: %s)" % [npc_name, spawn_pos, clan_name, mother_name, father_name])
	var playtest_pi = get_node_or_null("/root/PlaytestInstrumentor")
	if playtest_pi and playtest_pi.is_enabled() and playtest_pi.has_method("baby_spawned"):
		var slot_count: int = npc.inventory.slot_count if npc.inventory else -1
		playtest_pi.baby_spawned(clan_name, mother_name, father_name, slot_count)

func _start_sheep_goats_respawn_system() -> void:
	# Spawn 1 sheep AND 1 goat every 60 seconds (BalanceConfig)
	var timer := Timer.new()
	timer.wait_time = BalanceConfig.sheep_goat_respawn_interval_sec if BalanceConfig else 60.0
	timer.timeout.connect(_spawn_respawn_batch_sheep_goats)
	timer.autostart = true
	add_child(timer)
	timer.name = "SheepGoatsRespawnTimer"

func _spawn_respawn_batch_sheep_goats() -> void:
	if not player or not world_objects:
		return
	
	var center_pos := player.global_position
	var spawn_radius := 1200.0
	
	# Spawn 1 sheep (if under cap)
	var sheep_cap: int = BalanceConfig.sheep_respawn_cap if BalanceConfig else 15
	var sheep_count: int = 0
	for n in get_tree().get_nodes_in_group("npcs"):
		if is_instance_valid(n) and n.get("npc_type") == "sheep":
			sheep_count += 1
	if sheep_count < sheep_cap:
		_spawn_one_sheep_or_goat(center_pos, spawn_radius, true)
	
	# Spawn 1 goat (if under cap)
	var goat_cap: int = BalanceConfig.goat_respawn_cap if BalanceConfig else 15
	var goat_count: int = 0
	for n in get_tree().get_nodes_in_group("npcs"):
		if is_instance_valid(n) and n.get("npc_type") == "goat":
			goat_count += 1
	if goat_count < goat_cap:
		_spawn_one_sheep_or_goat(center_pos, spawn_radius, false)

func _spawn_one_sheep_or_goat(center_pos: Vector2, spawn_radius: float, is_sheep: bool) -> void:
	var angle := randf() * TAU
	var distance := randf_range(800.0, spawn_radius)
	var pos := Vector2(cos(angle), sin(angle)) * distance + center_pos
	
	var npc: Node = NPC_SCENE.instantiate()
	if not npc:
		return
	
	var npc_name: String
	var npc_type: String
	var texture_path: String
	
	if is_sheep:
		npc_name = "Sheep %d" % Time.get_ticks_msec()
		npc_type = "sheep"
		texture_path = "res://assets/sprites/sheep.png"
		npc.set("traits", ["herd", "group"])
	else:
		npc_name = "Goat %d" % Time.get_ticks_msec()
		npc_type = "goat"
		texture_path = "res://assets/sprites/goat.png"
		npc.set("traits", ["herd"])
	
	npc.set("npc_name", npc_name)
	npc.set("npc_type", npc_type)
	npc.set("age", 0)
	
	var sprite: Sprite2D = npc.get_node_or_null("Sprite")
	if sprite:
		var texture: Texture2D = load(texture_path) as Texture2D
		if texture:
			sprite.texture = texture
			sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
			var tint := _get_random_sheep_goat_tint()
			sprite.modulate = tint
			npc.set_meta("sheep_goat_tint", tint)
			sprite.visible = true
			if npc.has_method("apply_sprite_offset_for_texture"):
				npc.apply_sprite_offset_for_texture()
	
	world_objects.add_child(npc)
	npc.global_position = pos
	npc.set("spawn_position", pos)
	npc.visible = true
	var type_display: String = npc_type.substr(0, 1).to_upper() + npc_type.substr(1)
	print("✓ Respawned Wild %s: %s at %s" % [type_display, npc_name, pos])

func _setup_node_cache() -> void:
	# Initialize NodeCache singleton for performance optimization
	# NodeCache is used to cache node lookups (NPCs, resources, land claims)
	var node_cache = get_node_or_null("/root/NodeCache")
	if not node_cache:
		# NodeCache doesn't exist - create it
		var NodeCacheScript = load("res://scripts/npc/node_cache.gd")
		if NodeCacheScript:
			# Check if script extends Node (required for autoload singletons)
			var script_instance = NodeCacheScript.new()
			if script_instance is Node:
				node_cache = script_instance as Node
				node_cache.name = "NodeCache"
				get_tree().root.add_child.call_deferred(node_cache)
				UnifiedLogger.log_system("NodeCache created and initialized")
			else:
				# Script doesn't extend Node, skip setup
				UnifiedLogger.log_warning("NodeCache script does not extend Node, skipping setup", UnifiedLogger.Category.SYSTEM)
		else:
			UnifiedLogger.log_warning("NodeCache script not found", UnifiedLogger.Category.SYSTEM)
	else:
		UnifiedLogger.log_system("NodeCache already exists")

func _setup_debug_ui() -> void:
	# Create debug UI manually
	npc_debug_ui = NPCDebugUI.new()
	npc_debug_ui.name = "NPCDebugUI"
	ui_layer.add_child(npc_debug_ui)
	_create_debug_ui_panel()

func _setup_baby_pool_manager() -> void:
	# Create baby pool manager for reproduction system
	baby_pool_manager = BabyPoolManager.new()
	baby_pool_manager.name = "BabyPoolManager"
	add_child(baby_pool_manager)
	UnifiedLogger.log_system("Baby pool manager initialized")

func get_baby_pool_manager() -> BabyPoolManager:
	# Helper function for other systems to access baby pool manager
	return baby_pool_manager

func _create_debug_ui_panel() -> void:
	# Create debug UI panel manually
	var panel := Panel.new()
	panel.name = "DebugPanel"
	panel.custom_minimum_size = Vector2(600, 500)
	panel.position = Vector2(50, 50)
	npc_debug_ui.add_child(panel)
	
	var vbox := VBoxContainer.new()
	vbox.name = "VBox"
	panel.add_child(vbox)
	
	var title := Label.new()
	title.text = "NPC Debug Info (F1 to toggle)"
	title.add_theme_font_size_override("font_size", 18)
	vbox.add_child(title)
	
	var hbox := HBoxContainer.new()
	vbox.add_child(hbox)
	
	var list := ItemList.new()
	list.name = "NPCList"
	list.custom_minimum_size = Vector2(200, 400)
	list.item_selected.connect(_on_npc_list_item_selected)
	hbox.add_child(list)
	npc_debug_ui.npc_list = list
	
	var info := RichTextLabel.new()
	info.name = "InfoLabel"
	info.custom_minimum_size = Vector2(380, 400)
	info.bbcode_enabled = true
	hbox.add_child(info)
	npc_debug_ui.info_label = info
	
	var close_btn := Button.new()
	close_btn.name = "CloseButton"
	close_btn.text = "Close (F1)"
	close_btn.pressed.connect(npc_debug_ui._on_close_pressed)
	vbox.add_child(close_btn)
	npc_debug_ui.close_button = close_btn
	
	npc_debug_ui.debug_panel = panel

func _on_npc_list_item_selected(index: int) -> void:
	if npc_debug_ui and npc_debug_ui.npc_list:
		var npc = npc_debug_ui.npc_list.get_item_metadata(index) as Node2D
		if npc:
			npc_debug_ui.select_npc(npc)

func _on_land_claim_clicked(land_claim: LandClaim) -> void:
	# Block if any other inventory UI is already open
	if _is_any_inventory_open():
		return
	
	# Show building inventory when land claim is clicked
	if not land_claim or not building_inventory_ui:
		return
	
	if land_claim.inventory:
		# DEBUG: Verify inventory reference
		print("🔍 MAIN: Opening land claim inventory for %s" % land_claim.clan_name)
		building_inventory_ui.setup_land_claim(land_claim)
		building_inventory_ui.show_inventory()
		nearby_building = land_claim
		print("Showing inventory for land claim: ", land_claim.clan_name)

func _try_click_npc_for_inventory() -> void:
	# Block if any inventory UI is open
	if _is_any_inventory_open():
		return
	
	# Add logging at the very start to catch crashes
	print("🔍 MAIN: _try_click_npc_for_inventory() STARTED")
	
	# Safety check: ensure tree is valid
	if not is_inside_tree():
		print("❌ MAIN ERROR: Not in tree!")
		return
	
	var tree = get_tree()
	if not tree:
		print("❌ MAIN ERROR: Tree is null!")
		return
	
	print("   - Tree is valid, getting world mouse position...")
	
	# Check if clicking on NPC to show inventory
	var world_pos: Vector2
	if camera and is_instance_valid(camera):
		world_pos = _get_world_mouse_position()
		print("   - World mouse position: %s" % world_pos)
	else:
		print("❌ MAIN ERROR: Camera is null or invalid!")
		return
	
	print("   - Getting NPCs from group...")
	
	# Check all NPCs
	var npcs = tree.get_nodes_in_group("npcs")
	if npcs == null:
		print("❌ MAIN ERROR: Failed to get NPCs from group!")
		return
	
	print("   - Found %d NPCs in group" % npcs.size())
	
	for npc in npcs:
		if not is_instance_valid(npc):
			continue
		
		# global_position is a built-in property of Node2D, safe to access
		var distance: float = npc.global_position.distance_to(world_pos)
		if distance < 32.0:  # Within click range
			# Attack only if player has weapon in slot 1 (axe, pick, club)
			if player and player_inventory_ui:
				var first_slot = player_inventory_ui.hotbar_slots[player_inventory_ui.RIGHT_HAND_SLOT_INDEX] if player_inventory_ui.hotbar_slots.size() > player_inventory_ui.RIGHT_HAND_SLOT_INDEX else null
				if first_slot:
					var slot_item = first_slot.get_item()
					if not slot_item.is_empty():
						var it = slot_item.get("type", ResourceData.ResourceType.NONE) as ResourceData.ResourceType
						if it == ResourceData.ResourceType.AXE or it == ResourceData.ResourceType.PICK or it == ResourceData.ResourceType.WOOD:
							_player_attack_npc(npc)
							break
			
			clicked_npc = npc
			
			# Safely get npc_name (use get() which returns null if not found)
			var npc_name = npc.get("npc_name")
			if npc_name == null:
				npc_name = "unknown"
			
			# Check NPC type - show character menu for women, clansmen, cavemen, and babies
			var npc_type = npc.get("npc_type")
			var show_character_menu: bool = (npc_type == "woman" or npc_type == "clansman" or npc_type == "caveman" or npc_type == "baby")
			
			print("🔍 MAIN: NPC clicked - %s (type: %s)" % [npc_name, npc_type])
			
			# Freeze NPC when clicked (for all NPCs with menus)
			_freeze_npc_for_inspection(npc, true)
			
			# Show Character Menu (merged with inventory) - for women, clansmen, cavemen, and babies
			# Character menu now includes inventory slots in the same panel
			if show_character_menu and character_menu_ui:
				character_menu_ui.setup(npc)  # Setup handles both info and inventory
				character_menu_ui.show_menu()  # This freezes the NPC
				print("✅ MAIN: Character menu (with inventory) opened for %s" % npc_name)
			break

func _player_attack_npc(target_npc: Node) -> void:
	"""Legacy name - delegates to _player_attack_target."""
	_player_attack_target(target_npc)

func _player_attack_target(target: Node) -> void:
	"""Player attacks NPC or building with equipped weapon. Enables aggro on NPC hit."""
	if _is_any_inventory_open():
		return
	if not player or not target or not is_instance_valid(target):
		return
	# Skip if target is dead NPC
	var target_health: HealthComponent = target.get_node_or_null("HealthComponent")
	if target_health and target_health.is_dead:
		return
	var combat_comp: CombatComponent = player.get_node_or_null("CombatComponent")
	if combat_comp:
		combat_comp.request_attack(target as Node2D)
	else:
		print("⚠️ Player CombatComponent missing!")

func _freeze_npc_for_inspection(npc: Node, freeze: bool) -> void:
	"""Pause/unpause NPC movement when clicked for inventory/character menu inspection"""
	if not npc or not is_instance_valid(npc):
		return
	
	if freeze:
		# Pause NPC movement: Set velocity to zero and mark as frozen
		# The NPC's _physics_process will check this flag and skip movement updates
		npc.velocity = Vector2.ZERO
		npc.set_meta("inspection_frozen", true)
		print("🔒 MAIN: NPC %s movement paused" % (npc.get("npc_name") if npc else "unknown"))
	else:
		# Unpause NPC: Remove frozen flag - they'll resume movement naturally
		if npc.has_meta("inspection_frozen"):
			npc.remove_meta("inspection_frozen")
		print("🔓 MAIN: NPC %s movement resumed" % (npc.get("npc_name") if npc else "unknown"))

func _try_select_npc_for_debug() -> void:
	# Raycast to find NPC under mouse
	var world_pos := _get_world_mouse_position()
	
	# Check all NPCs
	var npcs := get_tree().get_nodes_in_group("npcs")
	for npc in npcs:
		if not is_instance_valid(npc):
			continue
		
		var distance: float = npc.global_position.distance_to(world_pos)
		if distance < 32.0:  # Within click range
			if npc_debug_ui:
				npc_debug_ui.select_npc(npc)
			break

func _generate_caveman_name() -> String:
	# Generate a name in CvCv or CvvC format (consonant-vowel pattern)
	const CONSONANTS: String = "BCDFGHJKLMNPQRSTVWXYZ"
	const VOWELS: String = "AEIOU"
	
	var pattern: int = randi() % 2  # 0 = CvCv, 1 = CvvC
	
	if pattern == 0:
		# CvCv format
		var c1: String = CONSONANTS[randi() % CONSONANTS.length()]
		var v1: String = VOWELS[randi() % VOWELS.length()]
		var c2: String = CONSONANTS[randi() % CONSONANTS.length()]
		var v2: String = VOWELS[randi() % VOWELS.length()]
		return c1 + v1 + c2 + v2
	else:
		# CvvC format
		var c1: String = CONSONANTS[randi() % CONSONANTS.length()]
		var v1: String = VOWELS[randi() % VOWELS.length()]
		var v2: String = VOWELS[randi() % VOWELS.length()]
		var c2: String = CONSONANTS[randi() % CONSONANTS.length()]
		return c1 + v1 + v2 + c2

func _generate_random_clan_name() -> String:
	# Same format as build_state: "Xy Xxxx" (2-letter + space + 4-letter) for land claim clan names
	const CONSONANTS: String = "BCDFGHJKLMNPQRSTVWXYZ"
	const VOWELS: String = "AEIOU"
	var prefix_c: String = CONSONANTS[randi() % CONSONANTS.length()]
	var prefix_v: String = VOWELS[randi() % VOWELS.length()]
	var prefix: String = prefix_c + prefix_v
	var pattern: int = randi() % 2
	if pattern == 0:
		var c1: String = CONSONANTS[randi() % CONSONANTS.length()]
		var v1: String = VOWELS[randi() % VOWELS.length()]
		var c2: String = CONSONANTS[randi() % CONSONANTS.length()]
		var v2: String = VOWELS[randi() % VOWELS.length()]
		return prefix + " " + c1 + v1 + c2 + v2
	else:
		var c1: String = CONSONANTS[randi() % CONSONANTS.length()]
		var v1: String = VOWELS[randi() % VOWELS.length()]
		var v2: String = VOWELS[randi() % VOWELS.length()]
		var c2: String = CONSONANTS[randi() % CONSONANTS.length()]
		return prefix + " " + c1 + v1 + v2 + c2

# Task system logger for women, land claims, ovens (only called when --debug)
func _log_task_system_data() -> void:
	# 1. Log all women (NPCs with npc_type == "woman")
	var npcs = get_tree().get_nodes_in_group("npcs")
	var women: Array = []
	for npc in npcs:
		if not is_instance_valid(npc):
			continue
		var npc_type: String = npc.get("npc_type") if "npc_type" in npc else ""
		if npc_type == "woman":
			women.append(npc)
	
	UnifiedLogger.log_npc("═══════════════════════════════════════════════════════")
	UnifiedLogger.log_npc("=== TASK SYSTEM LOG: %d Women ===" % women.size())
	for woman in women:
		var wname: String = str(woman.get("npc_name")) if "npc_name" in woman else "unknown"
		var clan: String = str(woman.get("clan_name")) if "clan_name" in woman else "none"
		var pos: Vector2 = woman.global_position if woman else Vector2.ZERO
		var state: String = "unknown"
		if "fsm" in woman and woman.fsm and woman.fsm.has_method("get_current_state_name"):
			state = woman.fsm.get_current_state_name()
		
		# Get inventory contents
		var inv_items: Array = []
		if "inventory" in woman and woman.inventory:
			for i in range(woman.inventory.slot_count):
				var slot = woman.inventory.get_slot(i)
				if not slot.is_empty():
					var item_type: ResourceData.ResourceType = slot.get("type", ResourceData.ResourceType.NONE)
					var count: int = slot.get("count", 0)
					if item_type != ResourceData.ResourceType.NONE:
						inv_items.append("%s x%d" % [ResourceData.get_resource_name(item_type), count])
		
		var inv_str: String = ", ".join(inv_items) if inv_items.size() > 0 else "empty"
		
		UnifiedLogger.log_npc("WOMAN: %s | State: %s | Clan: %s | Pos: (%.0f, %.0f) | Inventory: %s" % [
			wname, state, clan, pos.x, pos.y, inv_str
		], {
			"npc_name": wname,
			"state": state,
			"clan": clan,
			"position": pos,
			"inventory": inv_items
		})
	
	# 2. Log land claim inventory
	var land_claims = get_tree().get_nodes_in_group("land_claims")
	UnifiedLogger.log_inventory("=== TASK SYSTEM LOG: %d Land Claims ===" % land_claims.size())
	for claim in land_claims:
		if not is_instance_valid(claim):
			continue
		var claim_name: String = claim.get("clan_name") if "clan_name" in claim else "unknown"
		var pos: Vector2 = claim.global_position if claim else Vector2.ZERO
		
		# Get inventory contents
		var inv_items: Array = []
		if "inventory" in claim and claim.inventory:
			for i in range(claim.inventory.slot_count):
				var slot = claim.inventory.get_slot(i)
				if not slot.is_empty():
					var item_type: ResourceData.ResourceType = slot.get("type", ResourceData.ResourceType.NONE)
					var count: int = slot.get("count", 0)
					if item_type != ResourceData.ResourceType.NONE:
						inv_items.append("%s x%d" % [ResourceData.get_resource_name(item_type), count])
		
		var inv_str: String = ", ".join(inv_items) if inv_items.size() > 0 else "empty"
		
		UnifiedLogger.log_inventory("LAND CLAIM: %s | Pos: (%.0f, %.0f) | Inventory: %s" % [
			claim_name, pos.x, pos.y, inv_str
		], {
			"clan_name": claim_name,
			"position": pos,
			"inventory": inv_items
		})
	
	# 3. Log oven inventory (with debug for "0 Ovens" when user has placed ovens)
	var buildings = get_tree().get_nodes_in_group("buildings")
	var ovens: Array = []
	var with_type_count: int = 0
	for building in buildings:
		if not is_instance_valid(building):
			continue
		if "building_type" in building:
			with_type_count += 1
			if building.building_type == ResourceData.ResourceType.OVEN:
				ovens.append(building)
	UnifiedLogger.log_inventory("TASK SYSTEM DEBUG: buildings group=%d, with building_type=%d, ovens=%d" % [buildings.size(), with_type_count, ovens.size()])
	UnifiedLogger.log_inventory("=== TASK SYSTEM LOG: %d Ovens ===" % ovens.size())
	for oven in ovens:
		var pos: Vector2 = oven.global_position if oven else Vector2.ZERO
		var occupied: String = "unoccupied"
		if "occupied_by" in oven and oven.occupied_by and is_instance_valid(oven.occupied_by):
			var occupier_name: String = oven.occupied_by.get("npc_name") if "npc_name" in oven.occupied_by else "unknown"
			occupied = "occupied by %s" % occupier_name
		
		# Get inventory contents
		var inv_items: Array = []
		if "inventory" in oven and oven.inventory:
			for i in range(oven.inventory.slot_count):
				var slot = oven.inventory.get_slot(i)
				if not slot.is_empty():
					var item_type: ResourceData.ResourceType = slot.get("type", ResourceData.ResourceType.NONE)
					var count: int = slot.get("count", 0)
					if item_type != ResourceData.ResourceType.NONE:
						inv_items.append("%s x%d" % [ResourceData.get_resource_name(item_type), count])
		
		var inv_str: String = ", ".join(inv_items) if inv_items.size() > 0 else "empty"
		
		UnifiedLogger.log_inventory("OVEN | Pos: (%.0f, %.0f) | %s | Inventory: %s" % [
			pos.x, pos.y, occupied, inv_str
		], {
			"position": pos,
			"occupied_by": occupied,
			"inventory": inv_items
		})
	
	# Summary
	var total_women: int = women.size()
	var total_ovens: int = ovens.size()
	var occupied_ovens: int = 0
	for oven in ovens:
		if "occupied_by" in oven and oven.occupied_by and is_instance_valid(oven.occupied_by):
			occupied_ovens += 1
	
	UnifiedLogger.log_npc("SUMMARY: %d women, %d land claims, %d ovens (%d occupied)" % [
		total_women, land_claims.size(), total_ovens, occupied_ovens
	])
	UnifiedLogger.log_npc("═══════════════════════════════════════════════════════")

func _log_gather_test_data() -> void:
	"""Log NPC movement, logic, and resource tracking for gather test"""
	UnifiedLogger.log_npc("═══════════════════════════════════════════════════════")
	UnifiedLogger.log_npc("=== GATHER TEST LOG: NPC Movement, Logic & Resources ===")
	
	var npcs = get_tree().get_nodes_in_group("npcs")
	var test_clan_name := "TEST"
	
	# Filter NPCs in TEST clan
	var test_npcs: Array = []
	for npc in npcs:
		if not is_instance_valid(npc):
			continue
		var clan: String = npc.get("clan_name") if "clan_name" in npc else ""
		if clan == test_clan_name:
			test_npcs.append(npc)
	
	UnifiedLogger.log_npc("=== TEST CLAN NPCs: %d ===" % test_npcs.size())
	
	# Log each NPC: movement, state, inventory, and resource activity
	for npc in test_npcs:
		var npc_name_log: String = str(npc.get("npc_name")) if "npc_name" in npc else "unknown"
		var npc_type: String = str(npc.get("npc_type")) if "npc_type" in npc else "unknown"
		var pos: Vector2 = npc.global_position if npc else Vector2.ZERO
		
		# Track movement
		var npc_id: String = "%s_%s" % [npc_name_log, npc_type]
		var prev_pos: Vector2 = gather_test_npc_positions.get(npc_id, pos)
		var moved: bool = pos.distance_to(prev_pos) > 5.0  # Moved more than 5px
		if moved:
			var distance: float = pos.distance_to(prev_pos)
			UnifiedLogger.log_npc("MOVEMENT: %s (%s) moved %.1fpx from (%.0f,%.0f) to (%.0f,%.0f)" % [
				npc_name_log, npc_type, distance, prev_pos.x, prev_pos.y, pos.x, pos.y
			], {
				"npc": npc_name_log,
				"type": npc_type,
				"event": "movement",
				"distance": "%.1f" % distance,
				"from": "%s" % prev_pos,
				"to": "%s" % pos
			})
		gather_test_npc_positions[npc_id] = pos
		
		# Get current state
		var state: String = "unknown"
		if "fsm" in npc and npc.fsm and npc.fsm.has_method("get_current_state_name"):
			state = npc.fsm.get_current_state_name()
		
		# Check for state changes (simplified - just log current state)
		UnifiedLogger.log_npc("LOGIC: %s (%s) | State: %s" % [npc_name_log, npc_type, state], {
			"npc": npc_name_log,
			"type": npc_type,
			"state": state,
			"position": "%s" % pos
		})
		
		# Get inventory contents and track resource flow
		var inv_items: Array = []
		var resource_flow: Array = []
		if "inventory" in npc and npc.inventory:
			for i in range(npc.inventory.slot_count):
				var slot = npc.inventory.get_slot(i)
				if not slot.is_empty():
					var item_type: ResourceData.ResourceType = slot.get("type", ResourceData.ResourceType.NONE)
					var count: int = slot.get("count", 0)
					if item_type != ResourceData.ResourceType.NONE:
						var resource_name = ResourceData.get_resource_name(item_type)
						inv_items.append("%s x%d" % [resource_name, count])
						resource_flow.append({
							"resource": resource_name,
							"count": count,
							"location": "npc_inventory",
							"npc": npc_name_log
						})
		
		var inv_str: String = ", ".join(inv_items) if inv_items.size() > 0 else "empty"
		UnifiedLogger.log_inventory("RESOURCES: %s (%s) | Inventory: %s" % [npc_name_log, npc_type, inv_str], {
			"npc": npc_name_log,
			"type": npc_type,
			"inventory": inv_items,
			"resource_flow": resource_flow
		})
	
	# Log land claim inventory (where resources are being deposited)
	var land_claims = get_tree().get_nodes_in_group("land_claims")
	for claim in land_claims:
		if not is_instance_valid(claim):
			continue
		var claim_clan: String = claim.get("clan_name") if "clan_name" in claim else ""
		if claim_clan == test_clan_name:
			var claim_pos: Vector2 = claim.global_position if claim else Vector2.ZERO
			var inv_items: Array = []
			var resource_totals: Dictionary = {}
			
			if "inventory" in claim and claim.inventory:
				for i in range(claim.inventory.slot_count):
					var slot = claim.inventory.get_slot(i)
					if not slot.is_empty():
						var item_type: ResourceData.ResourceType = slot.get("type", ResourceData.ResourceType.NONE)
						var count: int = slot.get("count", 0)
						if item_type != ResourceData.ResourceType.NONE:
							var resource_name = ResourceData.get_resource_name(item_type)
							inv_items.append("%s x%d" % [resource_name, count])
							resource_totals[resource_name] = count
			
			var inv_str: String = ", ".join(inv_items) if inv_items.size() > 0 else "empty"
			UnifiedLogger.log_inventory("LAND CLAIM: %s at (%.0f,%.0f) | Inventory: %s" % [
				test_clan_name, claim_pos.x, claim_pos.y, inv_str
			], {
				"clan": test_clan_name,
				"position": "%s" % claim_pos,
				"inventory": inv_items,
				"resource_totals": resource_totals
			})
	
	# Log nearby resources (what's available to gather)
	var resources = get_tree().get_nodes_in_group("resources")
	var nearby_resources: Array = []
	var land_claim_pos: Vector2 = Vector2.ZERO
	for claim in land_claims:
		if not is_instance_valid(claim):
			continue
		var claim_clan: String = claim.get("clan_name") if "clan_name" in claim else ""
		if claim_clan == test_clan_name:
			land_claim_pos = claim.global_position
			break
	
	for resource in resources:
		if not is_instance_valid(resource):
			continue
		var res_pos: Vector2 = resource.global_position if resource else Vector2.ZERO
		var distance: float = land_claim_pos.distance_to(res_pos)
		if distance < 300.0:  # Within 300px of land claim
			var res_type: ResourceData.ResourceType = resource.get("resource_type") if "resource_type" in resource else ResourceData.ResourceType.NONE
			var amount: int = resource.get("amount") if "amount" in resource else 0
			if res_type != ResourceData.ResourceType.NONE and amount > 0:
				nearby_resources.append({
					"type": ResourceData.get_resource_name(res_type),
					"amount": amount,
					"position": "%s" % res_pos,
					"distance": "%.1f" % distance
				})
	
	UnifiedLogger.log_info("AVAILABLE RESOURCES: %d resources within 300px of land claim" % nearby_resources.size(), UnifiedLogger.Category.RESOURCE, {
		"count": nearby_resources.size(),
		"resources": nearby_resources
	})
	
	# Summary
	UnifiedLogger.log_npc("SUMMARY: %d TEST clan NPCs monitored | %d nearby resources" % [
		test_npcs.size(), nearby_resources.size()
	])
	UnifiedLogger.log_npc("═══════════════════════════════════════════════════════")

# TASK SYSTEM TEST: Test Task base class (Step 12)
func _test_task_base_class() -> void:
	print("=== Testing Task Base Class (Step 12) ===")
	
	# Test 1: Create a no-op task, start it, tick it, should succeed immediately
	var task1 = Task.new()
	print("Test 1: No-op task")
	print("  Before start: status=%s, is_started=%s" % [task1.get_status_string(), task1.is_started])
	
	task1.start(player)
	print("  After start: status=%s, is_started=%s" % [task1.get_status_string(), task1.is_started])
	
	var result = task1.tick(player, 0.1)
	print("  After tick: status=%s, result=%s" % [task1.get_status_string(), Task.TaskStatus.keys()[result]])
	
	if result == Task.TaskStatus.SUCCESS:
		print("  ✓ Test 1 PASSED: No-op task succeeds immediately")
	else:
		print("  ✗ Test 1 FAILED: Expected SUCCESS, got %s" % task1.get_status_string())
	
	# Test 2: Cancel a task mid-run
	var task2 = Task.new()
	print("\nTest 2: Cancel task")
	task2.start(player)
	print("  After start: status=%s" % task2.get_status_string())
	
	task2.cancel(player)
	print("  After cancel: status=%s, is_cancelled=%s" % [task2.get_status_string(), task2.is_cancelled])
	
	if task2.status == Task.TaskStatus.FAILED and task2.is_cancelled:
		print("  ✓ Test 2 PASSED: Task cancelled correctly")
	else:
		print("  ✗ Test 2 FAILED: Expected FAILED and is_cancelled=true")
	
	# Test 3: Tick after cancel should return FAILED
	var task3 = Task.new()
	print("\nTest 3: Tick after cancel")
	task3.start(player)
	task3.cancel(player)
	var result3 = task3.tick(player, 0.1)
	
	if result3 == Task.TaskStatus.FAILED:
		print("  ✓ Test 3 PASSED: Tick after cancel returns FAILED")
	else:
		print("  ✗ Test 3 FAILED: Expected FAILED, got %s" % Task.TaskStatus.keys()[result3])
	
	print("=== Task Base Class Tests Complete ===\n")

# TASK SYSTEM TEST: Test TaskRunner component (Step 13) and Job (Step 14)
func _test_task_runner() -> void:
	print("=== Testing TaskRunner Component (Step 13) and Job (Step 14) ===")
	
	# Get first woman NPC for testing
	var npcs = get_tree().get_nodes_in_group("npcs")
	var test_npc: Node = null
	for npc in npcs:
		if not is_instance_valid(npc):
			continue
		var npc_type: String = npc.get("npc_type") if "npc_type" in npc else ""
		if npc_type == "woman":
			test_npc = npc
			break
	
	if not test_npc:
		print("  ✗ Test FAILED: No woman NPC found for testing")
		return
	
	var npc_name: String = test_npc.get("npc_name") if "npc_name" in test_npc else "unknown"
	
	# Check if TaskRunner already exists
	var task_runner: TaskRunner = test_npc.get_node_or_null("TaskRunner")
	if not task_runner:
		# Create and add TaskRunner component
		task_runner = TaskRunner.new()
		task_runner.name = "TaskRunner"
		test_npc.add_child(task_runner)
		print("  Created TaskRunner component on %s" % npc_name)
	else:
		print("  Using existing TaskRunner on %s" % npc_name)
	
	# Test 1: Create Job with 3 tasks, assign to TaskRunner, should complete all
	print("\nTest 1: Create Job with 3 tasks")
	var task1 = Task.new()
	var task2 = Task.new()
	var task3 = Task.new()
	var job = Job.new([task1, task2, task3])
	
	print("  Created Job with %d tasks, progress: %s" % [job.get_task_count(), job.get_progress_string()])
	
	task_runner.assign_job(job)
	print("  Assigned job, status: %s" % task_runner.get_status_string())
	
	# Manually tick a few times (tasks should complete immediately)
	for i in range(5):
		task_runner._process(0.1)
		print("  Tick %d: status=%s, job_progress=%s" % [i + 1, task_runner.get_status_string(), job.get_progress_string() if job else "null"])
		if not task_runner.has_job():
			break
	
	if not task_runner.has_job() and job.is_complete():
		print("  ✓ Test 1 PASSED: Job completed successfully, is_complete()=%s" % job.is_complete())
	else:
		print("  ✗ Test 1 FAILED: Job still active or not complete")
	
	# Test 2: Cancel job mid-run
	print("\nTest 2: Cancel job")
	var task4 = Task.new()
	var task5 = Task.new()
	var job2 = Job.new([task4, task5])
	
	task_runner.assign_job(job2)
	print("  Assigned job, status: %s" % task_runner.get_status_string())
	task_runner._process(0.1)  # One tick to start first task
	task_runner.cancel_current_job()
	
	if not task_runner.has_job():
		print("  ✓ Test 2 PASSED: Job cancelled correctly")
	else:
		print("  ✗ Test 2 FAILED: Job still active after cancel")
	
	print("=== TaskRunner + Job Tests Complete ===\n")
