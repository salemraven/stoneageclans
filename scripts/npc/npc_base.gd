extends CharacterBody2D
class_name NPCBase

# Preload PerceptionArea so it resolves before npc_base (avoids "Could not find type" when run from CLI)
const PerceptionArea = preload("res://scripts/npc/components/perception_area.gd")
const HerdableComponentScript = preload("res://scripts/npc/components/herdable_component.gd")
const CombatAllyCheck = preload("res://scripts/systems/combat_ally_check.gd")

# Uses global WalkAnimation (class_name in walk_animation.gd)

# Base class for all NPCs (animals, humans, predators)
# Modular component system - attach components in inspector

@warning_ignore("unused_signal")
signal npc_died(npc: NPCBase)
@warning_ignore("unused_signal")
signal stat_changed(stat_name: String, old_value: float, new_value: float)
@warning_ignore("unused_signal")
signal clan_name_changed(old_clan: String, new_clan: String)  # Emitted when clan_name changes

# Component references (set in inspector or _ready)
var steering_agent: Node = null
var stats_component: Node = null
var reproduction_component: Node = null  # Only for women NPCs
var baby_growth_component: Node = null  # Only for baby NPCs
var fsm: Node = null
var sprite: Sprite2D = null
var task_runner: Node = null  # Task System - Step 17: TaskRunner component (Node type to avoid circular dependency)

# Basic properties
@export var npc_name: String = "NPC"
@export var npc_type: String = "generic"  # "animal", "human", "predator"
@export var age: int = 0  # Age in years (0 for animals, 13+ for humans)
@export var quality_tier: String = "Flawed"  # Flawed, Good, Legendary (age-based, affects stats)
@export var skin_tone: String = "Medium"  # Dark, Medium, Light (visual only)

# Traits array (editable in inspector)
@export var traits: Array[String] = []
## Bravery 0..1 for flee thresholds; &lt;0 = use NPCConfig.flee_default_bravery in logic
var bravery: float = -1.0

# Buffs/Debuffs array: {name, stat, mult, duration, visual}
var buffs_debuffs: Array[Dictionary] = []

# Wants array: {name, meter, max, deplete_rate, threshold}
var wants: Array[Dictionary] = []

# Inventory
var inventory: InventoryData = null
var hotbar: InventoryData = null  # 10-slot equipment hotbar for cavemen and clansmen
var carried_travois_inventory: InventoryData = null  # When set, NPC is carrying a travois (8 slots)

# Clan and herding
var clan_name: String = ""  # Empty = not part of any clan (wild NPCs: women/animals, AI players: cavemen)

# Debug: print assignment flow to Godot Output (toggle false when done)
const DEBUG_ASSIGN_CONSOLE := true

# Animals must be within this range to call add_animal (was 90 - logs showed closest 301px; 220 gives sheep more margin)
const ANIMAL_ENTER_RANGE := 220.0

# Cached "my land claim" lookup (invalidated on clan change)
var _cached_land_claim: Node = null
var _cached_land_claim_clan: String = ""

# Helper function to get clan_name (always checks meta as backup)
func get_clan_name() -> String:
	var value = clan_name
	var meta_value = ""
	var backup_value = ""
	
	# ALWAYS check meta property as backup (even if value exists, verify they match)
	if has_meta("clan_name"):
		meta_value = get_meta("clan_name", "")
	if has_meta("land_claim_clan_name"):
		backup_value = get_meta("land_claim_clan_name", "")
	
	if meta_value != "" or backup_value != "":
		if value == "":
			# Value is empty but meta has it - sync it
			var caller = _get_caller_info()
			var recovered_value = backup_value if backup_value != "" else meta_value
			print("⚠️ CLAN_NAME GET: %s.clan_name is EMPTY but meta has '%s' (backup='%s') (caller: %s) - SYNCING" % [npc_name, meta_value, backup_value, caller])
			clan_name = recovered_value
			value = recovered_value
			# Also sync the other meta if needed
			if backup_value != "" and meta_value == "":
				set_meta("clan_name", backup_value)
			elif meta_value != "" and backup_value == "":
				set_meta("land_claim_clan_name", meta_value)
			elif value != meta_value:
				# Mismatch - meta takes precedence (it's more reliable)
				print("⚠️ CLAN_NAME GET: %s.clan_name MISMATCH - direct='%s' but meta='%s' (caller: %s) - USING META" % [npc_name, value, meta_value, caller])
				clan_name = meta_value
				value = meta_value
	return value

# Helper function to set clan_name (always syncs with meta)
func set_clan_name(value: String, caller_name: String = "unknown") -> void:
	_cached_land_claim = null
	_cached_land_claim_clan = ""
	var old_value = clan_name
	var old_meta = get_meta("clan_name", "") if has_meta("clan_name") else ""
	var old_backup = get_meta("land_claim_clan_name", "") if has_meta("land_claim_clan_name") else ""
	
	clan_name = value
	# ALWAYS update meta property (even if value is same, ensure it's synced)
	if value != "":
		set_meta("clan_name", value)
		# Also set backup meta
		set_meta("land_claim_clan_name", value)
		# Verify meta was set
		var meta_check = get_meta("clan_name", "")
		var _backup_check = get_meta("land_claim_clan_name", "")
		if meta_check != value:
			push_error("CRITICAL: Failed to set meta clan_name for %s! Expected '%s', got '%s'" % [npc_name, value, meta_check])
		# Removed verbose set_clan_name log - only log on significant changes
	elif value == "":
		# CRITICAL FIX: Don't remove meta if it was set - it might be temporarily empty but should be recovered
		# Check if we had meta before setting to empty
		var had_meta_before = has_meta("clan_name")
		var meta_value_before = get_meta("clan_name", "") if had_meta_before else ""
		if had_meta_before and meta_value_before != "":
			print("⚠️ CLAN_NAME SET TO EMPTY: %s.clan_name set to '' (caller: %s) - KEEPING meta='%s' for recovery" % [npc_name, caller_name, meta_value_before])
		# DO NOT remove meta - allow recovery from meta later
		# This ensures meta properties persist even if direct property is temporarily empty
		print("🔵 SET_CLAN_NAME (EMPTY): %s - direct='%s'->'', meta='%s' (kept), backup='%s' (kept) (caller: %s)" % [npc_name, old_value, old_meta, old_backup, caller_name])

# Unified clan join: wild -> clan -> building assign. Single entry point for all join paths.
# skip_herd_release: when true (e.g. follow_is_ordered), join but keep herding
# Returns true if joined (caller may need to clear herd / change state).
func _try_join_clan_from_claim(skip_herd_release: bool = false) -> bool:
	if not can_join_clan() or clan_name != "":
		return false
	var land_claims := get_tree().get_nodes_in_group("land_claims")
	for claim in land_claims:
		if not is_instance_valid(claim):
			continue
		var claim_pos: Vector2 = claim.global_position
		var distance: float = global_position.distance_to(claim_pos)
		var radius: float = claim.get("radius") as float if claim.get("radius") != null else 400.0
		if distance >= radius:
			continue
		var claim_clan: String = claim.get("clan_name") as String if claim.get("clan_name") != null else ""
		if claim_clan == "":
			continue
		var should_join := false
		if is_herded and herder and is_instance_valid(herder):
			var herder_clan: String = ""
			if herder.is_in_group("player"):
				if claim.get("player_owned"):
					herder_clan = claim_clan
			elif herder.has_method("get_clan_name"):
				herder_clan = herder.get_clan_name()
			else:
				var hp = herder.get("clan_name")
				herder_clan = hp as String if hp != null else ""
			should_join = (claim_clan == herder_clan)
		elif not is_herded:
			should_join = claim.get("player_owned") if claim.get("player_owned") != null else false
		if not should_join:
			continue
		# Join
		set_clan_name(claim_clan, "npc_base._try_join_clan_from_claim")
		var reason := "wandered into player claim" if not is_herded else "entered herder's land claim"
		print("NPC %s joined clan %s (%s)" % [npc_name, claim_clan, reason])
		# Track herding delivery for leaderboard
		if is_herded and herder and is_instance_valid(herder):
			var herder_name: String = str(herder.get("npc_name")) if herder.get("npc_name") != null else (str(herder.name) if herder else "?")
			if herder.is_in_group("player"):
				herder_name = "Player"
			var ct = get_node_or_null("/root/CompetitionTracker")
			if ct and ct.has_method("record_herding_delivery"):
				ct.record_herding_delivery(herder_name, claim_clan, npc_type)
		var playtest = get_node_or_null("/root/PlaytestInstrumentor")
		if playtest and playtest.is_enabled() and playtest.has_method("npc_joined_clan"):
			playtest.npc_joined_clan(npc_name, claim_clan, npc_type, "herded" if is_herded else "placed_claim")
		var herder_ref_for_hut: Node = null
		if npc_type == "woman":
			if reproduction_component and reproduction_component.has_method("initialize"):
				reproduction_component.initialize(self)
			UnifiedLogger.log_system("Player interaction: npc_joined_clan", {
				"action": "npc_joined_clan", "clan": claim_clan, "npc": npc_name, "npc_type": npc_type,
				"herder": str(herder.name) if herder else "unknown", "land_claim_pos": "%.1f,%.1f" % [claim_pos.x, claim_pos.y]
			})
			# Herder builds a Living Hut per delivered woman (queued; one timer per hut)
			if is_herded and herder and is_instance_valid(herder):
				herder_ref_for_hut = herder
				var hut_q: Array = []
				if herder.has_meta("build_hut_queue"):
					hut_q = (herder.get_meta("build_hut_queue") as Array).duplicate()
				hut_q.append({"woman": self, "claim": claim})
				herder.set_meta("build_hut_queue", hut_q)
		if is_herded and not skip_herd_release:
			# Phase 3: Delivery cooldown - herder gets cooldown before we clear (animal-side authority)
			if herder and is_instance_valid(herder):
				var cooldown: float = 28.0
				if NPCConfig and "herd_delivery_cooldown_sec" in NPCConfig:
					cooldown = NPCConfig.herd_delivery_cooldown_sec as float
				herder.set_meta("herd_wildnpc_delivery_cooldown_until", Time.get_ticks_msec() / 1000.0 + cooldown)
				var pi = get_node_or_null("/root/PlaytestInstrumentor")
				if pi and pi.is_enabled():
					var hname: String = str(herder.get("npc_name")) if herder.get("npc_name") != null else (str(herder.name) if herder else "?")
					pi.herd_delivery_cooldown(hname, cooldown)
			_clear_herd()
		# NPC herder: immediately start timed Living Hut build (icon + progress); no resource cost (main._place_herder_hut).
		if herder_ref_for_hut and is_instance_valid(herder_ref_for_hut) and not skip_herd_release and npc_type == "woman":
			var hut_q_chk: Array = herder_ref_for_hut.get_meta("build_hut_queue", []) if herder_ref_for_hut.has_meta("build_hut_queue") else []
			if hut_q_chk.size() > 0:
				var hc_after: int = herder_ref_for_hut.herded_count if "herded_count" in herder_ref_for_hut else 0
				var hfsm = herder_ref_for_hut.get("fsm")
				if hc_after == 0 and hfsm and hfsm.has_method("change_state"):
					hfsm.change_state("build_hut_for_woman")
		if fsm and not skip_herd_release and fsm.has_method("change_state"):
			if "evaluation_timer" in fsm:
				fsm.evaluation_timer = 0.0
			fsm.change_state("wander")
		# CRITICAL: Sheep/goat/woman get building assignment immediately (clan block also runs, but immediate = smoother)
		if (npc_type == "sheep" or npc_type == "goat" or npc_type == "woman") and not skip_herd_release:
			_check_and_assign_to_building()
		return true
	return false

func _get_caller_info() -> String:
	var stack = get_stack()
	if stack.size() > 1:
		var caller = stack[1]
		if caller is Dictionary and "source" in caller and caller.get("source"):
			var source = caller.get("source")
			var line = caller.get("line", 0)
			if source:
				return "%s:%d" % [source.get_file().get_file(), line]
	return "unknown"

# Cached lookup for this NPC's land claim (by clan). Invalidated when clan changes.
func get_my_land_claim() -> Node:
	var clan: String = get_clan_name()
	if clan == "":
		_cached_land_claim = null
		_cached_land_claim_clan = ""
		return null
	if _cached_land_claim != null and is_instance_valid(_cached_land_claim) and _cached_land_claim_clan == clan:
		return _cached_land_claim
	_cached_land_claim = null
	_cached_land_claim_clan = ""
	var fallback_campfire: Node = null
	var land_claims = get_tree().get_nodes_in_group("land_claims")
	for claim in land_claims:
		if not is_instance_valid(claim):
			continue
		var claim_clan: String = claim.get("clan_name") if "clan_name" in claim else ""
		if claim_clan != clan:
			continue
		if claim is LandClaim:
			_cached_land_claim = claim
			_cached_land_claim_clan = clan
			return claim
		fallback_campfire = claim
	if fallback_campfire:
		_cached_land_claim = fallback_campfire
		_cached_land_claim_clan = clan
		return fallback_campfire
	return null

# Helper function to check if NPC is dead
func is_dead() -> bool:
	var health_comp: HealthComponent = get_node_or_null("HealthComponent")
	if health_comp:
		return health_comp.is_dead
	return false
var is_herded: bool = false  # True if being herded by player or clansman
var herder: Node2D = null  # Reference to the NPC/player herding this NPC
var herded_count: int = 0  # Phase 3: Count of NPCs being herded by this NPC (for herders)
var follow_is_ordered: bool = false  # True = player-ordered follow; no distance break, no steal (Step 5)

# Distance-based update scaling (stub): when far from player, run FSM less often
var _distance_based_update_scale: float = 1.0  # 1.0 = full rate; 0.25 = quarter rate when far
var _distance_update_accumulator: float = 0.0
var _distance_update_interval: float = 0.0  # When scale < 1, skip FSM until accumulated >= this

# State memory with validation: NPCs remember targets and resume after interruption (e.g. combat)
var state_memory: Dictionary = {}  # state_name -> { target: Node2D, data: Dictionary }

func get_herdable():
	return get_node_or_null("HerdableComponent")


func get_follow_mode_string() -> String:
	match follow_mode:
		FollowMode.GUARD:
			return "GUARD"
		FollowMode.ATTACK:
			return "ATTACK"
		_:
			return "FOLLOW"


func set_follow_mode_from_string(s: String) -> void:
	var u := s.to_upper()
	if u == "GUARD":
		follow_mode = FollowMode.GUARD
	elif u == "ATTACK":
		follow_mode = FollowMode.ATTACK
	else:
		follow_mode = FollowMode.FOLLOW


# Phase 3: Helper functions for herd management (keeps herded_count in sync)
func _start_herd(new_herder: Node2D) -> void:
	"""Start being herded by a new herder. HerdableComponent owns woman/sheep/goat herd state."""
	var hc = get_herdable()
	if hc:
		hc.attach(new_herder)
		return
	# Fallback: rare path without HerdableComponent
	if is_herded and herder == new_herder:
		return
	var old_count: int = 0
	if is_herded and herder and is_instance_valid(herder) and herder != new_herder:
		if "herded_count" in herder:
			old_count = herder.herded_count
			herder.herded_count = max(0, herder.herded_count - 1)
			var pi = get_node_or_null("/root/PlaytestInstrumentor")
			if pi and pi.is_enabled():
				var hname: String = str(herder.get("npc_name")) if herder.get("npc_name") != null else (str(herder.name) if herder else "?")
				pi.herd_count_change(hname, old_count, herder.herded_count, "switch_away")
	is_herded = true
	herder = new_herder
	herd_mentality_active = true
	if HerdManager:
		HerdManager.register_follower(new_herder, self)
	if new_herder and is_instance_valid(new_herder) and "herded_count" in new_herder:
		old_count = new_herder.herded_count
		new_herder.herded_count += 1
		var pi2 = get_node_or_null("/root/PlaytestInstrumentor")
		if pi2 and pi2.is_enabled():
			var hname2: String = str(new_herder.get("npc_name")) if new_herder.get("npc_name") != null else (str(new_herder.name) if new_herder else "?")
			pi2.herd_count_change(hname2, old_count, new_herder.herded_count, "attach")
		if not new_herder.is_in_group("player"):
			var herder_type: String = new_herder.get("npc_type") as String if new_herder.get("npc_type") != null else ""
			if herder_type == "caveman" or herder_type == "clansman":
				# Never force-enter herd_wildnpc if ordered to follow player or in ATTACK/GUARD
				var blocked: bool = new_herder.get("follow_is_ordered") as bool if new_herder.get("follow_is_ordered") != null else false
				if not blocked:
					var ctx_nb: Dictionary = new_herder.get("command_context") if new_herder.get("command_context") != null else {}
					var mode_nb: String = ctx_nb.get("mode", "FOLLOW") as String
					if mode_nb != "FOLLOW":
						blocked = true
				if not blocked:
					var herder_fsm = new_herder.get_node_or_null("FSM")
					if herder_fsm and herder_fsm.has_method("change_state"):
						herder_fsm.change_state("herd_wildnpc")

func _clear_herd() -> void:
	"""Stop being herded. HerdableComponent or manual for clansmen ordered follow."""
	# Must bail before detach/print: herd_state (and others) may call every frame after break
	# while FSM is still "herd"; HerdableComponent.detach() no-ops but we must not spam roam init + log.
	if not is_herded:
		return
	var hc = get_herdable()
	if hc:
		hc.detach()
	else:
		if herder and is_instance_valid(herder):
			if HerdManager:
				HerdManager.unregister_follower(herder, self)
			if "herded_count" in herder:
				var old_c: int = herder.herded_count
				herder.herded_count = max(0, herder.herded_count - 1)
				var pi = get_node_or_null("/root/PlaytestInstrumentor")
				if pi and pi.is_enabled():
					var hname: String = str(herder.get("npc_name")) if herder.get("npc_name") != null else (str(herder.name) if herder else "?")
					pi.herd_count_change(hname, old_c, herder.herded_count, "clear_herd")
		is_herded = false
		herder = null
		follow_is_ordered = false
		herd_mentality_active = false
	if clan_name == "" and ChunkUtils:
		_init_chunk_roaming()
	print("🏠 %s: Herd cleared (no longer following)" % npc_name)


func become_wild() -> void:
	"""Clan → wild transition. Clears clan/claim, resets defend/worker, reinitializes chunk roaming."""
	set_clan_name("", "become_wild")
	_cached_land_claim = null
	_cached_land_claim_clan = ""
	defend_target = null
	assigned_to_search = false
	search_home_claim = null
	workplace_building = null
	if get_herdable():
		_clear_herd()
	else:
		is_herded = false
		herder = null
		follow_is_ordered = false
		herd_mentality_active = false

	_init_chunk_roaming()
	if ChunkUtils:
		roam_radius = ChunkUtils.ROAM_RADIUS  # Overwrite any claim-based radius

	var fsm_node = get_node_or_null("FSM")
	if fsm_node and fsm_node.has_method("change_state"):
		fsm_node.change_state("wander")
	elif fsm_node and fsm_node.has_method("_evaluate_states"):
		fsm_node.evaluation_timer = 0.0
		fsm_node._evaluate_states()


