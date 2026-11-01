extends TextureButton


func _on_pressed() -> void:
	_start_demo.call_deferred()


func _start_demo() -> void:
	var board_scene: PackedScene = load("res://Game/board/board.tscn")
	var board = board_scene.instantiate()

	# Must be set before the node enters the tree,
	# so that _ready() emits test_mode_activated with the right value
	board.test_mode = true

	var tree := get_tree()
	var old_scene := tree.current_scene

	# Replace the current scene (title screen) with the board
	tree.root.add_child(board)
	tree.current_scene = board
	old_scene.queue_free()
