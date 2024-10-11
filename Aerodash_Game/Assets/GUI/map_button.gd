extends Control

@export var directory = ""
@export var image: ImageTexture

@onready var rect = $TextureRect
@onready var button = $TextureRect/TextureButton
@onready var label = $Label

var target_scale = 0.9
var scale_smooth = 0.1

func _ready():
	if image:
		button.texture_normal = image


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	lerp_scale()
	
func lerp_scale():
	rect.scale = lerp(rect.scale, Vector2(target_scale, target_scale), scale_smooth)

func _on_texture_button_mouse_entered():
	target_scale = 1.0
	button.modulate = Color(1.8, 1.8, 1.8)

func _on_texture_button_mouse_exited():
	target_scale = 0.9
	button.modulate = Color(1.0, 1.0, 1.0)


func _on_texture_button_pressed():
	button.modulate = Color(0.5, 0.5, 0.5)
