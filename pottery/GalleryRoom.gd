extends Node2D

const CAMERA_MOVE_SPEED := 55
const ZOOM_INCREMENT := Vector2(0.1, 0.1)

@export var camera_top_left_limit:Vector2 = Vector2(0, 0)
@export var camera_bot_right_limit:Vector2 = Vector2(4270, 2397)
var camera_drag_mouse_start = null
var camera_drag_camera_start = null

var gallery_items_unused := []
var gallery_rooms := [] # Array[Dictionary]
var cur_room_idx:int = 0

@onready var camera = find_child("Camera2D")

func _unhandled_input(event):
	if event.is_action_pressed("ui_cancel"):
		if find_child("GalleryMenu").visible:
			find_child("GalleryMenu").visible = false
			get_viewport().set_input_as_handled()
		else:
			_on_exit_button_pressed()
	elif event.is_action_pressed("right_click"):
		if find_child("GalleryMenu").visible:
			find_child("GalleryMenu").visible = false
			get_viewport().set_input_as_handled()
	else:
		handle_camera_input(event)

func _process(_delta):
	if camera_drag_mouse_start != null:
		var offset = get_viewport().get_mouse_position() - camera_drag_mouse_start
		offset = offset/camera.zoom.x
		set_camera_position(camera_drag_camera_start - offset)
	else:
		var movement = Input.get_vector("left", "right", "up", "down")
		if movement != Vector2.ZERO:
			var view_rect = camera.get_viewport_rect()
			view_rect.position += camera.get_screen_center_position()
			set_camera_position(camera.position + movement * CAMERA_MOVE_SPEED / camera.zoom.x)

func set_camera_position(new_pos:Vector2):
	var view_rect = camera.get_viewport_rect()
	view_rect.position += new_pos
	view_rect.size /= camera.zoom.x
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
	camera.position = new_pos

func handle_camera_input(event:InputEvent):
	#if event is InputEventMouseButton:
		if event.is_action_pressed("zoom_in", true):
			if camera.zoom.x >= 2:
				camera.zoom += ZOOM_INCREMENT * 2
			camera.zoom += ZOOM_INCREMENT
			if camera.zoom.x > 4.0:
				camera.zoom = Vector2(4, 4)
			Global.camera_zoom_changed.emit(camera.zoom.x)
			adjust_camera_limits()
			get_viewport().set_input_as_handled()
		elif event.is_action_pressed("zoom_out", true):
			if camera.zoom.x > 2:
				camera.zoom -= ZOOM_INCREMENT * 2
			camera.zoom -= ZOOM_INCREMENT
			if camera.zoom.x < 0.3:
				camera.zoom = Vector2(0.3, 0.3)
			Global.camera_zoom_changed.emit(camera.zoom.x)
			adjust_camera_limits()
			get_viewport().set_input_as_handled()
		elif event.is_action_pressed("camera_drag"):
			camera_drag_mouse_start = get_viewport().get_mouse_position()
			camera_drag_camera_start = camera.position
		elif event.is_action_released("camera_drag"):
			camera_drag_mouse_start = null
			camera_drag_camera_start = null

func adjust_camera_limits():
		var view_rect = camera.get_viewport_rect()
		view_rect.position += camera.get_target_position()
		view_rect.size /= camera.zoom.x
		var camera_top_left = view_rect.position - view_rect.size / 2
		var camera_bot_right = view_rect.position + view_rect.size / 2
		if camera_top_left.x <= camera_top_left_limit.x and camera_bot_right.x >= camera_bot_right_limit.x:
			camera.position.x = (camera_top_left_limit.x + camera_bot_right_limit.x) / 2
		elif camera_top_left.x < camera_top_left_limit.x:
			camera.position.x = camera_top_left_limit.x + view_rect.size.x / 2
		elif camera_bot_right.x > camera_bot_right_limit.x:
			camera.position.x = camera_bot_right_limit.x - view_rect.size.x / 2
		if camera_top_left.y <= camera_top_left_limit.y and camera_bot_right.y >= camera_bot_right_limit.y:
			camera.position.y = (camera_top_left_limit.y + camera_bot_right_limit.y) / 2
		elif camera_top_left.y < camera_top_left_limit.y:
			camera.position.y = camera_top_left_limit.y + view_rect.size.y / 2
		elif camera_bot_right.y > camera_bot_right_limit.y:
			camera.position.y = camera_bot_right_limit.y - view_rect.size.y / 2

func save_gallery_rooms():
	var file = FileAccess.open_compressed("user://gallery.cfg", FileAccess.WRITE)
	if file == null:
		push_error("Failed to save gallery room data: ", FileAccess.get_open_error())
		return
	file.store_var(gallery_rooms)
	file.close()

func load_gallery_rooms():
	var file = FileAccess.open_compressed("user://gallery.cfg", FileAccess.READ)
	if file == null:
		gallery_rooms = []
	else:
		gallery_rooms = file.read_var()
		file.close()
	var gallery_items_all := {}
	var dir = DirAccess.open("user://gallery")
	if dir:
		dir.list_dir_begin()
		var file_name = dir.get_next()
		while file_name != "":
			if !dir.current_is_dir():
				if file_name.ends_with(".dat"):
					gallery_items_all[file_name.substr(0, file_name.length()-4)] = true
			file_name = dir.get_next()
	else:
		push_error("An error occurred when trying to access the path.")
	gallery_items_unused = []
	var gallery_items_used = {}
	for room_item_data in gallery_rooms:
		for k in room_item_data.keys():
			gallery_items_used[k] = true
	for k in gallery_items_all.keys():
		if !gallery_items_used.get(k, false):
			gallery_items_unused.append(k)
	gallery_items_unused.sort()
	gallery_items_unused.reverse()

func _init():
	load_gallery_rooms()

func _ready():
	Global.unpack_gallery_item.connect(unpack_gallery_item)
	load_gallery_room(0)

func load_gallery_room(idx:int):
	cur_room_idx = idx
	var item_list
	if idx >= gallery_rooms.size():
		item_list = []
	else:
		item_list = gallery_rooms[idx]
	print("Loading items: ", item_list)

func display_gallery_menu():
	find_child("GalleryMenu").setup(gallery_items_unused)
	find_child("GalleryMenu").visible = true

func unpack_gallery_item(item_name:String):
	var item = await GalleryMgr.unpack_from_gallery(item_name, report_error)
	if item != null:
		find_child("Items").add_child(item)
		item.gallery_mode()
		item.global_position = get_viewport().get_camera_2d().get_screen_center_position() - item.bounding_box.size/2

func _on_exit_button_pressed():
	get_tree().change_scene_to_file("res://menu/main/TitleScreen.tscn")

func _on_unpack_button_pressed():
	display_gallery_menu()

func report_error(msg:String):
	push_error(msg)
