extends "res://BaseCharacter.gd"

const MOUSE_SENSITIVITY = 0.3

@onready var INGAME = true
@onready var mouse_delta: Vector2 = Vector2.ZERO

# Called when the node enters the scene tree for the first time.
func _ready():
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

# Handle input events like mouse motion and toggling mouse lock
func _input(event):
	# Toggle between mouse captured and visible modes with ESC key
	if event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE:
		toggle_mouse_mode()
	
	# Capture mouse motion when the game is in focus (INGAME)
	if event is InputEventMouseMotion and INGAME:
		mouse_delta = event.relative

# Toggle mouse mode between captured (for gameplay) and visible (for menus)
func toggle_mouse_mode():
	if Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
		INGAME = false
	else:
		Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
		INGAME = true

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
	var input_rotation = Vector3.ZERO
	input_rotation.y = -mouse_delta.x * MOUSE_SENSITIVITY
	input_rotation.x = mouse_delta.y * MOUSE_SENSITIVITY
	
	return input_rotation
