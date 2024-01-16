extends TextureButton

var attached_panel:SlideInPanel

func _ready():
	pressed.connect(toggle_parent_slide)
	var cur_parent = get_parent()
	while cur_parent != null:
		if cur_parent is SlideInPanel:
			attached_panel = cur_parent
			break
		cur_parent = cur_parent.get_parent()
	if !cur_parent:
		push_error("Expected at least one ancestor of SlideInPanelHandle to be a SlideInPanel")
	else:
		mouse_entered.connect(func(): cur_parent.mouse_entered.emit())
		mouse_exited.connect(func(): cur_parent.mouse_exited.emit())

func toggle_parent_slide():
	attached_panel.toggle_slide()
