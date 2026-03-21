extends TextureRect
class_name InventorySlot

# Individual inventory slot - displays item icon, name, description, and quality border
# 64x64 pixels total: 32x32 icon centered + 2 lines of text below

signal slot_clicked(slot: InventorySlot)
signal slot_drag_ended(slot: InventorySlot)

const ICON_SIZE := 32
const SLOT_SIZE := 64  # Base size, hotbar uses 32x32, inventory uses 64x64

var slot_index: int = -1
var item_data: Dictionary = {}  # {"type": ResourceType, "count": int, "quality": int}
var is_hotbar: bool = false
var can_stack: bool = false  # Player inventory: false, Building/Cart: true

var icon_texture: TextureRect = null
var name_label: Label = null
var desc_label: Label = null
var quality_border: Sprite2D = null
var count_label: Label = null
var slot_number_label: Label = null
var hotbar_number_label: Label = null  # Large transparent number for hotbar slots

# Drag-and-drop visual feedback
var drag_manager: DragManager = null
var is_drag_source: bool = false  # Is this slot the source of current drag?
var is_hovered_during_drag: bool = false  # Is mouse hovering over this slot during drag?
var highlight_overlay: ColorRect = null  # Visual overlay for valid/invalid drop targets
var base_modulate: Color = Color.WHITE  # Store original modulate for restoration

func _ready() -> void:
	# Hotbar slots are 32x32, inventory slots are horizontal list items
	if is_hotbar:
		custom_minimum_size = Vector2(32, 32)  # 32x32 for hotbar
	else:
		# Horizontal list: icon (32px) + text area (remaining width)
		custom_minimum_size = Vector2(300, 38)  # 38px tall to fit all 10 items in 400px panel, 300px minimum width
	
	texture_filter = TEXTURE_FILTER_NEAREST
	mouse_filter = MOUSE_FILTER_STOP
	
	# Setup slot appearance - make bounding box clearly visible
	var style: StyleBoxFlat = StyleBoxFlat.new()
	if is_hotbar:
		# Hotbar slots: distinct grid squares with rustic style and faint outline
		style.bg_color = Color(0x2a / 255.0, 0x1f / 255.0, 0x1a / 255.0, 0.98)  # Dark earthy brown - matches game's rustic palette
		style.border_color = Color(0x8b / 255.0, 0x65 / 255.0, 0x3e / 255.0, 0.4)  # Faint warm saddle brown border
		style.set_border_width_all(1)  # Faint outline
		style.corner_radius_top_left = 3
		style.corner_radius_top_right = 3
		style.corner_radius_bottom_left = 3
		style.corner_radius_bottom_right = 3
		# Add subtle shadow for depth
		style.shadow_color = Color(0, 0, 0, 0.3)
		style.shadow_size = 2
		style.shadow_offset = Vector2(1, 1)
	else:
		# Inventory slots: standard styling with faint outline
		style.bg_color = Color(0x3c / 255.0, 0x27 / 255.0, 0x23 / 255.0, 0.95)  # Earthy brown
		style.border_color = Color(0x8b / 255.0, 0x45 / 255.0, 0x13 / 255.0, 0.4)  # Faint saddle brown border
		style.set_border_width_all(1)  # Faint outline
		style.corner_radius_top_left = 4
		style.corner_radius_top_right = 4
		style.corner_radius_bottom_left = 4
		style.corner_radius_bottom_right = 4
	add_theme_stylebox_override("panel", style)
	
	# Ensure hotbar slots are always visible as grid squares
	if is_hotbar:
		visible = true
		modulate = Color.WHITE
		show_behind_parent = false
	
	# Create child nodes if they don't exist
	_setup_children()
	
	# Connect input
	if not gui_input.is_connected(_on_gui_input):
		gui_input.connect(_on_gui_input)
	
	# Connect resize signal to update text label widths
	if not resized.is_connected(_on_resized):
		resized.connect(_on_resized)
	
	# Connect mouse enter/exit for drag feedback
	if not mouse_entered.is_connected(_on_mouse_entered):
		mouse_entered.connect(_on_mouse_entered)
	if not mouse_exited.is_connected(_on_mouse_exited):
		mouse_exited.connect(_on_mouse_exited)
	
	# Get drag manager reference
	_setup_drag_manager()
	
	# Store base modulate
	base_modulate = modulate
	
	# Create highlight overlay for drop target feedback
	_create_highlight_overlay()
	
	# Enable process for drag feedback updates
	set_process(true)

