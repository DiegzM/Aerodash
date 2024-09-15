extends RigidBody3D

########## SETTINGS ##############
# SPEEDS
const ACCELERATION = Vector3(120, 120, 120) # Vector3(forward_acceleration, upward_acceleration, side_acceleration)
const MAX_SPEED = Vector3(100, 100, 100) # Vector3(forward_max_speed, upward_max_speed, side_max_speed)

# DAMPING
const MOVEMENT_DAMPING = 0.95 # Closer to 1 is slower
const ROTATION_DAMPING = 0.9 # Closer to 1 is slower
##################################

@onready var target_rotation = rotation_degrees

# Called when the node enters the scene tree for the first time.
func _ready():
	pass

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _integrate_forces(state):
	apply_movement(state)
	apply_rotation(state)
	pass

# Calculates movement
func apply_movement(state):
	var local_force = Vector3.ZERO
	
	# Calculate based on direction input
	if get_input_vector() != Vector3.ZERO:
		local_force = get_input_vector() * ACCELERATION
	else:
		# Apply damping to gradually reduce the velocity when no input
		state.linear_velocity *= MOVEMENT_DAMPING
	
	# Clamp velocity inline
	var velocity = state.linear_velocity
	velocity.x = clamp(velocity.x, -MAX_SPEED.x, MAX_SPEED.x)
	velocity.y = clamp(velocity.y, -MAX_SPEED.y, MAX_SPEED.y)
	velocity.z = clamp(velocity.z, -MAX_SPEED.z, MAX_SPEED.z)
	state.linear_velocity = velocity
	
	apply_force(local_force)

func apply_rotation(state):
	# Get the current rotation and the target rotation
	#var current_rotation = rotation_degrees
	var target_rotation = get_input_rotation()

	global_rotation = target_rotation
	
# Placeholder method, to be implemented by subclasses (Player or AI)
func get_input_vector() -> Vector3:
	return Vector3.ZERO
	
func get_input_rotation() -> Vector3:
	return Vector3.ZERO
