extends Node2D


# Called when the node enters the scene tree for the first time.
func _ready():
	refresh_polygon()

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	if Input.is_action_just_pressed("ui_cancel"):
		clear_polygon()
	elif Input.is_action_just_released("ui_cancel"):
		refresh_polygon()
	clear_polygon()
	refresh_polygon()

func clear_polygon():
	$Polygon2D.polygon = Array()
	for child in $Points.get_children():
		child.queue_free()

func refresh_polygon():
	var poly:PackedVector2Array = []
	for i in range(20):
		poly.append(Vector2(randf_range(100, 500), randf_range(100, 500)))
	for pt in poly:
		var new_pt := Polygon2D.new()
		new_pt.polygon = [Vector2(-1, -1), Vector2(1, -1), Vector2(1, 1), Vector2(-1, 1)]
		new_pt.position = pt
		$Points.add_child(new_pt)
	$Polygon2D.polygon = MyGeom.build_convex_polygon(poly)
