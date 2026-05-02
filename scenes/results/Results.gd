extends Control

@onready var scores_container: VBoxContainer = $VBox/ScoresContainer
@onready var currency_earned_label: Label = $VBox/CurrencyEarned
@onready var play_again_btn: Button = $VBox/BtnRow/PlayAgainBtn
@onready var menu_btn: Button = $VBox/BtnRow/MenuBtn

func _ready() -> void:
	_display_results()

func _display_results() -> void:
	var sorted := GameState.get_sorted_scores()
	var local_id := multiplayer.get_unique_id() if multiplayer.multiplayer_peer else 1
	var earned: int = 0
	for entry in sorted:
		var row := HBoxContainer.new()
		var name_lbl := Label.new()
		var score_lbl := Label.new()
		name_lbl.text = entry["name"] + (" (You)" if entry["peer_id"] == local_id else "")
		name_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		name_lbl.add_theme_font_size_override("font_size", 24)
		score_lbl.text = str(entry["score"]) + " pts"
		score_lbl.add_theme_font_size_override("font_size", 24)
		row.add_child(name_lbl)
		row.add_child(score_lbl)
		scores_container.add_child(row)
		if entry["peer_id"] == local_id:
			earned = entry["score"] / 10
	if earned > 0:
		SaveGame.add_currency(earned)
		currency_earned_label.text = "You earned: +%d coins!" % earned
	else:
		currency_earned_label.text = ""

func _on_play_again_btn_pressed() -> void:
	if multiplayer.is_server():
		NetworkManager.start_game.rpc()
	else:
		get_tree().change_scene_to_file("res://scenes/lobby/Lobby.tscn")

func _on_menu_btn_pressed() -> void:
	NetworkManager.disconnect_from_game()
	get_tree().change_scene_to_file("res://scenes/main_menu/MainMenu.tscn")
