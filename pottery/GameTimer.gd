extends PanelContainer

signal time_attack_complete

@export var piece_container:Node

@onready var label:Label = find_child("Label")
var expected_pieces:int

var time_seconds:int = 0:
	set(val):
		time_seconds = val
		$Label.text = get_time_text()
		if piece_container.get_child_count() <= expected_pieces:
			complete_game()
		
var time_fraction:float = 0

func setup(piece_count:int):
	expected_pieces = piece_count

func get_time_text():
	var hours:int = time_seconds / 3600
	var mins:int = time_seconds / 60
	var secs:int = time_seconds % 60
	var fragment_count := piece_container.get_child_count()
	if hours > 0:
		return "%d:%02d:%02d   %d/%d fragments" % [hours, mins, secs, fragment_count, expected_pieces]
	else:
		return "%02d:%02d   %d/%d fragments" % [mins, secs, fragment_count, expected_pieces]

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
	time_attack_complete.emit()
	set_process(false)
	label.text = get_time_text() + "Completed! You may save items to your gallery or press escape to move on."
