extends Task
class_name GatherTask

const MoveToTaskScript = preload("res://scripts/ai/tasks/move_to_task.gd")

# Gather Task System - Phase 1
# Caveman collects from the same node until inventory FULL (config) or node depleted (cooldown).
# Handles: Move to resource → [Wait → Harvest → repeat while inventory < fill_pct and node harvestable]

# Resource node to gather from
var resource_node: Node2D

# Expected resource type (for finding alternative when current node becomes invalid)
var _expected_resource_type: ResourceData.ResourceType = ResourceData.ResourceType.WOOD

# Gather duration (seconds) - how long to wait before each harvest
var gather_duration: float = 1.0

# Arrival distance for gathering (pixels) - slightly larger to lock on earlier and reduce "too far" frames
var gather_distance: float = 56.0

# Stop gathering when inventory reaches this fraction of capacity (use config; 1.0 = fill completely before leaving)

# Internal state
var _gather_timer: float = 0.0
var _has_started_gathering: bool = false
var _gather_start_position: Vector2 = Vector2.ZERO  # Moving beyond threshold cancels gather
var _move_cancel_threshold: float = 32.0  # From config; fallback 32px (was 20) to reduce bump cancellations
var _move_task: Task = null  # MoveToTask for moving to resource
const ALTERNATIVE_SEARCH_RANGE: float = 800.0  # Max distance to search for replacement resource

func _playtest_clan(npc: NPCBase) -> String:
	return npc.get_clan_name() if npc.has_method("get_clan_name") else ""

func _playtest_gather_completed(npc: NPCBase, resource_type: int, amount: int) -> void:
	var pi = npc.get_node_or_null("/root/PlaytestInstrumentor")
	if pi and pi.is_enabled() and pi.has_method("gather_completed"):
		var nt: String = str(npc.get("npc_type")) if npc.get("npc_type") != null else ""
		pi.gather_completed(npc.npc_name, _playtest_clan(npc), resource_type, amount, nt)

func _playtest_gather_failed(npc: NPCBase, reason: String, resource_type: int = -1) -> void:
	var pi = npc.get_node_or_null("/root/PlaytestInstrumentor")
	if pi and pi.is_enabled() and pi.has_method("gather_failed"):
		var nt: String = str(npc.get("npc_type")) if npc.get("npc_type") != null else ""
		pi.gather_failed(npc.npc_name, _playtest_clan(npc), reason, resource_type, nt)

func _init(resource: Node2D, duration: float = 1.0, dist: float = 56.0) -> void:
	resource_node = resource
	gather_duration = duration
	gather_distance = dist
	if resource and is_instance_valid(resource):
		var rt = resource.get("resource_type")
		if rt != null:
			_expected_resource_type = rt as ResourceData.ResourceType
		elif resource.get("item_type") != null:
			_expected_resource_type = resource.get("item_type") as ResourceData.ResourceType

func _start_impl(actor: Node) -> void:
	if not actor is NPCBase:
		UnifiedLogger.log_npc("GatherTask FAILED: actor not NPCBase", {"actor_type": actor.get_class() if actor else "null"}, UnifiedLogger.Level.DEBUG)
		status = TaskStatus.FAILED
		return

	var npc: NPCBase = actor as NPCBase
	if not npc.inventory:
		UnifiedLogger.log_npc("GatherTask FAILED: %s has no inventory" % npc.npc_name, {"npc": npc.npc_name}, UnifiedLogger.Level.DEBUG)
		_playtest_gather_failed(npc, "no_inventory", _expected_resource_type as int)
		status = TaskStatus.FAILED
		return

	# Check if resource node is valid; try alternative if invalid
	if not resource_node or not is_instance_valid(resource_node):
		var alt := _find_alternative_resource(npc)
		if alt:
			resource_node = alt
		else:
			UnifiedLogger.log_npc("GatherTask FAILED: %s resource invalid at start, no alternative" % npc.npc_name, {"npc": npc.npc_name}, UnifiedLogger.Level.DEBUG)
			_playtest_gather_failed(npc, "resource_invalid", _expected_resource_type as int)
			status = TaskStatus.FAILED
			return

	# Check if resource is harvestable; try alternative if not
	var is_harvestable_check: bool = false
	if resource_node.has_method("is_harvestable_ignore_lock"):
		is_harvestable_check = resource_node.is_harvestable_ignore_lock()
	elif resource_node.has_method("is_harvestable"):
		is_harvestable_check = resource_node.is_harvestable()

	if not is_harvestable_check:
		var alt := _find_alternative_resource(npc)
		if alt:
			resource_node = alt
			is_harvestable_check = alt.is_harvestable_ignore_lock() if alt.has_method("is_harvestable_ignore_lock") else alt.is_harvestable()
		if not is_harvestable_check:
			UnifiedLogger.log_npc("GatherTask FAILED: %s resource not harvestable at start, no alternative" % npc.npc_name, {"npc": npc.npc_name}, UnifiedLogger.Level.DEBUG)
			_playtest_gather_failed(npc, "not_harvestable", _expected_resource_type as int)
			status = TaskStatus.FAILED
			return

	# Check if NPC has inventory space
	if not npc.inventory.has_space():
		UnifiedLogger.log_npc("GatherTask FAILED: %s inventory full" % npc.npc_name, {"npc": npc.npc_name}, UnifiedLogger.Level.DEBUG)
		_playtest_gather_failed(npc, "inventory_full", _expected_resource_type as int)
		status = TaskStatus.FAILED
		return

	status = TaskStatus.RUNNING
	_gather_timer = 0.0
	_has_started_gathering = false
	_move_cancel_threshold = 32.0
	if NPCConfig and "gather_move_cancel_threshold" in NPCConfig:
		_move_cancel_threshold = NPCConfig.gather_move_cancel_threshold as float

