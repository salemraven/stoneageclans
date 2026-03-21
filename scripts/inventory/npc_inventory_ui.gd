extends InventoryUI
class_name NPCInventoryUI

# NPC inventory: 10 slots in vertical list, appears above NPC sprite when clicked
# Similar to player inventory but simpler layout

const SLOT_COUNT := 10
const SLOT_SIZE := 32
const PANEL_WIDTH := 200
const PANEL_HEIGHT := 380  # 10 slots * 32 + padding + taller name label (40px instead of 24px)

var inventory_panel: Panel = null
var target_npc: Node = null  # The NPC this inventory belongs to

# Helper function to log to both console and file
func _log(message: String, level: String = "INFO") -> void:
	var log_level = UnifiedLogger.Level.INFO
	match level.to_upper():
		"ERROR":
			log_level = UnifiedLogger.Level.ERROR
			UnifiedLogger.log_error(message, UnifiedLogger.Category.INVENTORY)
		"WARNING":
			log_level = UnifiedLogger.Level.WARNING
			UnifiedLogger.log_warning(message, UnifiedLogger.Category.INVENTORY)
		_:
			UnifiedLogger.log_inventory(message)

func _ready() -> void:
	super._ready()
	
	# Create inventory data (10 slots, no stacking) - will be replaced by setup()
	inventory_data = InventoryData.new(SLOT_COUNT, false, 1)
	
	# Setup panel
	call_deferred("_setup_panel")
	
	# Build slots (use call_deferred to ensure nodes are ready)
	call_deferred("_build_slots")
	
	# Initially hidden
	visible = false
	set_as_top_level(true)
	mouse_filter = Control.MOUSE_FILTER_IGNORE

func _setup_panel() -> void:
	if not has_node("InventoryPanel"):
		inventory_panel = Panel.new()
		inventory_panel.name = "InventoryPanel"
		add_child(inventory_panel)
	
	inventory_panel.custom_minimum_size = Vector2(PANEL_WIDTH, PANEL_HEIGHT)
	
	# Style panel using UITheme with custom purple border for NPCs
	var style := UITheme.get_panel_style_with_border(Color(0x8b / 255.0, 0x45 / 255.0, 0x9f / 255.0, 0.9))  # Purple-ish for NPCs
	# Override shadow for NPC panel (slightly different from standard)
	style.shadow_color = Color(0, 0, 0, 0.5)
	style.shadow_size = 5
	style.shadow_offset = Vector2(0, 2)
	inventory_panel.add_theme_stylebox_override("panel", style)
	
	# VBox container for vertical slot list
	if not inventory_panel.has_node("MarginContainer"):
		var margin: MarginContainer = MarginContainer.new()
		margin.name = "MarginContainer"
		margin.add_theme_constant_override("margin_left", 8)
		margin.add_theme_constant_override("margin_top", 8)
		margin.add_theme_constant_override("margin_right", 8)
		margin.add_theme_constant_override("margin_bottom", 8)
		inventory_panel.add_child(margin)
		
		# Create VBox for name bar and slots
		var main_vbox: VBoxContainer = VBoxContainer.new()
		main_vbox.name = "MainVBox"
		main_vbox.add_theme_constant_override("separation", 4)
		margin.add_child(main_vbox)
		
		# Create name bar label (for caveman NPCs, women with pregnancy timer, babies with age)
		var name_label: Label = Label.new()
		name_label.name = "NameLabel"
		name_label.text = ""
		name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		name_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		name_label.add_theme_color_override("font_color", Color.WHITE)
		name_label.add_theme_font_size_override("font_size", 14)
		name_label.add_theme_constant_override("outline_size", 4)
		name_label.add_theme_color_override("font_outline_color", Color.BLACK)
		name_label.autowrap_mode = TextServer.AUTOWRAP_OFF  # No wrapping, allow multi-line with \n
		name_label.custom_minimum_size = Vector2(PANEL_WIDTH - 16, 40)  # Taller to fit 2 lines (name + timer/age)
		name_label.visible = false  # Hidden by default, shown when NPC name is set
		main_vbox.add_child(name_label)
		
		slot_container = VBoxContainer.new()
		slot_container.name = "SlotContainer"
		slot_container.add_theme_constant_override("separation", 2)  # Minimal spacing
		main_vbox.add_child(slot_container)
	
	# Set size
	custom_minimum_size = Vector2(PANEL_WIDTH, PANEL_HEIGHT)

