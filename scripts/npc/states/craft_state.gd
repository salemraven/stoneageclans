extends "res://scripts/npc/states/base_state.gd"

const _StateEconomyRules = preload("res://scripts/npc/state_economy_rules.gd")

# Craft state - clansmen knap stones into blades via Task system
# CraftJob: MoveTo(claim) → PickUp(2 stone) → Knap → DropOff(blade) → DropOff(stone)
# Land claim generates jobs when blades < 4 and claim has 2+ stones in storage
# Unlocked only when clan has 2+ clansmen and claim has a safe food stock (gather first).

const BLADE_RESERVE_TARGET: int = 4
const MIN_CLANSMEN_FOR_CRAFT: int = 2  # Same as ClanBrain - crafting only when 2+ cavemen/clansmen
const MIN_FOOD_IN_CLAIM_FOR_CRAFT: int = 5  # Berries (or food) in claim before crafting allowed - gather first

var land_claim: Node2D = null

func enter() -> void:
	land_claim = _get_land_claim()
	if npc and npc.progress_display:
		npc.progress_display.stop_collection()
	# Try to pull craft job (Task system)
	if _try_pull_craft_job():
		return  # Job pulled, TaskRunner will handle it
	# No job available - will exit on first update

func exit() -> void:
	_cancel_tasks_if_active()
	if npc:
		npc.set("is_crafting", false)
	if npc and npc.progress_display:
		npc.progress_display.stop_collection(true)
	land_claim = null

func update(_delta: float) -> void:
	if not npc:
		return

	if npc.is_dead():
		return

	if _is_defending():
		if fsm:
			fsm.change_state("defend")
		return

	if _is_in_combat():
		if fsm:
			fsm.change_state("combat")
		return

	if _is_following():
		if fsm:
			var nt_cf: String = str(npc.get("npc_type")) if npc.get("npc_type") != null else ""
			if nt_cf == "caveman" or nt_cf == "clansman":
				fsm.change_state("party")
			else:
				fsm.change_state("herd")
		return

	# Task system: if TaskRunner has a job, delegate to it
	if npc.task_runner and npc.task_runner.has_method("has_job"):
		if npc.task_runner.has_job():
			return  # TaskRunner ticks automatically
		# Job done or none - try to pull another
		if _try_pull_craft_job():
			return

	# No job available - force re-eval so we can enter gather/herd_wildnpc (not just wander)
	if fsm and fsm.has_method("force_evaluation"):
		fsm.force_evaluation()
	else:
		if fsm:
			fsm.change_state("wander")

func _try_pull_craft_job() -> bool:
	"""Try to pull a craft job from land claim. Returns true if job was assigned."""
	if not npc or not npc.task_runner:
		return false
	if npc.task_runner.has_method("has_job") and npc.task_runner.has_job():
		return false  # Already has a job

	var claim: Node2D = _get_land_claim()
	if not claim or not is_instance_valid(claim):
		return false
	if not claim.has_method("generate_craft_job"):
		return false

	var job: Job = claim.generate_craft_job(npc)
	if not job:
		return false

	# Pre-check: if first task is PickUpTask and NPC has no space, skip
	var first_task = job.get_current_task() if job.has_method("get_current_task") else null
	if first_task and first_task.get_script():
		var script_path: String = first_task.get_script().get_path().get_file()
		if script_path == "pick_up_task.gd" and npc.inventory and not npc.inventory.has_space():
			return false

	if npc.task_runner.has_method("assign_job"):
		npc.task_runner.assign_job(job)
		UnifiedLogger.log_npc("CRAFT_JOB: %s pulled craft job from land claim" % npc.npc_name, {
			"npc": npc.npc_name,
			"task": "craft_job_pulled",
			"clan": npc.get_clan_name() if npc else ""
		}, UnifiedLogger.Level.DEBUG)
		return true
	return false

func can_enter() -> bool:
	if not npc or npc.is_dead():
		return false
	if _is_defending() or _is_in_combat() or _is_following():
		return false

	var npc_type: String = npc.get("npc_type") if npc else ""
	if npc_type != "clansman" and npc_type != "caveman":
		return false

	var claim: Node2D = _get_land_claim()
	if not claim or not is_instance_valid(claim):
		return false

	# Crafting unlocked only when clan has 2+ clansmen (cavemen focus on gather/herd until then)
	if _StateEconomyRules.count_fighters_in_clan(npc) < MIN_CLANSMEN_FOR_CRAFT:
		return false

	var claim_inv = claim.get("inventory")
	if not claim_inv or not claim_inv.has_method("get_count"):
		return false

	# Require a safe stock of food in claim before crafting - gather first
	var food_count: int = claim_inv.get_count(ResourceData.ResourceType.BERRIES) + claim_inv.get_count(ResourceData.ResourceType.GRAIN)
	if food_count < MIN_FOOD_IN_CLAIM_FOR_CRAFT:
		return false

	# Claim needs blades (< 4) and has 2+ stones in storage (job will PickUp from claim)
	if claim_inv.get_count(ResourceData.ResourceType.BLADE) >= BLADE_RESERVE_TARGET:
		return false
	if claim_inv.get_count(ResourceData.ResourceType.STONE) < 2:
		return false

	return true

func get_priority() -> float:
	var pb: float = 2.0
	var pfood: float = 2.0
	var pbelow: float = 4.0
	var phigh: float = 12.0
	var pfallback: float = 2.5
	if NPCConfig:
		pb = NPCConfig.priority_craft_blocked
		pfood = NPCConfig.priority_craft_blocked
		pbelow = NPCConfig.priority_craft_below_gather
		phigh = NPCConfig.priority_craft_high
		pfallback = NPCConfig.priority_craft_fallback
	if _StateEconomyRules.count_fighters_in_clan(npc) < MIN_CLANSMEN_FOR_CRAFT:
		return pb
	var claim: Node2D = _get_land_claim()
	if not claim:
		return pfood
	var claim_inv = claim.get("inventory")
	if not claim_inv or not claim_inv.has_method("get_count"):
		return pfood
	var food_count: int = claim_inv.get_count(ResourceData.ResourceType.BERRIES) + claim_inv.get_count(ResourceData.ResourceType.GRAIN)
	if food_count < MIN_FOOD_IN_CLAIM_FOR_CRAFT:
		return pfood
	if claim_inv.get_count(ResourceData.ResourceType.BLADE) < BLADE_RESERVE_TARGET and claim_inv.get_count(ResourceData.ResourceType.STONE) >= 2:
		if _StateEconomyRules.should_deprioritize_craft_vs_gather(npc):
			return pbelow
		return phigh
	return pfallback

func get_data() -> Dictionary:
	return {
		"land_claim": land_claim.get("clan_name") if land_claim else "",
	}

func _get_land_claim() -> Node2D:
	if not npc:
		return null
	var clan: String = npc.get_clan_name() if npc else ""
	if clan == "":
		return null
	var claims := get_tree().get_nodes_in_group("land_claims")
	for c in claims:
		if not is_instance_valid(c):
			continue
		var cclan: String = c.get("clan_name") as String if c.get("clan_name") != null else ""
		if cclan == clan:
			return c
	return null
