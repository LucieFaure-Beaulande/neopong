extends Node2D

# Total duration of a game, in seconds (3 minutes by default)
@export var game_duration: float = 180.0
var milestone = 0.0
var step = 0.0

@onready var ball: Ball = $Balle
@onready var ux: ScoreBoard = $Ux
@onready var clock: AnimatedSprite2D = $Clock

var game_timer: Timer
var is_game_over: bool = false

func _ready() -> void:
	game_timer = Timer.new()
	game_timer.one_shot = true
	game_timer.wait_time = game_duration
	step = game_duration/16
	milestone = game_duration-step
	game_timer.timeout.connect(_on_game_timer_timeout)
	add_child(game_timer)

	# The timer only starts when the ball is launched for the first time
	ball.first_launched.connect(_on_ball_first_launched)


func _process(_delta: float) -> void:
	if not game_timer.is_stopped():
		if(game_timer.time_left <= milestone):
			clock.update_timer()
			milestone -= step

func _on_ball_first_launched() -> void:
	if game_timer.is_stopped() and not is_game_over:
		game_timer.start()
		clock.play()

func _on_game_timer_timeout() -> void:
	is_game_over = true
	clock.update_timer()

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
