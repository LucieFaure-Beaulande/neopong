extends Node2D

@export var test_mode:bool = false
signal test_mode_activated

signal match_started

# Total duration of a game, in seconds (3 minutes by default)
@export var game_duration: float = 180.0
var milestone = 0.0
var step = 0.0

@onready var ball: Ball = $Balle
@onready var ux: ScoreBoard = $Ux
@onready var clock: AnimatedSprite2D = $Clock
@onready var countdown: Countdown = $CanvasLayer/Countdown
@onready var progress_bar_red: ProgressBar = $ProgressBarRed
@onready var progress_bar_blue: ProgressBar = $ProgressBarBlue

const SLINGSHOT_PROJECTILE = preload("uid://v0s1jbtupl54")

@onready var vacuum_test_position: Marker2D = $vacuum_test_position
@onready var slingshot_test_position: Marker2D = $slingshot_test_position
@onready var vacuum_test_aim_position: Marker2D = $vacuum_test_aim_position

var test_projectile_already_shot: bool = false
var test_vacuum_already_spawned: bool = false

@onready var rebondisseur_zone_bleu: RebondisseurZone = $RebondisseurZoneBleu
@onready var rebondisseur_zone_rouge: RebondisseurZone = $RebondisseurZoneRouge

@onready var vacuum_button_red: TextureButton = $VacuumButtonRed
@onready var slingshot_button_red: TextureButton = $SlingshotButtonRed
@onready var vacuum_button_blue: TextureButton = $VacuumButtonBlue
@onready var slingshot_button_blue: TextureButton = $SlingshotButtonBlue

var game_timer: Timer
var is_game_over: bool = false

var blue_team_ready:bool = false
var red_team_ready:bool = false

var current_phase:int = 0

@onready var slingshot = $SlingshotRed
@onready var vacuum = $VacuumZoneBlue

var previous_phase: int = -1

# Shows the placement previews of each power only during its own test phase
func update_previews() -> void:
	if current_phase == previous_phase:
		return
	previous_phase = current_phase
	vacuum.set_placement_previews_visible(test_mode and current_phase == 1)
	slingshot.set_placement_previews_visible(test_mode and current_phase == 2)
		
func _ready() -> void:
	if test_mode:
		test_mode_activated.emit()
		clock.turn_invisible()
	
	game_timer = Timer.new()
	game_timer.one_shot = true
	game_timer.wait_time = game_duration
	step = game_duration/16
	milestone = game_duration-step
	game_timer.timeout.connect(_on_game_timer_timeout)
	add_child(game_timer)

	# The timer only starts when the ball is launched for the first time
	ball.first_launched.connect(_on_ball_first_launched)
	
	countdown.countdown_finished.connect(_on_countdown_finished)
	#countdown.countdown_started.emit()


func _process(_delta: float) -> void:
	if not game_timer.is_stopped():
		if(game_timer.time_left <= milestone):
			clock.update_timer()
			milestone -= step
	  
	if test_mode:
		handle_test_script()
	
	if Input.is_action_just_pressed("ui_accept") and test_mode:
		current_phase += 1
	
	update_previews()


func _on_ball_first_launched() -> void:
	if game_timer.is_stopped() and not is_game_over:
		if not test_mode:
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

func test_disable_buttons()->void:
	vacuum_button_blue.disabled = true
	vacuum_button_red.disabled = true
	slingshot_button_blue.disabled = true
	slingshot_button_red.disabled = true

func handle_test_script():
	# Depending on test match progress, different behaviour
	match current_phase:
		0: # Phase de base, set up, renvoi de la balle 
			test_disable_buttons()
			
		1: # début des tests de pouvoir Aspirateur
			# Fill blue bar
			progress_bar_blue.value = progress_bar_blue.max_value
			# Empty other bar
			progress_bar_red.value = 0
			
			test_disable_buttons()
			vacuum_button_blue.disabled = false
			
		2: # début des tests de pouvoir Slingshot
			# Fill red bar
			progress_bar_red.value = progress_bar_red.max_value
			# Empty other bar
			progress_bar_blue.value = 0
			
			test_disable_buttons()
			slingshot_button_red.disabled = false
			
		3: # Attaque surprise slingshot!
			if !test_projectile_already_shot :
				var proj:RigidBody2D = SLINGSHOT_PROJECTILE.instantiate() as RigidBody2D
				proj.global_position = slingshot_test_position.global_position
				add_child(proj)
				var proj_direction : Vector2 = proj.global_position.direction_to(rebondisseur_zone_rouge.latest_center_position)
				var test_proj_speed := 400.0
				proj.apply_central_impulse(proj_direction * test_proj_speed)
				test_projectile_already_shot = true
			
			test_disable_buttons()
			
		4: # Attaque surprise vacuum!
			if !test_vacuum_already_spawned :
				var vacuum:VacuumRaycast = VacuumRaycast.new()
				
				vacuum.collision_mask = 4
				vacuum.target_position = Vector2(2000,0)
				vacuum.collide_with_areas = true
				vacuum.collide_with_bodies = false
				
				add_child(vacuum)
				
				vacuum.global_position = vacuum_test_position.global_position
				vacuum.global_rotation += PI/10
				
				var timer := Timer.new()
				add_child(timer)
				timer.wait_time = 10.0
				timer.one_shot = true
				
				# Define the inline behavior on timeout
				timer.timeout.connect(func():
					vacuum.previous_collider.pull_finished.emit()
					vacuum.queue_free()
					timer.queue_free() # Clean up the timer so it doesn't leak memory
				)
				
				timer.start()
				test_vacuum_already_spawned = true
			
		5: #Force finish match
			_on_game_timer_timeout()
			
		6: # Back to main menu
			get_tree().change_scene_to_file("res://UI/titleScreen.tscn")
	
