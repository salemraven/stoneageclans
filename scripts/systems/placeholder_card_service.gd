extends Node

const PlaceholderCardRegistryScript = preload("res://scripts/config/placeholder_card_registry.gd")
const CardVisualController = preload("res://scripts/systems/card_visual_controller.gd")
const WeaponOverlayCombat = preload("res://scripts/systems/weapon_overlay_combat.gd")
const TunerMannequinLayoutScript = preload("res://scripts/tools/tuner_mannequin_layout.gd")
const TunerBodyVisualScript = preload("res://scripts/tools/tuner_body_visual.gd")
const TunerIdlePreviewScript = preload("res://scripts/tools/tuner_idle_preview.gd")
const PartsRegistry = preload("res://scripts/config/character_card_parts_registry.gd")
const ProceduralArmControllerScript = preload("res://scripts/systems/procedural_arm_controller.gd")
const MannequinPoseRuntimeScript = preload("res://scripts/systems/mannequin_pose_runtime.gd")
const MannequinAnchorResolverScript = preload("res://scripts/systems/mannequin_anchor_resolver.gd")

const CARD_NPC_TYPES: Array[String] = ["caveman", "clansman", "woman", "baby"]
const PROCEDURAL_MANNEQUIN_NPC_TYPES: Array[String] = ["caveman", "clansman"]
const LEGACY_BAKED_CARD_NPC_TYPES: Array[String] = ["woman", "baby"]
## Main/gameplay: layered body+head only; procedural IK stays in Limb Tuner.
const PROCEDURAL_MANNEQUIN_ENABLED_IN_GAME := false
const RUNTIME_LAYERED_MANNEQUIN_DISPLAY_HEIGHT := PlaceholderCardRegistryScript.RUNTIME_MANNEQUIN_DISPLAY_HEIGHT

const NPC_ARM_CULL_DISTANCE_PX := 1400.0

var registry = PlaceholderCardRegistryScript.new()
var _idle_previews: Dictionary = {}
var _mannequin_layout_cache


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


func _eligible_for_layered_mannequin_body(entity: Node) -> bool:
	if entity == null or not is_instance_valid(entity):
		return false
	if not uses_placeholder_cards(entity):
		return false
	if entity.is_in_group("player"):
		return true
	var scr: Variant = entity.get_script()
	if scr is Script and str((scr as Script).resource_path).ends_with("player.gd"):
		return true
	var nt: Variant = entity.get("npc_type")
	return nt != null and str(nt) in PROCEDURAL_MANNEQUIN_NPC_TYPES


func uses_procedural_mannequin(entity: Node) -> bool:
	return PROCEDURAL_MANNEQUIN_ENABLED_IN_GAME and _eligible_for_layered_mannequin_body(entity)


## Gameplay: body+head layers + floating weapon overlay (no procedural arms).
func uses_layered_body_mannequin(entity: Node) -> bool:
	return not PROCEDURAL_MANNEQUIN_ENABLED_IN_GAME and _eligible_for_layered_mannequin_body(entity)


func uses_legacy_baked_card(entity: Node) -> bool:
	if entity == null or not is_instance_valid(entity):
		return false
	var nt: Variant = entity.get("npc_type")
	return nt != null and str(nt) in LEGACY_BAKED_CARD_NPC_TYPES


func apply_to_npc(npc: Node) -> void:
	if npc == null or not is_instance_valid(npc):
		return
	if not uses_placeholder_cards(npc):
		return
	if uses_procedural_mannequin(npc):
		var card_index: int = _resolve_card_index(npc, true)
		_apply_procedural_mannequin(npc, card_index)
		return
	if uses_layered_body_mannequin(npc):
		var card_index: int = _resolve_card_index(npc, true)
		_apply_layered_body_mannequin(npc, card_index)
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
	var tex: Texture2D = null
	if uses_procedural_mannequin(entity) or uses_layered_body_mannequin(entity):
		tex = PartsRegistry.load_blank_body()
	elif sprite and sprite.texture:
		tex = sprite.texture
	if tex:
		if uses_layered_body_mannequin(entity):
			y = registry.get_runtime_mannequin_progress_display_y(tex)
		else:
			y = registry.get_progress_display_y(tex)
	var progress: Variant = entity.get("progress_display")
	if progress is Node2D:
		(progress as Node2D).position = Vector2(0.0, y)
	var eat_progress: Variant = entity.get("eat_progress_display")
	if eat_progress is Node2D:
		(eat_progress as Node2D).position = Vector2(0.0, y)


