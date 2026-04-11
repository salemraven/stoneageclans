extends "res://scripts/npc/states/base_state.gd"

# SIMPLIFIED GATHER STATE - Clean flow: Gather → Check → Exit if needed → Repeat
# Flow: Find target → Move to target → Gather → Check inventory → Exit if 80%+ full → Repeat
# Deposit handled by wander state (movement) + auto-deposit (actual deposit)

# Phase 6: Job-only - no legacy fallback. Land claim assigns jobs via generate_gather_job.

var gather_target: Node2D = null  # Kept for get_data(); always null in job-only
var _last_target_search_time: float = -999.0  # Throttle: avoid per-frame scans
var _no_job_retry_time: float = -999.0  # Block can_enter for 3s after job+target both fail (prevents spam)
const SEARCH_THROTTLE: float = 0.5  # Min seconds between job pull attempts
const NO_JOB_RETRY_SEC: float = 3.0

# State completion: done when inventory at threshold (need to deposit)
func is_complete() -> bool:
	return _get_used_slots() >= _get_inventory_threshold()

# When to go deposit: config % of capacity (default 40%)
func _get_inventory_threshold() -> int:
	if not npc or not npc.inventory:
		return 3  # Default fallback
	var max_slots: int = npc.inventory.slot_count
	var pct: float = NPCConfig.gather_deposit_threshold if NPCConfig else 0.4
	return max(3, int(ceil(max_slots * pct)))

func enter() -> void:
	gather_target = null
	_last_target_search_time = Time.get_ticks_msec() / 1000.0  # Allow immediate job pull
	if _try_pull_gather_job():
		return
	_no_job_retry_time = Time.get_ticks_msec() / 1000.0 + NO_JOB_RETRY_SEC
	if fsm and fsm.has_method("force_evaluation"):
		fsm.force_evaluation()

func exit() -> void:
	_cancel_tasks_if_active()
	if npc:
		npc.set("is_gathering", false)
		if npc.progress_display:
			npc.progress_display.stop_collection(true)
	gather_target = null

func update(_delta: float) -> void:
	if not npc:
		return
	
	# Dead NPCs can't gather
	if npc.is_dead():
		return
	
	# CRITICAL: Exit immediately if defending or in combat - these take priority
	if _is_defending():
		# Defending - exit gather state
		if fsm:
			fsm.change_state("defend")
		return
	
	if _is_in_combat():
		# In combat - exit gather state
		if fsm:
			fsm.change_state("combat")
		return
	
	if _is_following():
		if fsm:
			var nt_gf: String = str(npc.get("npc_type")) if npc.get("npc_type") != null else ""
			if nt_gf == "caveman" or nt_gf == "clansman":
				fsm.change_state("party")
			else:
				fsm.change_state("herd")
		return
	
	# Job-only: require job; TaskRunner handles execution
	if not npc.task_runner or not npc.task_runner.has_method("has_job"):
		if fsm and fsm.has_method("force_evaluation"):
			fsm.force_evaluation()
		return
	if not npc.task_runner.has_job():
		var now: float = Time.get_ticks_msec() / 1000.0
		if now - _last_target_search_time < SEARCH_THROTTLE:
			return
		_last_target_search_time = now
		if _try_pull_gather_job():
			return
		_no_job_retry_time = now + NO_JOB_RETRY_SEC
		if fsm and fsm.has_method("force_evaluation"):
			fsm.force_evaluation()

