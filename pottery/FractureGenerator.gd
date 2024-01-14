extends Object
class_name FractureGenerator

const DEFAULT_DEFLECTION := 25.0

#func edge_to_center_fracture(item:ArcheologyItem)->PackedVector2Array:
	#var result = PackedVector2Array()
	#var start_pt = _random_bbox_edge_point(item.bounding_box)
	#return result

static func generate_standard_scars(item:ArcheologyItem, scar_count:int)->Array[PackedVector2Array]:
	var total_scars = 0
	var result:Array[PackedVector2Array] = []
	while total_scars < scar_count:
		var chance := randf()
		var potential_new_scars
		if chance < 0.2:
			print("##### Chisel fracture!")
			potential_new_scars = FractureGenerator.chisel_fracture(item, randi_range(1, scar_count-total_scars))
		elif chance < 0.6:
			print("##### Random fracture!")
			item.random_scar()
			total_scars += 1
		elif chance < 0.8:
			if scar_count - total_scars >= 3:
				print("##### Hammer fracture!")
				potential_new_scars = FractureGenerator.hammer_fracture(item, randi_range(5, 11), randf_range(10, 45), randi_range(2, scar_count-total_scars-1))
			else:
				print("##### Chisel fracture (converted from hammer for too few scars left: ", (scar_count-total_scars), " < 3)!")
				potential_new_scars = FractureGenerator.chisel_fracture(item, randi_range(1, scar_count-total_scars))
		elif chance < 0.85:
			print("##### Lightning fracture!")
			potential_new_scars = FractureGenerator.lightning_fracture(item, null, 0, 0.1)
		else:
			print("##### Bisecting fracture!")
			potential_new_scars = [FractureGenerator.edge_to_edge_fracture(item)]
		if potential_new_scars != null:
			print("New scars: ", potential_new_scars.size())
			for s in potential_new_scars:
				if total_scars >= scar_count:
					break
				if s.size() > 3:
					total_scars += 1
					result.append(s)
	return result

static func edge_to_edge_fracture(item:ArcheologyItem)->PackedVector2Array:
	var result = PackedVector2Array()
	# get the line started
	var random_pt = MyGeom.random_bbox_edge_point(item.bounding_box)
	result.append(random_pt)
	result.append(random_pt + (item.center + Vector2(randf_range(-item.bounding_box.size.x/2, item.bounding_box.size.x/2), randf_range(-item.bounding_box.size.y/2, item.bounding_box.size.y/2)) - random_pt).normalized() * 3)
	var min_dist = min(item.bounding_box.size.x, item.bounding_box.size.y)/20
	var max_dist = max(item.bounding_box.size.x, item.bounding_box.size.y)/16
	var max_deflection = deg_to_rad(DEFAULT_DEFLECTION)
	_extend_fracture_to_bbox_edge(result, min_dist, max_dist, max_deflection, item.bounding_box)
	result = trim_fracture(item, result)
	return result

## multiple fractures radiating from a random point in the middle of the object
static func chisel_fracture(item:ArcheologyItem, num_fractures:int) -> Array[PackedVector2Array]:
	var start_pt = item.center + (item.get_random_edge_point() - item.center) * randf()
	var result:Array[PackedVector2Array] = []
	var min_dist = min(item.bounding_box.size.x, item.bounding_box.size.y)/20
	var max_dist = max(item.bounding_box.size.x, item.bounding_box.size.y)/16
	var max_deflection = deg_to_rad(DEFAULT_DEFLECTION)
	for i in num_fractures:
		var cur_angle = randf_range(0, 2*PI)
		var cur_line = PackedVector2Array([start_pt, _extend_fracture(start_pt, min_dist, max_dist, cur_angle, max_deflection)])
		_extend_fracture_to_bbox_edge(cur_line, min_dist, max_dist, max_deflection, item.bounding_box)
		cur_line = trim_fracture(item, cur_line)
		if cur_line.size() > 0:
			result.append(cur_line)
	print("Ended chisel with ", result.size(), " fractures")
	return result

## roughly-circular fracture with fractures radiating from some of its points in the middle of the object
static func hammer_fracture(item:ArcheologyItem, circle_point_count:int, circle_radius:float, num_fractures:int) -> Array[PackedVector2Array]:
	var center_pt = item.center + (item.get_random_edge_point() - item.center) * randf()
	var circle_fracture := PackedVector2Array()
	for i in circle_point_count:
		circle_fracture.append(center_pt + Vector2.RIGHT.rotated(randf_range(0, 2*PI)) * circle_radius)
	var usable_points = Array(circle_fracture)
	usable_points.shuffle()
	var result:Array[PackedVector2Array] = []
	var min_dist = min(item.bounding_box.size.x, item.bounding_box.size.y)/20
	var max_dist = max(item.bounding_box.size.x, item.bounding_box.size.y)/16
	var max_deflection = deg_to_rad(DEFAULT_DEFLECTION)
	for i in min(num_fractures, circle_fracture.size()):
		var start_pt = usable_points.pop_back()
		var cur_angle = center_pt.angle_to_point(start_pt)
		var cur_line = PackedVector2Array([start_pt, _extend_fracture(start_pt, min_dist, max_dist, cur_angle, max_deflection)])
		_extend_fracture_to_bbox_edge(cur_line, min_dist, max_dist, max_deflection, item.bounding_box)
		result.append(cur_line)
	circle_fracture.append(circle_fracture[0]) # close the circle
	circle_fracture = MyGeom.build_convex_polygon(circle_fracture)
	result.append(circle_fracture)
	return result

