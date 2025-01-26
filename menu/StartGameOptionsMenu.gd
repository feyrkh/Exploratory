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
var mode := "relax"
var difficulty_button_group := ButtonGroup.new()
var cur_selected_button:Button
var hover_deselect_timer:float = 0

@onready var custom_difficulty_button:DifficultyMode = find_child("CustomDifficultyButton")
@onready var difficulty_name:Label = find_child("DifficultyName")
@onready var item_count_icon = find_child("ItemCountIcon")
@onready var item_count_icon_amt:Label = find_child("ItemCountIconAmt")
@onready var crack_count_icon = find_child("CrackCountIcon")
@onready var crack_count_icon_amt:Label = find_child("CrackCountIconAmt")
@onready var rotate_icon:TextureRect = find_child("RotateIcon")
@onready var bump_icon:TextureRect = find_child("BumpIcon")
@onready var weathering_icon = find_child("WeatheringIcon")
@onready var crack_size_icon = find_child("CrackSizeIcon")

func _notification(what):
	if what == NOTIFICATION_WM_MOUSE_EXIT:
		hide_tooltip()

func _ready():
	custom_difficulty_button = find_child("CustomDifficultyButton")
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
			child.mouse_exited.connect(prepare_to_show_default_description)
			if child != custom_difficulty_button:
				child.mouse_entered.connect(show_difficulty_description.bind(child.settings))
				child.pressed.connect(select_difficulty.bind(child))
			else:
				custom_difficulty_button.pressed.connect(select_custom_difficulty)
				child.mouse_entered.connect(show_custom_difficulty_description)
				
	find_child("CustomOptionPanel").visible = false
	find_child("BundleExplanationPanel").visible = true
	
	setup_tooltip("ItemCountIcon", func(): return "Number of shattered items\nMore items can be added freely in relax mode" if mode=="relax" else "Number of shattered items\nGame ends when this many fragments remain in struggle mode")
	setup_tooltip("CrackCountIcon", func(): return "Number of cracks per item")
	setup_tooltip("CrackSizeIcon", func(): 
		if cur_selected_button == null: return ""
		match cur_selected_button.settings.crack_width:
			0: return "Hairline cracks\nPieces will fit together almost seamlessly\nVery little glue may be visible"
			1: return "Thin cracks\nPieces will fit together easily"
			2: return "Medium cracks\nMore material will be removed\nMore room for mistakes"
			3: return "Thick cracks\nCareful positioning is required to avoid poor joins"
	)
	setup_tooltip("WeatheringIcon", func():
		match cur_selected_button.settings.weathering_amt:
			0: return "Pristine condition, no weathering"
			1: return "Lightly weathered condition\nDecorations may have a more used appearance"
			2: return "Moderately weathered condition\nDecorations may be noticeably degraded due to wear"
			3: return "Heavily weathered condition\nDecorations may be nearly unrecognizable due to wear"
	)
	setup_tooltip("BumpIcon", func():
		if cur_selected_button == null: return ""
		var msg = "Items will not move when bumped\nUse the 'avoid collision' button to move fragments through each other" if !cur_selected_button.settings.bump_enabled else "Items will move when bumped\nUse the 'avoid collision' button to move fragments through each other"
		if mode == "relax":
			msg += "\nThis setting can be freely changed in relax mode"
		return msg)
	setup_tooltip("RotateIcon", func(): 
		if cur_selected_button == null: return ""
		var msg = "Items will not rotate when bumped\nItems will not require rotation to assemble" if !cur_selected_button.settings.rotation_enabled else "Items may rotate when bumped\nItems will require rotation to assemble"
		if mode == "relax":
			msg += "\nThis setting can be freely changed in relax mode"
		return msg)

func show_custom_difficulty_description():
	custom_difficulty_button = find_child("CustomDifficultyButton")
	update_labels()
	show_difficulty_description(custom_difficulty_button.settings)
	find_child("BundleExplanationPanel").visible = false
	find_child("CustomOptionPanel").visible = true

func setup_tooltip(child_name, msg_callback:Callable):
		var child = find_child(child_name)
		child.mouse_entered.connect(show_tooltip.bind(msg_callback, child))
		child.mouse_exited.connect(hide_tooltip)

