extends Node3D

@export var max_fov = 140
@export var min_fov = 75
@export var max_fov_speed = 180

@export var fov_smoothness: float = 10  # Smoothness for the FOV change
@export var max_shake_magnitude: float = 0.1
@export var collision_shake_magnitude: float = 1.8
@export var collision_shake_magnitude_damping: float = 0.04
@export var collision_shake_fov: float = 5
@export var collision_shake_fov_damping: float = 0.1

@export var camera_position_damping: float = 0.2
@export var velocity_offset_strength: float = 0.004  # Controls how far back the camera drifts based on velocity

@export var mouse_sensitivity: float = 0.3

@onready var current_roll_speed: float = 0.0  # Variable to track the current roll speed
@onready var current_collision_shake_magnitude: float = collision_shake_magnitude
@onready var current_collision_fov: float = collision_shake_fov
@onready var velocity_offset = Vector3.ZERO
@onready var knocking_down = false
@onready var camera = $Camera
@onready var player = get_parent().get_node("Player")
@onready var level_manager = get_tree().current_scene
@onready var characters = level_manager.characters
@onready var speed = 0.0
@onready var in_game = true
@onready var controls_disabled = false
@onready var mouse_delta = Vector2.ZERO
@onready var previous_position = global_transform.origin
@onready var previous_camera_position = camera.transform.origin
@onready var shake_offset = Vector3.ZERO
@onready var camera_initial_orientation: Basis
@onready var debug = false

func _ready():
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	camera_initial_orientation = camera.transform.basis

# Handle input events like mouse motion and toggling mouse lock
func _input(event):
	if event is InputEventMouseMotion and in_game and not controls_disabled:
		mouse_delta = event.relative

# Toggle mouse mode between captured (for gameplay) and visible (for menus)
		
func _physics_process(delta):
	if get_tree().current_scene.has_node("DebugCamera"):
		var debug_camera = get_tree().current_scene.get_node("DebugCamera")
		if debug_camera.debug:
			debug = true
		else:
			debug = false
	
	if not debug:
		if not player.dead:
			global_transform.origin = player.global_transform.origin
			camera.transform.basis = camera_initial_orientation
			apply_fov(delta)
			apply_rotation(delta)
			apply_camera_shake(delta)
			apply_camera_position_damping(delta)
			if player.knockdown or knocking_down:
				if not knocking_down:
					knocking_down = true
				if knocking_down and current_collision_shake_magnitude <= 0:
					knocking_down = false
				apply_collision_camera_shake(delta)
			else:
				current_collision_shake_magnitude = collision_shake_magnitude
				current_collision_fov = collision_shake_fov
		else:
			camera.look_at(player.global_transform.origin)
			apply_collision_camera_shake(delta)
		if controls_disabled:
			Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
		
func apply_fov(delta):
	var current_position = global_transform.origin
	speed =	player.linear_velocity.length()
	previous_position = current_position 
	
	var target_fov = lerp(min_fov, max_fov, clamp(speed / max_fov_speed, 0, 1))
	camera.fov = lerp(camera.fov, target_fov, fov_smoothness * delta)

func apply_rotation(delta):
	if level_manager.race_started:
		var pitch_delta = deg_to_rad(-mouse_delta.y * mouse_sensitivity)
		var yaw_delta = deg_to_rad(-mouse_delta.x * mouse_sensitivity)

		rotate_object_local(Vector3.UP, yaw_delta)

		var x_axis = global_transform.basis.x.normalized()
		global_transform.basis = Basis(x_axis, pitch_delta) * global_transform.basis

		mouse_delta = Vector2.ZERO

func apply_camera_position_damping(delta):
	var player_velocity = player.linear_velocity
	var target_offset = -player_velocity * velocity_offset_strength
	
	velocity_offset = velocity_offset.lerp(target_offset, camera_position_damping)
	var target_position = camera.global_transform.origin + velocity_offset
	camera.global_transform.origin = target_position
	
func apply_camera_shake(delta):
	# Reset camera position to the previous position before adding shake
	camera.transform.origin = previous_camera_position

	var shake_strength = clamp(speed / max_fov_speed, 0, 1) * max_shake_magnitude

	var target_shake_offset = Vector3(
		randf_range(-shake_strength, shake_strength),
		randf_range(-shake_strength, shake_strength),
		0
	)
	
	camera.transform.origin += target_shake_offset

func apply_collision_camera_shake(delta):
	camera.transform.origin = previous_camera_position

	var shake_strength = clamp(speed / max_fov_speed, 0, 1) * current_collision_shake_magnitude

	var target_shake_offset = Vector3(
		randf_range(-shake_strength, shake_strength),
		randf_range(-shake_strength, shake_strength),
		0
	)
	var target_fov = randf_range(camera.fov - current_collision_fov, camera.fov + current_collision_fov)
	camera.fov = target_fov
	
	if current_collision_fov > 0:
		current_collision_fov -= collision_shake_fov_damping
		
	if current_collision_shake_magnitude > 0:
		current_collision_shake_magnitude -= collision_shake_magnitude_damping

	previous_camera_position = camera.transform.origin
	camera.transform.origin += target_shake_offset
