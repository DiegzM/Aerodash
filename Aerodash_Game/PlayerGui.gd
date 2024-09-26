extends Control

@onready var race_manager = get_tree().current_scene.get_node("RaceManager")
@onready var player = get_parent().get_node("Player")

var place = 0
var racer_count = 0
# Called when the node enters the scene tree for the first time.
func _ready():
	pass

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	place = race_manager.get_place(player)
	racer_count = race_manager.get_racer_count()
	$PlaceGui/Place.text = str(place)
	$PlaceGui/PlaceRacerCount.text = str(racer_count)
	$LapGui/LapCount.text = str(player.lap)
