extends RigidBody2D

signal score_updated(score: int)

# Car stats - exported for per-car customization
@export var max_speed: float = 800.0
@export var acceleration: float = 400.0
@export var brake_force: float = 600.0
@export var steering_angle: float = 45.0
@export var drift_factor: float = 0.92
@export var grip_factor: float = 0.75
@export var mass_val: float = 1.2

# Car definitions (stats per id)
const CAR_DATA := {
	"car_starter": {"max_speed": 600.0, "acceleration": 320.0, "brake_force": 500.0,
	                "steering_angle": 42.0, "drift_factor": 0.93, "grip_factor": 0.78, "color": Color(0.6, 0.3, 0.2)},
	"car_sport":   {"max_speed": 780.0, "acceleration": 440.0, "brake_force": 620.0,
	                "steering_angle": 48.0, "drift_factor": 0.90, "grip_factor": 0.72, "color": Color(0.2, 0.4, 0.9)},
	"car_super":   {"max_speed": 850.0, "acceleration": 500.0, "brake_force": 700.0,
	                "steering_angle": 50.0, "drift_factor": 0.88, "grip_factor": 0.65, "color": Color(0.9, 0.1, 0.9)},
	"car_muscle":  {"max_speed": 950.0, "acceleration": 560.0, "brake_force": 580.0,
	                "steering_angle": 36.0, "drift_factor": 0.91, "grip_factor": 0.70, "color": Color(0.9, 0.5, 0.1)}
}

# Network properties (replicated)
var is_local: bool = false
var peer_id: int = 0
var net_position: Vector2 = Vector2.ZERO
var net_rotation: float = 0.0
var net_velocity: Vector2 = Vector2.ZERO

# State
var is_drifting: bool = false
var drift_score: int = 0
var drift_score_buffer: float = 0.0
var drift_combo: int = 1
var slip_angle: float = 0.0
var speed_kmh: float = 0.0
var _handbrake: bool = false
var _throttle: float = 0.0
var _steer: float = 0.0
var _last_skid_pos: Vector2 = Vector2.ZERO

# Physics tuning constants
const PHYSICS_FRAME_RATE := 60.0
const DRIFT_SCORE_MULTIPLIER := 10.0
const SPEED_NORMALIZATION_FACTOR := 100.0

# Interpolation
const INTERP_SPEED := 15.0

@onready var body_poly: Polygon2D = $BodyPoly
@onready var smoke: CPUParticles2D = $SmokeParticles
@onready var skid_marks: Node2D = $SkidMarks
@onready var camera: Camera2D = $Camera2D
@onready var sync_node: MultiplayerSynchronizer = $MultiplayerSynchronizer

func _ready() -> void:
	mass = mass_val
	if is_local:
		camera.enabled = true
		set_physics_process(true)
	else:
		camera.enabled = false
		set_physics_process(false)
	# Car data applied via setup(); default stats remain until setup() is called

func setup(p_id: int, car_id: String, local: bool) -> void:
	peer_id = p_id
	is_local = local
	_apply_car_data(car_id)
	if local:
		camera.enabled = true
	# Configure MultiplayerSynchronizer authority
	if sync_node:
		sync_node.set_multiplayer_authority(p_id)

func _apply_car_data(car_id: String) -> void:
	var data: Dictionary = CAR_DATA.get(car_id, CAR_DATA["car_starter"])
	max_speed = data["max_speed"]
	acceleration = data["acceleration"]
	brake_force = data["brake_force"]
	steering_angle = data["steering_angle"]
	drift_factor = data["drift_factor"]
	grip_factor = data["grip_factor"]
	if body_poly:
		body_poly.color = data["color"]

func _physics_process(delta: float) -> void:
	if not is_local:
		# Interpolate remote car
		global_position = global_position.lerp(net_position, INTERP_SPEED * delta)
		global_rotation = lerp_angle(global_rotation, net_rotation, INTERP_SPEED * delta)
		linear_velocity = net_velocity
		return
	_read_input()
	_apply_drift_physics(delta)
	_update_skid_marks()
	_update_smoke()
	_update_score(delta)
	_broadcast_state()

