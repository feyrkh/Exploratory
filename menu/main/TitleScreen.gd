extends Node2D

const SETTINGS_PATH := "user://settings.cfg"

#var tables = []

enum CrackWidth {HAIRLINE, THIN, MEDIUM, THICK}
const crack_widths = {
	CrackWidth.HAIRLINE: 0.05,
	CrackWidth.THIN: 0.2,
	CrackWidth.MEDIUM: 0.75,
	CrackWidth.THICK: 1.5,
}
const crack_width_descs = {
	CrackWidth.HAIRLINE: "hairline",
	CrackWidth.THIN: "thin",
	CrackWidth.MEDIUM: "medium",
	CrackWidth.THICK: "thick",
}

const zen_min_settings = {
	"crack_count": 0
}

const time_attack_min_settings = {
	"crack_count": 5
}

var item_count := 1
var rotation_enabled := true
var bump_enabled := true
var crack_width := CrackWidth.THIN
var crack_count := 8

var config_file := ConfigFile.new()
var mode := "zen"

var next_bounding_box

@onready var subviewport = find_child("SubViewport")
@onready var spawn_start = find_child("ItemSpawn").global_position
@onready var demo_start_pos = find_child("SubViewportContainer").position
@onready var main_menu_start_pos = find_child("MainMenu").position
@onready var option_menu_start_pos = find_child("OptionsContainer").position

var demo_tween:Tween

const LIT_TIME := 10

# Called when the node enters the scene tree for the first time.
func _ready():
	subviewport.world_2d = get_world_2d()
	#find_child("DisplayCamera").global_position = find_child("ItemSpawn").global_position
	find_child("ContinueButton").visible = FileAccess.file_exists("user://save.dat")
	find_child("MainMenu").visible = true
	find_child("OptionsContainer").visible = false
	load_config()
	update_labels()
	await prepare_next_item(false)
	update_item()
	#var offset = randi_range(800, 1000)
	#for i in range(5):
		#var new_table = load("res://menu/main/DemoTable.tscn").instantiate()
		#new_table.should_load_slowly = i > 2
		#add_child(new_table)
		#new_table.position = Vector2(i * 1000 + offset, 0)
		#tables.append(new_table)

func _unhandled_key_input(event):
	if event.is_action_pressed("ui_cancel") and find_child("OptionsContainer").visible:
		_on_back_button_pressed()

func load_config():
	var err = config_file.load(SETTINGS_PATH)
	item_count = config_file.get_value(mode, "item_count", 1)
	rotation_enabled = config_file.get_value(mode, "rotation_enabled", true)
	bump_enabled = config_file.get_value(mode, "bump_enabled", true)
	crack_width = config_file.get_value(mode, "crack_width", CrackWidth.THIN)
	crack_count = config_file.get_value(mode, "crack_count", 8)

func save_config():
	config_file.set_value(mode, "item_count", item_count)
	config_file.set_value(mode, "rotation_enabled", rotation_enabled)
	config_file.set_value(mode, "bump_enabled", bump_enabled)
	config_file.set_value(mode, "crack_width", crack_width)
	config_file.set_value(mode, "crack_count", crack_count)
	config_file.save(SETTINGS_PATH)

func _process(delta):
	pass
	#if tables[0].position.x < -1000:
		#tables[0].position = Vector2(tables[0].position.x + ((tables.size()) * 1000), 0)
		##tables.append(new_table)
		##tables[0].queue_free()
		#tables.append(tables.pop_front())

func _on_exit_button_pressed():
	get_tree().quit()

func update_labels():
	find_child("ItemCountAmount").text = str(item_count)
	find_child("RotationValue").text = "yes" if rotation_enabled else "no"
	find_child("BumpValue").text = "yes" if bump_enabled else "no"
	find_child("CrackWidthAmount").text = crack_width_descs.get(crack_width, "???")
	find_child("CrackAmtAmount").text = str(crack_count)

func _on_item_count_decrease_pressed():
	var amt = 1
	if Input.is_key_pressed(KEY_SHIFT):
		amt = 5
	item_count = max(1, item_count-amt)
	update_labels()

