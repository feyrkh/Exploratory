extends RigidBody2D
class_name ArcheologyItem

const TOO_SMALL_POLYGON_AREA := 35
const TOO_SMALL_POLYGON_EDGE_RATIO := 0.6

enum Fields {IMG_DATA, POSITION, ROTATION, POLYGON, ORIG_AREA, SHATTER_SIZE}

# if -1, the mouse is not hovering over this piece
var hover_idx = -1
# If null, the user is not dragging this piece
var drag_start_mouse = null
var drag_start_item = null
var target_pos = null
# if null, the user is not rotating this piece
var rotate_start_mouse = null
var rotate_start_item = null
var rotate_start_item_com_position = null
var target_rot = null
var reset_position = null
var reset_rotation = null
var bounding_box:Rect2
var loading:bool = false
## This item is being used for display only and can't be interacted with
var is_display:bool = false:
	set(val):
		is_display = val
		apply_global_settings()
		if !is_display:
			set_process(false)
			set_process_input(false)

var original_boundary_polygon

# Length of all the edges in pixels, used for picking random spots on the edge
var total_edge_length:float = 0
var shattering_in_progress:
	set(val):
		shattering_in_progress = val
		set_process(!!val)
var shatter_size = 0.05

var center:
	get:
		if center == null:
			_find_center()
			center_of_mass = center
		return center
var area:float:
	get:
		if area == 0:
			for child in get_children():
				if child is CollisionPolygon2D:
					area += _calculate_area(child.polygon)
		return area

var original_area
var area_pct:
	get:
		if !original_area:
			refresh_polygon()
		return area / original_area

var visual_polygons:Array[ItemPolygon2D] = []:
	get:
		if visual_polygons.size() == 0:
			for child in get_children():
				if child is ItemPolygon2D:
					visual_polygons.append(child)
		return visual_polygons

var collision_polygons:Array[CollisionPolygon2D] = []:
	get:
		if collision_polygons.size() == 0:
			for child in get_children():
				if child is CollisionPolygon2D:
					collision_polygons.append(child)
		return collision_polygons

var glue_hashes = null:
	get:
		if glue_hashes == null:
			glue_hashes = {}
			for child in $Glue.get_children():
				glue_hashes[child.polygon.hash()] = child
		return glue_hashes

@onready var collision:CollisionPolygon2D = find_child("CollisionPolygon2D"):
	get:
		if collision == null:
			for child in get_children():
				if child is CollisionPolygon2D:
					collision = child
					break
		return collision
@onready var scars:Node2D = find_child("Scars")
@onready var polygon:ItemPolygon2D = find_child("Polygon2D"):
	get:
		if polygon == null:
			for child in get_children():
				if child is ItemPolygon2D:
					polygon = child
					break
		return polygon
@onready var shard_edges:Node2D = find_child("ShardEdges")
@onready var glue_edges:Node2D = find_child("Glue")
var _gallery_mode = false

func get_save_data(image_save_data:Dictionary) -> Dictionary: # Dictionary[String, ImageBuilder.ImageSaveData]
	var result := []
	var img_save_data = []
	var scar_save_data = []
	var edge_save_data = []
	var glue_save_data = []
	for child in get_children():
		if child is ItemPolygon2D:
			var child_image_data = child.save_data
			if !image_save_data.has(child_image_data):
				image_save_data[child_image_data] = ImageBuilder.get_next_unique_id()
			img_save_data.append({
				Fields.IMG_DATA: image_save_data[child_image_data],
				Fields.POSITION: child.position,
				Fields.ROTATION: child.rotation,
				Fields.POLYGON: child.polygon
			})
	for child in scars.get_children():
		scar_save_data.append(child.get_save_data())
	for child in shard_edges.get_children():
		edge_save_data.append(child.get_save_data())
	var me_data = {
		Fields.POSITION: global_position,
		Fields.ROTATION: global_rotation,
		Fields.ORIG_AREA: original_area,
		Fields.SHATTER_SIZE: shatter_size
	}
	return {"img":img_save_data, "scar":scar_save_data, "edge":edge_save_data, "me":me_data}

