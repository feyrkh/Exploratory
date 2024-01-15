extends HSlider
class_name CustomMenuHSlider

func _ready():
	#drag_started.connect(_play_button_click_sound)
	drag_ended.connect(_play_button_click_sound)
	#value_changed.connect(_play_button_click_sound)
	mouse_entered.connect(_play_button_mouseover_sound)

func _play_button_mouseover_sound():
	if !editable:
		Global.play_button_mouseover_sound()

func _play_button_click_sound(arg=null):
	Global.play_button_click_sound()