func _setup_children() -> void:
	# Icon (32x32, fits within bounding box)
	if has_node("Icon"):
		icon_texture = get_node("Icon") as TextureRect
	else:
		icon_texture = TextureRect.new()
		icon_texture.name = "Icon"
		icon_texture.custom_minimum_size = Vector2(ICON_SIZE, ICON_SIZE)
		icon_texture.texture_filter = TEXTURE_FILTER_NEAREST
		icon_texture.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
		icon_texture.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		icon_texture.visible = true
		icon_texture.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(icon_texture)
		
		if is_hotbar:
			# Hotbar: center icon in 32x32 slot
			icon_texture.position = Vector2((32 - ICON_SIZE) / 2.0, (32 - ICON_SIZE) / 2.0)
		else:
			# Inventory: icon on left side, vertically centered, constrained to 32x32 bounding box
			icon_texture.position = Vector2(8, (38 - ICON_SIZE) / 2.0)  # 8px padding, centered vertically in 38px slot
			icon_texture.custom_minimum_size = Vector2(ICON_SIZE, ICON_SIZE)
			icon_texture.size = Vector2(ICON_SIZE, ICON_SIZE)
			icon_texture.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
			icon_texture.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	
	# Name label - only for inventory slots, not hotbar (positioned to right of icon)
	if not is_hotbar:
		if has_node("NameLabel"):
			name_label = get_node("NameLabel") as Label
		else:
			name_label = Label.new()
			name_label.name = "NameLabel"
			name_label.add_theme_font_size_override("font_size", 16)  # Larger font for readability
			name_label.add_theme_color_override("font_color", Color.WHITE)
			name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
			name_label.vertical_alignment = VERTICAL_ALIGNMENT_TOP
			add_child(name_label)
			name_label.position = Vector2(ICON_SIZE + 11, 4)  # 11px gap from icon, 4px from top
			name_label.size = Vector2(250, 14)  # Reduced height to fit in smaller slot
			name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	
	# Description label - only for inventory slots, not hotbar (positioned below name, to right of icon)
	if not is_hotbar:
		if has_node("DescLabel"):
			desc_label = get_node("DescLabel") as Label
		else:
			desc_label = Label.new()
			desc_label.name = "DescLabel"
			desc_label.add_theme_font_size_override("font_size", 12)  # Larger font for readability
			desc_label.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7))
			desc_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
			desc_label.vertical_alignment = VERTICAL_ALIGNMENT_TOP
			desc_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			add_child(desc_label)
			desc_label.position = Vector2(ICON_SIZE + 11, 18)  # Below name label, 11px gap from icon
			desc_label.size = Vector2(250, 18)  # Reduced height to fit in smaller slot, allows 1-2 lines
			desc_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	
	# Quality border overlay
	if has_node("QualityBorder"):
		quality_border = get_node("QualityBorder") as Sprite2D
	else:
		quality_border = Sprite2D.new()
		quality_border.name = "QualityBorder"
		if is_hotbar:
			quality_border.position = Vector2(16, 16)  # Center of 32x32 slot
		else:
			quality_border.position = Vector2(8 + ICON_SIZE / 2.0, 19)  # Center of icon area (8px padding, centered in 38px slot)
		quality_border.scale = Vector2(ICON_SIZE / 32.0, ICON_SIZE / 32.0)
		quality_border.visible = false
		add_child(quality_border)
	
	# Count label (for stacked items)
	if has_node("CountLabel"):
		count_label = get_node("CountLabel") as Label
	else:
		count_label = Label.new()
		count_label.name = "CountLabel"
		count_label.add_theme_font_size_override("font_size", 12)
		count_label.add_theme_color_override("font_color", Color.WHITE)
		count_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		count_label.vertical_alignment = VERTICAL_ALIGNMENT_TOP
		add_child(count_label)
		if is_hotbar:
			count_label.position = Vector2(32 - 18, 2)  # Top-right of 32x32 slot
		else:
			count_label.position = Vector2(8 + ICON_SIZE - 18, 2)  # Top-right of icon area (8px padding)
		count_label.size = Vector2(16, 14)
		count_label.visible = false
	
	# Slot number label (small, top-left for inventory slots)
	if not is_hotbar:
		if has_node("SlotNumberLabel"):
			slot_number_label = get_node("SlotNumberLabel") as Label
		else:
			slot_number_label = Label.new()
			slot_number_label.name = "SlotNumberLabel"
			slot_number_label.add_theme_font_size_override("font_size", 10)
			slot_number_label.add_theme_color_override("font_color", Color(1.0, 1.0, 1.0, 0.5))  # Faint white
			slot_number_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
			slot_number_label.vertical_alignment = VERTICAL_ALIGNMENT_TOP
			add_child(slot_number_label)
			slot_number_label.position = Vector2(2, 2)  # Top-left of inventory slot
			slot_number_label.size = Vector2(20, 12)
			slot_number_label.text = str(slot_index + 1)  # Display 1-based index
			slot_number_label.visible = true
	
	# Hotbar number label (large, bold, transparent, centered for hotbar slots)
	if is_hotbar:
		if has_node("HotbarNumberLabel"):
			hotbar_number_label = get_node("HotbarNumberLabel") as Label
		else:
			hotbar_number_label = Label.new()
			hotbar_number_label.name = "HotbarNumberLabel"
			hotbar_number_label.add_theme_font_size_override("font_size", 24)  # Large font
			hotbar_number_label.add_theme_color_override("font_color", Color(1.0, 1.0, 1.0, 0.15))  # Very transparent (15% opacity)
			hotbar_number_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			hotbar_number_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
			# Make it bold by using a bold font if available, or increase size
			hotbar_number_label.add_theme_font_size_override("font_size", 28)  # Even larger for bold effect
			add_child(hotbar_number_label)
			# Center in 32x32 slot
			hotbar_number_label.anchors_preset = Control.PRESET_CENTER
			hotbar_number_label.anchor_left = 0.5
			hotbar_number_label.anchor_top = 0.5
			hotbar_number_label.anchor_right = 0.5
			hotbar_number_label.anchor_bottom = 0.5
			hotbar_number_label.offset_left = -16
			hotbar_number_label.offset_top = -16
			hotbar_number_label.offset_right = 16
			hotbar_number_label.offset_bottom = 16
			hotbar_number_label.custom_minimum_size = Vector2(32, 32)
			# Get slot number from meta or calculate: 0-8 = "1"-"9", 9 = "0"
			var slot_num: String
			if has_meta("slot_number"):
				slot_num = str(get_meta("slot_number"))  # str() avoids Invalid cast if stored as int
			else:
				slot_num = str((slot_index + 1) % 10)  # 1-9 for indices 0-8, 0 for index 9
			hotbar_number_label.text = slot_num
			hotbar_number_label.visible = true

