extends RayCast2D
class_name VacuumRaycast

var previous_collider:GoalZone = null

var vacuum_angle: float = 30 #not actually degrees, just pixels also just cosmetic

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _physics_process(delta: float) -> void:
	queue_redraw()
	if is_colliding():
		var collider = get_collider()
		if collider is GoalZone:
			previous_collider = collider
			previous_collider.pull_started.emit()
			var hit_pos = get_collision_point()
			collider.pull(hit_pos.x, global_rotation)
	elif previous_collider != null:
			previous_collider.pull_finished.emit()
			previous_collider = null
			

func _draw() -> void:
	var distance_limit:int = (get_collision_point().distance_to(global_position) if is_colliding() else 10000)
	var points = PackedVector2Array([
		position,
		Vector2(distance_limit, vacuum_angle), # Bas gauche
		Vector2(distance_limit, -vacuum_angle)  # Bas droit
	])
	var color = Color.FOREST_GREEN
	draw_colored_polygon(points, color)
