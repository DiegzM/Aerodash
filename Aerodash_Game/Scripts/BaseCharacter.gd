class_name BaseCharacter
extends RigidBody3D

########## SETTINGS ##############
# SPEEDS
const ACCELERATION = Vector3(400, 400, 400) # Vector3(forward_acceleration, upward_acceleration, side_acceleration)
const MAX_SPEED = Vector3(90, 90, 90) # Vector3(forward_max_speed, upward_max_speed, side_max_speed)
const MIN_BOOST_SPEED = Vector3(135, 135, 135) # Vector3(forward_max_boost_speed, upward_max_boost_speed, side_max_boost_speed)
const MAX_BOOST_SPEED = Vector3(135, 135, 135)
const MAX_BOOST_TIME = 7
const SPEED_PENALTY_MULTIPLIER = 0.5
const MIN_BOOST_RECHARGE_SPEED = 1.4 # Boost recharge speed at first place
const MAX_BOOST_RECHARGE_SPEED = 4.4 # Boost recharge speed at last place
const MAX_DOWNWARD_FACTOR = 1.6 # How many times to increase speed when facing vertically down
const MAX_UPWARD_FACTOR = 0.9 # How many times to increase speed when facing vertically up
const ROLL_SPEED = 4.0

# DAMPING
const MOVEMENT_DAMPING = 0.95 # Closer to 1 is slower
const ROTATION_DAMPING = 0.95 # Closer to 1 is slower

# COLLISION
const COLLISION_SPEED = 40 # How fast a collision has to be in order to crash another racer (or get crashed)
const COLLISION_DIFFERENCE = 3 # If the collision global speed difference is within this value, both racers will crash.
const KNOCKDOWN_STREAK_TIME = 4 # Maximum much time between knockdowns to count as a streak

# DEATH
const RESPAWN_TIME = 2.0 # How long to wait if killed
const FORCEFIELD_TIME = 4.0 # How long to be protected after respawning

# ROTATION SMOOTHNESS
const ROTATION_SMOOTHNESS = 0.1 # Lower value = smoother (slow), higher value = faster
const LERP_VELOCITY = 0.9 # Incase speed reaches max, allow for smooth slowdown
##################################

var boost_pressed = false
var boosting = false
var current_boost_time = MAX_BOOST_TIME
var current_boost_speed = MIN_BOOST_SPEED

var current_acceleration = ACCELERATION
var current_boost_acceleration = Vector3.ZERO
var current_boost_recharge_speed = MIN_BOOST_RECHARGE_SPEED

var track = null
var previous_section = null
var current_section = null
var current_section_index = -1
var current_gate = null
var track_sections: Array = []
var next_gate = null

var final_place = -1

var lap = 1

var elapsed_time = 0.0

var current_respawn_time = RESPAWN_TIME
var current_forcefield_time = 0
var off_track = false
var dead = false
var knockdown = false
var knockdown_streak = 0
var current_knockdown_streak_time = 0
var total_knockdowns = 0
var total_deaths = 0

var level_manager = null
var characters = null
var race_finished = false

var collision_box = null

var collided_with = ""

var target_velocity = Vector3.ZERO

# Called when the node enters the scene tree for the first time.
func _ready():
	set_contact_monitor(true)
	max_contacts_reported = 10
	level_manager = get_tree().current_scene
	characters = level_manager.characters
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
	knockdown = false
	if (level_manager.race_started and not race_finished):
		elapsed_time += delta
		boost(delta)
		forcefield_time(delta)
		smoke(delta)
		if not dead:
			if level_manager.knockdowns:
				handle_collisions()
				knockdown_time(delta)
	if dead:
		respawn(delta)
		death_movement()
	
	if race_finished and final_place == -1:
		final_place = level_manager.final_leaderboard.find(self)
	
func _integrate_forces(state):
	set_sleeping(false)
	if (level_manager.race_started and not race_finished and not dead):
		apply_rotation(state)
		apply_movement(state)
	
# Calculates movement
func apply_movement(state):
	var input_vector = get_input_vector()
	
	var current_max_speed = MAX_SPEED.length()
	current_acceleration = ACCELERATION
	
	if boosting:
		current_max_speed = current_boost_speed.length()
		current_acceleration = current_boost_acceleration
		
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
	
	if off_track:
		current_max_speed *= SPEED_PENALTY_MULTIPLIER
		
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

