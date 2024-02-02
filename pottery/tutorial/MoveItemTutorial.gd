extends GenericTutorial

@export var desired_movement_time:float = 2.0
var orig_desired_movement_time:float 
var tween:Tween

@onready var mouse_start:Vector2 = $Mouse.position
@onready var piece2_start:Vector2 = $Piece2.position

func _ready():
	Global.tutorial_moved_item.connect(on_moved_item)
	orig_desired_movement_time = desired_movement_time
	play_animation()

func on_moved_item(_item):
	desired_movement_time -= 1.0 / Engine.get_frames_per_second()
	tutorial_step_progress.emit(1.0 - desired_movement_time / orig_desired_movement_time)
	if desired_movement_time <= 0:
		Global.tutorial_moved_item.disconnect(on_moved_item)
		tutorial_step_success.emit()

func play_animation():
	$Mouse.position = mouse_start
	$Mouse.texture = preload("res://art/mouse_none.png")
	$Piece2.position = piece2_start
	tween = create_tween()
	tween.tween_property($Mouse, "position", $MouseClickPos.position, 1.0).set_delay(0.3)
	tween.tween_property($Mouse, "texture", preload("res://art/mouse_left.png"), 0)
	tween.set_parallel(true)
	tween.tween_property($Mouse, "position", $MouseClickPos.position - ($Piece2.position - $Piece1.position), 2.0).set_delay(0.5)
	tween.tween_property($Piece2, "position", $Piece1.position, 2.0).set_delay(0.5)
	tween.set_parallel(false)
	tween.tween_property($Mouse, "texture", preload("res://art/mouse_none.png"), 0).set_delay(0.5)
	tween.tween_property($Mouse, "texture", preload("res://art/mouse_none.png"), 0).set_delay(1.0)
	await tween.finished
	call_deferred("play_animation")
