extends Control

const SPRITE_PATH := "res://assets/sprites/walk.png"

@onready var texture_rect: TextureRect = $TextureRect

func _ready() -> void:
	var tex := load(SPRITE_PATH) as Texture2D
	if tex:
		texture_rect.texture = tex
		texture_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		texture_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT
		print("SpriteSheetViewer: Loaded %s (%dx%d)" % [SPRITE_PATH, tex.get_width(), tex.get_height()])
	else:
		push_error("SpriteSheetViewer: No sprite found at %s" % SPRITE_PATH)
