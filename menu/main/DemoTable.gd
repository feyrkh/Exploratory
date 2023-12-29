extends Node2D

var primes = [79, 83, 89, 97]
var should_load_slowly = true

func _ready():
	var tree_to_use
	var num_items = randi_range(2, 5)
	num_items=5
	var start_slot = randi_range(0, 4)
	var prime = primes.pick_random()
	for i in range(num_items):
		var item := await ItemBuilder.build_random_item(null, should_load_slowly)
		item.is_display = true
		item.scale = (Vector2(0.5, 0.5))
		var slot = find_child("Slot"+str(start_slot))
		slot.add_child(item)
		item.position = Vector2(-(item.bounding_box.size.x/2) * item.scale.x, -(item.bounding_box.size.y) * item.scale.y)
		start_slot = (start_slot + prime) % 5
		await(get_tree().process_frame)
		for j in range(randi_range(3, 12)):
			item.random_scar()
		item.try_shatter(randf_range(0.5, 1.5), true)
	for i in range(10):
		await(get_tree().process_frame)
	for i in range(5):
		var slot = find_child("Slot"+str(i))
		for item in slot.get_children():
			if item is ArcheologyItem:
				item.build_glue_polygons(item.global_position, 99999999)
				await(get_tree().process_frame)
