extends Node2D
## Water paint editor + shader-based island map preview.
## View mode: Pan/zoom. Paint mode: rivers or grass (reset biomes to savanna).

const BIOME_SHADER := preload("res://assets/shaders/biome_ground.gdshader")
const MaskTopologyRes := preload("res://scripts/world/mask_topology.gd")
const SCALE_MARKER_TEX := preload("res://assets/sprites/PlayerB.png")
const META_PATH := "res://maps/island/island_meta.json"
const MASK_PATH := "res://maps/island/biome_mask.png"
const MASK_SAVE_PATH := "res://maps/island/biome_mask.png"
const WATER_LAYER_PATH := "res://maps/island/water_layer.png"
const WATER_LAYER_SAVE_PATH := "res://maps/island/water_layer.png"

enum Mode { VIEW, PAINT }
enum PaintLayer { WATER, GRASS }

## Matches scenes/Player.tscn sprite scale (in-game character size).
const PLAYER_SPRITE_SCALE := Vector2(0.5, 0.5)

const ZOOM_MIN := 0.02
const ZOOM_MAX := 4.0
const ZOOM_STEP := 1.15
const CHUNK_SIZE_PX := 2048.0

@onready var _camera: Camera2D = $Camera2D
@onready var _ground_sprite: Sprite2D = $GroundSprite
@onready var _zoom_label: Label = $UI/Panel/VBoxContainer/ZoomLabel
@onready var _title_label: Label = $UI/Panel/VBoxContainer/Label
@onready var _toggles_container: VBoxContainer = $UI/Panel/VBoxContainer/Toggles
@onready var _instructions_label: Label = $UI/Panel/VBoxContainer/Instructions

var _zoom: float = 0.4
var _panning := false
var _painting := false
var _world_size: Vector2 = Vector2(65536, 65536)
var _shader_material: ShaderMaterial
var _mask_size: int = 1024
var _sample_stride: float = 64.0
var _chunk_count: Vector2i = Vector2i(32, 32)
var _show_chunk_grid := true
var _show_tile_grid := false

# Paint mode state
var _mode: Mode = Mode.VIEW
var _paint_layer: PaintLayer = PaintLayer.WATER
var _water_image: Image
var _water_texture: ImageTexture
var _brush_size: int = 3  # tiles
var _paint_erase := false  # false = paint water, true = erase
var _dirty := false

# UI refs (created at runtime)
var _mode_button: Button
var _brush_slider: HSlider
var _brush_label: Label
var _paint_toggle: CheckBox
var _paint_layer_option: OptionButton
var _save_button: Button
var _check_button: Button
var _topology_button: Button
var _validate_button: Button
var _mask_image: Image
var _mask_texture: ImageTexture
var _status_label: Label
var _grid_overlay: GridOverlay


class GridOverlay extends Node2D:
	var editor: Node2D

	func _draw() -> void:
		if editor == null or not is_instance_valid(editor):
			return
		editor._draw_grid_on(self)


func _ready() -> void:
	_title_label.text = "Island Map Editor"
	_load_meta()
	_setup_water_layer()
	_setup_ground_shader()
	_setup_scale_marker()
	_setup_toggle_buttons()
	_setup_grid_overlays()
	_setup_paint_ui()
	# Topology fix is manual (Fix Topology button) — auto-fix on load was slow and surprising.
	_focus_map_center()
	_update_zoom_label()
	_update_mode_ui()
	_queue_grid_redraw()


func _load_meta() -> void:
	if not FileAccess.file_exists(META_PATH):
		return
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(META_PATH))
	if typeof(parsed) == TYPE_DICTIONARY:
		var meta: Dictionary = parsed as Dictionary
		_world_size = Vector2(
			float(meta.get("world_width_px", 65536)),
			float(meta.get("world_height_px", 65536))
		)
		_mask_size = int(meta.get("mask_size", 1024))
		_sample_stride = float(meta.get("sample_stride_px", 64.0))
		_chunk_count = Vector2i(
			int(meta.get("chunk_count_x", 32)),
			int(meta.get("chunk_count_y", 32))
		)


