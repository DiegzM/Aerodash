extends RigidBody3D

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _integrate_forces(state):
	var local_force = calculate_forces(state)
	apply_force(local_force)
	
func calculate_forces(state) -> Vector3:
	var local_force = Vector3.ZERO
	var gravity = -ProjectSettings.get_setting("physics/3d/default_gravity")

	# Apply antigravity force if not falling
	if not Input.is_action_pressed("fall"):
		local_force += Vector3(0, -gravity, 0)

	return local_force
