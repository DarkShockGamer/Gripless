extends Node

signal player_joined(peer_id: int)
signal player_left(peer_id: int)
signal player_ready_changed(peer_id: int, ready: bool)
signal game_started()

var players: Dictionary = {}
var selected_track: String = "track1"
var session_active: bool = false
var local_peer_id: int = 1

func reset() -> void:
	players.clear()
	selected_track = "track1"
	session_active = false

func add_player(peer_id: int, player_name: String, car_id: String) -> void:
	players[peer_id] = {
		"name": player_name,
		"ready": false,
		"score": 0,
		"car_id": car_id
	}
	player_joined.emit(peer_id)

func remove_player(peer_id: int) -> void:
	if players.has(peer_id):
		players.erase(peer_id)
		player_left.emit(peer_id)

func set_player_ready(peer_id: int, ready: bool) -> void:
	if players.has(peer_id):
		players[peer_id]["ready"] = ready
		player_ready_changed.emit(peer_id, ready)

func update_score(peer_id: int, score: int) -> void:
	if players.has(peer_id):
		players[peer_id]["score"] = score

func all_players_ready() -> bool:
	if players.is_empty():
		return false
	for pid in players:
		if not players[pid]["ready"]:
			return false
	return true

func get_sorted_scores() -> Array:
	var arr := []
	for pid in players:
		arr.append({"peer_id": pid, "name": players[pid]["name"], "score": players[pid]["score"]})
	arr.sort_custom(func(a, b): return a["score"] > b["score"])
	return arr