func _setup_grid_overlays() -> void:
	_grid_overlay = GridOverlay.new()
	_grid_overlay.name = "GridOverlay"
	_grid_overlay.editor = self
	_grid_overlay.z_index = -50
	add_child(_grid_overlay)

	var grid_sep := HSeparator.new()
	_toggles_container.add_child(grid_sep)

	var grid_header := Label.new()
	grid_header.text = "Grid Overlays"
	grid_header.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_toggles_container.add_child(grid_header)

	var chunk_check := CheckBox.new()
	chunk_check.text = "Chunk grid (%d px)" % int(CHUNK_SIZE_PX)
	chunk_check.button_pressed = _show_chunk_grid
	chunk_check.toggled.connect(_on_chunk_grid_toggled)
	_toggles_container.add_child(chunk_check)

	var tile_check := CheckBox.new()
	tile_check.text = "Tile grid (%d px)" % int(_sample_stride)
	tile_check.button_pressed = _show_tile_grid
	tile_check.toggled.connect(_on_tile_grid_toggled)
	_toggles_container.add_child(tile_check)


func _on_chunk_grid_toggled(pressed: bool) -> void:
	_show_chunk_grid = pressed
	_queue_grid_redraw()


func _on_tile_grid_toggled(pressed: bool) -> void:
	_show_tile_grid = pressed
	_queue_grid_redraw()


func _draw_grid_on(canvas: CanvasItem) -> void:
	if _show_chunk_grid:
		_draw_chunk_grid(canvas)
	if _show_tile_grid:
		_draw_tile_grid(canvas)


func _draw_chunk_grid(canvas: CanvasItem) -> void:
	var minor := Color(1.0, 1.0, 0.9, 0.22)
	var major := Color(1.0, 0.85, 0.35, 0.45)
	var border := Color(0.95, 0.95, 1.0, 0.55)
	var line_w := maxf(1.0, 1.0 / _zoom)

	for cx in range(_chunk_count.x + 1):
		var x := float(cx) * CHUNK_SIZE_PX
		var color := major if cx % 4 == 0 else minor
		var width := line_w * (1.75 if cx % 4 == 0 else 1.0)
		canvas.draw_line(Vector2(x, 0.0), Vector2(x, _world_size.y), color, width)

	for cy in range(_chunk_count.y + 1):
		var y := float(cy) * CHUNK_SIZE_PX
		var color := major if cy % 4 == 0 else minor
		var width := line_w * (1.75 if cy % 4 == 0 else 1.0)
		canvas.draw_line(Vector2(0.0, y), Vector2(_world_size.x, y), color, width)

	canvas.draw_rect(Rect2(Vector2.ZERO, _world_size), border, false, line_w * 2.0)


func _draw_tile_grid(canvas: CanvasItem) -> void:
	# Only draw tile lines inside the camera view (keeps zoomed-in painting usable).
	var half_view := get_viewport().get_visible_rect().size * 0.5 / _zoom
	var cam := _camera.position
	var min_x := int(floor(maxf(0.0, cam.x - half_view.x) / _sample_stride))
	var max_x := int(ceil(minf(_world_size.x, cam.x + half_view.x) / _sample_stride))
	var min_y := int(floor(maxf(0.0, cam.y - half_view.y) / _sample_stride))
	var max_y := int(ceil(minf(_world_size.y, cam.y + half_view.y) / _sample_stride))

	var color := Color(0.85, 0.95, 1.0, 0.12)
	var line_w := maxf(1.0, 0.75 / _zoom)

	for tx in range(min_x, max_x + 1):
		var x := float(tx) * _sample_stride
		canvas.draw_line(
			Vector2(x, float(min_y) * _sample_stride),
			Vector2(x, float(max_y) * _sample_stride),
			color,
			line_w
		)

	for ty in range(min_y, max_y + 1):
		var y := float(ty) * _sample_stride
		canvas.draw_line(
			Vector2(float(min_x) * _sample_stride, y),
			Vector2(float(max_x) * _sample_stride, y),
			color,
			line_w
		)


