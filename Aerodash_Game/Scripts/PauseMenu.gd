extends Control

@onready var paused = get_parent().paused
@onready var main_menu_dir = "res://Levels/Main.tscn"

var go_to = ""
var pause_menu_pressed = false
# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.
func _input(event):
	if event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE:
		toggle_pause()
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass

func toggle_pause():
	paused = !paused
	if paused:
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
		get_tree().paused = true
		visible = true
	else:
		Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
		get_tree().paused = false
		visible = false
		
func fade_out():
	get_parent().get_node("Fade/AnimationPlayer").play("fade_out")
	
func _on_animation_player_animation_finished(anim_name):
	if anim_name == "fade_out":
		if go_to == "exit":
			get_tree().quit()
		elif go_to == "restart":
			toggle_pause()
			get_tree().reload_current_scene()  # Reload the scene from scratch
		elif pause_menu_pressed:
			toggle_pause()
			get_tree().change_scene_to_packed(load(go_to))

func _on_resume_pressed():
	toggle_pause()
	
func _on_restart_pressed():
	go_to = "restart"
	fade_out()

func _on_main_menu_pressed():
	pause_menu_pressed = true
	go_to = main_menu_dir
	fade_out()

func _on_exit_game_pressed():
	go_to = "exit"
	fade_out()