## item_save = as returned from get_save_data
## image_save_data = Dictionary[int (referenced from item_save[IMG_DATA]), Array[ImageBuilder.ImageSaveData]]
## rebuilt_textures = Dictionary[int (referenced from item_save[IMG_DATA]), Texture2D]
## image_save_data values may be either an array of ImageSaveData objects, or an inverted copy of the map
## 		populated by the parameter to ArcheologyItem.get_save_data()
## rebuilt_textures may be passed as an empty dictionary to be populated if desired
static func load_save_data(item_save:Dictionary, image_save_data:Dictionary, rebuilt_textures:Dictionary) -> ArcheologyItem: 
	for k in image_save_data.keys():
		if image_save_data[k] != null and image_save_data[k].size() > 0 and !(image_save_data[k][0] is ItemBuilder.ImageSaveData):
			image_save_data[k] = image_save_data[k].map(func(v): return ItemBuilder.ImageSaveData.load_save_data(v))
		if !rebuilt_textures.has(k):
			rebuilt_textures[k] = await ItemBuilder.build_specific_item(image_save_data[k])
	var result = load("res://pottery/ArcheologyItem.tscn").instantiate()
	var orig_poly = result.find_child("Polygon2D")
	result.remove_child(orig_poly)
	orig_poly.queue_free()
	orig_poly = result.find_child("CollisionPolygon2D")
	result.remove_child(orig_poly)
	orig_poly.queue_free()
	var poly_data = item_save.get("img", [])
	var scar_data = item_save.get("scar", [])
	var edge_data = item_save.get("edge", [])
	var me_data = item_save.get("me", {})
	result.global_position = me_data[Fields.POSITION]
	result.global_rotation = me_data[Fields.ROTATION]
	result.original_area = me_data[Fields.ORIG_AREA]
	for data in poly_data:
		var new_polygon = ItemPolygon2D.new()
		new_polygon.visibility_layer = 3 # Visible on layers 1 (normal view) and 2 (screenshot view)
		new_polygon.save_data = image_save_data[data[Fields.IMG_DATA]]
		new_polygon.texture = rebuilt_textures[data[Fields.IMG_DATA]]
		new_polygon.position = data[Fields.POSITION]
		new_polygon.rotation = data[Fields.ROTATION]
		new_polygon.polygon = data[Fields.POLYGON]
		var new_collision = CollisionPolygon2D.new()
		new_collision.position = new_polygon.position
		new_collision.rotation = new_polygon.rotation
		new_collision.polygon = new_polygon.polygon
		result.add_child(new_polygon)
		result.add_child(new_collision)
	for data in scar_data:
		var new_scar = ItemScar.load_save_data(data)
		result.find_child("Scars").add_child(new_scar)
	for data in edge_data:
		var new_edge = ItemShardEdge.load_save_data(data)
		result.find_child("ShardEdges").add_child(new_edge)
	result.loading = true
	result.call_deferred("post_load")
	return result

func post_load():
	get_tree().process_frame.connect(_post_load, CONNECT_ONE_SHOT)

func _post_load():
	center = null
	area = 0
	collision_polygons = []
	visual_polygons = []
	polygon = null
	collision = null
	glue_hashes = null
	refresh_polygon()
	loading = false
	for child in $ShardEdges.get_children():
		child.loading = false
	apply_global_settings()

func _ready():
	if !loading:
		refresh_polygon()
	if original_area == null:
		original_area = area

func gallery_mode():
	_gallery_mode = true
	collision_mask &= ~1 # disable collision with other pieces
	_find_center() # trigger center calculations so the center of mass gets calculated properly

func _process(_delta):
	if shattering_in_progress:
		try_shatter(shattering_in_progress[0], shattering_in_progress[1])

func apply_global_settings():
	if !is_display:
		lock_rotation = Global.lock_rotation
		safe_freeze(Global.freeze_pieces)
		global_collide(Global.collide)
	else:
		lock_rotation = true
		safe_freeze(true)
		global_collide(false)

func global_lock_rotation(val:bool):
	# Called by Global.lock_rotation when rotation locking for fragments is enabled/disabled
	# Only applied if we're not already dragging or rotating the current item - when we stop, it will take on the global setting again
	if drag_start_item == null and rotate_start_item == null:
		lock_rotation = val

func global_freeze_pieces(val:bool):
	# Called by Global.freeze_pieces. Only applied if we're not already interacting with the current item.
	if drag_start_item == null and rotate_start_item == null:
		safe_freeze(val)
		
func global_collide(val:bool):
	if _gallery_mode:
		return
	# Called by Global.collide when piece collisions should be disabled
	if val:
		collision_mask |= 1 # allow this piece to collide with elements on layer 1
		#modulate.a = 1.0
	else:
		collision_mask &= ~1 # prevent this piece from colliding with elements on layer 1
		#modulate.a = 0.8