func death_movement(): 
	var local_force = Vector3(0, -ACCELERATION.y, 0)
	apply_force(local_force)
	
func respawn(delta):
	current_respawn_time -= delta
	if current_respawn_time <= 0:
		current_respawn_time = RESPAWN_TIME
		dead = false
		global_transform = current_gate.global_transform
		linear_velocity = Vector3.ZERO
		
func smoke(delta):
	if self.has_node("Smoke"):
		if dead:
			$Smoke.emitting = true
			$Smoke.visible = true
		else:
			$Smoke.emitting = false
			$Smoke.visible = false
		
	
func forcefield_time(delta):
	if current_forcefield_time > 0:
		current_forcefield_time -= delta
	if dead:
		current_forcefield_time = FORCEFIELD_TIME

func knockdown_time(delta):
	if current_knockdown_streak_time > 0:
		current_knockdown_streak_time -= delta
	else:
		knockdown_streak = 0
			
	if knockdown:
		knockdown_streak += 1
		current_knockdown_streak_time = KNOCKDOWN_STREAK_TIME
	
func boost(delta):
	var player_index = -1
	for i in range(characters.size()):
		if characters[i] == self:
			player_index = i
			break
	
	if player_index != -1:
		var position_factor = float(player_index) / float(characters.size() - 1)  # Relative position from 0 (first place) to 1 (last place)
		if level_manager.knockdowns:
			current_boost_speed = lerp(MIN_BOOST_SPEED, MAX_BOOST_SPEED, position_factor)
		else:
			current_boost_speed = lerp(MIN_BOOST_SPEED, MAX_BOOST_SPEED, 0.5)
		
		var boost_acceleration_multiplier = current_boost_speed.length() / MAX_SPEED.length()
		
		current_boost_acceleration = ACCELERATION * boost_acceleration_multiplier
	else:
		current_boost_speed = MIN_BOOST_SPEED
		
	if boost_pressed and get_input_vector() != Vector3.ZERO:
		if current_boost_time > 0:
			boosting = true
			current_boost_time -= delta
		else:
			boosting = false
	else:
		boosting = false
		if current_boost_time <= MAX_BOOST_TIME:
			
			var position_factor = float(player_index) / float(characters.size() - 1)  
			if level_manager.knockdowns:
				current_boost_recharge_speed = lerp(MIN_BOOST_RECHARGE_SPEED, MAX_BOOST_RECHARGE_SPEED, position_factor)
			else:
				current_boost_recharge_speed = lerp(MIN_BOOST_RECHARGE_SPEED, MAX_BOOST_RECHARGE_SPEED, 0.5)
			current_boost_time += current_boost_recharge_speed * delta
	
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
	if current_gate != gate and not dead:
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
		
		var target_section_index = current_section.get_name().to_int()
		if target_section_index == 0 and not current_section_index == -1:
			lap += 1
		
		current_section_index = target_section_index
		
		next_gate = get_next_gate(current_section_index)
		
		off_track = false
		
		if lap > level_manager.laps:
			race_finished = true

func handle_collisions():
	var colliding_bodies = get_colliding_bodies()
	for i in range(colliding_bodies.size()):
		var body = colliding_bodies[i]
		if body and body is BaseCharacter:
			var relative_velocity = (linear_velocity - body.linear_velocity).length()
			if relative_velocity >= COLLISION_SPEED:
				collided_with = body.name
				if linear_velocity.length() > body.linear_velocity.length() + COLLISION_DIFFERENCE:
					if body.current_forcefield_time <= 0:
						knockdown = true
						total_knockdowns += 1
						body.dead = true
				elif linear_velocity.length() < body.linear_velocity.length() - COLLISION_DIFFERENCE:
					if current_forcefield_time <= 0:
						total_deaths += 1
						dead = true
				else:
					if current_forcefield_time <= 0:
						total_deaths += 1
						dead = true
					if body.current_forcefield_time <= 0:
						knockdown = true
						body.dead = true
						total_knockdowns += 1
						
			
func _on_section_boundary_exited(body):
	if body == self and not dead:  # Ensure that the body that exited is this BaseCharacter
		off_track = true

# Placeholder method, to be implemented by subclasses (Player or AI)
func get_input_vector() -> Vector3:
	return Vector3.ZERO
	
func get_input_rotation() -> Vector3:
	return Vector3.ZERO
