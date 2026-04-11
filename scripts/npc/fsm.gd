extends Node
class_name FSM

# Finite State Machine for NPC behaviors
# Modular state system - each state is a separate script

# Preload state scripts once at parse time (no per-NPC disk I/O)
const IdleStateScript = preload("res://scripts/npc/states/idle_state.gd")
const WanderStateScript = preload("res://scripts/npc/states/wander_state.gd")
const SeekStateScript = preload("res://scripts/npc/states/seek_state.gd")
const EatStateScript = preload("res://scripts/npc/states/eat_state.gd")
const GatherStateScript = preload("res://scripts/npc/states/gather_state.gd")
const HerdStateScript = preload("res://scripts/npc/states/herd_state.gd")
const PartyStateScript = preload("res://scripts/npc/states/party_state.gd")
const HerdWildNPCStateScript = preload("res://scripts/npc/states/herd_wildnpc_state.gd")
const AgroStateScript = preload("res://scripts/npc/states/agro_state.gd")
const CombatStateScript = preload("res://scripts/npc/states/combat_state.gd")
const FleeCombatStateScript = preload("res://scripts/npc/states/flee_combat_state.gd")
const DefendStateScript = preload("res://scripts/npc/states/defend_state.gd")
const RaidStateScript = preload("res://scripts/npc/states/raid_state.gd")
const SearchStateScript = preload("res://scripts/npc/states/search_state.gd")
const BuildStateScript = preload("res://scripts/npc/states/build_state.gd")
const ReproductionStateScript = preload("res://scripts/npc/states/reproduction_state.gd")
const OccupyBuildingStateScript = preload("res://scripts/npc/states/occupy_building_state.gd")
const WorkAtBuildingStateScript = preload("res://scripts/npc/states/work_at_building_state.gd")
const CraftStateScript = preload("res://scripts/npc/states/craft_state.gd")
const BuildHutForWomanStateScript = preload("res://scripts/npc/states/build_hut_for_woman_state.gd")

var npc: NPCBase = null
var current_state: Node = null
var current_state_name: String = "idle"
var _state_entered: bool = false  # Track if enter() has been called for current state

# State registry
var states: Dictionary = {}
var state_scripts: Dictionary = {}

# State priority system (higher = more important)
var state_priorities: Dictionary = {}

# Update interval for state evaluation (adaptive: near player = fast, far = slower)
var evaluation_interval: float = 0.1  # Base interval when near player
const NEAR_PLAYER_DISTANCE: float = 800.0  # px; within this use evaluation_interval
const FAR_EVALUATION_INTERVAL: float = 0.25  # when far from player (reduces frame spikes)
var evaluation_timer: float = 0.0
var last_state_change_time: float = 0.0  # Track when state last changed (prevent rapid switching loops)
var min_state_change_cooldown: float = 0.2  # Minimum time between state changes (prevents loops)

# Priority cache: state_name -> float; invalidated when combat_target, defend_target, herded_count, follow_is_ordered change
var _cached_priority: Dictionary = {}
var _cache_key: int = 0

func initialize(npc_ref: NPCBase) -> void:
	npc = npc_ref
	
	# Register default states (using class_name instead of script paths for now)
	# We'll create states as Node instances with scripts attached
	_register_state("idle", "")
	_register_state("wander", "")
	_register_state("seek", "")
	_register_state("eat", "")
	_register_state("gather", "")
	_register_state("herd", "")
	_register_state("party", "")
	_register_state("agro", "")
	_register_state("combat", "")  # Combat state for melee combat
	_register_state("flee_combat", "")  # Break contact — entered from combat_state or explicit change_state
	_register_state("defend", "")  # Defend land claim border (Step 7)
	_register_state("raid", "")  # Raid enemy land claims (Phase 3)
	_register_state("search", "")  # SEARCHING role — ant-style loop (guide)
	_register_state("build", "")  # Build state for land claim placement
	_register_state("herd_wildnpc", "")
	_register_state("reproduction", "")  # Reproduction state for women
	_register_state("occupy_building", "")  # Occupy building state for women
	_register_state("work_at_building", "")  # Work at building state for women
	_register_state("craft", "")  # Craft state for knapping (clansmen/cavemen)
	_register_state("build_hut_for_woman", "")  # Herder builds Living Hut for delivered woman
	
	# Create state instances directly
	_create_state_instances()
	
	# Set initial state to wander (NPCs should wander by default)
	# Set directly without calling change_state to avoid initialization issues
	current_state = _get_state("wander")
	current_state_name = "wander"
	_state_entered = false  # Will call enter() on first update
	# Stagger evaluations so all NPCs don't run _evaluate_states on same frame
	var id_str: String = str(npc.name) if npc else "unknown"
	evaluation_timer = (hash(id_str) % 100) / 1000.0  # 0–99ms offset

