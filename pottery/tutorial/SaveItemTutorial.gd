extends GenericTutorial

@export var desired_movement_time:float = 1.0
var orig_desired_movement_time:float 
var tween:Tween

func _ready():
	Global.save_to_gallery.connect(on_moved_item)
	orig_desired_movement_time = desired_movement_time
	play_animation()

func on_moved_item(item):
	desired_movement_time -= 1.0
	tutorial_step_progress.emit(1.0 - desired_movement_time / orig_desired_movement_time)
	if desired_movement_time <= 0:
		Global.save_to_gallery.disconnect(on_moved_item)
		tutorial_step_success.emit()

func play_animation():
	$AnimationPlayer.play("tutorial")
	await $AnimationPlayer.animation_finished
	call_deferred("play_animation")
