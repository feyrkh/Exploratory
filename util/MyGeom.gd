extends Node
class_name MyGeom

static func inflate_polyline(pts, offset):
	if pts.size() == 0:
		return []
	if pts.size() == 1:
		return [pts[0] + Vector2(-offset, -offset), pts[0] + Vector2(+offset, -offset), pts[0] + Vector2(+offset, +offset), pts[0] + Vector2(-offset, +offset)]
	var line_dir:Vector2
	if pts.size() == 2:
		line_dir = (pts[1] - pts[0]).normalized()
		return [pts[0] + line_dir.rotated(deg_to_rad(135)), pts[0] + line_dir.rotated(deg_to_rad(225)), pts[1] + line_dir.rotated(deg_to_rad(-45)), pts[1] + line_dir.rotated(45)]
	line_dir = (pts[1] - pts[0]).normalized() * offset
	# two points near start point
	var result = [pts[0] + line_dir.rotated(deg_to_rad(135))/2, pts[0] - line_dir * 2, pts[0] + line_dir.rotated(deg_to_rad(225))/2]
	if !Geometry2D.is_polygon_clockwise(result):
		result.reverse()
	#var result = [pts[0] - line_dir]
	var top_line = []
	var bottom_line = []
	for i in range(1, pts.size() - 1):
		var seg1 = Vector2(pts[i-1] - pts[i])
		var seg2 = Vector2(pts[i+1] - pts[i])
		var half_rads_between = seg1.angle_to(seg2) / 2
		if half_rads_between < 0:
			top_line.append(pts[i] + seg1.normalized().rotated(half_rads_between) * offset)
			bottom_line.append(pts[i] + seg1.normalized().rotated(half_rads_between + PI) * offset)
		else:
			bottom_line.append(pts[i] + seg1.normalized().rotated(half_rads_between) * offset)
			top_line.append(pts[i] + seg1.normalized().rotated(half_rads_between + PI) * offset)

	# record the top row of inflated points
	result.append_array(top_line)
	# record the inflated points on the end
	line_dir = (pts[-1] - pts[-2]).normalized() * offset
	var endcap = [pts[-1] + line_dir.rotated(deg_to_rad(225))/2, pts[-1] + line_dir * 2, pts[-1] + line_dir.rotated(deg_to_rad(135))/2]
	if !Geometry2D.is_polygon_clockwise(endcap):
		endcap.reverse()
	result.append_array(endcap)
	# record the bottom row, but it's reversed
	bottom_line.reverse()
	result.append_array(bottom_line)
	return result

static func shorten_path(path_part, shorten_amt:float):
	path_part[0] =  path_part[0] + (path_part[1] - path_part[0]).normalized() * shorten_amt
	path_part[-1] = path_part[-1] + (path_part[-2] - path_part[-1]).normalized() * shorten_amt

static func circle_polygon(pos:Vector2, radius:float, point_count:int) -> PackedVector2Array:
	var v: Vector2 = Vector2(0, radius)
	var delta_radians: float = 2 * PI / point_count
	var circle: PackedVector2Array = PackedVector2Array()
	circle.resize(point_count + 1)
	for i in range(point_count + 1):
		circle.append(v + pos)
		v = v.rotated(delta_radians)
	return circle

# Find the orientation of an ordered set of 3 points
# 0=colinear, 1=clockwise, 2=ccw
# https://www.geeksforgeeks.org/convex-hull-using-jarvis-algorithm-or-wrapping/
#static func orientation(p1:Vector2, p2:Vector2, p3:Vector2):
	#var val:int = (p2.y-p1.y)*(p3.x-p2.x)-(p2.x-p1.x)*(p3.y-p2.y)
	#if val == 0:
		#return 0
	#return 1 if val > 0 else 2
static func build_convex_polygon(points:PackedVector2Array) -> PackedVector2Array:
	return Geometry2D.convex_hull(points)

static func cleanup_close_points(poly:PackedVector2Array)->PackedVector2Array:
	# Find points that are too close together and merge them
	var points_to_delete := []
	for i in range(1, poly.size() - 1):
		var pt1 = poly[i-1]
		var pt2 = poly[i]
		if pt1.distance_squared_to(pt2) <= 1:
			points_to_delete.append(i)
	points_to_delete.reverse()
	for i in points_to_delete:
		#print("Merging points: ", poly[i], " and ", poly[i-1])
		poly[i-1] = (poly[i] + poly[i-1])/2.0
		poly.remove_at(i)
	return poly

static func cleanup_sharp_angles(poly:PackedVector2Array)->PackedVector2Array:
	#for i in range(-2, poly.size()-2):
		#var angle := poly[i+1].angle_to_point(poly[i]) - poly[i+1].angle_to_point(poly[i+2])
		#print("Angle made by ", i+1, " is ", rad_to_deg(angle))
	return poly

