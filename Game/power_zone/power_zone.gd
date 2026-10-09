extends Area2D


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.



func _input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		if event.pressed:
			print("Écran touché à la position : ", event.position)
		else:
			print("Doigt levé de l'écran à la position : ", event.position)
		
	if event is InputEventScreenDrag:
		print("Doigt déplacé à : ", event.position, " avec l'index : ", event.index)
