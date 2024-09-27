extends Control

@onready var race_manager = get_tree().current_scene.get_node("RaceManager")
@onready var player = get_parent().get_node("Player")

var place = 0
var racer_count = 0

var min_pitch = 0.9
var max_pitch = 2.0

var elapsed_time = 0.0
# Called when the node enters the scene tree for the first time.
func _ready():
	pass

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	update_text(delta)
	update_wind(delta)
	update_timer(delta)

func update_text(delta):
	place = race_manager.get_place(player)
	racer_count = race_manager.get_racer_count()
	$PlaceGui/Place.text = str(place)
	$PlaceGui/PlaceRacerCount.text = str(racer_count)
	$LapGui/LapCount.text = str(player.lap)

func update_wind(delta):
	var player_speed = player.linear_velocity.length()
	var max_speed = player.MAX_SPEED.length()
	var normalized_speed = clamp(player_speed / max_speed, 0, 1)
	var pitch = lerp(min_pitch, max_pitch, normalized_speed)
	
	$Wind.pitch_scale = pitch

func update_timer(delta):
	elapsed_time += delta
	
	var minutes = int(elapsed_time / 60)
	var seconds = int(elapsed_time) % 60
	var centiseconds = int((elapsed_time - int(elapsed_time)) * 100)
	
	var time_text = "%02d:%02d:%02d" % [minutes, seconds, centiseconds]

	$TimerGui/Timer.text = time_text
