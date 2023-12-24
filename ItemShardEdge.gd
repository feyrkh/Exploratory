extends Node2D

func clone():
	var new_scene = load(scene_file_path).instantiate()
	for child in get_children():
		var new_line = load("res://ItemShardEdgeLine.tscn").instantiate()
		new_line.points = PackedVector2Array(child.points)
		new_scene.add_child(new_line)
	return new_scene
	
func refresh_edge_path(polygon:PackedVector2Array, offset=0.1):
	for child in get_children():
		var cur_line = PackedVector2Array(child.points)
		if cur_line.size() == 0:
			queue_free()
			return
		var new_lines = Geometry2D.intersect_polyline_with_polygon(cur_line, polygon)
		if new_lines.size() > 0:
			child.points = new_lines[0]
			new_lines.pop_front()
			for extra_line in new_lines: 
				if extra_line.size() < 2: continue
				var new_line = load("res://ItemShardEdgeLine.tscn").instantiate()
				new_line.points = PackedVector2Array(extra_line)
				add_child(new_line)
		else:
			queue_free()

func get_intersecting_edge_lines(global_circle_center:Vector2, circle_radius:float):
	var local_circle_center = global_circle_center - global_position
	var intersections = []
	for child in get_children():
		var pt1 = child.points[0]
		for i in range(1, child.points.size()):
			var pt2 = child.points[i]
			if Geometry2D.segment_intersects_circle(pt1, pt2, local_circle_center, circle_radius) != -1:
				intersections.append(child)
				break
			pt1 = pt2
	return intersections
