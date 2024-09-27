extends RigidBody3D

@onready var stream = $AudioStreamPlayer3D

var min_pitch = 0.0
var max_pitch = 5.0
var max_speed = 120

var velocity = Vector3.ZERO

func _ready():
	pass
	

func _physics_process(state):
	
	var speed = linear_velocity.length()
	print(speed)
	var normalized_speed = clamp(speed / max_speed, 0, 1)
	var pitch = lerp(min_pitch, max_pitch, normalized_speed)

	stream.pitch_scale = 1
