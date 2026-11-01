extends TextureButton

@export var progressBarBlue : ProgressBar
@export var slingshotButtonBlue : TextureButton
@export var vacuum_blue_zone : PrivateTouchZone

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	progressBarBlue.barFull.connect(enableButton)
	progressBarBlue.barDepleted.connect(barDepleted)
	disabled = true
	changeZoneUsability(true)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func _pressed() -> void:
	disabled = true
	progressBarBlue.isDepleting = true
	progressBarBlue.isFull = false
	slingshotButtonBlue.disabled = true
	changeZoneUsability(false)

func enableButton():
	disabled = false

func barDepleted():
	changeZoneUsability(true)
	
func changeZoneUsability(state: bool):
	for child: Node in vacuum_blue_zone.get_children():
		if child is CollisionShape2D:
			child.disabled = state
