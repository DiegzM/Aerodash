extends Node3D

var AI = null
# Called when the node enters the scene tree for the first time.
func _ready():
	AI = get_parent().get_node("AI")
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	global_transform = AI.global_transform