func clone(new_polygon:Array, should_clone_slow=false):
	## TODO: Make this handle cloning glued items
	var new_scene = preload("res://pottery/ArcheologyItem.tscn").instantiate()
	new_scene.find_child("Polygon2D").texture = visual_polygons[0].texture
	new_scene.original_area = original_area
	new_scene.is_display = is_display
	new_scene.original_boundary_polygon = original_boundary_polygon
	get_parent().add_child(new_scene)
	new_scene.global_position = global_position
	new_scene.global_rotation = global_rotation
	new_scene.collision.polygon = new_polygon
	new_scene.collision_mask = collision_mask
	new_scene.safe_freeze(freeze)
	new_scene.lock_rotation = lock_rotation
	new_scene.scale = scale
	new_scene.shatter_size = shatter_size
	if should_clone_slow:
		await get_tree().process_frame
	#for scar in scars.get_children():
	#	var new_scar = scar.clone()
	#	new_scene.scars.add_child(new_scar)
	if should_clone_slow:
		await get_tree().process_frame
	for edge in shard_edges.get_children():
		var new_edge = edge.clone()
		new_scene.shard_edges.add_child(new_edge)
	new_scene.shattering_in_progress = shattering_in_progress
	new_scene.find_child("Polygon2D").save_data = polygon.save_data
	#await get_tree().physics_frame
	return new_scene

func refresh_polygon() -> int:
	center = null
	area = 0
	if collision.polygon[0].distance_to(collision.polygon[-1]) < 0.5:
		# sometimes the last point ends up being identical to the first point, and that can cause problems, so delete it
		#print("Cleaning up duplicate polygon point: ", collision.polygon[0], " vs ", collision.polygon[-1])
		var new_polygon = Array(collision.polygon)
		new_polygon.pop_back()
		collision.polygon = new_polygon
	if collision.position != Vector2.ZERO:
		var offset = collision.position
		collision.position = Vector2.ZERO
		var new_polygon = []
		for i in range(collision.polygon.size()):
			new_polygon.append(collision.polygon[i] + offset)
		collision.polygon = new_polygon
	polygon.polygon = collision.polygon
	total_edge_length = 0
	for i in range(collision.polygon.size()):
		var j = (i+1) % collision.polygon.size()
		total_edge_length += collision.polygon[i].distance_to(collision.polygon[j])
	if _gallery_mode:
		return 1
	polygon.uv = collision.polygon
	var scar_trim_poly = Geometry2D.offset_polygon(collision.polygon, shatter_size+0.05)
	for scar in scars.get_children():
		scar.refresh_scar_path(collision.polygon)
	for edge in shard_edges.get_children():
		if scar_trim_poly.size() > 0:
			edge.refresh_edge_path(scar_trim_poly[0])
	if abs(area) < TOO_SMALL_POLYGON_AREA:
		#print("Too-small shard was created, area is ", area, ", deleting")
		queue_free()
		return 0
	elif abs(area) < total_edge_length*TOO_SMALL_POLYGON_EDGE_RATIO:
		#print("Too-skinny shard was created, area is ", area, " which is smaller than the total edge length ", total_edge_length, " times ", TOO_SMALL_POLYGON_EDGE_RATIO)
		queue_free()
		return 0
	else:
		#print("Decent-sized shard was created, area is ", area)
		center_of_mass = center
		return 1

func get_random_edge_point() -> Vector2:
	var dist = randf_range(0, total_edge_length)
	var i = 0
	while(dist > 0 and i < collision.polygon.size()):
		var start_pt = collision.polygon[i]
		var next_pt = collision.polygon[(i+1) % collision.polygon.size()]
		var cur_len = next_pt.distance_to(start_pt)
		if cur_len >= dist:
			return start_pt + (next_pt - start_pt).normalized() * dist
		dist -= cur_len
		i += 1
	return collision.polygon[0]

func _unhandled_input(event):
	if is_display: 
		return
	match Global.click_mode:
		Global.ClickMode.move: handle_move_input(event)
		Global.ClickMode.save_item: handle_save_item_input(event)

func handle_save_item_input(event):
	if event is InputEventMouseButton:
		if hover_idx >= 0:
			if event.is_action_pressed("drag_start"):
				save_to_gallery()

