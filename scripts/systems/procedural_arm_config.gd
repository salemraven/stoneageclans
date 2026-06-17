extends Resource
class_name ProceduralArmConfig

## Tweakable layout for procedural Line2D arms (player first; reusable per body type).

# Shoulder anchors relative to body Sprite2D origin (display pixels, pre-flip).
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

# Grip point: offset from WeaponOverlay node origin in overlay-local pixels (Y+ = toward handle when vertical).
@export var grip_offset_from_overlay_px := Vector2(0.0, 72.0)

# Idle hand targets relative to body sprite origin (display pixels, pre-flip).
@export var idle_hand_offset_right := Vector2(12.0, 30.0)
@export var idle_hand_offset_left := Vector2(-12.0, 30.0)

# Draw order relative to body sprite.
@export var arm_z_index := 2
@export var debug_marker_radius := 4.0
