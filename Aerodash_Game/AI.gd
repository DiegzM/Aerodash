extends "res://BaseCharacter.gd"

@export var roll_speed: float = 5.0
@export var roll_smoothness: float = 3

@onready var current_roll_speed: float = 0

# Called when the node enters the scene tree for the first time.
func _ready():
	pass

# Handle input events like mouse motion and toggling mouse lock
func _input(event):
	pass

func _physics_process(delta):
	pass
		
# Get the player's input for movement
func get_input_vector() -> Vector3:
	var direction = Vector3(0, 0, -1)

	return direction.normalized()

# Get the player's input for rotation based on mouse movement
func get_input_rotation() -> Vector3:
	return Vector3(0,0,0)