func handle_move_input(event):
	if event is InputEventMouseButton:
		#print("Clicked: ", event)
		if hover_idx >= 0:
			if event.is_action_pressed("drag_start"):
				print("Starting drag")
				drag_start_mouse = get_global_mouse_position()
				drag_start_item = global_position
				lock_rotation = true
				safe_freeze(false)
				var prev_top = get_parent().get_child(-1)
				get_parent().move_child(self, -1)
				for i in range(get_parent().get_child_count()):
					get_parent().get_child(i).z_index = i * 5
				get_viewport().set_input_as_handled()
			if event.is_action_pressed("break_item"):
				random_scar()
			if event.is_action_pressed("rotate_start"):
				rotate_start_mouse = to_global(center_of_mass).angle_to_point(get_global_mouse_position())
				rotate_start_item = global_rotation
				rotate_start_item_com_position = to_global(center_of_mass)
				lock_rotation = false
				safe_freeze(false)
				print("Mouse at ", get_global_mouse_position(), ", COM at ", to_global(center_of_mass))
				print("Starting rotate, initial rotation=", rad_to_deg(global_rotation), ", mouse start angle=", rad_to_deg(rotate_start_mouse))
		if drag_start_mouse != null and event.is_action_released("drag_start"):
			drag_start_mouse = null
			drag_start_item = null
			target_pos = null
			if hover_idx == -1:
				_on_mouse_shape_exited(-1)
			lock_rotation = Global.lock_rotation
			safe_freeze(Global.freeze_pieces)
			#print("Ending drag")
		elif rotate_start_mouse != null and event.is_action_released("rotate_start"):
			rotate_start_mouse = null
			rotate_start_item = null
			target_rot = null
			lock_rotation = Global.lock_rotation
			safe_freeze(Global.freeze_pieces)
			print("Stopping rotate")
	elif drag_start_mouse != null and event is InputEventMouseMotion:
		target_pos = get_global_mouse_position()
	elif rotate_start_mouse != null and event is InputEventMouseMotion:
		target_rot = 0.1 # just something to get the _integrate_forces method started
	elif hover_idx >= 0 and event.is_action_pressed("delete_item"):
		print("Deleting item ", self)
		queue_free()

func _integrate_forces(state):
	if reset_position != null:
		freeze = false
		state.transform = state.transform.rotated(-state.transform.get_rotation())
		state.transform = state.transform.rotated(reset_rotation)
		state.transform.origin = reset_position
		reset_position = null
		#safe_freeze(Global.freeze_pieces)
		set_deferred("freeze", Global.freeze_pieces)
	if target_pos != null:
		var desired_motion = drag_start_item - global_position + target_pos - drag_start_mouse
		state.linear_velocity = desired_motion * 25
	if target_rot != null:
		var item_center = to_global(center_of_mass)
		var mouse_cursor = get_global_mouse_position()
		var angle_from_item_to_mouse = item_center.angle_to_point(mouse_cursor)
		var offset_from_original_angle = angle_from_item_to_mouse - rotate_start_mouse
		var distance_already_rotated = global_rotation - rotate_start_item
		var distance_to_rotate = offset_from_original_angle - distance_already_rotated
		if distance_to_rotate >= PI:
			distance_to_rotate -= 2*PI
		elif distance_to_rotate <= -PI:
			distance_to_rotate += 2*PI
		target_rot = distance_to_rotate
		while target_rot > PI:
			target_rot -= PI
		while target_rot < -PI:
			target_rot += PI
		angular_velocity = target_rot * 15

func _on_mouse_shape_entered(shape_idx):
	if is_display:
		return
	if Global.click_mode == Global.ClickMode.move or Global.click_mode == Global.ClickMode.save_item:
		highlight_visual_polygons()
	#print("Hovering ", shape_idx)
	hover_idx = shape_idx

func _on_mouse_shape_exited(shape_idx):
	if is_display:
		return
	if shape_idx == hover_idx:
		if drag_start_item == null:
			if Global.click_mode == Global.ClickMode.move or Global.click_mode == Global.ClickMode.save_item:
				unhighlight_visual_polygons()
		#print("Left hover ", shape_idx)
		hover_idx = -1

func highlight_visual_polygons():
	for polygon in visual_polygons:
		polygon.modulate = Color(1.3, 1.3, 1.3, 1.3)

func unhighlight_visual_polygons():
	for polygon in visual_polygons:
		polygon.modulate = Color.WHITE

func add_scar(scar:ItemScar):
	scar.refresh_scar_path(collision.polygon)
	for scar2 in scars.get_children():
		# Check that no other scars start really close to the start/end of this scar - if they do, skip it
		if scar.line.points[0].distance_squared_to(scar2.line.points[0]) <= 25 or scar.line.points[-1].distance_squared_to(scar2.line.points[0]) <= 25:
			# One of the endpoints is too close to an existing scar, delete it to avoid bad fragments later
			scar.queue_free()
	scars.add_child(scar)

