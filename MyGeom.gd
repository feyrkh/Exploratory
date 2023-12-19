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
