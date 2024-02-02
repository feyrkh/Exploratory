extends GenericTutorial

@export var desired_movement_time:float = 1.0
var orig_desired_movement_time:float 
var tween:Tween
var is_rotating = false
var start_rot

@onready var mouse_start:Vector2 = $Mouse.position
@onready var piece1_start:Vector2 = $Piece1.position

func _ready():
	Global.tutorial_rotated_item.connect(on_moved_item)
	orig_desired_movement_time = desired_movement_time
	play_animation()

func on_moved_item(_item):
	desired_movement_time -= 1.0 / Engine.get_frames_per_second()
	tutorial_step_progress.emit(1.0 - desired_movement_time / orig_desired_movement_time)
	if desired_movement_time <= 0:
		Global.tutorial_rotated_item.disconnect(on_moved_item)
		tutorial_step_success.emit()

func play_animation():
	$Mouse.position = mouse_start
	$Mouse.texture = preload("res://art/mouse_none.png")
	$Piece1.position = piece1_start
	$Piece1.rotation = 0
	start_rot = $Piece1.position.angle_to_point($MouseClickPos.position)
	tween = create_tween()
	tween.tween_property($Mouse, "position", $MouseClickPos.position, 1.0).set_delay(0.3)
	tween.tween_property($Mouse, "texture", preload("res://art/mouse_right.png"), 0)
	tween.set_parallel(true)
	tween.tween_property(self, "is_rotating", true, 0)
	tween.tween_property($Mouse, "position", $MouseRotatePos.position, 1.0).set_delay(0.5)
	#tween.tween_property($Piece1, "rotation", total_rot, 2.0).set_delay(0.5)
	tween.set_parallel(false)
	tween.tween_property(self, "is_rotating", true, 0)
	tween.tween_property($Mouse, "position", $MouseClickPos.position, 1.0).set_delay(0.5)
	tween.tween_property($Mouse, "position", $MouseRotatePos2.position, 1.0).set_delay(0.5)
	tween.tween_property($Mouse, "position", $MouseClickPos.position, 1.0).set_delay(0.5)
	tween.tween_property(self, "is_rotating", false, 0)
	tween.tween_property($Mouse, "texture", preload("res://art/mouse_none.png"), 0).set_delay(0.5)
	tween.tween_property($Mouse, "texture", preload("res://art/mouse_none.png"), 0).set_delay(1.0)
	await tween.finished
	call_deferred("play_animation")

func _process(_delta):
	if is_rotating:
		var end_rot = $Piece1.position.angle_to_point($Mouse.position)
		var final_rot = end_rot - start_rot
		$Piece1.rotation = final_rot
