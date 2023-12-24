extends Node2D
const CAMERA_MOVE_SPEED := 10
const ZOOM_INCREMENT := Vector2(0.1, 0.1)
@onready var camera:Camera2D = find_child("Camera2D")
@onready var cursor_area:CursorArea = find_child("CursorArea")
var collision_temp_disabled = false

func _process(_delta):
	var movement = Input.get_vector("left", "right", "up", "down")
	if movement != Vector2.ZERO:
		camera.position += movement * CAMERA_MOVE_SPEED / camera.zoom.x

func _unhandled_input(event):
	handle_camera_input(event)
	match Global.click_mode:
		Global.ClickMode.move: handle_move_input(event)
		Global.ClickMode.glue: handle_glue_input(event)

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
	if event.is_action("zoom_in"):
		camera.zoom += ZOOM_INCREMENT
		if camera.zoom.x > 4.0:
			camera.zoom = Vector2(4, 4)
		get_viewport().set_input_as_handled()
	elif event.is_action("zoom_out"):
		camera.zoom -= ZOOM_INCREMENT
		if camera.zoom.x < 0.2:
			camera.zoom = Vector2(0.2, 0.2)
		get_viewport().set_input_as_handled()

func handle_move_input(event):
	if Global.collide == true and event.is_action_pressed("disable_collision"):
		print("Disabling collision ", self)
		Global.collide = false
		collision_temp_disabled = true
	elif collision_temp_disabled and event.is_action_released("disable_collision"):
		Global.collide = true
		print("Reenabling collision")

# Called when the node enters the scene tree for the first time.
func _ready():
	update_button_text()
	var new_item = ItemBuilder.build_random_item()
	new_item.name = "Pot3"
	$Pieces.add_child(new_item)
	new_item.position = Vector2(350,150)
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
	
	var pot3:ArcheologyItem = new_item
	var pot_area = pot3.area
	#pot1.mass = pot3.mass * pot1.area / pot3.area
	#pot2.mass = pot3.mass * pot2.area / pot3.area
	for i in range(4):
		#pot1.random_scar()
		#pot2.random_scar()
		pot3.random_scar()
	
	#var square = find_child("Square")
	#square.specific_scar(Vector2(100, 151), Vector2(160, 150), 0, 0.5, 0.5) # from left
	#square.specific_scar(Vector2(151, 100), Vector2(150, 160), 0, 0.5, 0.5) # from top
	#square.specific_scar(Vector2(200, 151), Vector2(140, 150), 0, 0.5, 0.5) # from right
	#square.specific_scar(Vector2(151, 200), Vector2(150, 140), 0, 0.5, 0.5) # from bottom
	#square.specific_scar(Vector2(100, 101), Vector2(160, 160), 0, 0.5, 0.5) # from top-left
	#square.specific_scar(Vector2(100, 199), Vector2(160, 140), 0, 0.5, 0.5) # from bottom-left


	#square.specific_scar(Vector2(151, 200), Vector2(150, 40), 0, 0.5, 0.5) # from bottom, long
	#square.specific_scar(Vector2(100, 151), Vector2(260, 150), 0, 0.5, 0.5) # from left, long


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
		Global.ClickMode.move:
			find_child("ClickModeButton").text = "Click: Move"
		Global.ClickMode.glue:
			find_child("ClickModeButton").text = "Click: Glue"


func _on_add_fracture_button_pressed():
	find_child("Pieces").get_children().pick_random().random_scar()


func _on_shatter_button_pressed():
	for child in find_child("Pieces").get_children():
		child.shattering_in_progress = true


func _on_shuffle_button_pressed():
	var pieces = find_child("Pieces").get_children()
	pieces.shuffle()
	var cur_min_x = 150
	var cur_min_y = 0
	var max_x = get_viewport_rect().size.x
	var cur_row_height = 0
	for piece in pieces:
		piece.global_rotation = 0
		var poly = piece.find_child("CollisionPolygon2D").polygon
		var bb_xmin = 9999999
		var bb_ymin = 9999999
		var bb_xmax = -9999999
		var bb_ymax = -9999999
		for pt in poly:
			if pt.x < bb_xmin: bb_xmin = pt.x
			if pt.y < bb_ymin: bb_ymin = pt.y
			if pt.x > bb_xmax: bb_xmax = pt.x
			if pt.y > bb_ymax: bb_ymax = pt.y
		# check if there's room left on this row
		var space_needed = bb_xmax - bb_xmin + 20
		if space_needed + cur_min_x > max_x:
			cur_min_x = 200
			cur_min_y += cur_row_height
			cur_row_height = 0
		else:
			if cur_row_height < (bb_ymax - bb_ymin) + 10:
				cur_row_height = (bb_ymax - bb_ymin) + 10
			cur_min_x += space_needed
		piece.reset_position = Vector2(cur_min_x - space_needed - bb_xmin, cur_min_y - bb_ymin)
		piece.freeze = false #should get reset to whatever it should be after the position is changed


func _on_add_new_button_pressed():
	var new_item = ItemBuilder.build_random_item()
	$Pieces.add_child(new_item)
	new_item.position = Vector2(350,150)


func _on_delete_all_button_pressed():
	for child in $Pieces.get_children():
		child.queue_free()

func _on_click_mode_pressed():
	match Global.click_mode:
		Global.ClickMode.move: 
			Global.click_mode = Global.ClickMode.glue
		Global.ClickMode.glue: 
			Global.click_mode = Global.ClickMode.move
		_: 
			Global.click_mode = Global.ClickMode.move
	update_button_text()
	
