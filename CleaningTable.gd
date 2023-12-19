extends Node2D

func _unhandled_input(event):
	if event.is_action_pressed("add_crack"):
		find_child("Pot3").random_scar()
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("toggle_lock_rotation"):
		Global.lock_rotation = !Global.lock_rotation
		get_viewport().set_input_as_handled()
		

# Called when the node enters the scene tree for the first time.
func _ready():
	update_button_text()
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
	
	var pot3:ArcheologyItem = find_child("Pot3")
	var pot_area = pot3.area
	#pot1.mass = pot3.mass * pot1.area / pot3.area
	#pot2.mass = pot3.mass * pot2.area / pot3.area
	for i in range(4):
		#pot1.random_scar()
		#pot2.random_scar()
		pot3.random_scar()
	
	var square = find_child("Square")
	#square.specific_scar(Vector2(100, 151), Vector2(160, 150), 0, 0.5, 0.5) # from left
	#square.specific_scar(Vector2(151, 100), Vector2(150, 160), 0, 0.5, 0.5) # from top
	#square.specific_scar(Vector2(200, 151), Vector2(140, 150), 0, 0.5, 0.5) # from right
	#square.specific_scar(Vector2(151, 200), Vector2(150, 140), 0, 0.5, 0.5) # from bottom
	#square.specific_scar(Vector2(100, 101), Vector2(160, 160), 0, 0.5, 0.5) # from top-left
	#square.specific_scar(Vector2(100, 199), Vector2(160, 140), 0, 0.5, 0.5) # from bottom-left


	square.specific_scar(Vector2(151, 200), Vector2(150, 40), 0, 0.5, 0.5) # from bottom, long
	square.specific_scar(Vector2(100, 151), Vector2(260, 150), 0, 0.5, 0.5) # from left, long


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
