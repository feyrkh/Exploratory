extends RigidBody2D
class_name ArcheologyItem

# if -1, the mouse is not hovering over this piece
var hover_idx = -1
# If null, the user is not dragging this piece
var drag_start_mouse = null
var drag_start_item = null
var target_pos = null
# if null, the user is not rotating this piece
var rotate_start_mouse = null
var rotate_start_item = null
var rotate_start_item_com_position = null
var target_rot = null
var reset_position = null

const TOO_SMALL_POLYGON_AREA := 85

# Length of all the edges in pixels, used for picking random spots on the edge
var total_edge_length:float = 0
var shattering_in_progress:bool = false:
	set(val):
		shattering_in_progress = val
		set_process(val)

var center:
	get:
		if center == null:
			_find_center()
		return center
var area:float:
	get:
		if area == 0:
			_find_center()
		return area

var original_area
var area_pct:
	get:
		return area / original_area

@onready var collision:CollisionPolygon2D = find_child("CollisionPolygon2D")
@onready var sprite:Sprite2D = find_child("Sprite2D")
@onready var scars:Node2D = find_child("Scars")
@onready var polygon:Polygon2D = find_child("Polygon2D")
@onready var shard_edges:Node2D = find_child("ShardEdges")

func _ready():
	refresh_polygon()
	if original_area == null:
		original_area = area

func _process(_delta):
	if shattering_in_progress:
		shattering_in_progress = false
		try_shatter()

func global_lock_rotation(val:bool):
	# Called by Global.lock_rotation when rotation locking for fragments is enabled/disabled
	# Only applied if we're not already dragging or rotating the current item - when we stop, it will take on the global setting again
	if drag_start_item == null and rotate_start_item == null:
		lock_rotation = val

func global_freeze_pieces(val:bool):
	# Called by Global.freeze_pieces. Only applied if we're not already interacting with the current item.
	if drag_start_item == null and rotate_start_item == null:
		freeze = val
		
func global_collide(val:bool):
	# Called by Global.collide when piece collisions should be disabled
	if val:
		collision_mask |= 1 # allow this piece to collide with elements on layer 1
	else:
		collision_mask &= ~1 # prevent this piece from colliding with elements on layer 1

func clone(new_polygon:Array):
	var new_scene = load(scene_file_path).instantiate()
	new_scene.original_area = original_area
	get_parent().add_child(new_scene)
	new_scene.global_position = global_position
	new_scene.global_rotation = global_rotation
	new_scene.collision.polygon = new_polygon
	for scar in scars.get_children():
		var new_scar = scar.clone()
		new_scene.scars.add_child(new_scar)
	for edge in shard_edges.get_children():
		var new_edge = edge.clone()
		new_scene.shard_edges.add_child(new_edge)
	new_scene.shattering_in_progress = true
	return new_scene

func refresh_polygon() -> int:
	center = null
	area = 0
	if collision.polygon[0].distance_to(collision.polygon[-1]) < 0.5:
		# sometimes the last point ends up being identical to the first point, and that can cause problems, so delete it
		print("Cleaning up duplicate polygon point: ", collision.polygon[0], " vs ", collision.polygon[-1])
		var new_polygon = Array(collision.polygon)
		new_polygon.pop_back()
		collision.polygon = new_polygon
	if collision.position != Vector2.ZERO:
		var offset = collision.position
		collision.position = Vector2.ZERO
		var new_polygon = []
		for i in range(collision.polygon.size()):
			new_polygon.append(collision.polygon[i] + offset)
		collision.polygon = new_polygon
	polygon.polygon = collision.polygon
	polygon.uv = collision.polygon
	total_edge_length = 0
	for i in range(collision.polygon.size()):
		var j = (i+1) % collision.polygon.size()
		total_edge_length += collision.polygon[i].distance_to(collision.polygon[j])
	var scar_trim_poly = Geometry2D.offset_polygon(collision.polygon, 3)
	for scar in scars.get_children():
		scar.refresh_scar_path(collision.polygon)
	for edge in shard_edges.get_children():
		if scar_trim_poly.size() > 0:
			edge.refresh_edge_path(scar_trim_poly[0])
	if abs(area) < TOO_SMALL_POLYGON_AREA:
		print("Too-small shard was created, area is ", area, ", deleting")
		queue_free()
		return 0
	else:
		print("Decent-sized shard was created, area is ", area)
		return 1

