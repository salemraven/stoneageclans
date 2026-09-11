extends TileMap

## Classic ground: `WorldLayer/DirtBase` (dirtgrass shader tiles). This TileMap stays for optional overlays.
## Godot 4.5 canvas z_index is 0..4095 — do not use negative z or the sprite is skipped.

const DIRT_BASE_PATH := NodePath("../DirtBase")
const TILE_PX := 64.0
const COVER_PAD := 1.5

var _dirt_base: Sprite2D


func _ready() -> void:
	call_deferred("_refresh_classic_ground")


func _use_classic_ground() -> bool:
	var wgc: Node = get_node_or_null("/root/WorldGenConfig")
	return wgc == null or not bool(wgc.get("use_authored_island_map"))


func _get_dirt_base() -> Sprite2D:
	if _dirt_base == null or not is_instance_valid(_dirt_base):
		_dirt_base = get_node_or_null(DIRT_BASE_PATH) as Sprite2D
	return _dirt_base


func _refresh_classic_ground() -> void:
	if not _use_classic_ground():
		return
	var dirt := _get_dirt_base()
	if dirt == null:
		return
	dirt.visible = true
	dirt.centered = true
	dirt.z_as_relative = true
	dirt.z_index = 0
	dirt.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	print("ClassicGround: DirtBase on at %s scale=%s" % [dirt.global_position, dirt.scale])


func ensure_chunks_for_position(world_position: Vector2, delta_sec: float = 0.0) -> void:
	_sync_classic_ground_tiles(world_position)
	var cm: Node = get_node_or_null("/root/ChunkManager")
	if cm:
		cm.call("update_streaming", world_position, delta_sec)


func _sync_classic_ground_tiles(focus: Vector2) -> void:
	if not _use_classic_ground():
		return
	var dirt := _get_dirt_base()
	if dirt == null:
		return
	dirt.visible = true
	dirt.z_index = 0
	dirt.global_position = focus.floor()
	var cam: Camera2D = get_viewport().get_camera_2d()
	if cam == null:
		return
	var vp: Vector2 = get_viewport().get_visible_rect().size
	var zoom: float = maxf(cam.zoom.x, 0.05)
	# Godot 4: larger zoom = closer. Visible world size is viewport / zoom.
	var cover: float = maxf(vp.x, vp.y) / zoom * COVER_PAD
	var tex_px: float = TILE_PX
	if dirt.texture:
		tex_px = maxf(float(dirt.texture.get_width()), 1.0)
	var need_scale: float = maxf(80.0, ceil(cover / tex_px))
	if absf(dirt.scale.x - need_scale) > 0.5:
		dirt.scale = Vector2(need_scale, need_scale)