func _queue_grid_redraw() -> void:
	if _grid_overlay:
		_grid_overlay.queue_redraw()


func _setup_water_layer() -> void:
	_water_image = _load_grayscale_layer_image(WATER_LAYER_PATH)
	if _water_image != null and not _water_image.is_empty():
		print("Loaded existing water layer: %dx%d" % [_water_image.get_width(), _water_image.get_height()])

	if _water_image == null or _water_image.is_empty():
		# Create blank water layer (black = no water)
		_water_image = Image.create(_mask_size, _mask_size, false, Image.FORMAT_L8)
		_water_image.fill(Color.BLACK)
		print("Created blank water layer: %dx%d" % [_mask_size, _mask_size])

	_water_texture = ImageTexture.create_from_image(_water_image)


## Load PNG from res:// without requiring a Godot .import sidecar (editor saves raw PNG).
func _load_grayscale_layer_image(project_path: String) -> Image:
	if not FileAccess.file_exists(project_path):
		return null
	var fs_path := ProjectSettings.globalize_path(project_path)
	var img := Image.load_from_file(fs_path)
	if img == null or img.is_empty():
		push_warning("WorldMapEditor: failed to read image at %s" % project_path)
		return null
	if img.get_width() != _mask_size or img.get_height() != _mask_size:
		push_warning(
			"WorldMapEditor: water layer is %dx%d, expected %dx%d — using loaded image anyway"
			% [img.get_width(), img.get_height(), _mask_size, _mask_size]
		)
	img.convert(Image.FORMAT_L8)
	return img


func _load_mask_image_from_disk() -> Image:
	if not FileAccess.file_exists(MASK_PATH):
		return null
	var fs_path := ProjectSettings.globalize_path(MASK_PATH)
	var img := Image.load_from_file(fs_path)
	if img == null or img.is_empty():
		push_warning("WorldMapEditor: failed to read biome mask at %s" % MASK_PATH)
		return null
	img.convert(Image.FORMAT_L8)
	return img


func _setup_ground_shader() -> void:
	var mask_img := _load_mask_image_from_disk()
	if mask_img == null:
		push_warning("WorldMapEditor: biome_mask.png not found — run tools/build_biome_mask_from_map2.py")
		return
	_mask_image = mask_img
	_mask_texture = ImageTexture.create_from_image(_mask_image)
	
	# Create shader material
	_shader_material = ShaderMaterial.new()
	_shader_material.shader = BIOME_SHADER
	_shader_material.set_shader_parameter("biome_mask", _mask_texture)
	_shader_material.set_shader_parameter("water_mask", _water_texture)
	_shader_material.set_shader_parameter("use_water_layer", true)
	_shader_material.set_shader_parameter("world_size", _world_size)
	_shader_material.set_shader_parameter("enable_noise", true)
	_shader_material.set_shader_parameter("enable_grass_detail", true)
	_shader_material.set_shader_parameter("enable_river_detail", false)
	_shader_material.set_shader_parameter("enable_organic_edges", true)
	
	# Setup ground sprite to cover full world
	_ground_sprite.material = _shader_material
	_ground_sprite.centered = false
	_ground_sprite.position = Vector2.ZERO
	
	# Create a white texture as base (shader will color it)
	var img := Image.create(1, 1, false, Image.FORMAT_RGBA8)
	img.fill(Color.WHITE)
	var tex := ImageTexture.create_from_image(img)
	_ground_sprite.texture = tex
	_ground_sprite.scale = _world_size


