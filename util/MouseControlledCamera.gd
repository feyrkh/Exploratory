extends SmoothZoomCamera

@export var CAMERA_MOVE_SPEED := 25
@export var ZOOM_INCREMENT := Vector2(0.2, 0.2)
@export var camera_top_left_limit:Vector2 = Vector2(-1000, -500)
@export var camera_bot_right_limit:Vector2 = Vector2(1000, 500)
@export var move_with_keyboard := true

var camera_drag_mouse_start = null
var camera_drag_camera_start = null

func _process(delta:float) -> void:
	if camera_drag_mouse_start != null:
		var offset = get_viewport().get_mouse_position() - camera_drag_mouse_start
		offset = offset/zoom.x
		on_explicit_move()
		set_camera_position(camera_drag_camera_start - offset)
	elif move_with_keyboard:
		var movement = Input.get_vector("left", "right", "up", "down")
		if movement != Vector2.ZERO:
			stop_zoom_tween()
			var view_rect = get_viewport_rect()
			view_rect.position += get_screen_center_position()
			on_explicit_move()
			set_camera_position(position + movement * CAMERA_MOVE_SPEED / zoom.x)
	super._process(delta)

func _unhandled_input(event):
	#if event.is_action_pressed("change_click_mode"):
		#Global.play_button_click_sound()
		#Global.rotate_click_mode()
		#get_viewport().set_input_as_handled()
	handle_camera_input(event)
	#match Global.click_mode:	
		#Global.ClickMode.move: handle_move_input(event)
		#Global.ClickMode.glue: handle_glue_input(event)
		#Global.ClickMode.save_item: handle_save_item_input(event)
		#Global.ClickMode.paint: handle_paint_input(event)


func handle_camera_input(event:InputEvent):
	#if event is InputEventMouseButton:
		if event.is_action_pressed("zoom_in", true):
			var old_target:float = zoom_target.x
			stop_zoom_tween()
			if zoom_target.x > 3:
				zoom_target += ZOOM_INCREMENT * 2
			if zoom_target.x >= 2:
				zoom_target += ZOOM_INCREMENT * 2
			zoom_target += ZOOM_INCREMENT
			if zoom_target.x > 4.0:
				zoom_target = Vector2(4, 4)
			Global.camera_zoom_changed.emit(zoom_target.x)
			var new_target:float = zoom_target.x
			update_zoom_position_target(old_target, new_target)
			adjust_camera_limits()
			get_viewport().set_input_as_handled()
		elif event.is_action_pressed("zoom_out", true):
			var old_target:float = zoom_target.x
			stop_zoom_tween()
			if zoom_target.x > 3:
				zoom_target -= ZOOM_INCREMENT * 2
			if zoom_target.x > 2:
				zoom_target -= ZOOM_INCREMENT * 2
			zoom_target -= ZOOM_INCREMENT
			if zoom_target.x < 0.3:
				zoom_target = Vector2(0.3, 0.3)
			Global.camera_zoom_changed.emit(zoom_target.x)
			var new_target:float = zoom_target.x
			update_zoom_position_target(old_target, new_target)
			adjust_camera_limits()
			get_viewport().set_input_as_handled()
		elif event.is_action_pressed("camera_drag"):
			on_explicit_move()
			stop_zoom_tween()
			camera_drag_mouse_start = get_viewport().get_mouse_position()
			camera_drag_camera_start = position
			get_viewport().set_input_as_handled()
		elif event.is_action_released("camera_drag"):
			on_explicit_move()
			camera_drag_mouse_start = null
			camera_drag_camera_start = null
			get_viewport().set_input_as_handled()


func adjust_camera_limits():
		var view_rect = get_viewport_rect()
		view_rect.position += get_target_position()
		view_rect.size /= zoom.x
		var camera_top_left = view_rect.position - view_rect.size / 2
		var camera_bot_right = view_rect.position + view_rect.size / 2
		if camera_top_left.x <= camera_top_left_limit.x and camera_bot_right.x >= camera_bot_right_limit.x:
			position.x = (camera_top_left_limit.x + camera_bot_right_limit.x) / 2
		elif camera_top_left.x < camera_top_left_limit.x:
			position.x = camera_top_left_limit.x + view_rect.size.x / 2
		elif camera_bot_right.x > camera_bot_right_limit.x:
			position.x = camera_bot_right_limit.x - view_rect.size.x / 2
		if camera_top_left.y <= camera_top_left_limit.y and camera_bot_right.y >= camera_bot_right_limit.y:
			position.y = (camera_top_left_limit.y + camera_bot_right_limit.y) / 2
		elif camera_top_left.y < camera_top_left_limit.y:
			position.y = camera_top_left_limit.y + view_rect.size.y / 2
		elif camera_bot_right.y > camera_bot_right_limit.y:
			position.y = camera_bot_right_limit.y - view_rect.size.y / 2

func stop_zoom_tween():
	pass
	#if intro_zoom_tween != null:
		#intro_zoom_tween.stop()
		#intro_zoom_tween = null
		
func set_camera_position(new_pos:Vector2):
	var view_rect = get_viewport_rect()
	view_rect.position += new_pos
	view_rect.size /= zoom.x
	var camera_top_left = view_rect.position - view_rect.size / 2
	var camera_bot_right = view_rect.position + view_rect.size / 2
	if camera_top_left.x <= camera_top_left_limit.x and camera_bot_right.x >= camera_bot_right_limit.x:
		new_pos.x = (camera_top_left_limit.x + camera_bot_right_limit.x) / 2
	elif camera_top_left.x < camera_top_left_limit.x:
		new_pos.x = camera_top_left_limit.x + view_rect.size.x / 2
	elif camera_bot_right.x > camera_bot_right_limit.x:
		new_pos.x = camera_bot_right_limit.x - view_rect.size.x / 2
	if camera_top_left.y <= camera_top_left_limit.y and camera_bot_right.y >= camera_bot_right_limit.y:
		new_pos.y = (camera_top_left_limit.y + camera_bot_right_limit.y) / 2
	elif camera_top_left.y < camera_top_left_limit.y:
		new_pos.y = camera_top_left_limit.y + view_rect.size.y / 2
	elif camera_bot_right.y > camera_bot_right_limit.y:
		new_pos.y = camera_bot_right_limit.y - view_rect.size.y / 2
	if !position.is_equal_approx(new_pos):
		position = new_pos
		camera_position_target = global_position
		Global.tutorial_panned_camera.emit()
