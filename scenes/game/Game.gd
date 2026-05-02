extends Node2D

const CAR_SCENE := preload("res://scenes/car/Car.tscn")
const HUD_SCENE := preload("res://scenes/hud/HUD.tscn")
const TRACK_SCENES := {
	"track1": "res://scenes/tracks/Track1.tscn",
	"track2": "res://scenes/tracks/Track2.tscn",
	"track3": "res://scenes/tracks/Track3.tscn"
}

const ROUND_TIME := 180.0
const TANDEM_DISTANCE := 200.0

var _cars: Dictionary = {}  # peer_id -> Car
var _spawn_points: Array = []
var _time_remaining: float = ROUND_TIME
var _hud: CanvasLayer = null
var _local_car = null
var _fog_layer: CanvasLayer = null
var _fog_rect: ColorRect = null

func _ready() -> void:
	_load_track()
	await get_tree().process_frame
	_spawn_cars()
	_setup_hud()
	_setup_fog()

func _load_track() -> void:
	var track_id := GameState.selected_track
	var track_path: String = TRACK_SCENES.get(track_id, TRACK_SCENES["track1"])
	var track_scene := load(track_path)
	if track_scene:
		var track := track_scene.instantiate()
		add_child(track)
		# Collect spawn points
		for child in track.get_children():
			if child is Marker2D:
				_spawn_points.append(child)
		# Connect out-of-bounds with a short delay to avoid triggering on spawn
		var oob := track.find_child("OutOfBounds", true, false)
		if oob and oob is Area2D:
			get_tree().create_timer(2.0).timeout.connect(func():
				oob.body_entered.connect(_on_out_of_bounds)
			)

func _spawn_cars() -> void:
	var cars_node := Node2D.new()
	cars_node.name = "Cars"
	add_child(cars_node)
	var idx := 0
	for pid in GameState.players:
		var car := CAR_SCENE.instantiate()
		car.name = str(pid)
		var local := (pid == multiplayer.get_unique_id())
		cars_node.add_child(car)
		car.setup(pid, GameState.players[pid]["car_id"], local)
		# Spawn position
		if idx < _spawn_points.size():
			car.global_position = _spawn_points[idx].global_position
			car.global_rotation = _spawn_points[idx].global_rotation
		else:
			car.global_position = Vector2(200 + idx * 80, 300)
		_cars[pid] = car
		if local:
			_local_car = car
		idx += 1

func _setup_hud() -> void:
	_hud = HUD_SCENE.instantiate()
	add_child(_hud)
	if _local_car:
		_hud.set_car(_local_car)

func _setup_fog() -> void:
	_fog_layer = CanvasLayer.new()
	_fog_layer.layer = 10
	add_child(_fog_layer)
	_fog_rect = ColorRect.new()
	_fog_rect.color = Color(0, 0, 0, 0.88)
	_fog_rect.size = Vector2(1280, 720)
	_fog_layer.add_child(_fog_rect)
	# Apply fog-of-war shader
	var shader := load("res://shaders/fog_of_war.gdshader")
	if shader:
		var mat := ShaderMaterial.new()
		mat.shader = shader
		_fog_rect.material = mat

func _process(delta: float) -> void:
	_time_remaining -= delta
	if _hud:
		_hud.update_timer(max(_time_remaining, 0.0))
	if _time_remaining <= 0.0:
		_end_game()
		set_process(false)
		return
	_update_fog()
	_check_tandem()

func _update_fog() -> void:
	if _local_car == null or _fog_rect == null:
		return
	var mat := _fog_rect.material as ShaderMaterial
	if mat == null:
		return
	# Car is always at screen center when camera follows it
	mat.set_shader_parameter("car_pos", Vector2(0.5, 0.5))
	mat.set_shader_parameter("radius", 0.3)

func _check_tandem() -> void:
	var drifters := []
	for pid in _cars:
		var c := _cars[pid]
		if c.is_drifting:
			drifters.append(c)
	if drifters.size() < 2:
		return
	for i in drifters.size():
		for j in range(i + 1, drifters.size()):
			var dist := drifters[i].global_position.distance_to(drifters[j].global_position)
			if dist < TANDEM_DISTANCE:
				if multiplayer.is_server():
					drifters[i].apply_tandem_bonus()
					drifters[j].apply_tandem_bonus()
				if _hud:
					_hud.show_tandem()

func _on_out_of_bounds(body: Node2D) -> void:
	if body is RigidBody2D and body.has_method("reset_to_spawn"):
		var spawn_pos := Vector2(200, 300)
		var spawn_rot := 0.0
		if _spawn_points.size() > 0:
			spawn_pos = _spawn_points[0].global_position
			spawn_rot = _spawn_points[0].global_rotation
		body.reset_to_spawn(spawn_pos, spawn_rot)

func _end_game() -> void:
	GameState.session_active = false
	get_tree().change_scene_to_file("res://scenes/results/Results.tscn")
