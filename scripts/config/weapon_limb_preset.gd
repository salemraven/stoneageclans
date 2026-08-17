extends Resource
class_name WeaponLimbPreset

const WalkArmMotionScript = preload("res://scripts/systems/walk_arm_motion.gd")
const TunerPoseSeedGuard = preload("res://scripts/tools/tuner_pose_seed_guard.gd")
const CharacterAnimationPresetStoreScript = preload(
	"res://scripts/config/character_animation_preset_store.gd"
)
const CharacterAnimationPoseScript = preload("res://scripts/config/character_animation_pose.gd")
const CharacterAnimationClipScript = preload("res://scripts/config/character_animation_clip.gd")

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
## Documented exception: club **Walk** (legacy) borrows idle standing for the weapon arm.
## Club **Walk 1** uses full walk1_a / walk1_b rows for both arms; overlay follows 1h grip.


static func tuner_overlay_storage_mode(
	active_mode: TunerAnimMode,
	weapon_type: ResourceData.ResourceType
) -> TunerAnimMode:
	if weapon_type == ResourceData.ResourceType.WOOD and active_mode == TunerAnimMode.WALK:
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
	if weapon_type == ResourceData.ResourceType.WOOD and active_mode == TunerAnimMode.WALK and dominant:
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
## Unified two-pose animation clips (authoritative pose storage).
@export var animation_clips: Array = []
@export var unified_clips_initialized: bool = false

## Red shoulder — attachment on body card (offset from sprite origin).
@export var shoulder_offset_px: Vector2 = Vector2.ZERO

## Green hand — primary grip on weapon overlay (overlay-local px). Idle + general.
@export var hand_grip_offset_px: Vector2 = Vector2(0.0, 72.0)
## Dominant hand on spear in ready/attack (overlay-local px). Zero = use hand_grip_offset_px.
@export var hand_grip_ready_offset_px: Vector2 = Vector2.ZERO

## Off-hand shoulder on body card (display px, pre-flip).
@export var support_shoulder_offset_px: Vector2 = Vector2(-18.0, -20.0)
## Off-hand shoulder while raised (sun shield). Zero = no shoulder shift on raise.
@export var support_shoulder_idle_raise_offset_px: Vector2 = Vector2.ZERO
## Off-hand at rest in idle — on body, not on spear (sprite display px, pre-flip).
@export var support_hand_idle_offset_px: Vector2 = Vector2(-12.0, 30.0)
## Optional raised off-hand target for idle variety. Zero = no raise animation.
@export var support_hand_idle_raise_offset_px: Vector2 = Vector2.ZERO
## Raised off-hand while head looks back (sun shield). Zero = fall back to raise offset until tuned.
@export var support_hand_idle_raise_lookback_offset_px: Vector2 = Vector2.ZERO
## Off-hand grip on spear in ready/attack (overlay-local px).
@export var support_hand_offset_px: Vector2 = Vector2(6.0, 52.0)

## Spear overlay idle placement (offset from body sprite origin, pre-flip display px).
@export var overlay_offset_idle_px: Vector2 = Vector2(22.0, -34.0)
@export var idle_rotation_deg: float = 0.0
## Weapon overlay compass angle (0–360°) per pose row. ROTATION_UNSET = use combat profile default.
const ROTATION_UNSET := -1000.0
@export var attack_rotation_deg: float = ROTATION_UNSET
@export var walk_rotation_deg: float = ROTATION_UNSET
@export var walk1_rotation_deg: float = ROTATION_UNSET
@export var gather1_rotation_deg: float = ROTATION_UNSET
@export var idle_club1_rotation_deg: float = ROTATION_UNSET

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
## Pose 2 keyframe — preview lerps Pose 1 → Pose 2 each walk step.
@export var walk1_pull_hand_grip_offset_px: Vector2 = Vector2.ZERO
@export var walk1_pull_support_hand_offset_px: Vector2 = Vector2.ZERO
@export var walk1_pull_weapon_elbow_pole_px: Vector2 = Vector2.ZERO
@export var walk1_pull_support_elbow_pole_px: Vector2 = Vector2.ZERO
@export var walk1_pull_weapon_elbow_bend_sign_override: float = 0.0
@export var walk1_pull_support_elbow_bend_sign_override: float = 0.0

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
@export var gather1_pull_weapon_elbow_pole_px: Vector2 = Vector2.ZERO
@export var gather1_pull_support_elbow_pole_px: Vector2 = Vector2.ZERO
@export var gather1_pull_weapon_elbow_bend_sign_override: float = 0.0
@export var gather1_pull_support_elbow_bend_sign_override: float = 0.0
## Tuner: once true, seed/copy helpers must not overwrite this row from idle or sibling rows.
@export var walk1_pose_a_saved: bool = false
@export var walk1_pose_b_saved: bool = false
@export var gather1_reach_saved: bool = false
@export var gather1_pull_saved: bool = false

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
## Club windup idle loop: rest pose = ready_offset_px + hand_grip_ready + support_hand_idle.
## Off-hand loop uses support_hand_idle + optional key B only (key A support ignored at runtime).
@export var club_windup_idle_loop_sec: float = 5.0
@export var club_windup_idle_key_a_ready_offset_px: Vector2 = Vector2.ZERO
@export var club_windup_idle_key_a_hand_grip_offset_px: Vector2 = Vector2.ZERO
@export var club_windup_idle_key_a_support_hand_offset_px: Vector2 = Vector2.ZERO
@export var club_windup_idle_key_b_ready_offset_px: Vector2 = Vector2.ZERO
@export var club_windup_idle_key_b_hand_grip_offset_px: Vector2 = Vector2.ZERO
@export var club_windup_idle_key_b_support_hand_offset_px: Vector2 = Vector2.ZERO
@export var club_windup_idle_key_a_rotation_deg: float = ROTATION_UNSET
@export var club_windup_idle_key_b_rotation_deg: float = ROTATION_UNSET
@export var club_windup_idle_rest_rotation_deg: float = ROTATION_UNSET
## Off-hand travel during windup loop (1 = full authored keyframes, lower = subtler).
@export_range(0.0, 1.0, 0.05) var club_windup_support_motion_scale: float = 0.25
## Off-hand extension at strike peak as fraction of authored attack row (loop seam → peak).
@export_range(0.0, 1.0, 0.05) var club_strike_support_motion_frac: float = 0.15
## Spear attack windup row: false = inherit idle standing until user saves windup pose.
@export var spear_attack_pose_saved: bool = false

## Spear overlay ready placement (combat profile overrides).
@export var ready_offset_px: Vector2 = Vector2(8.0, 6.0)
## Spear thrust peak — max extension overlay (display px). Zero = use ready + thrust_extend_px.
@export var strike_offset_px: Vector2 = Vector2.ZERO
@export var ready_forward_px: float = 24.0

## IK segment lengths (display px).
@export var upper_arm_length: float = 140.0
@export var lower_arm_length: float = 140.0
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
const TUNER_MAX_UPPER_ARM_PX := 160.0
const TUNER_MAX_LOWER_ARM_PX := 160.0
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
@export var support_elbow_pole_idle_raise_px: Vector2 = Vector2.ZERO
## Mid-raise pole — elbow sweeps in front of body. Zero = auto from rest/raised poles.
@export var support_elbow_pole_idle_raise_sweep_px: Vector2 = Vector2.ZERO
@export var support_elbow_pole_ready_px: Vector2 = Vector2.ZERO

## Tuner: 0 = elbow follows facing. ±1 = forced bend side (right-click 1e/2e to flip).
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


static func normalize_rotation_deg(deg: float) -> float:
	var d := fmod(deg, 360.0)
	if d < 0.0:
		d += 360.0
	return d


static func signed_rotation_deg(deg: float) -> float:
	var d := normalize_rotation_deg(deg)
	if d > 180.0:
		d -= 360.0
	return d


func rotation_deg_is_custom(mode: TunerAnimMode) -> bool:
	match mode:
		TunerAnimMode.ATTACK:
			return attack_rotation_deg > ROTATION_UNSET + 1.0
		TunerAnimMode.WALK:
			return walk_rotation_deg > ROTATION_UNSET + 1.0
		TunerAnimMode.WALK1:
			return walk1_rotation_deg > ROTATION_UNSET + 1.0
		TunerAnimMode.GATHER1:
			return gather1_rotation_deg > ROTATION_UNSET + 1.0
		TunerAnimMode.IDLE_CLUB1:
			return idle_club1_rotation_deg > ROTATION_UNSET + 1.0
		TunerAnimMode.IDLE, TunerAnimMode.IDLE1:
			return absf(idle_rotation_deg) > 0.001
	return false


