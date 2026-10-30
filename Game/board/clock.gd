extends AnimatedSprite2D

var tick_count = 0

func update_timer() -> void:
	tick_count += 1
	play("tick" + str(tick_count))

func _on_animation_finished() -> void:
	if(animation == "tick16"):
		visible = false
