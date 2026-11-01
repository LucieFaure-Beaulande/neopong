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

@export var ennemyBounceBar: Area2D

# The zone's collision shapes now stay enabled all the time, so every touch is always tracked
# (disabling them made us miss finger releases, which left ghost touches behind).
# The slingshot only reacts while `active` is true. The red button calls activate(),
# and the slingshot deactivates itself after firing.
var active: bool = false
 
# Set when a base finger is lifted while the puller is held (cancelled pull).
# While set, no new base can be locked. It clears once every finger has been lifted,
# so the leftover fingers (including the old puller) can't become a new base.
var locked_out: bool = false

var base_touch_ids = []
var puller_id = -1
var anchor_id_1 = -1
var anchor_id_2 = -1

const PLACEMENT_PREVIEW_COUNT: int = 6

# Shows or hides PlacementPreview, PlacementPreview2, ..., PlacementPreview6
func set_placement_previews_visible(show_previews: bool) -> void:
	for i in range(1, PLACEMENT_PREVIEW_COUNT + 1):
		var preview_name: String = "PlacementPreview" if i == 1 else "PlacementPreview" + str(i)
		var preview := get_node_or_null(preview_name) as CanvasItem
		if preview != null:
			preview.visible = show_previews

func _ready():
	super._ready()
	set_shapes_disabled(false)
	reset_slingshot_state()
	set_placement_previews_visible(false)
	start_preview_loop()
	active = false

func activate():
	reset_slingshot_state()
	locked_out = false
	active = true

func _process(_delta):
	if not active:
		return
	
	# A cancelled pull blocks the slingshot until every finger has been lifted
	if locked_out:
		if touch_order_dict.is_empty():
			locked_out = false
		return
	
	if base_touch_ids.is_empty():
		if touch_order_dict.size() >= 5:
			var keys = touch_order_dict.keys()
			keys.sort()
			base_touch_ids = keys.slice(0, 5)
	elif puller_id == -1 and touch_order_dict.size() >= 6:
		for n in touch_order_dict.keys():
			if n in base_touch_ids:
				continue
			var p = get_position_from_touch_number(n)
			if is_valid_puller_position(p):
				puller_id = n
				lock_anchors(p)
				break
	
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

func lock_anchors(puller_start_pos: Vector2) -> bool:
	# Create an array of dictionaries containing the base touch IDs and their distances to the puller
	var distances = []
	for id in base_touch_ids:
		if touch_order_dict.keys().has(id):
			var dist = puller_start_pos.distance_to(get_position_from_touch_number(id))
			distances.append({"id": id, "distance": dist})
 
	if distances.size() < 2:
		return false
 
	# Sort to find the two closest points (thumb and index)
	distances.sort_custom(func(a, b): return a["distance"] < b["distance"])
 
	anchor_id_1 = distances[0]["id"]
	anchor_id_2 = distances[1]["id"]
	return true
	
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
	
	if not touch_order_dict.has(anchor_id_1) or not touch_order_dict.has(anchor_id_2):
		reset_slingshot_state()
		return
 
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
	new_projectile.collision_mask = ennemyBounceBar.collision_mask
	new_projectile.collision_layer = collision_layer | ennemyBounceBar.collision_layer
 
	# 4. Fire it
	new_projectile.apply_central_impulse(impulse_force)
 
	# 5. One shot per button press: reset and wait for the next activate()
	reset_slingshot_state()
	active = false

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
	if not active or touch_number == -1:
		return
	if puller_id != -1 and touch_number == puller_id:
		fire_projectile(touch_position)
	elif touch_number in base_touch_ids:
		if puller_id != -1:
			locked_out = true
		reset_slingshot_state()

func change_collision_state(state: bool):
	for child: Node in self.get_children():
		if child is CollisionShape2D:
			child.disabled = state

func set_shapes_disabled(state: bool):
	for child: Node in self.get_children():
		if child is CollisionShape2D:
			child.disabled = state
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