func _setup_scale_marker() -> void:
	var marker := Sprite2D.new()
	marker.name = "ScaleMarker"
	marker.texture = SCALE_MARKER_TEX
	marker.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	marker.scale = PLAYER_SPRITE_SCALE
	marker.position = _world_size * 0.5 + Vector2(0, -6)
	marker.z_index = 10
	add_child(marker)

	var label := Label.new()
	label.name = "ScaleMarkerLabel"
	label.text = "Player scale"
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.position = marker.position + Vector2(-48, -72)
	label.z_index = 11
	add_child(label)


func _setup_toggle_buttons() -> void:
	# Clear existing toggles
	for child in _toggles_container.get_children():
		child.queue_free()
	
	var toggles := [
		["Grass Detail", "enable_grass_detail", true],
		["River Detail", "enable_river_detail", false],
		["Organic Edges", "enable_organic_edges", true],
		["Noise", "enable_noise", true],
	]
	
	for toggle_data in toggles:
		var label_text: String = toggle_data[0]
		var param_name: String = toggle_data[1]
		var default_on: bool = toggle_data[2]
		
		var check := CheckBox.new()
		check.text = label_text
		check.button_pressed = default_on
		check.toggled.connect(_on_toggle_changed.bind(param_name))
		_toggles_container.add_child(check)


func _setup_paint_ui() -> void:
	# Add separator + paint controls after toggles
	var sep := HSeparator.new()
	_toggles_container.add_child(sep)
	
	var paint_header := Label.new()
	paint_header.text = "Paint Mode"
	paint_header.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_toggles_container.add_child(paint_header)
	
	# Mode toggle button
	_mode_button = Button.new()
	_mode_button.text = "Mode: View"
	_mode_button.pressed.connect(_toggle_mode)
	_toggles_container.add_child(_mode_button)
	
	# Brush size slider
	var brush_container := HBoxContainer.new()
	var brush_text := Label.new()
	brush_text.text = "Brush:"
	brush_container.add_child(brush_text)
	
	_brush_slider = HSlider.new()
	_brush_slider.min_value = 1
	_brush_slider.max_value = 10
	_brush_slider.step = 1
	_brush_slider.value = _brush_size
	_brush_slider.custom_minimum_size = Vector2(80, 0)
	_brush_slider.value_changed.connect(_on_brush_size_changed)
	brush_container.add_child(_brush_slider)
	
	_brush_label = Label.new()
	_brush_label.text = str(_brush_size)
	brush_container.add_child(_brush_label)
	_toggles_container.add_child(brush_container)

	var layer_container := HBoxContainer.new()
	var layer_label := Label.new()
	layer_label.text = "Brush:"
	layer_container.add_child(layer_label)
	_paint_layer_option = OptionButton.new()
	_paint_layer_option.add_item("Rivers", PaintLayer.WATER)
	_paint_layer_option.add_item("Grass", PaintLayer.GRASS)
	_paint_layer_option.item_selected.connect(_on_paint_layer_selected)
	layer_container.add_child(_paint_layer_option)
	_toggles_container.add_child(layer_container)

	# Paint/Erase toggle (rivers only)
	_paint_toggle = CheckBox.new()
	_paint_toggle.text = "Erase (remove water)"
	_paint_toggle.button_pressed = false
	_paint_toggle.toggled.connect(_on_paint_erase_changed)
	_toggles_container.add_child(_paint_toggle)
	
	# Save button
	_save_button = Button.new()
	_save_button.text = "Save Map (Ctrl+S)"
	_save_button.pressed.connect(_save_map)
	_toggles_container.add_child(_save_button)
	
	# Check connectivity button
	_check_button = Button.new()
	_check_button.text = "Check Rivers"
	_check_button.pressed.connect(_check_connectivity)
	_toggles_container.add_child(_check_button)

	_validate_button = Button.new()
	_validate_button.text = "Validate Map Shape"
	_validate_button.pressed.connect(_validate_map_pressed)
	_toggles_container.add_child(_validate_button)

	_topology_button = Button.new()
	_topology_button.text = "Fix Map (Specks + Topology)"
	_topology_button.tooltip_text = (
		"3/4 speck rule, land/ocean topology, desert off rivers. Rivers are never changed.\n"
		+ "Organic region shape is rebuilt offline: bash tools/rebuild_island_biomes.sh"
	)
	_topology_button.pressed.connect(_fix_topology_pressed)
	_toggles_container.add_child(_topology_button)
	
	# Status label
	_status_label = Label.new()
	_status_label.text = ""
	_status_label.autowrap_mode = TextServer.AUTOWRAP_WORD
	_toggles_container.add_child(_status_label)
	_update_paint_layer_ui()


