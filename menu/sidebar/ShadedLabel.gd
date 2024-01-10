extends Label

func _ready():
	material.set_shader_parameter("rect_global_position", global_position)
	material.set_shader_parameter("rect_size", size)
