extends Sprite3D

var timer = 0.1
var current_timer = timer
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if visible:
		if current_timer <= 0 and modulate.a == 0:
			current_timer = timer
			modulate.a = 1
		elif current_timer <= 0 and modulate.a == 1:
			current_timer = timer
			modulate.a = 0
		current_timer -= delta
