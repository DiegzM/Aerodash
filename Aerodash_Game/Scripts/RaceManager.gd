extends Node3D

########## RACE DEFAULT SETTINGS (Change in Inspector specific to map) ##############

@export var countdown_timer = 5

@export var laps = 3

#####################################################################################

var race_started = false

var characters: Array = []
# Called when the node enters the scene tree for the first time.
func _ready():
	find_characters(get_parent())
	pass

func find_characters(node: Node):
	if node is BaseCharacter and node.name != "BaseCharacter":
		characters.append(node)
	
	for child in node.get_children():
		find_characters(child)
		
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	update_places(delta)
	if not race_started:
		update_countdown_timer(delta)

func update_countdown_timer(delta):
	countdown_timer -= delta
	if countdown_timer <= 0:
		race_started = true
		
func update_places(delta):
	characters.sort_custom(compare_positions)

func compare_positions(a, b):
	# Sort by lap
	if a.lap > b.lap:
		return true
	elif a.lap < b.lap:
		return false
	# If theyre both same lap, then sort by section
	var a_section = a.current_section_index
	var b_section = b.current_section_index
	
	if a_section > b_section:
		return true
	elif a_section < b_section:
		return false
		
	# If theyre both same lap and same section, then sort by closest proximity to next_gate
	# RIGHT NOW its getting closest point to the gate's center, which isn't ideal
	var a_distance = a.global_transform.origin.distance_to(a.next_gate.global_transform.origin)
	var b_distance = b.global_transform.origin.distance_to(b.next_gate.global_transform.origin)
	
	if a_distance < b_distance:
		return true
	elif a_distance > b_distance:
		return false
	
	# Lower instance ID is lucky!
	if a.get_instance_id() < b.get_instance_id():
		return true
	elif a.get_instance_id() > b.get_instance_id():
		return false

func get_place(character):
	for i in range(characters.size()):
		if characters[i] == character:
			return i + 1
	return -1
	
func get_racer_count():
	return characters.size()
