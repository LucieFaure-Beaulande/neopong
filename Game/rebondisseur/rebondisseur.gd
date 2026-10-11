extends Node2D

var touches := {}

func _input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		if event.pressed:
			touches[event.index] = event.position
			print("Finger", event.index, "pressed at", event.position)
		else:
			touches.erase(event.index)
			print("Finger", event.index, " released")
		queue_redraw()
	elif event is InputEventScreenDrag:
		touches[event.index] = event.position
		print("Finger", event.index, " moved to", event.position)
		queue_redraw()

func _draw() -> void:
	var points := touches.values()

	# Draw a line between the first two fingers
	if points.size() >= 2:
		draw_line(points[0], points[1], Color.GREEN, 6.0, true)
