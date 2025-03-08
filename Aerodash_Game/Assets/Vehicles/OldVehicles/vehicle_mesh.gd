extends MeshInstance3D

@export var primary: int = 0  # Material override index
@export var base_color: Color = Color(1.0, 1.0, 1.0)  # Base color for the theme
@export var variation_range: float = 0.6  # Range for color variation

# Called when the node enters the scene tree for the first time.
func _ready():
	apply_color()

func apply_color():
	# Generate a single random factor within the range, to keep colors proportional
	var factor = 1.0 + randf_range(-variation_range, variation_range)

	# Apply the factor to each color channel of the base color, clamping between 0.0 and 1.0
	var random_color = Color(
		clamp(base_color.r * factor, 0.0, 1.0),
		clamp(base_color.g * factor, 0.0, 1.0),
		clamp(base_color.b * factor, 0.0, 1.0)
	)
	
	if primary >= 0 and primary < mesh.get_surface_count():
		# Get or duplicate the current material
		var material = get_surface_override_material(primary)
		
		# Ensure the material is unique for this instance
		if material:
			material = material.duplicate()  # Duplicate the existing material
		else:
			material = StandardMaterial3D.new()  # Create a new one if none exists
			
		# Set this unique material as the override for this instance
		set_surface_override_material(primary, material)
		
		# Apply the theme-based proportional color to the material's albedo
		material.albedo_color = random_color
func _process(delta):
	pass
