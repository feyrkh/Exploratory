extends Node2D

const SHIMMER_MOVE_SPEED := 40
#var tables = []

var next_bounding_box

@onready var subviewport = find_child("SubViewport")
@onready var spawn_start = find_child("ItemSpawn").global_position
@onready var demo_start_pos = find_child("SubViewportContainer").position
@onready var main_menu_start_pos = find_child("MainMenu").position
@onready var option_menu_start_pos = find_child("StartGameOptionsContainer").position
@onready var settings_menu_start_pos = find_child("SettingsContainer").position

var demo_tween:Tween
var next_item_shape
var shimmer_offset := 0.0
var shimmer_offset_dir := 1
var cur_backdrop
var next_backdrop

const LIT_TIME := 10

# Called when the node enters the scene tree for the first time.
func _ready():
	find_child("VersionLabel").text = ProjectSettings.get_setting("application/config/version")
	if OS.has_feature("web"):
		find_child("ExitButton").visible = false
	if !Global.splash_screen_shown:
		var splash = find_child("SplashScreen")
		splash.visible = true
	subviewport.world_2d = get_world_2d()
	#find_child("DisplayCamera").global_position = find_child("ItemSpawn").global_position
	find_child("ContinueButton").visible = FileAccess.file_exists("user://save.dat")
	find_child("MainMenu").visible = true
	find_child("StartGameOptionsContainer").visible = false
	find_child("SettingsContainer").visible = false
	find_child("StartGameOptionsContainer").menu_closed.connect(_on_back_button_pressed)
	find_child("GalleryButton").disabled = !at_least_one_gallery_item_exists()
		
	await prepare_next_item(false)
	update_item()
	await get_tree().process_frame
	var first_child = find_child("ItemSpawn").get_child(0)
	var backdrop = create_display_backdrop(next_item_shape)
	cur_backdrop = backdrop
	first_child.add_child(backdrop)
	if !Global.splash_screen_shown:
		Global.splash_screen_shown = true
		var splash = find_child("SplashScreen")
		splash.visible = true
		var tween = splash.create_tween()
		tween.tween_property(splash, "modulate", Color.TRANSPARENT, 1.0).set_delay(1.0)
		tween.tween_property(splash, "visible", false, 0)
	Global.enable_sound.emit()
	#var offset = randi_range(800, 1000)
	#for i in range(5):
		#var new_table = load("res://menu/main/DemoTable.tscn").instantiate()
		#new_table.should_load_slowly = i > 2
		#add_child(new_table)
		#new_table.position = Vector2(i * 1000 + offset, 0)
		#tables.append(new_table)

func at_least_one_gallery_item_exists():
	var dir = DirAccess.open("user://gallery")
	if dir:
		dir.list_dir_begin()
		var file_name = dir.get_next()
		while file_name != "":
			if !dir.current_is_dir():
				if file_name.ends_with(".dat"):
					return true
			file_name = dir.get_next()
	return false

func _unhandled_key_input(event):
	if event.is_action_pressed("ui_cancel") and find_child("StartGameOptionsContainer").visible:
		_on_back_button_pressed()
	elif event.is_action_pressed("ui_cancel") and find_child("SettingsContainer").visible:
		return_from_settings_menu()
	elif event.is_action_pressed("ui_cancel") and find_child("CreditsButton").text == "Back":
		_on_credits_button_pressed()
		Global.play_button_click_sound()

func _on_back_button_pressed():
	find_child("StartGameOptionsContainer").hide_menu()
	restore_demo_view()
	#find_child("StartGameOptionsContainer").visible = false
	find_child("MainMenu").visible = true
	Global.play_button_click_sound("menu_back")
	find_child("CreditsButton").visible = true
	
func _process(_delta):
	shimmer_offset += _delta / SHIMMER_MOVE_SPEED * sign(shimmer_offset_dir)
	if cur_backdrop and is_instance_valid(cur_backdrop):
		cur_backdrop.material.set_shader_parameter("offset", shimmer_offset)
	#if tables[0].position.x < -1000:
		#tables[0].position = Vector2(tables[0].position.x + ((tables.size()) * 1000), 0)
		##tables.append(new_table)
		##tables[0].queue_free()
		#tables.append(tables.pop_front())

func _on_exit_button_pressed():
	get_tree().quit()

func _on_zen_button_pressed():
	load_options_menu("relax")

func _on_time_button_pressed():
	load_options_menu("struggle")

func load_options_menu(mode):
	hide_demo_view()
	find_child("StartGameOptionsContainer").show_menu(mode)
	#find_child("MainMenu").visible = false

func _on_gallery_button_pressed():
	Global.game_mode = "gallery"
	Global.change_scene("res://pottery/GalleryRoom.tscn")

