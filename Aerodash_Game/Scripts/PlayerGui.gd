extends Control

@onready var level_manager = get_tree().current_scene
@onready var player = get_parent().get_node("Player")

var place = 0
var racer_count = 0

var min_pitch = 0.9
var pitch_sensitivity = 0.2

var knockdown_text_timer = 2
var current_knockdown_text_timer = 0

var elapsed_time = 0.0

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
	
	if not race_started:
		update_countdown(delta)
	elif not player.race_finished:
		update_stopwatch(delta)
	
	if player.race_finished:
		update_center_text("RACE FINISHED!", delta)
	
	if not player.dead and prev_dead:
		prev_dead = false
		update_center_text("", delta)
		
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
	var leaderboard = leaderboard_gui.get_node("VBoxContainer")
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
	
func update_wind(delta):
	var player_speed = player.linear_velocity.length()
	var target_pitch = min_pitch + (player_speed * pitch_sensitivity)
	var pitch = lerp(min_pitch, target_pitch, 0.03)
	
	$Wind.pitch_scale = pitch

func update_stopwatch(delta):
	elapsed_time += delta
	
	var minutes = int(elapsed_time / 60)
	var seconds = int(elapsed_time) % 60
	var centiseconds = int((elapsed_time - int(elapsed_time)) * 100)
	
	var time_text = "%02d:%02d:%02d" % [minutes, seconds, centiseconds]

	$StopwatchGui/Stopwatch.text = time_text

func update_countdown(delta):
	var timer = level_manager.countdown_timer

	if level_manager.race_started:
		update_center_text("", delta)
		race_started = true
	else:
		update_center_text(str(ceil(timer)), delta)

func update_center_text(text, delta):
	$CenterGui/Timer.text = text

func update_respawn_countdown(delta):
	if player.current_respawn_time > 0:
		update_center_text(str(ceil(player.current_respawn_time)), delta)
		
	prev_dead = player.dead
	
func update_knockdown(delta):
	if player.knockdown:
		current_knockdown_text_timer = knockdown_text_timer
		
	if player.knockdown_streak > 0 and current_knockdown_text_timer > 0:
		var streak_text = ""
		if player.knockdown_streak > 1:
			streak_text = " " + str(player.knockdown_streak) + "x"
		update_center_text("KNOCKDOWN!" + streak_text, delta)
		
		current_knockdown_text_timer -= delta
		
		if current_knockdown_text_timer <= 0:
			update_center_text("", delta)
		
