extends Resource
class_name WeaponLimbPreset

## Saved limb + weapon placement for one body card + weapon combo (display pixels, pre-scale).

enum TunerAnimMode { IDLE, IDLE1, WALK, WALK1, GATHER1, ATTACK, IDLE_CLUB1 }


static func is_idle_mode(mode: TunerAnimMode) -> bool:
	return mode == TunerAnimMode.IDLE or mode == TunerAnimMode.IDLE1 or mode == TunerAnimMode.IDLE_CLUB1


static func is_idle_club_mode(mode: TunerAnimMode) -> bool:
	return mode == TunerAnimMode.IDLE_CLUB1


static func is_walk_mode(mode: TunerAnimMode) -> bool:
	return mode == TunerAnimMode.WALK or mode == TunerAnimMode.WALK1


static func is_gather_mode(mode: TunerAnimMode) -> bool:
	return mode == TunerAnimMode.GATHER1


static func idle_storage_mode(mode: TunerAnimMode) -> TunerAnimMode:
	return TunerAnimMode.IDLE


## --- Tuner snapshot routing (single source of truth) ---
## Each pose catalog row owns its preset fields. The tuner must READ/WRITE the active row only.
## Never redirect because another row "exists" (e.g. idle_club1 plausible ≠ use it for idle standing).
## Documented exception: club walk weapon arm borrows idle standing; support arm uses walk row.


static func tuner_overlay_storage_mode(
	active_mode: TunerAnimMode,
	weapon_type: ResourceData.ResourceType
) -> TunerAnimMode:
	if weapon_type == ResourceData.ResourceType.WOOD and is_walk_mode(active_mode):
		return TunerAnimMode.IDLE
	return active_mode


static func tuner_hand_grip_storage_mode(
	active_mode: TunerAnimMode,
	weapon_type: ResourceData.ResourceType
) -> TunerAnimMode:
	return tuner_overlay_storage_mode(active_mode, weapon_type)


static func tuner_elbow_storage_mode(
	active_mode: TunerAnimMode,
	weapon_type: ResourceData.ResourceType,
	dominant: bool
) -> TunerAnimMode:
	if weapon_type == ResourceData.ResourceType.WOOD and is_walk_mode(active_mode) and dominant:
		return TunerAnimMode.IDLE
	return active_mode


static func tuner_commit_storage_mode(active_mode: TunerAnimMode) -> TunerAnimMode:
	## Save always goes to the pose row you are editing — never a borrowed walk/idle row.
	return active_mode


func verify_tuner_overlay_matches(
	active_mode: TunerAnimMode,
	live_overlay_px: Vector2,
	slack_px: float = 2.5
) -> bool:
	var storage := tuner_overlay_storage_mode(active_mode, weapon_type)
	return live_overlay_px.distance_to(resolve_overlay_for_mode(storage)) <= slack_px

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
## Optional raised off-hand target for idle variety. Zero = no raise animation.
@export var support_hand_idle_raise_offset_px: Vector2 = Vector2.ZERO
## Off-hand grip on spear in ready/attack (overlay-local px).
@export var support_hand_offset_px: Vector2 = Vector2(6.0, 52.0)

## Spear overlay idle placement (offset from body sprite origin, pre-flip display px).
@export var overlay_offset_idle_px: Vector2 = Vector2(22.0, -34.0)
@export var idle_rotation_deg: float = 0.0

## Walk animation arm + overlay snapshot (tuner). Zero = fall back to idle fields on load.
@export var walk_hand_grip_offset_px: Vector2 = Vector2.ZERO
@export var walk_support_hand_offset_px: Vector2 = Vector2.ZERO
@export var walk_overlay_offset_px: Vector2 = Vector2.ZERO
@export var walk_weapon_elbow_pole_px: Vector2 = Vector2.ZERO
@export var walk_support_elbow_pole_px: Vector2 = Vector2.ZERO

## Walk 1 — saved walk animation snapshot (tuner + in-game walk rest pose when set).
@export var walk1_hand_grip_offset_px: Vector2 = Vector2.ZERO
@export var walk1_support_hand_offset_px: Vector2 = Vector2.ZERO
@export var walk1_overlay_offset_px: Vector2 = Vector2.ZERO
@export var walk1_weapon_elbow_pole_px: Vector2 = Vector2.ZERO
@export var walk1_support_elbow_pole_px: Vector2 = Vector2.ZERO
@export var walk1_weapon_elbow_bend_sign_override: float = 0.0
@export var walk1_support_elbow_bend_sign_override: float = 0.0

## Gather 1 — bend down + pull to body (tuner snapshot + in-game gather rest when set).
@export var gather1_hand_grip_offset_px: Vector2 = Vector2.ZERO
@export var gather1_support_hand_offset_px: Vector2 = Vector2.ZERO
@export var gather1_overlay_offset_px: Vector2 = Vector2.ZERO
@export var gather1_weapon_elbow_pole_px: Vector2 = Vector2.ZERO
@export var gather1_support_elbow_pole_px: Vector2 = Vector2.ZERO
@export var gather1_weapon_elbow_bend_sign_override: float = 0.0
@export var gather1_support_elbow_bend_sign_override: float = 0.0
## Pull-to-body keyframe (second gather pin set) — preview lerps reach → pull.
@export var gather1_pull_hand_grip_offset_px: Vector2 = Vector2.ZERO
@export var gather1_pull_support_hand_offset_px: Vector2 = Vector2.ZERO

## Idle Club 1 — standing idle with club (tuner snapshot + in-game when set).
@export var idle_club1_hand_grip_offset_px: Vector2 = Vector2.ZERO
@export var idle_club1_support_hand_offset_px: Vector2 = Vector2.ZERO
@export var idle_club1_overlay_offset_px: Vector2 = Vector2.ZERO
@export var idle_club1_weapon_elbow_pole_px: Vector2 = Vector2.ZERO
@export var idle_club1_support_elbow_pole_px: Vector2 = Vector2.ZERO
@export var idle_club1_weapon_elbow_bend_sign_override: float = 0.0
@export var idle_club1_support_elbow_bend_sign_override: float = 0.0
## Set when user saves Club grip / in-hand — grip-on-art must never be overwritten by heuristics.
@export var idle_club1_grip_authoritative: bool = false
## Club attack row: false = tuner + resolve use idle standing until user commits attack pose.
@export var club_attack_pose_saved: bool = false
## Spear attack windup row: false = inherit idle standing until user saves windup pose.
@export var spear_attack_pose_saved: bool = false

## Spear overlay ready placement (combat profile overrides).
@export var ready_offset_px: Vector2 = Vector2(8.0, 6.0)
## Spear thrust peak — max extension overlay (display px). Zero = use ready + thrust_extend_px.
@export var strike_offset_px: Vector2 = Vector2.ZERO
@export var ready_forward_px: float = 24.0

