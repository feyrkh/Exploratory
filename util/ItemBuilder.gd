extends Node

## Valid entries for the 'type' field of .cfg files
const VALID_TYPES := ['icon', 'band', 'base']
## Which of the 'type' entries also require a .png file to exist alongside it
const IMAGE_TYPES := VALID_TYPES

var all_items = {}
var base_item_names = []

class ItemConfig:
	var item_name
	var item_dir
	var type:String = "icon"
	var img_size:Vector2
	var min_scale:Vector2 = Vector2.ONE
	var max_scale:Vector2 = Vector2(100, 100)
	## optional array of strings like "ffffff" - if provided, these colors will be used for random selections
	## if not provided, will use some global settings which I haven't figured out yet
	var colors
	
	func get_texture() -> Texture2D:
		return load(item_dir+item_name+".png")
	
	func load_collider_scene():
		return load(item_dir+item_name+'_collider.tscn').instantiate()
	
	func get_shadow_texture() -> Texture2D:
		if FileAccess.file_exists(item_dir+item_name+"_shadow.png"):
			return load(item_dir+item_name+"_shadow.png")
		else:
			return null

func _ready():
	reload_definitions()

func filter_options(item_type:String, desired_size:Vector2) -> Array[ItemConfig]:
	var retval:Array[ItemConfig] = []
	var items = {}
	for item_name in all_items:
		var item = all_items[item_name]
		if item.type != item_type:
			continue
		var desired_scale = desired_size / item.img_size
		# allow this item if it the desired scale is bigger than the minimum scale on both axes
		# if the desired scale is bigger than the max scale, then we can either center it or pick a random position when placing it 
		if desired_scale.x < item.min_scale.x and desired_scale.y < item.min_scale.y:
			continue
		retval.append(item)
	return retval

## The collider and/or sprite may not be correctly placed at position 0,0 in the scenes we're loading, so we adjust the collider based on that
func correct_collider_position(collider:CollisionPolygon2D, sprite:Sprite2D) -> Array[Vector2]:
	var retval:Array[Vector2] = []
	var sprite_offset = sprite.position
	var collider_offset = collider.position
	var adjustment = collider_offset - sprite_offset
	for pt in collider.polygon:
		retval.append(pt + adjustment)
	return retval

func build_random_item(base_item_name=null) -> ArcheologyItem:
	if base_item_name == null:
		base_item_name = base_item_names.pick_random()
	print("Building random item with ", base_item_name)
	var base_item_cfg:ItemConfig = all_items[base_item_name]
	var collider_scene = base_item_cfg.load_collider_scene()
	var item_collider = collider_scene.find_child("CollisionPolygon2D")
	var retval:ArcheologyItem = load("res://ArcheologyItem.tscn").instantiate()
	var retval_collider:CollisionPolygon2D = retval.find_child("CollisionPolygon2D")
	var retval_img:Polygon2D = retval.find_child("Polygon2D")
	retval_collider.polygon = PackedVector2Array(correct_collider_position(item_collider, collider_scene.find_child("Sprite2D")))
	var shadow_texture := base_item_cfg.get_shadow_texture()
	# find out what groups exist
	var placement_groups = {}
	var unnamed_group_id = -1
	for child in collider_scene.get_children():
		if child is DecorationBase:
			if child.group == null || child.group == "":
				child.group = str(unnamed_group_id)
				unnamed_group_id -= 1
			if child.img_id == null || child.img_id == "":
				child.img_id = str(unnamed_group_id)
				unnamed_group_id -= 1
			if placement_groups.get(child.group) == null:
				placement_groups[str(child.group)] = [child]
			else:
				placement_groups[str(child.group)].append(child)
	# pick a random placement group, discard any groups that conflict with it, and repeat
	var placements_used = []
	var groups_used = 0
	var img_groups = {}
	while placement_groups.size() > 0:
		var cur_group_name = placement_groups.keys().pick_random()
		var potential_placements = placement_groups[cur_group_name]
		placement_groups.erase(cur_group_name)
		var placement_valid = true
		for potential_placement in potential_placements:
			if !placement_valid: break
			var potential_placement_rect:Rect2 = potential_placement.get_rect()
			for existing_placement in placements_used:
				var existing_placement_rect:Rect2 = existing_placement.get_rect()
				if potential_placement_rect.intersects(existing_placement_rect):
					placement_valid = false
					break
		if placement_valid:
			groups_used += 1
			placements_used.append_array(potential_placements)
			for placement in potential_placements:
				if img_groups.get(placement.img_id) == null:
					img_groups[placement.img_id] = [placement]
				else:
					img_groups[placement.img_id].append(placement)
			if randf() > 0.5:
				# 50% chance to stop adding new groups after the first
				break
	# find which images will be used for each unique image id
	var img_group_choices = {}
	var img_group_colors = {}
	for img_group in img_groups:
		var smallest_rect = Vector2(9999999, 9999999)
		for placement in img_groups[img_group]:
			var cur_rect = placement.get_size()
			if cur_rect.x < smallest_rect.x:
				smallest_rect.x = cur_rect.x
			if cur_rect.y < smallest_rect.y:
				smallest_rect.y = cur_rect.y
		var options = filter_options(str(img_groups[img_group][0].type), smallest_rect)
		if options.size() >= 1:
			img_group_choices[img_group] = options.pick_random()
			if img_group_choices[img_group].colors == null or img_group_choices[img_group].colors.size() == 0:
				img_group_colors[img_group] = [Color.SADDLE_BROWN, Color.DARK_RED, Color.DIM_GRAY, Color.GREEN_YELLOW, Color.DARK_BLUE, Color.DARK_SLATE_BLUE, Color.MAROON].pick_random()
			else:
				img_group_colors[img_group] = img_group_choices[img_group].colors.pick_random()
	# place the images
	var base_image_details := ImageMerger.ImageMergeInfo.new()
	base_image_details.img = base_item_cfg.get_texture().get_image()
	base_image_details.position = Vector2.ZERO
	if base_item_cfg.colors == null or base_item_cfg.colors.size() == 0:
		base_image_details.modulate = [Color.ANTIQUE_WHITE, Color.BROWN, Color.CORAL, Color.FIREBRICK, Color.PERU, Color.SADDLE_BROWN].pick_random()
	else:
		base_image_details.modulate = base_item_cfg.colors.pick_random()

	var image_details:Array[ImageMerger.ImageMergeInfo] = [base_image_details]
	
	for placement in placements_used:
		var info := ImageMerger.ImageMergeInfo.new()
		info.img = img_group_choices[placement.img_id].get_texture().get_image()
		var x_scale = placement.get_size().x / info.img.get_size().x 
		var y_scale = placement.get_size().y / info.img.get_size().y
		var actual_scale = Vector2(min(x_scale, y_scale), min(x_scale, y_scale))
		info.img.resize(info.img.get_size().x * min(x_scale, y_scale), info.img.get_size().y * min(x_scale, y_scale))
		info.position = placement.position + placement.get_size()/2 - Vector2(info.img.get_size())/2
		info.modulate = img_group_colors[placement.img_id]
		image_details.append(info)
	
	var shadow = base_item_cfg.get_shadow_texture()
	if shadow:
		var shadow_details := ImageMerger.ImageMergeInfo.new()
		shadow_details.img = shadow.get_image()
		shadow_details.position = Vector2.ZERO
		shadow_details.modulate = Color.WHITE
		#image_details.append(shadow_details)
	
	var combined_img := ImageMerger.merge_images(image_details)
	retval_img.texture = combined_img
	
	return retval

