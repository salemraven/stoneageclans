extends Node

# EntityRegistry - id + generation, resolve at edge. Step 3.
# Logic uses entity_id; Nodes only at render edge. Prevents dangling refs and shadow fighting.
# network_entity_id: stable server-assigned id for multiplayer RPCs (guides/multiplayer.md Phase 3).

const META_NETWORK_ENTITY_ID: StringName = &"network_entity_id"

var _nodes: Dictionary = {}  # id -> Node (instance_id as id)
var _generation: Dictionary = {}  # id -> int (bump on unregister for reuse detection)
var _by_network_id: Dictionary = {}  # int network_id -> Node
var _next_network_id: int = 1


func register(node: Node) -> int:
	if not node:
		return -1
	var id: int = node.get_instance_id()
	_nodes[id] = node
	if not _generation.has(id):
		_generation[id] = 0
	_ensure_network_id(node)
	return id


func register_with_network_id(node: Node, network_id: int) -> int:
	"""Client-side: apply server-issued id before or after add_child."""
	if not node or network_id < 1:
		return register(node)
	node.set_meta(META_NETWORK_ENTITY_ID, network_id)
	var old: Node = _by_network_id.get(network_id) as Node
	if old != null and is_instance_valid(old) and old != node:
		push_warning("EntityRegistry: network_id %d already bound; reassigning" % network_id)
	_by_network_id[network_id] = node
	_next_network_id = maxi(_next_network_id, network_id + 1)
	return register(node)


func _ensure_network_id(node: Node) -> void:
	if node.has_meta(META_NETWORK_ENTITY_ID):
		var nid: int = int(node.get_meta(META_NETWORK_ENTITY_ID))
		if nid > 0:
			_by_network_id[nid] = node
			_next_network_id = maxi(_next_network_id, nid + 1)
		return
	var nid2: int = _next_network_id
	_next_network_id += 1
	node.set_meta(META_NETWORK_ENTITY_ID, nid2)
	_by_network_id[nid2] = node


func get_network_id(node: Node) -> int:
	if not node or not node.has_meta(META_NETWORK_ENTITY_ID):
		return -1
	return int(node.get_meta(META_NETWORK_ENTITY_ID))


func get_node_by_network_id(network_id: int) -> Node:
	if network_id < 1:
		return null
	var n: Node = _by_network_id.get(network_id) as Node
	if n != null and is_instance_valid(n):
		return n
	_by_network_id.erase(network_id)
	return null


func unregister(node: Node) -> void:
	if not node:
		return
	var nid: int = get_network_id(node)
	if nid > 0:
		if _by_network_id.get(nid) == node:
			_by_network_id.erase(nid)
	var id: int = node.get_instance_id()
	_nodes.erase(id)
	_generation[id] = _generation.get(id, 0) + 1

func unregister_id(id: int) -> void:
	var n: Node = _nodes.get(id) as Node
	if n:
		var nid: int = get_network_id(n)
		if nid > 0 and _by_network_id.get(nid) == n:
			_by_network_id.erase(nid)
	_nodes.erase(id)
	_generation[id] = _generation.get(id, 0) + 1

func get_entity_node(id: int) -> Node:
	if id < 0:
		return null
	if not _nodes.has(id):
		return null
	var n = _nodes[id]
	if not is_instance_valid(n):
		_nodes.erase(id)
		return null
	return n

func get_id(node: Node) -> int:
	if not node or not is_instance_valid(node):
		return -1
	# If already registered, return stored id (instance_id)
	if _nodes.has(node.get_instance_id()):
		return node.get_instance_id()
	# Not registered - caller can register first or we return instance_id for lookup
	return node.get_instance_id()

func get_generation(id: int) -> int:
	return _generation.get(id, 0)

func is_registered(id: int) -> bool:
	return _nodes.has(id) and is_instance_valid(_nodes.get(id))
