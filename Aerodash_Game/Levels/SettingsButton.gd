extends TextureButton

@export var go_to_gui: Control

signal settings_pressed(gui)
# Called when the node enters the scene tree for the first time.
func _ready():
	pass
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass

func _on_mouse_entered():
	self.modulate = Color(3.0, 3.0, 3.0) # Brighten on hover


func _on_mouse_exited():
	self.modulate = Color(1, 1, 1) # Reset to normal


func _on_pressed():
	emit_signal("settings_pressed", go_to_gui)
	self.modulate = Color(0.5, 0.5, 0.5) # Darken on clicks
