extends TextureButton

@export var progressBarRed : ProgressBar
@export var slingshotButtonRed : TextureButton
@export var vacuum_red_zone : PrivateTouchZone

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	progressBarRed.barFull.connect(enableButton)
	progressBarRed.barDepleted.connect(barDepleted)
	disabled = true
	changeZoneUsability(true)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func _pressed() -> void:
	disabled = true
	progressBarRed.isDepleting = true
	progressBarRed.isFull = false
	slingshotButtonRed.disabled = true
	changeZoneUsability(false)

func enableButton():
	disabled = false

func barDepleted():
	changeZoneUsability(true)
	
func changeZoneUsability(state: bool):
	for child: Node in vacuum_red_zone.get_children():
		if child is CollisionShape2D:
			child.disabled = state
