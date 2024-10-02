extends "res://Scripts/BaseCharacter.gd"

@export var roll_speed: float = 5.0
@export var roll_smoothness: float = 3

@export var radius_offset = 4 # How many units to decrease the radius the AI uses to reach next gate, aka aim closer to the cneter

@onready var current_roll_speed: float = 0

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
	current_target_position = get_closest_point_to_gate()
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
		
# Get the player's input for movement
func get_input_vector() -> Vector3:
	var direction = -pivot.transform.basis.z
	return direction.normalized()

# Get the player's input for rotation based on mouse movement
func get_input_rotation() -> Vector3: # Adjust the range as needed
	var target_position = current_target_position
	var current_forward = -pivot.transform.basis.z
	var direction_to_target =(target_position - global_transform.origin).normalized()
	
	var angle_to_target = current_forward.angle_to(direction_to_target)
	var rotation_speed = 5
	var adjusted_forward = current_forward.lerp(direction_to_target, rotation_speed).normalized()
	pivot.look_at(global_transform.origin + adjusted_forward, Vector3.UP)
	
	return pivot.global_rotation
	

func get_closest_point_to_gate() -> Vector3:
	var gate = next_gate
	var collision_shape = gate.get_node("Trigger/CollisionShape3D")
	if collision_shape and collision_shape.shape is CylinderShape3D:
		var radius = collision_shape.shape.radius - radius_offset
		
		var local_player_position = gate.to_local(global_transform.origin)
		var player_xz = Vector2(local_player_position.x, local_player_position.z)
		var closest_point_xz = player_xz.normalized() * min(player_xz.length(), radius)

		var target_position = next_gate.to_global(Vector3(closest_point_xz.x, 0, closest_point_xz.y))
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
	current_target_position = get_closest_point_to_gate()
	if current_gate != gate:
		random_x_offset = randf_range(-2.5, 2.5)  # Adjust the range as needed
		random_y_offset = randf_range(-2.5, 2.5) 

