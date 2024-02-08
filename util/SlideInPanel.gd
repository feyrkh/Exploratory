extends PanelContainer
class_name SlideInPanel

signal slide_shown()
signal slide_hidden()
signal slide_toggled()

@export var slide_in_direction:Vector2 = Vector2.LEFT
@export var slide_in_edge_buffer:float = 10
@export var slide_time:float = 0.5
@onready var start_pos := global_position

var slide_open_next := true
var tween:Tween

func reset_tween():
	if tween and tween.is_running():
		tween.stop()
	tween = create_tween()

func get_end_pos()->Vector2:
	#var overhang:float
	match slide_in_direction:
		Vector2.LEFT:
			#overhang = get_viewport_rect().size.x - start_pos.x
			return Vector2(get_viewport_rect().size.x - get_rect().size.x - slide_in_edge_buffer, global_position.y)
		Vector2.RIGHT:
			#overhang = get_rect().size.x + start_pos.x # assuming x is negative
			return Vector2(slide_in_edge_buffer, global_position.y)
		Vector2.UP:
			#overhang = get_viewport_rect().size.y - position.y
			print("%d, %d, %d" % [get_viewport_rect().size.y, get_rect().size.y, slide_in_edge_buffer])
			return Vector2(global_position.x, get_viewport_rect().size.y - get_rect().size.y - slide_in_edge_buffer)
		Vector2.DOWN:
			#overhang = get_rect().size.y + start_pos.y # assuming y is negative
			return Vector2(global_position.x, slide_in_edge_buffer)
		_:
			push_error("Unknown direction for slide in container: ", slide_in_direction)
			return Vector2.ZERO

func slide_in(override_time=null):
	reset_tween()
	tween.tween_property(self, "global_position", get_end_pos(), override_time if override_time != null else slide_time)
	slide_open_next = false
	slide_shown.emit()

func slide_out(override_time=null):
	reset_tween()
	tween.tween_property(self, "global_position", start_pos, override_time if override_time != null else slide_time)
	slide_open_next = true
	slide_hidden.emit()

func toggle_slide():
	if slide_open_next:
		slide_in()
		slide_toggled.emit()
	else:
		slide_out()
		slide_toggled.emit()

func is_hidden():
	return global_position.is_equal_approx(start_pos)
