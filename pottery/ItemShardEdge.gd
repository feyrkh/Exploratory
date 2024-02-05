extends Node2D
class_name ItemShardEdge

var loading := false

func get_save_data():
	var lines = [] 
	for child in get_children():
		if child is Line2D:
			var entry = [child.points]
			entry.append(MaterialPolygon.color_to_material(child.default_color))
			lines.append(entry)
	return [position, rotation, lines]

static func load_save_data(save_data) -> ItemShardEdge:
	var curve = preload("res://pottery/ItemShardEdgeLineCurve.tres")
	var new_item = load("res://pottery/ItemShardEdge.tscn").instantiate()
	new_item.loading = true
	new_item.position = save_data[0]
	new_item.rotation = save_data[1]
	for line_data in save_data[2]:
		var line = load("res://pottery/ItemScarLine.tscn").instantiate()
		line.width_curve = curve
		line.points = line_data[0]
		line.width = 16
		line.joint_mode = Line2D.LINE_JOINT_ROUND
		line.texture_mode = Line2D.LINE_TEXTURE_TILE
		if line_data[1] != null:
			line.default_color = MaterialPolygon.material_to_color(line_data[1])
			line.texture = load(MaterialPolygon.material_to_image(line_data[1]))
		else:
			line.default_color = MaterialPolygon.CLAY_COLOR
		new_item.add_child(line)
	return new_item

func clone():
	var new_scene = load(scene_file_path).instantiate()
	for child in get_children():
		var new_line = load("res://pottery/ItemShardEdgeLine.tscn").instantiate()
		new_line.points = PackedVector2Array(child.points)
		new_scene.add_child(new_line)
	return new_scene

func set_edge_colors(material_data:Array):
	# material_data is array of items like {MaterialPolygon.MATERIAL: MaterialPolygon.MaterialType.metal, MaterialPolygon.POLYGON: (polygon points)}
	if material_data.size() == 0:
		return
	for child in get_children():
		var cur_line = PackedVector2Array(child.points)
		var internal_point = cur_line[0] + (cur_line[1]-cur_line[0]) / 2
		var material_color = MaterialPolygon.CLAY_COLOR
		for data in material_data:
			if Geometry2D.is_point_in_polygon(internal_point, data.get(MaterialPolygon.POLYGON, [])):
				material_color = MaterialPolygon.material_to_color(data.get(MaterialPolygon.MATERIAL))
				child.texture = load(MaterialPolygon.material_to_image(data.get(MaterialPolygon.MATERIAL)))
				break
		child.default_color = material_color


func refresh_edge_path(polygon:PackedVector2Array, allow_outside_borders:=false):
	if loading:
		return
	for child in get_children():
		var cur_line = PackedVector2Array(child.points)
		if cur_line.size() == 0:
			queue_free()
			return
		var new_lines = Geometry2D.intersect_polyline_with_polygon(cur_line, polygon)
		if allow_outside_borders:
			new_lines.append_array(Geometry2D.clip_polyline_with_polygon(cur_line, polygon))
		if new_lines.size() > 0:
			#MyGeom.shorten_path(new_lines[0], 2)
			child.points = new_lines[0]
			new_lines.pop_front()
			for extra_line in new_lines: 
				if extra_line.size() < 2: continue
				#MyGeom.shorten_path(extra_line, 2)
				var new_line = load("res://pottery/ItemShardEdgeLine.tscn").instantiate()
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
			if Geometry2D.segment_intersects_circle(pt1, pt2, global_circle_center, circle_radius) != -1 || pt1.distance_to(global_circle_center) < circle_radius || pt2.distance_to(global_circle_center) < circle_radius:
				intersections.append(child)
				break
			pt1 = pt2
	return intersections

func adjust_scale(scale_change:float):
	for child in get_children():
		for i in range(child.points.size()):
			child.points[i] = child.points[i] * scale_change
		child.width *= scale_change

static func convert_to_glue(line:Line2D, color:Color):
	line.default_color = color
	line.texture = null
	line.z_index = 1
	line.material = preload("res://shader/ItemShardEdgeLine.tres")
