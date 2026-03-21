extends Task
class_name OccupyTask

# Task System - Step 16
# NPC occupies a building and waits for production to complete
# The building must be active and have required materials

# Building to occupy
var building: BuildingBase

# Production component to monitor
var production_component: Node = null

# Whether we've successfully occupied the building
var _occupied: bool = false

# Whether production has completed
var _production_complete: bool = false

# Initial output count when task started (to detect NEW production)
var _initial_output_count: int = 0

func _init(bldg: BuildingBase) -> void:
	building = bldg

func _start_impl(actor: Node) -> void:
	if not actor is NPCBase:
		if DebugConfig and DebugConfig.enable_debug_mode:
			UnifiedLogger.log_npc("OccupyTask: Actor is not NPCBase", {}, UnifiedLogger.Level.DEBUG)
		status = TaskStatus.FAILED
		return
	
	if not building or not is_instance_valid(building):
		if DebugConfig and DebugConfig.enable_debug_mode:
			UnifiedLogger.log_npc("OccupyTask: Building is invalid", {}, UnifiedLogger.Level.DEBUG)
		status = TaskStatus.FAILED
		return
	
	# Get production component
	production_component = building.get_node_or_null("ProductionComponent")
	if not production_component:
		if DebugConfig and DebugConfig.enable_debug_mode:
			UnifiedLogger.log_npc("OccupyTask: No ProductionComponent found", {}, UnifiedLogger.Level.DEBUG)
		status = TaskStatus.FAILED
		return
	
	# Check if building is already occupied
	if building.is_occupied():
		if DebugConfig and DebugConfig.enable_debug_mode:
			UnifiedLogger.log_npc("OccupyTask: Building is already occupied", {}, UnifiedLogger.Level.DEBUG)
		status = TaskStatus.FAILED
		return
	
	# CRITICAL: Occupy and activate BEFORE _can_craft() - _can_craft() requires is_occupied() when requires_woman
	if not building.is_active:
		building.set_active(true)
	var slot_idx: int = -1
	for i in building.woman_slots.size():
		if building.woman_slots[i] == null or not is_instance_valid(building.woman_slots[i]):
			slot_idx = i
			break
	if slot_idx >= 0 and OccupationSystem:
		OccupationSystem.force_assign(actor, building, slot_idx, "woman")
	else:
		status = TaskStatus.FAILED
		return
	_occupied = true
	
	# Check if building has required materials (via production component)
	if production_component.has_method("_can_craft"):
		var can_craft_result = production_component._can_craft()
		if not can_craft_result:
			if OccupationSystem and OccupationSystem.has_ref(actor):
				OccupationSystem.unassign(actor, "task_failed")
			building.set_active(false)
			_occupied = false
			if DebugConfig and DebugConfig.enable_debug_mode:
				UnifiedLogger.log_npc("OccupyTask: Cannot craft - materials missing or other issue", {}, UnifiedLogger.Level.DEBUG)
			status = TaskStatus.FAILED
			return
	
	# CRITICAL: Record initial output count to detect NEW production
	# We only complete when NEW bread is produced, not if bread already exists
	var recipe = production_component.get("recipe") if "recipe" in production_component else {}
	if recipe.has("output"):
		var output_type: ResourceData.ResourceType = recipe["output"].get("type", ResourceData.ResourceType.NONE)
		if building.inventory:
			_initial_output_count = building.inventory.get_count(output_type)
			if DebugConfig and DebugConfig.enable_debug_mode:
				UnifiedLogger.log_npc("OccupyTask: Starting - initial output count: %s x%d" % [ResourceData.get_resource_name(output_type), _initial_output_count], {}, UnifiedLogger.Level.DEBUG)
	
	if DebugConfig and DebugConfig.enable_debug_mode:
		UnifiedLogger.log_npc("OccupyTask: Starting successfully", {}, UnifiedLogger.Level.DEBUG)
	status = TaskStatus.RUNNING

func _tick_impl(actor: Node, delta: float) -> TaskStatus:
	if not actor is NPCBase:
		if DebugConfig and DebugConfig.enable_debug_mode:
			UnifiedLogger.log_npc("OccupyTask._tick: Actor is not NPCBase", {}, UnifiedLogger.Level.DEBUG)
		return TaskStatus.FAILED
	
	if not building or not is_instance_valid(building):
		if DebugConfig and DebugConfig.enable_debug_mode:
			UnifiedLogger.log_npc("OccupyTask._tick: Building is invalid", {}, UnifiedLogger.Level.DEBUG)
		return TaskStatus.FAILED
	
	# Already occupied in _start_impl - just monitor production
	# Check if production can continue
	# Production continues until resources run out (can't craft anymore)
	if production_component and production_component.has_method("_can_craft"):
		var can_craft = production_component._can_craft()
		
		# If we can't craft anymore (resources exhausted), production is complete
		if not can_craft:
			if DebugConfig and DebugConfig.enable_debug_mode:
				UnifiedLogger.log_npc("OccupyTask: Production complete! Resources exhausted - cannot craft anymore", {}, UnifiedLogger.Level.DEBUG)
			_production_complete = true
			if OccupationSystem and OccupationSystem.has_ref(actor):
				OccupationSystem.unassign(actor, "task_complete")
			return TaskStatus.SUCCESS
	
	# Continue waiting
	return TaskStatus.RUNNING

func _cancel_impl(actor: Node) -> void:
	if _occupied and building and is_instance_valid(building):
		if OccupationSystem and OccupationSystem.has_ref(actor):
			OccupationSystem.unassign(actor, "task_cancel")
