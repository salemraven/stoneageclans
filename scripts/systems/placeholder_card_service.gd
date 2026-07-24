extends Node

const PlaceholderCardRegistryScript = preload("res://scripts/config/placeholder_card_registry.gd")
const CardVisualController = preload("res://scripts/systems/card_visual_controller.gd")
const WeaponOverlayCombat = preload("res://scripts/systems/weapon_overlay_combat.gd")

const CARD_NPC_TYPES: Array[String] = ["caveman", "clansman", "woman", "baby"]

var registry = PlaceholderCardRegistryScript.new()


func uses_placeholder_cards(entity: Node) -> bool:
	if entity == null or not is_instance_valid(entity):
		return false
	if entity.is_in_group("player"):
		return true
	var scr: Variant = entity.get_script()
	if scr is Script and str((scr as Script).resource_path).ends_with("player.gd"):
		return true
	var nt: Variant = entity.get("npc_type")
	return nt != null and str(nt) in CARD_NPC_TYPES


func apply_to_npc(npc: Node) -> void:
	if npc == null or not is_instance_valid(npc):
		return
	if not uses_placeholder_cards(npc):
		return
	var sprite: Sprite2D = npc.get_node_or_null("Sprite") as Sprite2D
	if sprite == null:
		return
	var npc_type: String = str(npc.get("npc_type")) if npc.get("npc_type") != null else ""
	var texture: Texture2D = _resolve_body_texture(npc, npc_type)
	if texture == null:
		return
	var foot_y: float = CardVisualController.apply_card_layout(sprite, texture, registry)
	npc.set("_card_foot_y", foot_y)
	if npc.has_method("_store_sprite_base_position"):
		npc._store_sprite_base_position()
	elif "_sprite_base_position" in npc:
		npc.set("_sprite_base_position", sprite.position)
	_apply_skin_modulate(npc)
	sync_progress_display_position(npc)


func sync_progress_display_position(entity: Node) -> void:
	if entity == null or not is_instance_valid(entity):
		return
	var sprite: Sprite2D = entity.get_node_or_null("Sprite") as Sprite2D
	var y: float = -88.0
	if sprite and sprite.texture:
		y = registry.get_progress_display_y(sprite.texture)
	var progress: Variant = entity.get("progress_display")
	if progress is Node2D:
		(progress as Node2D).position = Vector2(0.0, y)
	var eat_progress: Variant = entity.get("eat_progress_display")
	if eat_progress is Node2D:
		(eat_progress as Node2D).position = Vector2(0.0, y)


func apply_to_player(player: Node) -> void:
	if player == null or not is_instance_valid(player):
		return
	var sprite: Sprite2D = player.get_node_or_null("Sprite") as Sprite2D
	if sprite == null:
		return
	var card_index: int = 0
	if player.has_meta("card_index"):
		card_index = int(player.get_meta("card_index"))
	if card_index <= 0 and player.get("card_index") != null:
		card_index = int(player.get("card_index"))
	if card_index <= 0:
		card_index = randi_range(1, registry.CLANSMEN_CARD_COUNT)
	player.set("card_index", card_index)
	player.set_meta("card_index", card_index)
	var texture: Texture2D = registry.get_clansmen_card(card_index)
	if texture == null:
		return
	var foot_y: float = CardVisualController.apply_card_layout(sprite, texture, registry)
	player.set("_card_foot_y", foot_y)
	if "_sprite_base_position" in player:
		player.set("_sprite_base_position", sprite.position)
	sync_progress_display_position(player)


func restore_body_after_knap(npc: Node) -> void:
	apply_to_npc(npc)


func apply_card_layout_only(npc: Node) -> void:
	apply_to_npc(npc)


func tick_card_bounce(npc: Node, delta: float, moving: bool) -> void:
	if npc == null or not uses_placeholder_cards(npc):
		return
	var sprite: Sprite2D = npc.get_node_or_null("Sprite") as Sprite2D
	if sprite == null or sprite.texture == null:
		return
	var foot_y: float = float(npc.get("_card_foot_y")) if npc.get("_card_foot_y") != null else registry.get_card_foot_y(sprite.texture)
	var bounce_time: float = float(npc.get("_card_bounce_time")) if npc.get("_card_bounce_time") != null else 0.0
	bounce_time = CardVisualController.tick_walk_bounce(sprite, foot_y, bounce_time, moving, delta)
	npc.set("_card_bounce_time", bounce_time)
	npc.set("_card_bounce_moving", moving)