func can_enter() -> bool:
	# Dead NPCs can't gather
	if npc and npc.is_dead():
		return false
	# Wild NPCs don't gather - they only wander and can be herded
	if not npc:
		return false
	
	# CRITICAL: When clan has 0 women, caveman MUST get one - no gathering allowed
	var claim = npc.get_my_land_claim() if npc.has_method("get_my_land_claim") else null
	if claim:
		var bf: int = claim.get_meta("breeding_females", -1)
		if bf == 0:
			return false
	
	# CRITICAL: Cannot gather while defending - defend takes priority
	if _is_defending():
		return false  # Defending - cannot gather
	
	# CRITICAL: Cannot gather while in combat - combat takes priority
	if _is_in_combat():
		return false  # In combat - cannot gather
	
	# CRITICAL: Cannot gather while following - following takes priority
	if _is_following():
		return false  # Following - cannot gather
	# Agro combat test leaders are driven by main — must not stop to gather
	if npc.has_meta("agro_combat_test_leader"):
		return false
	var npc_name = npc.get("npc_name") if npc else "unknown"
	var npc_type = npc.get("npc_type") if npc else ""
	var is_clansman = (npc_type == "clansman")
	
	# LOG CLANSMEN GATHER EVALUATION START (DEBUG level to reduce spam)
	if is_clansman:
		UnifiedLogger.log_npc("🧑 CLANSMAN GATHER EVAL START: %s checking can_enter()" % npc_name, {
			"npc": npc_name, "state": "gather", "eval_type": "can_enter_start"
		}, UnifiedLogger.Level.DEBUG)
	
	# Disable gather for wild NPCs (they should only wander)
	if npc.is_wild():
		if is_clansman:
			UnifiedLogger.log_npc("🧑 CLANSMAN GATHER: %s cannot enter gather (is_wild)" % npc_name, {
				"npc": npc_name, "state": "gather", "can_enter": false, "reason": "is_wild", "npc_type": npc_type
			}, UnifiedLogger.Level.DEBUG)
		return false
	
	# Block gather for cavemen/clansmen without land claim (no job source - jobs come from claim's ResourceIndex)
	if npc_type == "caveman" or npc_type == "clansman":
		var clan: String = npc.get_clan_name() if npc else ""
		if clan == "":
			if is_clansman:
				UnifiedLogger.log_npc("🧑 CLANSMAN GATHER: %s cannot enter gather (no clan/claim)" % npc_name, {
					"npc": npc_name, "state": "gather", "can_enter": false, "reason": "no_clan"
				}, UnifiedLogger.Level.DEBUG)
			return false
	
	# Babies can only wander, not gather
	if npc_type == "baby":
		return false
	
	# Phase 5c: Block re-entry for 3s after job+target both failed (prevents spam)
	var now: float = Time.get_ticks_msec() / 1000.0
	if now < _no_job_retry_time:
		return false
	
	# CRITICAL FIX: Check inventory BEFORE entering - prevent immediate exit
	# If inventory is already at threshold (80% of max slots), don't enter gather state
	# This prevents the "immediate exit" bug where gather state enters then exits on first update()
	var used_slots: int = _get_used_slots()
	var max_slots: int = npc.inventory.slot_count if npc.inventory else 10
	var threshold: int = _get_inventory_threshold()
	if used_slots >= threshold:
		if is_clansman:
			UnifiedLogger.log_npc("🧑 CLANSMAN GATHER: %s cannot enter gather (inventory_full: %d/%d >= %d)" % [
				npc_name, used_slots, max_slots, threshold
			], {
				"npc": npc_name, "state": "gather", "can_enter": false, "reason": "inventory_full",
				"used_slots": used_slots, "max_slots": max_slots, "threshold": threshold
			}, UnifiedLogger.Level.DEBUG)
		return false  # Inventory full - can't gather, need to deposit first
	
	# Enable gather for cavemen and clansmen (clan NPCs)
	# Cavemen/clansmen can gather when there are no wild NPCs nearby to herd
	# Herd_wildnpc has higher priority (10.6) than gather (3.0), so herding takes precedence
	if is_clansman:
		var clan_name = npc.get_clan_name() if npc else ""
		UnifiedLogger.log_npc("🧑 CLANSMAN GATHER: %s CAN enter gather (inventory: %d/%d, threshold: %d, clan: %s)" % [
			npc_name, used_slots, max_slots, threshold, clan_name
		], {
			"npc": npc_name, "state": "gather", "can_enter": true, "used_slots": used_slots, "max_slots": max_slots, "clan": clan_name
		}, UnifiedLogger.Level.DEBUG)
	return true

