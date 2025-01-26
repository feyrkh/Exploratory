extends Camera2D
class_name SmoothZoomCamera

const HALF_VECTOR:Vector2 = Vector2(0.5, 0.5)

@export var zoom_speed:float = 10
@onready var zoom_target:Vector2 = zoom
@onready var camera_position_target:Vector2 = global_position
var camera_zoom_position_target:Vector2 = global_position

var move_callback:Callable
var zoom_panning:bool = false

func _process(delta):
	if !zoom_target.is_equal_approx(zoom):
		zoom = lerp(zoom, zoom_target, zoom_speed * delta)
		if zoom_panning and move_callback:
			move_callback.call(camera_zoom_position_target)

# zoom so cursor stays on the same pixel when zooming completes
#func update_zoom_position_target(old_zoom:float, new_zoom:float):
	#var zoom_mouse_screen := get_viewport().get_mouse_position()
	#var viewport_size := Vector2(get_viewport().size)
	#var cursor_screen_pct = (zoom_mouse_screen / viewport_size - HALF_VECTOR)
	#var calculated_global_mouse = global_position + (viewport_size / zoom_target) * cursor_screen_pct
	#var next_global_mouse_if_not_moved = global_position + (viewport_size / new_zoom) * cursor_screen_pct
	#var desired_offset_from_actual = next_global_mouse_if_not_moved - get_global_mouse_position()
	#camera_position_target = global_position - desired_offset_from_actual * 1.1

# zoom so zoomed pixel becomes the new center
func update_zoom_position_target(old_zoom:float, new_zoom:float):
	if (abs(old_zoom - new_zoom) < 0.001):
		return
	#var zoom_mouse_screen := get_viewport().get_mouse_position()
	#var viewport_size := Vector2(get_viewport().size)
	#var cursor_screen_pct = (zoom_mouse_screen / viewport_size - HALF_VECTOR)
	#var calculated_global_mouse = global_position + (viewport_size / zoom_target) * cursor_screen_pct
	#var next_global_mouse_if_not_moved = global_position + (viewport_size / new_zoom) * cursor_screen_pct
	#var desired_offset_from_actual = next_global_mouse_if_not_moved - get_global_mouse_position()
	camera_zoom_position_target = get_global_mouse_position()
	zoom_panning = true

func on_explicit_move():
	zoom_panning = false
