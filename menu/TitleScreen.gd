extends Node2D

const SETTINGS_PATH := "user://settings.cfg"

var tables = []

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
var crack_width := CrackWidth.THIN
var crack_count := 8

var config_file := ConfigFile.new()
var mode := "zen"

# Called when the node enters the scene tree for the first time.
func _ready():
	find_child("MainMenu").visible = true
	find_child("OptionsContainer").visible = false
	load_config()
	update_labels()
	var offset = randi_range(0, 1000)
	for i in range(5):
		var new_table = load("res://menu/main/DemoTable.tscn").instantiate()
		new_table.should_load_slowly = false
		add_child(new_table)
		new_table.position = Vector2(i * 1000 - offset, 0)
		tables.append(new_table)

func _unhandled_key_input(event):
	if event.is_action_pressed("ui_cancel") and find_child("OptionsContainer").visible:
		_on_back_button_pressed()

func load_config():
	var err = config_file.load(SETTINGS_PATH)
	item_count = config_file.get_value(mode, "item_count", 1)
	rotation_enabled = config_file.get_value(mode, "rotation_enabled", true)
	crack_width = config_file.get_value(mode, "crack_width", CrackWidth.THIN)
	crack_count = config_file.get_value(mode, "crack_count", 8)

func save_config():
	config_file.set_value(mode, "item_count", item_count)
	config_file.set_value(mode, "rotation_enabled", rotation_enabled)
	config_file.set_value(mode, "crack_width", crack_width)
	config_file.set_value(mode, "crack_count", crack_count)
	config_file.save(SETTINGS_PATH)

func _process(delta):
	if tables[0].position.x < -1000:
		tables[0].position = Vector2(tables[0].position.x + ((tables.size()) * 1000), 0)
		#tables.append(new_table)
		#tables[0].queue_free()
		tables.append(tables.pop_front())

func _on_exit_button_pressed():
	get_tree().quit()

func update_labels():
	find_child("ItemCountAmount").text = str(item_count)
	find_child("RotationAmount").text = "yes" if rotation_enabled else "no"
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
	save_config()
	find_child("OptionsContainer").visible = false
	find_child("MainMenu").visible = true

func _on_zen_button_pressed():
	mode = "zen"
	load_options_menu()

func _on_time_button_pressed():
	mode = "time"
	load_options_menu()

func load_options_menu():
	load_config()
	update_labels()
	find_child("OptionsContainer").visible = true
	find_child("MainMenu").visible = false
	
func _on_start_button_pressed():
	save_config()
	var settings = {}
	match mode:
		"zen":
			settings["mode"] = "zen"
			settings[CleaningTable.CRACK_COUNT_SETTING] = crack_count
			settings[CleaningTable.ITEM_COUNT_SETTING] = item_count
		"time":
			settings["mode"] = "zen"
			settings[CleaningTable.CRACK_COUNT_SETTING] = crack_count
			settings[CleaningTable.ITEM_COUNT_SETTING] = item_count
	var scene = load("res://pottery/CleaningTable.tscn")
	Global.shatter_width = crack_widths[crack_width]
	Global.rotate_with_shuffle = rotation_enabled
	Global.lock_rotation = !rotation_enabled
	Global.freeze_pieces = false
	Global.collide = true
	Global.click_mode = Global.ClickMode.move
	Global.next_scene_settings = settings
	get_tree().change_scene_to_packed(scene)