func _build_slots() -> void:
	print("🔍 NPC_INVENTORY_UI: _build_slots() called")
	
	if not slot_container:
		print("❌ NPC_INVENTORY_UI ERROR: slot_container is null!")
		return
	
	print("   - slot_container: %s" % slot_container)
	print("   - Clearing existing slots (count: %d)..." % slots.size())
	
	# Clear existing slots
	for slot in slots:
		if is_instance_valid(slot):
			slot.queue_free()
	slots.clear()
	print("   - Slots cleared")
	
	print("   - Creating %d slots..." % SLOT_COUNT)
	# Create slots
	for i in SLOT_COUNT:
		print("   - Creating slot %d..." % i)
		var slot: InventorySlot = InventorySlot.new()
		slot.slot_index = i
		slot.is_hotbar = false
		slot.can_stack = false  # NPCs cannot stack - only building inventories allow stacking
		slot.custom_minimum_size = Vector2(SLOT_SIZE, SLOT_SIZE)
		slot.name = "Slot%d" % i
		
		# Connect signals
		if not slot.slot_clicked.is_connected(_on_slot_clicked):
			slot.slot_clicked.connect(_on_slot_clicked)
		if not slot.slot_drag_ended.is_connected(_on_slot_drag_ended):
			slot.slot_drag_ended.connect(_on_slot_drag_ended)
		
		slot_container.add_child(slot)
		slots.append(slot)
		print("   - Slot %d created and added" % i)
	
	print("   - All slots created (total: %d)" % slots.size())
	print("   - Calling _update_all_slots()...")
	# Update display
	_update_all_slots()
	print("✅ NPC_INVENTORY_UI: _build_slots() completed")
	
	# Make slots read-only (player can see but not take items from NPC inventory)
	# Slots will still be visible but won't respond to mouse clicks/drags
	for slot in slots:
		# Keep MOUSE_FILTER_STOP for visual feedback, but prevent actual drag in _on_slot_clicked
		pass

func _on_slot_clicked(_slot: InventorySlot) -> void:
	# NPC inventory is read-only - player cannot take items
	# Override to prevent dragging from NPC inventory
	pass

func _on_slot_drag_ended(_slot: InventorySlot) -> void:
	# NPC inventory is read-only - prevent drops into NPC inventory
	# Only allow drops FROM NPC inventory if somehow drag started (shouldn't happen)
	pass

func _handle_drop(target_slot: InventorySlot) -> void:
	# NPC inventory is read-only - prevent drops into NPC inventory
	if drag_manager and drag_manager.is_dragging:
		# Cancel the drag if trying to drop into NPC inventory
		drag_manager.end_drag()
		return
	super._handle_drop(target_slot)

func setup(inventory: InventoryData) -> void:
	print("🔍 NPC_INVENTORY_UI: setup() called")
	print("   - inventory: %s (valid: %s)" % [inventory, inventory != null])
	
	if not inventory:
		print("❌ NPC_INVENTORY_UI ERROR: inventory is null in setup()!")
		return
	
	print("   - inventory.slot_count: %d" % inventory.slot_count)
	print("   - slots.size() before super.setup(): %d" % slots.size())
	
	print("   - Calling super.setup(inventory)...")
	super.setup(inventory)
	print("   - super.setup() completed")
	
	print("   - slots.size() after super.setup(): %d" % slots.size())
	print("   - Calling _update_all_slots()...")
	_update_all_slots()
	print("   - _update_all_slots() completed")
	
	print("✅ NPC_INVENTORY_UI: setup() completed successfully")

