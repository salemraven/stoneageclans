extends RefCounted
class_name CharacterCardPartsRegistry

## Layered character-card parts (blank body + head) for the animation tuner and future card pipeline.

const PARTS_DIR := "res://assets/character_cards/"
const BLANK_BODY_PATH := PARTS_DIR + "blank_body.png"
const BLANK_HEAD_PATH := PARTS_DIR + "blank_head.png"

## Neck socket on the body texture (pixels from image top-left). Tune when art changes.
const BODY_NECK_SOCKET_PX := Vector2(128.0, 52.0)

## Head pivot on the head texture (pixels from image top-left). Usually bottom-center of the head.
const HEAD_PIVOT_PX := Vector2(128.0, 155.0)


static func load_blank_body() -> Texture2D:
	if ResourceLoader.exists(BLANK_BODY_PATH):
		return load(BLANK_BODY_PATH) as Texture2D
	return null


static func load_blank_head() -> Texture2D:
	if ResourceLoader.exists(BLANK_HEAD_PATH):
		return load(BLANK_HEAD_PATH) as Texture2D
	return null


static func head_pivot_on_body_local(body_tex: Texture2D) -> Vector2:
	if body_tex == null:
		return Vector2.ZERO
	var size := Vector2(body_tex.get_width(), body_tex.get_height())
	var center := size * 0.5
	return BODY_NECK_SOCKET_PX - center


static func head_sprite_offset_local(head_tex: Texture2D) -> Vector2:
	if head_tex == null:
		return Vector2.ZERO
	var size := Vector2(head_tex.get_width(), head_tex.get_height())
	var center := size * 0.5
	return center - HEAD_PIVOT_PX
