extends Area2D
class_name CursorArea

func _process(delta):
	global_position = get_global_mouse_position()

func get_overlaps() -> Array[Node2D]:
	return get_overlapping_bodies()
	#return overlapping_bodies.keys()
