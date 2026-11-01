extends PrivateTouchZone

signal vacuum_enabled(enabled:bool)
signal collision_mask_updated(mask:int)

@onready var placement_preview: Node2D = $PlacementPreview
@onready var placement_preview_7: Node2D = $PlacementPreview7

@export var preview_start_position: Vector2 = Vector2(-10, -57)
@export var preview_end_position: Vector2 = Vector2(-10, 61)
@export var preview_start_position_7: Vector2 = Vector2(-14, -1)
@export var preview_end_position_7: Vector2 = Vector2(-6, 117)
@export var preview_slide_duration: float = 1.5
# Max distance between the arc and the straight line joining start and end
@export var preview_arc_sagitta: float = 30.0
@export var preview_arc_sagitta_7: float = 30.0

var preview_tween: Tween

@export var nb_fingers_for_base: int = 2
@export var nb_fingers_for_aim: int = 2

@export var progressBar: ProgressBar

@onready var vacuum: Node2D = $Vacuum

var active: bool = false
const PLACEMENT_PREVIEW_COUNT: int = 7

# Shows or hides PlacementPreview, PlacementPreview2, ..., PlacementPreview7
func set_placement_previews_visible(show_previews: bool) -> void:
	for i in range(1, PLACEMENT_PREVIEW_COUNT + 1):
		var preview_name: String = "PlacementPreview" if i == 1 else "PlacementPreview" + str(i)
		var preview := get_node_or_null(preview_name) as CanvasItem
		if preview != null:
			preview.visible = show_previews

func _ready() -> void:
	change_collision_state(false)
	reset()
	set_placement_previews_visible(false)
	collision_mask_updated.emit(collision_mask)
	progressBar.barDepleted.connect(on_bar_depleted)

func activate() -> void:
	active = true
	start_preview_loop()
	

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _physics_process(_delta: float) -> void:
	if not active:
		reset()
		return
	if get_touch_ammount() >= nb_fingers_for_base:
		update_vacuum_position()
		if get_touch_ammount() >= nb_fingers_for_base + nb_fingers_for_aim: 
			update_vacuum_aim()
	else:
		reset()

func update_vacuum_position() -> void:
	#base position is the center of all fingers
	var pos_sum:Vector2 = Vector2.ZERO
	for i in range(1,nb_fingers_for_base+1):
		if touch_order_dict.get(i) != null:
			pos_sum += get_position_from_touch_number(i)
		else:
			reset()
			return
	
	vacuum.visible = true
	#print(vacuum.global_position)
	vacuum.global_position = pos_sum/nb_fingers_for_base

func update_vacuum_aim() -> void:
	#aim is the center of all fingers
	var pos_sum:Vector2 = Vector2.ZERO
	for i in range(nb_fingers_for_base+1,nb_fingers_for_base + nb_fingers_for_aim+1):
		if touch_order_dict.has(i):
			pos_sum += get_position_from_touch_number(i)
		else:
			vacuum_enabled.emit(false)
			return 
	
	vacuum_enabled.emit(true)
	vacuum.look_at(pos_sum/nb_fingers_for_aim)

# Returns the position on the arc between start and end for a progression t between 0 and 1
func get_arc_position(start: Vector2, end: Vector2, sagitta: float, t: float) -> Vector2:
	var chord: Vector2 = end - start
	var mid: Vector2 = (start + end) / 2.0
	var half_chord: float = chord.length() / 2.0

	# Circle radius deduced from the half chord and the sagitta
	var radius: float = (half_chord * half_chord + sagitta * sagitta) / (2.0 * sagitta)

	# Direction the arc bulges towards (left of the start -> end direction here).
	# Use chord.orthogonal() without the minus sign to bulge to the other side.
	var bulge_dir: Vector2 = -chord.orthogonal().normalized()

	# The center sits on the opposite side of the bulge
	var center: Vector2 = mid + bulge_dir * (sagitta - radius)

	var angle_start: float = (start - center).angle()
	var angle_bulge: float = (mid + bulge_dir * sagitta - center).angle()

	# Total angle covered by the arc, and the rotation direction to go through the bulge
	var sweep: float = 2.0 * asin(half_chord / radius)
	var direction: float = signf(angle_difference(angle_start, angle_bulge))

	var angle: float = angle_start + direction * sweep * t
	return center + Vector2.from_angle(angle) * radius

# Moves the preview dot along the arc from start to end, then back, forever
func start_preview_loop() -> void:
	# Make sure we never run two tweens at the same time
	stop_preview_loop()

	placement_preview.position = preview_start_position
	placement_preview_7.position = preview_start_position_7

	var update_position: Callable = func(t: float) -> void:
		placement_preview.position = get_arc_position(
			preview_start_position, preview_end_position, preview_arc_sagitta, t
		)
		placement_preview_7.position = get_arc_position(
			preview_start_position_7, preview_end_position_7, preview_arc_sagitta_7, t
		)

	preview_tween = create_tween()
	preview_tween.set_loops() # infinite loop

	# Forward: start -> end
	preview_tween.tween_method(
		update_position, 0.0, 1.0, preview_slide_duration
	).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)

	# Backward: end -> start, along the same arc
	preview_tween.tween_method(
		update_position, 1.0, 0.0, preview_slide_duration
	).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)


# Stops the loop and leaves the dot where it currently is
func stop_preview_loop() -> void:
	if preview_tween != null and preview_tween.is_valid():
		preview_tween.kill()

func reset() -> void:
	vacuum_enabled.emit(false)
	vacuum.visible = false

func change_collision_state(state: bool):
	for child: Node in self.get_children():
		if child is CollisionShape2D:
			child.disabled = state

func on_bar_depleted() -> void:
	active = false
	reset()
