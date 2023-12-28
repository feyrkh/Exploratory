extends Node2D

const GLUE_COLOR_FIELD := 0
const LINE_DATA_FIELD := 1

func get_save_data():
	var line_data = []
	var glue_color = []
	for child in get_children():
		if child is Line2D:
			line_data.append(child.points)
			if child.material != null:
				# If we have a material, this edge has been converted into glue and we should save its color
				glue_color.append(child.modulate)
			else:
				# otherwise we'll use the normal shard edge texture
				glue_color.append(null)
	return {LINE_DATA_FIELD: line_data, GLUE_COLOR_FIELD: glue_color}

func clone():
	var new_scene = load(scene_file_path).instantiate()
	for child in get_children():
		var new_line = load("res://ItemShardEdgeLine.tscn").instantiate()
		new_line.points = PackedVector2Array(child.points)
		new_scene.add_child(new_line)
	return new_scene
	
func refresh_edge_path(polygon:PackedVector2Array):
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
