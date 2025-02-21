extends RigidBody2D
class_name ArcheologyItem

const TOO_SMALL_POLYGON_AREA := 35
const TOO_SMALL_POLYGON_EDGE_RATIO := 0.9
const DRAG_SPEED := 15
const MAX_LINEAR_VELOCITY := 5000.0
const MAX_ANGULAR_VELOCITY := 10.0
const FLASH_COLOR = Color(3, 3, 3, 1.0) #Color(1.0*5, 0.9*5, 0.05*5, 1.0)

enum Fields {
	IMG_DATA, POSITION, ROTATION, POLYGON, ORIG_AREA, SHATTER_SIZE, ORIG_PIECE_COUNT, 
	ORIG_ITEM_COUNT, TIME_ATTACK_SECONDS, FINAL_SCORE, BUMP_ENABLED, ROTATE_ENABLED,
	DISPLACEMENT_SCORE, SAVE_DATE, GAME_MODE, ADJUSTED_SCALE
}

# if -1, the mouse is not hovering over this piece
var hover_idx = -1
# If null, the user is not dragging this piece
var drag_start_mouse = null
var drag_start_item = null
var target_pos = null
# if null, the user is not rotating ringthis piece
var rotate_start_mouse = null
var rotation_handle_start_mouse = null
var rotation_handle_start_screen = null
var rotate_start_item = null
var rotate_start_item_com_position = null
var indirect_rotation_x_direction:int = 1
var indirect_rotation_y_direction:int = 1
var indirect_rotation_on_x_axis := true
var rotation_pixel_delta:float = 0
var prev_rotation_pixel_delta:float = 0
var distance_travelled:Vector2 = Vector2.ZERO
var target_rot = null
var indirect_rotation_move_direction:int = 1
var reset_position = null
var reset_rotation = null
var bounding_box:Rect2
var loading:bool = false
var adjusted_scale := 1.0
var gallery_scale := 1.0
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
			mass = area
		return area

# time attack score values, not for use during normal gameplay
var original_area:float
var original_fragment_count:int
var original_item_count:int
var time_attack_seconds:int
var bump_enabled:bool
var rotate_enabled:bool
var final_displacement_score:float
var final_score:int
var save_timestamp:String
var game_mode:String
var flash_tween:Tween

var area_pct:
	get:
		if !original_area:
			refresh_polygon()
		area_pct = area / original_area
		mass = area_pct * original_area
		return area_pct

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

@onready var collision:CollisionPolygon2D = find_child("CollisionPolygon2D"):
	get:
		if collision == null:
			for child in get_children():
				if child is CollisionPolygon2D:
					collision = child
					break
		return collision
@onready var scars:Node2D = find_child("Scars")
@onready var polygon:ItemPolygon2D:
	get:
		if polygon == null:
			for child in get_children():
				if child is ItemPolygon2D:
					polygon = child
					break
		return polygon
@onready var shard_edges:Node2D = find_child("ShardEdges")
@onready var glue_edges:Node2D = find_child("Glue")
@onready var center_of_mass_indicator:Node2D = find_child("CenterOfMass")
@onready var rotation_handle_indicator:Node2D = find_child("RotationHandle")
var rotate_arrow:Node2D
var _gallery_mode = false
var gallery_id:String
var base_item_name:String
func get_save_data(image_save_data:Dictionary, weathering_save_data:Dictionary) -> Dictionary: # Dictionary[String, ItemBuilder.ImageSaveData]
	var img_save_data = []
	var scar_save_data = []
	var edge_save_data = []
	var glue_save_data = []
	save_timestamp = Time.get_datetime_string_from_system()
	for child in get_children():
		if child is ItemPolygon2D:
			var child_image_data = child.get_save_data(weathering_save_data)
			if !image_save_data.has(child_image_data):
				image_save_data[child_image_data] = ItemBuilder.get_next_unique_id()
			img_save_data.append({
				Fields.IMG_DATA: image_save_data[child_image_data],
				Fields.POSITION: child.position,
				Fields.ROTATION: child.rotation,
				Fields.POLYGON: child.polygon,
			})
	for child in scars.get_children():
		scar_save_data.append(child.get_save_data())
	for child in shard_edges.get_children():
		edge_save_data.append(child.get_save_data())
	for child in glue_edges.get_children():
		glue_save_data.append(child.get_save_data())
	var me_data = {
		Fields.POSITION: global_position,
		Fields.ROTATION: global_rotation,
		Fields.ORIG_AREA: original_area,
		Fields.ORIG_PIECE_COUNT: original_fragment_count,
		Fields.ORIG_ITEM_COUNT: original_item_count,
		Fields.TIME_ATTACK_SECONDS: time_attack_seconds,
		Fields.SHATTER_SIZE: shatter_size,
		Fields.BUMP_ENABLED: bump_enabled,
		Fields.ROTATE_ENABLED: rotate_enabled,
		Fields.DISPLACEMENT_SCORE: final_displacement_score,
		Fields.FINAL_SCORE: final_score,
		Fields.SAVE_DATE: save_timestamp,
		Fields.GAME_MODE: game_mode,
		Fields.ADJUSTED_SCALE: adjusted_scale,
	}
	return {"img":img_save_data, "scar":scar_save_data, "edge":edge_save_data, "glue":glue_save_data, "me":me_data}

