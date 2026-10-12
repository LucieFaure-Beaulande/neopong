extends RigidBody2D

@export var speed: float = 300.0
@export var launch_direction: Vector2 = Vector2(1, -1)
# Vitesse de rotation en radians/seconde (positif = sens des aiguilles d'une montre)
@export var spin_speed: float = 6.0
# Si activé, la direction du lancer est aléatoire (launch_direction est alors ignorée)
@export var random_launch: bool = true
# Écart maximal (en degrés) par rapport à l'horizontale, pour éviter les tirs trop verticaux
@export_range(0.0, 80.0) var max_launch_angle: float = 45.0
# Zone de jeu (en coordonnées globales). Si laissée vide (taille 0), on utilise tout l'écran.
@export var board_rect: Rect2 = Rect2()

var launched := false
var needs_reset := false

func _ready() -> void:
	# Permet aux GoalZone de reconnaître la balle
	add_to_group("balle")

	# Pas de gravité, pas de frottement, rebond parfait
	gravity_scale = 0.0
	linear_damp = 0.0
	angular_damp = 0.0
	lock_rotation = false # la balle doit pouvoir tourner

	var mat := PhysicsMaterial.new()
	mat.bounce = 1.0
	mat.friction = 0.0
	physics_material_override = mat

	# Permet de détecter le clic sur la balle
	input_pickable = true
	input_event.connect(_on_input_event)

func _get_board_rect() -> Rect2:
	if board_rect.size != Vector2.ZERO:
		return board_rect
	return get_viewport_rect()

func _on_input_event(_viewport: Node, event: InputEvent, _shape_idx: int) -> void:
	if launched:
		return
	var pressed := false
	if event is InputEventMouseButton:
		pressed = event.pressed and event.button_index == MOUSE_BUTTON_LEFT
	elif event is InputEventScreenTouch:
		pressed = event.pressed
	if pressed:
		launch()

func launch() -> void:
	launched = true
	var dir := launch_direction
	if random_launch:
		# Côté aléatoire (gauche ou droite) + angle aléatoire autour de l'horizontale
		var side := 1.0 if randf() < 0.5 else -1.0
		var angle := deg_to_rad(randf_range(-max_launch_angle, max_launch_angle))
		dir = Vector2(side, 0.0).rotated(angle)
	apply_central_impulse(dir.normalized() * speed * mass)

func _process(_delta: float) -> void:
	# Si la balle sort du board, on demande un reset
	if launched and not _get_board_rect().has_point(global_position):
		needs_reset = true

func _integrate_forces(state: PhysicsDirectBodyState2D) -> void:
	# Reset : on replace la balle au centre du board et on l'arrête
	# (il faut passer par state pour déplacer un RigidBody2D proprement)
	if needs_reset:
		needs_reset = false
		launched = false
		state.linear_velocity = Vector2.ZERO
		state.angular_velocity = 0.0
		state.transform = Transform2D(0.0, _get_board_rect().get_center())
		return

	# Tant que la balle n'est pas lancée, elle reste immobile
	if not launched:
		return

	# Rotation constante dans le sens des aiguilles d'une montre dès que la balle bouge
	state.angular_velocity = spin_speed

	# Garde une vitesse constante après chaque rebond
	if state.linear_velocity.length() > 0.0:
		state.linear_velocity = state.linear_velocity.normalized() * speed
