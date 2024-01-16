extends Node2D

const CAMERA_MOVE_SPEED := 55
const ZOOM_INCREMENT := Vector2(0.1, 0.1)
const FADE_TIME := 0.25

@export var camera_top_left_limit:Vector2 = Vector2(0, 0)
@export var camera_bot_right_limit:Vector2 = Vector2(4270, 2397)
var camera_drag_mouse_start = null
var camera_drag_camera_start = null

var background_imgs:Array[String] = []
var cur_background_img_idx:int = -1:
	set(val):
		if val >= background_imgs.size():
			val = -1
		cur_background_img_idx = val
		update_background()
var shelf_configuration:int = 0:
	set(val):
		shelf_configuration = val
		update_shelf_configuration()

var gallery_items_unused := []
var gallery_rooms := [] # Array[Dictionary]
var cur_room_idx:int = 0
var cur_room_name:String = "Gallery 1"

@onready var camera = find_child("Camera2D")
@onready var fade_rect = find_child("FadeRect")
@onready var control_hints:ControlHints = find_child("ControlHints")

func _unhandled_input(event):
	if event.is_action_pressed("ui_cancel"):
		if find_child("GalleryMenu").visible:
			hide_gallery_menu()
			get_viewport().set_input_as_handled()
			Global.play_button_click_sound("menu_back")
		elif find_child("RoomLabelEdit").visible:
			cancel_room_name_edit()
		else:
			_on_exit_button_pressed()
	elif event.is_action_pressed("right_click"):
		if find_child("GalleryMenu").visible:
			hide_gallery_menu()
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
			if find_child("GalleryMenu").visible:
				find_child("GalleryMenu").visible = false
			else:
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


const ROOM_FIELD_NAME := 0
const ROOM_FIELD_ITEMS := 1
const ROOM_FIELD_BG_FILE := 2
const ROOM_FIELD_SHELF_CONFIG := 3
const ITEM_FIELD_ID := 0
const ITEM_FIELD_POS := 1
const ITEM_FIELD_ROT := 2
func save_current_room():
	if find_child("RoomLabelEdit").visible:
		_on_room_label_edit_text_submitted(find_child("RoomLabelEdit").text)
	while cur_room_idx >= gallery_rooms.size():
		gallery_rooms.append([])
	var cur_room_items = []
	for child in find_child("Items").get_children():
		cur_room_items.append([child.gallery_id, child.global_position, child.global_rotation])
	var room_name
	if cur_background_img_idx == -1:
		room_name = ""
	else:
		room_name = background_imgs[cur_background_img_idx]
	var cur_room_data = [cur_room_name, cur_room_items, room_name, shelf_configuration]
	gallery_rooms[cur_room_idx] = cur_room_data
	save_gallery_rooms()

func save_gallery_rooms():
	while gallery_rooms.size() > 1 and gallery_rooms[0][ROOM_FIELD_ITEMS].size() == 0 and gallery_rooms[1][ROOM_FIELD_ITEMS].size() == 0:
		gallery_rooms.pop_front()
	while gallery_rooms.size() > 1 and gallery_rooms[-2][ROOM_FIELD_ITEMS].size() == 0 and gallery_rooms[-1][ROOM_FIELD_ITEMS].size() == 0:
		gallery_rooms.pop_back()
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
		gallery_rooms = file.get_var()
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
	for room_data in gallery_rooms:
		var room_items = room_data[ROOM_FIELD_ITEMS]
		for item in room_items:
			var item_id = item[ITEM_FIELD_ID]
			gallery_items_used[item_id] = true
	for k in gallery_items_all.keys():
		if !gallery_items_used.get(k, false):
			gallery_items_unused.append(k)
	gallery_items_unused.sort()
	gallery_items_unused.reverse()

func _init():
	load_gallery_rooms()

func _ready():
	load_background_images()
	Global.unpack_gallery_item.connect(unpack_gallery_item)
	Global.delete_archeology_item.connect(item_deleted)
	find_child("GalleryMenu").closed.connect(update_control_hints)
	fade_rect.visible = true
	load_gallery_room(0)
	update_control_hints()
	await(get_tree().process_frame)
	find_child("ControlHints").slide_in(0.01)

func item_deleted(item:ArcheologyItem):
	gallery_items_unused.append(item.gallery_id)
	save_current_room()

func load_gallery_room(idx:int):
	await find_child("FadeRect").fade_out(FADE_TIME)
	cur_room_idx = idx
	var room_data
	if idx >= gallery_rooms.size():
		room_data = ["Gallery "+str(cur_room_idx+1), [], -1, 0]
	else:
		room_data = gallery_rooms[idx]
	cur_room_name = room_data[ROOM_FIELD_NAME]
	find_child("RoomLabel").text = cur_room_name
	for child in find_child("Items").get_children():
		child.queue_free()
	var item_list = room_data[ROOM_FIELD_ITEMS]
	for item_data in item_list:
		var item = await unpack_gallery_item(item_data[ITEM_FIELD_ID])
		item.global_position = item_data[ITEM_FIELD_POS]
		item.global_rotation = item_data[ITEM_FIELD_ROT]
	cur_background_img_idx = background_imgs.find(room_data[ROOM_FIELD_BG_FILE])
	shelf_configuration = room_data[ROOM_FIELD_SHELF_CONFIG]
	await find_child("FadeRect").fade_in(FADE_TIME*2)
		

