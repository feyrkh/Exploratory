extends Panel

var color_settings:SettingsFile = SettingsFile.new("user://glue_colors.cfg")

@onready var color_picker:ColorPicker = find_child("ColorPicker")
@onready var color_picker_window = find_child("ColorPickerWindow")
var colors_updated = false
var cur_selected_glue_pot = null

func _ready():
	Global.click_mode_changed.connect(check_panel_closed)
	Global.toggle_glue_panel.connect(toggle_panel)
	var glue_idx = 0
	var record_glue_colors = false
	var cur_glue_colors = color_settings.get_config("glue_colors", null)
	if cur_glue_colors == null:
		cur_glue_colors = []
		record_glue_colors = true
	for child in get_children():
		if child is GluePot:
			child.gui_input.connect(glue_input.bind(child))
			if record_glue_colors:
				cur_glue_colors.append(child.get_glue_color())
			else:
				if cur_glue_colors.size() >= glue_idx:
					child.set_glue_color(cur_glue_colors[glue_idx])
				if glue_idx == 0:
					Global.glue_color = child.get_glue_color()
			glue_idx += 1
	update_glue_pot_highlights()
	color_picker.color_changed.connect(update_current_color)

func update_current_color(c:Color):
	if cur_selected_glue_pot == null:
		return
	cur_selected_glue_pot.set_glue_color(c)
	Global.glue_color = c
	colors_updated = true
	

func record_glue_colors():
	if colors_updated:
		var cur_glue_colors = []
		for child in get_children():
			if child is GluePot:
				cur_glue_colors.append(child.get_glue_color())
		color_settings.set_config("glue_colors", cur_glue_colors)
		color_settings.save_config()
		colors_updated = false

func glue_input(event:InputEvent, glue_pot:GluePot):
	if event is InputEventMouseButton and event.is_action_pressed("left_click"):
		Global.glue_color = glue_pot.get_glue_color()
		update_glue_pot_highlights()

func check_panel_closed():
	if Global.click_mode == Global.ClickMode.glue:
		open_panel()
	else:
		close_panel()

func open_panel():
	visible = true
	update_glue_pot_highlights()

func update_glue_pot_highlights():
	for child in get_children():
		if child is GluePot:
			if child.get_glue_color().is_equal_approx(Global.glue_color):
				child.highlight()
				cur_selected_glue_pot = child
			else:
				child.unhighlight()

func close_panel():
	record_glue_colors()
	color_picker_window.slide_out(0)
	visible = false
	
func toggle_panel():
	visible = !visible
	if visible:
		Global.click_mode = Global.ClickMode.glue
	else:
		Global.click_mode = Global.ClickMode.move
