extends Node3D

@onready var stream = $AudioStreamPlayer3D

var min_pitch = 0.50
var pitch_sensitivity = 0.007
var max_speed = 120

var velocity = Vector3.ZERO
var body: RigidBody3D = null

var current_pitch = min_pitch
var lerp_factor = 0.03

func _ready():
	stream.pitch_scale = min_pitch

func _physics_process(delta):
	if body:
		var velocity = body.linear_velocity
		var speed = velocity.length()
		
		# Calculate the target pitch based on speed
		var target_pitch = min_pitch + (speed * pitch_sensitivity)
		
		# Use lerp to smoothly transition from current_pitch to target_pitch
		current_pitch = lerp(current_pitch, target_pitch, lerp_factor)
		
		# Apply the smoothly changing pitch to the stream
		stream.pitch_scale = current_pitch