func get_priority() -> float:
	if not npc:
		return 1.0
	
	# Only for cavemen and clansmen
	var npc_type = npc.get("npc_type")
	var is_clansman = (npc_type == "clansman")
	if npc_type != "caveman" and npc_type != "clansman":
		return 1.0
	
	var clan_name: String = npc.get_clan_name() if npc else ""
	if clan_name == "":
		var npc_name = npc.get("npc_name") if npc else "unknown"
		if is_clansman:
			UnifiedLogger.log_npc("🧑 CLANSMAN GATHER PRIORITY: %s priority=1.0 (no_clan)" % npc_name, {
				"npc": npc_name, "state": "gather", "priority": "1.0", "reason": "no_clan"
			}, UnifiedLogger.Level.DEBUG)
		return 1.0  # No land claim, low priority
	
	# SIMPLIFIED: Lower priority if inventory full (need to deposit)
	var used_slots: int = _get_used_slots()
	var threshold: int = _get_inventory_threshold()
	if used_slots >= threshold:
		return 5.0
	
	# Config-driven; productivity mode boosts so gather beats herd-search
	var priority: float = 4.0
	if NPCConfig:
		var config_priority = NPCConfig.get("priority_gather_other")
		if config_priority != null:
			priority = config_priority as float
		if "caveman_productivity_test" in NPCConfig and (NPCConfig.caveman_productivity_test as float) >= 1.0:
			priority = 5.8  # Below herd-search (6.0) so cavemen commit to herding when target in range; still beats wander (0.01)
	return priority

# Helper functions

# Get used inventory slots (used in multiple places)
func _get_used_slots() -> int:
	if not npc or not npc.inventory:
		return 0
	if npc.inventory.has_method("get_used_slots"):
		return npc.inventory.get_used_slots()
	# Fallback: count manually
	var count: int = 0
	for i in range(npc.inventory.slot_count):
		var slot = npc.inventory.slots[i]
		if slot != null and slot is Dictionary:
			var slot_count: int = slot.get("count", 0) as int
			if slot_count > 0:
				count += 1
	return count

# Try to pull gather job from land claim
func _try_pull_gather_job() -> bool:
	"""Try to pull a gather job from land claim. Returns true if job was pulled."""
	if not npc:
		return false
	
	# Check if NPC has TaskRunner
	if not npc.task_runner:
		return false
	
	# Check if TaskRunner is idle (no current job)
	if npc.task_runner.has_method("has_job") and npc.task_runner.has_job():
		return false  # Already has a job
	
	var land_claim: Node = npc.get_my_land_claim()
	if not land_claim:
		return false  # No land claim found
	
	# Try to generate gather job
	if not land_claim.has_method("generate_gather_job"):
		return false
	
	var job: Job = land_claim.generate_gather_job(npc)
	if not job:
		return false  # No job available
	
	# Assign job to TaskRunner
	if npc.task_runner.has_method("assign_job"):
		npc.task_runner.assign_job(job)
		UnifiedLogger.log_npc("GATHER_JOB: %s pulled gather job from land claim" % npc.npc_name, {
			"npc": npc.npc_name,
			"task": "gather_job_pulled",
			"clan": npc.get_clan_name()
		})
		return true
	
	return false

func get_data() -> Dictionary:
	var data: Dictionary = {"has_target": false}
	if npc and npc.task_runner and npc.task_runner.has_job() and npc.task_runner.current_job and "resource_node" in npc.task_runner.current_job:
		var res = npc.task_runner.current_job.resource_node
		if res and is_instance_valid(res):
			data["has_target"] = true
			var resource_type = res.get("resource_type")
			if resource_type != null:
				data["target"] = ResourceData.get_resource_name(resource_type)
			if npc:
				data["distance"] = npc.global_position.distance_to(res.global_position)
	return data
