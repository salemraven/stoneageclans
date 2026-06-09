extends SceneTree

const PLAYER_SCENE := preload("res://scenes/Player.tscn")
const NPC_SCENE := preload("res://scenes/NPC.tscn")


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	await process_frame
	var svc = get_root().get_node_or_null("/root/PlaceholderCardService")
	print("svc=", svc)
	var player: Node = PLAYER_SCENE.instantiate()
	get_root().add_child(player)
	await process_frame
	print("player in group player=", player.is_in_group("player"))
	print("uses cards=", svc.uses_placeholder_cards(player) if svc else false)
	if player.has_method("set_equipment"):
		player.set_equipment(ResourceData.ResourceType.SPEAR)
	var equipped = player.get("_equipped_item")
	print("equipped=", equipped, " SPEAR=", ResourceData.ResourceType.SPEAR)
	var sprite: Sprite2D = player.get_node_or_null("Sprite")
	var overlay: Sprite2D = sprite.get_node_or_null("WeaponOverlay") if sprite else null
	print("overlay visible=", overlay.visible if overlay else null)
	print("overlay tex=", overlay.texture.resource_path if overlay and overlay.texture else "null")
	print("overlay scale=", overlay.scale if overlay else null)
	print("sprite scale=", sprite.scale if sprite else null)
	svc.sync_weapon_overlay(player, ResourceData.ResourceType.SPEAR, true)
	await process_frame
	print("after direct sync visible=", overlay.visible if overlay else null)
	print("after direct sync tex=", overlay.texture.resource_path if overlay and overlay.texture else "null")
	var caveman: Node = NPC_SCENE.instantiate()
	caveman.set("npc_type", "caveman")
	get_root().add_child(caveman)
	await process_frame
	var wc = caveman.get_node_or_null("WeaponComponent")
	if wc:
		wc.equip_weapon(ResourceData.ResourceType.SPEAR)
	caveman.set("is_hostile", true)
	await process_frame
	var co: Sprite2D = caveman.get_node("Sprite/WeaponOverlay")
	print("npc overlay visible=", co.visible, " tex=", co.texture.resource_path if co.texture else "null")
	quit(0)
