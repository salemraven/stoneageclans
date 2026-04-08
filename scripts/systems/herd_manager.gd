extends Node

## Server-authoritative registry: herder_instance_id -> Array of follower Node2D.
## Autoload name: HerdManager (do not use class_name — conflicts with autoload).
## Soft cap (8) and hard cap (10) apply when adding herd animals (woman/sheep/goat).

const SOFT_HERD_CAP: int = 8
const HARD_HERD_CAP: int = 10

var _followers_by_herder: Dictionary = {}  # int -> Array[Node2D]


func _sim_authority() -> bool:
	return not multiplayer.has_multiplayer_peer() or multiplayer.is_server()

func _ready() -> void:
	if not Engine.is_editor_hint():
		set_process(false)


func _herder_key(herder: Node) -> int:
	return herder.get_instance_id() if herder and is_instance_valid(herder) else -1


func _get_list(herder: Node) -> Array[Node2D]:
	var k := _herder_key(herder)
	if k < 0:
		return []
	if not _followers_by_herder.has(k):
		_followers_by_herder[k] = [] as Array[Node2D]
	return _followers_by_herder[k]


func get_herd(herder: Node) -> Array[Node2D]:
	var out: Array[Node2D] = []
	var lst = _get_list(herder)
	for n in lst:
		if is_instance_valid(n):
			out.append(n)
	return out


func get_herd_size(herder: Node) -> int:
	var lst = _get_list(herder)
	var c: int = 0
	for n in lst:
		if is_instance_valid(n):
			c += 1
	return c


func _is_herd_animal(node: Node) -> bool:
	if not node:
		return false
	var t: String = str(node.get("npc_type")) if node.get("npc_type") != null else ""
	return t in ["woman", "sheep", "goat"]


func get_herd_animal_count(herder: Node) -> int:
	var c: int = 0
	for n in get_herd(herder):
		if _is_herd_animal(n):
			c += 1
	return c


func has_party_ordered_followers(leader: Node) -> bool:
	"""True if any registered follower is a caveman/clansman in ordered follow (party)."""
	for n in get_herd(leader):
		if not is_instance_valid(n):
			continue
		var t: String = str(n.get("npc_type")) if n.get("npc_type") != null else ""
		if t != "caveman" and t != "clansman":
			continue
		if n.get("follow_is_ordered") == true:
			return true
	return false


func can_add_herd_animal(herder: Node, animal: Node) -> bool:
	if not herder or not is_instance_valid(herder):
		return false
	var lst = _get_list(herder)
	var count: int = 0
	var already: bool = false
	for n in lst:
		if not is_instance_valid(n):
			continue
		if _is_herd_animal(n):
			count += 1
		if n == animal:
			already = true
	if already:
		return true
	return count < HARD_HERD_CAP


func register_follower(herder: Node2D, follower: Node2D) -> void:
	# Kept on all peers until herd state is fully replicated on NPCs (UI + herded_count).
	if not herder or not is_instance_valid(herder) or not follower or not is_instance_valid(follower):
		return
	var lst: Array[Node2D] = _get_list(herder)
	if follower in lst:
		return
	lst.append(follower)


func unregister_follower(herder: Node2D, follower: Node2D) -> void:
	if not herder:
		return
	var k := _herder_key(herder)
	if k < 0 or not _followers_by_herder.has(k):
		return
	var lst: Array[Node2D] = _followers_by_herder[k]
	var i: int = lst.find(follower)
	if i >= 0:
		lst.remove_at(i)
	if lst.is_empty():
		_followers_by_herder.erase(k)


## Try to transfer herd animal to new herder. Enforces caps; runs npc._try_herd_chance body via NPCBase.
func try_transfer(animal: Node2D, new_herder: Node2D) -> bool:
	if not _sim_authority():
		return false
	if not animal or not is_instance_valid(animal) or not new_herder or not is_instance_valid(new_herder):
		return false
	if not _is_herd_animal(animal):
		return false
	var cur: Node2D = animal.get("herder") as Node2D if animal.get("herder") != null else null
	if cur == new_herder and animal.get("is_herded") == true:
		return true
	if not can_add_herd_animal(new_herder, animal):
		return false
	if animal.has_method("_try_herd_chance"):
		return animal._try_herd_chance(new_herder, true)
	return false


func cleanup_herder(herder: Node2D) -> void:
	if not _sim_authority():
		return
	if not herder:
		return
	var k := _herder_key(herder)
	if not _followers_by_herder.has(k):
		return
	var lst: Array[Node2D] = (_followers_by_herder[k] as Array).duplicate()
	for f in lst:
		if not is_instance_valid(f):
			continue
		if f.has_method("_clear_herd"):
			f._clear_herd()
	_followers_by_herder.erase(k)