## item_save = as returned from get_save_data
## image_save_data = Dictionary[int (referenced from item_save[IMG_DATA]), Array[ItemBuilder.ImageSaveData]]
## rebuilt_textures = Dictionary[int (referenced from item_save[IMG_DATA]), Texture2D]
## image_save_data values may be either an array of ImageSaveData objects, or an inverted copy of the map
## 		populated by the parameter to ArcheologyItem.get_save_data()
## weathering_save_data is an inverted copy of the map populated by the parameter to ArcheologyItem.get_save_data()
## rebuilt_textures may be passed as an empty dictionary to be populated if desired
static func load_save_data(item_save:Dictionary, image_save_data:Dictionary, weathering_save_data:Dictionary, rebuilt_textures:Dictionary) -> ArcheologyItem: 
	for k in image_save_data.keys():
		if image_save_data[k] != null and image_save_data[k].size() > 0 and !(image_save_data[k][0] is ItemBuilder.ImageSaveData):
			image_save_data[k] = image_save_data[k].map(func(v): return ItemBuilder.ImageSaveData.load_save_data(v, weathering_save_data))
		if !rebuilt_textures.has(k):
			rebuilt_textures[k] = await ItemBuilder.build_specific_item(image_save_data[k], image_save_data[k][0].weathering)
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
	var glue_data = item_save.get("glue", [])
	var me_data = item_save.get("me", {})
	result.global_position = me_data[Fields.POSITION]
	result.global_rotation = me_data[Fields.ROTATION]
	result.original_area = me_data[Fields.ORIG_AREA]
	result.original_fragment_count = me_data[Fields.ORIG_PIECE_COUNT]
	result.original_item_count = me_data[Fields.ORIG_ITEM_COUNT]
	result.time_attack_seconds = me_data[Fields.TIME_ATTACK_SECONDS]
	result.bump_enabled = me_data[Fields.BUMP_ENABLED]
	result.rotate_enabled = me_data[Fields.ROTATE_ENABLED]
	result.final_displacement_score = me_data[Fields.DISPLACEMENT_SCORE]
	result.final_score = me_data[Fields.FINAL_SCORE]
	result.game_mode = me_data[Fields.GAME_MODE]
	result.save_timestamp = me_data[Fields.SAVE_DATE]
	result.adjusted_scale = me_data.get(Fields.ADJUSTED_SCALE, 1.0)
	for data in poly_data:
		var new_polygon = ItemPolygon2D.new()
		new_polygon.visibility_layer = 3 # Visible on layers 1 (normal view) and 2 (screenshot view)
		new_polygon.save_data = image_save_data[data[Fields.IMG_DATA]]
		new_polygon.texture = rebuilt_textures[data[Fields.IMG_DATA]]
		new_polygon.position = data[Fields.POSITION]
		new_polygon.rotation = data[Fields.ROTATION]
		new_polygon.polygon = data[Fields.POLYGON]
		new_polygon.uv = ArcheologyItem._adjust_polygon_scale(new_polygon.polygon, 1.0/result.adjusted_scale)
		var new_collision = CollisionPolygon2D.new()
		new_collision.position = new_polygon.position
		new_collision.rotation = new_polygon.rotation
		new_collision.polygon = new_polygon.polygon
		result.add_child(new_polygon)
		result.add_child(new_collision)
	
	var scar_container = result.find_child("Scars")
	var edge_container = result.find_child("ShardEdges")
	var glue_container = result.find_child("Glue")
	for data in scar_data:
		var new_scar = ItemScar.load_save_data(data)
		scar_container.add_child(new_scar)
	for data in edge_data:
		var new_edge = ItemShardEdge.load_save_data(data)
		edge_container.add_child(new_edge)
	for data in glue_data:
		var new_glue = ItemGlueEdge.load_save_data(data)
		glue_container.add_child(new_glue)
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
	refresh_polygon()
	loading = false
	for child in $ShardEdges.get_children():
		child.loading = false
	apply_global_settings()