func set_item(data: Dictionary) -> void:
	item_data = data.duplicate() if data.size() > 0 else {}
	_update_display()

func get_item() -> Dictionary:
	return item_data.duplicate()

func is_empty() -> bool:
	return item_data.is_empty()

func _update_display() -> void:
	if item_data.is_empty():
		# Empty slot - but keep background visible, especially for hotbar grid squares
		if icon_texture:
			icon_texture.texture = null
			icon_texture.visible = false
		if name_label:
			name_label.text = ""
			name_label.visible = false
		if desc_label:
			desc_label.text = ""
			desc_label.visible = false
		if quality_border:
			quality_border.visible = false
		if count_label:
			count_label.visible = false
		
		# Update slot number visibility
		if slot_number_label:
			slot_number_label.visible = true  # Always show slot number (inventory slots)
		if hotbar_number_label:
			hotbar_number_label.visible = true  # Always show hotbar number (hotbar slots)
		
		# Hotbar slots must always show as visible grid squares
		if is_hotbar:
			visible = true
			modulate = Color.WHITE
		return
	
	# Item exists - make sure icon is visible
	if icon_texture:
		icon_texture.visible = true
	
	# Hide text labels for hotbar slots
	if is_hotbar:
		if name_label:
			name_label.visible = false
		if desc_label:
			desc_label.visible = false
	else:
		# Show text labels for inventory slots
		if name_label:
			name_label.visible = true
		if desc_label:
			desc_label.visible = true
		
		# Update text label sizes to match slot width
		_on_resized()
	
	# Get item info
	var item_type: ResourceData.ResourceType = item_data.get("type", ResourceData.ResourceType.NONE) as ResourceData.ResourceType
	var count: int = item_data.get("count", 1) as int
	var quality: int = item_data.get("quality", 0) as int
	
	# Set icon - ensure it fits within bounding box
	if not icon_texture:
		return  # Icon texture not created yet
	
	var icon_path: String = ResourceData.get_resource_icon_path(item_type)
	if icon_path != "":
		var loaded_texture: Texture2D = load(icon_path) as Texture2D
		if loaded_texture:
			icon_texture.texture = loaded_texture
			icon_texture.visible = true
			# Ensure icon doesn't exceed ICON_SIZE
			icon_texture.custom_minimum_size = Vector2(ICON_SIZE, ICON_SIZE)
			icon_texture.size = Vector2(ICON_SIZE, ICON_SIZE)
		else:
			# Fallback colored square
			icon_texture.texture = _create_fallback_icon(item_type)
			icon_texture.visible = true
			icon_texture.custom_minimum_size = Vector2(ICON_SIZE, ICON_SIZE)
			icon_texture.size = Vector2(ICON_SIZE, ICON_SIZE)
	else:
		icon_texture.texture = _create_fallback_icon(item_type)
		icon_texture.visible = true
		icon_texture.custom_minimum_size = Vector2(ICON_SIZE, ICON_SIZE)
		icon_texture.size = Vector2(ICON_SIZE, ICON_SIZE)
	
	# Set text (only for inventory slots, not hotbar)
	if not is_hotbar:
		if name_label:
			name_label.text = ResourceData.get_resource_name(item_type)
		if desc_label:
			desc_label.text = ResourceData.get_resource_description(item_type)
	
	# Set quality border
	_update_quality_border(quality)
	
	# Set count (only show if > 1 and can stack)
	if count_label:
		if can_stack and count > 1:
			count_label.text = str(count)
			count_label.visible = true
		else:
			count_label.visible = false