func _read_input() -> void:
	_throttle = Input.get_axis("ui_down", "ui_up")
	_steer = Input.get_axis("ui_left", "ui_right")
	_handbrake = Input.is_action_pressed("handbrake")

func _apply_drift_physics(delta: float) -> void:
	# Forward/lateral velocity in local space
	var local_vel := transform.basis_xform_inv(linear_velocity)
	var forward_vel: float = -local_vel.y  # Godot 2D: -Y is forward for top-down
	var lateral_vel: float = local_vel.x

	speed_kmh = abs(forward_vel) * 0.036

	# Steering (speed-sensitive)
	var speed_ratio := clamp(abs(forward_vel) / max_speed, 0.0, 1.0)
	var steer_amount := _steer * steering_angle * speed_ratio
	rotation_degrees += steer_amount * delta * PHYSICS_FRAME_RATE * sign(forward_vel + 0.01)

	# Throttle / braking force
	var drive_dir := -transform.basis_xform(Vector2(0, 1))
	if _throttle > 0.01:
		apply_central_force(drive_dir * acceleration * _throttle * PHYSICS_FRAME_RATE)
	elif _throttle < -0.01:
		apply_central_force(-drive_dir * brake_force * abs(_throttle) * PHYSICS_FRAME_RATE)

	# Grip vs drift lateral correction
	var current_grip := drift_factor if _handbrake else grip_factor
	# Apply lateral correction force
	var lateral_correction := -transform.basis_xform(Vector2(1, 0)) * lateral_vel * current_grip * PHYSICS_FRAME_RATE
	apply_central_force(lateral_correction)

	# Slip angle detection
	if abs(forward_vel) > 20.0:
		slip_angle = rad_to_deg(atan2(lateral_vel, abs(forward_vel)))
	else:
		slip_angle = 0.0

	is_drifting = abs(slip_angle) > 15.0 or (_handbrake and abs(forward_vel) > 80.0)

	# Speed limit
	if linear_velocity.length() > max_speed:
		linear_velocity = linear_velocity.normalized() * max_speed

func _update_skid_marks() -> void:
	if not is_drifting:
		_last_skid_pos = Vector2.ZERO
		return
	if _last_skid_pos != Vector2.ZERO and global_position.distance_to(_last_skid_pos) > 8.0:
		var line := Line2D.new()
		line.default_color = Color(0.1, 0.1, 0.1, 0.6)
		line.width = 4.0
		line.add_point(_last_skid_pos)
		line.add_point(global_position)
		skid_marks.add_child(line)
		# Limit skid marks
		if skid_marks.get_child_count() > 60:
			skid_marks.get_child(0).queue_free()
	_last_skid_pos = global_position

func _update_smoke() -> void:
	if smoke:
		smoke.emitting = is_drifting

func _update_score(delta: float) -> void:
	if is_drifting:
		drift_score_buffer += abs(slip_angle) * (speed_kmh / SPEED_NORMALIZATION_FACTOR) * delta * DRIFT_SCORE_MULTIPLIER
		if drift_score_buffer >= 10.0:
			drift_score += int(drift_score_buffer) * drift_combo
			drift_score_buffer = 0.0
			score_updated.emit(drift_score)
			NetworkManager.update_player_score.rpc(peer_id, drift_score)
	else:
		drift_score_buffer = 0.0

func _broadcast_state() -> void:
	if not is_local:
		return
	sync_remote_state.rpc(global_position, global_rotation, linear_velocity, is_drifting)

@rpc("any_peer", "call_remote", "unreliable")
func sync_remote_state(pos: Vector2, rot: float, vel: Vector2, drifting: bool) -> void:
	net_position = pos
	net_rotation = rot
	net_velocity = vel
	is_drifting = drifting

func apply_tandem_bonus() -> void:
	drift_combo = min(drift_combo + 1, 5)
	drift_score += 500 * drift_combo
	score_updated.emit(drift_score)
	NetworkManager.update_player_score.rpc(peer_id, drift_score)

func reset_to_spawn(spawn_pos: Vector2, spawn_rot: float) -> void:
	global_position = spawn_pos
	global_rotation = spawn_rot
	linear_velocity = Vector2.ZERO
	angular_velocity = 0.0
