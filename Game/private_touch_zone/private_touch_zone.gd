extends Area2D
class_name PrivateTouchZone

var touch_order_dict:Dictionary[int, int] = {}
var touch_event_dict:Dictionary[int, Vector2] = {}
#tracks total number of fingers places, only resets when there's no finger left
# this is to prevent placing fingers and then removing them to cheat
#also tracks the order fingers are placed
var nb_of_touches:int = 0

func _ready() -> void:
	input_pickable = true

func _input_event(viewport: Viewport, event: InputEvent, shape_idx: int) -> void:
	#print(touch_order_dict)
	if event is InputEventScreenTouch:
		if event.pressed:
			nb_of_touches += 1
			touch_order_dict.set(nb_of_touches, event.index)
			touch_event_dict.set(event.index, event.position)
			#print("touch: ", event.position)
			print("added ", nb_of_touches)
		else:
			remove_touch_from_event_index(event.index)
		
	if event is InputEventScreenDrag:
		touch_event_dict.set(event.index, event.position)
		#print("drag ", event.position, " index : ", event.index)

# if drag goes outside the box, we remove the touch
func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventScreenDrag:
		if !is_point_in_area(event.position):
			remove_touch_from_event_index(event.index)

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
	
	
func get_position_from_touch_number(touch:int) -> Vector2:
	var event_index:int = touch_order_dict.get(touch)
	if event_index != null:
		return touch_event_dict.get(event_index)
	else:
		print("Unknown touch number : " + str(touch))
		push_error("Unknown touch number : " + str(touch))
		return Vector2.ZERO

func remove_touch(touch_nb:int) ->void :
	touch_order_dict.erase(touch_nb)
	#touch_event_dict.erase(event.index)
	print("removed ", touch_nb)
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