func _ready():
	Global.cleanup_all_items.connect(func():self.queue_free())
	Global.camera_zoom_changed.connect(on_camera_zoom_changed)
	if !loading:
		refresh_polygon()
	if original_area == null:
		original_area = area
	center_of_mass_indicator.polygon = MyGeom.circle_polygon(Vector2.ZERO, Global.center_of_mass_indicator_size, 16)
	rotation_handle_indicator.polygon = MyGeom.circle_polygon(Vector2.ZERO, Global.center_of_mass_indicator_size*.75, 8)
	apply_global_settings()
	Global.click_mode_changed.connect(func():
		if Global.click_mode == Global.ClickMode.move:
			stop_dragging()
	)

func on_camera_zoom_changed(cur_zoom:float)->void:
	cur_zoom = 1.0/cur_zoom
	var cur_scale = Vector2(cur_zoom, cur_zoom)
	center_of_mass_indicator.scale = cur_scale
	rotation_handle_indicator.scale = cur_scale
	if rotate_arrow:
		rotate_arrow.scale = cur_scale

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
		modulate = Color.WHITE
	else:
		collision_mask &= ~1 # prevent this piece from colliding with elements on layer 1
		modulate = Color(0.8, 0.8, 0.8)

func clone(new_polygon:Array, should_clone_slow=false):
	## TODO: Make this handle cloning glued items
	var new_scene = preload("res://pottery/ArcheologyItem.tscn").instantiate()
	var new_visual_polygon = new_scene.find_child("Polygon2D")
	new_visual_polygon.texture = visual_polygons[0].texture
	new_scene.original_area = original_area
	new_scene.original_fragment_count = original_fragment_count
	new_scene.original_item_count = original_item_count
	new_scene.time_attack_seconds = time_attack_seconds
	new_scene.bump_enabled = bump_enabled
	new_scene.rotate_enabled = rotate_enabled
	new_scene.final_displacement_score = final_displacement_score
	new_scene.final_score = final_score
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
	new_scene.save_timestamp = save_timestamp
	new_scene.game_mode = game_mode
	new_scene.adjusted_scale = adjusted_scale
	new_scene.base_item_name = base_item_name
	if should_clone_slow:
		await wait_frame()
	#for scar in scars.get_children():
	#	var new_scar = scar.clone()
	#	new_scene.scars.add_child(new_scar)
	if should_clone_slow:
		await wait_frame()
	for edge in shard_edges.get_children():
		var new_edge = edge.clone()
		new_scene.shard_edges.add_child(new_edge)
	new_scene.shattering_in_progress = shattering_in_progress
	new_visual_polygon.save_data = polygon.save_data
	#await get_tree().physics_frame
	return new_scene

func wait_frame():
	if get_tree() != null:
		await get_tree().process_frame