# State memory with validation: get/set/validate so states can resume after interruption
func get_state_memory(state_name: String) -> Dictionary:
	return state_memory.get(state_name, {})

func set_state_memory(state_name: String, data: Dictionary) -> void:
	state_memory[state_name] = data

func validate_state_memory_target(state_name: String) -> bool:
	var mem: Dictionary = get_state_memory(state_name)
	var target = mem.get("target", null)
	return target != null and is_instance_valid(target)

var herd_mentality_active: bool = false  # True when following (herd mentality)
var last_leader_switch_time: float = 0.0  # Time when last switched leaders (cooldown to prevent constant switching)
var leader_switch_cooldown: float = 8.0  # Seconds before can switch again (prevents frequent switching) - increased from 4.0 to 8.0 for more loyalty
var workplace_building: Node2D = null  # OccupationSystem: building this NPC is assigned to (women + animals)
var spawn_time: float = 0.0  # Time when NPC was spawned (for build cooldown)
var build_cooldown_after_spawn: float = 30.0  # Seconds after spawn before cavemen can place land claims
var spawn_position: Vector2 = Vector2.ZERO  # Initial spawn position (for boundary checking)

# Chunk-bound roaming (wild NPCs) — replaces spawn anchoring
var home_chunk: Vector2i = Vector2i.ZERO
var chunk_center: Vector2 = Vector2.ZERO
var roam_radius: float = 0.0
var time_in_current_chunk: float = 0.0

# Caveman aggression tracking — single meter drives combat + agro_state; is_agro is derived
var agro_meter: float = 0.0  # Agro meter (0.0 to 100.0) — combat, hostile indicator, agro_state
var is_agro: bool:
	get:
		return agro_meter > 0.0001
var agro_target: Node2D = null  # Target to attack when agro
var combat_target: Node2D = null  # NPCBase or player when defending vs intruders (resolve from combat_target_id at edge)
var combat_target_id: int = -1  # Step 3: logic uses ID; resolve to Node at edge only
var combat_locked: bool = false  # True during windup/recovery (prevents FSM state switching)
# Follow / Guard / Attack — persistent per clansman (ordered follow uses command_context.mode)
enum FollowMode { FOLLOW = 0, GUARD = 1, ATTACK = 2 }
var follow_mode: int = FollowMode.FOLLOW

# Step 4: CommandContext (commander_id, mode FOLLOW|GUARD|ATTACK, is_hostile, issued_at_time)
var command_context: Dictionary = {}  # Empty or { commander_id, mode, is_hostile, issued_at_time }
var defend_target: Node2D = null  # Land claim to defend (Step 7); when set, NPC holds border
var assigned_to_search: bool = false  # Step 11: player-assigned SEARCHING role

# Step 3: Resolve combat_target from combat_target_id; invalid target → agro 69, clear intent.
func resolve_combat_target() -> Node2D:
	if combat_target_id < 0:
		combat_target = null
		return null
	var n: Node = EntityRegistry.get_entity_node(combat_target_id) if EntityRegistry else null
	if not n or not is_instance_valid(n):
		_invalidate_combat_target()
		return null
	combat_target = n as Node2D
	return combat_target

func reset_agro_after_combat() -> void:
	"""Mode-aware agro reset when leaving combat (FOLLOW/GUARD/ATTACK ordered followers)."""
	var ctx: Dictionary = {}
	if get("command_context") != null:
		ctx = get("command_context") as Dictionary
	var mode: String = str(ctx.get("mode", "FOLLOW"))
	var v: float = 0.0
	if mode == "GUARD":
		v = 40.0
	elif mode == "ATTACK":
		v = 69.0
	else:
		v = 0.0
	set("agro_meter", v)
	agro_meter = v

## Skip proximity/AOA/intrusion pumps while already fighting or fleeing — decay handles exit.
func _skip_agro_meter_pumps() -> bool:
	if not fsm or not fsm.has_method("get_current_state_name"):
		return false
	var st: String = str(fsm.get_current_state_name())
	return st == "combat" or st == "flee_combat"

func _invalidate_combat_target() -> void:
	reset_agro_after_combat()
	combat_target_id = -1
	set("combat_target_id", -1)
	combat_target = null
	set("combat_target", null)
	var comp = get_node_or_null("CombatComponent")
	if comp and comp.has_method("clear_target"):
		comp.clear_target()
	if fsm and fsm.has_method("_evaluate_states"):
		if "evaluation_timer" in fsm:
			fsm.evaluation_timer = 0.0
		fsm._evaluate_states()

# Single source of truth for "work (tasks/jobs) should be aborted" - defending, combat, or ordered follow
func should_abort_work() -> bool:
	if defend_target != null and is_instance_valid(defend_target):
		return true
	if combat_target != null and is_instance_valid(combat_target):
		return true
	return follow_is_ordered == true
var search_home_claim: Node = null  # Land claim to return to when searching (ant-style loop)
var lost_wildnpc: Node2D = null  # The wild NPC that was lost (to try to get back)
var is_hostile: bool = false  # True when agro level is high enough for hostile mode

# Visual
var _sprite_base_position := Vector2.ZERO
var _walk_timer := 0.0
var _last_facing := Vector2(0, 1)  # For directional sprites when idle (S = down)
var is_walking_animation: bool = false  # True while showing walk spritesheet (so weapon/combat don't overwrite)
var progress_display: Node2D = null  # Progress circle for eating/harvesting
var follow_line: Line2D = null  # Line showing connection to herder
var hostile_indicator: Label = null  # "!!!" indicator for hostile mode

func _ready() -> void:
	if EntityRegistry:
		EntityRegistry.register(self)
	# CRITICAL: Recover clan_name from meta if direct property is empty
	# This ensures meta properties persist across node recreation or state transitions
	if clan_name == "" and has_meta("clan_name"):
		var meta_clan = get_meta("clan_name", "")
		if meta_clan != "":
			clan_name = meta_clan
			print("🔵 NPC_READY: %s recovered clan_name from meta: '%s'" % [npc_name, meta_clan])
	# Also check backup meta
	if clan_name == "" and has_meta("land_claim_clan_name"):
		var meta_backup = get_meta("land_claim_clan_name", "")
		if meta_backup != "":
			clan_name = meta_backup
			set_meta("clan_name", meta_backup)  # Sync regular meta too
			# Removed verbose NPC_READY backup recovery log
	
	add_to_group("npcs")
	
	# Configure collision so NPCs can pass through each other, buildings, and resources
	# NPCs can walk through everything - separation behavior will prevent stopping on top of objects
	collision_layer = 2  # NPCs are on layer 2 (for detection by other systems if needed)
	collision_mask = 0  # Don't collide with anything - NPCs can walk through everything
	
	# Get component references
	steering_agent = get_node_or_null("SteeringAgent")
	stats_component = get_node_or_null("Stats")
	reproduction_component = get_node_or_null("ReproductionComponent")
	baby_growth_component = get_node_or_null("BabyGrowthComponent")
	fsm = get_node_or_null("FSM")
	sprite = get_node_or_null("Sprite")
	
	# HerdableComponent + HerdInfluenceArea for herdables (woman, sheep, goat)
	if npc_type == "woman" or npc_type == "sheep" or npc_type == "goat":
		if not get_node_or_null("HerdableComponent"):
			var hcomp = HerdableComponentScript.new()
			hcomp.name = "HerdableComponent"
			add_child(hcomp)
		var herd_influence = get_node_or_null("HerdInfluenceArea")
		if not herd_influence:
			var hi_script = load("res://scripts/npc/components/herd_influence_area.gd")
			if hi_script:
				herd_influence = hi_script.new()
				herd_influence.name = "HerdInfluenceArea"
				add_child(herd_influence)
	
	# Create reproduction component for women if it doesn't exist
	if npc_type == "woman" and not reproduction_component:
		var repro_script = load("res://scripts/npc/components/reproduction_component.gd")
		if repro_script:
			var repro_comp = repro_script.new()
			repro_comp.name = "ReproductionComponent"
			add_child(repro_comp)
			reproduction_component = repro_comp
			# Initialize immediately if we're already in the scene tree
			if is_inside_tree() and reproduction_component.has_method("initialize"):
				reproduction_component.initialize(self)
	
	# Create baby growth component for babies if it doesn't exist
	if npc_type == "baby" and not baby_growth_component:
		var growth_script = load("res://scripts/npc/components/baby_growth_component.gd")
		if growth_script:
			var growth_comp = growth_script.new()
			growth_comp.name = "BabyGrowthComponent"
			add_child(growth_comp)
			baby_growth_component = growth_comp
	
	# Create HealthComponent for cavemen, clansmen, women, sheep, goats (so they can be killed/hunted)
	if npc_type == "caveman" or npc_type == "clansman" or npc_type == "woman" or npc_type == "sheep" or npc_type == "goat":
		# Health Component
		var health_comp = get_node_or_null("HealthComponent")
		if not health_comp:
			var health_script = load("res://scripts/npc/components/health_component.gd")
			if health_script:
				health_comp = health_script.new()
				health_comp.name = "HealthComponent"
				add_child(health_comp)
		
		# Combat Component
		var combat_comp = get_node_or_null("CombatComponent")
		if not combat_comp:
			var combat_script = load("res://scripts/npc/components/combat_component.gd")
			if combat_script:
				combat_comp = combat_script.new()
				combat_comp.name = "CombatComponent"
				add_child(combat_comp)
		
		# Weapon Component
		var weapon_comp = get_node_or_null("WeaponComponent")
		if not weapon_comp:
			var weapon_script = load("res://scripts/npc/components/weapon_component.gd")
			if weapon_script:
				weapon_comp = weapon_script.new()
				weapon_comp.name = "WeaponComponent"
				add_child(weapon_comp)
	
	_sprite_base_position = sprite.position if sprite else Vector2.ZERO
	
	# Make sure sprite is visible
	if sprite:
		sprite.visible = true
	
	# Create progress display for eating/harvesting
	_create_progress_display()
	
	# Create follow line for showing connection to herder
	_create_follow_line()
	
	# Create hostile indicator for agro mode
	_create_hostile_indicator()
	
	# Initialize components
	if stats_component:
		stats_component.initialize(self)
	if reproduction_component:
		reproduction_component.initialize(self)
	if baby_growth_component:
		baby_growth_component.initialize(self)
	
	# Initialize combat components for cavemen, clansmen, mammoths, women, sheep, goats
	if npc_type == "caveman" or npc_type == "clansman" or npc_type == "mammoth" or npc_type == "woman" or npc_type == "sheep" or npc_type == "goat":
		var health_comp = get_node_or_null("HealthComponent")
		if health_comp and health_comp.has_method("initialize"):
			health_comp.initialize(self)
			if npc_type == "mammoth":
				# Mammoth: tougher (more HP)
				health_comp.max_hp = 100
				health_comp.current_hp = 100
			elif npc_type == "sheep" or npc_type == "goat":
				# Sheep/goat: weaker, 1-2 hits to kill
				health_comp.max_hp = 15
				health_comp.current_hp = 15
		
		var combat_comp = get_node_or_null("CombatComponent")
		if combat_comp and combat_comp.has_method("initialize"):
			combat_comp.initialize(self)
			if npc_type == "mammoth":
				# Mammoth: bigger attack range, more damage
				combat_comp.attack_range = 150.0
				combat_comp.base_damage = 25
		
		if npc_type == "caveman" or npc_type == "clansman":
			var weapon_comp = get_node_or_null("WeaponComponent")
			if weapon_comp and weapon_comp.has_method("initialize"):
				weapon_comp.initialize(self)
	
	if steering_agent and steering_agent.has_method("initialize"):
		steering_agent.initialize(self)
	elif steering_agent:
		push_warning("NPCBase: SteeringAgent missing initialize() — check scene script on %s" % name)
	if fsm and fsm.has_method("initialize"):
		fsm.initialize(self)
	elif fsm:
		push_warning("NPCBase: FSM missing initialize() — check scene script on %s" % name)
	
	# Task System - Step 17: Add TaskRunner component if it doesn't exist
	if not task_runner:
		task_runner = get_node_or_null("TaskRunner")
		if not task_runner:
			# Create TaskRunner component programmatically
			var task_runner_script = load("res://scripts/ai/task_runner.gd")
			if task_runner_script:
				var new_task_runner = Node.new()
				new_task_runner.set_script(task_runner_script)
				new_task_runner.name = "TaskRunner"
				add_child(new_task_runner)
				task_runner = new_task_runner
				print("Task System: Created TaskRunner component for %s" % npc_name)
	
	UnifiedLogger.log_npc("NPC initialized at %s (sprite: %s)" % [global_position, "found" if sprite else "missing"], {
		"npc": npc_name,
		"pos": "%.1f,%.1f" % [global_position.x, global_position.y],
		"sprite": "found" if sprite else "missing"
	}, UnifiedLogger.Level.INFO)
	
	# Record spawn time for build cooldown (cavemen must wait 30 seconds before placing land claims)
	spawn_time = Time.get_ticks_msec() / 1000.0
	
	# Record spawn position for boundary checking (wild NPCs should stay within reasonable distance)
	if spawn_position == Vector2.ZERO:
		spawn_position = global_position

	# Initialize chunk-bound roaming for wild NPCs
	if is_wild() and ChunkUtils:
		_init_chunk_roaming()

	# Setup quality tier based on age (stats)
	_update_quality_tier()
	# Randomize skin tone (Dark, Medium, Light) for variety - skip for sheep/goat (they use tint from spawn)
	if npc_type != "sheep" and npc_type != "goat":
		skin_tone = ["Dark", "Medium", "Light"][randi() % 3]
		_update_visual_tier()
	elif sprite and has_meta("sheep_goat_tint"):
		sprite.modulate = get_meta("sheep_goat_tint")
	
	# Initialize wants (hunger, etc.)
	_initialize_wants()
	
	# Initialize inventory based on NPC type
	_initialize_inventory()

	# Women use womanwalk.png (frame 0 = idle); set once ready
	if npc_type == "woman" and sprite:
		call_deferred("_apply_woman_idle_once")
	# Goats use goatwalk.png (frame 0 = idle); set once ready
	if npc_type == "goat" and sprite:
		call_deferred("_apply_goat_idle_once")
	# Cavemen/clansmen use directional SpriteForge sheets; apply once ready
	if (npc_type == "caveman" or npc_type == "clansman") and sprite:
		call_deferred("_apply_caveman_idle_once")

func _exit_tree() -> void:
	if EntityRegistry:
		EntityRegistry.unregister(self)
	if OccupationSystem:
		OccupationSystem.unassign(self, "exited_tree")

