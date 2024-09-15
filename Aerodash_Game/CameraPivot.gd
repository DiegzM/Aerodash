extends Node3D

@export var max_fov = 130
@export var min_fov = 75
@export var max_fov_speed = 100

@export var fov_smoothness: float = 10  # Smoothness for the FOV change

@export var mouse_sensitivity: float = 0.3
@export var roll_speed: float = 3.0
@export var roll_smoothness: float = 5

@onready var current_roll_speed: float = 0.0  # Variable to track the current roll speed
@onready var camera = $Camera
@onready var player = get_parent().get_node("Player")
@onready var speed = 0.0
@onready var in_game = true
@onready var mouse_delta = Vector2.ZERO
@onready var previous_position = global_transform.origin

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
		
func apply_fov(delta):
	var current_position = global_transform.origin
	speed = (current_position - previous_position).length() / delta
	previous_position = current_position 
	
	var target_fov = lerp(min_fov, max_fov, clamp(speed / max_fov_speed, 0, 1))
	camera.fov = lerp(camera.fov, target_fov, fov_smoothness * delta)

func apply_rotation(delta):
	var pitch_delta = deg_to_rad(-mouse_delta.y * mouse_sensitivity)
	var yaw_delta = deg_to_rad(-mouse_delta.x * mouse_sensitivity)
	var target_roll_speed = 0.0

	if Input.is_action_pressed("roll_left"):
		target_roll_speed = roll_speed
	elif Input.is_action_pressed("roll_right"):
		target_roll_speed = -roll_speed

	# Smoothly lerp roll speed from current value towards the target value
	current_roll_speed = lerp(current_roll_speed, target_roll_speed, roll_smoothness * delta)

	rotate_y(yaw_delta)

	var x_axis = global_transform.basis.x.normalized()
	global_transform.basis = Basis(x_axis, pitch_delta) * global_transform.basis

	if current_roll_speed != 0.0:
		var z_axis = global_transform.basis.z.normalized()
		global_transform.basis = Basis(z_axis, current_roll_speed * delta) * global_transform.basis
	
	mouse_delta = Vector2.ZERO