func apply_to_player(player: Node) -> void:
	if player == null or not is_instance_valid(player):
		return
	var card_index: int = _resolve_card_index(player, false)
	if uses_procedural_mannequin(player):
		_apply_procedural_mannequin(player, card_index)
		return
	if uses_layered_body_mannequin(player):
		_apply_layered_body_mannequin(player, card_index)
		return
	var sprite: Sprite2D = player.get_node_or_null("Sprite") as Sprite2D
	if sprite == null:
		return
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
	if WeaponOverlayCombat.get_overlay_state(npc) == WeaponOverlayCombat.OverlayState.STRIKING:
		npc.set("_card_bounce_moving", moving)
		return
	var sprite: Sprite2D = npc.get_node_or_null("Sprite") as Sprite2D
	if sprite == null:
		return
	if uses_procedural_mannequin(npc) or uses_layered_body_mannequin(npc):
		_tick_layered_body_mannequin(npc, sprite, delta, moving)
		return
	if sprite.texture == null:
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
	var swing_delta := Vector2.ZERO
	var weapon_type: ResourceData.ResourceType = ResourceData.ResourceType.NONE
	if entity.has_method("get_equipped_weapon_type"):
		weapon_type = entity.get_equipped_weapon_type()
	if entity.get("_card_bounce_moving") == true:
		var bounce_time: float = float(entity.get("_card_bounce_time")) if entity.get("_card_bounce_time") != null else 0.0
		bounce_y = CardVisualController.weapon_overlay_walk_bounce_offset_y(bounce_time, true)
		if weapon_type == ResourceData.ResourceType.SPEAR and LimbPresetRegistry != null and uses_procedural_mannequin(entity):
			var preset := LimbPresetRegistry.get_preset(weapon_type, "clansmen_1")
			if preset != null:
				CardVisualController.sync_weapon_overlay_flip(
					sprite, overlay, base_offset, mirror_tex, bounce_y, Vector2.ZERO
				)
				_apply_spear_overlay_walk_sway(entity, sprite, overlay, preset, bounce_time)
				return
		var shoulder := Vector2.ZERO
		if LimbPresetRegistry != null and weapon_type != ResourceData.ResourceType.NONE:
			var preset := LimbPresetRegistry.get_preset(weapon_type, "clansmen_1")
			if preset != null:
				shoulder = preset.shoulder_offset_px
		swing_delta = CardVisualController.walk_weapon_overlay_sway_delta_display(
			sprite, base_offset, shoulder, bounce_time, true
		)
	CardVisualController.sync_weapon_overlay_flip(sprite, overlay, base_offset, mirror_tex, bounce_y, swing_delta)