#func try_shatter_all_at_once():
	#var working_polygons = [collision.polygon]
	#var scar_polygons = []
	#for scar in scars.get_children():
		#scar_polygons.append(MyGeom.inflate_polyline(scar.line.points, 1))
	#for break_poly in scar_polygons:
		#var new_polygons = []
		#for working_poly in working_polygons:
			#var clipped_polygons = Geometry2D.clip_polygons(collision.polygon, break_poly)
			##for poly in clipped_polygons:
				## check that each result polygon is clockwise, reverse it if not
				##if !Geometry2D.is_polygon_clockwise(poly):
				##	poly.reverse()
			#new_polygons.append_array(clipped_polygons)
		#working_polygons = new_polygons
	#for poly in working_polygons:

func try_shatter(shatter_width:float = Global.shatter_width, should_shatter_slow:bool=true):
	shattering_in_progress = false
	if original_boundary_polygon == null:
		original_boundary_polygon = Geometry2D.offset_polygon(collision.polygon, -0.1)[0]
	shatter_size = shatter_width
	var scar_lines:Array = scars.get_children().map(
		func(scar): 
			add_unconditional_underlay(scar.get_child(0).points)
			scar.queue_free()
			return scar.get_child(0).points
	)
	var scar_polys:Array = scar_lines.map(func(scar_line): return MyGeom.inflate_polyline(scar_line, shatter_size))
	var collision_polygon_list:Array = collision_polygons.map(func(node): return node.polygon)
	var new_collision_polygons = []
	#var new_polygons_created = true
	
#	while new_polygons_created:
#		new_polygons_created = false
	for scar_poly in scar_polys:
		if should_shatter_slow and randf() < 0.1:
			await get_tree().process_frame
		for collision_polygon in collision_polygon_list:
			# intersect our break path with our existing polygon
			var clipped_polygons = Geometry2D.clip_polygons(collision_polygon, scar_poly)
			if clipped_polygons.size() != 1:
				new_collision_polygons.append_array(clipped_polygons)
			elif clipped_polygons.size() == 1 :
				new_collision_polygons.append(clipped_polygons[0])
		collision_polygon_list = new_collision_polygons
		new_collision_polygons = []

	for i in range(0, collision_polygon_list.size()):
		if should_shatter_slow:
			await get_tree().process_frame
		var new_item = await clone(collision_polygon_list[i], should_shatter_slow)
		new_item.refresh_polygon()
	queue_free()

func vector_arrays_equal(arr1:PackedVector2Array, arr2:PackedVector2Array) -> bool:
	if arr1.size() != arr2.size(): 
		return false
	var hash1 = 0
	var hash2 = 0
	for a in arr1:
		hash1 += a.length_squared()
	for b in arr2:
		hash2 += b.length_squared()
	return abs(hash1 - hash2) < 0.01

func try_shatter_old(shatter_width:float = Global.shatter_width, should_shatter_slow:bool=false):
	shattering_in_progress = false
	shatter_size = shatter_width
	# look at each scar in turn
	var scar_count = scars.get_child_count()
	var break_path
	var scar1:ItemScar
	var scar2:ItemScar
	var scar1_edge_segments
	var scar2_edge_segments
	for pt_idx in range(collision.polygon.size()):
		if break_path != null: break
		var next_pt_idx = (pt_idx + 1) % collision.polygon.size()
		for scar1_idx in range(scar_count):
			if break_path != null: break
			scar1 = scars.get_child(scar1_idx)
			# check if that scar intersects the same edge on both sides, if so that's our break path
			var scar1_intersect = scar1.get_edge_intersections(collision.polygon[pt_idx], collision.polygon[next_pt_idx])
			if scar1_intersect == null:
				continue
			if scar1_intersect[-1] == "both":
				break_path = scar1.line.points
				scar1_edge_segments = break_path
				break
			# otherwise, look for any scar which intersects with this one, our break path is the first scar up to the intersection point, then follow the second scar back to its start
			for scar2_idx in range(scar1_idx+1, scar_count):
				scar2 = scars.get_child(scar2_idx)
				var scar1_intersect_scar2 = scar1.intersect_scar(scar2, false, false)
				if scar1_intersect_scar2:
					break_path = scar1_intersect_scar2[0]
					scar1_edge_segments = scar1_intersect_scar2[1]
					scar2_edge_segments = scar1_intersect_scar2[2]
					break
			if !break_path:
				scar2 = null
				# Finally, if no other scars intersect this one, look at whether the endpoint of this scar intersects any other edges
				for endpt_idx in range(collision.polygon.size()):
					var next_endpt_idx = (endpt_idx + 1) % collision.polygon.size()
					var scar1_endpt_intersect = scar1.get_edge_intersections(collision.polygon[endpt_idx], collision.polygon[next_endpt_idx])
					if scar1_endpt_intersect != null:
						if scar1_endpt_intersect[-1] != "start":
							break_path = scar1.line.points
							scar1_edge_segments = break_path
							break
	# see if we found any break path
	if !break_path:
		for scar in scars.get_children():
			scar.queue_free()
		return
	if scar1 and scar1_edge_segments:
		scar1.remove_line_segments(scar1_edge_segments, false)
	if scar2 and scar2_edge_segments:
		scar2.remove_line_segments(scar2_edge_segments, false)
	
	# expand our break path
	shattering_in_progress = [shatter_width, should_shatter_slow]
	var break_poly = MyGeom.inflate_polyline(break_path, shatter_size)
	# intersect our break path with our existing polygon
	var clipped_polygons = Geometry2D.clip_polygons(collision.polygon, break_poly)
	for poly in clipped_polygons:
		# check that each result polygon is clockwise, reverse it if not
		if !Geometry2D.is_polygon_clockwise(poly):
			poly.reverse()
	# if no polygons were found, destroy this obj - it got divided into dust
	if clipped_polygons == null or clipped_polygons.size() == 0:
		queue_free()
		return
	add_break_underlay(break_path, clipped_polygons[0])
	# create a new item out of all but the first polygon we found
	for i in range(1, clipped_polygons.size()):
		if should_shatter_slow and randf() < 0.5:
			await get_tree().process_frame
		var new_item = await clone(clipped_polygons[i])
		new_item.refresh_polygon()
		#new_item.apply_central_impulse(Vector2.ONE.rotated(deg_to_rad(randf_range(0, 360))) * 260)
	# replace our current collision polygon with the first polygon we found
	collision.polygon = clipped_polygons[0]
	refresh_polygon()

