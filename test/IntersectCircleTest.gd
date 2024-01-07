extends Node2D


# Called when the node enters the scene tree for the first time.
func _ready():
	var intersect1 := Geometry2D.segment_intersects_circle($Line2D.points[0], $Line2D.points[1], $Circle.position, 20)
	var intersect2 := Geometry2D.segment_intersects_circle($Line2D.points[1], $Line2D.points[0], $Circle.position, 20)
	if intersect1 != -1:
		$Circle2.position = $Line2D.points[0] + ($Line2D.points[1] - $Line2D.points[0]) * intersect1
	else:
		$Circle2.position = Vector2.ZERO
	if intersect2 != -1 and (abs(1-intersect2-intersect1) > 0.0001):
		$Circle3.position = $Line2D.points[1] + ($Line2D.points[0] - $Line2D.points[1]) * intersect2
	else:
		$Circle3.position = Vector2.ZERO
	
