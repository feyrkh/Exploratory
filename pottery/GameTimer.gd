extends PanelContainer

signal time_attack_complete(total_seconds:int)

@export var piece_container:Node

@onready var label:Label = find_child("Label")
var expected_pieces:int

var time_seconds:int = 0:
	set(val):
		time_seconds = val
		find_child("Label").text = get_time_text()
		if piece_container.get_child_count() <= expected_pieces:
			complete_game()
		
var time_fraction:float = 0

func setup(piece_count:int):
	expected_pieces = piece_count

func get_time_text():
	var fragment_count := piece_container.get_child_count()
	return "%s   %d/%d fragments" % [TimeUtil.format_timer(time_seconds), fragment_count, expected_pieces]

func _ready():
	Global.first_click_received.connect(start_timer)
	set_process(false)

func start_timer():
	set_process(true)
	time_seconds = 0

func _process(delta:float):
	time_fraction += delta
	if time_fraction > 1:
		time_fraction -= 1
		time_seconds += 1

func complete_game():
	time_attack_complete.emit(time_seconds)
	set_process(false)
	label.text = get_time_text()
	var win_label = find_child("WinLabel")
	win_label.text = "Completed! You may save items to your gallery or press escape to move on."
	win_label.visible = true
	var win_button = find_child("WinButton")
	win_button.visible = true