## Apply flip + optional lagged walk bounce to weapon overlay (call after combat pose updates).
func sync_weapon_overlay_flip(entity: Node) -> void:
	if entity == null or not is_instance_valid(entity) or not uses_placeholder_cards(entity):
		return
	var sprite: Sprite2D = entity.get_node_or_null("Sprite") as Sprite2D
	if sprite == null:
		return
	var overlay: Sprite2D = sprite.get_node_or_null("WeaponOverlay") as Sprite2D
	if overlay == null or not overlay.visible:
		return
	if WeaponOverlayCombat.get_overlay_state(entity) == WeaponOverlayCombat.OverlayState.STRIKING:
		return
	var base_offset: Vector2 = overlay.get_meta("card_overlay_offset", Vector2.ZERO)
	var mirror_tex: bool = true
	if entity.has_method("get_equipped_weapon_type"):
		var wt: ResourceData.ResourceType = entity.get_equipped_weapon_type()
		if wt != ResourceData.ResourceType.NONE:
			mirror_tex = WeaponOverlayCombat.uses_overlay_texture_mirror(registry, wt)
	var bounce_y: float = 0.0
	var bounce_x: float = 0.0
	if entity.get("_card_bounce_moving") == true:
		var bounce_time: float = float(entity.get("_card_bounce_time")) if entity.get("_card_bounce_time") != null else 0.0
		bounce_y = CardVisualController.weapon_overlay_walk_bounce_offset_y(bounce_time, true)
		bounce_x = CardVisualController.walk_weapon_overlay_sway_offset_x(bounce_time, true, sprite.flip_h)
	CardVisualController.sync_weapon_overlay_flip(sprite, overlay, base_offset, mirror_tex, bounce_y, bounce_x)


## Show/hide the WeaponOverlay child on card entities (body card stays unchanged).
func sync_weapon_overlay(entity: Node, weapon_type: ResourceData.ResourceType, should_show: bool) -> void:
	if entity == null or not is_instance_valid(entity) or not uses_placeholder_cards(entity):
		return
	var sprite: Sprite2D = entity.get_node_or_null("Sprite") as Sprite2D
	if sprite == null:
		return
	var overlay: Sprite2D = sprite.get_node_or_null("WeaponOverlay") as Sprite2D
	if overlay == null:
		return
	if not should_show or weapon_type == ResourceData.ResourceType.NONE:
		overlay.visible = false
		return
	var tex: Texture2D = registry.get_tool_overlay(weapon_type)
	if tex == null:
		overlay.visible = false
		return
	overlay.texture = tex
	# Body sprite is already card-scaled in apply_card_layout; large overlays match that grid.
	var overlay_scale: float = registry.get_tool_overlay_scale(weapon_type)
	overlay.scale = Vector2(overlay_scale, overlay_scale)
	overlay.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	overlay.visible = true
	var ostate: int = WeaponOverlayCombat.get_overlay_state(entity)
	# Never clobber strike tween or ready pose with idle corner placement.
	if ostate == WeaponOverlayCombat.OverlayState.STRIKING:
		return
	if ostate == WeaponOverlayCombat.OverlayState.READY:
		_apply_overlay_combat_pose(entity, weapon_type, overlay)
		return
	if ostate == WeaponOverlayCombat.OverlayState.RECOVERING:
		_apply_overlay_combat_pose(entity, weapon_type, overlay)
		return
	var base_offset: Vector2 = _overlay_local_offset(sprite, _effective_overlay_offset_px(weapon_type))
	overlay.set_meta("card_overlay_offset", base_offset)
	CardVisualController.sync_weapon_overlay_flip(sprite, overlay, base_offset)
	_apply_overlay_combat_pose(entity, weapon_type, overlay)


