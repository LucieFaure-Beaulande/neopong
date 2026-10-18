extends ProgressBar

signal barFull
var isFull: bool

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	isFull = false
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	value += 1
	if(value == 2000 && !isFull):
		isFull = true
		barFull.emit()