func _create_fallback_icon(item_type: ResourceData.ResourceType) -> Texture2D:
	var image := Image.create(ICON_SIZE, ICON_SIZE, false, Image.FORMAT_RGBA8)
	var color: Color = ResourceData.get_resource_color(item_type)
	image.fill(color)
	var fallback_texture: ImageTexture = ImageTexture.create_from_image(image)
	return fallback_texture

func _update_quality_border(quality: int) -> void:
	if not quality_border:
		return
	
	# Quality colors: Grey=Flawed, White=Common, Blue=Good, Light Blue=Fine, Light Purple=Master, Purple=Legendary
	var border_colors := [
		Color(0.5, 0.5, 0.5),      # Flawed - Grey
		Color(1.0, 1.0, 1.0),      # Common - White
		Color(0.2, 0.4, 1.0),      # Good - Blue
		Color(0.4, 0.6, 1.0),      # Fine - Light Blue
		Color(0.7, 0.5, 1.0),      # Master - Light Purple
		Color(0.8, 0.2, 1.0),      # Legendary - Purple
	]
	
	if quality >= 0 and quality < border_colors.size():
		# Create border texture
		var border_image := Image.create(32, 32, false, Image.FORMAT_RGBA8)
		border_image.fill(Color.TRANSPARENT)
		
		# Draw 2px border
		var border_color: Color = border_colors[quality]
		for x in 32:
			for y in 32:
				if x < 2 or x >= 30 or y < 2 or y >= 30:
					border_image.set_pixel(x, y, border_color)
		
		var border_texture := ImageTexture.create_from_image(border_image)
		quality_border.texture = border_texture
		quality_border.visible = true
		
		# Add pulse animation for Legendary
		if quality == 5:
			var tween := create_tween()
			tween.set_loops()
			tween.tween_property(quality_border, "modulate", Color(1.2, 1.2, 1.2), 0.5)
			tween.tween_property(quality_border, "modulate", Color.WHITE, 0.5)
	else:
		quality_border.visible = false

