extends Node

# EntityRegistry - id + generation, resolve at edge. Step 3.
# Logic uses entity_id; Nodes only at render edge. Prevents dangling refs and shadow fighting.

var _nodes: Dictionary = {}  # id -> Node (instance_id as id)
var _generation: Dictionary = {}  # id -> int (bump on unregister for reuse detection)

func register(node: Node) -> int:
	if not node:
		return -1
	var id: int = node.get_instance_id()
	_nodes[id] = node
	if not _generation.has(id):
		_generation[id] = 0
	return id

func unregister(node: Node) -> void:
	if not node:
		return
	var id: int = node.get_instance_id()
	_nodes.erase(id)
	_generation[id] = _generation.get(id, 0) + 1

func unregister_id(id: int) -> void:
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