## Update overlay rotation for ready/strike/idle combat poses.
func update_weapon_overlay_combat(entity: Node, weapon_type: ResourceData.ResourceType, aim_dir: Vector2) -> void:
	if entity == null or not is_instance_valid(entity) or not uses_placeholder_cards(entity):
		return
	if weapon_type == ResourceData.ResourceType.NONE or weapon_type == ResourceData.ResourceType.TRAVOIS:
		return
	var sprite: Sprite2D = entity.get_node_or_null("Sprite") as Sprite2D
	if sprite == null:
		return
	var overlay: Sprite2D = sprite.get_node_or_null("WeaponOverlay") as Sprite2D
	if overlay == null or not overlay.visible:
		return
	var ostate: int = WeaponOverlayCombat.get_overlay_state(entity)
	if ostate == WeaponOverlayCombat.OverlayState.STRIKING:
		return
	if ostate == WeaponOverlayCombat.OverlayState.READY:
		WeaponOverlayCombat.apply_ready_pose(sprite, overlay, registry, weapon_type, aim_dir)
	elif ostate == WeaponOverlayCombat.OverlayState.RECOVERING:
		if WeaponOverlayCombat.should_hold_weapon_ready(entity):
			WeaponOverlayCombat.apply_ready_pose(sprite, overlay, registry, weapon_type, aim_dir)
		else:
			WeaponOverlayCombat.apply_idle_pose(sprite, overlay, registry, weapon_type)
	elif ostate == WeaponOverlayCombat.OverlayState.IDLE:
		WeaponOverlayCombat.apply_idle_pose(sprite, overlay, registry, weapon_type)


func play_weapon_overlay_strike(
	entity: Node,
	weapon_type: ResourceData.ResourceType,
	aim_dir: Vector2,
	on_hit: Callable,
	on_recovery_done: Callable = Callable()
) -> void:
	if entity == null or not is_instance_valid(entity):
		return
	var sprite: Sprite2D = entity.get_node_or_null("Sprite") as Sprite2D
	if sprite == null:
		return
	var overlay: Sprite2D = sprite.get_node_or_null("WeaponOverlay") as Sprite2D
	if overlay == null:
		return
	sync_weapon_overlay(entity, weapon_type, true)
	var profile: Dictionary = registry.get_weapon_combat_profile(weapon_type)
	var recovery_d: float = float(profile.get("recovery_duration", 0.5))
	var combat_recovery_d: float = float(profile.get("combat_recovery_duration", recovery_d))
	var combat_recovery_ready_d: float = float(profile.get("combat_recovery_duration_ready", combat_recovery_d))
	var strike_done := func() -> void:
		if not entity or not is_instance_valid(entity):
			return
		WeaponOverlayCombat.play_post_strike_recovery(
			entity, sprite, overlay, registry, weapon_type, aim_dir, recovery_d
		)
		if on_recovery_done.is_valid():
			var unlock_d: float = combat_recovery_ready_d if WeaponOverlayCombat.should_hold_weapon_ready(entity) else combat_recovery_d
			var unlock_t := entity.get_tree().create_timer(maxf(unlock_d, 0.03))
			unlock_t.timeout.connect(func() -> void:
				if on_recovery_done.is_valid() and entity and is_instance_valid(entity):
					on_recovery_done.call()
			)
	WeaponOverlayCombat.play_strike(entity, sprite, overlay, registry, weapon_type, aim_dir, on_hit, strike_done)


func set_overlay_combat_state(entity: Node, st: int) -> void:
	WeaponOverlayCombat.set_overlay_state(entity, st)


func _apply_overlay_combat_pose(entity: Node, weapon_type: ResourceData.ResourceType, overlay: Sprite2D) -> void:
	if entity == null or overlay == null:
		return
	var sprite: Sprite2D = entity.get_node_or_null("Sprite") as Sprite2D
	if sprite == null:
		return
	var ostate: int = WeaponOverlayCombat.get_overlay_state(entity)
	if ostate == WeaponOverlayCombat.OverlayState.STRIKING:
		return
	if ostate == WeaponOverlayCombat.OverlayState.READY:
		var aim: Vector2 = Vector2(1, 0)
		if entity.get("aim_dir") != null:
			aim = entity.get("aim_dir") as Vector2
		elif entity.get("last_facing") != null:
			aim = entity.get("last_facing") as Vector2
		WeaponOverlayCombat.apply_ready_pose(sprite, overlay, registry, weapon_type, aim)
	elif ostate == WeaponOverlayCombat.OverlayState.RECOVERING:
		if WeaponOverlayCombat.should_hold_weapon_ready(entity):
			var aim_r: Vector2 = WeaponOverlayCombat.resolve_recovery_aim(entity, Vector2(1, 0))
			WeaponOverlayCombat.apply_ready_pose(sprite, overlay, registry, weapon_type, aim_r)
		else:
			WeaponOverlayCombat.apply_idle_pose(sprite, overlay, registry, weapon_type)
	else:
		WeaponOverlayCombat.apply_idle_pose(sprite, overlay, registry, weapon_type)
		WeaponOverlayCombat.set_overlay_state(entity, WeaponOverlayCombat.OverlayState.IDLE)


