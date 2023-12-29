extends Node2D

var SCROLL_SPEED = 25
var tables = []

# Called when the node enters the scene tree for the first time.
func _ready():
	var offset = randi_range(0, 1000)
	for i in range(4):
		var new_table = load("res://menu/main/DemoTable.tscn").instantiate()
		new_table.should_load_slowly = false
		add_child(new_table)
		new_table.position = Vector2(i * 1000 - offset, 0)
		tables.append(new_table)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	var dist = delta * SCROLL_SPEED
	for table in tables:
		table.position.x -= dist
	if tables[0].position.x < -1000:
		var new_table = load("res://menu/main/DemoTable.tscn").instantiate()
		add_child(new_table)
		new_table.position = Vector2(new_table.position.x + ((tables.size()-1) * 1000), 0)
		tables.append(new_table)
		tables[0].queue_free()
		tables.pop_front()
		
