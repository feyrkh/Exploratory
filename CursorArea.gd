extends Area2D
class_name CursorArea

func _process(delta):
	global_position = get_global_mouse_position()

func get_overlaps() -> Array[Node2D]:
	return get_overlapping_bodies()
	#return overlapping_bodies.keys()


func _on_body_entered(body):
	if Global.click_mode == Global.ClickMode.glue and body.has_method("highlight_visual_polygons"):
		body.highlight_visual_polygons()


func _on_body_exited(body):
	if Global.click_mode == Global.ClickMode.glue and body.has_method("unhighlight_visual_polygons"):
		body.unhighlight_visual_polygons()