func _physics_process(delta: float) -> void:
	# Check if dead - if so, stop all processing
	var health_comp: HealthComponent = get_node_or_null("HealthComponent")
	if health_comp and health_comp.is_dead:
		# Dead NPCs don't move or process
		velocity = Vector2.ZERO
		move_and_slide()
		return
	
	# Update stats (hunger depletion, etc.)
	if stats_component:
		stats_component.update(delta)
	
	# Starvation death (NPCs only, not player; 20s safety after spawn)
	if stats_component and stats_component.get_stat("health") <= 0.0:
		var spawn_t: float = get("spawn_time") if get("spawn_time") != null else 0.0
		var elapsed: float = Time.get_ticks_msec() / 1000.0 - spawn_t
		var safety: float = 20.0
		if BalanceConfig:
			safety = BalanceConfig.starvation_safety_seconds
		if elapsed >= safety:
			die()
	
	# Agro decay: always run. Slower in combat so chasers eventually give up.
	var agro_current_state: String = ""
	if fsm:
		agro_current_state = fsm.get_current_state_name() if fsm.has_method("get_current_state_name") else ""
	
	# Agro decay and threshold (70 enter / 60 exit) moved to CombatTick (Step 2)
	
	# Update reproduction component (for women)
	if reproduction_component:
		# Safety check: ensure component is initialized before updating
		if reproduction_component.has_method("update"):
			var component_npc = reproduction_component.get("npc") if reproduction_component.has_method("get") else null
			if component_npc != null:
				reproduction_component.update(delta)
			else:
				UnifiedLogger.log_system("REPRODUCTION_UPDATE: Component has no npc reference for %s" % npc_name, {
					"npc": npc_name,
					"component_valid": is_instance_valid(reproduction_component)
				})
	
	# Update baby growth component (for babies)
	if baby_growth_component:
		baby_growth_component.update(delta)
	
	# Update wants
	_update_wants(delta)
	
	# Apply buffs/debuffs
	_apply_buffs_debuffs(delta)
	
	# Distance-based update scaling: far NPCs run FSM less often (combat/agro always full rate)
	var combat_t = get("combat_target")
	var is_agro_val = get("is_agro")
	var skip_throttle: bool = (combat_t != null and is_instance_valid(combat_t)) or (is_agro_val == true)
	if not skip_throttle and NPCConfig and NPCConfig.distance_update_scale_enabled:
		var player_ref = get_tree().get_first_node_in_group("player")
		if player_ref and is_instance_valid(player_ref):
			var dist: float = global_position.distance_to(player_ref.global_position)
			var half: float = NPCConfig.distance_threshold_half_rate
			var quarter: float = NPCConfig.distance_threshold_quarter_rate
			if dist > quarter:
				_distance_based_update_scale = 0.25
				_distance_update_interval = 0.4
			elif dist > half:
				_distance_based_update_scale = 0.5
				_distance_update_interval = 0.2
			else:
				_distance_based_update_scale = 1.0
				_distance_update_interval = 0.0
	else:
		_distance_based_update_scale = 1.0
		_distance_update_interval = 0.0
	
	# Update FSM (distance-based scaling: run FSM less often when far from player)
	if fsm:
		var effective_delta: float = delta
		if _distance_based_update_scale < 1.0 and _distance_update_interval > 0.0:
			_distance_update_accumulator += delta
			if _distance_update_accumulator < _distance_update_interval:
				effective_delta = 0.0  # Skip this frame
			else:
				effective_delta = _distance_update_accumulator
				_distance_update_accumulator = 0.0
		if effective_delta > 0.0 and fsm.has_method("update"):
			fsm.update(effective_delta)
	
	# Safety check: Cavemen cannot be herded - they are leaders
	if npc_type == "caveman" and is_herded:
		is_herded = false
		herder = null
		herd_mentality_active = false
		print("Caveman %s: Cleared herded status (cavemen cannot be herded)" % npc_name)
	
	# Check herd break distance for herded NPCs (simplified - direct trigger handles following)
	_check_herd_break_distance()
	
	# Check for caveman aggression (if a wild NPC is lost from the herd)
	# Auto-deposit for cavemen and clansmen
	if npc_type == "caveman" or npc_type == "clansman":
		if npc_type == "caveman":
			_check_caveman_aggression()
			# PUSH/BUMP MECHANICS DISABLED - Cavemen cannot push wild NPCs or player
			# if is_agro:
			#	_apply_caveman_push_mechanics(delta)
			#	_apply_caveman_seek_push_behavior(delta)
			
			# Defensive behavior: stay close to women when threats approach
			# This makes cavemen better competitors by reducing chance of women switching
			_apply_defensive_herding_behavior(delta)
		
		# Auto-deposit items when near any land claim (simplified deposit process)
		_check_and_deposit_items()
	
	# When combat is disabled (testing), keep agro at 0 and skip all agro buildup
	if NPCConfig and NPCConfig.get("combat_disabled"):
		agro_meter = 0.0
	else:
		# Check for land claim intrusion and increase agro_meter for defending clansmen
		# This applies to all NPCs with a land claim (cavemen and clansmen)
		if clan_name != "" and (npc_type == "caveman" or npc_type == "clansman"):
			_check_land_claim_intrusion(delta)
		
		# Proximity agro: enemy within radius → agro builds (both sides when formations meet). No claim required.
		if npc_type == "caveman" or npc_type == "clansman":
			_check_proximity_agro(delta)
		
		# Area of Agro (AOA): Trigger agro when enemy caveman enters personal space - even outside land claim
		# AOA is smaller than AOP (IMPLEMENTATION_CHECKLIST #2)
		if npc_type == "caveman" or npc_type == "clansman":
			_check_area_of_agro(delta)
		
		# Mammoth agro: triggers when predators, cavemen, or player enter AOP; rate scales with threat count
		if npc_type == "mammoth":
			_check_mammoth_agro(delta)
	
	# If NPC is part of a clan, keep them inside their land claim
	# EXCEPT for cavemen and clansmen - they can leave to gather materials and deposit them in storage
	# CRITICAL: Clansmen must be able to leave to gather and herd
	# Only restrict NPCs that are in a clan AND are NOT caveman AND are NOT clansman
	if clan_name != "" and npc_type != "caveman" and npc_type != "clansman":
		_keep_inside_land_claim()
		
		# Sheep, goats, and women in land claims should check for building assignments (throttled)
		if npc_type == "sheep" or npc_type == "goat" or npc_type == "woman":
			var last_assign: float = get_meta("last_assign_check", 0.0) as float
			var now_sec: float = Time.get_ticks_msec() / 1000.0
			if now_sec - last_assign >= NPCConfig.assignment_check_interval:
				set_meta("last_assign_check", now_sec)
				_check_and_assign_to_building()
	# Apply boundary force for cavemen without land claims (keep them within reasonable distance from spawn)
	# Cavemen should stay near their spawn point until they place a land claim
	elif npc_type == "caveman" and clan_name == "":
		_apply_world_boundary(delta)
	elif is_wild():
		if not is_herded or herder == null:
			if not multiplayer.has_multiplayer_peer() or is_multiplayer_authority():
				_update_chunk_boundary(delta)
	
	# Periodic clan joining check (every 0.5 seconds)
	# This ensures NPCs join clans when they enter land claims, even if not in herd state
	if not has_meta("last_clan_join_check_time"):
		set_meta("last_clan_join_check_time", 0.0)
	var last_check: float = get_meta("last_clan_join_check_time", 0.0)
	var current_time: float = Time.get_ticks_msec() / 1000.0
	
	if current_time - last_check >= 0.2:  # Check every 0.2 seconds (5x per second) for faster clan joining
		set_meta("last_clan_join_check_time", current_time)
		if is_wild():
			_try_join_clan_from_claim()
	
	# Check if NPC is inside a forbidden land claim and force them out
	# BUT: If NPC is herded AND can join clans, allow them to enter (they'll join the clan in herd_state)
	# OR: If NPC is already part of the clan, they can stay
	# IMPORTANT: Women who are part of a clan should NEVER be evicted from their own land claim
	var inside_claim: Dictionary = is_inside_land_claim()
	if not inside_claim.is_empty():
		# Check if we're already part of this clan (can stay)
		var claim: Node2D = inside_claim.get("land_claim")
		var claim_clan: String = ""
		if claim:
			var clan_name_prop = claim.get("clan_name")
			if clan_name_prop != null:
				claim_clan = clan_name_prop as String
		
		# If we're already part of this clan, we can stay - NEVER evict clan members
		if clan_name != "" and clan_name == claim_clan:
			# Already in the clan, can stay - this is our land claim
			# This check is critical - women in clans should NEVER be evicted
			return  # Exit early - no eviction needed
		
		# If we're herded AND can join clans, we're allowed to enter (will join clan in herd_state)
		if is_herded and can_join_clan():
			# Skip eviction - herd_state will handle joining the clan
			return  # Exit early - no eviction needed
		
		# For cavemen and player: They can enter land claims, so don't evict them
		# Only evict if they're not cavemen/clansmen/player and can't enter
		if npc_type == "caveman" or npc_type == "clansman":
			# Cavemen and clansmen can enter land claims - don't evict
			return
		
		# Sheep/goats pathing to Farm/Dairy: don't evict - let them reach their building (in their clan's claim)
		if (npc_type == "sheep" or npc_type == "goat") and workplace_building and is_instance_valid(workplace_building):
			return
		
		# Check if this is the player (player is not an NPC, so this check is for NPCs)
		# For non-cavemen NPCs that can't enter, move away
		var claim_pos: Vector2 = claim.global_position
		
		# Calculate direction away from land claim center
		var direction: Vector2 = (global_position - claim_pos)
		if direction.length() < 0.1:
			# At center, pick random direction
			var angle := randf() * TAU
			direction = Vector2(cos(angle), sin(angle))
		else:
			direction = direction.normalized()
		
		# Set flee target (flee FROM center); mark we're evicting so we stop when outside
		if steering_agent:
			steering_agent.set_flee_target(claim_pos)  # Flee from center
			set_meta("eviction_fleeing", true)
	else:
		# Outside forbidden claim - stop eviction FLEE if we were evicting
		if has_meta("eviction_fleeing") and steering_agent:
			remove_meta("eviction_fleeing")
			# FIX: Use center 150px further from nearest claim + radius 200 to avoid wandering back into border
			var w_center: Vector2 = global_position
			var w_radius: float = 200.0
			var land_claims_evict := get_tree().get_nodes_in_group("land_claims")
			var closest: Node2D = null
			var closest_d: float = INF
			for lc in land_claims_evict:
				if not is_instance_valid(lc):
					continue
				var lc_pos: Vector2 = lc.global_position
				# Skip own clan claim
				var lc_clan: String = lc.get("clan_name") as String if lc.get("clan_name") != null else ""
				if clan_name != "" and lc_clan == clan_name:
					continue
				var d: float = global_position.distance_to(lc_pos)
				if d < closest_d:
					closest_d = d
					closest = lc
			if closest:
				var away: Vector2 = (global_position - closest.global_position).normalized()
				if away.length_squared() > 0.01:
					w_center = global_position + away * 150.0
			steering_agent.set_wander(w_center, w_radius)
	
	# Clean up visuals when dead: clear !!! and follow lines; skip rest of draw updates
	if has_method("is_dead") and is_dead():
		_clear_overlay_visuals()
		return
	# Update follow line if being herded (but not for cavemen or clansmen)
	if follow_line:
		if is_herded and herder and is_instance_valid(herder) and npc_type != "caveman" and npc_type != "clansman":
			# Show line and update points
			if not follow_line.visible:
				follow_line.visible = true
			# Line goes from NPC position to herder position (in local coordinates)
			var npc_pos: Vector2 = Vector2.ZERO  # NPC is at origin in local space
			var herder_pos: Vector2 = to_local(herder.global_position)
			follow_line.points = PackedVector2Array([npc_pos, herder_pos])
		else:
			# Hide line when not following or if caveman
			if follow_line.visible:
				follow_line.visible = false
	
	# If this NPC is a leader (caveman, clansman, or player), draw lines to all followers
	# Skip follow line if we're a leader (mutually exclusive - leader lines show all connections)
	if npc_type == "caveman" or npc_type == "clansman" or is_in_group("player"):
		_draw_leader_lines()
	
	# Check if in idle state - don't apply movement
	var is_idle: bool = false
	if fsm and fsm.has_method("get_current_state_name"):
		var state_name: String = fsm.get_current_state_name()
		if state_name == "idle":
			is_idle = true
	
	# Check if caveman should back away from player (when player gets too close)
	# Skip when in agro (handles its own) or combat (we're fighting player, don't flee)
	var should_flee_from_player: bool = false
	var player_flee_target: Vector2 = Vector2.ZERO
	if npc_type == "caveman" and fsm and fsm.has_method("get_current_state_name"):
		var flee_current_state: String = fsm.get_current_state_name()
		if flee_current_state != "agro" and flee_current_state != "combat":
			var player_nodes := get_tree().get_nodes_in_group("player")
			var flee_distance: float = 80.0  # Default
			if NPCConfig:
				flee_distance = NPCConfig.caveman_flee_player_distance
			
			for player_node in player_nodes:
				if not is_instance_valid(player_node):
					continue
				var distance_to_player: float = global_position.distance_to(player_node.global_position)
				if distance_to_player < flee_distance:
					should_flee_from_player = true
					player_flee_target = player_node.global_position
					break
	
	# Check if NPC is frozen for inspection (pause movement only, keep other systems running)
	var is_frozen_for_inspection: bool = has_meta("inspection_frozen")
	if is_frozen_for_inspection:
		# Keep velocity at zero while frozen - skip all movement updates
		velocity = Vector2.ZERO
		move_and_slide()
		return  # Skip rest of movement processing but keep stats/reproduction running
	
	# Dead NPCs don't move (already checked at start, but double-check here)
	if health_comp and health_comp.is_dead:
		velocity = Vector2.ZERO
		move_and_slide()
		return
	
	# Crafting (e.g. knapping), hut build timer in claim, or gathering: NPC must stay in place until finished
	var crafting: bool = get("is_crafting") == true
	if not crafting and task_runner and task_runner.has_method("is_current_task_knap") and task_runner.is_current_task_knap():
		crafting = true  # Knap task active (in case is_crafting not set yet this frame)
	var building_hut: bool = get("is_building_hut") == true
	if crafting or building_hut or get("is_gathering") == true:
		velocity = Vector2.ZERO
		move_and_slide()
		return
	
	# Task controls movement (MoveToTask, DropOffTask walking) - don't overwrite velocity
	if task_runner and task_runner.has_method("controls_movement") and task_runner.controls_movement():
		pass  # Task set velocity; fall through to move_and_slide
	# Update steering/movement with smooth interpolation
	elif steering_agent and not is_idle:
		var desired_velocity: Vector2
		# If caveman should flee from player, use flee behavior
		if should_flee_from_player:
			steering_agent.set_flee_target(player_flee_target)
			desired_velocity = steering_agent.get_steering_force(delta)
		else:
			desired_velocity = steering_agent.get_steering_force(delta)
		
		# Party leader: match player formation_speed_mult so group moves as one unit
		if HerdManager and HerdManager.has_party_ordered_followers(self):
			var fsm_mult: float = get_meta("formation_speed_mult", 1.0)
			desired_velocity *= fsm_mult
		
		# Stats/action/wild speed modifiers disabled - only herding debuff applies
		
		# Add slight random variation to movement for more organic feel
		# Only add variation when moving (not when idle or stopped)
		# SMOOTHED: Apply variation gradually over time instead of every frame to prevent jitter
		if desired_velocity.length() > 10.0:
			# Initialize variation target if not exists
			if not has_meta("movement_variation_target"):
				set_meta("movement_variation_target", 0.0)
				set_meta("movement_variation_current", 0.0)
				set_meta("last_variation_update", Time.get_ticks_msec() / 1000.0)
			
			var variation_time: float = Time.get_ticks_msec() / 1000.0
			var last_update: float = get_meta("last_variation_update", variation_time)
			var update_interval: float = 0.5  # Update variation target every 0.5 seconds
			
			# Update variation target periodically
			if variation_time - last_update >= update_interval:
				var new_variation: float = randf_range(-0.08, 0.08)  # Slightly reduced range
				set_meta("movement_variation_target", new_variation)
				set_meta("last_variation_update", variation_time)
			
			# Smoothly interpolate current variation toward target
			var variation_target: float = get_meta("movement_variation_target", 0.0)
			var variation_current: float = get_meta("movement_variation_current", 0.0)
			variation_current = lerp(variation_current, variation_target, 2.0 * delta)  # Smooth transition
			set_meta("movement_variation_current", variation_current)
			
			# Apply smoothed variation
			var variation_rotated := desired_velocity.rotated(variation_current)
			desired_velocity = desired_velocity.lerp(variation_rotated, 0.15)  # Slightly more variation but smoother
		
		# Velocity interpolation for smooth, natural, deliberate movement
		# Reduced acceleration for smoother, less robotic movement
		var acceleration: float = 4.5  # Reduced from 8.0 for smoother transitions
		
		# Calculate direction change for momentum and acceleration adjustment
		var current_dir: Vector2 = velocity.normalized() if velocity.length() > 0.1 else Vector2.ZERO
		var desired_dir: Vector2 = desired_velocity.normalized() if desired_velocity.length() > 0.1 else Vector2.ZERO
		var direction_change: float = 1.0  # Default to no change
		
		if current_dir.length() > 0.1 and desired_dir.length() > 0.1:
			direction_change = current_dir.dot(desired_dir)
			# If direction changed by more than 45 degrees, slow down acceleration
			if direction_change < 0.707:  # cos(45°) ≈ 0.707
				acceleration = 3.0  # Slower acceleration for sharp turns
		
		# More deliberate velocity interpolation - slower, more intentional changes
		# Use lower lerp rate for more deliberate acceleration/deceleration
		var lerp_rate: float = acceleration * delta
		lerp_rate = clamp(lerp_rate, 0.0, 0.12)  # Cap at 12% per frame for more deliberate transitions
		
		# Apply momentum - resist sudden direction changes
		if velocity.length() > 20.0 and desired_velocity.length() > 20.0:
			# If changing direction significantly, reduce lerp rate (more momentum)
			if direction_change < 0.7:  # More than ~45 degree turn
				lerp_rate *= 0.6  # 40% slower when changing direction (more deliberate)
		
		velocity = velocity.lerp(desired_velocity, lerp_rate)
		
		# CRITICAL FIX: Prevent oscillation - if velocity is very small, just stop instead of forcing movement
		# This allows NPCs to idle in one place instead of oscillating
		# CRITICAL: Don't force movement if NPC is herded (would break herd)
		@warning_ignore("shadowed_variable")
		var is_herded: bool = false
		var herded_prop = get("is_herded")
		is_herded = herded_prop as bool if herded_prop != null else false
		
		if velocity.length() < 10.0 and desired_velocity.length() < 10.0:
			# Both velocities are very small - might be oscillating
			# Instead of forcing movement, just stop (allow idle in place)
			if fsm and not is_herded and fsm.has_method("get_current_state_name"):
				var oscillation_state: String = fsm.get_current_state_name()
				# FIX: Don't stop NPCs in combat state - they need to move to position for attacks
				# Only apply if in wander or idle (states that might cause oscillation)
				if oscillation_state == "wander" or oscillation_state == "idle":
					# Just stop - set velocity to zero to prevent oscillation
					# NPC will idle in place instead of oscillating
					velocity = Vector2.ZERO
					# Clear steering target to stop movement
					if steering_agent:
						steering_agent.target_node = null
						steering_agent.target_position = global_position  # Stop at current position
				# CRITICAL: In combat state, allow small movements even if velocities are small
				# This prevents NPCs from getting stuck when trying to position for attacks
				elif oscillation_state == "combat":
					# In combat, don't force stop - allow natural movement
					# The combat state will handle positioning
					pass
		
		# Add emergency separation force if NPCs are too close (prevent getting stuck)
		# SMOOTHED: Apply separation force gradually instead of instantly to prevent jerky movement
		var emergency_separation := _get_emergency_separation_force()
		if emergency_separation.length() > 0.0:
			# Smooth the separation force over time instead of applying instantly
			if not has_meta("smoothed_separation_force"):
				set_meta("smoothed_separation_force", Vector2.ZERO)
			
			var smoothed_force: Vector2 = get_meta("smoothed_separation_force", Vector2.ZERO)
			# Interpolate toward target separation force
			smoothed_force = smoothed_force.lerp(emergency_separation, 5.0 * delta)
			set_meta("smoothed_separation_force", smoothed_force)
			
			# Apply smoothed force (reduced multiplier for gentler effect)
			velocity += smoothed_force * delta * 60.0  # Reduced from 100.0 for smoother effect
		else:
			# Gradually reduce separation force when not needed
			if has_meta("smoothed_separation_force"):
				var smoothed_force: Vector2 = get_meta("smoothed_separation_force", Vector2.ZERO)
				smoothed_force = smoothed_force.lerp(Vector2.ZERO, 8.0 * delta)
				set_meta("smoothed_separation_force", smoothed_force)
		
		# Sheep grouping behavior - sheep try to stay near other sheep
		# Only apply when not herded and not stuck (velocity is not zero for too long)
		if npc_type == "sheep" and has_trait("group") and not is_herded:
			# Check if sheep is stuck (velocity near zero for too long)
			if not has_meta("stuck_check_time"):
				set_meta("stuck_check_time", 0.0)
				set_meta("last_velocity", Vector2.ZERO)
			var stuck_check_time: float = get_meta("stuck_check_time", 0.0)
			var last_velocity: Vector2 = get_meta("last_velocity", Vector2.ZERO)
			
			# If velocity is very low and hasn't changed much, might be stuck
			if velocity.length() < 5.0 and last_velocity.length() < 5.0:
				stuck_check_time += delta
				if stuck_check_time > 2.0:  # Stuck for 2 seconds
					# Clear steering target and use wander to unstick
					if steering_agent:
						steering_agent.set_wander(global_position, 100.0)
					stuck_check_time = 0.0
			else:
				stuck_check_time = 0.0
			
			set_meta("stuck_check_time", stuck_check_time)
			set_meta("last_velocity", velocity)
			
			_apply_sheep_grouping_behavior(delta)
		
		# Add slight velocity damping for more natural deceleration
		# Use a larger threshold to prevent oscillation when arriving at target
		if desired_velocity.length() < 2.0:
			velocity = velocity.lerp(Vector2.ZERO, 6.0 * delta)  # Slightly slower damping for smoother stop
		
		# Ensure minimum movement threshold (but lower for smoother movement)
		# Only apply if desired velocity is significant to prevent oscillation
		# SMOOTHED: Use gradual acceleration instead of instant minimum velocity
		if velocity.length() < 3.0 and desired_velocity.length() > 2.0:
			var min_velocity: Vector2 = desired_velocity.normalized() * 3.0
			velocity = velocity.lerp(min_velocity, 4.0 * delta)  # Smoothly accelerate to minimum
	elif is_idle:
		# In idle, smoothly stop with gradual deceleration
		velocity = velocity.lerp(Vector2.ZERO, 6.0 * delta)  # Slightly slower for smoother stop
	
	# Task (MoveTo/DropOff) already calls move_and_slide - don't double-move
	if not (task_runner and task_runner.has_method("controls_movement") and task_runner.controls_movement()):
		move_and_slide()
	
	if sprite:
		YSortUtils.update_object_y_sort(sprite, self)
	
	# Flip sprite based on movement direction (only if not in idle state)
	# Use hysteresis and target-based flipping in combat to prevent rapid flipping
	if sprite and fsm and fsm.has_method("get_current_state_name"):
		var state_name: String = fsm.get_current_state_name()
		# Mammoth and other animals: always flip based on movement (ensure they face movement direction)
		var force_velocity_flip: bool = (npc_type == "mammoth")
		if force_velocity_flip or state_name != "idle":  # Idle state handles its own sprite flipping
			# In combat, use target direction instead of velocity to prevent oscillation
			if state_name == "combat" and not force_velocity_flip:
				@warning_ignore("shadowed_variable")
				var combat_target = get("combat_target")
				if combat_target and is_instance_valid(combat_target):
					# Face toward target (more stable than velocity-based)
					var direction_to_target = (combat_target.global_position - global_position).normalized()
					# Only flip if target is clearly on one side (prevents rapid flipping)
					if direction_to_target.x < -0.3:  # Target is clearly to the left
						sprite.flip_h = true
					elif direction_to_target.x > 0.3:  # Target is clearly to the right
						sprite.flip_h = false
					# If target is roughly in front/behind (between -0.3 and 0.3), keep current flip state
			else:
				# For other states (and mammoth), use velocity with hysteresis
				# Mammoth: use lower threshold (5.0) - smaller scaled NPC may have lower apparent velocity
				var flip_left_threshold: float = -15.0
				var flip_right_threshold: float = 15.0
				if npc_type == "mammoth":
					flip_left_threshold = -5.0
					flip_right_threshold = 5.0
				
				# Only flip if velocity exceeds threshold in the opposite direction
				# flip_h = true when moving left (faces left)
				if velocity.x < flip_left_threshold:
					sprite.flip_h = true
				elif velocity.x > flip_right_threshold:
					sprite.flip_h = false

	# Walk spritesheet for cavemen/clansmen/women/goats when moving (not dead, not in combat)
	var is_caveman_clansman := (npc_type == "caveman" or npc_type == "clansman")
	var is_woman := (npc_type == "woman")
	var is_goat := (npc_type == "goat")
	var combat_comp: Node = get_node_or_null("CombatComponent")
	var combat_idle := true
	if combat_comp and combat_comp.get("state") != null:
		combat_idle = (combat_comp.state == CombatComponent.CombatState.IDLE)
	var moving := velocity.length_squared() > 50.0
	if moving:
		_last_facing = velocity.normalized()
	var should_walk := (is_caveman_clansman or is_woman or is_goat) and moving and combat_idle and not is_dead()
	if should_walk:
		is_walking_animation = true
		if is_woman:
			var dir_sheet := WalkAnimation.get_directional_woman_sheet()
			if dir_sheet and sprite:
				_walk_timer += delta
				var walk_index: int = int(_walk_timer * WalkAnimation.WOMAN_WALK_FPS) % dir_sheet.columns
				if WalkAnimation.apply_directional_walk_frame(sprite, dir_sheet, velocity, walk_index):
					sprite.flip_h = false  # Directional: no flip
					apply_sprite_offset_for_texture()
				else:
					var woman_sheet: Texture2D = WalkAnimation.get_woman_walk_sheet()
					if woman_sheet and sprite:
						var legacy_index: int = int(_walk_timer * WalkAnimation.WOMAN_WALK_FPS) % WalkAnimation.WOMAN_WALK_FRAMES
						WalkAnimation.apply_woman_walk_frame_by_index(sprite, legacy_index)
						sprite.flip_h = velocity.x < -15.0
						apply_sprite_offset_for_texture()
			elif sprite:
				var woman_sheet: Texture2D = WalkAnimation.get_woman_walk_sheet()
				if woman_sheet:
					_walk_timer += delta
					var walk_index: int = int(_walk_timer * WalkAnimation.WOMAN_WALK_FPS) % WalkAnimation.WOMAN_WALK_FRAMES
					WalkAnimation.apply_woman_walk_frame_by_index(sprite, walk_index)
					sprite.flip_h = velocity.x < -15.0
					apply_sprite_offset_for_texture()
		elif is_goat:
			# Goat: no directional sheet yet (add DIRECTIONAL_GOAT_PATH if needed)
			var goat_sheet: Texture2D = WalkAnimation.get_goat_walk_sheet()
			if goat_sheet and sprite:
				_walk_timer += delta
				var walk_index: int = int(_walk_timer * WalkAnimation.GOAT_WALK_FPS) % WalkAnimation.GOAT_WALK_FRAMES
				WalkAnimation.apply_goat_walk_frame_by_index(sprite, walk_index)
				sprite.flip_h = velocity.x < -15.0
				apply_sprite_offset_for_texture()
		else:
			var weapon_comp: Node = get_node_or_null("WeaponComponent")
			var show_club: bool = weapon_comp and weapon_comp.has_method("should_show_club") and weapon_comp.should_show_club()
			var dir_sheet: DirectionalSpriteSheet = WalkAnimation.get_directional_club_sheet() if show_club else WalkAnimation.get_directional_walk_sheet()
			var used_directional := false
			if dir_sheet and sprite:
				_walk_timer += delta
				var walk_index := int(_walk_timer * WalkAnimation.WALK_FPS) % dir_sheet.columns
				if WalkAnimation.apply_directional_walk_frame(sprite, dir_sheet, velocity, walk_index):
					used_directional = true
					sprite.flip_h = false
					apply_sprite_offset_for_texture()
			if not used_directional and sprite:
				if show_club:
					var club_sheet := WalkAnimation.get_club_walk_sheet()
					if club_sheet:
						_walk_timer += delta
						var walk_index := int(_walk_timer * WalkAnimation.CLUB_WALK_FPS) % WalkAnimation.CLUB_WALK_FRAMES
						WalkAnimation.apply_club_walk_frame_by_index(sprite, walk_index)
						sprite.flip_h = velocity.x < -15.0
						apply_sprite_offset_for_texture()
				else:
					var sheet := WalkAnimation.get_walk_sheet()
					if sheet:
						_walk_timer += delta
						var frame_index := int(_walk_timer * WalkAnimation.WALK_FPS) % WalkAnimation.WALK_CYCLE_FRAMES
						WalkAnimation.apply_walk_frame_by_index(sprite, sheet, frame_index)
						sprite.flip_h = velocity.x < -15.0
						apply_sprite_offset_for_texture()
	else:
		if is_walking_animation:
			is_walking_animation = false
			var dir_sheet: DirectionalSpriteSheet = null
			if is_woman:
				dir_sheet = WalkAnimation.get_directional_woman_sheet()
				if dir_sheet and WalkAnimation.apply_directional_idle(sprite, dir_sheet, _last_facing):
					apply_sprite_offset_for_texture()
				else:
					WalkAnimation.apply_woman_idle(sprite)
					apply_sprite_offset_for_texture()
			elif is_goat:
				WalkAnimation.apply_goat_idle(sprite)
				apply_sprite_offset_for_texture()
			else:
				var weapon_comp: Node = get_node_or_null("WeaponComponent")
				var show_club: bool = weapon_comp and weapon_comp.has_method("should_show_club") and weapon_comp.should_show_club()
				dir_sheet = WalkAnimation.get_directional_club_sheet() if show_club else WalkAnimation.get_directional_idle_sheet()
				if dir_sheet and WalkAnimation.apply_directional_idle(sprite, dir_sheet, _last_facing):
					apply_sprite_offset_for_texture()
				elif weapon_comp and weapon_comp.has_method("force_apply_idle"):
					weapon_comp.force_apply_idle()
		_walk_timer = 0.0

