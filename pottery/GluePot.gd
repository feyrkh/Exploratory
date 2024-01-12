extends ColorRect
class_name GluePot

func get_glue_color():
	return color

func highlight():
	$ColorRect.color = Color.WHITE_SMOKE

func unhighlight():
	$ColorRect.color = Color.DIM_GRAY