func get_random_edge_point() -> Vector2:
	var dist = randf_range(0, total_edge_length)
	var i = 0
	while(dist > 0):
		var start_pt = collision.polygon[i]
		var next_pt = collision.polygon[(i+1) % collision.polygon.size()]
		var cur_len = next_pt.distance_to(start_pt)
		if cur_len >= dist:
			return start_pt + (next_pt - start_pt).normalized() * dist
		dist -= cur_len
		i += 1
	return collision.polygon[0]

func _unhandled_input(event):
	if event is InputEventMouseButton:
		#print("Clicked: ", event)
		if hover_idx >= 0:
			if event.is_action_pressed("drag_start"):
				print("Starting drag")
				drag_start_mouse = get_global_mouse_position()
				drag_start_item = global_position
				lock_rotation = true
				freeze = false
				get_parent().move_child(self, -1)
				get_viewport().set_input_as_handled()
			if event.is_action_pressed("break_item"):
				print("Shattering item")
				try_shatter()
			if event.is_action_pressed("rotate_start"):
				rotate_start_mouse = to_global(center_of_mass).angle_to_point(get_global_mouse_position())
				rotate_start_item = global_rotation
				rotate_start_item_com_position = to_global(center_of_mass)
				lock_rotation = false
				freeze = false
				print("Mouse at ", get_global_mouse_position(), ", COM at ", to_global(center_of_mass))
				print("Starting rotate, initial rotation=", rad_to_deg(global_rotation), ", mouse start angle=", rad_to_deg(rotate_start_mouse))
		if drag_start_mouse != null and event.is_action_released("drag_start"):
			drag_start_mouse = null
			drag_start_item = null
			target_pos = null
			if hover_idx == -1:
				_on_mouse_shape_exited(-1)
			lock_rotation = Global.lock_rotation
			freeze = Global.freeze_pieces
			#print("Ending drag")
		elif rotate_start_mouse != null and event.is_action_released("rotate_start"):
			rotate_start_mouse = null
			rotate_start_item = null
			target_rot = null
			lock_rotation = Global.lock_rotation
			freeze = Global.freeze_pieces
			find_child("target_rot").visible = false
			find_child("rotate_start_item").visible = false
			find_child("rotate_start_mouse").visible = false
			find_child("actual_rot").visible = false
			print("Stopping rotate")
	elif drag_start_mouse != null and event is InputEventMouseMotion:
		target_pos = get_global_mouse_position()
	elif rotate_start_mouse != null and event is InputEventMouseMotion:
		target_rot = 0.1 # just something to get the _integrate_forces method started
	elif hover_idx >= 0 and event.is_action_pressed("delete_item"):
		print("Deleting item ", self)

