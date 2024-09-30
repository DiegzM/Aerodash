class_name BaseCharacter
extends RigidBody3D

########## SETTINGS ##############
# SPEEDS
const ACCELERATION = Vector3(300, 300, 300) # Vector3(forward_acceleration, upward_acceleration, side_acceleration)
const BOOST_ACCELERATION = Vector3(500, 500, 500)
const MAX_SPEED = Vector3(90, 90, 90) # Vector3(forward_max_speed, upward_max_speed, side_max_speed)
const MAX_BOOST_SPEED = Vector3(110, 110, 110) # Vector3(forward_max_boost_speed, upward_max_boost_speed, side_max_boost_speed)
const MAX_BOOST_TIME = 7
const BOOST_RECHARGE_SPEED = 0.2 # per second
const MAX_DOWNWARD_FACTOR = 1.6 # How many times to increase speed when facing vertically down
const MAX_UPWARD_FACTOR = 0.9 # How many times to increase speed when facing vertically up
const ROLL_SPEED = 4.0

# DAMPING
const MOVEMENT_DAMPING = 0.95 # Closer to 1 is slower
const ROTATION_DAMPING = 0.95 # Closer to 1 is slower

# ROTATION SMOOTHNESS
const ROTATION_SMOOTHNESS = 0.1 # Lower value = smoother (slow), higher value = faster
const LERP_VELOCITY = 0.9 # Incase speed reaches max, allow for smooth slowdown
##################################

var boost_pressed = false
var boosting = false
var current_boost_time = MAX_BOOST_TIME

var current_acceleration = ACCELERATION

var track = null
var previous_section = null
var current_section = null
var current_section_index = -1
var current_gate = null
var track_sections: Array = []
var next_gate = null

var lap = 1

var race_manager = null
var race_finished = false

var target_velocity = Vector3.ZERO

# Called when the node enters the scene tree for the first time.
func _ready():
	race_manager = get_tree().current_scene.get_node("RaceManager")
	track = get_tree().current_scene.get_node("Track")
	if track:
		for i in range(track.get_child_count()):
			track_sections.append(track.get_child(i))
		if track.get_child_count() > 1:
			next_gate = track.get_child(0).get_node("Gate")
		var start_track_node = track.get_child(track.get_child_count() - 1)
		if start_track_node:
			current_section = start_track_node
			current_gate = start_track_node.get_node("Gate")
		if current_section.has_node("SectionBoundary"):
			var boundary = current_section.get_node("SectionBoundary")
			if not boundary.body_exited.is_connected(_on_section_boundary_exited):
				boundary.body_exited.connect(_on_section_boundary_exited)

func _physics_process(delta):
	if (race_manager.race_started and not race_finished):
		boost(delta)
	
func _integrate_forces(state):
	set_sleeping(false)
	if (race_manager.race_started and not race_finished):
		apply_rotation(state)
		apply_movement(state)
	
# Calculates movement
func apply_movement(state):
	var input_vector = get_input_vector()
	
	var current_max_speed = MAX_SPEED.length()
	current_acceleration = ACCELERATION
	
	if boosting:
		current_max_speed = MAX_BOOST_SPEED.length()
		current_acceleration = BOOST_ACCELERATION
		
	var local_force = Vector3(
		input_vector.x * current_acceleration.x,
		input_vector.y * current_acceleration.y,
		input_vector.z * current_acceleration.z
	)

	# Apply damping to local velocity if no input is present
	if input_vector.x == 0:
		state.linear_velocity.x *= MOVEMENT_DAMPING
	if input_vector.y == 0:
		state.linear_velocity.y *= MOVEMENT_DAMPING
	if input_vector.z == 0:
		state.linear_velocity.z *= MOVEMENT_DAMPING
	
	var speed = state.linear_velocity.length()
	
	# Multiple current_max_speed given players tilt upwards or downwards
	var movement_direction = state.linear_velocity.normalized()
	var vertical_angle = movement_direction.dot(Vector3.UP)
	
	if vertical_angle > 0:
		var upward_factor = lerp(1.0, MAX_UPWARD_FACTOR, vertical_angle)
		current_max_speed *= upward_factor
		current_acceleration *= upward_factor
	elif vertical_angle < 0:
		var downward_factor = lerp(1.0, MAX_DOWNWARD_FACTOR, abs(vertical_angle))
		current_max_speed *= downward_factor
		current_acceleration *= downward_factor
	
	if speed > current_max_speed:
		target_velocity = state.linear_velocity.normalized() * current_max_speed
		state.linear_velocity = lerp(state.linear_velocity, target_velocity, LERP_VELOCITY)
	
	apply_force(local_force)

func apply_rotation(state):
	# Get the current rotation and the target rotation
	angular_velocity = Vector3.ZERO
	var current_rotation = global_rotation
	var target_rotation = get_input_rotation()

	# Smoothly interpolate each axis rotation using lerp_angle
	current_rotation.x = lerp_angle(current_rotation.x, target_rotation.x, ROTATION_SMOOTHNESS)
	current_rotation.y = lerp_angle(current_rotation.y, target_rotation.y, ROTATION_SMOOTHNESS)
	current_rotation.z = lerp_angle(current_rotation.z, target_rotation.z, ROTATION_SMOOTHNESS)

	# Apply the new smooth rotation
	global_rotation = current_rotation

func boost(delta):
	if boost_pressed:
		if current_boost_time > 0:
			boosting = true
			current_boost_time -= delta
		else:
			boosting = false
	else:
		boosting = false
		if current_boost_time <= MAX_BOOST_TIME:
			current_boost_time += BOOST_RECHARGE_SPEED * delta
	
func get_next_gate(section_index) -> Node3D:
	var gate = null
	if section_index + 1 < track.get_child_count():
		gate = track.get_child(section_index + 1).get_node("Gate")
	else:
		gate = track.get_child(0).get_node("Gate")
	return gate

func get_previous_gate(section_index) -> Node3D:
	var gate = null
	if section_index - 1 >= 0:
		gate = track.get_child(section_index -  1).get_node("Gate")
	else:
		gate = track.get_child(track.get_child_count() - 1).get_node("Gate")
	return gate
	
func on_section_passed(gate: Node3D):
	if current_gate != gate:
		previous_section = current_section
		current_section = gate.get_parent()
		current_gate = gate
		
		if previous_section and previous_section.has_node("SectionBoundary"):
			var prev_boundary = previous_section.get_node("SectionBoundary")
			if prev_boundary.body_exited.is_connected(_on_section_boundary_exited):
				prev_boundary.body_exited.disconnect(_on_section_boundary_exited)

		if current_section.has_node("SectionBoundary"):
			var boundary = current_section.get_node("SectionBoundary")
			if not boundary.body_exited.is_connected(_on_section_boundary_exited):
				boundary.body_exited.connect(_on_section_boundary_exited)
		
		current_section_index += 1
		if current_section_index >= track.get_child_count():
			current_section_index = 0
			lap += 1
			
		next_gate = get_next_gate(current_section_index)
		
		if lap > race_manager.laps:
			race_finished = true

func _on_section_boundary_exited(body):
	if body == self:  # Ensure that the body that exited is this BaseCharacter
		global_transform = current_gate.global_transform
		linear_velocity = Vector3.ZERO
		
# Placeholder method, to be implemented by subclasses (Player or AI)
func get_input_vector() -> Vector3:
	return Vector3.ZERO
	
func get_input_rotation() -> Vector3:
	return Vector3.ZERO
