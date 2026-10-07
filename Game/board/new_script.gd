extends Node

var dict:Dictionary[int, ColorRect]

func _input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		if event.pressed:
			print("Finger pressed at: ", event.position, " with index: ", event.index)
			var rect:ColorRect = ColorRect.new()
			add_child(rect)
			rect.global_position = event.position
			dict[event.index] = rect
		else:
			print("Finger released at: ", event.position, " with index: ", event.index)
			dict[event.index].queue_free()
			dict.erase(event.index)
