extends Node

var steam_enabled := false
var steam_username = Steam.getPersonaName()

func _ready():
	var initialize_response: Dictionary = Steam.steamInitEx( true, 480 )
	print("Did Steam initialize?: %s " % initialize_response)
	if initialize_response['status'] > 0:
		push_error("Failed to connect to Steam, status is ", initialize_response['status'])
		steam_enabled = false
	else:
		steam_enabled = true
		steam_username = Steam.getPersonaName()

func _process(_delta: float) -> void:
	Steam.run_callbacks()
