extends Node

var knockdowns = true
var meme_sounds = true

var random_names = []
# Called when the node enters the scene tree for the first time.
func _ready():
	load_names_from_file()

func _input(event):
	pass
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass

func load_names_from_file():
	var file = FileAccess.open("res://Scripts/names.txt", FileAccess.READ)
	if file:
		while not file.eof_reached():
			var name = file.get_line().strip_edges()  # Get each line and remove extra whitespace
			if name != "":
				random_names.append(name)  # Add each name to the list
		file.close()
	else:
		print("Error: Unable to open names.txt")

# Optional function to get a random name from the list
func get_random_name() -> String:
	if random_names.size() > 0:
		return random_names[randi() % random_names.size()]
	return "No names available"
