extends TextureButton

@export var progressBarRed : ProgressBar
@export var vacuumButtonRed : TextureButton
@onready var slingshot_red: PrivateTouchZone = $"../SlingshotRed"

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	progressBarRed.barHalfFull.connect(enableButton)
	disabled = true

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func _pressed() -> void:
	disabled = true
	progressBarRed.value -= progressBarRed.max_value / 2
	progressBarRed.isHalfFull = false
	progressBarRed.isFull = false
	vacuumButtonRed.disabled = true
	slingshot_red.activate()

func enableButton(state: bool):
	disabled = !state
