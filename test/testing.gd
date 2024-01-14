extends Node2D

@onready var line = find_child("Line2D")
@onready var polygon = find_child("Polygon2D")

# Called when the node enters the scene tree for the first time.
func _ready():
	#var inflated = MyGeom.inflate_polyline(line.points, 10)
	#polygon.polygon = inflated
	var new_item = await ItemBuilder.build_random_item()
	add_child(new_item)
	new_item.position = Vector2(200, 200)
	var paths:Array[PackedVector2Array]
	paths = [FractureGenerator.edge_to_edge_fracture(new_item)]
	new_item.create_scars_from_paths(paths)
	paths = FractureGenerator.chisel_fracture(new_item, 4)
	new_item.create_scars_from_paths(paths)
	for i in 4:
		new_item.random_scar()
	new_item.try_shatter(0.5, false)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass
