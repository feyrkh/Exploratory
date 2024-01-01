extends ColorRect

signal finished

func fade_out(fade_time:float):
	if visible == false:
		var fadeout := create_tween()
		modulate = Color(0, 0, 0, 0)
		visible = true
		fadeout.tween_property(self, "modulate", Color.BLACK, fade_time)
		await fadeout.finished
		await get_tree().process_frame
	finished.emit()

func fade_in(fade_time:float):
	if visible == true:
		await get_tree().process_frame
		var fadeout = create_tween()
		modulate = Color.BLACK
		fadeout.tween_property(self, "modulate", Color(0, 0, 0, 0), fade_time*2)
		await fadeout.finished
		visible = false
		finished.emit()