func _toggle_mode() -> void:
	if _mode == Mode.VIEW:
		_mode = Mode.PAINT
	else:
		_mode = Mode.VIEW
	_update_mode_ui()


func _update_mode_ui() -> void:
	if _mode == Mode.VIEW:
		_mode_button.text = "Mode: View"
		_title_label.text = "Island Map Editor (View)"
	else:
		_mode_button.text = "Mode: Paint"
		var dirty_mark := " *" if _dirty else ""
		_title_label.text = "Island Map Editor (Paint)%s" % dirty_mark
	_update_paint_layer_ui()


func _on_brush_size_changed(value: float) -> void:
	_brush_size = int(value)
	_brush_label.text = str(_brush_size)


func _on_paint_erase_changed(pressed: bool) -> void:
	_paint_erase = pressed


func _on_paint_layer_selected(index: int) -> void:
	_paint_layer = index as PaintLayer
	_update_paint_layer_ui()


func _update_paint_layer_ui() -> void:
	if _paint_layer_option == null or _paint_toggle == null:
		return
	var is_grass := _paint_layer == PaintLayer.GRASS
	_paint_toggle.visible = not is_grass
	if is_grass:
		_paint_toggle.button_pressed = false
		_paint_erase = false
	else:
		_paint_toggle.text = "Erase (remove water)"


func _on_toggle_changed(pressed: bool, param_name: String) -> void:
	if _shader_material:
		_shader_material.set_shader_parameter(param_name, pressed)


func _focus_map_center(custom_zoom: float = -1.0) -> void:
	## Island geographic center (mask 512,512 → glacier hub).
	_camera.position = _world_size * 0.5
	if custom_zoom < 0.0:
		_zoom = clampf(0.55, ZOOM_MIN, ZOOM_MAX)
	else:
		_zoom = clampf(custom_zoom, ZOOM_MIN, ZOOM_MAX)
	_camera.zoom = Vector2(_zoom, _zoom)
	_update_zoom_label()
	_queue_grid_redraw()


func _focus_scale_reference() -> void:
	_focus_map_center(1.2)


func _focus_glacier() -> void:
	if _mask_image == null:
		_focus_scale_reference()
		return
	var w := _mask_image.get_width()
	var h := _mask_image.get_height()
	var sum := Vector2.ZERO
	var count := 0
	for y in range(h):
		for x in range(w):
			var v := _mask_image.get_pixel(x, y).r
			var biome_id := clampi(int(roundi(v * 9.0)), 0, 8)
			if biome_id != 5:
				continue
			sum += Vector2(float(x), float(y))
			count += 1
	if count == 0:
		_focus_scale_reference()
		return
	var center_mask := sum / float(count)
	_camera.position = Vector2(
		(center_mask.x + 0.5) * _sample_stride,
		(center_mask.y + 0.5) * _sample_stride
	)
	_zoom = clampf(1.2, ZOOM_MIN, ZOOM_MAX)
	_camera.zoom = Vector2(_zoom, _zoom)
	_update_zoom_label()


func _fit_camera() -> void:
	_camera.position = _world_size * 0.5
	var viewport_size := get_viewport().get_visible_rect().size
	_zoom = clampf(minf(viewport_size.x / _world_size.x, viewport_size.y / _world_size.y) * 0.9, ZOOM_MIN, ZOOM_MAX)
	_camera.zoom = Vector2(_zoom, _zoom)