func _apply_spear_overlay_walk_sway(
	entity: Node,
	sprite: Sprite2D,
	overlay: Sprite2D,
	preset: WeaponLimbPreset,
	bounce_time: float
) -> void:
	## Move spear art with the grip point (same WalkArmSwing path as the tuner).
	if overlay == null or preset == null:
		return
	var rig := entity as Node2D
	if rig == null:
		return
	var grip_px := preset.hand_grip_offset_px
	var grip_local := Vector2(grip_px.x * overlay.scale.x, grip_px.y * overlay.scale.y)
	var rest_grip_global := overlay.to_global(grip_local)
	var body_visual: Node2D = sprite.get_node_or_null("BodyVisual") as Node2D
	var shoulder_global := MannequinAnchorResolverScript.shoulder_global_from_display(
		sprite, body_visual, preset.shoulder_offset_px
	)
	var travel_sign := 1.0
	if entity is CharacterBody2D:
		var vel := (entity as CharacterBody2D).velocity
		if absf(vel.x) > 1.0:
			travel_sign = signf(vel.x)
	elif sprite.flip_h:
		travel_sign = -1.0
	var swung_global := MannequinPoseRuntimeScript._apply_walk_swing_global(
		rig,
		shoulder_global,
		rest_grip_global,
		bounce_time,
		true,
		travel_sign,
		ResourceData.ResourceType.SPEAR
	)
	overlay.global_position += swung_global - rest_grip_global


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
		_sync_procedural_arm_process(entity)
		return
	var tex: Texture2D = registry.get_tool_overlay(weapon_type)
	if tex == null:
		overlay.visible = false
		_sync_procedural_arm_process(entity)
		return
	overlay.texture = tex
	# Body sprite is already card-scaled in apply_card_layout; large overlays match that grid.
	var overlay_scale: float = (
		registry.get_runtime_tool_overlay_scale(weapon_type)
		if uses_layered_body_mannequin(entity)
		else registry.get_tool_overlay_scale(weapon_type)
	)
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
	if uses_procedural_mannequin(entity):
		_apply_overlay_combat_pose(entity, weapon_type, overlay)
		_sync_procedural_arm_process(entity)
		return
	var base_offset: Vector2 = _overlay_local_offset(sprite, _effective_overlay_offset_px(entity, weapon_type))
	if uses_layered_body_mannequin(entity):
		_disable_procedural_arms(entity)
	overlay.set_meta("card_overlay_offset", base_offset)
	CardVisualController.sync_weapon_overlay_flip(sprite, overlay, base_offset)
	_apply_overlay_combat_pose(entity, weapon_type, overlay)
	_sync_procedural_arm_process(entity)


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
	if uses_procedural_mannequin(entity):
		_apply_overlay_combat_pose(entity, weapon_type, overlay, aim_dir)
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
	var combat_recovery_d: float = float(profile.get("combat_recovery_duration", 0.12))
	var combat_recovery_ready_d: float = float(profile.get("combat_recovery_duration_ready", combat_recovery_d))
	var strike_done := func() -> void:
		if not entity or not is_instance_valid(entity):
			return
		# Strike tween already retracts to ready — extra recovery poses caused visible bounce.
		WeaponOverlayCombat.set_overlay_state(entity, WeaponOverlayCombat.OverlayState.READY)
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


func _apply_overlay_combat_pose(
	entity: Node,
	weapon_type: ResourceData.ResourceType,
	overlay: Sprite2D,
	aim_override: Vector2 = Vector2.INF
) -> void:
	if entity == null or overlay == null:
		return
	var sprite: Sprite2D = entity.get_node_or_null("Sprite") as Sprite2D
	if sprite == null:
		return
	var ostate: int = WeaponOverlayCombat.get_overlay_state(entity)
	if ostate == WeaponOverlayCombat.OverlayState.STRIKING:
		return
	if uses_procedural_mannequin(entity):
		var preset: WeaponLimbPreset = _mannequin_limb_preset(weapon_type)
		if preset != null:
			var aim: Vector2 = _resolve_overlay_aim(entity, aim_override)
			match ostate:
				WeaponOverlayCombat.OverlayState.READY:
					MannequinPoseRuntimeScript.apply_ready_overlay(
						sprite, overlay, registry, preset, weapon_type, aim, entity
					)
				WeaponOverlayCombat.OverlayState.RECOVERING:
					if WeaponOverlayCombat.should_hold_weapon_ready(entity):
						MannequinPoseRuntimeScript.apply_ready_overlay(
							sprite, overlay, registry, preset, weapon_type, aim, entity
						)
					else:
						MannequinPoseRuntimeScript.apply_idle_overlay(
							sprite, overlay, registry, preset, weapon_type, entity
						)
				_:
					MannequinPoseRuntimeScript.apply_idle_overlay(
						sprite, overlay, registry, preset, weapon_type, entity
					)
					WeaponOverlayCombat.set_overlay_state(entity, WeaponOverlayCombat.OverlayState.IDLE)
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


func _mannequin_limb_preset(weapon_type: ResourceData.ResourceType) -> WeaponLimbPreset:
	if LimbPresetRegistry == null:
		return null
	return LimbPresetRegistry.get_preset(weapon_type, "clansmen_1")


