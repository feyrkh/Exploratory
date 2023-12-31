extends Node2D
const SCROLL_SPEED := 50
const NUM_SLOTS := 4
var primes = [79, 83, 89, 97]
var should_load_slowly = true

func _ready():
	var noise:FastNoiseLite = null
	noise = FastNoiseLite.new()
	noise.noise_type = FastNoiseLite.TYPE_PERLIN
	noise.frequency = 0.1
	noise.fractal_lacunarity = 2
	noise.fractal_gain = 0.5
	noise.fractal_octaves = 8
	noise.fractal_type = FastNoiseLite.FRACTAL_FBM
	noise.seed = randf()
	var tree_to_use
	var num_items = randi_range(2, NUM_SLOTS)
	num_items=NUM_SLOTS
	var start_slot = randi_range(0, NUM_SLOTS-1)
	var prime = primes.pick_random()
	for i in range(num_items):
		var item := await ItemBuilder.build_random_item(null, should_load_slowly, noise if randf() < 0.3 else null, randf_range(0.1, 1.0))
		item.is_display = true
		item.scale = (Vector2(0.5, 0.5))
		var slot = find_child("Slot"+str(start_slot))
		slot.add_child(item)
		item.position = Vector2(-(item.bounding_box.size.x/2) * item.scale.x, -(item.bounding_box.size.y) * item.scale.y)
		start_slot = (start_slot + prime) % NUM_SLOTS
		if should_load_slowly:
			await(get_tree().process_frame)
		for j in range(randi_range(2, 7)):
			item.random_scar()
		if should_load_slowly:
			await(get_tree().process_frame)
		item.try_shatter(randf_range(0.5, 1.5), should_load_slowly)
		if should_load_slowly:
			for j in range(NUM_SLOTS):
				await(get_tree().process_frame)
	for i in range(NUM_SLOTS):
		var slot = find_child("Slot"+str(i))
		for item in slot.get_children():
			if is_instance_valid(item) and item is ArcheologyItem:
				item.build_glue_polygons(item.global_position, 99999999)
				if should_load_slowly:
					await(get_tree().process_frame)

func _process(delta):
	var dist = delta * SCROLL_SPEED
	position.x -= dist
