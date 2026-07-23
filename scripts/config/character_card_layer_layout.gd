extends Resource
class_name CharacterCardLayerLayout

## Saved placement for layered character-card body + head parts.

@export var layout_id: String = "layered_blank_1"
@export var body_texture_path: String = "res://assets/character_cards/body1.png"
@export var head_texture_path: String = "res://assets/character_cards/head1.png"

## Neck socket on the body texture (pixels from image top-left).
@export var body_neck_socket_px: Vector2 = Vector2(176.0, 24.0)

## Head pivot on the head texture (pixels from image top-left). Usually bottom-center of the head.
@export var head_pivot_px: Vector2 = Vector2(153.0, 345.0)