func _on_resized() -> void:
	# Update text label widths when slot is resized
	if not is_hotbar and item_data.size() > 0:
		if name_label:
			var text_area_width: float = size.x - ICON_SIZE - 11 - 8  # Total width - icon - gap (11px) - right padding
			if text_area_width > 0:
				name_label.size.x = text_area_width
		if desc_label:
			var text_area_width: float = size.x - ICON_SIZE - 11 - 8  # Total width - icon - gap (11px) - right padding
			if text_area_width > 0:
				desc_label.size.x = text_area_width

func _on_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		var mouse_event := event as InputEventMouseButton
		if mouse_event.button_index == MOUSE_BUTTON_LEFT:
			if mouse_event.pressed:
				# Start drag on click
				if not item_data.is_empty():
					slot_clicked.emit(self)
					get_viewport().set_input_as_handled()
			else:
				# Release - handle drop (but also handled globally in inventory_ui)
				slot_drag_ended.emit(self)
				get_viewport().set_input_as_handled()
	elif event is InputEventMouseMotion:
		# Mouse movement while dragging - update highlight if hovering
		if drag_manager and drag_manager.is_dragging:
			_update_drop_target_highlight()

func _get_inventory_name() -> String:
	# Helper to get inventory name for logging
	var parent = get_parent()
	while parent:
		if parent.has_method("get") and parent.get("name"):
			var name = str(parent.get("name"))
			if "Inventory" in name:
				return name
		parent = parent.get_parent()
	return "unknown"

func _setup_drag_manager() -> void:
	# Get drag manager from scene tree
	var main: Node = get_tree().get_first_node_in_group("main")
	if main and main.has_method("get") and main.get("drag_manager"):
		drag_manager = main.get("drag_manager") as DragManager
		if drag_manager:
			# Connect to drag manager signals
			if not drag_manager.drag_started.is_connected(_on_drag_started):
				drag_manager.drag_started.connect(_on_drag_started)
			if not drag_manager.drag_ended.is_connected(_on_drag_ended):
				drag_manager.drag_ended.connect(_on_drag_ended)

func _create_highlight_overlay() -> void:
	# Create a color rect overlay for drop target feedback
	if highlight_overlay:
		return
	
	highlight_overlay = ColorRect.new()
	highlight_overlay.name = "HighlightOverlay"
	highlight_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	highlight_overlay.visible = false
	highlight_overlay.color = Color.TRANSPARENT
	add_child(highlight_overlay)
	
	# Make overlay fill the entire slot
	highlight_overlay.anchors_preset = Control.PRESET_FULL_RECT
	highlight_overlay.anchor_left = 0.0
	highlight_overlay.anchor_top = 0.0
	highlight_overlay.anchor_right = 1.0
	highlight_overlay.anchor_bottom = 1.0

func _on_drag_started(item_data: Dictionary, from_slot: InventorySlot) -> void:
	# Called when drag starts - check if this is the source slot
	if from_slot == self:
		is_drag_source = true
		# Make source slot semi-transparent (50% opacity)
		modulate = Color(1, 1, 1, 0.5)
	else:
		is_drag_source = false
		# Restore modulate if we were previously the source
		if modulate.a < 1.0:
			modulate = base_modulate

