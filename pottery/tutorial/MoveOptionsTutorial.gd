extends GenericTutorial

@export var desired_movement_time:float = 1.0
var orig_desired_movement_time:float 
var tween:Tween
var loop_num:int = 0

func _ready():
	Global.tutorial_move_option_toggled.connect(on_moved_item)
	orig_desired_movement_time = desired_movement_time
	play_animation()

func on_moved_item():
	desired_movement_time -= 1.0
	tutorial_step_progress.emit(1.0 - desired_movement_time / orig_desired_movement_time)
	if desired_movement_time <= 0:
		Global.tutorial_move_option_toggled.disconnect(on_moved_item)
		tutorial_step_success.emit()

func play_animation():
	$AnimationPlayer.play("tutorial"+str(loop_num+1))
	loop_num += 1
	if loop_num >= 3:
		loop_num = 0
	await $AnimationPlayer.animation_finished
	#$AnimationPlayer.play("RESET")
	#await $AnimationPlayer.animation_finished
	call_deferred("play_animation")
