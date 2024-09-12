extends Camera3D

var smoothness: float = 5.0
var current_rotation: Basis

func _ready():
	current_rotation = global_transform.basis

func _process(delta: float):
	var parent_rigid_body = get_parent()
	var target_rotation = parent_rigid_body.global_transform.basis

	current_rotation = current_rotation.slerp(target_rotation, delta * smoothness)
	global_transform.basis = current_rotation
