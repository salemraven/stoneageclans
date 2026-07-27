extends RefCounted
class_name PlaceholderCardRegistry

const TARGET_DISPLAY_HEIGHT := 128.0
const CLANSMEN_CARD_COUNT := 18
const CARDS_DIR := "res://assets/placeholder_cards/"

const WOMAN_CARD_PATH := CARDS_DIR + "woman_card.png"
const BABY_CARD_PATH := "res://assets/sprites/baby.png"

const CLUB_TEXTURE_SIZE := Vector2(471.0, 835.0)
## club.png: opaque art ~204–268 × 482–833 inside 471×835 (handle knob at bottom of art).
const CLUB_OPAQUE_BBOX := Rect2(204.0, 482.0, 65.0, 352.0)
## Measured from opaque pixels — bottom 15% center (handle knob), not full-texture center.
const CLUB_HANDLE_TEXTURE_NX := 0.5091
const CLUB_HANDLE_TEXTURE_NY := 0.9648
## spear.png: primary grip at shaft midpoint (texture center Y); overlay pivot stays centered for thrust.
const SPEAR_GRIP_TEXTURE_NY := 0.5

const TOOL_OVERLAY_PATHS := {
	ResourceData.ResourceType.WOOD: CARDS_DIR + "club.png",
	ResourceData.ResourceType.SPEAR: CARDS_DIR + "spear.png",
	ResourceData.ResourceType.AXE: CARDS_DIR + "axe.png",
	ResourceData.ResourceType.OLDOWAN: CARDS_DIR + "oldowan.png",
	ResourceData.ResourceType.PICK: CARDS_DIR + "pick.png",
}

## Large overlay PNGs (spear/axe/club) are 471×835; pick/oldowan are smaller and scaled up via TOOL_OVERLAY_SCALE.
const TOOL_OVERLAY_REFERENCE_HEIGHT := 835.0
## Card overlay spear — larger than 1:1 PNG so it reads on the body card; grip stays at SPEAR_GRIP_TEXTURE_NY.
const SPEAR_OVERLAY_SCALE := 1.52

## Display-pixel nudge after body card scale (x = right, y = up). Same top-right slot as spear.
const TOOL_OVERLAY_OFFSET_PX := {
	ResourceData.ResourceType.SPEAR: Vector2(22.0, -34.0),
	ResourceData.ResourceType.AXE: Vector2(22.0, -34.0),
	ResourceData.ResourceType.WOOD: Vector2(22.0, -34.0),
	ResourceData.ResourceType.PICK: Vector2(22.0, -34.0),
	ResourceData.ResourceType.OLDOWAN: Vector2(22.0, -34.0),
}

const TOOL_OVERLAY_SCALE := {
	ResourceData.ResourceType.SPEAR: SPEAR_OVERLAY_SCALE,
	ResourceData.ResourceType.AXE: 1.0,
	ResourceData.ResourceType.WOOD: 1.0,
	ResourceData.ResourceType.PICK: TOOL_OVERLAY_REFERENCE_HEIGHT / 32.0,
	ResourceData.ResourceType.OLDOWAN: TOOL_OVERLAY_REFERENCE_HEIGHT / 64.0,
}

const WALK_BOUNCE_AMPLITUDE := 2.5
const WALK_BOUNCE_SPEED := 8.0
## Shared walk tempo — body bounce, head bob, overlay lag, and arm swing stay in sync.
const WALK_RHYTHM_SPEED_SCALE := 0.62
## Weapon overlay lags the card body bounce (radians) so the tool follows slightly behind.
const WEAPON_OVERLAY_BOUNCE_PHASE_LAG_RAD := 0.55
const WEAPON_OVERLAY_BOUNCE_AMP_SCALE := 0.9

static func effective_walk_bounce_speed() -> float:
	return WALK_BOUNCE_SPEED * WALK_RHYTHM_SPEED_SCALE

