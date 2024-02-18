extends Node2D
class_name CleaningTable

const CAMERA_MOVE_SPEED := 55
const ZOOM_INCREMENT := Vector2(0.2, 0.2)

const CRACK_COUNT_SETTING := "crack_count"
const ITEM_COUNT_SETTING := "item_count"
const WEATHERING_AMT_SETTING := "weathering_amt"

@onready var camera:Camera2D = find_child("Camera2D")
@onready var screenshot_camera:Camera2D = find_child("ScreenshotCamera")
@onready var cursor_area:CursorArea = find_child("CursorArea")
@onready var sidebar_menu = find_child("SidebarMenu")
@onready var glue_brush_audio:AudioStreamPlayer = find_child("GlueBrushAudio")
@onready var control_hints:ControlHints = find_child("ControlHints")
@onready var pieces_container:Node2D = find_child("Pieces")

@export var camera_top_left_limit:Vector2 = Vector2(-100, -100)
@export var camera_bot_right_limit:Vector2 = Vector2(4500, 3300)

var camera_drag_mouse_start = null
var camera_drag_camera_start = null
var settings
var glue_cooldown:float = 0
var highlighted_items = {}
var total_items

var intro_zoom_tween:Tween

# Called when the node enters the scene tree for the first time.
func _ready():
	settings = Global.next_scene_settings
	Global.click_mode_changed.connect(update_button_text)
	Global.click_mode_changed.connect(update_glue_brush_sfx)
	Global.click_mode_changed.connect(update_control_hints)
	Global.save_to_gallery.connect(save_to_gallery)
	Global.item_highlighted.connect(func(item): highlighted_items[item] = true)
	Global.item_unhighlighted.connect(func(item): highlighted_items.erase(item))
	
	find_child("RelaxPanelCloseButton").pressed.connect(hide_relax_completion_window)
	find_child("StrugglePanelScoreButton").pressed.connect(time_attack_show_scoreboard)
	find_child("StrugglePanelExitButton").pressed.connect(func(): Global.change_scene("res://menu/main/TitleScreen.tscn"))
	
	camera.move_callback = set_camera_position
	
	glue_brush_audio.finished.connect(update_glue_brush_sfx)
		
	if settings == null:
		settings = {}
	
	var fade_rect:ColorRect = find_child("FadeRect")
	var fade_label:Label = find_child("FadeLabel")
	fade_rect.visible = true
	fade_rect.modulate.a = 1.0
	
	update_control_hints()
	await(get_tree().process_frame)
	find_child("ControlHints").slide_in(0.01)
	await(get_tree().process_frame)
	if !Global.control_hints_visible:
		find_child("ControlHints").slide_out(0.01)
	
	if settings.get("mode") == "continue":
		fade_label.text = "Restoring..."
		PhysicsServer2D.set_active(true)
		_on_load_button_pressed()
	else:
		Global.game_mode = settings.get("mode", "relax")
		PhysicsServer2D.set_active(false)
		update_button_text()
		var scene_center = (camera_bot_right_limit - camera_top_left_limit)/2 + camera_top_left_limit
		total_items = settings.get(ITEM_COUNT_SETTING, 1)
		for i in range(total_items):
			fade_label.text = "Item "+str(i+1)+" of "+str(total_items)+"\nShattering..."
			await generate_one_random_item($Pieces, i, scene_center + Vector2(randf_range(-400, 400), randf_range(-400, 400)))
		
		PhysicsServer2D.set_active(true)
		fade_label.text = "Shuffling..."
		await get_tree().process_frame
		shuffle_items()
	setup_game_mode()
	if Global.slow_initial_zoom:
		intro_zoom_tween = create_tween()
		intro_zoom_tween.tween_property($Camera2D, "zoom_target", Vector2(0.8, 0.8), 8).set_ease(Tween.EASE_OUT)
	var tween := create_tween()
	tween.tween_property(fade_rect, "modulate", Color(fade_rect.modulate.r, fade_rect.modulate.g, fade_rect.modulate.b, 0.0), 1.0)
	tween.tween_callback(fade_rect.queue_free)
	await tween.finished
	await get_tree().physics_frame
	set_piece_freeze()
	