func get_rotation_deg_for_mode(mode: TunerAnimMode) -> float:
	match mode:
		TunerAnimMode.ATTACK:
			return attack_rotation_deg
		TunerAnimMode.WALK:
			return walk_rotation_deg
		TunerAnimMode.WALK1:
			return walk1_rotation_deg
		TunerAnimMode.GATHER1:
			return gather1_rotation_deg
		TunerAnimMode.IDLE_CLUB1:
			return idle_club1_rotation_deg
		_:
			return idle_rotation_deg


func set_rotation_deg_for_mode(mode: TunerAnimMode, deg: float) -> void:
	var norm := normalize_rotation_deg(deg)
	match mode:
		TunerAnimMode.ATTACK:
			attack_rotation_deg = norm
		TunerAnimMode.WALK:
			walk_rotation_deg = norm
		TunerAnimMode.WALK1:
			walk1_rotation_deg = norm
		TunerAnimMode.GATHER1:
			gather1_rotation_deg = norm
		TunerAnimMode.IDLE_CLUB1:
			idle_club1_rotation_deg = norm
		_:
			idle_rotation_deg = norm


func resolve_swing_stored_rotation_deg(stored_ready_deg: float, facing_sign: float, profile: Dictionary) -> float:
	var idle_deg: float = idle_rotation_deg
	if absf(idle_deg) < 0.001:
		idle_deg = float(profile.get("idle_rotation_deg", 0.0))
	var offset: float = stored_ready_deg - idle_deg
	return idle_deg + offset * facing_sign


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


func has_club_windup_idle_loop() -> bool:
	if weapon_type != ResourceData.ResourceType.WOOD:
		return false
	return (
		club_windup_idle_key_a_ready_offset_px.length_squared() > 0.0001
		and club_windup_idle_key_b_ready_offset_px.length_squared() > 0.0001
	)


func resolve_club_windup_rotation_deg(segment: StringName, profile: Dictionary) -> float:
	## segment: rest | a | b — east-facing degrees; UNSET falls back to combat profile ready cock.
	var stored: float = ROTATION_UNSET
	match segment:
		&"a":
			stored = club_windup_idle_key_a_rotation_deg
		&"b":
			stored = club_windup_idle_key_b_rotation_deg
		_:
			stored = club_windup_idle_rest_rotation_deg
	if stored > ROTATION_UNSET + 1.0:
		return stored
	if attack_rotation_deg > ROTATION_UNSET + 1.0 and segment == &"a":
		return attack_rotation_deg
	# Windup cock uses combat ready offset only — not idle carry rotation (e.g. 107° hang).
	var ready_offset_deg: float = float(profile.get("ready_rotation_offset_deg", 42.0))
	return -ready_offset_deg


func club_strike_windup_keyframe() -> Dictionary:
	return {
		"overlay_px": club_windup_idle_key_b_ready_offset_px,
		"hand_grip_px": club_windup_idle_key_b_hand_grip_offset_px,
		"support_hand_px": resolve_club_strike_loop_seam_support_px(),
	}


## Idle / walk off-hand rest (body display px). Single anchor for club carry + loop wrap.
func club_support_rest_px() -> Vector2:
	return support_hand_idle_offset_px


func resolve_club_strike_loop_seam_support_px() -> Vector2:
	## Windup/strike join: rest → optional key B (scaled). Zero key B = rest only.
	var rest := club_support_rest_px()
	if club_windup_idle_key_b_support_hand_offset_px.length_squared() < 0.0001:
		return rest
	var scale := clampf(club_windup_support_motion_scale, 0.0, 1.0)
	return rest.lerp(club_windup_idle_key_b_support_hand_offset_px, scale)


func resolve_club_strike_peak_support_hand_px() -> Vector2:
	## Attack row 2h at strike peak, blended from loop seam (see club_strike_support_motion_frac).
	var rest := club_support_rest_px()
	var authored := support_hand_offset_px
	if authored.length_squared() < 0.0001 or authored.distance_to(rest) < 0.5:
		return resolve_club_strike_loop_seam_support_px()
	var seam := resolve_club_strike_loop_seam_support_px()
	var frac := clampf(club_strike_support_motion_frac, 0.0, 1.0)
	return seam.lerp(authored, frac)


func reset_club_off_hand_authoring() -> void:
	## Clear stale windup/attack 2h rows; keep idle rest. Call before re-posing pin 2h.
	if weapon_type != ResourceData.ResourceType.WOOD:
		return
	var rest := club_support_rest_px()
	support_hand_offset_px = rest
	club_windup_idle_key_a_support_hand_offset_px = Vector2.ZERO
	club_windup_idle_key_b_support_hand_offset_px = Vector2.ZERO
	idle_club1_support_hand_offset_px = rest
	if walk_support_hand_offset_px.length_squared() < 0.0001:
		walk_support_hand_offset_px = rest


func club_strike_peak_keyframe() -> Dictionary:
	## Attack row — maximum extension at strike peak.
	var overlay_px := strike_offset_px
	if overlay_px.length_squared() < 0.0001:
		overlay_px = ready_offset_px
	return {
		"overlay_px": overlay_px,
		"hand_grip_px": hand_grip_ready_offset_px,
		"support_hand_px": resolve_club_strike_peak_support_hand_px(),
	}


func has_club_keyframed_strike() -> bool:
	return (
		weapon_type == ResourceData.ResourceType.WOOD
		and has_club_windup_idle_loop()
		and club_attack_pose_saved
		and strike_offset_px.length_squared() > 0.0001
		and club_windup_idle_key_b_ready_offset_px.length_squared() > 0.0001
		and strike_offset_px.distance_to(club_windup_idle_key_b_ready_offset_px) > 2.0
	)


func has_spear_keyframed_strike() -> bool:
	## Preset windup → strike peak tween (no cursor aim extension).
	return (
		weapon_type == ResourceData.ResourceType.SPEAR
		and spear_attack_pose_saved
		and ready_offset_px.length_squared() > 0.0001
		and strike_offset_px.length_squared() > 0.0001
		and strike_offset_px.distance_to(ready_offset_px) > 2.0
	)


func spear_strike_windup_keyframe() -> Dictionary:
	return {
		"overlay_px": ready_offset_px,
		"hand_grip_px": hand_grip_ready_offset_px,
		"support_hand_px": support_hand_offset_px,
	}


func spear_strike_peak_keyframe() -> Dictionary:
	return {
		"overlay_px": strike_offset_px,
		"hand_grip_px": hand_grip_ready_offset_px,
		"support_hand_px": support_hand_offset_px,
	}


func sample_club_windup_idle_loop(phase: float) -> Dictionary:
	## Smooth rest → A → B → rest loop (phase 0..1).
	var p := fposmod(phase, 1.0)
	var t := p * 3.0
	var seg := mini(int(floor(t)), 2)
	var local := _smoothstep01(t - float(seg))
	var rest_ready := ready_offset_px
	var rest_grip := hand_grip_ready_offset_px
	var from_ready: Vector2
	var to_ready: Vector2
	var from_grip: Vector2
	var to_grip: Vector2
	match seg:
		0:
			from_ready = rest_ready
			to_ready = club_windup_idle_key_a_ready_offset_px
			from_grip = rest_grip
			to_grip = club_windup_idle_key_a_hand_grip_offset_px
		1:
			from_ready = club_windup_idle_key_a_ready_offset_px
			to_ready = club_windup_idle_key_b_ready_offset_px
			from_grip = club_windup_idle_key_a_hand_grip_offset_px
			to_grip = club_windup_idle_key_b_hand_grip_offset_px
		_:
			from_ready = club_windup_idle_key_b_ready_offset_px
			to_ready = rest_ready
			from_grip = club_windup_idle_key_b_hand_grip_offset_px
			to_grip = rest_grip
	return {
		"ready_offset_px": from_ready.lerp(to_ready, local),
		"hand_grip_ready_offset_px": from_grip.lerp(to_grip, local),
		"support_hand_idle_offset_px": _sample_club_windup_support_loop(seg, local),
	}


func _sample_club_windup_support_loop(seg: int, local_t: float) -> Vector2:
	## Off-hand only: rest → hold loop seam → rest (club overlay still uses A/B keys).
	var rest := club_support_rest_px()
	var seam := resolve_club_strike_loop_seam_support_px()
	var ease := _smoothstep01(local_t)
	match seg:
		0:
			return rest.lerp(seam, ease)
		1:
			return seam
		_:
			return seam.lerp(rest, ease)


