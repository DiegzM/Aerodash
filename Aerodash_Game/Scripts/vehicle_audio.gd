extends Node3D

@onready var stream = $AudioStreamPlayer3D
@onready var crash_sound = $CrashSound
@onready var fake_crash_sound = $FakeCrashSound

@export var min_pitch = 0.25
@export var pitch_sensitivity = 0.006
@export var max_speed = 120

var velocity = Vector3.ZERO
var body: RigidBody3D = null

var current_pitch = min_pitch
var lerp_factor = 0.03

var crash_sound_played = false

var random_fake_crash_sounds = [
	"res://Audio/crash_1.mp3",
	"res://Audio/crash_2.mp3",
	"res://Audio/crash_3.mp3",
	"res://Audio/crash_4.mp3",
	"res://Audio/crash_5.mp3",
	"res://Audio/crash_6.mp3",
	"res://Audio/crash_7.mp3",
	"res://Audio/crash_8.mp3",
	"res://Audio/crash_9.mp3",
	"res://Audio/crash_10.mp3",
	"res://Audio/crash_11.mp3",
	"res://Audio/crash_12.mp3",
	"res://Audio/crash_13.mp3",
	"res://Audio/crash_14.mp3",
	"res://Audio/crash_15.mp3"
]

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
				crash_sound.playing = false
				fake_crash_sound.playing = false
				target_pitch = min_pitch + (speed * pitch_sensitivity)
		
		# Use lerp to smoothly transition from current_pitch to target_pitch
		current_pitch = lerp(current_pitch, target_pitch, lerp_factor)
		
		# Apply the smoothly changing pitch to the stream
		stream.pitch_scale = current_pitch

func play_crash_sound():
	if not crash_sound_played:
		crash_sound.playing = true
		choose_random_fake_crash_sound()
		fake_crash_sound.playing = true
		crash_sound_played = true

func choose_random_fake_crash_sound():
	if random_fake_crash_sounds.size() > 0:
		randomize()  # Randomize the seed
		var random_index = randi() % random_fake_crash_sounds.size()  # Get random index
		var selected_audio = load(random_fake_crash_sounds[random_index])  # Use load() instead of preload()
		
		if selected_audio:
			fake_crash_sound.stream = selected_audio
		else:
			print("Error: Could not load the selected vehicle scene.")
