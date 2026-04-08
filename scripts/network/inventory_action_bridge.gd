extends Node
## Phase 6: UI proposes inventory/build mutations; server validates and applies. Single-player: applies immediately.
signal inventory_mutate_validated(op: Dictionary)

const OP_MOVE: String = "move"
const OP_CRAFT: String = "craft"
const OP_PLACE: String = "place"


func propose_inventory_mutate(op: Dictionary) -> void:
	if op.is_empty():
		return
	if not multiplayer.has_multiplayer_peer() or multiplayer.is_server():
		inventory_mutate_validated.emit(op)
		return
	submit_inventory_mutate_to_server.rpc_id(1, op)


@rpc("any_peer", "call_remote", "reliable")
func submit_inventory_mutate_to_server(op: Dictionary) -> void:
	if not multiplayer.is_server():
		return
	# TODO: validate op (clan, distance, slot rules) before emit
	inventory_mutate_validated.emit(op)
