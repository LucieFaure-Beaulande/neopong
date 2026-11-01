extends TextureButton

var game_over: bool

@export var progressBarRed : ProgressBar
@export var slingshotButtonRed : TextureButton
@export var vacuum_red_zone : PrivateTouchZone

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	progressBarRed.barFull.connect(enableButton)
	disabled = true
	game_over = false

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if game_over and !disabled:
		disabled = true

func _pressed() -> void:
	if !game_over:
		disabled = true
		progressBarRed.isDepleting = true
		progressBarRed.isFull = false
		slingshotButtonRed.disabled = true
		vacuum_red_zone.activate()

func enableButton():
	disabled = false

func on_game_over():
	game_over = true
