extends PrivateTouchZone

const MAX_LINE_DISTANCE: float = 250.0

var line_broken: bool = false

# Adapte le chemin à ta scène
@onready var collision_shape: CollisionShape2D = $AnimatableBody2D/CollisionShape2D

var _segment: SegmentShape2D

func _ready() -> void:
	_segment = SegmentShape2D.new()
	collision_shape.shape = _segment
	collision_shape.disabled = true

func _physics_process(delta: float) -> void:
	_update_line_state()
	_update_collision()
	queue_redraw()

func _has_two_touches() -> bool:
	if not (touch_order_dict.has(1) and touch_order_dict.has(2)):
		return false
	if not (touch_event_dict.has(touch_order_dict[1]) and touch_event_dict.has(touch_order_dict[2])):
		return false
	return true

func _line_active() -> bool:
	return _has_two_touches() and not line_broken

func _update_line_state() -> void:
	if not _has_two_touches():
		line_broken = false
		return
	if line_broken:
		return

	var p1: Vector2 = get_position_from_touch_number(1)
	var p2: Vector2 = get_position_from_touch_number(2)

	if p1.distance_to(p2) > MAX_LINE_DISTANCE:
		line_broken = true

func _update_collision() -> void:
	if not _line_active():
		collision_shape.set_deferred("disabled", true)
		return

	var p1: Vector2 = get_position_from_touch_number(1)
	var p2: Vector2 = get_position_from_touch_number(2)

	# Les points du segment sont dans le repère local du CollisionShape2D
	_segment.a = collision_shape.to_local(p1)
	_segment.b = collision_shape.to_local(p2)
	collision_shape.set_deferred("disabled", false)

func _draw() -> void:
	if not _line_active():
		return

	var p1: Vector2 = get_position_from_touch_number(1)
	var p2: Vector2 = get_position_from_touch_number(2)

	draw_line(to_local(p1), to_local(p2), Color.GREEN, 6.0, true)
