class_name WalkAnimation
# walk.png and clubwalk.png: same layout — 3 columns, 4 rows.
# walk.png: 11 frames (0 = idle, 1–10 = walk). clubwalk.png: 11 frames (0 = idle, 1–10 = walk).

const WALK_SHEET_PATH := "res://assets/sprites/walk.png"
const DIRECTIONAL_WALK_PATH := ""
const DIRECTIONAL_IDLE_PATH := ""
const COLS := 3
const ROWS := 4
const WALK_TOTAL_FRAMES := 11   # 0 = idle, 1–10 = walk
const WALK_CYCLE_FRAMES := 10   # walk cycle uses sheet frames 1–10
const WALK_FPS := 7.0

const DIRECTIONAL_CLUB_PATH := ""
const CLUB_WALK_SHEET_PATH := "res://assets/sprites/clubwalk.png"
const CLUB_COLS := 3
const CLUB_ROWS := 4
const CLUB_TOTAL_FRAMES := 11   # 0 = idle, 1–10 = walk
const CLUB_WALK_FRAMES := 10
const CLUB_WALK_FPS := 7.0

# womanwalk.png: 3 cols 3 rows, 7 frames (0 = idle, 1–6 = walk). Same format as caveman/player.
const DIRECTIONAL_WOMAN_PATH := ""
const WOMAN_WALK_SHEET_PATH := "res://assets/sprites/womanwalk.png"
const WOMAN_COLS := 3
const WOMAN_ROWS := 3
const WOMAN_TOTAL_FRAMES := 7   # 0 = idle, 1–6 = walk
const WOMAN_WALK_FRAMES := 6
const WOMAN_WALK_FPS := 5.0
const WOMAN_SCALE := 0.40  # Slightly smaller than caveman (0.46)

static var _cached_sheet: Texture2D = null
static var _cached_club_sheet: Texture2D = null
static var _cached_woman_sheet: Texture2D = null
static var _cached_dir_sheet: DirectionalSpriteSheet = null
static var _cached_dir_idle_sheet: DirectionalSpriteSheet = null
static var _cached_dir_club_sheet: DirectionalSpriteSheet = null
static var _cached_dir_woman_sheet: DirectionalSpriteSheet = null

static func get_walk_sheet() -> Texture2D:
	if _cached_sheet == null:
		_cached_sheet = load(WALK_SHEET_PATH) as Texture2D
	return _cached_sheet

static func get_club_walk_sheet() -> Texture2D:
	if _cached_club_sheet == null:
		_cached_club_sheet = load(CLUB_WALK_SHEET_PATH) as Texture2D
	return _cached_club_sheet

static func get_woman_walk_sheet() -> Texture2D:
	if _cached_woman_sheet == null:
		_cached_woman_sheet = load(WOMAN_WALK_SHEET_PATH) as Texture2D
	return _cached_woman_sheet

static func get_directional_walk_sheet() -> DirectionalSpriteSheet:
	if _cached_dir_sheet == null and DIRECTIONAL_WALK_PATH != "":
		_cached_dir_sheet = DirectionalSpriteSheet.new(DIRECTIONAL_WALK_PATH)
		if not _cached_dir_sheet.is_valid():
			_cached_dir_sheet = null
	return _cached_dir_sheet

## Idle sheet (8-dir). Falls back to walk sheet if idle not set.
static func get_directional_idle_sheet() -> DirectionalSpriteSheet:
	if _cached_dir_idle_sheet == null and DIRECTIONAL_IDLE_PATH != "":
		_cached_dir_idle_sheet = DirectionalSpriteSheet.new(DIRECTIONAL_IDLE_PATH)
		if not _cached_dir_idle_sheet.is_valid():
			_cached_dir_idle_sheet = null
	if _cached_dir_idle_sheet:
		return _cached_dir_idle_sheet
	return get_directional_walk_sheet()

static func get_directional_club_sheet() -> DirectionalSpriteSheet:
	if _cached_dir_club_sheet == null and DIRECTIONAL_CLUB_PATH != "":
		_cached_dir_club_sheet = DirectionalSpriteSheet.new(DIRECTIONAL_CLUB_PATH)
		if not _cached_dir_club_sheet.is_valid():
			_cached_dir_club_sheet = null
	return _cached_dir_club_sheet

static func get_directional_woman_sheet() -> DirectionalSpriteSheet:
	if _cached_dir_woman_sheet == null and DIRECTIONAL_WOMAN_PATH != "":
		_cached_dir_woman_sheet = DirectionalSpriteSheet.new(DIRECTIONAL_WOMAN_PATH)
		if not _cached_dir_woman_sheet.is_valid():
			_cached_dir_woman_sheet = null
	return _cached_dir_woman_sheet

static func get_frame_size(sheet: Texture2D) -> Vector2:
	if not sheet:
		return Vector2.ZERO
	return Vector2(sheet.get_width() / float(COLS), sheet.get_height() / float(ROWS))