func show_tooltip(msg_callback, target):
	find_child("HoverDescription").text = ""
	var tooltip:PanelContainer = find_child("Tooltip")
	tooltip.visible = false
	tooltip.find_child("TooltipLabel").hide()
	tooltip.size = Vector2(10, 10)
	tooltip.find_child("TooltipLabel").text = msg_callback.call()
	tooltip.find_child("TooltipLabel").show()
	await get_tree().process_frame
	tooltip.visible = true
	var tooltip_rect = tooltip.get_rect()
	print("target size: ", target.size)
	tooltip.global_position = target.global_position + Vector2(-tooltip_rect.size.x / 2.0, -(tooltip_rect.size.y)) + Vector2(target.get_rect().size.x/2.0, 0)
	if tooltip.global_position.x < find_child("BundleExplanationPanel").global_position.x + 30:
		tooltip.global_position.x = find_child("BundleExplanationPanel").global_position.x + 30
	if get_viewport_rect().size.x < tooltip.get_rect().size.x + tooltip.global_position.x + 40:
		tooltip.global_position.x -= (tooltip.get_rect().size.x + tooltip.global_position.x) - get_viewport_rect().size.x + 40

func hide_tooltip():
	find_child("Tooltip").visible = false
	
func reset():
	for child in find_child("DifficultyLevels").get_children():
		child.button_pressed = false
	custom_difficulty_button = null
	cur_selected_button = null
	find_child("StartButton").visible = false
	show_difficulty_description(null)

func _process(delta:float):
	hover_deselect_timer -= delta
	if hover_deselect_timer <= 0:
		set_process(false)
		show_default_difficulty_description()

func select_difficulty(btn:Button):
	find_child("CustomOptionPanel").visible = false
	find_child("BundleExplanationPanel").visible = true
	cur_selected_button = btn
	show_difficulty_description(btn.settings)
	item_count = btn.settings.item_count
	rotation_enabled = btn.settings.rotation_enabled
	bump_enabled = btn.settings.bump_enabled
	crack_width = btn.settings.crack_width
	crack_count = btn.settings.crack_count
	weathering_amt = btn.settings.weathering_amt

func select_custom_difficulty():
	save_config()
	find_child("CustomOptionPanel").visible = true
	find_child("BundleExplanationPanel").visible = false
	cur_selected_button = custom_difficulty_button
	load_config()
	update_labels()
	show_default_difficulty_description()

func show_difficulty_description(settings:GameSettings):
	set_process(false)
	find_child("BundleExplanationPanel").visible = true
	find_child("CustomOptionPanel").visible = false
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
		set_crack_size_texture(crack_size_icon, settings)
		set_weathering_texture(weathering_icon, settings)
		set_rotation_texture(rotate_icon, settings)
		set_bump_texture(bump_icon, settings)
	find_child("StartButton").visible = cur_selected_button != null

func set_rotation_texture(_rotate_icon, settings):
	if settings.rotation_enabled:
		_rotate_icon.texture = preload("res://art/sidebar menu/sidebar_icon_rotate-on.png")
	else:
		_rotate_icon.texture = preload("res://art/sidebar menu/sidebar_icon_rotate-off.png")

func set_bump_texture(_bump_icon, settings):
	if settings.bump_enabled:
		_bump_icon.texture = preload("res://art/sidebar menu/sidebar_icon_movement-on.png")
	else:
		_bump_icon.texture = preload("res://art/sidebar menu/sidebar_icon_movement-off.png")

func set_crack_size_texture(_crack_size_icon, settings):
	match settings.crack_width:
		0: _crack_size_icon.texture = preload("res://art/mode select/ui_mode-select_CrackWidth-1.png")
		1: _crack_size_icon.texture = preload("res://art/mode select/ui_mode-select_CrackWidth-2.png")
		2: _crack_size_icon.texture = preload("res://art/mode select/ui_mode-select_CrackWidth-3.png")
		3: _crack_size_icon.texture = preload("res://art/mode select/ui_mode-select_CrackWidth-4.png")

func set_weathering_texture(_weathering_icon, settings):
	match settings.weathering_amt:
		0: _weathering_icon.texture = preload("res://art/mode select/ui_mode-select_Weathering-1.png")
		1: _weathering_icon.texture = preload("res://art/mode select/ui_mode-select_Weathering-2.png")
		2: _weathering_icon.texture = preload("res://art/mode select/ui_mode-select_Weathering-3.png")
		3: _weathering_icon.texture = preload("res://art/mode select/ui_mode-select_Weathering-4.png")
		4: _weathering_icon.texture = preload("res://art/mode select/ui_mode-select_Weathering-random.png")

func prepare_to_show_default_description():
	set_process(true)
	hover_deselect_timer = 0.15

