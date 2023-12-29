extends Node2D

var tables = []

# Called when the node enters the scene tree for the first time.
func _ready():
	var offset = randi_range(0, 1000)
	for i in range(5):
		var new_table = load("res://menu/main/DemoTable.tscn").instantiate()
		new_table.should_load_slowly = false
		add_child(new_table)
		new_table.position = Vector2(i * 1000 - offset, 0)
		tables.append(new_table)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	if tables[0].position.x < -1000:
		tables[0].position = Vector2(tables[0].position.x + ((tables.size()) * 1000), 0)
		#tables.append(new_table)
		#tables[0].queue_free()
		tables.append(tables.pop_front())
		
