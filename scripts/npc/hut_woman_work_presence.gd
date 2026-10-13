extends Node

## Woman at a specialized living hut: patrol along the hut foot line, idle poses, craft timer over head.

const HutSpecialtyScript = preload("res://scripts/buildings/hut_specialty.gd")
const CollectionProgressScript = preload("res://scripts/collection_progress.gd")

const PATROL_SPEED := 34.0
const FOOT_OFFSET_Y := 52.0
const PATROL_WIDTH_RATIO := 0.2
const MIN_PATROL_HALF_W := 28.0
const MAX_PATROL_HALF_W := 56.0
const PAUSE_MIN_SEC := 0.35
const PAUSE_MAX_SEC := 2.4
const END_PAUSE_CHANCE := 0.28
const RANDOM_PAUSE_WHILE_WALK_CHANCE := 0.002
const SLOW_TO_PAUSE_SEC := 0.48
const EASE_FROM_PAUSE_SEC := 0.38
const WALK_ANIM_MIN_SPEED_SCALE := 0.12
## Subtle idle/work at hut vs full patrol walk.
const WORK_IDLE_MOTION_MUL := 0.34
const WORK_WALK_MOTION_FLOOR := 0.45
const HUT_APPROACH_MAX_DIST := 72.0
const CLAIM_APPROACH_RADIUS := 32.0
const HUT_CRAFT_PROGRESS_EXTRA_ABOVE_HEAD := 22.0


func hut_approach_position(hut: Node2D) -> Vector2:
	if hut == null or not is_instance_valid(hut):
		return Vector2.ZERO
	var bounds := _patrol_bounds(hut)
	return Vector2((bounds.left_x + bounds.right_x) * 0.5, bounds.foot_y)


func claim_approach_position(claim: Node2D, approach_from: Vector2) -> Vector2:
	if claim == null or not is_instance_valid(claim):
		return approach_from
	var center := claim.global_position
	var outward: Vector2 = approach_from - center
	if outward.length_squared() < 4.0:
		outward = Vector2(1.0, 0.0)
	else:
		outward = outward.normalized()
	return center + outward * CLAIM_APPROACH_RADIUS


func is_living_hut_occupant(npc: Node) -> bool:
	var hut := _home_hut(npc)
	if hut == null:
		return false
	if str(hut.get("hut_specialty")).strip_edges() == "":
		return false
	if _woman_in_hut_slot(npc, hut):
		return true
	if OccupationSystem and OccupationSystem.get_ref_state(npc) == OccupationSystem.OccupationState.OCCUPIED:
		var wp: Node2D = OccupationSystem.get_workplace(npc)
		return wp == hut
	return false


func controls_npc(npc: Node) -> bool:
	if not is_living_hut_occupant(npc):
		return false
	if _carrying_stack(npc):
		return false
	var tr: Variant = npc.get("task_runner")
	if tr != null and is_instance_valid(tr) and tr.has_method("controls_movement") and tr.controls_movement():
		return false
	if _on_hut_carry_job(npc):
		return _hut_carry_allows_presence(npc)
	return _near_hut_work_line(npc)


func _hut_carry_allows_presence(npc: Node) -> bool:
	var task: Variant = _hut_carry_task(npc)
	if task == null:
		return false
	var phase: String = str(task.get("_phase"))
	if phase == "wait":
		return _near_hut_work_line(npc)
	return false


func pre_physics(npc: Node, delta: float) -> void:
	var active := controls_npc(npc)
	npc.set_meta("hut_work_presence_active", active)
	if not active:
		npc.set_meta("hut_work_walking", false)
		_hide_craft_progress(npc)
		return
	var hut := _home_hut(npc)
	if hut == null:
		return
	_ensure_sprite_visible(npc)
	_align_patrol_foot_if_near(npc, hut)
	_update_patrol(npc, hut, delta)
	sync_work_motion_scale(npc)
	_sync_craft_progress(npc, hut)


func sync_work_motion_scale(npc: Node) -> void:
	if npc == null or not npc.get_meta("hut_work_presence_active", false):
		if npc != null and npc.has_meta("hut_work_motion_scale"):
			npc.remove_meta("hut_work_motion_scale")
		return
	var mul: float = WORK_IDLE_MOTION_MUL
	if bool(npc.get_meta("hut_work_walking", false)):
		var speed: float = float(npc.get_meta("hut_work_speed_scale", 1.0))
		mul = lerpf(WORK_WALK_MOTION_FLOOR, 1.0, clampf(speed, 0.0, 1.0))
	npc.set_meta("hut_work_motion_scale", mul)


func apply_patrol_velocity(npc: Node, _delta: float) -> void:
	if not controls_npc(npc):
		return
	# Patrol position is applied in _update_patrol; keep physics from fighting steering.
	npc.velocity = Vector2.ZERO


func _hut_carry_task(npc: Node) -> Task:
	var tr: Variant = npc.get("task_runner")
	if tr == null or not is_instance_valid(tr):
		return null
	var task: Variant = tr.get("current_task")
	if task == null or not is_instance_valid(task) or task.get_script() == null:
		return null
	if not str(task.get_script().get_path()).ends_with("hut_carry_task.gd"):
		return null
	return task as Task


func _on_hut_carry_job(npc: Node) -> bool:
	return _hut_carry_task(npc) != null


func _carrying_stack(npc: Node) -> bool:
	var inv: Variant = npc.get("inventory")
	if inv == null or not inv.has_method("get_slot"):
		return false
	var slot: Dictionary = inv.get_slot(0)
	return not slot.is_empty() and int(slot.get("count", 0)) > 0


func _near_hut_work_line(npc: Node) -> bool:
	var hut := _home_hut(npc)
	if hut == null:
		return false
	var stand := hut_approach_position(hut)
	return npc.global_position.distance_to(stand) <= HUT_APPROACH_MAX_DIST


func _align_patrol_foot_if_near(npc: Node, hut: Node2D) -> void:
	if not _near_hut_work_line(npc):
		return
	var bounds := _patrol_bounds(hut)
	var pos: Vector2 = npc.global_position
	pos.y = bounds.foot_y
	pos.x = clampf(pos.x, bounds.left_x, bounds.right_x)
	npc.global_position = pos


func _ensure_sprite_visible(npc: Node) -> void:
	var spr: Node = npc.get_node_or_null("Sprite")
	if spr:
		spr.visible = true


## Match npc_base: flip_h true = facing left along patrol.
func _sync_patrol_facing(npc: Node, dir: float) -> void:
	if dir == 0.0:
		return
	var spr: Sprite2D = npc.get_node_or_null("Sprite") as Sprite2D
	if spr == null:
		return
	spr.flip_h = dir < 0.0
	if npc.get("_last_facing") != null:
		npc.set("_last_facing", Vector2(-1.0 if dir < 0.0 else 1.0, 0.0))


