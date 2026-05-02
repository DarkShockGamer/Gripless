extends Control

@onready var player_list: VBoxContainer = $VBox/PlayerList
@onready var track_select: OptionButton = $VBox/HBox/TrackSelect
@onready var ready_btn: Button = $VBox/BtnRow/ReadyBtn
@onready var start_btn: Button = $VBox/BtnRow/StartBtn
@onready var back_btn: Button = $VBox/BtnRow/BackBtn
@onready var status_label: Label = $VBox/StatusLabel

const TRACKS := ["track1", "track2", "track3"]
const TRACK_NAMES := ["Industrial Drift", "Harbor Circuit", "Mountain Pass"]

var _is_ready: bool = false

func _ready() -> void:
	start_btn.visible = multiplayer.is_server()
	start_btn.disabled = true

	# Populate track dropdown
	track_select.clear()
	for t in TRACK_NAMES:
		track_select.add_item(t)
	track_select.disabled = not multiplayer.is_server()

	# Connect signals
	GameState.player_joined.connect(_refresh_player_list)
	GameState.player_left.connect(_refresh_player_list)
	GameState.player_ready_changed.connect(_on_ready_changed)
	NetworkManager.game_start_signal.connect(_on_game_start)

	_refresh_player_list(0)

func _refresh_player_list(_id) -> void:
	for child in player_list.get_children():
		child.queue_free()
	for pid in GameState.players:
		var p: Dictionary = GameState.players[pid]
		var row := HBoxContainer.new()
		var name_lbl := Label.new()
		name_lbl.text = p["name"] + (" (You)" if pid == GameState.local_peer_id else "")
		name_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var ready_lbl := Label.new()
		ready_lbl.text = "✓ Ready" if p["ready"] else "○ Not Ready"
		ready_lbl.modulate = Color(0.2, 1, 0.2) if p["ready"] else Color(1, 0.5, 0.2)
		row.add_child(name_lbl)
		row.add_child(ready_lbl)
		player_list.add_child(row)
	_update_start_btn()

func _on_ready_changed(_id, _r) -> void:
	_refresh_player_list(0)

func _update_start_btn() -> void:
	if multiplayer.is_server():
		start_btn.disabled = not GameState.all_players_ready()

func _on_ready_btn_pressed() -> void:
	_is_ready = not _is_ready
	ready_btn.text = "UNREADY" if _is_ready else "READY"
	NetworkManager.set_ready_state.rpc(GameState.local_peer_id, _is_ready)

func _on_start_btn_pressed() -> void:
	if not multiplayer.is_server():
		return
	var track_idx := track_select.selected
	NetworkManager.set_track.rpc(TRACKS[track_idx])
	NetworkManager.start_game.rpc()

func _on_back_btn_pressed() -> void:
	NetworkManager.disconnect_from_game()
	get_tree().change_scene_to_file("res://scenes/main_menu/MainMenu.tscn")

func _on_game_start() -> void:
	pass  # Scene change handled by NetworkManager.start_game rpc

func _on_track_select_item_selected(index: int) -> void:
	if multiplayer.is_server():
		NetworkManager.set_track.rpc(TRACKS[index])
