extends "res://BaseCharacter.gd"

@export var roll_speed: float = 5.0
@export var roll_smoothness: float = 3

@onready var current_roll_speed: float = 0

var pivot = null
var random_x_offset = randf_range(-2.5, 2.5)
var random_y_offset = randf_range(-2.5, 2.5) 

# Called when the node enters the scene tree for the first time.
func _ready():
	super()
	pivot = get_parent().get_node("Pivot")

# Handle input events like mouse motion and toggling mouse lock
func _input(event):
	pass

func _physics_process(delta):
	pass
		
# Get the player's input for movement
func get_input_vector() -> Vector3:
	var direction = -pivot.transform.basis.z
	return direction.normalized()

# Get the player's input for rotation based on mouse movement
func get_input_rotation() -> Vector3: # Adjust the range as needed
	var target_position = next_gate.global_transform.origin + (next_gate.transform.basis * Vector3(random_x_offset, random_y_offset, 0))
	pivot.look_at(target_position)
	
	return pivot.global_rotation

func _on_section_boundary_exited(body):
	if body == self:  # Ensure that the body that exited is this BaseCharacter
		global_rotation = current_gate.global_rotation
		global_transform = current_gate.global_transform

func on_section_passed(gate: Node3D):
	super(gate)
	if current_gate != gate:
		random_x_offset = randf_range(-2.5, 2.5)  # Adjust the range as needed
		random_y_offset = randf_range(-2.5, 2.5) 