## Sheet frame index 0..10 → region. Layout: 3 cols 4 rows, row = frame/3, col = frame%3.
static func get_walk_frame_region(sheet: Texture2D, frame_index: int) -> Rect2:
	var sz := get_frame_size(sheet)
	if sz.x <= 0 or sz.y <= 0:
		return Rect2()
	frame_index = clampi(frame_index, 0, WALK_TOTAL_FRAMES - 1)
	var col := frame_index % COLS
	var row := frame_index / COLS
	return Rect2(int(col * sz.x), int(row * sz.y), int(sz.x), int(sz.y))

## Apply walk frame to sprite. Slightly smaller than idle (0.46) so walk matches stand size.
static func apply_walk_frame(sprite: Sprite2D, sheet: Texture2D, frame_index: int) -> void:
	if not sprite or not sheet:
		return
	var region := get_walk_frame_region(sheet, frame_index)
	if region.size.x <= 0:
		return
	var atlas := AtlasTexture.new()
	atlas.atlas = sheet
	atlas.region = region
	sprite.texture = atlas
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	var frame_h := get_frame_size(sheet).y
	# Slightly smaller than idle (0.5) so walk animation matches stand size
	sprite.scale = Vector2(0.46, 0.46) if frame_h >= 128 else Vector2(0.92, 0.92)

## Idle: frame 0 of walk.png.
static func apply_walk_idle(sprite: Sprite2D) -> void:
	var sheet := get_walk_sheet()
	if sheet:
		apply_walk_frame(sprite, sheet, 0)

## Walk cycle: walk_index 0..9 → sheet frames 1–10.
static func apply_walk_frame_by_index(sprite: Sprite2D, sheet: Texture2D, frame_index: int) -> void:
	var sheet_frame := 1 + (frame_index % WALK_CYCLE_FRAMES)
	apply_walk_frame(sprite, sheet, sheet_frame)

## Directional: use when sheet is valid. No flip_h needed.
static func apply_directional_walk_frame(sprite: Sprite2D, dir_sheet: DirectionalSpriteSheet, velocity: Vector2, walk_index: int) -> bool:
	if not dir_sheet or not dir_sheet.is_valid():
		return false
	var dir := DirectionalSpriteSheet.velocity_to_direction(velocity, dir_sheet.directions)
	var frame_idx := walk_index % dir_sheet.columns
	return dir_sheet.apply_frame(sprite, dir, frame_idx)

## Directional idle: frame 0 of direction 0 (S) or use last_facing if provided.
static func apply_directional_idle(sprite: Sprite2D, dir_sheet: DirectionalSpriteSheet, last_facing: Vector2 = Vector2.ZERO) -> bool:
	if not dir_sheet or not dir_sheet.is_valid():
		return false
	var dir := DirectionalSpriteSheet.velocity_to_direction(last_facing, dir_sheet.directions) if last_facing.length_squared() > 0.1 else 0
	return dir_sheet.apply_frame(sprite, dir, 0)

# --- Club (clubwalk.png): 11 frames, 3 cols 4 rows. Frame 0 = idle, 1–10 = walk. ---

static func get_club_frame_size(sheet: Texture2D) -> Vector2:
	if not sheet:
		return Vector2.ZERO
	return Vector2(sheet.get_width() / float(CLUB_COLS), sheet.get_height() / float(CLUB_ROWS))

static func get_club_frame_region(sheet: Texture2D, frame_index: int) -> Rect2:
	var sz := get_club_frame_size(sheet)
	if sz.x <= 0 or sz.y <= 0:
		return Rect2()
	frame_index = clampi(frame_index, 0, CLUB_TOTAL_FRAMES - 1)
	var col := frame_index % CLUB_COLS
	var row := frame_index / CLUB_COLS
	return Rect2(int(col * sz.x), int(row * sz.y), int(sz.x), int(sz.y))

## Apply one frame from club sheet (0 = idle, 1–10 = walk). Same scale as walk.
static func apply_club_frame(sprite: Sprite2D, sheet: Texture2D, frame_index: int) -> void:
	if not sprite or not sheet:
		return
	var region := get_club_frame_region(sheet, frame_index)
	if region.size.x <= 0:
		return
	var atlas := AtlasTexture.new()
	atlas.atlas = sheet
	atlas.region = region
	sprite.texture = atlas
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	var frame_h := get_club_frame_size(sheet).y
	sprite.scale = Vector2(0.46, 0.46) if frame_h >= 128 else Vector2(0.92, 0.92)

## Idle with club: frame 0 of clubwalk.png.
static func apply_club_idle(sprite: Sprite2D) -> void:
	var sheet := get_club_walk_sheet()
	if sheet:
		apply_club_frame(sprite, sheet, 0)

