extends Control

@onready var currency_label: Label = $VBox/CurrencyLabel
@onready var cars_container: VBoxContainer = $VBox/ScrollContainer/CarsContainer
@onready var back_btn: Button = $VBox/BackBtn

const CAR_DATA := [
	{
		"id": "car_starter",
		"name": "Rusty Hatchback",
		"cost": 0,
		"description": "Your trusty starter car. Nothing special.",
		"stats": "Speed: ★★☆☆☆  Drift: ★★★☆☆  Handling: ★★★☆☆"
	},
	{
		"id": "car_sport",
		"name": "Street Racer",
		"cost": 1000,
		"description": "A sporty ride with better speed and handling.",
		"stats": "Speed: ★★★★☆  Drift: ★★★☆☆  Handling: ★★★★☆"
	},
	{
		"id": "car_super",
		"name": "Drift King",
		"cost": 3000,
		"description": "Built for drifting. Maximum slip, maximum style.",
		"stats": "Speed: ★★★★☆  Drift: ★★★★★  Handling: ★★★☆☆"
	},
	{
		"id": "car_muscle",
		"name": "V8 Beast",
		"cost": 2000,
		"description": "Raw power. It wants to go straight, but you won't let it.",
		"stats": "Speed: ★★★★★  Drift: ★★★☆☆  Handling: ★★☆☆☆"
	}
]

func _ready() -> void:
	currency_label.text = "Coins: %d" % SaveGame.currency
	_populate_shop()

func _populate_shop() -> void:
	for child in cars_container.get_children():
		child.queue_free()
	for car in CAR_DATA:
		var card := _make_car_card(car)
		cars_container.add_child(card)

func _make_car_card(car: Dictionary) -> Control:
	var panel := PanelContainer.new()
	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 6)
	panel.add_child(vbox)

	var name_lbl := Label.new()
	name_lbl.text = car["name"]
	name_lbl.add_theme_font_size_override("font_size", 22)
	name_lbl.modulate = Color(0.914, 0.271, 0.376)
	vbox.add_child(name_lbl)

	var desc_lbl := Label.new()
	desc_lbl.text = car["description"]
	desc_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	vbox.add_child(desc_lbl)

	var stats_lbl := Label.new()
	stats_lbl.text = car["stats"]
	stats_lbl.modulate = Color(0.9, 0.9, 0.7)
	vbox.add_child(stats_lbl)

	var hbox := HBoxContainer.new()
	vbox.add_child(hbox)

	var price_lbl := Label.new()
	if car["cost"] == 0:
		price_lbl.text = "FREE"
	else:
		price_lbl.text = "%d coins" % car["cost"]
	price_lbl.modulate = Color(1, 0.843, 0)
	price_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hbox.add_child(price_lbl)

	var buy_btn := Button.new()
	if SaveGame.has_car(car["id"]):
		buy_btn.text = "OWNED"
		buy_btn.disabled = true
	elif SaveGame.currency < car["cost"]:
		buy_btn.text = "BUY (%d)" % car["cost"]
		buy_btn.disabled = true
	else:
		buy_btn.text = "BUY (%d)" % car["cost"]
		buy_btn.disabled = false

	buy_btn.pressed.connect(_on_buy_pressed.bind(car["id"], buy_btn))
	hbox.add_child(buy_btn)

	return panel

func _on_buy_pressed(car_id: String, btn: Button) -> void:
	if SaveGame.buy_car(car_id):
		btn.text = "OWNED"
		btn.disabled = true
		currency_label.text = "Coins: %d" % SaveGame.currency

func _on_back_btn_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/main_menu/MainMenu.tscn")
