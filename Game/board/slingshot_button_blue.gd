extends TextureButton

var game_over: bool

@export var progressBarBlue : ProgressBar
@export var vacuumButtonBlue : TextureButton
@onready var slingshot_blue: PrivateTouchZone = $"../SlingshotBlue"

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	progressBarBlue.barHalfFull.connect(enableButton)
	disabled = true
	game_over = false

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if game_over and !disabled:
		disabled = true

func _pressed() -> void:
	if !game_over:
		disabled = true
		progressBarBlue.value -= progressBarBlue.max_value / 2
		progressBarBlue.isHalfFull = false
		progressBarBlue.isFull = false
		vacuumButtonBlue.disabled = true
		slingshot_blue.activate()

func enableButton(state: bool):
	disabled = !state

func on_game_over():
	game_over = true
