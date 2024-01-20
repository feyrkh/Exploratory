extends Object
class_name TimeUtil

static func format_timer(time_seconds:int):
	var hours:int = floor(time_seconds / 3600.0)
	var mins:int = floor(time_seconds / 60.0)
	var secs:int = time_seconds % 60
	if hours > 0:
		return "%d:%02d:%02d" % [hours, mins, secs]
	else:
		return "%02d:%02d" % [mins, secs]
