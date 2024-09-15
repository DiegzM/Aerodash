extends "res://BaseCharacter.gd"

const MOUSE_SENSITIVITY = 0.3
var pivot: Node3D

# Called when the node enters the scene tree for the first time.
func _ready():
	pivot = get_parent().get_node("CameraPivot")
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

# Handle input events like mouse motion and toggling mouse lock
func _input(event):
	pass

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
