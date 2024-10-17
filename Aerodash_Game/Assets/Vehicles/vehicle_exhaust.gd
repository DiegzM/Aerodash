extends Node3D

@export var min_dissolve_length = 0.0
@export var max_dissolve_length = 0.5

var max_exhaust_speed = 200.0
var current_dissolve_length = min_dissolve_length

var body = null
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if body and body is BaseCharacter:
		for child in get_children():
			var shader_material = child.get_surface_override_material(0)
			if shader_material is ShaderMaterial:
				var clamped_speed = clamp(body.linear_velocity.length(), 0, max_exhaust_speed)
				var current_dissolve_length = lerp(min_dissolve_length, max_dissolve_length, clamped_speed / max_exhaust_speed)
				shader_material.set_shader_parameter("dissolve_length", current_dissolve_length)