## IK segment lengths (display px).
@export var upper_arm_length: float = 120.0
@export var lower_arm_length: float = 120.0
## Per-arm overrides (display px). <= 0 uses shared upper_arm_length / lower_arm_length above.
@export var weapon_upper_arm_length: float = -1.0
@export var weapon_lower_arm_length: float = -1.0
@export var support_upper_arm_length: float = -1.0
@export var support_lower_arm_length: float = -1.0
@export var elbow_hint_outward: float = 18.0
## Line2D width at shoulder (display px). Hand end uses hand_width (taper).
@export var arm_width: float = 14.0
@export var hand_width: float = 10.0

## Tuner hard caps (display px) — both arms share upper_arm_length / lower_arm_length below.
const TUNER_MAX_UPPER_ARM_PX := 120.0
const TUNER_MAX_LOWER_ARM_PX := 120.0
const TUNER_MIN_SEGMENT_PX := 4.0
const TUNER_DEFAULT_ARM_WIDTH := 14.0
const TUNER_DEFAULT_HAND_WIDTH := 10.0
const TUNER_MIN_ARM_WIDTH := 2.0
const TUNER_MAX_ARM_WIDTH := 48.0
## Fixed IK bend direction per arm in tuner + game arms (no pole flip).
const DOMINANT_ELBOW_BEND_SIGN := 1.0
const SUPPORT_ELBOW_BEND_SIGN := 1.0

## IK pole targets (body display px). Zero = auto elbow_hint_outward.
@export var weapon_elbow_pole_idle_px: Vector2 = Vector2.ZERO
@export var weapon_elbow_pole_ready_px: Vector2 = Vector2.ZERO
@export var support_elbow_pole_idle_px: Vector2 = Vector2.ZERO
@export var support_elbow_pole_ready_px: Vector2 = Vector2.ZERO

## Tuner: 0 = elbow follows facing. ±1 = forced bend side (click 1e/2e to flip).
@export var weapon_elbow_bend_sign_override: float = 0.0
@export var support_elbow_bend_sign_override: float = 0.0
@export var support_elbow_bend_sign_raise_override: float = 0.0
@export var walk_weapon_elbow_bend_sign_override: float = 0.0
@export var walk_support_elbow_bend_sign_override: float = 0.0
@export var weapon_elbow_bend_sign_ready_override: float = 0.0
@export var support_elbow_bend_sign_ready_override: float = 0.0

## Legacy — no longer used; presets are always 1:1 game display px. Kept for old .tres files.
@export var tuner_stage_scale: float = 1.0


static func uses_two_hand_grip(weapon_type: ResourceData.ResourceType) -> bool:
	return weapon_type == ResourceData.ResourceType.SPEAR


func attack_pose_inherits_idle() -> bool:
	if weapon_type == ResourceData.ResourceType.WOOD:
		return not club_attack_pose_saved
	if weapon_type == ResourceData.ResourceType.SPEAR:
		return not spear_attack_pose_saved
	return false


func club_attack_inherits_idle() -> bool:
	return weapon_type == ResourceData.ResourceType.WOOD and attack_pose_inherits_idle()


func mark_attack_windup_pose_saved() -> void:
	if weapon_type == ResourceData.ResourceType.WOOD:
		club_attack_pose_saved = true
	elif weapon_type == ResourceData.ResourceType.SPEAR:
		spear_attack_pose_saved = true


func mark_club_attack_pose_saved() -> void:
	mark_attack_windup_pose_saved()


func resolve_elbow_pole_px(dominant: bool, ready_pose: bool) -> Vector2:
	if ready_pose and attack_pose_inherits_idle():
		ready_pose = false
	if dominant:
		return weapon_elbow_pole_ready_px if ready_pose else weapon_elbow_pole_idle_px
	return support_elbow_pole_ready_px if ready_pose else support_elbow_pole_idle_px


func resolve_elbow_pole_for_mode(dominant: bool, mode: TunerAnimMode) -> Vector2:
	if is_idle_club_mode(mode):
		var club_pole := idle_club1_weapon_elbow_pole_px if dominant else idle_club1_support_elbow_pole_px
		if club_pole.length_squared() > 0.0001:
			return club_pole
		return resolve_elbow_pole_px(dominant, false)
	if is_gather_mode(mode):
		var gather_pole := gather1_weapon_elbow_pole_px if dominant else gather1_support_elbow_pole_px
		if gather_pole.length_squared() > 0.0001:
			return gather_pole
		return resolve_elbow_pole_px(dominant, false)
	if is_walk_mode(mode):
		var walk_pole := _resolve_walk_elbow_pole_px(dominant, mode)
		if walk_pole.length_squared() > 0.0001:
			return walk_pole
		return resolve_elbow_pole_px(dominant, false)
	return resolve_elbow_pole_px(dominant, mode == TunerAnimMode.ATTACK)


func _resolve_walk_elbow_pole_px(dominant: bool, mode: TunerAnimMode) -> Vector2:
	if mode == TunerAnimMode.WALK1:
		return walk1_weapon_elbow_pole_px if dominant else walk1_support_elbow_pole_px
	return walk_weapon_elbow_pole_px if dominant else walk_support_elbow_pole_px


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


func set_elbow_pole_for_mode(dominant: bool, mode: TunerAnimMode, display_px: Vector2) -> void:
	if is_idle_club_mode(mode):
		if dominant:
			idle_club1_weapon_elbow_pole_px = display_px
		else:
			idle_club1_support_elbow_pole_px = display_px
		return
	if is_gather_mode(mode):
		if dominant:
			gather1_weapon_elbow_pole_px = display_px
		else:
			gather1_support_elbow_pole_px = display_px
		return
	if is_walk_mode(mode):
		if mode == TunerAnimMode.WALK1:
			if dominant:
				walk1_weapon_elbow_pole_px = display_px
			else:
				walk1_support_elbow_pole_px = display_px
		elif dominant:
			walk_weapon_elbow_pole_px = display_px
		else:
			walk_support_elbow_pole_px = display_px
		return
	set_elbow_pole_px(dominant, mode == TunerAnimMode.ATTACK, display_px)