func _create_state_instances() -> void:
	# Create state instances with preloaded scripts
	var nn_prop = npc.get("npc_name") if npc else null
	var npc_name: String = str(nn_prop) if nn_prop != null else "unknown"
	
	if IdleStateScript:
		var state: Node = Node.new()
		state.set_script(IdleStateScript)
		state.name = "IdleState"
		add_child(state)
		states["idle"] = state
		state.initialize(npc)
		# Set FSM reference after initialization
		# Directly set fsm property (it's defined in base_state.gd)
		state.set("fsm", self)
	
	if WanderStateScript:
		var state: Node = Node.new()
		state.set_script(WanderStateScript)
		state.name = "WanderState"
		add_child(state)
		states["wander"] = state
		state.initialize(npc)
		# Set FSM reference after initialization
		# Directly set fsm property (it's defined in base_state.gd)
		state.set("fsm", self)
	
	if SeekStateScript:
		var state: Node = Node.new()
		state.set_script(SeekStateScript)
		state.name = "SeekState"
		add_child(state)
		states["seek"] = state
		state.initialize(npc)
		# Set FSM reference after initialization
		# Directly set fsm property (it's defined in base_state.gd)
		state.set("fsm", self)
	
	if EatStateScript:
		var state: Node = Node.new()
		state.set_script(EatStateScript)
		# Check if script was attached by verifying it has the initialize method
		if state.has_method("initialize"):
			state.name = "EatState"
			add_child(state)
			states["eat"] = state
			state.initialize(npc)
			# Set FSM reference after initialization
			# Directly set fsm property (it's defined in base_state.gd)
			state.set("fsm", self)
			print("FSM: Successfully created eat state for %s" % npc_name)
		else:
			push_error("FSM: Failed to attach eat_state script or missing initialize method for %s" % npc_name)
			state.queue_free()
	
	if GatherStateScript:
		var state: Node = Node.new()
		state.set_script(GatherStateScript)
		# Check if script was attached by verifying it has the initialize method
		if state.has_method("initialize"):
			state.name = "GatherState"
			add_child(state)
			states["gather"] = state
			state.initialize(npc)
			# Set FSM reference after initialization
			# Directly set fsm property (it's defined in base_state.gd)
			state.set("fsm", self)
			print("FSM: Successfully created gather state for %s" % npc_name)
		else:
			push_error("FSM: Failed to attach gather_state script or missing initialize method for %s" % npc_name)
			state.queue_free()
	
	if HerdStateScript:
		var state: Node = Node.new()
		state.set_script(HerdStateScript)
		# Check if script was attached by verifying it has the initialize method
		if state.has_method("initialize"):
			state.name = "HerdState"
			add_child(state)
			states["herd"] = state
			state.initialize(npc)
			# Set FSM reference after initialization
			# Directly set fsm property (it's defined in base_state.gd)
			state.set("fsm", self)
			print("FSM: Successfully created herd state for %s" % npc_name)
		else:
			push_error("FSM: Failed to attach herd_state script or missing initialize method for %s" % npc_name)
			state.queue_free()
	
	if PartyStateScript:
		var party_st: Node = Node.new()
		party_st.set_script(PartyStateScript)
		if party_st.has_method("initialize"):
			party_st.name = "PartyState"
			add_child(party_st)
			states["party"] = party_st
			party_st.initialize(npc)
			party_st.set("fsm", self)
			print("FSM: Successfully created party state for %s" % npc_name)
		else:
			push_error("FSM: Failed to attach party_state for %s" % npc_name)
			party_st.queue_free()
	
	if HerdWildNPCStateScript:
		var state: Node = Node.new()
		state.set_script(HerdWildNPCStateScript)
		# Check if script was attached by verifying it has the initialize method
		if state.has_method("initialize"):
			state.name = "HerdWildNPCState"
			add_child(state)
			states["herd_wildnpc"] = state
			state.initialize(npc)
			# Set FSM reference after initialization
			# Directly set fsm property (it's defined in base_state.gd)
			state.set("fsm", self)
			print("FSM: Successfully created herd_wildnpc state for %s" % npc_name)
		else:
			push_error("FSM: Failed to attach herd_wildnpc_state script or missing initialize method for %s" % npc_name)
			state.queue_free()
	
	if AgroStateScript:
		var state: Node = Node.new()
		state.set_script(AgroStateScript)
		# Check if script was attached by verifying it has the initialize method
		if state.has_method("initialize"):
			state.name = "AgroState"
			add_child(state)
			states["agro"] = state
			state.initialize(npc)
			# Set FSM reference after initialization
			# Directly set fsm property (it's defined in base_state.gd)
			state.set("fsm", self)
			print("FSM: Successfully created agro state for %s" % npc_name)
		else:
			push_error("FSM: Failed to attach agro_state script or missing initialize method for %s" % npc_name)
			state.queue_free()
	
	if CombatStateScript:
		var state: Node = Node.new()
		state.set_script(CombatStateScript)
		# Check if script was attached by verifying it has the initialize method
		if state.has_method("initialize"):
			state.name = "CombatState"
			add_child(state)
			states["combat"] = state
			state.initialize(npc)
			# Set FSM reference after initialization
			# Directly set fsm property (it's defined in base_state.gd)
			state.set("fsm", self)
			print("FSM: Successfully created combat state for %s" % npc_name)
		else:
			push_error("FSM: Failed to attach combat_state script or missing initialize method for %s" % npc_name)
			state.queue_free()
	
	if FleeCombatStateScript:
		var state_flee: Node = Node.new()
		state_flee.set_script(FleeCombatStateScript)
		if state_flee.has_method("initialize"):
			state_flee.name = "FleeCombatState"
			add_child(state_flee)
			states["flee_combat"] = state_flee
			state_flee.initialize(npc)
			state_flee.set("fsm", self)
		else:
			push_error("FSM: Failed to attach flee_combat_state for %s" % npc_name)
			state_flee.queue_free()
	
	if DefendStateScript:
		var state: Node = Node.new()
		state.set_script(DefendStateScript)
		if state.has_method("initialize"):
			state.name = "DefendState"
			add_child(state)
			states["defend"] = state
			state.initialize(npc)
			state.set("fsm", self)
			print("FSM: Successfully created defend state for %s" % npc_name)
		else:
			push_error("FSM: Failed to attach defend_state script or missing initialize method for %s" % npc_name)
			state.queue_free()
	
	if RaidStateScript:
		var state: Node = Node.new()
		state.set_script(RaidStateScript)
		if state.has_method("initialize"):
			state.name = "RaidState"
			add_child(state)
			states["raid"] = state
			state.initialize(npc)
			state.set("fsm", self)
			print("FSM: Successfully created raid state for %s" % npc_name)
		else:
			push_error("FSM: Failed to attach raid_state script or missing initialize method for %s" % npc_name)
			state.queue_free()
	
	if SearchStateScript:
		var state: Node = Node.new()
		state.set_script(SearchStateScript)
		if state.has_method("initialize"):
			state.name = "SearchState"
			add_child(state)
			states["search"] = state
			state.initialize(npc)
			state.set("fsm", self)
			print("FSM: Successfully created search state for %s" % npc_name)
		else:
			push_error("FSM: Failed to attach search_state script or missing initialize method for %s" % npc_name)
			state.queue_free()
	
	if BuildStateScript:
		var state: Node = Node.new()
		state.set_script(BuildStateScript)
		# Check if script was attached by verifying it has the initialize method
		if state.has_method("initialize"):
			state.name = "BuildState"
			add_child(state)
			states["build"] = state
			state.initialize(npc)
			# Set FSM reference after initialization
			# Directly set fsm property (it's defined in base_state.gd)
			state.set("fsm", self)
			print("FSM: Successfully created build state for %s" % npc_name)
		else:
			push_error("FSM: Failed to attach build_state script or missing initialize method for %s" % npc_name)
			state.queue_free()
	
	if ReproductionStateScript:
		var state: Node = Node.new()
		state.set_script(ReproductionStateScript)
		# Check if script was attached by verifying it has the initialize method
		if state.has_method("initialize"):
			state.name = "ReproductionState"
			add_child(state)
			states["reproduction"] = state
			state.initialize(npc)
			# Set FSM reference after initialization
			# Directly set fsm property (it's defined in base_state.gd)
			state.set("fsm", self)
			print("FSM: Successfully created reproduction state for %s" % npc_name)
		else:
			push_error("FSM: Failed to attach reproduction_state script or missing initialize method for %s" % npc_name)
			state.queue_free()
	
	if OccupyBuildingStateScript:
		var state: Node = Node.new()
		state.set_script(OccupyBuildingStateScript)
		# Check if script was attached by verifying it has the initialize method
		if state.has_method("initialize"):
			state.name = "OccupyBuildingState"
			add_child(state)
			states["occupy_building"] = state
			state.initialize(npc)
			# Set FSM reference after initialization
			# Directly set fsm property (it's defined in base_state.gd)
			state.set("fsm", self)
			print("FSM: Successfully created occupy_building state for %s" % npc_name)
		else:
			push_error("FSM: Failed to attach occupy_building_state script or missing initialize method for %s" % npc_name)
			state.queue_free()
	
	if WorkAtBuildingStateScript:
		var state: Node = Node.new()
		state.set_script(WorkAtBuildingStateScript)
		# Check if script was attached by verifying it has the initialize method
		if state.has_method("initialize"):
			state.name = "WorkAtBuildingState"
			add_child(state)
			states["work_at_building"] = state
			state.initialize(npc)
			# Set FSM reference after initialization
			# Directly set fsm property (it's defined in base_state.gd)
			state.set("fsm", self)
			print("FSM: Successfully created work_at_building state for %s" % npc_name)
		else:
			push_error("FSM: Failed to attach work_at_building_state script or missing initialize method for %s" % npc_name)
			state.queue_free()
	
	if CraftStateScript:
		var state: Node = Node.new()
		state.set_script(CraftStateScript)
		if state.has_method("initialize"):
			state.name = "CraftState"
			add_child(state)
			states["craft"] = state
			state.initialize(npc)
			state.set("fsm", self)
			print("FSM: Successfully created craft state for %s" % npc_name)
		else:
			push_error("FSM: Failed to attach craft_state script or missing initialize method for %s" % npc_name)
			state.queue_free()
	
	if BuildHutForWomanStateScript:
		var state: Node = Node.new()
		state.set_script(BuildHutForWomanStateScript)
		if state.has_method("initialize"):
			state.name = "BuildHutForWomanState"
			add_child(state)
			states["build_hut_for_woman"] = state
			state.initialize(npc)
			state.set("fsm", self)
		else:
			state.queue_free()

