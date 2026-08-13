extends Node3D

@export_node_path("Camera3D") var cam_path := NodePath("Camera")
@onready var cam: Camera3D = get_node(cam_path)

@export var mouse_sensitivity := 2.0
@export var y_limit := 90.0
@export var invert_y := false
@export var controller_sensitivity := 1.0
@export var controller_deadzone := 0.18
var mouse_axis := Vector2()
var rot := Vector3()

func _ready() -> void:
	mouse_sensitivity = mouse_sensitivity / 1000.0
	y_limit = deg_to_rad(y_limit)

func _input(event: InputEvent) -> void:
	if event is InputEventMouseMotion and Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
		mouse_axis = event.relative
		camera_rotation()

func _physics_process(delta: float) -> void:
	var joystick_axis := Input.get_vector(&"look_left", &"look_right", &"look_up", &"look_down", controller_deadzone)
	if joystick_axis != Vector2.ZERO:
		mouse_axis = joystick_axis * 1000.0 * delta * controller_sensitivity
		camera_rotation()

func camera_rotation() -> void:
	rot.y -= mouse_axis.x * mouse_sensitivity
	var vertical = mouse_axis.y * mouse_sensitivity
	rot.x = clamp(rot.x + (vertical if invert_y else -vertical), -y_limit, y_limit)
	get_owner().rotation.y = rot.y
	rotation.x = rot.x

func set_look_sensitivity(value: float) -> void:
	mouse_sensitivity = clamp(value,0.5,5.0) / 1000.0

func get_look_sensitivity() -> float:
	return mouse_sensitivity * 1000.0
