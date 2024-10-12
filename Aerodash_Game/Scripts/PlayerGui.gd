extends Control

@onready var level_manager = get_tree().current_scene
@onready var player = get_parent().get_node("Player")
@onready var pivot = get_parent().get_node("CameraPivot")

@onready var final_leaderboard_row = "res://Assets/GUI/final_leaderboard_row.tscn"

var added_characters = []

var place = 0
var racer_count = 0

var min_pitch = 0.9
var pitch_sensitivity = 0.2

var knockdown_text_timer = 2
var current_knockdown_text_timer = 0

var final_leaderboard_timer = 3.0

var race_started

var prev_dead = false
# Called when the node enters the scene tree for the first time.
func _ready():
	pass

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	update_text(delta)
	update_wind(delta)
	update_knockdown(delta)
	update_final_leaderboard(delta)
	
	if not race_started:
		update_countdown(delta)
	elif not player.race_finished:
		update_stopwatch(delta)
	
	if player.race_finished:
		if final_leaderboard_timer <= 0:
			if not $RaceFinishedGui.visible:
				update_center_text("", "All", delta)
				$RaceFinishedGui.visible = true
				pivot.controls_disabled = true
		else:
			update_center_text(get_place_suffix(player.final_place + 1) + " PLACE!", "MedTop", delta)
			update_center_text("RACE FINISHED!", "Bottom", delta)
			$LeaderboardGui.visible = false
			$RaceFinishedGui/PlaceValue.text = get_place_suffix(player.final_place + 1)
			$RaceFinishedGui/Time.text = "Time: " + get_formatted_time(player.elapsed_time)
			if final_leaderboard_timer > 0:
				final_leaderboard_timer -= delta
	
	if not player.dead and prev_dead:
		prev_dead = false
		update_center_text("", "All", delta)
		
	if player.dead:
		update_respawn_countdown(delta)
		
func update_text(delta):
	place = level_manager.get_place(player)
	racer_count = level_manager.get_racer_count()
	$PlaceGui/Place.text = str(place)
	$PlaceGui/PlaceRacerCount.text = str(racer_count)
	$LapGui/LapCount.text = str(player.lap)
	$BoostGui/BoostBar.value = clamp(player.current_boost_time/player.MAX_BOOST_TIME, 0, 1)
	update_leaderboard(delta)
	
func update_leaderboard(delta):
	var leaderboard_gui = $LeaderboardGui
	var leaderboard = leaderboard_gui.get_node("ScrollContainer/VBoxContainer")
	var characters = level_manager.get_characters()
	
	for i in range(characters.size()):
		if i >= leaderboard.get_child_count():
			var row = leaderboard_gui.get_node("Row").duplicate()
			leaderboard.add_child(row)
			leaderboard.get_child(i).text = str(characters[i].name)
		else:
			leaderboard.get_child(i).text = str(characters[i].name)
		var current_row = leaderboard.get_child(i)
		if characters[i] == player:
			current_row.text = str(characters[i].name)
			current_row.modulate = Color(1, 1, 1, 1) 
		else:
			current_row.text = str(characters[i].name)
			current_row.modulate = Color(0.8, 0.8, 0.8, 0.5)
			
					
	if leaderboard_gui.has_node("Row"):
		var row = leaderboard_gui.get_node("Row")
		leaderboard_gui.remove_child(row)
		row.queue_free()

func update_final_leaderboard(delta):
	var race_finished_gui = $RaceFinishedGui
	var final_leaderboard_container = race_finished_gui.get_node("ScrollContainer/VBoxContainer")
	
	for character in level_manager.final_leaderboard:
		if character and character.final_place != -1 and character not in added_characters:
			var row = load(final_leaderboard_row).instantiate()
			row.get_node("Place").text = str(character.final_place + 1)
			row.get_node("Name").text = character.name
			row.get_node("Knockdowns").text = str(character.total_knockdowns)
			row.get_node("Deaths").text = str(character.total_deaths)
			row.get_node("Time").text = get_formatted_time(character.elapsed_time)
			
			if character == player:
				for child in row.get_children():
					if child is Label:
						child.modulate = Color(3.0, 3.0, 3.0) 
						
			final_leaderboard_container.add_child(row)
			added_characters.append(character)
	
func update_wind(delta):
	var player_speed = player.linear_velocity.length()
	var target_pitch = min_pitch + (player_speed * pitch_sensitivity)
	var pitch = lerp(min_pitch, target_pitch, 0.03)
	
	$Wind.pitch_scale = pitch

func update_stopwatch(delta):
	var time_text = get_formatted_time(player.elapsed_time)
	$StopwatchGui/Stopwatch.text = time_text

func get_formatted_time(time):
	var elapsed_time = time
	
	var minutes = int(elapsed_time / 60)
	var seconds = int(elapsed_time) % 60
	var centiseconds = int((elapsed_time - int(elapsed_time)) * 100)
	
	var time_text = "%02d:%02d:%02d" % [minutes, seconds, centiseconds]
	
	return time_text
	
func update_countdown(delta):
	var timer = level_manager.countdown_timer

	if level_manager.race_started:
		update_center_text("", "Center", delta)
		race_started = true
	else:
		update_center_text(str(ceil(timer)), "Center", delta)

func update_center_text(text, pos, delta):
	if pos == "Top" or pos == "All":
		$CenterGui/Top.text = text
	if pos == "MedTop" or pos == "All":
		$CenterGui/MedTop.text = text
	if pos == "Center" or pos == "All":
		$CenterGui/Center.text = text
	if pos == "MedBottom" or pos == "All":
		$CenterGui/MedBottom.text = text
	if pos == "Bottom" or pos == "All":
		$CenterGui/Bottom.text = text

func update_respawn_countdown(delta):
	if player.current_respawn_time > 0:
		player.handle_collisions()
		update_center_text("", "All", delta)
		update_center_text(player.collided_with, "Top", delta)
		update_center_text("KILLED YOU!!", "MedTop", delta)
		update_center_text(str(ceil(player.current_respawn_time)), "Bottom", delta)
		
	prev_dead = player.dead
	
func update_knockdown(delta):
	if player.knockdown:
		current_knockdown_text_timer = knockdown_text_timer
		
	if player.knockdown_streak > 0 and current_knockdown_text_timer > 0:
		var streak_text = ""
		if player.knockdown_streak > 1:
			streak_text = " " + str(player.knockdown_streak) + "x"
		update_center_text("KNOCKDOWN!!" + streak_text, "Center", delta)
		update_center_text("You Killed: " + player.collided_with, "MedBottom", delta)
		
		current_knockdown_text_timer -= delta
		
		if current_knockdown_text_timer <= 0:
			update_center_text("", "All", delta)
		
func get_place_suffix(place: int) -> String:
	var suffix = ""
	
	if place % 100 >= 10 and place % 100 <= 20:
		suffix = "th"
	else:
		match place % 10:
			1:
				suffix = "st"
			2:
				suffix = "nd"
			3:
				suffix = "rd"
			_:
				suffix = "th"
	return str(place) + suffix


func _on_back_to_menu_pressed():
	level_manager.fade_out()
