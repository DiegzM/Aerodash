extends "res://Scripts/BaseCharacter.gd"

@export var roll_speed: float = 5.0
@export var roll_smoothness: float = 3

@export var radius_offset = 4 # How many units to decrease the radius the AI uses to reach next gate, aka aim closer to the cneter
@export var target_error = 1.0

@export var min_boost_probability = 0.002 # How likely AI will boost at first place any frame
@export var max_boost_probability = 0.10 # How likely AI will boost at last place any frame
@export var boost_cutoff_probability = 0.005 # How likely AI will stop boosting at any frame
@export var min_boost_timeout = 3 # Minimum how long to wait before boosting again, after running out of boost
@export var max_boost_timeout = 10 # Maximum how long to wait before boosting again, after running out of boost

@onready var current_roll_speed: float = 0

var current_boost_probability = 0
var current_boost_timeout = 0
var current_target_position = Vector3.ZERO
var pivot = null
var random_x_offset = randf_range(-2.5, 2.5)
var random_y_offset = randf_range(-2.5, 2.5) 

var vehicles_scenes = [
	"res://Assets/Vehicles/vehicle_1.tscn",
	"res://Assets/Vehicles/vehicle_2.tscn",
	"res://Assets/Vehicles/vehicle_3.tscn"
]
var vehicle_instance = null

# Called when the node enters the scene tree for the first time.
func _ready():
	super()
	current_target_position = calculate_target_position(next_gate)
	pivot = get_parent().get_node("Pivot")
	
	select_random_vehicle()
	
	for child in vehicle_instance.get_children():
		vehicle_instance.remove_child(child)
		add_child(child)
	
	for child in get_children():
		if child.name == "Audio":
			child.body = self
			
	remove_child(vehicle_instance)

func select_random_vehicle():

	if vehicles_scenes.size() > 0:
		randomize()  # Randomize the seed
		var random_index = randi() % vehicles_scenes.size()  # Get random index
		var selected_vehicle_scene = load(vehicles_scenes[random_index])  # Use load() instead of preload()
		
		if selected_vehicle_scene:
			vehicle_instance = selected_vehicle_scene.instantiate()  # Instance the loaded scene
			add_child(vehicle_instance)  # Add it to the scene tree
		else:
			print("Error: Could not load the selected vehicle scene.")
			
# Handle input events like mouse motion and toggling mouse lock
func _input(event):
	pass

func _physics_process(delta):
	super(delta)
	if race_manager.race_started:
		determine_boost(delta)
		
# Get the player's input for movement
func get_input_vector() -> Vector3:
	var direction = -pivot.transform.basis.z
	return direction.normalized()

# Get the player's input for rotation based on mouse movement
func get_input_rotation() -> Vector3:
	
	if global_transform.origin.distance_to(current_target_position) < 30.0:
		current_target_position = calculate_target_position(get_next_gate(current_section_index + 1))
	var distance_to_target = current_target_position - global_transform.origin
	var direction_to_target = distance_to_target.normalized()
	var adjustment_vector = direction_to_target - linear_velocity.normalized()

	if adjustment_vector.length() > randf_range(0.01, 1.0):
		adjustment_vector = adjustment_vector.normalized() * 5.0 

	# Combine the target direction and the adjustment vector
	var corrected_direction = direction_to_target + adjustment_vector
	
	var current_rotation = pivot.global_rotation
	# Rotate the AI to face the corrected direction
	pivot.look_at(global_transform.origin + corrected_direction)
	var target_rotation = pivot.global_rotation
	current_rotation = target_rotation
	pivot.global_rotation = current_rotation
	# Return the AI's new global rotation after applying the adjustment
	return pivot.global_rotation

func determine_boost(delta):
	if current_boost_timeout <= 0:
		var player_count = characters.size()
		var player_index = -1
		
		for i in range(player_count):
			if characters[i] == self:
				player_index = i
				break
		
		if player_index != -1:
			var position_factor = float(player_index) / float(player_count - 1)  # Relative position from 0 (first place) to 1 (last place)
			current_boost_probability = lerp(min_boost_probability, max_boost_probability, position_factor)
			if randf() < current_boost_probability or boosting:
				if randf() < boost_cutoff_probability:
					boost_pressed = false
				else:
					boost_pressed = true
					if current_boost_time <= 0:
						current_boost_timeout = lerp(max_boost_timeout, min_boost_timeout, position_factor)
			else:
				boost_pressed = false
	else:
		boost_pressed = false
		current_boost_timeout -= delta
	
func predict_future_position(time_ahead: float) -> Vector3:
	var current_velocity = linear_velocity
	var input_vector = get_input_vector()
	var current_acceleration = ACCELERATION * input_vector

	if input_vector.x == 0:
		current_velocity.x *= MOVEMENT_DAMPING
	if input_vector.y == 0:
		current_velocity.y *= MOVEMENT_DAMPING
	if input_vector.z == 0:
		current_velocity.z *= MOVEMENT_DAMPING
	
	var future_velocity = current_velocity + (current_acceleration * time_ahead)
	var future_position = global_transform.origin + (future_velocity * time_ahead)

	return future_position

func calculate_target_position(gate) -> Vector3:
	var closest_point = get_closest_point_to_gate(gate)
	var collision_shape = gate.get_node("Trigger/CollisionShape3D")
	
	if collision_shape and collision_shape.shape is CylinderShape3D:
		var radius = collision_shape.scale.x - radius_offset
		var error_x = randf_range(-target_error, target_error)
		var error_y = randf_range(-target_error, target_error)
		var local_errored_position = gate.to_local(closest_point + Vector3(error_x, error_y, 0))
		var distance_to_center = Vector2(local_errored_position.x, local_errored_position.y).length()
		
		if distance_to_center > radius:
			var clamped_position = Vector2(local_errored_position.x, local_errored_position.y).normalized() * radius
			local_errored_position.x = clamped_position.x
			local_errored_position.y = clamped_position.y
		
		return gate.to_global(local_errored_position)
	else:
		return Vector3.ZERO
	
func get_closest_point_to_gate(gate) -> Vector3:
	var collision_shape = gate.get_node("Trigger/CollisionShape3D")
	if collision_shape and collision_shape.shape is CylinderShape3D:
		var radius = collision_shape.scale.x - radius_offset
		
		var local_player_position = gate.to_local(global_transform.origin)
		var player_xz = Vector2(local_player_position.x, local_player_position.y)
		var closest_point_xz = player_xz.normalized() * min(player_xz.length(), radius)

		var target_position = next_gate.to_global(Vector3(closest_point_xz.x, closest_point_xz.y, 0))
		return target_position
	else:
		return Vector3.ZERO

func _on_section_boundary_exited(body):
	if body == self:  # Ensure that the body that exited is this BaseCharacter
		pivot.global_rotation = current_gate.global_rotation
		global_transform = current_gate.global_transform
		global_rotation = current_gate.global_rotation
		linear_velocity /= 3

func on_section_passed(gate: Node3D):
	super(gate)
	current_target_position = calculate_target_position(next_gate)
	if current_gate != gate:
		random_x_offset = randf_range(-2.5, 2.5)  # Adjust the range as needed
		random_y_offset = randf_range(-2.5, 2.5) 
	var mesh = MeshInstance3D.new()
	mesh.mesh = SphereMesh.new()
	mesh.scale = Vector3(2,2,2)
	get_tree().current_scene.add_child(mesh)
	mesh.global_transform.origin = current_target_position
