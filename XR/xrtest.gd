extends Node3D


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	var interface = XRServer.find_interface("OpenXR")
	if interface and interface.initialize():
		DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
		get_viewport().use_xr = true


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