func _apply_woman_idle_once() -> void:
	"""Apply woman idle (womanwalk frame 0) once after _ready. Used for women."""
	if npc_type != "woman" or not sprite:
		return
	WalkAnimation.apply_woman_idle(sprite)
	apply_sprite_offset_for_texture()

func _apply_goat_idle_once() -> void:
	"""Apply goat idle (goatwalk frame 0) once after _ready. Used for goats."""
	if npc_type != "goat" or not sprite:
		return
	WalkAnimation.apply_goat_idle(sprite)
	apply_sprite_offset_for_texture()

func _apply_caveman_idle_once() -> void:
	"""Apply directional idle once after _ready. Used for cavemen/clansmen."""
	if npc_type != "caveman" and npc_type != "clansman" or not sprite:
		return
	var show_club: bool = false
	var weapon_comp: Node = get_node_or_null("WeaponComponent")
	if weapon_comp and weapon_comp.has_method("should_show_club"):
		show_club = weapon_comp.should_show_club()
	var dir_sheet: DirectionalSpriteSheet = WalkAnimation.get_directional_club_sheet() if show_club else WalkAnimation.get_directional_idle_sheet()
	if dir_sheet and WalkAnimation.apply_directional_idle(sprite, dir_sheet, _last_facing):
		apply_sprite_offset_for_texture()

func apply_sprite_offset_for_texture() -> void:
	if not sprite or not sprite.texture:
		return
	sprite.position = Vector2.ZERO
	# If texture is from walk/club sheet (AtlasTexture), scale already set to 0.46 by apply_*_idle — don't overwrite.
	# Otherwise (e.g. axe) use 0.46 so all character sprites match walk size.
	if not (sprite.texture is AtlasTexture):
		var tex := sprite.texture
		var h := tex.get_height() if tex else 0
		# 128px+ (cavemen): 0.46. 64px (sheep, goat, baby): 1.0 so they're visible, not tiny
		sprite.scale = Vector2(0.46, 0.46) if h >= 128 else Vector2(1.0, 1.0)
	_sprite_base_position = sprite.position

func _initialize_wants() -> void:
	# Initialize hunger want
	wants.append({
		"name": "hunger",
		"meter": 100.0,
		"max": 100.0,
		"deplete_rate": 1.0,  # per minute
		"threshold": 80.0  # Seek food when below this
	})

func _initialize_inventory() -> void:
	# Initialize inventory based on NPC type
	var slot_count: int = 10  # Default for humans
	var can_stack: bool = false
	var max_stack: int = 1
	
	# Set inventory size based on NPC type
	match npc_type:
		"caveman", "human":
			slot_count = 5  # Reduced from 10 per UI.md spec
			can_stack = false
			max_stack = 1
		"woman":
			slot_count = 10  # Women need extra slots for oven jobs (Wood + Grain + Bread + misc)
			can_stack = false
			max_stack = 1
		"baby":
			slot_count = NPCConfig.baby_inventory_slots if NPCConfig else 2  # Babies: configurable slots for food
			can_stack = false
			max_stack = 1
		"sheep", "goat":
			slot_count = 5  # Sheep and goats have 5 inventory slots
			can_stack = false
			max_stack = 1
		_:
			# Default for other types
			slot_count = 5
			can_stack = false
			max_stack = 1
	
	inventory = InventoryData.new(slot_count, can_stack, max_stack)
	
	# Initialize hotbar for cavemen and clansmen (10 equipment slots)
	if npc_type == "caveman" or npc_type == "clansman" or npc_type == "human":
		hotbar = InventoryData.new(10, false, 1)  # 10 slots, no stacking
		# Hotbar slots: 1=right hand, 2=left hand, 3=head, 4=body, 5=legs, 6=feet, 7=neck, 8=backpack, 9=consumable, 0=consumable
	
	# Give NPCs 1 berry to start with (so they don't worry about gathering right away)
	var berry_item: Dictionary = {
		"type": ResourceData.ResourceType.BERRIES,
		"quantity": 1
	}
	# Add berry to first available slot
	if inventory:
		inventory.set_slot(0, berry_item)
	
	# Cavemen start with a land claim item only if not pre-assigned to a claim (AI spawn = claim + caveman together)
	if npc_type == "caveman" and inventory and not get_meta("has_land_claim", false):
		inventory.add_item(ResourceData.ResourceType.LANDCLAIM, 1)
	
	UnifiedLogger.log_npc("NPC inventory initialized: %d slots (started with 1 berry)" % slot_count, {
		"npc": npc_name,
		"slot_count": str(slot_count),
		"starting_item": "berries"
	}, UnifiedLogger.Level.INFO)

func is_part_of_clan() -> bool:
	# Returns true if NPC belongs to a clan
	return clan_name != ""

func has_travois() -> bool:
	"""True when NPC is carrying a travois (2-handed, cannot defend)."""
	return carried_travois_inventory != null

func can_join_clan() -> bool:
	# Only women and herdable animals (sheep, goats) can join clans
	# Cavemen cannot join clans - they start their own
	return npc_type == "woman" or npc_type == "sheep" or npc_type == "goat"

func can_enter_land_claim(land_claim: Node2D) -> bool:
	# NPCs can enter land claims if:
	# 1. They belong to that clan, OR
	# 2. They are being herded AND can join clans (women, sheep, goats), OR
	# 3. They are cavemen, clansmen, or player (can enter enemy land claims)
	if not land_claim:
		return false
	
	# Try to get clan_name property (it's an @export var on LandClaim)
	var claim_clan: String = ""
	var clan_name_prop = land_claim.get("clan_name")
	if clan_name_prop != null:
		claim_clan = clan_name_prop as String
	
	# Check if NPC belongs to this clan
	if clan_name != "" and clan_name == claim_clan:
		return true
	
	# CAVEMEN, CLANSMEN, AND PLAYER CAN ENTER ENEMY LAND CLAIMS
	# They can cross into land claims for raiding/gathering
	# This allows raiding mechanics - intruders will trigger agro
	if npc_type == "caveman" or npc_type == "clansman":
		# Cavemen and clansmen can enter enemy land claims (triggers agro for defenders)
		return true
	
	# Check if NPC is being herded AND can join clans
	# Cavemen cannot join clans even if herded
	if is_herded and can_join_clan():
		return true
	
	# Wild NPCs cannot enter
	return false

func is_inside_land_claim() -> Dictionary:
	# Returns {land_claim: Node2D, distance: float} if inside any land claim, {} otherwise
	var land_claims := get_tree().get_nodes_in_group("land_claims")
	
	for claim in land_claims:
		if not is_instance_valid(claim):
			continue
		
		var claim_pos: Vector2 = claim.global_position
		var distance: float = global_position.distance_to(claim_pos)
		var radius: float = 400.0
		var radius_prop = claim.get("radius")
		if radius_prop != null:
			radius = radius_prop as float
		
		if distance < radius:
			# Inside this land claim
			if not can_enter_land_claim(claim):
				return {"land_claim": claim, "distance": distance, "radius": radius}
	
	return {}

func _keep_inside_land_claim() -> void:
	# Keep clan members inside their land claim - they cannot leave on their own
	# CAVEMEN CAN LEAVE - they need to gather and herd women outside their land claim
	# Only women and other NPCs in clans are restricted to stay inside
	if clan_name == "":
		return  # Not in a clan, no restriction
	
	# Don't override steering when sheep/goat/woman is headed to building (Farm/Dairy/Living Hut)
	if (npc_type == "sheep" or npc_type == "goat" or npc_type == "woman") and workplace_building and is_instance_valid(workplace_building):
		return
	
	# Cavemen and clansmen can leave their land claim to gather and herd
	# CRITICAL: Cavemen/clansmen in herd_wildnpc state should be able to leave to search for wild NPCs
	if npc_type == "caveman" or npc_type == "clansman":
		# Check if caveman/clansman is actively herding - if so, allow them to leave the land claim
		if fsm and fsm.current_state_name == "herd_wildnpc":
			return  # Caveman/clansman is actively searching for wild NPCs - allow leaving land claim
		# Also allow leaving for gather state (they need resources outside)
		if fsm and fsm.current_state_name == "gather":
			return  # Caveman/clansman is gathering resources - allow leaving land claim
		# For other states (wander, deposit, etc.), cavemen/clansmen can also leave
		return  # Cavemen/clansmen are not restricted - they can leave to gather and herd
	
	# Find the land claim for this clan
	var land_claims := get_tree().get_nodes_in_group("land_claims")
	var my_claim: Node2D = null
	var claim_radius: float = 400.0
	
	for claim in land_claims:
		if not is_instance_valid(claim):
			continue
		
		var claim_clan: String = ""
		var clan_name_prop = claim.get("clan_name")
		if clan_name_prop != null:
			claim_clan = clan_name_prop as String
		
		if claim_clan == clan_name:
			# Found our land claim
			my_claim = claim
			var radius_prop = claim.get("radius")
			if radius_prop != null:
				claim_radius = radius_prop as float
			break
	
	if not my_claim:
		return  # No land claim found for this clan
	
	# Check if we're at or near the boundary
	var claim_pos: Vector2 = my_claim.global_position
	var distance: float = global_position.distance_to(claim_pos)
	var boundary_threshold: float = claim_radius * 0.95  # Start applying force at 95% of radius
	
	if distance >= boundary_threshold:
		# Near or at boundary - apply strong force to keep inside (no teleporting)
		# The steering agent will handle the boundary force, but we also clamp position here
		# Clamp position to stay inside (but don't teleport - just prevent further movement out)
		if distance >= claim_radius:
			# At or past boundary - use steering agent to move back inside (prevents oscillation)
			var direction_from_center: Vector2 = (global_position - claim_pos).normalized()
			if direction_from_center.length() > 0.1:
				# Calculate target position inside boundary
				var target_pos: Vector2 = claim_pos + direction_from_center * (claim_radius * 0.8)  # Move to 80% of radius
				
				# CRITICAL FIX: Always use steering agent for boundary enforcement to prevent oscillation
				# Direct position modification (lerp) conflicts with steering and causes back-and-forth movement
				if steering_agent:
					# Check if we're already moving toward the target (prevent rapid target switching)
					var current_target: Vector2 = steering_agent.target_position if steering_agent else Vector2.ZERO
					var distance_to_current_target: float = current_target.distance_to(target_pos) if current_target != Vector2.ZERO else INF
					
					# Only update target if it's significantly different (prevents oscillation)
					if distance_to_current_target > 20.0:  # Only change target if >20px different
						steering_agent.set_arrive_target(target_pos)
				else:
					# No steering agent - use lerp as fallback (shouldn't happen, but handle it)
					var max_lerp_distance: float = claim_radius * 2.0
					if distance <= max_lerp_distance:
						global_position = global_position.lerp(target_pos, 0.2)  # Slower lerp to reduce oscillation
				# Log boundary enforcement
				UnifiedLogger.log_npc("Boundary enforcement: land_claim pushed_back", {
					"npc": npc_name,
					"boundary_type": "land_claim",
					"action": "pushed_back",
					"distance": "%.1f" % distance,
					"radius": "%.1f" % claim_radius,
					"clan": clan_name,
					"method": "lerp" if distance <= (claim_radius * 2.0) else "steering"
				}, UnifiedLogger.Level.DEBUG)
		elif not has_meta("last_boundary_warn_time"):
			set_meta("last_boundary_warn_time", 0.0)
		var last_warn: float = get_meta("last_boundary_warn_time", 0.0) if has_meta("last_boundary_warn_time") else 0.0
		var current_time: float = Time.get_ticks_msec() / 1000.0
		if current_time - last_warn > 5.0:  # Log every 5 seconds
			UnifiedLogger.log_npc("Boundary enforcement: land_claim near_boundary", {
				"npc": npc_name,
				"boundary_type": "land_claim",
				"action": "near_boundary",
				"distance": "%.1f" % distance,
				"threshold": "%.1f" % boundary_threshold,
				"radius": "%.1f" % claim_radius,
				"clan": clan_name
			}, UnifiedLogger.Level.DEBUG)
			set_meta("last_boundary_warn_time", current_time)