static func cleanup_self_intersections(poly:PackedVector2Array)->PackedVector2Array:
	var removed_intersection = true
	while removed_intersection:
		removed_intersection = false
		var intersecting_lines := []
		var prev_pt = poly[-1]
		# Find all intersecting lines and their lengths
		for i in poly.size():
			var cur_pt = poly[i]
			for j in range(i, poly.size()-2):
				var other_pt1 := poly[j]
				var other_pt2 := poly[j+1]
				var intersects = Geometry2D.segment_intersects_segment(prev_pt, cur_pt, other_pt1, other_pt2)
				if intersects:
					if other_pt1 == cur_pt and intersects.is_equal_approx(other_pt1):
						#print("Only intersection was at the endpoints")
						continue
					intersecting_lines.append([i-1, i, prev_pt.distance_to(cur_pt)])
					intersecting_lines.append([j, j+1, other_pt1.distance_to(other_pt2)])
			prev_pt = cur_pt
		#print("Found ", intersecting_lines.size(), " intersecting lines, ", intersecting_lines)
		if intersecting_lines.size() == 0:
			return poly
			
		var longest := {}
		for line in intersecting_lines:
			longest[line[0]] = max(longest.get(line[0], 0), line[2])
			longest[line[1]] = max(longest.get(line[1], 0), line[2])
		#print("Longest lines associated with each point: ", longest)
		intersecting_lines.sort_custom(func(a,b): return longest.get(a[0], 999999) + longest.get(a[1], 999999) < longest.get(b[0], 999999) + longest.get(b[1], 999999))
		#print("Point sorted by smallest impacted lines: ", intersecting_lines)
		var idx_to_remove
		if longest[intersecting_lines[0][0]] < longest[intersecting_lines[0][1]]:
			#print("Pt ", intersecting_lines[0][0], " has the smallest impactful intersections, deleting it")
			print("Removed self-intersection with length ", intersecting_lines[0][2])
			idx_to_remove = intersecting_lines[0][0]
		else:
			#print("Pt ", intersecting_lines[0][1], " has the smallest impactful intersections, deleting it")
			print("Removed self-intersection with length ", intersecting_lines[0][2])
			idx_to_remove = intersecting_lines[0][1]
		if idx_to_remove < 0: idx_to_remove += poly.size()
		poly.remove_at(idx_to_remove)
		removed_intersection = true
	return poly

#static func build_convex_polygon(points:PackedVector2Array) -> PackedVector2Array:
	#var n := points.size()
	#if points == null or n < 3:
		#return points
	#var hull:Array[Vector2] = []
	#
	## Find leftmost point
	#var leftmost_idx = 0
	#for i in range(1, n):
		#if points[i].x < points[leftmost_idx].x:
			#leftmost_idx = i
	#
	## Start from leftmost point, move counterclockwise until we reach the start
	## point again.
	#var p=leftmost_idx
	#var q
	#for j in points.size():
		#hull.append(points[p])
		## Search for a point 'q' such that orientation (p, q, x) is ccw for all
		## all points 'x'. The idea is to keep track of the last visited most ccw 
		## point in q. If any point 'i' is more ccw than q, then update q.
		#q = (p+1)%n
		#for i in range(n):
			#if orientation(points[p], points[i], points[q]) == 2:
				#q = i
		#p = q
		#if p == leftmost_idx:
			#break
	#return hull

static func calculate_area(polygon) -> float:
	var triangles = Geometry2D.triangulate_polygon(polygon)
	if triangles.size() == 0:
		polygon = Geometry2D.convex_hull(polygon)
		triangles = Geometry2D.triangulate_polygon(polygon)
	var twiceArea = 0
	for i in range(0, triangles.size(), 3):
		var t1 = triangles[i]
		var t2 = triangles[i+1]
		var t3 = triangles[i+2]
		twiceArea += abs(polygon[t1].x * (polygon[t2].y - polygon[t3].y) + polygon[t2].x * (polygon[t3].y - polygon[t1].y) + polygon[t3].x * (polygon[t1].y - polygon[t2].y))
	return twiceArea / 2

static func global_polygon(polygon_holder:Node2D):
	var result := PackedVector2Array()
	for pt in polygon_holder.polygon:
		result.append(polygon_holder.to_global(pt))
	return result

static func local_polygon(polygon_holder:Node2D, polygon):
	var result := PackedVector2Array()
	for pt in polygon:
		result.append(polygon_holder.to_local(pt))
	return result

static func random_bbox_edge_point(bbox:Rect2)->Vector2:
	var edge_len = bbox.size.x*2 + bbox.size.y*2
	var edge_dist = randf_range(0, edge_len)
	if edge_dist < bbox.size.x:
		return bbox.position + Vector2(edge_dist, 0)
	edge_dist -= bbox.size.x
	if edge_dist < bbox.size.y:
		return bbox.position + Vector2(bbox.size.x, edge_dist)
	edge_dist -= bbox.size.y
	if edge_dist < bbox.size.x:
		return bbox.position + Vector2(edge_dist, bbox.size.y)
	edge_dist -= bbox.size.x
	if edge_dist < bbox.size.y:
		return bbox.position + Vector2(0, edge_dist)
	push_error("Unexpectedly went outside the range of a bounding box ", bbox, " edge by ", edge_dist)
	return Vector2.ZERO