static func _smoothstep01(t: float) -> float:
	t = clampf(t, 0.0, 1.0)
	return t * t * (3.0 - 2.0 * t)


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
	return resolve_elbow_bend_sign_override_for_pose(dominant, mode, false, false)


func resolve_elbow_bend_sign_override_for_pose(
	dominant: bool,
	mode: TunerAnimMode,
	pose_b: bool,
	gather_pull: bool
) -> float:
	if mode == TunerAnimMode.WALK1 and pose_b:
		return (
			walk1_pull_weapon_elbow_bend_sign_override
			if dominant
			else walk1_pull_support_elbow_bend_sign_override
		)
	if mode == TunerAnimMode.GATHER1 and gather_pull:
		return (
			gather1_pull_weapon_elbow_bend_sign_override
			if dominant
			else gather1_pull_support_elbow_bend_sign_override
		)
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
	set_elbow_bend_sign_override_for_pose(dominant, mode, false, false, sign)


func set_elbow_bend_sign_override_for_pose(
	dominant: bool,
	mode: TunerAnimMode,
	pose_b: bool,
	gather_pull: bool,
	sign: float
) -> void:
	var forced := 0.0 if absf(sign) < 0.001 else signf(sign)
	if mode == TunerAnimMode.WALK1 and pose_b:
		if dominant:
			walk1_pull_weapon_elbow_bend_sign_override = forced
		else:
			walk1_pull_support_elbow_bend_sign_override = forced
		return
	if mode == TunerAnimMode.GATHER1 and gather_pull:
		if dominant:
			gather1_pull_weapon_elbow_bend_sign_override = forced
		else:
			gather1_pull_support_elbow_bend_sign_override = forced
		return
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
	return resolve_elbow_bend_sign_for_pose(dominant, mode, false, false, auto_from_facing)


func resolve_elbow_bend_sign_for_pose(
	dominant: bool,
	mode: TunerAnimMode,
	pose_b: bool,
	gather_pull: bool,
	auto_from_facing: float
) -> float:
	var override := resolve_elbow_bend_sign_override_for_pose(dominant, mode, pose_b, gather_pull)
	if absf(override) < 0.001:
		return auto_from_facing
	## Stored override is the desired bend sign in east-facing (unflipped) display space.
	var east_auto := -DOMINANT_ELBOW_BEND_SIGN if dominant else -SUPPORT_ELBOW_BEND_SIGN
	var east_desired := signf(override)
	if signf(auto_from_facing) == signf(east_auto):
		return east_desired
	return -east_desired


func toggle_elbow_bend_sign(dominant: bool, mode: TunerAnimMode, auto_from_facing: float) -> float:
	return toggle_elbow_bend_sign_for_pose(dominant, mode, false, false, auto_from_facing)


func toggle_elbow_bend_sign_for_pose(
	dominant: bool,
	mode: TunerAnimMode,
	pose_b: bool,
	gather_pull: bool,
	auto_from_facing: float
) -> float:
	var current := resolve_elbow_bend_sign_for_pose(dominant, mode, pose_b, gather_pull, auto_from_facing)
	var flipped := -current
	var east_auto := -DOMINANT_ELBOW_BEND_SIGN if dominant else -SUPPORT_ELBOW_BEND_SIGN
	var facing_east := signf(auto_from_facing) == signf(east_auto)
	var new_east_desired := flipped if facing_east else -flipped
	set_elbow_bend_sign_override_for_pose(dominant, mode, pose_b, gather_pull, new_east_desired)
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
			if uses_club_walk_off_arm_travel_swing():
				var body_px := resolve_club_carry_body_hand_px()
				if body_px.length_squared() > 0.0001:
					return body_px
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
	if uses_saved_club_grip_on_art():
		return idle_club1_hand_grip_offset_px
	if mode == TunerAnimMode.ATTACK:
		return resolve_hand_grip_for_mode(mode)
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
		TunerAnimMode.IDLE:
			set_club_carry_body_hand_px(display_px)
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
			hand_grip_offset_px = display_px


func set_club_carry_body_hand_px(display_px: Vector2) -> void:
	## Body-card dominant hand for club carry — never overwrites saved grip-on-art (yellow 3).
	hand_grip_offset_px = display_px


func club_carry_body_hand_is_plausible() -> bool:
	if hand_grip_offset_px.length_squared() < 0.0001:
		return false
	if uses_saved_club_grip_on_art():
		# Body hand is a separate field from grip-on-art (yellow 3). Reject only overlay corruption.
		if hand_grip_offset_px.is_equal_approx(idle_club1_hand_grip_offset_px):
			return false
		return true
	return hand_grip_offset_px.y > 0.0


func repair_club_carry_body_hand_from_none(none_preset: WeaponLimbPreset) -> void:
	if weapon_type != ResourceData.ResourceType.WOOD or none_preset == null:
		return
	if club_carry_body_hand_is_plausible():
		return
	if uses_saved_club_grip_on_art() and hand_grip_offset_px.length_squared() > 0.0001:
		if not hand_grip_offset_px.is_equal_approx(idle_club1_hand_grip_offset_px):
			return
	if none_preset.hand_grip_offset_px.length_squared() > 0.0001:
		hand_grip_offset_px = none_preset.hand_grip_offset_px


func resolve_club_carry_body_hand_px() -> Vector2:
	## Body-card green 1h for club carry rows (not grip-on-art yellow 3).
	if club_carry_body_hand_is_plausible():
		return hand_grip_offset_px
	return Vector2.ZERO


func resolve_club_walk1_dominant_hand_export(pose_b: bool) -> Vector2:
	## Walk 1 receipt/export: club weapon arm uses idle carry body hand when off-arm swings.
	if uses_club_walk_off_arm_travel_swing():
		var body_px := resolve_club_carry_body_hand_px()
		if body_px.length_squared() > 0.0001:
			return body_px
	if pose_b:
		return walk1_pull_hand_grip_offset_px
	return walk1_hand_grip_offset_px


func resolve_support_hand_for_mode(mode: TunerAnimMode) -> Vector2:
	if mode == TunerAnimMode.ATTACK:
		if uses_two_hand_grip(weapon_type):
			if attack_pose_inherits_idle():
				return support_hand_idle_offset_px
			return support_hand_offset_px
		if weapon_type == ResourceData.ResourceType.WOOD:
			if attack_pose_inherits_idle():
				return support_hand_idle_offset_px
			if support_hand_offset_px.length_squared() > 0.0001:
				return support_hand_offset_px
			return support_hand_idle_offset_px
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


func resolve_support_shoulder_idle_rest_px() -> Vector2:
	return support_shoulder_offset_px


func resolve_support_shoulder_idle_raised_px() -> Vector2:
	if support_shoulder_idle_raise_offset_px.length_squared() > 0.0001:
		return support_shoulder_idle_raise_offset_px
	return support_shoulder_offset_px


func has_idle_support_shoulder_raise() -> bool:
	return support_shoulder_idle_raise_offset_px.length_squared() > 0.0001


const IDLE_LOWER_ELBOW_LEAD := 1.45
const IDLE_LOWER_HAND_LAG := 0.58
const IDLE_LOWER_SHOULDER_LEAD := 1.15


func _idle_lower_stagger(lower_progress: float) -> Dictionary:
	var lp := clampf(lower_progress, 0.0, 1.0)
	return {
		"elbow_up": 1.0 - _smoothstep01(minf(lp * IDLE_LOWER_ELBOW_LEAD, 1.0)),
		"hand_up": 1.0 - _smoothstep01(lp * IDLE_LOWER_HAND_LAG),
		"shoulder_up": 1.0 - _smoothstep01(minf(lp * IDLE_LOWER_SHOULDER_LEAD, 1.0)),
	}


func resolve_support_shoulder_for_idle_raise(raise_blend: float, lowering: bool = false) -> Vector2:
	var rest_px := resolve_support_shoulder_idle_rest_px()
	var raised_px := resolve_support_shoulder_idle_raised_px()
	if not lowering or raise_blend >= 0.999:
		return rest_px.lerp(raised_px, clampf(raise_blend, 0.0, 1.0))
	var stagger := _idle_lower_stagger(1.0 - clampf(raise_blend, 0.0, 1.0))
	return rest_px.lerp(raised_px, stagger.shoulder_up)


func has_idle_lookback_hand_pose() -> bool:
	return support_hand_idle_raise_lookback_offset_px.length_squared() > 0.0001