func _init_chunk_roaming() -> void:
	"""Initialize chunk-bound roaming from current position. Always zeros time_in_current_chunk."""
	if not ChunkUtils:
		return
	home_chunk = ChunkUtils.get_chunk_coords(global_position)
	chunk_center = ChunkUtils.get_chunk_center(home_chunk)
	roam_radius = ChunkUtils.ROAM_RADIUS
	time_in_current_chunk = 0.0


func _update_chunk_boundary(delta: float) -> void:
	"""Chunk-bound roaming: update home_chunk if NPC stays in new chunk for HOME_UPDATE_TIME."""
	if not ChunkUtils:
		return
	var current_chunk: Vector2i = ChunkUtils.get_chunk_coords(global_position)
	if current_chunk != home_chunk:
		time_in_current_chunk += delta
		if time_in_current_chunk >= ChunkUtils.HOME_UPDATE_TIME:
			home_chunk = current_chunk
			chunk_center = ChunkUtils.get_chunk_center(home_chunk)
			time_in_current_chunk = 0.0
	else:
		time_in_current_chunk = 0.0

func _apply_world_boundary(delta: float) -> void:
	# Only cavemen without claim use world boundary (keep them near spawn until they place a land claim)
	if npc_type != "caveman":
		return
	if spawn_position == Vector2.ZERO:
		return
	var max_distance: float = 2000.0
	if NPCConfig:
		max_distance = NPCConfig.max_wander_distance_from_spawn
	var distance_from_spawn: float = global_position.distance_to(spawn_position)
	var boundary_threshold: float = max_distance * 0.95
	if distance_from_spawn < boundary_threshold:
		return
	var direction_to_spawn: Vector2 = (spawn_position - global_position).normalized()
	var boundary_force: float = 200.0
	if distance_from_spawn >= max_distance:
		boundary_force = 400.0
		var target_pos: Vector2 = spawn_position + direction_to_spawn * (max_distance * 0.99)
		if steering_agent:
			steering_agent.set_arrive_target(target_pos)
		else:
			global_position = global_position.lerp(target_pos, 0.1)
	if steering_agent:
		var target_velocity: Vector2 = velocity + direction_to_spawn * boundary_force * delta
		velocity = velocity.lerp(target_velocity, 0.4)

func _create_progress_display() -> void:
	# Create a progress display node for eating/harvesting
	progress_display = Node2D.new()
	progress_display.name = "ProgressDisplay"
	progress_display.position = Vector2(0, -50)  # Above NPC head
	progress_display.visible = false
	progress_display.z_as_relative = false
	progress_display.z_index = YSortUtils.Z_ABOVE_WORLD  # Above Y-sorted sprite
	add_child(progress_display)
	
	# Add script to draw progress circle
	var progress_script := load("res://scripts/collection_progress.gd")
	if progress_script:
		progress_display.set_script(progress_script)
		# Make sure it can draw
		progress_display.set_process_mode(Node.PROCESS_MODE_INHERIT)

func _create_follow_line() -> void:
	# Create a Line2D node for showing connection to herder
	follow_line = Line2D.new()
	follow_line.name = "FollowLine"
	follow_line.width = 2.0  # Thin line
	follow_line.default_color = Color(1.0, 1.0, 1.0, 0.35)  # White, more transparent, behind entities
	follow_line.visible = false
	follow_line.z_as_relative = false
	follow_line.z_index = YSortUtils.Z_BEHIND_ENTITIES
	follow_line.points = PackedVector2Array([Vector2.ZERO, Vector2.ZERO])
	add_child(follow_line)
	
	# Create leader lines container for drawing lines to followers (only for leaders)
	if npc_type == "caveman" or is_in_group("player"):
		var leader_lines_container = Node2D.new()
		leader_lines_container.name = "LeaderLines"
		add_child(leader_lines_container)

func _create_hostile_indicator() -> void:
	# Create a Label to show "!!!" when in hostile mode
	hostile_indicator = Label.new()
	hostile_indicator.name = "HostileIndicator"
	hostile_indicator.text = "!!!"
	hostile_indicator.position = Vector2(-20, -60)  # Above NPC head, centered
	hostile_indicator.add_theme_color_override("font_color", Color(1.0, 0.0, 0.0, 1.0))  # Red
	hostile_indicator.add_theme_font_size_override("font_size", 30)  # Larger for visibility
	hostile_indicator.z_as_relative = false
	hostile_indicator.z_index = YSortUtils.Z_ABOVE_WORLD  # Above Y-sorted sprite
	hostile_indicator.visible = false
	add_child(hostile_indicator)

func _clear_overlay_visuals() -> void:
	"""Hide follow line and hostile (!!!) indicator. Call when NPC dies or when overlays should be cleared."""
	if follow_line and follow_line.visible:
		follow_line.visible = false
	if hostile_indicator and hostile_indicator.visible:
		hostile_indicator.visible = false

func _update_wants(delta: float) -> void:
	# Wild NPCs don't have wants/hunger - they just wander
	if is_wild():
		return
	
	for want in wants:
		var deplete_rate: float = want.get("deplete_rate", 0.0) as float
		var meter: float = want.get("meter", 0.0) as float
		meter = max(0.0, meter - (deplete_rate * delta / 60.0))  # Convert to per-second
		want["meter"] = meter

func _apply_buffs_debuffs(delta: float) -> void:
	# Remove expired buffs
	var expired: Array[int] = []
	for i in range(buffs_debuffs.size()):
		var buff: Dictionary = buffs_debuffs[i] as Dictionary
		var duration: float = buff.get("duration", 0.0) as float
		duration -= delta
		if duration <= 0.0:
			expired.append(i)
		else:
			buffs_debuffs[i]["duration"] = duration
	
	# Remove expired buffs (reverse order to maintain indices)
	for i in range(expired.size() - 1, -1, -1):
		buffs_debuffs.remove_at(expired[i])

func _update_quality_tier() -> void:
	# Age-based quality tiers (affects stats via StatsComponent)
	if age < 13:
		quality_tier = "Flawed"
	elif age < 46:
		quality_tier = "Good"
	else:
		quality_tier = "Legendary"

func _update_visual_tier() -> void:
	# Skin tone modulates sprite (Dark, Medium, Light)
	if sprite:
		match skin_tone:
			"Dark":
				sprite.modulate = Color(0.55, 0.42, 0.35, 1.0)  # Dark skin
			"Light":
				sprite.modulate = Color(1.05, 0.92, 0.82, 1.0)  # Light skin
			"Medium":
				sprite.modulate = Color(0.88, 0.72, 0.58, 1.0)  # Medium skin
			_:
				sprite.modulate = Color(0.88, 0.72, 0.58, 1.0)  # Default medium

## Restore sprite modulate after selection outline clear (ESC). Preserves skin tone and sheep/goat tint.
func restore_sprite_modulate() -> void:
	if not sprite:
		return
	if npc_type == "sheep" or npc_type == "goat":
		if has_meta("sheep_goat_tint"):
			sprite.modulate = get_meta("sheep_goat_tint")
		else:
			sprite.modulate = Color.WHITE
	elif npc_type == "caveman" or npc_type == "clansman" or npc_type == "woman":
		_update_visual_tier()
	else:
		sprite.modulate = Color.WHITE

func take_damage(amount: float) -> void:
	# Old damage system - use health component instead
	var health_comp: HealthComponent = get_node_or_null("HealthComponent")
	if health_comp:
		health_comp.take_damage(int(amount))
	elif stats_component:
		stats_component.modify_stat("health", -amount)
		if stats_component.get_stat("health") <= 0.0:
			die()

func die() -> void:
	# Health component handles death - this is old method, keep for compatibility
	# Health component will handle death properly
	var health_comp: HealthComponent = get_node_or_null("HealthComponent")
	if health_comp:
		health_comp.die()
	else:
		# Fallback for NPCs without health component
		npc_died.emit(self)
		queue_free()

func get_stat(stat_name: String) -> float:
	if stats_component:
		return stats_component.get_stat(stat_name)
	return 0.0

func modify_stat(stat_name: String, amount: float) -> void:
	if stats_component:
		stats_component.modify_stat(stat_name, amount)

@warning_ignore("shadowed_variable_base_class")
func add_buff_debuff(name: String, stat: String, mult: float, duration: float, visual: String = "") -> void:
	buffs_debuffs.append({
		"name": name,
		"stat": stat,
		"mult": mult,
		"duration": duration,
		"visual": visual
	})

func has_trait(trait_name: String) -> bool:
	return trait_name in traits

func is_wild() -> bool:
	# NPC is wild if: not in a clan, outside land claim, and is a woman or animal
	# CAVEMEN ARE NEVER WILD - they are AI players, not wild NPCs
	if npc_type == "caveman":
		return false  # Cavemen are AI players, never wild
	
	if clan_name != "":
		return false  # Part of a clan
	
	# Check if inside any land claim (regardless of whether we can enter it)
	var land_claims := get_tree().get_nodes_in_group("land_claims")
	for claim in land_claims:
		if not is_instance_valid(claim):
			continue
		var claim_pos: Vector2 = claim.global_position
		var distance: float = global_position.distance_to(claim_pos)
		var radius: float = 400.0
		var radius_prop = claim.get("radius")
		if radius_prop != null:
			radius = radius_prop as float
		if distance < radius:
			return false  # Inside a land claim
	
	# Only women and animals can be wild
	# Cavemen are AI players and are never considered wild
	return true

# Simple chance-based herding - roll chance every frame when caveman is close
# Chance increases with proximity, allows stealing back and forth
# force_influence_transfer: when true (from HerdInfluenceArea), skip random roll - deterministic transfer
func _try_herd_chance(leader: Node2D, force_influence_transfer: bool = false) -> bool:
	# Safety checks
	if not is_instance_valid(self) or not is_instance_valid(leader):
		return false
	
	# Never attach to dead herder (fixes re-target loop when herder corpse stays in scene)
	if leader.has_method("is_dead") and leader.is_dead():
		return false
	
	# Only wild NPCs can be herded
	if not is_wild():
		return false
	
	# Only women, sheep, goats can be herded (not cavemen)
	if npc_type == "caveman":
		return false
	
	var distance: float = global_position.distance_to(leader.global_position)
	var max_range: float = 150.0  # Max herding range (150px - must get close to "capture")
	var influence_range: float = 200.0  # HerdInfluenceArea radius - allow when force_influence_transfer
	if NPCConfig and "herd_mentality_detection_range" in NPCConfig:
		influence_range = NPCConfig.herd_mentality_detection_range as float
	const BODY_RADIUS_BUFFER: float = 60.0  # Align with HerdInfluenceArea overlap (shape vs center-distance)
	influence_range += BODY_RADIUS_BUFFER
	# Too far away (influence-driven transfer uses larger range)
	if not force_influence_transfer and distance > max_range:
		return false
	if force_influence_transfer and distance > influence_range:
		return false
	
	# Ordered follow: cannot be stolen by another leader
	if follow_is_ordered and is_herded and herder != null and herder != leader and is_instance_valid(herder):
		return false
	
	# No stealing within same clan: if already herded by a clansman, do not allow another same-clan to steal
	if is_herded and herder != leader and is_instance_valid(herder):
		var herder_clan: String = herder.get_clan_name() if herder.has_method("get_clan_name") else (herder.get("clan_name") as String if herder.get("clan_name") != null else "")
		var leader_clan: String = leader.get_clan_name() if leader.has_method("get_clan_name") else (leader.get("clan_name") as String if leader.get("clan_name") != null else "")
		if herder_clan != "" and herder_clan == leader_clan:
			return false  # Same clan - never steal from a clan mate
	
	# Calculate chance based on proximity (closer = higher chance)
	var base_chance: float = 0.10  # 10% at max range (150px)
	var max_chance: float = 0.80   # 80% at very close range (<50px)
	var proximity_factor: float = 1.0 - (distance / max_range)  # 1.0 at 0px, 0.0 at 150px
	var chance: float = base_chance + (max_chance - base_chance) * proximity_factor
	
	# STEALING MECHANICS: If already herded by someone else
	if is_herded and herder != leader and is_instance_valid(herder):
		# Stealer must be closer than current herder to have a chance
		var herder_distance: float = global_position.distance_to(herder.global_position)
		if distance >= herder_distance:
			return false  # Stealer not closer than herder - can't steal
		
		# Base steal chance is much lower (25% of normal)
		chance *= 0.25
		
		# PROXIMITY-BASED PROTECTION: If herder is close, make stealing much harder
		var protection_distance: float = 150.0  # Protection radius
		if herder_distance < protection_distance:
			# Herder is close - apply protection multiplier
			# At 0px from herder: 0.1x chance (very hard to steal)
			# At 150px from herder: 1.0x chance (normal steal difficulty)
			var protection_factor: float = herder_distance / protection_distance
			chance *= (0.1 + 0.9 * protection_factor)  # Range: 0.1x to 1.0x
		
		# STEALING REQUIRES VERY CLOSE PROXIMITY: Reduce chance if stealer is not very close
		var steal_close_range: float = 100.0  # Must be within 100px to steal effectively
		if distance > steal_close_range:
			# Stealer is too far - heavily reduce chance
			var distance_penalty: float = (distance - steal_close_range) / (max_range - steal_close_range)  # 0.0 at 100px, 1.0 at 150px
			chance *= (1.0 - distance_penalty * 0.8)  # Reduce by up to 80% if at max range
	
	# Prevent rapid back-and-forth stealing with cooldown
	var current_time: float = Time.get_ticks_msec() / 1000.0
	var stealing_cooldown: float = 1.0  # 1 second cooldown between steals
	if is_herded and herder != leader and is_instance_valid(herder):
		if current_time - last_leader_switch_time < stealing_cooldown:
			return false  # Still on cooldown, can't steal yet
	
	# Roll the chance (skip when influence-driven transfer)
	var roll_success: bool = force_influence_transfer or (randf() < chance)
	if roll_success:
		# Resist: chance animal resists; cooldown prevents spam. Disabled during playtests for deterministic transport.
		var resist_chance: float = 0.0
		var resist_disabled: bool = false
		var dc = get_node_or_null("/root/DebugConfig")
		if dc and dc.get("test_overrides") is Dictionary:
			resist_disabled = dc.test_overrides.get("herd_resist_disabled", false)
		if not resist_disabled and NPCConfig and "herd_resist_chance_base" in NPCConfig:
			resist_chance = NPCConfig.herd_resist_chance_base as float
		var resist_cooldown: float = 2.0
		if NPCConfig and "herd_resist_cooldown_sec" in NPCConfig:
			resist_cooldown = NPCConfig.herd_resist_cooldown_sec as float
		var last_resist: float = get_meta("herd_last_resist_time", -999.0)
		var on_cooldown: bool = (current_time - last_resist) < resist_cooldown
		if resist_chance > 0 and not on_cooldown and randf() < resist_chance:
			set_meta("herd_last_resist_time", current_time)
			var herder_id: String = str(leader.get("npc_name")) if leader.get("npc_name") != null else (str(leader.name) if leader else "?")
			if leader.is_in_group("player"):
				herder_id = "Player"
			# Skip log in headless when player is herder (no human to see it; reduces log noise)
			var args: PackedStringArray = OS.get_cmdline_user_args()
			if not (args.has("--headless") and leader.is_in_group("player")):
				print("🐑 Resist: %s resisted herding by %s (%.0f%% base)" % [npc_name, herder_id, resist_chance * 100])
			return false  # Animal resisted - no transfer
		# Only log and set herder if not already herded by this leader
		var already_herded_by_leader: bool = (is_herded and herder == leader)
		
		if not already_herded_by_leader:
			# Capture old herder before overwriting (for agro recover trigger)
			var old_herder: Node2D = null
			var old_herder_name: String = ""
			if is_herded and herder != leader and is_instance_valid(herder):
				old_herder = herder
				@warning_ignore("incompatible_ternary")
				old_herder_name = herder.name if herder else "unknown"
			
			_start_herd(leader)  # Updates herded_count on both old and new herder
			last_leader_switch_time = current_time  # Update cooldown timer
			
			# Agro escalation: successful steal - push to CombatTick (Step 2)
			if old_herder and is_instance_valid(old_herder):
				var agro_add: float = 40.0
				if NPCConfig and "agro_steal_success" in NPCConfig:
					agro_add = NPCConfig.agro_steal_success as float
				if CombatTick:
					CombatTick.push_agro_event(old_herder, agro_add, "herd_steal_success", null)
			
			# Agro recover: notify old herder (caveman/clansman) that they lost this NPC so they can try to recover
			if old_herder and is_instance_valid(old_herder) and old_herder.get("npc_type") in ["caveman", "clansman"]:
				old_herder.set("lost_wildnpc", self)
				old_herder.set("agro_target", leader)
				# agro_meter > 0 from herd_steal_success push above makes is_agro true
				var old_fsm = old_herder.get("fsm")
				if old_fsm and "evaluation_timer" in old_fsm:
					old_fsm.evaluation_timer = 0.0

			
			var leader_name: String = str(leader.name) if leader else "unknown"
			if old_herder_name != "":
				UnifiedLogger.log_npc("NPC switched leaders (stolen): %s -> %s (chance: %.1f%%, distance: %.1f)" % [
					old_herder_name, leader_name, chance * 100.0, distance
				], {
					"npc": npc_name,
					"from": old_herder_name,
					"to": leader_name,
					"chance_percent": "%.1f" % (chance * 100.0),
					"distance": "%.1f" % distance
				}, UnifiedLogger.Level.INFO)
			else:
				UnifiedLogger.log_npc("NPC started following %s (chance: %.1f%%, distance: %.1f)" % [
					leader_name, chance * 100.0, distance
				], {
					"npc": npc_name,
					"leader": leader_name,
					"chance_percent": "%.1f" % (chance * 100.0),
					"distance": "%.1f" % distance
				}, UnifiedLogger.Level.INFO)
			
			var pi = get_node_or_null("/root/PlaytestInstrumentor")
			if pi and pi.is_enabled():
				var lname: String = str(leader.get("npc_name")) if leader.get("npc_name") != null else (str(leader.name) if leader else "?")
				pi.herd_try_chance(npc_name, lname, true, force_influence_transfer)
			# Force immediate FSM evaluation and state change to herd_state (high priority follow mode)
			# NPC must go into high priority follow mode as soon as they are put into a herd
			if fsm:
				# Immediately force state change to herd (bypass normal evaluation)
				# Herd state has priority 11.0 (high priority) and should always be entered when is_herded is true
				if is_herded and herder and is_instance_valid(herder):
					# Check if herd state can be entered (it should always be able to if is_herded is true)
					var states_dict = fsm.get("states")
					if states_dict and states_dict.has("herd"):
						var herd_state = states_dict.get("herd")
						if herd_state and herd_state.has_method("can_enter") and herd_state.can_enter():
							# Only log when we actually transition into herd (change_state no-ops if already herd)
							var prev_fsm: String = fsm.get_current_state_name() if fsm.has_method("get_current_state_name") else ""
							fsm.change_state("herd")
							var now_fsm: String = fsm.get_current_state_name() if fsm.has_method("get_current_state_name") else ""
							if prev_fsm != "herd" and now_fsm == "herd":
								print("🚨 HIGH PRIORITY FOLLOW: %s immediately entered herd state (following %s)" % [
									npc_name, leader_name
								])
					else:
						# Can't enter herd state - force FSM evaluation to find best state
						if "evaluation_timer" in fsm: fsm.evaluation_timer = 0.0
						if fsm.has_method("_evaluate_states"): fsm._evaluate_states()
				else:
					# No herd state found - force FSM evaluation
					if "evaluation_timer" in fsm: fsm.evaluation_timer = 0.0
					if fsm.has_method("_evaluate_states"): fsm._evaluate_states()
			else:
				# Not properly herded - force FSM evaluation
				if "evaluation_timer" in fsm: fsm.evaluation_timer = 0.0
				if fsm.has_method("_evaluate_states"): fsm._evaluate_states()
		
		return true
	else:
		# Failed steal attempt - add agro to herder (current owner) when challenger is NPC, not player
		if is_herded and herder != leader and is_instance_valid(herder):
			var is_player_leader: bool = leader.is_in_group("player") if leader else false
			var leader_type: String = leader.get("npc_type") as String if leader else ""
			if not is_player_leader and leader_type in ["caveman", "clansman"]:
				var agro_add: float = 20.0
				if NPCConfig and "agro_steal_attempt" in NPCConfig:
					agro_add = NPCConfig.agro_steal_attempt as float
				if CombatTick:
					CombatTick.push_agro_event(herder, agro_add, "herd_steal_attempt", null)
	return false

