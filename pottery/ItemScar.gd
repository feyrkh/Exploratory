extends Node2D
class_name ItemScar

var line:Line2D

func get_save_data() -> Array:
	return [position, rotation, line.points]

static func load_save_data(save_data) -> ItemScar:
	var new_item = load("res://pottery/ItemScar.tscn").instantiate()
	if new_item.line != null and is_instance_valid(new_item.line):
		new_item.line.queue_free()
	new_item.line = load("res://pottery/ItemScarLine.tscn").instantiate()
	var curve = preload("res://pottery/ItemScarLineCurve.tres")
	new_item.line.width_curve = curve
	new_item.position = save_data[0]
	new_item.rotation = save_data[1]
	new_item.line.points = save_data[2]
	new_item.add_child(new_item.line)
	return new_item

func clone() -> ItemScar:
	var new_scene = load(scene_file_path).instantiate()
	var new_line = preload("res://pottery/ItemScarLine.tscn").instantiate()
	new_line.points = Array(line.points)
	new_scene.add_child(new_line)
	new_scene.line = new_line
	return new_scene
	

func generate_scar(polygon:PackedVector2Array, start_pos:Vector2, len:float, initial_angle_radians:float, max_deviation_radians:float=PI/6, min_segment_len_percent:float=0.2, max_segment_len_percent:float=0.3):
	var generated_points:Array[Vector2] = [start_pos]
	var consumed_pct:float = 0
	line = preload("res://pottery/ItemScarLine.tscn").instantiate()
	add_child(line)
	while consumed_pct < 1:
		var new_consumed = min(randf_range(min_segment_len_percent, max_segment_len_percent), 1-consumed_pct)
		consumed_pct += new_consumed
		var pt:Vector2 = start_pos + Vector2.RIGHT.rotated(initial_angle_radians) * (new_consumed * len)
		generated_points.append(pt)
		start_pos = pt
		initial_angle_radians += randf_range(-max_deviation_radians, max_deviation_radians)
	refresh_scar_path(polygon, generated_points)

func refresh_scar_path(polygon:PackedVector2Array, generated_points = line.points):
	var new_line = PackedVector2Array(generated_points)
	var orig_start_point = generated_points[0]
	var new_lines = Geometry2D.intersect_polyline_with_polygon(new_line, polygon)
	if new_lines.size() > 0: 
		# Sort the intersected line so that the point closest to an edge is first in line, otherwise scars can point in the wrong direction
		if new_lines[0][0].distance_to(orig_start_point) > 0.01:
			new_lines[0].reverse()
		line.points = new_lines[0]
	else:
		queue_free()

func remove_line_segments(covered_pts, from_end:bool):
	var cur_line_pt = line.points.size()-1 if from_end else 0
	var line_pt_delta = -1 if from_end else 1
	#var line_pt_end = -1 if from_end else line.points.size()
	var delete_from = null
	var replacement_line = Array(line.points)
	var found_endpoint := false
	for pt_to_remove in covered_pts:
		if replacement_line[cur_line_pt].distance_squared_to(pt_to_remove) < 0.1:
			delete_from = cur_line_pt
			cur_line_pt += line_pt_delta
		else:
			found_endpoint = true
			if from_end:
				for i in range(replacement_line.size()-1, delete_from, -1):
					replacement_line.remove_at(i)
				replacement_line[delete_from] = pt_to_remove
			else:
				for i in range(delete_from, -1, -1):
					#print("Removing at new loc 0, ", replacement_line[0])
					replacement_line.remove_at(0)
				#print("Replacing original 0 ", replacement_line[0], " with new 0, ", pt_to_remove)
				replacement_line[0] = pt_to_remove
			line.points = replacement_line
	
	if !found_endpoint or replacement_line.size() < 2:
		#print("Full line was deleted")
		queue_free()

func get_edge_intersections(edge_start:Vector2, edge_end:Vector2, distance_tolerance=0.7):
	var closest_intersection_of_start
	var closest_intersection_of_end
	var closest = Geometry2D.get_closest_point_to_segment(line.points[0], edge_start, edge_end)
	var distance1 = closest.distance_to(line.points[0])
	#print("Distance1 ", distance1, ", edge=(", edge_start, ", ", edge_end, "), pt=", line.points[0])
	if distance1 < distance_tolerance:
		closest_intersection_of_start = closest
	closest = Geometry2D.get_closest_point_to_segment(line.points[-1], edge_start, edge_end)
	var distance2 = closest.distance_to(line.points[-1])
	#print("Distance2 ", distance2, ", edge=(", edge_start, ", ", edge_end, "), pt=", line.points[-1])
	if distance2 < distance_tolerance:
		closest_intersection_of_end = closest
	if closest_intersection_of_start == null and closest_intersection_of_end == null:
		return null
	elif closest_intersection_of_start == null:
		return [closest_intersection_of_end, "end"]
	elif closest_intersection_of_end == null:
		return [closest_intersection_of_start, "start"]
	else:
		return [closest_intersection_of_start, closest_intersection_of_end, "both"]

func intersect_scar(scar2:ItemScar, scar1_from_end:bool, scar2_from_end:bool): #-> Array[Vector2] or null:
	#print("Checking intersection of ", self, " and ", scar2)
	var scar1_pts = Array(line.points)
	var scar2_pts = Array(scar2.line.points)
	if scar1_from_end: scar1_pts.reverse()
	if scar2_from_end: scar2_pts.reverse()
	if self == scar2:
		#print("Self-intersection")
		return [scar1_pts, scar1_pts, []] 
	var start_pt = scar1_pts[0]
	var intersection = [start_pt]
	var covered_scar1_pts = [start_pt]
	var covered_scar2_pts = Array()
	for i in range(1, scar1_pts.size()):
		var next_pt = scar1_pts[i]
		var start_pt2 = scar2_pts[0]
		for j in range(1, scar2_pts.size()):
			# walk forward on second scar to find the segment that intersects with the current segment of scar1
			var next_pt2 = scar2_pts[j]
			var intersect_pt = Geometry2D.segment_intersects_segment(start_pt, next_pt, start_pt2, next_pt2)
			if intersect_pt != null:
				# we've reached the intersection point, add it to the combined path and then walk backward down the second scar to get the remaining points
				covered_scar1_pts.append(intersect_pt)
				if scar2_pts[j-1].distance_to(intersect_pt) > 0.01:
					# unless it's practically identical to the first element of the second scar
					intersection.append(intersect_pt)
					covered_scar2_pts.append(intersect_pt)
				for k in range(j-1, -1, -1):
					intersection.append(scar2_pts[k])
					covered_scar2_pts.append(scar2_pts[k])
				covered_scar2_pts.reverse()
				return [intersection, covered_scar1_pts, covered_scar2_pts]
			start_pt2 = next_pt2
		intersection.append(next_pt)
		covered_scar1_pts.append(next_pt)
		start_pt = next_pt
	return null