func resolve_elbow_bend_sign_override(dominant: bool, mode: TunerAnimMode) -> float:
	if mode == TunerAnimMode.IDLE_CLUB1:
		return idle_club1_weapon_elbow_bend_sign_override if dominant else idle_club1_support_elbow_bend_sign_override
	if mode == TunerAnimMode.GATHER1:
		return gather1_weapon_elbow_bend_sign_override if dominant else gather1_support_elbow_bend_sign_override
	if mode == TunerAnimMode.WALK1:
		return walk1_weapon_elbow_bend_sign_override if dominant else walk1_support_elbow_bend_sign_override
	if mode == TunerAnimMode.WALK:
		return walk_weapon_elbow_bend_sign_override if dominant else walk_support_elbow_bend_sign_override
	if mode == TunerAnimMode.ATTACK:
		if attack_pose_inherits_idle():
			return weapon_elbow_bend_sign_override if dominant else support_elbow_bend_sign_override
		return weapon_elbow_bend_sign_ready_override if dominant else support_elbow_bend_sign_ready_override
	return weapon_elbow_bend_sign_override if dominant else support_elbow_bend_sign_override


func set_elbow_bend_sign_override(dominant: bool, mode: TunerAnimMode, sign: float) -> void:
	var forced := 0.0 if absf(sign) < 0.001 else signf(sign)
	if mode == TunerAnimMode.IDLE_CLUB1:
		if dominant:
			idle_club1_weapon_elbow_bend_sign_override = forced
		else:
			idle_club1_support_elbow_bend_sign_override = forced
	elif mode == TunerAnimMode.GATHER1:
		if dominant:
			gather1_weapon_elbow_bend_sign_override = forced
		else:
			gather1_support_elbow_bend_sign_override = forced
	elif mode == TunerAnimMode.WALK1:
		if dominant:
			walk1_weapon_elbow_bend_sign_override = forced
		else:
			walk1_support_elbow_bend_sign_override = forced
	elif mode == TunerAnimMode.WALK:
		if dominant:
			walk_weapon_elbow_bend_sign_override = forced
		else:
			walk_support_elbow_bend_sign_override = forced
	elif mode == TunerAnimMode.ATTACK:
		if dominant:
			weapon_elbow_bend_sign_ready_override = forced
		else:
			support_elbow_bend_sign_ready_override = forced
	elif dominant:
		weapon_elbow_bend_sign_override = forced
	else:
		support_elbow_bend_sign_override = forced


func resolve_elbow_bend_sign(dominant: bool, mode: TunerAnimMode, auto_from_facing: float) -> float:
	var override := resolve_elbow_bend_sign_override(dominant, mode)
	if absf(override) > 0.001:
		return signf(override)
	return auto_from_facing


func toggle_elbow_bend_sign(dominant: bool, mode: TunerAnimMode, auto_from_facing: float) -> float:
	var current := resolve_elbow_bend_sign(dominant, mode, auto_from_facing)
	var flipped := -current
	set_elbow_bend_sign_override(dominant, mode, flipped)
	return flipped


func resolve_hand_grip_for_mode(mode: TunerAnimMode) -> Vector2:
	match mode:
		TunerAnimMode.IDLE_CLUB1:
			if idle_club1_hand_grip_is_plausible():
				return idle_club1_hand_grip_offset_px
			return default_club_hand_grip_px()
		TunerAnimMode.GATHER1:
			if gather1_hand_grip_offset_px.length_squared() > 0.0001:
				return gather1_hand_grip_offset_px
			return hand_grip_offset_px
		TunerAnimMode.WALK, TunerAnimMode.WALK1:
			var walk_hand := (
				walk1_hand_grip_offset_px
				if mode == TunerAnimMode.WALK1
				else walk_hand_grip_offset_px
			)
			if walk_hand.length_squared() > 0.0001:
				return walk_hand
			return hand_grip_offset_px
		TunerAnimMode.ATTACK:
			return resolve_hand_grip_ready_px()
		_:
			return hand_grip_offset_px


## Club only: where the hand meets the club art (yellow grip pin).
## When idle_club1_grip_authoritative, user-tuned grip is law — never infer from (0,0) or texture anchor.
func uses_saved_club_grip_on_art() -> bool:
	return weapon_type == ResourceData.ResourceType.WOOD and idle_club1_grip_authoritative


func mark_club_grip_on_art_authoritative() -> void:
	if weapon_type == ResourceData.ResourceType.WOOD:
		idle_club1_grip_authoritative = true


func resolve_club_overlay_grip_px(mode: TunerAnimMode) -> Vector2:
	if weapon_type != ResourceData.ResourceType.WOOD:
		return resolve_hand_grip_for_mode(mode)
	if mode == TunerAnimMode.ATTACK:
		return resolve_hand_grip_for_mode(mode)
	if uses_saved_club_grip_on_art():
		return idle_club1_hand_grip_offset_px
	var row_grip := resolve_hand_grip_for_mode(mode)
	if row_grip.length_squared() > 0.0001:
		return row_grip
	if idle_club1_hand_grip_is_plausible():
		return idle_club1_hand_grip_offset_px
	return row_grip


func set_club_grip_on_art_from_overlay_px(grip_px: Vector2) -> void:
	idle_club1_hand_grip_offset_px = grip_px
	mark_club_grip_on_art_authoritative()


func set_hand_grip_for_mode(mode: TunerAnimMode, display_px: Vector2) -> void:
	match mode:
		TunerAnimMode.IDLE_CLUB1:
			idle_club1_hand_grip_offset_px = display_px
			mark_club_grip_on_art_authoritative()
		TunerAnimMode.GATHER1:
			gather1_hand_grip_offset_px = display_px
		TunerAnimMode.WALK:
			walk_hand_grip_offset_px = display_px
		TunerAnimMode.WALK1:
			walk1_hand_grip_offset_px = display_px
		TunerAnimMode.ATTACK:
			hand_grip_ready_offset_px = display_px
		_:
			if weapon_type == ResourceData.ResourceType.WOOD and display_px.length_squared() > 0.0001:
				idle_club1_hand_grip_offset_px = display_px
			hand_grip_offset_px = display_px


func resolve_support_hand_for_mode(mode: TunerAnimMode) -> Vector2:
	if mode == TunerAnimMode.ATTACK and uses_two_hand_grip(weapon_type):
		if attack_pose_inherits_idle():
			return support_hand_idle_offset_px
		return support_hand_offset_px
	if is_gather_mode(mode):
		if gather1_support_hand_offset_px.length_squared() > 0.0001:
			return gather1_support_hand_offset_px
		return support_hand_idle_offset_px
	if is_idle_club_mode(mode):
		if idle_club1_support_hand_offset_px.length_squared() > 0.0001:
			return idle_club1_support_hand_offset_px
		return support_hand_idle_offset_px
	if is_walk_mode(mode):
		var walk_hand := (
			walk1_support_hand_offset_px
			if mode == TunerAnimMode.WALK1
			else walk_support_hand_offset_px
		)
		if walk_hand.length_squared() > 0.0001:
			return walk_hand
		return support_hand_idle_offset_px
	if is_idle_mode(mode):
		return support_hand_idle_offset_px
	return support_hand_idle_offset_px


