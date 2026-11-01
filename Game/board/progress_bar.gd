extends ProgressBar

signal barHalfFull(state:bool)
signal barFull
signal barDepleted
var isHalfFull: bool
var isFull: bool
var isDepleting: bool
var gameStarted: bool


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	isFull = false
	isDepleting = false
	isHalfFull = false
	gameStarted = false
	
func on_game_over():
	gameStarted = false

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if gameStarted:
		if not isDepleting:
			value += 1
			if (value < max_value / 2):
				var fill_style = get_theme_stylebox("fill").duplicate()
				fill_style.bg_color = Color.RED
				add_theme_stylebox_override("fill", fill_style)
			elif (value >= max_value / 2 and !isHalfFull):
				isHalfFull = true
				barHalfFull.emit(true)
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
			if (isHalfFull):
				isHalfFull = false
				barHalfFull.emit(false)
			value -= self.max_value / 500
			if (value <= 0 && isDepleting):
				value = 0
				isDepleting = false
				barDepleted.emit()


func _on_countdown_countdown_finished() -> void:
	gameStarted = true
