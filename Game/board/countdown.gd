extends Control
class_name Countdown

@onready var label_left: Label = $Container/HBoxContainer/LabelLeft
@onready var label_right: Label = $Container/HBoxContainer/LabelRight
@onready var animation_player: AnimationPlayer = $AnimationPlayer

signal countdown_started
signal countdown_finished

var countdown:int = 3

var timer:Timer

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	visible = false
	countdown_started.connect(_on_countdown_started)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func _on_countdown_started()->void:
	visible = true
	timer = Timer.new()
	add_child(timer)
	timer.timeout.connect(_on_timer_timeout)
	timer.wait_time = 1.0
	timer.one_shot = true
	timer.start()
	
	change_text(str(countdown))
	

func _on_timer_timeout():
	countdown -= 1
	if countdown >= 1:
		change_text(str(countdown))
		timer.start()
	elif countdown == 0:
		change_text("GO!")
		timer.start()
	else:
		countdown_finished.emit()
		visible = false
		change_text("If you see this then there's something wrong")

func change_text(text:String)->void:
	label_left.text = text
	label_right.text = text
	animation_player.play("zoom")