func resolve_support_hand_idle_for_idle_scan(
	raise_blend: float,
	scan_blend: float,
	lowering: bool = false
) -> Vector2:
	var rest_px := resolve_support_hand_idle_rest_px()
	var pose_a_px := resolve_support_hand_idle_raised_px()
	var pose_b_px := resolve_support_hand_idle_raised_lookback_px()
	if lowering and raise_blend < 0.999:
		var stagger := _idle_lower_stagger(1.0 - clampf(raise_blend, 0.0, 1.0))
		return rest_px.lerp(pose_a_px, stagger.hand_up)
	var raise_t := clampf(raise_blend, 0.0, 1.0)
	if raise_t <= 0.0001:
		return rest_px
	var raised_px := rest_px.lerp(pose_a_px, raise_t)
	if scan_blend <= 0.0001 or pose_b_px.is_equal_approx(pose_a_px):
		return raised_px
	var scan_t := clampf(scan_blend, 0.0, 1.0) * raise_t
	return pose_a_px.lerp(pose_b_px, scan_t)


func resolve_support_hand_idle_raised_px() -> Vector2:
	return support_hand_idle_raise_offset_px


func resolve_support_hand_idle_raised_lookback_px() -> Vector2:
	if support_hand_idle_raise_lookback_offset_px.length_squared() > 0.0001:
		return support_hand_idle_raise_lookback_offset_px
	return support_hand_idle_raise_offset_px


func has_idle_arm2_raise_pose() -> bool:
	return support_hand_idle_raise_offset_px.length_squared() > 0.0001


func resolve_support_elbow_bend_sign_for_idle_raise(
	raise_blend: float,
	auto_from_facing: float,
	_lowering: bool = false
) -> float:
	## Pole arc picks elbow side — keep rest bend for whole raise/lower (no mid-motion flip).
	return resolve_elbow_bend_sign(false, TunerAnimMode.IDLE, auto_from_facing)


func _default_idle_raise_sweep_pole_px(rest_px: Vector2, raised_px: Vector2) -> Vector2:
	## Mid-raise pole pushed toward body center so the forearm sweeps in front of the torso.
	var rest_shoulder := resolve_support_shoulder_idle_rest_px()
	var raised_shoulder := resolve_support_shoulder_idle_raised_px()
	var rest_hand := resolve_support_hand_idle_rest_px()
	var raised_hand := resolve_support_hand_idle_raised_px()
	var mid_shoulder := rest_shoulder.lerp(raised_shoulder, 0.42)
	var mid_hand := rest_hand.lerp(raised_hand, 0.48)
	var mid_arm := mid_shoulder.lerp(mid_hand, 0.38)
	var toward_center_x := maxf(56.0, -mid_arm.x + 40.0)
	return mid_arm + Vector2(toward_center_x, 36.0)


func _resolve_support_elbow_pole_sweep_px(rest_px: Vector2, raised_px: Vector2) -> Vector2:
	if support_elbow_pole_idle_raise_sweep_px.length_squared() > 0.0001:
		return support_elbow_pole_idle_raise_sweep_px
	return _default_idle_raise_sweep_pole_px(rest_px, raised_px)


func resolve_support_elbow_pole_for_idle_raise(raise_blend: float, lowering: bool = false) -> Vector2:
	var rest_px := support_elbow_pole_idle_px
	if rest_px.length_squared() <= 0.0001:
		rest_px = walk_support_elbow_pole_px
	var raised_px := support_elbow_pole_idle_raise_px
	if raised_px.length_squared() <= 0.0001:
		raised_px = rest_px
	var sweep_px := _resolve_support_elbow_pole_sweep_px(rest_px, raised_px)
	var t: float
	if lowering and raise_blend < 0.999:
		var stagger := _idle_lower_stagger(1.0 - clampf(raise_blend, 0.0, 1.0))
		t = _smoothstep01(stagger.elbow_up)
	else:
		t = _smoothstep01(clampf(raise_blend, 0.0, 1.0))
	return _quadratic_bezier_px(rest_px, sweep_px, raised_px, t)


func resolve_support_elbow_display_for_idle_raise(
	raise_blend: float,
	upper_len_px: float,
	lower_len_px: float
) -> Vector2:
	if raise_blend <= 0.001 or raise_blend >= 0.999 or not has_idle_arm2_raise_pose():
		return Vector2.ZERO
	if upper_len_px <= 0.0 or lower_len_px <= 0.0:
		return Vector2.ZERO
	var t := _smoothstep01(clampf(raise_blend, 0.0, 1.0))
	var rest_shoulder := resolve_support_shoulder_idle_rest_px()
	var raised_shoulder := resolve_support_shoulder_idle_raised_px()
	var rest_hand := resolve_support_hand_idle_rest_px()
	var raised_hand := resolve_support_hand_idle_raised_px()
	var rest_pole := resolve_support_elbow_pole_for_idle_raise(0.0, false)
	var raised_pole := resolve_support_elbow_pole_for_idle_raise(1.0, false)
	var rest_px := support_elbow_pole_idle_px
	if rest_px.length_squared() <= 0.0001:
		rest_px = walk_support_elbow_pole_px
	var raised_px := support_elbow_pole_idle_raise_px
	if raised_px.length_squared() <= 0.0001:
		raised_px = rest_px
	var sweep_pole := _resolve_support_elbow_pole_sweep_px(rest_px, raised_px)
	var mid_shoulder := rest_shoulder.lerp(raised_shoulder, 0.42)
	var mid_hand := rest_hand.lerp(raised_hand, 0.52)
	var rest_elbow := ProceduralArm.estimate_elbow_position(
		rest_shoulder, rest_hand, upper_len_px, lower_len_px, rest_pole, true
	)
	var raised_elbow := ProceduralArm.estimate_elbow_position(
		raised_shoulder, raised_hand, upper_len_px, lower_len_px, raised_pole, true
	)
	var front_elbow := ProceduralArm.estimate_elbow_position(
		mid_shoulder, mid_hand, upper_len_px, lower_len_px, sweep_pole, true
	)
	return _quadratic_bezier_px(rest_elbow, front_elbow, raised_elbow, t)


func resolve_support_elbow_display_for_idle_rest(
	upper_len_px: float,
	lower_len_px: float
) -> Vector2:
	if not has_idle_arm2_raise_pose() or upper_len_px <= 0.0 or lower_len_px <= 0.0:
		return Vector2.ZERO
	var rest_shoulder := resolve_support_shoulder_idle_rest_px()
	var rest_hand := resolve_support_hand_idle_rest_px()
	var rest_pole := support_elbow_pole_idle_px
	if rest_pole.length_squared() <= 0.0001:
		rest_pole = walk_support_elbow_pole_px
	return ProceduralArm.estimate_elbow_position(
		rest_shoulder, rest_hand, upper_len_px, lower_len_px, rest_pole, true
	)


func resolve_support_elbow_display_for_idle_lower(
	raise_blend: float,
	_scan_blend: float,
	lowering: bool,
	upper_len_px: float,
	lower_len_px: float
) -> Vector2:
	if not lowering or raise_blend >= 0.999 or not has_idle_arm2_raise_pose():
		return Vector2.ZERO
	if upper_len_px <= 0.0 or lower_len_px <= 0.0:
		return Vector2.ZERO
	var stagger := _idle_lower_stagger(1.0 - clampf(raise_blend, 0.0, 1.0))
	var rest_shoulder := resolve_support_shoulder_idle_rest_px()
	var raised_shoulder := resolve_support_shoulder_idle_raised_px()
	var rest_hand := resolve_support_hand_idle_rest_px()
	var pose_a := resolve_support_hand_idle_raised_px()
	var rest_pole := resolve_support_elbow_pole_for_idle_raise(0.0, false)
	var raised_pole := resolve_support_elbow_pole_for_idle_raise(1.0, false)
	var rest_elbow := ProceduralArm.estimate_elbow_position(
		rest_shoulder, rest_hand, upper_len_px, lower_len_px, rest_pole, true
	)
	var raised_elbow := ProceduralArm.estimate_elbow_position(
		raised_shoulder, pose_a, upper_len_px, lower_len_px, raised_pole, true
	)
	return rest_elbow.lerp(raised_elbow, stagger.elbow_up)


static func _quadratic_bezier_px(a: Vector2, b: Vector2, c: Vector2, t: float) -> Vector2:
	var u := 1.0 - t
	return a * (u * u) + b * (2.0 * u * t) + c * (t * t)


func set_support_hand_for_mode(mode: TunerAnimMode, display_px: Vector2) -> void:
	if mode == TunerAnimMode.ATTACK:
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
			if weapon_type == ResourceData.ResourceType.WOOD and club_attack_pose_saved:
				if strike_offset_px.length_squared() > 0.0001:
					return strike_offset_px
				return ready_offset_px
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
			if weapon_type == ResourceData.ResourceType.SPEAR or weapon_type == ResourceData.ResourceType.WOOD:
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