func refresh_polygon() -> int:
	center = null
	area = 0
	if collision.polygon.size() > 0 and collision.polygon[0].distance_to(collision.polygon[-1]) < 0.5:
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
	#if polygon.uv.size() != collision.polygon.size():
		#polygon.uv = collision.polygon
	#print("About to refresh polygon uv to scale ", adjusted_scale, ": ", polygon.uv)
	polygon.uv = ArcheologyItem._adjust_polygon_scale(collision.polygon, 1.0/adjusted_scale)
	#print("After: ", polygon.uv)
	var scar_trim_poly = Geometry2D.offset_polygon(collision.polygon, shatter_size+0.1)
	for scar in scars.get_children():
		scar.refresh_scar_path(collision.polygon)
	var material_trim_polys = []
	var material_zones = []
	if base_item_name != null:
		material_zones = ItemBuilder.base_item_material_zones.get(base_item_name, [])
		for material_data in material_zones: # Dict like {MaterialPolygon.MATERIAL: MaterialPolygon.MaterialType.metal, MaterialPolygon.POLYGON: (polygon points)}
			material_trim_polys.append(material_data.get(MaterialPolygon.POLYGON, []))
	for edge in shard_edges.get_children():
		if scar_trim_poly.size() > 0:
			edge.refresh_edge_path(scar_trim_poly[0])
		for trim_poly in material_trim_polys:
			edge.refresh_edge_path(trim_poly, true)
	
	for edge in shard_edges.get_children():
		edge.set_edge_colors(material_zones)

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
				start_dragging()
				get_viewport().set_input_as_handled()
			if event.is_action_pressed("break_item"):
				random_scar()
			if event.is_action_pressed("rotate_start"):
				if Global.awaiting_first_click:
					Global.awaiting_first_click = false
					Global.first_click_received.emit()
				rotate_start_mouse = to_global(center_of_mass).angle_to_point(get_global_mouse_position())
				rotate_start_item = global_rotation
				rotate_start_item_com_position = to_global(center_of_mass)
				center_of_mass_indicator.visible = true
				rotation_handle_indicator.visible = Global.rotation_mode_direct
				rotation_handle_start_mouse = get_global_mouse_position()
				rotation_handle_indicator.position = to_local(rotation_handle_start_mouse)
				if !Global.rotation_mode_direct:
					distance_travelled = Vector2.ZERO
					rotation_handle_start_mouse = get_global_mouse_position()
					rotation_handle_start_screen = get_viewport().get_mouse_position()
					indirect_rotation_x_direction = 1 if rotation_handle_start_mouse.y < rotate_start_item_com_position.y else -1
					indirect_rotation_y_direction = -1 if rotation_handle_start_mouse.x < rotate_start_item_com_position.x else 1
					var offset = rotation_handle_start_mouse - rotate_start_item_com_position
					indirect_rotation_on_x_axis = abs(offset.y) > abs(offset.x)
					if indirect_rotation_on_x_axis:
						rotate_arrow = get_tree().get_first_node_in_group("RotateArrow")
						rotate_arrow.rotation_degrees = 0 if rotation_handle_start_mouse.y < rotate_start_item_com_position.y else 180
						rotate_arrow.visible = true
						Input.mouse_mode = Input.MOUSE_MODE_HIDDEN
						update_rotation_arrow_placement()
					else:
						rotate_arrow = get_tree().get_first_node_in_group("RotateArrow")
						rotate_arrow.rotation_degrees = -90 if rotation_handle_start_mouse.x < rotate_start_item_com_position.x else 90
						rotate_arrow.visible = true
						Input.mouse_mode = Input.MOUSE_MODE_HIDDEN
						update_rotation_arrow_placement()
					print("Directions: %d, %d" % [indirect_rotation_x_direction, indirect_rotation_y_direction])
					rotation_pixel_delta = 0
				lock_rotation = false
				safe_freeze(false)
				#print("Mouse at ", get_global_mouse_position(), ", COM at ", to_global(center_of_mass))
				#print("Starting rotate, initial rotation=", rad_to_deg(global_rotation), ", mouse start angle=", rad_to_deg(rotate_start_mouse))
		if drag_start_mouse != null and event.is_action_released("drag_start"):
			stop_dragging()
			#print("Ending drag")
		elif rotate_start_mouse != null and event.is_action_released("rotate_start"):
			Input.set_default_cursor_shape(Input.CURSOR_ARROW)
			rotate_start_mouse = null
			rotate_start_item = null
			target_rot = null
			if hover_idx == -1:
				_on_mouse_shape_exited(-1)
				center_of_mass_indicator.visible = false
			else:
				center_of_mass_indicator.visible = !Global.lock_rotation 
			rotation_handle_indicator.visible = false
			if rotate_arrow:
				rotate_arrow.visible = false
				rotate_arrow = null
			Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
			lock_rotation = Global.lock_rotation
			safe_freeze(Global.freeze_pieces)
			#print("Stopping rotate")
	elif drag_start_mouse != null and event is InputEventMouseMotion:
		target_pos = get_global_mouse_position()
		Global.tutorial_moved_item.emit(self)
	elif rotate_start_mouse != null and event is InputEventMouseMotion:
		target_rot = 0.1 # just something to get the _integrate_forces method started
		Global.tutorial_rotated_item.emit(self)
	elif hover_idx >= 0 and event.is_action_pressed("delete_item"):
		if Global.game_mode == "gallery":
			Global.delete_archeology_item.emit(self)
			queue_free()
	if rotate_arrow != null and rotate_arrow.visible: update_rotation_arrow_placement()

func update_rotation_arrow_placement()->void:
	if rotate_arrow == null or rotate_arrow.visible == false:
		return
	rotate_arrow.position = to_global(center_of_mass)

func start_dragging():
	if Global.awaiting_first_click:
		Global.awaiting_first_click = false
		Global.first_click_received.emit()
	#print("Starting drag")
	drag_start_mouse = get_global_mouse_position()
	drag_start_item = global_position
	lock_rotation = true
	safe_freeze(false)
	get_parent().move_child(self, -1)
	if _gallery_mode:
		for i in range(get_parent().get_child_count()):
			get_parent().get_child(i).z_index = i * 5
	Global.started_dragging_item.emit(self)

func stop_dragging():
	drag_start_mouse = null
	drag_start_item = null
	target_pos = null
	if hover_idx == -1:
		_on_mouse_shape_exited(-1)
	lock_rotation = Global.lock_rotation
	safe_freeze(Global.freeze_pieces)
	Global.stopped_dragging_item.emit(self)

