class_name Racer

extends RigidBody3D

@export var custom_vehicle: PackedScene
@export var randomize_vehicle_selection: bool = true

@onready var collision_shape = $CollisionShape3D

@onready var target_pivot = $TargetPivot

@onready var vehicle_scenes: Array[PackedScene] = []
@onready var vehicle = $Vehicle

func _ready() -> void:
	#Load Vehicle
	load_vehicle_scenes()
	load_vehicle()
	
func load_vehicle_scenes():
	var dir = DirAccess.open("res://Assets/Vehicles/CustomVehicles")
	if dir:
		dir.list_dir_begin()
		var file_name = dir.get_next()
		
		while file_name != "":
			if file_name.ends_with(".tscn"):
				var path = "res://Assets/Vehicles/CustomVehicles/" + file_name
				var scene = load(path)
				if scene:
					vehicle_scenes.append(scene)
			file_name = dir.get_next()
		dir.list_dir_end()
		
func load_vehicle():
	# Skip if we should keep the default vehicle
	if (not custom_vehicle and not randomize_vehicle_selection) or vehicle_scenes.size() == 0:
		return
	
	# Determine which vehicle to load
	var vehicle_scene: PackedScene
	if custom_vehicle:
		vehicle_scene = custom_vehicle
	elif randomize_vehicle_selection:
		var random_index = randi() % vehicle_scenes.size()
		vehicle_scene = vehicle_scenes[random_index]
	
	# Replace vehicle
	if is_instance_valid(vehicle):
		vehicle.queue_free()
	
	var new_vehicle = vehicle_scene.instantiate()
	new_vehicle.name = "Vehicle"
	add_child(new_vehicle)
	
	# Update reference to the new vehicle
	vehicle = new_vehicle

func _process(delta: float):
	pass
