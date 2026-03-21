extends Task
class_name KnapTask

const MoveToTaskScript = preload("res://scripts/ai/tasks/move_to_task.gd")

# Craft Task System - Atomic task for knapping stones into blades at land claim
# Handles: Move to land claim → Wait (show knapp sprite) → Consume 2 stone, add 1 stone + 1 blade

const KNAPP_SPRITE_PATH := "res://assets/sprites/knapp.png"
const NORMAL_SPRITE_PATH := "res://assets/sprites/PlayerB.png"
const STONES_REQUIRED: int = 2

var land_claim: Node2D
var craft_duration: float = 1.5
var craft_range: float = 50.0

var _knap_timer: float = 0.0
var _has_started_knapping: bool = false
var _knap_start_position: Vector2 = Vector2.ZERO  # If NPC moves beyond threshold, cancel crafting
const MOVE_CANCEL_THRESHOLD: float = 20.0  # Pixels - moving this far cancels knap
var _move_task: Task = null

func _init(claim: Node2D, duration: float = 1.5, range_dist: float = 50.0) -> void:
	land_claim = claim
	craft_duration = duration
	craft_range = range_dist

func _start_impl(actor: Node) -> void:
	if not actor is NPCBase:
		status = TaskStatus.FAILED
		return

	var npc: NPCBase = actor as NPCBase
	if not npc.inventory:
		status = TaskStatus.FAILED
		return

	if not land_claim or not is_instance_valid(land_claim):
		status = TaskStatus.FAILED
		return

	if npc.inventory.get_count(ResourceData.ResourceType.STONE) < STONES_REQUIRED:
		status = TaskStatus.FAILED
		return

	status = TaskStatus.RUNNING
	_knap_timer = 0.0
	_has_started_knapping = false

func _tick_impl(actor: Node, delta: float) -> TaskStatus:
	if not actor is NPCBase:
		return TaskStatus.FAILED

	var npc: NPCBase = actor as NPCBase

	if npc.should_abort_work():
		_cleanup_knap_sprite(npc)
		return TaskStatus.FAILED

	if not npc.inventory or not land_claim or not is_instance_valid(land_claim):
		_cleanup_knap_sprite(npc)
		return TaskStatus.FAILED

	if npc.inventory.get_count(ResourceData.ResourceType.STONE) < STONES_REQUIRED:
		_cleanup_knap_sprite(npc)
		return TaskStatus.FAILED

	# Step 1: Move to land claim if not in range
	var npc_pos: Vector2 = npc.global_position
	var claim_pos: Vector2 = land_claim.global_position
	var distance: float = npc_pos.distance_to(claim_pos)

	if distance > craft_range:
		if not _move_task:
			_move_task = MoveToTaskScript.new(claim_pos, craft_range) as Task
			if _move_task:
				_move_task.start(actor)
			else:
				return TaskStatus.FAILED

		var move_status = _move_task.tick(actor, delta)
		if move_status == TaskStatus.RUNNING:
			return TaskStatus.RUNNING
		elif move_status == TaskStatus.FAILED:
			return TaskStatus.FAILED

	# In range: block movement immediately (so we never move during knap, regardless of frame order)
	npc.set("is_crafting", true)
	npc.velocity = Vector2.ZERO
	if npc.steering_agent:
		npc.steering_agent.target_position = npc.global_position
		npc.steering_agent.target_node = null

	# Step 2: Start knapping (show knapp sprite, progress display) — must stay in place until done
	if not _has_started_knapping:
		_has_started_knapping = true
		_knap_start_position = npc.global_position
		npc.set("is_crafting", true)
		npc.velocity = Vector2.ZERO
		if npc.steering_agent:
			npc.steering_agent.target_position = npc.global_position
			npc.steering_agent.target_node = null
		_apply_knapp_sprite(npc)
		if npc.progress_display:
			var icon_path: String = ResourceData.get_resource_icon_path(ResourceData.ResourceType.BLADE)
			var icon: Texture2D = load(icon_path) as Texture2D if icon_path else null
			npc.progress_display.start_collection(icon)
			npc.progress_display.collection_time = craft_duration

	# If NPC moved after starting knap, cancel crafting (must stay in place; ready for future animation)
	var moved: float = npc.global_position.distance_to(_knap_start_position)
	if moved > MOVE_CANCEL_THRESHOLD:
		_cleanup_knap_sprite(npc)
		return TaskStatus.FAILED

	# Stay still every tick while knapping (no moving or craft cancels; knapp sprite shown)
	npc.velocity = Vector2.ZERO
	if npc.steering_agent:
		npc.steering_agent.target_position = npc.global_position
		npc.steering_agent.target_node = null

	# Step 3: Wait for craft duration
	_knap_timer += delta
	if npc.progress_display:
		npc.progress_display.set_progress(_knap_timer / craft_duration)

	if _knap_timer < craft_duration:
		return TaskStatus.RUNNING

	# Step 4: Apply recipe (2 stone → 1 stone + 1 blade)
	if not npc.inventory.remove_item(ResourceData.ResourceType.STONE, STONES_REQUIRED):
		_cleanup_knap_sprite(npc)
		return TaskStatus.FAILED

	npc.inventory.add_item(ResourceData.ResourceType.STONE, 1)
	npc.inventory.add_item(ResourceData.ResourceType.BLADE, 1)

	_cleanup_knap_sprite(npc)

	UnifiedLogger.log_npc("KNAP_TASK: %s crafted 1 blade" % npc.npc_name, {
		"npc": npc.npc_name,
		"task": "knap",
		"output": "blade"
	})

	return TaskStatus.SUCCESS

func _apply_knapp_sprite(npc: NPCBase) -> void:
	if not npc or not npc.sprite:
		return
	var tex: Texture2D = load(KNAPP_SPRITE_PATH) as Texture2D
	if tex:
		npc.sprite.texture = tex
		npc.sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		if npc.has_method("apply_sprite_offset_for_texture"):
			npc.apply_sprite_offset_for_texture()

func _cleanup_knap_sprite(npc: NPCBase) -> void:
	if not npc:
		return
	npc.set("is_crafting", false)
	if npc.progress_display:
		npc.progress_display.stop_collection()
	if npc.sprite:
		var tex: Texture2D = load(NORMAL_SPRITE_PATH) as Texture2D
		if tex:
			npc.sprite.texture = tex
			npc.sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
			if npc.has_method("apply_sprite_offset_for_texture"):
				npc.apply_sprite_offset_for_texture()
	var weapon: Node = npc.get_node_or_null("WeaponComponent")
	if weapon and weapon.has_method("force_apply_idle"):
		weapon.force_apply_idle()

func _cancel_impl(actor: Node) -> void:
	if actor is NPCBase:
		_cleanup_knap_sprite(actor as NPCBase)
	if _move_task:
		_move_task.cancel(actor)
