extends Control
class_name NPCDebugUI

# Debug UI for inspecting NPCs
# Press F1 to toggle, click NPCs to inspect

@onready var debug_panel: Panel = get_node_or_null("DebugPanel")
@onready var npc_list: ItemList = get_node_or_null("DebugPanel/NPCList")
@onready var info_label: RichTextLabel = get_node_or_null("DebugPanel/InfoLabel")
@onready var close_button: Button = get_node_or_null("DebugPanel/CloseButton")

var debug_visible: bool = false
var selected_npc: Node = null
var update_timer: float = 0.0
var update_interval: float = 0.5  # Update every 0.5 seconds

func _ready() -> void:
	visible = false
	if debug_panel:
		debug_panel.visible = false
	
	# Connect close button
	if close_button:
		close_button.pressed.connect(_on_close_pressed)
	
	# Setup input
	_setup_input()

func _setup_input() -> void:
	# F1 to toggle debug UI
	pass  # Will be handled in main.gd

func _process(delta: float) -> void:
	if not debug_visible:
		return
	
	update_timer += delta
	if update_timer >= update_interval:
		update_timer = 0.0
		_update_npc_list()
		_update_info_display()

func toggle() -> void:
	debug_visible = not debug_visible
	visible = debug_visible
	if debug_panel:
		debug_panel.visible = debug_visible
	
	if debug_visible:
		_update_npc_list()
		_update_info_display()

func _update_npc_list() -> void:
	if not npc_list:
		return
	
	npc_list.clear()
	
	var npcs: Array = get_tree().get_nodes_in_group("npcs")
	for npc in npcs:
		if not is_instance_valid(npc):
			continue
		
		var npc_node: Node = npc as Node
		var display_name: String = "%s (%s)" % [npc_node.get("npc_name"), npc_node.get("npc_type")]
		var index: int = npc_list.add_item(display_name)
		npc_list.set_item_metadata(index, npc_node)
		
		# Highlight selected
		if npc_node == selected_npc:
			npc_list.select(index)

func _update_info_display() -> void:
	if not info_label:
		return
	
	if not selected_npc or not is_instance_valid(selected_npc):
		info_label.text = "No NPC selected. Click an NPC in the list or in the world."
		return
	
	var info: Dictionary = selected_npc.get_debug_info() as Dictionary
	var text: String = "[b]%s[/b]\n" % info.get("name", "Unknown")
	text += "Type: %s\n" % info.get("type", "unknown")
	text += "Age: %d years\n" % info.get("age", 0)
	text += "Quality: %s\n" % info.get("quality_tier", "Unknown")
	text += "Position: (%.1f, %.1f)\n" % [info.get("position", Vector2.ZERO).x, info.get("position", Vector2.ZERO).y]
	text += "Velocity: (%.1f, %.1f)\n" % [info.get("velocity", Vector2.ZERO).x, info.get("velocity", Vector2.ZERO).y]
	text += "\n[b]Current State:[/b] %s\n" % info.get("current_state", "unknown")
	
	# Inventory
	var inventory_items: Array = info.get("inventory_items", []) as Array
	text += "\n[b]Inventory:[/b] "
	if inventory_items.size() > 0:
		text += "\n"
		for item in inventory_items:
			var item_type = item.get("type")
			var item_count = item.get("count", 0)
			if item_type != null:
				var type_name: String = str(item_type)
				# Try to get resource name
				var resource_name: String = type_name
				if ResourceData:
					resource_name = ResourceData.get_resource_name(item_type)
				text += "  %s: %d\n" % [resource_name, item_count]
	else:
		text += "Empty\n"
	
	# Stats
	text += "\n[b]Stats:[/b]\n"
	var stats: Dictionary = info.get("stats", {}) as Dictionary
	for stat_name in stats:
		var stat_name_str: String = str(stat_name)
		var value: float = stats[stat_name] as float
		if stat_name_str.ends_with("_max"):
			continue  # Skip max values, show as percentage
		var max_key: String = stat_name_str + "_max"
		if stats.has(max_key):
			var max_val: float = stats[max_key] as float
			var percent: float = (value / max_val) * 100.0 if max_val > 0 else 0.0
			text += "  %s: %.1f/%.1f (%.0f%%)\n" % [stat_name_str, value, max_val, percent]
		else:
			text += "  %s: %.1f\n" % [stat_name_str, value]
	
	# Wants
	text += "\n[b]Wants:[/b]\n"
	var wants: Array = info.get("wants", []) as Array
	for want in wants:
		var want_dict: Dictionary = want as Dictionary
		var want_name: String = want_dict.get("name", "unknown") as String
		var meter: float = want_dict.get("meter", 0.0) as float
		var max_val: float = want_dict.get("max", 1.0) as float
		var percent: float = want_dict.get("percent", 0.0) as float
		text += "  %s: %.1f/%.1f (%.0f%%)\n" % [want_name, meter, max_val, percent]
	
	# Traits
	text += "\n[b]Traits:[/b]\n"
	var traits: Array = info.get("traits", []) as Array
	if traits.is_empty():
		text += "  None\n"
	else:
		for trait_item in traits:
			text += "  - %s\n" % str(trait_item)
	
	# Buffs/Debuffs
	text += "\n[b]Buffs/Debuffs:[/b]\n"
	var buffs: Array = info.get("buffs_debuffs", []) as Array
	if buffs.is_empty():
		text += "  None\n"
	else:
		for buff in buffs:
			var buff_dict: Dictionary = buff as Dictionary
			var buff_name: String = buff_dict.get("name", "unknown") as String
			var buff_stat: String = buff_dict.get("stat", "unknown") as String
			var buff_mult: float = buff_dict.get("mult", 1.0) as float
			var buff_duration: float = buff_dict.get("duration", 0.0) as float
			text += "  %s: %s x%.2f (%.1fs)\n" % [buff_name, buff_stat, buff_mult, buff_duration]
	
	# State data
	var state_data: Dictionary = info.get("state_data", {}) as Dictionary
	if not state_data.is_empty():
		text += "\n[b]State Data:[/b]\n"
		for key in state_data:
			text += "  %s: %s\n" % [str(key), str(state_data[key])]
	
	info_label.text = text

func _on_close_pressed() -> void:
	toggle()

func select_npc(npc: Node) -> void:
	selected_npc = npc
	if debug_visible:
		_update_info_display()

func _on_npc_list_item_selected(index: int) -> void:
	if not npc_list:
		return
	
	var npc: Node = npc_list.get_item_metadata(index) as Node
	if npc:
		select_npc(npc)