func generate_one_random_item(piece_container:Node2D, _item_id:int, generation_coords:Vector2):
	await get_tree().process_frame
	var weathering_amt_setting = settings.get(WEATHERING_AMT_SETTING, 0)
	var weathering = null
	match weathering_amt_setting:
		1: weathering = WeatheringMgr.get_random_option(randf_range(0.15, 0.35))
		2: weathering = WeatheringMgr.get_random_option(randf_range(0.45, 0.65))
		3: weathering = WeatheringMgr.get_random_option(randf_range(0.8, 1.0))
		4: weathering = WeatheringMgr.get_random_option(randf_range(0.0, 1.0))
	
	var new_item = await ItemBuilder.build_random_item(null, false, weathering)
	new_item.original_item_count = settings.get(ITEM_COUNT_SETTING, 1)
	piece_container.add_child(new_item)
	new_item.position = generation_coords
	await get_tree().process_frame
	var orig_uv = new_item.polygon.uv
	#new_item.adjust_scale(randf_range(0.5, 1.5))
	var cracks := FractureGenerator.generate_standard_scars(new_item, settings.get(CRACK_COUNT_SETTING, 8))
	new_item.create_scars_from_paths(cracks)
	#for j in range(settings.get(CRACK_COUNT_SETTING, 8)):
	#	new_item.random_scar()
	new_item.polygon.uv = orig_uv
	await new_item.try_shatter(Global.shatter_width, true)
			
func setup_game_mode():
	var game_timer := find_child("GameTimer")
	match Global.game_mode:
		"relax":
			# delete time attack stuff
			Global.awaiting_first_click = false
			game_timer.queue_free()
		"struggle":
			# prepare to trigger time attack stuff
			Global.awaiting_first_click = true
			game_timer.setup(settings[ITEM_COUNT_SETTING])
			game_timer.time_attack_complete.connect(time_attack_complete)
			game_timer.slide_in()

func set_piece_freeze():
	for child in $Pieces.get_children():
		child.safe_freeze(Global.freeze_pieces)

func set_camera_position(new_pos:Vector2):
	var view_rect = camera.get_viewport_rect()
	view_rect.position += new_pos
	view_rect.size /= camera.zoom.x
	var camera_top_left = view_rect.position - view_rect.size / 2
	var camera_bot_right = view_rect.position + view_rect.size / 2
	if camera_top_left.x <= camera_top_left_limit.x and camera_bot_right.x >= camera_bot_right_limit.x:
		new_pos.x = (camera_top_left_limit.x + camera_bot_right_limit.x) / 2
	elif camera_top_left.x < camera_top_left_limit.x:
		new_pos.x = camera_top_left_limit.x + view_rect.size.x / 2
	elif camera_bot_right.x > camera_bot_right_limit.x:
		new_pos.x = camera_bot_right_limit.x - view_rect.size.x / 2
	if camera_top_left.y <= camera_top_left_limit.y and camera_bot_right.y >= camera_bot_right_limit.y:
		new_pos.y = (camera_top_left_limit.y + camera_bot_right_limit.y) / 2
	elif camera_top_left.y < camera_top_left_limit.y:
		new_pos.y = camera_top_left_limit.y + view_rect.size.y / 2
	elif camera_bot_right.y > camera_bot_right_limit.y:
		new_pos.y = camera_bot_right_limit.y - view_rect.size.y / 2
	if !camera.position.is_equal_approx(new_pos):
		camera.position = new_pos
		camera.camera_position_target = camera.global_position
		Global.tutorial_panned_camera.emit()


var glue_brush_streams = [ # elements are arrays [AudioStream, volume %, min_seconds]
	[preload("res://sfx/brush2.mp3"), 0.8, 0.5], #[preload("res://sfx/brush.mp3"), 1.1], 
]
var glue_brush_stream_min_seconds = 1

func play_glue_sfx():
	var stream_data = glue_brush_streams.pick_random()
	glue_brush_audio.stream = stream_data[0]
	glue_brush_audio.volume_db = AudioPlayerPool.get_decibels_for_sfx(stream_data[1])
	glue_brush_audio.pitch_scale = randf_range(0.9, 1.1)
	glue_brush_stream_min_seconds = stream_data[2]
	glue_brush_audio.play()

