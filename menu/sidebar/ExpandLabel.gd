extends Label
class_name ExpandLabel

const REVEAL_PER_SECOND := 7.0

@onready var orig_text := text
var reveal_timer

# Called when the node enters the scene tree for the first time.
func _ready():
	text = ""
	set_process(false)

func reveal_text():
	set_process(true)
	reveal_timer = 0

func hide_text():
	text = ""
	set_process(false)
	reveal_timer = 0

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	reveal_timer += min(1.0, REVEAL_PER_SECOND * delta)
	var revealed_len = roundi(orig_text.length() * reveal_timer)
	text = orig_text.substr(0, revealed_len)
	if reveal_timer >= 1.0:
		set_process(false)
