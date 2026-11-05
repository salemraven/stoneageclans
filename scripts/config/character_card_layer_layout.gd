extends Resource
class_name CharacterCardLayerLayout

## Saved placement for layered character-card body + head parts.

@export var layout_id: String = "layered_blank_1"
@export var body_texture_path: String = "res://assets/character_cards/body1.png"
@export var head_texture_path: String = "res://assets/character_cards/head1.png"

## Neck socket on the body texture (pixels from image top-left).
@export var body_neck_socket_px: Vector2 = Vector2(180.0, 76.0)

## Head pivot on the head texture (pixels from image top-left). Usually bottom-center of the head.
@export var head_pivot_px: Vector2 = Vector2(153.0, 345.0)

## Nudge body layer in card texture pixels (from centered origin).
@export var body_offset_px: Vector2 = Vector2.ZERO

## Optional hair sheet (500×700) — see guides/character_layers.md.
@export var hair_texture_path: String = "res://assets/character_cards/hair/01hair.png"

## Pixel on the hair texture that sits on `hair_attach_local_px` (from image top-left).
@export var hair_pivot_px: Vector2 = Vector2(249.5, 655.0)

## Attach point on HeadPivot (head-local) where `hair_pivot_px` is pinned — drag R pin in tuner.
## Stored east-facing; X mirrors automatically when travel facing is left.
@export var hair_attach_local_px: Vector2 = Vector2(0.0, -265.0)

## Spotted tunic. Receipt 2026-10-11T13:13:27. Slide from the neck pin.
@export var clothing_offset_px: Vector2 = Vector2(61.2, 39.17)

## 1 = the measured fit on the body. The tuner size slider changes this.
@export var clothing_scale_mul: float = 1.35

## Fur cloak (hide2). Receipt 2026-10-11T14:51:08. Slide from the neck pin.
@export var clothing2_offset_px: Vector2 = Vector2(-14.29, -36.46)

@export var clothing2_scale_mul: float = 1.2

## Tooth harness (hide3). Receipt 2026-10-11T15:30:53. Slide from the neck pin.
@export var clothing3_offset_px: Vector2 = Vector2(-7.34, -46.51)

@export var clothing3_scale_mul: float = 1.1

## Woven fiber vest (fiber1). Receipt 2026-10-11T16:11:56. Slide from the neck pin.
@export var clothing4_offset_px: Vector2 = Vector2(-9.79, -34.27)

@export var clothing4_scale_mul: float = 1.2

## Dot eyes on HeadPivot (east-facing; X mirrors when the body faces left).
## Receipt 2026-10-18T00:14:32 (eyes-edit idle copy).
@export var eye_left_local_px: Vector2 = Vector2(5.12, -179.43)

@export var eye_right_local_px: Vector2 = Vector2(98.14, -184.33)

## Scales both eye ovals. 1.0 is the fitted middle. Genes nudge this a little.
@export var eye_scale_mul: float = 1.0

## 1.0 is the drawn oval. Higher is a bit wider, lower a bit rounder.
@export var eye_aspect: float = 1.0

## Pupil tint. The white of the eye stays white.
@export var pupil_color: Color = Color(0.05, 0.04, 0.03, 1.0)

## nose2.png on HeadPivot. East-facing; X mirrors when the body faces left.
## Receipt 2026-10-18T02:11:13 (eyes-edit idle copy).
@export var nose_texture_path: String = "res://assets/characters/Noses/nose2.png"
@export var nose_local_px: Vector2 = Vector2(19.81, -147.61)
@export var nose_scale_mul: float = 0.9

## brow4.png on HeadPivot. East-facing; X mirrors when the body faces left.
## Receipt 2026-10-18T02:15:06.
@export var brow_texture_path: String = "res://assets/characters/Brow/brow4.png"
@export var brow_local_px: Vector2 = Vector2(17.13, -173.5)
@export var brow_scale_mul: float = 0.9