func resolve_support_hand_idle_rest_px() -> Vector2:
	return support_hand_idle_offset_px


func resolve_support_hand_idle_raised_px() -> Vector2:
	return support_hand_idle_raise_offset_px


func has_idle_arm2_raise_pose() -> bool:
	return support_hand_idle_raise_offset_px.length_squared() > 0.0001


func resolve_support_elbow_bend_sign_for_idle_raise(raise_blend: float, auto_from_facing: float) -> float:
	var rest_sign := resolve_elbow_bend_sign(false, TunerAnimMode.IDLE, auto_from_facing)
	if raise_blend <= 0.0001:
		return rest_sign
	var raise_sign := support_elbow_bend_sign_raise_override
	if absf(raise_sign) < 0.001:
		raise_sign = -rest_sign if absf(rest_sign) > 0.001 else -SUPPORT_ELBOW_BEND_SIGN
	else:
		raise_sign = signf(raise_sign)
	return raise_sign if raise_blend >= 0.5 else rest_sign


func set_support_hand_for_mode(mode: TunerAnimMode, display_px: Vector2) -> void:
	if mode == TunerAnimMode.ATTACK and uses_two_hand_grip(weapon_type):
		support_hand_offset_px = display_px
	elif is_gather_mode(mode):
		gather1_support_hand_offset_px = display_px
	elif is_idle_club_mode(mode):
		idle_club1_support_hand_offset_px = display_px
	elif is_walk_mode(mode):
		if mode == TunerAnimMode.WALK1:
			walk1_support_hand_offset_px = display_px
		else:
			walk_support_hand_offset_px = display_px
	else:
		support_hand_idle_offset_px = display_px

func resolve_overlay_for_mode(mode: TunerAnimMode) -> Vector2:
	match mode:
		TunerAnimMode.IDLE_CLUB1:
			if idle_club1_overlay_is_plausible():
				return idle_club1_overlay_offset_px
			if overlay_offset_idle_px.distance_to(default_club_overlay_offset_px()) <= 80.0:
				return overlay_offset_idle_px
			return default_club_overlay_offset_px()
		TunerAnimMode.GATHER1:
			if gather1_overlay_offset_px.length_squared() > 0.0001:
				return gather1_overlay_offset_px
			return overlay_offset_idle_px
		TunerAnimMode.WALK, TunerAnimMode.WALK1:
			var walk_overlay := (
				walk1_overlay_offset_px
				if mode == TunerAnimMode.WALK1
				else walk_overlay_offset_px
			)
			if walk_overlay.length_squared() > 0.0001:
				return walk_overlay
			return overlay_offset_idle_px
		TunerAnimMode.ATTACK:
			if weapon_type == ResourceData.ResourceType.SPEAR and spear_attack_pose_saved:
				if strike_offset_px.length_squared() > 0.0001:
					return strike_offset_px
			if attack_pose_inherits_idle():
				return overlay_offset_idle_px
			return ready_offset_px
		_:
			return overlay_offset_idle_px


func set_overlay_for_mode(mode: TunerAnimMode, display_px: Vector2) -> void:
	match mode:
		TunerAnimMode.IDLE_CLUB1:
			idle_club1_overlay_offset_px = display_px
		TunerAnimMode.GATHER1:
			gather1_overlay_offset_px = display_px
		TunerAnimMode.WALK:
			walk_overlay_offset_px = display_px
		TunerAnimMode.WALK1:
			walk1_overlay_offset_px = display_px
		TunerAnimMode.ATTACK:
			if weapon_type == ResourceData.ResourceType.SPEAR:
				strike_offset_px = display_px
			else:
				ready_offset_px = display_px
		_:
			overlay_offset_idle_px = display_px


func seed_walk_from_idle_if_unset() -> void:
	if walk_hand_grip_offset_px.length_squared() < 0.0001:
		walk_hand_grip_offset_px = hand_grip_offset_px
	if walk_support_hand_offset_px.length_squared() < 0.0001:
		walk_support_hand_offset_px = support_hand_idle_offset_px
	if walk_overlay_offset_px.length_squared() < 0.0001:
		walk_overlay_offset_px = overlay_offset_idle_px
	if walk_weapon_elbow_pole_px.length_squared() < 0.0001:
		walk_weapon_elbow_pole_px = weapon_elbow_pole_idle_px
	if walk_support_elbow_pole_px.length_squared() < 0.0001:
		walk_support_elbow_pole_px = support_elbow_pole_idle_px


func seed_walk1_from_walk_if_unset() -> void:
	if walk1_hand_grip_offset_px.length_squared() > 0.0001:
		return
	copy_walk_pose_to_walk1()


func copy_walk_pose_to_walk1() -> void:
	seed_walk_from_idle_if_unset()
	walk1_hand_grip_offset_px = walk_hand_grip_offset_px
	walk1_support_hand_offset_px = walk_support_hand_offset_px
	walk1_overlay_offset_px = walk_overlay_offset_px
	walk1_weapon_elbow_pole_px = walk_weapon_elbow_pole_px
	walk1_support_elbow_pole_px = walk_support_elbow_pole_px
	walk1_weapon_elbow_bend_sign_override = walk_weapon_elbow_bend_sign_override
	walk1_support_elbow_bend_sign_override = walk_support_elbow_bend_sign_override


func seed_gather1_from_idle_if_unset() -> void:
	if gather1_hand_grip_offset_px.length_squared() > 0.0001:
		return
	gather1_hand_grip_offset_px = hand_grip_offset_px + Vector2(8.0, 42.0)
	gather1_support_hand_offset_px = support_hand_idle_offset_px + Vector2(-8.0, 42.0)
	gather1_overlay_offset_px = overlay_offset_idle_px
	gather1_weapon_elbow_pole_px = weapon_elbow_pole_idle_px
	gather1_support_elbow_pole_px = support_elbow_pole_idle_px
	gather1_weapon_elbow_bend_sign_override = weapon_elbow_bend_sign_override
	gather1_support_elbow_bend_sign_override = support_elbow_bend_sign_override


func seed_idle_club1_from_idle_if_unset() -> void:
	if not idle_club1_needs_reseed():
		return
	idle_club1_overlay_offset_px = default_club_overlay_offset_px()
	idle_club1_hand_grip_offset_px = default_club_hand_grip_px()
	idle_club1_support_hand_offset_px = support_hand_idle_offset_px
	idle_club1_weapon_elbow_pole_px = weapon_elbow_pole_idle_px
	idle_club1_support_elbow_pole_px = support_elbow_pole_idle_px
	idle_club1_weapon_elbow_bend_sign_override = weapon_elbow_bend_sign_override
	idle_club1_support_elbow_bend_sign_override = support_elbow_bend_sign_override


