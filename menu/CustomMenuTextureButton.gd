extends TextureButton
class_name CustomMenuTextureButton

const HIGHLIGHT_COLOR := Color("f2f77d")
const PRESS_COLOR := Color("f2f77d", 5.0)
var tween:Tween

func _ready():
	pressed.connect(_play_button_click_sound)
	pressed.connect(_glow)
	mouse_entered.connect(_play_button_mouseover_sound)
	mouse_entered.connect(_highlight)
	mouse_exited.connect(_unhighlight)

func _notification(what):
	if what == NOTIFICATION_WM_MOUSE_EXIT:
		_unhighlight()

func _glow():
	if tween:
		tween.stop()
	tween = create_tween()
	tween.set_ease(Tween.EASE_OUT)
	self_modulate = PRESS_COLOR
	tween.tween_property(self, "self_modulate", Color.WHITE, .8)

func _unhighlight():
	modulate = Color.WHITE

func _highlight():
	modulate = HIGHLIGHT_COLOR


func _play_button_mouseover_sound():
	if !disabled:
		Global.play_button_mouseover_sound()

func _play_button_click_sound():
	Global.play_button_click_sound()
