extends InventoryUI
class_name CartInventoryUI

# Cart inventory: 10 vertical slots, left side of screen
# Stacking up to 10

const SLOT_COUNT := 10
const PANEL_WIDTH := 80
const PANEL_HEIGHT := 640

@onready var inventory_panel: Panel = $InventoryPanel

func _ready() -> void:
	super._ready()
	
	# Create inventory data (10 slots, stacking disabled - only building inventories allow stacking)
	inventory_data = InventoryData.new(SLOT_COUNT, false, 1)
	
	# Setup panel
	_setup_panel()
	
	# Build slots
	_build_slots()
	
	# Initially hidden
	visible = false

func _setup_panel() -> void:
	if not has_node("InventoryPanel"):
		inventory_panel = Panel.new()
		inventory_panel.name = "InventoryPanel"
		add_child(inventory_panel)
	
	inventory_panel.custom_minimum_size = Vector2(PANEL_WIDTH, PANEL_HEIGHT)
	
	# Style panel using UITheme
	UITheme.apply_panel_style(inventory_panel)
	
	# Slot container
	if not inventory_panel.has_node("SlotContainer"):
		slot_container = VBoxContainer.new()
		slot_container.name = "SlotContainer"
		slot_container.add_theme_constant_override("separation", 4)
		inventory_panel.add_child(slot_container)
	
	# Position centered (to left of building inventory if both are visible)
	custom_minimum_size = Vector2(PANEL_WIDTH, PANEL_HEIGHT)
	anchors_preset = Control.PRESET_CENTER
	anchor_left = 0.5
	anchor_top = 0.5
	anchor_right = 0.5
	anchor_bottom = 0.5
	offset_left = -PANEL_WIDTH * 2 - 360  # Further left (2 panels + gaps from center)
	offset_top = -PANEL_HEIGHT / 2.0 - 50  # Match player inventory vertical offset
	offset_right = -PANEL_WIDTH - 360
	offset_bottom = PANEL_HEIGHT / 2.0 - 50

func _build_slots() -> void:
	# Clear existing
	for slot in slots:
		slot.queue_free()
	slots.clear()
	
	# Create vertical slots
	for i in SLOT_COUNT:
		var slot: InventorySlot = InventorySlot.new()
		slot.slot_index = i
		slot.is_hotbar = false
		slot.can_stack = false  # Carts cannot stack - only building inventories allow stacking
		slot.slot_clicked.connect(_on_slot_clicked)
		slot_container.add_child(slot)
		slots.append(slot)

