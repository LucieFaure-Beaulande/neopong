extends TextureButton

@export var progressBarBlue : ProgressBar
@export var vacuumButtonBlue : TextureButton
@onready var slingshot_blue: PrivateTouchZone = $"../SlingshotBlue"

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	progressBarBlue.barHalfFull.connect(enableButton)
	disabled = true

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func _pressed() -> void:
	disabled = true
	progressBarBlue.value -= progressBarBlue.max_value / 2
	progressBarBlue.isHalfFull = false
	progressBarBlue.isFull = false
	vacuumButtonBlue.disabled = true
	slingshot_blue.activate()

func enableButton(state: bool):
	disabled = !state
