extends Node2D

@export var dot_color:Color

@onready var animation_player: AnimationPlayer = $AnimationPlayer

@onready var main_dot: MeshInstance2D = $"main dot"
@onready var afterimage: MeshInstance2D = $afterimage


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	animation_player.play("pulse")
	main_dot.modulate = dot_color
	afterimage.modulate = dot_color

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass


func _on_area_2d_input_event(viewport: Node, event: InputEvent, shape_idx: int) -> void:
	if event is InputEventScreenTouch:
		if event.pressed:
			animation_player.play("pressed")
		else:
			animation_player.play("pulse")
