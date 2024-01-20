extends Area2D
class_name CursorArea

var default_radius:float

func _ready():
	Global.camera_zoom_changed.connect(camera_zoom_changed)
	default_radius = $CollisionShape2D.shape.radius

func camera_zoom_changed(new_zoom:float):
	$CollisionShape2D.shape.radius = default_radius / new_zoom

func _process(_delta):
	global_position = get_global_mouse_position()

func get_overlaps() -> Array[Node2D]:
	return get_overlapping_bodies()

func _on_body_entered(body):
	if Global.click_mode == Global.ClickMode.glue and body.has_method("highlight_visual_polygons"):
		body.highlight_visual_polygons()


func _on_body_exited(body):
	if Global.click_mode == Global.ClickMode.glue and body.has_method("unhighlight_visual_polygons"):
		body.unhighlight_visual_polygons()
