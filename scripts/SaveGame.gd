extends Node

const SAVE_PATH := "user://savegame.json"

var currency: int = 500
var owned_cars: Array = ["car_starter"]
var selected_car: String = "car_starter"

func _ready() -> void:
	load_data()

func save() -> void:
	var data := {
		"currency": currency,
		"owned_cars": owned_cars,
		"selected_car": selected_car
	}
	var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(data))
		file.close()

func load_data() -> void:
	if not FileAccess.file_exists(SAVE_PATH):
		save()
		return
	var file := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if not file:
		return
	var text := file.get_as_text()
	file.close()
	var parsed = JSON.parse_string(text)
	if parsed == null:
		return
	currency = int(parsed.get("currency", 500))
	owned_cars = parsed.get("owned_cars", ["car_starter"])
	selected_car = parsed.get("selected_car", "car_starter")

func add_currency(amount: int) -> void:
	currency += amount
	save()

func spend_currency(amount: int) -> bool:
	if currency < amount:
		return false
	currency -= amount
	save()
	return true

func buy_car(car_id: String) -> bool:
	if has_car(car_id):
		return false
	var car_prices := {
		"car_starter": 0,
		"car_sport": 1000,
		"car_super": 3000,
		"car_muscle": 2000
	}
	var price: int = car_prices.get(car_id, 9999)
	if not spend_currency(price):
		return false
	owned_cars.append(car_id)
	save()
	return true

func has_car(car_id: String) -> bool:
	return car_id in owned_cars

func set_selected_car(car_id: String) -> void:
	if has_car(car_id):
		selected_car = car_id
		save()
