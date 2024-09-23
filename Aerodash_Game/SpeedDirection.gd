extends RigidBody3D

# Variable to store the previous position
var previous_position : Vector3

# Called when the node enters the scene tree for the first time.
func _ready():
	# Initialize previous position to the current position
	previous_position = global_position

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _physics_process(delta):
	# Calculate the movement direction based on the change in position (delta)
	var movement_direction = (global_position - previous_position).normalized()

	# Update the previous position for the next frame
	previous_position = global_position

	# Check if there's meaningful movement before rotating
	if movement_direction.length() > 0.01:
		# Rotate to face the direction of movement
		look_at(global_position + movement_direction, Vector3.UP)