func update_glue_brush_sfx():
	if Global.click_mode == Global.ClickMode.glue and Input.is_action_pressed("drag_start") and highlighted_items.size() > 0:
		if !glue_brush_audio.playing:
			play_glue_sfx()
	elif glue_brush_audio.playing and glue_brush_audio.get_playback_position() >= glue_brush_stream_min_seconds:
		glue_brush_audio.stop()

func _process(_delta):
	update_glue_brush_sfx()
	if camera_drag_mouse_start != null:
		var offset = get_viewport().get_mouse_position() - camera_drag_mouse_start
		offset = offset/camera.zoom.x
		camera.on_explicit_move()
		set_camera_position(camera_drag_camera_start - offset)
	else:
		var movement = Input.get_vector("left", "right", "up", "down")
		if movement != Vector2.ZERO:
			stop_zoom_tween()
			var view_rect = camera.get_viewport_rect()
			view_rect.position += camera.get_screen_center_position()
			camera.on_explicit_move()
			set_camera_position(camera.position + movement * CAMERA_MOVE_SPEED / camera.zoom.x)
	if glue_cooldown > 0:
		glue_cooldown = max(0, glue_cooldown-_delta)
		if glue_cooldown <= 0 and Input.is_action_pressed("drag_start"):
			do_glue_at_cursor()

func adjust_camera_limits():
		var view_rect = camera.get_viewport_rect()
		view_rect.position += camera.get_target_position()
		view_rect.size /= camera.zoom.x
		var camera_top_left = view_rect.position - view_rect.size / 2
		var camera_bot_right = view_rect.position + view_rect.size / 2
		if camera_top_left.x <= camera_top_left_limit.x and camera_bot_right.x >= camera_bot_right_limit.x:
			camera.position.x = (camera_top_left_limit.x + camera_bot_right_limit.x) / 2
		elif camera_top_left.x < camera_top_left_limit.x:
			camera.position.x = camera_top_left_limit.x + view_rect.size.x / 2
		elif camera_bot_right.x > camera_bot_right_limit.x:
			camera.position.x = camera_bot_right_limit.x - view_rect.size.x / 2
		if camera_top_left.y <= camera_top_left_limit.y and camera_bot_right.y >= camera_bot_right_limit.y:
			camera.position.y = (camera_top_left_limit.y + camera_bot_right_limit.y) / 2
		elif camera_top_left.y < camera_top_left_limit.y:
			camera.position.y = camera_top_left_limit.y + view_rect.size.y / 2
		elif camera_bot_right.y > camera_bot_right_limit.y:
			camera.position.y = camera_bot_right_limit.y - view_rect.size.y / 2

func _unhandled_input(event):
	if event.is_action_pressed("change_click_mode"):
		Global.play_button_click_sound()
		Global.rotate_click_mode()
		get_viewport().set_input_as_handled()
	handle_camera_input(event)
	match Global.click_mode:	
		Global.ClickMode.move: handle_move_input(event)
		Global.ClickMode.glue: handle_glue_input(event)
		Global.ClickMode.save_item: handle_save_item_input(event)
		#Global.ClickMode.paint: handle_paint_input(event)

func handle_save_item_input(event):
	if event.is_action_pressed("rotate_start") or event.is_action_pressed("ui_cancel"):
		Global.play_button_click_sound("menu_back")
		Global.reset_click_mode()

func handle_glue_input(event):
	if event.is_action_pressed("drag_start"):
		# find all pieces under the cursor and glue them together
		do_glue_at_cursor()
	elif event.is_action_released("drag_start"):
		update_glue_brush_sfx()
	elif event.is_action_pressed("rotate_start") or event.is_action_pressed("ui_cancel"):
		Global.play_button_click_sound("menu_back")
		Global.reset_click_mode()