func seed_walk1_from_idle_if_unset() -> void:
	if walk1_pose_a_saved or walk1_hand_grip_offset_px.length_squared() > 0.0001:
		return
	if weapon_type == ResourceData.ResourceType.WOOD and idle_club1_grip_authoritative:
		## Club walk1 dominant hand is body-card px — seeded from live idle carry, not overlay grip row.
		walk1_support_hand_offset_px = support_hand_idle_offset_px
		walk1_overlay_offset_px = overlay_offset_idle_px
		walk1_weapon_elbow_pole_px = weapon_elbow_pole_idle_px
		walk1_support_elbow_pole_px = support_elbow_pole_idle_px
		if absf(walk1_weapon_elbow_bend_sign_override) < 0.001 and not walk1_pose_a_saved:
			walk1_weapon_elbow_bend_sign_override = weapon_elbow_bend_sign_override
		if absf(walk1_support_elbow_bend_sign_override) < 0.001 and not walk1_pose_a_saved:
			walk1_support_elbow_bend_sign_override = support_elbow_bend_sign_override
		return
	walk1_hand_grip_offset_px = hand_grip_offset_px
	walk1_support_hand_offset_px = support_hand_idle_offset_px
	walk1_overlay_offset_px = overlay_offset_idle_px
	walk1_weapon_elbow_pole_px = weapon_elbow_pole_idle_px
	walk1_support_elbow_pole_px = support_elbow_pole_idle_px
	if absf(walk1_weapon_elbow_bend_sign_override) < 0.001 and not walk1_pose_a_saved:
		walk1_weapon_elbow_bend_sign_override = weapon_elbow_bend_sign_override
	if absf(walk1_support_elbow_bend_sign_override) < 0.001 and not walk1_pose_a_saved:
		walk1_support_elbow_bend_sign_override = support_elbow_bend_sign_override


func seed_club_walk1_dominant_from_idle_carry(idle_hand_body_px: Vector2) -> void:
	## First-time only — never clobber saved club walk carry on tuner relaunch.
	if weapon_type != ResourceData.ResourceType.WOOD:
		return
	if uses_club_walk_off_arm_travel_swing():
		return
	if walk1_pose_a_saved or walk1_hand_grip_offset_px.length_squared() > 0.0001:
		return
	if idle_hand_body_px.length_squared() < 0.0001:
		return
	seed_walk1_from_idle_if_unset()
	walk1_hand_grip_offset_px = idle_hand_body_px


func sync_club_walk_dominant_from_saved_carry_if_needed() -> void:
	## Repair drift: Walk 1 weapon arm should match saved idle carry on the same preset.
	if weapon_type != ResourceData.ResourceType.WOOD or not uses_saved_club_grip_on_art():
		return
	if not walk1_pose_a_saved:
		return
	var body_px := resolve_club_carry_body_hand_px()
	if body_px.length_squared() < 0.0001:
		return
	if not TunerPoseSeedGuard.vectors_differ(walk1_hand_grip_offset_px, body_px):
		if not TunerPoseSeedGuard.vectors_differ(walk1_pull_hand_grip_offset_px, body_px):
			return
	walk1_hand_grip_offset_px = body_px
	walk1_pull_hand_grip_offset_px = body_px
	walk_hand_grip_offset_px = body_px
	if TunerPoseSeedGuard.vectors_differ(walk1_weapon_elbow_pole_px, weapon_elbow_pole_idle_px):
		walk1_weapon_elbow_pole_px = weapon_elbow_pole_idle_px
		walk1_pull_weapon_elbow_pole_px = weapon_elbow_pole_idle_px
		walk1_weapon_elbow_bend_sign_override = weapon_elbow_bend_sign_override
		walk1_pull_weapon_elbow_bend_sign_override = weapon_elbow_bend_sign_override


func seed_club_walk_off_arm_from_none(none_preset: WeaponLimbPreset) -> void:
	## Club Walk 1: copy empty-hands off-arm swing only — never overwrite tuned club walk rows.
	if weapon_type != ResourceData.ResourceType.WOOD or none_preset == null:
		return
	if not walk1_pose_a_saved:
		return
	if not TunerPoseSeedGuard.vec_unset(walk1_support_hand_offset_px):
		return
	if none_preset.walk1_support_hand_offset_px.length_squared() > 0.0001:
		walk1_support_hand_offset_px = none_preset.walk1_support_hand_offset_px
	if TunerPoseSeedGuard.vec_unset(walk1_pull_support_hand_offset_px):
		if none_preset.walk1_pull_support_hand_offset_px.length_squared() > 0.0001:
			walk1_pull_support_hand_offset_px = none_preset.walk1_pull_support_hand_offset_px
	if TunerPoseSeedGuard.vec_unset(walk1_support_elbow_pole_px):
		if none_preset.walk1_support_elbow_pole_px.length_squared() > 0.0001:
			walk1_support_elbow_pole_px = none_preset.walk1_support_elbow_pole_px
	if TunerPoseSeedGuard.vec_unset(walk1_pull_support_elbow_pole_px):
		if none_preset.walk1_pull_support_elbow_pole_px.length_squared() > 0.0001:
			walk1_pull_support_elbow_pole_px = none_preset.walk1_pull_support_elbow_pole_px
	if absf(walk1_support_elbow_bend_sign_override) < 0.001:
		walk1_support_elbow_bend_sign_override = none_preset.walk1_support_elbow_bend_sign_override
	if absf(walk1_pull_support_elbow_bend_sign_override) < 0.001:
		walk1_pull_support_elbow_bend_sign_override = none_preset.walk1_pull_support_elbow_bend_sign_override


func seed_walk1_pull_from_pose_a_if_unset() -> void:
	if walk1_pose_b_saved or has_walk1_pull_pose():
		return
	if walk1_hand_grip_offset_px.length_squared() < 0.0001:
		seed_walk1_from_idle_if_unset()
	_apply_walk1_pose_b_from_pose_a_template()


func _apply_walk1_pose_a_from_idle_template() -> void:
	walk1_hand_grip_offset_px = hand_grip_offset_px
	walk1_support_hand_offset_px = support_hand_idle_offset_px
	walk1_overlay_offset_px = overlay_offset_idle_px
	walk1_weapon_elbow_pole_px = weapon_elbow_pole_idle_px
	walk1_support_elbow_pole_px = support_elbow_pole_idle_px
	walk1_weapon_elbow_bend_sign_override = weapon_elbow_bend_sign_override
	walk1_support_elbow_bend_sign_override = support_elbow_bend_sign_override
	walk1_pose_a_saved = false


func _apply_walk1_pose_b_from_pose_a_template() -> void:
	if walk1_hand_grip_offset_px.length_squared() < 0.0001:
		_apply_walk1_pose_a_from_idle_template()
	walk1_pull_hand_grip_offset_px = walk1_hand_grip_offset_px + Vector2(-40.0, 20.0)
	walk1_pull_support_hand_offset_px = walk1_support_hand_offset_px + Vector2(40.0, -10.0)
	walk1_pull_weapon_elbow_pole_px = walk1_weapon_elbow_pole_px
	walk1_pull_support_elbow_pole_px = walk1_support_elbow_pole_px
	walk1_pull_weapon_elbow_bend_sign_override = walk1_weapon_elbow_bend_sign_override
	walk1_pull_support_elbow_bend_sign_override = walk1_support_elbow_bend_sign_override
	walk1_pose_b_saved = false


func _apply_gather1_reach_from_idle_template() -> void:
	gather1_hand_grip_offset_px = hand_grip_offset_px + Vector2(8.0, 42.0)
	gather1_support_hand_offset_px = support_hand_idle_offset_px + Vector2(-8.0, 42.0)
	gather1_overlay_offset_px = overlay_offset_idle_px
	gather1_weapon_elbow_pole_px = weapon_elbow_pole_idle_px
	gather1_support_elbow_pole_px = support_elbow_pole_idle_px
	gather1_weapon_elbow_bend_sign_override = weapon_elbow_bend_sign_override
	gather1_support_elbow_bend_sign_override = support_elbow_bend_sign_override
	gather1_reach_saved = false


func _apply_gather1_pull_from_reach_template() -> void:
	if gather1_hand_grip_offset_px.length_squared() < 0.0001:
		_apply_gather1_reach_from_idle_template()
	gather1_pull_hand_grip_offset_px = gather1_hand_grip_offset_px + Vector2(-30.0, -40.0)
	gather1_pull_support_hand_offset_px = gather1_support_hand_offset_px + Vector2(20.0, -30.0)
	gather1_pull_weapon_elbow_pole_px = gather1_weapon_elbow_pole_px
	gather1_pull_support_elbow_pole_px = gather1_support_elbow_pole_px
	gather1_pull_weapon_elbow_bend_sign_override = gather1_weapon_elbow_bend_sign_override
	gather1_pull_support_elbow_bend_sign_override = gather1_support_elbow_bend_sign_override
	gather1_pull_saved = false


