extends Node3D

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass

func _on_gate_pass_body_entered(body):
	if body is BaseCharacter:
		body.on_section_passed(self, true)


func _on_gate_miss_body_entered(body: Node3D) -> void:
	if body is BaseCharacter:
		body.on_section_passed(self, false)