func do_glue_at_cursor():
		update_glue_brush_sfx()
		glue_cooldown = 0.05
		var pieces = cursor_area.get_overlaps()
		if pieces.size() > 1:
			var main_piece = pieces[0]
			main_piece.glue_flash()
			for i in range(1, pieces.size()):
				# only glue items together if they haven't already taken part in a completed time attack game
				if !main_piece.time_attack_seconds and !pieces[i].time_attack_seconds:
					main_piece.glue(pieces[i])
					main_piece.glue_flash()
			main_piece.call_deferred("highlight_visual_polygons")
			main_piece.build_glue_polygons(get_global_mouse_position(), cursor_area.find_child("CollisionShape2D").shape.radius)
			await get_tree().process_frame
			if pieces_container.get_child_count() <= total_items:
				get_tree().create_timer(3).timeout.connect(show_completion_window, CONNECT_ONE_SHOT)
			Global.tutorial_glued_item.emit()
		elif pieces.size() == 1:
			pieces[0].build_glue_polygons(get_global_mouse_position(), cursor_area.find_child("CollisionShape2D").shape.radius)
			Global.tutorial_glued_item.emit()

func show_completion_window():
	if Global.game_mode == "relax":
		show_relax_completion_window()
	else:
		show_struggle_completion_window()

func show_relax_completion_window():
	find_child("RelaxCompletionPanel").visible = true
	find_child("RelaxCompletionPanel").slide_in()

func show_struggle_completion_window():
	find_child("StruggleCompletionPanel").visible = true
	find_child("StruggleCompletionPanel").slide_in()

func hide_relax_completion_window():
	find_child("RelaxCompletionPanel").slide_out()

func hide_struggle_completion_window():
	find_child("StruggleCompletionPanel").slide_out()

func stop_zoom_tween():
	if intro_zoom_tween != null:
		intro_zoom_tween.stop()
		intro_zoom_tween = null

func handle_camera_input(event:InputEvent):
	#if event is InputEventMouseButton:
		if event.is_action_pressed("zoom_in", true):
			var old_target:float = camera.zoom_target.x
			stop_zoom_tween()
			if camera.zoom_target.x > 3:
				camera.zoom_target += ZOOM_INCREMENT * 2
			if camera.zoom_target.x >= 2:
				camera.zoom_target += ZOOM_INCREMENT * 2
			camera.zoom_target += ZOOM_INCREMENT
			if camera.zoom_target.x > 4.0:
				camera.zoom_target = Vector2(4, 4)
			Global.camera_zoom_changed.emit(camera.zoom_target.x)
			var new_target:float = camera.zoom_target.x
			camera.update_zoom_position_target(old_target, new_target)
			adjust_camera_limits()
			get_viewport().set_input_as_handled()
		elif event.is_action_pressed("zoom_out", true):
			var old_target:float = camera.zoom_target.x
			stop_zoom_tween()
			if camera.zoom_target.x > 3:
				camera.zoom_target -= ZOOM_INCREMENT * 2
			if camera.zoom_target.x > 2:
				camera.zoom_target -= ZOOM_INCREMENT * 2
			camera.zoom_target -= ZOOM_INCREMENT
			if camera.zoom_target.x < 0.3:
				camera.zoom_target = Vector2(0.3, 0.3)
			Global.camera_zoom_changed.emit(camera.zoom_target.x)
			var new_target:float = camera.zoom_target.x
			camera.update_zoom_position_target(old_target, new_target)
			adjust_camera_limits()
			get_viewport().set_input_as_handled()
		elif event.is_action_pressed("camera_drag"):
			camera.on_explicit_move()
			stop_zoom_tween()
			camera_drag_mouse_start = get_viewport().get_mouse_position()
			camera_drag_camera_start = camera.position
			get_viewport().set_input_as_handled()
		elif event.is_action_released("camera_drag"):
			camera.on_explicit_move()
			camera_drag_mouse_start = null
			camera_drag_camera_start = null
			get_viewport().set_input_as_handled()

func handle_move_input(event):
	if Global.collide == true and event.is_action_pressed("disable_collision"):
		Global.collide = false
		get_viewport().set_input_as_handled()
	elif Global.collide == false and event.is_action_released("disable_collision"):
		Global.collide = true
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("ui_cancel"):
		open_pause_menu()
		get_viewport().set_input_as_handled()

func _on_collide_button_pressed():
	Global.collide = !Global.collide
	update_button_text()

func update_button_text():
	if sidebar_menu:
		sidebar_menu.update_buttons()

func _on_add_fracture_button_pressed():
	find_child("Pieces").get_children().pick_random().random_scar()

func _on_shatter_button_pressed():
	for child in find_child("Pieces").get_children():
		child.shattering_in_progress = [Global.shatter_width, false]

