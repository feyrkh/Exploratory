extends Node2D
class_name ItemGlueEdge

@onready var polygon2d:Polygon2D = $Polygon2D

var polygon:
	get:
		return polygon2d.polygon
	set(val):
		polygon2d.polygon = val

func setup(poly):
	$Polygon2D.polygon = poly
