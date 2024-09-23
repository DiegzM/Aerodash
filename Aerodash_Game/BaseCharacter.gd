extends RigidBody3D

########## SETTINGS ##############
# SPEEDS
const ACCELERATION = Vector3(240, 240, 240) # Vector3(forward_acceleration, upward_acceleration, side_acceleration)
const MAX_SPEED = Vector3(100, 100, 100) # Vector3(forward_max_speed, upward_max_speed, side_max_speed)

# DAMPING
const MOVEMENT_DAMPING = 0.95 # Closer to 1 is slower
const ROTATION_DAMPING = 0.9 # Closer to 1 is slower

# ROTATION SMOOTHNESS
const ROTATION_SMOOTHNESS = 0.1 # Lower value = smoother (slow), higher value = faster
##################################

# Called when the node enters the scene tree for the first time.
func _ready():
	pass
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _integrate_forces(state):
	apply_rotation(state)
	apply_movement(state)
	
# Calculates movement
func apply_movement(state):
	var input_vector = get_input_vector()

	var local_force = Vector3(
		input_vector.x * ACCELERATION.x,
		input_vector.y * ACCELERATION.y,
		input_vector.z * ACCELERATION.z
	)

	# Apply damping to local velocity if no input is present
	if input_vector.x == 0:
		state.linear_velocity.x *= MOVEMENT_DAMPING
	if input_vector.y == 0:
		state.linear_velocity.y *= MOVEMENT_DAMPING
	if input_vector.z == 0:
		state.linear_velocity.z *= MOVEMENT_DAMPING
	
	# Clamp velocity
	var speed = state.linear_velocity.length()

	if speed > MAX_SPEED.length():
		state.linear_velocity = state.linear_velocity.normalized() * MAX_SPEED.length()
	
	apply_force(local_force)

func apply_rotation(state):
	# Get the current rotation and the target rotation
	var current_rotation = global_rotation
	var target_rotation = get_input_rotation()

	# Smoothly interpolate each axis rotation using lerp_angle
	current_rotation.x = lerp_angle(current_rotation.x, target_rotation.x, ROTATION_SMOOTHNESS)
	current_rotation.y = lerp_angle(current_rotation.y, target_rotation.y, ROTATION_SMOOTHNESS)
	current_rotation.z = lerp_angle(current_rotation.z, target_rotation.z, ROTATION_SMOOTHNESS)

	# Apply the new smooth rotation
	global_rotation = current_rotation
	
# Placeholder method, to be implemented by subclasses (Player or AI)
func get_input_vector() -> Vector3:
	return Vector3.ZERO
	
func get_input_rotation() -> Vector3:
	return Vector3.ZERO
