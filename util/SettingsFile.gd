extends RefCounted
class_name SettingsFile

var config_file := ConfigFile.new()
var config_path := "user://settings.cfg"
var defaults:Dictionary = {}
var keys_set:Dictionary = {}
var section:String = "default"

func _init(filename:String, defaults:Dictionary={}, section:String="default"):
	self.config_path = filename
	self.defaults = defaults
	self.section = section

func get_config(key:String, default_value=null):
	return config_file.get_value(section, key, default_value if default_value != null else defaults.get(key))

func set_config(key:String, value):
	config_file.set_value(section, key, value)

func load_config():
	var err = config_file.load(config_path)
	for key in config_file.get_section_keys(section):
		keys_set[key] = true

func save_config():
	config_file.save(config_path)
