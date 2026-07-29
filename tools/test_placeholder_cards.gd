extends SceneTree
# Headless placeholder card layout + spawn helper verification.
#
# SKIP_SINGLE_INSTANCE=1 godot --headless --path . --script res://tools/test_placeholder_cards.gd

# Load at runtime so dependent scripts (EntityRegistry, etc.) compile after autoloads init.
const NPC_SCENE_PATH := "res://scenes/NPC.tscn"
const PLAYER_SCENE_PATH := "res://scenes/Player.tscn"
const PartsRegistry = preload("res://scripts/config/character_card_parts_registry.gd")
const MANNEQUIN_TARGET_HEIGHT := 56.0
const CARD_TARGET_HEIGHT := 128.0
const FOOT_Y_TOLERANCE := 1.5


func _init() -> void:
	call_deferred("_run")


func _fail(msg: String) -> void:
	push_error("TEST_PLACEHOLDER_CARDS_FAIL: %s" % msg)
	quit(1)


func _assert_near(actual: float, expected: float, label: String) -> void:
	if absf(actual - expected) > FOOT_Y_TOLERANCE:
		_fail("%s expected %.2f got %.2f" % [label, expected, actual])


func _expected_foot_y(texture: Texture2D, display_height: float = CARD_TARGET_HEIGHT) -> float:
	if texture == null:
		_fail("texture is null")
	var scale := display_height / float(texture.get_height())
	return -(texture.get_height() * scale * 0.5)


func _mannequin_body_tex() -> Texture2D:
	var tex: Texture2D = PartsRegistry.load_blank_body()
	if tex == null:
		_fail("body1.png failed to load")
	return tex


func _count_head_pivots(sprite: Sprite2D) -> int:
	if sprite == null:
		return 0
	var count := 0
	for child in sprite.get_children():
		if child.name == "HeadPivot":
			count += 1
	return count


func _assert_layered_body_mannequin(entity: Node, sprite: Sprite2D, label: String) -> void:
	if sprite == null:
		_fail("%s sprite missing" % label)
		return
	if sprite.texture != null:
		_fail("%s should use layered body+head (sprite.texture cleared)" % label)
	var head_count := _count_head_pivots(sprite)
	if head_count != 1:
		_fail("%s should have exactly 1 HeadPivot, got %d" % [label, head_count])
	var body_visual: Node = sprite.get_node_or_null("BodyVisual")
	if body_visual == null:
		_fail("%s BodyVisual missing" % label)
	var body_tex: Texture2D = _mannequin_body_tex()
	_assert_near(sprite.position.y, _expected_foot_y(body_tex, MANNEQUIN_TARGET_HEIGHT), "%s foot_y" % label)
	if absf(sprite.scale.y - (MANNEQUIN_TARGET_HEIGHT / float(body_tex.get_height()))) > 0.02:
		_fail("%s scale not 56px tall runtime mannequin layout" % label)
	var arm_ctrl: Node = entity.get_node_or_null("ProceduralArmController")
	if arm_ctrl != null and arm_ctrl.is_processing():
		_fail("%s ProceduralArmController should not run in game" % label)


func _texture_path(texture: Texture2D) -> String:
	if texture == null:
		return ""
	return texture.resource_path