func reload_definitions():
	all_items = {}
	base_item_names = []
	var dir := DirAccess.open("res://art/item")
	process_dir(dir)
	dir = DirAccess.open("user://mods/items")
	process_dir(dir)

func process_dir(dir:DirAccess):
	if dir:
		dir.list_dir_begin()
		var file_name = dir.get_next()
		while file_name != "":
			if !dir.current_is_dir():
				if file_name.ends_with(".cfg"):
					read_file(dir.get_current_dir()+"/", file_name)
			file_name = dir.get_next()
	else:
		print("An error occurred when trying to access the path.")

func read_file(dir_name, file_name):
	var file_path = dir_name+file_name
	var file_name_prefix = file_name.substr(0, file_name.length()-4)
	print("Processing config file: ", file_path)
	var file = FileAccess.open(file_path, FileAccess.READ)
	var content = file.get_as_text()
	var data = JSON.parse_string(content)
	if data == null:
		push_error("Error reading ", file_path, ", skipping")
		return
	var item = ItemConfig.new()
	item.item_name = file_name_prefix
	item.item_dir = dir_name
	if data['type'] == null:
		push_error(file_path, " missing 'type' of item, skipping")
		return
	if data['type'] not in VALID_TYPES:
		push_error(file_path, " has invalid type ", data['type'], " expected one of ", VALID_TYPES)
		return
	item.type = data['type']
	if item.type in IMAGE_TYPES:
		if !FileAccess.file_exists(dir_name+file_name_prefix+".png"):
			print("Found an item/deco config file, but it doesn't have a matching .png file, can't use this one!")
			return
		item.img_size = load(dir_name+file_name_prefix+".png").get_size()
	if item.type == 'base':
		if !FileAccess.file_exists(dir_name+file_name_prefix+'_collider.tscn'):
			print("Found a base item config file, but it doesn't have a matching ", file_name_prefix+'_collider.tscn', " file, can't use this one!")
			return
	if data.get('min_scale') != null:
		item.min_scale = Vector2(data['min_scale'], data['min_scale'])
	if data.get('max_scale') != null:
		item.max_scale = Vector2(data['max_scale'], data['max_scale'])
	if data.get('min_scale_x') != null:
		item.min_scale = Vector2(data['min_scale_x'], item.min_scale.y)
	if data.get('max_scale_x') != null:
		item.max_scale = Vector2(data['max_scale_x'], item.max_scale.y)
	if data.get('min_scale_y') != null:
		item.min_scale = Vector2(item.min_scale.x, data['min_scale_y'])
	if data.get('max_scale_y') != null:
		item.max_scale = Vector2(item.max_scale.x, data['max_scale_y'])
	item.colors = data.get('colors')
	match item.type:
		'base': 
			all_items[file_name_prefix] = item
			base_item_names.append(item.item_name)
		'band': all_items[file_name_prefix] = item
		'icon': all_items[file_name_prefix] = item
		_: push_error("Didn't know where to save this kind of file: ", item.type)
