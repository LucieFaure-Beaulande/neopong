extends TextureButton

@export var progressBarRed : ProgressBar
@export var slingshotButtonRed : TextureButton
@export var vacuum_red_zone : PrivateTouchZone

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	progressBarRed.barFull.connect(enableButton)
	disabled = true

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func _pressed() -> void:
	disabled = true
	progressBarRed.isDepleting = true
	progressBarRed.isFull = false
	slingshotButtonRed.disabled = true
	vacuum_red_zone.activate()

func enableButton():
	disabled = false
