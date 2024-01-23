extends Control

signal menu_closed()

const SETTINGS_PATH := "user://settings.cfg"

enum CrackWidth {HAIRLINE, THIN, MEDIUM, THICK}

const crack_widths = {
	CrackWidth.HAIRLINE: 0.08,
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
var crack_width := CrackWidth.MEDIUM
var crack_count := 8
var weathering_amt := 0

var config_file := ConfigFile.new()
var mode := "zen"
var difficulty_button_group := ButtonGroup.new()
var cur_selected_button:Button
var hover_deselect_timer:float = 0

@onready var custom_difficulty_button:Button = find_child("CustomDifficultyButton")
@onready var difficulty_name:Label = find_child("DifficultyName")
@onready var item_count_icon = find_child("ItemCountIcon")
@onready var item_count_icon_amt:Label = find_child("ItemCountIconAmt")
@onready var crack_count_icon = find_child("CrackCountIcon")
@onready var crack_count_icon_amt:Label = find_child("CrackCountIconAmt")
@onready var rotate_icon:TextureRect = find_child("RotateIcon")
@onready var bump_icon:TextureRect = find_child("BumpIcon")
@onready var weathering_icon = find_child("WeatheringIcon")
@onready var weathering_icon_amt = find_child("WeatheringIconAmt")
@onready var crack_size_icon = find_child("CrackSizeIcon")
@onready var crack_size_icon_amt = find_child("CrackSizeIconAmt")


func _ready():
	load_config()
	update_labels()
	find_child("BackButton").pressed.connect(func(): menu_closed.emit())
	find_child("BackButton").mouse_entered.connect(_on_back_button_mouse_entered)
	find_child("StartButton").mouse_entered.connect(_on_start_button_mouse_entered)
	find_child("StartButton").pressed.connect(_on_start_button_pressed)
	setup_menu_buttons("ItemCount", _on_item_count_decrease_pressed, _on_item_count_increase_pressed, _on_item_count_label_mouse_entered)
	setup_menu_buttons("Rotation", _on_rotation_decrease_pressed, _on_rotation_decrease_pressed, _on_rotation_label_mouse_entered)
	setup_menu_buttons("Bump", _on_bump_decrease_pressed, _on_bump_decrease_pressed, _on_bump_label_mouse_entered)
	setup_menu_buttons("CrackWidth", _on_crack_width_decrease_pressed, _on_crack_width_increase_pressed, _on_crack_width_label_mouse_entered)
	setup_menu_buttons("CrackAmt", _on_crack_amt_decrease_pressed, _on_crack_amt_increase_pressed, _on_crack_amt_label_mouse_entered)
	setup_menu_buttons("Weathering", _on_weathering_decrease_pressed, _on_weathering_increase_pressed, _on_weathering_label_mouse_entered)
	for child in find_child("DifficultyLevels").get_children():
		if child is DifficultyMode:
			child.button_group = difficulty_button_group
			child.mouse_entered.connect(show_difficulty_description.bind(child.settings))
			child.mouse_exited.connect(prepare_to_show_default_description)
			child.pressed.connect(select_difficulty.bind(child))
	custom_difficulty_button.button_group = difficulty_button_group

func reset():
	for child in find_child("DifficultyLevels").get_children():
		child.button_pressed = false
	custom_difficulty_button = null
	find_child("StartButton").visible = false
	show_difficulty_description(null)

func _process(delta:float):
	hover_deselect_timer -= delta
	if hover_deselect_timer <= 0:
		set_process(false)
		show_default_difficulty_description()

func select_difficulty(btn:Button):
	cur_selected_button = btn
	show_difficulty_description(btn.settings)
	item_count = btn.settings.item_count
	rotation_enabled = btn.settings.rotation_enabled
	bump_enabled = btn.settings.bump_enabled
	crack_width = btn.settings.crack_width
	crack_count = btn.settings.crack_count
	weathering_amt = btn.settings.weathering_amt

func show_difficulty_description(settings:GameSettings):
	set_process(false)
	if settings == null:
		find_child("DifficultyName").text = ""
		find_child("DifficultyLevelDescription").text = ""
		find_child("SettingSummary").visible = false
	else:
		find_child("DifficultyName").text = settings.name
		find_child("DifficultyLevelDescription").text = settings.desc
		find_child("SettingSummary").visible = true
		item_count_icon_amt.text = str(settings.item_count)
		crack_count_icon_amt.text = str(settings.crack_count)
		match settings.crack_width:
			0: crack_size_icon_amt.text = "x"
			1: crack_size_icon_amt.text = "s"
			2: crack_size_icon_amt.text = "m"
			3: crack_size_icon_amt.text = "l"
		match settings.weathering_amt:
			0: weathering_icon_amt.text = "x"
			1: weathering_icon_amt.text = "s"
			2: weathering_icon_amt.text = "m"
			3: weathering_icon_amt.text = "l"
		if settings.rotation_enabled:
			rotate_icon.texture = preload("res://art/sidebar menu/sidebar_icon_rotate-on.png")
		else:
			rotate_icon.texture = preload("res://art/sidebar menu/sidebar_icon_rotate-off.png")
		if settings.bump_enabled:
			bump_icon.texture = preload("res://art/sidebar menu/sidebar_icon_movement-on.png")
		else:
			bump_icon.texture = preload("res://art/sidebar menu/sidebar_icon_movement-off.png")

	find_child("StartButton").visible = cur_selected_button != null

func prepare_to_show_default_description():
	set_process(true)
	hover_deselect_timer = 0.15

func show_default_difficulty_description():
	if cur_selected_button != null:
		show_difficulty_description(cur_selected_button.settings)
	else:
		show_difficulty_description(null)
	
func setup_menu_buttons(button_prefix:String, decrease_callback:Callable, increase_callback:Callable, hover_callback:Callable):
	var label = find_child(button_prefix+"Label")
	var decrease = find_child(button_prefix+"Decrease")
	var amt = find_child(button_prefix+"Amount")
	var increase = find_child(button_prefix+"Increase")
	label.mouse_entered.connect(hover_callback)
	decrease.mouse_entered.connect(hover_callback)
	amt.mouse_entered.connect(hover_callback)
	increase.mouse_entered.connect(hover_callback)
	decrease.pressed.connect(decrease_callback)
	increase.pressed.connect(increase_callback)

func show_menu(new_mode):
	reset()
	mode = new_mode
	load_config()
	update_labels()
	visible = true
	hover_tooltip("")

func hide_menu():
	save_config()
	hover_tooltip("")

func load_config():
	var err = config_file.load(SETTINGS_PATH)
	if err != OK and err != ERR_FILE_NOT_FOUND:
		push_error("Error loading settings ", SETTINGS_PATH, ": ", err)
	item_count = config_file.get_value(mode, "item_count", 1)
	rotation_enabled = config_file.get_value(mode, "rotation_enabled", true)
	bump_enabled = config_file.get_value(mode, "bump_enabled", true)
	crack_width = config_file.get_value(mode, "crack_width", CrackWidth.THIN)
	crack_count = config_file.get_value(mode, "crack_count", 8)
	weathering_amt = config_file.get_value(mode, "weathering_amt", 0)

func save_config():
	config_file.set_value(mode, "item_count", item_count)
	config_file.set_value(mode, "rotation_enabled", rotation_enabled)
	config_file.set_value(mode, "bump_enabled", bump_enabled)
	config_file.set_value(mode, "crack_width", crack_width)
	config_file.set_value(mode, "crack_count", crack_count)
	config_file.set_value(mode, "weathering_amt", weathering_amt)
	config_file.save(SETTINGS_PATH)

func update_labels():
	find_child("ItemCountAmount").text = str(item_count)
	find_child("RotationAmount").text = "yes" if rotation_enabled else "no"
	find_child("BumpAmount").text = "yes" if bump_enabled else "no"
	find_child("CrackWidthAmount").text = crack_width_descs.get(crack_width, "???")
	find_child("CrackAmtAmount").text = str(crack_count)
	var weathering_label = find_child("WeatheringAmount")
	match weathering_amt:
		0: weathering_label.text = "none"
		1: weathering_label.text = "low"
		2: weathering_label.text = "medium"
		3: weathering_label.text = "high"
		4: weathering_label.text = "random"

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
	crack_width = (crack_width - 1) as CrackWidth
	if crack_width < 0:
		crack_width = (crack_width + CrackWidth.size()) as CrackWidth
	update_labels()

func _on_crack_width_increase_pressed():
	crack_width = (crack_width + 1) % CrackWidth.size() as CrackWidth
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

func _on_weathering_decrease_pressed():
	weathering_amt = (weathering_amt - 1)
	if weathering_amt < 0:
		weathering_amt += 5
	update_labels()

func _on_weathering_increase_pressed():
	weathering_amt = (weathering_amt + 1) % 5
	update_labels()

func _on_weathering_label_mouse_entered():
		hover_tooltip("Age and exposure to weather can affect decorative elements in a variety of ways.")

func _on_crack_width_label_mouse_entered():
	hover_tooltip("Adjust the thickness of the fracture lines\n\nThinner fractures fit together more perfectly, but thicker fractures allow more room for adjustment\n\nFind beauty in imperfection")

func _on_crack_amt_label_mouse_entered():
	hover_tooltip("Adjust the number of fracture lines on each item")

func _on_start_button_mouse_entered():
	if mode == "zen":
		hover_tooltip("Begin a calm and reflective meditation on imperfection\n\nNo time limit, discard fragments freely, and bring new broken items into the mix as you wish\n\nSave completed pieces to your gallery")
	else:
		hover_tooltip("Begin a frantic rush to repair what has been broken\n\nThe timer will start when you move the first fragment\n\nSave completed pieces to your gallery, along with your score")

func _on_back_button_mouse_entered():
	hover_tooltip("Return to the main menu")

func _on_start_button_pressed():
	save_config()
	var settings = {}
	match mode:
		"zen":
			settings["mode"] = "zen"
			settings[CleaningTable.CRACK_COUNT_SETTING] = crack_count
			settings[CleaningTable.ITEM_COUNT_SETTING] = item_count
			settings[CleaningTable.WEATHERING_AMT_SETTING] = weathering_amt
			var dir = DirAccess.open("user://")
			dir.remove("save.dat")
		"time":
			settings["mode"] = "time"
			settings[CleaningTable.CRACK_COUNT_SETTING] = crack_count
			settings[CleaningTable.ITEM_COUNT_SETTING] = item_count
			settings[CleaningTable.WEATHERING_AMT_SETTING] = weathering_amt
	var scene = load("res://pottery/CleaningTable.tscn")
	Global.shatter_width = crack_widths[crack_width]
	Global.rotate_with_shuffle = rotation_enabled
	Global.lock_rotation = !rotation_enabled
	Global.freeze_pieces = !bump_enabled
	Global.collide = true
	Global.click_mode = Global.ClickMode.move
	Global.next_scene_settings = settings
	Global.change_scene(scene)