## Overlay combat: idle = natural vertical in corner (0°); ready offset tilts from idle; spear tracks cursor.
const WEAPON_COMBAT_PROFILES := {
	ResourceData.ResourceType.SPEAR: {
		"texture_tip_deg": -90.0,
		"idle_rotation_deg": 0.0,
		"ready_rotation_offset_deg": 0.0,
		"ready_offset_px": Vector2(8.0, 6.0),
		"ready_forward_px": 24.0,
		"pivot_y_frac": SPEAR_GRIP_TEXTURE_NY,
		"attack_kind": 0,  # WeaponOverlayCombat.AttackKind.THRUST
		"strike_duration": 0.24,
		"recovery_duration": 0.22,
		"combat_recovery_duration": 0.14,
		"combat_recovery_duration_ready": 0.09,
		"thrust_windup_px": 3.0,
		"thrust_extend_px": 56.0,
		"thrust_windup_frac": 0.1,
		"thrust_lunge_frac": 0.5,
		"thrust_hit_lunge_frac": 0.88,
		"thrust_lunge_trans": "sine",
		"thrust_lunge_ease": "in_out",
		"thrust_recover_ease": "out",
	},
	ResourceData.ResourceType.WOOD: {
		"texture_tip_deg": -90.0,
		"idle_rotation_deg": 0.0,
		# Ready = raised (~10 o'clock right / mirrored left). Pivot = handle knob on art.
		"ready_rotation_offset_deg": 50.0,
		"pivot_x_frac": CLUB_HANDLE_TEXTURE_NX,
		"pivot_y_frac": CLUB_HANDLE_TEXTURE_NY,
		# Smooth heavy smash — long downswing, lower hit point.
		"swing_windup_deg": 28.0,
		"swing_arc_deg": 114.0,
		"swing_windup_frac": 0.08,
		"swing_strike_frac": 0.64,
		"swing_pull_back_px": 14.0,
		"swing_pull_up_px": 10.0,
		"swing_lunge_forward_px": 20.0,
		"swing_lunge_down_px": 72.0,
		"swing_windup_trans": "sine",
		"swing_windup_ease": "out",
		"swing_strike_trans": "cubic",
		"swing_strike_ease": "in_out",
		"swing_recover_trans": "cubic",
		"swing_recover_ease": "out",
		"attack_kind": 1,  # SWING_DOWN
		"strike_duration": 0.30,
		"recovery_duration": 0.18,
		"combat_recovery_duration": 0.16,
		"combat_recovery_duration_ready": 0.06,
	},
	ResourceData.ResourceType.AXE: {
		"texture_tip_deg": -90.0,
		"idle_rotation_deg": 0.0,
		"ready_rotation_offset_deg": 42.0,
		"pivot_y_frac": 0.88,
		# Snappy chop — former club swing (quick windup, sharp downswing).
		"swing_windup_deg": 42.0,
		"swing_arc_deg": 110.0,
		"swing_windup_frac": 0.14,
		"swing_strike_frac": 0.52,
		"swing_pull_back_px": 18.0,
		"swing_pull_up_px": 16.0,
		"swing_lunge_forward_px": 32.0,
		"swing_lunge_down_px": 42.0,
		"attack_kind": 1,
		"strike_duration": 0.22,
		"recovery_duration": 0.14,
		"combat_recovery_duration": 0.16,
		"combat_recovery_duration_ready": 0.06,
	},
	ResourceData.ResourceType.PICK: {
		"texture_tip_deg": -90.0,
		"idle_rotation_deg": 0.0,
		"ready_rotation_offset_deg": 50.0,
		"pivot_y_frac": 0.88,
		"swing_arc_deg": 90.0,
		"swing_windup_deg": 14.0,
		"swing_windup_frac": 0.12,
		"swing_strike_frac": 0.5,
		"swing_pull_back_px": 8.0,
		"swing_pull_up_px": 5.0,
		"swing_lunge_forward_px": 22.0,
		"swing_lunge_down_px": 22.0,
		"attack_kind": 1,
		"strike_duration": 0.22,
		"recovery_duration": 0.6,
	},
	ResourceData.ResourceType.OLDOWAN: {
		"texture_tip_deg": -90.0,
		"idle_rotation_deg": 0.0,
		"ready_rotation_offset_deg": 50.0,
		"pivot_y_frac": 0.88,
		"swing_arc_deg": 90.0,
		"swing_windup_deg": 12.0,
		"swing_windup_frac": 0.1,
		"swing_strike_frac": 0.52,
		"swing_pull_back_px": 8.0,
		"swing_pull_up_px": 4.0,
		"swing_lunge_forward_px": 20.0,
		"swing_lunge_down_px": 18.0,
		"attack_kind": 1,
		"strike_duration": 0.18,
		"recovery_duration": 0.45,
	},
}