func random_scar():
	#var start_pos_idx = randi_range(0, collision.polygon.size() - 2)
	#var start_pos = collision.polygon[start_pos_idx] + randf_range(0, 1) * (collision.polygon[(start_pos_idx+1)%collision.polygon.size()] - collision.polygon[start_pos_idx])
	var start_pos = get_random_edge_point()
	var end_pos = center
	var len = start_pos.distance_to(end_pos) * 2
	#scar.generate_scar(collision.polygon, start_pos, randf_range(len/2, len*2), start_angle, 0, 1.0, 1.0)
	specific_scar(start_pos, end_pos + Vector2.ONE.rotated(deg_to_rad(randf_range(0, 360))) * randf_range(len/6, len/5), PI/6, 0.1, 0.2)

func specific_scar(start_pos:Vector2, end_pos:Vector2, max_deviation:float=0, min_segment_len:float=1.0, max_segment_len:float=1.0):
	var start_angle = start_pos.angle_to_point(end_pos)
	var scar:ItemScar = preload("res://pottery/ItemScar.tscn").instantiate()
	#print("start=", start_pos, ", end=", end_pos, ", angle=", start_angle)
	scar.generate_scar(collision.polygon, start_pos, (end_pos-start_pos).length(), start_angle, max_deviation, min_segment_len, max_segment_len)
	add_scar(scar)

func _calculate_area(polygon) -> float:
	var triangles = Geometry2D.triangulate_polygon(polygon)
	if triangles.size() == 0:
		polygon = Geometry2D.convex_hull(polygon)
		triangles = Geometry2D.triangulate_polygon(polygon)
	var twiceArea = 0
	for i in range(0, triangles.size(), 3):
		var t1 = triangles[i]
		var t2 = triangles[i+1]
		var t3 = triangles[i+2]
		twiceArea += abs(polygon[t1].x * (polygon[t2].y - polygon[t3].y) + polygon[t2].x * (polygon[t3].y - polygon[t1].y) + polygon[t3].x * (polygon[t1].y - polygon[t2].y))
	return twiceArea / 2


