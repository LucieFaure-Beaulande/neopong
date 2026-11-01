extends Area2D
class_name PrivateTouchZone

# Tracks the different touch inputs inside the zone
# Saves the touch number (usually the order in which the finger has been placed)
# and the event index associated with the touch number
# Use this when you need to get a touch input
# touch number starts at 1 (because the 0th touch doesn't make sense)
var touch_order_dict:Dictionary[int, int] = {}

# Tracks the position of each input event inside the zone
# it's best to avoid using this variable when PrivateTouchZone is inherited
# prioritise using the touch number
var touch_event_dict:Dictionary[int, Vector2] = {}

# tracks total number of fingers places, only resets when there's no finger left
# this is to prevent placing fingers and then removing them to cheat
# also tracks the order fingers are placed
# in the end this is probably not the best solution but it does its job
var nb_of_touches:int = 0

# When false, every touch is ignored (used when the game is over)
var input_enabled: bool = true

# We needed a way to see when a specific touch is let go off for the sling shot 
signal release_touch(touch_number:int, touch_position:Vector2)

const EMULATED_DEVICE_ID:int = -1

func _ready() -> void:
	input_pickable = true

func _input_event(viewport: Viewport, event: InputEvent, shape_idx: int) -> void:
	if not input_enabled:
		return

	if event is InputEventScreenTouch:
		if event.device == EMULATED_DEVICE_ID:
			return
		if event.pressed:
			end_touch(event.index)
			var touch_number:int = generate_touch_number()
			touch_order_dict.set(touch_number, event.index)
			touch_event_dict.set(event.index, event.position)
			#print("touch: ", event.position)
			#print("added ", nb_of_touches)
		else:
			end_touch(event.index, event.position)
		
	if event is InputEventScreenDrag:
		if event.device == EMULATED_DEVICE_ID:
			return
		touch_event_dict.set(event.index, event.position)
		#print("drag ", event.position, " index : ", event.index)
		
	

# if drag goes outside the box, we remove the touch
func _unhandled_input(event: InputEvent) -> void:
	if not input_enabled:
		return
	if event is InputEventScreenDrag:
		if !is_point_in_area(event.position):
			end_touch(event.index)

#ça c'est généré mdr
func is_point_in_area(point: Vector2) -> bool:
	# 1. Configurer les paramètres de la requête de point
	var query = PhysicsPointQueryParameters2D.new()
	query.position = point
	query.collide_with_areas = true  # Permet de détecter les Area2D
	query.collide_with_bodies = false # Ignore les CharacterBody2D/RigidBody2D
	
	# Optionnel : Restreindre la recherche uniquement à la couche de collision de l'Area2D
	query.collision_mask = collision_layer

	# 2. Récupérer l'état physique du monde 2D actuel
	var space_state = get_world_2d().direct_space_state
	
	# 3. Interroger l'espace (ici on récupère jusqu'à 32 résultats maximum)
	var results = space_state.intersect_point(query, 32)
	
	# 4. Parcourir les résultats pour voir si notre zone spécifique y figure
	for result in results:
		if result["collider"] == self:
			return true
			
	return false
	
# Ends a touch: emits release_touch (if the touch is tracked) and then removes it
# Does nothing for an event index we don't track
func end_touch(index:int, final_position = null) -> void:
	var touch:int = get_touch_from_event_index(index)
	if touch == -1:
		return
	if final_position != null:
		touch_event_dict.set(index, final_position)
	release_touch.emit(touch, touch_event_dict.get(index, Vector2.ZERO))
	remove_touch(touch)
	
func get_position_from_touch_number(touch:int) -> Vector2:
	if !touch_order_dict.has(touch):
		print("Unknown touch number : " + str(touch))
		push_error("Unknown touch number : " + str(touch))
		return Vector2.ZERO
		
	var event_index:int = touch_order_dict.get(touch)
	if event_index != null:
		return touch_event_dict.get(event_index)
	else:
		print("Unknown touch number : " + str(touch))
		push_error("Unknown touch number : " + str(touch))
		return Vector2.ZERO
	return touch_event_dict.get(touch_order_dict[touch], Vector2.ZERO)

func remove_touch(touch_nb:int) ->void :
	touch_order_dict.erase(touch_nb)
	#touch_event_dict.erase(event.index)
	if touch_order_dict.size() == 0:
		nb_of_touches = 0

func remove_touch_from_event_index(index:int) -> void:
	if index != -1:
		remove_touch(get_touch_from_event_index(index))

func get_touch_from_event_index(index:int) -> int:
	var touch = touch_order_dict.find_key(index)
	if touch == null:
		return -1
	return touch

# Checks if a touch is missing and returns it
# otherwise increases the nb_of_touches and returns that
# this is because previously, we just kept incresing nb_of_touches if not all fingers were released, 
# and the generated numbers didn't make a lot of sense
# so now if a finger is accidentaly release and placed back, the original order is kept
func generate_touch_number() -> int:
	for i in range(1,nb_of_touches):
		if !touch_order_dict.has(i):
			return i
	nb_of_touches += 1
	return nb_of_touches
	
	
func get_touch_ammount() -> int:
	return touch_order_dict.keys().size()

# Enables or disables every touch of this zone (used when the game is over)
func set_input_enabled(enabled: bool) -> void:
	input_enabled = enabled
	if not enabled:
		touch_order_dict.clear()
		touch_event_dict.clear()
		nb_of_touches = 0
		_on_input_disabled()

# Hook meant to be overridden by child classes to clean up their own state
func _on_input_disabled() -> void:
	pass
