extends CustomMenuButton
class_name DifficultyMode

@export var settings:GameSettings

func _ready():
	super._ready()
	if settings == null:
		settings = GameSettings.new()
		settings.name = "Custom Difficulty"
	else:
		text = settings.name
