class_name BaseCharacter
extends RigidBody3D

########## SETTINGS ##############
# SPEEDS
const ACCELERATION = Vector3(300, 300, 300) # Vector3(forward_acceleration, upward_acceleration, side_acceleration)
const MAX_SPEED = Vector3(80, 80, 80) # Vector3(forward_max_speed, upward_max_speed, side_max_speed)
const ROLL_SPEED = 4.0

# DAMPING
const MOVEMENT_DAMPING = 0.95 # Closer to 1 is slower
const ROTATION_DAMPING = 0.95 # Closer to 1 is slower

# ROTATION SMOOTHNESS
const ROTATION_SMOOTHNESS = 0.1 # Lower value = smoother (slow), higher value = faster
##################################

var track = null
var previous_section = null
var current_section = null
var current_section_index = -1
var current_gate = null
var track_sections: Array = []
var next_gate = null

var lap = 1

# Called when the node enters the scene tree for the first time.
func _ready():
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
	angular_velocity = Vector3.ZERO
	var current_rotation = global_rotation
	var target_rotation = get_input_rotation()

	# Smoothly interpolate each axis rotation using lerp_angle
	current_rotation.x = lerp_angle(current_rotation.x, target_rotation.x, ROTATION_SMOOTHNESS)
	current_rotation.y = lerp_angle(current_rotation.y, target_rotation.y, ROTATION_SMOOTHNESS)
	current_rotation.z = lerp_angle(current_rotation.z, target_rotation.z, ROTATION_SMOOTHNESS)

	# Apply the new smooth rotation
	global_rotation = current_rotation

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
			
		if current_section_index + 1 < track.get_child_count():
			next_gate = track.get_child(current_section_index + 1).get_node("Gate")
		else:
			next_gate = track.get_child(0).get_node("Gate")

func _on_section_boundary_exited(body):
	if body == self:  # Ensure that the body that exited is this BaseCharacter
		global_transform = current_gate.global_transform
		linear_velocity = Vector3.ZERO
		
# Placeholder method, to be implemented by subclasses (Player or AI)
func get_input_vector() -> Vector3:
	return Vector3.ZERO
	
func get_input_rotation() -> Vector3:
	return Vector3.ZERO