func _integrate_forces(state):
	if reset_position != null:
		state.transform = state.transform.rotated(-state.transform.get_rotation())
		state.transform.origin = reset_position
		reset_position = null
		freeze = Global.freeze_pieces
	if target_pos != null:
		var desired_motion = drag_start_item - global_position + target_pos - drag_start_mouse
		state.linear_velocity = desired_motion * 25
	if target_rot != null:
		#var direction
		#if (global_rotation <= target_rot) and (target_rot - global_rotation < PI):
		#	direction = 1
		#elif (target_rot <= global_rotation) and (global_rotation - target_rot < PI):
		#	direction = -1
		#elif (global_rotation <= target_rot) and (target_rot - global_rotation < PI):
		#	direction = -1
		#elif (target_rot <= global_rotation) and (global_rotation - target_rot < PI):
		#	direction = 1
		#else:
		#	direction = target_rot - global_rotation
		#var actual_rot = rotate_start_item - global_rotation
		#print("target: ", rad_to_deg(target_rot), ", actual: ", rad_to_deg(actual_rot))
		#if target_rot < global_rotation:
			#angular_velocity = -abs(target_rot - global_rotation) * 5
			##print("Rot neg, ", global_rotation, " to ", target_rot)
		#elif target_rot > global_rotation:
			#angular_velocity = abs(target_rot - global_rotation) * 5
			##print("Rot pos, ", global_rotation, " to ", target_rot)
		#else:
			#print("Reached position? ", global_rotation, " vs ", target_rot)		var item_center = to_global(center_of_mass)
		var item_center = to_global(center_of_mass)
		var mouse_cursor = get_global_mouse_position()
		var angle_from_item_to_mouse = item_center.angle_to_point(mouse_cursor)
		var offset_from_original_angle = angle_from_item_to_mouse - rotate_start_mouse
		var distance_already_rotated = global_rotation - rotate_start_item
		var distance_to_rotate = offset_from_original_angle - distance_already_rotated
		#state.transform.origin += item_center - rotate_start_item_com_position
		#rotate_start_item_com_position = to_global(center_of_mass)
		if distance_to_rotate >= PI:
			distance_to_rotate -= 2*PI
		elif distance_to_rotate <= -PI:
			distance_to_rotate += 2*PI
		#print("item_center=%s, mouse_cursor=%s, angle_from_item_to_mouse=%s, offset_from_original_angle=%s, distance_already_rotated=%s, distance_to_rotate=%s" % 
		#[item_center, mouse_cursor, rad_to_deg(angle_from_item_to_mouse), rad_to_deg(offset_from_original_angle), rad_to_deg(distance_already_rotated), rad_to_deg(distance_to_rotate)])
		target_rot = distance_to_rotate
		while target_rot > PI:
			target_rot -= PI
		while target_rot < -PI:
			target_rot += PI
		angular_velocity = target_rot * 15

func _on_mouse_shape_entered(shape_idx):
	sprite.modulate = Color.AQUAMARINE
	#print("Hovering ", shape_idx)
	hover_idx = shape_idx

func _on_mouse_shape_exited(shape_idx):
	if shape_idx == hover_idx:
		if drag_start_item == null:
			sprite.modulate = Color.WHITE
		#print("Left hover ", shape_idx)
		hover_idx = -1

func add_scar(scar:ItemScar):
	scar.refresh_scar_path(collision.polygon)
	for scar2 in scars.get_children():
		# Check that no other scars start really close to the start/end of this scar - if they do, skip it
		if scar.line.points[0].distance_squared_to(scar2.line.points[0]) <= 25 or scar.line.points[-1].distance_squared_to(scar2.line.points[0]) <= 25:
			# One of the endpoints is too close to an existing scar, delete it to avoid bad fragments later
			scar.queue_free()
	scars.add_child(scar)

#func try_shatter_all_at_once():
	#var working_polygons = [collision.polygon]
	#var scar_polygons = []
	#for scar in scars.get_children():
		#scar_polygons.append(MyGeom.inflate_polyline(scar.line.points, 1))
	#for break_poly in scar_polygons:
		#var new_polygons = []
		#for working_poly in working_polygons:
			#var clipped_polygons = Geometry2D.clip_polygons(collision.polygon, break_poly)
			##for poly in clipped_polygons:
				## check that each result polygon is clockwise, reverse it if not
				##if !Geometry2D.is_polygon_clockwise(poly):
				##	poly.reverse()
			#new_polygons.append_array(clipped_polygons)
		#working_polygons = new_polygons
	#for poly in working_polygons:
		

