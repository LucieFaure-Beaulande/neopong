extends Label


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	add_theme_font_size_override("font_size", 100)
	add_theme_color_override("font_color", Color(0.553, 0.628, 1.0, 1.0))

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func change_text(score: int) -> void:
	text = str(score)
