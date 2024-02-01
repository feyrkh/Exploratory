extends Control

@export var tutorial_steps := [
	"res://pottery/tutorial/MoveItemTutorial.tscn",
	"res://pottery/tutorial/RotateItemTutorial.tscn",
	"res://pottery/tutorial/SafeMoveItemTutorial.tscn",
	"res://pottery/tutorial/ZoomTutorial.tscn",
	"res://pottery/tutorial/PanTutorial.tscn",
	"res://pottery/tutorial/GlueTutorial.tscn",
	"res://pottery/tutorial/MoveOptionsTutorial.tscn",
	"res://pottery/tutorial/SaveItemTutorial.tscn",
]

var cur_tutorial_idx := -1
var cur_tutorial:GenericTutorial
@onready var progress:ProgressBar = find_child("ProgressBar")

# Called when the node enters the scene tree for the first time.
func _ready():
	if Global.game_mode != "relax" or Global.has_completed_relax_tutorial:
		visible = false
		queue_free()
		return
	show_next_step()
	find_child("NextButton").pressed.connect(next_button_pressed)

func show_next_step():
	if cur_tutorial:
		cur_tutorial.queue_free()
	cur_tutorial_idx += 1
	if cur_tutorial_idx >= tutorial_steps.size():
		return
	if cur_tutorial_idx == tutorial_steps.size() - 1:
		find_child("NextButton").text = "Finish"
	else:
		find_child("NextButton").text = "Next"
	find_child("NextButton").disabled = true
	progress.visible = false
	cur_tutorial = load(tutorial_steps[cur_tutorial_idx]).instantiate()
	cur_tutorial.tutorial_step_success.connect(cur_step_complete)
	cur_tutorial.tutorial_step_progress.connect(on_tutorial_step_progress)
	find_child("TutorialContent").add_child(cur_tutorial)

func cur_step_complete():
	find_child("NextButton").disabled = false

func next_button_pressed():
	if cur_tutorial_idx >= tutorial_steps.size() - 1:
		queue_free()
		Global.has_completed_relax_tutorial = true
	else:
		show_next_step()

func on_tutorial_step_progress(amt:float):
	progress.visible = true
	progress.value = amt
