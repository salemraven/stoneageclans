extends Resource
class_name CharacterAnimationPose

## One static pose snapshot — every visible tuner pin for a single pose index.

const SelfScript = preload("res://scripts/config/character_animation_pose.gd")

@export var shoulder_weapon_px: Vector2 = Vector2.ZERO
@export var shoulder_support_px: Vector2 = Vector2(-18.0, -20.0)
@export var hand_weapon_px: Vector2 = Vector2(0.0, 72.0)
@export var hand_support_px: Vector2 = Vector2(-12.0, 30.0)
@export var elbow_weapon_bend_sign: float = 0.0
@export var elbow_support_bend_sign: float = 0.0
@export var overlay_offset_px: Vector2 = Vector2(22.0, -34.0)
const ROTATION_UNSET := -1000.0

@export var weapon_rotation_deg: float = ROTATION_UNSET
@export var head_offset_px: Vector2 = Vector2.ZERO
## Grip on weapon art (overlay-local). Zero = use weapon primary grip fallback.
@export var grip_on_art_px: Vector2 = Vector2.ZERO
## Tuner size slider. 0 means unset. 1 is the small handheld rock.
@export var overlay_scale_mul: float = 0.0


func resolved_shoulder_weapon_px(preset) -> Vector2:
	if preset != null and shoulder_weapon_px.length_squared() < 0.0001:
		return preset.shoulder_offset_px
	return shoulder_weapon_px


func resolved_shoulder_support_px(preset) -> Vector2:
	if preset == null:
		return shoulder_support_px
	if shoulder_support_px.length_squared() < 0.0001:
		return preset.support_shoulder_offset_px
	# Factory pose default (-18,-20) is not a tuned clansmen anchor — inherit morph.
	if (
		shoulder_weapon_px.length_squared() < 0.0001
		and shoulder_support_px.distance_to(Vector2(-18.0, -20.0)) < 0.05
	):
		return preset.support_shoulder_offset_px
	return shoulder_support_px


func duplicate_pose():
	var copy = SelfScript.new()
	copy.shoulder_weapon_px = shoulder_weapon_px
	copy.shoulder_support_px = shoulder_support_px
	copy.hand_weapon_px = hand_weapon_px
	copy.hand_support_px = hand_support_px
	copy.elbow_weapon_bend_sign = elbow_weapon_bend_sign
	copy.elbow_support_bend_sign = elbow_support_bend_sign
	copy.overlay_offset_px = overlay_offset_px
	copy.weapon_rotation_deg = weapon_rotation_deg
	copy.head_offset_px = head_offset_px
	copy.grip_on_art_px = grip_on_art_px
	copy.overlay_scale_mul = overlay_scale_mul
	return copy


func lerp_to(other, t: float) -> Resource:
	return lerp_to_blend(other, _smoothstep01(t))


func lerp_to_blend(other, blend: float) -> Resource:
	var eased := clampf(blend, 0.0, 1.0)
	var out = SelfScript.new()
	out.shoulder_weapon_px = shoulder_weapon_px.lerp(other.shoulder_weapon_px, eased)
	out.shoulder_support_px = shoulder_support_px.lerp(other.shoulder_support_px, eased)
	out.hand_weapon_px = hand_weapon_px.lerp(other.hand_weapon_px, eased)
	out.hand_support_px = hand_support_px.lerp(other.hand_support_px, eased)
	out.elbow_weapon_bend_sign = _lerp_bend_sign(
		elbow_weapon_bend_sign, other.elbow_weapon_bend_sign, eased
	)
	out.elbow_support_bend_sign = _lerp_bend_sign(
		elbow_support_bend_sign, other.elbow_support_bend_sign, eased
	)
	out.overlay_offset_px = overlay_offset_px.lerp(other.overlay_offset_px, eased)
	out.weapon_rotation_deg = lerpf(weapon_rotation_deg, other.weapon_rotation_deg, eased)
	out.head_offset_px = head_offset_px.lerp(other.head_offset_px, eased)
	out.grip_on_art_px = grip_on_art_px.lerp(other.grip_on_art_px, eased)
	out.overlay_scale_mul = lerpf(overlay_scale_mul, other.overlay_scale_mul, eased)
	return out


static func _smoothstep01(t: float) -> float:
	t = clampf(t, 0.0, 1.0)
	return t * t * (3.0 - 2.0 * t)


static func _lerp_bend_sign(a: float, b: float, t: float) -> float:
	if signf(a) == signf(b) or absf(a) < 0.001 or absf(b) < 0.001:
		return a if t < 0.5 else b
	return a if t < 0.5 else b
