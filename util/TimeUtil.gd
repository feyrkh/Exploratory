extends Object
class_name TimeUtil

static func format_timer(time_seconds:int):
	var hours:int = time_seconds / 3600
	var mins:int = time_seconds / 60
	var secs:int = time_seconds % 60
	if hours > 0:
		return "%d:%02d:%02d" % [hours, mins, secs]
	else:
		return "%02d:%02d" % [mins, secs]
