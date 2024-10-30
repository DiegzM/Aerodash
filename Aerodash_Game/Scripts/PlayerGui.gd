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

var danger_sign_anim = Vector3(0.1, 0.1, 0.1)
var danger_sign_timer = 0.0
var danger_sign_fade_phase = 0
var rearcam_anim = 0.1
var rearcam_timer = 0.0
var rearcam_fade_phase = 0

var min_anim_speed = 0.75
var max_anim_speed = 20.0
var min_anim_visibility = 0.0
var max_anim_visibility = 0.05
var max_speed = 300

var base_speed_lines_scale = 4.3

var race_started

var prev_dead = false

# Called when the node enters the scene tree for the first time.
func _ready():
	var rearcam_rid = get_parent().get_node("CameraPivot/TPBCamera").get_camera_rid()
	var viewport_rid = $SubViewportContainer/SubViewport.get_viewport_rid()
	RenderingServer.viewport_attach_camera(viewport_rid, rearcam_rid)
	$SubViewportContainer.modulate.a = 0.0
	pass
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	update_text(delta)
	update_wind(delta)
	update_danger_sound(delta)
	update_knockdown(delta)
	update_final_leaderboard(delta)
	update_speed_lines(delta)
	update_rearcam(delta)
	
	if not race_started:
		update_countdown(delta)
	elif not player.race_finished:
		update_stopwatch(delta)
	
	if player.race_finished:
		if final_leaderboard_timer <= 0:
			if not $RaceFinishedGui.visible:
				update_center_text("", delta)
				update_bottom_text("", "All", delta)
				$RaceFinishedGui.visible = true
				pivot.controls_disabled = true
		else:
			update_center_text(get_place_suffix(player.final_place + 1) + " PLACE!", delta)
			$LeaderboardGui.visible = false
			$RaceFinishedGui/PlaceValue.text = get_place_suffix(player.final_place + 1)
			$RaceFinishedGui/Time.text = "Time: " + get_formatted_time(player.elapsed_time)
			if final_leaderboard_timer > 0:
				final_leaderboard_timer -= delta
	
	if not player.dead and prev_dead:
		prev_dead = false
		update_center_text("", delta)
		update_bottom_text("", "All", delta)
		
	if player.dead:
		update_respawn_countdown(delta)
	
	if player.chased:
		update_danger_gui(delta)
	else:
		$DangerGui/TextureRect.modulate.a = 0.0

func update_speed_lines(delta):
	var sprite = $SpeedLineGui/SpeedLines
	var player_speed = player.linear_velocity.length()
	var speed_ratio = clamp(player_speed / max_speed, 0, 1)

	sprite.play("default")
	sprite.speed_scale = lerp(min_anim_speed, max_anim_speed, speed_ratio)
	sprite.modulate.a = lerp(min_anim_visibility, max_anim_visibility, speed_ratio)

	# Adjust scale as before
	var speedline_size = $SpeedLineGui.size
	var viewport_size = get_viewport().size
	var scale_factor_x = speedline_size.x / viewport_size.x
	var scale_factor_y = speedline_size.y / viewport_size.y
	var scale_factor = max(scale_factor_x, scale_factor_y) * base_speed_lines_scale
	sprite.scale = Vector2(scale_factor, scale_factor)
	
func update_text(delta):
	place = level_manager.get_place(player)
	racer_count = level_manager.get_racer_count()
	$PlaceGui/Place.text = str(place)
	$PlaceGui/PlaceRacerCount.text = str(racer_count)
	$LapGui/LapCount.text = str(player.lap)
	$BoostGui/BoostBar.value = clamp(player.current_boost_time/player.MAX_BOOST_TIME, 0, 1)
	update_leaderboard(delta)

func update_danger_sound(delta):
	if player.chased:
		if not $Danger.playing:
			$Danger.playing = true
	else:
		$Danger.playing = false
	
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
		update_center_text("", delta)
		race_started = true
	else:
		update_center_text(str(ceil(timer)), delta)
		if timer <= 3 and not $Countdown.playing:
			$Countdown.playing = true
		

func update_center_text(text, delta):
	$CenterGui/Label.text = text
		
func update_bottom_text(text, pos, delta):
	if pos == "Top" or pos == "All":
		$BottomGui/Top.text = text
	if pos == "Bottom" or pos == "All":
		$BottomGui/Bottom.text = text

