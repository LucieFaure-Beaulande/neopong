extends TextureButton

@export var progressBarBlue : ProgressBar
@export var slingshotButtonBlue : TextureButton
@export var vacuum_blue_zone : PrivateTouchZone

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	progressBarBlue.barFull.connect(enableButton)
	disabled = true

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func _pressed() -> void:
	disabled = true
	progressBarBlue.isDepleting = true
	progressBarBlue.isFull = false
	slingshotButtonBlue.disabled = true
	vacuum_blue_zone.activate()

func enableButton():
	disabled = false
