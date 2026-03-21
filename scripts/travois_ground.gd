extends Area2D
class_name TravoisGround

# Placed travois on ground - has inventory, can be picked up when empty
# carried_by: reservation so only one NPC can pick it up at a time

var inventory: InventoryData = null
var sprite: Sprite2D = null
var carried_by: Node = null  # NPCBase that has reserved or is carrying this travois

func _ready() -> void:
	input_pickable = true
	sprite = get_node_or_null("Sprite") as Sprite2D
	if not inventory:
		inventory = InventoryData.new(8, true, 999)
	var tex = AssetRegistry.get_travois_sprite()
	if sprite and tex:
		sprite.texture = tex
	add_to_group("travois_ground")
	add_to_group("buildings")
	var shape_node = get_node_or_null("CollisionShape2D") as CollisionShape2D
	if shape_node:
		var circle := CircleShape2D.new()
		circle.radius = 24.0
		shape_node.shape = circle
	body_entered.connect(_on_body_entered)
	input_event.connect(_on_input_event)

func _on_body_entered(_body: Node2D) -> void:
	pass

func _on_input_event(_viewport: Node, event: InputEvent, _shape_idx: int) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		var main = get_tree().get_first_node_in_group("main")
		if main and main.has_method("_on_travois_ground_clicked"):
			main._on_travois_ground_clicked(self)

func is_empty() -> bool:
	if not inventory:
		return true
	for i in inventory.slot_count:
		if not inventory.get_slot(i).is_empty():
			return false
	return true