func _resolve_overlay_aim(entity: Node, aim_override: Vector2) -> Vector2:
	if aim_override != Vector2.INF and aim_override.length_squared() > 0.0001:
		return aim_override.normalized()
	if entity.get("aim_dir") != null:
		var aim: Vector2 = entity.get("aim_dir") as Vector2
		if aim.length_squared() > 0.0001:
			return aim.normalized()
	if entity.get("last_facing") != null:
		var facing: Vector2 = entity.get("last_facing") as Vector2
		if facing.length_squared() > 0.0001:
			return facing.normalized()
	return Vector2(1, 0)


func _effective_overlay_offset_px(entity: Node, weapon_type: ResourceData.ResourceType) -> Vector2:
	var offset_px: Vector2
	if LimbPresetRegistry:
		offset_px = LimbPresetRegistry.get_overlay_offset_idle_px(weapon_type)
	else:
		offset_px = registry.get_tool_overlay_offset_px(weapon_type)
	return offset_px * get_runtime_display_scale(entity)


func get_runtime_display_scale(entity: Node) -> float:
	if uses_layered_body_mannequin(entity):
		return registry.get_runtime_mannequin_display_scale()
	return 1.0


func _runtime_layered_mannequin_layout(card_index: int):
	var layout = TunerMannequinLayoutScript.from_registry(registry, card_index)
	layout.display_height = RUNTIME_LAYERED_MANNEQUIN_DISPLAY_HEIGHT
	layout.sprite_scale = layout.display_height / layout.ref_texture_height
	layout.foot_y = -layout.display_height * 0.5
	return layout


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
			var card_index: int = _resolve_card_index(npc, true)
			npc.set("card_index", card_index)
			npc.set_meta("card_index", card_index)
			return registry.get_clansmen_card(card_index)
		_:
			return null


func _resolve_card_index(entity: Node, allow_npc_rng: bool) -> int:
	var card_index: int = 0
	if entity.has_meta("card_index"):
		card_index = int(entity.get_meta("card_index"))
	if card_index <= 0 and entity.get("card_index") != null:
		card_index = int(entity.get("card_index"))
	if card_index <= 0:
		if allow_npc_rng and entity.has_method("npc_randi_range"):
			card_index = entity.npc_randi_range(1, registry.CLANSMEN_CARD_COUNT)
		else:
			card_index = randi_range(1, registry.CLANSMEN_CARD_COUNT)
	entity.set("card_index", card_index)
	entity.set_meta("card_index", card_index)
	return card_index


func _apply_procedural_mannequin(entity: Node, card_index: int) -> void:
	var sprite: Sprite2D = entity.get_node_or_null("Sprite") as Sprite2D
	if sprite == null:
		return
	entity.set("card_index", card_index)
	entity.set_meta("card_index", card_index)
	var layout = TunerMannequinLayoutScript.from_registry(registry, card_index)
	sprite.texture = null
	sprite.region_enabled = false
	sprite.hframes = 1
	sprite.vframes = 1
	sprite.frame = 0
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	sprite.scale = Vector2.ONE * layout.sprite_scale
	var foot_y: float = layout.foot_y
	sprite.position = Vector2(0.0, foot_y)
	entity.set("_card_foot_y", foot_y)
	_ensure_procedural_rig(entity)
	var body_visual: Node = sprite.get_node_or_null("BodyVisual")
	if body_visual and body_visual.has_method("apply_layout"):
		body_visual.call("apply_layout", layout)
	if body_visual and body_visual.has_method("apply_runtime_draw_layers"):
		body_visual.call("apply_runtime_draw_layers")
	if body_visual and body_visual.has_method("sync_head_draw_transform"):
		body_visual.call("sync_head_draw_transform")
	var arm_ctrl: Node = entity.get_node_or_null("ProceduralArmController")
	if arm_ctrl:
		arm_ctrl.set("body_card_id", "clansmen_1")
	if entity.has_method("_store_sprite_base_position"):
		entity._store_sprite_base_position()
	elif "_sprite_base_position" in entity:
		entity.set("_sprite_base_position", sprite.position)
	if entity.get("npc_type") != null:
		_apply_skin_modulate(entity)
	sync_progress_display_position(entity)
	var preview = _get_idle_preview(entity)
	preview.set_playing(true)
	preview.reset()
	_sync_procedural_arm_process(entity)


