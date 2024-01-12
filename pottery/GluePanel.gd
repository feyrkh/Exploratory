extends Panel

func _ready():
	Global.click_mode_changed.connect(check_panel_closed)
	Global.toggle_glue_panel.connect(toggle_panel)
	for child in get_children():
		if child is GluePot:
			child.gui_input.connect(glue_input.bind(child))

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
			if child.get_glue_color() == Global.glue_color:
				child.highlight()
			else:
				child.unhighlight()

func close_panel():
	visible = false
	
func toggle_panel():
	visible = !visible
	if visible:
		Global.click_mode = Global.ClickMode.glue
	else:
		Global.click_mode = Global.ClickMode.move