func reset_indirect_rotation_move_direction():
	target_rot = 0
	distance_travelled = Vector2.ZERO
	rotate_start_item = global_rotation
	rotation_handle_start_mouse = get_global_mouse_position()
	rotation_pixel_delta = 0
	prev_rotation_pixel_delta = 0
	angular_velocity = 0

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
		var desired_motion = (drag_start_item - global_position + target_pos - drag_start_mouse)
		state.linear_velocity = desired_motion * DRAG_SPEED
		if state.linear_velocity.length() > MAX_LINEAR_VELOCITY:
			state.linear_velocity = state.linear_velocity.normalized() * MAX_LINEAR_VELOCITY
	if target_rot != null:
		if Global.rotation_mode_direct:
			# Direct rotation - tries to make a straight line between center of item, rotation handle, and mouse pointer
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
				target_rot -= 2*PI
			while target_rot < -PI:
				target_rot += 2*PI
			angular_velocity = target_rot * 15
			if angular_velocity > MAX_ANGULAR_VELOCITY: angular_velocity = MAX_ANGULAR_VELOCITY
			elif angular_velocity < -MAX_ANGULAR_VELOCITY: angular_velocity = -MAX_ANGULAR_VELOCITY
		else:
			# Indirect rotation - 
			var item_center := to_global(center_of_mass)
			var mouse_cursor := get_global_mouse_position()
			distance_travelled += (get_viewport().get_mouse_position() - rotation_handle_start_screen)
			Input.warp_mouse(rotation_handle_start_screen)
			if indirect_rotation_on_x_axis:
				rotation_pixel_delta = distance_travelled.x * indirect_rotation_x_direction
			else:
				rotation_pixel_delta = distance_travelled.y * indirect_rotation_y_direction
			print("\nRotation pixel delta: ", rotation_pixel_delta)
			var distance_to_rotate_from_original:float = rotation_pixel_delta * Global.rotation_pixels_to_radians
			print("distance_to_rotate_from_original: ", distance_to_rotate_from_original)
			target_rot = distance_to_rotate_from_original + rotate_start_item
			print("target_rot1: ", target_rot)
			if abs(rotation_pixel_delta-prev_rotation_pixel_delta) > 0.0000001:
				var new_move_direction = sign(rotation_pixel_delta-prev_rotation_pixel_delta)
				if indirect_rotation_move_direction != 0 and new_move_direction != 0 and new_move_direction != indirect_rotation_move_direction:
					# We reversed course, reset the rotation
					indirect_rotation_move_direction = new_move_direction
					reset_indirect_rotation_move_direction()
					return
				indirect_rotation_move_direction = new_move_direction
				prev_rotation_pixel_delta = rotation_pixel_delta
			print("indirect_rotation_move_direction: ", indirect_rotation_move_direction)
			# keep target_rot between -360 and +360
			#target_rot = fmod(target_rot, 2*PI)
			# keep global_rotation between -360 and +360
			#while global_rotation > 2*PI:
			#	global_rotation -= 2*PI
			#while global_rotation < -2*PI:
			#	global_rotation += 2*PI
			#if target_rot > 0 and global_rotation < 0:
				#target_rot -= 2*PI
			#elif target_rot < 0 and global_rotation > 0:
				#target_rot += 2*PI
			#if indirect_rotation_move_direction > 0:
				#while target_rot < global_rotation:
					#target_rot += 2*PI
				#while target_rot > global_rotation+2*PI:
					#target_rot -= 2*PI
			#if indirect_rotation_move_direction < 0:
				#while target_rot > global_rotation:
					#target_rot -= 2*PI
					#print("Reduced target_rot")
				#while target_rot < global_rotation-2*PI:
					#target_rot += 2*PI
			target_rot = fmod(target_rot, 2*PI)
			if abs(target_rot - global_rotation) > PI:
				if target_rot > global_rotation:
					target_rot -= 2*PI
				else:
					target_rot += 2*PI
			print("target_rot2: ", target_rot)
			var rotation_left = target_rot - global_rotation
			print("cur rotation: ", global_rotation)
			print("rotation_left: ", rotation_left)
			if abs(rotation_left) > 0.0001:
				angular_velocity = abs(rotation_left)*indirect_rotation_move_direction*10
				print("Setting angular velocity: ", angular_velocity)
			else:
				angular_velocity = 0
			if angular_velocity > MAX_ANGULAR_VELOCITY: angular_velocity = MAX_ANGULAR_VELOCITY
			elif angular_velocity < -MAX_ANGULAR_VELOCITY: angular_velocity = -MAX_ANGULAR_VELOCITY
		#print("av=", angular_velocity)

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
		if drag_start_item == null and rotate_start_item == null:
			if Global.click_mode == Global.ClickMode.move or Global.click_mode == Global.ClickMode.save_item:
				unhighlight_visual_polygons()
		#print("Left hover ", shape_idx)
		hover_idx = -1