func _on_item_count_increase_pressed():
	var amt = 1
	if Input.is_key_pressed(KEY_SHIFT):
		amt = 5
	item_count = min(10, item_count+amt)
	update_labels()

func _on_rotation_decrease_pressed():
	rotation_enabled = !rotation_enabled
	update_labels()
	_on_rotation_label_mouse_entered()

func _on_crack_width_decrease_pressed():
	crack_width = (crack_width - 1)
	if crack_width < 0:
		crack_width += CrackWidth.size()
	update_labels()

func _on_crack_width_increase_pressed():
	crack_width = (crack_width + 1) % CrackWidth.size()
	update_labels()

func _on_crack_amt_decrease_pressed():
	var min_allowed
	match mode:
		"zen": min_allowed = 0
		"time": min_allowed = 5
	var amt = 1
	if Input.is_key_pressed(KEY_SHIFT):
		amt = 5
	crack_count = max(min_allowed, crack_count-amt)
	update_labels()

func _on_crack_amt_increase_pressed():
	var amt = 1
	if Input.is_key_pressed(KEY_SHIFT):
		amt = 5
	crack_count = min(50, crack_count+amt)
	update_labels()

func _on_back_button_pressed():
	restore_demo_view()
	save_config()
	#find_child("OptionsContainer").visible = false
	find_child("MainMenu").visible = true

func _on_zen_button_pressed():
	mode = "zen"
	load_options_menu()

func _on_time_button_pressed():
	mode = "time"
	load_options_menu()

func load_options_menu():
	hide_demo_view()
	load_config()
	update_labels()
	find_child("OptionsContainer").visible = true
	#find_child("MainMenu").visible = false
	
func _on_start_button_pressed():
	save_config()
	var settings = {}
	match mode:
		"zen":
			settings["mode"] = "zen"
			settings[CleaningTable.CRACK_COUNT_SETTING] = crack_count
			settings[CleaningTable.ITEM_COUNT_SETTING] = item_count
			var dir = DirAccess.open("user://")
			dir.remove("save.dat")
		"time":
			settings["mode"] = "zen"
			settings[CleaningTable.CRACK_COUNT_SETTING] = crack_count
			settings[CleaningTable.ITEM_COUNT_SETTING] = item_count
	var scene = load("res://pottery/CleaningTable.tscn")
	Global.shatter_width = crack_widths[crack_width]
	Global.rotate_with_shuffle = rotation_enabled
	Global.lock_rotation = !rotation_enabled
	Global.freeze_pieces = !bump_enabled
	Global.collide = true
	Global.click_mode = Global.ClickMode.move
	Global.next_scene_settings = settings
	Global.change_scene(scene)

func _on_bump_decrease_pressed():
	bump_enabled = !bump_enabled
	update_labels()
	_on_bump_label_mouse_entered()


func _on_bump_increase_pressed():
	bump_enabled = !bump_enabled
	update_labels()
	_on_bump_label_mouse_entered()

func hover_tooltip(str:String):
	find_child("HoverDescription").text = str

func _on_item_count_label_mouse_entered():
	hover_tooltip("Change how many items are generated for you to reassemble.\n\nThe fragments will be mixed together - add more items for a greater challenge!")

func _on_rotation_label_mouse_entered():
	if !rotation_enabled:
		hover_tooltip("Fragments will not rotate when they collide with other pieces that you are moving\n\nWhen shuffled, fragments will always be oriented so that they will fit together without rotation\n\nAn easier, more meditative experience")
	else:
		hover_tooltip("Fragments may rotate when they collide with other pieces that you are moving\n\nWhen shuffled, fragments will be randomly oriented, and you will need to rotate to fit them together\n\nA more engaging experience")

func _on_bump_label_mouse_entered():
	if !bump_enabled:
		hover_tooltip("Fragments will not move when bumped by a piece you are moving\n\nHold 'shift' to temporarily disable fragment collision if you need to move one piece through another")
	else:
		hover_tooltip("Fragments will be bumped out of the way by a piece you are moving\n\nTake care when fitting pieces together\n\nHold 'shift' to temporarily disable fragment collision if you need to move one piece through another")

