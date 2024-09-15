extends Node3D

@export var max_fov = 130
@export var min_fov = 75
@export var max_fov_speed = 100

@export var fov_smoothness: float = 10  # Smoothness for the FOV change
@export var max_shake_magnitude: float = 0.2

@export var mouse_sensitivity: float = 0.3

@onready var current_roll_speed: float = 0.0  # Variable to track the current roll speed
@onready var camera = $Camera
@onready var player = get_parent().get_node("Player")
@onready var speed = 0.0
@onready var in_game = true
@onready var mouse_delta = Vector2.ZERO
@onready var previous_position = global_transform.origin
@onready var previous_camera_position = camera.transform.origin
@onready var shake_offset = Vector3.ZERO

func _ready():
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

# Handle input events like mouse motion and toggling mouse lock
func _input(event):
	# Toggle between mouse captured and visible modes with ESC key
	if event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE:
		toggle_mouse_mode()
	
	if event is InputEventMouseMotion and in_game:
		mouse_delta = event.relative

# Toggle mouse mode between captured (for gameplay) and visible (for menus)
func toggle_mouse_mode():
	if Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
		in_game = false
	else:
		Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
		in_game = true
		
func _physics_process(delta):
	global_transform.origin = player.global_transform.origin
	apply_fov(delta)
	apply_rotation(delta)
	apply_camera_shake(delta)
		
func apply_fov(delta):
	var current_position = global_transform.origin
	speed = (current_position - previous_position).length() / delta
	previous_position = current_position 
	
	var target_fov = lerp(min_fov, max_fov, clamp(speed / max_fov_speed, 0, 1))
	camera.fov = lerp(camera.fov, target_fov, fov_smoothness * delta)

func apply_rotation(delta):
	var pitch_delta = deg_to_rad(-mouse_delta.y * mouse_sensitivity)
	var yaw_delta = deg_to_rad(-mouse_delta.x * mouse_sensitivity)

	rotate_object_local(Vector3.UP, yaw_delta)

	var x_axis = global_transform.basis.x.normalized()
	global_transform.basis = Basis(x_axis, pitch_delta) * global_transform.basis

	mouse_delta = Vector2.ZERO

func apply_camera_shake(delta):
	# Reset camera position to the previous position before adding shake
	camera.transform.origin = previous_camera_position

	var shake_strength = clamp(speed / max_fov_speed, 0, 1) * max_shake_magnitude

	var target_shake_offset = Vector3(
		randf_range(-shake_strength, shake_strength),
		randf_range(-shake_strength, shake_strength),
		0
	)

	shake_offset = shake_offset.lerp(target_shake_offset, fov_smoothness * delta)
	previous_camera_position = camera.transform.origin
	camera.transform.origin += shake_offset