# Simplified herd break check - breaks herd if herder is too far away or dead
func _check_herd_break_distance() -> void:
	# Only check if being herded
	if not is_herded or not herder or not is_instance_valid(herder):
		return
	
	# Check if herder is dead - break herd immediately
	if herder.has_method("is_dead") and herder.is_dead():
		var herder_name: String = str(herder.name) if herder else "unknown"
		UnifiedLogger.log_npc("NPC lost herder %s (herder died)" % herder_name, {
			"npc": npc_name,
			"leader": herder_name,
			"reason": "herder_died"
		}, UnifiedLogger.Level.WARNING)
		var npc_type_str: String = npc_type if npc_type else ""
		if npc_type_str == "woman" or npc_type_str == "sheep" or npc_type_str == "goat":
			if clan_name != "":
				var old_clan = clan_name
				set_clan_name("", "herder_died")
				print("🔄 %s released from herd - became wild (herder died, was in clan: %s)" % [npc_name, old_clan])
			else:
				print("🔄 %s released from herd - became wild (herder died)" % npc_name)
		_clear_herd()
		if fsm and "evaluation_timer" in fsm:
			fsm.evaluation_timer = 0.0
		return
	
	# Ordered follow: never break on distance; only on herder death (handled above)
	if follow_is_ordered:
		return
	
	# Only applies to NPCs with "herd" trait (women, sheep, goats)
	if not has_trait("herd") or (npc_type != "woman" and npc_type != "sheep" and npc_type != "goat"):
		return
	
	# Check if herder is still in range - break herd if out of range
	var herder_distance: float = global_position.distance_to(herder.global_position)
	var herd_break_distance: float = 600.0  # Herd breaks at 600px (per plan)
	if NPCConfig:
		var config_break = NPCConfig.get("herd_max_distance_before_break")
		if config_break != null:
			herd_break_distance = config_break as float
	
	if herder_distance > herd_break_distance:
		# Herder is outside herd break distance (600px) - break the herd
		@warning_ignore("incompatible_ternary")
		var herder_name_str: String = herder.name if herder else "unknown"
		UnifiedLogger.log_npc("NPC lost herder %s (outside range: %.1f > %.1f)" % [
			herder_name_str, herder_distance, herd_break_distance
		], {
			"npc": npc_name,
			"leader": herder_name_str,
			"distance": "%.1f" % herder_distance,
			"max_distance": "%.1f" % herd_break_distance
		}, UnifiedLogger.Level.WARNING)
		
		# Log herd break
		var herder_name: String = str(herder.name) if herder else "unknown"
		UnifiedLogger.log_herding("Herd detection: herd_broken_distance", {
			"npc": npc_name,
			"leader": herder_name,
			"event": "herd_broken_distance",
			"distance": "%.1f" % herder_distance,
			"herd_break_distance": "%.1f" % herd_break_distance
		})
		_clear_herd()
		if fsm and "evaluation_timer" in fsm:
			fsm.evaluation_timer = 0.0

# OLD HERD MENTALITY CODE REMOVED - Using direct trigger system instead
# The direct trigger system in herd_wildnpc_state.gd handles all herding now
# This function has been replaced with _check_herd_break_distance() above

# OLD HERD MENTALITY CODE REMOVED - All orphaned code deleted

func _apply_caveman_seek_push_behavior(_delta: float) -> void:
	# Cavemen actively seek out nearby entities to push them
	# This makes them move toward women and other cavemen to bump into them
	# ONLY active when in agro mode (pushing is basic combat)
	
	# Only seek/push when in agro mode
	if not is_agro:
		return
	
	# CRITICAL FIX: Don't seek push if target is also agro at us (prevents mutual push loops)
	if agro_target and is_instance_valid(agro_target):
		var target_is_agro: bool = agro_target.get("is_agro") if agro_target else false
		var target_agro_target = agro_target.get("agro_target") if agro_target else null
		if target_is_agro and target_agro_target == self:
			# Target is also agro at us - don't seek push (prevents mutual loops)
			# Let agro state handle movement instead
			return
	
	# Don't override important states (agro, build, etc.)
	if fsm:
		var current_state: String = fsm.current_state_name if fsm else ""
		if current_state in ["agro", "build"]:
			return  # Let these states handle movement
	
	# Only do this occasionally (not every frame) to avoid constant direction changes
	if not has_meta("last_seek_push_time"):
		set_meta("last_seek_push_time", 0.0)
	
	var current_time := Time.get_ticks_msec() / 1000.0
	var last_seek_time: float = get_meta("last_seek_push_time", 0.0)
	var seek_interval: float = 0.5  # Check every 0.5 seconds
	
	if current_time - last_seek_time < seek_interval:
		return
	
	set_meta("last_seek_push_time", current_time)
	
	# Get config values
	var seek_range: float = 200.0
	var seek_priority: float = 0.3
	if NPCConfig:
		seek_range = NPCConfig.caveman_seek_push_range
		seek_priority = NPCConfig.caveman_push_seek_priority
	
	# Roll chance to seek push target
	if randf() > seek_priority:
		return  # Skip this check
	
	# Find nearby entities to push (within seek_range)
	var entities := get_tree().get_nodes_in_group("npcs")
	entities.append_array(get_tree().get_nodes_in_group("player"))
	
	var closest_target: Node2D = null
	var closest_distance: float = seek_range
	
	for entity in entities:
		if entity == self or not is_instance_valid(entity):
			continue
		# Skip dead NPCs
		if entity.has_method("is_dead") and entity.is_dead():
			continue
		var distance: float = global_position.distance_to(entity.global_position)
		if distance < closest_distance:
			closest_distance = distance
			closest_target = entity
	
	# If found a target, move toward it to push
	if closest_target and steering_agent:
		steering_agent.set_arrive_target(closest_target.global_position)

# OLD HERD MENTALITY CODE REMOVED - All orphaned attraction-based code deleted
# Direct trigger system in herd_wildnpc_state.gd handles all herding now

func _apply_caveman_push_mechanics(delta: float) -> void:
	# Cavemen push/bump into nearby entities (women, other cavemen, player)
	# ONLY active when in agro mode (cavemen push when aggressive)
	# Note: This function is only called when is_agro is true
	
	# Get push parameters from config
	var push_radius: float = 60.0
	var push_force: float = 500.0
	var agro_multiplier: float = 1.5
	if NPCConfig:
		push_radius = NPCConfig.caveman_push_radius
		push_force = NPCConfig.caveman_push_force
		agro_multiplier = NPCConfig.caveman_push_agro_multiplier
	
	# Apply agro multiplier (always active since this is only called in agro mode)
	push_force *= agro_multiplier
	
	var caveman_pos: Vector2 = global_position
	
	# Push women NPCs (use squared distance for performance)
	var npcs := get_tree().get_nodes_in_group("npcs")
	var push_radius_squared: float = push_radius * push_radius
	var min_distance_squared: float = 0.1 * 0.1
	
	for other_npc in npcs:
		if other_npc == self or not is_instance_valid(other_npc):
			continue
		# Skip dead NPCs
		if other_npc.has_method("is_dead") and other_npc.is_dead():
			continue
		
		var other_type: String = other_npc.get("npc_type") if other_npc else ""
		# Only push other cavemen (not women or animals)
		if other_type != "caveman":
			continue  # Skip women, sheep, goats, etc.
		
		# Skip if same clan (don't push clan members)
		var other_clan: String = other_npc.get("clan_name") if other_npc else ""
		if other_clan != "" and other_clan == clan_name:
			continue  # Same clan, don't push
		# Don't push NPCs that are gathering or crafting (they must stay still)
		if other_npc.get("is_gathering") == true or other_npc.get("is_crafting") == true:
			continue
		
		if true:  # Only push cavemen
			var distance_squared: float = caveman_pos.distance_squared_to(other_npc.global_position)
			if distance_squared < push_radius_squared and distance_squared > min_distance_squared:
				var distance: float = sqrt(distance_squared)
				# Calculate push direction (away from caveman)
				var push_direction: Vector2 = (other_npc.global_position - caveman_pos).normalized()
				# Apply stronger push when closer
				var distance_factor: float = 1.0 - (distance / push_radius)  # 1.0 at 0 distance, 0.0 at push_radius
				var effective_force: float = push_force * distance_factor
				
				# Apply push to NPC velocity
				if other_npc is CharacterBody2D:
					var npc_velocity: Vector2 = other_npc.velocity
					npc_velocity += push_direction * effective_force * delta
					other_npc.velocity = npc_velocity
				
				# Also apply a small position offset for immediate feedback
				other_npc.global_position += push_direction * effective_force * delta * 0.1
	
	# Push player
	var player_nodes := get_tree().get_nodes_in_group("player")
	for player_node in player_nodes:
		if not is_instance_valid(player_node):
			continue
		
		var distance: float = caveman_pos.distance_to(player_node.global_position)
		if distance < push_radius and distance > 0.1:
			# Calculate push direction (away from caveman)
			var push_direction: Vector2 = (player_node.global_position - caveman_pos).normalized()
			# Apply stronger push when closer
			var distance_factor: float = 1.0 - (distance / push_radius)  # 1.0 at 0 distance, 0.0 at push_radius
			var effective_force: float = push_force * distance_factor
			
			# Apply push to player velocity
			if player_node is CharacterBody2D:
				var player_velocity: Vector2 = player_node.velocity
				player_velocity += push_direction * effective_force * delta
				player_node.velocity = player_velocity
			
			# Also apply a small position offset for immediate feedback
			player_node.global_position += push_direction * effective_force * delta * 0.1

func _get_emergency_separation_force() -> Vector2:
	# Emergency separation force when NPCs are too close (prevents getting stuck)
	# This is a direct push-away force, stronger than normal separation
	var emergency_force := Vector2.ZERO
	var min_safe_distance: float = 25.0  # Minimum safe distance between NPCs
	var push_strength: float = 166.67  # 500/3 - reduced by 2/3; NPCs move 1/3 as far when pushed
	
	var npcs := get_tree().get_nodes_in_group("npcs")
	for other_npc in npcs:
		if other_npc == self or not is_instance_valid(other_npc):
			continue
		# Skip dead NPCs
		if other_npc.has_method("is_dead") and other_npc.is_dead():
			continue
		
		var distance: float = global_position.distance_to(other_npc.global_position)
		if distance < min_safe_distance and distance > 0.0:
			# Too close - push away immediately
			var direction: Vector2 = (global_position - other_npc.global_position).normalized()
			var push_force: float = (min_safe_distance - distance) / min_safe_distance * push_strength
			emergency_force += direction * push_force
	
	# Also check for player
	var player_nodes := get_tree().get_nodes_in_group("player")
	for player_node in player_nodes:
		if not is_instance_valid(player_node):
			continue
		var distance: float = global_position.distance_to(player_node.global_position)
		if distance < min_safe_distance and distance > 0.0:
			# Too close to player - push away
			var direction: Vector2 = (global_position - player_node.global_position).normalized()
			var push_force: float = (min_safe_distance - distance) / min_safe_distance * push_strength
			emergency_force += direction * push_force
	
	return emergency_force

func _count_herd_size(leader: Node2D) -> int:
	if HerdManager and leader and is_instance_valid(leader):
		return HerdManager.get_herd_size(leader)
	var count: int = 0
	var all_npcs := get_tree().get_nodes_in_group("npcs")
	for npc in all_npcs:
		if not is_instance_valid(npc):
			continue
		if npc.has_method("is_dead") and npc.is_dead():
			continue
		if npc.get("is_herded") != null and npc.is_herded:
			if npc.get("herder") != null and npc.herder == leader:
				count += 1
	return count

func _check_caveman_aggression() -> void:
	# FIXED: Cavemen should NOT agro at wild NPCs (women, goats, sheep)
	# They should ONLY agro at other cavemen intruders in their land claim
	# This function now only tracks herd size for reference, but does NOT trigger agro
	# Agro is only triggered by _check_land_claim_intrusion() when another caveman enters our land claim
	
	if not is_instance_valid(self):
		return
	
	# Only check for cavemen
	if npc_type != "caveman":
		return
	
	var _current_herd_size: int = _count_herd_size(self)
	# Reference only — agro is from land claim intrusion, not herd size changes

func _apply_defensive_herding_behavior(_delta: float) -> void:
	# AGRO DISABLED: System not ready for implementation
	# Defensive behavior logging disabled to prevent spam
	return
	
	# Cavemen should stay close to their women when threats (player or other cavemen) approach
	# Being closer increases proximity bonus and reduces chance of woman switching
	@warning_ignore("unreachable_code")
	if not is_instance_valid(self):
		return
	
	# Only apply when not in agro state (agro has its own behavior)
	if is_agro:
		return
	
	# Only apply when in herd_wildnpc state or when we have herded NPCs following us
	var current_state_name: String = ""
	if fsm and fsm.current_state:
		current_state_name = fsm.current_state.name if fsm.current_state.has_method("get") else ""
	
	var has_herded_women: bool = _count_herd_size(self) > 0
	
	# If we're not in herd_wildnpc state and have no herded NPCs, skip
	if current_state_name != "herd_wildnpc" and not has_herded_women:
		return
	
	# Find women that are following us (cache this check)
	# Only check periodically to reduce O(n) operations
	if not has_meta("last_herded_women_check_time"):
		set_meta("last_herded_women_check_time", 0.0)
	var last_check: float = get_meta("last_herded_women_check_time", 0.0)
	var current_time: float = Time.get_ticks_msec() / 1000.0
	
	# Cache herded women list and only update every 1 second
	var herded_women: Array[Node2D] = []
	var all_npcs: Array = []  # Declare once at function scope (get_nodes_in_group returns Array[Node])
	if current_time - last_check >= 1.0:
		all_npcs = get_tree().get_nodes_in_group("npcs")
		for npc_check in all_npcs:
			if not is_instance_valid(npc_check):
				continue
			# Skip dead NPCs
			if npc_check.has_method("is_dead") and npc_check.is_dead():
				continue
			var npc_type_str: String = npc_check.get("npc_type") if npc_check else ""
			# Check for all herdable NPCs (women, sheep, goats)
			if npc_type_str == "woman" or npc_type_str == "sheep" or npc_type_str == "goat":
				var npc_herder = npc_check.get("herder")
				if npc_herder == self:
					herded_women.append(npc_check)
		set_meta("last_herded_women_check_time", current_time)
		set_meta("cached_herded_women", herded_women)
	else:
		# Use cached list
		var cached = get_meta("cached_herded_women", [])
		herded_women = cached as Array[Node2D] if cached else []
		# Still need all_npcs for threat checking
		all_npcs = get_tree().get_nodes_in_group("npcs") as Array
	
	# Early exit if no herded women
	if herded_women.is_empty():
		return
	
	# Check each herded woman for nearby threats
	var threat_detection_range: float = 300.0
	var threat_detection_range_squared: float = threat_detection_range * threat_detection_range
	var defensive_distance: float = 100.0  # Stay within this distance when defending
	
	# Cache player list once
	var player_nodes := get_tree().get_nodes_in_group("player")
	
	for woman in herded_women:
		if not is_instance_valid(woman):
			continue
		
		var threat_nearby: bool = false
		var woman_pos: Vector2 = woman.global_position
		
		# Check player (usually only 1)
		for player_node in player_nodes:
			if not is_instance_valid(player_node):
				continue
			var distance_squared: float = woman_pos.distance_squared_to(player_node.global_position)
			if distance_squared <= threat_detection_range_squared:
				threat_nearby = true
				break
		
		# Check other cavemen (only if player not a threat)
		if not threat_nearby:
			for other_npc in all_npcs:
				if other_npc == self or not is_instance_valid(other_npc):
					continue
				# Skip dead NPCs - they don't count as cavemen
				if other_npc.has_method("is_dead") and other_npc.is_dead():
					continue
				var other_type_prop = other_npc.get("npc_type")
				var other_type: String = other_type_prop as String if other_type_prop != null else ""
				if other_type == "caveman":
					var distance_squared: float = woman_pos.distance_squared_to(other_npc.global_position)
					if distance_squared <= threat_detection_range_squared:
						threat_nearby = true
						break
		
		# If threat detected, move closer to woman to defend her
		if threat_nearby:
			var distance_to_woman: float = global_position.distance_to(woman.global_position)
			if distance_to_woman > defensive_distance:
				# Move closer to woman - being closer increases our proximity bonus
				if steering_agent:
					steering_agent.set_target_node(woman)
					
					# AGRO DISABLED: System not ready for implementation
					# Log defensive behavior
					# var woman_name: String = woman.get("npc_name") if woman else "unknown"
					# UnifiedLogger.log("Caveman agro triggered: defending_herded_woman (target: %s, level: 0.0)" % woman_name, UnifiedLogger.Category.COMBAT, UnifiedLogger.Level.INFO, {
					# 	"npc": npc_name,
					# 	"trigger": "defending_herded_woman",
					# 	"target": woman_name,
					# 	"agro_level": "0.0"
					# })