func show_default_difficulty_description():
	if cur_selected_button != null:
		if cur_selected_button == custom_difficulty_button:
			show_custom_difficulty_description()
		else:
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
	show_default_difficulty_description()

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
	if !custom_difficulty_button: return
	custom_difficulty_button.settings.item_count = item_count
	custom_difficulty_button.settings.rotation_enabled = rotation_enabled
	custom_difficulty_button.settings.bump_enabled = bump_enabled
	custom_difficulty_button.settings.crack_width = crack_width
	custom_difficulty_button.settings.crack_count = crack_count
	custom_difficulty_button.settings.weathering_amt = weathering_amt
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
	set_bump_texture(find_child("CustomBumpIcon"), custom_difficulty_button.settings)
	set_rotation_texture(find_child("CustomRotationIcon"), custom_difficulty_button.settings)
	set_weathering_texture(find_child("CustomWeatheringIcon"), custom_difficulty_button.settings)
	set_crack_size_texture(find_child("CustomCrackSizeIcon"), custom_difficulty_button.settings)
	item_count_icon_amt.text = str(custom_difficulty_button.settings.item_count)
	crack_count_icon_amt.text = str(custom_difficulty_button.settings.crack_count)
	set_crack_size_texture(crack_size_icon, custom_difficulty_button.settings)
	set_weathering_texture(weathering_icon, custom_difficulty_button.settings)
	set_rotation_texture(rotate_icon, custom_difficulty_button.settings)
	set_bump_texture(bump_icon, custom_difficulty_button.settings)

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
		"relax": min_allowed = 0
		"struggle": min_allowed = 5
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
	hover_tooltip("Change how many items are generated for you to reassemble.\nThe fragments will be mixed together - add more items for a greater challenge!")

func _on_rotation_label_mouse_entered():
	if !rotation_enabled:
		hover_tooltip("Fragments will not rotate when they collide with other pieces that you are moving\nWhen shuffled, fragments will always be oriented so that they will fit together without rotation\nAn easier, more meditative experience")
	else:
		hover_tooltip("Fragments may rotate when they collide with other pieces that you are moving\nWhen shuffled, fragments will be randomly oriented, and you will need to rotate to fit them together\nA more engaging experience")

func _on_bump_label_mouse_entered():
	if !bump_enabled:
		hover_tooltip("Fragments will not move when bumped by a piece you are moving\nHold 'shift' to temporarily disable fragment collision if you need to move one piece through another")
	else:
		hover_tooltip("Fragments will be bumped out of the way by a piece you are moving\nTake care when fitting pieces together\nHold 'shift' to temporarily disable fragment collision if you need to move one piece through another")

func _on_weathering_decrease_pressed():
	weathering_amt = (weathering_amt - 1)
	if weathering_amt < 0:
		weathering_amt += 5
	update_labels()

func _on_weathering_increase_pressed():
	weathering_amt = (weathering_amt + 1) % 5
	update_labels()

func _on_weathering_label_mouse_entered():
		hover_tooltip("\nAge and exposure to weather can affect decorative elements in a variety of ways.")

func _on_crack_width_label_mouse_entered():
	hover_tooltip("Adjust the thickness of the fracture lines\nThinner fractures fit together more perfectly, but thicker fractures allow more room for adjustment\nFind beauty in imperfection")

func _on_crack_amt_label_mouse_entered():
	hover_tooltip("\nAdjust the number of fracture lines on each item")

func _on_start_button_mouse_entered():
	if mode == "relax":
		hover_tooltip("Begin a calm and reflective meditation on imperfection\nNo time limit, discard fragments freely, and bring new broken items into the mix as you wish\nSave completed pieces to your gallery")
	else:
		hover_tooltip("Begin a frantic rush to repair what has been broken\nThe timer will start when you move the first fragment\nSave completed pieces to your gallery, along with your score")

func _on_back_button_mouse_entered():
	hover_tooltip("\nReturn to the main menu")

func _on_start_button_pressed():
	save_config()
	var settings = {}
	match mode:
		"relax":
			settings["mode"] = "relax"
			settings[CleaningTable.CRACK_COUNT_SETTING] = crack_count
			settings[CleaningTable.ITEM_COUNT_SETTING] = item_count
			settings[CleaningTable.WEATHERING_AMT_SETTING] = weathering_amt
			var dir = DirAccess.open("user://")
			dir.remove("save.dat")
		"struggle":
			settings["mode"] = "struggle"
			settings[CleaningTable.CRACK_COUNT_SETTING] = crack_count
			settings[CleaningTable.ITEM_COUNT_SETTING] = item_count
			settings[CleaningTable.WEATHERING_AMT_SETTING] = weathering_amt
	Global.game_mode = settings.get("mode", "relax")
	Global.shatter_width = crack_widths[crack_width]
	Global.rotate_with_shuffle = rotation_enabled
	Global.lock_rotation = !rotation_enabled
	Global.freeze_pieces = !bump_enabled
	Global.collide = true
	Global.click_mode = Global.ClickMode.move
	Global.next_scene_settings = settings
	var scene = load("res://pottery/CleaningTable.tscn")
	Global.change_scene(scene)