func _find_center() -> Vector2:
	var centers:Array[Vector2] = []
	var areas:Array[float] = []
	var new_top_left := Vector2(999999, 999999)
	var new_bot_right := Vector2(-999999, -999999)
	for collision in collision_polygons:
		var origin = collision.position
		var twiceArea:float = 0
		var off:Vector2 = collision.polygon[0].rotated(collision.rotation) + origin
		var x:float = 0
		var y:float = 0
		var p1:Vector2
		var p2:Vector2
		var f
		var j = collision.polygon.size() - 1
		for i in range(collision.polygon.size()):
			p1 = collision.polygon[i].rotated(collision.rotation) + origin
			p2 = collision.polygon[j].rotated(collision.rotation) + origin
			if p1.x < new_top_left.x: new_top_left.x = p1.x
			if p1.y < new_top_left.y: new_top_left.y = p1.y
			if p1.x > new_bot_right.x: new_bot_right.x = p1.x
			if p1.y > new_bot_right.y: new_bot_right.y = p1.y
			f = (p1.x - off.x) * (p2.y - off.y) - (p2.x - off.x) * (p1.y - off.y)
			twiceArea += f
			x += (p1.x + p2.x - 2*off.x) * f
			y += (p2.y + p2.y - 2*off.y) * f
			j = i
		f = twiceArea * 3
		centers.append(Vector2(x/f+off.x, y/f+off.y))
		areas.append(abs(twiceArea/2))
	if centers.size() == 0:
		print("Item with no collision polygons? Freeing")
		queue_free()
	var totalArea = 0
	center = Vector2.ZERO
	for a in areas:
		totalArea += a
	for i in range(centers.size()):
		center += centers[i] * (areas[i] / totalArea)
	bounding_box = Rect2(new_top_left, new_bot_right-new_top_left)
	# TODO: Uncomment if painting returns
	#new_top_left -= Vector2(20, 20)
	#new_bot_right += Vector2(20, 20)
	#print("Center of ", name, " with ", collision.polygon.size(), " points: ", center)
	#if new_top_left != $Paint/PaintPoly.position or new_bot_right != $Paint/PaintPoly.polygon[2]:
	#	$Paint/PaintPoly.resize(new_top_left, new_bot_right)
	center_of_mass = center
	return center

func add_break_underlay(break_path, clip_polygon, offset=1):
	break_path = Geometry2D.clip_polyline_with_polygon(break_path, Geometry2D.offset_polygon(clip_polygon, offset))
	for path_part in break_path:
		var edge = load("res://pottery/ItemShardEdge.tscn").instantiate()
		var line = load("res://pottery/ItemShardEdgeLine.tscn").instantiate()
		if path_part.size() == 2:
			#print("Zero width path found")
			var new_pt = path_part[0] - (path_part[0] - path_part[1])/2
			path_part.insert(1, new_pt)
		line.points = path_part
		edge.add_child(line)
		shard_edges.add_child(edge)
		
func add_unconditional_underlay(break_path):
	var edge = load("res://pottery/ItemShardEdge.tscn").instantiate()
	var line = load("res://pottery/ItemShardEdgeLine.tscn").instantiate()
	if break_path.size() == 2:
		#print("Zero width path found")
		var new_pt = break_path[0] - (break_path[0] - break_path[1])/2
		break_path.insert(1, new_pt)
	MyGeom.shorten_path(break_path, -shatter_size)
	if !Geometry2D.is_point_in_polygon(break_path[0], original_boundary_polygon):
		break_path[0] = break_path[0] + (break_path[1] - break_path[0]).normalized() * (2.5+shatter_size)
	if !Geometry2D.is_point_in_polygon(break_path[-1], original_boundary_polygon):
		break_path[-1] = break_path[-1] + (break_path[-2] - break_path[-1]).normalized() * (2.5+shatter_size)
	line.points = break_path
	edge.add_child(line)
	shard_edges.add_child(edge)

func glue(other:ArcheologyItem):
	for child in other.get_children():
		if child is ItemPolygon2D or child is CollisionPolygon2D:
			var child_pos = child.global_position
			var child_rot = child.global_rotation
			other.remove_child(child)
			add_child(child)
			child.global_position = child_pos
			child.global_rotation = child_rot
		elif child.name == "ShardEdges":
			for edge in child.get_children():
				var edge_pos = edge.global_position
				var edge_rot = edge.global_rotation
				child.remove_child(edge)
				shard_edges.add_child(edge)
				edge.global_position = edge_pos
				edge.global_rotation = edge_rot
		elif child.name == "Scars":
			for scar in child.get_children():
				var scar_pos = scar.global_position
				var scar_rot = scar.global_rotation
				child.remove_child(scar)
				scars.add_child(scar)
				scar.global_position = scar_pos
				scar.global_rotation = scar_rot
		elif child.name == "Glue":
			for g in child.get_children():
				var pos = g.global_position
				var rot = g.global_rotation
				child.remove_child(g)
				glue_edges.add_child(g)
				g.global_position = pos
				g.global_rotation = rot
				glue_hashes[g.find_child("Polygon2D").polygon.hash()] = g
	visual_polygons = []
	collision_polygons = []
	area = 0
	center = null
	center_of_mass = center
	other.queue_free()

