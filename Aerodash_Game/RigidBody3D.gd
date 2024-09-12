extends RigidBody3D

const UPWARD_FORCE = 37
const FORWARD_FORCE = -130
const BOOST_FORCE = -240
const MAX_SPEED = 100.0
const MIN_SPEED = 5.0
const MAX_TURN_SPEED = 1.25
const MIN_TURN_SPEED = 0.25
const MAX_TILT_ANGLE = deg_to_rad(90)
const ROLL_SPEED = 4
const MAX_ANGULAR_SPEED = 8  # Maximum tilt angle in radians

var angular_inertia = Vector3.ZERO
const INERTIA_DECAY = 0.9 # Decay rate of inertia each frame

func _ready():
	linear_damp = 2
	angular_damp = 2

func _integrate_forces(state):
	var local_force = calculate_forces(state)
	var local_torque = calculate_torque(state)
	apply_force(local_force)
	apply_torque(local_torque)
	adjust_cube_tilt(state)
	angular_inertia *= INERTIA_DECAY  # Apply decay to inertia

func calculate_forces(state) -> Vector3:
	var local_force = Vector3.ZERO
	var gravity = -ProjectSettings.get_setting("physics/3d/default_gravity")

	# Apply antigravity force if not falling
	if not Input.is_action_pressed("fall"):
		local_force += Vector3(0, -gravity * gravity_scale * mass, 0)

	# Forward and backward movement
	local_force += calculate_directional_forces(state)

	return local_force

func calculate_directional_forces(state) -> Vector3:
	var directional_force = Vector3.ZERO
	var speed = state.linear_velocity.length()
	var boost = 0
	
	if Input.is_action_pressed("boost"):
		boost = BOOST_FORCE
		
	var force_scale = clamp((MAX_SPEED - speed) / MAX_SPEED, 0.0, 1.0)

	if Input.is_action_pressed("move_forward"):
		directional_force += global_transform.basis.z * (FORWARD_FORCE + boost) * force_scale
	if Input.is_action_pressed("move_backward"):
		directional_force -= global_transform.basis.z * (FORWARD_FORCE + boost) * force_scale
	if Input.is_action_pressed("move_up"):
		directional_force += global_transform.basis.y * UPWARD_FORCE
	if Input.is_action_pressed("move_down"):
		directional_force -= global_transform.basis.y * UPWARD_FORCE

	return directional_force

func calculate_torque(state) -> Vector3:
	var turn_speed_factor = lerp(MIN_TURN_SPEED, MAX_TURN_SPEED, (MAX_SPEED - state.linear_velocity.length()) / MAX_SPEED)
	var local_torque = Vector3.ZERO

	if Input.is_action_pressed("move_left"):
		local_torque += global_transform.basis.y * turn_speed_factor
		angular_inertia += local_torque * 0.1  # Add a fraction of the torque to inertia
	if Input.is_action_pressed("move_right"):
		local_torque -= global_transform.basis.y * turn_speed_factor
		angular_inertia += local_torque * 0.1  # Add a fraction of the torque to inertia

	if Input.is_action_pressed("roll_left"):
		local_torque += global_transform.basis.z * ROLL_SPEED
	if Input.is_action_pressed("roll_right"):
		local_torque -= global_transform.basis.z * ROLL_SPEED

	return local_torque

func adjust_cube_tilt(state):
	var cube = $Cube
	var angular_velocity = state.angular_velocity.y
	var tilt_angle = angular_velocity / MAX_ANGULAR_SPEED * MAX_TILT_ANGLE
	tilt_angle = clamp(tilt_angle, -MAX_TILT_ANGLE, MAX_TILT_ANGLE)
	cube.rotation_degrees.z = rad_to_deg(tilt_angle)

	if !Input.is_action_pressed("move_left") && !Input.is_action_pressed("move_right"):
		angular_damp = 7
	else:
		angular_damp = 1
