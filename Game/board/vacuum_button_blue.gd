extends TextureButton

@export var progressBarBlue : ProgressBar
@export var slingshotButtonBlue : TextureButton
@export var vacuum_blue_zone : PrivateTouchZone

var game_over: bool

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	progressBarBlue.barFull.connect(enableButton)
	disabled = true
	game_over = false

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if game_over and !disabled:
		disabled = true

func _pressed() -> void:
	if !game_over:
		disabled = true
		progressBarBlue.isDepleting = true
		progressBarBlue.isFull = false
		slingshotButtonBlue.disabled = true
		vacuum_blue_zone.activate()

func enableButton():
	disabled = false

func on_game_over():
	game_over = true
