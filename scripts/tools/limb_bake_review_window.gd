extends Window
class_name LimbBakeReviewWindow

## Popup that loops a baked horizontal sprite strip using manifest JSON metadata.

const FRAME_PADDING := 2

@onready var _title_label: Label = $Margin/VBox/TitleLabel
@onready var _meta_label: Label = $Margin/VBox/MetaLabel
@onready var _preview_rect: TextureRect = $Margin/VBox/PreviewFrame/PreviewRect
@onready var _play_pause_btn: Button = $Margin/VBox/Controls/PlayPauseBtn
@onready var _close_btn: Button = $Margin/VBox/Controls/CloseBtn

var _manifest: Dictionary = {}
var _sheet: Texture2D
var _frame_w: int = 128
var _frame_h: int = 128
var _columns: int = 1
var _fps: float = 8.0
var _frame_index: int = 0
var _playing: bool = true
var _accum: float = 0.0


func _ready() -> void:
	title = "Bake review"
	unresizable = false
	size = Vector2i(420, 360)
	close_requested.connect(_on_close_requested)
	if _play_pause_btn:
		_play_pause_btn.pressed.connect(_on_play_pause_pressed)
	if _close_btn:
		_close_btn.pressed.connect(_on_close_requested)
	_update_play_button()


func show_bake(result: Dictionary) -> void:
	if result.get("ok", false) != true:
		return
	_manifest = result.get("manifest", {}) as Dictionary
	var png_path: String = str(result.get("png_path", ""))
	if png_path.is_empty() or not ResourceLoader.exists(png_path):
		return
	_sheet = load(png_path) as Texture2D
	if _sheet == null:
		return
	var frame_size: Array = _manifest.get("frame_size", [128, 128])
	_frame_w = int(frame_size[0]) if frame_size.size() > 0 else 128
	_frame_h = int(frame_size[1]) if frame_size.size() > 1 else 128
	_columns = maxi(int(_manifest.get("columns", 1)), 1)
	_fps = maxf(float(_manifest.get("fps", 8)), 1.0)
	_frame_index = 0
	_playing = true
	_accum = 0.0
	if _title_label:
		var clip: String = str(_manifest.get("clip", "clip"))
		var weapon: String = str(_manifest.get("weapon", ""))
		_title_label.text = "%s · %s" % [weapon.capitalize(), clip]
	if _meta_label:
		_meta_label.text = (
			"%d frames @ %d fps · %dx%d · %s"
			% [_columns, int(_fps), _frame_w, _frame_h, png_path.get_file()]
		)
	_apply_frame()
	_update_play_button()
	popup_centered()


func _process(delta: float) -> void:
	if not visible:
		return
	if not _playing or _sheet == null or _columns <= 0:
		return
	_accum += delta
	var frame_dt := 1.0 / _fps
	while _accum >= frame_dt:
		_accum -= frame_dt
		_frame_index = (_frame_index + 1) % _columns
		_apply_frame()


func _apply_frame() -> void:
	if _preview_rect == null or _sheet == null:
		return
	var atlas := AtlasTexture.new()
	atlas.atlas = _sheet
	var pad := int(_manifest.get("padding", FRAME_PADDING))
	var x := _frame_index * (_frame_w + pad)
	atlas.region = Rect2(x, 0, _frame_w, _frame_h)
	_preview_rect.texture = atlas
	_preview_rect.custom_minimum_size = Vector2(_frame_w * 2.0, _frame_h * 2.0)
	_preview_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED


func _on_play_pause_pressed() -> void:
	_playing = not _playing
	_update_play_button()


func _update_play_button() -> void:
	if _play_pause_btn:
		_play_pause_btn.text = "⏸ Pause" if _playing else "▶ Play"


func _on_close_requested() -> void:
	_playing = false
	hide()
