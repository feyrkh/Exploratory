extends Control

signal exited()

const MAX_RECENTLY_USED := 35

@onready var allowed_colors_container := find_child("AllowedColorsContainer")
@onready var available_colors_container := find_child("AvailableColorsContainer")
@onready var color_picker := find_child("ColorPicker")
@onready var example_item := find_child("ExampleItem")

@onready var base_item_list := ItemBuilder.base_item_names
var decoration_item_list:Array
var cur_item_color_option := 0
var cur_item_name:String
var cur_item_data:ItemBuilder.ItemConfig
var colors_modified:bool = false

func _ready():
	decoration_item_list = ItemBuilder.all_items.keys()
	for n in base_item_list:
		decoration_item_list.erase(n)
	decoration_item_list.sort()
	color_picker.color_changed.connect(show_color)
	color_picker.color_chosen.connect(add_allowed_color)
	show_cur_item()
	render_recently_used_colors()

func show_cur_item():
	if colors_modified: 
		colors_modified = false
		ColorMgr.save()
	var total_items = base_item_list.size() + decoration_item_list.size()
	if cur_item_color_option < 0:
		cur_item_color_option += total_items
	cur_item_color_option = cur_item_color_option % total_items
	if cur_item_color_option < base_item_list.size():
		cur_item_name = base_item_list[cur_item_color_option]
	else:
		cur_item_name = decoration_item_list[cur_item_color_option - base_item_list.size()]
	cur_item_data = ItemBuilder.all_items[cur_item_name]
	find_child("ExampleItem").texture = cur_item_data.get_texture()
	find_child("ExampleItemShadow").texture = cur_item_data.get_shadow_texture()
	find_child("EnabledCheckbox").button_pressed = !ItemBuilder.get_item_disabled(cur_item_name)
	render_allowed_colors()

func render_allowed_colors():
	for c in allowed_colors_container.get_children():
		c.queue_free()
	var allowed = ColorMgr.get_colors_for_item(cur_item_name)
	allowed.sort_custom(hue_sort)
	for c:Color in allowed:
		render_allowed_color(c)

func render_allowed_color(c:Color):
	var block = preload("res://menu/item_color_settings/ColorBlock.tscn").instantiate()
	block.color = c
	allowed_colors_container.add_child(block)
	block.mouse_entered.connect(func():
		show_color(c)
		block.set_label("x")
	)
	block.mouse_exited.connect(func():
		show_default_color()
		block.set_label("")
	)
	block.clicked.connect(remove_allowed_color.bind(c))

func render_recently_used_colors():
	var colors = ColorMgr.get_recently_used_colors()
	for c in colors:
		render_recently_used_color(c)

func render_recently_used_color(c:Color):
	for child in available_colors_container.get_children():
		if child.color.is_equal_approx(c):
			child.queue_free()
	var block = preload("res://menu/item_color_settings/ColorBlock.tscn").instantiate()
	block.color = c
	available_colors_container.add_child(block)
	available_colors_container.move_child(block, 0)
	block.mouse_entered.connect(func():
		show_color(c)
		block.set_label("+")
	)
	block.mouse_exited.connect(func():
		show_default_color()
		block.set_label("")
	)
	block.clicked.connect(add_allowed_color.bind(c))
	while available_colors_container.get_child_count() > MAX_RECENTLY_USED:
		available_colors_container.get_child(-1).queue_free()
		available_colors_container.remove_child(available_colors_container.get_child(-1))

func show_color(c:Color):
	example_item.modulate = c

func show_default_color():
	var c = color_picker.color
	example_item.modulate = c

func hue_sort(a:Color, b:Color):
	if a.h != b.h: return a.h < b.h
	if a.s != b.s: return a.s < b.s
	return a.v < b.v

func remove_allowed_color(c:Color):
	var cur_allowed_colors = ColorMgr.get_colors_for_item(cur_item_name)
	if cur_allowed_colors.size() == 1:
		return
	ColorMgr.remove_color_from_item(cur_item_name, c)
	Global.play_button_click_sound("menu_back")
	for child in allowed_colors_container.get_children():
		if child.color == c:
			child.queue_free()
			break
	if ColorMgr.get_colors_for_item(cur_item_name).size() == 0:
		ColorMgr.add_color_to_item(cur_item_name, c)
		add_allowed_color(Color.WHITE)
	add_recently_used_color(c)
	
func add_recently_used_color(c:Color):
	ColorMgr.add_recently_used_color(c, MAX_RECENTLY_USED)
	render_recently_used_color(c)

func add_allowed_color(c:Color):
	for child in allowed_colors_container.get_children():
		if child.color == c:
			Global.play_button_click_sound("menu_back")
			return
	ColorMgr.add_color_to_item(cur_item_name, c)
	render_allowed_color(c)
	add_recently_used_color(c)
	Global.play_button_click_sound()

func _on_reset_button_pressed():
	Global.play_button_click_sound()
	ColorMgr.clear_colors_for_item(cur_item_name)
	colors_modified = true
	find_child("EnabledCheckbox").button_pressed = true
	show_cur_item()

func _on_next_button_pressed():
	ColorMgr.save()
	cur_item_color_option += 1
	Global.play_button_click_sound()
	show_cur_item()

func _on_prev_button_pressed():
	ColorMgr.save()
	cur_item_color_option -= 1
	Global.play_button_click_sound()
	show_cur_item()

func _on_enabled_checkbox_toggled(toggled_on):
	ItemBuilder.set_item_disabled(cur_item_name, !toggled_on)