func _on_continue_button_pressed():
	Global.next_scene_settings = {"mode":"continue"}
	Global.change_scene("res://pottery/CleaningTable.tscn")

func update_item():
	var coverup = find_child("Coverup")
	#var display_area_size = coverup.get_rect()
	var tween
	if coverup.modulate.a == 0:
		print("Fading out")
		tween = create_tween()
		tween.tween_property(coverup, "modulate", Color(0, 0, 0, 1), 2.0).set_delay(1)
		await tween.finished
	for child in find_child("ItemSpawn").get_children():
		child.queue_free()
	transfer_prepared_item()

	tween = create_tween()
	tween.tween_property(coverup, "modulate", Color(0, 0, 0, 0.0), 2.0).set_delay(1)
	print("Fading in")
	prepare_next_item()
	await tween.finished
	var timer := get_tree().create_timer(LIT_TIME)
	await timer.timeout
	call_deferred("update_item")

func create_display_backdrop(polygon_points):
	var backdrop = Polygon2D.new()
	backdrop.color = [Color("ccb00e"), Color("adb300"), Color("db0b00"), Color.BLACK, Color("1d9e00")].pick_random()
	backdrop.material = preload("res://shader/GoldShimmerMaterial.tres").duplicate()
	backdrop.material.set_shader_parameter("normal_color", backdrop.color)
	backdrop.polygon = polygon_points
	backdrop.show_behind_parent = true
	next_backdrop = backdrop
	return backdrop

func prepare_next_item(load_slowly=true):
	var weathering_type = null
	if randf() < 0.7:
		weathering_type = WeatheringMgr.get_random_option(0.6)
	var item := await ItemBuilder.build_random_item(null, load_slowly, weathering_type)
	item.is_display = true
	find_child("ItemPreparation").add_child(item)
	next_item_shape = item.polygon.polygon
	item.global_rotation = 0
	next_bounding_box = item.bounding_box
	item.position = -(item.bounding_box.size / 2 + item.bounding_box.position)
	var backdrop = create_display_backdrop(item.polygon.polygon)
	
	var cracks := FractureGenerator.generate_standard_scars(item, randi_range(5, 12))
	item.create_scars_from_paths(cracks)
	#for j in range(randi_range(5, 12)):
	#	item.random_scar()
	if load_slowly: await(get_tree().process_frame)
	if !item or !is_instance_valid(item):
		return
	await item.try_shatter(randf_range(1.0, 1.8), load_slowly)
	if load_slowly: await(get_tree().process_frame)
	for i in find_child("ItemPreparation").get_children():
		if i != null and is_instance_valid(i) and i is ArcheologyItem:
			#i.build_glue_polygons(i.global_position, 99999999)
			if load_slowly: await(get_tree().process_frame)
	await get_tree().process_frame
	while find_child("ItemPreparation").get_child_count() == 0:
		await get_tree().process_frame
	find_child("ItemPreparation").get_child(0).add_child(backdrop)

func transfer_prepared_item():
	cur_backdrop = next_backdrop
	var spawn = find_child("ItemSpawn")
	spawn.global_position = spawn_start
	var prep = find_child("ItemPreparation")
	for child in spawn.get_children():
		child.queue_free()
	for child in prep.get_children():
		var pos = child.position
		prep.remove_child(child)
		spawn.add_child(child)
		child.position = pos

	var available_space = Vector2(830, 720)
	var used_space = next_bounding_box.size
	var actual_scale = max(used_space.x / available_space.x, used_space.y / available_space.y)
	var desired_zoom = 0.7 / actual_scale
	find_child("DisplayCamera").zoom = Vector2(desired_zoom, desired_zoom)
	var offset = Vector2(randf_range(100, 200), randf_range(100, 200))
	if randf() < 0.5: offset.x = -offset.x
	if randf() < 0.5: offset.y = -offset.y
	find_child("DisplayCamera").global_position = spawn_start# - Vector2(415, 0)
	shimmer_offset_dir = -1 if randf() < 0.5 else 1
	#var camera_tween = create_tween()
	#spawn.global_position = spawn_start - offset
	#camera_tween.tween_property(spawn, "global_position", spawn_start + offset, LIT_TIME + 6)

func hide_demo_view():
	if demo_tween != null and demo_tween.is_running():
		demo_tween.stop()
	demo_tween = create_tween()
	demo_tween.set_parallel(true)
	demo_tween.tween_property(find_child("SubViewportContainer"), "position", Vector2(1280, 0), 1.0)
	find_child("MainMenu").position = main_menu_start_pos
	demo_tween.tween_property(find_child("MainMenu"), "position", main_menu_start_pos - Vector2(1280, 0), 1.0)
	find_child("StartGameOptionsContainer").position = option_menu_start_pos + Vector2(0, 1280)
	demo_tween.tween_property(find_child("StartGameOptionsContainer"), "position", option_menu_start_pos, 1.0)
	find_child("CreditsButton").visible = false