func _apply_layered_body_mannequin(entity: Node, card_index: int) -> void:
	var sprite: Sprite2D = entity.get_node_or_null("Sprite") as Sprite2D
	if sprite == null:
		return
	entity.set("card_index", card_index)
	entity.set_meta("card_index", card_index)
	var layout = _runtime_layered_mannequin_layout(card_index)
	sprite.texture = null
	sprite.region_enabled = false
	sprite.hframes = 1
	sprite.vframes = 1
	sprite.frame = 0
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	sprite.scale = Vector2.ONE * layout.sprite_scale
	var foot_y: float = layout.foot_y
	sprite.position = Vector2(0.0, foot_y)
	entity.set("_card_foot_y", foot_y)
	_ensure_body_visual_rig(entity)
	_disable_procedural_arms(entity)
	var body_visual: Node = sprite.get_node_or_null("BodyVisual")
	if body_visual and body_visual.has_method("apply_layout"):
		body_visual.call("apply_layout", layout)
	if body_visual and body_visual.has_method("apply_runtime_draw_layers"):
		body_visual.call("apply_runtime_draw_layers")
	if body_visual and body_visual.has_method("sync_head_draw_transform"):
		body_visual.call("sync_head_draw_transform")
	if entity.has_method("_store_sprite_base_position"):
		entity._store_sprite_base_position()
	elif "_sprite_base_position" in entity:
		entity.set("_sprite_base_position", sprite.position)
	if entity.get("npc_type") != null:
		_apply_skin_modulate(entity)
	sync_progress_display_position(entity)
	var preview = _get_idle_preview(entity)
	preview.set_playing(true)
	preview.reset()


func _disable_procedural_arms(entity: Node) -> void:
	var arm_ctrl: Node = entity.get_node_or_null("ProceduralArmController")
	if arm_ctrl == null:
		return
	arm_ctrl.set("enabled", false)
	arm_ctrl.set("force_show_arms", false)
	arm_ctrl.set_process(false)
	if arm_ctrl.has_method("_set_arms_visible"):
		arm_ctrl.call("_set_arms_visible", false)


func _ensure_body_visual_rig(entity: Node) -> void:
	var sprite: Sprite2D = entity.get_node_or_null("Sprite") as Sprite2D
	if sprite == null:
		return
	var body_visual: Node = sprite.get_node_or_null("BodyVisual")
	if body_visual == null:
		body_visual = TunerBodyVisualScript.new()
		body_visual.name = "BodyVisual"
		sprite.add_child(body_visual)
	var overlay: Sprite2D = sprite.get_node_or_null("WeaponOverlay") as Sprite2D
	if overlay:
		overlay.z_as_relative = true
		overlay.z_index = TunerBodyVisualScript.WEAPON_DRAW_Z_INDEX
		sprite.move_child(overlay, -1)


func _sync_procedural_arm_process(entity: Node) -> void:
	if not uses_procedural_mannequin(entity):
		return
	var arm_ctrl: Node = entity.get_node_or_null("ProceduralArmController")
	if arm_ctrl == null:
		return
	var sprite: Sprite2D = entity.get_node_or_null("Sprite") as Sprite2D
	if sprite == null:
		arm_ctrl.set_process(false)
		return
	var overlay: Sprite2D = sprite.get_node_or_null("WeaponOverlay") as Sprite2D
	var weapon_type: ResourceData.ResourceType = ResourceData.ResourceType.NONE
	if entity.has_method("get_equipped_weapon_type"):
		weapon_type = entity.get_equipped_weapon_type()
	elif entity.get("_equipped_item") != null:
		weapon_type = entity.get("_equipped_item") as ResourceData.ResourceType
	var show_arms := (
		overlay != null
		and overlay.visible
		and (
			weapon_type == ResourceData.ResourceType.SPEAR
			or weapon_type == ResourceData.ResourceType.WOOD
		)
	)
	if arm_ctrl.get("force_show_arms") == true:
		show_arms = true
	show_arms = _should_process_procedural_arms(entity, show_arms)
	arm_ctrl.set_process(show_arms)