func has_walk1_pull_pose() -> bool:
	return (
		walk1_pull_hand_grip_offset_px.length_squared() > 0.0001
		and walk1_pull_support_hand_offset_px.length_squared() > 0.0001
	)


func resolve_walk1_pull_hand(dominant: bool) -> Vector2:
	if dominant and uses_club_walk_off_arm_travel_swing():
		var body_px := resolve_club_carry_body_hand_px()
		if body_px.length_squared() > 0.0001:
			return body_px
	if dominant:
		return walk1_pull_hand_grip_offset_px
	return walk1_pull_support_hand_offset_px


func set_walk1_pull_hand(dominant: bool, display_px: Vector2) -> void:
	if dominant:
		walk1_pull_hand_grip_offset_px = display_px
	else:
		walk1_pull_support_hand_offset_px = display_px


func resolve_walk1_elbow_pole_px(dominant: bool, pose_b: bool = false) -> Vector2:
	if pose_b:
		var pull_pole := walk1_pull_weapon_elbow_pole_px if dominant else walk1_pull_support_elbow_pole_px
		if pull_pole.length_squared() > 0.0001:
			return pull_pole
	return walk1_weapon_elbow_pole_px if dominant else walk1_support_elbow_pole_px


func set_walk1_elbow_pole(dominant: bool, pose_b: bool, display_px: Vector2) -> void:
	if pose_b:
		if dominant:
			walk1_pull_weapon_elbow_pole_px = display_px
		else:
			walk1_pull_support_elbow_pole_px = display_px
	elif dominant:
		walk1_weapon_elbow_pole_px = display_px
	else:
		walk1_support_elbow_pole_px = display_px


func resolve_walk1_elbow_pole_for_keyframe(dominant: bool, cycle_phase: float) -> Vector2:
	if dominant and uses_club_walk_off_arm_travel_swing():
		if weapon_elbow_pole_idle_px.length_squared() > 0.0001:
			return weapon_elbow_pole_idle_px
		return resolve_elbow_pole_px(true, false)
	var pose_a := resolve_walk1_elbow_pole_px(dominant, false)
	if not has_walk1_pull_pose():
		return pose_a
	var pose_b := resolve_walk1_elbow_pole_px(dominant, true)
	return WalkArmMotionScript.body_snapshot_between_keyframes(pose_a, pose_b, cycle_phase)


func copy_walk_pose_to_walk1() -> void:
	if walk1_pose_a_saved:
		return
	seed_walk_from_idle_if_unset()
	walk1_hand_grip_offset_px = walk_hand_grip_offset_px
	walk1_support_hand_offset_px = walk_support_hand_offset_px
	walk1_overlay_offset_px = walk_overlay_offset_px
	walk1_weapon_elbow_pole_px = walk_weapon_elbow_pole_px
	walk1_support_elbow_pole_px = walk_support_elbow_pole_px
	walk1_weapon_elbow_bend_sign_override = walk_weapon_elbow_bend_sign_override
	walk1_support_elbow_bend_sign_override = walk_support_elbow_bend_sign_override


func mark_walk1_pose_a_saved() -> void:
	walk1_pose_a_saved = true


func mark_walk1_pose_b_saved() -> void:
	walk1_pose_b_saved = true


func mark_gather1_reach_saved() -> void:
	gather1_reach_saved = true


func mark_gather1_pull_saved() -> void:
	gather1_pull_saved = true


func seed_gather1_from_idle_if_unset() -> void:
	if gather1_reach_saved or gather1_hand_grip_offset_px.length_squared() > 0.0001:
		return
	gather1_hand_grip_offset_px = hand_grip_offset_px + Vector2(8.0, 42.0)
	gather1_support_hand_offset_px = support_hand_idle_offset_px + Vector2(-8.0, 42.0)
	gather1_overlay_offset_px = overlay_offset_idle_px
	gather1_weapon_elbow_pole_px = weapon_elbow_pole_idle_px
	gather1_support_elbow_pole_px = support_elbow_pole_idle_px
	gather1_weapon_elbow_bend_sign_override = weapon_elbow_bend_sign_override
	gather1_support_elbow_bend_sign_override = support_elbow_bend_sign_override


func seed_gather1_pull_from_reach_if_unset() -> void:
	if gather1_pull_saved or has_gather1_pull_pose():
		return
	_apply_gather1_pull_from_reach_template()


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
	if uses_saved_club_grip_on_art() and idle_club1_hand_grip_is_plausible():
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
	p.seed_idle_lookaround_from_none_if_unset()


static func default_none_idle_raise_hand_px() -> Vector2:
	return Vector2(9.179688, -375.7352)


func seed_idle_lookaround_from_none_if_unset() -> void:
	if support_hand_idle_raise_offset_px.length_squared() > 0.0001:
		return
	if LimbPresetRegistry == null:
		support_hand_idle_raise_offset_px = WeaponLimbPreset.default_none_idle_raise_hand_px()
		if absf(support_elbow_bend_sign_raise_override) < 0.001:
			support_elbow_bend_sign_raise_override = -1.0
		return
	var none_preset := LimbPresetRegistry.get_preset(ResourceData.ResourceType.NONE, body_card_id)
	if none_preset == null or not none_preset.has_idle_arm2_raise_pose():
		return
	support_hand_idle_raise_offset_px = none_preset.support_hand_idle_raise_offset_px
	if absf(none_preset.support_elbow_bend_sign_raise_override) > 0.001:
		support_elbow_bend_sign_raise_override = none_preset.support_elbow_bend_sign_raise_override


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
	# Handle pivot sits on the knob at the bottom of club art — grip is up the shaft (negative Y).
	# Legacy body-card / center-texture saves used large positive Y (e.g. +80, +250).
	if idle_club1_hand_grip_offset_px.y > 0.0:
		return false
	if idle_club1_hand_grip_offset_px.y < -400.0:
		return false
	return true


func migrate_legacy_club_grip_on_art() -> void:
	if weapon_type != ResourceData.ResourceType.WOOD:
		return
	if idle_club1_hand_grip_is_plausible():
		return
	var keep_authoritative := idle_club1_grip_authoritative
	idle_club1_hand_grip_offset_px = default_club_hand_grip_px()
	if keep_authoritative:
		mark_club_grip_on_art_authoritative()


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


func set_gather1_pull_hand(dominant: bool, display_px: Vector2) -> void:
	if dominant:
		gather1_pull_hand_grip_offset_px = display_px
	else:
		gather1_pull_support_hand_offset_px = display_px


func resolve_gather1_elbow_pole_px(dominant: bool, pull: bool = false) -> Vector2:
	if pull:
		var pull_pole := gather1_pull_weapon_elbow_pole_px if dominant else gather1_pull_support_elbow_pole_px
		if pull_pole.length_squared() > 0.0001:
			return pull_pole
	if dominant:
		return gather1_weapon_elbow_pole_px
	return gather1_support_elbow_pole_px


func set_gather1_elbow_pole(dominant: bool, pull: bool, display_px: Vector2) -> void:
	if pull:
		if dominant:
			gather1_pull_weapon_elbow_pole_px = display_px
		else:
			gather1_pull_support_elbow_pole_px = display_px
	elif dominant:
		gather1_weapon_elbow_pole_px = display_px
	else:
		gather1_support_elbow_pole_px = display_px


func mark_pose_row_saved(mode: TunerAnimMode, pose_b: bool = false, gather_pull: bool = false) -> void:
	match mode:
		TunerAnimMode.WALK1:
			if pose_b:
				mark_walk1_pose_b_saved()
			else:
				mark_walk1_pose_a_saved()
		TunerAnimMode.GATHER1:
			if gather_pull:
				mark_gather1_pull_saved()
			else:
				mark_gather1_reach_saved()
		_:
			pass


## Explicit pose row id for tuner commit (see guides/animation_tuner.md reliability contract).
static func resolve_pose_row_id(
	mode: TunerAnimMode,
	pose_b: bool = false,
	gather_pull: bool = false
) -> StringName:
	if mode == TunerAnimMode.WALK1:
		return &"walk1_b" if pose_b else &"walk1_a"
	if mode == TunerAnimMode.GATHER1:
		return &"gather_pull" if gather_pull else &"gather_reach"
	return &""


