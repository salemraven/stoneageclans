extends Node
class_name WeaponComponent

# Weapon Component - tracks equipped weapon, damage bonuses
# Axe sprite shown only when hostile or defending. Club (WOOD) shown only when aggro, defense, or combat.

var npc: NPCBase = null
var equipped_weapon: ResourceData.ResourceType = ResourceData.ResourceType.NONE
var weapon_damage_bonus: int = 0  # Axe +0 (base damage is 10, so 3 hits = 30 HP)

const NORMAL_SPRITE_PATH := "res://assets/sprites/PlayerB.png"
const AXE_SPRITE_PATH := "res://assets/sprites/male1a.png"
var _tex_normal: Texture2D = null
var _tex_axe: Texture2D = null
var _last_show_axe: bool = false  # Avoid redundant texture swaps
var _last_show_club: bool = false

func initialize(npc_ref: NPCBase) -> void:
	npc = npc_ref
	set_process(true)

## Returns true when club should be visible (agro, hostile, defending, combat, or follow_ordered).
func should_show_club() -> bool:
	if not npc or equipped_weapon != ResourceData.ResourceType.WOOD:
		return false
	var is_agro: bool = npc.get("is_agro") if npc.get("is_agro") != null else false
	var hostile: bool = npc.get("is_hostile") if npc.get("is_hostile") != null else false
	var dt = npc.get("defend_target")
	var defending: bool = dt != null and is_instance_valid(dt) if dt is Object else false
	var combat_comp = npc.get_node_or_null("CombatComponent")
	var in_combat: bool = combat_comp and combat_comp.state != CombatComponent.CombatState.IDLE if combat_comp else false
	var follow_ordered: bool = npc.get("follow_is_ordered") if npc.get("follow_is_ordered") != null else false
	return is_agro or hostile or defending or in_combat or follow_ordered

func equip_weapon(weapon_type: ResourceData.ResourceType) -> void:
	equipped_weapon = weapon_type
	
	# Calculate damage bonus
	match weapon_type:
		ResourceData.ResourceType.AXE:
			weapon_damage_bonus = 0  # Axe doesn't add bonus, base damage is 10
		ResourceData.ResourceType.PICK:
			weapon_damage_bonus = 0  # Pick doesn't add bonus for now
		ResourceData.ResourceType.WOOD:
			weapon_damage_bonus = 0  # Club (wood in slot 1)
		_:
			weapon_damage_bonus = 0
	
	# Don't change sprite here — axe visible only when hostile or defend (_process)

func _process(_delta: float) -> void:
	_update_weapon_visibility()

func _update_weapon_visibility() -> void:
	if not npc or not is_instance_valid(npc):
		return
	
	# CRITICAL: Don't override corpse sprite if NPC is dead
	var health_comp = npc.get_node_or_null("HealthComponent") if npc else null
	var is_dead: bool = false
	if health_comp and health_comp.has_method("get") and health_comp.get("is_dead") != null:
		is_dead = health_comp.is_dead
	elif npc and npc.has_meta("is_dead"):
		is_dead = npc.get_meta("is_dead", false)
	
	if is_dead:
		# NPC is dead - don't change sprite, keep corpse sprite
		return
	
	# Don't overwrite crafting sprite (knapp.png)
	if npc.get("is_crafting") == true:
		return
	
	# Don't overwrite combat animation (WINDUP/RECOVERY use AtlasTexture)
	var combat: CombatComponent = npc.get_node_or_null("CombatComponent")
	if combat and combat.state != CombatComponent.CombatState.IDLE:
		return
	# Don't overwrite walk spritesheet animation
	if npc.get("is_walking_animation") == true:
		return

	var sprite: Sprite2D = npc.get_node_or_null("Sprite")
	if not sprite:
		return
	
	var show_axe: bool = false
	var show_club: bool = false
	if equipped_weapon == ResourceData.ResourceType.WOOD:
		var is_agro: bool = npc.get("is_agro") if npc.get("is_agro") != null else false
		var hostile: bool = npc.get("is_hostile") if npc.get("is_hostile") != null else false
		var dt = npc.get("defend_target")
		var defending: bool = dt != null and is_instance_valid(dt) if dt is Object else false
		var combat_comp = npc.get_node_or_null("CombatComponent")
		var in_combat: bool = combat_comp and combat_comp.state != CombatComponent.CombatState.IDLE if combat_comp else false
		var follow_ordered: bool = npc.get("follow_is_ordered") if npc.get("follow_is_ordered") != null else false
		show_club = (is_agro or hostile or defending or in_combat or follow_ordered)
	elif equipped_weapon == ResourceData.ResourceType.AXE:
		var hostile: bool = npc.get("is_hostile") if npc.get("is_hostile") != null else false
		var dt = npc.get("defend_target")
		var defending: bool = dt != null and is_instance_valid(dt) if dt is Object else false
		show_axe = hostile or defending
	
	if show_axe == _last_show_axe and show_club == _last_show_club:
		return
	_last_show_axe = show_axe
	_last_show_club = show_club
	
	if show_club:
		WalkAnimation.apply_club_idle(sprite)
		if npc.has_method("apply_sprite_offset_for_texture"):
			npc.apply_sprite_offset_for_texture()
		return
	if show_axe:
		if _tex_axe == null:
			_tex_axe = load(AXE_SPRITE_PATH) as Texture2D
		if _tex_axe:
			sprite.texture = _tex_axe
			sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
			if npc.has_method("apply_sprite_offset_for_texture"):
				npc.apply_sprite_offset_for_texture()
		return
	# Default idle: walk.png or womanwalk.png by NPC type
	var npc_type_str: String = npc.get("npc_type") if npc.get("npc_type") != null else ""
	if npc_type_str == "woman":
		WalkAnimation.apply_woman_idle(sprite)
	else:
		WalkAnimation.apply_walk_idle(sprite)
	if npc.has_method("apply_sprite_offset_for_texture"):
		npc.apply_sprite_offset_for_texture()

