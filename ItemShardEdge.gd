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
