extends Node3D

@onready var stream = $AudioStreamPlayer3D
@onready var crash_sound = $CrashSound

@export var min_pitch = 0.25
@export var pitch_sensitivity = 0.006
@export var max_speed = 120

var velocity = Vector3.ZERO
var body: RigidBody3D = null

var current_pitch = min_pitch
var lerp_factor = 0.03

var crash_sound_played = false

func _ready():
	stream.pitch_scale = min_pitch

func _physics_process(delta):
	if body:
		var velocity = body.linear_velocity
		var speed = velocity.length()
		
		var target_pitch = 0
		# Calculate the target pitch based on speed
		if body is BaseCharacter:
			if body.dead:
				target_pitch = min_pitch
				play_crash_sound()
			else:
				crash_sound_played = false
				target_pitch = min_pitch + (speed * pitch_sensitivity)
		
		# Use lerp to smoothly transition from current_pitch to target_pitch
		current_pitch = lerp(current_pitch, target_pitch, lerp_factor)
		
		# Apply the smoothly changing pitch to the stream
		stream.pitch_scale = current_pitch

func play_crash_sound():
	if not crash_sound_played:
		crash_sound.playing = true
		crash_sound_played = true
