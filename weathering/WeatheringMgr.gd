extends Node

const ALLOWED_RANDOM := "allowed_random"

var weather_low := {}
var weather_high := {}
var weather_settings := SettingsFile.new("user://weathering.cfg", {
	ALLOWED_RANDOM: ["cracked", "crystallized", "dissolve", "faded", "parched", "sand-blasted"]
})

func _ready():
	load_weathering_options()
	weather_settings.set_config(ALLOWED_RANDOM, weather_settings.get_config(ALLOWED_RANDOM))
	weather_settings.save_config()

func get_specific_option(option_name:String, intensity:float) -> WeatheringConfig:
	if !weather_low.get(option_name) or !weather_high.get(option_name):
		return null
	return WeatheringConfig.interpolate(weather_low.get(option_name), weather_high.get(option_name), intensity)

func get_random_option(intensity:float) -> WeatheringConfig:
	var opts = weather_settings.get_config(ALLOWED_RANDOM, [])
	if opts.size() == 0:
		return null
	return get_specific_option(opts.pick_random(), intensity)

func load_weathering_options():
	var dir = DirAccess.open("res://weathering")
	if dir:
		dir.list_dir_begin()
		var file_name = dir.get_next()
		while file_name != "":
			if !dir.current_is_dir():
				if file_name.ends_with("-low.tres"):
					var weathering_option_name = file_name.substr(0, file_name.length()-9)
					load_weathering_option(weathering_option_name)
			file_name = dir.get_next()

func load_weathering_option(option_name:String):
	var low_filename = "res://weathering/%s-low.tres" % option_name
	var high_filename = "res://weathering/%s-high.tres" % option_name
	if FileAccess.file_exists(low_filename) and FileAccess.file_exists(high_filename):
		pass
	else:
		push_error("Tried to load weathering option %s but both %s-low.tres and %s-high.tres did not exist" % [option_name, option_name, option_name])
	var low_option = ResourceLoader.load(low_filename)
	var high_option = ResourceLoader.load(high_filename)

func set_random_allowed(option_name:String, allowed:bool):
	var setting:Array = weather_settings.get_config(ALLOWED_RANDOM, [])
	if !allowed:
		setting.erase(option_name)
	else:
		if setting.find(option_name) >= 0:
			setting.push_back(option_name)
	weather_settings.set_config(ALLOWED_RANDOM, setting)
	weather_settings.save_config()