static func lightning_fracture(item:ArcheologyItem, start_pt=null, start_angle:float=0, fracture_split_chance:float=0.2, post_split_chance_multiplier:float=0.5):
	if start_pt == null:
		start_pt = item.get_random_edge_point()
		#start_pt = item.center + (item.get_random_edge_point() - item.center) * randf()
		var rand_offset := Vector2(randf_range(-item.bounding_box.size.x/3, item.bounding_box.size.x/3), randf_range(-item.bounding_box.size.y/3, item.bounding_box.size.y/3))
		start_angle = start_pt.angle_to_point(item.center + rand_offset)
	var result:Array[PackedVector2Array] = []
	var cur_crack = PackedVector2Array([start_pt])
	result.append(cur_crack)
	var min_dist = min(item.bounding_box.size.x, item.bounding_box.size.y)/20
	var max_dist = max(item.bounding_box.size.x, item.bounding_box.size.y)/16
	var max_deflection = deg_to_rad(DEFAULT_DEFLECTION)
	var cur_pt = start_pt
	var cur_angle = start_angle
	while item.bounding_box.has_point(cur_pt):
		cur_pt = _extend_fracture(cur_pt, min_dist, max_dist, cur_angle, max_deflection)
		cur_crack.append(cur_pt)
		if randf() < fracture_split_chance:
			var new_deflection = randf_range(max_deflection*0.5, max_deflection*2)
			if randf() > 0.5:
				new_deflection = -new_deflection
			var split_cracks = lightning_fracture(item, cur_crack[-1], cur_angle + new_deflection, fracture_split_chance * post_split_chance_multiplier)
			result.append_array(split_cracks)
	return result

static func trim_fracture(item:ArcheologyItem, fracture:PackedVector2Array) -> PackedVector2Array:
	var poly = item.polygon.polygon
	var trimmed_fracture := PackedVector2Array()
	var first_pt:int = 0
	var last_pt:int = fracture.size() - 1
	var cur_pt = fracture[0]
	var cur_in_area = Geometry2D.is_point_in_polygon(cur_pt, item.polygon.polygon)
	for i in range(1, fracture.size() - 1):
		var next_pt = fracture[i]
		var next_in_area = Geometry2D.is_point_in_polygon(next_pt, item.polygon.polygon)
		if !cur_in_area and !next_in_area:
			first_pt = i
		else:
			break
		cur_pt = next_pt
		cur_in_area = next_in_area
	
	cur_pt = fracture[-1]
	cur_in_area = Geometry2D.is_point_in_polygon(cur_pt, item.polygon.polygon)
	for i in range(2, fracture.size() - first_pt):
		var next_pt = fracture[-i]
		var next_in_area = Geometry2D.is_point_in_polygon(next_pt, item.polygon.polygon)
		if !cur_in_area and !next_in_area:
			last_pt = fracture.size() - i + 1
		else:
			break
		cur_pt = next_pt
		cur_in_area = next_in_area
	
	if first_pt >= last_pt:
		#print("Returning empty fracture, it is entirely outside the area")
		return []
	if first_pt == 0 and last_pt == fracture.size() - 1:
		#print("Returning full fracture, it is entirely inside the area")
		return fracture
	#print("Returning partial fracture, from ", first_pt, " to ", last_pt, " of ", fracture.size())
	return fracture.slice(first_pt, last_pt)
	
static func _extend_fracture(cur_pt:Vector2, min_dist:float, max_dist:float, cur_angle:float, max_deflection:float)->Vector2:
	var next_dist = randf_range(min_dist, max_dist)
	cur_angle = cur_angle + randf_range(-max_deflection, max_deflection)
	cur_pt = cur_pt + Vector2.RIGHT.rotated(cur_angle) * next_dist
	return cur_pt

static func _extend_fracture_to_bbox_edge(result:PackedVector2Array, min_dist:float, max_dist:float, max_deflection:float, bbox:Rect2):
	var cur_pt = result[-1]
	var cur_angle = result[0].angle_to_point(result[1])
	while bbox.has_point(cur_pt):
		cur_pt = _extend_fracture(cur_pt, min_dist, max_dist, cur_angle, max_deflection)
		result.append(cur_pt)
