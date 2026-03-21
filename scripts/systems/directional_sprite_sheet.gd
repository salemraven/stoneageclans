class_name DirectionalSpriteSheet
## Loads SpriteForge-style directional sprite sheets (PNG + JSON).
## Layout: rows = directions (row 0 = S, row 1 = SE, ...), columns = frames.
## Use velocity_to_direction() to map Godot velocity to direction index.

var sheet: Texture2D = null
var meta: Dictionary = {}
var frame_w: int = 0
var frame_h: int = 0
var padding: int = 2
var directions: int = 8
var columns: int = 0  # frames per direction
var _base_scale: float = 0.46  # 128px frames; 256px uses 0.23 in apply_frame

func _init(png_path: String, json_path: String = "") -> void:
	if json_path.is_empty():
		json_path = png_path.get_basename() + ".json"
	sheet = load(png_path) as Texture2D
	if not sheet:
		return
	var f := FileAccess.open(json_path, FileAccess.READ)
	if f:
		var json := JSON.new()
		var err := json.parse(f.get_as_text())
		f.close()
		if err == OK:
			meta = json.data
	_parse_meta()

func _parse_meta() -> void:
	if meta.is_empty():
		# Require JSON for correct layout - no guessing
		frame_w = 0
		frame_h = 0
		return
	var fs: Array = meta.get("frame_size", [64, 64])
	frame_w = int(fs[0]) if fs.size() > 0 else 64
	frame_h = int(fs[1]) if fs.size() > 1 else 64
	padding = int(meta.get("padding", 2))
	directions = int(meta.get("directions", 8))
	columns = int(meta.get("columns", 24))

func is_valid() -> bool:
	return sheet != null and frame_w > 0 and frame_h > 0

## Map Godot velocity (Y increases down) to SpriteForge direction index.
## SpriteForge dir 0=S, 1=E, 2=N, 3=W (4-dir) or 0=S,1=SE,2=E,... (8-dir).
## Godot: atan2(x, -y) gives 0=up, 90=right, 180=down. SpriteForge topdown_34 needs +90° offset.
static func velocity_to_direction(velocity: Vector2, dir_count: int = 8) -> int:
	if velocity.length_squared() < 1.0:
		return 0  # Default to S when idle
	var angle_rad := atan2(velocity.x, -velocity.y)
	var angle_deg := rad_to_deg(angle_rad)
	if angle_deg < 0:
		angle_deg += 360.0
	var step := 360.0 / dir_count
	var dir := (dir_count / 2 - int(round(angle_deg / step)) + dir_count) % dir_count
	# SpriteForge topdown_34: swap S↔N, E↔W so down→S, right→E, up→N, left→W
	return (dir + 2) % dir_count

## Get Rect2 for region (dir_index, frame_index).
func get_frame_region(dir_index: int, frame_index: int) -> Rect2:
	if not is_valid():
		return Rect2()
	dir_index = clampi(dir_index, 0, directions - 1)
	frame_index = clampi(frame_index, 0, columns - 1)
	var x := frame_index * (frame_w + padding)
	var y := dir_index * (frame_h + padding)
	return Rect2(x, y, frame_w, frame_h)

## Apply frame to sprite. Returns true if applied.
func apply_frame(sprite: Sprite2D, dir_index: int, frame_index: int) -> bool:
	if not sprite or not is_valid():
		return false
	var region := get_frame_region(dir_index, frame_index)
	if region.size.x <= 0:
		return false
	var atlas := AtlasTexture.new()
	atlas.atlas = sheet
	atlas.region = region
	sprite.texture = atlas
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	# Scale: 512→0.23 (~118px), 256→0.23, 128→0.46. 0.115 was too small (invisible).
	var scale_val := 0.23 if frame_h >= 256 else (_base_scale if frame_h >= 128 else 0.92)
	sprite.scale = Vector2(scale_val, scale_val)
	return true

func set_base_scale(s: float) -> void:
	_base_scale = s