## Single write path for dominant + support hand display px on the active pose row.
func commit_row_hand_display_px(
	mode: TunerAnimMode,
	pose_b: bool,
	gather_pull: bool,
	dominant_display_px: Vector2,
	support_display_px: Vector2
) -> void:
	var row_id := resolve_pose_row_id(mode, pose_b, gather_pull)
	match row_id:
		&"walk1_b":
			set_walk1_pull_hand(true, dominant_display_px)
			set_walk1_pull_hand(false, support_display_px)
		&"walk1_a":
			walk1_hand_grip_offset_px = dominant_display_px
			walk1_support_hand_offset_px = support_display_px
		&"gather_pull":
			set_gather1_pull_hand(true, dominant_display_px)
			set_gather1_pull_hand(false, support_display_px)
		&"gather_reach":
			gather1_hand_grip_offset_px = dominant_display_px
			gather1_support_hand_offset_px = support_display_px
		_:
			set_hand_grip_for_mode(mode, dominant_display_px)
			set_support_hand_for_mode(mode, support_display_px)


func copy_gather1_pose_from(source: WeaponLimbPreset) -> void:
	if source == null:
		return
	gather1_hand_grip_offset_px = source.gather1_hand_grip_offset_px
	gather1_support_hand_offset_px = source.gather1_support_hand_offset_px
	gather1_overlay_offset_px = source.gather1_overlay_offset_px
	gather1_weapon_elbow_pole_px = source.gather1_weapon_elbow_pole_px
	gather1_support_elbow_pole_px = source.gather1_support_elbow_pole_px
	gather1_weapon_elbow_bend_sign_override = source.gather1_weapon_elbow_bend_sign_override
	gather1_support_elbow_bend_sign_override = source.gather1_support_elbow_bend_sign_override
	gather1_pull_hand_grip_offset_px = source.gather1_pull_hand_grip_offset_px
	gather1_pull_support_hand_offset_px = source.gather1_pull_support_hand_offset_px
	gather1_pull_weapon_elbow_pole_px = source.gather1_pull_weapon_elbow_pole_px
	gather1_pull_support_elbow_pole_px = source.gather1_pull_support_elbow_pole_px
	gather1_reach_saved = source.gather1_reach_saved
	gather1_pull_saved = source.gather1_pull_saved
	walk1_pose_a_saved = source.walk1_pose_a_saved
	walk1_pose_b_saved = source.walk1_pose_b_saved
	if source.gather1_rotation_deg > ROTATION_UNSET + 1.0:
		gather1_rotation_deg = source.gather1_rotation_deg


func resolve_walk_rest_hand_grip() -> Vector2:
	if uses_club_walk_off_arm_travel_swing():
		var body_px := resolve_club_carry_body_hand_px()
		if body_px.length_squared() > 0.0001:
			return body_px
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


func uses_club_walk_off_arm_travel_swing() -> bool:
	## Club Walk 1: weapon arm idle carry; off-arm uses empty-hands Walk 1 Pose 1↔2 keyframe loop.
	return weapon_type == ResourceData.ResourceType.WOOD and walk1_pose_a_saved


func sync_club_walk_off_arm_keyframe_from_none(none_preset: WeaponLimbPreset) -> void:
	## Keep club off-arm Walk 1 rows matched to none / clansmen_1 (source of truth for 2h swing).
	if weapon_type != ResourceData.ResourceType.WOOD or none_preset == null:
		return
	if not walk1_pose_a_saved or not none_preset.walk1_pose_a_saved:
		return
	walk1_support_hand_offset_px = none_preset.walk1_support_hand_offset_px
	walk1_pull_support_hand_offset_px = none_preset.walk1_pull_support_hand_offset_px
	walk1_support_elbow_pole_px = none_preset.walk1_support_elbow_pole_px
	walk1_pull_support_elbow_pole_px = none_preset.walk1_pull_support_elbow_pole_px
	walk1_support_elbow_bend_sign_override = none_preset.walk1_support_elbow_bend_sign_override
	walk1_pull_support_elbow_bend_sign_override = none_preset.walk1_pull_support_elbow_bend_sign_override


func resolve_walk_support_swing_rest_hand() -> Vector2:
	if uses_club_walk_off_arm_travel_swing():
		if walk1_support_hand_offset_px.length_squared() > 0.0001:
			return walk1_support_hand_offset_px
		return support_hand_idle_offset_px
	return resolve_walk_rest_support_hand()


func resolve_walk_tuner_mode() -> TunerAnimMode:
	if (
		walk1_hand_grip_offset_px.length_squared() > 0.0001
		or walk1_support_hand_offset_px.length_squared() > 0.0001
	):
		return TunerAnimMode.WALK1
	return TunerAnimMode.WALK


func resolve_support_elbow_bend_sign_for_walk_swing(auto_from_facing: float) -> float:
	## Keep rest walk bend for the whole swing — no mid-cycle IK flip.
	var mode := resolve_walk_tuner_mode()
	return resolve_elbow_bend_sign(false, mode, auto_from_facing)


func resolve_weapon_elbow_bend_sign_for_walk_swing(auto_from_facing: float) -> float:
	var mode := resolve_walk_tuner_mode()
	return resolve_elbow_bend_sign(true, mode, auto_from_facing)


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
	## Legacy alias — prefer windup vs strike helpers below.
	return resolve_tuner_spear_windup_overlay_px()


func resolve_tuner_spear_strike_overlay_px() -> Vector2:
	if strike_offset_px.length_squared() > 0.0001:
		return strike_offset_px
	return resolve_tuner_spear_windup_overlay_px()


func reset_pose_row_to_defaults(
	mode: TunerAnimMode,
	pose_b: bool = false,
	gather_pull: bool = false
) -> StringName:
	## Reset one pose row to an idle-derived authoring template (not disk, not all zeros).
	var row_id := resolve_pose_row_id(mode, pose_b, gather_pull)
	match row_id:
		&"walk1_a":
			_apply_walk1_pose_a_from_idle_template()
		&"walk1_b":
			_apply_walk1_pose_b_from_pose_a_template()
		&"gather_reach":
			_apply_gather1_reach_from_idle_template()
		&"gather_pull":
			_apply_gather1_pull_from_reach_template()
		_:
			if mode == TunerAnimMode.WALK:
				walk_hand_grip_offset_px = hand_grip_offset_px
				walk_support_hand_offset_px = support_hand_idle_offset_px
				walk_overlay_offset_px = overlay_offset_idle_px
				walk_weapon_elbow_pole_px = weapon_elbow_pole_idle_px
				walk_support_elbow_pole_px = support_elbow_pole_idle_px
				walk_weapon_elbow_bend_sign_override = weapon_elbow_bend_sign_override
				walk_support_elbow_bend_sign_override = support_elbow_bend_sign_override
			else:
				reset_mode_to_defaults(mode)
	return row_id


func reset_mode_to_defaults(mode: TunerAnimMode) -> void:
	## Full variant wipe (prep scripts). UI Reset pose uses reset_pose_row_to_defaults instead.
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
			walk1_pull_hand_grip_offset_px = Vector2.ZERO
			walk1_pull_support_hand_offset_px = Vector2.ZERO
			walk1_pull_weapon_elbow_pole_px = Vector2.ZERO
			walk1_pull_support_elbow_pole_px = Vector2.ZERO
			walk1_pull_weapon_elbow_bend_sign_override = 0.0
			walk1_pull_support_elbow_bend_sign_override = 0.0
			walk1_pose_a_saved = false
			walk1_pose_b_saved = false
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
			gather1_pull_weapon_elbow_pole_px = Vector2.ZERO
			gather1_pull_support_elbow_pole_px = Vector2.ZERO
			gather1_pull_weapon_elbow_bend_sign_override = 0.0
			gather1_pull_support_elbow_bend_sign_override = 0.0
			gather1_reach_saved = false
			gather1_pull_saved = false
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
			attack_rotation_deg = ROTATION_UNSET
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
	var dom_bend := resolve_elbow_bend_sign_override(true, mode)
	var off_bend := resolve_elbow_bend_sign_override(false, mode)
	if weapon_type == ResourceData.ResourceType.WOOD and mode != TunerAnimMode.ATTACK:
		if mode == TunerAnimMode.IDLE and uses_saved_club_grip_on_art():
			return (
				"%s %s — body 1h %s | grip-on-art 3 %s | overlay %s | 1e %s | 2e %s"
				% [
					weapon_slug,
					mode_name,
					str(resolve_club_carry_body_hand_px()),
					str(idle_club1_hand_grip_offset_px),
					str(overlay),
					bend_sign_chat_label(dom_bend),
					bend_sign_chat_label(off_bend),
				]
			)
		if mode == TunerAnimMode.IDLE_CLUB1:
			hand = idle_club1_hand_grip_offset_px
		else:
			hand = resolve_club_overlay_grip_px(mode)
	if weapon_type == ResourceData.ResourceType.SPEAR and mode == TunerAnimMode.ATTACK:
		return (
			"%s attack windup — Y1 %s | Y2 %s | overlay ready %s | strike %s | 1e %s | 2e %s"
			% [
				weapon_slug,
				str(hand_grip_ready_offset_px),
				str(support_hand_offset_px),
				str(ready_offset_px),
				str(strike_offset_px),
				bend_sign_chat_label(dom_bend),
				bend_sign_chat_label(off_bend),
			]
		)
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
	if weapon_type == ResourceData.ResourceType.SPEAR:
		for line in spear_windup_handoff_lines():
			lines.append(line)
	lines.append("arm length: %.0f / %.0f px" % [upper_arm_length, lower_arm_length])
	lines.append("arm thickness: %.0f px (hand end %.0f px)" % [arm_width, hand_width])
	return "\n".join(lines)


