extends ColorRect
class_name ColorBlock

signal clicked()

func _ready():
	gui_input.connect(_on_gui_input)

func _on_gui_input(event:InputEvent):
	if event is InputEventMouseButton and event.is_pressed() and event.button_index == MOUSE_BUTTON_LEFT:
		clicked.emit()
