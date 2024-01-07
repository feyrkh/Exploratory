extends Node
class_name MyGeom

static func inflate_polyline(pts, offset):
	if pts.size() == 0:
		return []
	if pts.size() == 1:
		return [pts[0] + Vector2(-offset, -offset), pts[0] + Vector2(+offset, -offset), pts[0] + Vector2(+offset, +offset), pts[0] + Vector2(-offset, +offset)]
	if pts.size() == 2:
		var line_dir = (pts[1] - pts[0]).normalized()
		return [pts[0] + line_dir.rotated(deg_to_rad(135)), pts[0] + line_dir.rotated(deg_to_rad(225)), pts[1] + line_dir.rotated(deg_to_rad(-45)), pts[1] + line_dir.rotated(45)]
	var line_dir = (pts[1] - pts[0]).normalized() * offset
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
		var half_degs_between = rad_to_deg(half_rads_between)
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
