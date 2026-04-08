extends Node
## WebSocket multiplayer peer + handshake (guides/multiplayer.md Phase 2).
## Call start_server / connect_client from lobby UI when you wire menus.

signal peer_connected_to_game(peer_id: int)
signal peer_disconnected_from_game(peer_id: int)

var _peer: MultiplayerPeer = null

const DEFAULT_PORT: int = 9080


func _ready() -> void:
	multiplayer.peer_connected.connect(_on_peer_connected)
	multiplayer.peer_disconnected.connect(_on_peer_disconnected)


func _on_peer_connected(id: int) -> void:
	peer_connected_to_game.emit(id)


func _on_peer_disconnected(id: int) -> void:
	peer_disconnected_from_game.emit(id)


func get_network_peer() -> MultiplayerPeer:
	return _peer


func start_server(port: int = DEFAULT_PORT) -> Error:
	var ws := WebSocketMultiplayerPeer.new()
	var err: Error = ws.create_server(port)
	if err != OK:
		push_error("NetworkManager: create_server failed: %d" % err)
		return err
	multiplayer.multiplayer_peer = ws
	_peer = ws
	return OK


func connect_to_server(url: String) -> Error:
	var ws := WebSocketMultiplayerPeer.new()
	var err: Error = ws.create_client(url)
	if err != OK:
		push_error("NetworkManager: create_client failed: %d" % err)
		return err
	multiplayer.multiplayer_peer = ws
	_peer = ws
	return OK


func disconnect_network() -> void:
	if _peer:
		_peer.close()
	_peer = null
	multiplayer.multiplayer_peer = null