func setup_with_npc(npc: Node, inventory: InventoryData) -> void:
	_log("🔍 NPC_INVENTORY_UI: setup_with_npc() called")
	var npc_name_str = "unknown"
	if npc and is_instance_valid(npc):
		var name_val = npc.get("npc_name")
		if name_val != null:
			npc_name_str = name_val
	_log("   - npc: %s (valid: %s)" % [npc_name_str, is_instance_valid(npc)])
	_log("   - inventory: %s (valid: %s)" % [inventory, inventory != null])
	
	if not npc or not is_instance_valid(npc):
		_log("NPC_INVENTORY_UI ERROR: npc is null or invalid!", "ERROR")
		return
	
	if not inventory:
		_log("NPC_INVENTORY_UI ERROR: inventory is null!", "ERROR")
		return
	
	_log("   - inventory.slot_count: %d" % inventory.slot_count)
	_log("   - slots.size(): %d" % slots.size())
	
	target_npc = npc
	_log("   - target_npc set successfully")
	
	_log("   - Calling setup(inventory)...")
	setup(inventory)
	_log("   - setup() completed")
	
	_log("   - Calling _update_name_label()...")
	_update_name_label()
	_log("   - _update_name_label() completed")
	
	_log("✅ NPC_INVENTORY_UI: setup_with_npc() completed successfully")

func show_at_npc_position(npc: Node) -> void:
	print("🔍 NPC_INVENTORY_UI: show_at_npc_position() called")
	var npc_name_str = "unknown"
	if npc and is_instance_valid(npc):
		var name_val = npc.get("npc_name")
		if name_val != null:
			npc_name_str = name_val
	print("   - npc: %s (valid: %s)" % [npc_name_str, is_instance_valid(npc)])
	
	if not npc or not is_instance_valid(npc):
		print("❌ NPC_INVENTORY_UI ERROR: npc is null or invalid in show_at_npc_position()!")
		return
	
	print("   - Setting target_npc...")
	target_npc = npc
	var target_name = "unknown"
	if target_npc and is_instance_valid(target_npc):
		var name_val = target_npc.get("npc_name")
		if name_val != null:
			target_name = name_val
	print("   - target_npc set: %s" % target_name)
	
	print("   - Calling _update_name_label()...")
	_update_name_label()
	print("   - _update_name_label() completed")
	
	print("   - Calling _update_position()...")
	_update_position()
	print("   - _update_position() completed")
	
	# Explicitly ensure visibility is set (in case _update_position had issues)
	visible = true
	print("   - visible explicitly set to: true")
	if inventory_panel:
		inventory_panel.visible = true
		print("   - inventory_panel.visible explicitly set to: true")
	
	print("✅ NPC_INVENTORY_UI: show_at_npc_position() completed successfully")

func hide_inventory() -> void:
	visible = false
	if inventory_panel:
		inventory_panel.visible = false
	target_npc = null

func _update_position() -> void:
	print("🔍 NPC_INVENTORY_UI: _update_position() called")
	
	if not target_npc or not is_instance_valid(target_npc):
		print("❌ NPC_INVENTORY_UI ERROR: target_npc is null or invalid!")
		return
	
	var target_name = "unknown"
	if target_npc and is_instance_valid(target_npc):
		var name_val = target_npc.get("npc_name")
		if name_val != null:
			target_name = name_val
	print("   - target_npc: %s" % target_name)
	
	# Safety check - make sure we have a viewport
	var viewport: Viewport = get_viewport()
	if not viewport:
		print("❌ NPC_INVENTORY_UI ERROR: viewport is null!")
		return
	
	print("   - viewport: %s" % viewport)
	
	# Get NPC's world position and convert to screen position
	var camera: Camera2D = viewport.get_camera_2d()
	if not camera:
		print("❌ NPC_INVENTORY_UI ERROR: camera is null!")
		return
	
	print("   - camera: %s" % camera)
	
	# Convert world position to screen position using camera
	print("   - Getting world position...")
	var world_pos: Vector2 = target_npc.global_position
	print("   - world_pos: %s" % world_pos)
	
	var camera_pos: Vector2 = camera.global_position
	print("   - camera_pos: %s" % camera_pos)
	
	var viewport_size: Vector2 = viewport.get_visible_rect().size
	print("   - viewport_size: %s" % viewport_size)
	
	if viewport_size.x <= 0 or viewport_size.y <= 0:
		print("❌ NPC_INVENTORY_UI ERROR: viewport_size is invalid: %s" % viewport_size)
		return  # Viewport not ready yet
	
	var screen_center: Vector2 = viewport_size / 2.0
	print("   - screen_center: %s" % screen_center)
	
	# Convert world position relative to camera to screen position
	# Camera is centered on screen, so world position relative to camera = screen position
	var relative_pos: Vector2 = world_pos - camera_pos
	var screen_pos: Vector2 = screen_center + relative_pos
	print("   - screen_pos: %s" % screen_pos)
	
	# Position inventory above NPC sprite (offset upward)
	var offset_y: float = -80.0  # Above the NPC
	position = screen_pos + Vector2(-PANEL_WIDTH / 2.0, offset_y)
	print("   - position set to: %s" % position)
	
	# Make sure it's visible
	visible = true
	print("   - visible set to: true")
	
	if inventory_panel:
		inventory_panel.visible = true
		print("   - inventory_panel.visible set to: true")
	else:
		print("⚠️ NPC_INVENTORY_UI WARNING: inventory_panel is null!")
	
	# Update display (throttled in _process() to prevent crash)
	# Removed immediate _update_all_slots() call - now handled safely in _process()
	print("✅ NPC_INVENTORY_UI: _update_position() completed")

