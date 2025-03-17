extends Racer

# -------------------------------------
# VARIABLES
# -------------------------------------

# Settings

const MOUSE_SENSITIVITY= 0.3

const FCAM_MIN_FOV = 85
const FCAM_MAX_FOV = 140
const BCAM_MIN_FOV = 85
const BCAM_MAX_FOV = 110
const FOV_SMOOTHNESS = 10
const CAM_POSITION_DAMPING = 0.2
const CAM_OFFSET_STRENGTH = 0.008

# Onready Variables

@onready var fcam = target_pivot.get_node("FCamera")
@onready var bcam = target_pivot.get_node("BCamera")
@onready var fcam_base_transform = fcam.transform
@onready var bcam_base_transform = fcam.transform
@onready var velocity_offset = Vector3.ZERO

@onready var mouse_button_pressed = false
@onready var mouse_delta = Vector2.ZERO

# -------------------------------------
# INITIALIZE
# -------------------------------------
func _ready() -> void:
	super._ready()
	
	# Set the GUI to lock mouse in place
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

# -------------------------------------
# INPUT
# -------------------------------------
func _input(event) -> void:
	if event is InputEventMouseMotion:
		mouse_delta = event.relative
	if event is InputEventMouseButton:
		mouse_button_pressed = event.is_pressed()

# -------------------------------------
# UPDATE
# -------------------------------------
func _physics_process(delta: float) -> void:
	super._physics_process(delta)
	
	match current_state:
		RacerState.NORMAL:
			process_keyboard_input()
			process_mouse_input()
	
	process_cameras(delta)
		
	
# -------------------------------------
# INPUTS
# -------------------------------------
func process_keyboard_input() -> void:
	var direction = Vector3.ZERO
	
	# Movements
	if Input.is_action_pressed("move_forward"):
		direction += target_pivot.global_transform.basis.z
	if Input.is_action_pressed("move_backward"):
		direction -= target_pivot.global_transform.basis.z
	if Input.is_action_pressed("move_left"):
		direction += target_pivot.global_transform.basis.x
	if Input.is_action_pressed("move_right"):
		direction -= target_pivot.global_transform.basis.x
	if Input.is_action_pressed("move_up"):
		direction += target_pivot.global_transform.basis.y
	if Input.is_action_pressed("move_down"):
		direction -= target_pivot.global_transform.basis.y
	
	# Roll
	if Input.is_action_pressed("roll_right") and not Input.is_action_pressed("roll_left"):
		set_roll(1)
	elif Input.is_action_pressed("roll_left") and not Input.is_action_pressed("roll_right"):
		set_roll(-1)
	elif not roll_direction == 0:
		set_roll(0)

	set_movement_direction(direction.normalized())

func process_mouse_input() -> void:
	var pitch_delta = deg_to_rad(mouse_delta.y * MOUSE_SENSITIVITY)
	var yaw_delta = deg_to_rad(-mouse_delta.x * MOUSE_SENSITIVITY)

	target_pivot.rotate_object_local(Vector3.UP, yaw_delta)
	target_pivot.rotate_object_local(Vector3.RIGHT, pitch_delta)
	
	# Reset mouse delta
	mouse_delta = Vector2.ZERO
	
	# Boost
	if Input.is_action_just_pressed("boost"):
		set_boost(true)
	elif Input.is_action_just_released("boost"):
		set_boost(false)
		

# -------------------------------------
# CAMERA EFFECTS
# -------------------------------------
func process_cameras(delta) -> void:
	
	# FOV
	var fcam_target_fov = lerp(FCAM_MIN_FOV, FCAM_MAX_FOV, clamp(linear_velocity.length() / BOOST_SPEED, 0, 1))
	var bcam_target_fov = lerp(BCAM_MIN_FOV, BCAM_MAX_FOV, clamp(linear_velocity.length() / BOOST_SPEED, 0, 1))
	
	fcam.fov = lerp(fcam.fov, fcam_target_fov, FOV_SMOOTHNESS * delta)
	bcam.fov = lerp(bcam.fov, bcam_target_fov, FOV_SMOOTHNESS * delta)
	
	# Position Damping
	var target_offset = global_transform.basis.inverse() * -linear_velocity * CAM_OFFSET_STRENGTH
	
	velocity_offset = velocity_offset.lerp(target_offset, CAM_POSITION_DAMPING)
	var fcam_target_position = fcam_base_transform.origin + velocity_offset
	var bcam_target_position = bcam_base_transform.origin + velocity_offset
	
	fcam.transform.origin = fcam_target_position
	bcam.transform.origin = bcam_target_position