func try_shatter():
	# look at each scar in turn
	var scar_count = scars.get_child_count()
	var break_path
	var scar1:ItemScar
	var scar2:ItemScar
	var scar1_edge_segments
	var scar2_edge_segments
	for pt_idx in range(collision.polygon.size()):
		if break_path != null: break
		var next_pt_idx = (pt_idx + 1) % collision.polygon.size()
		for scar1_idx in range(scar_count):
			if break_path != null: break
			scar1 = scars.get_child(scar1_idx)
			# check if that scar intersects the same edge on both sides, if so that's our break path
			var scar1_intersect = scar1.get_edge_intersections(collision.polygon[pt_idx], collision.polygon[next_pt_idx])
			if scar1_intersect == null:
				continue
			if scar1_intersect[-1] == "both":
				break_path = scar1.line.points
				scar1_edge_segments = break_path
				break
			# otherwise, look for any scar which intersects with this one, our break path is the first scar up to the intersection point, then follow the second scar back to its start
			for scar2_idx in range(scar1_idx+1, scar_count):
				scar2 = scars.get_child(scar2_idx)
				var scar1_intersect_scar2 = scar1.intersect_scar(scar2, false, false)
				if scar1_intersect_scar2:
					break_path = scar1_intersect_scar2[0]
					scar1_edge_segments = scar1_intersect_scar2[1]
					scar2_edge_segments = scar1_intersect_scar2[2]
					break
			if !break_path:
				scar2 = null
				# Finally, if no other scars intersect this one, look at whether the endpoint of this scar intersects any other edges
				for endpt_idx in range(collision.polygon.size()):
					var next_endpt_idx = (endpt_idx + 1) % collision.polygon.size()
					var scar1_endpt_intersect = scar1.get_edge_intersections(collision.polygon[endpt_idx], collision.polygon[next_endpt_idx])
					if scar1_endpt_intersect != null:
						if scar1_endpt_intersect[-1] != "start":
							break_path = scar1.line.points
							scar1_edge_segments = break_path
							break
	# see if we found any break path
	if !break_path:
		return
	if scar1 and scar1_edge_segments:
		scar1.remove_line_segments(scar1_edge_segments, false)
	if scar2 and scar2_edge_segments:
		scar2.remove_line_segments(scar2_edge_segments, false)
	
	# expand our break path
	# this doesn't work like I want it to, gonna write my own
	#var break_poly := Geometry2D.offset_polyline(PackedVector2Array(break_path), 5, Geometry2D.JOIN_MITER, Geometry2D.END_JOINED)
	var break_poly = MyGeom.inflate_polyline(break_path, 1.5)
	# intersect our break path with our existing polygon
	var clipped_polygons = Geometry2D.clip_polygons(collision.polygon, break_poly)
	for poly in clipped_polygons:
		# check that each result polygon is clockwise, reverse it if not
		if !Geometry2D.is_polygon_clockwise(poly):
			poly.reverse()
	# if no polygons were found, destroy this obj - it got divided into dust
	if clipped_polygons == null or clipped_polygons.size() == 0:
		queue_free()
		return
	add_break_underlay(break_path, clipped_polygons[0])
	# create a new item out of all but the first polygon we found
	for i in range(1, clipped_polygons.size()):
		var new_item = clone(clipped_polygons[i])
		new_item.refresh_polygon()
		new_item.apply_central_impulse(Vector2.ONE.rotated(deg_to_rad(randf_range(0, 360))) * 260)
	# replace our current collision polygon with the first polygon we found
	collision.polygon = clipped_polygons[0]
	refresh_polygon()
	shattering_in_progress = true