func apply_shared_body_from_none(none: WeaponLimbPreset) -> void:
	if none == null:
		return
	shoulder_offset_px = none.shoulder_offset_px
	support_shoulder_offset_px = none.support_shoulder_offset_px
	support_hand_idle_offset_px = none.support_hand_idle_offset_px
	weapon_elbow_pole_idle_px = none.weapon_elbow_pole_idle_px
	support_elbow_pole_idle_px = none.support_elbow_pole_idle_px
	weapon_elbow_bend_sign_override = none.weapon_elbow_bend_sign_override
	support_elbow_bend_sign_override = none.support_elbow_bend_sign_override
	upper_arm_length = none.upper_arm_length
	lower_arm_length = none.lower_arm_length
	arm_width = none.arm_width
	hand_width = none.hand_width
	elbow_hint_outward = none.elbow_hint_outward


func apply_idle_club1_body_from_none(none: WeaponLimbPreset) -> void:
	if none == null:
		return
	apply_shared_body_from_none(none)
	idle_club1_support_hand_offset_px = none.support_hand_idle_offset_px
	idle_club1_weapon_elbow_pole_px = none.weapon_elbow_pole_idle_px
	idle_club1_support_elbow_pole_px = none.support_elbow_pole_idle_px
	idle_club1_weapon_elbow_bend_sign_override = none.weapon_elbow_bend_sign_override
	idle_club1_support_elbow_bend_sign_override = none.support_elbow_bend_sign_override


static func default_club_overlay_offset_px() -> Vector2:
	return Vector2(22.0, -34.0)


static func default_club_handle_grip_px() -> Vector2:
	## Handle pivot = overlay node origin after combat pivot setup.
	return Vector2.ZERO


static func default_club_hand_grip_px() -> Vector2:
	## ~58 px up the shaft from handle pivot (negative Y toward club head).
	return Vector2(0.0, -58.0)


static func default_spear_hand_grip_px() -> Vector2:
	## Tuned on clansmen_1 @ overlay scale 1.52 — yellow/green grip on shaft (overlay-local px).
	return Vector2(4.966575, 101.0588)


static func default_spear_overlay_idle_px() -> Vector2:
	return Vector2(63.5, -116.0)


static func apply_default_spear_idle_pose(p: WeaponLimbPreset) -> void:
	if p == null or p.weapon_type != ResourceData.ResourceType.SPEAR:
		return
	p.hand_grip_offset_px = default_spear_hand_grip_px()
	p.overlay_offset_idle_px = default_spear_overlay_idle_px()
	p.weapon_elbow_pole_idle_px = Vector2(110.2281, -162.7713)
	p.support_elbow_pole_idle_px = Vector2(-111.3289, -176.4535)
	p.weapon_elbow_bend_sign_override = 1.0
	p.support_elbow_bend_sign_override = 1.0


## Spear: saved overlay-local grip (yellow pin stacks on green hand).
func uses_saved_spear_grip_on_art() -> bool:
	if weapon_type != ResourceData.ResourceType.SPEAR:
		return false
	return not spear_hand_grip_needs_reseed() and hand_grip_offset_px.length_squared() > 0.0001


func spear_hand_grip_needs_reseed() -> bool:
	if weapon_type != ResourceData.ResourceType.SPEAR:
		return false
	# Legacy center-texture coords were ~+300–380 Y on the 471×835 overlay.
	if hand_grip_offset_px.y > 280.0:
		return true
	return false


func ensure_spear_grip_defaults() -> void:
	if weapon_type != ResourceData.ResourceType.SPEAR:
		return
	if not spear_hand_grip_needs_reseed():
		return
	hand_grip_offset_px = default_spear_hand_grip_px()


func idle_club1_hand_grip_is_plausible() -> bool:
	if idle_club1_hand_grip_offset_px.length_squared() < 0.0001:
		return false
	if absf(idle_club1_hand_grip_offset_px.x) > 280.0:
		return false
	# Legacy center-texture coords were ~+250 Y; pivot-relative grips are small offsets.
	if idle_club1_hand_grip_offset_px.y > 120.0:
		return false
	return true


func idle_club1_overlay_is_plausible() -> bool:
	if idle_club1_overlay_offset_px.length_squared() < 0.0001:
		return false
	if idle_club1_overlay_offset_px.distance_to(default_club_overlay_offset_px()) > 100.0:
		return false
	return true


func idle_club1_needs_reseed() -> bool:
	if not idle_club1_hand_grip_is_plausible():
		return true
	if not idle_club1_overlay_is_plausible():
		return true
	return false


func has_gather1_pull_pose() -> bool:
	return (
		gather1_pull_hand_grip_offset_px.length_squared() > 0.0001
		and gather1_pull_support_hand_offset_px.length_squared() > 0.0001
	)


func resolve_gather1_pull_hand(dominant: bool) -> Vector2:
	if dominant:
		return gather1_pull_hand_grip_offset_px
	return gather1_pull_support_hand_offset_px


func resolve_walk_rest_hand_grip() -> Vector2:
	if walk1_hand_grip_offset_px.length_squared() > 0.0001:
		return walk1_hand_grip_offset_px
	if walk_hand_grip_offset_px.length_squared() > 0.0001:
		return walk_hand_grip_offset_px
	return hand_grip_offset_px


func resolve_walk_rest_support_hand() -> Vector2:
	if walk1_support_hand_offset_px.length_squared() > 0.0001:
		return walk1_support_hand_offset_px
	if walk_support_hand_offset_px.length_squared() > 0.0001:
		return walk_support_hand_offset_px
	return support_hand_idle_offset_px


func seed_attack_from_idle_if_unset() -> void:
	if attack_pose_inherits_idle():
		return
	_seed_attack_windup_fields()


func seed_spear_attack_windup_if_unset() -> void:
	## Tuner: seed windup row even while spear_attack_pose_saved is false.
	if weapon_type != ResourceData.ResourceType.SPEAR:
		return
	_seed_attack_windup_fields()