func _register_state(state_name: String, script_path: String) -> void:
	states[state_name] = null  # Will be instantiated on demand
	state_scripts[state_name] = script_path
	
	# Default priorities (can be overridden)
	state_priorities[state_name] = 1.0

func update(delta: float) -> void:
	if not npc or not current_state:
		return
	
	# Check if NPC is dead - if so, don't process FSM
	var health_comp: HealthComponent = npc.get_node_or_null("HealthComponent")
	if health_comp and health_comp.is_dead:
		return
	
	# If state was just set but enter() hasn't been called yet, call it now
	if not _state_entered:
		current_state.enter()
		_state_entered = true
	
	# Update current state
	current_state.update(delta)
	
	# Evaluate state conditions periodically (adaptive: near player = 0.1s, far = 0.25s)
	var effective_interval: float = evaluation_interval
	var player_ref = npc.get_tree().get_first_node_in_group("player") if npc else null
	if player_ref and is_instance_valid(player_ref):
		var dist: float = npc.global_position.distance_to(player_ref.global_position)
		if dist > NEAR_PLAYER_DISTANCE:
			effective_interval = FAR_EVALUATION_INTERVAL
	evaluation_timer += delta
	if evaluation_timer >= effective_interval:
		evaluation_timer = 0.0
		_evaluate_states()

