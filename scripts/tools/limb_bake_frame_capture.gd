extends RefCounted
class_name LimbBakeFrameCapture

## Renders body + head + weapon (no arm lines) into a fixed-size bake frame — headless-safe compositing.

const TunerBodyVisualScript = preload("res://scripts/tools/tuner_body_visual.gd")

const FRAME_W := 128
const FRAME_H := 128
const FOOT_ANCHOR := Vector2(64.0, 120.0)


func capture_rig(rig: LimbTunerRig) -> Image:
	var img := Image.create(FRAME_W, FRAME_H, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	if rig == null or rig.sprite == null:
		return img
	var foot_global: Vector2 = rig.sprite.global_position
	var foot_scale: float = absf(rig.sprite.scale.x)
	if foot_scale < 0.001:
		foot_scale = 1.0
	var layers: Array[Dictionary] = []
	_collect_sprite_layers(rig.sprite.get_node_or_null("BodyVisual") as Node2D, foot_global, foot_scale, layers)
	var head_pivot := rig.sprite.get_node_or_null("HeadPivot") as Node2D
	if head_pivot:
		_collect_node_layers(head_pivot, foot_global, foot_scale, layers)
	_collect_sprite_layer(rig.weapon_overlay, foot_global, foot_scale, layers)
	layers.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		return int(a.get("z", 0)) < int(b.get("z", 0))
	)
	for layer in layers:
		_draw_layer(img, layer)
	return img


func _collect_sprite_layers(node: Node2D, foot_global: Vector2, foot_scale: float, layers: Array[Dictionary]) -> void:
	if node == null:
		return
	if node is Sprite2D:
		_collect_sprite_layer(node as Sprite2D, foot_global, foot_scale, layers)
		return
	for child in node.get_children():
		if child is Sprite2D:
			_collect_sprite_layer(child as Sprite2D, foot_global, foot_scale, layers)
		elif child is Node2D:
			_collect_node_layers(child as Node2D, foot_global, foot_scale, layers)


func _collect_node_layers(node: Node2D, foot_global: Vector2, foot_scale: float, layers: Array[Dictionary]) -> void:
	if node == null:
		return
	for child in node.get_children():
		if child is Sprite2D:
			_collect_sprite_layer(child as Sprite2D, foot_global, foot_scale, layers)
		elif child is Node2D:
			_collect_node_layers(child as Node2D, foot_global, foot_scale, layers)


func _collect_sprite_layer(source: Sprite2D, foot_global: Vector2, foot_scale: float, layers: Array[Dictionary]) -> void:
	if source == null or source.texture == null or not source.visible:
		return
	var z := 0
	if source.get_parent() and str(source.get_parent().name) == "BodyVisual":
		z = TunerBodyVisualScript.BODY_DRAW_Z_INDEX
	elif source.name == "HeadSprite":
		z = TunerBodyVisualScript.HEAD_DRAW_Z_INDEX
	elif source.name == "WeaponOverlay":
		z = TunerBodyVisualScript.WEAPON_DRAW_Z_INDEX
	var xf := source.get_global_transform()
	var world_scale := Vector2(xf.x.length(), xf.y.length())
	layers.append({
		"texture": source.texture,
		"pos": (source.global_position - foot_global) / foot_scale + FOOT_ANCHOR,
		"rotation": source.global_rotation,
		"scale": world_scale / foot_scale,
		"flip_h": source.flip_h,
		"flip_v": source.flip_v,
		"offset": source.offset,
		"centered": source.centered,
		"z": z,
	})


func _draw_layer(target: Image, layer: Dictionary) -> void:
	var tex: Texture2D = layer.get("texture") as Texture2D
	if tex == null:
		return
	var piece := _texture_to_image(tex)
	if piece == null:
		return
	if layer.get("flip_h", false):
		piece.flip_x()
	if layer.get("flip_v", false):
		piece.flip_y()
	var scale: Vector2 = layer.get("scale", Vector2.ONE)
	scale = Vector2(clampf(absf(scale.x), 0.01, 8.0), clampf(absf(scale.y), 0.01, 8.0))
	var w := maxi(int(roundf(float(piece.get_width()) * absf(scale.x))), 1)
	var h := maxi(int(roundf(float(piece.get_height()) * absf(scale.y))), 1)
	if w != piece.get_width() or h != piece.get_height():
		piece.resize(w, h, Image.INTERPOLATE_NEAREST)
	var rotation: float = float(layer.get("rotation", 0.0))
	if absf(rotation) > 0.001:
		piece.rotate(rotation)
		w = piece.get_width()
		h = piece.get_height()
	var pos: Vector2 = layer.get("pos", FOOT_ANCHOR)
	var offset: Vector2 = layer.get("offset", Vector2.ZERO)
	if layer.get("centered", true):
		pos -= Vector2(w, h) * 0.5
	else:
		pos -= offset * scale
	var blit_pos := Vector2i(int(roundf(pos.x)), int(roundf(pos.y)))
	target.blit_rect(piece, Rect2i(0, 0, w, h), blit_pos)


func _texture_to_image(tex: Texture2D) -> Image:
	if tex is AtlasTexture:
		var atlas_tex := tex as AtlasTexture
		if atlas_tex.atlas == null:
			return null
		var base := atlas_tex.atlas.get_image()
		if base == null or base.is_empty():
			return null
		var region := atlas_tex.region
		return base.get_region(Rect2i(int(region.position.x), int(region.position.y), int(region.size.x), int(region.size.y)))
	if tex is ImageTexture:
		return (tex as ImageTexture).get_image()
	if tex is CompressedTexture2D:
		return (tex as Texture2D).get_image()
	return tex.get_image()
