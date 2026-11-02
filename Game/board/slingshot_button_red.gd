extends TextureButton

var game_over: bool

@export var progressBarRed : ProgressBar
@export var vacuumButtonRed : TextureButton
@onready var slingshot_red: PrivateTouchZone = $"../SlingshotRed"

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	progressBarRed.barHalfFull.connect(enableButton)
	disabled = true
	game_over = false

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if game_over and !disabled:
		disabled = true

func _pressed() -> void:
	if !game_over:
		disabled = true
		progressBarRed.value -= progressBarRed.max_value / 2
		progressBarRed.isHalfFull = false
		progressBarRed.isFull = false
		vacuumButtonRed.disabled = true
		slingshot_red.activate()

func enableButton(state: bool):
	disabled = !state

func on_game_over():
	game_over = true
