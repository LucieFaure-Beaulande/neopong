extends Node2D

@onready var line_left = $LineLeft
@onready var line_right = $LineRight
@onready var line_trajectory = $LineTrajectory
@export var projectile_scene: PackedScene
@export var slingshot_power_multiplier: float = 5.0
@export var max_pull_distance: float = 300.0

var active_touches = {}
var base_touch_ids = []
var puller_id = -1
var anchor_id_1 = -1
var anchor_id_2 = -1

func _ready():
	clear_slingshot_visuals()

func _input(event):
	if event is InputEventScreenTouch:
		if event.pressed:
			active_touches[event.index] = event.position
			evaluate_touch_state(event.index, event.position)
		else:
			active_touches.erase(event.index)
			if event.index == puller_id:
				fire_projectile()
			elif event.index in base_touch_ids:
				reset_slingshot_state()
				
	elif event is InputEventScreenDrag:
		if active_touches.has(event.index):
			active_touches[event.index] = event.position

func _process(_delta):
	if puller_id != -1 and active_touches.has(puller_id):
		update_visuals()
		
func is_valid_puller_position(pos: Vector2) -> bool:
	var min_x = INF
	var max_x = -INF
	var min_y = INF
	var max_y = -INF

	# Find the outermost boundaries of the 5 base fingers
	for id in base_touch_ids:
		if active_touches.has(id):
			var touch_pos = active_touches[id]
			min_x = min(min_x, touch_pos.x)
			max_x = max(max_x, touch_pos.x)
			min_y = min(min_y, touch_pos.y)
			max_y = max(max_y, touch_pos.y)
			
	# Create a bounding box around those fingers, expanded slightly for leniency
	var margin = 60.0 
	var hand_rect = Rect2(
		min_x - margin, 
		min_y - margin, 
		(max_x - min_x) + (margin * 2), 
		(max_y - min_y) + (margin * 2)
	)

	# Return true only if the 6th finger is inside this area
	return hand_rect.has_point(pos)

func evaluate_touch_state(new_touch_index: int, new_touch_pos: Vector2):
	# If we hit 5 touches and haven't locked a base yet, lock these 5 IDs
	if active_touches.size() == 5 and base_touch_ids.is_empty():
		base_touch_ids = active_touches.keys()
		
	# If the base is locked and a 6th touch appears, it's the puller
	elif active_touches.size() >= 6 and not base_touch_ids.is_empty() and puller_id == -1:
		if is_valid_puller_position(new_touch_pos):
			puller_id = new_touch_index
			lock_anchors(new_touch_pos)

func lock_anchors(puller_start_pos: Vector2):
	# Create an array of dictionaries containing the base touch IDs and their distances to the puller
	var distances = []
	for id in base_touch_ids:
		if active_touches.has(id):
			var dist = puller_start_pos.distance_to(active_touches[id])
			distances.append({"id": id, "distance": dist})
			
	# Sort to find the two closest points (thumb and index)
	distances.sort_custom(func(a, b): return a["distance"] < b["distance"])
	
	anchor_id_1 = distances[0]["id"]
	anchor_id_2 = distances[1]["id"]

func update_visuals():
	var pull_pos = active_touches[puller_id]
	var a1_pos = active_touches[anchor_id_1]
	var a2_pos = active_touches[anchor_id_2]
	
	line_left.visible = true
	line_right.visible = true
	line_trajectory.visible = true
	
	# Draw the V-shape of the slingshot
	line_left.points = [a1_pos, pull_pos]
	line_right.points = [a2_pos, pull_pos]
	
	# Calculate and draw the forward trajectory line
	var midpoint = (a1_pos + a2_pos) / 2.0
	var pull_vector = midpoint - pull_pos
	var trajectory_end = midpoint + (pull_vector * 2.0) # Multiply to extend the line forward
	
	line_trajectory.points = [midpoint, trajectory_end]

func fire_projectile():
	if not projectile_scene:
		print("Error: Projectile scene not assigned in Inspector!")
		reset_slingshot_state()
		return

	var pull_pos = active_touches[puller_id]
	var a1_pos = active_touches[anchor_id_1]
	var a2_pos = active_touches[anchor_id_2]

	var midpoint = (a1_pos + a2_pos) / 2.0
	var pull_vector = midpoint - pull_pos
	var direction = pull_vector.normalized()
	var distance = clamp(pull_pos.distance_to(midpoint), 0, max_pull_distance)

	var impulse_force = direction * distance * slingshot_power_multiplier

	# 1. Instantiate the projectile
	var new_projectile = projectile_scene.instantiate() as RigidBody2D

	# 2. Add it to the main game scene (so it moves independently of the slingshot node)
	get_tree().current_scene.add_child(new_projectile)

	# 3. Set its starting position to the center of the slingshot base
	new_projectile.global_position = midpoint

	# 4. Fire it
	new_projectile.apply_central_impulse(impulse_force)

	reset_slingshot_state()

func reset_slingshot_state():
	base_touch_ids.clear()
	puller_id = -1
	anchor_id_1 = -1
	anchor_id_2 = -1
	clear_slingshot_visuals()

func clear_slingshot_visuals():
	line_left.visible = false
	line_right.visible = false
	line_trajectory.visible = false
