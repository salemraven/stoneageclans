extends Resource
class_name ProceduralArmConfig

## Tweakable layout for procedural Line2D arms (player first; reusable per body type).

# Card anchor: offset from body Sprite2D origin (centered card texture). Weapon arm runs card center -> weapon overlay center.
@export var card_center_offset := Vector2.ZERO

# Support (idle) arm shoulder anchors relative to body sprite origin (display pixels, pre-flip).
@export var shoulder_offset_right := Vector2(18.0, -20.0)
@export var shoulder_offset_left := Vector2(-18.0, -20.0)

# Segment lengths in display pixels (scaled by sprite.scale).
@export var upper_arm_length := 24.0
@export var lower_arm_length := 22.0

# Line2D appearance.
@export var arm_width := 8.0
@export var hand_width := 6.0
@export_range(0.5, 2.0) var width_genetics_mult := 1.0
@export var arm_color := Color(0.55, 0.42, 0.35, 1.0)
@export var arm_texture: Texture2D

# IK: elbow bends toward shoulder + outward * this distance.
@export var elbow_hint_outward := 18.0

# Idle hand targets relative to body sprite origin (display pixels, pre-flip).
@export var idle_hand_offset_right := Vector2(12.0, 30.0)
@export var idle_hand_offset_left := Vector2(-12.0, 30.0)

# Draw above character card and weapon overlay (YSortUtils.Z_ABOVE_WORLD).
@export var arm_z_index := 4095
@export var endpoint_marker_radius := 5.0
@export var shoulder_marker_color := Color(0.9, 0.2, 0.2, 1.0)
@export var hand_marker_color := Color(0.2, 0.8, 0.2, 1.0)
@export var debug_marker_radius := 4.0
