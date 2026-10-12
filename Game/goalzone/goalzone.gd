extends Area2D
class_name GoalZone

signal pull_started
signal pull_finished

@onready var dynamic_collision_shape: CollisionPolygon2D = $DynamicCollisionShape

@export var max_pull_distance: float = 200
@export var pull_speed: float = 1000

var target_dot_position: Vector2 = Vector2.ZERO
var is_pulled: bool = false
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pull_started.connect(_on_pull_started)
	pull_finished.connect(_on_pull_finished)
	body_entered.connect(_on_body_entered)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _physics_process(delta: float) -> void:
	queue_redraw()
	if !is_pulled:
		target_dot_position = Vector2.ZERO
	var temp_polygon:PackedVector2Array = dynamic_collision_shape.get_polygon()
	var current_dot_position:Vector2 = temp_polygon.get(0)
	var new_dot_position:Vector2 = current_dot_position.move_toward(target_dot_position, pull_speed*delta)
	temp_polygon.set(0, new_dot_position)
	
	dynamic_collision_shape.set_polygon(temp_polygon)
	

func pull(origin:int, angle:float) -> void:
	# Here we modify the target position of the first dot of the polygon so that we can "pull" on the goal zone
	var fixed_origin := origin-360 #half of the width because the polygon's center is 0
	# We create a vector that we then rotate
	# this vector is used to create an "offset" that aligns with the vacuum's angle
	var pull_vector:Vector2 = Vector2(0,max_pull_distance).rotated(angle)
	target_dot_position = pull_vector + Vector2(fixed_origin,0)


func _on_pull_started() -> void:
	is_pulled = true
	
func _on_pull_finished() -> void:
	is_pulled = false
	
func _on_body_entered(body: Node2D):
	# Check if the object entering the goal is the slingshot projectile
	if body.is_in_group("projectile"):
		body.queue_free() # Deletes the slingshot projectile from the game
	
func _draw() -> void:
	var color = Color.DIM_GRAY
	draw_colored_polygon(dynamic_collision_shape.get_polygon(), color)
