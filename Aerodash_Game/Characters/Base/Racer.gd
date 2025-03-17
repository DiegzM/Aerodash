class_name Racer

extends RigidBody3D

# -------------------------------------
# VARIABLES
# -------------------------------------

# Export Variables

@export var custom_vehicle: PackedScene
@export var randomize_vehicle_selection: bool = true

# Physics Settings

const ACCELERATION = 380.0
const MAX_SPEED = 60.0
const BOOST_SPEED = 100.0
const BOOST_MAX_TIME = 7.0
const BOOST_RECHARGE_RATE = 1.4
const MOVEMENT_DAMPING = 0.95
const ROTATION_SMOOTHNESS = 0.05
const LERP_VELOCITY = 0.05
const MAX_DOWNWARD_FACTOR = 1.6  # Speed increase when facing down
const MAX_UPWARD_FACTOR = 0.9    # Speed reduction when facing up
const ROLL_SPEED = 5.0
const ROLL_ACCELERATION = 10.0

# Onready Variables

enum RacerState {
	NORMAL,
	DEAD,
	RESPAWNING,
	DEACTIVATED
}

@onready var roll_direction = 0
@onready var current_roll_speed = 0.0

@onready var is_boosting = false
@onready var is_dashing = false
@onready var current_state = RacerState.NORMAL

@onready var collision_shape = $CollisionShape3D
@onready var target_pivot = $TargetPivot
@onready var vehicle_scenes: Array[PackedScene] = []
@onready var vehicle = $Vehicle

@onready var movement_direction = Vector3.ZERO
@onready var target_basis = target_pivot.global_transform.basis

# -------------------------------------
# INITIALIZATION
# -------------------------------------
func _ready() -> void:
	# Load Vehicle
	load_vehicle_scenes()
	load_vehicle()

# -------------------------------------
# UPDATE
# -------------------------------------
func _physics_process(delta: float) -> void:
	match current_state:
		RacerState.NORMAL:
			process_movement(delta)
			process_rotation(delta)
		RacerState.DEAD:
			pass
		RacerState.RESPAWNING:
			pass
	
# -------------------------------------
# VEHICLE MANAGEMENT
# -------------------------------------
func load_vehicle_scenes():
	var dir = DirAccess.open("res://Assets/Vehicles/CustomVehicles")
	if dir:
		dir.list_dir_begin()
		var file_name = dir.get_next()
		
		while file_name != "":
			if file_name.ends_with(".tscn"):
				var path = "res://Assets/Vehicles/CustomVehicles/" + file_name
				var scene = load(path)
				if scene:
					vehicle_scenes.append(scene)
			file_name = dir.get_next()
		dir.list_dir_end()
		
func load_vehicle():
	if (not custom_vehicle and not randomize_vehicle_selection) or vehicle_scenes.size() == 0:
		return
	
	var vehicle_scene: PackedScene
	if custom_vehicle:
		vehicle_scene = custom_vehicle
	elif randomize_vehicle_selection:
		var random_index = randi() % vehicle_scenes.size()
		vehicle_scene = vehicle_scenes[random_index]
	
	if is_instance_valid(vehicle):
		vehicle.queue_free()
	
	var new_vehicle = vehicle_scene.instantiate()
	new_vehicle.name = "Vehicle"
	add_child(new_vehicle)
	
	vehicle = new_vehicle

# -------------------------------------
# MOVEMENT
# -------------------------------------
func process_movement(delta: float) -> void:
	var current_max_speed = MAX_SPEED
	var current_acceleration = ACCELERATION
	
	angular_velocity = Vector3.ZERO
	
	if is_boosting:
		current_max_speed = BOOST_SPEED
		current_acceleration = ACCELERATION * (BOOST_SPEED / MAX_SPEED)
	
	var local_force = movement_direction * current_acceleration * (delta * 60)
	
	if movement_direction.x == 0:
		linear_velocity.x *= pow(MOVEMENT_DAMPING, delta * 60)
	if movement_direction.y == 0:
		linear_velocity.y *= pow(MOVEMENT_DAMPING, delta * 60)
	if movement_direction.z == 0:
		linear_velocity.z *= pow(MOVEMENT_DAMPING, delta * 60)
	
	var speed = linear_velocity.length()
	if speed > current_max_speed:
		var target_velocity = linear_velocity.normalized() * current_max_speed
		linear_velocity = lerp(linear_velocity, target_velocity, LERP_VELOCITY)
	
	apply_force(local_force)
	

# -------------------------------------
# ROTATION
# -------------------------------------
func process_rotation(delta: float) -> void:
	
	angular_velocity = Vector3.ZERO
	
	var preserved_pivot_transform = target_pivot.global_transform
	var current_rotation = global_rotation
	var target_rotation = target_pivot.global_rotation
	
	current_rotation.x = lerp_angle(current_rotation.x, target_rotation.x, ROTATION_SMOOTHNESS)
	current_rotation.y = lerp_angle(current_rotation.y, target_rotation.y, ROTATION_SMOOTHNESS)
	current_rotation.z = lerp_angle(current_rotation.z, target_rotation.z, ROTATION_SMOOTHNESS)
	
	global_rotation = current_rotation
	
	target_pivot.global_transform = preserved_pivot_transform
	
	# ROLL
	var target_roll_speed = ROLL_SPEED * -roll_direction * delta
	current_roll_speed = lerp(current_roll_speed, target_roll_speed, ROLL_ACCELERATION * delta)
	
	if abs(current_roll_speed) > 0.001:
		target_pivot.rotate_object_local(Vector3.FORWARD, current_roll_speed)
	
# -------------------------------------
# PUBLIC SET FUNCTIONS
# -------------------------------------

func set_state(state: RacerState) -> void:
	current_state = state
	
func set_movement_direction(direction: Vector3) -> void:
	movement_direction = direction
	
func set_boost(enabled: bool) -> void:
	is_boosting = enabled

func set_roll(direction) -> void:
	roll_direction = direction