func _effective_overlay_offset_px(weapon_type: ResourceData.ResourceType) -> Vector2:
	if LimbPresetRegistry:
		return LimbPresetRegistry.get_overlay_offset_idle_px(weapon_type)
	return registry.get_tool_overlay_offset_px(weapon_type)


func _overlay_local_offset(sprite: Sprite2D, offset_px: Vector2) -> Vector2:
	if offset_px == Vector2.ZERO or sprite == null:
		return Vector2.ZERO
	var sx: float = absf(sprite.scale.x)
	if sx < 0.001:
		sx = 1.0
	return Vector2(offset_px.x / sx, offset_px.y / sx)


func get_card_index_from_texture_path(path: String) -> int:
	if path.is_empty():
		return 0
	var base: String = path.get_file().get_basename()
	if base.begins_with("clansmen_card"):
		var num_str: String = base.trim_prefix("clansmen_card")
		if num_str.is_valid_int():
			return int(num_str)
	return 0


func get_card_index_from_entity(entity: Node) -> int:
	if entity == null or not is_instance_valid(entity):
		return 0
	if entity.has_meta("card_index"):
		var meta_idx: int = int(entity.get_meta("card_index"))
		if meta_idx > 0:
			return meta_idx
	if entity.get("card_index") != null:
		var prop_idx: int = int(entity.get("card_index"))
		if prop_idx > 0:
			return prop_idx
	var sprite: Sprite2D = entity.get_node_or_null("Sprite") as Sprite2D
	if sprite and sprite.texture:
		var from_tex: int = get_card_index_from_texture_path(sprite.texture.resource_path)
		if from_tex > 0:
			return from_tex
	return 0


func _find_player_node() -> Node:
	var tree := get_tree()
	if tree == null:
		return null
	var player: Node = tree.get_first_node_in_group("player")
	if player:
		return player
	return tree.root.find_child("Player", true, false)


## Father NPC or player (when reproduction passes null for player). Sons inherit this card_index.
func resolve_father_card_index(father: Node) -> int:
	var idx: int = get_card_index_from_entity(father)
	if idx > 0:
		return idx
	var player: Node = _find_player_node()
	idx = get_card_index_from_entity(player)
	if idx > 0:
		return idx
	return randi_range(1, registry.CLANSMEN_CARD_COUNT)


func assign_inherited_card_index(child: Node, father: Node) -> int:
	var idx: int = resolve_father_card_index(father)
	if child:
		child.set("card_index", idx)
		child.set_meta("card_index", idx)
	return idx


func _resolve_body_texture(npc: Node, npc_type: String) -> Texture2D:
	match npc_type:
		"woman":
			return registry.get_woman_card()
		"baby":
			return registry.get_baby_card()
		"caveman", "clansman":
			var card_index: int = int(npc.get("card_index")) if npc.get("card_index") != null else 0
			if card_index <= 0:
				if npc.has_method("npc_randi_range"):
					card_index = npc.npc_randi_range(1, registry.CLANSMEN_CARD_COUNT)
				else:
					card_index = randi_range(1, registry.CLANSMEN_CARD_COUNT)
				npc.set("card_index", card_index)
			npc.set_meta("card_index", card_index)
			return registry.get_clansmen_card(card_index)
		_:
			return null


func _apply_skin_modulate(npc: Node) -> void:
	if npc == null:
		return
	var profile: Variant = npc.get("genetics_profile")
	if profile is Dictionary and (profile as Dictionary).has("skin_modulate"):
		var sprite: Sprite2D = npc.get_node_or_null("Sprite") as Sprite2D
		if sprite:
			sprite.modulate = (profile as Dictionary)["skin_modulate"]
		return
	if npc.has_method("_update_visual_tier"):
		npc._update_visual_tier()
