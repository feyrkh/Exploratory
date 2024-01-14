extends Node2D

@onready var line = find_child("Line2D")
@onready var polygon = find_child("Polygon2D")

# Called when the node enters the scene tree for the first time.
func _ready():
	#var inflated = MyGeom.inflate_polyline(line.points, 10)
	#polygon.polygon = inflated
	
	var poly:PackedVector2Array = $Polygon2D.polygon
	#poly = MyGeom.cleanup_close_points(poly)
	poly = MyGeom.cleanup_self_intersections(poly)
	poly = MyGeom.cleanup_sharp_angles(poly)
	$Polygon2D.polygon = poly
	var prev_pt = poly[-1]
	#for i in poly.size():
		#var cur_pt = poly[i]
		#for j in range(i+1, poly.size()-2):
			#var other_pt1 := poly[j]
			#var other_pt2 := poly[j+1]
			#var intersects = Geometry2D.segment_intersects_segment(prev_pt, cur_pt, other_pt1, other_pt2)
			#if intersects:
				#print("Lines intersect: (%s, %s)=%.5f + (%s, %s)=%.5f" % [prev_pt, cur_pt, cur_pt.distance_to(prev_pt), other_pt1, other_pt2, other_pt1.distance_to(other_pt2)])
			#
		#prev_pt = cur_pt
		#print(i, " = ", Geometry2D.is_point_in_polygon($Polygon2D.polygon[i], poly))
	#pass
	var new_item = await ItemBuilder.build_random_item()
	add_child(new_item)
	#new_item.position = Vector2(000, 200)
	var paths:Array[PackedVector2Array]
	#paths = FractureGenerator.hammer_fracture(new_item, 12, 30, 6)
	paths = FractureGenerator.lightning_fracture(new_item)
	new_item.create_scars_from_paths(paths)
	#paths = [FractureGenerator.edge_to_edge_fracture(new_item)]
	#new_item.create_scars_from_paths(paths)
	#paths = FractureGenerator.chisel_fracture(new_item, 4)
	#new_item.create_scars_from_paths(paths)
	#for i in 4:
		#new_item.random_scar()
	new_item.try_shatter(1.5, false)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass
