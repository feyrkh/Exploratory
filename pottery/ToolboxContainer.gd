extends PanelContainer

const ANIMATE_TIME := 0.5

@onready var resting_position = position
@onready var extended_position = Vector2(position.x, get_viewport().size.y -  get_rect().size.y)
@onready var normal_distance = extended_position.distance_to(resting_position)
var cur_tween:Tween

func _on_mouse_entered():
	if cur_tween and cur_tween.is_running():
		cur_tween.stop()
	var duration = ANIMATE_TIME * (position.distance_to(extended_position) / normal_distance)
	cur_tween = create_tween()
	cur_tween.tween_property(self, "position", extended_position, duration)


func _on_mouse_exited():
	if cur_tween and cur_tween.is_running():
		cur_tween.stop()
	var duration = ANIMATE_TIME * (position.distance_to(resting_position) / normal_distance)
	cur_tween = create_tween()
	cur_tween.tween_property(self, "position", resting_position, duration)