func _on_drag_ended() -> void:
	# Called when drag ends - restore visual state
	is_drag_source = false
	is_hovered_during_drag = false
	modulate = base_modulate
	_clear_highlight()

func _on_mouse_entered() -> void:
	# Called when mouse enters this slot
	if drag_manager and drag_manager.is_dragging:
		is_hovered_during_drag = true
		_update_drop_target_highlight()

func _on_mouse_exited() -> void:
	# Called when mouse exits this slot
	is_hovered_during_drag = false
	_clear_highlight()

func _update_drop_target_highlight() -> void:
	# Update highlight based on whether drop is valid
	if not drag_manager or not drag_manager.is_dragging:
		_clear_highlight()
		return
	
	if not is_hovered_during_drag:
		_clear_highlight()
		return
	
	# Don't highlight the source slot
	if is_drag_source:
		_clear_highlight()
		return
	
	# Check if drop is valid
	var is_valid = _is_valid_drop_target()
	
	if is_valid:
		# Valid drop target - gold highlight (#FFCE1B at ~30% opacity)
		_show_highlight(Color(1.0, 0.808, 0.106, 0.3))  # #FFCE1B with 30% opacity
	else:
		# Invalid drop target - red highlight (#B31B1B at ~30% opacity)
		_show_highlight(Color(0.702, 0.106, 0.106, 0.3))  # #B31B1B with 30% opacity

func _is_valid_drop_target() -> bool:
	# Check if the dragged item can be dropped in this slot
	if not drag_manager or not drag_manager.is_dragging:
		return false
	
	var dragged_item = drag_manager.dragged_item
	if dragged_item.is_empty():
		return false
	
	# Hotbar slots: reject placeable buildings (they must be placed in world, not equipped)
	if is_hotbar:
		var item_type: ResourceData.ResourceType = dragged_item.get("type", -1) as ResourceData.ResourceType
		var is_placeable_building: bool = (
			item_type == ResourceData.ResourceType.LANDCLAIM or
			item_type == ResourceData.ResourceType.LIVING_HUT or
			item_type == ResourceData.ResourceType.SUPPLY_HUT or
			item_type == ResourceData.ResourceType.SHRINE or
			item_type == ResourceData.ResourceType.DAIRY_FARM or
			item_type == ResourceData.ResourceType.FARM or
			item_type == ResourceData.ResourceType.OVEN
		)
		if is_placeable_building:
			return false
	
	# Get inventory data for this slot
	var inventory_data = _get_inventory_data_for_slot()
	if not inventory_data:
		return false
	
	# If slot is empty, drop is valid (and not a rejected building)
	if item_data.is_empty():
		return true
	
	# If slot has item, check if we can stack
	var slot_item_type = item_data.get("type", -1)
	var dragged_item_type = dragged_item.get("type", -1)
	
	# Same type and can stack - valid
	if slot_item_type == dragged_item_type and inventory_data.can_stack:
		var slot_count = item_data.get("count", 1)
		var dragged_count = dragged_item.get("count", 1)
		var max_stack = inventory_data.max_stack
		return (slot_count + dragged_count) <= max_stack
	
	# Different type or can't stack - invalid (would overwrite)
	return false

func _get_inventory_data_for_slot() -> InventoryData:
	# Helper to get inventory data for this slot
	if drag_manager:
		return drag_manager._get_inventory_data_for_slot(self)
	return null

func _show_highlight(color: Color) -> void:
	# Show highlight overlay with specified color
	if highlight_overlay:
		highlight_overlay.color = color
		highlight_overlay.visible = true

func _clear_highlight() -> void:
	# Clear highlight overlay
	if highlight_overlay:
		highlight_overlay.visible = false
		highlight_overlay.color = Color.TRANSPARENT

func _process(_delta: float) -> void:
	# Update highlight if dragging and hovering
	if drag_manager and drag_manager.is_dragging and is_hovered_during_drag:
		_update_drop_target_highlight()
