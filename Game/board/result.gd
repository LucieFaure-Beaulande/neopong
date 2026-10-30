extends AnimatedSprite2D

func _ready() -> void:
	visible = false

func show_result(victory) -> void:
	if(victory == 1):
		play("victory")
	elif(victory == 2):
		play("loss")
	else:
		play("draw")



func _on_clock_animation_finished() -> void:
	visible = true
