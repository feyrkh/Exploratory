extends Node

var steam_enabled := false

func _ready():
	if !OS.has_feature("steam"):
		return
	var initialize_response: Dictionary = Steam.steamInitEx( true, 480 )
	print("Did Steam initialize?: %s " % initialize_response)
	if initialize_response['status'] > 0:
		push_error("Failed to connect to Steam, status is ", initialize_response['status'])
		steam_enabled = false
	else:
		steam_enabled = true

func get_steam_username():
	if !steam_enabled:
		return ""
	return Steam.getPersonaName()

func _process(_delta: float) -> void:
	if !steam_enabled:
		set_process(false)
		return
	Steam.run_callbacks()