func _should_process_procedural_arms(entity: Node, show_arms: bool) -> bool:
	if not show_arms:
		return false
	if entity.is_in_group("player"):
		return true
	if not (entity is Node2D):
		return show_arms
	var tree := entity.get_tree()
	if tree == null:
		return show_arms
	var player := tree.get_first_node_in_group("player") as Node2D
	if player == null or not is_instance_valid(player):
		return show_arms
	var cull_sq: float = NPC_ARM_CULL_DISTANCE_PX * NPC_ARM_CULL_DISTANCE_PX
	return (entity as Node2D).global_position.distance_squared_to(player.global_position) <= cull_sq


func _ensure_procedural_rig(entity: Node) -> void:
	_ensure_body_visual_rig(entity)
	var arm_ctrl: Node = entity.get_node_or_null("ProceduralArmController")
	if arm_ctrl == null:
		arm_ctrl = ProceduralArmControllerScript.new()
		arm_ctrl.name = "ProceduralArmController"
		arm_ctrl.use_tuner_arm_layers = true
		arm_ctrl.body_card_id = "clansmen_1"
		entity.add_child(arm_ctrl)
	elif arm_ctrl.get("use_tuner_arm_layers") != true:
		arm_ctrl.set("use_tuner_arm_layers", true)
		if arm_ctrl.has_method("initialize_tuner_arm_layers"):
			arm_ctrl.initialize_tuner_arm_layers()
	elif arm_ctrl.has_method("is_tuner_arm_layers_ready") and not arm_ctrl.is_tuner_arm_layers_ready():
		arm_ctrl.initialize_tuner_arm_layers()
	if arm_ctrl:
		arm_ctrl.set("body_card_id", "clansmen_1")


func _tick_layered_body_mannequin(entity: Node, sprite: Sprite2D, delta: float, moving: bool) -> void:
	var foot_y: float = float(entity.get("_card_foot_y")) if entity.get("_card_foot_y") != null else -PlaceholderCardRegistryScript.RUNTIME_MANNEQUIN_DISPLAY_HEIGHT * 0.5
	var bounce_time: float = float(entity.get("_card_bounce_time")) if entity.get("_card_bounce_time") != null else 0.0
	var body_visual: Node = sprite.get_node_or_null("BodyVisual")
	var card_index: int = get_card_index_from_entity(entity)
	if card_index <= 0:
		card_index = 1
	var layout = _get_mannequin_layout(card_index)
	var direction: int = -1 if sprite.flip_h else 1
	if moving:
		bounce_time = CardVisualController.tick_walk_bounce(sprite, foot_y, bounce_time, true, delta)
		var preview = _get_idle_preview(entity)
		preview.reset()
		if body_visual and body_visual.has_method("set_walk_state"):
			body_visual.call("set_walk_state", true, bounce_time, direction)
		if uses_procedural_mannequin(entity):
			_sync_mannequin_weapon_overlay_bounce(entity, sprite, layout, true, bounce_time, preview)
		else:
			entity.set("_card_bounce_time", bounce_time)
			entity.set("_card_bounce_moving", true)
			sync_weapon_overlay_flip(entity)
			entity.set("_card_bounce_moving", moving)
	else:
		bounce_time = 0.0
		sprite.position.y = roundf(foot_y)
		var preview = _get_idle_preview(entity)
		preview.tick(delta)
		var body_amp: float = layout.display_to_local(TunerIdlePreviewScript.BODY_BOUNCE_DISPLAY_PX)
		var head_amp: float = layout.display_to_local(TunerIdlePreviewScript.HEAD_BOB_DISPLAY_PX)
		sprite.position.y = roundf(foot_y + preview.body_bounce_offset(body_amp))
		var look_right: bool = not sprite.flip_h
		if body_visual and body_visual.has_method("set_idle_state"):
			body_visual.call(
				"set_idle_state",
				preview.head_bob_offset(head_amp),
				preview.body_sway_rad(),
				look_right
			)
		if uses_procedural_mannequin(entity):
			_sync_mannequin_weapon_overlay_bounce(entity, sprite, layout, false, bounce_time, preview)
		else:
			entity.set("_card_bounce_time", bounce_time)
			entity.set("_card_bounce_moving", false)
			sync_weapon_overlay_flip(entity)
	if uses_procedural_mannequin(entity):
		_sync_procedural_arm_process(entity)
	entity.set("_card_bounce_time", bounce_time)
	entity.set("_card_bounce_moving", moving)