func _tick_impl(actor: Node, delta: float) -> TaskStatus:
	if not actor is NPCBase:
		return TaskStatus.FAILED

	var npc: NPCBase = actor as NPCBase

	if npc.should_abort_work():
		UnifiedLogger.log_npc("GatherTask FAILED: %s should_abort_work" % npc.npc_name, {"npc": npc.npc_name}, UnifiedLogger.Level.WARNING)
		_playtest_gather_failed(npc, "abort_work", _expected_resource_type as int)
		return TaskStatus.FAILED

	if not npc.inventory:
		UnifiedLogger.log_npc("GatherTask FAILED: %s inventory null (tick)" % npc.npc_name, {"npc": npc.npc_name}, UnifiedLogger.Level.WARNING)
		_playtest_gather_failed(npc, "no_inventory", _expected_resource_type as int)
		return TaskStatus.FAILED

	if not resource_node or not is_instance_valid(resource_node):
		var alt := _find_alternative_resource(npc)
		if alt:
			_clear_gathering(npc, true)
			_switch_to_resource(alt, actor)
			UnifiedLogger.log_npc("GatherTask: %s switched to alternative resource (original invalid)" % npc.npc_name, {"npc": npc.npc_name}, UnifiedLogger.Level.DEBUG)
			return TaskStatus.RUNNING
		UnifiedLogger.log_npc("GatherTask FAILED: %s resource invalid, no alternative found" % npc.npc_name, {"npc": npc.npc_name}, UnifiedLogger.Level.WARNING)
		_playtest_gather_failed(npc, "resource_invalid", _expected_resource_type as int)
		return TaskStatus.FAILED

	# Step 1: Move to resource if not in range (only tick MoveToTask here; skip harvestable until in range)
	var npc_pos: Vector2 = npc.global_position
	var resource_pos: Vector2 = resource_node.global_position
	var distance_to_resource: float = npc_pos.distance_to(resource_pos)

	if distance_to_resource > gather_distance:
		# Approaching — walk, no berry/timer ring until in harvest range
		if _has_started_gathering:
			_has_started_gathering = false
			_gather_timer = 0.0
		_clear_gathering(npc, false)
		# Need to move closer - use MoveToTask; no harvestable check while moving
		if not _move_task:
			_move_task = MoveToTaskScript.new(resource_pos, gather_distance) as Task
			if _move_task:
				_move_task.start(actor)
			else:
				return TaskStatus.FAILED

		var move_status = _move_task.tick(actor, delta)
		if move_status == TaskStatus.RUNNING:
			return TaskStatus.RUNNING
		elif move_status == TaskStatus.FAILED:
			UnifiedLogger.log_npc("GatherTask FAILED: %s move_to_resource failed" % npc.npc_name, {"npc": npc.npc_name, "distance": distance_to_resource}, UnifiedLogger.Level.WARNING)
			_playtest_gather_failed(npc, "move_failed", _expected_resource_type as int)
			return TaskStatus.FAILED
		# SUCCESS: fall through and run harvestable check once before gathering

	# In range (or just arrived): check harvestable once before starting/continuing gather
	var is_harvestable_check: bool = false
	if resource_node.has_method("is_harvestable_ignore_lock"):
		is_harvestable_check = resource_node.is_harvestable_ignore_lock()
	elif resource_node.has_method("is_harvestable"):
		is_harvestable_check = resource_node.is_harvestable()

	if not is_harvestable_check:
		var alt := _find_alternative_resource(npc)
		if alt:
			_clear_gathering(npc, true)
			_switch_to_resource(alt, actor)
			var res_type: int = resource_node.get("resource_type") as int if resource_node.get("resource_type") != null else -1
			var pi = npc.get_node_or_null("/root/PlaytestInstrumentor")
			if pi and pi.has_method("gather_empty_switch"):
				pi.gather_empty_switch(npc.npc_name, res_type, "not_harvestable", _playtest_clan(npc))
			UnifiedLogger.log_npc("GatherTask: %s switched to alternative resource (not harvestable)" % npc.npc_name, {"npc": npc.npc_name}, UnifiedLogger.Level.DEBUG)
			return TaskStatus.RUNNING
		UnifiedLogger.log_npc("GatherTask FAILED: %s resource not harvestable, no alternative" % npc.npc_name, {"npc": npc.npc_name}, UnifiedLogger.Level.WARNING)
		var res_type_fail: int = resource_node.get("resource_type") as int if resource_node.get("resource_type") != null else _expected_resource_type as int
		_playtest_gather_failed(npc, "not_harvestable", res_type_fail)
		return TaskStatus.FAILED

	# Step 2: Start gathering animation/display — must stay in place until done
	if not _has_started_gathering:
		_has_started_gathering = true
		_gather_start_position = npc.global_position
		npc.set("is_gathering", true)
		npc.velocity = Vector2.ZERO
		if npc.steering_agent:
			npc.steering_agent.target_position = npc.global_position
			npc.steering_agent.target_node = null
		if npc.progress_display:
			var res_type = resource_node.get("resource_type")
			var icon: Texture2D = null
			if res_type != null:
				var icon_path: String = ResourceData.get_resource_icon_path(res_type)
				if icon_path != "":
					icon = load(icon_path) as Texture2D
			_start_gather_progress(npc, icon)

	# If NPC moved after starting gather, cancel
	var moved: float = npc.global_position.distance_to(_gather_start_position)
	if moved > _move_cancel_threshold:
		_clear_gathering(npc, true)
		UnifiedLogger.log_npc("GatherTask FAILED: %s moved %.1fpx during gather" % [npc.npc_name, moved], {"npc": npc.npc_name, "moved": moved}, UnifiedLogger.Level.WARNING)
		var res_type_move: int = resource_node.get("resource_type") as int if resource_node and resource_node.get("resource_type") != null else _expected_resource_type as int
		_playtest_gather_failed(npc, "moved_during_gather", res_type_move)
		return TaskStatus.FAILED

	# Stay still every tick (clear steering so no drift; ready for future gather animation)
	npc.velocity = Vector2.ZERO
	if npc.steering_agent:
		npc.steering_agent.target_position = npc.global_position
		npc.steering_agent.target_node = null

	# Step 3: Wait for gather duration
	_gather_timer += delta
	if npc.progress_display:
		npc.progress_display.set_progress(_gather_timer / gather_duration)

	if _gather_timer < gather_duration:
		return TaskStatus.RUNNING

	# Step 4: Harvest resource
	_clear_gathering(npc, false)
	var resource_type = resource_node.get("resource_type")
	if resource_type == null:
		_playtest_gather_failed(npc, "resource_type_null", _expected_resource_type as int)
		return TaskStatus.FAILED

	var yield_amount: int = 0
	if resource_node.has_method("harvest"):
		yield_amount = resource_node.harvest()
	else:
		_playtest_gather_failed(npc, "harvest_failed", _expected_resource_type as int)
		return TaskStatus.FAILED

	if yield_amount == 0:
		# Node depleted (e.g. cooldown) - we're done with this node
		var res_type_val: int = resource_type as int if resource_type != null else -1
		var pi = npc.get_node_or_null("/root/PlaytestInstrumentor")
		if pi and pi.has_method("gather_empty_switch"):
			pi.gather_empty_switch(npc.npc_name, res_type_val, "yield_zero", _playtest_clan(npc))
		if resource_node.has_method("release"):
			resource_node.release(npc)
		return TaskStatus.SUCCESS

	# Convert wheat to grain (type conversion)
	if resource_type == ResourceData.ResourceType.WHEAT:
		resource_type = ResourceData.ResourceType.GRAIN

	# Add to inventory
	if not npc.inventory.add_item(resource_type, yield_amount):
		_playtest_gather_failed(npc, "inventory_full", resource_type as int)
		if resource_node.has_method("release"):
			resource_node.release(npc)
		return TaskStatus.SUCCESS  # Inventory full, stop gathering

	# Hidden nut find while chopping wood (matches player forage-on-tree)
	if resource_type == ResourceData.ResourceType.WOOD and randf() < 0.25:
		if npc.inventory.add_item(ResourceData.ResourceType.NUTS, 1):
			_playtest_gather_completed(npc, ResourceData.ResourceType.NUTS as int, 1)

	var resource_name: String = ResourceData.get_resource_name(resource_type)
	_playtest_gather_completed(npc, resource_type as int, yield_amount)
	UnifiedLogger.log_npc("GATHER_TASK: %s gathered %d %s" % [npc.npc_name, yield_amount, resource_name], {
		"npc": npc.npc_name,
		"task": "gather",
		"resource": resource_name,
		"amount": yield_amount
	})
	var activity_tracker = npc.get_tree().root.get_node_or_null("NPCActivityTracker") if npc.get_tree() else null
	if activity_tracker and activity_tracker.has_method("log_gather"):
		activity_tracker.log_gather(str(npc.get_instance_id()), resource_name, yield_amount)

	# Collect entire node until inventory full (config) or node depleted: loop by resetting timer and staying RUNNING
	var used_slots: int = npc.inventory.get_used_slots() if npc.inventory.has_method("get_used_slots") else 0
	var max_slots: int = npc.inventory.slot_count if npc.inventory else 5
	var fill_pct: float = NPCConfig.gather_same_node_until_pct if NPCConfig else 1.0
	var threshold_slots: int = int(ceil(max_slots * fill_pct))
	if used_slots >= threshold_slots:
		if resource_node.has_method("release"):
			resource_node.release(npc)
		return TaskStatus.SUCCESS

	# Node still harvestable? Stay and gather again
	var still_harvestable: bool = false
	if resource_node.has_method("is_harvestable_ignore_lock"):
		still_harvestable = resource_node.is_harvestable_ignore_lock()
	elif resource_node.has_method("is_harvestable"):
		still_harvestable = resource_node.is_harvestable()
	if not still_harvestable:
		if resource_node.has_method("release"):
			resource_node.release(npc)
		return TaskStatus.SUCCESS

	# Same node, keep gathering: reset timer and show collection again for next cycle
	_gather_timer = 0.0
	npc.set("is_gathering", true)
	if npc.progress_display:
		var icon: Texture2D = null
		var res_type = resource_node.get("resource_type")
		if res_type != null:
			var icon_path: String = ResourceData.get_resource_icon_path(res_type)
			if icon_path != "":
				icon = load(icon_path) as Texture2D
		_start_gather_progress(npc, icon)
	return TaskStatus.RUNNING