# Alias for CombatComponent restore-from-weapon fallback (IDLE/cancel)
func _update_sprite_with_weapon() -> void:
	_update_weapon_visibility()

## Call when NPC stops walking so idle texture (male1/male1a) is restored.
func force_apply_idle() -> void:
	if not npc or not is_instance_valid(npc):
		return
	if npc.get("is_crafting") == true:
		return  # Don't overwrite knapp sprite
	var health_comp = npc.get_node_or_null("HealthComponent")
	if health_comp and health_comp.get("is_dead") and health_comp.is_dead:
		return
	var sprite: Sprite2D = npc.get_node_or_null("Sprite")
	if not sprite:
		return
	if _tex_normal == null:
		_tex_normal = load(NORMAL_SPRITE_PATH) as Texture2D
	if _tex_axe == null:
		_tex_axe = load(AXE_SPRITE_PATH) as Texture2D
	var show_axe: bool = false
	var show_club: bool = false
	if equipped_weapon == ResourceData.ResourceType.WOOD:
		var is_agro: bool = npc.get("is_agro") if npc.get("is_agro") != null else false
		var hostile = npc.get("is_hostile") if npc.get("is_hostile") != null else false
		var dt = npc.get("defend_target")
		var defending = dt != null and is_instance_valid(dt) if dt is Object else false
		var combat_comp = npc.get_node_or_null("CombatComponent")
		var in_combat: bool = combat_comp and combat_comp.state != CombatComponent.CombatState.IDLE if combat_comp else false
		var follow_ordered: bool = npc.get("follow_is_ordered") if npc.get("follow_is_ordered") != null else false
		show_club = (is_agro or hostile or defending or in_combat or follow_ordered)
	elif equipped_weapon == ResourceData.ResourceType.AXE:
		var hostile = npc.get("is_hostile") if npc.get("is_hostile") != null else false
		var dt = npc.get("defend_target")
		var defending = dt != null and is_instance_valid(dt) if dt is Object else false
		show_axe = hostile or defending
	if show_club:
		WalkAnimation.apply_club_idle(sprite)
		_last_show_club = true
		_last_show_axe = false
		if npc.has_method("apply_sprite_offset_for_texture"):
			npc.apply_sprite_offset_for_texture()
		return
	if show_axe:
		if _tex_axe == null:
			_tex_axe = load(AXE_SPRITE_PATH) as Texture2D
		if _tex_axe:
			sprite.texture = _tex_axe
			sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
			_last_show_axe = true
			_last_show_club = false
			if npc.has_method("apply_sprite_offset_for_texture"):
				npc.apply_sprite_offset_for_texture()
		return
	var npc_type_str: String = npc.get("npc_type") if npc.get("npc_type") != null else ""
	if npc_type_str == "woman":
		WalkAnimation.apply_woman_idle(sprite)
	else:
		WalkAnimation.apply_walk_idle(sprite)
	_last_show_axe = false
	_last_show_club = false
	if npc.has_method("apply_sprite_offset_for_texture"):
		npc.apply_sprite_offset_for_texture()

func get_damage_bonus() -> int:
	return weapon_damage_bonus
