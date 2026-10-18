extends TextureButton

@export var progressBarRed : ProgressBar
@export var slingshotButtonRed : TextureButton

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	progressBarRed.barFull.connect(enableButton)
	disabled = true

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func _pressed() -> void:
	disabled = true
	progressBarRed.value = 0
	progressBarRed.isFull = false
	slingshotButtonRed.disabled = true

func enableButton():
	disabled = false