func _process(_delta: float) -> void:
	# Continuous painting while mouse held
	if _painting and _mode == Mode.PAINT:
		var mouse_pos := get_global_mouse_position()
		_paint_at(mouse_pos)


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		var mb := event as InputEventMouseButton
		if mb.button_index == MOUSE_BUTTON_WHEEL_UP and mb.pressed:
			_zoom_by(ZOOM_STEP)
		elif mb.button_index == MOUSE_BUTTON_WHEEL_DOWN and mb.pressed:
			_zoom_by(1.0 / ZOOM_STEP)
		elif mb.button_index == MOUSE_BUTTON_LEFT:
			if _mode == Mode.PAINT:
				_painting = mb.pressed
				if mb.pressed:
					_paint_at(get_global_mouse_position())
			else:
				_panning = mb.pressed
		elif mb.button_index == MOUSE_BUTTON_MIDDLE:
			_panning = mb.pressed
		elif mb.button_index == MOUSE_BUTTON_RIGHT and _mode == Mode.PAINT:
			if _paint_layer == PaintLayer.GRASS:
				_painting = mb.pressed
				if mb.pressed:
					_paint_at(get_global_mouse_position())
			else:
				# Right-click = erase rivers (temporary)
				_painting = mb.pressed
				if mb.pressed:
					var old_erase := _paint_erase
					_paint_erase = true
					_paint_at(get_global_mouse_position())
					_paint_erase = old_erase
				elif not mb.pressed:
					_painting = false
	elif event is InputEventMouseMotion:
		if _panning:
			var mm := event as InputEventMouseMotion
			_camera.position -= mm.relative / _zoom
			_queue_grid_redraw()
	elif event is InputEventKey and event.pressed and not event.echo:
		match event.keycode:
			KEY_EQUAL, KEY_KP_ADD, KEY_PLUS:
				_zoom_by(ZOOM_STEP)
			KEY_MINUS, KEY_KP_SUBTRACT:
				_zoom_by(1.0 / ZOOM_STEP)
			KEY_LEFT:
				_camera.position.x -= 200.0 / _zoom
			KEY_RIGHT:
				_camera.position.x += 200.0 / _zoom
			KEY_UP:
				_camera.position.y -= 200.0 / _zoom
			KEY_DOWN:
				_camera.position.y += 200.0 / _zoom
			KEY_HOME:
				_fit_camera()
				_update_zoom_label()
			KEY_C:
				_focus_map_center()
			KEY_V:
				if _mode != Mode.VIEW:
					_mode = Mode.VIEW
					_update_mode_ui()
			KEY_P:
				if _mode != Mode.PAINT:
					_mode = Mode.PAINT
					_update_mode_ui()
			KEY_G:
				_show_chunk_grid = not _show_chunk_grid
				_queue_grid_redraw()
			KEY_S:
				if event.ctrl_pressed or event.meta_pressed:
					_save_map()


func _paint_at(world_pos: Vector2) -> void:
	if _paint_layer == PaintLayer.GRASS:
		_paint_grass_at(world_pos)
	else:
		_paint_water_at(world_pos)


func _paint_water_at(world_pos: Vector2) -> void:
	if _water_image == null:
		return

	var mask_x := int(world_pos.x / _sample_stride)
	var mask_y := int(world_pos.y / _sample_stride)
	var color := Color.BLACK if _paint_erase else Color.WHITE
	var radius := _brush_size

	for dy in range(-radius, radius + 1):
		for dx in range(-radius, radius + 1):
			if dx * dx + dy * dy <= radius * radius:
				var px := mask_x + dx
				var py := mask_y + dy
				if px >= 0 and px < _water_image.get_width() and py >= 0 and py < _water_image.get_height():
					_water_image.set_pixel(px, py, color)

	_water_texture.update(_water_image)
	_dirty = true
	_update_mode_ui()