func _seed_attack_windup_fields() -> void:
	if hand_grip_ready_offset_px.length_squared() < 0.0001:
		if weapon_type == ResourceData.ResourceType.SPEAR:
			hand_grip_ready_offset_px = hand_grip_offset_px
		elif weapon_type == ResourceData.ResourceType.WOOD:
			hand_grip_ready_offset_px = Vector2(0.0, 95.0)
		else:
			hand_grip_ready_offset_px = hand_grip_offset_px
	if (
		weapon_type == ResourceData.ResourceType.SPEAR
		and (
			support_hand_offset_px.length_squared() < 0.0001
			or support_hand_offset_px.distance_to(Vector2(6.0, 52.0)) < 0.01
		)
	):
		var dom := hand_grip_ready_offset_px
		# Second hand toward spear tip when horizontal (overlay +X ≈ shaft forward).
		support_hand_offset_px = Vector2(dom.x + 140.0, dom.y * 0.25)
	if weapon_elbow_pole_ready_px.length_squared() < 0.0001:
		weapon_elbow_pole_ready_px = weapon_elbow_pole_idle_px
	if support_elbow_pole_ready_px.length_squared() < 0.0001:
		support_elbow_pole_ready_px = support_elbow_pole_idle_px
	if ready_offset_px.length_squared() < 0.0001 or (
		weapon_type == ResourceData.ResourceType.SPEAR and ready_offset_px == Vector2(8.0, 6.0)
	):
		ready_offset_px = overlay_offset_idle_px
	if (
		weapon_type == ResourceData.ResourceType.SPEAR
		and strike_offset_px.length_squared() < 0.0001
	):
		strike_offset_px = ready_offset_px


func resolve_spear_windup_dominant_grip_px() -> Vector2:
	if hand_grip_ready_offset_px.length_squared() > 0.0001:
		return hand_grip_ready_offset_px
	return hand_grip_offset_px


func resolve_tuner_spear_windup_overlay_px() -> Vector2:
	## Horizontal windup hold (Shift ready) — not the thrust peak.
	if ready_offset_px.length_squared() > 0.0001:
		if attack_pose_inherits_idle() and ready_offset_px.distance_to(Vector2(8.0, 6.0)) < 0.01:
			return overlay_offset_idle_px
		return ready_offset_px
	return overlay_offset_idle_px


func resolve_tuner_spear_attack_overlay_px() -> Vector2:
	## Tuner attack row + thrust peak overlay.
	if spear_attack_pose_saved and strike_offset_px.length_squared() > 0.0001:
		return strike_offset_px
	return resolve_tuner_spear_windup_overlay_px()


func reset_mode_to_defaults(mode: TunerAnimMode) -> void:
	var d := defaults_for(weapon_type, body_card_index)
	match mode:
		TunerAnimMode.IDLE, TunerAnimMode.IDLE1:
			hand_grip_offset_px = d.hand_grip_offset_px
			support_hand_idle_offset_px = d.support_hand_idle_offset_px
			overlay_offset_idle_px = d.overlay_offset_idle_px
			idle_rotation_deg = d.idle_rotation_deg
			weapon_elbow_bend_sign_override = 0.0
			support_elbow_bend_sign_override = 0.0
			weapon_elbow_pole_idle_px = Vector2.ZERO
			support_elbow_pole_idle_px = Vector2.ZERO
		TunerAnimMode.WALK:
			walk_hand_grip_offset_px = Vector2.ZERO
			walk_support_hand_offset_px = Vector2.ZERO
			walk_overlay_offset_px = Vector2.ZERO
			walk_weapon_elbow_bend_sign_override = 0.0
			walk_support_elbow_bend_sign_override = 0.0
			walk_weapon_elbow_pole_px = Vector2.ZERO
			walk_support_elbow_pole_px = Vector2.ZERO
		TunerAnimMode.WALK1:
			walk1_hand_grip_offset_px = Vector2.ZERO
			walk1_support_hand_offset_px = Vector2.ZERO
			walk1_overlay_offset_px = Vector2.ZERO
			walk1_weapon_elbow_bend_sign_override = 0.0
			walk1_support_elbow_bend_sign_override = 0.0
			walk1_weapon_elbow_pole_px = Vector2.ZERO
			walk1_support_elbow_pole_px = Vector2.ZERO
		TunerAnimMode.GATHER1:
			gather1_hand_grip_offset_px = Vector2.ZERO
			gather1_support_hand_offset_px = Vector2.ZERO
			gather1_overlay_offset_px = Vector2.ZERO
			gather1_weapon_elbow_bend_sign_override = 0.0
			gather1_support_elbow_bend_sign_override = 0.0
			gather1_weapon_elbow_pole_px = Vector2.ZERO
			gather1_support_elbow_pole_px = Vector2.ZERO
			gather1_pull_hand_grip_offset_px = Vector2.ZERO
			gather1_pull_support_hand_offset_px = Vector2.ZERO
		TunerAnimMode.IDLE_CLUB1:
			idle_club1_hand_grip_offset_px = Vector2.ZERO
			idle_club1_support_hand_offset_px = Vector2.ZERO
			idle_club1_overlay_offset_px = Vector2.ZERO
			idle_club1_weapon_elbow_bend_sign_override = 0.0
			idle_club1_support_elbow_bend_sign_override = 0.0
			idle_club1_weapon_elbow_pole_px = Vector2.ZERO
			idle_club1_support_elbow_pole_px = Vector2.ZERO
		TunerAnimMode.ATTACK:
			hand_grip_ready_offset_px = Vector2.ZERO
			support_hand_offset_px = d.support_hand_offset_px
			ready_offset_px = d.ready_offset_px
			ready_forward_px = d.ready_forward_px
			weapon_elbow_bend_sign_ready_override = 0.0
			support_elbow_bend_sign_ready_override = 0.0
			weapon_elbow_pole_ready_px = Vector2.ZERO
			support_elbow_pole_ready_px = Vector2.ZERO
			club_attack_pose_saved = false
			spear_attack_pose_saved = false


func reset_anchors_to_defaults() -> void:
	var none := load_none_body_preset(body_card_index)
	if none != null:
		apply_shared_body_from_none(none)
		return
	var d := defaults_for(weapon_type, body_card_index)
	shoulder_offset_px = d.shoulder_offset_px
	support_shoulder_offset_px = d.support_shoulder_offset_px
	upper_arm_length = d.upper_arm_length
	lower_arm_length = d.lower_arm_length
	arm_width = d.arm_width
	hand_width = d.hand_width
	elbow_hint_outward = d.elbow_hint_outward


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


static func compute_pole_px_from_elbow(
	shoulder_px: Vector2,
	hand_px: Vector2,
	elbow_px: Vector2,
	outward: float,
	bend_sign: float
) -> Vector2:
	var mid := (shoulder_px + hand_px) * 0.5
	var to_elbow := elbow_px - mid
	if to_elbow.length_squared() < 0.01:
		return compute_auto_elbow_pole_px(shoulder_px, hand_px, outward, bend_sign)
	return mid + to_elbow.normalized() * outward


func resolve_hand_grip_ready_px() -> Vector2:
	if attack_pose_inherits_idle():
		if weapon_type == ResourceData.ResourceType.WOOD:
			return resolve_club_overlay_grip_px(TunerAnimMode.IDLE)
		return resolve_hand_grip_for_mode(TunerAnimMode.IDLE)
	if hand_grip_ready_offset_px.length_squared() > 0.0001:
		return hand_grip_ready_offset_px
	return hand_grip_offset_px