func _find_agro_target() -> void:
	# AGRO DISABLED: System not ready for implementation
	return
	
	# Find nearest caveman or player to target when agro
	@warning_ignore("unreachable_code")
	var perception: float = get_stat("perception")
	var detection_range: float = perception * 20.0 * 2.0  # Double perception range when agro
	
	var nearest_target: Node2D = null
	var nearest_distance: float = INF
	
	# Check player
	var player_nodes := get_tree().get_nodes_in_group("player")
	for player_node in player_nodes:
		if not is_instance_valid(player_node):
			continue
		var distance: float = global_position.distance_to(player_node.global_position)
		if distance < detection_range and distance < nearest_distance:
			nearest_target = player_node
			nearest_distance = distance
	
	# Check other cavemen
	var npcs := get_tree().get_nodes_in_group("npcs")
	for other_npc in npcs:
		if other_npc == self or not is_instance_valid(other_npc):
			continue
		# Skip dead NPCs - they don't count as cavemen
		if other_npc.has_method("is_dead") and other_npc.is_dead():
			continue
		var other_type: String = other_npc.get("npc_type") if other_npc else ""
		if other_type == "caveman":
			var distance: float = global_position.distance_to(other_npc.global_position)
			if distance < detection_range and distance < nearest_distance:
				nearest_target = other_npc
				nearest_distance = distance
	
	agro_target = nearest_target
	if agro_target:
		@warning_ignore("incompatible_ternary")
		var target_name: String = agro_target.name if agro_target else "unknown"
		print("Caveman %s found agro target: %s (distance: %.1f)" % [npc_name, target_name, nearest_distance])

func get_want(want_name: String) -> Dictionary:
	for want in wants:
		if want.get("name") == want_name:
			return want
	return {}

func get_want_meter(want_name: String) -> float:
	var want := get_want(want_name)
	return want.get("meter", 0.0)

func get_debug_info() -> Dictionary:
	# Returns comprehensive debug info about this NPC
	var info := {
		"name": npc_name,
		"type": npc_type,
		"age": age,
		"quality_tier": quality_tier,
		"position": global_position,
		"velocity": velocity,
		"traits": traits.duplicate(),
		"wants": [],
		"buffs_debuffs": [],
		"stats": {}
	}
	
	# Add wants info
	for want in wants:
		info["wants"].append({
			"name": want.get("name"),
			"meter": want.get("meter"),
			"max": want.get("max"),
			"percent": (want.get("meter", 0.0) / want.get("max", 1.0)) * 100.0
		})
	
	# Add buffs/debuffs info
	for buff in buffs_debuffs:
		info["buffs_debuffs"].append({
			"name": buff.get("name"),
			"stat": buff.get("stat"),
			"mult": buff.get("mult"),
			"duration": buff.get("duration", 0.0)
		})
	
	# Add stats info
	if stats_component:
		info["stats"] = stats_component.get_all_stats()
	
	# Add FSM state
	if fsm:
		info["current_state"] = fsm.get_current_state_name()
		info["state_data"] = fsm.get_state_data()
	
	# Add inventory info
	if inventory:
		info["inventory_slots"] = inventory.slot_count
		info["inventory_items"] = []
		for i in range(inventory.slot_count):
			var slot = inventory.slots[i]
			if slot != null:
				info["inventory_items"].append({
					"slot": i,
					"type": slot.get("type"),
					"count": slot.get("count", 1)
				})
	
	return info

func _draw_leader_lines() -> void:
	# Draw lines from this leader to all their followers
	# Only for cavemen, clansmen, and player; skip when dead or when herded
	if (npc_type != "caveman" and npc_type != "clansman" and not is_in_group("player")) or is_herded:
		return
	if has_method("is_dead") and is_dead():
		return
	
	var leader_lines_container = get_node_or_null("LeaderLines")
	if not leader_lines_container:
		# Create container if it doesn't exist
		leader_lines_container = Node2D.new()
		leader_lines_container.name = "LeaderLines"
		add_child(leader_lines_container)
	
	# Clear existing lines
	for child in leader_lines_container.get_children():
		child.queue_free()
	
	# Find all NPCs following this leader
	var all_npcs := get_tree().get_nodes_in_group("npcs")
	var followers: Array[Node2D] = []
	
	for npc_check in all_npcs:
		if not is_instance_valid(npc_check):
			continue
		if npc_check == self:
			continue
		# Skip dead NPCs
		if npc_check.has_method("is_dead") and npc_check.is_dead():
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
		
		# Line goes from leader (origin in local space) to follower position (in local coordinates)
		var leader_pos: Vector2 = Vector2.ZERO
		var follower_pos: Vector2 = to_local(follower.global_position)
		line.points = PackedVector2Array([leader_pos, follower_pos])
		
		leader_lines_container.add_child(line)

# SIMPLIFIED AUTO-DEPOSIT: Clean flow - Check → Find claim → Group items → Deposit → Done
func _check_and_deposit_items() -> void:
	# SIMPLIFIED: Consolidate early returns - check everything upfront
	# Babies cannot deposit - only cavemen and clansmen can
	var is_clansman = (npc_type == "clansman")
	if (npc_type != "caveman" and npc_type != "clansman") or not inventory:
		return
	# Don't deposit while crafting - NPC needs stones to knap; deposit runs after exiting craft
	if fsm and "current_state_name" in fsm and fsm.current_state_name == "craft":
		return
	
	# SIMPLIFIED: Cooldown check (prevent multiple rapid deposits)
	var current_time: float = Time.get_ticks_msec() / 1000.0
	var last_deposit: float = get_meta("last_deposit_time", 0.0)
	if current_time - last_deposit < 1.0:  # 1 second cooldown
		return
	
	# CRITICAL FIX: Check interval - prioritize deposit when inventory is full
	# Check more frequently (0.1s) when inventory is full to prevent getting stuck at perimeter
	var last_check: float = get_meta("last_deposit_check_time", 0.0)
	var check_interval: float = 0.5  # Default 0.5 seconds
	var inv_used_slots: int = inventory.get_used_slots() if inventory.has_method("get_used_slots") else 0
	# 80% of 5 slots normally; when herding 2+, treat as "should deposit" with any items (not 80% full)
	var inventory_full_threshold: int = 4
	var herding_two_plus: bool = herded_count >= 2
	if herding_two_plus:
		inventory_full_threshold = 1  # Any occupied slot → eligible for deposit cadence
	
	# Frequent checks when near-full (4+) or herding 2+ with any items (threshold 1)
	if inv_used_slots >= inventory_full_threshold:
		check_interval = 0.1
	
	if current_time - last_check < check_interval:
		return
	set_meta("last_deposit_check_time", current_time)
	
	# SIMPLIFIED: Early exit if no items (use helper function if available)
	if inventory.has_method("get_used_slots") and inventory.get_used_slots() == 0:
		return
	
	# SIMPLIFIED: Find land claim (extract to helper)
	var my_clan: String = get_clan_name()
	if my_clan == "":
		return
	
	var land_claim: Node2D = _find_land_claim_for_deposit(my_clan)
	if not land_claim:
		return
	
	var claim_inventory = land_claim.get("inventory")
	if not claim_inventory:
		return
	
	# CRITICAL: Check if land claim inventory has space before attempting deposit
	# This prevents NPCs from getting stuck trying to deposit when claim is full
	if not claim_inventory.has_space():
		var used_slots = claim_inventory.get_used_slots()
		var total_slots = claim_inventory.slot_count
		# Only log once every 5 seconds to prevent spam
		var last_full_warning: float = get_meta("last_full_claim_warning", 0.0)
		if current_time - last_full_warning >= 5.0:
			print("⚠️ AUTO-DEPOSIT: %s cannot deposit - land claim '%s' inventory is FULL (%d/%d slots used)" % [npc_name, my_clan, used_slots, total_slots])
			set_meta("last_full_claim_warning", current_time)
		return  # Land claim inventory is full, skip deposit attempt
	
	# SIMPLIFIED: Group ALL items by type (keep 1 food TOTAL for personal use, not per type)
	const FOOD_TO_KEEP: int = 1
	var items_to_deposit: Dictionary = {}  # Type -> Amount
	var total_items_before: int = 0
	var _total_food_items: int = 0  # Track total food items across all slots (for future use)
	
	# First pass: Count total food items first (needed to keep only 1 food total)
	for i in range(inventory.slot_count):
		var slot = inventory.slots[i]
		if slot == null or not slot is Dictionary:
			continue
		var item_type = slot.get("type")
		var item_count: int = slot.get("count", 0) as int
		if item_type != null and item_count > 0 and ResourceData.is_food(item_type):
			_total_food_items += item_count
	
	# Second pass: Collect ALL items and group by type (deposit all except 1 food total)
	var food_kept: int = 0  # Track how many food items we've kept
	for i in range(inventory.slot_count):
		var slot = inventory.slots[i]
		if slot == null or not slot is Dictionary:
			continue
		
		var item_type = slot.get("type")
		var item_count: int = slot.get("count", 0) as int
		
		if item_type == null or item_count <= 0:
			continue
		
		total_items_before += item_count
		var is_food: bool = ResourceData.is_food(item_type)
		var amount_to_deposit: int = item_count
		
		# For food: keep only 1 food item TOTAL across all food types
		if is_food:
			var food_to_deposit_from_slot: int = item_count
			if food_kept < FOOD_TO_KEEP:
				# Keep some food from this slot
				var food_to_keep_from_slot: int = min(FOOD_TO_KEEP - food_kept, item_count)
				food_kept += food_to_keep_from_slot
				food_to_deposit_from_slot = item_count - food_to_keep_from_slot
			amount_to_deposit = food_to_deposit_from_slot
		
		# Group by type (sum amounts for same type across multiple slots)
		if amount_to_deposit > 0:
			items_to_deposit[item_type] = items_to_deposit.get(item_type, 0) + amount_to_deposit
	
	# Second pass: Deposit ALL grouped items (single transaction per type)
	var total_deposited: int = 0
	var distance: float = global_position.distance_to(land_claim.global_position)
	
	for item_type in items_to_deposit:
		var amount: int = items_to_deposit[item_type]
		if amount <= 0:
			continue
		
		# Add to land claim first
		if not claim_inventory.add_item(item_type, amount):
			# Land claim inventory became full during deposit (another NPC may have filled it)
			print("⚠️ AUTO-DEPOSIT: %s failed to add %d %s to land claim '%s' - inventory became full during deposit (used: %d/%d slots)" % [
				npc_name, amount, ResourceData.get_resource_name(item_type) if item_type != null else "items",
				my_clan, claim_inventory.get_used_slots(), claim_inventory.slot_count
			])
			# Break out of deposit loop - claim is now full, stop trying to deposit more items
			break
		
		# Then remove from NPC inventory (this handles multiple slots automatically)
		if not inventory.remove_item(item_type, amount):
			print("⚠️ AUTO-DEPOSIT: %s failed to remove %d %s from inventory" % [npc_name, amount, ResourceData.get_resource_name(item_type) if item_type != null else "items"])
			# Rollback: remove from land claim if remove failed
			claim_inventory.remove_item(item_type, amount)
			continue
		
		total_deposited += amount
		
		# Track deposit by resource type in competition tracker
		var competition_tracker = get_node_or_null("/root/CompetitionTracker")
		if competition_tracker and competition_tracker.has_method("record_deposit"):
			competition_tracker.record_deposit(npc_name, my_clan, item_type, amount)
	
	# SIMPLIFIED: Log and set cooldown if deposit succeeded
	if total_deposited > 0:
		set_meta("last_deposit_time", current_time)
		if herding_two_plus:
			var pi = get_node_or_null("/root/PlaytestInstrumentor")
			if pi and pi.has_method("deposit_while_herding"):
				pi.deposit_while_herding(npc_name, herded_count, total_deposited)
		var activity_tracker = get_node_or_null("/root/NPCActivityTracker")
		if activity_tracker and activity_tracker.has_method("log_deposit"):
			activity_tracker.log_deposit(str(get_instance_id()), total_deposited)
		var remaining_items: int = inventory.get_used_slots() if inventory.has_method("get_used_slots") else 0
		var log_msg = "✅ AUTO-DEPOSIT: %s deposited %d items (%d total before, %d remaining) to land claim '%s' (distance: %.1fpx)" % [
			npc_name, total_deposited, total_items_before, remaining_items, my_clan, distance
		]
		print(log_msg)
		if is_clansman:
			UnifiedLogger.log_npc("🧑 CLANSMAN DEPOSIT: %s deposited %d items (%d before, %d remaining) to '%s' (%.1fpx)" % [
				npc_name, total_deposited, total_items_before, remaining_items, my_clan, distance
			], {
				"npc": npc_name, "action": "deposit", "items_deposited": total_deposited,
				"items_before": total_items_before, "items_remaining": remaining_items, "clan": my_clan, "distance": "%.1f" % distance
			}, UnifiedLogger.Level.INFO)
		
		# USER REQUIREMENT: After deposit, immediately go back to herd mode
		# Trigger immediate FSM evaluation to check if herd_wildnpc can enter
		# Clear any deposit-related flags
		remove_meta("moving_to_deposit")
		if has_meta("is_depositing"):
			remove_meta("is_depositing")
		
		# Force immediate state evaluation - caveman should go back to herding
		if fsm and "evaluation_timer" in fsm:
			fsm.evaluation_timer = 0.0  # Force immediate evaluation
		if fsm and fsm.has_method("_evaluate_states"):
			fsm._evaluate_states()  # Evaluate now - herd_wildnpc (10.6) should take priority
	else:
		# No items deposited - check if it's just 1 food item (expected behavior, don't warn)
		if total_items_before == 0:
			return  # No items at all (expected)
		
		# Check if remaining item is food (we keep 1 food item, so this is expected)
		var remaining_items: int = inventory.get_used_slots() if inventory.has_method("get_used_slots") else 0
		
		# Check if all remaining items are food (we keep 1 food total, so if all remaining are food, it's expected)
		if remaining_items > 0:
			var all_food: bool = true
			var total_food_count: int = 0
			for i in range(inventory.slot_count):
				var slot = inventory.slots[i]
				if slot != null and slot is Dictionary:
					var item_type = slot.get("type")
					var item_count: int = slot.get("count", 0) as int
					if item_type != null and item_count > 0:
						if ResourceData.is_food(item_type):
							total_food_count += item_count
						else:
							all_food = false
							break
			
			# If all remaining items are food and we have 1 or less food item, that's expected (we keep 1 food)
			if all_food and total_food_count <= 1:
				return  # All remaining items are food and we're keeping 1 - expected, don't warn
		
		# Single item check (backup)
		if remaining_items == 1 and total_items_before == 1:
			# Only 1 item remains - check if it's food (expected to keep 1 food)
			var has_food: bool = false
			for i in range(inventory.slot_count):
				var slot = inventory.slots[i]
				if slot != null and slot is Dictionary:
					var item_type = slot.get("type")
					if item_type != null and ResourceData.is_food(item_type):
						has_food = true
						break
			if has_food:
				return  # Only 1 food item kept - this is expected, don't warn
		
		# Otherwise, something might be wrong - log it
		print("⚠️ AUTO-DEPOSIT: %s has %d items but deposited 0 (remaining: %d slots) - check if deposit failed" % [npc_name, total_items_before, remaining_items])

# Helper to find land claim for deposit (NPCs must be within deposit_range of center)
@warning_ignore("shadowed_variable")
func _find_land_claim_for_deposit(clan_name: String) -> Node2D:
	var deposit_dist: float = 100.0
	if NPCConfig:
		deposit_dist = NPCConfig.deposit_range

	var land_claims := get_tree().get_nodes_in_group("land_claims")
	for claim in land_claims:
		if not is_instance_valid(claim):
			continue
		
		var claim_clan: String = claim.get("clan_name") as String if claim.get("clan_name") != null else ""
		if claim_clan != clan_name:
			continue
		
		var distance: float = global_position.distance_to(claim.global_position)
		if distance <= deposit_dist:
			return claim
	
	return null