func _paint_grass_at(world_pos: Vector2) -> void:
	if _mask_image == null:
		return

	var savanna := MaskTopologyRes.pixel_from_biome_id(MaskTopologyRes.SAVANNA)
	var mask_x := int(world_pos.x / _sample_stride)
	var mask_y := int(world_pos.y / _sample_stride)
	var radius := _brush_size
	var changed := false

	for dy in range(-radius, radius + 1):
		for dx in range(-radius, radius + 1):
			if dx * dx + dy * dy > radius * radius:
				continue
			var px := mask_x + dx
			var py := mask_y + dy
			if px < 0 or py < 0 or px >= _mask_image.get_width() or py >= _mask_image.get_height():
				continue
			var biome_id := MaskTopologyRes.biome_id_from_pixel(_mask_image.get_pixel(px, py))
			if biome_id == MaskTopologyRes.OCEAN:
				continue
			if biome_id == MaskTopologyRes.SAVANNA:
				continue
			_mask_image.set_pixel(px, py, savanna)
			changed = true

	if changed:
		_mask_texture.update(_mask_image)
		_dirty = true
		_update_mode_ui()


func _save_map() -> void:
	if _water_image == null:
		_status_label.text = "Error: No water layer"
		return

	var topology := _apply_topology_fix()
	
	# Save PNG to maps/island/
	var save_path := ProjectSettings.globalize_path(WATER_LAYER_SAVE_PATH)
	var err := _water_image.save_png(save_path)
	if err != OK:
		_status_label.text = "Error saving water: %s" % error_string(err)
		return

	if _mask_image != null:
		var mask_path := ProjectSettings.globalize_path(MASK_PATH)
		err = _mask_image.save_png(mask_path)
		if err != OK:
			_status_label.text = "Error saving biome mask: %s" % error_string(err)
			return
	
	# Update island_meta.json
	_update_meta_json()
	
	_dirty = false
	_update_mode_ui()
	var report: Dictionary = MaskTopologyRes.validate(_mask_image, _water_image)
	if report.get("ok", false):
		_status_label.text = "Saved. Topology OK.\n%s" % _topology_summary(topology)
	else:
		_status_label.text = "Saved with topology warnings:\n%s" % MaskTopologyRes.format_report(report)
	print("Saved water layer to: %s" % save_path)


func _update_meta_json() -> void:
	if not FileAccess.file_exists(META_PATH):
		return
	var text := FileAccess.get_file_as_string(META_PATH)
	var parsed: Variant = JSON.parse_string(text)
	if typeof(parsed) != TYPE_DICTIONARY:
		return
	var meta: Dictionary = parsed as Dictionary
	meta["water_layer_path"] = "water_layer.png"
	
	var save_path := ProjectSettings.globalize_path(META_PATH)
	var file := FileAccess.open(save_path, FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(meta, "  "))
		file.close()


func _check_connectivity() -> int:
	if _water_image == null:
		_status_label.text = "No water layer"
		return 0
	
	var w := _water_image.get_width()
	var h := _water_image.get_height()
	
	# Find water tiles using union-find
	var parent := {}
	var water_count := 0
	
	# First pass: identify water pixels
	for y in range(h):
		for x in range(w):
			var c := _water_image.get_pixel(x, y)
			if c.r > 0.5:
				var idx := y * w + x
				parent[idx] = idx
				water_count += 1
	
	if water_count == 0:
		_status_label.text = "No water tiles painted"
		return 0
	
	# Find with path compression
	var find_root := func(i: int) -> int:
		var root := i
		while parent[root] != root:
			root = parent[root]
		# Path compression
		var curr := i
		while parent[curr] != root:
			var next_val: int = parent[curr]
			parent[curr] = root
			curr = next_val
		return root
	
	# Union neighbors (8-connected)
	var directions := [
		Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1),
		Vector2i(1, 1), Vector2i(-1, 1), Vector2i(1, -1), Vector2i(-1, -1)
	]
	
	for y in range(h):
		for x in range(w):
			var idx := y * w + x
			if not parent.has(idx):
				continue
			for d in directions:
				var nx: int = x + d.x
				var ny: int = y + d.y
				if nx >= 0 and nx < w and ny >= 0 and ny < h:
					var nidx: int = ny * w + nx
					if parent.has(nidx):
						var r1: int = find_root.call(idx)
						var r2: int = find_root.call(nidx)
						if r1 != r2:
							parent[r1] = r2
	
	# Count unique roots
	var roots := {}
	for idx in parent.keys():
		var r: int = find_root.call(idx)
		roots[r] = true
	
	var component_count := roots.size()
	
	if component_count == 1:
		_status_label.text = "✓ Rivers connected!\n%d water tiles" % water_count
	else:
		_status_label.text = "⚠ %d separate rivers\n%d water tiles\nConnect them!" % [component_count, water_count]
	
	return component_count


