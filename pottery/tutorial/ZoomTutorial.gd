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

func on_moved_item(_item):
	desired_movement_time -= 0.25
	tutorial_step_progress.emit(1.0 - desired_movement_time / orig_desired_movement_time)
	if desired_movement_time <= 0:
		Global.camera_zoom_changed.disconnect(on_moved_item)
		tutorial_step_success.emit()

func play_animation():
	$Mouse.position = mouse_start
	$Mouse.texture = preload("res://art/mouse_none.png")
	$Piece1.scale = piece1_start
	$Mouse.modulate = Color.WHITE
	$E.modulate = HIDE_COLOR
	$Q.modulate = HIDE_COLOR
	tween = create_tween()
	tween.tween_property($Mouse, "texture", preload("res://art/mouse_scroll_down.png"), 0).set_delay(0.5)
	tween.tween_property($Piece1, "scale", piece1_start * 0.5, 2.0)
	tween.tween_property($Mouse, "texture", preload("res://art/mouse_scroll_up.png"), 0).set_delay(0.5)
	tween.tween_property($Piece1, "scale", piece1_start, 2.0)
	tween.tween_property($Mouse, "texture", preload("res://art/mouse_none.png"), 0).set_delay(0.5)
	tween.tween_property($Mouse, "texture", preload("res://art/mouse_none.png"), 0).set_delay(1.0)
	tween.tween_property($Mouse, "modulate", HIDE_COLOR, 0)
	tween.tween_property($Q, "modulate", Color.WHITE, 0)
	tween.tween_property($Piece1, "scale", piece1_start * 0.5, 2.0)
	tween.tween_property($Q, "modulate", HIDE_COLOR, 0)
	tween.tween_property($E, "modulate", Color.WHITE, 0)
	tween.tween_property($Piece1, "scale", piece1_start, 2.0)
	tween.tween_property($E, "modulate", HIDE_COLOR, 0)
	await tween.finished
	call_deferred("play_animation")