func _on_add_new_button_pressed():
	var new_item = await ItemBuilder.build_random_item()
	$Pieces.add_child(new_item)
	new_item.position = Vector2(350,150)

func _on_delete_all_button_pressed():
	for child in $Pieces.get_children():
		child.queue_free()

func _on_click_mode_pressed():
	Global.rotate_click_mode()

func _on_save_button_pressed():
	var image_save_data := {} # ItemBuilder.ImageSaveData -> int index
	var weathering_save_data := {} # WeatheringConfig -> int index
	var item_save_data = []
	for item in $Pieces.get_children():
		item_save_data.append(item.get_save_data(image_save_data, weathering_save_data))
	var save_file := FileAccess.open("user://save.dat", FileAccess.WRITE)
	var reversed_image_save_data = {}
	for k in image_save_data.keys():
		reversed_image_save_data[image_save_data[k]] = k #k.map(func(entry): return entry.get_save_data())
	var reversed_weathering_save_data = {}
	for k in weathering_save_data.keys():
		reversed_weathering_save_data[weathering_save_data[k]] = k.get_save_data()
	save_file.store_var(Global.get_save_data())
	save_file.store_var(reversed_image_save_data)
	save_file.store_var(reversed_weathering_save_data)
	save_file.store_var(item_save_data)
	save_file.store_var(settings)
	save_file.store_var(total_items)
	save_file.close()

func _on_load_button_pressed():
	for child in $Pieces.get_children():
		child.queue_free()
	var save_file := FileAccess.open("user://save.dat", FileAccess.READ)
	var global_data = save_file.get_var()
	var image_save_data = save_file.get_var()
	var weathering_save_data = save_file.get_var()
	var rebuilt_textures = {}
	for k in weathering_save_data.keys():
		weathering_save_data[k] = WeatheringConfig.load_save_data(weathering_save_data[k])
	#for k in image_save_data.keys():
	#	image_save_data[k] = image_save_data[k].map(func(v): return ItemBuilder.ImageSaveData.load_save_data(v))
	#	rebuilt_textures[k] = await ItemBuilder.build_specific_item(image_save_data[k])
	var item_save_data = save_file.get_var()
	settings = save_file.get_var()
	total_items = save_file.get_var()
	for item_save in item_save_data:
		var new_item = await ArcheologyItem.load_save_data(item_save, image_save_data, weathering_save_data, rebuilt_textures)
		$Pieces.add_child(new_item)
	save_file.close()
	Global.load_save_data(global_data)

func take_screenshot_of_piece(piece:ArcheologyItem) -> Image:
	if piece == null or !is_instance_valid(piece): 
		return
	piece.visibility_layer |= 2
	var result = await ScreenshotUtil.take_screenshot(camera, piece.to_global(piece.center), piece.bounding_box.size + Vector2(20, 20), piece.global_rotation)
	piece.visibility_layer &= ~2
	return result
	
func save_to_gallery(item:Node2D):
	var mode = Global.game_mode
	match mode:
		"relax": mode = "relax"
		"struggle": mode = "struggle"
	item.game_mode = mode
	Global.click_mode = Global.ClickMode.move
	var img = await take_screenshot_of_piece(item)
	var popup:SaveItemToGalleryMenu = load("res://pottery/SaveItemToGalleryMenu.tscn").instantiate()
	find_child("PopupContainer").add_child(popup)
	popup.setup(img, item)
	popup.position = get_viewport_rect().size/2 - popup.get_rect().size/2
	popup.item_saved.connect(func():
		if get_tree():
			await get_tree().process_frame
			_on_save_button_pressed()
			total_items = max(0, total_items-1)
	, CONNECT_ONE_SHOT)

func time_attack_complete(_total_seconds:int):
	load("res://pottery/TimeAttackCompleteMenu.tscn").instantiate()
	var time_attack_complete_data := []
	for piece in find_child("Pieces").get_children():
		var img = await take_screenshot_of_piece(piece)
		piece.time_attack_seconds = _total_seconds
		time_attack_complete_data.append([img, piece])
	var popup = load("res://pottery/TimeAttackCompleteMenu.tscn").instantiate()
	popup.setup(time_attack_complete_data)
	for i in range(time_attack_complete_data.size()):
		popup.render_item(i)
	popup.queue_free()