func _evaluate_states() -> void:
	# Check all states and switch to highest priority valid state
	var best_state: String = current_state_name
	var best_priority: float = 0.0  # Set to current_priority after we compute it (so no false fallback)
	var nt_prop = npc.get("npc_type") if npc else null
	var npc_type_str: String = (nt_prop as String) if nt_prop != null else ""  # Declare once at function start
	
	# COMBAT LOCK: Don't switch states if NPC is locked in combat (windup/recovery)
	if npc and npc.get("combat_locked") == true:
		return  # Prevent state switching during combat
	
	# If currently in idle, check if idle duration has passed
	if current_state_name == "idle":
		var idle_state: Node = _get_state("idle")
		if idle_state:
			# Check if properties exist by trying to access them
			var timer = idle_state.get("idle_timer")
			var duration = idle_state.get("idle_duration")
			if timer != null and duration != null:
				if timer >= duration:
					# Idle duration complete, allow state change
					pass
				else:
					# Still in idle period, don't change states
					return
	
	# Don't switch states if we're actively gathering or eating (timer is running)
	# Exception: cavemen/clansmen - allow herd_wildnpc (11.5) to interrupt gather (wild NPCs valuable, instant follow)
	if current_state_name == "gather":
		var gather_state: Node = _get_state("gather")
		if gather_state:
			var gather_timer = gather_state.get("gather_timer")
			var gather_target = gather_state.get("gather_target")
			var block_gather_switch: bool = (gather_timer != null and gather_timer > 0.0 and gather_target != null)
			if block_gather_switch and (npc_type_str != "caveman" and npc_type_str != "clansman"):
				return  # Non-cavemen: don't interrupt gather
			elif block_gather_switch:
				# Cavemen: let evaluation run - herd_wildnpc (11.5) can interrupt if can_enter
				pass
			# else: timer 0 or no target, allow switch as before
	
	if current_state_name == "eat":
		var eat_state: Node = _get_state("eat")
		if eat_state:
			var eat_timer = eat_state.get("eat_timer")
			# For eat state, we can switch if timer is 0 (completed) or if we're eating from inventory (no target)
			# Only prevent if timer is running and we're moving to a food target
			var food_target = eat_state.get("food_target")
			if eat_timer != null and eat_timer > 0.0 and food_target != null:
				# Timer is running and we have a food target to reach, don't interrupt
				return
	
	# Herd leader must always move toward land claim - block combat/defend when herding
	var hc_val = npc.get("herded_count") if npc else null
	var hc: int = int(hc_val) if hc_val != null else 0
	var is_herd_leader: bool = (hc > 0)

	# Combat before defend: when intruders present (combat_target + agro), engage first
	# Otherwise defenders just patrol the border and never fight
	# Skip when herding: leader must not chase enemies, must move toward claim
	if not is_herd_leader and (npc_type_str == "caveman" or npc_type_str == "clansman"):
		var combat_state_node: Node = _get_state("combat")
		if combat_state_node and combat_state_node.has_method("can_enter") and combat_state_node.can_enter():
			change_state("combat")
			return

	# Defend directive: player slider or ClanBrain quota - bypasses work priority
	# When quota > 0, defenders go to border regardless of gather/craft/herd
	# Skip when herding: leader must move toward claim with herd
	if not is_herd_leader and (npc_type_str == "caveman" or npc_type_str == "clansman"):
		var defend_state_node: Node = _get_state("defend")
		if defend_state_node and defend_state_node.has_method("can_enter") and defend_state_node.can_enter():
			change_state("defend")
			return
	
	# Transport lock: when herder has followers, stay in herd_wildnpc until delivery or herded_count=0
	# Combat/defend already handled above. Block wander/gather from preempting transport.
	if current_state_name == "herd_wildnpc" and npc and hc > 0:
		return  # Transport locked - no evaluation, herder commits until delivery
	
	# Craft state: do not cancel for wander/gather/deposit etc — only defend or combat may interrupt
	var in_craft_and_busy: bool = (current_state_name == "craft" and npc and (
		npc.get("is_crafting") == true or (npc.task_runner and npc.task_runner.has_method("has_job") and npc.task_runner.has_job())
	))
	if in_craft_and_busy:
		# Will override best_state below so only defend/combat can take over
		pass

	# SIMPLIFIED: Skip random idle chance for cavemen and clansmen (they should always be productive)
	var should_skip_idle: bool = (npc_type_str == "caveman" or npc_type_str == "clansman")
	
	# Random chance to enter idle state (1% - was 5%, caused NPCs to get stuck) - skip for cavemen/clansmen
	if not should_skip_idle and randf() < 0.01 and current_state_name != "idle":
		var idle_state: Node = _get_state("idle")
		if idle_state and idle_state.has_method("can_enter") and idle_state.can_enter():
			# Check if any higher priority state wants to activate
			var has_higher_priority: bool = false
			for state_name in states.keys():
				if state_name == "idle":
					continue
				var state: Node = _get_state(state_name)
				if not state:
					continue
				if not state.has_method("can_enter"):
					continue
				if state.can_enter():
					var priority: float = state_priorities.get(state_name, 1.0) as float
					if state.has_method("get_priority"):
						priority = state.get_priority() as float
					if priority > 2.0:  # Only interrupt idle for high priority (eat, gather)
						has_higher_priority = true
						break
			
			if not has_higher_priority:
				# NPCs with idle priority 0 should wander, not idle (cavemen, wild women/sheep/goats)
				var idle_priority: float = 0.5
				if idle_state.has_method("get_priority"):
					idle_priority = idle_state.get_priority() as float
				var wander_state: Node = _get_state("wander")
				var wander_priority: float = state_priorities.get("wander", 1.0) as float
				if wander_state and wander_state.has_method("get_priority"):
					wander_priority = wander_state.get_priority() as float
				# If wander has higher priority than idle and can enter, prefer wander (keeps NPCs moving)
				if idle_priority <= 0.1 and wander_state and wander_state.has_method("can_enter") and wander_state.can_enter() and wander_priority > idle_priority:
					change_state("wander")
					return
				# Other NPCs (e.g. clan women with low idle priority) can take brief idle breaks
				change_state("idle")
				return
	
	var nn_prop = npc.get("npc_name") if npc else null
	var npc_name: String = str(nn_prop) if nn_prop != null else "unknown"

	# Invalidate priority cache when key NPC properties change
	var new_key: int = _compute_priority_cache_key()
	if new_key != _cache_key:
		_cache_key = new_key
		_cached_priority.clear()

	var current_state_node: Node = _get_state(current_state_name)
	# Priority caching: get current state priority, build sorted candidate list, evaluate in order with early exit
	var current_priority: float = _get_cached_priority(current_state_name, current_state_node)
	best_priority = current_priority  # So we don't fall back to wander when already in high-priority state
	
	# Build candidate state names (pass npc_type skips)
	var candidates: Array[String] = []
	for state_name in states.keys():
		if npc:
			if npc_type_str == "baby":
				if state_name != "wander" and state_name != "idle":
					continue
			if state_name == "herd":
				if npc_type_str != "woman" and npc_type_str != "sheep" and npc_type_str != "goat":
					continue
			if state_name == "party":
				if npc_type_str != "caveman" and npc_type_str != "clansman":
					continue
				var is_ordered_p: bool = npc.get("follow_is_ordered") if npc.get("follow_is_ordered") != null else false
				if not is_ordered_p:
					continue
			if state_name == "herd_wildnpc" and npc_type_str != "caveman" and npc_type_str != "clansman":
				continue
			if state_name == "defend":
				continue  # Handled by directive above, not work priority
			if state_name == "search" and npc_type_str != "caveman" and npc_type_str != "clansman":
				continue
			if state_name == "build" and npc_type_str != "caveman":
				continue
			if state_name == "craft" and npc_type_str != "caveman" and npc_type_str != "clansman":
				continue
		candidates.append(state_name)
	
	# Precompute priority per candidate and sort descending (priority caching)
	var priority_list: Array[Dictionary] = []
	for state_name in candidates:
		var st: Node = _get_state(state_name)
		if not st or not st.has_method("can_enter"):
			continue
		var pri: float = _get_cached_priority(state_name, st)
		priority_list.append({"name": state_name, "priority": pri, "state": st})
	priority_list.sort_custom(func(a, b): return (a["priority"] as float) > (b["priority"] as float))
	
	# Evaluate in priority order; first state that can_enter and has priority > current_priority wins (early exit)
	var evaluated_states: Array[Dictionary] = []
	var found_better_state: bool = false
	for entry in priority_list:
		var state_name: String = entry["name"]
		var priority: float = entry["priority"]
		var state: Node = entry["state"]
		if priority <= current_priority:
			continue
		var can_enter_result: bool = state.can_enter()
		evaluated_states.append({"name": state_name, "can_enter": can_enter_result, "priority": priority})
		UnifiedLogger.log_npc("Priority eval: %s - %s (priority=%.1f, can_enter=%s)" % [npc_name, state_name, priority, can_enter_result], {
			"npc": npc_name,
			"state": state_name,
			"priority": "%.1f" % priority,
			"can_enter": can_enter_result
		}, UnifiedLogger.Level.DEBUG)
		if can_enter_result:
			best_priority = priority
			best_state = state_name
			found_better_state = true
			break
	
	# Log evaluation summary (defensive: avoid null/invalid values in format strings)
	if evaluated_states.size() > 0:
		var summary: String = "Evaluated %d states: " % evaluated_states.size()
		for eval_data in evaluated_states:
			var pname: String = str(eval_data.get("name", "unknown"))
			var prio: float = float(eval_data.get("priority", 0.0))
			var cen: bool = bool(eval_data.get("can_enter", false))
			summary += "%s(priority=%.1f,can_enter=%s) " % [pname, prio, "true" if cen else "false"]
		summary += "-> Best: %s (priority=%.1f)" % [best_state, best_priority]
		UnifiedLogger.log_npc(summary, {
			"npc": npc_name,
			"best_state": best_state,
			"best_priority": "%.1f" % best_priority
		}, UnifiedLogger.Level.DEBUG)
		
		# LOG CLANSMEN STATE EVALUATION SUMMARY
		if npc_type_str == "clansman":
			var gather_eval = null
			var herd_eval = null
			for eval_data in evaluated_states:
				if eval_data["name"] == "gather":
					gather_eval = eval_data
				elif eval_data["name"] == "herd_wildnpc":
					herd_eval = eval_data
			
			var gather_info = "N/A"
			if gather_eval:
				gather_info = "priority=%.1f,can_enter=%s" % [gather_eval["priority"], "true" if gather_eval["can_enter"] else "false"]
			
			var herd_info = "N/A"
			if herd_eval:
				herd_info = "priority=%.1f,can_enter=%s" % [herd_eval["priority"], "true" if herd_eval["can_enter"] else "false"]
			
			UnifiedLogger.log_npc("🧑 CLANSMAN STATE EVAL: %s - gather: %s, herd_wildnpc: %s -> selected: %s (priority=%.1f)" % [
				npc_name, gather_info, herd_info, best_state, best_priority
			], {
				"npc": npc_name,
				"gather": gather_info,
				"herd_wildnpc": herd_info,
				"selected": best_state,
				"selected_priority": "%.1f" % best_priority
			}, UnifiedLogger.Level.INFO)
	
	# If no higher-priority state could enter, only fallback to wander when CURRENT state can_enter is false
	# (When in herd_wildnpc we don't re-evaluate it (priority <= current), so we must not force wander if current is still valid)
	if not found_better_state and best_state == current_state_name:
		if npc_type_str == "caveman":
			var current_st: Node = _get_state(current_state_name)
			var current_still_valid: bool = current_st and current_st.has_method("can_enter") and current_st.can_enter()
			if not current_still_valid:
				var wander_state: Node = _get_state("wander")
				if wander_state and wander_state.has_method("can_enter") and wander_state.can_enter():
					best_state = "wander"
					best_priority = 1.0
					UnifiedLogger.log_npc("State changed: %s → wander (fallback_to_wander: no_other_state_can_enter)" % current_state_name, {
						"npc": npc_name,
						"from": current_state_name,
						"to": "wander",
						"reason": "fallback_to_wander: no_other_state_can_enter"
					})
	
	# Craft lock: only combat may interrupt when actively crafting (defend handled by directive above)
	if in_craft_and_busy and best_state != "combat":
		best_state = current_state_name
	
	# Switch to best state if different
	if best_state != current_state_name:
		# LOOP PREVENTION: Check cooldown to prevent rapid state switching
		var current_time: float = Time.get_ticks_msec() / 1000.0
		var time_since_last_change: float = current_time - last_state_change_time
		
		if time_since_last_change < min_state_change_cooldown:
			# Too soon since last change - skip this evaluation to prevent loops
			return  # Don't change state yet, wait for cooldown
		
		# Log state change with detailed reason
		UnifiedLogger.log_npc("State changed: %s → %s (priority_eval: best_priority=%.1f)" % [current_state_name, best_state, best_priority], {
			"npc": npc_name,
			"from": current_state_name,
			"to": best_state,
			"reason": "priority_eval: best_priority=%.1f" % best_priority
		})
		# LOG CLANSMEN STATE TRANSITIONS
		if npc_type_str == "clansman":
			UnifiedLogger.log_npc("🧑 CLANSMAN STATE TRANSITION: %s changing from %s → %s (priority_eval: best_priority=%.1f)" % [
				npc_name, current_state_name, best_state, best_priority
			], {
				"npc": npc_name,
				"from": current_state_name,
				"to": best_state,
				"reason": "priority_eval: best_priority=%.1f" % best_priority,
				"npc_type": "clansman"
			}, UnifiedLogger.Level.INFO)
		change_state(best_state)

