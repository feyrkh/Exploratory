extends SlideInPanel
class_name GalleryNotes

func _ready():
	dim_notes()
	Global.item_highlighted.connect(update_notes)
	Global.item_unhighlighted.connect(dim_notes)
	mouse_exited.connect(dim_notes)

func update_notes(item:ArcheologyItem):
	if item != null:
		var show_struggle_data:bool = item.game_mode == "struggle"
		find_child("TimeLabel").visible = show_struggle_data
		find_child("Time").visible = show_struggle_data
		find_child("ScoreLabel").visible = show_struggle_data
		find_child("Score").visible = show_struggle_data
		find_child("Date").text = item.save_timestamp.substr(0, 10)
		find_child("Mode").text = item.game_mode
		find_child("Time").text = TimeUtil.format_timer(item.time_attack_seconds)
		find_child("Score").text = str(item.final_score)
		modulate = Color(1, 1, 1, 1)

func _on_mouse_entered():
	modulate = Color(1, 1, 1, 1)
	$Timer.paused = false

func dim_notes(_arg=null):
	modulate = Color(1, 1, 1, 0.5)

func _gui_input(event):
	if event.is_action_pressed("left_click"):
		toggle_slide()
