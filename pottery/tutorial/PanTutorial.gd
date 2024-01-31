extends GenericTutorial

@export var desired_movement_time:float = 2.0
var orig_desired_movement_time:float 
var tween:Tween
const HIDE_COLOR = Color(0.2, 0.2, 0.2)

@onready var mouse_start:Vector2 = $Mouse.position
@onready var camera_start:Vector2 = $MockCamera.position

func _ready():
	Global.tutorial_panned_camera.connect(on_moved_item)
	orig_desired_movement_time = desired_movement_time
	play_animation()

func on_moved_item():
	desired_movement_time -= 1.0 / Engine.get_frames_per_second()
	tutorial_step_progress.emit(1.0 - desired_movement_time / orig_desired_movement_time)
	if desired_movement_time <= 0:
		Global.tutorial_panned_camera.disconnect(on_moved_item)
		tutorial_step_success.emit()

func play_animation():
	$Mouse.position = mouse_start
	$Mouse.texture = preload("res://art/mouse_middle.png")
	$MockCamera.position = camera_start
	$Mouse.modulate = Color.WHITE
	modulate_keys(HIDE_COLOR)
	tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property($Mouse, "position", $MouseMovePos1.position, 1.0)
	tween.tween_property($MockCamera, "position", camera_start + ($MouseMovePos1.position - $Mouse.position), 1.0)
	tween.tween_property($Mouse, "position", $Mouse.position, 1).set_delay(1.2)
	tween.tween_property($MockCamera, "position", camera_start, 1).set_delay(1.2)
	await tween.finished
	tween = create_tween()
	$Mouse.texture = preload("res://art/mouse_none.png")
	$Mouse.modulate = Color.TRANSPARENT
	modulate_keys(HIDE_COLOR)
	tween.set_parallel(true)
	var delay = 0.5
	var delay_between_steps = 1
	tween.tween_property($Keys/A, "modulate", Color.WHITE, 0).set_delay(delay)
	tween.tween_property($Keys/Left, "modulate", Color.WHITE, 0).set_delay(delay)
	tween.tween_property($MockCamera, "position", camera_start + Vector2(-20, 0), delay_between_steps).set_delay(delay)
	delay += delay_between_steps
	tween.tween_property($Keys/A, "modulate", HIDE_COLOR, 0).set_delay(delay)
	tween.tween_property($Keys/Left, "modulate", HIDE_COLOR, 0).set_delay(delay)
	tween.tween_property($Keys/S, "modulate", Color.WHITE, 0).set_delay(delay)
	tween.tween_property($Keys/Down, "modulate", Color.WHITE, 0).set_delay(delay)
	tween.tween_property($MockCamera, "position", camera_start + Vector2(-20, 20), delay_between_steps).set_delay(delay)
	delay += delay_between_steps
	tween.tween_property($Keys/S, "modulate", HIDE_COLOR, 0).set_delay(delay)
	tween.tween_property($Keys/Down, "modulate", HIDE_COLOR, 0).set_delay(delay)
	tween.tween_property($Keys/D, "modulate", Color.WHITE, 0).set_delay(delay)
	tween.tween_property($Keys/Right, "modulate", Color.WHITE, 0).set_delay(delay)
	tween.tween_property($MockCamera, "position", camera_start + Vector2(0, 20), delay_between_steps).set_delay(delay)
	delay += delay_between_steps
	tween.tween_property($Keys/D, "modulate", HIDE_COLOR, 0).set_delay(delay)
	tween.tween_property($Keys/Right, "modulate", HIDE_COLOR, 0).set_delay(delay)
	tween.tween_property($Keys/W, "modulate", Color.WHITE, 0).set_delay(delay)
	tween.tween_property($Keys/Up, "modulate", Color.WHITE, 0).set_delay(delay)
	tween.tween_property($MockCamera, "position", camera_start, delay_between_steps).set_delay(delay)
	delay += delay_between_steps
	tween.tween_property($Keys/W, "modulate", HIDE_COLOR, 0).set_delay(delay)
	tween.tween_property($Keys/Up, "modulate", HIDE_COLOR, 0).set_delay(delay)
	delay += delay_between_steps
	tween.tween_property($Keys/Up, "modulate", HIDE_COLOR, 0).set_delay(delay)
	await tween.finished
	call_deferred("play_animation")

func modulate_keys(c:Color):
	for k in $Keys.get_children():
		k.modulate = c
	
	