func _find_alternative_resource(npc: Node) -> Node2D:
	"""Find a nearby harvestable resource of the same type when current one becomes invalid."""
	if not npc or not npc.get_tree() or not ResourceIndex:
		return null
	var npc_pos: Vector2 = npc.global_position
	var filters: Dictionary = {
		"exclude_cooldown": true,
		"exclude_no_capacity": true,
		"exclude_empty": true,
		"resource_type": _expected_resource_type
	}
	var candidates: Array = ResourceIndex.query_near(npc_pos, ALTERNATIVE_SEARCH_RANGE, filters)
	for pair in candidates:
		var res: Node2D = pair.node
		if res == resource_node:
			continue
		return res
	return null

func _switch_to_resource(new_resource: Node2D, actor: Node) -> void:
	"""Switch to a new resource and reset move/gather state."""
	if resource_node and is_instance_valid(resource_node) and resource_node.has_method("release"):
		resource_node.release(actor)
	resource_node = new_resource
	_move_task = null
	_has_started_gathering = false
	_gather_timer = 0.0

func _clear_gathering(npc: NPCBase, cancelled: bool = false) -> void:
	if not npc:
		return
	npc.set("is_gathering", false)
	if npc.progress_display:
		npc.progress_display.stop_collection(cancelled)


func _kill_progress_tween(npc: NPCBase) -> void:
	if not npc or not npc.progress_display:
		return
	if npc.progress_display.get("_collection_tween") and npc.progress_display._collection_tween:
		npc.progress_display._collection_tween.kill()
		npc.progress_display._collection_tween = null


func _start_gather_progress(npc: NPCBase, icon: Texture2D) -> void:
	if not npc or not npc.progress_display:
		return
	npc.progress_display.start_collection(icon, gather_duration)
	_kill_progress_tween(npc)

func _cancel_impl(actor: Node) -> void:
	if actor is NPCBase:
		_clear_gathering(actor as NPCBase, true)

	if resource_node and is_instance_valid(resource_node) and resource_node.has_method("release"):
		resource_node.release(actor)

	if _move_task:
		_move_task.cancel(actor)