func spear_windup_handoff_lines() -> PackedStringArray:
	## Copy/Save handoff: every Attack-row field for spear windup + thrust.
	if weapon_type != ResourceData.ResourceType.SPEAR:
		return PackedStringArray()
	var rot_label := (
		"%.1f" % attack_rotation_deg
		if attack_rotation_deg > ROTATION_UNSET + 1.0
		else "unset (overlay thrust path)"
	)
	var lines: PackedStringArray = PackedStringArray()
	lines.append("--- spear windup (Attack) ---")
	lines.append("spear_attack_pose_saved: %s" % spear_attack_pose_saved)
	lines.append("ready_offset_px (windup overlay): %s" % str(ready_offset_px))
	lines.append("hand_grip_ready_offset_px (Y1 shaft): %s" % str(hand_grip_ready_offset_px))
	lines.append("support_hand_offset_px (Y2 shaft): %s" % str(support_hand_offset_px))
	lines.append("strike_offset_px (thrust peak): %s" % str(strike_offset_px))
	lines.append("attack_rotation_deg: %s" % rot_label)
	lines.append("weapon_elbow_pole_ready_px (1e): %s" % str(weapon_elbow_pole_ready_px))
	lines.append("support_elbow_pole_ready_px (2e): %s" % str(support_elbow_pole_ready_px))
	lines.append(
		"weapon_elbow_bend_sign_ready (1e): %s"
		% bend_sign_chat_label(weapon_elbow_bend_sign_ready_override)
	)
	lines.append(
		"support_elbow_bend_sign_ready (2e): %s"
		% bend_sign_chat_label(support_elbow_bend_sign_ready_override)
	)
	return lines


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
		"support_shoulder_idle_raise_offset_px": support_shoulder_idle_raise_offset_px,
		"support_hand_idle_offset_px": support_hand_idle_offset_px,
		"support_hand_idle_raise_offset_px": support_hand_idle_raise_offset_px,
		"support_hand_idle_raise_lookback_offset_px": support_hand_idle_raise_lookback_offset_px,
		"support_hand_offset_px": support_hand_offset_px,
		"overlay_offset_idle_px": overlay_offset_idle_px,
		"idle_rotation_deg": idle_rotation_deg,
		"attack_rotation_deg": attack_rotation_deg,
		"walk_rotation_deg": walk_rotation_deg,
		"walk1_rotation_deg": walk1_rotation_deg,
		"gather1_rotation_deg": gather1_rotation_deg,
		"idle_club1_rotation_deg": idle_club1_rotation_deg,
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
		"walk1_pull_hand_grip_offset_px": walk1_pull_hand_grip_offset_px,
		"walk1_pull_support_hand_offset_px": walk1_pull_support_hand_offset_px,
		"walk1_pull_weapon_elbow_pole_px": walk1_pull_weapon_elbow_pole_px,
		"walk1_pull_support_elbow_pole_px": walk1_pull_support_elbow_pole_px,
		"walk1_pull_weapon_elbow_bend_sign_override": walk1_pull_weapon_elbow_bend_sign_override,
		"walk1_pull_support_elbow_bend_sign_override": walk1_pull_support_elbow_bend_sign_override,
		"walk1_pose_a_saved": walk1_pose_a_saved,
		"walk1_pose_b_saved": walk1_pose_b_saved,
		"gather1_hand_grip_offset_px": gather1_hand_grip_offset_px,
		"gather1_support_hand_offset_px": gather1_support_hand_offset_px,
		"gather1_overlay_offset_px": gather1_overlay_offset_px,
		"gather1_weapon_elbow_pole_px": gather1_weapon_elbow_pole_px,
		"gather1_support_elbow_pole_px": gather1_support_elbow_pole_px,
		"gather1_weapon_elbow_bend_sign_override": gather1_weapon_elbow_bend_sign_override,
		"gather1_support_elbow_bend_sign_override": gather1_support_elbow_bend_sign_override,
		"gather1_pull_hand_grip_offset_px": gather1_pull_hand_grip_offset_px,
		"gather1_pull_support_hand_offset_px": gather1_pull_support_hand_offset_px,
		"gather1_pull_weapon_elbow_pole_px": gather1_pull_weapon_elbow_pole_px,
		"gather1_pull_support_elbow_pole_px": gather1_pull_support_elbow_pole_px,
		"gather1_pull_weapon_elbow_bend_sign_override": gather1_pull_weapon_elbow_bend_sign_override,
		"gather1_pull_support_elbow_bend_sign_override": gather1_pull_support_elbow_bend_sign_override,
		"gather1_reach_saved": gather1_reach_saved,
		"gather1_pull_saved": gather1_pull_saved,
		"idle_club1_hand_grip_offset_px": idle_club1_hand_grip_offset_px,
		"idle_club1_support_hand_offset_px": idle_club1_support_hand_offset_px,
		"idle_club1_overlay_offset_px": idle_club1_overlay_offset_px,
		"idle_club1_weapon_elbow_pole_px": idle_club1_weapon_elbow_pole_px,
		"idle_club1_support_elbow_pole_px": idle_club1_support_elbow_pole_px,
		"idle_club1_weapon_elbow_bend_sign_override": idle_club1_weapon_elbow_bend_sign_override,
		"idle_club1_support_elbow_bend_sign_override": idle_club1_support_elbow_bend_sign_override,
		"idle_club1_grip_authoritative": idle_club1_grip_authoritative,
		"club_attack_pose_saved": club_attack_pose_saved,
		"club_windup_idle_loop_sec": club_windup_idle_loop_sec,
		"club_windup_idle_key_a_ready_offset_px": club_windup_idle_key_a_ready_offset_px,
		"club_windup_idle_key_a_hand_grip_offset_px": club_windup_idle_key_a_hand_grip_offset_px,
		"club_windup_idle_key_a_support_hand_offset_px": club_windup_idle_key_a_support_hand_offset_px,
		"club_windup_idle_key_b_ready_offset_px": club_windup_idle_key_b_ready_offset_px,
		"club_windup_idle_key_b_hand_grip_offset_px": club_windup_idle_key_b_hand_grip_offset_px,
		"club_windup_idle_key_b_support_hand_offset_px": club_windup_idle_key_b_support_hand_offset_px,
		"club_windup_idle_key_a_rotation_deg": club_windup_idle_key_a_rotation_deg,
		"club_windup_idle_key_b_rotation_deg": club_windup_idle_key_b_rotation_deg,
		"club_windup_idle_rest_rotation_deg": club_windup_idle_rest_rotation_deg,
		"club_windup_support_motion_scale": club_windup_support_motion_scale,
		"club_strike_support_motion_frac": club_strike_support_motion_frac,
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
		"support_elbow_pole_idle_raise_px": support_elbow_pole_idle_raise_px,
		"support_elbow_pole_idle_raise_sweep_px": support_elbow_pole_idle_raise_sweep_px,
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
	p.ensure_unified_clips(null)
	return p


func ensure_unified_clips(registry: Node = null) -> void:
	if unified_clips_initialized and not animation_clips.is_empty():
		return
	animation_clips.clear()
	CharacterAnimationPresetStoreScript.ensure_all_clips(self, registry)
	unified_clips_initialized = true


func get_unified_clip(clip_id: StringName):
	return CharacterAnimationPresetStoreScript.get_clip(self, clip_id)


func current_pose(clip_id: StringName, pose_index: int):
	var clip = get_unified_clip(clip_id)
	if clip == null:
		return CharacterAnimationPoseScript.new()
	return clip.pose_at_index(pose_index)
