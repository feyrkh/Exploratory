extends Polygon2D

var _pen:Node2D
@onready var viewport = $SubViewport
var _prev_mouse_pos = Vector2.ZERO
var uv_offset:Vector2

func _ready():
	_pen = Node2D.new()
	viewport.add_child(_pen)
	_pen.draw.connect(_on_draw)

#func _process(_delta):
#	_pen.queue_redraw()

func resize(new_top_left:Vector2, new_bot_right:Vector2):
	polygon = [new_top_left, Vector2(new_bot_right.x, new_top_left.y), new_bot_right, Vector2(new_top_left.x, new_bot_right.y)]
	uv_offset = Vector2.ZERO - new_top_left
	uv = [new_top_left + uv_offset, Vector2(new_bot_right.x, new_top_left.y) + uv_offset, new_bot_right + uv_offset, Vector2(new_top_left.x, new_bot_right.y) + uv_offset]
	viewport.size = new_bot_right - new_top_left
	
func _on_draw():
	var mouse_pos = get_local_mouse_position() + uv_offset
	
	if Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
		_pen.draw_line(mouse_pos, _prev_mouse_pos, Color(1, 1, 0), 30, true)
	_prev_mouse_pos = mouse_pos
