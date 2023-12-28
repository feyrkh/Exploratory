extends Node2D
class_name ItemShardEdge

const DEFAULT_COLOR := Color(0.455, 0.192, 0.137)
var loading := false

func get_save_data():
	var lines = [] 
	for child in get_children():
		if child is Line2D:
			var entry = [child.points]
			if child.material != null:
				# If we have a material, this edge has been converted into glue and we should save its color
				entry.append(child.modulate)
			else:
				# otherwise we'll use the normal shard edge texture
				entry.append(null)
			lines.append(entry)
	return [position, rotation, lines]

static func load_save_data(save_data) -> ItemShardEdge:
	var curve = preload("res://ItemShardEdgeLineCurve.tres")
	var new_item = load("res://ItemShardEdge.tscn").instantiate()
	new_item.loading = true
	new_item.position = save_data[0]
	new_item.rotation = save_data[1]
	for line_data in save_data[2]:
		var line = load("res://ItemScarLine.tscn").instantiate()
		line.width_curve = curve
		line.points = line_data[0]
		line.width = 16
		line.joint_mode = Line2D.LINE_JOINT_ROUND
		line.texture_mode = Line2D.LINE_TEXTURE_TILE
		if line_data[1] != null and line_data[1] != DEFAULT_COLOR:
			convert_to_glue(line, line_data[1])
		else:
			line.default_color = DEFAULT_COLOR
			line.texture = load("res://art/broken_clay.png")
		new_item.add_child(line)
	return new_item

func clone():
	var new_scene = load(scene_file_path).instantiate()
	for child in get_children():
		var new_line = load("res://ItemShardEdgeLine.tscn").instantiate()
		new_line.points = PackedVector2Array(child.points)
		new_scene.add_child(new_line)
	return new_scene
	
func refresh_edge_path(polygon:PackedVector2Array):
	if loading:
		return
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
	#var local_circle_center = global_circle_center - global_position
	var intersections = []
	for child in get_children():
		var pt1 = child.to_global(child.points[0])
		for i in range(1, child.points.size()):
			var pt2 = child.to_global(child.points[i])
			if Geometry2D.segment_intersects_circle(pt1, pt2, global_circle_center, circle_radius) != -1:
				intersections.append(child)
				break
			pt1 = pt2
	return intersections

static func convert_to_glue(line:Line2D, color:Color):
	line.default_color = color
	line.texture = null
	line.z_index = 1
	line.material = preload("res://shader/ItemShardEdgeLine.tres")