# Build glue polygons by finding scars and recoloring them?
func build_glue_polygons(circle_center_global:Vector2, circle_radius:float):
	for edge in shard_edges.get_children():
		var intersecting_edges = edge.get_intersecting_edge_lines(circle_center_global, circle_radius)
		for line in intersecting_edges:
			ItemShardEdge.convert_to_glue(line, Color.GOLD)

## Build glue polygons based on the segments near the circle - doesn't work very well
#func build_glue_polygons(circle_center_global:Vector2, circle_radius:float):
	#var segments = []
	#for poly in collision_polygons:
		#var seg = get_segment_intersecting_circle(circle_center_global - poly.global_position, circle_radius, poly.polygon, poly.position)
		#if seg.size() > 0:
			#segments.append(seg)
	#for i in range(segments.size()):
		#var seg1 = segments[i]
		#for j in range(i+1, segments.size()):
			#var seg2 = segments[j]
			#var glue_poly = []
			#glue_poly.append_array(seg1)
			#glue_poly.append_array(seg2)
			#if !Geometry2D.is_polygon_clockwise(glue_poly):
				#glue_poly.reverse()
			#print("Got glue polygon: ", glue_poly)
			#if glue_hashes.has(glue_poly.hash()):
				#continue # polygon already exists (probably...could check the actual values in case of hash collision, but prob not worth it)
			#print("Creating new glue and adding it")
			#var new_glue = load("res://pottery/ItemGlueEdge.tscn").instantiate()
			#new_glue.setup(glue_poly)
			#$Glue.add_child(new_glue)
			#glue_hashes[glue_poly.hash()] = new_glue
			
func get_segment_intersecting_circle(circle_center:Vector2, circle_radius:float, polygon, polygon_offset:Vector2) -> Array[Vector2]:
	var cur_segment:Array[Vector2] = []
	for i in range(polygon.size()):
		var pt1 = polygon[i - 1]
		var pt2 = polygon[i]
		if Geometry2D.segment_intersects_circle(pt1, pt2, circle_center, circle_radius) != -1:
			if cur_segment.size() == 0:
				cur_segment.append(pt1 + polygon_offset)
			cur_segment.append(pt2 + polygon_offset)
		#else:
			#if cur_segment.size() > 0:
				#segment_list.append(cur_segment)
				#cur_segment = []
	return cur_segment

func recalculate_structure_completion():
	var result = {}
	var avg_displacements = 0
	var num_polygons = 0
	var total_area = 0
	for child in get_children():
		if child is ItemPolygon2D:
			var total_displacement = 0
			var num_pts = 0
			var cur_area = _calculate_area(child.polygon)
			total_area += cur_area
			for pt in child.polygon:
				var actual_pt = child.to_global(pt)
				var expected_pt = self.to_global(pt)
				total_displacement += abs(expected_pt.distance_to(actual_pt))
				num_pts += 1
			if num_pts > 0:
				avg_displacements += total_displacement/num_pts * cur_area
				num_polygons += 1
	$StructurePct.text = "avg displace: "+str(snapped(avg_displacements/num_polygons/total_area, 0.01))+"\ncomplete: "+str(snapped(area_pct*100, 0.1))+"%"
	result['displace'] = avg_displacements/num_polygons/total_area

func _on_timer_timeout():
	recalculate_structure_completion()

func safe_freeze(val:bool):
	freeze = val
	var cur_mode = PhysicsServer2D.body_get_mode(get_rid())
	if !val:
		if cur_mode != PhysicsServer2D.BodyMode.BODY_MODE_RIGID_LINEAR and cur_mode != PhysicsServer2D.BodyMode.BODY_MODE_RIGID:
			set_deferred("freeze", val)
	elif cur_mode != PhysicsServer2D.BodyMode.BODY_MODE_STATIC: 
			set_deferred("freeze", val)

func save_to_gallery():
	Global.save_to_gallery.emit(self)

func adjust_scale(scale_change:float):
	for child in get_children():
		if child is Polygon2D or child is CollisionPolygon2D:
			child.position *= scale_change
			if "uv" in child:
				child.uv = PackedVector2Array(child.polygon)
			child.polygon = _adjust_polygon_scale(child.polygon, scale_change)
	for child in $Scars.get_children():
		child.position *= scale_change
		child.adjust_scale(scale_change)
	for child in $ShardEdges.get_children():
		child.position *= scale_change
		child.adjust_scale(scale_change)
	center = null
	_find_center()

func _adjust_polygon_scale(polygon, scale_change:float):
	for i in range(polygon.size()):
		polygon[i] = polygon[i] * scale_change
	return polygon
