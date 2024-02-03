extends Camera2D

@export var zoom_speed:float = 10
@onready var zoom_target:Vector2 = zoom

func _process(delta):
	if !zoom_target.is_equal_approx(zoom):
		zoom = lerp(zoom, zoom_target, zoom_speed * delta)
