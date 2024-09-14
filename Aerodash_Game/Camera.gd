extends Camera3D

@export var offset_position: Vector3 = Vector3(0, 0.7, 5)  # Offset from the player's position
@export var offset_rotation: Vector3 = Vector3(0, 0, 0)

@export var max_fov = 130
@export var min_fov = 75
@export var max_fov_speed = 100

@export var fov_smoothness: float = 10  # Smoothness for the FOV change
@export var mouse_sensitivity = 0.3

@onready var target_position = global_transform
@onready var target_rotation = rotation_degrees

@onready var player: Node3D
@onready var previous_position: Vector3 = Vector3.ZERO
@onready var camera_speed: float = 0
@onready var in_game = true
@onready var mouse_delta: Vector2 = Vector2.ZERO
@onready var yaw: float = 0.0  # Left-right camera rotation
@onready var pitch: float = 0.0  # Up-down camera rotation

func _ready():
	player = get_parent().get_node("Player")
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

# Handle input events like mouse motion and toggling mouse lock
func _input(event):
	# Toggle between mouse captured and visible modes with ESC key
	if event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE:
		toggle_mouse_mode()
	
	# Capture mouse motion when the game is in focus (INGAME)
	if event is InputEventMouseMotion and in_game:
		mouse_delta = event.relative

# Toggle mouse mode between captured (for gameplay) and visible (for menus)
func toggle_mouse_mode():
	if Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
		in_game = false
	else:
		Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
		in_game = true
		
func _physics_process(delta):
	if player:
		yaw -= mouse_delta.x * mouse_sensitivity
		pitch = clamp(pitch - mouse_delta.y * mouse_sensitivity, -89, 89)

		var yaw_quat = Quaternion(Vector3(0, 1, 0), deg_to_rad(yaw))
		var pitch_quat = Quaternion(Vector3(1, 0, 0), deg_to_rad(pitch))
		var rotation_quat = yaw_quat * pitch_quat

		var rotated_offset = rotation_quat * offset_position

		global_transform.origin = player.global_transform.origin + rotated_offset
		look_at(player.global_position, Vector3.UP)

		camera_speed = global_transform.origin.distance_to(previous_position) / delta
		previous_position = global_transform.origin

		var target_fov = lerp(min_fov, max_fov, clamp(camera_speed / max_fov_speed, 0, 1))
		fov = lerp(fov, target_fov, fov_smoothness * delta)