func change_state(new_state_name: String) -> void:
	# LOOP PREVENTION: Update last state change time
	last_state_change_time = Time.get_ticks_msec() / 1000.0
	
	# Track clan_name before state change to detect if it's lost during transition
	var clan_before: String = npc.clan_name if npc else ""
	var meta_clan_before: String = ""
	var meta_backup_before: String = ""
	var nn_track = npc.get("npc_name") if npc else null
	var npc_name_track: String = str(nn_track) if nn_track != null else "unknown"
	var old_state_track: String = current_state_name
	if npc:
		if npc.has_meta("clan_name"):
			meta_clan_before = npc.get_meta("clan_name", "")
		if npc.has_meta("land_claim_clan_name"):
			meta_backup_before = npc.get_meta("land_claim_clan_name", "")
		
		# CRITICAL FIX: If meta is empty but we're a caveman, try to recover from land claim
		if npc.get("npc_type") == "caveman" and (clan_before == "" and meta_clan_before == "" and meta_backup_before == ""):
			# Try to find land claim by owner_npc_name
			var land_claims = get_tree().get_nodes_in_group("land_claims")
			for claim in land_claims:
				if not is_instance_valid(claim):
					continue
				var owner_npc_name_meta = claim.get_meta("owner_npc_name", "") if claim.has_meta("owner_npc_name") else ""
				if owner_npc_name_meta == npc_name_track:
					var claim_clan = claim.get("clan_name") if claim else ""
					if claim_clan != "":
						# Recover from land claim
						npc.clan_name = claim_clan
						npc.set_meta("clan_name", claim_clan)
						npc.set_meta("land_claim_clan_name", claim_clan)
						clan_before = claim_clan
						meta_clan_before = claim_clan
						meta_backup_before = claim_clan
						print("🔵 FSM RECOVERY: %s recovered clan_name='%s' from land claim before state change" % [npc_name_track, claim_clan])
						break
		
		# Removed verbose FSM state change log - only log significant transitions
	if not states.has(new_state_name):
		push_error("FSM: State '%s' not registered" % new_state_name)
		return
	
	# Herd state: wild herdables only.
	if new_state_name == "herd" and npc:
		var nt2 = npc.get("npc_type") if npc else null
		var npc_type_str: String = (nt2 as String) if nt2 != null else ""
		if npc_type_str != "woman" and npc_type_str != "sheep" and npc_type_str != "goat":
			push_error("FSM: Only woman/sheep/goat enter herd state")
			return
	
	# Party: ordered follow with player, same-clan NPC leader, or agro-combat-test NPC leader
	if new_state_name == "party" and npc:
		var nt3 = npc.get("npc_type") if npc else null
		var npc_type_party: String = (nt3 as String) if nt3 != null else ""
		if npc_type_party != "caveman" and npc_type_party != "clansman":
			push_error("FSM: Only cavemen/clansmen enter party state")
			return
		var is_ordered: bool = npc.get("follow_is_ordered") if npc.get("follow_is_ordered") != null else false
		var h: Node = npc.get("herder") if npc else null
		var herder_valid: bool = h != null and is_instance_valid(h)
		var player_ordered: bool = is_ordered and herder_valid and h.is_in_group("player")
		var agro_test_npc_leader: bool = is_ordered and herder_valid and (DebugConfig and DebugConfig.get("enable_agro_combat_test"))
		var same_clan_ok: bool = false
		if is_ordered and herder_valid:
			same_clan_ok = PartyCommandUtils.same_clan_warband_herder(h, npc)
		if not (player_ordered or agro_test_npc_leader or same_clan_ok):
			push_error("FSM: Attempted invalid party state for %s" % (npc.npc_name if npc else "unknown"))
			if npc:
				npc.set("is_herded", false)
				npc.set("herder", null)
			return
	
	# Don't change if already in this state
	if current_state_name == new_state_name:
		return
	
	var old_state: String = current_state_name
	var nn_prop = npc.get("npc_name") if npc else null
	var npc_name: String = str(nn_prop) if nn_prop != null else "unknown"
	
	# LOGGING: State duration tracking
	if current_state:
		var entry_time: float = current_state.get_meta("entry_time", 0.0)
		var current_time: float = Time.get_ticks_msec() / 1000.0
		var duration: float = current_time - entry_time
		
		# Flag long states (potentially stuck) - per-state thresholds
		var warn_threshold: float = 15.0
		match current_state_name:
			"wander": warn_threshold = 30.0
			"idle": warn_threshold = 15.0
			"gather", "herd_wildnpc": warn_threshold = 25.0
			"herd", "party": warn_threshold = 20.0
		if duration > warn_threshold:
			UnifiedLogger.log_npc("STATE_DURATION: %s in %s for %.1fs (LONG - potentially stuck!)" % [
				npc_name, current_state_name, duration
			], {
				"npc": npc_name,
				"state": current_state_name,
				"duration_s": "%.1f" % duration,
				"warning": "potentially_stuck"
			}, UnifiedLogger.Level.WARNING)
		elif duration > 0.0:
			# Log all state exits for analysis
			UnifiedLogger.log_npc("STATE_EXIT: %s exited %s after %.1fs" % [
				npc_name, current_state_name, duration
			], {
				"npc": npc_name,
				"state": current_state_name,
				"duration_s": "%.1f" % duration
			}, UnifiedLogger.Level.INFO)
	
	# Log state exit
	if current_state:
		UnifiedLogger.log_npc("State exited: %s left %s" % [npc_name, current_state_name], {
			"npc": npc_name,
			"state": current_state_name
		})
	
	# Notify activity tracker of state change
	var activity_tracker = get_node_or_null("/root/NPCActivityTracker")
	if activity_tracker and activity_tracker.has_method("_on_state_changed"):
		var npc_id = str(npc.get_instance_id()) if npc else ""
		activity_tracker._on_state_changed(npc_id, current_state_name, new_state_name, "")
	
	# Exit current state (set next_state meta so defend can preserve defend_target when going to combat)
	if npc:
		npc.set_meta("fsm_next_state", new_state_name)
	if current_state:
		current_state.exit()
	if npc and npc.has_meta("fsm_next_state"):
		npc.remove_meta("fsm_next_state")
	
	# Enter new state
	current_state = _get_state(new_state_name)
	current_state_name = new_state_name
	_state_entered = false  # Reset flag so enter() will be called on next update

	# Playtest: structured FSM transition for all AI NPCs (not player)
	var pi_tr = get_node_or_null("/root/PlaytestInstrumentor")
	if pi_tr and pi_tr.is_enabled() and npc and not npc.is_in_group("player") and pi_tr.has_method("npc_fsm_transition"):
		var nt_tr: String = str(npc.get("npc_type")) if npc.get("npc_type") != null else ""
		var clan_tr: String = npc.clan_name if npc else ""
		var hc_tr: int = int(npc.get("herded_count")) if npc.get("herded_count") != null else 0
		var fo_tr: bool = npc.get("follow_is_ordered") == true
		var hdn: String = ""
		var htr = npc.get("herder") if npc else null
		if htr != null and is_instance_valid(htr):
			var nnh = htr.get("npc_name")
			hdn = str(nnh) if nnh != null else str(htr.name)
		pi_tr.npc_fsm_transition(npc_name, nt_tr, clan_tr, old_state, new_state_name, hc_tr, fo_tr, hdn)

	# LOGGING: Track state entry time for duration calculation
	if current_state:
		current_state.set_meta("entry_time", Time.get_ticks_msec() / 1000.0)
		UnifiedLogger.log_npc("STATE_ENTRY: %s entered %s (from %s)" % [npc_name, new_state_name, old_state], {
			"npc": npc_name,
			"state": new_state_name,
			"from_state": old_state
		}, UnifiedLogger.Level.INFO)
	
	# Check clan_name after state transition - also check meta properties
	var clan_after: String = npc.clan_name if npc else ""
	var meta_clan_after: String = ""
	var meta_backup_after: String = ""
	if npc:
		if npc.has_meta("clan_name"):
			meta_clan_after = npc.get_meta("clan_name", "")
		if npc.has_meta("land_claim_clan_name"):
			meta_backup_after = npc.get_meta("land_claim_clan_name", "")
	
	if clan_before != "" and clan_after == "":
		print("🚨 CLAN_NAME LOST IN STATE TRANSITION: %s lost clan_name '%s' during %s -> %s (meta='%s', backup='%s')" % [npc_name, clan_before, old_state, new_state_name, meta_clan_after, meta_backup_after])
	
	# DEBUG: Log state transitions for gather state specifically
	if new_state_name == "gather":
		var nt3 = npc.get("npc_type") if npc else null
		var npc_type: String = (nt3 as String) if nt3 != null else ""
		if npc_type == "caveman":
			print("🔵 FSM TRANSITION TO GATHER: %s (from %s, clan_name='%s')" % [npc_name_track, old_state_track, clan_after])
	
	# Log state entry
	if current_state:
		UnifiedLogger.log_npc("State entered: %s entered %s" % [npc_name, new_state_name], {
			"npc": npc_name,
			"state": new_state_name
		})
	
	# TRACK: Check meta right before enter() call
	var meta_before_enter = ""
	var backup_before_enter = ""
	var direct_before_enter = ""
	if npc:
		if npc.has_meta("clan_name"):
			meta_before_enter = npc.get_meta("clan_name", "")
		if npc.has_meta("land_claim_clan_name"):
			backup_before_enter = npc.get_meta("land_claim_clan_name", "")
		direct_before_enter = npc.clan_name if npc else ""
		# Debug print disabled to reduce console spam
		# if npc_name_track != "unknown":
		# 	print("🔵 FSM PRE-ENTER: %s - Before enter(): direct='%s', meta='%s', backup='%s' (state: %s)" % [npc_name_track, direct_before_enter, meta_before_enter, backup_before_enter, new_state_name])
	
	if current_state:
		# Call enter() immediately for state changes (not during initialization)
		current_state.enter()
		_state_entered = true
		
		# TRACK: Check meta immediately after enter() call
		var meta_after_enter = ""
		var backup_after_enter = ""
		var direct_after_enter = ""
		if npc:
			if npc.has_meta("clan_name"):
				meta_after_enter = npc.get_meta("clan_name", "")
			if npc.has_meta("land_claim_clan_name"):
				backup_after_enter = npc.get_meta("land_claim_clan_name", "")
			direct_after_enter = npc.clan_name if npc else ""
			if npc_name_track != "unknown" and (meta_before_enter != meta_after_enter or backup_before_enter != backup_after_enter or direct_before_enter != direct_after_enter):
				print("🔵 FSM POST-ENTER: %s - After enter(): direct='%s', meta='%s', backup='%s' (state: %s) - CHANGED!" % [npc_name_track, direct_after_enter, meta_after_enter, backup_after_enter, new_state_name])
		
		# Check clan_name after enter() call - also check meta properties
		var clan_after_enter: String = npc.clan_name if npc else ""
		var meta_clan_enter: String = ""
		var meta_backup_enter: String = ""
		if npc:
			if npc.has_meta("clan_name"):
				meta_clan_enter = npc.get_meta("clan_name", "")
			if npc.has_meta("land_claim_clan_name"):
				meta_backup_enter = npc.get_meta("land_claim_clan_name", "")
		
		if clan_before != "" and clan_after_enter == "":
			print("🚨 CLAN_NAME LOST IN STATE.enter(): %s lost clan_name '%s' in %s.enter() (meta='%s', backup='%s')" % [npc_name, clan_before, new_state_name, meta_clan_enter, meta_backup_enter])
			# Try to recover from meta using helper function
			if npc.has_method("set_clan_name"):
				if meta_clan_enter != "":
					npc.set_clan_name(meta_clan_enter, "fsm_state_enter_recovery")
					print("🔵 FSM: Recovered %s.clan_name from meta: '%s'" % [npc_name, meta_clan_enter])
				elif meta_backup_enter != "":
					npc.set_clan_name(meta_backup_enter, "fsm_state_enter_recovery")
					print("🔵 FSM: Recovered %s.clan_name from backup meta: '%s'" % [npc_name, meta_backup_enter])
			else:
				# Fallback if helper doesn't exist
				if meta_clan_enter != "":
					npc.clan_name = meta_clan_enter
					print("🔵 FSM: Recovered %s.clan_name from meta (direct): '%s'" % [npc_name, meta_clan_enter])
				elif meta_backup_enter != "":
					npc.clan_name = meta_backup_enter
					npc.set_meta("clan_name", meta_backup_enter)
					print("🔵 FSM: Recovered %s.clan_name from backup meta (direct): '%s'" % [npc_name, meta_backup_enter])