func _run() -> void:
	await process_frame
	var root_node := get_root()
	var svc = root_node.get_node_or_null("/root/PlaceholderCardService")
	if svc == null:
		_fail("PlaceholderCardService autoload missing")

	var registry = svc.registry
	if registry == null:
		_fail("registry missing")

	var clansmen_tex: Texture2D = registry.get_clansmen_card(1)
	if clansmen_tex == null:
		_fail("clansmen_card1 failed to load")
	if not _texture_path(clansmen_tex).contains("placeholder_cards"):
		_fail("clansmen card path wrong: %s" % _texture_path(clansmen_tex))

	var woman_tex: Texture2D = registry.get_woman_card()
	if woman_tex == null:
		_fail("woman_card failed to load")

	var npc_scene: PackedScene = load(NPC_SCENE_PATH) as PackedScene
	var player_scene: PackedScene = load(PLAYER_SCENE_PATH) as PackedScene
	if npc_scene == null or player_scene == null:
		_fail("NPC or Player scene failed to load")

	# Player
	var player: Node = player_scene.instantiate()
	if player == null:
		_fail("Player instantiate failed")
	root_node.add_child(player)
	await process_frame
	svc.apply_to_player(player)
	svc.apply_to_player(player)
	var player_sprite: Sprite2D = player.get_node_or_null("Sprite") as Sprite2D
	_assert_layered_body_mannequin(player, player_sprite, "player")
	if not svc.uses_layered_body_mannequin(player):
		_fail("player should use layered body mannequin in game")
	if svc.uses_procedural_mannequin(player):
		_fail("player should not use procedural arms in game")

	# Caveman NPC
	var caveman: Node = npc_scene.instantiate()
	if caveman == null:
		_fail("NPC instantiate failed")
	caveman.set("npc_type", "caveman")
	caveman.set("npc_name", "TEST_CAVE")
	root_node.add_child(caveman)
	await process_frame
	svc.apply_to_npc(caveman)
	var cave_sprite: Sprite2D = caveman.get_node_or_null("Sprite") as Sprite2D
	_assert_layered_body_mannequin(caveman, cave_sprite, "caveman")
	var card_index: int = int(caveman.get("card_index"))
	if card_index < 1 or card_index > 18:
		_fail("caveman card_index out of range: %d" % card_index)

	# Woman NPC
	var woman: Node = npc_scene.instantiate()
	woman.set("npc_type", "woman")
	woman.set("npc_name", "TEST_WOMAN")
	root_node.add_child(woman)
	await process_frame
	svc.apply_to_npc(woman)
	var woman_sprite: Sprite2D = woman.get_node_or_null("Sprite") as Sprite2D
	if woman_sprite == null or woman_sprite.texture == null:
		_fail("woman sprite/texture missing")
	_assert_near(woman_sprite.position.y, _expected_foot_y(woman_sprite.texture), "woman foot_y")
	if not _texture_path(woman_sprite.texture).contains("woman_card"):
		_fail("woman card path wrong: %s" % _texture_path(woman_sprite.texture))

	# WeaponOverlay child exists
	var overlay: Node = cave_sprite.get_node_or_null("WeaponOverlay")
	if overlay == null:
		_fail("WeaponOverlay missing on NPC Sprite")
	var weapon_comp: Node = caveman.get_node_or_null("WeaponComponent")
	if weapon_comp and weapon_comp.has_method("equip_weapon"):
		weapon_comp.equip_weapon(ResourceData.ResourceType.SPEAR)
	caveman.set("is_hostile", true)
	await process_frame
	var overlay_sprite: Sprite2D = overlay as Sprite2D
	if overlay_sprite == null or not overlay_sprite.visible:
		_fail("WeaponOverlay not visible on caveman with spear + hostile")
	if overlay_sprite.texture == null:
		_fail("WeaponOverlay texture missing for spear")
	if not _texture_path(overlay_sprite.texture).contains("spear.png"):
		_fail("WeaponOverlay texture wrong: %s" % _texture_path(overlay_sprite.texture))

	if player.has_method("set_equipment"):
		player.set_equipment(ResourceData.ResourceType.SPEAR)
	await process_frame
	var player_overlay: Sprite2D = player_sprite.get_node_or_null("WeaponOverlay") as Sprite2D
	if player_overlay == null or not player_overlay.visible:
		_fail("Player WeaponOverlay not visible with spear equipped")
	if player_overlay.texture == null or not _texture_path(player_overlay.texture).contains("spear.png"):
		_fail("Player WeaponOverlay texture wrong: %s" % _texture_path(player_overlay.texture if player_overlay.texture else null))
	# Spear PNG is authored vertical; idle overlay must not apply a bogus -90° on top.
	if absf(player_overlay.rotation) > 0.05:
		_fail("Player spear idle rotation should be ~0 got %.3f rad" % player_overlay.rotation)
	const WeaponOverlayCombat = preload("res://scripts/systems/weapon_overlay_combat.gd")
	WeaponOverlayCombat.apply_ready_pose(player_sprite, player_overlay, registry, ResourceData.ResourceType.SPEAR, Vector2(1, 0))
	if player_sprite.flip_h:
		_fail("Spear aim-right should not flip card")
	var ready_right: float = player_overlay.rotation
	if absf(ready_right - PI * 0.5) > 0.15:
		_fail("Spear ready-right rotation expected ~90° got %.1f°" % rad_to_deg(ready_right))
	WeaponOverlayCombat.apply_ready_pose(player_sprite, player_overlay, registry, ResourceData.ResourceType.SPEAR, Vector2(-1, 0))
	if not player_sprite.flip_h:
		_fail("Spear aim-left should flip card to face left")
	var ready_left: float = player_overlay.rotation
	if absf(ready_left + PI * 0.5) > 0.2 and absf(ready_left - PI * 1.5) > 0.2:
		_fail("Spear ready-left rotation expected ~-90° got %.1f°" % rad_to_deg(ready_left))
	player_sprite.flip_h = false
	var delta_right_u: Vector2 = WeaponOverlayCombat._aim_delta_local(player_sprite, Vector2(1, 0), 50.0)
	var delta_left_u: Vector2 = WeaponOverlayCombat._aim_delta_local(player_sprite, Vector2(-1, 0), 50.0)
	if delta_right_u.x <= 0.0:
		_fail("Thrust delta aim-right should extend +local X")
	if delta_left_u.x >= 0.0:
		_fail("Thrust delta aim-left should extend -local X")
	var spear_profile: Dictionary = registry.get_weapon_combat_profile(ResourceData.ResourceType.SPEAR)
	var ready_px: Vector2 = spear_profile.get("ready_offset_px", Vector2.ZERO) as Vector2
	var strike_px: Vector2 = spear_profile.get("strike_offset_px", Vector2.ZERO) as Vector2
	var spear_ready_base: Vector2 = WeaponOverlayCombat._pose_offset(
		player_sprite, registry, ResourceData.ResourceType.SPEAR, spear_profile, true
	)
	var ready_pos: Vector2 = WeaponOverlayCombat._flipped_position(player_sprite, spear_ready_base)
	var extend_dist: float = ready_px.distance_to(strike_px)
	var sx: float = maxf(absf(player_sprite.scale.x), 0.001)
	var runtime_mul: float = svc.get_runtime_display_scale(player)
	var expected_local_extend: float = extend_dist * runtime_mul / sx
	var strike_right: Vector2 = WeaponOverlayCombat.compute_tuned_thrust_strike_pos(
		player_sprite, ready_pos, ready_px, strike_px, Vector2(1.0, 0.0)
	)
	if absf(strike_right.distance_to(ready_pos) - expected_local_extend) > 1.5:
		_fail("Tuned thrust right should extend by preset distance")
	if strike_right.x <= ready_pos.x + 5.0:
		_fail("Tuned thrust right should move overlay right from ready")
	var min_horiz: float = float(spear_profile.get("thrust_min_horizontal_frac", 0.35))
	var clamped_up: Vector2 = WeaponOverlayCombat.clamp_thrust_aim(
		Vector2(0.0, -1.0), registry, ResourceData.ResourceType.SPEAR, 1.0
	)
	var clamped_down: Vector2 = WeaponOverlayCombat.clamp_thrust_aim(
		Vector2(0.0, 1.0), registry, ResourceData.ResourceType.SPEAR, -1.0
	)
	if absf(clamped_up.x) < min_horiz - 0.02:
		_fail("Spear thrust should block straight up (min horizontal)")
	if absf(clamped_down.x) < min_horiz - 0.02:
		_fail("Spear thrust should block straight down (min horizontal)")
	if clamped_up.y >= -0.05:
		_fail("Clamped up thrust should still point upward")
	if clamped_down.y <= 0.05:
		_fail("Clamped down thrust should still point downward")
	player_sprite.flip_h = false
	WeaponOverlayCombat.apply_idle_pose(player_sprite, player_overlay, registry, ResourceData.ResourceType.SPEAR)
	if absf(player_overlay.rotation) > 0.05:
		_fail("Spear should return to idle 0° after apply_idle_pose")

	# Club: idle vertical, ready cocks back (+), pivot at handle (bottom of texture).
	if player.has_method("set_equipment"):
		player.set_equipment(ResourceData.ResourceType.WOOD)
	await process_frame
	svc.sync_weapon_overlay(player, ResourceData.ResourceType.WOOD, true)
	var club_overlay: Sprite2D = player_sprite.get_node_or_null("WeaponOverlay") as Sprite2D
	if club_overlay == null or club_overlay.texture == null:
		_fail("Club WeaponOverlay missing")
	var wood_profile: Dictionary = registry.get_weapon_combat_profile(ResourceData.ResourceType.WOOD)
	WeaponOverlayCombat.apply_idle_pose(player_sprite, club_overlay, registry, ResourceData.ResourceType.WOOD)
	if absf(club_overlay.rotation) > 0.05:
		_fail("Club idle rotation should be ~0 got %.1f°" % rad_to_deg(club_overlay.rotation))
	var club_h: float = float(club_overlay.texture.get_height()) * absf(club_overlay.scale.y)
	if club_overlay.offset.y >= 0.0:
		_fail("Club pivot offset should be negative (handle at node origin)")
	var pivot_y_frac: float = clampf(float(wood_profile.get("pivot_y_frac", 0.88)), 0.0, 1.0)
	var expected_pivot_y: float = (0.5 - pivot_y_frac) * club_h
	if absf(club_overlay.offset.y - expected_pivot_y) > club_h * 0.05:
		_fail("Club handle pivot offset wrong got %.1f expected ~%.1f" % [club_overlay.offset.y, expected_pivot_y])
	player_sprite.flip_h = false
	WeaponOverlayCombat.apply_ready_pose(player_sprite, club_overlay, registry, ResourceData.ResourceType.WOOD, Vector2(1, 0))
	if club_overlay.rotation >= 0.0:
		_fail("Club ready facing right should be ~-42° (10 o'clock) got %.1f°" % rad_to_deg(club_overlay.rotation))
	if club_overlay.flip_h:
		_fail("Club overlay should not mirror texture on swing weapons")
	player_sprite.flip_h = true
	WeaponOverlayCombat.apply_ready_pose(player_sprite, club_overlay, registry, ResourceData.ResourceType.WOOD, Vector2(-1, 0))
	if not player_sprite.flip_h:
		_fail("Club ready should keep movement flip_h when aim differs")
	if club_overlay.rotation <= 0.0:
		_fail("Club ready facing left should be ~+42° (2 o'clock) got %.1f°" % rad_to_deg(club_overlay.rotation))
	if club_overlay.flip_h:
		_fail("Club overlay should not mirror texture when facing left")

	var ready_base: Vector2 = WeaponOverlayCombat._pose_offset(
		player_sprite, registry, ResourceData.ResourceType.WOOD, wood_profile, true
	)
	player_sprite.flip_h = false
	var right_targets: Dictionary = WeaponOverlayCombat.compute_swing_strike_targets(
		player_sprite, ready_base, wood_profile
	)
	if right_targets["windup_pos"].y >= right_targets["ready_pos"].y:
		_fail("Club windup facing right should move up (lower Y)")
	if right_targets["hit_pos"].y <= right_targets["ready_pos"].y:
		_fail("Club hit facing right should move down (higher Y)")
	if right_targets["hit_pos"].x <= right_targets["ready_pos"].x:
		_fail("Club hit facing right should lunge forward (+X)")
	if right_targets["windup_pos"].x >= right_targets["ready_pos"].x:
		_fail("Club windup facing right should pull back (-X)")
	if right_targets["windup_rot"] >= right_targets["ready_rot"]:
		_fail("Club windup facing right should rotate further back (more negative)")
	if right_targets["end_rot"] <= right_targets["ready_rot"]:
		_fail("Club downswing facing right should rotate forward (more positive)")
	player_sprite.flip_h = true
	var left_targets: Dictionary = WeaponOverlayCombat.compute_swing_strike_targets(
		player_sprite, ready_base, wood_profile
	)
	if left_targets["windup_pos"].y >= left_targets["ready_pos"].y:
		_fail("Club windup facing left should move up (lower Y)")
	if left_targets["hit_pos"].y <= left_targets["ready_pos"].y:
		_fail("Club hit facing left should move down (higher Y)")
	if left_targets["hit_pos"].x >= left_targets["ready_pos"].x:
		_fail("Club hit facing left should lunge forward (-X)")
	if left_targets["windup_pos"].x <= left_targets["ready_pos"].x:
		_fail("Club windup facing left should pull back (+X)")
	if left_targets["windup_rot"] <= left_targets["ready_rot"]:
		_fail("Club windup facing left should rotate further back (mirrored +local)")
	if left_targets["end_rot"] >= left_targets["ready_rot"]:
		_fail("Club downswing facing left should rotate forward (mirrored -local)")

	# Son inherits father's card_index (player as father when father node is null)
	player.add_to_group("player")
	player.set_meta("card_index", 5)
	player.set("card_index", 5)
	svc.apply_to_player(player)
	var son: Node = npc_scene.instantiate()
	son.set("npc_type", "baby")
	son.set("npc_name", "TEST_SON")
	root_node.add_child(son)
	await process_frame
	svc.assign_inherited_card_index(son, player)
	var son_index: int = int(son.get("card_index"))
	if son_index != 5:
		_fail("son should inherit player card_index 5, got %d" % son_index)
	son.set("npc_type", "clansman")
	svc.apply_to_npc(son)
	var son_sprite: Sprite2D = son.get_node_or_null("Sprite") as Sprite2D
	_assert_layered_body_mannequin(son, son_sprite, "grown son")
	if int(son.get("card_index")) != 5:
		_fail("grown son should keep inherited card_index 5")

	player.queue_free()
	caveman.queue_free()
	woman.queue_free()
	son.queue_free()
	await process_frame

	print("TEST_PLACEHOLDER_CARDS_OK")
	quit(0)
