extends Node2D

@onready var ray_cast_2d: VacuumRaycast = $RayCast2D


func _on_vacuum_zone_vacuum_enabled(enabled: bool) -> void:
	ray_cast_2d.enabled = enabled
