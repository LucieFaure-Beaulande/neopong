extends PrivateTouchZone

signal vacuum_enabled(enabled:bool)
signal collision_mask_updated(mask:int)

@export var nb_fingers_for_base: int = 2
@export var nb_fingers_for_aim: int = 2

@export var progressBar: ProgressBar

@onready var vacuum: Node2D = $Vacuum

var active: bool = false

func _ready() -> void:
	change_collision_state(false)
	reset()
	collision_mask_updated.emit(collision_mask)
	progressBar.barDepleted.connect(on_bar_depleted)

func activate() -> void:
	active = true

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _physics_process(_delta: float) -> void:
	if not active:
		reset()
		return
	if get_touch_ammount() >= nb_fingers_for_base:
		update_vacuum_position()
		if get_touch_ammount() >= nb_fingers_for_base + nb_fingers_for_aim: 
			update_vacuum_aim()
	else:
		reset()

func update_vacuum_position() -> void:
	#base position is the center of all fingers
	var pos_sum:Vector2 = Vector2.ZERO
	for i in range(1,nb_fingers_for_base+1):
		if touch_order_dict.get(i) != null:
			pos_sum += get_position_from_touch_number(i)
		else:
			reset()
			return
	
	vacuum.visible = true
	#print(vacuum.global_position)
	vacuum.global_position = pos_sum/nb_fingers_for_base

func update_vacuum_aim() -> void:
	#aim is the center of all fingers
	var pos_sum:Vector2 = Vector2.ZERO
	for i in range(nb_fingers_for_base+1,nb_fingers_for_base + nb_fingers_for_aim+1):
		if touch_order_dict.has(i):
			pos_sum += get_position_from_touch_number(i)
		else:
			vacuum_enabled.emit(false)
			return 
	
	vacuum_enabled.emit(true)
	vacuum.look_at(pos_sum/nb_fingers_for_aim)

func reset() -> void:
	vacuum_enabled.emit(false)
	vacuum.visible = false

func change_collision_state(state: bool):
	for child: Node in self.get_children():
		if child is CollisionShape2D:
			child.disabled = state

func on_bar_depleted() -> void:
	active = false
	reset()
