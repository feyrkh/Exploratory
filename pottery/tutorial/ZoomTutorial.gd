extends GenericTutorial

@export var desired_movement_time:float = 1.0
var orig_desired_movement_time:float 
var tween:Tween
const HIDE_COLOR = Color(0.2, 0.2, 0.2)

@onready var mouse_start:Vector2 = $Mouse.position
@onready var piece1_start:Vector2 = $Piece1.scale

func _ready():
	Global.camera_zoom_changed.connect(on_moved_item)
	orig_desired_movement_time = desired_movement_time
	play_animation()

func on_moved_item(item):
	desired_movement_time -= 0.25
	tutorial_step_progress.emit(1.0 - desired_movement_time / orig_desired_movement_time)
	if desired_movement_time <= 0:
		Global.camera_zoom_changed.disconnect(on_moved_item)
		tutorial_step_success.emit()

func play_animation():
	$AnimationPlayer.play("glue_tutorial")
	await $AnimationPlayer.animation_finished
	call_deferred("play_animation")