func try_shatter_old():
	var pts := polygon.polygon
	var cur_edge_start := pts[0]
	var cur_edge_end := cur_edge_start
	var fragment_edge_idx_start
	var fragment_edge_offset_start 
	var fragment_edge_idx_end
	var fragment_edge_offset_end
	var scar_intersection
	var first_scar
	var second_scar
	var scar1_from_end:bool
	var scar2_from_end:bool
	var covered_scar1_pts
	var covered_scar2_pts
	
	# Loop over all edges
	var edge_count = pts.size()
	for i in range(edge_count):
		if scar_intersection != null: break
		cur_edge_start = pts[i]
		cur_edge_end = pts[(i+1) % edge_count]
		# If the current edge intersects with any of the edges on any scar, this might be the start of a fragment
		for scar in scars.get_children():
			if scar_intersection != null: break
			var intersections = scar.get_edge_intersections(cur_edge_start, cur_edge_end)
			var intersections2
			if intersections == null:
				continue
			if intersections.size() == 3:
				print("Found a scar that intersects with the same edge twice: ", intersections)
				first_scar = scar
				print("Skipping for now")
				continue
			if intersections.size() == 2:
				print("Found a scar that intersects with this edge ", i, " at ", intersections)
				scar1_from_end = intersections[-1] == "end"
				first_scar = scar
				# one end of the scar touches the current edge of this item
				# check all the edges starting with the current one, looking for other scars that intersect with this one
				# We know we don't have to check any previous edges, because they would have caught this one
				for j in range(i, edge_count):
					if scar_intersection != null: break
					for scar2 in scars.get_children():
						if scar_intersection != null: break
						var later_edge_start := pts[j]
						var later_edge_end := pts[(j+1)%edge_count]
						intersections2 = scar2.get_edge_intersections(later_edge_start, later_edge_end)
						if intersections2 == null:
							# the current scar2 doesn't intersect with this edge2, so try the next scar2
							continue
						if intersections2.size() == 2:
							scar2_from_end = intersections2[-1] == "end"
							# We have a scar2 that intersects with this edge, now check if it intersects with the first scar
							# but skip it if this intersection is the same as the previous intersection
							if intersections[0].distance_to(intersections2[0]) < 0.5:
								print("Found an intersecting scar, but it looks like it's the same as the first one, skipping")
								continue
							print("Found a second intersecting scar, ", scar2, " at edge ", j, ", checking if it intersects with ", scar)
							second_scar = scar2
							scar_intersection = scar.intersect_scar(scar2, scar1_from_end, scar2_from_end)
							if scar_intersection != null:
								covered_scar1_pts = scar_intersection[1]
								covered_scar2_pts = scar_intersection[2]
								scar_intersection = scar_intersection[0]
								print("Found an intersection with another scar at edge ", j, " with coords ", scar_intersection)
								# if the scars intersect, then we have a fragment
								fragment_edge_idx_start = i
								fragment_edge_offset_start = intersections[0]
								fragment_edge_idx_end = j
								fragment_edge_offset_end = intersections2[0]
								break
						elif intersections2.size() == 3:
							second_scar = scar2
							scar_intersection = scar.intersect_scar(scar2, intersections[-1] == "end", intersections2[-1] == "end")
							if scar_intersection != null:
								covered_scar1_pts = scar_intersection[1]
								covered_scar2_pts = scar_intersection[2]
								scar_intersection = scar_intersection[0]
								print("Found an intersection with another scar at edge ", j, " with coords ", scar_intersection)
								# if the scars intersect, then we have a fragment
								fragment_edge_idx_start = i
								fragment_edge_offset_start = intersections[0]
								fragment_edge_idx_end = j
								fragment_edge_offset_end = intersections2[0]
								break

	if scar_intersection != null:
		print("Found a scar intersection: ", scar_intersection)
		# We found two scars that intersect, and the fragment_edge* fields should be set to point to the start and end
		# endpoints around the edge of the current item, while the scar_intersection represents the internal points.
		# From the POV of the original item, the internal points are in clockwise order, while from the POV of the new
		# fragment they are in counterclockwise order, so we should reverse them when constructing the edge of the new
		# fragment.
		var my_new_polygon = []
		var other_new_polygon = []
		var working_on_original = true
		
		# We need to delete the points that will disappear when the break is made
		# The first element of scar_intersection is the edge endpoint the first scar
		# The last element of scar_intersection is the edge endpoint of the second scar
		first_scar.remove_line_segments(covered_scar1_pts, scar1_from_end)
		second_scar.remove_line_segments(covered_scar2_pts, scar2_from_end)
		#if !scar1_from_end:
			## remove from the front
			#while scar_intersection[0].distance_squared_to(first_scar.line.points[0]) >= 1:
				#first_scar.line.points.remove_at(0)
		#else:
			## remove from the back
			#while scar_intersection[0].distance_squared_to(first_scar.line.points[-1]) >= 1:
				#first_scar.line.points.remove_at(-1)
		#if !scar2_from_end:
			## remove from the front
			#while scar_intersection[-1].distance_squared_to(second_scar.line.points[0]) >= 1:
				#second_scar.line.points.remove_at(0)
		#else:
			## remove from the back
			#while scar_intersection[-1].distance_squared_to(second_scar.line.points[-1]) >= 1:
				#second_scar.line.points.remove_at(-1)
		
		working_on_original = true
		for i in range(collision.polygon.size()):
			if working_on_original:
				if i == (fragment_edge_idx_start+1)%edge_count:
					# We've reached the start of the fragment, append the internal fracture points, then continue accumulating edge
					# points on the new polygon until we reach the endpoint
					working_on_original = false
					for pt in scar_intersection:
						my_new_polygon.append(pt)
						print("Orig (s): ", pt)
				else:
					my_new_polygon.append(collision.polygon[i])
					print("Orig (o): ", collision.polygon[i])
			if !working_on_original:
				other_new_polygon.append(collision.polygon[i])
				print("New (o): ", collision.polygon[i])
				if i == fragment_edge_idx_end:
					working_on_original = true
					scar_intersection.reverse()
					for pt in scar_intersection:
						other_new_polygon.append(pt)
						print("New (s): ", pt)
		collision.polygon = my_new_polygon
		clone(other_new_polygon)
		shattering_in_progress = true
		refresh_polygon()
	else:
		print("No scar intersections")

