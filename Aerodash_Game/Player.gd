extends "res://BaseCharacter.gd"

const MOUSE_SENSITIVITY = 0.3
@export var roll_speed: float = 5.0
@export var roll_smoothness: float = 3

@onready var current_roll_speed: float = 0

var pivot: Node3D

# Called when the node enters the scene tree for the first time.
func _ready():
	pivot = get_parent().get_node("CameraPivot")
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

# Handle input events like mouse motion and toggling mouse lock
func _input(event):
	pass

func _physics_process(delta):
	var target_roll_speed = 0.0

	if Input.is_action_pressed("roll_left"):
		target_roll_speed = roll_speed
	elif Input.is_action_pressed("roll_right"):
		target_roll_speed = -roll_speed

	# Smoothly lerp roll speed from current value towards the target value
	current_roll_speed = lerp(current_roll_speed, target_roll_speed, roll_smoothness * delta)

	if current_roll_speed != 0.0:
		var z_axis = pivot.global_transform.basis.z.normalized()
		pivot.global_transform.basis = Basis(z_axis, current_roll_speed * delta) * pivot.global_transform.basis
# Get the player's input for movement
func get_input_vector() -> Vector3:
	var direction = Vector3.ZERO

	if Input.is_action_pressed("move_forward"):
		direction -= transform.basis.z
	if Input.is_action_pressed("move_backward"):
		direction += transform.basis.z
	if Input.is_action_pressed("move_left"):
		direction -= transform.basis.x
	if Input.is_action_pressed("move_right"):
		direction += transform.basis.x
	if Input.is_action_pressed("move_up"):
		direction += transform.basis.y
	if Input.is_action_pressed("move_down"):
		direction -= transform.basis.y

	return direction.normalized()

# Get the player's input for rotation based on mouse movement
func get_input_rotation() -> Vector3:
	var input_rotation = pivot.global_rotation
	return input_rotation