func _topology_summary(topology: Dictionary) -> String:
	return (
		"fixed land-in-ocean=%d, ocean-in-land=%d, desert-off-river=%d, specks=%d (rivers untouched)"
		% [
			topology.get("grass_in_water", 0),
			topology.get("ocean_in_grass", 0),
			topology.get("desert_retracted", 0),
			topology.get("biome_specks_fixed", 0),
		]
	)


func _validate_map_pressed() -> void:
	if _mask_image == null or _water_image == null:
		_status_label.text = "Missing biome mask or water layer"
		return
	var report: Dictionary = MaskTopologyRes.validate(_mask_image, _water_image)
	var shape_text := MaskTopologyRes.format_shape_report(_mask_image, _water_image)
	if report.get("ok", false):
		_status_label.text = "✓ Map shape OK\n%s" % shape_text
	else:
		_status_label.text = "%s\n%s" % [MaskTopologyRes.format_report(report), shape_text]


func _apply_topology_fix() -> Dictionary:
	if _mask_image == null or _water_image == null:
		return {}
	var fixed: Dictionary = MaskTopologyRes.fix(_mask_image, _water_image)
	_mask_texture.update(_mask_image)
	if (
		fixed.get("grass_in_water", 0) > 0
		or fixed.get("ocean_in_grass", 0) > 0
		or fixed.get("desert_retracted", 0) > 0
		or fixed.get("disconnected_ocean", 0) > 0
		or fixed.get("biome_specks_fixed", 0) > 0
	):
		_dirty = true
	return fixed


func _fix_topology_pressed() -> void:
	if _mask_image == null or _water_image == null:
		_status_label.text = "Missing biome mask or water layer"
		return
	var fixed := _apply_topology_fix()
	var report: Dictionary = MaskTopologyRes.validate(_mask_image, _water_image)
	if report.get("ok", false):
		_status_label.text = "✓ Map fixed\n%s\n%s" % [_topology_summary(fixed), MaskTopologyRes.format_shape_report(_mask_image, _water_image)]
	else:
		_status_label.text = "%s\nAfter fix:\n%s" % [
			MaskTopologyRes.format_report(report),
			_topology_summary(fixed),
		]


func _zoom_by(factor: float) -> void:
	_zoom = clampf(_zoom * factor, ZOOM_MIN, ZOOM_MAX)
	_camera.zoom = Vector2(_zoom, _zoom)
	_update_zoom_label()
	_queue_grid_redraw()


func _update_zoom_label() -> void:
	_zoom_label.text = "Zoom: %.2fx" % _zoom
	var mode_hint := "V=view, P=paint" if _mode == Mode.PAINT else "P=paint mode"
	_instructions_label.text = (
		"Controls:\n"
		+ "• Click+drag: pan (view) / paint (paint)\n"
		+ "• Right-click: erase rivers (river brush)\n"
		+ "• Grass brush: click to reset biomes → savanna\n"
		+ "• - / + or wheel: zoom\n"
		+ "• C: map center, Home: fit full island\n"
		+ "• G: toggle chunk grid\n"
		+ "• Ctrl+S / Cmd+S: save map, %s" % mode_hint
	)
