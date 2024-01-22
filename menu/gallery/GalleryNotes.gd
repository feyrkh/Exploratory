extends PanelContainer
class_name GalleryNotes

func _ready():
	dim_notes()
	Global.item_highlighted.connect(update_notes)
	Global.item_unhighlighted.connect(dim_notes)

func update_notes(item:ArcheologyItem):
	set_process(true)
	visible = true
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

func dim_notes(_arg=null):
	visible = false
	set_process(false)

func _process(_delta:float):
	if !visible:
		set_process(false)
	var mouse_x = get_global_mouse_position().x
	if mouse_x < 640:
		position.x = 1280 - get_rect().size.x - 5
	else:
		position.x = 5