func _on_crack_width_label_mouse_entered():
	hover_tooltip("Adjust the thickness of the fracture lines\n\nThinner fractures fit together more perfectly, but thicker fractures more room for adjustment\n\nFind beauty in imperfection")

func _on_crack_amt_label_mouse_entered():
	hover_tooltip("Adjust the number of fracture lines on each item")

func _on_start_button_mouse_entered():
	if mode == "zen":
		hover_tooltip("Begin a calm and reflective meditation on imperfection\n\nNo time limit, discard fragments freely, and bring new broken items into the mix as you wish\n\nSave completed pieces to your gallery")
	else:
		hover_tooltip("Begin a frantic rush to repair what has been broken\n\nThe timer will start when you move the first fragment\n\nSave completed pieces to your gallery, along with your score")


func _on_back_button_mouse_entered():
	hover_tooltip("Return to the main menu")


func _on_gallery_button_pressed():
	Global.change_scene("res://pottery/GalleryRoom.tscn")


func _on_continue_button_pressed():
	Global.next_scene_settings = {"mode":"continue"}
	Global.change_scene("res://pottery/CleaningTable.tscn")

func update_item():
	var coverup = find_child("Coverup")
	var display_area_size = coverup.get_rect()
	if coverup.modulate.a == 0:
		print("Fading out")
		var tween = create_tween()
		tween.tween_property(coverup, "modulate", Color(0, 0, 0, 1), 2.0).set_delay(1)
		await tween.finished
	for child in find_child("ItemSpawn").get_children():
		child.queue_free()
	transfer_prepared_item()

	var tween = create_tween()
	tween.tween_property(coverup, "modulate", Color(0, 0, 0, 0.0), 2.0).set_delay(1)
	print("Fading in")
	prepare_next_item()
	await tween.finished
	var timer := get_tree().create_timer(LIT_TIME)
	await timer.timeout
	call_deferred("update_item")

func prepare_next_item(load_slowly=true):
	var noise:FastNoiseLite = null
	noise = FastNoiseLite.new()
	noise.noise_type = FastNoiseLite.TYPE_PERLIN
	noise.frequency = 0.1
	noise.fractal_lacunarity = 2
	noise.fractal_gain = 0.5
	noise.fractal_octaves = 8
	noise.fractal_type = FastNoiseLite.FRACTAL_FBM
	noise.seed = randf()
	var item := await ItemBuilder.build_random_item(null, load_slowly, noise if randf() < 0.3 else null, randf_range(0.1, 1.0))
	item.is_display = true
	find_child("ItemPreparation").add_child(item)
	item.global_rotation = 0
	next_bounding_box = item.bounding_box
	item.position = -(item.bounding_box.size / 2 + item.bounding_box.position)
	
	for j in range(randi_range(5, 12)):
		item.random_scar()
	if load_slowly: await(get_tree().process_frame)
	await item.try_shatter(randf_range(0.5, 1.5), load_slowly)
	if load_slowly: await(get_tree().process_frame)
	for i in find_child("ItemPreparation").get_children():
		if is_instance_valid(i) and i is ArcheologyItem:
			i.build_glue_polygons(i.global_position, 99999999)
			if load_slowly: await(get_tree().process_frame)

func transfer_prepared_item():
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
	find_child("OptionsContainer").position = option_menu_start_pos + Vector2(0, 1280)
	demo_tween.tween_property(find_child("OptionsContainer"), "position", option_menu_start_pos, 1.0)


func restore_demo_view():
	if demo_tween != null and demo_tween.is_running():
		demo_tween.stop()
	demo_tween = create_tween()
	demo_tween.set_parallel(true)
	demo_tween.tween_property(find_child("SubViewportContainer"), "position", demo_start_pos, 1.0)
	demo_tween.tween_property(find_child("MainMenu"), "position", main_menu_start_pos, 1.0)
	demo_tween.tween_property(find_child("OptionsContainer"), "position", option_menu_start_pos + Vector2(0, 1280), 1.0)

func show_demo_view():
	var tween = create_tween()
	