func _get_mannequin_layout(card_index: int):
	if not PROCEDURAL_MANNEQUIN_ENABLED_IN_GAME:
		return _runtime_layered_mannequin_layout(card_index)
	if _mannequin_layout_cache == null:
		_mannequin_layout_cache = TunerMannequinLayoutScript.from_registry(registry, card_index)
	return _mannequin_layout_cache


func _get_idle_preview(entity: Node):
	var key: int = entity.get_instance_id()
	if not _idle_previews.has(key):
		var preview = TunerIdlePreviewScript.new()
		preview.set_playing(true)
		_idle_previews[key] = preview
		var exit_key := key
		entity.tree_exiting.connect(func() -> void:
			_idle_previews.erase(exit_key)
		)
	return _idle_previews[key]


func _sync_mannequin_head_draw(body_visual: Node) -> void:
	if body_visual and body_visual.has_method("sync_head_draw_transform"):
		body_visual.call("sync_head_draw_transform")


func _sync_mannequin_weapon_overlay_bounce(
	entity: Node,
	sprite: Sprite2D,
	layout,
	moving: bool,
	bounce_time: float,
	preview
) -> void:
	if entity == null or sprite == null:
		return
	var overlay: Sprite2D = sprite.get_node_or_null("WeaponOverlay") as Sprite2D
	if overlay == null or not overlay.visible:
		return
	if WeaponOverlayCombat.get_overlay_state(entity) == WeaponOverlayCombat.OverlayState.STRIKING:
		return
	var base_offset: Vector2 = overlay.get_meta("card_overlay_offset", Vector2.ZERO)
	var bounce_y: float = 0.0
	if moving:
		bounce_y = CardVisualController.weapon_overlay_walk_bounce_offset_y(bounce_time, true)
	elif preview != null:
		var weapon_amp: float = layout.display_to_local(TunerIdlePreviewScript.WEAPON_EXTRA_BOUNCE_DISPLAY_PX)
		bounce_y = preview.weapon_bounce_offset(weapon_amp)
	var weapon_type: ResourceData.ResourceType = ResourceData.ResourceType.NONE
	if entity.has_method("get_equipped_weapon_type"):
		weapon_type = entity.get_equipped_weapon_type()
	elif entity.get("_equipped_item") != null:
		weapon_type = entity.get("_equipped_item") as ResourceData.ResourceType
	var mirror_tex: bool = true
	if weapon_type != ResourceData.ResourceType.NONE:
		mirror_tex = WeaponOverlayCombat.uses_overlay_texture_mirror(registry, weapon_type)
	if moving and weapon_type == ResourceData.ResourceType.SPEAR and LimbPresetRegistry != null and uses_procedural_mannequin(entity):
		var spear_preset := LimbPresetRegistry.get_preset(weapon_type, "clansmen_1")
		if spear_preset != null:
			CardVisualController.sync_weapon_overlay_flip(
				sprite, overlay, base_offset, mirror_tex, bounce_y, Vector2.ZERO
			)
			_apply_spear_overlay_walk_sway(entity, sprite, overlay, spear_preset, bounce_time)
			return
	var swing_delta := Vector2.ZERO
	if moving and weapon_type == ResourceData.ResourceType.WOOD and LimbPresetRegistry != null:
		var club_preset := LimbPresetRegistry.get_preset(weapon_type, "clansmen_1")
		if club_preset != null:
			swing_delta = CardVisualController.walk_weapon_overlay_sway_delta_display(
				sprite, base_offset, club_preset.shoulder_offset_px, bounce_time, true
			)
	CardVisualController.sync_weapon_overlay_flip(sprite, overlay, base_offset, mirror_tex, bounce_y, swing_delta)


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
