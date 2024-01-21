extends RefCounted
class_name SettingsFile

var config_file := ConfigFile.new()
var config_path := "user://settings.cfg"
var defaults:Dictionary = {}
var keys_set:Dictionary = {}
var section:String = "default"

func _init(filename:String, default_settings:Dictionary={}, section_name:String="default"):
	self.config_path = filename
	self.defaults = default_settings
	self.section = section_name
	load_config()

func get_config(key:String, default_value=null):
	return config_file.get_value(section, key, default_value if default_value != null else defaults.get(key))

func set_config(key:String, value):
	config_file.set_value(section, key, value)
	print("Set %s:%s=%s\nRetrieved value: %s" % [section, key, value, config_file.get_value(section, key)])

func load_config():
	var err = config_file.load(config_path)
	if err != OK and err != ERR_FILE_NOT_FOUND:
		push_error("Failed to open config file ", config_path, ": ", err)
	if config_file.has_section(section):
		for key in config_file.get_section_keys(section):
			keys_set[key] = true

func erase_config(key:String):
	if config_file.has_section_key(section, key):
		config_file.erase_section_key(section, key)

func save_config():
	config_file.save(config_path)