func restore_demo_view():
	if demo_tween != null and demo_tween.is_running():
		demo_tween.stop()
	demo_tween = create_tween()
	demo_tween.set_parallel(true)
	demo_tween.tween_property(find_child("SubViewportContainer"), "position", demo_start_pos, 1.0)
	demo_tween.tween_property(find_child("MainMenu"), "position", main_menu_start_pos, 1.0)
	demo_tween.tween_property(find_child("StartGameOptionsContainer"), "position", option_menu_start_pos + Vector2(0, 1280), 1.0)
	demo_tween.set_parallel(false)
	demo_tween.tween_property(find_child("StartGameOptionsContainer"), "visible", false, 0.01)
	find_child("CreditsButton").visible = true

func enter_settings_menu():
	if demo_tween != null and demo_tween.is_running():
		demo_tween.stop()
	show_weathering_settings()
	demo_tween = create_tween()
	demo_tween.set_parallel(true)
	demo_tween.tween_property(find_child("SubViewportContainer"), "position", Vector2(1280, 0), 1.0)
	find_child("MainMenu").position = main_menu_start_pos
	demo_tween.tween_property(find_child("MainMenu"), "position", main_menu_start_pos - Vector2(1280, 0), 1.0)
	find_child("SettingsContainer").position = settings_menu_start_pos - Vector2(0, 1280)
	find_child("SettingsContainer").visible = true
	demo_tween.tween_property(find_child("SettingsContainer"), "position", settings_menu_start_pos, 1.0)
	find_child("CreditsButton").visible = false

func return_from_settings_menu():
	if demo_tween != null and demo_tween.is_running():
		demo_tween.stop()
	demo_tween = create_tween()
	demo_tween.set_parallel(true)
	demo_tween.tween_property(find_child("SubViewportContainer"), "position", demo_start_pos, 1.0)
	demo_tween.tween_property(find_child("MainMenu"), "position", main_menu_start_pos, 1.0)
	demo_tween.tween_property(find_child("SettingsContainer"), "position", settings_menu_start_pos - Vector2(0, 1280), 1.0)
	demo_tween.set_parallel(false)
	demo_tween.tween_property(find_child("SettingsContainer"), "visible", false, 0.01)
	find_child("CreditsButton").visible = true

func _on_settings_button_pressed():
	enter_settings_menu()
	show_audio_settings()

func show_audio_settings():
	find_child("WeatheringSettingsContainer").visible = false
	find_child("ItemColorSettingsContainer").visible = false
	find_child("GeneralSettingsContainer").visible = true
	find_child("WeatheringSettings").modulate = Color.WHITE
	find_child("ItemColorSettings").modulate = Color.WHITE
	find_child("AudioSettings").modulate = Color.GOLD
	find_child("GeneralSettingsContainer").refresh()

func _on_item_color_settings_pressed():
	show_item_color_settings()
	
func show_weathering_settings():
	find_child("WeatheringSettingsContainer").visible = true
	find_child("ItemColorSettingsContainer").visible = false
	find_child("GeneralSettingsContainer").visible = false
	find_child("WeatheringSettings").modulate = Color.GOLD
	find_child("ItemColorSettings").modulate = Color.WHITE
	find_child("AudioSettings").modulate = Color.WHITE
	find_child("WeatheringSettingsContainer").refresh()

func show_item_color_settings():
	find_child("WeatheringSettingsContainer").visible = false
	find_child("ItemColorSettingsContainer").visible = true
	find_child("GeneralSettingsContainer").visible = false
	find_child("WeatheringSettings").modulate = Color.WHITE
	find_child("ItemColorSettings").modulate = Color.GOLD
	find_child("AudioSettings").modulate = Color.WHITE

func _on_audio_settings_pressed():
	show_audio_settings()

func _on_weathering_settings_pressed():
	show_weathering_settings()

func _on_settings_back_pressed():
	return_from_settings_menu()
	ColorMgr.save()
	find_child("MainMenu").visible = true
	Global.play_button_click_sound("menu_back")

func _on_credits_button_pressed():
	var credits = find_child("CreditsScreen")
	if credits.modulate.a <= 0:
		var tween = credits.create_tween()
		tween.tween_property(credits, "modulate", Color.WHITE, 0.5)
		find_child("CreditsButton").text = "Back"
	elif credits.modulate.a >= 1:
		var tween = credits.create_tween()
		tween.tween_property(credits, "modulate", Color.TRANSPARENT, 0.5)
		find_child("CreditsButton").text = "Credits"
		
	
