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

## Legacy — no longer used; presets are always 1:1 game display px. Kept for old .tres files.
@export var tuner_stage_scale: float = 1.0


static func uses_two_hand_grip(weapon_type: ResourceData.ResourceType) -> bool:
	return weapon_type == ResourceData.ResourceType.SPEAR


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
