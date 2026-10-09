extends Node2D

var vacuum_enabled:bool = false

@onready var ray_cast_2d: VacuumRaycast = $RayCast2D

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _physics_process(delta: float) -> void:
	#look_at(get_global_mouse_position())
	ray_cast_2d.enabled = vacuum_enabled
	
func _input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		if event.pressed:
			print("Écran touché à la position : ", event.position)
			
			if event.index == 0:
				global_position = event.position
				vacuum_enabled = true
			if event.index > 0:
				look_at(event.position)
		else:
			print("Doigt levé de l'écran à la position : ", event.position)
		
	if event is InputEventScreenDrag:
		look_at(event.position)
