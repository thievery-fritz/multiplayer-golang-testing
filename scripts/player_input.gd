extends BaseNetInput
class_name PlayerInput

var movement: Vector2 = Vector2.ZERO
var _movement_buffer: Vector2 = Vector2.ZERO
var _movement_samples: int = 0

var is_rolling: bool = false
var _is_rolling_buffer: bool = false

var is_shooting: bool = false
var _is_shooting_buffer: bool = false

func _ready():
	super()
	NetworkTime.after_tick.connect(func(_dt, _t): _gather_always())

func _process(_dt: float) -> void:
	_movement_buffer += Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	_movement_samples += 1

	if Input.is_action_just_pressed("roll"):
		_is_rolling_buffer = true

	if Input.is_action_just_pressed("shoot"):
		_is_shooting_buffer = true

func _gather() -> void:
	if _movement_samples > 0:
		movement = _movement_buffer / _movement_samples
	else:
		movement = Vector2.ZERO
	_movement_buffer = Vector2.ZERO
	_movement_samples = 0

func _gather_always():
	is_rolling = _is_rolling_buffer
	_is_rolling_buffer = false
	is_shooting = _is_shooting_buffer
	_is_shooting_buffer = false
