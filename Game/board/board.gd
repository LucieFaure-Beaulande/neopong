extends Node2D

@export var test_mode:bool = false
signal test_mode_activated

signal match_started

# Total duration of a game, in seconds (3 minutes by default)
@export var game_duration: float = 180.0

@onready var ball: Ball = $Balle
@onready var ux: ScoreBoard = $Ux
@onready var countdown: Countdown = $CanvasLayer/Countdown
@onready var progress_bar_red: ProgressBar = $ProgressBarRed
@onready var progress_bar_blue: ProgressBar = $ProgressBarBlue

var game_timer: Timer
var is_game_over: bool = false

var blue_team_ready:bool = false
var red_team_ready:bool = false

func _ready() -> void:
	if test_mode:
		test_mode_activated.emit()
	
	game_timer = Timer.new()
	game_timer.one_shot = true
	game_timer.wait_time = game_duration
	game_timer.timeout.connect(_on_game_timer_timeout)
	add_child(game_timer)

	# The timer only starts when the ball is launched for the first time
	ball.first_launched.connect(_on_ball_first_launched)

	# Shows the full duration before the game starts
	ux.update_timer(game_duration)
	
	countdown.countdown_finished.connect(_on_countdown_finished)
	#countdown.countdown_started.emit()

func _process(_delta: float) -> void:
	if not game_timer.is_stopped():
		ux.update_timer(game_timer.time_left)
	
	if test_mode:
		handle_script()

func _on_ball_first_launched() -> void:
	if game_timer.is_stopped() and not is_game_over:
		if not test_mode:
			game_timer.start()
		

func _on_game_timer_timeout() -> void:
	is_game_over = true
	ux.update_timer(0.0)

	# Stops the ball and forbids any new launch
	ball.end_game()

	# Blocks every touch zone (Slingshot, VacuumZone, RebondisseurZones)
	for child in get_children():
		if child is PrivateTouchZone:
			child.set_input_enabled(false)

	# Removes the slingshot projectiles still in play
	for projectile in get_tree().get_nodes_in_group("projectile"):
		projectile.queue_free()

	ux.show_game_over()


func _on_rebondisseur_zone_bleu_players_ready(ready: bool) -> void:
	blue_team_ready = ready
	initial_ready_launch()


func _on_rebondisseur_zone_rouge_players_ready(ready: bool) -> void:
	red_team_ready = ready
	initial_ready_launch()


func initial_ready_launch():
	if blue_team_ready and red_team_ready:
		match_started.emit()
		countdown.countdown_started.emit()
		
func _on_countdown_finished():
	if test_mode:
		ball.speed = 150
		ball.random_launch = false
		ball.launch(Vector2.LEFT)
	else:
		ball.launch()


func handle_script():
	# Depending on test match progress, different behaviour
	match Scores.red_team + Scores.blue_team :
		0:
			pass
		1:
			# Fill blue bar
			progress_bar_blue.value = progress_bar_blue.max_value
			# On pourrait activer et désactiver des boutons mais ça va attendre un peu
		2:
			# Fill red bar
			progress_bar_red.value = progress_bar_red.max_value
		3:
			pass
			#Force finish match
