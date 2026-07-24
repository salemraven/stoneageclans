extends Resource
class_name ProceduralArmConfig

## Tweakable layout for procedural Line2D arms (player first; reusable per body type).

## Red shoulder on body card; green hand grip on weapon overlay (display px, pre-scale).
@export var weapon_shoulder_offset_px := Vector2.ZERO
@export var hand_grip_offset_px := Vector2(0.0, 72.0)
@export var hand_grip_ready_offset_px := Vector2.ZERO
@export var support_hand_grip_offset_px := Vector2(6.0, 52.0)
@export var support_hand_idle_offset_px := Vector2(-12.0, 30.0)

# Legacy alias — prefer weapon_shoulder_offset_px.
@export var card_center_offset := Vector2.ZERO

# Support (idle) arm shoulder anchors relative to body sprite origin (display pixels, pre-flip).
@export var shoulder_offset_right := Vector2(18.0, -20.0)
@export var shoulder_offset_left := Vector2(-18.0, -20.0)

# Segment lengths in display pixels (scaled by sprite.scale).
@export var upper_arm_length := 120.0
@export var lower_arm_length := 120.0
@export var weapon_upper_arm_length := -1.0
@export var weapon_lower_arm_length := -1.0
@export var support_upper_arm_length := -1.0
@export var support_lower_arm_length := -1.0

## How far the elbow can straighten (min) and curl (max), in degrees of fold from a straight arm.
@export_range(0.0, 45.0) var elbow_fold_min_deg := 8.0
@export_range(60.0, 170.0) var elbow_fold_max_deg := 150.0

# Line2D appearance.
@export var arm_width := 14.0
@export var hand_width := 10.0
@export_range(0.5, 2.0) var width_genetics_mult := 1.0
@export var arm_color := Color(0.55, 0.42, 0.35, 1.0)
@export var arm_texture: Texture2D

# IK: elbow bends toward shoulder + outward * this distance.
@export var elbow_hint_outward := 18.0
@export var weapon_elbow_pole_idle_px := Vector2.ZERO
@export var weapon_elbow_pole_ready_px := Vector2.ZERO
@export var support_elbow_pole_idle_px := Vector2.ZERO
@export var support_elbow_pole_ready_px := Vector2.ZERO

# Idle hand targets relative to body sprite origin (display pixels, pre-flip).
@export var idle_hand_offset_right := Vector2(12.0, 30.0)
@export var idle_hand_offset_left := Vector2(-12.0, 30.0)

# Draw above character card and weapon overlay (YSortUtils.Z_ABOVE_WORLD).
@export var arm_z_index := 4095
@export var line_endpoint_inset_px := 3.0
@export var endpoint_marker_radius := 5.0
@export var shoulder_marker_color := Color(0.9, 0.2, 0.2, 1.0)
@export var hand_marker_color := Color(0.2, 0.8, 0.2, 1.0)
@export var debug_marker_radius := 4.0
@export var elbow_joint_radius := 7.0
@export var show_elbow_joints := false


func resolve_weapon_upper_arm_length() -> float:
	return upper_arm_length


func resolve_weapon_lower_arm_length() -> float:
	return lower_arm_length


func resolve_support_upper_arm_length() -> float:
	return upper_arm_length


func resolve_support_lower_arm_length() -> float:
	return lower_arm_length