func _update_name_label() -> void:
	# Update the name label with NPC's name, pregnancy timer (women), or age (babies)
	var name_label: Label = inventory_panel.get_node_or_null("MarginContainer/MainVBox/NameLabel") if inventory_panel else null
	if not name_label:
		return
	
	if target_npc and is_instance_valid(target_npc):
		var npc_name: String = ""
		var npc_type: String = ""
		if target_npc and is_instance_valid(target_npc):
			var name_val = target_npc.get("npc_name")
			if name_val != null:
				npc_name = name_val
			var type_val = target_npc.get("npc_type")
			if type_val != null:
				npc_type = type_val
		
		# Show name for cavemen and clansmen
		if (npc_type == "caveman" or npc_type == "clansman") and npc_name != "":
			name_label.text = npc_name
			name_label.visible = true
		# Show name and pregnancy timer for women
		elif npc_type == "woman" and npc_name != "":
			var display_text = npc_name
			# Check if woman is pregnant
			var repro_comp = target_npc.get_node_or_null("ReproductionComponent")
			if repro_comp and repro_comp is ReproductionComponent:
				if repro_comp.is_pregnant and repro_comp.birth_timer > 0.0:
					var timer_seconds = int(ceil(repro_comp.birth_timer))
					display_text = "%s\nPregnant: %ds remaining" % [npc_name, timer_seconds]
			name_label.text = display_text
			name_label.visible = true
		# Show name and age for babies (1 year = 2 seconds for testing)
		elif npc_type == "baby" and npc_name != "":
			var display_text = npc_name
			# Get baby age from growth component (1 year = 2 seconds)
			var growth_comp = target_npc.get_node_or_null("BabyGrowthComponent")
			if growth_comp and growth_comp is BabyGrowthComponent:
				var age_years = int(floor(growth_comp.growth_timer / 2.0))  # 1 year = 2 seconds
				display_text = "%s\nAge: %dy" % [npc_name, age_years]
			name_label.text = display_text
			name_label.visible = true
		else:
			name_label.text = ""
			name_label.visible = false
	else:
		name_label.text = ""
		name_label.visible = false

var position_update_timer: float = 0.0
const POSITION_UPDATE_INTERVAL: float = 0.1  # Update position every 0.1 seconds instead of every frame

func _process(delta: float) -> void:
	# OPTIMIZATION: Early exit if not visible - no need to process when hidden
	if not visible:
		return
	
	# Throttle position updates to prevent freeze (only update every 0.1 seconds)
	if target_npc and is_instance_valid(target_npc):
		position_update_timer += delta
		if position_update_timer >= POSITION_UPDATE_INTERVAL:
			position_update_timer = 0.0
			_update_position()
			# Update name label (for pregnancy timer and baby age)
			_update_name_label()
			# Only update slots when position changes, not every frame
			# Add null check to prevent crash
			if inventory_data and slots.size() > 0:
				_update_all_slots()
