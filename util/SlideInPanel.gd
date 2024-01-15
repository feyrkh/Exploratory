extends PanelContainer
class_name SlideInPanel

@export var slide_in_direction:Vector2 = Vector2.LEFT
@export var slide_in_edge_buffer:float = 10
@export var slide_time:float = 0.5
@onready var start_pos := position

var slide_open_next := true
var tween:Tween

func reset_tween():
	if tween and tween.is_running():
		tween.stop()
	tween = create_tween()

func get_end_pos()->Vector2:
	var overhang:float
	match slide_in_direction:
		Vector2.LEFT:
			overhang = get_viewport_rect().size.x - start_pos.x
			return Vector2(get_viewport_rect().size.x - get_rect().size.x - slide_in_edge_buffer, position.y)
		Vector2.RIGHT:
			overhang = get_rect().size.x + start_pos.x # assuming x is negative
			return Vector2(slide_in_edge_buffer, position.y)
		Vector2.UP:
			overhang = get_viewport_rect().size.y - position.y
			return Vector2(position.x, get_viewport_rect().size.y - get_rect().size.y - slide_in_edge_buffer)
		Vector2.DOWN:
			overhang = get_rect().size.y + start_pos.y # assuming y is negative
			return Vector2(position.x, slide_in_edge_buffer)
		_:
			push_error("Unknown direction for slide in container: ", slide_in_direction)
			return Vector2.ZERO

func slide_in(override_time=null):
	reset_tween()
	tween.tween_property(self, "position", get_end_pos(), override_time if override_time != null else slide_time)
	slide_open_next = true

func slide_out(override_time=null):
	reset_tween()
	tween.tween_property(self, "position", start_pos, override_time if override_time != null else slide_time)
	slide_open_next = false

func is_hidden():
	return position.is_equal_approx(start_pos)