func highlight_visual_polygons():
	for poly in visual_polygons:
		poly.modulate = Color(1.3, 1.3, 1.3, 1.3)
	center_of_mass_indicator.position = center_of_mass
	center_of_mass_indicator.visible = !Global.lock_rotation or (rotate_start_item != null)
	Global.item_highlighted.emit(self)

func unhighlight_visual_polygons():
	for poly in visual_polygons:
		poly.modulate = Color.WHITE
	center_of_mass_indicator.visible = false
	Global.item_unhighlighted.emit(self)

func add_scar(scar:ItemScar):
	scar.refresh_scar_path(collision.polygon)
	if scars != null and is_instance_valid(scars):
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
			await wait_frame()
		for collision_polygon in collision_polygon_list:
			# intersect our break path with our existing polygon
			var clipped_polygons = Geometry2D.clip_polygons(collision_polygon, scar_poly)
			if clipped_polygons.size() != 1:
				new_collision_polygons.append_array(clipped_polygons)
			elif clipped_polygons.size() == 1 :
				new_collision_polygons.append(clipped_polygons[0])
		collision_polygon_list = new_collision_polygons
		new_collision_polygons = []
	
	var total_size = 0
	collision_polygon_list = collision_polygon_list.map(func(poly):
		poly = MyGeom.cleanup_self_intersections(poly)
		poly = MyGeom.cleanup_close_points(poly)
		return poly
	)
	for poly in collision_polygon_list:
		total_size += _calculate_area(poly)
	print("After shattering, original area changed by ", (1.0 - total_size / original_area)*100, "% (", original_area, " -> ", total_size, ")")
	original_area = total_size
	original_fragment_count = collision_polygon_list.size()
	for i in range(0, collision_polygon_list.size()):
		if should_shatter_slow and get_tree() != null:
			await wait_frame()
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

func create_scars_from_paths(scar_paths:Array[PackedVector2Array]):
	for path in scar_paths:
		if path.size() >= 2:
			#print("Adding scar")
			var scar:ItemScar = ItemScar.create_scar_from_path(path)
			add_scar(scar)
		else:
			pass
			print("Skipping zero-length scar")
		
func _calculate_area(poly) -> float:
	var triangles = Geometry2D.triangulate_polygon(poly)
	if triangles.size() == 0:
		poly = Geometry2D.convex_hull(poly)
		triangles = Geometry2D.triangulate_polygon(poly)
	var twiceArea = 0
	for i in range(0, triangles.size(), 3):
		var t1 = triangles[i]
		var t2 = triangles[i+1]
		var t3 = triangles[i+2]
		twiceArea += abs(poly[t1].x * (poly[t2].y - poly[t3].y) + poly[t2].x * (poly[t3].y - poly[t1].y) + poly[t3].x * (poly[t1].y - poly[t2].y))
	return twiceArea / 2


func _find_center() -> Vector2:
	var centers:Array[Vector2] = []
	var areas:Array[float] = []
	var new_top_left := Vector2(999999, 999999)
	var new_bot_right := Vector2(-999999, -999999)
	for col in collision_polygons:
		var origin = col.position
		var twiceArea:float = 0
		var off:Vector2 = col.polygon[0].rotated(col.rotation) + origin
		var x:float = 0
		var y:float = 0
		var p1:Vector2
		var p2:Vector2
		var f
		var j = col.polygon.size() - 1
		for i in range(col.polygon.size()):
			p1 = col.polygon[i].rotated(col.rotation) + origin
			p2 = col.polygon[j].rotated(col.rotation) + origin
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
		# retreat by 5px in both directions
		path_part[0] = path_part[0] + (path_part[1] - path_part[0]).normalized() * 5
		path_part[-1] = path_part[-1] + (path_part[-2] - path_part[-1]).normalized() * 5
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
				#var pos = g.global_position
				#var rot = g.global_rotation
				var global_poly = MyGeom.global_polygon(g)
				child.remove_child(g)
				glue_edges.add_child(g)
				#g.global_position = pos
				#g.global_rotation = rot
				g.rotation = 0
				g.position = Vector2.ZERO
				g.polygon = MyGeom.local_polygon(self, global_poly)
			glue_edges.refresh_polygons()
	visual_polygons = []
	collision_polygons = []
	area = 0
	center = null
	center_of_mass = center
	other.queue_free()

