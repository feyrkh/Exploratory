extends Node2D

func _unhandled_input(event):
	if event.is_action_pressed("add_crack"):
		find_child("Pot3").random_scar()

# Called when the node enters the scene tree for the first time.
func _ready():
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