func _get_state(state_name: String) -> Node:
	if not states.has(state_name):
		return null
	
	# States are created in _create_state_instances()
	return states.get(state_name, null)

func _compute_priority_cache_key() -> int:
	"""Hash of NPC properties that affect state priorities; when these change, cache invalidates."""
	if not npc:
		return 0
	var ct = npc.get("combat_target")
	var dt = npc.get("defend_target")
	var hc = npc.get("herded_count")
	var fo = npc.get("follow_is_ordered")
	var h: int = 0
	if ct != null and ct != false and is_instance_valid(ct):
		h = h * 31 + ct.get_instance_id()
	if dt != null and dt != false and is_instance_valid(dt):
		h = h * 31 + dt.get_instance_id()
	h = h * 31 + int(hc) if hc != null else h
	h = h * 31 + (1 if fo == true else 0)
	return h

func _get_cached_priority(state_name: String, state_node: Node) -> float:
	"""Return cached get_priority() or compute and cache."""
	if _cached_priority.has(state_name):
		return _cached_priority[state_name] as float
	var pri: float = state_priorities.get(state_name, 1.0) as float
	if state_node and state_node.has_method("get_priority"):
		pri = state_node.get_priority() as float
	_cached_priority[state_name] = pri
	return pri

func get_current_state_name() -> String:
	return current_state_name

func get_state_data() -> Dictionary:
	# Returns debug data from current state
	var data: Dictionary = {}
	if current_state and current_state.has_method("get_data"):
		data = current_state.get_data()
	# Add FSM-specific debug info
	data["current_state_name"] = current_state_name
	data["evaluation_timer"] = evaluation_timer
	data["evaluation_interval"] = evaluation_interval
	return data

func force_evaluation() -> void:
	# Force immediate state evaluation (used when buildings become active, etc.)
	evaluation_timer = 0.0
	_evaluate_states()
	print("🔵 FSM: Forced evaluation for %s" % (npc.get("npc_name") if npc else "unknown"))