func _global_bounding_box(node:ItemPolygon2D) -> Rect2:
	var bbox = node.bounding_box
	var top_left = node.to_global(bbox.position)
	var top_right = node.to_global(bbox.position + Vector2(bbox.size.x, 0))
	var bot_right = node.to_global(bbox.end)
	var bot_left = node.to_global(bbox.position + Vector2(0, bbox.size.y))
	var x1:float = min(top_left.x, bot_right.x, top_right.x, bot_left.x)
	var y1:float = min(top_left.y, bot_right.y, top_right.y, bot_left.y)
	var x2:float = max(top_left.x, bot_right.x, top_right.x, bot_left.x)
	var y2:float = max(top_left.y, bot_right.y, top_right.y, bot_left.y)
	return Rect2(x1, y1, x2-x1, y2-y1)
	

# Find edges intersecting the circle, collect all their points, build a convex hull from them
# Encourage careful gluing, otherwise you'll get artifacts :(
# Consider only finding the closest edge from each piece to the center?
func build_glue_polygons(circle_center_global:Vector2, circle_radius:float):
	var affected_area:Rect2 = Rect2(circle_center_global - Vector2(circle_radius, circle_radius), Vector2(circle_radius*2, circle_radius*2))
	# Get list of visual polygons that might intersect with the circle based on their bounding boxes
	var possible_polygon_overlaps := visual_polygons.filter(func(poly): 
		var poly_box = _global_bounding_box(poly)
		#print("Checking whether ", poly_box, " intersects with ", affected_area, ": ", affected_area.intersects(_global_bounding_box(poly)))
		return affected_area.intersects(poly_box)
	)
	# Get list of intersection points along the edges of these polygons
	var intersection_pts:Array[Vector2] = []
	for poly:ItemPolygon2D in possible_polygon_overlaps:
		var pt1 = poly.to_global(poly.polygon[-1])
		for local_pt2 in poly.polygon:
			var pt2 := poly.to_global(local_pt2)
			var intersect1:float = Geometry2D.segment_intersects_circle(pt1, pt2, circle_center_global, circle_radius)
			if intersect1 >= 0:
				intersection_pts.append(self.to_local(pt1 + (pt2-pt1)*intersect1))
				var intersect2:float = Geometry2D.segment_intersects_circle(pt2, pt1, circle_center_global, circle_radius)
				# if it intersects once, it might intersect twice - check from both ends, but ignore duplicates
				if intersect2 >= 0 and (1-(intersect1 + intersect2) > 0.000001):
					intersection_pts.append(self.to_local(pt2 + (pt1-pt2)*intersect2))
			if Geometry2D.is_point_in_circle(pt2, circle_center_global, circle_radius):
				intersection_pts.append(self.to_local(pt2))
			pt1 = pt2
	# Now that we have all the affected points, build a convex hull around them
	# Hopefully this doesn't stick out in weird ways in thin concave sections
	if intersection_pts.size() >= 3:
		var new_glue_poly = MyGeom.build_convex_polygon(intersection_pts)
		var new_glue_obj = preload("res://pottery/ItemGlueEdge.tscn").instantiate()
		new_glue_obj.setup(new_glue_poly, Global.glue_material)
		glue_edges.add_child(new_glue_obj)
		glue_edges.refresh_polygons()
	
		
# Build glue polygons by finding scars and recoloring them?
#func build_glue_polygons2(circle_center_global:Vector2, circle_radius:float):
	#for edge in shard_edges.get_children():
		#var intersecting_edges = edge.get_intersecting_edge_lines(circle_center_global, circle_radius)
		#for line in intersecting_edges:
			#ItemShardEdge.convert_to_glue(line, Color.GOLD)

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
			
func get_segment_intersecting_circle(circle_center:Vector2, circle_radius:float, poly, polygon_offset:Vector2) -> Array[Vector2]:
	var cur_segment:Array[Vector2] = []
	for i in range(poly.size()):
		var pt1 = poly[i - 1]
		var pt2 = poly[i]
		if Geometry2D.segment_intersects_circle(pt1, pt2, circle_center, circle_radius) != -1:
			if cur_segment.size() == 0:
				cur_segment.append(pt1 + polygon_offset)
			cur_segment.append(pt2 + polygon_offset)
		#else:
			#if cur_segment.size() > 0:
				#segment_list.append(cur_segment)
				#cur_segment = []
	return cur_segment

## Sorts visual polygons in order of descending size, then adjusts the offset of everything and the
## actual object position to be based on the location of the largest item. This prevents displacement
## score from being thrown off by considering a tiny fragment that's wildly out of place from being the
## true origin of the object
func find_largest_polygon():
	if visual_polygons.size() < 2:
		return visual_polygons[0] # nothing to do if we only have 1 polygon (or less)
	var largest_polygon := visual_polygons[0]
	var largest_size := _calculate_area(largest_polygon.polygon)
	for i in range(1, visual_polygons.size()):
		var cur_polygon := visual_polygons[i]
		var cur_size := _calculate_area(cur_polygon.polygon)
		if cur_size > largest_size:
			largest_polygon = cur_polygon
			largest_size = cur_size
	return largest_polygon

