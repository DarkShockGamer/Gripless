extends Node

signal connection_succeeded()
signal connection_failed()
signal player_connected(peer_id: int)
signal player_disconnected(peer_id: int)
signal game_start_signal()

const PORT := 7777
const MAX_CLIENTS := 4

var _player_name: String = "Player"
var _car_id: String = "car_starter"

func _ready() -> void:
	multiplayer.peer_connected.connect(_on_peer_connected)
	multiplayer.peer_disconnected.connect(_on_peer_disconnected)
	multiplayer.connected_to_server.connect(_on_connected_to_server)
	multiplayer.connection_failed.connect(_on_connection_failed)
	multiplayer.server_disconnected.connect(_on_server_disconnected)

func host_game(player_name: String, car_id: String) -> void:
	_player_name = player_name
	_car_id = car_id
	var peer := ENetMultiplayerPeer.new()
	var err := peer.create_server(PORT, MAX_CLIENTS)
	if err != OK:
		push_error("Failed to create server: " + str(err))
		connection_failed.emit()
		return
	multiplayer.multiplayer_peer = peer
	GameState.reset()
	GameState.local_peer_id = 1
	GameState.add_player(1, _player_name, _car_id)
	connection_succeeded.emit()

func join_game(ip: String, player_name: String, car_id: String) -> void:
	_player_name = player_name
	_car_id = car_id
	var peer := ENetMultiplayerPeer.new()
	var err := peer.create_client(ip, PORT)
	if err != OK:
		push_error("Failed to connect: " + str(err))
		connection_failed.emit()
		return
	multiplayer.multiplayer_peer = peer

func disconnect_from_game() -> void:
	if multiplayer.multiplayer_peer:
		multiplayer.multiplayer_peer.close()
		multiplayer.multiplayer_peer = null
	GameState.reset()

func _on_peer_connected(peer_id: int) -> void:
	player_connected.emit(peer_id)
	if multiplayer.is_server():
		# Send current player list to newly connected peer
		for pid in GameState.players:
			var p: Dictionary = GameState.players[pid]
			register_player.rpc_id(peer_id, pid, p["name"], p["car_id"])

func _on_peer_disconnected(peer_id: int) -> void:
	GameState.remove_player(peer_id)
	player_disconnected.emit(peer_id)
	# Broadcast to remaining peers (not the disconnected one)
	if multiplayer.is_server():
		notify_player_left.rpc(peer_id)

func _on_connected_to_server() -> void:
	GameState.reset()
	GameState.local_peer_id = multiplayer.get_unique_id()
	register_player.rpc_id(1, multiplayer.get_unique_id(), _player_name, _car_id)
	connection_succeeded.emit()

func _on_connection_failed() -> void:
	connection_failed.emit()

func _on_server_disconnected() -> void:
	disconnect_from_game()
	get_tree().change_scene_to_file("res://scenes/main_menu/MainMenu.tscn")

@rpc("any_peer", "call_local", "reliable")
func register_player(peer_id: int, player_name: String, car_id: String) -> void:
	if not GameState.players.has(peer_id):
		GameState.add_player(peer_id, player_name, car_id)

@rpc("any_peer", "call_local", "reliable")
func notify_player_left(peer_id: int) -> void:
	GameState.remove_player(peer_id)

@rpc("any_peer", "call_local", "reliable")
func set_ready_state(peer_id: int, ready: bool) -> void:
	GameState.set_player_ready(peer_id, ready)

@rpc("authority", "call_local", "reliable")
func set_track(track_id: String) -> void:
	GameState.selected_track = track_id

@rpc("authority", "call_local", "reliable")
func start_game() -> void:
	GameState.session_active = true
	game_start_signal.emit()
	get_tree().change_scene_to_file("res://scenes/game/Game.tscn")

@rpc("any_peer", "call_local", "reliable")
func update_player_score(peer_id: int, score: int) -> void:
	GameState.update_score(peer_id, score)
