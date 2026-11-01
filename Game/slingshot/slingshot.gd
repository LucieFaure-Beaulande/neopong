extends PrivateTouchZone
var projectile_preload = preload("res://Game/slingshot/slingshot_projectile.tscn")

@onready var placement_preview_6: Node2D = $PlacementPreview6

@export var preview_start_position: Vector2 = Vector2(221, 424)
@export var preview_end_position: Vector2 = Vector2(121, 350)
@export var preview_slide_duration: float = 1.5

var preview_tween: Tween

@onready var line_left = $LineLeft
@onready var line_right = $LineRight
@onready var line_trajectory = $LineTrajectory
@export var slingshot_power_multiplier: float = 5.0
@export var max_pull_distance: float = 300.0

var active_touches = {}
var base_touch_ids = []
var puller_id = -1
var anchor_id_1 = -1
var anchor_id_2 = -1

func _ready():
	clear_slingshot_visuals()
	start_preview_loop()

func _process(_delta):
	if touch_order_dict.size() == 5 and base_touch_ids.is_empty():
		base_touch_ids = touch_order_dict.keys()
	elif touch_order_dict.size() >= 6 and not base_touch_ids.is_empty() and puller_id == -1:
		var touch_number: int = touch_order_dict.keys().max()
		if is_valid_puller_position(get_position_from_touch_number(touch_number)):
			puller_id = touch_number
			lock_anchors(get_position_from_touch_number(touch_number))
	
	if puller_id != -1 and touch_order_dict.keys().has(puller_id):
		update_visuals()
		
func is_valid_puller_position(pos: Vector2) -> bool:
	var min_x = INF
	var max_x = -INF
	var min_y = INF
	var max_y = -INF

	# Find the outermost boundaries of the 5 base fingers
	for id in base_touch_ids:
		if touch_order_dict.keys().has(id):
			var touch_pos = get_position_from_touch_number(id)
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
	if touch_order_dict.size() == 5 and base_touch_ids.is_empty():
		base_touch_ids = touch_order_dict.keys()
		
	# If the base is locked and a 6th touch appears, it's the puller
	elif touch_order_dict.size() >= 6 and not base_touch_ids.is_empty() and puller_id == -1:
		if is_valid_puller_position(new_touch_pos):
			puller_id = new_touch_index
			lock_anchors(new_touch_pos)

func lock_anchors(puller_start_pos: Vector2):
	# Create an array of dictionaries containing the base touch IDs and their distances to the puller
	var distances = []
	for id in base_touch_ids:
		if touch_order_dict.keys().has(id):
			var dist = puller_start_pos.distance_to(get_position_from_touch_number(id))
			distances.append({"id": id, "distance": dist})
			
	# Sort to find the two closest points (thumb and index)
	distances.sort_custom(func(a, b): return a["distance"] < b["distance"])
	
	anchor_id_1 = distances[0]["id"]
	anchor_id_2 = distances[1]["id"]
	
func screen_to_local(node: Node2D, screen_pos: Vector2) -> Vector2:
	return node.get_global_transform_with_canvas().affine_inverse() * screen_pos

func update_visuals():
	var pull_pos = get_position_from_touch_number(puller_id)
	var a1_pos = get_position_from_touch_number(anchor_id_1)
	var a2_pos = get_position_from_touch_number(anchor_id_2)
	
	line_left.visible = true
	line_right.visible = true
	line_trajectory.visible = true
	
	# Draw the V-shape of the slingshot
	line_left.points = [
		screen_to_local(line_left, a1_pos),
		screen_to_local(line_left, pull_pos)
	]
	line_right.points = [
		screen_to_local(line_right, a2_pos),
		screen_to_local(line_right, pull_pos)
	]
	
	# Calculate and draw the forward trajectory line
	var midpoint = (a1_pos + a2_pos) / 2.0
	var pull_vector = midpoint - pull_pos
	var trajectory_end = midpoint + (pull_vector * 2.0) # Multiply to extend the line forward
	
	line_trajectory.points = [
		screen_to_local(line_trajectory, midpoint),
		screen_to_local(line_trajectory, trajectory_end)
	]

func fire_projectile(pull_pos:Vector2):
	
	var a1_pos = get_position_from_touch_number(anchor_id_1)
	var a2_pos = get_position_from_touch_number(anchor_id_2)

	var midpoint = (a1_pos + a2_pos) / 2.0
	var pull_vector = midpoint - pull_pos
	var direction = pull_vector.normalized()
	var distance = clamp(pull_pos.distance_to(midpoint), 0, max_pull_distance)

	var impulse_force = direction * distance * slingshot_power_multiplier

	# 1. Instantiate the projectile
	var new_projectile = projectile_preload.instantiate() as RigidBody2D

	# 2. Add it to the main game scene (so it moves independently of the slingshot node)
	get_tree().current_scene.add_child(new_projectile)

	# 3. Set its starting position to the center of the slingshot base
	var world_midpoint = get_canvas_transform().affine_inverse() * midpoint
	new_projectile.global_position = world_midpoint

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


func _on_release_touch(touch_number: int, touch_position:Vector2) -> void:
	if touch_number == puller_id:
		fire_projectile(touch_position)
	elif touch_number in base_touch_ids:
		reset_slingshot_state()

func _on_input_disabled() -> void:
	# Cancels any slingshot being armed, so nothing is fired and the lines disappear
	reset_slingshot_state()

# Slides the preview dot from start to end, then snaps back to start, forever
func start_preview_loop() -> void:
	# Make sure we never run two tweens at the same time
	stop_preview_loop()

	placement_preview_6.position = preview_start_position

	preview_tween = create_tween()
	preview_tween.set_loops() # infinite loop
	preview_tween.tween_property(
		placement_preview_6, "position", preview_end_position, preview_slide_duration
	).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	# Instantly send the dot back to its starting point before the next cycle
	preview_tween.tween_callback(func(): placement_preview_6.position = preview_start_position)

# Stops the loop and leaves the dot where it currently is
func stop_preview_loop() -> void:
	if preview_tween != null and preview_tween.is_valid():
		preview_tween.kill()
