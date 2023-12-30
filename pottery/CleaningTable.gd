extends Node2D
class_name CleaningTable

const CAMERA_MOVE_SPEED := 25
const ZOOM_INCREMENT := Vector2(0.1, 0.1)

const CRACK_COUNT_SETTING := "crack_count"
const ITEM_COUNT_SETTING := "item_count"

@onready var camera:Camera2D = find_child("Camera2D")
@onready var cursor_area:CursorArea = find_child("CursorArea")
@export var camera_top_left_limit:Vector2 = Vector2(-100, -100)
@export var camera_bot_right_limit:Vector2 = Vector2(4500, 3300)
var collision_temp_disabled = false

# Called when the node enters the scene tree for the first time.
func _ready():
	var settings = Global.next_scene_settings
	if settings == null:
		settings = {}
	
	PhysicsServer2D.set_active(false)
	Global.click_mode_changed.connect(update_button_text)
	update_button_text()
	var scene_center = (camera_bot_right_limit - camera_top_left_limit)/2 + camera_top_left_limit
	for i in range(settings.get(ITEM_COUNT_SETTING, 1)):
		var new_item = await ItemBuilder.build_random_item(null, false)
		$Pieces.add_child(new_item)
		new_item.position = scene_center + Vector2(randf_range(-400, 400), randf_range(-400, 400))
		await get_tree().process_frame
		for j in range(settings.get(CRACK_COUNT_SETTING, 8)):
			new_item.random_scar()
		await new_item.try_shatter(Global.shatter_width, true)
	
	PhysicsServer2D.set_active(true)
	_on_shuffle_button_pressed()
	
#	var new_item = await ItemBuilder.build_random_item()
#	new_item.name = "Pot3"
#	$Pieces.add_child(new_item)
#	new_item.position = Vector2(350,150)
	#var pot1:ArcheologyItem = find_child("Pot1")
	#var poly := pot1.collision.polygon
	#for i in range(30):
		#poly.remove_at(0)
	#pot1.collision.polygon = poly
	#pot1.refresh_polygon()
	#poly[5] = (pot1.center)
	#pot1.refresh_polygon()
#
	#var pot2:ArcheologyItem = find_child("Pot2")
	#poly = pot2.collision.polygon
	#for i in range(30):
		#poly.remove_at(poly.size()-1)
	#poly.append(pot2.center)
	#pot2.collision.polygon = poly
	#pot2.refresh_polygon()
	
#	var pot3:ArcheologyItem = new_item
	#var pot_area = pot3.area
	#pot1.mass = pot3.mass * pot1.area / pot3.area
	#pot2.mass = pot3.mass * pot2.area / pot3.area
#	for i in range(4):
		#pot1.random_scar()
		#pot2.random_scar()
#		pot3.random_scar()
	
	#var square = find_child("Square")
	#square.specific_scar(Vector2(100, 151), Vector2(160, 150), 0, 0.5, 0.5) # from left
	#square.specific_scar(Vector2(151, 100), Vector2(150, 160), 0, 0.5, 0.5) # from top
	#square.specific_scar(Vector2(200, 151), Vector2(140, 150), 0, 0.5, 0.5) # from right
	#square.specific_scar(Vector2(151, 200), Vector2(150, 140), 0, 0.5, 0.5) # from bottom
	#square.specific_scar(Vector2(100, 101), Vector2(160, 160), 0, 0.5, 0.5) # from top-left
	#square.specific_scar(Vector2(100, 199), Vector2(160, 140), 0, 0.5, 0.5) # from bottom-left


	#square.specific_scar(Vector2(151, 200), Vector2(150, 40), 0, 0.5, 0.5) # from bottom, long
	#square.specific_scar(Vector2(100, 151), Vector2(260, 150), 0, 0.5, 0.5) # from left, long

func _process(_delta):
	var movement = Input.get_vector("left", "right", "up", "down")
	if movement != Vector2.ZERO:
		var view_rect = camera.get_viewport_rect()
		view_rect.position += camera.get_screen_center_position()
		view_rect.size /= camera.zoom.x
		var camera_top_left = view_rect.position - view_rect.size / 2
		var camera_bot_right = view_rect.position + view_rect.size / 2
		if movement.x < 0 and camera_top_left.x < camera_top_left_limit.x:
			movement.x = 0
		if movement.x > 0 and camera_bot_right.x > camera_bot_right_limit.x:
			movement.x = 0
		if movement.y < 0 and camera_top_left.y < camera_top_left_limit.y:
			movement.y = 0
		if movement.y > 0 and camera_bot_right.y > camera_bot_right_limit.y:
			movement.y = 0
		
		camera.position += movement * CAMERA_MOVE_SPEED / camera.zoom.x
		adjust_camera_limits()

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

