extends Area2D
class_name GoalZone

signal pull_started
signal pull_finished
# Émis quand la balle touche cette zone : team = l'équipe qui marque le point
signal goal_scored(team: int)

enum Team { BLEUE, ROUGE }

const TEAM_COLORS := {
	Team.BLEUE: Color(0.2, 0.4, 1.0, 0.7),
	Team.ROUGE: Color(1.0, 0.25, 0.25, 0.7),
}

@onready var dynamic_collision_shape: CollisionPolygon2D = $DynamicCollisionShape

# Équipe associée à cette zone (réglable dans l'Inspecteur).
# Si le nom du node ou de son parent contient "bleu" / "rouge", l'équipe est déduite automatiquement.
@export var team: Team = Team.BLEUE
@export var max_pull_distance: float = 200
@export var pull_speed: float = 1000

var target_dot_position: Vector2 = Vector2.ZERO
var is_pulled: bool = false

func _ready() -> void:
	add_to_group("goal_zone")
	_guess_team_from_names()
	pull_started.connect(_on_pull_started)
	pull_finished.connect(_on_pull_finished)
	body_entered.connect(_on_body_entered)

func _guess_team_from_names() -> void:
	var names := String(name).to_lower()
	if get_parent():
		names += " " + String(get_parent().name).to_lower()
	if names.contains("rouge"):
		team = Team.ROUGE
	elif names.contains("bleu"):
		team = Team.BLEUE

func _physics_process(delta: float) -> void:
	queue_redraw()
	if !is_pulled:
		target_dot_position = Vector2.ZERO
	var temp_polygon: PackedVector2Array = dynamic_collision_shape.get_polygon()
	var current_dot_position: Vector2 = temp_polygon.get(0)
	var new_dot_position: Vector2 = current_dot_position.move_toward(target_dot_position, pull_speed * delta)
	temp_polygon.set(0, new_dot_position)

	dynamic_collision_shape.set_polygon(temp_polygon)

func pull(origin: int, angle: float) -> void:
	# Here we modify the target position of the first dot of the polygon so that we can "pull" on the goal zone
	var fixed_origin := origin - 360 # half of the width because the polygon's center is 0
	# We create a vector that we then rotate
	# this vector is used to create an "offset" that aligns with the vacuum's angle
	var pull_vector: Vector2 = Vector2(-max_pull_distance, 0).rotated(angle)
	target_dot_position = pull_vector + Vector2(fixed_origin, 0)

func _on_pull_started() -> void:
	is_pulled = true

func _on_pull_finished() -> void:
	is_pulled = false

func _on_body_entered(body: Node2D) -> void:
	# La balle touche la zone : point pour l'équipe de la zone, puis la balle est remise en jeu
	if body.is_in_group("balle"):
		goal_scored.emit(team)
		body.needs_reset = true
		return
	# Check if the object entering the goal is the slingshot projectile
	if body.is_in_group("projectile"):
		body.queue_free() # Deletes the slingshot projectile from the game

func _draw() -> void:
	draw_colored_polygon(dynamic_collision_shape.get_polygon(), TEAM_COLORS[team])