func _apply_sheep_grouping_behavior(_delta: float) -> void:
	# Sheep try to stay near other sheep (grouping behavior)
	# This makes sheep naturally cluster together
	if not is_instance_valid(self):
		return
	
	# Only apply when not herded (herded sheep follow their leader)
	if is_herded:
		return
	
	# Don't override steering when headed to a farm/dairy - building assignment takes priority
	if workplace_building and is_instance_valid(workplace_building):
		return
	
	# Find nearby sheep (use squared distance for performance)
	var all_npcs := get_tree().get_nodes_in_group("npcs")
	var nearby_sheep: Array[Node2D] = []
	var grouping_range: float = 150.0  # Range to look for other sheep
	var grouping_range_squared: float = grouping_range * grouping_range
	var my_pos: Vector2 = global_position
	
	for other_npc in all_npcs:
		if other_npc == self or not is_instance_valid(other_npc):
			continue
		# Skip dead NPCs
		if other_npc.has_method("is_dead") and other_npc.is_dead():
			continue
		
		var other_type: String = other_npc.get("npc_type") if other_npc else ""
		if other_type == "sheep":
			var distance_squared: float = my_pos.distance_squared_to(other_npc.global_position)
			if distance_squared <= grouping_range_squared:
				nearby_sheep.append(other_npc)
	
	# Log grouping behavior occasionally
	if not has_meta("last_grouping_log_time"):
		set_meta("last_grouping_log_time", 0.0)
	var last_grouping_log: float = get_meta("last_grouping_log_time", 0.0)
	var current_time: float = Time.get_ticks_msec() / 1000.0
	if current_time - last_grouping_log > 10.0:  # Log every 10 seconds
		UnifiedLogger.log_herding("Herd detection: sheep_grouping", {
			"npc": npc_name,
			"leader": "grouping",
			"event": "sheep_grouping",
			"nearby_sheep": str(nearby_sheep.size()),
			"grouping_range": "%.1f" % grouping_range
		}, UnifiedLogger.Level.DEBUG)
		set_meta("last_grouping_log_time", current_time)
	
	# If we found nearby sheep, move toward the group center
	if nearby_sheep.size() > 0:
		var group_center: Vector2 = Vector2.ZERO
		for sheep in nearby_sheep:
			group_center += sheep.global_position
		group_center /= nearby_sheep.size()
		
		# Move toward group center (but not too close - maintain some spacing)
		var distance_to_center: float = global_position.distance_to(group_center)
		var desired_distance: float = 40.0  # Desired distance from group center
		
		if distance_to_center > desired_distance:
			# Move toward group center
			var direction: Vector2 = (group_center - global_position).normalized()
			if steering_agent:
				# Use steering to move toward group center
				var target_pos: Vector2 = group_center - direction * desired_distance
				steering_agent.set_target_position(target_pos)
		else:
			# Close enough to group center - clear target to prevent getting stuck
			if steering_agent:
				# Set to wander mode if close enough to group
				steering_agent.set_wander(global_position, 50.0)  # Small wander radius when grouped

func _check_and_assign_to_building() -> void:
	# OccupationSystem: animals and women request slot, path, confirm on arrival
	if not is_instance_valid(self):
		return
	if npc_type != "sheep" and npc_type != "goat" and npc_type != "woman":
		return
	if clan_name == "":
		return
	if not OccupationSystem:
		return
	var target: Node2D = OccupationSystem.get_workplace(self) as Node2D
	if target:
		# Already OCCUPIED = we're in the building, don't steer
		if OccupationSystem.get_ref_state(self) == OccupationSystem.OccupationState.OCCUPIED:
			workplace_building = null
			return
		# RESERVED - path and try confirm when close
		workplace_building = target
		var dist: float = global_position.distance_to(target.global_position)
		if steering_agent:
			steering_agent.set_target_position(target.global_position)
		# Timeout: unassign after 12s if not close (was 5s - too aggressive for distant animals)
		var assign_time: float = get_meta("assigned_building_since", 0.0) as float
		var now_sec: float = Time.get_ticks_msec() / 1000.0
		if assign_time > 0.0 and (now_sec - assign_time) > 12.0 and dist >= ANIMAL_ENTER_RANGE:
			OccupationDiagLogger.log("ANIMAL_ASSIGN_TIMEOUT", {"npc": npc_name, "building": target.name, "dist": roundf(dist), "elapsed_s": roundf(now_sec - assign_time)})
			OccupationSystem.unassign(self, "timeout")
			workplace_building = null
			remove_meta("assigned_building_since")
			return
		if dist < ANIMAL_ENTER_RANGE:
			if OccupationSystem.get_ref_state(self) == OccupationSystem.OccupationState.RESERVED:
				var ok: bool = OccupationSystem.confirm_arrival(self)
				if ok:
					OccupationDiagLogger.log("ANIMAL_ENTERED_BUILDING", {"npc": npc_name, "building": target.name, "type": npc_type})
					workplace_building = null
					remove_meta("assigned_building_since")
					if steering_agent:
						steering_agent.set_wander(global_position, 50.0)
		return
	# No assignment - retry throttle
	var now: float = Time.get_ticks_msec() / 1000.0
	var next_retry: float = get_meta("next_occupation_retry_time", 0.0) as float
	if now < next_retry:
		return
	var result: Dictionary = OccupationSystem.request_slot(self)
	if result.is_empty():
		set_meta("next_occupation_retry_time", now + 1.5)
		return
	var bld: BuildingBase = result.get("building") as BuildingBase
	if not bld or not is_instance_valid(bld):
		return
	workplace_building = bld as Node2D
	set_meta("assigned_building_since", now)
	set_meta("next_occupation_retry_time", now + 1.5)
	if steering_agent:
		steering_agent.set_target_position(bld.global_position)
	OccupationDiagLogger.log("ANIMAL_ASSIGNED_TO_BUILDING", {"npc": npc_name, "type": npc_type, "building": bld.name})
	var bt = bld.get("building_type")
	var building_type_name: String = ResourceData.get_resource_name(bt) if bt != null else "unknown"
	UnifiedLogger.log_npc("Action started: assign_to_building (building: %s)" % building_type_name, {
		"npc": npc_name,
		"action": "assign_to_building",
		"target": building_type_name,
		"npc_type": npc_type,
		"building": str(bld.name),
		"distance": "%.1f" % global_position.distance_to(bld.global_position)
	})

func _building_is_physically_full(building: Node2D) -> bool:
	"""True when all animal slots have animals (ignores reservations). Used for 'give up' check."""
	if not building or not is_instance_valid(building):
		return true
	# Only Farm/Dairy have animal_slots; LandClaim etc. return false (don't give up)
	var bt = building.get("building_type")
	if bt == null or (bt != ResourceData.ResourceType.FARM and bt != ResourceData.ResourceType.DAIRY_FARM):
		return false
	if not "animal_slots" in building or building.animal_slots.size() == 0:
		return false
	var filled := 0
	var slots: Array = building.animal_slots
	for i in slots.size():
		var n = slots[i]
		if n != null and is_instance_valid(n):
			filled += 1
	return filled >= slots.size()

func _check_land_claim_intrusion(delta: float) -> void:
	# Check if any intruders (player, enemy cavemen, enemy clansmen) are in our land claim
	# If so, rapidly increase agro_meter for combat entry
	var my_claim: Node2D = null
	var claim_pos: Vector2 = Vector2.ZERO
	var claim_radius: float = 400.0
	var filter_clan: String = clan_name if clan_name else ""
	
	# Defenders use defend_target as the claim they're defending (Step 7). Run even without clan_name.
	var dt = get("defend_target")
	if dt != null and is_instance_valid(dt):
		my_claim = dt
		claim_pos = my_claim.global_position
		var rp = my_claim.get("radius")
		if rp != null:
			claim_radius = rp as float
		var cp = my_claim.get("clan_name")
		if cp != null and cp is String and (cp as String) != "":
			filter_clan = cp as String
	elif clan_name and clan_name != "":
		# Match get_my_land_claim(): prefer LandClaim, else Campfire (same clan)
		var land_claims := get_tree().get_nodes_in_group("land_claims")
		var fallback_territory: Node2D = null
		for claim in land_claims:
			if not is_instance_valid(claim):
				continue
			var claim_clan_prop = claim.get("clan_name")
			var c: String = claim_clan_prop as String if claim_clan_prop != null else ""
			if c != clan_name:
				continue
			if claim is LandClaim:
				my_claim = claim as Node2D
				claim_pos = my_claim.global_position
				var radius_prop = my_claim.get("radius")
				if radius_prop != null:
					claim_radius = radius_prop as float
				filter_clan = clan_name
				break
			fallback_territory = claim as Node2D
		if not my_claim and fallback_territory:
			my_claim = fallback_territory
			claim_pos = my_claim.global_position
			var rp2 = my_claim.get("radius")
			if rp2 != null:
				claim_radius = rp2 as float
			filter_clan = clan_name
	
	if not my_claim:
		return  # No territory (flag/campfire) found
	
	# Step 5: Prefer EnemiesInClaim (event-driven) when available; else scan
	var intruders: Array = []
	if my_claim.has_method("get_enemies_in_claim"):
		intruders = my_claim.get_enemies_in_claim()
	else:
		var all_npcs := get_tree().get_nodes_in_group("npcs")
		var player_nodes := get_tree().get_nodes_in_group("player")
		for other_npc in all_npcs:
			if not is_instance_valid(other_npc) or other_npc == self:
				continue
			if other_npc.has_method("is_dead") and other_npc.is_dead():
				continue
			var other_type: String = other_npc.get("npc_type") if other_npc else ""
			if other_type != "caveman" and other_type != "clansman":
				continue
			var other_clan: String = other_npc.get("clan_name") if other_npc else ""
			if filter_clan != "" and other_clan == filter_clan:
				continue
			if claim_pos.distance_to(other_npc.global_position) <= claim_radius:
				intruders.append(other_npc)
		for player_node in player_nodes:
			if not is_instance_valid(player_node):
				continue
			if claim_pos.distance_to(player_node.global_position) <= claim_radius:
				if not my_claim.get("player_owned"):
					intruders.append(player_node)
	
	# If intruders found, report to land claim for emergency defend (throttling at claim)
	if intruders.size() > 0 and my_claim and my_claim.has_method("report_raid"):
		if intruders.size() >= 2:
			my_claim.report_raid()
		else:
			my_claim.report_intruder()
	
	# If intruders found, push agro event only when within our perception range
	if intruders.size() > 0:
		var perception_range: float = 300.0
		if NPCConfig:
			var pr = NPCConfig.get("agro_perception_range")
			if pr != null:
				perception_range = pr as float
		var agro_increase_rate: float = 50.0
		var nearest_intruder: Node2D = null
		var nearest_distance: float = INF
		for intruder in intruders:
			if not is_instance_valid(intruder):
				continue
			var d: float = global_position.distance_to(intruder.global_position)
			if d < nearest_distance and d <= perception_range:
				nearest_distance = d
				nearest_intruder = intruder
		if nearest_intruder and CombatTick and not _skip_agro_meter_pumps():
			CombatTick.push_agro_event(self, agro_increase_rate * delta, "intrusion", nearest_intruder)

func _check_proximity_agro(delta: float) -> void:
	"""Proximity agro: enemy within config radius of this NPC builds agro. No claim required. Capped by agro_perception_range."""
	if npc_type != "caveman" and npc_type != "clansman":
		return
	if _skip_agro_meter_pumps():
		return
	var radius: float = 380.0
	var rate: float = 50.0
	if NPCConfig:
		var r = NPCConfig.get("proximity_agro_radius")
		if r != null:
			radius = r as float
		var rt = NPCConfig.get("proximity_agro_rate")
		if rt != null:
			rate = rt as float
		var pr = NPCConfig.get("agro_perception_range")
		if pr != null:
			radius = minf(radius, pr as float)
	var pa: PerceptionArea = get_node_or_null("DetectionArea") as PerceptionArea
	if not pa:
		UnifiedLogger.log_npc("PerceptionArea null - skipping proximity agro check", {"npc": npc_name}, UnifiedLogger.Level.WARNING)
		return
	var enemies: Array = pa.get_enemies_in_range(global_position, radius, self)
	var nearest_enemy: Node2D = null
	var nearest_d: float = radius + 1.0
	for other in enemies:
		if not is_instance_valid(other):
			continue
		var d: float = global_position.distance_to(other.global_position)
		if d < nearest_d:
			nearest_d = d
			nearest_enemy = other as Node2D
	if nearest_enemy and CombatTick:
		var pi = get_node_or_null("/root/PlaytestInstrumentor")
		if pi and pi.has_method("perception_query"):
			pi.perception_query(npc_name, "proximity", enemies.size(), radius)
		var rate_mult: float = 1.0
		var ctx = get("command_context") if get("command_context") != null else {}
		if ctx.get("mode") == "GUARD":
			rate_mult = 1.5  # Agro raises faster in guard mode
		CombatTick.push_agro_event(self, rate * rate_mult * delta, "proximity", nearest_enemy)

func _check_area_of_agro(delta: float) -> void:
	"""AOA: (1) On claim — inner zone vs enemies near us while we have a claim. (2) Wilderness — personal-space bubble for cavemen/clansmen vs hostile cavemen/clansmen even with no claim."""
	if _skip_agro_meter_pumps():
		return
	var aoa_radius: float = 200.0
	var perception_cap: float = 300.0
	if NPCConfig:
		var r = NPCConfig.get("area_of_agro_radius")
		if r != null:
			aoa_radius = r as float
		var pr = NPCConfig.get("agro_perception_range")
		if pr != null:
			perception_cap = pr as float
	aoa_radius = minf(aoa_radius, perception_cap)

	var pa: PerceptionArea = get_node_or_null("DetectionArea") as PerceptionArea
	if not pa:
		UnifiedLogger.log_npc("PerceptionArea null - skipping AOA agro check", {"npc": npc_name}, UnifiedLogger.Level.WARNING)
		return

	# AOP = our land claim radius when we have a claim
	var aop_radius: float = 400.0
	var claim: Node2D = get("defend_target") if get("defend_target") != null else null
	if not claim and clan_name != "":
		var claims := get_tree().get_nodes_in_group("land_claims")
		for c in claims:
			if not is_instance_valid(c):
				continue
			if c.get("clan_name") == clan_name:
				claim = c as Node2D
				break
	if claim and is_instance_valid(claim):
		var rp = claim.get("radius")
		if rp != null:
			aop_radius = rp as float

	# Wilderness personal space: cavemen/clansmen without a valid claim still get tight AOA vs enemies (not claim-only)
	if not claim or not is_instance_valid(claim):
		if npc_type == "caveman" or npc_type == "clansman":
			_push_aoa_agro_for_enemies(delta, aoa_radius, "aoa_wilderness")
		return

	var claim_aoa: float = minf(aoa_radius, aop_radius)
	var nearby_enemies: Array = pa.get_enemies_in_range(global_position, claim_aoa, self)
	if nearby_enemies.size() > 0:
		var agro_increase_rate: float = 50.0
		var nearest_enemy: Node2D = null
		var nearest_distance: float = INF
		for enemy in nearby_enemies:
			if not is_instance_valid(enemy):
				continue
			var d: float = global_position.distance_to(enemy.global_position)
			if d < nearest_distance:
				nearest_distance = d
				nearest_enemy = enemy
		if CombatTick and nearest_enemy:
			var pi = get_node_or_null("/root/PlaytestInstrumentor")
			if pi and pi.has_method("perception_query"):
				pi.perception_query(npc_name, "aoa", nearby_enemies.size(), claim_aoa)
			CombatTick.push_agro_event(self, agro_increase_rate * delta, "aoa", nearest_enemy)

func _push_aoa_agro_for_enemies(delta: float, range_px: float, reason: String) -> void:
	if _skip_agro_meter_pumps():
		return
	var pa_inner: PerceptionArea = get_node_or_null("DetectionArea") as PerceptionArea
	if not pa_inner:
		return
	var nearby_enemies: Array = pa_inner.get_enemies_in_range(global_position, range_px, self)
	if nearby_enemies.is_empty():
		return
	var agro_increase_rate: float = 50.0
	var nearest_enemy: Node2D = null
	var nearest_distance: float = INF
	for enemy in nearby_enemies:
		if not is_instance_valid(enemy):
			continue
		var d: float = global_position.distance_to(enemy.global_position)
		if d < nearest_distance:
			nearest_distance = d
			nearest_enemy = enemy as Node2D
	if not nearest_enemy or not CombatTick:
		return
	var pi = get_node_or_null("/root/PlaytestInstrumentor")
	if pi and pi.has_method("perception_query"):
		pi.perception_query(npc_name, reason, nearby_enemies.size(), range_px)
	CombatTick.push_agro_event(self, agro_increase_rate * delta, reason, nearest_enemy)

func _check_mammoth_agro(delta: float) -> void:
	"""Mammoth agro: when threats enter AOP and within perception, agro increases. Rate scales with threat count."""
	if _skip_agro_meter_pumps():
		return
	var aop_radius: float = 600.0
	var base_rate: float = 30.0
	if NPCConfig:
		var r = NPCConfig.get("mammoth_aop_radius")
		if r != null:
			aop_radius = r as float
		var pr = NPCConfig.get("agro_perception_range")
		if pr != null:
			aop_radius = minf(aop_radius, pr as float)
		var br = NPCConfig.get("mammoth_base_agro_rate")
		if br != null:
			base_rate = br as float

	var pa: PerceptionArea = get_node_or_null("DetectionArea") as PerceptionArea
	if not pa:
		UnifiedLogger.log_npc("PerceptionArea null - skipping mammoth agro check", {"npc": npc_name}, UnifiedLogger.Level.WARNING)
		return
	var threats: Array = pa.get_threats_in_range(global_position, aop_radius, self)

	if threats.size() > 0:
		var agro_rate: float = base_rate * threats.size()
		var nearest: Node2D = null
		var nearest_dist: float = INF
		for threat in threats:
			if not is_instance_valid(threat):
				continue
			var d: float = global_position.distance_to(threat.global_position)
			if d < nearest_dist:
				nearest_dist = d
				nearest = threat
		if CombatTick:
			var pi = get_node_or_null("/root/PlaytestInstrumentor")
			if pi and pi.has_method("perception_query"):
				pi.perception_query(npc_name, "mammoth", threats.size(), aop_radius)
			CombatTick.push_agro_event(self, agro_rate * delta, "mammoth", nearest)

# Get combat target candidates in range (Step 5: HostileEntityIndex; fallback PerceptionArea/legacy).
func get_combat_target_candidates(center: Vector2, radius: float) -> Array:
	if HostileEntityIndex:
		return HostileEntityIndex.get_enemies_in_range(center, radius, self)
	var pa: PerceptionArea = get_node_or_null("DetectionArea") as PerceptionArea
	if pa:
		return pa.get_enemies_in_range(center, radius, self)
	# Legacy: no index
	var out: Array = []
	var all_npcs = get_tree().get_nodes_in_group("npcs")
	var player_nodes = get_tree().get_nodes_in_group("player")
	for target in all_npcs + player_nodes:
		if not is_instance_valid(target) or target == self:
			continue
		var target_type: String = target.get("npc_type") as String if target.get("npc_type") != null else ""
		var is_player: bool = target.is_in_group("player")
		if target_type != "caveman" and target_type != "clansman" and not is_player:
			continue
		if CombatAllyCheck.is_ally(self, target):
			continue
		var th: HealthComponent = target.get_node_or_null("HealthComponent")
		if th and th.is_dead:
			continue
		if center.distance_to(target.global_position) <= radius:
			out.append(target)
	return out

# NOTE: Removed duplicate _trigger_follow_directly function - using the one defined earlier at line 953