func time_attack_show_scoreboard():
	var time_attack_complete_data := []
	for piece in find_child("Pieces").get_children():
		var img = await take_screenshot_of_piece(piece)
		time_attack_complete_data.append([img, piece])
	var popup = load("res://pottery/TimeAttackCompleteMenu.tscn").instantiate()
	find_child("PopupContainer").add_child(popup)
	popup.setup(time_attack_complete_data)
	popup.position = get_viewport_rect().size/2 - popup.get_rect().size/2
	
func open_pause_menu():
	control_hints.set_hints([
		["Return to game", preload("res://art/escape_key.png"), preload("res://art/escape_key.png")]
	])
	var popup:PauseMenu = preload("res://menu/PauseMenu.tscn").instantiate()
	Global.play_button_click_sound("default")
	find_child("PopupContainer").add_child(popup)
	set_process(false)
	set_process_input(false)
	popup.close.connect(func(): 
		set_process_input(true)
		set_process(true)
		update_control_hints()
	)
	popup.save_game.connect(_on_save_button_pressed)
	popup.exit_game.connect(func():
		Global.change_scene("res://menu/main/TitleScreen.tscn")
	)

var adding_items_list:Array[Node2D] = []
func _physics_process(_delta:float):
	if adding_items_list.size() > 0:
		try_place_newly_added_fragments()

func _on_sidebar_menu_add_item_button_pressed():
	total_items += 1
	var fragment_container := Node2D.new()
	add_child(fragment_container)
	fragment_container.position = Vector2(15000, 15000)
	await generate_one_random_item(fragment_container, randi(), Vector2(randf_range(0, 10000), randf_range(0, 10000)))
	adding_items_list.append(fragment_container)

func try_place_newly_added_fragments():
	if adding_items_list.size() <= 0: return
	var fragment_container:Node2D = adding_items_list.pop_back()
	for fragment:ArcheologyItem in fragment_container.get_children():
		if !Global.lock_rotation:
			fragment.rotation = randf_range(0, 2*PI)
		var tries := 10

		while tries > 0:
			tries -= 1
			var try_position := Vector2(randf_range(camera_top_left_limit.x, camera_bot_right_limit.x), randf_range(camera_top_left_limit.y, camera_bot_right_limit.y))
			var collision := fragment.test_move(Transform2D(fragment.rotation, Vector2.ONE, 0, try_position), Vector2.ONE*15)
			if !collision:
				collision = fragment.test_move(Transform2D(fragment.rotation, Vector2.ONE, 0, try_position), -Vector2.ONE*15)
			if !collision:
				collision = fragment.test_move(Transform2D(fragment.rotation, Vector2.ONE, 0, try_position), Vector2(1, -1)*15)
			if !collision:
				collision = fragment.test_move(Transform2D(fragment.rotation, Vector2.ONE, 0, try_position), Vector2(-1, 1)*15)
			if !collision or tries <= 0:
				fragment_container.remove_child(fragment)
				pieces_container.add_child(fragment)
				fragment.global_position = try_position
				print("Placed item after ", tries, " tries")
				
				break
	fragment_container.queue_free()

func _on_sidebar_menu_movement_button_toggled(new_val):
	Global.freeze_pieces = new_val
	update_button_text()

func _on_sidebar_menu_rotate_button_toggled(new_val):
	Global.lock_rotation = new_val
	update_button_text()

func _on_sidebar_menu_save_item_button_pressed():
	Global.click_mode = Global.ClickMode.save_item

func _on_sidebar_menu_shuffle_button_pressed():
	shuffle_items()

