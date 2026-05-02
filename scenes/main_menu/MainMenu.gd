extends Control

@onready var title_label: Label = $VBox/TitleLabel
@onready var name_edit: LineEdit = $VBox/NameEdit
@onready var car_select: OptionButton = $VBox/CarSelect
@onready var currency_label: Label = $VBox/CurrencyLabel
@onready var host_btn: Button = $VBox/ButtonRow/HostBtn
@onready var join_btn: Button = $VBox/ButtonRow/JoinBtn
@onready var shop_btn: Button = $VBox/ButtonRow/ShopBtn
@onready var ip_panel: PanelContainer = $VBox/IPPanel
@onready var ip_edit: LineEdit = $VBox/IPPanel/VBox/IPEdit
@onready var connect_btn: Button = $VBox/IPPanel/VBox/ConnectBtn
@onready var status_label: Label = $VBox/StatusLabel

var _joining: bool = false

func _ready() -> void:
	ip_panel.visible = false
	status_label.text = ""
	_refresh_car_list()
	currency_label.text = "Coins: " + str(SaveGame.currency)
	NetworkManager.connection_succeeded.connect(_on_connection_succeeded)
	NetworkManager.connection_failed.connect(_on_connection_failed)
	name_edit.text = "Player" + str(randi() % 1000)

func _refresh_car_list() -> void:
	car_select.clear()
	var car_names := {
		"car_starter": "Rusty Hatchback",
		"car_sport": "Street Racer",
		"car_super": "Drift King",
		"car_muscle": "V8 Beast"
	}
	for car_id in SaveGame.owned_cars:
		car_select.add_item(car_names.get(car_id, car_id))
		car_select.set_item_metadata(car_select.item_count - 1, car_id)
	# Select previously selected car
	for i in car_select.item_count:
		if car_select.get_item_metadata(i) == SaveGame.selected_car:
			car_select.select(i)
			break

func _get_selected_car_id() -> String:
	if car_select.item_count == 0:
		return "car_starter"
	return car_select.get_item_metadata(car_select.selected)

func _on_host_btn_pressed() -> void:
	_joining = false
	ip_panel.visible = false
	var player_name := name_edit.text.strip_edges()
	if player_name.is_empty():
		player_name = "Player"
	SaveGame.set_selected_car(_get_selected_car_id())
	NetworkManager.host_game(player_name, _get_selected_car_id())

func _on_join_btn_pressed() -> void:
	_joining = true
	ip_panel.visible = true
	ip_edit.placeholder_text = "Enter host IP..."
	connect_btn.text = "Connect"

func _on_connect_btn_pressed() -> void:
	var ip := ip_edit.text.strip_edges()
	if ip.is_empty():
		ip = "127.0.0.1"
	var player_name := name_edit.text.strip_edges()
	if player_name.is_empty():
		player_name = "Player"
	SaveGame.set_selected_car(_get_selected_car_id())
	status_label.text = "Connecting..."
	NetworkManager.join_game(ip, player_name, _get_selected_car_id())

func _on_shop_btn_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/shop/Shop.tscn")

func _on_connection_succeeded() -> void:
	status_label.text = "Connected!"
	get_tree().change_scene_to_file("res://scenes/lobby/Lobby.tscn")

func _on_connection_failed() -> void:
	status_label.text = "Connection failed!"

func _on_car_select_item_selected(index: int) -> void:
	SaveGame.set_selected_car(car_select.get_item_metadata(index))
