extends Node2D

@onready var line = find_child("Line2D")
@onready var polygon = find_child("Polygon2D")

# Called when the node enters the scene tree for the first time.
func _ready():
	var inflated = MyGeom.inflate_polyline(line.points, 10)
	polygon.polygon = inflated


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass
