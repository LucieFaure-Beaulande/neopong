extends PrivateTouchZone

const MAX_LINE_DISTANCE: float = 250.0

# Combien de temps (en secondes) la ligne rouge reste visible après la cassure avant de disparaître
@export var broken_display_time: float = 0.4

const COLOR_ACTIVE := Color.GREEN
const COLOR_BROKEN := Color.RED

var line_broken: bool = false

@onready var collision_shape: CollisionShape2D = $AnimatableBody2D/CollisionShape2D

@onready var line2d: Line2D = $AnimatableBody2D/Line2D

@onready var area_shape: CollisionShape2D = $AnimatableBody2D/Area2D/CollisionShape2D


var _segment: SegmentShape2D
var _broken_timer: float = 0.0
var _broken_p1: Vector2 = Vector2.ZERO
var _broken_p2: Vector2 = Vector2.ZERO

@export var _rect_width: int = 20

func _ready() -> void:
	# Création du segment physique
	_segment = SegmentShape2D.new()
	collision_shape.shape = _segment
	area_shape.shape = _segment
	collision_shape.disabled = true
	
	for child: Node in get_children():
		if child is Area2D:
			child.collision_layer = collision_layer
			child.collision_mask = collision_mask

	# Style visuel de la ligne
	line2d.width = 6.0
	line2d.default_color = COLOR_ACTIVE
	line2d.clear_points()

func _physics_process(delta: float) -> void:
	_update_line_state()
	_update_collision()
	_update_visual_line(delta)

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
		_broken_timer = 0.0
		return
	if line_broken:
		return

	var p1: Vector2 = get_position_from_touch_number(1)
	var p2: Vector2 = get_position_from_touch_number(2)

	if p1.distance_to(p2) > MAX_LINE_DISTANCE:
		# La ligne casse : on garde sa dernière position pour l'afficher en rouge un court instant
		line_broken = true
		_broken_timer = broken_display_time
		_broken_p1 = p1
		_broken_p2 = p2

func _update_collision() -> void:
	if not _line_active():
		collision_shape.set_deferred("disabled", true)
		# On remet le segment à zéro pour ne pas garder une "ligne fantôme" (visible avec Debug > Collision Shapes)
		_segment.a = Vector2.ZERO
		_segment.b = Vector2.ZERO
		area_shape.set_deferred("disabled", true)
		return

	var p1: Vector2 = get_position_from_touch_number(1)
	var p2: Vector2 = get_position_from_touch_number(2)

	_segment.a = collision_shape.to_local(p1)
	_segment.b = collision_shape.to_local(p2)
	
	collision_shape.set_deferred("disabled", false)
	area_shape.set_deferred("disabled", false)

func _update_visual_line(delta: float) -> void:
	# Ligne active : verte, qui suit les doigts
	if _line_active():
		var p1: Vector2 = get_position_from_touch_number(1)
		var p2: Vector2 = get_position_from_touch_number(2)
		line2d.visible = true
		line2d.default_color = COLOR_ACTIVE
		line2d.modulate.a = 1.0
		line2d.points = [
			line2d.to_local(p1),
			line2d.to_local(p2)
		]
		return

	# Ligne cassée : rouge, figée, qui s'estompe puis disparaît
	if line_broken and _broken_timer > 0.0:
		_broken_timer -= delta
		line2d.visible = true
		line2d.default_color = COLOR_BROKEN
		line2d.modulate.a = clampf(_broken_timer / broken_display_time, 0.0, 1.0)
		line2d.points = [
			line2d.to_local(_broken_p1),
			line2d.to_local(_broken_p2)
		]
		return

	# Plus rien à afficher : on vide ET on cache complètement la ligne
	line2d.clear_points()
	line2d.visible = false


func _on_area_2d_body_entered(body: Node2D) -> void:
	if body != self:
		print(body)
		line_broken = true