func get_displacement_score():
	var avg_displacements = 0
	var num_polygons = 0
	var total_area = 0
	var largest_polygon = find_largest_polygon()
	for child in get_children():
		if child is ItemPolygon2D:
			var total_displacement = 0
			var num_pts = 0
			var cur_area = _calculate_area(child.polygon)
			total_area += cur_area
			for pt in child.polygon:
				var actual_pt = child.to_global(pt)
				var expected_pt = largest_polygon.to_global(pt)
				total_displacement += abs(expected_pt.distance_to(actual_pt))
				num_pts += 1
			if num_pts > 0:
				avg_displacements += total_displacement/num_pts * cur_area
				num_polygons += 1
	$StructurePct.text = "avg displace: "+str(snapped(avg_displacements/num_polygons/total_area, 0.01))+"\ncomplete: "+str(snapped(area_pct*100, 0.1))+"%"
	return avg_displacements/num_polygons/total_area

func safe_freeze(val:bool):
	freeze = val
	var cur_mode = PhysicsServer2D.body_get_mode(get_rid())
	if !val:
		if cur_mode != PhysicsServer2D.BodyMode.BODY_MODE_RIGID_LINEAR and cur_mode != PhysicsServer2D.BodyMode.BODY_MODE_RIGID:
			set_deferred("freeze", val)
	elif cur_mode != PhysicsServer2D.BodyMode.BODY_MODE_STATIC: 
			set_deferred("freeze", val)

func save_to_gallery():
	save_timestamp = Time.get_date_string_from_system()
	Global.save_to_gallery.emit(self)

func adjust_scale(scale_change:float):
	adjusted_scale = adjusted_scale*scale_change
	print("Adjusting scale to ", adjusted_scale)
	for child in get_children():
		if child is Polygon2D or child is CollisionPolygon2D:
			child.position *= scale_change
			child.polygon = ArcheologyItem._adjust_polygon_scale(child.polygon, scale_change)
			if "bounding_box" in child:
				child.bounding_box = null
			#if "uv" in child:
			#	child.uv = ArcheologyItem._adjust_polygon_scale(child.polygon, 1.0/adjusted_scale)
	for child in $Scars.get_children():
		child.position *= scale_change
		child.adjust_scale(scale_change)
	for child in $ShardEdges.get_children():
		child.position *= scale_change
		child.adjust_scale(scale_change)
	for child in $Glue.get_children():
		child.position *= scale_change
		child.adjust_scale(scale_change)
	center = null
	_find_center()

static func _adjust_polygon_scale(poly, scale_change:float):
	for i in range(poly.size()):
		poly[i] = poly[i] * scale_change
	return poly

var next_clink_time = {}
func _on_body_entered(body):
	if !body is ArcheologyItem or loading or is_display or shattering_in_progress or body.shattering_in_progress or body.loading:
		return
	if next_clink_time.get(body, 0) < Time.get_ticks_msec():
		var relative_velocity = (linear_velocity - body.linear_velocity).length() + abs(angular_velocity - body.angular_velocity) * 30
		if relative_velocity == 0:
			return
		var volume_adjustment = max(0.4, min(1.0, relative_velocity / 1500.0))
		#print(body, " and ", self, " clinking at ", Time.get_ticks_msec(), " with velocity ", relative_velocity, " and volume ", volume_adjustment)
		var other_area = body.area
		var area_ratio = min(other_area, area) / max(other_area, area)
		var pitch = 1.6 - area_ratio*1.1 + randf_range(-0.1, 0.1)
		AudioPlayerPool.play_sfx(preload("res://sfx/clink3.mp3"), pitch, volume_adjustment)
	#print(body, " and ", self, " refreshing connection at ", Time.get_ticks_msec())
	next_clink_time[body] = Time.get_ticks_msec() + 30000
	body.next_clink_time[self] = Time.get_ticks_msec() + 30000

func _on_body_exited(body):
	if !body is ArcheologyItem:
		return
	#print(body, " and ", self, " separating at ", Time.get_ticks_msec())
	next_clink_time[body] = Time.get_ticks_msec() + 300
	body.next_clink_time[self] = Time.get_ticks_msec() + 300

func glue_flash(flash_delay:float=0, flash_time:float=0.2):
	if flash_tween != null and flash_tween.is_running():
		flash_tween.stop()
	flash_tween = create_tween()
	flash_tween.tween_property(self, "modulate", FLASH_COLOR, 0.1).set_delay(flash_delay)
	flash_tween.tween_property(self, "modulate", Color.WHITE, flash_time)