func display_gallery_menu():
	find_child("GalleryMenu").setup(gallery_items_unused)
	find_child("GalleryMenu").visible = true
	control_hints.set_hints([
		["Close window", preload("res://art/mouse_right.png"), preload("res://art/mouse_none.png")],
		["Close window", preload("res://art/escape_key.png"), preload("res://art/escape_key.png")],
	])

func hide_gallery_menu():
	find_child("GalleryMenu").visible = false
	update_control_hints()

func unpack_gallery_item(item_name:String) -> Node2D:
	var item = await GalleryMgr.unpack_from_gallery(item_name, report_error)
	if item != null:
		find_child("Items").add_child(item)
		item.gallery_mode()
		item.global_position = get_viewport().get_camera_2d().get_screen_center_position() - item.bounding_box.size/2
	gallery_items_unused.erase(item_name)
	return item

func _on_exit_button_pressed():
	Global.play_button_click_sound("menu_back")
	save_current_room()
	Global.change_scene("res://menu/main/TitleScreen.tscn")

func _on_unpack_button_pressed():
	display_gallery_menu()

func report_error(msg:String):
	push_error(msg)


func _on_previous_button_pressed():
	save_current_room()
	cur_room_idx -= 1
	if cur_room_idx < 0:
		cur_room_idx = gallery_rooms.size()
		if gallery_rooms[-1][ROOM_FIELD_ITEMS].size() == 0:
			cur_room_idx -= 1
	load_gallery_room(cur_room_idx)

func _on_next_button_pressed():
	save_current_room()
	cur_room_idx += 1
	if cur_room_idx >= gallery_rooms.size():
		if gallery_rooms[-1][ROOM_FIELD_ITEMS].size() == 0:
			cur_room_idx = 0
	load_gallery_room(cur_room_idx)

func _on_room_label_gui_input(event):
	if event is InputEventMouseButton:
		if event.button_index == 1 and event.double_click:
			find_child("RoomLabelEdit").text = cur_room_name
			find_child("RoomLabel").visible = false
			find_child("RoomLabelEdit").visible = true
			find_child("RoomLabelEdit").grab_focus()
			find_child("RoomLabelEdit").select_all()


func _on_room_label_edit_text_submitted(new_text):
	cur_room_name = new_text
	find_child("RoomLabel").text = cur_room_name
	find_child("RoomLabel").visible = true
	find_child("RoomLabelEdit").visible = false
	

func _on_room_label_edit_gui_input(event):
	if event.is_action_pressed("ui_cancel"):
		cancel_room_name_edit()

func cancel_room_name_edit():
	find_child("RoomLabelEdit").text = cur_room_name
	find_child("RoomLabel").visible = true
	find_child("RoomLabelEdit").visible = false

func update_control_hints():
	control_hints.set_hints([
		["Move item", preload("res://art/mouse_left.png"), preload("res://art/mouse_none.png")],
		["Rotate item", preload("res://art/mouse_right.png"), preload("res://art/mouse_none.png")],
		["Pan camera", preload("res://art/mouse_middle.png"), preload("res://art/mouse_none.png")],
		["Pan camera", preload("res://art/arrow_keys.png"), preload("res://art/arrow_keys.png")],
		["Zoom camera", preload("res://art/mouse_scroll_up.png"), preload("res://art/mouse_scroll_down.png")],
		["Pack item", preload("res://art/delete_key.png"), preload("res://art/delete_key.png")],
		["Exit gallery", preload("res://art/escape_key.png"), preload("res://art/escape_key.png")],
	])

func load_background_images():
	var dir := DirAccess.open("res://art/background")
	if dir:
		dir.list_dir_begin()
		var file_name = dir.get_next()
		while file_name != "":
			if !dir.current_is_dir() and (file_name.ends_with(".png") or file_name.ends_with(".jpg") or file_name.ends_with(".jpeg")):
				background_imgs.append("res://art/background/"+file_name)
			file_name = dir.get_next()
	
func update_background():
	if cur_background_img_idx < 0 or cur_background_img_idx >= background_imgs.size():
		$BackgroundSprite.visible = false
	else:
		$BackgroundSprite.visible = true
		$BackgroundSprite.texture = load(background_imgs[cur_background_img_idx])

func update_shelf_configuration():
	set_shelf_config(["L1", "L2", "L3", "R1", "R2", "R3", "C1", "C2", "C3"], false)
	if shelf_configuration > 10:
		shelf_configuration = shelf_configuration % 11
	match shelf_configuration:
		0: set_shelf_config(["L1", "L2", "L3", "R1", "R2", "R3"])
		1: set_shelf_config(["L1", "L2", "L3"])
		2: set_shelf_config(["R1", "R2", "R3"])
		3: set_shelf_config(["L1", "L2", "R1", "R2"])
		4: set_shelf_config(["L1", "R1",])
		5: set_shelf_config(["L1"])
		6: set_shelf_config(["R1"])
		7: set_shelf_config(["C1", "C2", "C3"])
		8: set_shelf_config(["C1", "C2"])
		9: set_shelf_config(["C1"])
		10: set_shelf_config([])

func set_shelf_config(items:Array[String], is_visible:=true):
	for item in items:
		find_child(item).visible = is_visible


func _on_shelf_button_pressed():
	shelf_configuration += 1


func _on_background_button_pressed():
	cur_background_img_idx += 1