func _unhandled_input(event):
	if event.is_action_pressed("change_click_mode"):
		Global.rotate_click_mode()
		get_viewport().set_input_as_handled()
	handle_camera_input(event)
	match Global.click_mode:
		Global.ClickMode.move: handle_move_input(event)
		Global.ClickMode.glue: handle_glue_input(event)
		Global.ClickMode.paint: handle_paint_input(event)

func handle_paint_input(_event):
	pass

func handle_glue_input(event):
	if event.is_action_pressed("drag_start"):
		# find all pieces under the cursor and glue them together
		var pieces = cursor_area.get_overlaps()
		if pieces.size() > 1:
			print("Gluing ", pieces.size(), " pieces together")
			var main_piece = pieces[0]
			for i in range(1, pieces.size()):
				main_piece.glue(pieces[i])
			main_piece.call_deferred("highlight_visual_polygons")
			main_piece.build_glue_polygons(get_global_mouse_position(), cursor_area.find_child("CollisionShape2D").shape.radius)
		elif pieces.size() == 1:
			print("Filling glue in cracks, maybe")
			pieces[0].build_glue_polygons(get_global_mouse_position(), cursor_area.find_child("CollisionShape2D").shape.radius)

func handle_camera_input(event):
	if event is InputEventMouseButton:
		if event.is_action_pressed("zoom_in"):
			if camera.zoom.x >= 2:
				camera.zoom += ZOOM_INCREMENT * 2
			camera.zoom += ZOOM_INCREMENT
			if camera.zoom.x > 4.0:
				camera.zoom = Vector2(4, 4)
			Global.camera_zoom_changed.emit(camera.zoom.x)
			adjust_camera_limits()
			get_viewport().set_input_as_handled()
		elif event.is_action_pressed("zoom_out"):
			if camera.zoom.x > 2:
				camera.zoom -= ZOOM_INCREMENT * 2
			camera.zoom -= ZOOM_INCREMENT
			if camera.zoom.x < 0.3:
				camera.zoom = Vector2(0.3, 0.3)
			Global.camera_zoom_changed.emit(camera.zoom.x)
			adjust_camera_limits()
			get_viewport().set_input_as_handled()

func handle_move_input(event):
	if Global.collide == true and event.is_action_pressed("disable_collision"):
		print("Disabling collision ", self)
		Global.collide = false
		collision_temp_disabled = true
	elif collision_temp_disabled and event.is_action_released("disable_collision"):
		Global.collide = true
		print("Reenabling collision")


func _on_freeze_button_pressed():
	Global.freeze_pieces = !Global.freeze_pieces
	update_button_text()



func _on_lock_rotate_button_pressed():
	Global.lock_rotation = !Global.lock_rotation
	update_button_text()


func _on_collide_button_pressed():
	Global.collide = !Global.collide
	update_button_text()

func update_button_text():
	if Global.freeze_pieces:
		find_child("FreezeButton").text = "Move: Locked"
	else:
		find_child("FreezeButton").text = "Move: Free"
	if Global.collide:
		find_child("CollideButton").text = "Collide: Yes"
	else:
		find_child("CollideButton").text = "Collide: No"
	if Global.lock_rotation:
		find_child("LockRotateButton").text = "Rotate: Locked"
	else:
		find_child("LockRotateButton").text = "Rotate: Free"
	match Global.click_mode:
		Global.ClickMode.move: find_child("ClickModeButton").text = "Click: Move"
		Global.ClickMode.glue: find_child("ClickModeButton").text = "Click: Glue"
		Global.ClickMode.paint: find_child("ClickModeButton").text = "Click: Paint"
		_: find_child("ClickModeButton").text = "Click: Unknown?"


func _on_add_fracture_button_pressed():
	find_child("Pieces").get_children().pick_random().random_scar()