func resolve_weapon_upper_arm_length() -> float:
	return upper_arm_length


func resolve_weapon_lower_arm_length() -> float:
	return lower_arm_length


func resolve_support_upper_arm_length() -> float:
	return upper_arm_length


func resolve_support_lower_arm_length() -> float:
	return lower_arm_length


func resolve_upper_arm_length(dominant: bool) -> float:
	return resolve_weapon_upper_arm_length() if dominant else resolve_support_upper_arm_length()


func resolve_lower_arm_length(dominant: bool) -> float:
	return resolve_weapon_lower_arm_length() if dominant else resolve_support_lower_arm_length()


func tuner_max_reach_px() -> float:
	return upper_arm_length + lower_arm_length


func tuner_ik_max_reach_px(dominant: bool, fold_min_deg: float = 8.0) -> float:
	var upper := resolve_upper_arm_length(dominant)
	var lower := resolve_lower_arm_length(dominant)
	var min_fold := deg_to_rad(fold_min_deg)
	return sqrt(
		upper * upper + lower * lower - 2.0 * upper * lower * cos(PI - min_fold)
	) - 0.01


func tuner_ik_min_reach_px(dominant: bool, fold_max_deg: float = 150.0) -> float:
	var upper := resolve_upper_arm_length(dominant)
	var lower := resolve_lower_arm_length(dominant)
	var max_fold := deg_to_rad(fold_max_deg)
	return sqrt(
		upper * upper + lower * lower - 2.0 * upper * lower * cos(PI - max_fold)
	) + 0.01


func set_shared_arm_lengths(upper: float, lower: float) -> void:
	var capped := cap_arm_segment_lengths(upper, lower)
	apply_tuner_arm_lengths(capped.x, capped.y)


func apply_tuner_arm_lengths(upper: float, lower: float) -> void:
	upper_arm_length = maxf(upper, TUNER_MIN_SEGMENT_PX)
	lower_arm_length = maxf(lower, TUNER_MIN_SEGMENT_PX)
	weapon_upper_arm_length = -1.0
	weapon_lower_arm_length = -1.0
	support_upper_arm_length = -1.0
	support_lower_arm_length = -1.0


func apply_tuner_arm_thickness(shoulder_width_px: float) -> void:
	arm_width = clampf(shoulder_width_px, TUNER_MIN_ARM_WIDTH, TUNER_MAX_ARM_WIDTH)
	var hand_ratio := TUNER_DEFAULT_HAND_WIDTH / TUNER_DEFAULT_ARM_WIDTH
	hand_width = arm_width * hand_ratio


static func cap_arm_segment_lengths(upper: float, lower: float) -> Vector2:
	upper = clampf(upper, TUNER_MIN_SEGMENT_PX, TUNER_MAX_UPPER_ARM_PX)
	lower = clampf(lower, TUNER_MIN_SEGMENT_PX, TUNER_MAX_LOWER_ARM_PX)
	var max_total := TUNER_MAX_UPPER_ARM_PX + TUNER_MAX_LOWER_ARM_PX
	var total := upper + lower
	if total > max_total:
		var scale := max_total / total
		upper *= scale
		lower *= scale
	return Vector2(upper, lower)


func duplicate_preset() -> WeaponLimbPreset:
	var copy: WeaponLimbPreset = duplicate(true) as WeaponLimbPreset
	return copy


static func bend_sign_chat_label(override_sign: float) -> String:
	if absf(override_sign) < 0.001:
		return "auto"
	return "outward +" if override_sign > 0.0 else "outward -"


func chat_summary_line(mode: TunerAnimMode, weapon_slug: String) -> String:
	var mode_name := "idle"
	match mode:
		TunerAnimMode.IDLE1:
			mode_name = "idle1"
		TunerAnimMode.WALK:
			mode_name = "walk"
		TunerAnimMode.WALK1:
			mode_name = "walk1"
		TunerAnimMode.GATHER1:
			mode_name = "gather1"
		TunerAnimMode.IDLE_CLUB1:
			mode_name = "idle club1"
		TunerAnimMode.ATTACK:
			mode_name = "attack"
	var hand := resolve_hand_grip_for_mode(mode)
	var overlay := resolve_overlay_for_mode(mode)
	if weapon_type == ResourceData.ResourceType.WOOD and mode != TunerAnimMode.ATTACK:
		hand = resolve_club_overlay_grip_px(mode)
	var dom_bend := resolve_elbow_bend_sign_override(true, mode)
	var off_bend := resolve_elbow_bend_sign_override(false, mode)
	return (
		"%s %s — hand %s | overlay %s | 1e %s | 2e %s"
		% [
			weapon_slug,
			mode_name,
			str(hand),
			str(overlay),
			bend_sign_chat_label(dom_bend),
			bend_sign_chat_label(off_bend),
		]
	)


func to_chat_handoff(weapon_slug: String) -> String:
	var lines: PackedStringArray = PackedStringArray()
	lines.append("Limb pose map (%s / %s)" % [weapon_slug, body_card_id])
	lines.append("shoulder 1: %s | shoulder 2: %s" % [str(shoulder_offset_px), str(support_shoulder_offset_px)])
	lines.append(chat_summary_line(TunerAnimMode.IDLE, weapon_slug))
	lines.append(chat_summary_line(TunerAnimMode.WALK, weapon_slug))
	lines.append(chat_summary_line(TunerAnimMode.WALK1, weapon_slug))
	lines.append(chat_summary_line(TunerAnimMode.GATHER1, weapon_slug))
	lines.append(chat_summary_line(TunerAnimMode.IDLE_CLUB1, weapon_slug))
	lines.append(chat_summary_line(TunerAnimMode.ATTACK, weapon_slug))
	lines.append("arm length: %.0f / %.0f px" % [upper_arm_length, lower_arm_length])
	lines.append("arm thickness: %.0f px (hand end %.0f px)" % [arm_width, hand_width])
	return "\n".join(lines)


