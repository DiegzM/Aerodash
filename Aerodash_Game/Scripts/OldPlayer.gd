extends "res://Scripts/BaseCharacter.gd"

const MOUSE_SENSITIVITY = 0.3
const GATES_VISIBLE = 8
@export var roll_smoothness: float = 3

@onready var current_roll_speed: float = 0

var pivot: Node3D
var vehicles_scenes = [
	"res://Assets/Vehicles/vehicle_1.tscn",
	"res://Assets/Vehicles/vehicle_2.tscn",
	"res://Assets/Vehicles/vehicle_3.tscn",
]
var vehicle_instance = null
var mouse_button_pressed = false

var debug = false

# Called when the node enters the scene tree for the first time.
func _ready():
	super()
	
	pivot = get_parent().get_node("CameraPivot")
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	
	select_random_vehicle()
	
	for child in vehicle_instance.get_children():
		vehicle_instance.remove_child(child)
		add_child(child)
		
	for child in get_children():
		if child.name == "Audio" or child.name == "Exhaust":
			child.body = self
	
	for section in track_sections:
		var gate_mesh = get_gate_mesh(section.get_node("Gate"))
		if gate_mesh:
			set_mesh_local_transparency(gate_mesh, 1.0)

		
	vehicle_instance.queue_free()

	if $CollisionShape3D:
		collision_box = $CollisionShape3D
		
	if $MeshInstance3D:
		var parent_mesh = $MeshInstance3D.mesh
		if $MeshInstance3D.has_node("Outline"):
			var outline_mesh = $MeshInstance3D.get_node("Outline")

			outline_mesh.mesh = parent_mesh
			var outline_material = ShaderMaterial.new()
			outline_material.shader = load("res://Shaders/outline.gdshader")
			outline_mesh.material_override = outline_material
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
	
func _input(event):
	if event is InputEventMouseButton:
		if event.is_pressed():  # Mouse button down.
			mouse_button_pressed = true
		elif not event.is_pressed():  # Mouse button released.
			mouse_button_pressed = false

func _physics_process(delta):
	super(delta)
	if get_tree().current_scene.has_node("DebugCamera"):
		var debug_camera = get_tree().current_scene.get_node("DebugCamera")
		if debug_camera.debug:
			debug = true
		else:
			debug = false
		
	var target_roll_speed = 0.0

	if level_manager.race_started and not debug:
		if Input.is_action_pressed("roll_left"):
			target_roll_speed = ROLL_SPEED
		elif Input.is_action_pressed("roll_right"):
			target_roll_speed = -ROLL_SPEED

	# Smoothly lerp roll speed from current value towards the target value
	current_roll_speed = lerp(current_roll_speed, target_roll_speed, roll_smoothness * delta)

	if current_roll_speed != 0.0:
		pivot.rotate_object_local(Vector3(0, 0, 1), current_roll_speed * delta)
		
	if mouse_button_pressed:
		boost_pressed = true
	else:
		boost_pressed = false
	
	update_gates_transparency(delta)

func update_gates_transparency(delta):
	for section in track_sections:
		var gate_mesh = get_gate_mesh(section.get_node("Gate"))
		if gate_mesh:
			set_mesh_local_transparency(gate_mesh, 1.0)
			
	var max_visible_gates = GATES_VISIBLE
	var player_distance = global_transform.origin.distance_to(next_gate.global_transform.origin)
	var current_gate_distance = current_gate.global_transform.origin.distance_to(next_gate.global_transform.origin)
	var proximity_fraction = player_distance/current_gate_distance
	
	for i in range(max_visible_gates):
		var index = (current_section_index + i) % track_sections.size()
			
		var gate = get_next_gate(index)
		if gate:
			var gate_mesh = get_gate_mesh(gate)
			if gate_mesh:
				var gate_min_transparency = float(i) / float(max_visible_gates)  # Lower bound (e.g., 0.0 for the first gate)
				var gate_max_transparency = float(i + 1) / float(max_visible_gates)  # Upper bound (e.g., 0.2, 0.4, etc.)
				var target_transparency = lerp(gate_min_transparency, gate_max_transparency, proximity_fraction)
				
				set_mesh_local_transparency(gate_mesh, target_transparency)
				
	for i in range(max_visible_gates):
		var adjusted_section_index = max(current_section_index, 0)
		var index = (adjusted_section_index - (i) + track_sections.size()) % track_sections.size()
		var gate = get_previous_gate(index + 1)
		if gate:
			var gate_mesh = get_gate_mesh(gate)
			if gate_mesh:
				var gate_min_transparency = float(i) / float(max_visible_gates)  # Lower bound (e.g., 0.0 for the first gate behind)
				var gate_max_transparency = float(i + 1) / float(max_visible_gates)  # Upper bound (e.g., 0.2, 0.4, etc.)
				var target_transparency = lerp(gate_max_transparency, gate_min_transparency, proximity_fraction)  # Reverse lerp for less visibility
				
				set_mesh_local_transparency(gate_mesh, target_transparency)
				
# Get the player's input for movement
func get_input_vector() -> Vector3:
	var direction = Vector3.ZERO
	if not debug:
		if Input.is_action_pressed("move_forward"):
			direction -= pivot.transform.basis.z
		if Input.is_action_pressed("move_backward"):
			direction += pivot.transform.basis.z
		if Input.is_action_pressed("move_left"):
			direction -= pivot.transform.basis.x
		if Input.is_action_pressed("move_right"):
			direction += pivot.transform.basis.x
		if Input.is_action_pressed("move_up"):
			direction += pivot.transform.basis.y
		if Input.is_action_pressed("move_down"):
			direction -= pivot.transform.basis.y

	return direction.normalized()

func get_dash_vector() -> Vector3:
	var direction = Vector3.ZERO
	if double_pressed("move_left"):
		direction.x -= 1
	if double_pressed("move_right"):
		direction.x += 1
	if double_pressed("move_up"):
		direction.y += 1
	if double_pressed("move_down"):
		direction.y -= 1
	return direction 

func double_pressed(action):
	var current_time = Time.get_ticks_msec() / 1000.0  # Get current time in seconds
	if Input.is_action_just_pressed(action):
		var time_since_last_press = current_time - last_press_time[action]
		
		if time_since_last_press <= DOUBLE_TAP_THRESHOLD:
			last_press_time[action] = current_time
			return true
		else:
			last_press_time[action] = current_time
	return false
	
func get_input_rotation() -> Vector3:
	var input_rotation = pivot.global_rotation
	return input_rotation

func on_section_passed(gate, gate_passed):
	super(gate, gate_passed)
	
func get_gate_mesh(gate) -> MeshInstance3D:
	var mesh = gate.get_node("Mesh/MeshInstance3D")
	if mesh:
		return mesh
	else:
		return null

func set_mesh_local_transparency(mesh, transparency):
	if multiplayer.get_peers().size() > 1:
		if multiplayer.get_unique_id() == multiplayer.get_multiplayer_authority():
			mesh.transparency = transparency
	else:
			mesh.transparency = transparency