func update_respawn_countdown(delta):
	if player.current_respawn_time > 0:
		player.handle_collisions()
		update_bottom_text("", "All", delta)
		update_bottom_text("YOU DIED!!", "Top", delta)
		update_bottom_text(player.collided_with + " killed you! Respawning in " + str(ceil(player.current_respawn_time)), "Bottom", delta)
		
	prev_dead = player.dead

func update_danger_gui(delta):
	var image = $DangerGui/TextureRect
	# Fade-in phase
	if danger_sign_fade_phase == 0:
		danger_sign_timer += delta
		image.modulate.a = clamp(danger_sign_timer / danger_sign_anim.x, 0, 1) # Gradually increase alpha
		if danger_sign_timer >= danger_sign_anim.x:
			danger_sign_timer = 0 # Reset the timer
			danger_sign_fade_phase = 1 # Move to display phase
	
	# Display phase (holding full opacity)
	elif danger_sign_fade_phase == 1:
		danger_sign_timer += delta
		image.modulate.a = 1.0 # Fully visible
		if danger_sign_timer >= danger_sign_anim.y:
			danger_sign_timer = 0 # Reset the timer
			danger_sign_fade_phase = 2 # Move to fade-out phase
	
	# Fade-out phase
	elif danger_sign_fade_phase == 2:
		danger_sign_timer += delta
		image.modulate.a = clamp(1 - (danger_sign_timer / danger_sign_anim.z), 0, 1) # Gradually decrease alpha
		if danger_sign_timer >= danger_sign_anim.z:
			danger_sign_timer = 0 # Reset the timer
			danger_sign_fade_phase = 0 # Optionally, you can reset this to loop the animation or stop


func update_knockdown(delta):
	if player.knockdown:
		current_knockdown_text_timer = knockdown_text_timer
		$Knockdown.playing = false
		$Knockdown.playing = true
		
	if player.knockdown_streak > 0 and current_knockdown_text_timer > 0:
		var streak_text = ""
		if player.knockdown_streak > 1:
			streak_text = " " + str(player.knockdown_streak) + "x"
		update_bottom_text("KNOCKDOWN!!" + streak_text, "Top", delta)
		update_bottom_text("You Killed: " + player.collided_with, "Bottom", delta)
		
		current_knockdown_text_timer -= delta
		
		if current_knockdown_text_timer <= 0:
			update_bottom_text("", "All", delta)

func update_rearcam(delta):
	var image = $SubViewportContainer
	var rearcam_gui = $RearcamGui
	var distance_label = rearcam_gui.get_node("Distance")
	if player.chased and image.modulate.a < 1.0:
		rearcam_timer += delta
		image.modulate.a = clamp(rearcam_timer / rearcam_anim, 0, 1)
		rearcam_gui.modulate.a = clamp(rearcam_timer / rearcam_anim, 0, 1)
		if image.modulate.a >= 1.0:
			image.modulate.a = 1.0
			rearcam_gui.modulate.a = 1.0
			rearcam_timer = 0 # Reset the timer
	elif not player.chased and image.modulate.a > 0:
		rearcam_timer += delta
		image.modulate.a = clamp(1 - (rearcam_timer / rearcam_anim), 0, 1)
		rearcam_gui.modulate.a = clamp(1 - (rearcam_timer / rearcam_anim), 0, 1)
		if image.modulate.a <= 0.0:
			image.modulate.a = 0.0
			rearcam_gui.modulate.a = 0.0
			rearcam_timer = 0 # Reset the timer
	
	if player.chased_by:
		var distance = player.chased_by.global_transform.origin.distance_to(player.global_transform.origin)
		var rounded_distance = round(distance)
		distance_label.text = "Distance: " + str(rounded_distance)
		if rounded_distance < 15:
			distance_label.add_theme_color_override("font_color", Color(1, 0, 0))  # Red color
		else:
			distance_label.add_theme_color_override("font_color", Color(1, 1, 1))  # White color
			
		if player.chased_by.get_node("DangerLabel"):
			player.chased_by.get_node("DangerLabel").visible = true
	else:
		for char in level_manager.characters:
			if char.has_node("DangerLabel"):
				char.get_node("DangerLabel").visible = false
		distance_label.text = ""
		distance_label.add_theme_color_override("font_color", Color(1, 1, 1))  # White color
	
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
	level_manager.leaderboard_pressed = true
	level_manager.fade_out()
