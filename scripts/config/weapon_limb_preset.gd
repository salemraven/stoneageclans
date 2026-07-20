extends Resource
class_name WeaponLimbPreset

## Saved limb + weapon placement for one body card + weapon combo (display pixels, pre-scale).

@export var weapon_type: ResourceData.ResourceType = ResourceData.ResourceType.SPEAR
@export var body_card_id: String = "clansmen_1"
@export var body_card_index: int = 1

## Red shoulder — attachment on body card (offset from sprite origin).
@export var shoulder_offset_px: Vector2 = Vector2.ZERO

## Green hand — primary grip on weapon overlay (overlay-local px). Idle + general.
@export var hand_grip_offset_px: Vector2 = Vector2(0.0, 72.0)
## Dominant hand on spear in ready/attack (overlay-local px). Zero = use hand_grip_offset_px.
@export var hand_grip_ready_offset_px: Vector2 = Vector2.ZERO

## Off-hand shoulder on body card (display px, pre-flip).
@export var support_shoulder_offset_px: Vector2 = Vector2(-18.0, -20.0)
## Off-hand at rest in idle — on body, not on spear (sprite display px, pre-flip).
@export var support_hand_idle_offset_px: Vector2 = Vector2(-12.0, 30.0)
## Off-hand grip on spear in ready/attack (overlay-local px).
@export var support_hand_offset_px: Vector2 = Vector2(6.0, 52.0)

## Spear overlay idle placement (offset from body sprite origin, pre-flip display px).
@export var overlay_offset_idle_px: Vector2 = Vector2(22.0, -34.0)
@export var idle_rotation_deg: float = 0.0

## Spear overlay ready placement (combat profile overrides).
@export var ready_offset_px: Vector2 = Vector2(8.0, 6.0)
@export var ready_forward_px: float = 24.0

## IK segment lengths (display px).
@export var upper_arm_length: float = 24.0
@export var lower_arm_length: float = 22.0
@export var elbow_hint_outward: float = 18.0

## IK pole targets (body display px). Zero = auto elbow_hint_outward.
@export var weapon_elbow_pole_idle_px: Vector2 = Vector2.ZERO
@export var weapon_elbow_pole_ready_px: Vector2 = Vector2.ZERO
@export var support_elbow_pole_idle_px: Vector2 = Vector2.ZERO
@export var support_elbow_pole_ready_px: Vector2 = Vector2.ZERO

## Legacy — no longer used; presets are always 1:1 game display px. Kept for old .tres files.
@export var tuner_stage_scale: float = 1.0


static func uses_two_hand_grip(weapon_type: ResourceData.ResourceType) -> bool:
	return weapon_type == ResourceData.ResourceType.SPEAR


func resolve_elbow_pole_px(dominant: bool, ready_pose: bool) -> Vector2:
	if dominant:
		return weapon_elbow_pole_ready_px if ready_pose else weapon_elbow_pole_idle_px
	return support_elbow_pole_ready_px if ready_pose else support_elbow_pole_idle_px


func set_elbow_pole_px(dominant: bool, ready_pose: bool, display_px: Vector2) -> void:
	if dominant:
		if ready_pose:
			weapon_elbow_pole_ready_px = display_px
		else:
			weapon_elbow_pole_idle_px = display_px
	else:
		if ready_pose:
			support_elbow_pole_ready_px = display_px
		else:
			support_elbow_pole_idle_px = display_px


static func compute_auto_elbow_pole_px(
	shoulder_px: Vector2,
	hand_px: Vector2,
	outward: float,
	bend_sign: float
) -> Vector2:
	var to_hand := hand_px - shoulder_px
	if to_hand.length_squared() < 0.01:
		to_hand = Vector2(0.0, 1.0)
	var outward_dir := Vector2(-to_hand.y, to_hand.x).normalized() * signf(bend_sign)
	return shoulder_px + outward_dir * outward


func resolve_hand_grip_ready_px() -> Vector2:
	if hand_grip_ready_offset_px.length_squared() > 0.0001:
		return hand_grip_ready_offset_px
	return hand_grip_offset_px


func duplicate_preset() -> WeaponLimbPreset:
	var copy: WeaponLimbPreset = duplicate(true) as WeaponLimbPreset
	return copy


func to_export_dict() -> Dictionary:
	return {
		"weapon_type": weapon_type,
		"body_card_id": body_card_id,
		"body_card_index": body_card_index,
		"shoulder_offset_px": shoulder_offset_px,
		"hand_grip_offset_px": hand_grip_offset_px,
		"hand_grip_ready_offset_px": hand_grip_ready_offset_px,
		"support_shoulder_offset_px": support_shoulder_offset_px,
		"support_hand_idle_offset_px": support_hand_idle_offset_px,
		"support_hand_offset_px": support_hand_offset_px,
		"overlay_offset_idle_px": overlay_offset_idle_px,
		"idle_rotation_deg": idle_rotation_deg,
		"ready_offset_px": ready_offset_px,
		"ready_forward_px": ready_forward_px,
		"upper_arm_length": upper_arm_length,
		"lower_arm_length": lower_arm_length,
		"elbow_hint_outward": elbow_hint_outward,
		"weapon_elbow_pole_idle_px": weapon_elbow_pole_idle_px,
		"weapon_elbow_pole_ready_px": weapon_elbow_pole_ready_px,
		"support_elbow_pole_idle_px": support_elbow_pole_idle_px,
		"support_elbow_pole_ready_px": support_elbow_pole_ready_px,
		"tuner_stage_scale": tuner_stage_scale,
	}


static func defaults_for(weapon_type: ResourceData.ResourceType, body_index: int = 1) -> WeaponLimbPreset:
	var p := WeaponLimbPreset.new()
	p.weapon_type = weapon_type
	p.body_card_id = "clansmen_%d" % body_index
	p.body_card_index = body_index
	var registry = PlaceholderCardRegistry.new()
	if registry.TOOL_OVERLAY_OFFSET_PX.has(weapon_type):
		p.overlay_offset_idle_px = registry.get_tool_overlay_offset_px(weapon_type)
	var profile: Dictionary = registry.get_weapon_combat_profile(weapon_type)
	if profile.has("ready_offset_px"):
		p.ready_offset_px = profile["ready_offset_px"] as Vector2
	if profile.has("ready_forward_px"):
		p.ready_forward_px = float(profile["ready_forward_px"])
	if profile.has("idle_rotation_deg"):
		p.idle_rotation_deg = float(profile["idle_rotation_deg"])
	p.support_hand_idle_offset_px = Vector2(-12.0, 30.0)
	p.tuner_stage_scale = 1.0
	return p