func _on_shatter_button_pressed():
	for child in find_child("Pieces").get_children():
		child.shattering_in_progress = [Global.shatter_width, false]


func _on_shuffle_button_pressed():
	#PhysicsServer2D.set_active(false)
	var pieces = find_child("Pieces").get_children()
	pieces.shuffle()
	var largest_x_seen = 0
	var cur_min_x = 0
	var cur_min_y = 0
	var max_x = 3500
	var cur_row_height = 0
	for piece:ArcheologyItem in pieces:
		var orig_rotation = piece.global_rotation
		if Global.rotate_with_shuffle:
			piece.global_rotation = randf_range(0, 2*PI)
		else:
			piece.global_rotation = 0
		var bb_xmin = 9999999
		var bb_ymin = 9999999
		var bb_xmax = -9999999
		var bb_ymax = -9999999
		for collision:CollisionPolygon2D in piece.collision_polygons:
			var poly := collision.polygon
			for pt in poly:
				pt = collision.to_global(pt)
				if pt.x < bb_xmin: bb_xmin = pt.x
				if pt.y < bb_ymin: bb_ymin = pt.y
				if pt.x > bb_xmax: bb_xmax = pt.x
				if pt.y > bb_ymax: bb_ymax = pt.y
		# check if there's room left on this row
		var space_needed = bb_xmax - bb_xmin + 20
		if largest_x_seen < cur_min_x:
			largest_x_seen = cur_min_x
		if space_needed + cur_min_x > max_x:
			cur_min_x = space_needed
			cur_min_y += cur_row_height
			cur_row_height = 0
		else:
			if cur_row_height < (bb_ymax - bb_ymin) + 20:
				cur_row_height = (bb_ymax - bb_ymin) + 20
			cur_min_x += space_needed
		piece.reset_position = Vector2(cur_min_x - space_needed, cur_min_y) - piece.center_of_mass.rotated(piece.global_rotation) + Vector2(bb_xmax-bb_xmin, bb_ymax-bb_ymin)/2
		piece.reset_rotation = piece.global_rotation
		piece.global_rotation = orig_rotation
		piece.freeze = false #should get reset to whatever it should be after the position is changed
	var area_center = camera_top_left_limit + (camera_bot_right_limit - camera_top_left_limit)/2
	var y_offset = area_center.y - ((cur_min_y + cur_row_height) / 2)
	var x_offset = area_center.x - (largest_x_seen / 2)
	for piece:ArcheologyItem in pieces:
		piece.reset_position.y += y_offset
		piece.reset_position.x += x_offset
	#PhysicsServer2D.set_active(true)
	
func _on_add_new_button_pressed():
	var new_item = await ItemBuilder.build_random_item()
	$Pieces.add_child(new_item)
	new_item.position = Vector2(350,150)


func _on_delete_all_button_pressed():
	for child in $Pieces.get_children():
		child.queue_free()

func _on_click_mode_pressed():
	Global.rotate_click_mode()

func _on_save_button_pressed():
	var image_save_data := {} # ImageBuilder.ImageSaveData -> int index
	var item_save_data = []
	for item in $Pieces.get_children():
		item_save_data.append(item.get_save_data(image_save_data))
	var save_file := FileAccess.open("user://save.dat", FileAccess.WRITE)
	var reversed_image_save_data = {}
	for k in image_save_data.keys():
		reversed_image_save_data[image_save_data[k]] = k.map(func(entry): return entry.get_save_data())
	save_file.store_var((reversed_image_save_data))
	save_file.store_var((item_save_data))
	save_file.close()

func _on_load_button_pressed():
	for child in $Pieces.get_children():
		child.queue_free()
	var save_file := FileAccess.open("user://save.dat", FileAccess.READ)
	var image_save_data = save_file.get_var()
	var rebuilt_textures = {}
	for k in image_save_data.keys():
		image_save_data[k] = image_save_data[k].map(func(v): return ItemBuilder.ImageSaveData.load_save_data(v))
		rebuilt_textures[k] = await ItemBuilder.build_specific_item(image_save_data[k])
	var item_save_data = save_file.get_var()
	for item_save in item_save_data:
		var new_item = ArcheologyItem.load_save_data(item_save, image_save_data, rebuilt_textures)
		$Pieces.add_child(new_item)
	save_file.close()
