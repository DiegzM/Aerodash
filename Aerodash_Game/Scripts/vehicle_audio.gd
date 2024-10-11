extends Node3D

@onready var stream = $AudioStreamPlayer3D
@onready var crash_sound = $CrashSound
@onready var meme_crash_sound = $MemeCrashSound

@export var min_pitch = 0.25
@export var pitch_sensitivity = 0.006
@export var max_speed = 120

var velocity = Vector3.ZERO
var body: RigidBody3D = null

var current_pitch = min_pitch
var lerp_factor = 0.03

var crash_sound_played = false

var meme_crash_sounds = DirAccess.get_files_at("res://Assets/Audio/MemeCrashSounds")

var level_manager = null

func _ready():
	stream.pitch_scale = min_pitch
	if get_tree().current_scene is Level:
		level_manager = get_tree().current_scene

func _physics_process(delta):
	if body:
		var velocity = body.linear_velocity
		var speed = velocity.length()
		
		var target_pitch = 0
		# Calculate the target pitch based on speed
		if body is BaseCharacter:
			if body.dead:
				target_pitch = min_pitch
				play_crash_sound(true)
			else:
				play_crash_sound(false)
				target_pitch = min_pitch + (speed * pitch_sensitivity)
		
		# Use lerp to smoothly transition from current_pitch to target_pitch
		current_pitch = lerp(current_pitch, target_pitch, lerp_factor)
		
		# Apply the smoothly changing pitch to the stream
		stream.pitch_scale = current_pitch

func play_crash_sound(state):
	if state:
		if not crash_sound_played:
			crash_sound.playing = true
			if level_manager and level_manager.meme_sounds:
				random_meme_crash_sound()
				meme_crash_sound.playing = true
			crash_sound_played = true
	else:
		crash_sound.playing = false
		if level_manager and level_manager.meme_sounds:
			meme_crash_sound.playing = false
		crash_sound_played = false

func random_meme_crash_sound():
	
	var valid_files = []
	for file in meme_crash_sounds:
		if file.ends_with(".mp3") or file.ends_with(".wav") or file.ends_with(".ogg"):
			valid_files.append(file)
			
	if valid_files.size() > 0:
		var random_file = valid_files[randi() % valid_files.size()]
		var resource = load("res://Assets/Audio/MemeCrashSounds/" + random_file)
		if resource:
			meme_crash_sound.stream = resource
		else:
			print("Error: Could not load the selected audio.")
