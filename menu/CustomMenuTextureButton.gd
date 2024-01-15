extends TextureButton
class_name CustomMenuTextureButton

func _ready():
	pressed.connect(_play_button_click_sound)
	mouse_entered.connect(_play_button_mouseover_sound)

func _play_button_mouseover_sound():
	if !disabled:
		Global.play_button_mouseover_sound()

func _play_button_click_sound():
	Global.play_button_click_sound()
