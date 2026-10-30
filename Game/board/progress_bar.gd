extends ProgressBar

signal barFull
signal barDepleted
var isFull: bool
var isDepleting: bool

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	isFull = false
	isDepleting = false


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if not isDepleting:
		value += 5
		if (value < max_value / 2):
			var fill_style = get_theme_stylebox("fill").duplicate()
			fill_style.bg_color = Color.RED
			add_theme_stylebox_override("fill", fill_style)
		elif (value < max_value):
			var fill_style = get_theme_stylebox("fill").duplicate()
			fill_style.bg_color = Color.ORANGE
			add_theme_stylebox_override("fill", fill_style)
		if(value == self.max_value && !isFull):
			var fill_style = get_theme_stylebox("fill").duplicate()
			fill_style.bg_color = Color.DARK_GREEN
			add_theme_stylebox_override("fill", fill_style)
			isFull = true
			barFull.emit()
	else:
		value -= self.max_value / 500
		if (value <= 0 && isDepleting):
			value = 0
			isDepleting = false
			barDepleted.emit()