func random_scar():
	#var start_pos_idx = randi_range(0, collision.polygon.size() - 2)
	#var start_pos = collision.polygon[start_pos_idx] + randf_range(0, 1) * (collision.polygon[(start_pos_idx+1)%collision.polygon.size()] - collision.polygon[start_pos_idx])
	var start_pos = get_random_edge_point()
	var end_pos = center
	var len = start_pos.distance_to(end_pos)
	#scar.generate_scar(collision.polygon, start_pos, randf_range(len/2, len*2), start_angle, 0, 1.0, 1.0)
	specific_scar(start_pos, end_pos + Vector2.ONE.rotated(deg_to_rad(randf_range(0, 360))) * randf_range(len/3, len/2), PI/6, 0.1, 0.2)

func specific_scar(start_pos:Vector2, end_pos:Vector2, max_deviation:float=0, min_segment_len:float=1.0, max_segment_len:float=1.0):
	var start_angle = start_pos.angle_to_point(end_pos)
	var scar:ItemScar = preload("res://ItemScar.tscn").instantiate()
	print("start=", start_pos, ", end=", end_pos, ", angle=", start_angle)
	scar.generate_scar(collision.polygon, start_pos, (end_pos-start_pos).length(), start_angle, max_deviation, min_segment_len, max_segment_len)
	add_scar(scar)
	

func _find_center() -> Vector2:
	var off:Vector2 = collision.polygon[0]
	var twiceArea:float = 0
	var x:float = 0
	var y:float = 0
	var p1:Vector2
	var p2:Vector2
	var f
	var j = collision.polygon.size() - 1
	for i in range(collision.polygon.size()):
		p1 = collision.polygon[i]
		p2 = collision.polygon[j]
		f = (p1.x - off.x) * (p2.y - off.y) - (p2.x - off.x) * (p1.y - off.y)
		twiceArea += f
		x += (p1.x + p2.x - 2*off.x) * f
		y += (p2.y + p2.y - 2*off.y) * f
		j = i
	f = twiceArea * 3
	area = twiceArea / 2
	center = Vector2(x/f+off.x, y/f+off.y)

	print("Center of ", name, " with ", collision.polygon.size(), " points: ", center)
	center_of_mass = center
	return center

func add_break_underlay(break_path, clip_polygon, offset=0.1):
	#for i in break_path.size():
	#	break_path[i] = break_path[i] + (center - break_path[i]).normalized()*0.1
	break_path = Geometry2D.clip_polyline_with_polygon(break_path, Geometry2D.offset_polygon(clip_polygon, 1))
	for path_part in break_path:
		var edge = load("res://ItemShardEdge.tscn").instantiate()
		var line = load("res://ItemShardEdgeLine.tscn").instantiate()
		line.points = path_part
		edge.add_child(line)
		shard_edges.add_child(edge)