func _update_patrol(npc: Node, hut: Node2D, delta: float) -> void:
	var bounds := _patrol_bounds(hut)
	var pos: Vector2 = npc.global_position
	pos.y = bounds.foot_y
	var phase: String = str(npc.get_meta("hut_work_phase", "walk"))
	var dir: float = float(npc.get_meta("hut_work_dir", 1.0))
	if dir == 0.0:
		dir = 1.0
	if phase == "pause":
		var pause_left: float = float(npc.get_meta("hut_work_pause_left", 0.0)) - delta
		npc.set_meta("hut_work_vx", 0.0)
		npc.set_meta("hut_work_speed_scale", 0.0)
		npc.set_meta("hut_work_walking", false)
		_tick_idle_pose(npc, delta)
		if pause_left <= 0.0:
			if npc.has_method("npc_randf") and npc.npc_randf() < 0.5:
				dir = -dir
				npc.set_meta("hut_work_dir", dir)
			_begin_ease_from_pause(npc)
		else:
			npc.set_meta("hut_work_pause_left", pause_left)
		pos.x = clampf(pos.x, bounds.left_x, bounds.right_x)
		npc.global_position = pos
		return
	if phase == "slow":
		var slow_left: float = float(npc.get_meta("hut_work_slow_left", 0.0)) - delta
		var slow_u: float = clampf(slow_left / SLOW_TO_PAUSE_SEC, 0.0, 1.0)
		var slow_scale: float = slow_u * slow_u
		_apply_patrol_step(npc, pos, bounds, dir, delta, slow_scale)
		if slow_left <= 0.0:
			_begin_pause(npc)
		else:
			npc.set_meta("hut_work_slow_left", slow_left)
		npc.global_position = pos
		return
	if phase == "ease_walk":
		var ease_left: float = float(npc.get_meta("hut_work_ease_left", 0.0)) - delta
		var ease_u: float = 1.0 - clampf(ease_left / EASE_FROM_PAUSE_SEC, 0.0, 1.0)
		var ease_scale: float = ease_u * ease_u
		_apply_patrol_step(npc, pos, bounds, dir, delta, ease_scale)
		if ease_left <= 0.0:
			npc.set_meta("hut_work_phase", "walk")
		else:
			npc.set_meta("hut_work_ease_left", ease_left)
		npc.global_position = pos
		return
	# walk
	npc.set_meta("hut_work_speed_scale", 1.0)
	npc.set_meta("hut_work_walking", true)
	var vx: float = dir * PATROL_SPEED
	npc.set_meta("hut_work_vx", vx)
	_sync_patrol_facing(npc, dir)
	pos.x += vx * delta
	var hit_left: bool = pos.x <= bounds.left_x
	var hit_right: bool = pos.x >= bounds.right_x
	if hit_left:
		pos.x = bounds.left_x
		dir = 1.0
	elif hit_right:
		pos.x = bounds.right_x
		dir = -1.0
	if hit_left or hit_right:
		npc.set_meta("hut_work_dir", dir)
		_sync_patrol_facing(npc, dir)
		if npc.has_method("npc_randf") and npc.npc_randf() < END_PAUSE_CHANCE:
			_begin_slow_to_pause(npc)
	elif npc.has_method("npc_randf") and npc.npc_randf() < RANDOM_PAUSE_WHILE_WALK_CHANCE:
		_begin_slow_to_pause(npc)
	pos.x = clampf(pos.x, bounds.left_x, bounds.right_x)
	npc.global_position = pos


func _apply_patrol_step(npc: Node, pos: Vector2, bounds: Dictionary, dir: float, delta: float, speed_scale: float) -> void:
	var scale: float = clampf(speed_scale, 0.0, 1.0)
	npc.set_meta("hut_work_speed_scale", scale)
	var walking: bool = scale >= WALK_ANIM_MIN_SPEED_SCALE
	npc.set_meta("hut_work_walking", walking)
	var vx: float = dir * PATROL_SPEED * scale
	npc.set_meta("hut_work_vx", vx)
	if walking:
		_sync_patrol_facing(npc, dir)
	pos.x += vx * delta
	pos.x = clampf(pos.x, bounds.left_x, bounds.right_x)  # slow / ease_walk


func _begin_slow_to_pause(npc: Node) -> void:
	npc.set_meta("hut_work_phase", "slow")
	npc.set_meta("hut_work_slow_left", SLOW_TO_PAUSE_SEC)


func _begin_ease_from_pause(npc: Node) -> void:
	npc.set_meta("hut_work_phase", "ease_walk")
	npc.set_meta("hut_work_ease_left", EASE_FROM_PAUSE_SEC)
	npc.set_meta("hut_work_vx", 0.0)
	npc.set_meta("hut_work_walking", false)


func _begin_pause(npc: Node) -> void:
	npc.set_meta("hut_work_phase", "pause")
	var dur := PAUSE_MIN_SEC
	if npc.has_method("npc_randf_range"):
		dur = npc.npc_randf_range(PAUSE_MIN_SEC, PAUSE_MAX_SEC)
	npc.set_meta("hut_work_pause_left", dur)
	npc.set_meta("hut_work_vx", 0.0)
	npc.set_meta("hut_work_walking", false)
	var pose_roll := 0
	if npc.has_method("npc_randi_range"):
		pose_roll = npc.npc_randi_range(0, 2)
	npc.set_meta("hut_work_idle_pose", pose_roll)
	npc.set_meta("hut_work_idle_pose_time", 0.0)