func shuffle_items():
	#PhysicsServer2D.set_active(false)
	var pieces = find_child("Pieces").get_children()
	for i in range(pieces.size()):
		if pieces[i]._gallery_mode:
			pieces[i].z_index = i * 5
	pieces.shuffle()
	var largest_x_seen = 0
	var cur_min_x = 0
	var cur_min_y = 0
	var max_x = 3500
	var cur_row_height = 0
	var flash_delay = 0.1
	for piece:ArcheologyItem in pieces:
		var orig_rotation = piece.global_rotation
		if Global.rotate_with_shuffle:
			piece.global_rotation = randf_range(0, 2*PI)
		else:
			piece.global_rotation = 0
		var bb_xmin = 9999999
		var bb_ymin = 9999999
		var bb_xmax = -9999999
		var bb_ymax = -9999999
		for collision:CollisionPolygon2D in piece.collision_polygons:
			var poly := collision.polygon
			for pt in poly:
				pt = collision.to_global(pt)
				if pt.x < bb_xmin: bb_xmin = pt.x
				if pt.y < bb_ymin: bb_ymin = pt.y
				if pt.x > bb_xmax: bb_xmax = pt.x
				if pt.y > bb_ymax: bb_ymax = pt.y
		# check if there's room left on this row
		var space_needed = bb_xmax - bb_xmin + 20
		if largest_x_seen < cur_min_x:
			largest_x_seen = cur_min_x
		if space_needed + cur_min_x > max_x:
			cur_min_x = space_needed
			cur_min_y += cur_row_height
			cur_row_height = 0
		else:
			if cur_row_height < (bb_ymax - bb_ymin) + 20:
				cur_row_height = (bb_ymax - bb_ymin) + 20
			cur_min_x += space_needed
		piece.reset_position = Vector2(cur_min_x - space_needed, cur_min_y) - piece.center_of_mass.rotated(piece.global_rotation) + Vector2(bb_xmax-bb_xmin, bb_ymax-bb_ymin)/2
		piece.reset_rotation = piece.global_rotation
		piece.global_rotation = orig_rotation
		piece.set_deferred("freeze", false) #should get reset to whatever it should be after the position is changed
	var area_center = camera_top_left_limit + (camera_bot_right_limit - camera_top_left_limit)/2
	var y_offset = area_center.y - ((cur_min_y + cur_row_height) / 2)
	var x_offset = area_center.x - (largest_x_seen / 2.0)
	for piece:ArcheologyItem in pieces:
		piece.reset_position.y += y_offset
		piece.reset_position.x += x_offset
		piece.glue_flash(flash_delay, 2)
		flash_delay += 0.01
	#PhysicsServer2D.set_active(true)
	
func update_control_hints():
	match Global.click_mode:
		Global.ClickMode.move:
			control_hints.set_hints([
				["Move item", preload("res://art/mouse_left.png"), preload("res://art/mouse_none.png")],
				["Rotate item", preload("res://art/mouse_right.png"), preload("res://art/mouse_none.png")],
				["Disable bump", preload("res://art/shift_key.png"), preload("res://art/shift_key.png")],
				["Pan camera", preload("res://art/mouse_middle.png"), preload("res://art/mouse_none.png")],
				["Pan camera", preload("res://art/arrow_keys.png"), preload("res://art/arrow_keys.png")],
				["Zoom camera", preload("res://art/mouse_scroll_up.png"), preload("res://art/mouse_scroll_down.png")],
				["Glue brush", preload("res://art/tab_key.png"), preload("res://art/tab_key.png")],
				["Options menu", preload("res://art/escape_key.png"), preload("res://art/escape_key.png")],
			])
		Global.ClickMode.glue:
			control_hints.set_hints([
				["Glue items", preload("res://art/mouse_left.png"), preload("res://art/mouse_none.png")],
				["Stop gluing", preload("res://art/mouse_right.png"), preload("res://art/mouse_none.png")],
				["Stop gluing", preload("res://art/escape_key.png"), preload("res://art/escape_key.png")],
				["Pan camera", preload("res://art/mouse_middle.png"), preload("res://art/mouse_none.png")],
				["Pan camera", preload("res://art/arrow_keys.png"), preload("res://art/arrow_keys.png")],
				["Zoom camera", preload("res://art/mouse_scroll_up.png"), preload("res://art/mouse_scroll_down.png")],
			])
		Global.ClickMode.save_item:
			control_hints.set_hints([
				["Save item", preload("res://art/mouse_left.png"), preload("res://art/mouse_none.png")],
				["Stop saving", preload("res://art/mouse_right.png"), preload("res://art/mouse_none.png")],
				["Stop saving", preload("res://art/escape_key.png"), preload("res://art/escape_key.png")],
			])
		_: control_hints.set_hints([])

func _on_win_button_pressed():
	pass # Replace with function body.
