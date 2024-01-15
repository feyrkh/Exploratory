extends SlideInPanel
class_name ControlHints

var first_frame_showing := true
var hint_data:Array # [label, frame1 texture, frame2 texture]
var hints_loaded := false

func _ready():
	_on_mouse_exited()

func set_hints(hint_data:Array): 
	hints_loaded = false
	var container = find_child("HintContainer")
	for child in container.get_children():
		child.queue_free()
	self.hint_data = hint_data
	if !is_hidden():
		load_hints()
	first_frame_showing = true

func load_hints():
	if hints_loaded:
		return
	hints_loaded = true
	var container = find_child("HintContainer")
	for data in hint_data:
		var new_label := preload("res://control_hints/HintLabel.tscn").instantiate()
		new_label.text = data[0]
		var new_icon := preload("res://control_hints/HintIcon.tscn").instantiate()
		new_icon.texture = data[1]
		container.add_child(new_label)
		container.add_child(new_icon)

func toggle_frames():
	if position == start_pos:
		return
	first_frame_showing = !first_frame_showing
	var container = find_child("HintContainer")
	var i = 0
	for child in container.get_children():
		if child is TextureRect:
			child.texture = hint_data[i][1 if first_frame_showing else 2]
			i += 1

func _on_timer_timeout():
	toggle_frames()

func slide_in(override_time=null):
	if is_hidden():
		load_hints()
	super.slide_in(override_time)

func _on_mouse_entered():
	modulate = Color(1, 1, 1, 1)
	$Timer.paused = false

func _on_mouse_exited():
	modulate = Color(1, 1, 1, 0.5)
	$Timer.paused = true
	first_frame_showing = false
	toggle_frames()

func _gui_input(event):
	if event.is_action_pressed("left_click"):
		toggle_slide()
