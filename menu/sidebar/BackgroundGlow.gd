extends Sprite2D

const FADE_COOLDOWN := 0.3
const FADE_TIME := 0.25

var glow_timeout:float = 1
var fade_tween:Tween

var first_button:TextureButton
var last_button:TextureButton

func _ready():
	for child in get_parent().get_children():
		if child is TextureButton:
			if first_button == null: first_button = child
			last_button = child
			child.mouse_entered.connect(self.show_glow)
			child.mouse_exited.connect(self.hide_glow)
	position = first_button.get_rect().position - Vector2(0, 60)
	position.x = 0

func show_glow():
	visible = true
	set_process(false)
	fade_to(Color.WHITE)

func stop_tween():
	if fade_tween and fade_tween.is_running():
		fade_tween.stop()

func hide_glow():
	set_process(true)
	glow_timeout = FADE_COOLDOWN
	
func _process(delta:float):
	glow_timeout -= delta
	if glow_timeout <= 0:
		set_process(false)
		fade_to(Color.TRANSPARENT)

func fade_to(color:Color):
	stop_tween()
	fade_tween = create_tween()
	fade_tween.tween_property(self, "modulate", color, FADE_TIME)
		