func _tick_idle_pose(npc: Node, delta: float) -> void:
	var t: float = float(npc.get_meta("hut_work_idle_pose_time", 0.0)) + delta
	npc.set_meta("hut_work_idle_pose_time", t)
	var pose: int = int(npc.get_meta("hut_work_idle_pose", 0))
	npc.set_meta("hut_work_idle_pose", pose)


func get_idle_pose_for_visual(npc: Node) -> Dictionary:
	if not npc.get_meta("hut_work_presence_active", false):
		return {}
	if npc.get_meta("hut_work_walking", false):
		return {}
	var pose: int = int(npc.get_meta("hut_work_idle_pose", 0))
	var t: float = float(npc.get_meta("hut_work_idle_pose_time", 0.0))
	return {"pose": pose, "time": t}


func _patrol_bounds(hut: Node2D) -> Dictionary:
	var center := hut.global_position
	var half_w := MIN_PATROL_HALF_W
	var spr: Sprite2D = hut.get_node_or_null("Sprite") as Sprite2D
	if spr and spr.texture:
		var tex_w := float(spr.texture.get_width()) * absf(spr.scale.x)
		half_w = clampf(tex_w * PATROL_WIDTH_RATIO, MIN_PATROL_HALF_W, MAX_PATROL_HALF_W)
	var foot_y := center.y + FOOT_OFFSET_Y
	return {
		"left_x": center.x - half_w,
		"right_x": center.x + half_w,
		"foot_y": foot_y,
	}


func _home_hut(npc: Node) -> Node2D:
	if OccupationSystem and OccupationSystem.has_method("get_home_living_hut"):
		var hut: Node2D = OccupationSystem.get_home_living_hut(npc)
		if hut and is_instance_valid(hut):
			return hut
	if npc.get("workplace_building") != null:
		var wb: Node = npc.workplace_building
		if wb and is_instance_valid(wb) and int(wb.get("building_type")) == int(ResourceData.ResourceType.LIVING_HUT):
			return wb as Node2D
	return null


func _woman_in_hut_slot(npc: Node, hut: Node) -> bool:
	if not hut.has_method("get_occupant"):
		return false
	for i in range(4):
		var occ: Node = hut.get_occupant(i, true)
		if occ == npc:
			return true
	if "woman_slots" in hut:
		for slot in hut.woman_slots:
			if slot == npc:
				return true
	return false


func _sync_craft_progress(npc: Node, hut: Node) -> void:
	var info := HutSpecialtyScript.craft_progress_display(hut)
	var pd: Node = npc.get("progress_display")
	if pd == null:
		return
	if not bool(info.get("active", false)):
		_hide_craft_progress(npc)
		return
	if PlaceholderCardService and PlaceholderCardService.has_method("sync_progress_display_position"):
		PlaceholderCardService.sync_progress_display_position(npc, HUT_CRAFT_PROGRESS_EXTRA_ABOVE_HEAD)
	var ratio: float = float(info.get("ratio", 0.0))
	var product: int = int(info.get("product", int(ResourceData.ResourceType.NONE)))
	var icon_path := ResourceData.get_resource_icon_path(product as ResourceData.ResourceType)
	var icon: Texture2D = null
	if icon_path != "" and ResourceLoader.exists(icon_path):
		icon = load(icon_path) as Texture2D
	if pd.has_method("show_manual_progress"):
		pd.call("show_manual_progress", icon, ratio)
	if pd is Node2D:
		(pd as Node2D).visible = true


func _hide_craft_progress(npc: Node) -> void:
	var pd: Node = npc.get("progress_display")
	if pd and pd.has_method("hide_manual_progress"):
		pd.call("hide_manual_progress")
