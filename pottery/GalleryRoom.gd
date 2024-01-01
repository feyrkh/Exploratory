extends Node2D

var gallery_items_unused := []
var gallery_rooms := [] # Array[Dictionary]
var cur_room_idx:int = 0

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
		item.global_position = get_viewport_rect().size/2

func _on_exit_button_pressed():
	get_tree().change_scene_to_file("res://menu/main/TitleScreen.tscn")

func _on_unpack_button_pressed():
	display_gallery_menu()

func report_error(msg:String):
	push_error(msg)