func get_weapon_combat_profile(resource_type: ResourceData.ResourceType) -> Dictionary:
	return WEAPON_COMBAT_PROFILES.get(resource_type, {
		"texture_tip_deg": -90.0,
		"idle_rotation_deg": 0.0,
		"ready_rotation_offset_deg": -30.0,
		"attack_kind": 1,
		"strike_duration": 0.15,
		"recovery_duration": 0.5,
	})

var _clansmen_cards: Array[Texture2D] = []
var _woman_card: Texture2D
var _baby_card: Texture2D
var _tool_overlays: Dictionary = {}


func get_clansmen_card(index: int) -> Texture2D:
	var clamped := clampi(index, 1, CLANSMEN_CARD_COUNT)
	if _clansmen_cards.size() < clamped or _clansmen_cards[clamped - 1] == null:
		_ensure_clansmen_loaded(clamped)
	return _clansmen_cards[clamped - 1]


func get_woman_card() -> Texture2D:
	if _woman_card == null:
		_woman_card = load(WOMAN_CARD_PATH) as Texture2D
	return _woman_card


func get_baby_card() -> Texture2D:
	if _baby_card == null:
		_baby_card = load(BABY_CARD_PATH) as Texture2D
	return _baby_card


func get_tool_overlay(resource_type: ResourceData.ResourceType) -> Texture2D:
	if not TOOL_OVERLAY_PATHS.has(resource_type):
		return null
	if not _tool_overlays.has(resource_type):
		var path: String = TOOL_OVERLAY_PATHS[resource_type]
		if ResourceLoader.exists(path):
			_tool_overlays[resource_type] = load(path) as Texture2D
	return _tool_overlays.get(resource_type)


func get_tool_overlay_offset_px(resource_type: ResourceData.ResourceType) -> Vector2:
	return TOOL_OVERLAY_OFFSET_PX.get(resource_type, Vector2.ZERO)


func get_tool_overlay_scale(resource_type: ResourceData.ResourceType) -> float:
	return float(TOOL_OVERLAY_SCALE.get(resource_type, 1.0))


func get_card_scale(texture: Texture2D) -> float:
	if texture == null or texture.get_height() <= 0:
		return 1.0
	return TARGET_DISPLAY_HEIGHT / float(texture.get_height())


func get_card_foot_y(texture: Texture2D) -> float:
	if texture == null:
		return -128.0
	var scale := get_card_scale(texture)
	var half_visual := texture.get_height() * scale * 0.5
	return -half_visual


## World-space Y for CollectionProgress above a card body (negative = up).
const PROGRESS_CIRCLE_RADIUS := 18.0
const PROGRESS_CIRCLE_GAP_ABOVE_CARD := 12.0


func get_progress_display_y(texture: Texture2D) -> float:
	if texture == null:
		return -88.0
	var foot_y: float = get_card_foot_y(texture)
	var half_visual: float = texture.get_height() * get_card_scale(texture) * 0.5
	return foot_y - half_visual - PROGRESS_CIRCLE_RADIUS - PROGRESS_CIRCLE_GAP_ABOVE_CARD


func _ensure_clansmen_loaded(up_to_index: int) -> void:
	while _clansmen_cards.size() < CLANSMEN_CARD_COUNT:
		_clansmen_cards.append(null)
	for i in range(1, up_to_index + 1):
		if _clansmen_cards[i - 1] != null:
			continue
		var path := CARDS_DIR + "clansmen_card%d.png" % i
		if ResourceLoader.exists(path):
			_clansmen_cards[i - 1] = load(path) as Texture2D