func to_export_dict() -> Dictionary:
	return {
		"_chat_handoff": to_chat_handoff(_weapon_slug_for_export()),
		"weapon_type": weapon_type,
		"body_card_id": body_card_id,
		"body_card_index": body_card_index,
		"shoulder_offset_px": shoulder_offset_px,
		"hand_grip_offset_px": hand_grip_offset_px,
		"hand_grip_ready_offset_px": hand_grip_ready_offset_px,
		"support_shoulder_offset_px": support_shoulder_offset_px,
		"support_hand_idle_offset_px": support_hand_idle_offset_px,
		"support_hand_idle_raise_offset_px": support_hand_idle_raise_offset_px,
		"support_hand_offset_px": support_hand_offset_px,
		"overlay_offset_idle_px": overlay_offset_idle_px,
		"idle_rotation_deg": idle_rotation_deg,
		"walk_hand_grip_offset_px": walk_hand_grip_offset_px,
		"walk_support_hand_offset_px": walk_support_hand_offset_px,
		"walk_overlay_offset_px": walk_overlay_offset_px,
		"walk_weapon_elbow_pole_px": walk_weapon_elbow_pole_px,
		"walk_support_elbow_pole_px": walk_support_elbow_pole_px,
		"walk1_hand_grip_offset_px": walk1_hand_grip_offset_px,
		"walk1_support_hand_offset_px": walk1_support_hand_offset_px,
		"walk1_overlay_offset_px": walk1_overlay_offset_px,
		"walk1_weapon_elbow_pole_px": walk1_weapon_elbow_pole_px,
		"walk1_support_elbow_pole_px": walk1_support_elbow_pole_px,
		"walk1_weapon_elbow_bend_sign_override": walk1_weapon_elbow_bend_sign_override,
		"walk1_support_elbow_bend_sign_override": walk1_support_elbow_bend_sign_override,
		"gather1_hand_grip_offset_px": gather1_hand_grip_offset_px,
		"gather1_support_hand_offset_px": gather1_support_hand_offset_px,
		"gather1_overlay_offset_px": gather1_overlay_offset_px,
		"gather1_weapon_elbow_pole_px": gather1_weapon_elbow_pole_px,
		"gather1_support_elbow_pole_px": gather1_support_elbow_pole_px,
		"gather1_weapon_elbow_bend_sign_override": gather1_weapon_elbow_bend_sign_override,
		"gather1_support_elbow_bend_sign_override": gather1_support_elbow_bend_sign_override,
		"gather1_pull_hand_grip_offset_px": gather1_pull_hand_grip_offset_px,
		"gather1_pull_support_hand_offset_px": gather1_pull_support_hand_offset_px,
		"idle_club1_hand_grip_offset_px": idle_club1_hand_grip_offset_px,
		"idle_club1_support_hand_offset_px": idle_club1_support_hand_offset_px,
		"idle_club1_overlay_offset_px": idle_club1_overlay_offset_px,
		"idle_club1_weapon_elbow_pole_px": idle_club1_weapon_elbow_pole_px,
		"idle_club1_support_elbow_pole_px": idle_club1_support_elbow_pole_px,
		"idle_club1_weapon_elbow_bend_sign_override": idle_club1_weapon_elbow_bend_sign_override,
		"idle_club1_support_elbow_bend_sign_override": idle_club1_support_elbow_bend_sign_override,
		"idle_club1_grip_authoritative": idle_club1_grip_authoritative,
		"club_attack_pose_saved": club_attack_pose_saved,
		"spear_attack_pose_saved": spear_attack_pose_saved,
		"ready_offset_px": ready_offset_px,
		"strike_offset_px": strike_offset_px,
		"ready_forward_px": ready_forward_px,
		"upper_arm_length": upper_arm_length,
		"lower_arm_length": lower_arm_length,
		"weapon_upper_arm_length": weapon_upper_arm_length,
		"weapon_lower_arm_length": weapon_lower_arm_length,
		"support_upper_arm_length": support_upper_arm_length,
		"support_lower_arm_length": support_lower_arm_length,
		"arm_width": arm_width,
		"hand_width": hand_width,
		"elbow_hint_outward": elbow_hint_outward,
		"weapon_elbow_pole_idle_px": weapon_elbow_pole_idle_px,
		"weapon_elbow_pole_ready_px": weapon_elbow_pole_ready_px,
		"support_elbow_pole_idle_px": support_elbow_pole_idle_px,
		"support_elbow_pole_ready_px": support_elbow_pole_ready_px,
		"weapon_elbow_bend_sign_override": weapon_elbow_bend_sign_override,
		"support_elbow_bend_sign_override": support_elbow_bend_sign_override,
		"support_elbow_bend_sign_raise_override": support_elbow_bend_sign_raise_override,
		"walk_weapon_elbow_bend_sign_override": walk_weapon_elbow_bend_sign_override,
		"walk_support_elbow_bend_sign_override": walk_support_elbow_bend_sign_override,
		"weapon_elbow_bend_sign_ready_override": weapon_elbow_bend_sign_ready_override,
		"support_elbow_bend_sign_ready_override": support_elbow_bend_sign_ready_override,
		"tuner_stage_scale": tuner_stage_scale,
	}


func _weapon_slug_for_export() -> String:
	match weapon_type:
		ResourceData.ResourceType.NONE:
			return "none"
		ResourceData.ResourceType.WOOD:
			return "club"
		ResourceData.ResourceType.SPEAR:
			return "spear"
		ResourceData.ResourceType.AXE:
			return "axe"
		_:
			return "weapon_%d" % int(weapon_type)


static func none_body_preset_path(body_index: int = 1) -> String:
	return "res://assets/limb_presets/none_clansmen_%d.tres" % body_index


static func load_none_body_preset(body_index: int = 1) -> WeaponLimbPreset:
	var path := none_body_preset_path(body_index)
	if ResourceLoader.exists(path):
		return load(path) as WeaponLimbPreset
	return null


static func defaults_for(weapon_type: ResourceData.ResourceType, body_index: int = 1) -> WeaponLimbPreset:
	var p := WeaponLimbPreset.new()
	p.weapon_type = weapon_type
	p.body_card_id = "clansmen_%d" % body_index
	p.body_card_index = body_index
	var registry = PlaceholderCardRegistry.new()
	if weapon_type == ResourceData.ResourceType.NONE:
		p.hand_grip_offset_px = Vector2(24.0, 8.0)
		p.support_hand_idle_offset_px = Vector2(-12.0, 30.0)
	if weapon_type == ResourceData.ResourceType.SPEAR:
		apply_default_spear_idle_pose(p)
	elif registry.TOOL_OVERLAY_OFFSET_PX.has(weapon_type):
		p.overlay_offset_idle_px = registry.get_tool_overlay_offset_px(weapon_type)
	var profile: Dictionary = registry.get_weapon_combat_profile(weapon_type)
	if profile.has("ready_offset_px"):
		p.ready_offset_px = profile["ready_offset_px"] as Vector2
	if profile.has("ready_forward_px"):
		p.ready_forward_px = float(profile["ready_forward_px"])
	if profile.has("idle_rotation_deg"):
		p.idle_rotation_deg = float(profile["idle_rotation_deg"])
	if weapon_type != ResourceData.ResourceType.NONE:
		var none := load_none_body_preset(body_index)
		if none != null:
			p.apply_shared_body_from_none(none)
		else:
			p.support_hand_idle_offset_px = Vector2(-12.0, 30.0)
	p.tuner_stage_scale = 1.0
	return p