## Walk with club: walk_index 0..9 → sheet frames 1–10.
static func apply_club_walk_frame_by_index(sprite: Sprite2D, walk_index: int) -> void:
	var sheet := get_club_walk_sheet()
	if sheet:
		var frame_index := 1 + (walk_index % CLUB_WALK_FRAMES)
		apply_club_frame(sprite, sheet, frame_index)

# --- Woman (womanwalk.png): 7 frames, 3 cols 3 rows. Frame 0 = idle, 1–6 = walk. ---

static func get_woman_frame_size(sheet: Texture2D) -> Vector2:
	if not sheet:
		return Vector2.ZERO
	return Vector2(sheet.get_width() / float(WOMAN_COLS), sheet.get_height() / float(WOMAN_ROWS))

static func get_woman_frame_region(sheet: Texture2D, frame_index: int) -> Rect2:
	var sz := get_woman_frame_size(sheet)
	if sz.x <= 0 or sz.y <= 0:
		return Rect2()
	frame_index = clampi(frame_index, 0, WOMAN_TOTAL_FRAMES - 1)
	var col := frame_index % WOMAN_COLS
	var row := frame_index / WOMAN_COLS
	return Rect2(int(col * sz.x), int(row * sz.y), int(sz.x), int(sz.y))

static func apply_woman_frame(sprite: Sprite2D, sheet: Texture2D, frame_index: int) -> void:
	if not sprite or not sheet:
		return
	var region := get_woman_frame_region(sheet, frame_index)
	if region.size.x <= 0:
		return
	var atlas := AtlasTexture.new()
	atlas.atlas = sheet
	atlas.region = region
	sprite.texture = atlas
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	sprite.scale = Vector2(WOMAN_SCALE, WOMAN_SCALE)

## Idle for woman: frame 0 of womanwalk.png.
static func apply_woman_idle(sprite: Sprite2D) -> void:
	var sheet := get_woman_walk_sheet()
	if sheet:
		apply_woman_frame(sprite, sheet, 0)

## Walk for woman: walk_index 0..5 → sheet frames 1–6.
static func apply_woman_walk_frame_by_index(sprite: Sprite2D, walk_index: int) -> void:
	var sheet := get_woman_walk_sheet()
	if sheet:
		var frame_index := 1 + (walk_index % WOMAN_WALK_FRAMES)
		apply_woman_frame(sprite, sheet, frame_index)

# --- Goat (goatwalk.png): 10 frames, 3 cols 4 rows. Frame 0 = idle, 1–9 = walk. ---
const GOAT_WALK_SHEET_PATH := "res://assets/sprites/goatwalk.png"
const GOAT_COLS := 3
const GOAT_ROWS := 4
const GOAT_TOTAL_FRAMES := 10   # 0 = idle, 1–9 = walk
const GOAT_WALK_FRAMES := 9
const GOAT_WALK_FPS := 7.0
const GOAT_SCALE := 0.33  # Smaller than woman (0.40)

static var _cached_goat_sheet: Texture2D = null

static func get_goat_walk_sheet() -> Texture2D:
	if _cached_goat_sheet == null:
		_cached_goat_sheet = load(GOAT_WALK_SHEET_PATH) as Texture2D
	return _cached_goat_sheet

static func get_goat_frame_size(sheet: Texture2D) -> Vector2:
	if not sheet:
		return Vector2.ZERO
	return Vector2(sheet.get_width() / float(GOAT_COLS), sheet.get_height() / float(GOAT_ROWS))

static func get_goat_frame_region(sheet: Texture2D, frame_index: int) -> Rect2:
	var sz := get_goat_frame_size(sheet)
	if sz.x <= 0 or sz.y <= 0:
		return Rect2()
	frame_index = clampi(frame_index, 0, GOAT_TOTAL_FRAMES - 1)
	var col := frame_index % GOAT_COLS
	var row := frame_index / GOAT_COLS
	return Rect2(int(col * sz.x), int(row * sz.y), int(sz.x), int(sz.y))

static func apply_goat_frame(sprite: Sprite2D, sheet: Texture2D, frame_index: int) -> void:
	if not sprite or not sheet:
		return
	var region := get_goat_frame_region(sheet, frame_index)
	if region.size.x <= 0:
		return
	var atlas := AtlasTexture.new()
	atlas.atlas = sheet
	atlas.region = region
	sprite.texture = atlas
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	sprite.scale = Vector2(GOAT_SCALE, GOAT_SCALE)

static func apply_goat_idle(sprite: Sprite2D) -> void:
	var sheet := get_goat_walk_sheet()
	if sheet:
		apply_goat_frame(sprite, sheet, 0)

static func apply_goat_walk_frame_by_index(sprite: Sprite2D, walk_index: int) -> void:
	var sheet := get_goat_walk_sheet()
	if sheet:
		var frame_index := 1 + (walk_index % GOAT_WALK_FRAMES)
		apply_goat_frame(sprite, sheet, frame_index)
