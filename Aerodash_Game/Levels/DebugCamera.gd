extends Camera3D

var debug = false
var player_interface: Node = null

var min_speed := 1.0
var max_speed := 400.0
var speed := 10.0  # Starting speed
var mouse_sensitivity = 0.3
var scroll_speed_increment = 4
var boost_speed_multiplier = 2  # Movement speed
var sensitivity := 0.1  # Mouse sensitivity for rotation
var target_velocity := Vector3.ZERO
var current_velocity := Vector3.ZERO
var current_target_speed = speed
var lerp_speed := 5.0  # Speed of the smooth interpolation

var max_vertical_angle := 89.0  # Prevent camera from looking fully up or down
var min_vertical_angle := -89.0

var in_game = true
var mouse_delta = Vector2.ZERO
var yaw := 0.0
var pitch := 0.0

func _ready():
	player_interface = get_tree().current_scene.get_node("PlayerInterface")
	yaw = rotation_degrees.y
	pitch = rotation_degrees.x
	fov = 100

	current = false

func _input(event):
	if event is InputEventMouseButton:
	# Check if the mouse wheel is scrolled up
		if event.button_index == MOUSE_BUTTON_WHEEL_UP:
			speed += scroll_speed_increment
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			speed -= scroll_speed_increment
	if event is InputEventMouseMotion:
		mouse_delta = event.relative
		
	speed = clamp(speed, min_speed, max_speed)
	
	if event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE:
		toggle_mouse_mode()


# Toggle mouse mode between captured (for gameplay) and visible (for menus)
func toggle_mouse_mode():
	if in_game:
		in_game = false
	else:
		in_game = true
	
func _process(delta):
	if Input.is_action_just_pressed("debug"):
		debug = not debug
	
	if debug:
		player_interface.get_node("PlayerGui").visible = false
		current = true
		debug_camera_movement(delta)
	else:
		player_interface.get_node("PlayerGui").visible = true
		global_transform.origin = player_interface.get_node("Player").global_transform.origin
		current = false

func debug_camera_movement(delta):
	if in_game:
		var direction := Vector3.ZERO
		
		if Input.is_action_pressed("move_forward"):
			direction.z -= 1
		if Input.is_action_pressed("move_backward"):
			direction.z += 1
		if Input.is_action_pressed("move_left"):
			direction.x -= 1
		if Input.is_action_pressed("move_right"):
			direction.x += 1
		if Input.is_action_pressed("move_up"):
			direction.y += 1
		if Input.is_action_pressed("move_down"):
			direction.y -= 1
		
		direction = direction.normalized()
		
		var current_target_speed = speed

		if Input.is_key_pressed(KEY_SHIFT):
			current_target_speed *= boost_speed_multiplier
			
		target_velocity = direction * speed
		current_velocity = current_velocity.lerp(target_velocity, lerp_speed * delta)
		
		translate(current_velocity * delta)
		
		yaw -= mouse_delta.x * mouse_sensitivity
		pitch -= mouse_delta.y * mouse_sensitivity

		# Clamp pitch to prevent looking too far up or down
		pitch = clamp(pitch, -90.0, 90.0)

		# Apply rotation
		rotation_degrees = Vector3(pitch, yaw, 0)

		# Reset mouse delta
		mouse_delta = Vector2.ZERO
