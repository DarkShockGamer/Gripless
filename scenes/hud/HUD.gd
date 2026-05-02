extends CanvasLayer

@onready var drift_score_label: Label = $HUDRoot/BottomCenter/DriftScore
@onready var combo_label: Label = $HUDRoot/BottomCenter/ComboLabel
@onready var speed_label: Label = $HUDRoot/TopRight/SpeedLabel
@onready var tandem_label: Label = $HUDRoot/TandemLabel
@onready var drift_bar: ProgressBar = $HUDRoot/BottomCenter/DriftBar
@onready var timer_label: Label = $HUDRoot/TopCenter/TimerLabel

const MAX_SLIP_ANGLE_DEGREES := 60.0

var _car: RigidBody2D = null

func set_car(car: RigidBody2D) -> void:
	_car = car
	if car.has_signal("score_updated"):
		car.score_updated.connect(_on_score_updated)

func _process(_delta: float) -> void:
	if _car == null:
		return
	speed_label.text = "%.0f km/h" % _car.speed_kmh
	drift_bar.value = clamp(abs(_car.slip_angle) / MAX_SLIP_ANGLE_DEGREES * 100.0, 0.0, 100.0)
	tandem_label.visible = false  # toggled externally

func _on_score_updated(score: int) -> void:
	drift_score_label.text = "DRIFT: %d" % score

func show_tandem() -> void:
	tandem_label.visible = true
	tandem_label.text = "TANDEM!"
	await get_tree().create_timer(1.5).timeout
	tandem_label.visible = false

func update_combo(combo: int) -> void:
	if combo > 1:
		combo_label.text = "x%d COMBO" % combo
		combo_label.visible = true
	else:
		combo_label.visible = false

func update_timer(seconds: float) -> void:
	var m := int(seconds / 60.0)
	var s := int(fmod(seconds, 60.0))
	timer_label.text = "%d:%02d" % [m, s]
