extends PrivateTouchZone

func _physics_process(delta: float) -> void:
	queue_redraw()

func _draw() -> void:
	# On teste les touches réellement présentes, pas nb_of_touches
	# (nb_of_touches ne redescend pas tant qu'il reste un doigt)
	if not (touch_order_dict.has(1) and touch_order_dict.has(2)):
		return
	
	# Vérifie aussi que les positions sont connues
	if not (touch_event_dict.has(touch_order_dict[1]) and touch_event_dict.has(touch_order_dict[2])):
		return
	
	var p1: Vector2 = get_position_from_touch_number(1)
	var p2: Vector2 = get_position_from_touch_number(2)
	
	# _draw() travaille en coordonnées locales, event.position est en coordonnées écran
	draw_line(to_local(p1), to_local(p2), Color.GREEN, 6.0, true)
