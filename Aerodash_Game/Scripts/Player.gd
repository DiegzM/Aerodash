extends "res://Scripts/BaseCharacter.gd"

const MOUSE_SENSITIVITY = 0.3
@export var roll_smoothness: float = 3

@onready var current_roll_speed: float = 0

var pivot: Node3D
var vehicle = preload("res://Assets/Vehicles/vehicle_1.tscn")
var vehicle_instance = vehicle.instantiate()

var mouse_button_pressed = false
\
# Called when the node enters the scene tree for the first time.
func _ready():
	super()
	pivot = get_parent().get_node("CameraPivot")
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	
	add_child(vehicle_instance)
	
	for child in vehicle_instance.get_children():
		vehicle_instance.remove_child(child)
		add_child(child)
		
	for child in get_children():
		if child.name == "Audio":
			child.body = self
		
	remove_child(vehicle_instance)

func _input(event):
	if event is InputEventMouseButton:
		if event.is_pressed():  # Mouse button down.
			mouse_button_pressed = true
		elif not event.is_pressed():  # Mouse button released.
			mouse_button_pressed = false

func _physics_process(delta):
	var target_roll_speed = 0.0

	if race_manager.race_started:
		if Input.is_action_pressed("roll_left"):
			target_roll_speed = ROLL_SPEED
		elif Input.is_action_pressed("roll_right"):
			target_roll_speed = -ROLL_SPEED

	# Smoothly lerp roll speed from current value towards the target value
	current_roll_speed = lerp(current_roll_speed, target_roll_speed, roll_smoothness * delta)

	if current_roll_speed != 0.0:
		pivot.rotate_object_local(Vector3(0, 0, 1), current_roll_speed * delta)
		
	if mouse_button_pressed:
		boosting = true
	else:
		boosting = false
		
		
# Get the player's input for movement
func get_input_vector() -> Vector3:
	var direction = Vector3.ZERO

	if Input.is_action_pressed("move_forward"):
		direction -= pivot.transform.basis.z
	if Input.is_action_pressed("move_backward"):
		direction += pivot.transform.basis.z
	if Input.is_action_pressed("move_left"):
		direction -= pivot.transform.basis.x
	if Input.is_action_pressed("move_right"):
		direction += pivot.transform.basis.x
	if Input.is_action_pressed("move_up"):
		direction += pivot.transform.basis.y
	if Input.is_action_pressed("move_down"):
		direction -= pivot.transform.basis.y

	return direction.normalized()
	
func get_input_rotation() -> Vector3:
	var input_rotation = pivot.global_rotation
	return input_rotation
	
func _on_section_boundary_exited(body):
	if body == self:  # Ensure that the body that exited is this BaseCharacter
		pivot.global_rotation = current_gate.global_rotation
		global_transform = current_gate.global_transform

func on_section_passed(gate: Node3D):
	super(gate)

	
