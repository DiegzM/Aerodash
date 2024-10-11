extends Node3D

@onready var fade = $Fade

@onready var title_screen = $TitleScreen

@onready var select_map = $SelectMap
@onready var select_map_container = select_map.get_node("ScrollContainer/GridContainer")
@onready var select_map_button_directory = "res://Assets/GUI/map_button.tscn"
@onready var select_map_thumbnail_directory = "res://Assets/Images/LevelThumbnails/"
@onready var selected_map = null

@onready var map_setup = $MapSetup
@onready var knockdowns_button = map_setup.get_node("Knockdowns")
@onready var meme_sounds_button = map_setup.get_node("MemeSounds")
@onready var knockdowns = knockdowns_button.button_pressed
@onready var meme_sounds = meme_sounds_button.button_pressed
@onready var disabled_color = Color(125,125,125)

@onready var maps = DirAccess.get_files_at("res://Levels/Maps")

@onready var game_start = false

var previous_gui = null
var current_gui = null
var next_gui = null
# Called when the node enters the scene tree for the first time.
func _ready():
	fade.visible = true
	fade.get_node("AnimationPlayer").play("fade_in")
	title_screen.visible = true
	current_gui = title_screen
	previous_gui = current_gui
	next_gui = current_gui
	
	initialize_select_map()
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass

func transition_to(gui):
	fade_out()
	next_gui = gui
	
func fade_out():
	fade.get_node("AnimationPlayer").play("fade_out")

func fade_in():
	fade.get_node("AnimationPlayer").play("fade_in")

# Title Screen

func _on_title_screen_play_pressed():
	transition_to(select_map)

# Select Map

func initialize_select_map():
	for map in maps:
		var map_path = "res://Levels/Maps/" + map
		var map_button_dir = load(select_map_button_directory)
		if map_button_dir:
			var map_button = map_button_dir.instantiate()
			var map_name = map.get_basename().replace("_", " ")
			var texture_button = map_button.get_node("TextureRect/TextureButton")
			
			texture_button.texture_normal = load(select_map_thumbnail_directory + map.get_basename() + ".png")
			map_button.get_node("Label").text = map_name
			select_map_container.add_child(map_button)

			texture_button.pressed.connect(Callable(self, "_on_map_button_pressed").bind(load(map_path)))
			
func _on_animation_player_animation_finished(anim_name):
	if game_start:
		if anim_name == "fade_out":
			Global.knockdowns = knockdowns
			Global.meme_sounds = meme_sounds
			get_tree().change_scene_to_packed(selected_map)
			
	else:
		if anim_name == "fade_out":
			current_gui.visible = false
			previous_gui = current_gui
			current_gui = next_gui
			current_gui.visible = true
			fade_in()
	
func _on_map_button_pressed(map):
	selected_map = map
	transition_to(map_setup)


func _on_back_button_back_pressed(gui):
	transition_to(gui)


func _on_knockdowns_toggled(toggled_on):
	knockdowns = toggled_on
	if not knockdowns:
		meme_sounds_button.disabled = true
		meme_sounds_button.button_pressed = false
		meme_sounds = false
		map_setup.get_node("MemeSoundsLabel").add_theme_color_override("font_color", Color(0.5,0.5,0.5))
	else:
		meme_sounds_button.disabled = false
		map_setup.get_node("MemeSoundsLabel").add_theme_color_override("font_color", Color(255,255,255))


func _on_meme_sounds_toggled(toggled_on):
	meme_sounds = toggled_on


func _on_map_setup_start_pressed():
	game_start = true
	fade_out()
